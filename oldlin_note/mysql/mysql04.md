## MYSQL基础语句2        

### **1.DDL语句**

#### 1.1.显示表结构

mysql> desc student;                 
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\1.png](https://s2.loli.net/2022/02/14/V7cXwgaf1nPy5ex.png)

#### 1.2、修改表字段

语法：
alter table 表名 change 原字段名 新字段名 数据类型 约束条件  （一定要加数据类型，可不加约束条件）
mysql> alter table student <font color='red'>change</font> gender sex char(5) not null ;
mysql> desc student; 
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\2.png](https://s2.loli.net/2022/02/14/t5pJsLW8abcrANh.png)

#### 1.3、修改字段属性

语法：
alter table 表名 <font color='red'>modify </font>字段名称 数据类型  [完整性约束条件]
<font color='red'>注意，修改时如果不带完整性约束条件，原有的约束条件将丢失，如果想保留修改时就得带上完整性约束条件</font>
将name字段 char(64)修改成varchar(12)
mysql>alter table student modify name varchar(12)  ;        
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\3.png](https://s2.loli.net/2022/02/14/Qp5k6m7rORgtZHG.png)

#### 1.4、添加字段

语法：
alter table 表名 <font color='red'>add </font>字段名称 数据类型  [完整性约束条件]
mysql>alter table student add  math VARCHAR(3) NOT NULL  COMMENT '数学成绩';
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\4.png](https://s2.loli.net/2022/02/14/KUVzxTO6ckSwqQP.png)

在sex字段后面增加chinese字段。
mysql>alter table student add  chinese VARCHAR(3) NOT NULL  COMMENT '语文成绩' after sex;
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\5.png](https://s2.loli.net/2022/02/14/ceniVBAN1PUZ5g3.png)

在最前面的字段增加english字段
mysql>alter table student add  english VARCHAR(3) NOT NULL  COMMENT '英语成绩' first ;
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\6.png](https://s2.loli.net/2022/02/14/VArPt6fIF3XCkY1.png)

#### 1.5、修改字段位置(比较少用)

将english移到chinese后面
mysql>alter table student <font color='red'>modify</font>  english VARCHAR(3) NOT NULL  COMMENT '英语成绩' after chinese ;
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\7.png](https://s2.loli.net/2022/02/14/bXJMAn8ROSof7uY.png)

将math放到第一个，保留原完整性约束条件
mysql>alter table student modify  math VARCHAR(3) NOT NULL  COMMENT '数学成绩'  first ;
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\8.png](https://s2.loli.net/2022/02/14/LaK59jNZXyYDiSr.png)

#### 1.6、删除字段

语法：
alter table 表名 drop 字段名称
mysql> alter table student drop english ;
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\9.png](https://s2.loli.net/2022/02/14/OyPW7KzL6gp9Bso.png)

#### 1.7、添加与删除默认值：

创建新表
CREATE table user11(
id INT UNSIGNED KEY AUTO_INCREMENT,
username varchar(20) NOT NULL UNIQUE,
age TINYINT UNSIGNED
);

给age添加默认值
mysql>alter table user11 alter age SET DEFAULT 18;
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\10.png](https://s2.loli.net/2022/02/14/OelAHdB5jZqXip1.png)

删除默认值
mysql>alter table user11 alter age DROP DEFAULT;![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\11.png](https://s2.loli.net/2022/02/22/iNkmbXuQLTg1rAw.png)

#### 1.8、表主键的含义和作用

关系型数据库中的一条记录有若干个属性，如其中一个属性组能唯一标识一条记录，那么此属性组就可以称为一个主键。主键在表中必须唯一，且不可以为空。
主键的作用如下：
1.保证数据库的完整性
2.加快数据库表的查询速度



创建一个表
CREATE table test12(
id INT
);

#### 1.9、添加主键

语法：
alter table 表名 add PRIMARY KEY  (字段名称)
mysql>alter table test12 add PRIMARY KEY(id);

```
mysql> desc test12;
+-------+---------+------+-----+---------+-------+
| Field | Type    | Null | Key | Default | Extra |
+-------+---------+------+-----+---------+-------+
| id    | int(11) | NO   | PRI | NULL    |       |
+-------+---------+------+-----+---------+-------+
1 row in set (0.00 sec)
```

#### 1.10、删除主键

alter table 表名 drop PRIMARY KEY
mysql>alter table test12 DROP PRIMARY KEY;

```
mysql> desc test12;
+-------+---------+------+-----+---------+-------+
| Field | Type    | Null | Key | Default | Extra |
+-------+---------+------+-----+---------+-------+
| id    | int(11) | NO   |     | NULL    |       |
+-------+---------+------+-----+---------+-------+
1 row in set (0.00 sec)

```


在删除主键时，有一种情况是需要注意的，<font color='red'>需要知道具有自增长的属性的字段必须是主键</font>，如果表里的主键是具有自增长属性的；那么直接删除是会报错的。如果想要删除主键的话，可以先去除自增长属性，再删除主键

再创建一个表，
CREATE table test14(
id INT  PRIMARY KEY AUTO_INCREMENT
);

```mysql
mysql> show create table test14;
+--------+-----------------------------------------------------------------------------------------------------------------------------+
| Table  | Create Table                                                                                                                |
+--------+-----------------------------------------------------------------------------------------------------------------------------+
| test14 | CREATE TABLE `test14` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 |
+--------+-----------------------------------------------------------------------------------------------------------------------------+
1 row in set (0.00 sec)
```

删除主键，这样会报错，因为自增长的必须是主键

```
mysql> alter table test14 DROP PRIMARY KEY;
ERROR 1075 (42000): Incorrect table definition; there can be only one auto column and it must be defined as a key
```

直接删除自增长也会报错

```
mysql> alter table test14  drop auto_increment;   
ERROR 1091 (42000): Can't DROP 'auto_increment'; check that column/key exists
```

需要用modify修改自增长属性，注意modify不能去掉主键属性

```
mysql> alter table test14 modify id INT ;
Query OK, 0 rows affected (0.00 sec)
Records: 0  Duplicates: 0  Warnings: 0
mysql> show create table test14;
+--------+--------------------------------------------------------------------------------------------------------------+
| Table  | Create Table                                                                                                 |
+--------+--------------------------------------------------------------------------------------------------------------+
| test14 | CREATE TABLE `test14` (
  `id` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 |
+--------+--------------------------------------------------------------------------------------------------------------+
1 row in set (0.00 sec)
```

再来删除主键
alter table test14 DROP PRIMARY KEY; 

```
mysql> show create table test14;
+--------+----------------------------------------------------------------------------------------+
| Table  | Create Table                                                                           |
+--------+----------------------------------------------------------------------------------------+
| test14 | CREATE TABLE `test14` (
  `id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 |
+--------+----------------------------------------------------------------------------------------+
1 row in set (0.00 sec)

```

#### 1.11、修改表的存储引擎：

语法：
alter table 表名 ENGINE=存储引擎名称
mysql>alter table test14 ENGINE=MyISAM;
mysql>alter table test14 ENGINE=INNODB; 

#### 1.12、修改自增长值：

语法：
alter table 表名 AUTO_INCREMENT=值      #下次插入表时的数据就会自增长的值是多少
mysql>alter table test14 AUTO_INCREMENT=100;

#### 1.13、删除表

语法:
drop table 表名
mysql>drop table test12;

#### 1.14、修改表名称

语法：alter table 表名 <font color='red'>rename</font> 新表名;
mysql>alter table test14 rename test11;

注：在mysql中<font color='red'>DDL语句在对表进行操作时可能会发生锁表</font>（锁住的是元数据表：相当于文件的inode）

##### 一、导致锁表的原因

1、锁表发生在insert update 、delete 中 
2、锁表的原理是 数据库使用独占式封锁机制，当执行上面的语句时，对表进行锁住，直到发生commit 或者 回滚 或者退出数据库用户
3、锁表的原因 
第一、 A程序执行了对 tableA 的 insert ，并还未 commit时，B程序也对tableA 进行insert 则此时会发生资源正忙的异常
第二、锁表常发生于大并发

##### 二、mysql锁表的解决

查看进程id,然后用kill id杀掉进程
 show processlist;
 SELECT * FROM information_schema.PROCESSLIST;
 查询正在执行的进程 
 SELECT * FROM information_schema.PROCESSLIST where length(info) >0 ; 
 查询是否锁表
  show OPEN TABLES where In_use > 0; 
 查看被锁住的 
 SELECT * FROM INFORMATION_SCHEMA.INNODB_LOCKS; 
 等待锁定
 SELECT * FROM INFORMATION_SCHEMA.INNODB_LOCK_WAITS;
 杀掉锁表进程
 kill xxx

### 2、DML语句

#### **2.1.插入数据insert**

语法：insert into 表名 values (字段值 1,字段值 2, 字段值 3，...);

创建一个表
mysql>create table test (id  int(4) not null ,name char(24) not null,age TINYINT );

插入记录时要对应相对的类型
mysql> insert into test values(1,'zhangs',21);

同时插入多条，使用，分开
mysql> insert into test values(2,'lis',24),(3,'wange',26);

指定字段插入
mysql> insert into test (id,name)values(4,'hangl');

插入指定内容
mysql> insert into test set id=4,name='xiaohong';

将另外表中的内容查出并插入
mysql> insert into test select * from 表名;



Records:100 Duplicates:0 Warnings:0

Records代表此语句操作了多少行数据，但不一定是多少行被插入的数据，因为如果存在相同的行数据且违反了某个唯一性，则duplicates会显示非0数值，warning代表语句执行过程中的一些警告信息





#### **2.2.更新数据update**

语法：update 表名 set 字段名='新内容'  where 条件表达式

mysql>update test set age='30' where name='zhangs';

如果不添加条件表达式，会发生什么？
mysql>update test set age='30';
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\12.png](https://s2.loli.net/2022/02/14/h1YPdaJIoCwHLkW.png)

#### **2.3.删除数据delete**

语法：delete from 表名 where 条件表达式 

mysql>delete from test where id=4;	#会将id=4的那一行数据整行删除

如果不添加条件表达式，会发生什么？

什么是伪删除?

drop、 truncate 、 delete的区别？

drop table:删除表对象，表数据、表结构都进行了删除。
delete和truncate table：删除表数据，表对象及表结构依然存在。

delete与truncate table的区别如下：
delete：
（1）可以删除表所有数据，也可以根据条件删除数据。
（2）如果有自动编号，删除后继续编号，例如delete删除表所有数据后，之前数据的自动编号是1，2，3，那么之后新增数据的编号从4开始。
（3）delete只是伪删除数据，只是逻辑层面的删除，内存里面没有删除
truncate table：
（1）只能清空整个表数据，不能根据条件删除数据。
（2）如果有自动编号，清空表数据后重新编号，例如truncate table清空表所有数据后，之前数据的自动编号是1，2，3，那么之后新增数据的编号仍然从1开始。

### 3、DQL语句

#### **查询数据select** 

语法：select 字段名 1 ，字段名 2 from 表名  [where 条件];

常用 select 命令 

#### 3.1使用 select 命令查看 mysql 数据库系统信息：

-- 打印当前的日期和时间 mysql> select now();
-- 打印当前的日期             mysql> select curdate();
-- 打印当前的时间             mysql> select curtime();
-- 打印当前数据库               mysql> select database();
-- 打印 MySQL 版本        mysql> select version();
-- 打印当前用户          mysql> select user();

#### 3.2.查看系统参数：

语法：
select @@xxx 

举例：

SELECT @@port;
SELECT @@basedir;
SELECT @@datadir;
SELECT @@socket;
<font color='red'>SELECT @@server_id;</font>

#### 3.3.查看系统信息

show 语句：
show processlist; 查询连接数信息。
show full processlist; 显示连接的详细信息.
show grants for xxx用户；用户; 查看用户权限
show index from 某表；查看某表索引。
show status;查看数据库状态。
show table status;查看表状态
show status like ‘%%’; 模糊查询数据库状态
show binary logs   查询二进制日志
show binlog event in 二进制文件；查询二进制日志事件
show create database test                #查看建库语句
show create table student              #查看建表语句
show  charset；                                  #查看字符集
show collation；                                 #查看校对规则
show variables;                              #查看所有配置信息
show engines;                                     #查看支持的所有的存储引擎
show master status;                            #查看数据库的日志位置信息，开启主从使用,开启binlog日志用
show slave status;                               #查询从库状态。开启主从用
like  模糊搜索还可用于where 语句。
MySQL 提供两个通配符，用于与 LIKE 运算符一起使用，它们分别是：百分比符号 %和下划线 _。
百分比（% ）表示通配符允许匹配任何字符串的零个或多个字符。
下划线（\_） 表示通配符允许匹配任何单个字符。

mysql>insert into test values(1,'zhangs',21),(2,'lis',24),(3,'Jk',24),(4,'lo',25),(5,'io',25),(6,'jk',22);
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\13.png](https://s2.loli.net/2022/02/14/XuV73pmBaPiqdWI.png)

#### 3.4去重复查询    

mysql> select <font color='red'>distinct</font> age from test;
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\14.png](https://s2.loli.net/2022/02/14/7if9AnQHUEuX1qd.png)

distinct +多字段时，需要多字段的内容都重复时才能去重

![image-20220423102114578](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202204231021660.png)



#### 3.5.使用and和 or 进行多条件查询

or 和and 同时存在时，先算 and的两边值，逻辑优先执行
mysql> select * from test where id>1 and age>24;                 
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\15.png](https://s2.loli.net/2022/02/14/2D385nE1YMcVXPo.png)

mysql>  select * from test where id>3 or age<30;
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\16.png](https://s2.loli.net/2022/02/14/fVSN65DaoxCZ4Pw.png)

mysql> select * from test where age>22 and  id >=4 or id<2 ;							#and 前后条件可视为一个整体，																																		  or 前后条件分别独立
![image-20220825104252288](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202208251042347.png)



mysql> select * from test where name='zhangs' and (age=21 or age=24);
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\17.png](https://s2.loli.net/2022/02/14/FyGiHY5XvjUBkEr.png)
注意and和 or 都是用的时候的逻辑关系

#### 3.6.MySQL 区分大小写查询

MySQL 查询默认是不区分大小写的
mysql> select name from test where name='jk'; 
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\18.png](https://s2.loli.net/2022/02/14/H1ypifUd6TFvQeE.png)

解决：
mysql> select * from test where <font color='red'>binary</font> name='jk';                                    
![123](https://s2.loli.net/2022/02/24/zwecvqkGMFBs8DP.png)
binary [ˈbaɪnə ri] 二进制的
BINARY 是类型转换运算符，它用来强制它后面的字符串为一个二进制字符串，可以理解为在字符串
比较的时候区分大小写。

#### 3.7.MySQL 查询排序

语法：select  字段 1 ，字段 2 from 表名   <font color='red'>order by</font> 字段名    asc/desc;
默认为升序asc
mysql> select  id from test order by id asc;                                    
![456](https://s2.loli.net/2022/02/24/pNqvKuEbP38OG4d.png)

desc为降序
 mysql> select distinct id from test order by id desc;                                  
![789](https://s2.loli.net/2022/02/24/61qKG7XxsBTphQJ.png)

多个字段排序。
 mysql> select * from test order by id desc,age asc ;               #从左到右，有优先级
![147](https://s2.loli.net/2022/02/24/7A8vCsptFOkQDSo.png)

mysql> select * from test order by age asc,id desc ;
![258](https://s2.loli.net/2022/02/24/5DeLjvyNzBTJ3SX.png)

#### 3.8.AS的用法，类似linux中的别名操作。

定义表或者库为一个别名，下面的子句，直接引用别名即可。
mysql>select  id  as 身份证 ,name as 姓名
from test
where age=25 or age=24
order by 身份证 DESC ;
![1](https://s2.loli.net/2022/02/24/Adpk49bywPJQWxc.png)





### 4、**SQL 查 询 语 句进 阶**

在我们刚导入的 book 数据库进行测试
mysql>source /opt/book.sql

查 看 表 的 内 容

mysql> select * from category;
![2](https://s2.loli.net/2022/02/24/vB1QGNepnhMcJ68.png)

mysql>   select * from books;
![3](https://s2.loli.net/2022/02/24/vBJxPVsZ51eUmcD.png)
mysql>   select * from books\G
*************************** 1. row ***************************
bId: 1
bName: 网站制作直通车
bTypeId: 2
publishing: 电脑爱好者杂志社
price: 34
pubDate: 2004- 10-01 author: 苗壮
ISBN: 7505380796
bId: 43
bName: ASP 3 初级教程
	bTypeId: 2
publishing: 机械工业出版社
price: 104
	pubDate: 2003- 11-01
	author: 韩旭日
	ISBN: 7505375458
。。。
*************************** 44. row ***************************
bId: 44
bName: XML 完全探索 bTypeId: 2
publishing: 中国青年出版社
price: 104                pubDate: 2004-01-01
author: 齐鹏
ISBN: 7505357778 44 rows in set (0.00 sec)

```
mysql> desc books;
+------------+------------------------------------------------+------+-----+---------+----------------+
| Field      | Type                                           | Null | Key | Default | Extra          |
+------------+------------------------------------------------+------+-----+---------+----------------+
| bId        | int(4)                                         | NO   | PRI | NULL    | auto_increment |
| bName      | varchar(255)                                   | YES  |     | NULL    |                |
| bTypeId    | enum('1','2','3','4','5','6','7','8','9','10') | YES  |     | NULL    |                |
| publishing | varchar(255)                                   | YES  |     | NULL    |                |
| price      | int(4)                                         | YES  |     | NULL    |                |
| pubDate    | date                                           | YES  |     | NULL    |                |
| author     | varchar(30)                                    | YES  |     | NULL    |                |
| ISBN       | varchar(255)                                   | YES  |     | NULL    |                |
+------------+------------------------------------------------+------+-----+---------+----------------+
8 rows in set (0.00 sec)

```

####  4.1.逻 辑 运 算 符

and or not 
and 且      
or   或       
not 非
选择出书籍价格为（30,40,50,60）的记录,只显示书籍名称，出版社，价格

```
mysql> select bName,publishing,price from books where price=30 or price=40 or price=50 or price=60;
+--------------------------------------+--------------------------+-------+
| bName                                | publishing               | price |
+--------------------------------------+--------------------------+-------+
| Illustrator 10完全手册               | 科学出版社               |    50 |
| FreeHand 10基础教程                  | 北京希望电子出版         |    50 |
| 网站设计全程教程                     | 科学出版社               |    50 |
| ASP数据库系统开发实例导航            | 人民邮电出版社           |    60 |
| Delphi 5程序设计与控件参考           | 电子工业出版社           |    60 |
| ASP数据库系统开发实例导航            | 人民邮电出版社           |    60 |
+--------------------------------------+--------------------------+-------+
6 rows in set (0.00 sec)

```
 选择出书籍价格不为（50,60）的记录,只显示书籍名称，出版社，价格

```
mysql> select bName,publishing,price from books where not  (price=50 or  price=60);
+---------------------------------------------------------+-----------------------------------+-------+
| bName                                                   | publishing                        | price |
+---------------------------------------------------------+-----------------------------------+-------+
| 网站制作直通车                                          | 电脑爱好者杂志社                  |    34 |
| 黑客与网络安全                                          | 航空工业出版社                    |    36 |
| 网络程序与设计－asp                                     | 北方交通大学出版社                |    38 |
| pagemaker 7.0短期培训教程                               | 中国电力出版社                    |    38 |
| 黑客攻击防范秘笈                                        | 北京腾图电子出版社                |    39 |
| Dreamweaver 4入门与提高                                 | 清华大学出版社                    |    39 |
......
| 3D Studio Max 3综合使用                                 | 人民邮电出版社                    |    91 |
| SQL Server 2000 从入门到精通                            | 电子工业出版社                    |    93 |
| SQL Server 7.0数据库系统管理与应用开发                  | 人民邮电出版社                    |    95 |
| ASP 3初级教程                                           | 机械工业出版社                    |   104 |
| XML 完全探索                                            | 中国青年出版社                    |   104 |
+---------------------------------------------------------+-----------------------------------+-------+
38 rows in set (0.01 sec)

```



#### 4.2.算 术 运 算 符

=   等于
**<>      不等于（相当于!=） ** 
\>   大于
<   小于
\>= 大于等于
<=  小于等于

in     运算符
IN 运算符用于 WHERE 表达式中，以列表项的形式支持多个选择，语法如下： 
WHERE column IN (value1,value2,...)
WHERE column NOT IN (value1,value2,...)
**Not in 与 in 相反**
当 IN 前面加上  NOT 运算符时，表示与 IN 相反的意思，即不在这些列表项内选择。



找出价格大于 60 的记录

```
mysql> select bName,price from books where price>60;
+---------------------------------------------------------+-------+
| bName                                                   | price |
+---------------------------------------------------------+-------+
| 活学活用Delphi5                                         |    62 |
| Auto CAD 2002 中文版实用教程                            |    63 |
| 3DS MAX 4横空出世                                       |    63 |
| 精通Javascript                                          |    63 |
| 深入Flash 5教程                                         |    64 |
| Auto CAD R14 中文版实用教程                             |    64 |
| Frontpage 2000＆ ASP 网页设计技巧与网站维护             |    71 |
| HTML设计实务                                            |    72 |
| 3D MAX R3动画制作与培训教程                             |    73 |
| Javascript与Jscript从入门到精通                         |  7500 |
| lllustrator 9宝典                                       |    83 |
| 3D Studio Max 3综合使用                                 |    91 |
| SQL Server 2000 从入门到精通                            |    93 |
| SQL Server 7.0数据库系统管理与应用开发                  |    95 |
| ASP 3初级教程                                           |   104 |
| XML 完全探索                                            |   104 |
+---------------------------------------------------------+-------+
16 rows in set (0.00 sec)

```

 找出价格等于 60 的。

```
mysql>  select bName,price from books where price=60; 
+--------------------------------------+-------+
| bName                                | price |
+--------------------------------------+-------+
| ASP数据库系统开发实例导航            |    60 |
| Delphi 5程序设计与控件参考           |    60 |
| ASP数据库系统开发实例导航            |    60 |
+--------------------------------------+-------+
3 rows in set (0.00 sec)
```

找出价格不等于 60 的

```
mysql> select bName,price from books where price<>60;  
+---------------------------------------------------------+-------+
| bName                                                   | price |
+---------------------------------------------------------+-------+
| 网站制作直通车                                          |    34 |
| 黑客与网络安全                                          |    36 |
| 网络程序与设计－asp                                     |    38 |
| pagemaker 7.0短期培训教程                               |    38 |
| 黑客攻击防范秘笈                                        |    39 |
| Dreamweaver 4入门与提高                                 |    39 |
。。。。。
| 3D Studio Max 3综合使用                                 |    91 |
| SQL Server 2000 从入门到精通                            |    93 |
| SQL Server 7.0数据库系统管理与应用开发                  |    95 |
| ASP 3初级教程                                           |   104 |
| XML 完全探索                                            |   104 |
+---------------------------------------------------------+-------+
41 rows in set (0.00 sec)

```

找出价格是 60，50 ，70 的记录 。

```
mysql> select bName,price from books where price in (50,60,70); 
+--------------------------------------+-------+
| bName                                | price |
+--------------------------------------+-------+
| Illustrator 10完全手册               |    50 |
| FreeHand 10基础教程                  |    50 |
| 网站设计全程教程                     |    50 |
| ASP数据库系统开发实例导航            |    60 |
| Delphi 5程序设计与控件参考           |    60 |
| ASP数据库系统开发实例导航            |    60 |
+--------------------------------------+-------+
6 rows in set (0.00 sec)
```

找出价格不是60， 50， 70 的记录

```
mysql> select bName,price from books where price not in (50,60,70);  
+---------------------------------------------------------+-------+
| bName                                                   | price |
+---------------------------------------------------------+-------+
| 网站制作直通车                                          |    34 |
| 黑客与网络安全                                          |    36 |
| 网络程序与设计－asp                                     |    38 |
| pagemaker 7.0短期培训教程                               |    38 |
。。。。
| lllustrator 9宝典                                       |    83 |
| 3D Studio Max 3综合使用                                 |    91 |
| SQL Server 2000 从入门到精通                            |    93 |
| SQL Server 7.0数据库系统管理与应用开发                  |    95 |
| ASP 3初级教程                                           |   104 |
| XML 完全探索                                            |   104 |
+---------------------------------------------------------+-------+
38 rows in set (0.00 sec)

```



#### 4.3.范 围 运 算

[not]between ....and....
Between and 可以使用大于小于的方式来代替，<font color='red'>并且使用大于小于意义表述更明确 </font>

查找价格不在 30 到 60 之间的书名和价格

```
mysql> select bName,price from books where price not between 30 and 60 order by price desc;
+---------------------------------------------------------+-------+
| bName                                                   | price |
+---------------------------------------------------------+-------+
| Javascript与Jscript从入门到精通                         |  7500 |
| ASP 3初级教程                                           |   104 |
| XML 完全探索                                            |   104 |
| SQL Server 7.0数据库系统管理与应用开发                  |    95 |
| SQL Server 2000 从入门到精通                            |    93 |
| 3D Studio Max 3综合使用                                 |    91 |
| lllustrator 9宝典                                       |    83 |
| 3D MAX R3动画制作与培训教程                             |    73 |
| HTML设计实务                                            |    72 |
| Frontpage 2000＆ ASP 网页设计技巧与网站维护             |    71 |
| 深入Flash 5教程                                         |    64 |
| Auto CAD R14 中文版实用教程                             |    64 |
| Auto CAD 2002 中文版实用教程                            |    63 |
| 3DS MAX 4横空出世                                       |    63 |
| 精通Javascript                                          |    63 |
| 活学活用Delphi5                                         |    62 |
+---------------------------------------------------------+-------+
16 rows in set (0.00 sec)

```

注：
这里的查询条件有三种：between。。。and ，or 和 in  
(30,60)    >30 and <60
[30,60]    >=30 and <=60

####  4.4.模 糊 匹 配 查 询

字段名  [not]like '通配符'   ----》% 表示任意多个字符

查找书名中包括"程序"字样记录

```
mysql> select bName from books where bName like '%程序%';
+-------------------------------------+
| bName                               |
+-------------------------------------+
| 网络程序与设计－asp                 |
| Delphi 5程序设计与控件参考          |
+-------------------------------------+
2 rows in set (0.00 sec)

```

 查 找 书 名 中 不 包 括  “ 程 序 ” 字 样 记 录

```
mysql>  select bName from books where bName not like '%程序%';
+---------------------------------------------------------+
| bName                                                   |
+---------------------------------------------------------+
| 网站制作直通车                                          |
| 黑客与网络安全                                          |
| pagemaker 7.0短期培训教程                               |
| 黑客攻击防范秘笈                                        |
.....
| SQL Server 2000 从入门到精通                            |
| SQL Server 7.0数据库系统管理与应用开发                  |
| ASP 3初级教程                                           |
| XML 完全探索                                            |
+---------------------------------------------------------+
42 rows in set (0.00 sec)

```



#### 4.5.MySQL 子查询：

概念：在select  的 where 条件中又出现了 select ，查询中嵌套着查询

选择 类型名为 “网络技术”的图书：

```
mysql> select bName,bTypeId from books where bTypeId=(select bTypeId from category where bTypeName='网络技术');
+----------------------+---------+
| bName                | bTypeId |
+----------------------+---------+
| Internet操作技术      | 7       |
+----------------------+---------+
1 row in set (0.00 sec)

```


选择类型名称为 “黑客”的图书；

```
mysql> select bName,bTypeId from books where bTypeId=(select bTypeId from category where bTypeName='黑客');
+--------------------------+---------+
| bName                    | bTypeId |
+--------------------------+---------+
| 黑客与网络安全           | 6       |
| 黑客攻击防范秘笈         | 6       |
+--------------------------+---------+
2 rows in set (0.00 sec)

```

#### 4.6.Limit 限 定 显 示 的 条 目

SELECT * FROM table LIMIT [offset,] rows
偏移量   行数
LIMIT 子句可以被用于强制 SELECT 语句返回指定的记录数。LIMIT 接受一个或两个数字参数。参数必须是一个整数常量。
如果给定两个参数，第一个参数指定第一个返回记录行的偏移量，第二个 参数指定返回记录行的最大数目。初始记录行的偏移量是 0（而不是  1）。
<font color='red'>比如 select * from table limit m,n 语句</font>
<font color='red'>表示其中 m 是指记录开始的 index ，从 0 开始，表示第一条记录 ;  n 是指从第 m+1 条开始，取 n 条。</font>
查出 category 表中第 2 条到第 6 行的记录。
首先 2 到 6 行有 2， 3，4， 5， 6 总共有 5 个数字，从 2 开始，偏移量为 1 

```
mysql> select * from category limit 1,5;
+---------+--------------+
| bTypeId | bTypeName    |
+---------+--------------+
|       2 | 网站         |
|       3 | 3D动画       |
|       4 | linux学习    |
|       5 | Delphi学习   |
|       6 | 黑客         |
+---------+--------------+
5 rows in set (0.00 sec)
```



查看所有书籍中价格中最低的三条记录 ：
我们对所有记录排序以升序排列，取出前面 3 个来

```
mysql> select bName,price from books order by price asc limit 0,3;
+-----------------------------+-------+
| bName                       | price |
+-----------------------------+-------+
| 网站制作直通车              |    34 |
| 黑客与网络安全              |    36 |
| 网络程序与设计－asp         |    38 |
+-----------------------------+-------+
3 rows in set (0.00 sec)
```

我们将子查询和限制条目，算术运算结合起来查询
显示字段bName ,price ；条件：找出价格比电子工业出版社出版的书中最便宜还要便宜的书。 针对这种查询，我们一步步的来，先找出电子工业出版社出版中最便宜的书。 

```
mysql> select bName,price from books where publishing="电子工业出版社" order by price asc limit 0,1;
+-------------------------------------+-------+
| bName                               | price |
+-------------------------------------+-------+
| Delphi 5程序设计与控件参考          |    60 |
+-------------------------------------+-------+
1 row in set (0.00 sec)
```

```mysql
mysql> select bName,price from books where price<(select price from books where publishing="电子工业出版社" order by price asc limit 0,1);
+--------------------------------------------------------+-------+
| bName                                                  | price |
+--------------------------------------------------------+-------+
| 网站制作直通车                                         |    34 |
| 黑客与网络安全                                         |    41 |
| 网络程序与设计－asp                                    |    43 |
| pagemaker 7.0短期培训教程                              |    43 |
| 黑客攻击防范秘笈                                       |    44 |
| Dreamweaver 4入门与提高                                |    44 |
| 网页样式设计－CSS                                      |    45 |
| Internet操作技术                                       |    45 |
| Dreamweaver 4网页制作                                  |    45 |
| 3D MAX 3.0 创作效果百例                                |    45 |
| Auto CAD职业技能培训教程                               |    47 |
| Fireworks 4网页图形制作                                |    48 |
| 自己动手建立企业局域网                                 |    48 |
| 页面特效精彩实例制作                                   |    49 |
| 平面设计制作整合案例详解－页面设计卷                   |    49 |
| Illustrator 10完全手册                                 |    50 |
| FreeHand 10基础教程                                    |    50 |
| 网站设计全程教程                                       |    50 |
| 动态页面技术－HTML 4.0使用详解                         |    51 |
| Auto CAD 3D模型大师                                    |    53 |
| Linux傻瓜书                                            |    54 |
| 网页界面设计艺术教程                                   |    54 |
| Flash MX 标准教程                                      |    54 |
| Auto CAD 2000 应用及实例基集锦                         |    58 |
| Access 2000应用及实例基集锦                            |    59 |
+--------------------------------------------------------+-------+
25 rows in set (0.00 sec)
```

或者：
多行子查询： all 表示小于子查询中返回全部值中的最小值

```
mysql> select bName,price from books where price<all(select price from books where publishing="电子工业出版社");
+--------------------------------------------------------+-------+
| bName                                                  | price |
+--------------------------------------------------------+-------+
| 网站制作直通车                                         |    34 |
| 黑客与网络安全                                         |    36 |
| 网络程序与设计－asp                                    |    38 |
| pagemaker 7.0短期培训教程                              |    38 |
| 黑客攻击防范秘笈                                       |    39 |
。。。。。。
| 网页界面设计艺术教程                                   |    54 |
| Flash MX 标准教程                                      |    54 |
| Auto CAD 2000 应用及实例基集锦                         |    58 |
| Access 2000应用及实例基集锦                            |    59 |
+--------------------------------------------------------+-------+
25 rows in set (0.00 sec)

```

#### 4.7.多表查询


笛卡尔积是关系代数里的一个概念，表示两个表中的每一行数据任意组合,两个表连接即为笛卡尔积(交叉连接)

MySQL的多表查询(笛卡尔积原理)
先确定数据要用到哪些表。
将多个表先通过笛卡尔积变成一个表。
然后去除不符合逻辑的数据（根据两个表的关系去掉）。
最后当做是一个虚拟表一样来加上条件即可。

常用的连接：
内连接：根据表中的共同字段进行匹配
外连接分两种：左外连接、右外链接。

4.7.1、内连接
语法：
select 字段   from 表 1  join 表 2   on 表 1.字段=表 2.字段 
内连接：根据表中的共同字段进行匹配
测试

```mysql
mysql> select a.bname,a.price,b.btypename from books as a  join category as(as可以省略) b on a.btypeid=b.btypeid;
+---------------------------------------------------------+-------+---------------+
| bname                                                   | price | btypename     |
+---------------------------------------------------------+-------+---------------+
| 网站制作直通车                                          |    34 | 网站          |
| 黑客与网络安全                                          |    36 | 黑客          |
| 网络程序与设计－asp                                     |    38 | 网站          |
| pagemaker 7.0短期培训教程                               |    38 | 平面          |
| 黑客攻击防范秘笈                                        |    39 | 黑客          |
| Dreamweaver 4入门与提高                                 |    39 | 网站          |
。。。。。。
| Javascript与Jscript从入门到精通                         |  7500 | 网站          |
| lllustrator 9宝典                                       |    83 | 平面          |
| 3D Studio Max 3综合使用                                 |    91 | 3D动画        |
| SQL Server 2000 从入门到精通                            |    93 | windows应用   |
| SQL Server 7.0数据库系统管理与应用开发                  |    95 | windows应用   |
| ASP 3初级教程                                           |   104 | 网站          |
| XML 完全探索                                            |   104 | 网站          |
+---------------------------------------------------------+-------+---------------+
44 rows in set (0.00 sec)
内连接第二种写法：WHERE 子句结果一样
mysql> select a.bname,a.price,b.btypename from books a, category b where a.btypeid=b.btypeid;
```

举例：

创建模拟数据：

create table student1 (id int, name char(5),math varchar(5) )ENGINE=INNODB CHARSET=utf8;
create table student2 (id int, name char(5),sex varchar(5),abc char(5) )ENGINE=INNODB CHARSET=utf8;
insert into student1 values(1,'zhang',33),(2,'lin',42),(3,'xiao',65),(4,'ming',87);
insert into student2 values(1,'zhang','man','zhang'),(2,'lin','man','lin'),(3,'hong','woman','hong'),(4,'ming','man','ming');

创建a表如下
![4](https://s2.loli.net/2022/02/24/WSVnmOPqMue2URp.png)
创建b表如下
![5](https://s2.loli.net/2022/02/24/xQbntpUDIZ3HWNE.png)
select a.sex,b.math from student2 a JOIN  student1 b on a.name=b.name;
![6](https://s2.loli.net/2022/02/24/OkcyVWmvfbroL3n.png)
select a.sex,b.math from student2 a JOIN  student1 b on a.abc=b.name;
![7](https://s2.loli.net/2022/02/24/lNWD6Hzj3GaMevI.png)
由此证明，多表连接交集的内容是行数据，与字段无关。

#### 4.8.外连接  (分为左外连接；右外连接)

1. 左连接： select   字段 from a 表 left join b 表   on 连接条件 
2. 解释：优先显示左表全部记录,此时左表主表 ，右表为从表
3. 主表内容全都有，从表内没有的显示 null。

select b.*,a.math from student2 b left join student1 a on b.abc=a.name ;

![image-20220224155855422](https://s2.loli.net/2022/02/24/jIcWPhwf8BbtgED.png)

1.右连接：select 字段 from a 表 right join b 表 on 条件

2.解释：优先显示右表全部记录,此时右表主表，左表为从表 

3.主表内容全都有，从表内没有的显示 null。
select b.*,a.math from student2 b right join student1 a on b.abc=a.name ;

![image-20220224155956464](https://s2.loli.net/2022/02/24/GgdrJPpil2oabQy.png)

#### 4.9.当两个表没有任何关联然后还需要查询拼接数据时，需找中间表。(重点)

新建三表：

create table student (Sno char(8),Name varchar(8))ENGINE=INNODB CHARSET=utf8;
create table course (Cno char(8),Cname varchar(8))ENGINE=INNODB CHARSET=utf8;
create table student_course (ID int,Sno char(8),Cno char(8))ENGINE=INNODB CHARSET=utf8;
insert into student values('S001','张三'),('S002','李四'),('S003','王二');
insert into course values('C001','足球'),('C002','音乐'),('C003','美术');
insert into student_course values(1,'S001','C001'),(2,'S002','C001'),(3,'S002','C002'),(4,'S003','C003'),(5,'S003','C001');

表A:  student 截图如下： 
![image-20220224161135592](https://s2.loli.net/2022/02/24/km9eaJbHB8l6zUy.png)
表B:  course 截图如下：
![image-20220224161159560](https://s2.loli.net/2022/02/24/CgT2Fu5orAcE1fv.png)
表C:  student_course 截图如下：
![image-20220224161229603](https://s2.loli.net/2022/02/24/1gwBUxtRjXvEOD5.png)

 一个学生可以选择多门课程，一门课程可以被多个学生选择，因此学生表student和课程表course之间是多对多的关系。

当两表为多对多关系的时候，我们需要建立一个中间表student_course，中间表至少要有两表相关的内容。

mysql>select a.Name,b.Cname from (student_course c left join student a on a.Sno=c.Sno) left join course b on b.Cno=c.Cno 

![image-20220224173507964](https://s2.loli.net/2022/02/24/8uZxUPraEDjLqSB.png)

### 5、 **聚 合 函 数**

函数：执行特定功能的代码块。

#### 5.1.算数运算函数

（1）Sum()求和
显示所有图书单价的总合
mysql> select sum(price) from books; 或：
select sum(price) as 图书总价 from books;

```
+------------+
| sum(price) |
+------------+
|      10048 |
+------------+
1 row in set (0.00 sec)

```

（2）avg()平均值
求书籍Id小于 3 的所有书籍的平均价格

```
mysql> select avg(price) from books where bId<=3;
+------------+
| avg(price) |
+------------+
|   228.3636 |
+------------+
1 row in set (0.00 sec)
```

（3）max() 最大值
求所有图书中价格最贵的书籍
mysql> select bName,max(price) from books; 这种方法是错误的       <font color='red'>  #函数不可以与字段一起显示</font>

我们来查一下最贵的图书是哪本？


```
mysql> Select bname,price from books order by price desc limit 1;
mysql> Select bName,price from books where price=(select max(price) from books);
+----------------------------------------+-------+
| bName                                  | price |
+----------------------------------------+-------+
| Javascript与Jscript从入门到精通          |  7500 |
+----------------------------------------+-------+
1 row in set (0.00 sec)

```

```
mysql> Select max(price) from books where price<40;
+------------+
| max(price) |
+------------+
|         34 |
+------------+
1 row in set (0.00 sec)
```

（4）min()最小值
求所有图书中价格便宜的书籍？

```
mysql> select bName,price from books where price=(select min(price) from books);
+-----------------------+-------+
| bName                 | price |
+-----------------------+-------+
| 网站制作直通车          |    34 |
+-----------------------+-------+
1 row in set (0.00 sec)
```

（5）count()统计记录数
统计价格大于 40 的书籍数量

```
mysql> select count(*) from books where price>40;
+----------+
| count(*) |
+----------+
|       43 |
+----------+
1 row in set (0.00 sec)

Count （）中还可以增加你需要的内容，比如增加 distinct 来配合使用  
mysql> select count(distinct price) from books where price>40;
+-----------------------+
| count(distinct price) |
+-----------------------+
|                    26 |
+-----------------------+
1 row in set (0.00 sec)
```

```
mysql> Select min(price),max(price) from books ;				#可以多个聚合函数组合使用
+------------+------------+
| min(price) | max(price) |
+------------+------------+
|         34 |       7500 |
+------------+------------+
1 row in set (0.00 sec)
```

#### 5.2.算数运算（禁止在数据库做计算）

\+ - * /
给所有价格小于 40 元的书籍，涨价 5 元
mysql> update books set price=price+5 where price<40; 
给所有价格高于 70 元的书籍打 8 折
mysql> update books set price=price*0.8 where price>70;
在查询中查看修改后的价格
mysql>  select bName,price-4 as price from books where price<40;

#### 5.3字符串函数

substr(string ,start,len) 截取：从 start 开始，截取 len 长.start 从 1 开始算起。

```
mysql> select substr(bTypeName,1,7) from category where bTypeId=10;
+-----------------------+
| substr(bTypeName,1,7) |
+-----------------------+
| AutoCAD               |       #本来是 AutoCAD 技术
+-----------------------+
1 row in set (0.00 sec)

```

```
mysql> select substr(bTypeName,8,2)from category where bTypeId=10;
+-----------------------+
| substr(bTypeName,8,2) |
+-----------------------+
| 技术                  |
+-----------------------+
1 row in set (0.00 sec)

```

concat(str1,str2,str3.....) 拼接，把多个字段拼成一个字段输出（重点）

```
mysql> select concat(bName,publishing) from books;
+------------------------------------------------------------------------------+
| concat(bName,publishing)                                                     |
+------------------------------------------------------------------------------+
| 网站制作直通车电脑爱好者杂志社                                               |
| 黑客与网络安全航空工业出版社                                                 |
| 网络程序与设计－asp北方交通大学出版社                                        |
| pagemaker 7.0短期培训教程中国电力出版社                                      |
| 黑客攻击防范秘笈北京腾图电子出版社                                           |
。。。。。
| SQL Server 7.0数据库系统管理与应用开发人民邮电出版社                         |
| ASP 3初级教程机械工业出版社                                                  |
| XML 完全探索中国青年出版社                                                   |
+------------------------------------------------------------------------------+
44 rows in set (0.00 sec)

```

```
mysql> select concat(bName,"-----",publishing) from books;        #同上边的结果是一样的
+------------------------------------------------------------------------------------+
| concat(bName,"------",publishing)                                                  |
+------------------------------------------------------------------------------------+
| 网站制作直通车------电脑爱好者杂志社                                               |
| 黑客与网络安全------航空工业出版社                                                 |
| 网络程序与设计－asp------北方交通大学出版社                                        |
| pagemaker 7.0短期培训教程------中国电力出版社                                      |
| 黑客攻击防范秘笈------北京腾图电子出版社                                           |
。。。。


```

```
mysql> select concat(max(price),"------",min(price)) from books;			#拼接可以里面接聚合函数
+----------------------------------------+
| concat(max(price),"------",min(price)) |
+----------------------------------------+
| 7500------34                           |
+----------------------------------------+
1 row in set (0.00 sec)

```

#### 5.4.大小写转换

upper()大写 : 转为大写输出

```
mysql> select upper(bname) from books where bId=9;
+---------------------------+
| upper(bname)              |
+---------------------------+
| DREAMWEAVER 4网页制作     |
+---------------------------+
1 row in set (0.00 sec)

```

lower()小写：转为小写输出

```
mysql> select lower(bName) from books where bId=10;
+-------------------------------+
| lower(bName)                  |
+-------------------------------+
| 3d max 3.0 创作效果百例       |
+-------------------------------+
1 row in set (0.00 sec)
```

#### 5.5.group by的常规用法

group by的常规用法是配合聚合函数，利用分组信息进行统计，常见的是配合max等聚合函数筛选数据后分析，以及配合having进行筛选后过滤

新建 表：

create table test15 (id int AUTO_INCREMENT,user_id varchar(15),grade char(5),class char(5),PRIMARY KEY(`id`))ENGINE=INNODB charset=utf8;

insert  into test15 (user_id,grade,class)values(10221,'A','a'),(10222,'A','a'),(10223,'A','b'),(10224,'A','b'),(10225,'B','a'),(10226,'B','a'),(10227,'B','b'),(10228,'B','b'),(10229,'C','a'),(10230,'C','b');

![8](https://s2.loli.net/2022/02/24/cy7hjs9GpAFSBJl.png)

mysql>select max(user_id),grade from test15 group by grade ;
![9](https://s2.loli.net/2022/02/24/dMnjsTiDw3zoACL.png)

mysql>select max(user_id),grade from test15 group by grade having grade>'A';
![10](https://s2.loli.net/2022/02/24/U3zbAm71gSVRIpN.png)

mysql>select max(user_id),grade from test15 group by class;   #聚合函数可接字段，但一定要是gruop by 接的字段

![image-20220825165739599](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202208251657655.png)



mysql>select max(user_id),class from test15 group by grade  having class>='a';		#having后接字段，也一定要是gruop by 接的字段

![image-20220825170954433](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202208251709489.png)



### **6、合并查询**

1.union:  数据库系统会将所有的查询结果合并到一起，然后相同的记录去重；

```
mysql> select bTypeId,bName from books  UNION select * from category;
+---------+---------------------------------------------------------+
| bTypeId | bName                                                   |
+---------+---------------------------------------------------------+
| 2       | 网站制作直通车                                          |
| 6       | 黑客与网络安全                                          |
| 2       | 网络程序与设计－asp                                     |
。。。。。。
| 7       | 网络技术                                                |
| 8       | 安全                                                    |
| 9       | 平面                                                    |
| 10      | AutoCAD技术                                             |
+---------+---------------------------------------------------------+
53 rows in set (0.00 sec)

```

```
mysql> select bTypeId from books  UNION select bTypeId from category;
+---------+
| bTypeId |
+---------+
| 2       |
| 6       |
| 9       |
| 7       |
| 3       |
| 10      |
| 8       |
| 4       |
| 1       |
| 5       |
+---------+
10 rows in set (0.00 sec)

```

2.union all:  不会去除掉重复的记录；

```
mysql> select bTypeId from books  UNION ALL select bTypeId from category;
+---------+
| bTypeId |
+---------+
| 2       |
| 6       |
| 2       |
| 9       |
| 6       |
。。。。。。
| 4       |
| 5       |
| 6       |
| 7       |
| 8       |
| 9       |
| 10      |
+---------+
54 rows in set (0.00 sec)
```



注：union与union all的区别

union与union all 都是合并查询结果，但union会去重相同的结果，union all不会去重







### 7、视图 

什么是视图：
视图就是一个存在于数据库中的虚拟表。
视图本身没有数据，只是通过执行相应的 select 语句完成获得相应的数据。

我们在怎样的场景使用它，为什么使用视图   ：
如果某个查询结果出现的非常频繁，也就是，要经常拿这个查询结果来做子查询这种 

1.视图能够简化用户的操作
视图机制用户可以将注意力集中在所关心的数据上。如果这些数据不是直接来自基本表，则可以通过 定义视图，使数据库看起来结构简单、清晰，并且可以简化用户的数据查询操作

2.视图是用户能以不同的角度看待同样的数据。
对于固定的一些基本表，我们可以给不同的用户建立不同的视图，这样不同的用户就可以看到自己需要的信息了。

3.视图对重构数据库提供了一定程度的逻辑性。
比如原来的 A 表被分割成了 B 表和 C 表，我们仍然可以在 B 表和 C 表的基础上构建一个视图 A ，而使用该数据表的程序可以不变。

4.视图能够对机密数据提供安全保护
比如说，每门课的成绩都构成了一个基本表，但是对于每个同学只可以查看自己这门课的成绩，因此 可以为每个同学建立一个视图，隐藏其他同学的数据，只显示该同学自己的

5.适当的利用视图可以更加清晰的表达查询数据。
有时用现有的视图进行查询可以极大的减小查询语句的复杂程度。

#### 7.1创 建 视 图

语法：create view 视图名称（即虚拟的表名） as select 语句。 

创建视图
mysql> create view bc as select b.bName ,b.price ,c.bTypeName from books as b left join category as c   on b.bTypeId=c.bTypeId ;
可以按照普通表去访问。

<font color='red'>注：修改原数据表中数据，视图表中的数据也会修改;但修改视图表中的数据，则不能修改原数据表中数据</font>

#### 7.2. 查看视图创建信息

```
mysql> show create view bc \G
*************************** 1. row ***************************
                View: bc
         Create View: CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `bc` AS select `b`.`bName` AS `bName`,`b`.`price` AS `price`,`c`.`bTypeName` AS `bTypeName` from (`books` `b` left join `category` `c` on((`b`.`bTypeId` = `c`.`bTypeId`)))
character_set_client: utf8
collation_connection: utf8_general_ci
1 row in set (0.00 sec)

```

#### 7.3. 查询视图中的数据

```
mysql>  select * from bc where price<40\G
*************************** 1. row ***************************
    bName: 网站制作直通车
    price: 34
bTypeName: 网站
*************************** 2. row ***************************
    bName: 黑客与网络安全
    price: 36
bTypeName: 黑客
*************************** 3. row ***************************
    bName: 网络程序与设计－asp
    price: 38
bTypeName: 网站
*************************** 4. row ***************************
    bName: pagemaker 7.0短期培训教程
    price: 38
bTypeName: 平面
*************************** 5. row ***************************
    bName: 黑客攻击防范秘笈
    price: 39
bTypeName: 黑客
*************************** 6. row ***************************
    bName: Dreamweaver 4入门与提高
    price: 39
bTypeName: 网站
6 rows in set (0.00 sec)

```

#### 7.4. 如何在库中查找视图

```
mysql> show table  status  where  comment ='view'\G
*************************** 1. row ***************************
           Name: bc
         Engine: NULL
        Version: NULL
     Row_format: NULL
           Rows: NULL
 Avg_row_length: NULL
    Data_length: NULL
Max_data_length: NULL
   Index_length: NULL
      Data_free: NULL
 Auto_increment: NULL
    Create_time: NULL
    Update_time: NULL
     Check_time: NULL
      Collation: NULL
       Checksum: NULL
 Create_options: NULL
        Comment: VIEW
1 row in set (0.00 sec)
```

#### 7.5    更 新 或 修 改 视 图

语法：
alter view 视图名称（即虚拟的表名）  as select 语句。
mysql> alter view bc as select b.bName ,b.publishing ,c.bTypeId from books as b left join category as c on b.bTypeId=c.bTypeId;
mysql> select * from bc\G
*************************** 1. row ***************************
     bName: 网站制作直通车
publishing: 电脑爱好者杂志社
   bTypeId: 2
*************************** 2. row ***************************
     bName: 黑客与网络安全
publishing: 航空工业出版社
   bTypeId: 6
。。。。。。
*************************** 43. row ***************************
     bName: ASP 3初级教程
publishing: 机械工业出版社
   bTypeId: 2
*************************** 44. row ***************************
     bName: XML 完全探索
publishing: 中国青年出版社
   bTypeId: 2
44 rows in set (0.00 sec)

#### 7.6    删 除 视 图

drop view 视图名。    
mysql> drop view bc;