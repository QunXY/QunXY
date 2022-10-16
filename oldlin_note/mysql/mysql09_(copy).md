###                                                                  主从复制

### 1、主从复制 工作原理

整体上来说，复制有 3 个步骤： 
（1） master 将改变记录到二进制日志(binary log)中
（2） slave 将 master 的 binary log events 拷贝到它的中继日志(relay log)
（3） slave 重做中继日志中的事件，修改 salve 上的数据。

 ![file://c:\users\admini~1\appdata\local\temp\tmpodtugz\1.png](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203031928916.png)



MySQL 主从复制中：
第一步：master 记录二进制日志。在每个事务更新数据完成之前，master 在二进制日志记录这些改变。 MySQL 将事务写入二进制日志，即使事务中的语句都是交叉执行的。在事件写入二进制日志完成后，master 通知存储引擎提交事务。
第二步：slave 将 master 的 binary log拷贝到它自己的中继日志。首先，slave 开始一个工作线程 —I/O 线程 。I/O 线程在 master 上打开一个普通的连接，然后开始同步 。Binlog dump process 从 master 的二进制日志中读取事件，如果已经执行完 master 产生的所有文件，它会睡眠并等待 master 产生新的事件。I/O 线程将这些事件写入中继日志。
第三步：SQL slave thread（SQL 从线程）处理该过程的最后一步。SQL 线程从中继日志读取事件 ， 并重新执行其中的事件而更新 slave 的数据，使其与 master 中的数据一致。



小结一下：master数据库会把修改语句（DDL,DCL,DML）同步到binlog日志里，从机可以主动通过I/O线程读取binlog日志同步到relaylog中继日志，主机也可以主动通过I/O线程把binlog日志同步给从机的relaylog中继日志，从机根据更新的relaylog日志，会生成一个本机的sql线程，来同步relaylog里面的操作



### 2、服务器环境规划

| 服务器主机名 |  服务器IP地址   | 服务器角色 |
| :----------: | :-------------: | :--------: |
|   mysql01    | 192.168.188.128 | master主库 |
|   mysql02    | 192.168.188.129 | slave从库  |



### 3、服务器系统环境

```shell
[root@mysql01 ~]# cat /etc/redhat-release
CentOS Linux release 7.4.1708 (Core)

[root@mysql02 ~]# cat /etc/redhat-release
CentOS Linux release 7.4.1708 (Core)
```



### 4、数据库版本

```shell
[root@mysql01 ~]# mysql -V
mysql  Ver 14.14 Distrib 5.7.30, for linux-glibc2.12 (x86_64) using  EditLine wrapper

[root@mysql02 ~]# mysql -V
mysql  Ver 14.14 Distrib 5.7.30, for linux-glibc2.12 (x86_64) using  EditLine wrapper
```



### 5、配置mysql主从复制

#### 5.1.在主库上开启binlog日志

```shell
[root@mysql01 ~]# vim /etc/my.cnf   #添加以下内容，最后两行注释掉了，根据需求设置
log_bin=/data/binlog/mysql-bin
sync_binlog=1
binlog_format=row
expire_logs_days=15
max_binlog_size=100M
#binlog-do-db=HA                         
#binlog-ignore-db=mysql

[root@mysql01 ~]# mkdir /data/binlog/
[root@mysql01 ~]# chown -R mysql.mysql /data/binlog/
```

server_id=1    #原本设置的，可以不用加
log_bin=/data/binlog/mysql-bin 
sync_binlog=1 
binlog_format=row 
expire_logs_days=15 
max_binlog_size=100M 
<font color='cornflowerblue'>binlog-do-db=HA</font>                        <font color='red'> #可以被从服务器复制的库, 二进制需要同步的数据库名</font>
<font color='cornflowerblue'>binlog-ignore-db=mysql</font>              <font color='red'>#不可以被从服务器复制的库</font>

重启生效

```shell
[root@mysql01 ~]# systemctl restart mysqld
```



#### 5.2.配置主从复制用户并授权

主库操作

```mysql
mysql> grant replication slave on *.* to repl_user@"%" identified by "123456";
Query OK, 0 rows affected, 1 warning (0.00 sec)

mysql> flush privileges;
Query OK, 0 rows affected (0.00 sec)
```



#### 5.3.查看主库当前状态

```mysql
mysql> show master status;
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203061137519.png)



#### 5.4.配置从库

<font color='red'>修改从库server_id不能与主库相同</font>

<font color='red'>重新生成auto.cnf文件</font>

```shell
[root@mysql02 ~]# cp /data/mysql/auto.cnf /opt/auto.cnf.bak
[root@mysql02 ~]# rm -rf /data/mysql/auto.cnf
```

```shell
[root@mysql02 ~]# vim /etc/my.cnf
server_id=2   #改成了2
port=3306
socket=/data/mysql/mysql.sock
relay-log=/data/relay-log/relay-log        #自定义relay-log日志存放目录，不设置，默认存放在共享表空间
relay-log-index=/data/relay-log/relay-log.index

[root@mysql02 ~]# mkdir -p /data/relay-log
[root@mysql02 ~]# chown -R mysql:mysql /data/relay-log   #加权限
```

重启生效

```shell
[root@mysql02 ~]# systemctl restart mysqld
```

```mysql
mysql> help change master to;   #主从复制命令的帮助文档
```



#### 5.5.建立主从连接

从机上
即使重启从机的mysql服务后，而不会影响主从

```mysql
mysql> CHANGE MASTER TO
    -> MASTER_HOST='192.168.188.128',				#(主机)
    -> MASTER_USER='repl_user',
    -> MASTER_PASSWORD='123456',
    -> MASTER_LOG_FILE='mysql-bin.000001',			#(主机)
    -> MASTER_LOG_POS=594,
    -> MASTER_CONNECT_RETRY=10; 			##在主服务器宕机或连接丢失的情况下，从服务器线程重新尝试连接主服务器之前睡眠的秒数,10秒连一次
Query OK, 0 rows affected, 2 warnings (0.01 sec)
```

CHANGE MASTER TO
MASTER_HOST='192.168.188.128', 
MASTER_USER='repl_user',
MASTER_PASSWORD='123456',
MASTER_LOG_FILE='mysql-bin.000001', 
MASTER_LOG_POS=594,
MASTER_CONNECT_RETRY=10; 



#### 5.6.开启主从复制并查看状态

```mysql
#在从机上操作
mysql>start slave;          

mysql>show slave status\G
```

错误例子

<font color='red'> 遇到错误在机子上先执行**stop slave再reset slave;**清除主从信息再重开服务</font>![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203061206323.png)

正确

 ![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203061208967.png)



#### 5.7.验证主从复制

**在<font color='red'>主库</font>上创建一个新库，并插入数据**

```mysql
mysql> create database class charset utf8;
Query OK, 1 row affected (0.00 sec)

mysql> use class
Database changed
mysql> create table teacher (
    -> id int,
    -> name varchar(12),
    -> age char(6));
Query OK, 0 rows affected (0.11 sec)

mysql> insert into teacher values(1,'zhangs',16);
Query OK, 1 row affected (0.15 sec)
```

**在<font color='red'>从库</font>上验证**

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203061212839.png)



#### 5.8.从节点产生的文件

**master.info  文件记录了备节点的连接信息，例如用户名，密码等。同时包括主节点信息**
从节点操作

```shell
[root@mysql02 ~]# vim /etc/my.cnf   #添加以下内容
[mysqld]
master_info_repository=TABLE

[root@mysql02 ~]# systemctl restart mysqld
```

```mysql
mysql> select * from mysql.slave_master_info \G
```

 ![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203061217917.png)

**relay-log.info  文件记录了备节点应用 relay log 文件的进度情况**

```shell
[root@mysql02 ~]# vim /etc/my.cnf   #添加以下内容
[mysqld]
relay_log_info_repository=TABLE

[root@mysql02 ~]# systemctl restart mysqld
```

```mysql
mysql> select * from mysql.slave_relay_log_info \G
```

 ![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203061219435.png)



#### 5.9.开启主从复制不成功

非正常状态：
Slave_IO_Running: NO
Slave_SQL_Running: Conncting

出现故障原因：
连接主库：
1，网络防火墙端口问题。
2，用户密码问题。用户权限必须有replication slave权限
3，主库的连接数达到上限。
4，版本不统一的情况。
5，server-id忘记修改为不一样



#### 5.10.reset master与reset slave区别？

reset master参数
功能说明：删除所有的binglog日志文件，并将日志索引文件清空，重新开始所有新的日志文件。用于第一次进行搭建主从库时，进行主库binlog初始化工作；
reset master 不能用于有任何slave 正在运行的主从关系的主库。

reset slave参数
功能说明：用于删除slave数据库的relaylog日志文件，并重新启用新的relaylog文件；
reset slave 将使slave 忘记主从复制关系的位置信息。该语句将被用于干净的启动, 它删除master.info文件和relay-log.info 文件以及所有的relay log 文件并重新启用一个新的relaylog文件。
使用reset slave之前必须使用stop slave 命令将复制进程停止。

#### 5.11.主从不一致原因分析

1.网络的延迟
由于mysql主从复制是基于binlog的一种异步复制，通过网络传送binlog文件，理所当然网络延迟是主从不同步的绝大多数的原因，特别是跨机房的数据同步出现这种几率非常的大，所以做读写分离，注意从业务层进行前期设计。

2.主从两台机器的负载不一致
由于mysql主从复制是主数据库上面启动1个io线程，而从上面启动1个sql线程和1个io线程，当中任何一台机器的负载很高，忙不过来，导致其中的任何一个线程出现资源不足，都将出现主从不一致的情况。

3.max_allowed_packet设置不一致
数据库上面设置的max_allowed_packet比从数据库大，当一个大的sql语句，能在主数据库上面执行完毕，从数据库上面设置过小，无法执行，导致的主从不一致。

4.key自增键开始的键值跟自增设置不一致引起的主从不一致。

5.mysql异常宕机情况下，如果未设置sync_binlog=1或者innodb_flush_log_at_trx_commit=1很有可能出现binlog或者relaylog文件出现损坏，导致主从不一致。

6.mysql本身的bug引起的主从不同步。

7.版本不一致，特别是高版本是主，低版本为从的情况下，主数据库上面支持的功能，从数据库上面不支持该功能。



#### 5.12.解决方案：

方法一：忽略错误后，继续同步 
该方法适用于主从库数据相差不大，或者要求数据可以不完全统一的情况，数据要求不严格的情况 
解决(从机)： 

```mysql
stop slave; 
set global sql_slave_skip_counter =1; 
start slave;
```



方式二：重新做主从，完全同步 
该方法适用于主从库数据相差较大，或者要求数据完全统一的情况 

清空主从：
从库中执行：

```mysql
mysql> stop slave;
mysql> reset slave all;
mysql> CHANGE MASTER TO
    -> MASTER_HOST='192.168.188.128',
    -> MASTER_USER='repl_user',
    -> MASTER_PASSWORD='123456',
    -> MASTER_LOG_FILE='mysql-bin.000001',
    -> MASTER_LOG_POS=594,
    -> MASTER_CONNECT_RETRY=10;            

mysql> start slave;          
mysql> show slave status\G
```



方式三：配置文件上设置跳过错误

slave_skip_errors选项有四个可用值，分别为：off，all，ErrorCode，ddl_exist_errors，默认情况下该参数值是off
 一些error code代表的错误如下：
    1007：数据库已存在，创建数据库失败
    1008：数据库不存在，删除数据库失败
    1050：数据表已存在，创建数据表失败
    1051：数据表不存在，删除数据表失败
    1054：字段不存在，或程序文件跟数据库有冲突
    1060：字段重复，导致无法插入
    1061：重复键名
    1068：定义了多个主键
    1094：位置线程ID
    1146：数据表缺失，请恢复数据库
    1053：复制过程中主服务器宕机
    1062：主键冲突

```shell
修改配置文件举例
[mysqld]
slave_skip_errors=1062,1053  
slave_skip_errors=all  
slave_skip_errors=ddl_exist_errors
```



模拟故障：
配置好mysql主从同步，然后在从上写入数据，造成主从不一致。
准备测试表结构
    在主机上创建表：

```mysql
mysql> create table replication (c1 int not null primary key, c2 varchar(10));
```

准备测试数据
    在主机上插入基础数据

```mysql
mysql> insert into replication values (1, 'test1'),(2, 'test2'); 
```

主机从机replication表里面都有两条记录
 开始测试
    从机插入一条记录

```mysql
mysql> insert into replication values (3, 'test3'); 
```

​    然后在主机上执行相同的操作

```mysql
mysql> insert into replication values (3, 'test3'); 
```

​    在从机上查看复制状态

```mysql
mysql> show slave status \G
```

**参考 [Mysql主从（主从不同步解决办法，常见问题及解决办法）_sky__liang的博客-CSDN博客_主从不同步](https://blog.csdn.net/sky__liang/article/details/85684615)**









#### 5.13.MySQL复制使用场景

1.MySQL复制可以用在主库和从库采用不同的存储引擎的情况下。这样做的目的通常是在主库和从库可以分别利用不同存储引擎的优势，比如在主库使用

InnoDB是为了事务功能，而从库使用MyISAM因为是只读操作而不需要事务功能



2.MySQL复制可以用来做负载均衡功能的水平扩展，最主要是将数据库的读压力分担到多个MySQL slave实例上，这种情况适用在读多写少的环境中。比如

一个基本的WEB架构：

![image-20220831024028254](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202208310240340.png)



3.MySQL复制可以用在当需要将主库上的不同数据库复制到不同的slave上，以便在不同的slave上执行不同的数据分析任务时。可以在每个slave上配置不同的参数来约束复制过来的数据，通过replicate-wild-do-table参数或者replicate-do-db参数

![image-20220831024117092](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202208310241139.png)

slave1上应该配置参数replicate-wild-do-table=databaseA.%  或	replicate-do-db = databaseA

slave2上应该配置参数replicate-wild-do-table=databaseB.%

slave3上应该配置参数replicate-wild-do-table=databaseC.%

每个slave其实是接收到完整的bin log日志，但在应用环节中会进行过滤，仅应用符合参数配置的事件

在配置完参数之后，通过mysqldump的方式将对应数据库在slave应用起来，再启动slave线程







#### 5.14.MySQL延迟复制

延迟复制是指定从库对主库的延迟至少是指定的这个间隔时间，默认是0秒。可以通过change master to命令来指定

CHANGE MASTER TO 

   	MASTER_DELAY = N（秒）;

其原理是从库收到主库的bin log之后，不是立即执行，而是等待指定的秒数之后再执行

延迟复制的使用场景比如：

1.确保在主库上被错误修改的数据能及时找回

2.测试在从库IO集中在恢复bin log过程中对应用程序的访问影响

3.保留一份若干天前的数据库状态，和当前状态可以做对比

show slave status中SQL_Delay值表明了设置的延迟时长



```
在从机操作：
mysql> stop slave;
Query OK, 0 rows affected (0.00 sec)

mysql> CHANGE MASTER TO MASTER_DELAY = 10 ;
Query OK, 0 rows affected (0.00 sec)

mysql> start slave;
Query OK, 0 rows affected (0.00 sec)

在主机操作：
mysql> insert into test values(1,'ljr','man');
Query OK, 1 row affected (0.01 sec)


在从机查看：
mysql> select * from test;
Empty set (0.00 sec)

mysql> select * from test;
Empty set (0.00 sec)

mysql> select * from test;
Empty set (0.00 sec)

mysql> select * from test;
Empty set (0.00 sec)

mysql> select * from test;
Empty set (0.00 sec)
 
mysql> select * from test;
Empty set (0.00 sec)

mysql> select * from test;
+------+------+------+
| id   | name | sex  |
+------+------+------+
|    1 | ljr  | man  |
+------+------+------+
1 row in set (0.00 sec)
```





提问：异步复制，全同步复制，半同步复制有什么区别？

https://zhuanlan.zhihu.com/p/452529201





#### 5.15.半同步复制：

​		默认创建的MySQL复制是异步的，意味着主库将数据库修改事件写入到自己的bin log，而并不知道从库是否获取了这些事件并应用在自己身上。所以当主

库崩溃导致要主从切换时，有可能从库上的数据不是最新的

​		从5.7版本开始MySQL通过扩展的方式支持了半同步复制，当主库执行一个更新操作事务时，提交操作会被阻止直到至少有一个半同步的复制slave确认已经接收到本次更新操作，主库的提交操作才会继续半同步复制的slave发送确认消息只会在本次更新操作记录已经记录到本地的relay log之后如果没有任何slave发送确认消息而导致超时时，半同步复制会转换成异步复制

半同步复制会对MySQL性能产生影响，因为主库的提交动作只有在收到至少一个从库的确认消息之后才能执行。但这个功能是性能和数据可靠性方面的权

衡















### 6、使用GTID恢复数据

#### 6.1.GTID 的概念

1、全局事务标识：global transaction identifiers。
2、GTID(Global Transaction ID)  是对于一个已提交事务的编号，并且是一个全局唯一的编号。
3、一个GTID在一个服务器上只执行一次，避免重复执行导致数据混乱或者主从不一致。
4、GTID 用来代替传统 AB 复制方法，不再使用  MASTER_LOG_FILE + MASTER_LOG_POS  开启复制。
      而是使用  MASTER_AUTO_POSTION=1  的方式开始复制。

#### 6.2.GTID 的组成   

**<font color='cornflowerblue'>GTID = source_id:transaction_id </font>**
source_id，用于鉴别原服务器，即mysql服务器唯一的的server_uuid，由于 GTID 会传递到slave，所以也可以理解为源ID。
transaction_id，为当前服务器上已提交事务的一个序列号，通常从1开始自增长的序列，一个数值对应一个事务。        

示例：
3E11FA47-71CA-11E1-9E33-C80AA9429562:23
前面的一串为服务器的server_uuid，即3E11FA47-71CA-11E1-9E33-C80AA9429562，后面的23为transaction_id

在首次启动时 MySQL 会自动生成一个 server_uuid，
并且保存到数据目录的auto.cnf 文件 —— 这个文件目前存在的唯一目的就是保存 server_uuid。
在 MySQL 再次启动时会读取 auto.cnf 文件，继续使用上次生成的 server_uuid。

#### 6.3.GTID 的优势

1、更简单的实现 failover，不用以前那样在需要找 log_file 和 log_pos。
2、更简单的搭建主从复制。
3、比传统的复制更加安全。
4、GTID是连续的没有空洞的，保证数据的一致性，零丢失。



#### 6.4.开启gtid

```shell
[root@mysql01 ~]# vim /etc/my.cnf
[mysqld]
gtid-mode=on
enforce-gtid-consistency=true       #对事务强制添加事务号
```

重启生效

```shell
[root@mysql01 ~]# systemctl restart mysqld
```

```
mysql> show master status;
```

此事时还没有gtid的

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203061243574.png)

插入一些数据后

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203061244748.png)

**语法：**

**mysqlbinlog --include-gtids=xxxxx:id(范围)  --exclude-gtids=xxxxxx:id（排除的id号）mysql-bin.xxxx  mysql-bin.xxxx >/opt/xxx.sql**

![2022-03-06_131330](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203061314980.png)

 ![2022-03-06_131343](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203061315496.png)

 ![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203061316716.png)

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203061314957.png)

```shell
[root@mysql01 ~]# mysqlbinlog --include-gtids=10965a34-9b51-11ec-b179-000c295bf3f4:8-10 --exclude-gtids=10965a34-9b51-11ec-b179-000c295bf3f4:10 /data/binlog/mysql-bin.000002 >/opt/test.sql
```

恢复数据

```mysql
mysql> source /opt/test.sql;
```

恢复不成功

 ![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203061317389.png)



<font color='red'>**gtid的幂等性：**</font>
**<font color='red'>数据库中有相关执行过的gtid的id，不会再执行了。</font>**
**参数：--skip-gtids  #注释掉gtid信息**
**语法：**
**mysqlbinlog --skip-gtids  --include-gtids=xxxxx:id(范围)  --exclude-gtids=xxxxxx:id（排除的id号）mysql-bin.xxx1   mysql-bin.xxx2（跨文件是两个binlog的写法） >/opt/xxx.sql**

```shell
[root@mysql01 ~]# mysqlbinlog --skip-gtids --include-gtids=10965a34-9b51-11ec-b179-000c295bf3f4:8-10 --exclude-gtids=10965a34-9b51-11ec-b179-000c295bf3f4:10 /data/binlog/mysql-bin.000002 >/opt/test.sql
```

```mysql
mysql> source /opt/test.sql;
```

 ![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203061319072.png)



### 7、基于gtid的主从复制

#### 7.1.在主库上开启binlog日志

```shell
[root@mysql01 ~]# vim /etc/my.cnf
[mysqld]
server_id=1  
log_bin=/data/binlog/mysql-bin  
sync_binlog=1 
binlog_format=row 
expire_logs_days=15 
max_binlog_size=100M 
```

重启生效

```
[root@mysql01 ~]# systemctl restart mysqld
```



#### 7.2.配置主从复制用户并授权

```mysql
mysql> grant replication slave on *.* to repl_user@"%" identified by "123456";
mysql> flush privileges;
```



#### 7.3.查看主库当前状态

```mysql
mysql> show master status;
```



#### 7.4.配置从库

修改从库server_id不能与主库相同

主从机子都要开启gtid

```shell
[root@mysql02 ~]# vim /etc/my.cnf
server_id=2   #修改成不与主机一样
gtid-mode=on
enforce-gtid-consistency=true

注：从机可以不需要开启binlog日志也可以建立主从关系，但不可以恢复数据，因为没有binlog日志

[root@mysql02 ~]# systemctl restart mysql
```



#### 7.5.开启主从复制并查看状态

```mysql
mysql> CHANGE MASTER TO
    -> MASTER_HOST='192.168.188.128',
    -> MASTER_USER='repl_user',
    -> MASTER_PASSWORD='123456',
    -> MASTER_AUTO_POSITION=1,
    -> MASTER_CONNECT_RETRY=10; 
Query OK, 0 rows affected, 2 warnings (0.00 sec)
```

```mysql
#在主机和从机都执行
mysql> reset slave;

#在从机
mysql> start slave;
Query OK, 0 rows affected (0.01 sec)

mysql> show slave status\G
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203061330935.png)



#### 7.6.验证主从复制

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203061332656.png)



### 8、主从读写分离

#### 8.1.查看只读模式是否开启

在从机上：

```mysql
mysql> show variables like 'read_only';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| read_only     | OFF   |
+---------------+-------+
1 row in set (0.00 sec)
```



#### 8.2.开启只读模式

在从机上：

```mysql
mysql> set global  read_only=1;
Query OK, 0 rows affected (0.00 sec)

mysql> show variables like 'read_only';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| read_only     | ON    |
+---------------+-------+
1 row in set (0.00 sec)
```



#### 8.3.新增普通用户，授予增删减改权限

在从机上：

```mysql
mysql> grant select,update,delete,insert on *.* to test@'%' identified by '123456';
Query OK, 0 rows affected, 1 warning (0.00 sec)

mysql> flush privileges;
Query OK, 0 rows affected (0.00 sec)
```



#### 8.4.测试：

```shell
[root@mysql02 ~]# mysql -utest -p123456			#切换普通用户
```

```mysql
mysql> select * from class.replication;
+----+-------+
| c1 | c2    |
+----+-------+
|  2 | test2 |
|  3 | test3 |
|  4 | test4 |
+----+-------+
3 rows in set (0.00 sec)

mysql> insert into class.replication values(8,'test8');
ERROR 1290 (HY000): The MySQL server is running with the --read-only option so it cannot execute this statement
```



#### 8.5.切换root用户

```shell
[root@mysql02 ~]# mysql -uroot -p123456			#切换特权用户
```

```mysql
mysql> insert into class.replication values(8,'test8');
Query OK, 1 row affected (0.00 sec)

mysql> select * from class.replication;
+----+-------+
| c1 | c2    |
+----+-------+
|  2 | test2 |
|  3 | test3 |
|  4 | test4 |
|  8 | test8 |
+----+-------+
4 rows in set (0.00 sec)
```



#### 8.6.查看特权只读模式是否开启

```mysql
mysql> show variables like 'super_read_only';
+-----------------+-------+
| Variable_name   | Value |
+-----------------+-------+
| super_read_only | OFF   |
+-----------------+-------+
1 row in set (0.00 sec)
```



#### 8.7.开启只读模式

```mysql
mysql> set global  super_read_only=1;
Query OK, 0 rows affected (0.00 sec)

mysql> show variables like 'super_read_only';
+-----------------+-------+
| Variable_name   | Value |
+-----------------+-------+
| super_read_only | ON    |
+-----------------+-------+
1 row in set (0.00 sec)
```



#### 8.8.测试

```mysql
mysql> delete from class.replication where c1>5;
ERROR 1290 (HY000): The MySQL server is running with the --super-read-only option so it cannot execute this statement
```

<font color='red'>**注：可以得出结论：普通用户可以通过设置read_only=1开启只读模式，但特权用户不受影响**</font>

​									**<font color='red'>特权用户可以通过设置super_read_only=1限制只读权限</font>**

