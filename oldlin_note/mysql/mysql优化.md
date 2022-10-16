## 														mysql优化

### 1、安全优化（业务持续性）

长期工作：
需要长期的一个优化和攻防策略、数据库保护策略：
在数据库必须开放到公网的情况下：
1，设置复杂度较高的密码。一般来说，8-32位，大小写字母，数字加特殊符号。一般180天更换一次，业务生产酌情考虑更换。
2，增加域名式访问，使用ssl机制，采用https方式连接。必要的情况下，相应的ip开放白名单。
3，必要时，加入相应的云安全产品或者硬件安全产品。比如waf。在有版本漏洞的情况下，必须升级数据库。
生产建议：数据库尽量不要放到公网。

### 2、操作系统方面:

主机架构稳定性

I/O规划及配置

Swap

OS内核参数

网络问题

### 3、硬件优化方面：

\#CPU根据数据库类型
OLTP ： 在线事务处理 IO密集型，线上系统，OLTP主要是IO密集型的业务，高并发 ，E系列（至强），主频相对低，核心数量多
OLAP : CPU密集型：数据分析数据处理，OLAP，cpu密集型的，需要CPU高计算能力（i系列，IBM power系列 I 系列的，主频很高，核心少 )

\# 内存
建议2-4倍cpu核心数量 （ECC）

\# 磁盘选择
SATA-III , SAS , Fc , SSD（sata）, pci-e ssd , Flash

### 4、mysql架构优化：

高可用

读写分离

分布式

NoSQL

### 5、业务层面:（Index，lock，session）

数据库或表设计

应用程序稳定性和性能

SQL语句性能

串行访问资源

性能欠佳会话管理

### 6、数据库优化工具常用命令：

show status 

show variables

show index from 表名

<font color='red'>show processlist</font>

  show slave status

  show engine innodb status

desc /explain

​    slowlog

### 7、优化细节（参数优化）：

#### 7.1.skip-name-resolve

简介：禁止MYSQL对外部连接进行DNS解析，可以省去MYSQL进行DNS解析的时间

#### 7.2.Max_connections 

（1）简介
Mysql的最大连接数，如果服务器的并发请求量比较大，可以调高这个值，当然这是要建立在机器能够支撑的情况下，因为如果连接数越来越多，mysql会为每个连接提供缓冲区，就会开销的越多的内存，所以需要适当的调整该值，不能随便去提高设值。

（2）判断依据
show variables like 'max_connections';          #最大连接数

  +-----------------+-------+

  | Variable_name | Value |

  +-----------------+-------+

  | max_connections | 151 |

  +-----------------+-------+

show status like 'Max_used_connections';        #最大用户使用数（随着用户使用而改变）

  +----------------------+-------+

  | Variable_name    | Value |

  +----------------------+-------+

  | Max_used_connections | 10 |

  +----------------------+-------+

（3）修改方式举例

vim /etc/my.cnf

max_connections=1024

如何设置：
  1.开启数据库时,我们可以临时设置一个比较大的测试值
  2.观察show status like 'Max_used_connections';变化
  3.如果max_used_connections跟max_connections相同,
  那么就是max_connections设置过低或者超过服务器的负载上限了，
  低于10%则设置过大.



#### 7.3.back_log 

（1）简介
mysql能暂存的连接数量，当主要mysql线程在一个很短时间内得到非常多的连接请求时候它就会起作用，如果mysql的连接数据达到max_connections时候，新来的请求将会被存在堆栈中，等待某一连接释放资源，back_log存储该推栈的数量，如果等待连接的数量超过back_log，将不被授予连接资源。

back_log值指出在mysql暂时停止回答新请求之前的短时间内有多少个请求可以被存在推栈中，只有如果期望在一个短时间内有很多连接的时候需要增加它

（2）判断依据
show full processlist

发现大量的待连接进程时，就需要加大back_log或者加大max_connections的值

（3）修改方式举例

vim /etc/my.cnf
back_log=1024



#### 7.4.wait_timeout和interactive_timeout 

（1）简介
wait_timeout：指的是mysql在关闭一个<font color='red'>非交互</font>的连接之前所要等待的秒数
mysql> show variables like 'wait_timeout';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| wait_timeout  | 28800 |
+---------------+-------+
1 row in set (0.00 sec)

interactive_timeout：指的是mysql在关闭一个<font color='red'>交互</font>的连接之前所需要等待的秒数，比如我们在终端上进行mysql管理，使用的即使交互的连接，这时候，如果没有操作的时间超过了interactive_time设置的时间就会自动的断开，默认的是28800，可调优为7200。
mysql> show variables like 'interactive_timeout';
+---------------------+-------+
| Variable_name       | Value |
+---------------------+-------+
| interactive_timeout | 28800 |
+---------------------+-------+
1 row in set (0.00 sec)

（2）设置建议
wait_timeout:如果设置太小，那么连接关闭的就很快，从而使一些持久的连接不起作用
如果设置太大，容易造成连接打开时间过长，在show processlist时候，能看到很多的连接 ，一般希望wait_timeout尽可能低

（3）修改方式举例
vim /etc/my.cnf
wait_timeout=120
interactive_timeout=7200

长连接的应用，为了不去反复的回收和分配资源，降低额外的开销。

一般我们会将wait_timeout设定比较小，interactive_timeout要和应用开发人员沟通长链接的应用是否很多。如果他需要长链接，那么这个值可以不需要调整。

另外还可以使用类似的参数弥补。
增加内核参数：
vim /etc/sysctl.conf
net.ipv4.tcp_keepalive_time = 60 
刷新参数生效：
/sbin/sysctl -p

#### 7.5.max_connect_errors=20

简介：最大连接失败次数，默认值是100，达到此上限后会阻止连接数据库

mysql> show variables like 'max_connect_errors';
+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| max_connect_errors | 100   |
+--------------------+-------+
1 row in set (0.00 sec)

#### 7.6.tmp_table_size=256M

简介：指定内存临时表空间最大值。如果超过此值 ，则会将临时表写入磁盘中，可设置范围为1KB~4GB

#### 7.7.key_buffer_size 

（1）简介
key_buffer_size指定索引缓冲区的大小，它决定索引处理的速度，尤其是索引读的速度

《1》此参数与myisam表的索引有关
《2》临时表的创建有关（多表链接、子查询中、union）
在有以上查询语句出现的时候，需要创建临时表，用完之后会被丢弃
注：key_buffer_size只对myisam表起作用，即使不使用myisam表，但是内部的临时磁盘表是myisam表，也要使用该值。

可以使用检查状态值created_tmp_disk_tables得知：

mysql> show status like "created_tmp%";

+-------------------------+-------+

| Variable_name     | Value |

+-------------------------+-------+

| Created_tmp_disk_tables | 0  |

| Created_tmp_files   | 6  |

| Created_tmp_tables   | 1  |

+-------------------------+-------+

3 rows in set (0.00 sec)



通常地，我们习惯以

Created_tmp_tables/(Created_tmp_disk_tables + Created_tmp_tables)

Created_tmp_disk_tables/(Created_tmp_disk_tables + Created_tmp_tables)

或者已各自的一个时段内的差额计算，来判断基于内存的临时表利用率。所以，我们会比较关注 Created_tmp_disk_tables 是否过多，从而认定当前服务器运行状况的优劣。

Created_tmp_disk_tables/(Created_tmp_disk_tables + Created_tmp_tables)

控制在5%-10%以内

配置：
vim /etc/my.cnf
key_buffer_size=64M



#### 7.8.query_cache_size 

（1）简介：
查询缓存简称QC，主要缓存SQL语句hash值+执行结果（内存里），默认为1M。

10条语句，经常做查询。

案例四 ： 开QC ，导致性能降低。 QPS ，TPS降低。

没开起的时候。QPS 2000 TPS 500

开了之后直接降低到 800，200

为什么呢？

分区表。Query Cache 不支持。

配置：
vim /etc/my.cnf
query_cache_size=5M 		#设得越大，占得内存就越多，不建议设置很大



#### 7.9.query_cache_limit

简介：指定单个查询能够使用的缓冲区大小，默认为1M。

#### 7.10.query_cache_type

简介：是否开启缓存功能，取值为ON, OFF, DEMAND，默认值为OFF

　　- 值为OFF或0时，查询缓存功能关闭；
　　- 值为ON或1时，查询缓存功能打开，SELECT的结果符合缓存条件即会缓存，否则，不予缓存，显式指定SQL_NO_CACHE，不予缓存；
　　- 值为DEMAND或2时，查询缓存功能按需进行，显式指定SQL_CACHE的SELECT语句才会缓存；其它均不予缓存



#### 7.11.sort_buffer_size 

（1）简介：
每个需要进行排序的线程分配该大小的一个缓冲区。增加这值加速

ORDER BY

GROUP BY

distinct

union

（2）配置依据
Sort_Buffer_Size并不是越大越好，由于是connection级的参数，过大的设置+高并发可能会耗尽系统内存资源。

列如：500个连接将会消耗500*sort_buffer_size（2M）=1G内存
根据实际业务来设置此参数，默认值为256kb，谨慎使用。

（3）配置方法
修改/etc/my.cnf文件

[mysqld]

sort_buffer_size=1M

建议： 尽量排序能够使用索引更好。



#### 7.12.max_allowed_packet 

（1）简介：

mysql根据配置文件会限制，server接受的数据包大小。

（2）配置依据：

根据实际业务来设置此参数，默认值为4M

有时候大的插入和更新会受max_allowed_packet参数限制，导致写入或者更新失败，更大值是1GB，必须设置1024的倍数

（3）配置方法：
vim /etc/my.cnf
max_allowed_packet=32M



#### 7.13.join_buffer_size 

select a.name,b.name from a join b on a.id=b.id where xxxx

用于表间关联缓存的大小，和sort_buffer_size一样，该参数对应的分配内存也是每个连接独享。

尽量在SQL与方面进行优化，效果较为明显。

优化的方法：在on条件列加索引，至少应当是有MUL索引

建议： 尽量能够使用索引优化更好。



#### 7.14.thread_cache_size = 16 

(1)简介

服务器线程缓存，这个值表示可以重新利用保存在缓存中线程的数量,当断开连接时,那么客户端的线程将被放到缓存中以响应下一个客户连接而不是销毁(前提是缓存数未达上限),如果线程重新被请求，那么请求将从缓存中读取,如果缓存中是空的或者是新的请求，那么这个线程将被重新创建,如果有很多新的线程，增加这个值可以改善系统性能.

（2）配置依据

通过比较 Connections 和 Threads_created 状态的变量，可以看到这个变量的作用。

<font color='red'>设置规则如下：1GB 内存配置为8，2GB配置为16，3GB配置为24，4GB或更高内存，可配置更大。</font>

试图连接到MySQL(不管是否连接成功)的连接数

mysql> show status like 'threads_%';
+-------------------+-------+
| Variable_name     | Value |
+-------------------+-------+
| Threads_cached    | 1     |
| Threads_connected | 3     |
| Threads_created   | 4     |
| Threads_running   | 1     |
+-------------------+-------+
4 rows in set (0.00 sec)


Threads_cached :代表当前此时此刻线程缓存中有多少空闲线程。

Threads_connected:代表当前已建立连接的数量，因为一个连接就需要一个线程，所以也可以看成当前被使用的线程数。

Threads_created:代表从最近一次服务启动，已创建线程的数量，如果发现Threads_created值过大的话，表明MySQL服务器一直在创建线程，这也是比较耗cpu 资源，可以适当增加配置文件中thread_cache_size值。

Threads_running :代表当前激活的（非睡眠状态）线程数。并不是代表正在使用的线程数，有时候连接已建立，但是连接处于sleep状态。

(3)配置方法：
vim /etc/my.cnf
thread_cache_size=16

如何设置：
Threads_created ：一般在架构设计阶段，会设置一个测试值，做压力测试。结合zabbix监控，看一段时间内此状态的变化。如果在一段时间内，Threads_created趋于平稳，说明对应参数设定是OK。
如果一直陡峭的增长，或者出现大量峰值，那么继续增加此值的大小，在系统资源够用的情况下（内存）



#### 7.15.<font color='red'>innodb_buffer_pool_size</font> 

（1）简介
对于InnoDB表来说，innodb_buffer_pool_size的作用就相当于key_buffer_size对于MyISAM表的作用一样。
InnoDB使用该参数指定大小的内存来缓冲数据和索引。

（2）配置规则：
对于单独的MySQL数据库服务器，最大可以把该值设置成物理内存的80%,一般我们建议不要超过物理内存的70%。

（3）配置方法
vim /etc/my.cnf
innodb_buffer_pool_size=1400M





#### 7.16.innodb_flush_log_at_trx_commit 

（1）简介
主要控制了innodb将log buffer中的数据写入日志文件并flush磁盘的时间点，取值分别为0、1、2三个。

0，表示当事务提交时，不做日志写入操作，而是每秒钟将log buffer中的数据写入日志文件并flush&sync磁盘一次；

1，每次事务的提交都会引起redo日志文件写入、flush&sync磁盘的操作，确保了事务的ACID；

2，每次事务提交引起写入日志文件的动作,但每秒钟完成一次sync磁盘操作。

（2）配置依据
实际测试发现，该值对插入数据的速度影响非常大，设置为2时插入10000条记录只需要2秒，设置为0时只需要1秒，而设置为1时则需要229秒。因此，MySQL手册也建议尽量将插入操作合并成一个事务，这样可以大幅提高速度。

根据MySQL官方文档，在允许丢失最近部分事务的危险的前提下，可以把该值设为0或2。

（3）配置方法
vim /etc/my.cnf
innodb_flush_log_at_trx_commit=1



#### 7.17.<font color='red'>innodb_thread_concurrency</font> 

（1）简介
此参数用来限制innodb线程的并发数量，默认值为0表示不限制。

（2）配置依据
在官方doc上，对于innodb_thread_concurrency的使用，也给出了一些建议，如下：
如果一个工作负载中，并发用户线程的数量小于64，建议设置innodb_thread_concurrency=0；
如果工作负载一直较为严重甚至偶尔达到顶峰，建议先设置innodb_thread_concurrency=128，
并通过不断的降低这个参数，96, 80, 64等等，直到发现能够提供最佳性能的线程数，

例如，假设系统通常有40到50个用户，但定期的数量增加至60，70，甚至200。你会发现，
性能在80个并发用户设置时表现稳定，如果高于这个数，性能反而下降。在这种情况下，
建议设置innodb_thread_concurrency参数为80，以避免影响性能。
如果你不希望InnoDB使用的虚拟CPU数量比用户线程使用的虚拟CPU更多（比如20个虚拟CPU），
建议通过设置innodb_thread_concurrency 参数为这个值（也可能更低，这取决于性能体现），
如果你的目标是将MySQL与其他应用隔离，你可以l考虑绑定mysqld进程到专有的虚拟CPU。
但是需 要注意的是，这种绑定，在myslqd进程一直不是很忙的情况下，可能会导致非最优的硬件使用率。在这种情况下，
你可能会设置mysqld进程绑定的虚拟 CPU，允许其他应用程序使用虚拟CPU的一部分或全部。
在某些情况下，最佳的innodb_thread_concurrency参数设置可以比虚拟CPU的数量小。
定期检测和分析系统，负载量、用户数或者工作环境的改变可能都需要对innodb_thread_concurrency参数的设置进行调整。

设置标准：

1、当前系统cpu使用情况，均不均匀

2、当前的连接数，有没有达到顶峰

show status like 'threads_%';

show processlist;

（3）配置方法：
vim /etc/my.cnf
innodb_thread_concurrency=8

方法:

1. 看top ,观察每个cpu的各自的负载情况

2. 发现不平均,先设置参数为cpu个数,然后不断增加(一倍)这个数值

3. 一直观察top状态,直到达到比较均匀时,说明已经到位了.



#### 7.18.innodb_log_buffer_size

此参数确定日志文件所用的内存大小，以M为单位。缓冲区更大能提高性能，对于较大的事务，可以增大缓存大小。

innodb_log_buffer_size=128M

设定依据：

1、大事务： 存储过程调用 CALL

2、多事务

#### 7.19.innodb_log_file_size = 100M *****

设置 ib_logfile0 ib_logfile1

此参数确定数据日志文件的大小，以M为单位，更大的设置可以提高性能.

innodb_log_file_size = 100M

innodb_log_files_in_group = 3

为提高性能，MySQL可以以循环方式将日志文件写到多个文件。推荐设置为3



#### 7.20.read_buffer_size = 1M 

MySql读入缓冲区大小。对表进行顺序扫描的请求将分配一个读入缓冲区，MySql会为它分配一段内存缓冲区。如果对表的顺序扫描请求非常频繁，并且你认为频繁扫描进行得太慢，可以通过增加该变量值以及内存缓冲区大小提高其性能。和 sort_buffer_size一样，该参数对应的分配内存也是每个连接独享

#### 7.21.read_rnd_buffer_size = 1M 

MySql的随机读（查询操作）缓冲区大小。当按任意顺序读取行时(例如，按照排序顺序)，将分配一个随机读缓存区。进行排序查询时，MySql会首先扫描一遍该缓冲，以避免磁盘搜索，提高查询速度，如果需要排序大量数据，可适当调高该值。但MySql会为每个客户连接发放该缓冲空间，所以应尽量适当设置该值，以避免内存开销过大。

注：顺序读是指根据索引的叶节点数据就能顺序地读取所需要的行数据。随机读是指一般需要根据辅助索引叶节点中的主键寻找实际行数据，而辅助索引和主键所在的数据段不同，因此访问方式是随机的。

#### 7.22.bulk_insert_buffer_size = 8M 

批量插入数据缓存大小，可以有效提高插入效率，默认为8M





### 8、安全参数 


Innodb_flush_method=(O_DIRECT, fsync)

1、fsync  ：

（1）在数据页需要持久化时，首先将数据写入OS buffe（系统缓存）中，然后由os（操作系统）决定什么时候写入磁盘

（2）在redo buffuer需要持久化时，首先将数据写入OS buffer中，然后由os决定什么时候写入磁盘

但，如果innodb_flush_log_at_trx_commit=1的话，操作数据还是直接每次commit直接写入磁盘

2、 O_DIRECT

（1）在数据页需要持久化时，直接写入磁盘

（2）在redo buffuer需要持久化时，首先将数据写入OS buffer中，然后由os决定什么时候写入磁盘

但，如果innodb_flush_log_at_trx_commit=1的话，日志还是直接每次commit直接写入磁盘

最安全模式：

innodb_flush_log_at_trx_commit=1

innodb_flush_method=O_DIRECT

最高性能模式：

innodb_flush_log_at_trx_commit=0

innodb_flush_method=fsync

一般情况下，我们更偏向于安全。



#### 参数优化结果，基于4核4G实体数据库服务器的优化参数模板：

```shell
[mysqld]
basedir=/data/mysql
datadir=/data/mysql/data
socket=/tmp/mysql.sock
log-error=/var/log/mysql.log
log_bin=/data/binlog/mysql-bin
binlog_format=row
skip-name-resolve
server-id=1
gtid-mode=on
enforce-gtid-consistency=true
log-slave-updates=1
relay_log_purge=0
max_connections=1024
back_log=128
wait_timeout=60
interactive_timeout=7200
key_buffer_size=16M
query_cache_size=64M
query_cache_type=1
query_cache_limit=50M
max_connect_errors=20
sort_buffer_size=2M
max_allowed_packet=32M
join_buffer_size=2M
thread_cache_size=200
innodb_buffer_pool_size=4096M
innodb_flush_log_at_trx_commit=1
innodb_log_buffer_size=32M
innodb_log_file_size=128M
innodb_log_files_in_group=3
binlog_cache_size=2M
max_binlog_cache_size=8M
max_binlog_size=512M
expire_logs_days=7
read_buffer_size=2M
read_rnd_buffer_size=2M
bulk_insert_buffer_size=8M

[client]
socket=/tmp/mysql.sock
```

再次压力测试 ：

```mysql
mysqlslap --defaults-file=/etc/my.cnf --concurrency=100 --iterations=1 --create-schema='today' --query="select * from today.test where name='zhangs'" engine=innodb --number-of-queries=200000 -uroot -p123456 -verbos
```

