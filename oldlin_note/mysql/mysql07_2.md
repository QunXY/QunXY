锁

在 MySQL 里，根据加锁的范围，可以分为**全局锁、表级锁和行锁**三类。



![图片](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203231720568.png)

### 全局锁（针对库）

> 全局锁是怎么用的？

要使用全局锁，则要执行这条命：

```mysql
flush tables with read lock
```

执行后，**整个数据库就处于只读状态了**，这时其他线程执行以下操作，都会被阻塞：

- 对数据的增删改操作，比如 insert、delete、update等语句；
- 对表结构的更改操作，比如 alter table、drop table 等语句。

如果要释放全局锁，则要执行这条命令：

```mysql
unlock tables
```

当然，当会话断开了，全局锁会被自动释放。

> 全局锁应用场景是什么？

全局锁主要应用于做**全库逻辑备份**，这样在备份数据库期间，不会因为数据或表结构的更新，而出现备份文件的数据与预期的不一样。

举个例子大家就知道了。

在全库逻辑备份期间，假设不加全局锁的场景，看看会出现什么意外的情况。

如果在全库逻辑备份期间，有用户购买了一件商品，一般购买商品的业务逻辑是会涉及到多张数据库表的更新，比如在用户表更新该用户的余额，然后在商品表更新被购买的商品的库存。

那么，有可能出现这样的顺序：

1. 先备份了用户表的数据；
2. 然后有用户发起了购买商品的操作；
3. 接着再备份商品表的数据。

也就是在备份用户表和商品表之间，有用户购买了商品。

这种情况下，备份的结果是用户表中该用户的余额并没有扣除，反而商品表中该商品的库存被减少了，如果后面用这个备份文件恢复数据库数据的话，用户钱没少，而库存少了，等于用户白嫖了一件商品。

所以，在全库逻辑备份期间，加上全局锁，就不会出现上面这种情况了。

> 加全局锁又会带来什么缺点呢？

加上全局锁，意味着整个数据库都是只读状态。

那么如果数据库里有很多数据，备份就会花费很多的时间，关键是备份期间，业务只能读数据，而不能更新数据，这样会造成业务停滞。

> 既然备份数据库数据的时候，使用全局锁会影响业务，那有什么其他方式可以避免？

有的，如果数据库的引擎支持的事务支持**可重复读的隔离级别**，那么在备份数据库之前先开启事务，会先创建 Read View，然后整个事务执行期间都在用这个 Read View，而且由于 MVCC 的支持，备份期间业务依然可以对数据进行更新操作。

因为在可重复读的隔离级别下，即使其他事务更新了表的数据，也不会影响备份数据库时的 Read View，这就是事务四大特性中的隔离性，这样备份期间备份的数据一直是在开启事务时的数据。

备份数据库的工具是 mysqldump，在使用 mysqldump 时加上 `–single-transaction` 参数的时候，就会在备份数据库之前先开启事务。<font color='red'>这种方法只适用于支持「可重复读隔离级别的事务」的存储引擎。InnoDB 存储引擎默认的事务隔离级别正是可重复读，因此可以采</font><font color='red'>用这种方式来备份数据库。</font>但是，对于 MyISAM 这种不支持事务的引擎，在备份数据库时就要使用全局锁的方法。

### 表级锁

> MySQL 表级锁有哪些？具体怎么用的。

MySQL 里面表级别的锁有这几种：

- 表锁；
- 元数据锁（MDL）;
- 意向锁；
- AUTO-INC 锁；

#### 表锁

先来说说**表锁**

如果我们想对学生表（t_student）加表锁，可以使用下面的命令：

```mysql
//表级别的共享锁，也就是读锁；
lock tables t_student read;		#注：table可以加s，也可以不加s，不影响
								
//表级别的独占锁，又称排他锁，也就是写锁；		#单表加读锁，可以读，不可以写，其它表不可以读写
lock tables t_stuent wirte;		         #单表加写锁，可以写和读，其它表不可读写
		   


//这种写法没报错，但会实现的是全局锁
mysql> lock table test test1 read;
Query OK, 0 rows affected (0.00 sec)

mysql> select * from test1;
ERROR 1100 (HY000): Table 'test1' was not locked with LOCK TABLES
mysql> select * from test;
ERROR 1100 (HY000): Table 'test' was not locked with LOCK TABLES
mysql> insert into test1 values(china,台湾);
ERROR 1100 (HY000): Table 'test1' was not locked with LOCK TABLES
mysql> select * from test15;
ERROR 1100 (HY000): Table 'test15' was not locked with LOCK TABLES
mysql> unlock teble;

```

需要注意的是，表锁除了会限制别的线程的读写外，也会限制本线程接下来的读写操作。

也就是说如果本线程对学生表加了「共享表锁」，那么本线程接下来如果要对学生表执行写操作的语句，是会被阻塞的，当然其他线程对学生表进行写操作时也会被阻塞，直到锁被释放。

要释放表锁，可以使用下面这条命令，会释放当前会话的所有表锁：

```mysql
unlock tables
```

另外，当会话退出后，也会释放所有表锁。

不过尽量避免在使用 InnoDB 引擎的表使用表锁，因为表锁的颗粒度太大，会影响并发性能，**InnoDB 牛逼的地方在于实现了颗粒度更细的行级锁**。

#### 元数据锁

再来说说**元数据锁（MDL）**。

我们不需要显示的使用 MDL，因为当我们对数据库表进行操作时，会自动给这个表加上 MDL：

- 对一张表进行<font color='red'> CR(read)UD（增删改查）</font>操作时，加的是 **MDL 读锁**；
- 对一张表做结构变更操作的时候，加的是 **MDL 写锁**；

MDL 是为了保证当用户对表执行 CRUD 操作时，防止其他线程对这个表结构做了变更。

当有线程在执行 select 语句（ 加 MDL 读锁）的期间，如果有其他线程要更改该表的结构（ 申请 MDL 写锁），那么将会被阻塞，直到执行完 select 语句（ 释放 MDL 读锁）。

反之，当有线程对表结构进行变更（ 加 MDL 写锁）的期间，如果有其他线程执行了 CRUD 操作（ 申请 MDL 读锁），那么就会被阻塞，直到表结构变更完成（ 释放 MDL 写锁）。

> MDL 不需要显示调用，那它是在什么时候释放的?

<font color='red'>MDL 是在事务提交后才会释放，这意味着**事务执行期间，MDL 是一直持有的**。</font>

那如果数据库有一个长事务（所谓的长事务，就是开启了事务，但是一直还没提交），那在对表结构做变更操作的时候，可能会发生意想不到的事情，比如下面这个顺序的场景：

1. 首先，线程 A 先启用了事务（但是一直不提交），然后执行一条 select 语句，此时就先对该表加上 MDL 读锁；
2. 然后，线程 B 也执行了同样的 select 语句，此时并不会阻塞，因为「读读」并不冲突；
3. 接着，线程 C 修改了表字段，此时由于线程 A 的事务并没有提交，也就是 MDL 读锁还在占用着，这时线程 C 就无法申请到 MDL 写锁，就会被阻塞，

那么在线程 C 阻塞后，后续有对该表的 select 语句，就都会被阻塞，如果此时有大量该表的 select 语句的请求到来，就会有大量的线程被阻塞住，这时数据库的线程很快就会爆满了。

> 为什么线程 C 因为申请不到 MDL 写锁，而导致后续的申请读锁的查询操作也会被阻塞？

这是因为申请 MDL 锁的操作会形成一个队列，队列中**写锁获取优先级高于读锁**，一旦出现 MDL 写锁等待，会阻塞后续该表的所有 CRUD 操作。

所以为了能安全的对表结构进行变更，在对表结构变更前，先要看看数据库中的长事务，是否有事务已经对表加上了 MDL 读锁，如果可以考虑 kill 掉这个长事务，然后再做表结构的变更。

实例：

```mysql
mysql> select * from performance_schema.metadata_locks;
Empty set (0.00 sec)

#需开启元数据锁记录
mysql> UPDATE performance_schema.setup_instruments
    -> SET ENABLED = 'YES', TIMED = 'YES'
    -> WHERE NAME = 'wait/lock/metadata/sql/mdl';
Query OK, 1 row affected (0.00 sec)
Rows matched: 1  Changed: 1  Warnings: 0

会话1：查询前，先看一下metadata_locks表，这个表位于performance_schema下，记录了metadata lock的加锁信息。

mysql> select * from performance_schema.metadata_locks;
+-------------+--------------------+----------------+-----------------------+-------------+---------------+-------------+--------+-----------------+----------------+
| OBJECT_TYPE | OBJECT_SCHEMA      | OBJECT_NAME    | OBJECT_INSTANCE_BEGIN | LOCK_TYPE   | LOCK_DURATION | LOCK_STATUS | SOURCE | OWNER_THREAD_ID | OWNER_EVENT_ID |
+-------------+--------------------+----------------+-----------------------+-------------+---------------+-------------+--------+-----------------+----------------+
| TABLE       | performance_schema | metadata_locks |              56363728 | SHARED_READ | TRANSACTION   | GRANTED     |        |              27 |            107 |
+-------------+--------------------+----------------+-----------------------+-------------+---------------+-------------+--------+-----------------+----------------+

会话1：开启事务，并执行简单查询

mysql> begin;
Query OK, 0 rows affected (0.00 sec)

mysql> select * from test1;
+-------+--------+
| name  | home   |
+-------+--------+
| china | 中国   |
+-------+--------+
1 row in set (0.00 sec)

会话1：再次查看metadata_locks表
mysql> select * from performance_schema.metadata_locks;
+-------------+--------------------+----------------+-----------------------+-------------+---------------+-------------+--------+-----------------+----------------+
| OBJECT_TYPE | OBJECT_SCHEMA      | OBJECT_NAME    | OBJECT_INSTANCE_BEGIN | LOCK_TYPE   | LOCK_DURATION | LOCK_STATUS | SOURCE | OWNER_THREAD_ID | OWNER_EVENT_ID |
+-------------+--------------------+----------------+-----------------------+-------------+---------------+-------------+--------+-----------------+----------------+
| TABLE       | class              | test1          |              57562016 | SHARED_READ | TRANSACTION   | GRANTED     |        |              27 |            110 |
| TABLE       | performance_schema | metadata_locks |              54878592 | SHARED_READ | TRANSACTION   | GRANTED     |        |              27 |            111 |
+-------------+--------------------+----------------+-----------------------+-------------+---------------+-------------+--------+-----------------+----------------+
2 rows in set (0.00 sec)

注：再次查看metadata_lock表，发现多了一条test1的加锁记录，加锁类型为SHARED_READ,且状态是已授予（GRANTED)。大家通常理解的查询不加锁，是指不在表上加innodb行锁。


会话2：另外一个session执行了一个DDL操作，此时就会产生互斥的metadata lock：
mysql> drop table test1;


会话1：再次查看metadata_locks表,发现test1表有MDL锁冲突
mysql> select * from performance_schema.metadata_locks;
+-------------+--------------------+----------------+-----------------------+---------------------+---------------+-------------+--------+-----------------+----------------+
| OBJECT_TYPE | OBJECT_SCHEMA      | OBJECT_NAME    | OBJECT_INSTANCE_BEGIN | LOCK_TYPE           | LOCK_DURATION | LOCK_STATUS | SOURCE | OWNER_THREAD_ID | OWNER_EVENT_ID |
+-------------+--------------------+----------------+-----------------------+---------------------+---------------+-------------+--------+-----------------+----------------+
| TABLE       | class              | test1          |              57562016 | SHARED_READ         | TRANSACTION   | GRANTED     |        |              27 |            110 |
| TABLE       | performance_schema | metadata_locks |              54878592 | SHARED_READ         | TRANSACTION   | GRANTED     |        |              27 |            111 |
| GLOBAL      | NULL               | NULL           |       139879300312832 | INTENTION_EXCLUSIVE | STATEMENT     | GRANTED     |        |              32 |             21 |
| SCHEMA      | class              | NULL           |       139879300276688 | INTENTION_EXCLUSIVE | TRANSACTION   | GRANTED     |        |              32 |             21 |
| TABLE       | class              | test1          |       139879300437600 | EXCLUSIVE           | TRANSACTION   | PENDING     |        |              32 |             21 |
+-------------+--------------------+----------------+-----------------------+---------------------+---------------+-------------+--------+-----------------+----------------+
5 rows in set (0.00 sec)


查看所有会话,id为7的线程还未执行drop操作，状态为‘Waiting for table metadata lock’，也就是在等待会话1的事务提交操作完成。

mysql> show processlist;
+----+------+--------------------+--------------------+---------+------+---------------------------------+------------------+
| Id | User | Host               | db                 | Command | Time | State                           | Info             |
+----+------+--------------------+--------------------+---------+------+---------------------------------+------------------+
|  2 | root | localhost          | class              | Query   |    0 | starting                        | show processlist |
|  3 | root | 192.168.245.1:2063 | performance_schema | Sleep   |  380 |                                 | NULL             |
|  4 | root | 192.168.245.1:2064 | performance_schema | Sleep   |  380 |                                 | NULL             |
|  5 | root | 192.168.245.1:2549 | class              | Sleep   | 3137 |                                 | NULL             |
|  6 | root | 192.168.245.1:2550 | class              | Sleep   | 3137 |                                 | NULL             |
|  7 | root | localhost          | class              | Query   |   62 | Waiting for table metadata lock | drop table test1 |
+----+------+--------------------+--------------------+---------+------+---------------------------------+------------------+
6 rows in set (0.00 sec)

```

https://blog.csdn.net/weixin_48943299/article/details/123927176









#### 意向锁

接着，说说**意向锁**

- 在使用 InnoDB 引擎的表里对某些记录加上「共享锁」之前，需要先在表级别加上一个「意向共享锁」；
- 在使用 InnoDB 引擎的表里对某些纪录加上「独占锁」之前，需要先在表级别加上一个「意向独占锁」；

也就是，当执行插入、更新、删除操作，需要先对表加上「意向共享锁」，然后对该记录加独占锁。

而普通的 select 是不会加行级锁的，普通的 select 语句是利用 MVCC 实现一致性读，是无锁的。

不过，select 也是可以对记录加共享锁和独占锁的，具体方式如下：

```mysql
//先在表上加上意向共享锁，然后对读取的记录加独占锁
select ... lock in share mode;

//先表上加上意向独占锁，然后对读取的记录加独占锁
select ... for update;
```

**意向共享锁和意向独占锁是表级锁，不会和行级的共享锁和独占锁发生冲突，而且意向锁之间也不会发生冲突，只会和共享表锁（\*lock tables … read\*）和独占表锁（\*lock tables … write\*）发生冲突。**

表锁和行锁是满足<font color='red'>读读共享、读写互斥、写写互斥</font>的。

如果没有「意向锁」，那么加「独占表锁」时，就需要遍历表里所有记录，查看是否有记录存在独占锁，这样效率会很慢。

那么有了「意向锁」，由于在对记录加独占锁前，先会加上表级别的意向独占锁，那么在加「独占表锁」时，直接查该表是否有意向独占锁，如果有就意味着表里已经有记录被加了独占锁，这样就不用去遍历表里的记录。

所以，**意向锁的目的是为了快速判断表里是否有记录被加锁**。

#### AUTO-INC 锁

最后，说说 **AUTO-INC 锁**。

在为某个字段声明 `AUTO_INCREMENT` 属性时，之后可以在插入数据时，可以不指定该字段的值，数据库会自动给该字段赋值递增的值，这主要是通过 AUTO-INC 锁实现的。

AUTO-INC 锁是特殊的表锁机制，**不是在一个事务提交后才释放，而是再执行完插入语句后就会立即释放**。

**在插入数据时，会加一个表级别的 AUTO-INC 锁**，然后为被 `AUTO_INCREMENT` 修饰的字段赋值递增的值，等插入语句执行完成后，才会把 AUTO-INC 锁释放掉。

那么，一个事务在持有 AUTO-INC 锁的过程中，其他事务的如果要向该表插入语句都会被阻塞，从而保证插入数据时，被 `AUTO_INCREMENT` 修饰的字段的值是连续递增的。

但是， AUTO-INC 锁再对大量数据进行插入的时候，会影响插入性能，因为另一个事务中的插入会被阻塞。

因此， 在 MySQL 5.1.22 版本开始，InnoDB 存储引擎提供了一种**轻量级的锁**来实现自增。

一样也是在插入数据的时候，会为被 `AUTO_INCREMENT` 修饰的字段加上轻量级锁，**然后给该字段赋值一个自增的值，就把这个轻量级锁释放了，而不需要等待整个插入语句执行完后才释放锁**。

- AUTO_INC 锁互不兼容，也就是说同一张表同时只允许有一个自增锁；
- 自增值一旦分配了就会 +1，如果事务回滚，自增值也不会减回去，所以自增值可能会出现中断的情况。

InnoDB 存储引擎提供了个 innodb_autoinc_lock_mode 的系统变量，是用来控制选择用 AUTO-INC 锁，还是轻量级的锁。

- 当 innodb_autoinc_lock_mode = 0，就采用 AUTO-INC 锁；
- 当 innodb_autoinc_lock_mode = 2，就采用轻量级锁；
- 当 innodb_autoinc_lock_mode = 1，这个是默认值，两种锁混着用，如果能够确定插入记录的数量就采用轻量级锁，不确定时就采用 AUTO-INC 锁。

不过，当 innodb_autoinc_lock_mode = 2 是性能最高的方式，但是会带来一定的问题。因为并发插入的存在，在每次插入时，自增长的值可能不是连续的，**这在有主从赋值的场景中是不安全的**。

前面也提到，普通的 select 语句是不会对记录加锁的，如果要在查询时对记录加行锁，可以使用下面这两个方式：

```mysql
//对读取的记录加共享锁
select ... lock in share mode;

//对读取的记录加独占锁
select ... for update;
```

上面这两条语句必须再一个事务中，当事务提交了，锁就会被释放，因此在使用这两条语句的时候，要加上 begin、start transaction 或者 set autocommit = 0。



### 行级锁

**行锁是存储引擎实现，不同的引擎实现的不同，而表锁则是由 MySQL 实现。在 MySQL的常用引擎中InnoDB 支持行锁，而MyISAM则只能使用 MySQL提供的表锁**。

行锁的劣势：开销大；加锁慢；会出现死锁

行锁的优势：锁的粒度小，发生锁冲突的概率低；处理并发的能力强

加锁的方式：自动加锁。对于`UPDATE、DELETE、INSERT`语句



## 行锁的模式

锁的模式有：

- - 读意向锁
  - 写意向锁
  - 读锁
  - 写锁
  - 自增锁(auto_inc)。

<font color='red'>行锁在 InnoDB 中是基于索引实现的，所以一旦某个加锁操作没有使用索引，那么该锁就会退化为表锁。</font>

### 读写锁

读锁，又称共享锁（Share locks，简称 S 锁），加了读锁的记录，所有的事务都可以读取，但是不能修改，并且可同时有多个事务对记录加读锁。

写锁，又称排他锁（Exclusive locks，简称 X 锁），或独占锁，对记录加了排他锁之后，只有拥有该锁的事务可以读取和修改，其他事务都不可以读取和修改，并且同一时间只能有一个事务加写锁。

### 意向锁

锁定允许事务在行级上的锁和表级上的锁同时存在。为了支持在不同粒度上进行加锁操作，InnoDB存储引擎支持一种额外的锁方式。

释义：

<font color='red'> 意向共享锁（IS）：事务想要在获得表中某些记录的共享锁，需要在表上先加意向共享锁。</font>

<font color='red'> 意向互斥锁（IX）：事务想要在获得表中某些记录的互斥锁，需要在表上先加意向互斥锁。</font>

意向共享锁和意向排它锁总称为意向锁。意向锁的出现是为了支持Innodb支持多粒度锁。

首先，意向锁是表级别锁。

理由:当我们需要给一个加表锁的时候，我们需要根据意向锁去判断表中有没有数据行被锁定，以确定是否能加成功。如果意向锁是行锁，那么我们就得遍历表中所有数据行来判断。如果意向锁是表锁，则我们直接判断一次就知道表中是否有数据行被锁定了。所以说将意向锁设置成表级别的锁的性能比行锁高的多。

所以，意向锁的作用就是：

<font color='red'>当一个事务在需要获取资源的锁定时，如果该资源已经被排他锁占用，则数据库会自动给该事务申请一个该表的意向锁。如果自己需要一个共享锁定，就申请一个意向共享锁。如果需要的是某行（或者某些行）的排他锁定，则申请一个意向排他锁。</font>



### 数据准备

```mysql
CREATE TABLE `user` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_name` varchar(255) ,
  `password` varchar(255) ,
  `age` int, 
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

---可以看出，user表中的id就用到了自增。
```

## 行锁类型

根据锁的粒度可以把锁细分为表锁和行锁，行锁根据场景的不同又可以进一步细分。下面要说的三种锁，也是我们面试中的加分项，所以很有必要来聊聊。

- 记录锁（Record Locks）
- 间隙锁（Gap Locks）
- 临键锁（Next-Key Locks）

### 记录锁（Record Locks）

记录锁就是为**某行**记录加锁，它封锁该行的索引记录：

```mysql
-- id 列为主键列或唯一索引列
SELECT * FROM user WHERE id = 1 FOR UPDATE;
```

id 为 1 的记录行会被锁住。

需要注意的是：id 列必须为唯一索引列或主键列，否则上述语句加的锁就会变成临键锁。

同时查询语句必须为精准匹配（=），不能为 >、<、like等，否则也会退化成临键锁。

我们也可以在通过 主键索引 与 唯一索引 对数据行进行 UPDATE 操作时，也会对该行数据加记录锁：

```mysql
-- id 列为主键列或唯一索引列
UPDATE t_user SET age = 50 WHERE id = 1;
```



实例：

```
mysql> select * from test15 ;
+-----+
| id  |
+-----+
| 103 |
| 104 |
| 105 |
| 106 |
| 107 |
| 108 |
+-----+
6 rows in set (0.00 sec)

mysql> begin;
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT * FROM test15 WHERE id = 103 FOR UPDATE;
+-----+
| id  |
+-----+
| 103 |
+-----+
1 row in set (0.00 sec)

会话2：
mysql> begin;
Query OK, 0 rows affected (0.01 sec)

mysql> UPDATE test15  SET id = 110 WHERE id = 103;
^C^C -- query aborted
ERROR 1317 (70100): Query execution was interrupted

mysql> UPDATE test15  SET id = 110 WHERE id = 104;
Query OK, 1 row affected (0.00 sec)
Rows matched: 1  Changed: 1  Warnings: 0

mysql> select * from test15 where id = 103;
+-----+
| id  |
+-----+
| 103 |
+-----+
1 row in set (0.00 sec)

```







### 间隙锁（Gap Locks）

**间隙锁**基于非唯一索引，它锁定一段范围内的索引记录。**间隙锁**基于下面将会提到的Next-Key Locking 算法，请务必牢记：**使用间隙锁锁住的是一个区间，而不仅仅是这个区间中的每一条数据**。

```mysql
SELECT * FROM t_user WHERE id BETWEEN 1 AND 10 FOR UPDATE;
```

即所有在（1，10）区间内的记录行都会被锁住，所有id 为 1、2、3、4、5、6、7、8、9 、10的数据行的插入会被阻塞。

除了手动加锁外，在执行完某些 SQL后，InnoDB也会自动加**间隙锁**。

```
mysql> SELECT * FROM test15 WHERE id BETWEEN 105 AND 110 FOR UPDATE;
+-----+
| id  |
+-----+
| 105 |
| 106 |
| 107 |
| 108 |
| 109 |
| 110 |
+-----+
6 rows in set (0.00 sec)

会话2执行更新：
mysql> UPDATE test15  SET id = 120 WHERE id = 107;
ERROR 1205 (HY000): Lock wait timeout exceeded; try restarting transaction
mysql> UPDATE test15  SET id = 120 WHERE id = 105;
ERROR 1205 (HY000): Lock wait timeout exceeded; try restarting transaction

```



### 临键锁（Next-Key Locks）

临键锁是一种特殊的**间隙锁**，也可以理解为一种特殊的**算法**。通过**临建锁**可以解决幻读的问题。每个数据行上的非唯一索引列上都会存在一把**临键锁**，当某个事务持有该数据行的**临键锁**时，会锁住一段**左开右闭区间**的数据。需要强调的一点是，InnoDB 中行级锁是基于索引实现的，**临键锁**只与非唯一索引列有关，在唯一索引列（包括主键列）上不存在**临键锁**。

比如：表信息 user(id PK, age KEY, name)

 ![640.webp](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203232149481.webp)



该表中 age 列潜在的临键锁有：

 ![640 (1).webp](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203232149687.webp)

在事务 A 中执行如下命令：

```mysql
-- 根据非唯一索引列 UPDATE 某条记录
UPDATE user SET name = Vladimir WHERE age = 24;
-- 或根据非唯一索引列 锁住某条记录
SELECT * FROM user WHERE age = 24 FOR UPDATE;
```

不管执行了上述 SQL 中的哪一句，之后如果在事务 B 中执行以下命令，则该命令会被阻塞：

```mysql
INSERT INTO user VALUES(100, 26, 'tian');
```

很明显，事务 A 在对 age 为 24 的列进行 UPDATE 操作的同时，也获取了 (24, 32] 这个区间内的临键锁。

不仅如此，在执行以下 SQL 时，也会陷入阻塞等待：

```mysql
INSERT INTO table VALUES(100, 30, 'zhang');
```

那最终我们就可以得知，在根据非唯一索引 对记录行进行 UPDATE \ FOR UPDATE \ LOCK IN SHARE MODE 操作时，InnoDB 会获取该记录行的 临键锁 ，并同时获取该记录行下一个区间的间隙锁。

即事务 A在执行了上述的 SQL 后，最终被锁住的记录区间为 (10, 32)。



```
mysql> select * from test15;
+-----+------+------+
| id  | age  | name |
+-----+------+------+
| 103 |   10 | a    |
| 105 |   15 | b    |
| 106 |   20 | c    |
| 107 |   25 | d    |
| 108 |   30 | e    |
| 109 |   35 | f    |
| 110 |   40 | g    |
+-----+------+------+
7 rows in set (0.00 sec)

mysql> begin;
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT * FROM test15 WHERE age = 20  FOR UPDATE;
+-----+------+------+
| id  | age  | name |
+-----+------+------+
| 106 |   20 | c    |
+-----+------+------+
1 row in set (0.00 sec)

在会话2上操作：
mysql> insert into test15 values(111,18,'h');
ERROR 1205 (HY000): Lock wait timeout exceeded; try restarting transaction
mysql> insert into test15 values(111,32,'h');
Query OK, 1 row affected (0.00 sec)

```







参考资料：《MySQL技术内幕：innodb》、《MySQL实战45讲》、《从根儿上理解MySQL》。

