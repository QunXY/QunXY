##                                                        索引与外键



索引是一种特殊的文件（InnoDB 数据表上的索引是表空间的一个组成部分） ，它们包含着对数据表里所有记录的引用指针。
更通俗的说，数据库索引好比是一本书前面的目录，能加快数据库的查询速度。

索引的实质是什么？    
从原始表中，选择一个或多个字段，并按照这些字段 排序  而产生的一张额外表

举例：
全表扫描  VS 索引扫描

以字典为例，全表扫描就是如果我们查找某个字时，那么通读一遍新华字典，然后找到我们想要找到的字，
而跟全表扫描相对应的就是索引查找，索引查找就是在表的索引部分找到我们想要找的数据具体位置，
然后会到表里面将我们想要找的数据全部查出。

一个索引的实例：在一张学生表找到名字叫  Dev%  的学生， 显示名字            

![file://c:\users\admini~1\appdata\local\temp\tmp5hdd8k\1.png](https://s2.loli.net/2022/02/28/HnwXMB8PWGEAOqN.png)

左边全表扫描：需要从第一行开始一行行的扫描，直到找到100008行Dev这个学生的信息为止，将这个数据返回回来，
但有可能该表中还有同名的学生，因此扫描并没有结束，通常全表扫描要找到一个数据，是需要将整张表的数据遍历一遍，
然后才能确定是否将所有数据返回。

右边索引扫描：索引查找是以name字段建立索引，然后根据首字母排序  找到D开头的，如果首字母相同，那么再根据第二个字母排序找到，以此类推，我们找到name=Dev记录，然后查出ID为100008的那一行数据。

优点：为了加快搜索速度，减少查询时间。 
缺点：

1.索引是以文件存储的。如果索引过多，占磁盘空间较大。而且他影响： insert ,update,delete 执行时间。

2.索引中数据必须与数据表数据同步：如果索引过多，当表中数据更新的时候后，索引也要同步更新， 这就降低了效率。

基于算法的索引类型
1.B树索引
2.hash索引
3.GIS索引

![image-20220425103644544](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202204251036638.png)

基于功能的索引类型：
\1. 主键索引 (聚簇索引)
\2. 普通索引（辅助索引）
\3. 唯一性索引
\4. 复合索引(联合索引)
\5. 全文索引

聚簇索引是对磁盘上实际数据重新组织以按指定的一个或多个列的值排序的算法。特点是存储数据的顺序和索引顺序一致。
一般情况下主键会默认创建聚簇索引，且一张表只允许存在一个聚簇索引。
 对 innodb来说, 
1: 主键索引 既存储索引值,又存储行的数据
2: 如果没有主键, 则会Unique key（唯一索引）做主键 
3: 如果没有unique,则系统生成一个内部隐藏的rowid做主键.
4: 像innodb中,主键的索引结构中,既存储了主键值,又存储了行数据,这种结构称为”聚簇索引”
作用：
有了聚簇索引后，将来插入数据行，在同一区内，都会按照设定的ID值顺序，有序在磁盘存储。

<font color='red'>insert update delete 语句会引起聚簇索引立即更新，辅助索引不是实时更新。</font>

\4. 3. 3    主 键 索 引
查询数据库，按主键查询是最快的，每个表只能有一个主键索引 ，但可以有多个普通索引列。主键列要求列的所有内容必须唯一，而索引列不要求内容必须唯一，但不允许为空
1.创建主键索引
mysql> create table demo5( id int(4) not null auto_increment, name varchar(20) default null,primary key(id));

查看索引的方法：
方法1：
mysql> desc demo5;
![file://c:\users\admini~1\appdata\local\temp\tmp5hdd8k\3.png](https://s2.loli.net/2022/02/28/qNQczmtO2rHInxC.png)

方法2
show index from 表名;
mysql> show index from demo5 \G
![file://c:\users\admini~1\appdata\local\temp\tmp5hdd8k\4.png](https://s2.loli.net/2022/02/28/P4Eu5Ja2rbzY6Ad.png)



\4. 3. 1    普通索引(辅助索引)
最基本的索引，不具备唯一性，就是加快查询速度

创建普通索引 ：
方法一：创建表时添加索引 
create table 表名（
列定义

语法：<font color='red'>index/key  索引名称（字段）</font> 	#索引名称可以加，也可以不加，不加默认以字段为索引名称
）

举例：
mysql> create table demo( id int(4), name varchar(20), pwd varchar(20), <font color='red'>index</font>(pwd) );
mysql> create table demo1( id int(4), name varchar(20), pwd varchar(20), <font color='red'>key</font>(pwd) );
注意：index 和 key 是相同的
mysql> create table demo2( id int(4), name varchar(20), pwd varchar(20), key index_pwd(pwd) );   #加上名称

![image-20220425110743064](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202204251107098.png)



 方法二： 当表创建完成后，使用 alter 为表添加索引
mysql>alter table 表名 add index 索引名称   （字段 1，字段 2..... ）; 
mysql>CREATE INDEX 索引名称  ON  表名 (索引关联字段);

例：create index name on demo2(name);



\4. 3. 2    唯 一 索 引
与普通索引基本相同，但有一个区别：索引列的所有值都只能出现一次，即必须唯一，用来约束内容， 字段值只能出现一次 ，应该加唯一索引。<font color='red'>唯一性允许有 NULL 值 <允许为空> </font>。
创建唯一索引：
方法一：创建表时，加唯一索引 
create table 表名(
列定义：
unique index 索引名   （字段）; 
)
注意：常用在值不能重复的字段上，比如说用户名，电话号码，身份证号。
mysql> create table demo3(id int(4) auto_increment primary key, uName varchar(20), uPwd varchar(20), unique   index   (uName));
![file://c:\users\admini~1\appdata\local\temp\tmp5hdd8k\5.png](https://s2.loli.net/2022/02/28/47WjigXlz61CQfh.png)

方法二：修改表时，加唯一索引
alter table 表名 add unique 索引名 (字段);         
mysql> alter table demo3 drop key uName;      
mysql> alter table demo3 add unique(uName);
 CREATE UNIQUE INDEX 索引名字 ON 表名 (索引关联字段);

<font color='red'>总结：主键索引，唯一性索引区别：主键索引不能有 NULL ，唯一性索引可以有空值</font>

\4. 3. 4    复合索引
索引可以包含一个、两个或更多个列。两个或更多个列上的索引被称作复合索引 
<font color='red'>联合索引又叫复合索引</font>。对于复合索引:<font color='red'>最左原则</font>：Mysql从左到右的使用索引中的字段，一个查询可以只使用索引中的一部份，但只能是最左侧部分。例如索引是key index (a,b,c). 可以支持a | a,b| a,b,c 3种组合进行查找，但不支持 b,c或c的组合进行查找 .当最左侧字段是常量引用时，索引就十分有效。

两个或更多个列上的索引被称作复合索引。
利用索引中的附加列，您可以缩小搜索的范围，但使用一个具有两列的索引不同于使用两个单独的索引。复合索引的结构与电话簿类似，人名由姓和名构成，电话簿首先按姓氏对进行排序，然后按名字对有相同姓氏的人进行排序。如果您知 道姓，电话簿将非常有用；如果您知道姓和名，电话簿则更为有用，但如果您只知道名不姓，电话簿将没有用处

方法1：创建表时，添加复合索引：
create table 表名（
列定义，
index   索引名   （字段1,字段2，...）;
）

mysql> CREATE TABLE garde (
		id INT,
		name VARCHAR(30) ,
		garde VARCHAR(50),
INDEX people (name, garde)
		);        
mysql> desc garde;
![image-20220425113004561](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202204251130600.png)

注：此时只显示name为普通索引，看不出复合索引

需要执行show index from garde\G

![image-20220425113139862](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202204251131916.png)

注：此时才能看联合索引people 包含了两个字段：一个是name，一个是garde;



 方法2：修改表时，加复合索引
mysql> alter table 表名 add index 索引名 (字段1,字段2);
mysql> CREATE INDEX  索引名字 ON 表名 (索引关联字段1, 索引关联字段2);



\4. 3. 5    全 文 索 引   (F ULLT EXT INDEX)  
全文索引（也称全文检索）是目前搜索引擎使用的一种关键技术。它能够利用"分词技术"等多种算法智能分析出文本文字中关键字词的频率及重要性，然后按照一定的算法规则智能地筛选出我们想要的搜索结果 。

查看表当前默认的存储引擎：                                                                             
mysql> show create table 表名;                                                                    
全文索引只能用在 varchar text 数据类型

创建全文索引：
方法一：创建表时创建
create table 表名（
列定义，
fulltext key 索引名  （字段）;
）

 方法二：创建表时添加
alter table 表名 add fulltext 索引名   （字段）;
CREATE FULLTEXT INDEX 索引名字 ON 表名 (索引关联字段);

<font color='red'>强烈注意：MySQL 自带的全文索引只能用于数据库引擎为 MyISAM的数据表，如果是其他数据引擎， 则全文索引不会生效 。</font>
一般交给第三方软件进行全文索引。
http://sphinxsearch.com/

删除索引
DROP INDEX 索引名 ON 表名;



合理选择适合字段创建索引？

1、字段值的重复程度，如图：
![file://c:\users\admini~1\appdata\local\temp\tmp5hdd8k\6.png](https://s2.loli.net/2022/02/28/GYTa6rqtEOSQ94Z.png)


身份证号码由于基本上不可能重复，因此选择性非常好，而人的名字重复性较低，选择性也不错， 性别选择性较差，重复度非常高

2、选择性很差的字段通常不适合创建索引 （索引列的 基数，对比 总数 太低）
如：男女比例相仿的表中，性别不适合创建单列索引，如果走索引不如走全表扫描，因为走索引的I/O开销更大

<font color='red'>什么是回表（重点）</font>

如果在选择性很差的字段上创建索引， 而且索引覆盖率没占全表的25%以上，可能会导致 Mysql 查询优化器自行判断放弃使用这种索引，而去执行全表扫描，这种就是回表。

索引不能完全覆盖的情况下会出现回表，Mysql 的查询优化器会自动进行选择，决定放弃使用该索引如果回表过多会产生大量I/O，导致iops（I/O压力）增大，

怎么避免或者减少回表？
1.将查询尽可能的用id的主键列查询。
2.设置合理的辅助索引或者联合索引。（完全覆盖）（精确的查询条件）
3.联合/多列 索引中热门的字段应该排在前面




### QPS


Queries Per Second：每秒查询数，一台数据库每秒能够处理的查询次数

### TPS


Transactions Per Second：一台数据库每秒能够写入的次数（每秒处理的事务）

一般而言，QPS>TPS

举例：

中小型公司，QPS范围：2000~10000+；TPS范围：1000~8000+ （视公司数据量而定，仅做参考）



**索引效率验证：**

**使用 执行计划 desc 或 explain** 

explain  select * from today.salaries where salary='abcd';


使用 show status like "%last_query_cost%" ;查看



不走索引会发生什么情况？

<> ，not in 不走索引

mysql> select * from class.students where name like '%张'; ##无法使用索引
mysql>  select * from class.students where name like '张%'; ## 可以使用索引
mysql> select * from class.students  force  index(i_name)  where name like "张%";   ## 强制使用某个索引
mysql> select * from class.students  ignore index(i_name)  where name like "张%";  ##放弃使用某个索引





压力测试
 mysqlslap --defaults-file=/etc/my.cnf  \
--concurrency=100（人数） --iterations=1 （语句迭代次数）--create-schema='test'  \
--query="select * from test.salaries where salary='abcd' " engine=innodb  \
--number-of-queries=100（总查询次数） -uroot -p123456 -verbose

[root@mysql1 ~]# mysqlslap --defaults-file=/etc/my.cnf  \
--concurrency=100 --iterations=1  --create-schema='today'  \
--query="select * from today.salaries where salary='abcd' " engine=innodb  \
--number-of-queries=100  -uroot -p123456 -verbose   -S /data/mysql/mysql.sock



 建立索引：
alter table salaries add index index_salary(salary);



**索引维护**

在insert/delete/update操作时，为了维护索引的排序，数据库会自动的完成索引项的维护，索引的排序，这些行为对用户是透明的，感觉不到的
在一个有索引的表中，创建它时，实际上还同时创建了索引排序的表，

因此在DML中，插入等操作不再是普通的插入，**MySQL将它封装成了一个事务**，连着索引的所有更新维护动作。 事务步骤增多，时间增长。

因此，我们应当严格控制表上的索引数量，否则容易影响数据库的性能  
总结索引维护如下：

\1. 索引维护由数据库自动完成
\2. 插入/修改/删除  每一个索引的更新 ，都变成一个内部封装的事务
\3. 索引越多，事务越大，代价越高
\4. 索引越多，对表的 插入 和 索引字段 的修改就越慢

因此可以看出索引并非是越多越好，在工作中也要慎用，尤其对于  写操作较为 频繁的业务。

注：如果经常作为条件的列，重复值特别多，可以建立联合索引。
尽量使用前缀来索引
如果索引字段的值很长，最好使用值的前缀来索引

索引的数目不是越多越好。
可能会产生的问题:
(1) 每个索引都需要占用磁盘空间，索引越多，需要的磁盘空间就越大。
(2) 修改表时，对索引的重构和更新很麻烦。越多的索引，会使更新表变得很浪费时间。
(3) 优化器的负担会很重,有可能会影响到优化器的选择.

什么情况下建索引

1.读缓慢的情况下，可以建索引加快读速度

2.对热门的字段建立索引



索引的管理：
1.表中的数据被大量更新，或者数据的使用方式被改变后，原有的一些索引可能不再需要。数据库管理员应当定期找出这些索引，将它们删除，从而减少索引对更新操作的影响。
2.大表加索引,要在业务不繁忙期间操作（业务低峰期添加）
3.建索引原则
(1) 必须要有主键,如果没有可以做为主键条件的列,创建相关列。
(2) 经常做为where条件列  order by  group by  join on, distinct 的条件(业务:产品功能+用户行为)
(3) 最好使用唯一值多的列作为索引,如果索引列重复值较多,可以考虑使用联合索引
(4) 列值长度较长的索引列,我们建议使用前缀索引.
(5) 降低索引条目,一方面不要创建没用索引,不常使用的索引清理
(6) 索引维护要避开业务繁忙期,更新索引会锁表









外键约束

1    什 么 是 外 键 约 束
foreign key 就是表与表之间的某种约定的关系，由于这种关系的存在，我们能够让表与表之间的数据，更加的完整，关联性更强。
关于完整性，关联性我们举个例子

例：
有二张表，一张是用户表，一张是订单表

1.如果我删除了用户表里的用户，那么订单表里面与这个用户有关的数据，就成了无头数据了，不完整了。

2.如果我在订单表里面，随便插入了一条数据，这个订单在用户表里面，没有与之对应的用户。这样数据也不完整了。

如果有外键的话，就方便多了，可以不让用户删除数据，或者删除用户的话，通过外键同样删除订单表里面的数据，这样也能让数据完整。

\4. 4. 2    创 建 外 键 约 束
外键： 每次插入或更新时，都会检查数据的完整性。

方法一：通过 create table 创建外键 
语法：
create table 数据表名称(
[CONSTRAINT [约束名称]] FOREIGN KEY [外键字段]
REFERENCES [外键表名](外键字段，外键字段 2…..) 
[ON DELETE [C](http://www.jzxue.com/tag/FlashAS/)[AS](http://www.jzxue.com/tag/FlashAS/)[C](http://www.jzxue.com/tag/FlashAS/)ADE ]
[ON UPDATE CASCADE ] 
)

关于参数的解释：
RESTRICT: 拒绝对父表的删除或更新操作。
CASCADE: 从父表删除或更新且自动删除或更新子表中匹配的行。
ON DELETE CASCADE 和ON UPDATE CASCADE 都可用 
注意：on update cascade 是级联更新的意思， on delete cascade 是级联删除的意思，意思就是 说当你更新或删除主键表，那外键表也会跟随一起更新或删除。

精简化后的语法：
语法：foreign key 当前表的字段（子表）   references   外部表名（主表）   on update cascade     on delete cascade  ENGINE =innodb

注：创建成功，必须满足以下 4 个条件：
\1. 确保参照的表和字段存在。
\2. 组成外键的字段被索引。
\3. 必须使用 ENGINE 指定存储引擎为：innodb 。
\4. 外键字段和关联字段，数据类型必须一致。

例子：我们创建一个数据库，包含用户信息表和订单表 
mysql> create database market charset utf8;
mysql> use market;
mysql> create table `user`(id int(11) not null auto_increment, name varchar(50) not null default '', sex int(1) not null default '0', primary key(id))ENGINE=innodb;
mysql> create table `order`(o_id int(11) auto_increment, u_id int(11) default '0',username varchar(50), money int(11), primary key(o_id), index(u_id), foreign key order_f_key(u_id) references user(id) on delete cascade on update cascade) ENGINE=innodb;
注：
on delete cascade   on update cascade 添加级联删除和更新。
确保参照的表 user 中 id 字段存在 。组成外键的字段 u_id 被索引。必须使用type 指定存储引擎为： innodb。

外键字段和关联字段，数据类型必须一致。
插入测试数据
mysql> insert into user (name,sex) values ('HA',1),('LB',2),('HPC',1); 
mysql> insert into `order` (u_id,username,money) values (1,'HA',234),(2,'LB',46),(3,'HPC',256); 
mysql> select * from `order`;


![file://c:\users\admini~1\appdata\local\temp\tmp5hdd8k\7.png](https://s2.loli.net/2022/02/28/zXVp2ouMGe4amYJ.png)
mysql> select id,name,sex,money,o_id from user,`order` where id=u_id;
![file://c:\users\admini~1\appdata\local\temp\tmp5hdd8k\8.png](https://s2.loli.net/2022/02/28/dymkJbPMDXIH18w.png)

测试级联删除：
mysql> delete from user where id=1;         #删除 user 表中 id 为 1 的数据
再查看 order 表。
mysql> select * from `order`;
![file://c:\users\admini~1\appdata\local\temp\tmp5hdd8k\9.png](https://s2.loli.net/2022/02/28/8dJyCNYnAx5mv37.png)

测试级联更新：
更新前数据状态
mysql> select * from `order`;
![file://c:\users\admini~1\appdata\local\temp\tmp5hdd8k\10.png](https://s2.loli.net/2022/02/28/f3gO1mnKvckFGql.png)
mysql> select * from user;

![file://c:\users\admini~1\appdata\local\temp\tmp5hdd8k\11.png](https://s2.loli.net/2022/02/28/R26YFCfdLpv5Gi9.png)
mysql> update user set id=6 where id=2; 
mysql> select * from user;
![file://c:\users\admini~1\appdata\local\temp\tmp5hdd8k\12.png](https://s2.loli.net/2022/02/28/BiP2LpybnqkgRxa.png)
测试数据完整性：
mysql> insert into `order` (u_id,username,money)values(5,'Find',346);
![file://c:\users\admini~1\appdata\local\temp\tmp5hdd8k\13.png](https://s2.loli.net/2022/02/28/6udO5pKbAIG92WF.png)

外键约束，order 表受 user 表的约束
在 order 里面插入一条数据 u_id为 5 用户，在 user 表里面根本没有，所以插入不进去
mysql> insert into user values(5,'Find',1);
mysql> insert into `order` (u_id,username,money)values(5,'Find',346);         #这里 u_id 只
能是 5
mysql> select * from `order`;
![file://c:\users\admini~1\appdata\local\temp\tmp5hdd8k\14.png](https://s2.loli.net/2022/02/28/MPylH7uGA9saLcT.png)

方法二：通过alter table 创建外键和级联更新，级联删除 
语法：
alter table 数据表名称 add
[constraint [约束名称] ]   foreign key (外键字段,..) references 数据表(参照字段,...) 
[on update cascade|set null|no action]
[on delete cascade|set null|no action] 
)

mysql> create table order1(o_id int(11) auto_increment, u_id int(11) default '0', username varchar(50), money int(11), primary key(o_id), index(u_id)) ENGINE=innodb;
mysql> alter table order1 add foreign key(u_id) references user(id) on delete cascade on update cascade, ENGINE =innodb;
mysql> alter table order1 add constraint `bk`(指定外键名称) foreign key(u_id) references user(id) on delete cascade on update cascade,ENGINE=InnoDB;   
一定要记得带上InnoDB
mysql> show create table order1;
![file://c:\users\admini~1\appdata\local\temp\tmp5hdd8k\15.png](https://s2.loli.net/2022/02/28/nrIAgCtaVfZRW91.png)
\4. 4. 3    删 除 外 键
语法
alter table 数据表名称 drop foreign key 约束（外键）名称   
mysql> alter table order1 drop foreign key order1_ibfk_1; 
mysql> show create table order1;
![file://c:\users\admini~1\appdata\local\temp\tmp5hdd8k\16.png](https://s2.loli.net/2022/02/28/qc5jkvrCldZyGHm.png)