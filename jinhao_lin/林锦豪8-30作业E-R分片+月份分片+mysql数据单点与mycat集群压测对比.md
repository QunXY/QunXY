# 08-30

# 1，MyCat全局表和E-R分片测试。

## 一、全局表：

**修改schema.xml:**

```html
<table name="t_area" dataNode="dn1,dn2"  primaryKey="id"  type="global"  />
```

![image-20220830192054353](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202208301920424.png)

**后端数据准备：**

```shell
[root@mgr1 conf]# mysql -S /data/3307/mysql.sock -e "use taobao;create table t_area (id int not null primary key auto_increment,name varchar(20) not null);"
[root@mgr1 conf]# mysql -S /data/3308/mysql.sock -e "use taobao;create table t_area (id int not null primary key auto_increment,name varchar(20) not null);"
[root@mgr1 conf]# mycat restart
```

**测试：**

```sql
[root@mgr1 conf]# mysql -uroot -p123456 -h127.0.0.1 -P8066
mysql> use TESTDB;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> insert into t_area(id,name) values(1,'a');
Query OK, 1 row affected (0.02 sec)

mysql> 
mysql> insert into t_area(id,name) values(2,'b');
Query OK, 1 row affected (0.01 sec)

mysql> 
mysql> insert into t_area(id,name) values(3,'c');
Query OK, 1 row affected (0.00 sec)

mysql> 
mysql> insert into t_area(id,name) values(4,'d');
Query OK, 1 row affected (0.01 sec)

mysql> commit
    -> ;
Query OK, 0 rows affected (0.00 sec)

mysql> quit
Bye
```

**结果：**

![image-20220830192600304](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202208301926383.png)

**数据一样测试成功。**

## 二、E-R分片:

**修改schema.xml:**

```html
<table name="a" dataNode="dn1,dn2" rule="mod-long">
<childTable name="b" joinKey="aid" parentKey="id" />
</table>
```

**修改rule.xml:**

![](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202208301949924.png)

**后端数据准备：**

```shell
[root@mgr1 conf]# mysql -S /data/3307/mysql.sock -e "use taobao;create table a (id int not null primary key auto_increment,name varchar(20) not null);"
[root@mgr1 conf]# mysql -S /data/3307/mysql.sock -e "use taobao;create table b (id int not null primary key auto_increment,addr varchar(20) not null ,aid int );"
[root@mgr1 conf]# mysql -S /data/3308/mysql.sock -e "use taobao;create table a (id int not null primary key auto_increment,name varchar(20) not null);"
[root@mgr1 conf]# mysql -S /data/3308/mysql.sock -e "use taobao;create table b (id int not null primary key auto_increment,addr varchar(20) not null ,aid int );"
[root@mgr1 conf]# mysql -uroot -p123456 -h127.0.0.1 -P8066
```

**测试：**

```sql
[root@mgr1 conf]# mysql -uroot -p123456 -h127.0.0.1 -P8066
mysql> use TESTDB;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> insert into a(id,name) values(1,'a');
Query OK, 1 row affected (0.02 sec)

mysql> insert into a(id,name) values(2,'b');
Query OK, 1 row affected (0.01 sec)

mysql> insert into a(id,name) values(3,'c'); 
Query OK, 1 row affected (0.00 sec)

mysql> insert into a(id,name) values(4,'d');
Query OK, 1 row affected (0.00 sec)

mysql> insert into a(id,name) values(5,'e');
Query OK, 1 row affected (0.01 sec)

mysql> insert into b(id,addr,aid) values(1001,'bj',1);
Query OK, 1 row affected (0.00 sec)

mysql> insert into b(id,addr,aid) values(1002,'sj',3);
Query OK, 1 row affected (0.00 sec)

mysql> insert into b(id,addr,aid) values(1003,'sd',4);
Query OK, 1 row affected (0.00 sec)

mysql> insert into b(id,addr,aid) values(1004,'we',2);
Query OK, 1 row affected (0.00 sec)

mysql> insert into b(id,addr,aid) values(1005,'er',5);
Query OK, 1 row affected (0.00 sec)
```

**结果：**

![image-20220830195923365](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202208301959442.png)

# 2，测试月份分片 <tableRule name="sharding-by-month">

**修改schema.xml:**

```html
  <table name="user" dataNode="dn$1-12" rule="sharding-by-month"/>
</schema>
        <dataNode name="dn1" dataHost="localhost" database="month1" />
        <dataNode name="dn2" dataHost="localhost" database="month2" />
        <dataNode name="dn3" dataHost="localhost" database="month3" />
        <dataNode name="dn4" dataHost="localhost" database="month4" />
        <dataNode name="dn5" dataHost="localhost" database="month5" />
        <dataNode name="dn6" dataHost="localhost" database="month6" />
        <dataNode name="dn7" dataHost="localhost" database="month7" />
        <dataNode name="dn8" dataHost="localhost" database="month8" />
        <dataNode name="dn9" dataHost="localhost" database="month9" />
        <dataNode name="dn10" dataHost="localhost" database="month10" />
        <dataNode name="dn11" dataHost="localhost" database="month11" />
        <dataNode name="dn12" dataHost="localhost" database="month12" />
        <dataHost name="localhost" maxCon="1000" minCon="10" balance="0"
                  writeType="0" dbType="mysql" dbDriver="native" switchType="1"  slaveThreshold="100">
        <heartbeat>select user()</heartbeat>
        <writeHost host="db" url="192.168.159.148:3307" user="root" password="123"/>
        </dataHost>
```

![image-20220830201748759](C:\Users\15893\AppData\Roaming\Typora\typora-user-images\image-20220830201748759.png)

**修改rule.xml:**

![image-20220830202017773](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202208302020815.png)

![image-20220830202114479](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202208302021549.png)

**后端数据准备：**

```sql
[root@mgr1 conf]# mysql -S /data/3307/mysql.sock 
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 189
Server version: 5.7.38-log MySQL Community Server (GPL)

Copyright (c) 2000, 2022, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> create database month1;
Query OK, 1 row affected (0.00 sec)

mysql> create database month2;
Query OK, 1 row affected (0.01 sec)

mysql> create database month3;
Query OK, 1 row affected (0.00 sec)

mysql> create database month4;
Query OK, 1 row affected (0.00 sec)

mysql> create database month5;
Query OK, 1 row affected (0.03 sec)

mysql> create database month6;
Query OK, 1 row affected (0.02 sec)

mysql> create database month7;
Query OK, 1 row affected (0.00 sec)

mysql> create database month8;
Query OK, 1 row affected (0.00 sec)

mysql> create database month9;
Query OK, 1 row affected (0.00 sec)

mysql> create database month10;
Query OK, 1 row affected (0.00 sec)

mysql> create database month11;
Query OK, 1 row affected (0.00 sec)

mysql> create database month12;
Query OK, 1 row affected (0.00 sec)

mysql> use month1
Database changed
mysql> create table user(id int not null primary key, name varchar(20), create_time datetime);
Query OK, 0 rows affected (0.02 sec)

mysql> use month2 
Database changed
mysql> create table user(id int not null primary key, name varchar(20), create_time datetime);
Query OK, 0 rows affected (0.04 sec)

mysql> use month3
Database changed
mysql> create table user(id int not null primary key, name varchar(20), create_time datetime);
Query OK, 0 rows affected (0.01 sec)

mysql> use month4
Database changed
mysql> create table user(id int not null primary key, name varchar(20), create_time datetime);
Query OK, 0 rows affected (0.00 sec)

mysql> use month5
Database changed
mysql> create table user(id int not null primary key, name varchar(20), create_time datetime);
Query OK, 0 rows affected (0.04 sec)

mysql> use month6
Database changed
mysql> create table user(id int not null primary key, name varchar(20), create_time datetime);
Query OK, 0 rows affected (0.04 sec)

mysql> use month7
Database changed
mysql> create table user(id int not null primary key, name varchar(20), create_time datetime);
Query OK, 0 rows affected (0.05 sec)

mysql> use month8
Database changed
mysql> create table user(id int not null primary key, name varchar(20), create_time datetime);
Query OK, 0 rows affected (0.00 sec)

mysql> use month9
Database changed
mysql> create table user(id int not null primary key, name varchar(20), create_time datetime);
Query OK, 0 rows affected (0.05 sec)

mysql> use month10
Database changed
mysql> create table user(id int not null primary key, name varchar(20), create_time datetime);
Query OK, 0 rows affected (0.04 sec)

mysql> use month11
Database changed
mysql> create table user(id int not null primary key, name varchar(20), create_time datetime);
Query OK, 0 rows affected (0.04 sec)

mysql> use month12
Database changed
mysql> create table user(id int not null primary key, name varchar(20), create_time datetime);
Query OK, 0 rows affected (0.05 sec)

mysql> quit
Bye
[root@mgr1 conf]# mycat restart
Stopping Mycat-server...
Stopped Mycat-server.
Starting Mycat-server...
```

**测试：**

```sql
[root@mgr1 conf]# mysql -uroot -p123456 -h127.0.0.1 -P8066
mysql> use TESTDB
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> show tables;
+------------------+
| Tables in TESTDB |
+------------------+
| user             |
+------------------+
1 row in set (0.00 sec)

mysql> insert into user(id,name,create_time) values(111,'zhangsan','2019-01-01');
Query OK, 1 row affected (0.05 sec)

mysql> insert into user(id,name,create_time) values(111,'zhangsan','2019-03-01');
Query OK, 1 row affected (0.01 sec)

mysql> insert into user(id,name,create_time) values(111,'zhangsan','2019-05-01');
Query OK, 1 row affected (0.00 sec)

mysql> insert into user(id,name,create_time) values(111,'zhangsan','2019-07-01');
Query OK, 1 row affected (0.00 sec)

mysql> insert into user(id,name,create_time) values(111,'zhangsan','2019-09-01');
Query OK, 1 row affected (0.01 sec)

mysql> insert into user(id,name,create_time) values(111,'zhangsan','2019-11-01');
Query OK, 1 row affected (0.00 sec)
```



**结果：**

![image-20220830210555998](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202208302105064.png)

根据我们插入的数据查询结果得出，因为我们没有插入2，4，6月的数据所以查询不到，剩下的成功匹配并写入了。

# 3，mysql数据库单点与mycat集群在2000w数据下的压测对比报告

**报告要求：**
**1，在优化之前的压测情况对比**
**2，在优化之后的压测情况对比**
**3，报告所带内容，压测对比截图。相应的结论，架构选型预测**
**4，带搭建所需所有脚本。**
**5，可将之前的云数据库压测一并加入对比，并总结优劣势。**
**6，描述小，中，大型公司如需你做架构升级优化，你所能想到的方案简述(带架构图)。**

**测压工具选择sysbench：**

mysql数据库单点和云数据库用sysbench 1.0.20

mycat用sysbench 0.4.12.10（因为高版本的sysbench支持了tpcc，但是mycat对tpcc兼容性很差，所以我们mycat改用0.4的版本测压）

注意：建议虚拟机预留空间＞20G，sysbench是先生成数据再测压，可能会生成数据量太大，导致磁盘爆满。

**数据库配置：4核心，8G内存。**









## 2.Mycat

**一、安装sysbench 0.4.12.10**

```shell
[root@mgr1 opt]# yum install -y automake libtool
[root@mgr1 opt]# wget http://downloads.mysql.com/source/sysbench-0.4.12.10.tar.gz
[root@mgr1 opt]# tar -xf sysbench-0.4.12.10.tar.gz
[root@mgr1 opt]# cd sysbench-0.4.12.10
[root@mgr1 sysbench-0.4.12.10]# ln -sf /usr/local/mysql/lib/libmysql*  /usr/lib64
[root@mgr1 sysbench-0.4.12.10]# ln -sf /usr/local/mysql/lib/libmysqlclient.so  /usr/lib64/libmysqlclient_r.so
[root@mgr1 sysbench-0.4.12.10]# sed -i 's/AC_LIB_PREFIX()/#AC_LIB_PREFIX()/g' configure.ac
[root@mgr1 sysbench-0.4.12.10]# ./autogen.sh
[root@mgr1 sysbench-0.4.12.10]# ./configure --with-mysql-includes=/usr/local/mysql/include/ --with-mysql-libs=/usr/local/mysql/lib/
[root@mgr1 sysbench-0.4.12.10]# make
[root@mgr1 sysbench-0.4.12.10]# cd sysbench
```

**二、配置server.xml**

设置了一些相关压测的项目参数,和创建了两个用户sysbench,test.这两个用户和数据库的用户没有关联,是独立的,即使这个用户密码被破解,数据库的密码依然安全.其中root有完全控制权限,sysbench只能控制sbtest库,test也只能控制sbtest库,而且限制了读写权限.

```html
        <user name="root" defaultAccount="true">
                <property name="password">123456</property>
                <property name="schemas">sbtest,TESTDB</property>
                <!--No MyCAT Database selected 错误前会尝试使用该schema作为schema，不设置则为null,报错 -->

                <!-- 表级 DML 权限设置 -->
                <!--            
                <privileges check="false">
                        <schema name="TESTDB" dml="0110" >
                                <table name="tb01" dml="0000"></table>
                                <table name="tb02" dml="1111"></table>
                        </schema>
                </privileges>           
                 -->
        </user>
        <user name="sysbench">
                        <property name="password">sb123</property>
                        <property name="schemas">sbtest</property>
                </user>
        <user name="test">
                <property name="password">test</property>
                <property name="schemas">sbtest</property>
                <property name="readOnly">true</property>
        </user> 
```

![image-20220910231713362](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209102317494.png)

**三、修改schem.xml**

```html
[root@mgr1 conf]# vim /opt/mycat/conf/schema.xml
<?xml version="1.0"?>
<!DOCTYPE mycat:schema SYSTEM "schema.dtd">
<mycat:schema xmlns:mycat="http://io.mycat/">
        <schema name="sbtest" checkSQLschema="false" sqlMaxLimit="100" dataNode="dn1">
        </schema>
        <schema name="TESTDB" checkSQLschema="false" sqlMaxLimit="100" dataNode="dn2">
        </schema>
        <dataNode name="dn1" dataHost="192.168.159.148" database="sbtest" />
        <dataNode name="dn2" dataHost="192.168.159.148" database="TESTDB" />
        <dataHost name="192.168.159.148" maxCon="1000" minCon="10" balance="0"
                          writeType="0" dbType="mysql" dbDriver="native" switchType="1" slaveThreshold="100" >
                <heartbeat>select user()</heartbeat>
                <writeHost host="db1" url="192.168.159.148:3307" user="root" password="123">
                </writeHost>
        </dataHost>
</mycat:schema>
```

![image-20220911001522970](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209110015047.png)

**三、重启Mycat，验证一下是否连接到我们所设置的库（创库创表验证，测压前记得删除！）**

```sql
[root@mgr1 conf]# mycat restart
Stopping Mycat-server...
Stopped Mycat-server.
Starting Mycat-server...
[root@mgr1 conf]# mysql -usysbench -psb123 -h127.0.0.1 -P8066
mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 2
Server version: 5.6.29-mycat-1.6.7.4-release-20200105164103 MyCat Server (OpenCloudDB)
mysql> show databases;
+----------+
| DATABASE |
+----------+
| sbtest   |
+----------+
1 row in set (0.00 sec)

###########################################进入192.168.159.148:3307#################################################
[root@mgr1 ~]# mysql -uroot -P3307 -h192.168.159.148
mysql> create database sbtest;
Query OK, 1 row affected (0.01 sec)

mysql> use sbtest;											#创建mycat需要读取的库
Database changed

mysql> quit
Bye
```

**四、使用sysbench生成2000万，并压测。**

```shell
[root@mgr1 sysbench]# cd /opt/sysbench-0.4.12.10/sysbench/
[root@mgr1 sysbench]# ./sysbench --test=oltp --mysql-table-engine=innodb --oltp-table-size=20000000 --mysql-user=root --mysql-host=192.168.159.148 --mysql-port=3307 --mysql-password=123 prepare
sysbench 0.4.12.10:  multi-threaded system evaluation benchmark

No DB drivers specified, using mysql
Creating table 'sbtest'...
Creating 20000000 records in table 'sbtest'...
####################################################参数解释########################################################
--test=oltp    表示进行 oltp 模式测试,oltp是啥就不解析了
--oltp_tables_count=1    表示会生成1个测试表,数量越多,自然花费时间越长
--oltp-table-size=20000000    表示每个测试表填充数据量为 20000000行 ,数量越多也是越时间长
--mysql-table-engine=innodb    表示表的引擎是innodb

###########################################注意要点！非常重要########################################################
因为sysbench生成的数据表结构中有主键和索引，为了模拟未优化场景我们要将全部索引去除！
[root@mgr1 sysbench]# mysql -uroot -p123 -h192.168.159.148 -P3307
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sbtest             |
| sys                |
| taobao             |
| world              |
+--------------------+
7 rows in set (0.00 sec)
mysql> desc sbtest;								#可以看到有主键和索引，现在我们删除
+-------+------------------+------+-----+---------+----------------+
| Field | Type             | Null | Key | Default | Extra          |
+-------+------------------+------+-----+---------+----------------+
| id    | int(10) unsigned | NO   | PRI | NULL    | auto_increment |
| k     | int(10) unsigned | NO   | MUL | 0       |                |
| c     | char(120)        | NO   |     |         |                |
| pad   | char(60)         | NO   |     |         |                |
+-------+------------------+------+-----+---------+----------------+
4 rows in set (0.04 sec)
mysql> alter table sbtest modify id int(10) unsigned  not null;
Query OK, 20000000 rows affected (3 min 42.78 sec)
Records: 20000000  Duplicates: 0  Warnings: 0

mysql> alter table sbtest drop primary key;
Query OK, 20000000 rows affected (6 min 4.36 sec)
Records: 20000000  Duplicates: 0  Warnings: 0

mysql> show index from sbtest;
+--------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+
| Table  | Non_unique | Key_name | Seq_in_index | Column_name | Collation | Cardinality | Sub_part | Packed | Null | Index_type | Comment | Index_comment |
+--------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+
| sbtest |          1 | k        |            1 | k           | A         |           1 |     NULL | NULL   |      | BTREE      |         |               |
+--------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+
1 row in set (0.01 sec)

mysql> alter table sbtest drop index k;
Query OK, 0 rows affected (0.05 sec)
Records: 0  Duplicates: 0  Warnings: 0

mysql> desc sbtest;
+-------+------------------+------+-----+---------+-------+
| Field | Type             | Null | Key | Default | Extra |
+-------+------------------+------+-----+---------+-------+
| id    | int(10) unsigned | NO   |     | NULL    |       |
| k     | int(10) unsigned | NO   |     | 0       |       |
| c     | char(120)        | NO   |     |         |       |
| pad   | char(60)         | NO   |     |         |       |
+-------+------------------+------+-----+---------+-------+
4 rows in set (0.06 sec)

mysql> quit
Bye


#################################################开始测试###########################################################
[root@mgr1 sysbench]# ./sysbench --mysql-host=127.0.0.1 --mysql-port=8066 --mysql-user=sysbench --mysql-password=sb123 --test=oltp  --oltp-table-size=20000000 --mysql-table-engine=innodb --num-threads=4 --oltp-read-only=off --report-interval=10 --max-time=300 --max-requests=0 --percentile=99 run >> /tmp/sysbench_oltp
###############################################参数解释#############################################################
--num-threads=4    表示发起4个并发连接
--oltp-read-only=off    表示不要进行只读测试，也就是会采用读写混合模式测试
--report-interval=10    表示每10秒输出一次测试进度报告
--max-time=300    表示最大执行时长为300秒,测试将在这个时间后结束
--max-requests=0    表示总请求数为 0，因为上面已经定义了总执行时长，所以总请求数可以设定为 0；也可以只设定总请求数，不设定最大执行时长
--percentile=99    表示设定采样比例，默认是 95%，即丢弃1%的长请求，在剩余的99%里取最大值
##############################################查看压测报告##########################################################
[root@mgr1 sysbench]# cat /tmp/sysbench_oltp 
```

![image-20220911040334970](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209110403068.png)





































# 4，昨天的mycat脚本加功能（2，高可用。3，分片功能（写三个基础分片））

```shell
#!/bin/bash
High_Availability (){
echo -e "\e[36m
_____________________________
|                            |
|   	   高可用 	     |
|		             | 
|   `date "+%F|%H:%M:%S"`      |
|                            |
|____________________________|
(\__/) ||               
(•ㅅ•) ||               
/ 　 づv\e[0m"
read -p "请输入主库IP:" IP1
read -p "请输入从库IP:" IP2
read -p "请输入只写port:" P1
read -p "请输入只读port:" P2
read -p "请输入主库密码:" password1
read -p "请输入从库密码:" password2
mysql -uroot -p$password1 -h$IP1 -P$P1 -e "show databases;"
read -p "请输入进行读写分离的库:" data
SC=`find / -name schema.xml | grep /conf/schema.xml`
cp -f $SC "$SC".bak
cat > $SC << EOF
<?xml version="1.0"?>
<!DOCTYPE mycat:schema SYSTEM "schema.dtd">
<mycat:schema xmlns:mycat="http://io.mycat/">

        <schema name="TESTDB" checkSQLschema="false" sqlMaxLimit="100" dataNode="dn1">
        </schema>
        <dataNode name="dn1" dataHost="localhost1" database="$data" />
        <dataHost name="localhost1" maxCon="1000" minCon="10" balance="1"
                          writeType="0" dbType="mysql" dbDriver="native" switchType="1" >
                <heartbeat>select user()</heartbeat>
                <writeHost host="db1" url="$IP1:$P1" user="root"
                                   password="123">
                    <readHost host="db2" url="$IP1:$P2" user="root"
                                   password="123"/>
                </writeHost>
                <writeHost host="db3" url="$IP2:$P1" user="root"
                                   password="123">
                    <readHost host="db4" url="$IP2:$P2" user="root"
                                   password="$password2"/>
                </writeHost>
        </dataHost>
</mycat:schema>
EOF
mycat start

}

Rang_Long (){
echo -e "\e[36m
_____________________________
|                            |
|         范围分片           |
|                            | 
|   `date "+%F|%H:%M:%S"`      |
|                            |
|____________________________|
(\__/) ||               
(•ㅅ•) ||               
/ 　 づv\e[0m"
read -p "请输入数据库一IP:" IP1
read -p "请输入数据库二IP:" IP2
read -p "请输入只写port1:" WP1
read -p "请输入只写port2:" WP2
read -p "请输入只读port1:" RP1
read -p "请输入只读port2:" RP2
read -p "请输入数据库一密码:" password1
read -p "请输入数据库二密码:" password2
mysql -uroot -p$password1 -h$IP1 -P$WP1 -e "show databases;"
read -p "请输入库一中作为范围分片的库:" data1
mysql -uroot -p$password2 -h$IP2 -P$WP1 -e "show databases;"
read -p "请输入库二中作为范围分片的库:" data2
mysql -uroot -p$password1 -h$IP1 -P$WP1 -e "show tables from $data1;"
read -p "请输入作为范围分片的表:" table
read -p "请输入结果到节点一的范围:" Rang1
read -p "请输入结果到节点二的范围:" Rang2
SC=`find / -name schema.xml | grep /conf/schema.xml`
cp -f $SC "$SC".bak
cat > $SC << EOF
<?xml version="1.0"?>
<!DOCTYPE mycat:schema SYSTEM "schema.dtd">
<mycat:schema xmlns:mycat="http://io.mycat/">

        <schema name="TESTDB" checkSQLschema="false" sqlMaxLimit="100" dataNode="dn1">
               <table name="$table" dataNode="dn1,dn2" rule="auto-sharding-long" />
        </schema>
        <dataNode name="dn1" dataHost="localhost1" database="$data1" />
        <dataNode name="dn2" dataHost="localhost2" database="$data2" />

        <dataHost name="localhost1" maxCon="1000" minCon="10" balance="1"
                          writeType="0" dbType="mysql" dbDriver="native" switchType="1" >
                <heartbeat>select user()</heartbeat>
                <writeHost host="db1" url="$IP1:$WP1" user="root"
                                   password="$password1">
                    <readHost host="db2" url="$IP1:$RP1" user="root"
                                   password="$password1"/>
                </writeHost>
                <writeHost host="db3" url="$IP2:$WP1" user="root"
                                   password="$password2">
                    <readHost host="db4" url="$IP2:$RP1" user="root"
                                   password="$password2"/>
                </writeHost>
        </dataHost>
       <dataHost name="localhost2" maxCon="1000" minCon="10" balance="1"
                          writeType="0" dbType="mysql" dbDriver="native" switchType="1" >
                <heartbeat>select user()</heartbeat>
                <writeHost host="db1" url="$IP1:$WP2" user="root"
                                   password="$password1">
                    <readHost host="db2" url="$IP:$RP2" user="root"
                                   password="$password1"/>
                </writeHost>
                <writeHost host="db3" url="$IP2:$WP2" user="root"
                                   password="$password2">
                    <readHost host="db4" url="$IP2:$RP2" user="root"
                                   password="$password2"/>
                </writeHost>
        </dataHost>
</mycat:schema>
EOF
AL=`find / -name autopartition-long.txt | grep /conf/autopartition-long.txt`
cp -f $AL "$AL".bak
cat > $AL << EOF
$Rang1=0
$Rang2=1
EOF
mycat restart

}

Hash_Int (){
echo -e "\e[36m
_____________________________
|                            |
|         枚举分片           |
|                            | 
|   `date "+%F|%H:%M:%S"`      |
|                            |
|____________________________|
(\__/) ||               
(•ㅅ•) ||               
/ 　 づv\e[0m"
read -p "请输入数据库一IP:" IP1
read -p "请输入数据库二IP:" IP2
read -p "请输入只写port1:" WP1
read -p "请输入只写port2:" WP2
read -p "请输入只读port1:" RP1
read -p "请输入只读port2:" RP2
read -p "请输入数据库一密码:" password1
read -p "请输入数据库二密码:" password2
mysql -uroot -p$password1 -h$IP1 -P$WP1 -e "show databases;"
read -p "请输入库一中作为枚举分片的库:" data1
mysql -uroot -p$password2 -h$IP2 -P$WP1 -e "show databases;"
read -p "请输入库二中作为枚举分片的库:" data2
mysql -uroot -p$password1 -h$IP1 -P$WP1 -e "show tables from $data1;"
read -p "请输入作为枚举分片的表:" table
read -p "请输入分片字段类型(0为整数型，1为字符串型):" Type
read -p "请输入需要枚举的字段1:" C1
read -p "请输入需要枚举的字段2:" C2
SC=`find / -name schema.xml | grep /conf/schema.xml`
cp -f $SC "$SC".bak
cat > $SC << EOF
<?xml version="1.0"?>
<!DOCTYPE mycat:schema SYSTEM "schema.dtd">
<mycat:schema xmlns:mycat="http://io.mycat/">

        <schema name="TESTDB" checkSQLschema="false" sqlMaxLimit="100" dataNode="dn1">
        <table name="$table" dataNode="dn1,dn2" rule="sharding-by-intfile" />
	</schema>
        <dataNode name="dn1" dataHost="localhost1" database="$data1" />
        <dataNode name="dn2" dataHost="localhost2" database="$data2" />

        <dataHost name="localhost1" maxCon="1000" minCon="10" balance="1"
                          writeType="0" dbType="mysql" dbDriver="native" switchType="1" >
                <heartbeat>select user()</heartbeat>
                <writeHost host="db1" url="$IP1:$WP1" user="root"
                                   password="$password1">
                    <readHost host="db2" url="$IP1:$RP1" user="root"
                                   password="$password1"/>
                </writeHost>
                <writeHost host="db3" url="$IP2:$WP1" user="root"
                                   password="$password2">
                    <readHost host="db4" url="$IP2:$RP1" user="root"
                                   password="$password2"/>
                </writeHost>
        </dataHost>
       <dataHost name="localhost2" maxCon="1000" minCon="10" balance="1"
                          writeType="0" dbType="mysql" dbDriver="native" switchType="1" >
                <heartbeat>select user()</heartbeat>
                <writeHost host="db1" url="$IP1:$WP2" user="root"
                                   password="$password1">
                    <readHost host="db2" url="$IP:$RP2" user="root"
                                   password="$password1"/>
                </writeHost>
                <writeHost host="db3" url="$IP2:$WP2" user="root"
                                   password="$password2">
                    <readHost host="db4" url="$IP2:$RP2" user="root"
                                   password="$password2"/>
                </writeHost>
        </dataHost>
</mycat:schema>
EOF
RU=`find / -name rule.xml | grep /conf/rule.xml`
cp -f $RU "$RU".bak
T=`cat $RU | | grep -i '<property name="type">'`
sed -i "s@$T@<property name="type">$Type</property>@g" $RU
PHI=`find / -name partition-hash-int.txt | grep /conf/partition-hash-int.txt`
cp -f $PHI "$PHI".bak
cat > $PHI << EOF
$C1=0
$C2=1
DEFAULT_NODE=1
EOF
mycat restart

}

Mod_Long (){
echo -e "\e[36m
_____________________________
|                            |
|         取模分片           |
|                            | 
|   `date "+%F|%H:%M:%S"`      |
|                            |
|____________________________|
(\__/) ||               
(•ㅅ•) ||               
/ 　 づv\e[0m"
read -p "请输入数据库一IP:" IP1
read -p "请输入数据库二IP:" IP2
read -p "请输入只写port1:" WP1
read -p "请输入只写port2:" WP2
read -p "请输入只读port1:" RP1
read -p "请输入只读port2:" RP2
read -p "请输入数据库一密码:" password1
read -p "请输入数据库二密码:" password2
mysql -uroot -p$password1 -h$IP1 -P$WP1 -e "show databases;"
read -p "请输入库一中作为取模分片的库:" data1
mysql -uroot -p$password2 -h$IP2 -P$WP1 -e "show databases;"
read -p "请输入库二中作为取模分片的库:" data2
mysql -uroot -p$password1 -h$IP1 -P$WP1 -e "show tables from $data1;"
read -p "请输入作为取模分片的表:" table
read -p "请输入分片数量:" count
SC=`find / -name schema.xml | grep /conf/schema.xml`
cp -f $SC "$SC".bak
cat > $SC << EOF
<?xml version="1.0"?>
<!DOCTYPE mycat:schema SYSTEM "schema.dtd">
<mycat:schema xmlns:mycat="http://io.mycat/">

        <schema name="TESTDB" checkSQLschema="false" sqlMaxLimit="100" dataNode="dn1">
        <table name="$table" dataNode="dn1,dn2" rule="mod-long" />
        </schema>
        <dataNode name="dn1" dataHost="localhost1" database="$data1" />
        <dataNode name="dn2" dataHost="localhost2" database="$data2" />

        <dataHost name="localhost1" maxCon="1000" minCon="10" balance="1"
                          writeType="0" dbType="mysql" dbDriver="native" switchType="1" >
                <heartbeat>select user()</heartbeat>
                <writeHost host="db1" url="$IP1:$WP1" user="root"
                                   password="$password1">
                    <readHost host="db2" url="$IP1:$RP1" user="root"
                                   password="$password1"/>
                </writeHost>
                <writeHost host="db3" url="$IP2:$WP1" user="root"
                                   password="$password2">
                    <readHost host="db4" url="$IP2:$RP1" user="root"
                                   password="$password2"/>
                </writeHost>
        </dataHost>
       <dataHost name="localhost2" maxCon="1000" minCon="10" balance="1"
                          writeType="0" dbType="mysql" dbDriver="native" switchType="1" >
                <heartbeat>select user()</heartbeat>
                <writeHost host="db1" url="$IP1:$WP2" user="root"
                                   password="$password1">
                    <readHost host="db2" url="$IP:$RP2" user="root"
                                   password="$password1"/>
                </writeHost>
                <writeHost host="db3" url="$IP2:$WP2" user="root"
                                   password="$password2">
                    <readHost host="db4" url="$IP2:$RP2" user="root"
                                   password="$password2"/>
                </writeHost>
        </dataHost>
</mycat:schema>
EOF
RU=`find / -name rule.xml | grep /conf/rule.xml`
cp -f $RU "$RU".bak
C=`cat $RU | grep -i '<property name="count">' | awk 'NR==3{print $0}'`
sed -i "ss@$C@<property name="count">$count</property>@g" $RU
mycat restart

}


while true
do
echo -e "\e[36m
_____________________________
|                            |
|         MyCat              |	
|    1.高可用		     | 
|    2.范围分片		     |           
|    3.枚举分片		     |	     
|    4.取模分片	             |       
|                 	     |	     
|   `date "+%F|%H:%M:%S"`      |
|			     |
| 9.退出程序                 |
|____________________________|
(\__/) ||               
(•ㅅ•) ||               
/ 　 づv\e[0m"
read -p "请选择日志恢复的类型:" I
case $I in
1|高可用)
	High_Availability
	continue
	;;
2|范围分片)
	Rang_Long
	continue
	;;
3|枚举分片)
	Hash_Int
	continue
        ;;
4|取模分片)
        Mod_Long
        continue
        ;;
9|退出程序)
	echo "谢谢使用"
	break
	;;
	*)
	exit
	esac
done
```

