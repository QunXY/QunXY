#                                               MYSQL基础语句1

## **1.字符集**

什么是[字符集](https://baike.baidu.com/item/字符集/946585?fr=aladdin)

MySQL提供了多种字符集（charset）和排序规则选择，其中字符集设置和数据存储以及客户端与MySQL实例的交互相关，排序规则和字符串的对比规则相关

字符集的设置可以在MySQL实例、数据库、表、列四个级别

MySQL设置字符集支持在InnoDB，MyISAM，Memory.三个存储引擎

查看当前ySQL支持的字符集的方式有两种，一种是通过查看information_schema.character_set系统表，一种是通过命令show character set查看

一般来说企业内常用，utf8或者utf8mb4两种字符集，字符集规则也用相应的引擎。
mysql>show charset;     #查看数据库支持的字符集

```
mysql> show charset; 
+----------+---------------------------------+---------------------+--------+
| Charset  | Description                     | Default collation   | Maxlen |
+----------+---------------------------------+---------------------+--------+
| big5     | Big5 Traditional Chinese        | big5_chinese_ci     |      2 |
| dec8     | DEC West European               | dec8_swedish_ci     |      1 |
| cp850    | DOS West European               | cp850_general_ci    |      1 |
| hp8      | HP West European                | hp8_english_ci      |      1 |
| koi8r    | KOI8-R Relcom Russian           | koi8r_general_ci    |      1 |
| latin1   | cp1252 West European            | latin1_swedish_ci   |      1 |
| latin2   | ISO 8859-2 Central European     | latin2_general_ci   |      1 |
| swe7     | 7bit Swedish                    | swe7_swedish_ci     |      1 |
| ascii    | US ASCII                        | ascii_general_ci    |      1 |
| ujis     | EUC-JP Japanese                 | ujis_japanese_ci    |      3 |
| sjis     | Shift-JIS Japanese              | sjis_japanese_ci    |      2 |
| hebrew   | ISO 8859-8 Hebrew               | hebrew_general_ci   |      1 |
| tis620   | TIS620 Thai                     | tis620_thai_ci      |      1 |
| euckr    | EUC-KR Korean                   | euckr_korean_ci     |      2 |
| koi8u    | KOI8-U Ukrainian                | koi8u_general_ci    |      1 |
| gb2312   | GB2312 Simplified Chinese       | gb2312_chinese_ci   |      2 |
| greek    | ISO 8859-7 Greek                | greek_general_ci    |      1 |
| cp1250   | Windows Central European        | cp1250_general_ci   |      1 |
| gbk      | GBK Simplified Chinese          | gbk_chinese_ci      |      2 |
| latin5   | ISO 8859-9 Turkish              | latin5_turkish_ci   |      1 |
| armscii8 | ARMSCII-8 Armenian              | armscii8_general_ci |      1 |
| utf8     | UTF-8 Unicode                   | utf8_general_ci     |      3 |
| ucs2     | UCS-2 Unicode                   | ucs2_general_ci     |      2 |
| cp866    | DOS Russian                     | cp866_general_ci    |      1 |
| keybcs2  | DOS Kamenicky Czech-Slovak      | keybcs2_general_ci  |      1 |
| macce    | Mac Central European            | macce_general_ci    |      1 |
| macroman | Mac West European               | macroman_general_ci |      1 |
| cp852    | DOS Central European            | cp852_general_ci    |      1 |
| latin7   | ISO 8859-13 Baltic              | latin7_general_ci   |      1 |
| utf8mb4  | UTF-8 Unicode                   | utf8mb4_general_ci  |      4 |
| cp1251   | Windows Cyrillic                | cp1251_general_ci   |      1 |
| utf16    | UTF-16 Unicode                  | utf16_general_ci    |      4 |
| utf16le  | UTF-16LE Unicode                | utf16le_general_ci  |      4 |
| cp1256   | Windows Arabic                  | cp1256_general_ci   |      1 |
| cp1257   | Windows Baltic                  | cp1257_general_ci   |      1 |
| utf32    | UTF-32 Unicode                  | utf32_general_ci    |      4 |
| binary   | Binary pseudo charset           | binary              |      1 |
| geostd8  | GEOSTD8 Georgian                | geostd8_general_ci  |      1 |
| cp932    | SJIS for Windows Japanese       | cp932_japanese_ci   |      2 |
| eucjpms  | UJIS for Windows Japanese       | eucjpms_japanese_ci |      3 |
| gb18030  | China National Standard GB18030 | gb18030_chinese_ci  |      4 |
+----------+---------------------------------+---------------------+--------+
41 rows in set (0.00 sec)
```

字符与字节的区别？[utf8与utf8mb4区别？](https://blog.csdn.net/grl18840839630/article/details/105597074/)

可以修改字符集，但只能从长度小的改成大的，不能从长度大的改成小的

## 2.排序规则

什么是[排序规则](https://www.jianshu.com/p/d231cb8d8893)

每个指定的字符集都会有一个或多个支持的排序规则，可以通过两种方式查看，一种是查看information schema.collations:表，另一种是通过showcollation命令查看

排序规则设置可以分为：MySQL实例级别、库级别、表级别、列级别以及SQL指定

不同的字符集不可能有相同的排序规则

每个字符集都会有一个默认的排序规则

```
mysql> show collation;
+--------------------------+----------+-----+---------+----------+---------+
| Collation                | Charset  | Id  | Default | Compiled | Sortlen |
+--------------------------+----------+-----+---------+----------+---------+
。。。。。。
| latin1_german1_ci        | latin1   |   5 |         | Yes      |       1 |
| latin1_swedish_ci        | latin1   |   8 | Yes     | Yes      |       1 |
| latin1_danish_ci         | latin1   |  15 |         | Yes      |       1 |
| latin1_german2_ci        | latin1   |  31 |         | Yes      |       2 |
| latin1_bin               | latin1   |  47 |         | Yes      |       1 |
| latin1_general_ci        | latin1   |  48 |         | Yes      |       1 |
| latin1_general_cs        | latin1   |  49 |         | Yes      |       1 |
| latin1_spanish_ci        | latin1   |  94 |         | Yes      |       1 |
| latin2_czech_cs          | latin2   |   2 |         | Yes      |       4 |
| latin2_general_ci        | latin2   |   9 | Yes     | Yes      |       1 |
| latin2_hungarian_ci      | latin2   |  21 |         | Yes      |       1 |
| latin2_croatian_ci       | latin2   |  27 |         | Yes      |       1 |
| latin2_bin               | latin2   |  77 |         | Yes      |       1 |

| utf8_general_ci          | utf8     |  33 | Yes     | Yes      |       1 |
| utf8_bin                 | utf8     |  83 |         | Yes      |       1 |
| utf8_unicode_ci          | utf8     | 192 |         | Yes      |       8 |
| utf8_icelandic_ci        | utf8     | 193 |         | Yes      |       8 |
| utf8_latvian_ci          | utf8     | 194 |         | Yes      |       8 |
| utf8_romanian_ci         | utf8     | 195 |         | Yes      |       8 |
| utf8_slovenian_ci        | utf8     | 196 |         | Yes      |       8 |
| utf8_polish_ci           | utf8     | 197 |         | Yes      |       8 |
| utf8_estonian_ci         | utf8     | 198 |         | Yes      |       8 |
| utf8_spanish_ci          | utf8     | 199 |         | Yes      |       8 |
| utf8_swedish_ci          | utf8     | 200 |         | Yes      |       8 |
| utf8_turkish_ci          | utf8     | 201 |         | Yes      |       8 |
| utf8_czech_ci            | utf8     | 202 |         | Yes      |       8 |
| utf8_danish_ci           | utf8     | 203 |         | Yes      |       8 |
| utf8_lithuanian_ci       | utf8     | 204 |         | Yes      |       8 |
| utf8_slovak_ci           | utf8     | 205 |         | Yes      |       8 |
| utf8_spanish2_ci         | utf8     | 206 |         | Yes      |       8 |
| utf8_roman_ci            | utf8     | 207 |         | Yes      |       8 |
| utf8_persian_ci          | utf8     | 208 |         | Yes      |       8 |
| utf8_esperanto_ci        | utf8     | 209 |         | Yes      |       8 |
| utf8_hungarian_ci        | utf8     | 210 |         | Yes      |       8 |
| utf8_sinhala_ci          | utf8     | 211 |         | Yes      |       8 |
| utf8_german2_ci          | utf8     | 212 |         | Yes      |       8 |
| utf8_croatian_ci         | utf8     | 213 |         | Yes      |       8 |
| utf8_unicode_520_ci      | utf8     | 214 |         | Yes      |       8 |
| utf8_vietnamese_ci       | utf8     | 215 |         | Yes      |       8 |
| utf8_general_mysql500_ci | utf8     | 223 |         | Yes      |       1 |
。。。。。
+--------------------------+----------+-----+---------+----------+---------+

```

![image-20220823213533504](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202208232135621.png)



实战：

```
mysql> create database test;
Query OK, 1 row affected (0.00 sec)


mysql> show create database test;							#查看库的字符集
+----------+-----------------------------------------------------------------+
| Database | Create Database                                                 |
+----------+-----------------------------------------------------------------+
| test     | CREATE DATABASE `test` /*!40100 DEFAULT CHARACTER SET latin1 */ |
+----------+-----------------------------------------------------------------+
1 row in set (0.00 sec)



mysql> use test
Database changed
mysql> create table test1 (name varchar (30),home varchar (30))；
Query OK, 0 rows affected (0.00 sec)

mysql> show create table test1;				查看表的字符集
+-------+-----------------------------------------------------------------------------------------------------------------------------------+
| Table | Create Table                                                                                                                      |
+-------+-----------------------------------------------------------------------------------------------------------------------------------+
| test1  | CREATE TABLE `test` (
  `name` varchar(30) DEFAULT NULL,
  `home` varchar(30) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 |
+-------+-----------------------------------------------------------------------------------------------------------------------------------+
1 row in set (0.00 sec)

mysql> insert into test values('china','中国');
ERROR 1366 (HY000): Incorrect string value: '\xE4\xB8\xAD\xE5\x9B\xBD' for column 'home2' at row 1



mysql> show full columns from test1;			#查看列的字符集
+-------+-------------+-------------------+------+-----+---------+-------+---------------------------------+---------+
| Field | Type        | Collation         | Null | Key | Default | Extra | Privileges                      | Comment |
+-------+-------------+-------------------+------+-----+---------+-------+---------------------------------+---------+
| name  | varchar(30) | latin1_swedish_ci | YES  |     | NULL    |       | select,insert,update,references |         |
| home  | varchar(30) | latin1_swedish_ci | YES  |     | NULL    |       | select,insert,update,references |         |
+-------+-------------+-------------------+------+-----+---------+-------+---------------------------------+---------+


mysql> alter table `test1` modify home varchar(45) charset utf8 collate utf8_general_ci;
Query OK, 0 rows affected (0.00 sec)
Records: 0  Duplicates: 0  Warnings: 0


mysql> show full columns from test1;				
+-------+-------------+-------------------+------+-----+---------+-------+---------------------------------+---------+
| Field | Type        | Collation         | Null | Key | Default | Extra | Privileges                      | Comment |
+-------+-------------+-------------------+------+-----+---------+-------+---------------------------------+---------+
| name  | varchar(30) | latin1_swedish_ci | YES  |     | NULL    |       | select,insert,update,references |         |
| home  | varchar(45) | utf8_general_ci   | YES  |     | NULL    |       | select,insert,update,references |         |
+-------+-------------+-------------------+------+-----+---------+-------+---------------------------------+---------+
2 rows in set (0.00 sec)


mysql> insert into test values('china','中国');
Query OK, 1 row affected (0.00 sec)
```











**2.	Mysql 的sql模式**
5.5 默认关闭，5.6，5.7 默认开启。

查看严格模式内容选项：

mysql> show variables like 'sql_mode';

修改严格模式的内容选项：

往配置文件/etc/my.cnf中添加参数：
[mysqld]

sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES


![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\1.png](https://s2.loli.net/2022/02/14/okS9rpF6mefTxMh.png)

## **3.** **SQL 概述**

结构化查询语言(Structured Query Language)简称SQL ，是一种特殊目的的编程语言，是一种数据库查询和程序设计语言 ，
用于存取数据以及查询、更新和管理关系数据库系统 ，同时也是数据库脚本文件的扩展名。
从上可以看出我们数据库相关工作职位大概两种：DBA 和 DBD
DBA 是数据库管理员database administrator 
DBD 是数据库开发人员database developer
SQL 是 1986 年 10 月由美国国家标准局（ANSI）通过的数据库语言美国标准，接着，国际标准化 组织（ISO）颁布了 SQL 正式国际标准。1989 年 4 月，ISO 提出了具有完整性特征的 SQL89 标准，1992 年 11 月又公布了 SQL92 标准。

3.1. 常见 sql 语句
Select 查询  Insert 插入   Delete 删除 Update 更新
3.2. 理解数据库：数据库是一个有组织的，根据具体标准分类的数据集合
例如：
• 档案柜=数据库服务器
• 抽屉=数据库
• 文件=表
• 文件中每条信息=记录

## **4.**SQL 语句结构（面试常问题）

<font color='red'>数据控制语言（DCL）</font> 它的语句通过 GRANT 或 REVOKE 获得许可，确定单个用户和用户组对数据库对象的访问。某些 RDBMS 可用 GRANT 或 REVOKE 控制对表单个列的访问。
<font color='red'>数据定义语言（DDL）</font> 其语句包括动词 CREATE 和 DROP。在数据库中创建新表或删除表（CREAT TABLE 或 DROP  TABLE）；为表加入索引等。DDL 包括许多与人数据库目录中获得数据有关的保留字。它也是动作查询的 一部分
<font color='red'>数据操作语言（DML</font>） 其语句包括动词 INSERT，UPDATE 和 DELETE。它们分别用于添加，修改和删除表中的行。也称为 动作操作语言。 
<font color='red'>数据查询语言 （DQL）</font>其语句，也称为“数据检索语句”，用以从表中获得数据，确定数据怎样在应用程序给出。保留字 SELECT 是 DQL（也是所有 SQL）用得最多的动词，其他 DQL 常用的保留字有 WHERE，ORDER BY， GROUP BY 和 HAVING。这些 DQL 保留字常与其他类型的 SQL 语句一起使用。

mysql>show databases; （5.7版本一开始有4个库，5.7以前是3个库）
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\2.png](https://s2.loli.net/2022/02/14/1jHBJKuE3VPM8rh.png)
注：
（1） information_schema    #这数据库保存了 MySQL 服务器所有数据库的信息。如数据库名， 数据库的表，表栏的数据类型与访问权限等。 
（2） performance_schema  #MySQL 5.5 开始新增一个数据库：PERFORMANCE_SCHEMA ，
主要用于收集数据库服务器性能参数。并且库里表的存储引擎均为 PERFORMANCE_SCHEMA ，而用户 是不能创建存储引擎为 PERFORMANCE_SCHEMA 的表。
（3） mysql 库是系统库，里面保存有账户信息，权限信息等。
（4) MySQL 5.7 增加了sys 系统数据库，通过这个库可以快速的了解系统的元数据信息。元数据 是关于数据信息的数据，如：数据库名或表名，列的数据类型，或访问权限等。



mysql>create database test_db;                  #创库语法：create database 库名
mysql>create schema sch;
mysql>show variables like 'character%';      #显示默认建立的字符集
mysql>show create database test_db;         #显示建库语句
mysql>create database test_db1 default character set utf8 ;
mysql>create database test charset utf8; (常用)
mysql>alter database test charset utf8;          #修改字符集
mysql>drop database test ;                       #高危操作，慎用
mysql><font color='red'>drop</font> database <font color='red'>if   exists</font> books;            #如果存在数据库books，则删除
mysql><font color='red'>create</font> database <font color='red'>if not exists</font> books;      #如果不存在数据库books，则创建

建库规范： 
1.库名尽量不要有大写字母 ，不能使用保留字符 （反引号会强制创建）
2.建库要加字符集         
3.库名尽量不能有数字开头
4.库名要和业务相关



## **5.数据类型**（表的字段）

5.1、字符串类型：
• char(11) ：
定长的字符串类型,在存储字符串时，最大字符长度11个，立即分配11个字符长度的存储空间，如果存不满，空格填充。
• varchar(11):
变长的字符串类型看，最大字符长度11个。在存储字符串时，自动判断字符长度，不会用空格填充。按需分配存储空间。
enum('bj','tj','sh')：
枚举类型，比较适合于将来此列的值是固定范围内的特点，可以使用enum,
可以很大程度的优化我们的索引结构
enum（'bj','sh'。。。。）枚举类型
             1， 2，。。。。

![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\3.png](https://s2.loli.net/2022/02/14/CTLzqHXyjW4wrmb.png)



5.2、数字类型：
在MySQL的数据类型中，Tinyint的取值范围是：带符号的范围是-128到127。
Tinyint占用1字节的存储空间，即8位（bit）。那么Tinyint的取值范围怎么来的呢？我们先看无符号的情况。无符号的最小值即全部8位（bit)都为0，换算成十进制就是0，所以无符号的Tinyint的最小值为0.无符号的最大值即全部8bit都为1，11111111，换算成十进制就是255.这很好理解。
有符号的Tinyint的取值范围是怎么来的呢？在计算机中，用最高位表示符号。0表示正，1表示负，剩下的表示数值。那么有符号的8bit的最小值就是
　　1　　1　　1　　1　　1　　1　　1　　1=-127
表示负值
最大值：
　　0　　1　　1　　1　　1　　1　　1　　1=+127
表示正值
为什么有符号的TINYINT的最小值是-128？虽然“-0”也是“0”，但根据正、反、补码体系，“-0”的补码和“+0”是不同的，这样就出现两个补码代表一个数值的情况。为了将补码与数字一一对应，所以人为规定“0”一律用“+0”代表。同时为了充分利用资源，就将原来本应该表示“-0”的补码规定为代表-128。

int       ：-2^31~2^31-1（同上，计算可得，最高10位）
说明：手机号是无法存储到int的。一般是使用char类型来存储手机号
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\4.png](https://s2.loli.net/2022/02/14/DuJ15dliXhIPtG7.png)

5.3、时间类型：
应用最多
timestamp
datetime
DATETIME  8字节
范围为从 1000-01-01 00:00:00.000000 至 9999-12-31 23:59:59.999999。
TIMESTAMP 4字节
1970-01-01 00:00:00.000000 至 2038-01-19 03:14:07.999999。
timestamp会受到时区的影响
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\5.png](https://s2.loli.net/2022/02/14/IO5T1wga2LfyUGD.png)
二进制类型：
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\6.png](https://s2.loli.net/2022/02/14/H1bhvBrmekSJX7i.png)

建表语句示例：
mysql > CREATE TABLE `student` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `name` char(64) NOT NULL,
  `addr` char(64) NOT NULL,
  `phone_num` varchar(11) unique key,
  `gender` tinyint(3) NOT NULL,
  PRIMARY KEY (`id`)
) ;

mysql >show create table student\G
CREATE TABLE `student` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `name` char(64) NOT NULL,
  `addr` char(64) NOT NULL,
  `phone_num` varchar(11) NOT NULL,
  `gender` tinyint(3) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;



like关键字：创建表时以另一张表的格式创建

```
mysql> create table teacher like stduent;	
mysql >show create table teacher
CREATE TABLE `student` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `name` char(64) NOT NULL,
  `addr` char(64) NOT NULL,
  `phone_num` varchar(11) NOT NULL,
  `gender` tinyint(3) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


```






设计表的时候设置数据类型，设计约束和唯一主键：

## **6.****字段属性  (约束 )：**

primary key ：主键约束
作用：唯一且非空每张表只能有一个主键。

not null ： 非空约束，作用：必须非空。
列值不能为空，也是表设计的规范，尽可能将所有的列设置为非空。可以设置默认值为0

unique key ：唯一键 唯一约束。
列值不能重复

unsigned：无符号
针对数字列，非负数。

key :索引
可以在某列上建立索引，来优化查询,一般是根据需要后添加

default +值           :默认值
列中，没有录入值时，会自动使用default的值填充

comment ' 内容 ' : 注释，对内容的解释

auto_increment   :自增长
AUTO_INCREMENT说明：
（1）如果把一个NULL插入到一个AUTO_INCREMENT数据列里去，MySQL将自动生成下一个序列编号。编号从 1 开始，并以1为基数递增。
（2）把0插入AUTO_INCREMENT数据列的效果与插入NULL值一样。但不建议这样做，还是以插入NULL值为好。
（3）当插入记录时，没有为AUTO_INCREMENT明确指定值，则等同插入NULL值。
（4）当插入记录时，如果为AUTO_INCREMENT数据列明确指定了一个数值，则会出现两种情况，情况一，如果插入的值与已有的编号重复，则会出现出错信息，因为AUTO_INCREMENT数据列的值必须是唯一的；

情况二，如果插入的值大于已编号的值，则会把该插入到数据列中，并使在下一个编号将从这个新值开始递增。也就是说，可以跳过一些编号。
（5）如果用UPDATE命令更新自增列，如果列值与已有的值重复，则会出错。如果大于已有值，则下一个编号从该值开始递增。

（6）AUTO_INCREMENT=33，下次增加数据序列编号从34开始



null 和 not null 修饰符（优化的一种）
我们通过这个例子来看看
[root@mysql1 ~]# mysql -u root   -p123456
mysql> create database today charset utf8; 
mysql> use today;
mysql> create table worker(id int not null,name varchar(8) not null,pass varchar(20) not null);
mysql> insert into worker values(1,'HA','123456');
mysql> insert into worker values(1,'LB',null);
ERROR 1048 (23000): Column 'pass' cannot be null         #不能为 null
mysql> insert into worker values(2,'HPC','');
注：NOT NULL 的字段是不能插入 “NULL”的，只能插入 “空值”。

1. 我们可能有这些疑问<null 和not null 区别>
   （1） 字段类型是 not null ，为什么可以插入空值
   （2）  not null 与null的效率谁高
   （3） 如何判断字段不为空的时候，

2. “空值” 和   “NULL”有什么不一样？
   （1） 空值是不占用空间的
   （2） MySQL 中的 NULL 其实是占用空间的，下面是来自于 MySQL 官方的解释
   “NULL columns require additional space in the row to record whether their values are  NULL. For MyISAM tables, each NULL column takes one bit extra, rounded up to the nearest byte.”
   \#“空列需要行中的额外空间来记录其值是否为空。对于 MyISAM 表，每个 NULL 列需要一个额外 的位，四舍五入到最接近的字节。
   比如：一个杯子，空值' '代表杯子是真空的，NULL 代表杯子中装满了空气，虽然杯子看起来都是空的， 但是里面是有空气的。

3. 对于问题 2 ，为什么 not null 的效率比 null 高？
   NULL 其实并不是空值，而是要占用空间，所以 mysql 在进行比较的时候，NULL 会参与字段比较， 所以对效率有一部分影响。
   而且索引时不会存储 NULL 值的，所以如果索引的字段可以为 NULL ，索引的效率会下降很多。
   -MySQL 难以优化引用null查询，它会使索引、索引统计和值更加复杂。null需要更多的存储空 间，还需要 MySQL 内部进行特殊处理。null被索引后，每条记录都需要一个额外的字节，还能导致  innodb中固定大小的索引变成可变大小的索引--------这也是《高性能 MySQL 第二版》介绍的解读： “可空列需要更多的存储空间” ：需要一个额外字节作为判断是否为 NULL 的标志位 “需要 MySQL 内部 进行特殊处理”
   所以使用not null 比 null 效率高

4. 对于问题 3，判断字段不为空的时候，到底要   select * from table where column <> ' ' 还是
   要用 select * from table where column is not null 我们举例看看（不能用is not null ）
   mysql> create table test(col1 varchar(10) not null, col2 varchar(10) null)ENGINE=InnoDB;
   mysql> insert into test values(' ',null); 
   mysql> insert into test values('1','2'); 
   mysql> insert into test values(' ','1'); 
   mysql> select * from test;

   ```
   +------+------+
   | col1 | col2 |
   +------+------+
   |      | NULL |
   | 1    | 2    |
   |      | 1    |
   +------+------+
   3 rows in set (0.00 sec)
   ```

   下面我分别用这两条语句查询看看
   mysql> select * from test where col1 is not null;

   ```
   +------+------+
   | col1 | col2 |
   +------+------+
   |      | NULL |
   | 1    | 2    |
   |      | 1    |
   +------+------+
   3 rows in set (0.00 sec)
   ```

   mysql> select * from test where col1 <>'';

   ```
   +------+------+
   | col1 | col2 |
   +------+------+
   | 1    | 2    |
   +------+------+
   1 row in set (0.00 sec)
   ```

   总结：为空表示不占空间，null 占用空间

注意事项：

1. 在进行count()统计某列的记录数的时候，如果采用的NULL值，系统会自动忽略掉，但是空值是会进行统计到其中的。
2. 判断NULL 用IS NULL 或者 IS NOT NULL,SQL语句函数中可以使用ifnull()函数来进行处理，判断空字符用<font color='red'>=’‘</font>或者<font color='red'> <>’'</font>来进行处理
3. 对于MySQL特殊的注意事项，对于timestamp数据类型，如果往这个数据类型插入的列插入NULL值，则出现的值是当前系统时间。插入空值，则会出现 0000-00-00 00:00:00
4. 对于空值的判断到底是使用is null 还是=’’ 要根据实际业务来进行区分。

