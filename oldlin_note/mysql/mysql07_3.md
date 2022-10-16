# **MySQL 锁机制**



# 1.锁的分类

## mysql锁划分



- 按照锁的粒度划分：行锁、表锁、页锁
- 按照锁的使用方式划分：共享锁、排它锁（悲观锁的一种实现）
- 还有两种思想上的锁：悲观锁、乐观锁。
- InnoDB中有几种行级锁类型：Record Lock、Gap Lock、Next-key Lock
- Record Lock：在索引记录上加锁
- Gap Lock：间隙锁
- Next-key Lock：Record Lock+Gap Lock

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203231328536.png)



## 1.1 锁的粒度

​            按照锁的粒度划分：行锁，表锁，页锁，全局锁。



### 1.1.1 行锁

 ![image.png](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203231329439.png)



#### 1.1.1.1 Record Lock

```mysql
锁直接加在索引记录上面，锁住的是key;
```



#### 1.1.1.2 Gap Lock

```mysql
锁定索引记录间隙，确保索引记录的间隙不变。
间隙锁是针对事务隔离级别为可重复读或以上级别而已的。
```



#### 1.1.1.3 Next-Key Lock

```mysql
行锁和间隙锁组合起来就叫Next-Key Lock。
```



### 1.1.2 表锁

- 表锁：可以使用lock tableName ...read/write 进行上锁，客户端断开链接的时候自动释放，也可以通过 unlock tables 手动释放
- MDL：不需要显示使用，访问表的时候会自动带上，主要是DDL语句和DML查询更新语句之间进行加锁，保证表结构更新时，DML等语句堵塞



### 1.1.3 全局锁

看mysql7_02



### 1.1.4 页锁

页级锁是MySQL中锁定粒度介于行级锁和表级锁中间的一种锁。表级锁速度快，但冲突多，行级冲突少，但速度慢。所以取了折中的页级，一次锁定相邻的一组记录。BDB支持页级锁





## 1.2 锁的兼容性

| 共享锁 | 读锁 |
| :----: | :--: |
| 排它锁 | 写锁 |



## 1.3 锁的加锁机制

按照锁的心态划分：悲观锁，乐观锁。



## 1.4 意向锁

**<font color='red'>由于表锁和行锁虽然锁定范围不同，但是会相互冲突</font>**。所以当你要加表锁时，势必要先遍历该表的所有记录，判断是否加有排他锁。这种遍历检查的方式显然是一种低效的方式，**<font color='red'>MySQL 引入了意向锁，来检测表锁和行锁的冲突</font>。**



**<font color='red'>意向锁也是表级锁</font>，**也可分为读意向锁（IS 锁）和写意向锁（IX 锁）。当事务要在记录上加上读锁或写锁时，要首先在表上加上意向锁。这样判断表中是否有记录加锁就很简单了，只要看下表上是否有意向锁就行了。
<font color='red'>**意向锁之间是不会产生冲突的，也不和 AUTO_INC 表锁冲突，它只会阻塞表级读锁或表级写锁，另外，意向锁也不会和行锁冲突，行锁只会和行锁冲突。**</font>
<font color='red'>**意向锁是InnoDB自动加的，不需要用户干预。**</font>



对于insert、update、delete，InnoDB会自动给涉及的数据加排他锁（X）；
对于一般的Select语句，InnoDB不会加任何锁，事务可以通过以下语句给显示加共享锁或排他锁。



### 1.4.1 意向共享锁（Intention Shared Lock）

意向共享锁（IS）：表示事务准备给数据行加入共享锁，也就是说一个数据行加共享锁前必须先取得该表的IS锁



### 1.4.2 意向排他锁（Exclusive Lock）

意向排他锁（IX）：类似上面，表示事务准备给数据行加入排他锁，说明事务在一个数据行加排他锁前必须先取得该表的IX锁



### 1.4.3 插入意向锁（Insert Intention Locks）

`插入意向锁`是在插入一条记录行前，由 **INSERT** 操作产生的一种`间隙锁`。该锁用以表示插入**意向**，当多个事务在**同一区间**（gap）插入**位置不同**的多条数据时，事务之间**不需要互相等待**。假设存在两条值分别为 4 和 7 的记录，两个不同的事务分别试图插入值为 5 和 6 的两条记录，每个事务在获取插入行上独占的（排他）锁前，都会获取（4，7）之间的`间隙锁`，但是因为数据行之间并不冲突，所以两个事务之间并**不会产生冲突**（阻塞等待）。
总结来说，`插入意向锁`的特性可以分成两部分：

1. `插入意向锁`是一种特殊的`间隙锁` —— `间隙锁`可以锁定**开区间**内的部分记录。
2. `插入意向锁`之间互不排斥，所以即使多个事务在同一区间插入多条记录，只要记录本身（`主键`、`唯一索引`）不冲突，那么事务之间就不会出现**冲突等待**。

需要强调的是，虽然`插入意向锁`中含有`意向锁`三个字，但是它并不属于`意向锁`而属于`间隙锁`，因为`意向锁`是**表锁**而`插入意向锁`是**行锁**，`插入意向锁`在**锁定区间相同**但**记录行本身不冲突**的情况下**互不排斥**。



## 1.5 共享锁用法（S锁 读锁）：

<font color='red'>若事务T对数据对象A加上S锁，则事务T可以读A但不能修改A，其他事务只能再对A加S锁，而不能加X锁，直到T释放A上的S锁。</font>这保证了其他事务可以读A，但在T释放A上的S锁之前不能对A做任何修改。

```mysql
select ... lock in share mode;
```

共享锁就是允许多个线程同时获取一个锁，一个锁可以同时被多个线程拥有。





## 1.6 排它锁用法（X 锁 写锁）：

<font color='red'>若事务T对数据对象A加上X锁，事务T可以读A也可以修改A，其他事务不能再对A加任何锁，直到T释放A上的锁。</font>这保证了其他事务在T释放A上的锁之前不能再读取和修改A。

```sql
select ... for update
```

排它锁，也称作独占锁，一个锁在某一时刻只能被一个线程占有，其它线程必须等待锁被释放之后才可能获取到锁。





## 1.7 乐观锁和悲观锁

在数据库的锁机制中介绍过，数据库管理系统（DBMS）中的并发控制的任务是确保在多个事务同时存取数据库中同一数据时不破坏事务的隔离性和统一性以及数据库的统一性。

乐观并发控制(乐观锁)和悲观并发控制（悲观锁）是并发控制主要采用的技术手段。

<font color='red'>无论是悲观锁还是乐观锁，都是人们定义出来的概念，可以认为是一种思想。</font>其实不仅仅是关系型数据库系统中有乐观锁和悲观锁的概念，像memcache、hibernate、tair等都有类似的概念。

针对于不同的业务场景，应该选用不同的并发控制方式。所以，不要把乐观并发控制和悲观并发控制狭义的理解为DBMS中的概念，更不要把他们和数据中提供的锁机制（行锁、表锁、排他锁、共享锁）混为一谈。其实，在DBMS中，悲观锁正是利用数据库本身提供的锁机制来实现的。



### 1.7.1 悲观锁



 在关系数据库管理系统里，悲观并发控制（又名“悲观锁”，Pessimistic Concurrency Control，缩写“PCC”）是一种并发控制的方法。它可以阻止一个事务以影响其他用户的方式来修改数据。如果一个事务执行的操作对某行数据应用了锁，那只有当这个事务把锁释放，其他事务才能够执行与该锁冲突的操作。悲观并发控制主要用于数据争用激烈的环境，以及发生并发冲突时使用锁保护数据的成本要低于回滚事务的成本的环境中。

 悲观锁，正如其名，它指的是对数据被外界（包括本系统当前的其他事务，以及来自外部系统的事务处理）修改持保守态度(悲观)，因此，在整个数据处理过程中，将数据处于锁定状态。 悲观锁的实现，往往依靠数据库提供的锁机制 （也只有数据库层提供的锁机制才能真正保证数据访问的排他性，否则，即使在本系统中实现了加锁机制，也无法保证外部系统不会修改数据）



#### 1.7.1.1 悲观锁的具体流程：

- 在对任意记录进行修改前，先尝试为该记录加上排他锁（exclusive locking）
- 如果加锁失败，说明该记录正在被修改，那么当前查询可能要等待或者抛出异常。 具体响应方式由开发者根据实际需要决定。
- 如果成功加锁，那么就可以对记录做修改，事务完成后就会解锁了。
- 其间如果有其他对该记录做修改或加排他锁的操作，都会等待我们解锁或直接抛出异常。

##### 在mysql/InnoDB中使用悲观锁

首先我们得关闭mysql中的autocommit属性，因为mysql默认使用自动提交模式，也就是说当我们进行一个sql操作的时候，mysql会将这个操作当做一个事务并且自动提交这个操作。

```sql
-- 开始事务
begin;/begin work;/start transaction; (三者选一就可以)
-- 查询出商品信息
select ... for update;
-- 提交事务
commit;/commit work;
```



通过下面的例子来说明：

1.当你手动加上排它锁，但是并没有关闭mysql中的autocommit。

```mysql
SESSION1:
mysql> select * from user for update;
+----+------+--------+
| id | name | psword |
+----+------+--------+
|  1 | a    | 1      |
|  2 | b    | 2      |
|  3 | c    | 3      |
+----+------+--------+
3 rows in set

-- 这里他会一直提示Unknown
mysql> update user set name=aa where id=1;
1054 - Unknown column 'aa' in 'field list'

mysql> insert into user values(4,d,4);
1054 - Unknown column 'd' in 'field list'
```



2.正常流程

```mysql
-- 窗口1：
mysql> set autocommit=0;
Query OK, 0 rows affected
我这里锁的是表
mysql> select * from user for update;
+----+-------+
| id | price |
+----+-------+
|  1 |   500 |
|  2 |   800 |
+----+-------+
2 rows in set

-- 窗口2：
mysql> update user set price=price-100 where id=1;
ERROR 1205 (HY000): Lock wait timeout exceeded; try restarting transaction
执行上面操作的时候，会显示等待状态，一直到窗口1执行commit提交事务才会出现下面的显示结果
Database changed
Rows matched: 1  Changed: 1  Warnings: 0

-- 窗口1：
mysql> commit;
Query OK, 0 rows affected
mysql> select * from user;
+----+-------+
| id | price |
+----+-------+
|  1 |   400 |
|  2 |   800 |
+----+-------+
2 rows in set
```

上面的例子展示了排它锁的原理：一个锁在某一时刻只能被一个线程占有，其它线程必须等待锁被释放之后才可能获取到锁或者进行数据的操作。



#### 1.7.1.2 悲观锁的优点和不足：

悲观锁实际上是采取了“先取锁在访问”的策略，为数据的处理安全提供了保证，但是在效率方面，由于额外的加锁机制产生了额外的开销，并且增加了死锁的机会。并且降低了并发性；当一个事物所以一行数据的时候，其他事物必须等待该事务提交之后，才能操作这行数据。



### 1.7.2 乐观锁

在关系数据库管理系统里，乐观并发控制（又名“乐观锁”，Optimistic Concurrency Control，缩写“OCC”）是一种并发控制的方法。它假设多用户并发的事务在处理时不会彼此互相影响，各事务能够在不产生锁的情况下处理各自影响的那部分数据。在提交数据更新之前，每个事务会先检查在该事务读取数据后，有没有其他事务又修改了该数据。如果其他事务有更新的话，正在提交的事务会进行回滚。

乐观锁（ Optimistic Locking ） 相对悲观锁而言，乐观锁假设认为数据一般情况下不会造成冲突，所以在数据进行提交更新的时候，才会正式对数据的冲突与否进行检测，如果发现冲突了，则让返回用户错误的信息，让用户决定如何去做。

相对于悲观锁，在对数据库进行处理的时候，乐观锁并不会使用<font color='red'>数据库提供的锁机制</font>。一般的实现乐观锁的方式就是记录数据版本。

数据版本：为数据增加的一个版本标识。当读取数据时，将版本标识的值一同读出，数据每更新一次，同时对版本标识进行更新。当我们提交更新的时候，判断数据库表对应记录的当前版本信息与第一次取出来的版本标识进行比对，如果数据库表当前版本号与第一次取出来的版本标识值相等，则予以更新，否则认为是过期数据。



#### 1.7.2.1 乐观锁的优点和不足：

乐观并发控制相信事务之间的数据竞争(data race)的概率是比较小的，因此尽可能直接做下去，直到提交的时候才去锁定，所以不会产生任何锁和死锁。但如果直接简单这么做，还是有可能会遇到不可预期的结果，例如两个事务都读取了数据库的某一行，经过修改以后写回数据库，这时就遇到了问题。





# 2.间隙锁实践



## 2.1 主键索引-间隙锁

### 1.数据准备

```mysql
# 建表
CREATE TABLE `userinfo` (
  `id` int(11) NOT NULL COMMENT '主键',
  `name` varchar(255) DEFAULT NULL COMMENT '姓名',
  `age` int(11) DEFAULT NULL COMMENT '年龄，普通索引列',
  `phone` varchar(255) DEFAULT NULL COMMENT '手机，唯一索引列',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_userinfo_phone` (`phone`) USING BTREE COMMENT '手机号码，唯一索引',
  KEY `idx_user_info_age` (`age`) USING BTREE COMMENT '年龄，普通索引'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


# 插入数据
INSERT INTO `userinfo`(`id`, `name`, `age`, `phone`, `remark`) VALUES (0, 'mayun', 20, '0000', '马云');
INSERT INTO `userinfo`(`id`, `name`, `age`, `phone`, `remark`) VALUES (5, 'liuqiangdong', 23, '5555', '刘强东');
INSERT INTO `userinfo`(`id`, `name`, `age`, `phone`, `remark`) VALUES (10, 'mahuateng', 18, '1010', '马化腾');
INSERT INTO `userinfo`(`id`, `name`, `age`, `phone`, `remark`) VALUES (15, 'liyanhong', 27, '1515', '李彦宏');
INSERT INTO `userinfo`(`id`, `name`, `age`, `phone`, `remark`) VALUES (20, 'wangxing', 23, '2020', '王兴');
INSERT INTO `userinfo`(`id`, `name`, `age`, `phone`, `remark`) VALUES (25, 'zhangyiming', 38, '2525', '张一鸣');
```



### 2.事务A中开启区间排他锁

```mysql
SET autocommit = 0;

SHOW VARIABLES LIKE 'autocommit';

begin;

select * from userinfo where id between 5 and 10 for update;
```



### 3.事务B中插入区间内数据

很明显被阻塞了。

```mysql
begin;

INSERT INTO `userinfo`(`id`, `name`, `age`, `phone`, `remark`) VALUES (7, 'mayun2', 20, '00030', '马云2');
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203231847742.png)

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203231848933.png)



## 2.2 主键索引-死锁



### 2.2.1 事务A删除一个不存在的值 获取间隙锁

```mysql
mysql> select * from userinfo;
+----+--------------+------+-------+--------+
| id | name         | age  | phone | remark |
+----+--------------+------+-------+--------+
|  0 | mayun        |   20 | 0000  | 马云   |
|  5 | liuqiangdong |   23 | 5555  | 刘强东 |
| 10 | mahuateng    |   18 | 1010  | 马化腾 |
| 15 | liyanhong    |   27 | 1515  | 李彦宏 |
| 20 | wangxing     |   23 | 2020  | 王兴   |
| 25 | zhangyiming  |   38 | 2525  | 张一鸣 |
+----+--------------+------+-------+--------+
6 rows in set (0.00 sec)

begin;

delete from userinfo where id=4;
# 获取间隙锁[0,5]
```



### 2.2.2 事务B删除一个不存在的值 获取间隙锁

```mysql
begin;

delete from userinfo where id=3;

# 获取间隙锁[0,5]
```



### 2.2.3 事务A 要往间隙内插入数据

```mysql
INSERT INTO `userinfo`(`id`, `name`, `age`, `phone`, `remark`) VALUES (4, 'weishen', 20, '00030', '韦神');
```

由于事务B已获取到间隙锁，此时事务A插入阻塞

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203231916721.png)



### 2.2.4 事务B 要往间隙内插入数据

出现死锁

```mysql
INSERT INTO `userinfo`(`id`, `name`, `age`, `phone`, `remark`) VALUES (4, 'hantaoer', 20, '00030', '憨桃儿');
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203231925545.png)



## 2.3 普通索引-间隙锁

### 2.3.1 准备数据

```mysql
CREATE TABLE `student2` (
  `id` int NOT NULL COMMENT '主键',
  `name` varchar(255) DEFAULT NULL COMMENT '姓名',
  `age` int DEFAULT NULL COMMENT '年龄，普通索引列',
  PRIMARY KEY (`id`),
  KEY `idx_user_info_age` (`age`) USING BTREE COMMENT '年龄，普通索引'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ;


INSERT INTO `student2` VALUES (1, '绯烟', 20),(5, '凝光', 25),(7, '宵宫', 29),(11, '雷神', 34),(25, '刻晴', 38);
```



### 2.3.2  事务A删除一个不存在的值获取到间隙锁

```mysql
begin;

delete from student2 where age=31;

# 不存在的值就会获取到向上及向下最近的间隙锁。
# 获取到（29，34] 范围的间隙锁
```



### 2.3.3 事务B要往间隙锁内插入数据

说明被阻塞

```mysql
insert into student2 value (6,'芭芭拉',32);
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203232036033.png)



## 2.4 普通索引-死锁

- <font color='red'>**在普通索引列上，不管是何种查询，只要加锁，都会产生间隙锁，这跟唯一索引不一样；**</font>
- <font color='red'>**在普通索引跟唯一索引中，数据间隙的分析，数据行是优先根据普通普通索引排序，再根据唯一索引排序。**</font>
- <font color='red'>**普通索引如果删除不存在的值key，则会在最左 num[i]<key 和 最右num[i+1] > key 充当间隙锁。**</font>
- <font color='red'>**普通索引如果删除索引所在的值num[i]，则会在[num[i-1],nums[i+1]]之间建立间隙锁，很容易两个事务之间出现死锁情况。**</font>



### 2.4.1 事务A删除存在的一个普通索引所对应数据

```mysql
# id 主键索引
# age 普通索引

begin;

delete from student2 where age=34;

# 产生间隙锁(29,38]
```



### 2.4.2 事务B删除存在的一个普通索引所对应数据

```mysql
begin;

delete from student2 where age=29;
# 产生间隙锁(25,34]
```



### 2.4.3 事务A创建普通索引在交际区间内数据

```mysql
insert into student2 value (8,'安柏',30);

# 此时被阻塞
```



### 2.4.4 事务B 创建普通索引在交际区间内数据

```mysql
insert into student2 value (23,'丽莎',31);

# 直接爆死锁
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203232048728.png)



# 3.加锁规则



## 3.1 唯一索引等值查询

- 当索引项存在时，next-key lock 退化为 record lock；
- 当索引项不存在时，默认 next-key lock，访问到不满足条件的第一个值后next-key lock退化成gap lock



## 3.2 唯一索引范围查询

默认 next-key lock，(特殊’<=’ 范围查询直到访问不满足条件的第一个值为止)
