

##                                             存储引擎 - 存储过程 - 触发器 - 事务![file://c:\users\admini~1\appdata\local\temp\tmpfycuue\1.png](https://s2.loli.net/2022/03/01/Tz9bN2G1vg4EJ6f.png)

Mysql逻辑架构图主要分三层：
（1）第一层负责连接处理，授权认证，安全等等 
（2）第二层负责编译并优化SQL 
（3）第三层是存储引擎



### 1、什么是存储引擎

如何存储数据、如何为存储的数据建立索引和如何更新、查询数据等技术的实现方法。相当于mysql内置的文件系统。



注：用户可以根据不同的需求为数据表选择不同的存储引擎

#### 1.1查看支持的引擎（至少需要了解三种以上）

mysql> show engines;
![file://c:\users\admini~1\appdata\local\temp\tmpfycuue\2.png](https://s2.loli.net/2022/03/01/kUw7fhJtsluSPZd.png)

了解：TokuDB，RocksDB，MyRocks
以上三种存储引擎的共同点:压缩比较高,数据插入性能极高
未来技术的新力军newsql：[TiDB](https://docs.pingcap.com/zh/tidb/v4.0)，[PolarDB](https://help.aliyun.com/document_detail/58764.html)

SQL(Structured Query Language)：数据库，指关系型数据库。主要代表：SQL Server、Oracle、MySQL、PostgreSQL。
NoSQL(Not Only SQL)：泛指非关系型数据库。主要代表：MongoDB、Redis、CouchDB、HBASE。
NewSQL：对各种新的可扩展/高性能数据库的简称。主要代表：TiDB，PolarDB。

![file://c:\users\admini~1\appdata\local\temp\tmpfycuue\3.png](https://s2.loli.net/2022/03/01/O5HI4DwFWhn3Jed.png)

#### 1.2、查看存储引擎命令：

mysql>SELECT @@default_storage_engine;

临时生效：
修改存储引擎（仅影响当前会话）:
mysql>set default_storage_engine=myisam;
修改存储引擎（影响所有会话）:
mysql>set global default_storage_engine=myisam;    #此修改可以应用于大多数参数项（可以修改的）
重启之后均失效

永久生效:
写入配置文件
vim /etc/my.cnf
[mysqld]
default_storage_engine=myisam

#### 1.3、innodb引擎

![file://c:\users\admini~1\appdata\local\temp\tmpfycuue\4.png](https://s2.loli.net/2022/03/01/EOrXpkz6QbY5K4s.png)
注：需要理解MVCC和自动故障恢复

#### 1.4、InnoDB 存储引擎 表空间的含义

![file://c:\users\admini~1\appdata\local\temp\tmpfycuue\5.png](https://s2.loli.net/2022/03/01/qmVRL7pDO9a1Szw.png)
共享表空间：--------------------------------------------------------------------

​    Innodb的所有数据保存在一个单独的表空间里面，而这个表空间可以由很多个文件组成， 例如   ibdata1==》 ibdata2==》ibdata3 
​    一个表可以跨多个文件存在，所以表的大小限制不再是文件系统单独文件的大小的限制，而是其自身的限制。
​    从Innodb的官方文档中可以看到，其  表空间的最大限制为64TB，也就是说，Innodb的单表限制基本上也在 64TB 左右了，
​    这个大小是包括这个表的所有索引等其他相关数据。


    所有的数据和索引存放到一个文件中，将有一个非常大的文件，虽然可以把一个大文件分成多个小文件，但是多个表及索引在表空间中混合存储，
    这样对于一个表做了大量删除操作后表空间中将会有大量的空隙，特别是对于统计分析，日志系统这类应用最不适合用共享表空间。

独立表空间：--------------------------------------------------------------------
从5.6起，默认表空间不再使用共享表空间，替换为独立表空间。
    每一个表都将会生成以独立的文件方式来进行存储，每一个表都有一个 .frm 表描述文件，还有一个.ibd文件
    (这个文件包括了单独一个表的数据内容以及索引内容)。
    可以实现单表在不同的 数据库中移动。

​    使用独享表空间来存放Innodb的表的时候，每个表的数据以一个单独的文件来存放，这个时候的单表限制，
​    又变成文件系统的单个文件大小限制了（ ext4  的 16TB ，xfs的64TB）。
​    所以当单表占用空间过大时，存储空间不足，只能从操作系统层面思考解决方法；

#### 1.5、查看默认表空间模式：

mysql>select @@innodb_file_per_table;
返回1则为独立表空间模式
0代表共享表空间模式

修改默认表空间模式：
临时修改：
mysql> set global innodb_file_per_table=1  ;

永久修改：
vim /etc/my.cnf
[mysqld]
innodb_file_per_table=1    
重新载入配置文件生效  reload 

注：修改完之后只影响新创建的表。

#### 1.6、InnoDB 存储结构

1.6.1.物理层面：
innodb相关的文件

*.pem：与密钥相关的文件
ibdata1：系统数据字典信息(统计信息)，UNDO（回滚信息）表空间等数据
ib_logfile0 ~ ib_logfile1: REDO日志文件，事务重做日志文件。
ibtmp1： 临时表空间磁盘位置，存储临时表（排序，分组，多表连接，子查询，逻辑备份等） 
[ib_buffer_pool](https://blog.csdn.net/weixin_30055951/article/details/113639763)：存储缓存区的热数据

innodb表
frm：表结构定义文件 
ibd：表的数据行和索引

myisam表
frm:表结构定义文件
MYD:数据行  #D：data
MYI:索引       #I：index



1.6.2.逻辑层面


![file://c:\users\admini~1\appdata\local\temp\tmpfycuue\6.png](https://s2.loli.net/2022/03/01/t3ebY4fkjwZTKAv.png)

1.段 (segment)
表空间是由不同的段组成的，常见的段有：数据段，索引段，回滚段等等，在 MySQL中，数据是按照B+树来存储，
因此 数据即索引，因此 数据段即为B+树的叶子节点，索引段 为B+树的非叶子节点,

回滚段用于存储undo日志，用于事务失败后数据回滚以及在事务未提交之前通过undo日志获取之前的数据，
在InnoDB1.1版本之前一个InnoDB,只支持一个回滚段，支持1023个并发修改事务同时进行，
在InnoDB1.2版本，将回滚段数量提高到了128个，也就是说可以同时进行128*1023个并发修改事务。

2.区 (extent)
区是由连续页组成的空间，每个区的固定大小为 1MB ,为保证区中页的连续性，InnoDB会一次从磁盘中申请  4~5个区，
在默认不压缩的情况下，一个区可以容纳  64个  连续的页。

3.页 (page)
页是 InnoDB 存储引擎的 最小管理单位，每页大小默认是 16KB  ，
每个  页  使用一个32位 的 int 值来唯一标识，这也正好对应 InnoDB最大  64TB  的存储容量（16Kib * 2^32 = 64Tib）。

4.行(row)
行对应的是表中的行记录，每页存储最多的行记录也是有硬性规定的最多  7992 行  （16KB是页大小）





#### 1.7、查看碎片判断方法：

MySQL 的碎片是否产生，通过查看
mysql> show table status from 表名\G;
这个命令中 Data_free 字段，如果该字段不为 0，则产生了数据碎片。

什么是数据碎片： 当应用程序所需的物理内存不足时，一般操作系统会在硬盘中产生临时交换文件，用该文件所占用的硬盘空间虚拟成内存。虚拟内存管理程序会对硬盘频繁读写，产生大量的碎片，这是产生硬盘碎片的主要原因。 其他如IE浏览器浏览信息时生成的临时文件或临时文件目录的设置也会造成系统中形成大量的碎片。

清理方法：

1.ALTER TABLE 表名 ENGINE=InnoDB；(重建表存储引擎，重新组织数据)	（修改表结构会导致锁表，不能在高峰期使用，需要谨慎）

2.进行一次数据的导入导出

注：在企业中要定时去清理，不是天天清，可以一周或半个月清一次，视业务数据量的变化量而言







### 2、存储过程

#### 2.1   什么是存储过程

大多数 SQL 语句都是针对一个或多个表的单条语句。并非所有的操作都怎么简单。经常会有一个完整 的操作需要多条才能完成。存储过程（Stored Procedure）是在大型数据库系统中，一组为了完成特定功能的 SQL 语句集，存储在数据库中经过第一次编译后再次调用不需要再次编译，用户通过指定存储过程的名字并给出参数（如果该存储过程带有参数）来执行它。存储过程是数据库中的一个重要对象，任何一个设计良好的数据库应用程序都应该用到存储过程。



#### 2.4   定义存储过程

语法：
create procedure 过程名（参数 1 ，参数 2.... ） 
begin
    sql 语句; 
end



注1：Begin…end语句通常出现在存储过程、函数和触发器中，其中可以包含一个或多个语句，每个语句用;号隔开

注2：创建存储过程之前我们必须修改 <font color='red'>mysql 语句默认结束符“ ;  ”</font>否则创建失败，使用 delimiter 可以修改执行符号
delimiter 是分割符的意思，因为 MySQL 默认以";"为分隔符，如果我们没有声明分割符，那么编译器会把存储过程当成 SQL 语句进行处理，则存储过程的编译过程会报错，所以要事先用 “delimiter 关键字” 申明当前段分隔符，这样 MySQL 才会将";"当做存储过程中的代码，不会执行这些代码，用完了之后要把分隔符还原(为了接下来进行其它操作不报错)。

语法：
delimiter 新执行符号   可以是%或//   (退出数据库则重置为默认分隔符“；”)

mysql> use book;
mysql> delimiter %   这样结束符就为% 
mysql> create procedure selCg()
\- > begin
\- > select * from category; 

\- > select * from books; 

\- > end %

#### 2.5   调用存储过程

语法：
call 过程名（参数 1，参数 2）; 
mysql> call selCg() %
![file://c:\users\admini~1\appdata\local\temp\tmpfycuue\7.png](https://s2.loli.net/2022/03/01/ZPyOWmFv9rnDKC4.png)

#### 2.6   存储过程参数类型

##### 1． In 参数 传入参数

特点：读取外部变量值，且有效范围仅限存储过程内部。 
例子：

```
mysql> use book;    
mysql> delimiter //
mysql> create procedure xx(in abc int)
begin
select abc; 		#此时abc是参数变量，相当于select @@server_id
set abc=2; 
select abc;
end;
//
```

mysql> use book;    
mysql> delimiter //
mysql> create procedure xx(in abc int)
\- > begin
\- > select abc; 
\- > set abc=2; 
\- > select abc;
-> end;
-> //
mysql> call xx(123) //
![file://c:\users\admini~1\appdata\local\temp\tmpfycuue\8.png](https://s2.loli.net/2022/03/01/cSlH5veTUs1fQo8.png)
 mysql> delimiter ;                 #使用完马上恢复默认的

##### 2． mysql 定义变量方法

语法格式：   set @字段名=值

查看变量：	select @字段名

例如     set @num=1
mysql> set @y=1;         #局部变量
mysql> select @y;
![file://c:\users\admini~1\appdata\local\temp\tmpfycuue\9.png](https://s2.loli.net/2022/03/01/73TyAOi14SJjBYp.png)
直接写数值传入值：
mysql> call xx(6);

![file://c:\users\admini~1\appdata\local\temp\tmpfycuue\10.png](https://s2.loli.net/2022/03/01/jNYK35XOpEJi8IQ.png)
例：定义一个存储过程 getOneBook ，当输入某书籍 id 后，可以调出对应书籍记录

```
mysql>delimiter //
mysql> create procedure getOneBook(in b int, c int)        #多个参数
begin
select   bid,bname,price from books where bId=b; 
end //
Query OK, 0 rows affected (0.01 sec)

mysql>  call getOneBook(1)//			#传参数时也需要对应的个数
ERROR 1318 (42000): Incorrect number of arguments for PROCEDURE text.getOneBook; expected 2, got 1
mysql>  call getOneBook(1,10)//
+-----+-----------------------+-------+
| bid | bname                 | price |
+-----+-----------------------+-------+
|   1 | 网站制作直通车        | 10000 |
+-----+-----------------------+-------+
1 row in set (0.00 sec)

Query OK, 0 rows affected (0.00 sec)
```

 

##### 3． Out参数 传出参数 (针对于变量)

特点：不读取外部变量值，在存储过程执行完毕后保留新值，传到外部变量。 

```
mysql>set @abc=789
Query OK, 0 rows affected (0.00 sec)

mysql> select @abc
    -> //
+------+
| @abc |
+------+
|  789 |
+------+
1 row in set (0.00 sec)



mysql> delimiter //
mysql> create procedure a2(out p_out int)
begin
select p_out; 
set p_out=2; 
select p_out; 
end;
//
Query OK, 0 rows affected (0.00 sec)

mysql> delimiter ;   

mysql> call a2(66)//
ERROR 1414 (42000): OUT or INOUT argument 1 for routine text.a2 is not a variable or NEW pseudo-variable in BEFORE trigger
mysql> set @p_out=66//
Query OK, 0 rows affected (0.00 sec)

mysql> call a2(@p_out)//
+-------+
| p_out |
+-------+
|  NULL |
+-------+
1 row in set (0.00 sec)

+-------+
| p_out |
+-------+
|     2 |
+-------+
1 row in set (0.00 sec)

Query OK, 0 rows affected (0.00 sec)

mysql> select @p_out//		#把存储过程里得出的值传出存储过程外
+--------+
| @p_out |
+--------+
|      2 |
+--------+
1 row in set (0.00 sec)
```




In 传入参数,是外部将值传给存储过程来使用的，而 out 传出参数是为了让存储过程的执行结果回传
给调用他的程序来使用的。
再举个例子

```
mysql> delimiter //
mysql> create procedure demo(out pa varchar(200)) 
begin
select bname into  @pa from books where bid=3; 		#相当于pa=`ls /opt`
select @pa as '图书名';
end //

mysql> call demo(@ljr)//		#随便调用一个变量，都不影响结果
+-----------------------------+
| 图书名                      |
+-----------------------------+
| 网络程序与设计－asp         |
+-----------------------------+
1 row in set (0.00 sec)

Query OK, 0 rows affected (0.00 sec)


mysql> call demo(@pa)//		
+-----------------------------+
| 图书名                      |
+-----------------------------+
| 网络程序与设计－asp         |
+-----------------------------+
1 row in set (0.00 sec)

Query OK, 0 rows affected (0.00 sec)


```



##### 4． Inout 参数

特点：读取外部变量，在存储过程执行完后保留新值<类似银行存款 >
传进来，又传出去。 

```
mysql> delimiter //
mysql> create procedure a3(inout p_inout int)
begin
select p_inout; 
set p_inout=2; 
select p_inout; 
end;
// 

mysql> select @p_inout//
+----------+
| @p_inout |
+----------+
| NULL     |
+----------+
1 row in set (0.00 sec)

mysql> call a3(@p_inout)//
+---------+
| p_inout |
+---------+
|    NULL |
+---------+
1 row in set (0.00 sec)

+---------+
| p_inout |
+---------+
|       2 |
+---------+
1 row in set (0.00 sec)

Query OK, 0 rows affected (0.00 sec)

mysql> set @p_inout=88
    -> //
Query OK, 0 rows affected (0.00 sec)

mysql> select @p_inout//
+----------+
| @p_inout |
+----------+
|       88 |
+----------+
1 row in set (0.00 sec)

mysql> call a3(@p_inout)//
+---------+
| p_inout |
+---------+
|      88 |
+---------+
1 row in set (0.00 sec)

+---------+
| p_inout |
+---------+
|       2 |
+---------+
1 row in set (0.00 sec)

Query OK, 0 rows affected (0.00 sec)

mysql> select @p_inout//
+----------+
| @p_inout |
+----------+
|        2 |
+----------+
1 row in set (0.00 sec)
```

​             

5． 不加参数的情况
如果在创建存储过程时没有指定参数类型，则需要在调用的时候指定参数值
mysql> create table t2(id int(11));              #创建表
mysql> delimiter //
mysql> create procedure t2(n1 int) 
\- > begin
\- > set @x=0;
\- > repeat set @x=@x+1;     #做了循环 
\- > insert into t2 values(@x);
\- > until @x>n1
\- > end repeat; 
\- > end;
\- > //              
mysql> delimiter ;
mysql> call t2(5);           #循环 5 次
mysql> select * from t2;
![file://c:\users\admini~1\appdata\local\temp\tmpfycuue\16.png](https://s2.loli.net/2022/03/01/YmATbRCaKWZDoQ9.png)

#### 2.7   存储过程变量的使用

MySQL 中使用 declare 进行变量定义
变量定义：DECLARE variable_name [,variable_name...] datatype [DEFAULT value]; 
    `datatype` 为 MySQL 的数据类型，如:int, float, date, varchar(length)

declare语句通常用来声明本地变量、游标、条件或者handler

declare的顺序也有要求，通常是先声明本地变量，再是游标，然后是条件和handler

<font color='red'>declare语句只允许出现在begin … end语句中而且必须出现在第一行</font>

声明后的变量可以通过select … into @pa进行赋值，或者通过set语句赋值，或者通过定义游标并使用fetch … into var_list赋值



变量赋值可以在不同的存储过程中继承 

例：

```
delimiter //
create procedure sp2(v_sid int) 
begin
declare  xTypeId int;
declare  xprice int;
select  bTypeId, price into xTypeId, xprice from books where bid=v_sid; 
select  xTypeId,xprice; 
END;
//


mysql> call sp1(1)//
+---------+--------+
| xTypeId | xprice |
+---------+--------+
|       2 |     34 |
+---------+--------+
1 row in set (0.00 sec)

Query OK, 0 rows affected (0.00 sec)
```



例：	

```
delimiter //
create procedure decl1() 
begin
declare name varchar(200);							
set @name=(select bName from books where bId=12); 
select @name;
end//


mysql> call decl//
+-------------------------------+
| @name                         |
+-------------------------------+
| Fireworks 4网页图形制作         |
+-------------------------------+
1 row in set (0.00 sec)

Query OK, 0 rows affected (0.00 sec)
```












#### 2.8   存储过程语句的注释

写注释是个利人利己的事情。便于理解维护 MySQL 注释有两种风格
“--“：单行注释
“/* …..*/”:一般用于多行注释
例子：
![file://c:\users\admini~1\appdata\local\temp\tmpfycuue\18.png](https://s2.loli.net/2022/03/01/2IUaG9idKJDrteP.png)
--执行此脚本时，需要先创建好一个库 
例：

```
delimiter //
create procedure sp1(in p int) comment 'insert into a int value' 	#comment后 注释
begin
/*定义一个变量 */ 
declare v1 int;
/* 将输入参数的值赋给变量 */ 
set v1 = p;
/* 执行插入操作 */
insert into test(id) values(v1); 
end
//
/* 调用这个存储过程 */ 
call sp1(1)//
/* 去数据库查看调用之后的结果 */ 
select * from test//
```

 





### 3、函数

数据库里函数分[内部函数](https://www.runoob.com/mysql/mysql-functions.html)与自定义函数，可以理解为liunx的系统变量与自定义变量

#### 3.1.语法

```
create function 函数名(参数名 参数类型,...) 
returns 返回值类型 
begin
 函数体 #函数体中肯定有 return 语句 
end
```

用户定义函数中，用returns 子句指定该函数返回值的数据类型，return用于返回具体的值/值变量；returns子句只能对function做指定，对函数而言这是强制的。



#### 3.2.调用函数

语法：

SELECT 函数名(参数列表) 



例：

```
mysql> delimiter //
mysql> create function b1(edg int) 
returns int
begin
update books set price=1000 where bId=edg;
select count(*) into @a from books where bId>edg;
return @a;
end
 //
 ERROR 1418 (HY000): This function has none of DETERMINISTIC, NO SQL, or READS SQL DATA in its declaration and binary logging is enabled (you *might* want to use the less safe log_bin_trust_function_creators variable)

注：二进制日志的一个重要功能是用于主从复制，而存储函数有可能导致主从的数据不一致。所以当开启二进制日志后，参数log_bin_trust_function_creators就会生效，限制存储函数的创建、修改、调用。

解决方法：
方法1：
set global log_bin_trust_function_creators=1;
方法2：
vim /etc/my.cnf
global log_bin_trust_function_creators=1

 
Query OK, 0 rows affected (0.00 sec) 
mysql> delimiter ;
mysql> select b1(1);
+-------+
| b1(1) |
+-------+
|    43 |
+-------+
1 row in set (0.00 sec)
mysql> select * from books where bId=1;
+-----+-----------------------+---------+--------------------------+-------+------------+--------+------------+
| bId | bName                 | bTypeId | publishing               | price | pubDate    | author | ISBN       |
+-----+-----------------------+---------+--------------------------+-------+------------+--------+------------+
|   1 | 网站制作直通车          | 2        | 电脑爱好者杂志社           |  1000 | 2004-10-01 | 苗壮    | 7505380796 |
+-----+-----------------------+---------+--------------------------+-------+------------+--------+------------+
1 row in set (0.00 sec)

```



#### 3.3.对比过程和函数

![image-20220915030032876](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202209150300936.png)



此外，**存储函数可以放在查询语句中使用，存储过程不行**。反之，存储过程的功能更加强大，包括能够执行对表的操作（比如创建表，删除表等）和事务操作，这些功能是存储函数不具备的



#### 3.4.存储过程流程控制语句

MySQL支持if,case,iterate,leave,loop,while,repeat语句作为存储过程和函数中的流程控制语句，另外return语句也是函数中的特定流程控制语句





##### 1.变量作用域

内部的变量在其作用域范围内享有更高的优先权，当执行到end。变量时，内部变量消失，此时已经在其作用域外，变量不再可见了，因为在存储过程外再也不能找到这个申明的变量，但是你可以通过 out 参数或者将其值指派给会话变量来保存其值。
mysql > DELIMITER // 
两层嵌套

```
mysql > CREATE PROCEDURE proc3() 
begin
declare x1 varchar(5) default 'outer'; 
begin
declare x1 varchar(5) default 'inner';
select x1; 
end;
select x1; 
end;        
//
mysql > DELIMITER ;
mysql> call proc3()//
```



##### 2.条件语句

（1） if-then -else 语句 

```
mysql> select * from student1//
+------+-------+------+
| id   | name  | math |
+------+-------+------+
|    1 | zhang | 33   |
|    2 | lin   | 42   |
|    3 | xiao  | 65   |
|    4 | ming  | 87   |
+------+-------+------+
4 rows in set (0.00 sec)


mysql> delimiter //
mysql> create procedure proc2(in parameter int) 
begin
  declare var int;
  set var=parameter+1; 
    if var=0 then
    insert into student1 values(5,'ljr',68); 
    end if;
      if parameter=0 then   
      update student1 set math=math+1 where id=1; 
      else
      update student1 set math=math+2 where id=1; 
      end if;
end; 
//

mysql> call proc2(0)//
Query OK, 1 row affected (0.00 sec)

mysql> select * from student1//
+------+-------+------+
| id   | name  | math |
+------+-------+------+
|    1 | zhang | 34   |
|    2 | lin   | 42   |
|    3 | xiao  | 65   |
|    4 | ming  | 87   |
+------+-------+------+
4 rows in set (0.00 sec)

mysql> call proc2(2)//
Query OK, 1 row affected (0.00 sec)

mysql> select * from student1//
+------+-------+------+
| id   | name  | math |
+------+-------+------+
|    1 | zhang | 36   |
|    2 | lin   | 42   |
|    3 | xiao  | 65   |
|    4 | ming  | 87   |
+------+-------+------+
4 rows in set (0.00 sec)

mysql> call proc2(-1)//
Query OK, 1 row affected (0.00 sec)

mysql> select * from student1//
+------+-------+------+
| id   | name  | math |
+------+-------+------+
|    1 | zhang | 38   |
|    2 | lin   | 42   |
|    3 | xiao  | 65   |
|    4 | ming  | 87   |
|    5 | ljr   | 68   |
+------+-------+------+
5 rows in set (0.00 sec)

```



（2） case ... end case 语句  

```
mysql> delimiter //
mysql> create procedure proc3 (in parameter int) 
begin
declare var int;
set var=parameter+1; 
case var
when 2 then
insert into student1 values(6,'a1',11); 
when 3 then
insert into student1 values(7,'a2',12); 
else
insert into student1 values(8,'a3',13); 
end case;
end; 
//
```

##### 3.循环语句

1） while  ···· end while 

```
mysql> delimiter //
mysql> create procedure proc4() 
begin
declare var int; 
set var=0;
while var<6 do			#当条件返回为true时，则循环执行end while前的语句，直到条件的结果返回为false
insert into student1 values(var,'a4',18); 
set var=var+1;
end while; 
end;          
//

```



2） repeat. . . end repeat
执行操作后检查结果，而 while 则是执行前进行检查。 

```
mysql> create procedure proc5()
begin
declare v int; 
set v=0;
repeat						#repeat都会搭配until
insert into t values(v,'a5',28); 
set v=v+1;
until v>=5 		#一直重复执行直到until条件满足
end repeat; 
end;
//  
```




3） loop  ·····end loop
loop 循环不需要初始条件，这点和while 循环相似，同时和 repeat 循环一样不需要结束条件,。

```
mysql> delimiter //
mysql> create procedure proc6 () 
begin
declare v int; 
set v=0;
	loop_lable:loop							
	insert into student1 values(v,'a6',38); 
	set v=v+1;
	if  v>=5 then      
	leave loop_lable;
	end if;     
end loop; 
end;
//        
```




```
delimiter //
create procedure proc6(in p1 int, out p2 int) 
begin
label1: loop					#标签label可以加在begin…end语句以及loop, repeat和while语句
set p1 = p1 + 1;
if p1 < 10 then 
iterate label1; #语句中通过iterate和leave来控制流程，iterate表示返回指定标签位置，leave表示跳出标签
else
leave label1;
end if;			
end loop label1;
set p2=p1;
end;
//

注：Iterate语句仅出现在loop,repeat,while循环语句中，其含义表示重新开始此循环；Leave语句表明退出指定标签的流程控制语句块，通常会用在begin…end，以及loop,repeat,while的循环语句中


mysql> call proc6(1,@a)//
Query OK, 0 rows affected (0.00 sec)

mysql> select @a//
+------+
| @a   |
+------+
|   10 |
+------+
1 row in set (0.00 sec)
```



#### 课堂练习

创建一个存储过程proc1，将10万行如下格式的测试数据插入到students表中，数据中只有sid是递增的，其余字段值都是固定的			（两种方法）

sid,sname,gender,dept_id

（1，’mike’,1,1),

（2,’mike’,1,1),

（3,’mike’,1,1),

…….

（100000,’mike’,1,1)



```
CREATE TABLE ab ( id int(10),name char(20),gender int(10),dept int(10) );

Delimiter //
Create procedure proc1()
Begin
Declare n int default 1;
while n<=100000 do
Insert into students values(n, 'mike' , 1,1);
Set n=n+1;
End while;
End;
//

mysql> delimiter //
mysql> create procedure book3(n1 int) 
begin  
set @x=0; 
repeat set @x=@x+1; 
insert into ab values(@x,'mike',1,1); 
until @x>n1-1 
end repeat; 
end; 
// 



delimiter //
Create procedure proc1_2()
begin
Declare n int default 1;
start_label: loop
if n>100000 then
leave start_label; 
End if;
insert into students values(n, 'mike' , 1,1);
set n=n+1;
end loop;
End;
//
Delimiter ;

```



在第1题的基础上，创建另一个存储过程proc2，插入10万行数据到students表中，但要求gender字段在0和1之间随机，dept_id在1~3这三个整数之间取随机，sname字段固定是'mike'          

 提示：    0和1之间随机需要使用系统函数，1~3这三个整数之间取随机需要使用系统函数作运算

```
Delimiter //
Create procedure proc2()
Begin
Declare n int default 1;
Declare v_gender_id int; 
Declare v_dept_id int; 
while n<=100000 do
Set v_gender_id=round(rand());
Set v_dept_id=floor(rand()*3+1);
Insert into students values(n, 'mike' , v_gender_id,v_dept_id);
Set n=n+1;
End while;
End;
//
delimiter ;
```





创建一个函数，输入参数为学生学号sid，函数返回对应学生的平均成绩

```
Delimiter //
Create function func1(v_sid int) 
Returns int
Begin
Select avg(score) into @x from score where sid=v_sid; 
Return @x;
End;
//
delimiter ;
```





创建一个函数，输入参数是老师的id，函数返回该老师所教授的课程数量，并将这些学习这些课程的每个学生如果成绩不及格，把学生的sid和对应课程名字、成绩insert到表A中，如果成绩及格，把学生的sid和对应的课程名字、成绩insert到表B中

提示：inner join 

```
Delimiter //
Create function func2(v_teacher_id int) 
Returns int
Begin
Declare n_course int; 
Select count(*) into n_course from course where teacher_id=v_teacher_id; 

Insert into A select a.sid,b.course_name,a.score From score a inner join course b on a.course_id=b.id Where b.teacher_id=v_teacher_id and a.score<60;

Insert into B select a.sid,b.course_name,a.score From score a inner join course b on a.course_id=b.idWhere b.teacher_id=v_teacher_id and a.score>=60;

Return n_course; 
End;
//
Delimiter ;
```







#### 2.10   查看存储过程

1． 查看存储过程内容
mysql> show create procedure demo \G
![file://c:\users\admini~1\appdata\local\temp\tmpfycuue\20.png](https://s2.loli.net/2022/03/01/ZOYV2mgSfLTBN4Q.png)
2． 查看存储过程状态
mysql> show procedure status \G      #查看所有存储过程
![file://c:\users\admini~1\appdata\local\temp\tmpfycuue\21.png](https://s2.loli.net/2022/03/01/ReTMzdqHuEUQZ1a.png)

#### 2.11   修改存储过程

使用alter 语句修改 （一般不建议这样改）
ALTER {PROCEDURE | FUNCTION} sp_name [characteristic ...] 
    characteristic:
    { CONTAINS SQL | NO SQL | READS SQL DATA | MODIFIES SQL DATA } 
    | SQL SECURITY { DEFINER | INVOKER }
    | COMMENT 'string'

sp_name 参数表示存储过程或函数的名称 
characteristic 参数指定存储函数的特性
CONTAINS SQL 表示子程序包含 SQL 语句，但不包含读或写数据的语句； 
NO SQL 表示子程序中不包含 SQL 语句
READS SQL DATA 表示子程序中包含读数据的语句     
MODIFIES SQL DATA 表示子程序中包含写数据的语句
SQL SECURITY { DEFINER | INVOKER }指明谁有权限来执行 
DEFINER 表示只有定义者自己才能够执行
INVOKER 表示调用者可以执行     
COMMENT 'string'是注释信息。
\--   
/**/
就是说只能改名字和定义，不能改里面的内容。一般都是要删了重新建 
通过第三方工具 修改

#### 2.12   删除存储过程

语法：
方法一：DROP   PROCEDURE  过程名 
mysql> drop procedure p_inout;
方法二：DROP PROCEDURE  IF   EXISTS 存储过程名
这个语句被用来移除一个存储程序。
不能在一个存储过程中删除另一个存储过程，只能调用另一个存储过程



#### 2.13 用 navicat 维护 存储过程

![file://c:\users\admini~1\appdata\local\temp\tmprbyf14\1.png](https://s2.loli.net/2022/03/01/cnhUPrzjC5QLf2a.png)


![image-20220426155942367](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202204261559424.png)


![file://c:\users\admini~1\appdata\local\temp\tmprbyf14\3.png](https://s2.loli.net/2022/03/01/xtkAq3HNMB5VYWG.png)


![file://c:\users\admini~1\appdata\local\temp\tmprbyf14\4.png](https://s2.loli.net/2022/03/01/jsGvAFdnXxhCqVW.png)


![file://c:\users\admini~1\appdata\local\temp\tmprbyf14\5.png](https://s2.loli.net/2022/03/01/Bl251gDSrKPdR9h.png)







#### 2.14   为什么要使用存储过程   （优点）

1． 增强 SQL 语言的功能和灵活性：存储过程可以用控制语句编写，有很强的灵活性，可以完成复杂的判断和较复杂的运算。
2． 标准组件式编程：存储过程被创建后，可以在程序中被多次调用，而不必重新编写该存储过程的 SQL 语句。而且数据库专业人员可以随时对存储过程进行修改，然后模块之间可以重复使用 ，在减少开发工作量的同时，还能保证代码的结构清晰。。

3． 减少网络流量：针对同一个数据库对象的操作（如查询、修改），如果这一操作所涉及的SQL语句被组织进存储过程，那么当在客户计算机上调用该存储过程时，网络中传送的只是该调用语句，从而大大减少网络流量并降低了网络负载。

4.良好的封装性。在进行相对复杂的数据库操作时，原本需要使用一条一条的 SQL 语句，可能要连接多次数据库才能完成的操作，现在变成了一次存储过程，只需要 连接一次即可 



#### 2.15   为什么不使用存储过程 (缺点)

1. 可移植性差，存储过程不能跨数据库移植，比如在 MySQL、Oracle 和 SQL Server 里编写的存储过程，在换成其他数据库时都需要重新编写。
2. 对于简单的 SQL 语句，存储过程没什么优势
3. 如果只有一个用户使用数据库，那么存储过程对安全也没什么影响
4. 团队开发时需要先统一标准，否则后期维护成本大
5. 在大并发量访问的情况下，不宜写过多涉及运算的存储过程
6. 业务逻辑复杂时，特别是涉及到对很大的表进行操作的时候，不如在前端先简化业务逻辑









### 4、游标

什么是游标

由于 SQL 语言是面向集合的语句，它每次查询出来都是一堆数据的集合，没有办法对其中一条记录进行单独的处理。如果要对每条记录进行单独处理就需要游标。

#### 1、声明游标

```
DECLARE 游标名字 CURSOR FOR SELECT 语句；
```

SELECT 语句就是正常的查询语句，例如：SELECT id,age FROM table;		

游标的声明必须在变量和条件声明之后，在handler声明之前



#### 2、打开游标

```
OPEN 游标名字;
```

在打开游标之前，游标定义的 SQL 语句是不执行的。

#### 3、取出记录

```
FETCH 游标名字 INTO 变量1[,变量2,变量3];1.
```

将当前的记录数据存入变量。

当 FETCH 没有找到记录时会抛出异常，异常的定义需要下面的 HANDLER FOR 语句。

声明游标语句中的 SELECT 如果有多个字段，INTO 后面需要多个变量进行接收。

#### 4、设置结束条件

```
DECLARE 处理种类 HANDLER FOR 异常的类型 异常发生时的处理
```

这个语句的作用是指定一个条件，告诉程序所有数据已经循环完毕，可以结束了。由于游标是使用 WHILE 循环进行每条数据的读取，就需要给 WHILE 一个结束条件。

**处理种类：**可以是， EXIT 代表退出声明此handler的begin…end语句块。CONTINUE 代表继续执行该存储过程或函数。

**异常的类型：**一般指定为 NOT FOUND ，意思是没有找到任何数据。也可以有以下两种形式

• Mysql_err_code表示MySQL error code的整数

• SQLSTATE sqlstate_value表示MySQL中用5位字符串表达的语句状态

![img](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202209150421143.jpeg)

**异常发生时的处理：**当异常发生时需要做的事情，可以是一个简单SQL语句，也可以是begin…end组成的多个语句

#### 5、关闭游标

```
CLOSE 游标名字;
```

如果关闭一个未打开的游标，则MySQL会报错

如果在存储过程和函数中未使用此语句关闭已经打开的游标，则游标会在声明的begin…end语句块执行完之后自动关闭



例：

```
CREATE PROCEDURE sp_abc()
BEGIN
 -- 定义一个临时存放使用逗号分割的所有客户名字的变量
 DECLARE result VARCHAR(1000) DEFAULT '';

 -- 定义一个 flag 变量，用来判断记录是否全部取出，我这里设置，1代表没有记录，0代表还有记录。
 DECLARE flag INT DEFAULT 0;

 -- 定义一个存放当前记录客户名字的临时变量
 DECLARE tmp VARCHAR(50) DEFAULT '';

 -- 定义游标，在打开游标之前，这个SELECT语句是不执行的
 DECLARE cur CURSOR FOR SELECT `name` FROM kefu;

 -- 设置结束条件，当没有记录的时候抛出 NOT FOUND 异常，并设置 flag 等于1
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag = 1;

 -- 打开游标
 OPEN cur;
 
 -- 定义循环，从游标中一条一条的取出记录
 WHILE flag != 1 DO

  -- 将 SELECT 语句当前行中的 name 字段保存到 tmp 变量中
  -- 如果 SELECT 指定多个字段，INTO 后面就需要跟多个变量，例如：tmp1,tmp2，每个变量单独存放一个字段的值
  FETCH cur INTO tmp;

  -- 这里需要判断一下，因为上面定义异常发生后继续处理 CONTINUE ，当 FETCH 发生异常时 tmp 没有得到正确的值。所以 IF 内的语句块不应该被执行。
  IF flag != 1 THEN
   SET result = CONCAT_WS(',',result ,tmp);
  END IF;

 END WHILE;

 -- 关闭游标
 CLOSE cur;

 -- 最后你可以根据你的情况来处理这个 result 变量了
 SELECT result;

END;
```



例：

```
CREATE PROCEDURE curdemo()
BEGIN
DECLARE done INT DEFAULT FALSE;
DECLARE a CHAR(16);
DECLARE b, c INT;
DECLARE cur1 CURSOR FOR SELECT id,data FROM test.t1;
DECLARE cur2 CURSOR FOR SELECT i FROM test.t2;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE; 
OPEN cur1;
OPEN cur2; 
read_loop: LOOP
FETCH cur1 INTO a, b;
FETCH cur2 INTO c;
IF done THEN
LEAVE read_loop; 
END IF;
IF b < c THEN
INSERT INTO test.t3 VALUES (a,b);
ELSE
INSERT INTO test.t3 VALUES (a,c);
END IF;
END LOOP; 
CLOSE cur1;
CLOSE cur2;
END;
```



#### 课堂练习

用游标的方法实现创建一个函数，输入参数是老师的id，函数返回该老师所教授的课程数量，并将这些学习这些课程的每个学生

如果成绩不及格，把学生的sid和对应课程名字、成绩insert到表A中，如果成绩及格，把学生的sid和对应的课程名字、成绩insert到表B中

```mysql
delimiter //
create function func3(v_teacher_id int) 
returns int
begin
  declare n_course int; 
  declare v_sid int default null;
  declare v_course_name varchar(60);
  declare v_score int; 
  declare cur1 cursor for select a.sid,b.course_name,a.score from score a inner join course b on a.coure_id=b.id where b.teacher_id=v_teacher_id; 

declare continue handler for not found set v_sid=null;

select count(*) into n_course from course where teacher_id=v_teacher_id; 

open cur1;

fetch cur1 into v_sid,v_course_name,v_score; 

while v_sid is not null do
if v_score<60 then
insert into A select v_sid,v_course_name,v_score; 
else
insert into B select v_sid,v_course_name,v_score; 
end if;
end while;

close cur1;
return n_course; 
end;
//
delimiter ;
```







### 5、触发器

什么是触发器： 
触发器是一种特殊的存储过程，它在插入，删除或修改特定表中的数据时触发执行，它比数据库本身标准的功能有更精细和更复杂的数据控制能力

#### 5.1   触发器的作用

1.安全性
可以基于数据库的值使用户具有操作数据库的某种权利。
可以基于时间限制用户的操作，例如不允许下班后和节假日修改数据库数据。
可以基于数据库中的数据限制用户的操作，例如不允许股票的价格的升幅一次超过 10%。

2.审计
可以跟踪用户对数据库的操作 
审计用户操作数据库的语句
把用户对数据库的操作写入审计表

3.实现复杂的数据完整性规则
实现非标准的数据完整性检查和约束。触发器可产生比规则更为复杂的限制。与规则不同，触发器可以引用列或数据库对象。
例如，触发器可回退任何企图吃进超过自己保证金的期货。

4.实现复杂的非标准的数据库相关完整性规则 触发器可以对数据库中相关的表进行连环更新。
例如，在 auths 表 author_code 列上的删除触发器可导致相应删除在其它表中的与之匹配的行。 
触发器能够拒绝或回退那些破坏相关完整性的变化，取消试图进行数据更新的事务

5.实时同步地复制表中的数据

6.自动计算数据值
如果数据的值达到了一定的要求，则进行特定的处理。
例如，如果公司的帐号上的资金低于 5 万元则立即给财务人员发送警告数据

#### 5.2  创建触发器

语法：
create   trigger 触发器名称   触发的时机   触发的动作   on 表名 for each row 触发器状态。 

参数说明：
触发器名称：自己定义
触发的时机： before /after   在执行动作之前还是之后
触发的动作：指的激发触发程序的语句类型<insert ,update,delete>
each row ：操作每一行我都监控着 
触发器状态：可以是一个简单SQL语句，也可以是begin…end组成的多个语句



触发器创建语法四要素：

1. 监视地点(table)

2. 监视事件(insert/update/delete)

3. 触发时间(after/before)

4. 触发事件(insert/update/delete)

   例：当 category 表中，删除一个 bTypeid=3 的图书分类时，books 表中也要删除对应分类的图书信息（类似级联删除）							#用小表驱动大表
   mysql> use book;

在 category 执行删除前，查看 bTypeId=3 的图书分类：
mysql> select bName,bTypeId from books where bTypeId=3;


![file://c:\users\admini~1\appdata\local\temp\tmpl7bpge\1.png](https://s2.loli.net/2022/03/02/OvZzpK6VF2fyleX.png) 

创建触发   （实际跟创建存储过程一样，关键字换而已） 
mysql> delimiter //
mysql> create trigger delCategory after delete on category for each row
\- > begin
\- > delete from books where bTypeId=3; 
\- > end
\- > //
删除 bTypeId=3 的记录
mysql> delete from category where bTypeId=3;//
查看：是否还有 bTypeId=3 的图书记录。可以看出已经删除。          
mysql> select bName,bTypeId from books where bTypeId=3;
![file://c:\users\admini~1\appdata\local\temp\tmpl7bpge\2.png](https://s2.loli.net/2022/03/02/rga8K91oiYqjkRU.png) 



#### 5.3 OLD与NEW字段

触发器触发之后要执行的一个或多个语句，在内部可以引用涉及表的字段，OLD.col_name表示行数据被修改或删除之前的字段数据，NEW.col_name表示行数据被插入或修改之后的字段数据

```
mysql> select * from student2 where id=1;
+------+------+------+-------+
| id   | name | sex  | abc   |
+------+------+------+-------+
|    1 | zhang| man  | zhang |
+------+------+------+-------+
1 row in set (0.00 sec)


delimiter //
create trigger simple
after update
on student2 for each row
begin
set @name1=old.name;
set @name2=new.name;
set @sex1=old.sex;
set @sex2=new.sex;
end;
//
delimiter ; 
mysql> update student2 set name='abc',sex=1 where id=1; 
mysql> select @id,@id2,@sex1,@sex2//
+-------+------+-------+-------+
|@name1 |@name2| @sex1 | @sex2 |
+-------+------+-------+-------+
| zhang | abc  | man   | 1     |
+-------+------+-------+-------+
1 row in set (0.00 sec)

```





#### 5.4   查看触发器

1.查看创建过程
mysql> show create trigger delCategory\G
![file://c:\users\admini~1\appdata\local\temp\tmpl7bpge\3.png](https://s2.loli.net/2022/03/02/t6vXs1WzV2gCIBT.png) 

2.查看触发器详细信息
mysql> show triggers\G       #查看所有
![file://c:\users\admini~1\appdata\local\temp\tmpl7bpge\4.png](https://s2.loli.net/2022/03/02/JrqhVKN13j9UTy4.png) 
3.查看系统triggers表
mysql>select  TRIGGER_NAME  from information_schema.`TRIGGERS`;

#### 5.5   删除触发器

语法：
drop trigger   触发器名称;
mysql> drop trigger delCategory;//
![file://c:\users\admini~1\appdata\local\temp\tmpl7bpge\5.png](https://s2.loli.net/2022/03/02/wVlDBMtQ4scCvm1.png) 



#### 练习：

在score表上创建一个触发器，当有新的数据插入时，在score_bak表里记录新插入的数据的所有字段信息，并用tstamp字段标注数据的插入时间

```
Delimiter //
Create trigger trig1
after insert on score
For each row
Begin
Insert into score_bak(Sid,course_id,score,tstamp) 
values(new.sid,new.course_id,new.score,now());
End;
//
Delimiter ;
```



 在score表上创建一个触发器，当有新的数据插入时，在score_avg表里记录对应学生的所有课程（score表）的平均成绩（注意，如果在score_avg表里已经有了学生的记录，需要update）

```
Delimiter //
Create trigger trig2
After insert on score
For each row
Begin
Declare n int; 
Select count(*) into n from score_avg where sid=new.sid; 
If n=1 then
update score_avg set avg_score=(select avg(score) from score where sid=new.sid) where 
sid=new.sid; 
Else 
insert into score_avg  select sid,avg(score) from score where sid=new.sid group by sid; 
End if;
End;
//
Delimiter ;
```



### 6、 事务

#### 6.1   什么是事务

数据库事务：（database transaction）: <font color='red'>事务是由一组 SQL 语句组成的逻辑处理单元，要不全成功要不全失败。</font>
MYSQL 中只有 INNODB 和 BDB 类型的数据表才能支持事务处理，其他的类型都不支持！ 
事务处理：可以确保非事务性单元的多个操作都能成功完成，否则不会更新数据资源。
<font color='red'>数据库默认事务是自动提交的</font>， 也就是发一条 SQL 它就执行一条。如果想多条 SQL 放在一个事务中执行，则需要使用事务进行处理。当我们开启一个事务，并且没有提交，mysql 会自动回滚事务。或者 我们使用 rollback 命令手动回滚事务。
优点：通过将一组操作组成一个事务，执行时，要么全部成功，要么全部失败的单元。
使程序更可靠，简化错误恢复。 
例：
A 汇款给 B 1000 元 

A 账户- 1000
B 账户+1000
以上操作对应数据库为两个 update。这两个操作属于一个事务。否则，可能会出现 A 账户钱少了，B 账户钱没增加的情况。

#### 6.2事务的4个特性（重点）

1.<font color='red'>原子性（Autmic ）</font> ：事务在执行性，要做到“要么不做，要么全做！”。就是说不允许事务部分得执行。即使因为故障而使事务不能完成，在 rollback 时也要消除对数据库得影响！

2.<font color='red'>一致性（Consistency）</font> ：事务必须是使数据库从一个一致性状态变到另一个一致性状态。一致性 与原子性是密切相关的。在事务开始之前和结束之后，数据库的完整性约束没有被破坏。

3.<font color='red'>隔离性（Isolation ）</font> ：一个事务的执行不能被其他事务干扰。即一个事务内部的操作及使用的数据对并发的其他事务是隔离的，并发执行的各个事务之间不能互相干扰，这些通过锁来实现。

4.<font color='red'>持久性（Durability）</font>：指一个事务一旦提交，它对数据库中数据的改变就是永久性的。接下来的其他操作或故障（比如说宕机等）不应该对其有任何影响。
<font color='red'>事务的 ACID 特性</font>可以确保银行不会弄丢你的钱

#### 6.3   MySQL 事务处理的方法

语法：

1.用 BEGIN,ROLLBACK,COMMIT 来实现

start transaction | begin   开启事务

commit  提交当前事务，执行永久操作。

rollback   回滚当前事务到开始点，取消上一次开始点后的所有操作。

2.savepoint 名称     折返点



直接用 set 来改变 MySQL 的自动提交模式

MYSQL 默认是自动提交的，也就是你提交一个 SQL，它就直接执行！

3.查看当前自动提交模式

mysql> show variables like 'autocommit';

```
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| autocommit    | ON    |
+---------------+-------+
1 row in set (0.03 sec)
```

4.设置自动提交模式 
SET AUTOCOMMIT = {0 | 1} 设置事务是否自动提交，默认是自动提交的。
0 ：禁止自动提交   1 ：开启自动提交。

mysql> set autocommit=0; 
mysql> delimiter //             
mysql> start transaction;
\- > update books set bName="ccc" where bId=1; 
\- > update books set bName="ddd" where bId=2; 
\- > commit;//
测试，查看是否完成修改：
mysql> select bName from books where bId=1 or bId=2;//

![file://c:\users\admini~1\appdata\local\temp\tmpl7bpge\6.png](https://s2.loli.net/2022/03/02/DqgFSe7XBOp46os.png) 
我们测试回滚操作，首先看我们的数据库存储引擎是否为innodb 
mysql> show create table books//\G
![file://c:\users\admini~1\appdata\local\temp\tmpl7bpge\7.png](https://s2.loli.net/2022/03/02/nVRt18lO4WMgTqS.png) 
为 MyISAM 无法成功启动事务，虽然提交了，却无法回滚
修改数据库存储引擎为 innodb
mysql> delimiter ;
mysql> alter table books engine=innodb;    
mysql> alter table category engine=innodb;
![file://c:\users\admini~1\appdata\local\temp\tmpl7bpge\8.png](https://s2.loli.net/2022/03/02/hKuVTRFer6IiWf7.png) 

重新开启事务，并测试回滚     
mysql> set autocommit=0; 
mysql> delimiter //             
mysql> start transaction;
\- > update books set bName="HA" where bId=1; 
\- > update books set bName="LB" where bId=2;
\- > commit;// 
mysql> delimiter ;
mysql> select bName from books where bId=1 or bId=2;

![file://c:\users\admini~1\appdata\local\temp\tmpl7bpge\10.png](https://s2.loli.net/2022/03/02/MbvXHQlCz1VokJs.png) 
无法回滚，因为我们 commit 已经提交了
mysql> delimiter //
mysql> start transaction; update books set bName="AH" where bId=1; update books set bName="BL" where bId=2;//   不提交
mysql> delimiter ;
mysql> select bName from books where bId=1 or bId=2;
![file://c:\users\admini~1\appdata\local\temp\tmpl7bpge\11.png](https://s2.loli.net/2022/03/02/yRUs715SGvBqHOx.png) 
回滚：
mysql> rollback;
mysql> select bName from books where bId=1 or bId=2;
![file://c:\users\admini~1\appdata\local\temp\tmpl7bpge\12.png](https://s2.loli.net/2022/03/02/sRFCig7KebmNJQL.png) 

恢复了

#### 6.4 隐式提交：

导致提交的非事务语句：
DDL语句： （ALTER、CREATE 和 DROP）
DCL语句： （GRANT、REVOKE 和 SET PASSWORD）
锁定语句：（LOCK TABLES 和 UNLOCK TABLES）
事务没未提交前，再开启一个事务begin，也会造成隐式提交



#### 6.5 隐式回滚：


会话断开或者被kill掉（数据库宕机，事务执行失败等）事务自动回滚



#### 6.6 保存点：

如果你已经开启了一个事务，并且已经输入了很多语句，这时你突然发现前面已经执行完成的某个语句的参数写错了，需要rollback回到执行前的样子
为了解决这种情况，提出了保存点的概念
语法：
savepoint 保存点名称

回滚到保存点
rollback to 保存点名称



事务日志:

​	文件位置：数据目录下：	 
Undo Log: ibdata1 ibdata2(存储在共享表空间中)，回滚日志
工作原理：
　　<font color='red'>Undo Log的原理很简单，为了满足事务的一致性 ，在操作任何数据的步骤之前，</font>
​       <font color='red'>首先将表中数据备份到一个地方（这个存储数据备份的地方称为 Undo Log），然后再进行数据的修改。</font>
　　<font color='red'>如果出现了错误或者用户执行了  ROLLBACK  语句，系统可以利用 Undo Log 中的备份将表中数据恢复到事务开始之前的状态。</font>

​    控制参数：
​    vim /etc/my.cnf
​	    innodb_rollback_segments=128(默认128个可以回滚）
​	功能：
​	    用于存储回滚日志，来提供innodb多版本读写。（提供一个快照用于事务操作）
​		提供回滚功能可以理解为每次操作的备份，属于逻辑日志。

Redo Log: ib_logfile0  ib_logfile1，又叫重做日志/前滚日志
工作原理：
     Redo Log记录的是新数据的备份。
     <font color='red'>在事务提交后，会将修改类（DML）操作 记录到  Redo Log 并将它同步到磁盘（持久化）即可</font>，
	

	控制参数：
	vim /etc/my.cnf
	innodb_log_file_size=50M(设置大小）
	innodb_log_files_in_group=2(设置文件个数）
	innodb_log_group_home_dir=./(存储位置，默认数据目录）	
	innodb_flush_log_at_trx_commit=0/1/2
	=1时在每次事务提交时立即刷新redo到磁盘，commit成功 (默认为1)
	=0时每秒先刷新日志到系统内存,再同步到磁盘，异常宕机时会丢失1秒内事务
	=2时每次事务提交都立即刷新redo缓冲池 到系统内存再每秒同步刷新到磁盘
	设置为0/2时，异常宕机会丢失1秒内事务，在高并发时候非常严重，1秒也可能丢失大量事务。

​	功能：
​	   用来存储在修改类（DML）操作时，数据页的变化（版本号LSN)，属于物理日志
​	   默认两个文件热动，循环覆盖使用。

举例：(假设表中A=1)
1.start transaction;
2.记录A=1到undo.log;
3.update A=4;
4.commint;
5.记录A=4到redo.log
6.将redo.log刷新到磁盘（数据库文件ib_logfilexx）



#### 6.7 事务的并发问题

​       1、脏写：如果一个事务修改了另一个未提交事务修改过的数据，就意味着发生了脏写现象
　　2、脏读：如果一个事务读到了另一个未提交事务修改过的数据，就意示着发生了脏读现象
　　3、不可重复读：事务 A 多次读取同一数据，事务 B 在事务A多次读取的过程中，对数据作了更新并提交，
​                        导致事务A多次读取同一数据时，结果不一致。
　　4、幻读：系统管理员A将数据库中所有学生的成绩从  具体分数 改为 ABCDE  等级，但是系统管理员B就在这个时候插入了一条具体分数的记录，
​             当系统管理员A改结束后发现还有一条记录没有改过来，就好像发生了幻觉一样，这就叫幻读

#### 6.8 事务的隔离级别

1.事务隔离性以下四种
RU：读未提交
RC：读已提交
RR：可重复读 ：默认级别
SR：可串行化

2.四种隔离级别的特点：
RU（read-uncommitted)：读未提交
可能出现的情况，脏页读，不可重复读，幻读

RC(read-committed)：读已提交
可能出现的问题，不可重复读，幻读

RR(repeatable-read)：可重复读            #系统默认隔离级别
可能出现的问题，有可能出现幻读             #添加索引可以解决幻读

SR(serializable)：可串行化         #执行完一个事务，才能继续执行另一个事务

串行化事务，以上问题都能避免，但是事务不能并发

3.临时修改
查看事务隔离级别以及调整：
select @@transaction_isolation;
set global transaction_isolation='read-uncommitted'; #全局修改
永久修改
vim /etc/my.cnf
transaction_isolation='read-uncommitted'

