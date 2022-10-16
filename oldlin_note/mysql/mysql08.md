##                              日志-数据库的备份与恢复

### 1.错误日志：

记录mysql启动依赖所有状态，警告，错误等，帮助我们定位数据库问题。
配置方法：
默认存放位置：默认开启，默认位置：/datadir/hostname.err  #不定制日志文件时，则会默认生成
定制方法：

```shell
[root@mysql01 ~]# vim /etc/my.cnf
[mysqld]   #在mysqld添加一行
log_error=/var/log/mysql/mysql.log   #（该位置需要mysql有写入权限）
```

重启数据库生效。日志目录提前创建，
查看输出日志

```shell
[root@mysql01 ~]# mysqld --default-file=/etc/my.cnf
```

如果遇到MySQL一直处于刷新状态，卡顿无法CTRL+c或者CTRL+z就去到另外一个终端执行刷新操作

另一个客户端

```shell
#结束刷新
[root@mysql01 ~]# mysqladmin -uroot -p shutdown   #因为配置文件我设置的是不是默认套接字文件所以要接-S接我们自己设置的套接字文件，采用这种方式会报错

或者

[root@mysql01 ~]# mysqladmin -uroot -p shutdown -S /data/mysql/mysql.sock
```

查看错误日志主要查看ERROR行



### 2.binlog日志：

主要记录数据库变化性日志。数据库修改的操作DDL，DML，DCL性质的日志，是逻辑性质的日志，<font color='red'>只记录修改操作，不记录查询操作</font>。
作用：数据恢复和主从复制。

#### 2.1、如何配置：

8.0以前没有开启。生产建议全部开启

配置方法：

```shell
[root@mysql01 ~]# vim /etc/my.cnf
[mysqld]
server_id=3   #前面设置了1，这个可以不设置
log_bin=/data/binlog/mysql-bin  
sync_binlog=1
binlog_format=row
expire_logs_days=15
max_binlog_size=100M
```

[mysqld]
server_id=3     #(5.6可以不设置，5.7必须，是主从中应用)
log_bin=/data/binlog/mysql-bin     #(日志位置和日志名前缀)  非常重要，差重选择存储目录
sync_binlog=1                  #（binlog日志刷盘的策略，每次事务提交立刻刷写到磁盘）
[binlog_format=row](https://blog.csdn.net/mycwq/article/details/17136997)         #binlog的日志记录格式为row模式(row模式会产生大量日志)（row相似debug）
expire_logs_days=15       #设置binlog日志15天过期删除
max_binlog_size=100M    #设置binlog日志大小为100M (单个二进制日志 大小上限  默认1G ，到达自动滚动日志)

**其中可以前往官网查看[5.7的文档](https://dev.mysql.com/doc/refman/5.7/en/replication-options-binary-log.html)配置选项**



重启前创建binlog目录

```mysql
[root@mysql01 ~]# mkdir /data/binlog/
[root@mysql01 ~]# chown -R mysql.mysql /data/binlog/   #一定要给权限
[root@mysql01 ~]# systemctl restart mysqld
[root@mysql01 ~]# systemctl status mysqld
[root@mysql01 ~]# systemctl status mysqld
● mysqld.service - LSB: start and stop MySQL
   Loaded: loaded (/etc/rc.d/init.d/mysqld; bad; vendor preset: disabled)
   Active: active (running) since 六 2022-03-05 22:48:20 CST; 44s ago
   ......
```



#### 2.2、binlog如何记录？

<font color='red'>DDL：原封不动的记录</font>
<font color='red'>DCL：原封不动的记录</font>
<font color='red'>DML：只记录已经提交事务的DML（insert，update，delete） </font>
event:事件是什么？
二进制日志记录的最小记录单元
对于DDL，DCL操作一个语句是一个事件。
对于DML语句来说：已提交事务为一个事件。



#### 2.3、查看binlog日志：

在数据库查看有几个binlog日志

```mysql
mysql> show binary logs; 
+------------------+-----------+
| Log_name         | File_size |
+------------------+-----------+
| mysql-bin.000001 |       154 |
+------------------+-----------+
1 row in set (0.10 sec)
```

查看当前在用的日志文件

```mysql
mysql> show master status;
+------------------+----------+--------------+------------------+-------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
+------------------+----------+--------------+------------------+-------------------+
| mysql-bin.000001 |      154 |              |                  |                   |
+------------------+----------+--------------+------------------+-------------------+
1 row in set (0.00 sec) 
```

查看二进制事件的功能：

```mysql
#语法：show binlog events in 'mysql-bin.xxxxxx';

mysql> show binlog events in 'mysql-bin.000001';
+------------------+-----+----------------+-----------+-------------+---------------------------------------+
| Log_name         | Pos | Event_type     | Server_id | End_log_pos | Info                                  |
+------------------+-----+----------------+-----------+-------------+---------------------------------------+
| mysql-bin.000001 |   4 | Format_desc    |         1 |         123 | Server ver: 5.7.30-log, Binlog ver: 4 |
| mysql-bin.000001 | 123 | Previous_gtids |         1 |         154 |                                       |
+------------------+-----+----------------+-----------+-------------+---------------------------------------+
2 rows in set (0.00 sec)
```



#### 2.4、使用binlog日志恢复数据

**命令行查看**
**mysqlbinlog mysql-binxxxx(binlog路径) >xxx.sql**
常用参数：
--start-position  =     ：开始位置
--stop-position   =     ：结束位置
--start-datetime  = 'yyyy-mm-dd hh:mm:ss'  ：开始时间
--stop-datetime = 'yyyy-mm-dd hh:mm:ss'  ：结束时间



例子： 
导出 二进制日志中的指定范围的内容为  sql  文件

```mysql
mysql> update test.books set bName='IG' where bId=1;
Query OK, 1 row affected (0.34 sec)
Rows matched: 1  Changed: 1  Warnings: 0

mysql> show binlog events in 'mysql-bin.000001';
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203052309939.png)

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203052311741.png)

```shell
[root@mysql01 ~]# which mysqlbin
/usr/bin/which: no mysqlbin in (/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin:/usr/local/mysql/bin:/root/bin)
```

```shell
[root@mysql01 ~]# cd /data/binlog
[root@mysql01 binlog]# ls
mysql-bin.000001  mysql-bin.index
[root@mysql01 binlog]# cd /opt/
[root@mysql01 opt]# mysqlbinlog  /data/binlog/mysql-bin.000001 --start-position 154  --stop-position 543  > /opt/bak.sql   #指定pos点

[root@mysql01 opt]# ls
bak.sql  book.sql  mysql-5.7.30-linux-glibc2.12-x86_64.tar.gz  mysql.sh  yum
[root@mysql01 opt]# vim bak.sql
```

```shell
#或者
[root@mysql1 binlog]# mysqlbinlog  --start-datetime  = 'yyyy-mm-dd hh:mm:ss'  mysql-bin.000001  --stop-datetime = 'yyyy-mm-dd hh:mm:ss' mysql-bin.000001 >/opt/bak1.sql

[root@host binlog]# mysqlbinlog  --start-datetime='2021-9-8 19:02:00'  mysql-bin.000001  --stop-datetime='2021-9-8 19:02:50' mysql-bin.000001 >/opt/bak1.sql   

#在MySQL里面使用以下语句，可以更新到与服务器一样的时间，不然可能会出现时间节点一模一样不变
select date_format(now(),"%Y-%m-%d %H:%i:%s");
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203052319585.png)



例：跨不同binlog日志要怎么恢复数据

```
[root@mysql1 binlog]# mysqlbinlog mysql1-bin.000006 --start-position=21500   mysql1-bin.000007 --stop-position=415 >/opt/binlog1.sql
或
[root@mysql1 binlog]#  mysqlbinlog  --start-datetime='2022-04-28 15:01:37'  mysql1-bin.000006  --stop-datetime='2022-04-28 15:54:00' mysql1-bin.000007 >/opt/binlog2.sql

注：binglog通过跨时间点恢复数据，要找到对应的时间点的binlog日志
如下图，上述命令要恢复的是15：01分到15：54时间段的内数据，
符合条件的是最后修改时间为15：51分的mysql1-bin.000006和16:03分的mysql1-bin.000007
```

![image-20220428162715527](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202204281627604.png)



<font color='red'>先关闭binlog写入，再读取导出的binlog-sql文件</font>

```mysql
mysql> set sql_log_bin=0;   #暂时关闭
Query OK, 0 rows affected (0.13 sec)

mysql> update test.books set bName='EDG' where bId=1;
Query OK, 1 row affected (0.00 sec)
Rows matched: 1  Changed: 1  Warnings: 0

mysql> select * from test.books limit 5;

mysql> source /opt/bak.sql   #导回去看看

mysql> set sql_log_bin=1;   #再打开
Query OK, 0 rows affected (0.00 sec)
```

**<font color='red'>未利用binlog日志前</font>**

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203052323894.png)

<font color='red'>**利用binlog日志后**</font>

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203052326204.png)



#### 2.5、binlog日志维护

刷新日志

```mysql
mysql>flush logs;     #滚动生成下一个binlog日志
[root@mysql1 binlog]# systemctl restart mysqld		#重启机器也会导致生成下一个binlog日志
```

手工删除：

```mysql
mysql>purge binary logs to 'mysql-binxxxx';   #删除到某个位置,从000001开 
mysql>purge binary logs before '时间'；
```

全部清空：

```mysql
mysql>reset master   #危险操作，主从中主库做该操作会引起主从宕机
```



### 3、slow log（慢日志）

**作用：记录mysql运行过程中运行较慢的语句，帮助我们进行一些语句的优化**。

<font color='red'>默认是没有开启</font>
配置参数：
select @@slow_query_log;            #查看是否开启
select @@slow_query_log_file;      #查看慢日志路径
select @@long_query_time;           #慢语句认定时间阈值
select @@log_queries_not_using_indexes;     #记录不走索引的语句。
默认放在数据目录。建议数据与日志分开放

查看慢查询变量情况

```mysql
mysql> show variables like "%slow_query_log%";
+---------------------+------------------------------+
| Variable_name       | Value                        |
+---------------------+------------------------------+
| slow_query_log      | OFF                          |
| slow_query_log_file | /data/mysql/mysql01-slow.log |
+---------------------+------------------------------+
2 rows in set (0.00 sec)
```



如何配置：

```shell
vim /etc/my.cnf
[mysqld]
slow_query_log=1
slow_query_log_file=/data/mysql/slow-query.log    #文件位置
long_query_time=5          # 自定义时间  默认是10.000000秒
log_queries_not_using_indexes=1             #开启记录不走索引语句的功能
```

测试可以使用  select  sleep(6)  函数



### 4、事务日志

​    MySQL的存储引擎日志：
​    文件位置：数据目录下：
4.1、<font color='red'>Redo Log: ib_logfile0  ib_logfile1，又叫重做日志/前滚日志</font>
​	**控制参数：**
​	<font color='red'>innodb_log_file_size=50M(设置大小）</font>
​	<font color='red'>innodb_log_files_in_group=2(设置文件个数）</font>
​    <font color='red'>innodb_log_group_home_dir=./(存储位置，默认数据目录）</font>	

工作原理：
     Redo Log记录的是新数据的备份。
     <font color='red'>在事务提交后，会将修改类（DML）操作 记录到  Redo Log 并将它同步到磁盘（持久化）即可</font>，

功能：
​	   用来存储在修改类（DML）操作时，数据页变化过长（版本号LSN)，属于物理日志
​	   默认两个文件热动，循环覆盖使用。
​	 
4.2、<font color='red'>Undo Log: ibdata1 ibdata2(存储在共享表空间中)，回滚日志</font>
​    文件位置：默认为存储在ibdata里，一部分存在ibtmp里
​    控制参数：
​	    <font color='red'>innodb_rollback_segments=128(默认128个可以回滚）</font>

工作原理：
　　<font color='red'>Undo Log的原理很简单，为了满足事务的一致性 ，在操作任何数据的步骤之前，</font>
       <font color='red'>首先将表中数据备份到一个地方（这个存储数据备份的地方称为 Undo Log），然后再进行数据的修改。</font>
　　<font color='red'>如果出现了错误或者用户执行了  ROLLBACK  语句，系统可以利用 Undo Log 中的备份将表中数据恢复到事务开始之前的状态。</font>

功能：
​	    用于存储回滚日志，来提供innodb多版本读写。（提供一个快照用于事务操作）
​		提供回滚功能可以理解为每次操作的反操作，属于逻辑日志。











### 5、数据库备份类型

1.<font color='red'>热备</font>
<font color='red'>在数据库正常业务时,备份数据,并且能够一致性恢复（innodb即支持温备，也支持热备）</font>
<font color='red'>对业务影响非常小</font>

2.温备（mysqldump）
锁表备份,只能查询不能修改（myisam支持温备，不支持热备）
影响到写入操作

3.冷备
关闭数据库业务,数据库没有任何变更的情况下,进行备份数据.



### 6、数据库的备份概述

 全量与增量备份
 	1.全量备份：就是将数据库所有的数据包括库的大小、表的大小全部备份
 此种备份方式比较占用磁盘空间，每次的全量备份文件中都存在冗余数据。在实际生产操作环境中，一般每天会有一次定时的全量备份
 	2.增量备份：备份上次全量备份之后所更新的数据
 mysql数据库的增量备份是备份数据库的binlog，binlog记录的是对数据库更新操作的SQL语句，但不包括查询语句



###  7、数据库的备份方法

 1.物理备份
 物理备份是使用相关的复制命令（cp、tar等命令）直接将数据库的数据目录中的数据拷贝。
 缺点：当复制数据目录中的数据时，数据库仍然会有写入等操作，因此可能会造成一部份数据丢失，一般用于停机、停服迁移使用

 2.逻辑备份
 逻辑备份是使用mysqldump命令把需要的数据以SQL语句的形式存储。恢复数据库时，使用mysql恢复命令将SQL语句重新在数据库执行一次



### 8、数据库的备份操作

 **修改前备份配置文件(/etc/my.cnf)**

```shell
[mysqldump]
socket=/data/mysql/mysql.sock
```

####  1.单库备份

**mysqldump -uroot -h 127.0.0.1 -p 库名 >/opt/bak1_$(date +%F).sql**   <font color='red'>不使用-h接IP地址会提示找不到套接字文件</font>

```shell
[root@mysql01 ~]# mysqldump -uroot -h 127.0.0.1 -p test > /opt/bak_$(date +%F).sql
Enter password:
```

方便查看，过滤内容

```shell
[root@mysql01 ~]# egrep -v '^$|\*|^--' /opt/bak_2022-03-06.sql
或
[root@mysql01 ~]# egrep -v '^$|\/\*|^--' /opt/bak_2022-03-06.sql
```

<font color='red'>注：在恢复上述备份文件时必须事先建好新库，否则无法恢复数据，因为上述语句没有建库语句</font>
**解决方法：在执行备份时加上 “-B”参数**， 
**mysqldump -uroot -p -h 127.0.0.1 -B 库名 >/opt/bak2_$(date +%F).sql** 

```shell
[root@mysql01 ~]# mysqldump -uroot -h 127.0.0.1 -p -B test > /opt/bak2_$(date +%F).sql
Enter password:
```



#### 2.多库备份

多库备份就是同时备份多个库，也可以将整个mysql数据库全部备份。
注：这种备份方法有个严重问题？

备份多个库操作：
**mysqldump -uroot -h 127.0.0.1 -p  -B库名1  库名2  库名3 >/opt/bak3_$(date +%F).sql**

```shell
[root@mysql01 opt]# mysqldump -uroot -h 127.0.0.1 -p -B test today > /opt/bak3_$(date +%F).sql
Enter password:

#要加个-B参数，不然会提示找不到后面的库
```



备份所有库的操作：
**参数：-A 全部备份**
**mysqldump -uroot -p -A >/opt/bak4_$(date +%F).sql**

```shell
[root@mysql01 opt]# mysqldump -uroot -h 127.0.0.1 -p -A > /opt/bak4_$(date +%F).sql
Enter password:
```



####  3.分库备份

 分库备分是为了解决上面多库备份在同一个备份文件造成的问题
 一般做法是使用脚本，然后将脚本加入定时任务定期执行

```shell
[root@mysql1 ~]# cat /opt/mysql_bak.sh 
#!/bin/bash
MYSQL_CMD=/usr/local/mysql/bin/mysqldump
MYSQL_USER=root
MYSQL_PWD=123456
DATA=`date +%F`
DBname=`mysql -u$MYSQL_USER -p$MYSQL_PWD -e "show databases;" |egrep -v  'Database|schema$|sys|mysql'`

for i in $DBname
    do
       $MYSQL_CMD -u$MYSQL_USER -p$MYSQL_PWD  -B $i >/opt/mysqlbackup/$DBname_$DATA.Sql

    done
```



###  9、数据库表和表结构备份

####  1.表备份 （数据+结构）

 在实际生产环境中，对某个库的单表备份很常见。这种备份方法易于及时恢复单表数据，而且可以在不影响其他表数据写入的情况下进行。

**备份单个表**

**语法：mysqldump -u 用户名 -p 数据库名 表名 >备份的文件名**

```shell
[root@mysql01 opt]# mysqldump -uroot -h 127.0.0.1 -p test category > /opt/bak5_$(date +%F).sql
Enter password:
```

**备份多个表**

**语法：mysqldump -u 用户名 -p 数据库名 表名1 表名2 >备份的文件名**

```shell
[root@mysql01 opt]# mysqldump -uroot -h 127.0.0.1 -p test category demo > /opt/bak6_$(date +%F).sql
Enter password:
```



#### 2.表结构 （仅结构）

备份表结构一般用于在不同库到相同的表的场景，能够省去建表的一些操作，特别适用于表字段较多时

**语法：mysqldump -uroot -p   -d  库名1  表名1   > 备份的文件名**   

```shell
[root@mysql01 opt]# mysqldump -uroot -h 127.0.0.1 -p -d test category > /opt/bak7_$(date +%F).sql
Enter password:
```

方便查看，过滤内容 
**egrep -v "^$|^\/\*|^--" 备份的文件名**

```shell
[root@mysql01 opt]# egrep -v "^$|^\/\*|^--" /opt/bak7_2022-03-06.sql
DROP TABLE IF EXISTS `category`;
CREATE TABLE `category` (
  `bTypeId` int(4) NOT NULL AUTO_INCREMENT,
  `bTypeName` varchar(40) DEFAULT NULL,
  PRIMARY KEY (`bTypeId`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;
```



#### 3.表数据 （仅数据）

**语法：mysqldump -uroot -p -t 库名1 表名1  > 备份的文件名**

```shell
[root@mysql01 opt]# mysqldump -uroot -h 127.0.0.1 -p -t test category > /opt/bak8_$(date +%F).sql
Enter password:
```



分表备份缺点：文件多，碎。

　　　　　　1、备一个完整全备，再做一个分库分表备份。

　　　　　　2、脚本批量服务多个SQL文件。



### 10、备份优化

####  1.压缩备份

 **mysqldump -uroot -p   -h 127.0.0.1  库名1  表名1    |  gzip           >/opt/bak7_$(date +%F).sql.gz**



#### 2.优化输出信息

 **使用参数 <font color='red'> --compact(全部使用)</font>**
 **mysqldump -uroot -p  -h 127.0.0.1 --compact    库名  >/opt/bak8_$(date +%F).sql**



其它参数：
<font color='red'>--master_data=2  以注释的形式,保存备份开始时间点的binlog的状态信息</font>
 -R            备份存储过程及函数（脚本）
--triggers  备份触发器（脚本）
-E             备份事件（类似计划任务）
<font color='red'>--single-transaction  只有能支持热备的存储引擎才能开启热备(快照备份)功能</font>
--max_allow_packet=64m 备份超出最大传输包大小，使用该参数。

<font color='cornflowerblue'>--master_data=2 </font>
<font color='cornflowerblue'>功能：</font>
<font color='cornflowerblue'>（1）在备份时，会自动记录，二进制日志文件名和位置号</font>
  	<font color='cornflowerblue'>0 默认值，表示不开启</font>
  	<font color='cornflowerblue'>1  以change master to命令形式，可以用作主从复制</font>
  	<font color='cornflowerblue'>2  以注释的形式记录，备份在sql文件中的文件名+position号</font>
<font color='cornflowerblue'>（2） 自动锁表和解锁</font>
<font color='cornflowerblue'>（3）如果配合--single-transaction，只对非InnoDB表进行锁表备份，InnoDB表进行“热”备，实际上是实现快照备份</font>

![file://c:\users\admini~1\appdata\local\temp\tmpl7bpge\1.png](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203060842809.png)



###  11、数据库的恢复

 **1.使用source命令**
 针对没有建库语句恢复
 **先建库，use 库名，再source**

 **针对有建库语句恢复**
 直接source
 **mysql>source 备份sql文件**

 **2.使用mysql命令**
 **[root@mysql1 ~]#mysql -uroot -p <备份sql文件**



###  12、xtrabackup 备份工具使用

xtrabackup 简介
我们知道，针对 InnoDB 存储引擎，MySQL 本身没有提供合适的热备工具，ibbackup 虽是一款高效的首选热备方式，但它是是收费的。好在 Percona 公司给大家提供了一个开源、免费的Xtrabackup 热备工具，它可实现 ibbackup 的所有功能，并且还扩展支持真正的增量备份功能，是商业备份工具 InnoDB Hotbackup 的一个很好的替代品。

mysql自带的mysqldump命令采用的是逻辑备份，最大的缺点是备份和恢复的速度比较慢，一旦数据库的数据量超过50G-100G以上，就不太适合mysqldump这种备份方式


xtrabackup备份的工作原理，如下图：

 ![file://c:\users\admini~1\appdata\local\temp\tmpl7bpge\2.png](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202204291635005.png)



1.innobackupex在启动后，生成一个进程，然后启动xtrabackup_log后台实时监测进程来监控mysql  redo文件的变化，一旦发现有新日志写入，立即将日志写入日志文件xtrabcakup_log中
2.复制数据库的数据文件和系统表空间文件到指定的备份目录
3.复制完成后，执行flush tables with read lock操作
4.复制.frm、.myd、.myi等文件
5.获取到binary log位置点后，就会停止redo的复制线程，然后通知innobackupex     redo 文件复制完成
6.innobackupex 收到redo 文件复制完成的通知后，执行unlock tables操作
7.进程进入释放资源、写备份元数据的状态，最终停止进程退出

xtrabackup增量备份的工作原理
xtrabackup增量备份只能针对innodb存储引擎，innodb每个page都有一个LSN号，且LSN号是全局递增的，表空间的page中的LSN号越大，说明数据越新。每完成一次备份后，
会记录当前备份到的LSN号到xtrabackup_checkpoints文件中，执行增量备份时，会比较当前点的LSN号是否大于上次备份的LSN号，若大于则备份



xtrabackup恢复的工作原理
就是将xtrabackup 日志文件xtrabackup_log进行回放，然后将提交的事务信息及更改应用到数据库或表空间中，同时回滚未提交的事务，最终实现数据的一致



#### 12.1 xtrbackup 安装

mysql5.7 需安装2.4以上的版本 这里使用版本为XtraBackup2.4.9
下载安装包：

去到[官网](https://www.percona.com/)下载

![](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202204291635427.png)



#### 12.2 解压包

```shell
[root@mysql01 opt]# tar -xvf Percona-XtraBackup-2.4.9-ra467167cdd4-el7-x86_64-bundle.tar
percona-xtrabackup-24-2.4.9-1.el7.x86_64.rpm
percona-xtrabackup-24-debuginfo-2.4.9-1.el7.x86_64.rpm
percona-xtrabackup-test-24-2.4.9-1.el7.x86_64.rpm
```



#### 12.3 安装并解决依赖

```shell
[root@mysql01 opt]# yum -y install percona-xtrabackup-24-2.4.9-1.el7.x86_64.rpm
```



#### 12.4 查看版本

```shell
[root@mysql01 opt]# innobackupex -v
innobackupex version 2.4.9 Linux (x86_64) (revision id: a467167cdd4)
```



xtrbackup相关参数
--defaults-file：该选项指定了从哪个文件读取MySQL配置，必须放在命令行第一个选项的位置。
--host=IP    通过tcp协议连接
--backup 目录名：指定备份数据的存储目录
--apply-log：一般情况下,在备份完成后，数据尚且不能用于恢复操作，因为备份的数据中可能会包含尚未提交的事务或已经提交但尚未同步至数据文件中的事务。因此，此时数据 文件仍处理不一致状态。--apply-log的作用是通过回滚未提交的事务及同步已经提交的事务至数据文件使数据文件处于一致性状态。
--copy-back：复制之前备份的数据文件到MySQL服务器的datadir，复制之前需要确保原始目录下不能有任何目录或文件，除非指定 --force-non-empty-directorires选项
--force-non-empty-directories：指定该参数时候，使得--copy-back或--move-back选项转移文件到非空目录，已存在的文件不会被覆盖。如果--copy-back和--move-back文件需要从备份目录拷贝一个在datadir已经存在的文件，会报错失败。
--no-timestamp：该选项可以表示不要创建一个时间戳目录来存储备份，指定到自己想要的备份文件夹。
--incremental：该选项表示创建一个增量备份，需要指定--incremental-basedir。
--incremental-basedir：该选项表示接受了一个字符串参数指定含有全备的目录为增量备份的base目录，与--incremental同时使用。
--incremental-dir：该选项表示增量备份的目录。
--redo-only：这个选项在“全量备份”和“合并所有增量备份”（但不包括最后一个）时候使用。



#### 12.5 全量备份

```shell
[root@mysql01 opt]# innobackupex --defaults-file=/etc/my.cnf  --host=127.0.0.1 --user=root  --password=123456   --backup  /opt/fullback/

[root@mysql01 opt]# ls
```



#### 12.6 删除数据测试恢复

 ![](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202204291635974.png)



#### 12.7 数据恢复

12.7.1、停止服务并将数据目录清空

```shell
[root@mysql01 opt]# systemctl stop mysqld
[root@mysql01 opt]# mkdir -p /opt/data/
[root@mysql01 opt]# mv /data/mysql/* /opt/data/
```



12.7.2、执行回滚操作

**innobackupex --apply-log   /opt/fullback/备份文件**

```shell
[root@mysql01 opt]# cd fullback/
[root@mysql01 fullback]# ls
2022-03-06_09-23-33
[root@mysql01 fullback]# innobackupex --apply-log   /opt/fullback/2022-03-06_09-23-33
```

 ![](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202204291635967.png)



12.7.3、执行全量备份恢复

```shell
[root@mysql01 fullback]# innobackupex --defaults-file=/etc/my.cnf --copy-back /opt/fullback/2022-03-06_09-23-33
或者
[root@mysql01 fullback]# cp -r /opt/fullback/备份文件 /data/mysql/
[root@mysql01 fullback]# cd /data/
[root@mysql01 data]# chown -R mysql:mysql mysql
```



12.7.4、启动服务检查

```shell
[root@mysql01 data]# systemctl start mysqld
[root@mysql01 data]# mysql -uroot -p
```

![](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202204291635977.png)



#### 12.8 增量备份

1.创建数据

 ![](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202204291635992.png)



2.创建增量备份

```shell
[root@mysql01 data]# innobackupex --defaults-file=/etc/my.cnf --host=127.0.0.1 --user=root  --password=123456   --incremental   --incremental-basedir=/opt/fullback/2022-03-06_09-23-33    /opt/addback/
```



3. 删除数据测试恢复

 ![](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202204291635467.png)



4.数据恢复
4.1、停止服务并将数据目录清空

```shell
[root@mysql01 data]# systemctl stop mysqld
[root@mysql01 data]# mkdir -p /opt/data2/
[root@mysql01 data]# mv /data/mysql/* /opt/data2
```



4.2、执行全量备份回滚操作

```shell
[root@mysql01 data]# cd /opt/
[root@mysql01 opt]# cd addback/
[root@mysql01 addback]# ls
2022-03-06_09-38-47
[root@mysql01 addback]# innobackupex --apply-log  --redo-only /opt/fullback/2022-03-06_09-23-33
```



4.3、执行增量备份到全量备份回滚操作

```shell
[root@mysql01 addback]# innobackupex --apply-log   /opt/fullback/2022-03-06_09-23-33 --incremental-dir=/opt/addback/2022-03-06_09-38-47
```



4.4、执行增量备份恢复

```shell
[root@mysql01 addback]# innobackupex --defaults-file=/etc/my.cnf --copy-back  /opt/fullback/2022-03-06_09-23-33
[root@mysql01 addback]# cd /data/
[root@mysql01 data]# chown -R mysql:mysql mysql
```



5.启动服务检查

```shell
[root@mysql01 data]# systemctl start mysqld
```

![](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202204291635475.png)



