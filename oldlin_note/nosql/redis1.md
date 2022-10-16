

### 1、什么是NoSQL数据库

泛指非关系型数据库，NoSQL数据库并没有一个统一的架构，每种NoSQL数据库都各不相同，在各自不同的场景与领域发挥着不同的用途。

### 2、NoSQL数据库的分类

总体分四大类：键值（key-value）数据库，列存储数据库，文档数据库，图形数据库

#### 2.1. 键值对数据库	

键值对数据库主要是维护一个哈希表，表里存储着一个特定键值对。这类数据库操作简单常见的键值对数据库有Redis和Memcached等。

#### 2.2.列存储数据库	

列存储数据库通常用于分布式存储场景中。常见的列存储数据库HBase。

#### 2.3.文档数据库

文档数据库与键值对数据库类似，它没有特定的格式、结构，但比键值对数据库的效率要高。常见的文档数据库是MongoDB。

#### 2.4*.*图形数据库

图形数据库很容易理解，也就是存储一些图像的数据库。它使用比较灵活的图形模型，可以扩展到多台服务器上。常见的图形数据库有Graph和Neo4j。



### 3、什么是redis


Redis 是完全开源的，遵守 BSD 协议，是一个高性能的 key-value 数据库。

Redis 与其他 key - value 缓存产品有以下三个特点：
• Redis支持数据的持久化，可以将内存中的数据保存在磁盘中，重启的时候可以再次加载进行使用。
• Redis不仅仅支持简单的key-value类型的数据，同时还提供list，set，zset，hash等数据结构的存储。
• Redis支持数据的备份，即master-slave模式的数据备份。



### 4、Redis 优势

• 性能极高 – Redis能读的速度是<font color='red'>110000</font>次/s,写的速度是<font color='red'>81000</font>次/s 。
• 丰富的数据类型 – Redis支持二进制案例的 Strings, Lists, Hashes, Sets 及 Ordered Sets 数据类型操作。
• 原子 – Redis的所有操作都是原子性的，意思就是要么成功执行要么失败完全不执行。单个操作是原子性的。多个操作也支持事务，即原子性，通过MULTI和EXEC指令包起来。
• 丰富的特性 – Redis还支持 publish/subscribe, 通知, key 过期等等特性

### 5、常用的分布式缓存的对比

常用的分布式缓存包括Redis、Memcached和阿里巴巴的Tair（见下表），
因为Redis提供的数据结构比较丰富且简单易用，所以Redis的使用广泛。

![file://c:\users\admini~1\appdata\local\temp\tmpsrptxj\1.png](https://s2.loli.net/2022/03/08/zIKesD5QiHt6E9N.png)

Memcached:
优点：高性能读写、单一数据类型、支持客户端式分布式集群、一致性hash，多核结构、多线程读写性能高。
缺点：无持久化、节点故障可能出现缓存穿透、分布式需要客户端实现、跨机房数据同步困难、架构扩容复杂度高

Redis:  
优点：高性能读写、多数据类型支持、数据持久化、高可用架构、支持自定义虚拟内存、支持分布式分片集群、单线程读写性能极高（redis6.0以前版本没有多线程）
缺点：线程读写较Memcached慢
以上两种广泛应用于网页类、游戏类产品、金融交易类
    
memcache与redis在读写性能的对比
memcached 适合多用户访问,每个用户少量的rw
redis     适合少用户访问,每个用户大量rw （所有的对比，针对redis6.0以前版本。）
            
Tair：(Tair是由淘宝网自主开发的Key/Value结构数据存储系统，在淘宝网有着大规模的应用。)
优点：高性能、高扩展、高可用，也就是传说中的三高产品，支持分布式集群部署、支撑了几乎所有淘宝业务的缓存。
缺点：单机情况下，读写性能较其他两种产品较慢

### 6、redis单机安装

#### 6.1.下载redis并编译安装

[root@redis1 opt]# wget https://download.redis.io/releases/redis-7.0.2.tar.gz
[root@redis1 opt]# tar -xvf redis-7.0.2.tar.gz
[root@redis1 opt]# cd redis-7.0.2
[root@redis1 redis-5.0.13]# make
[root@redis1 redis-5.0.13]# mkdir -p /usr/local/redis/conf 
[root@redis1 redis-5.0.13]# mkdir /usr/local/redis/bin
[root@redis1 redis-5.0.13]# mkdir /usr/local/redis/log

#### 6.2.配置到/usr/local/redis/bin

![file://c:\users\admini~1\appdata\local\temp\tmpsrptxj\2.png](https://s2.loli.net/2022/03/08/zoCvWru578Nt3Yw.png)
配置到/usr/local/redis/conf
![file://c:\users\admini~1\appdata\local\temp\tmpsrptxj\3.png](https://s2.loli.net/2022/03/08/3zDXJYwGRTfQjsF.png)

#### 6.3.设置系统环境变量：

vim /etc/profile
export PATH=$PATH:/usr/local/redis/bin/ 
[root@redis1 opt]# source /etc/profile

#### 6.4.启动redis:

[root@redis1 src]# redis-server

#### 6.5.解决warning问题 

1.echo "echo 511 >/proc/sys/net/core/somaxconn" >>/etc/rc.d/rc.local		

#重启机器，该文件内容会还原，所以把此命令添加到开机启动

2.echo vm.overcommit_memory = 1 >>/etc/sysctl.conf 
重新加载内核参数：sysctl -p

3.echo never > /sys/kernel/mm/transparent_hugepage/enabled
添加开机启动：echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.d/rc.local
这样可以了没？

远程连接语法：
 redis-cli -h host -p port -a password

关闭redis语法:
redis-cli -h host -p port -a password shutdown

#### 6.6.检查是否启动成功：

[root@redis1 ~]# redis-cli    #后不接-p参数，默认以6379端口启动
127.0.0.1:6379> ping
PONG

#### 6.7.配置文件：（需要关注的参数）

vim  redis.conf
87   bind ip              #绑定指定ip 
111   protected-mode yes/no #保护模式，是否只允许本地访问
138   port 6379         #端口号
309 daemonize yes  #开启后台运行模式
354  logfile /xxxx/redis.log #指定日志生成路径和文件名字 
481  dbfilename dump.rdb #默认的持久化文件名字
504  dir /data/redis          #指定应用持久化路径
1036  requirepass 123456(需新增加)    #开启密码验证，生产建议复杂密码。



#### 6.8.在线查看和临时性修改配置

127.0.0.1:6379> config get *
127.0.0.1:6379> config get  requirepass
127.0.0.1:6379> config get  r*
127.0.0.1:6379> config set  requirepass 123456
127.0.0.1:6379> auth 123456         #输入密码

注：永久修改需要修改配置文件



### 7、redis 持久化、备份与恢复

redis 持久化（内存数据保存到磁盘）有两种方式：RDB和AOF

#### 7.1.RDB 持久化

存储在内存的数据以快照 的方式写入二进制文件中，如默认的dump.rdb。
    优点：速度快，适合于用做备份。
    缺点：会有数据丢失

rdb持久化核心配置参数：
vim redis.conf

旧版写法：

save 900 1                  900秒（15分钟）内有1个键更改，则启动快照保存
save 300 10                 300秒（5分钟）内有10个键更改，则启动快照保存
save 60 10000             60秒内有10000个键更改，则启动快照保存

新版写法：

save 3600 1 300 100 60 10000

#### 7.2.AOF 持久化

​    记录服务器执行的所有写操作命令到appendonly.aof，并在服务器启动时，通过重新执行这些命令来还原数据集。 
​    AOF 文件中的命令全部以 Redis 协议的格式来保存，新命令会被追加到文件的末尾。
​    优点：可以最大程度保证数据不丢
​    缺点：日志记录量级比较大

AOF持久化配置
1381  appendonly yes                  开启AOF持久化存储方式
1439  appendfsync always           收到写命令后立即写入磁盘，效果最好
1440  appendfsync everysec        每秒写入磁盘一次，可能会造成数据丢失
1441  appendfsync no                  完全依赖操作系统，由操作系统判断内存缓冲区大小，效果无法保证

注：对于AOF与RDB备份，服务读取文件的优先顺序不同，会按照以下优先级进行启动
1.如果只配置了AOF，启动时将加载AOF文件恢复数据
2.<font color='red'>如果同时配置了AOF与RDB，启动时只加载AOF文件恢复数据</font>
3.如果只配置了RDB，启动时将加载dump文件恢复数据

#### 7.3.面试问题： 

redis 持久化方式有哪些？有什么区别？
rdb：基于快照的持久化，速度更快，一般用作备份，redis主从复制也是依赖于rdb持久化功能,压缩比高，体积小比较省空间。
aof：以追加的方式记录redis写操作日志的文件。可以最大程度的保证redis数据安全，类似于mysql的binlog

#### 7.4.redis 备份和恢复

（1）dump.db备份
redis服务默认的自动备份方式（在AOF没有开启的情况下），在服务启动时，就会自动从dump.db文件中去加载数据
（2）手动备份
命令：
SAVE  保存是<font color='red'>阻塞主进程，客户端无法连接redis</font>，等SAVE完成后，主进程才开始工作，客户端可以连接 #key值多，不推荐使用
BGSAVE  是<font color='red'>开启一个save的子进程，在执行save过程中，不影响主进程，客户端可以正常连接redis</font>，等子进程执行save完成后，通知主进程，子进程关闭。

举例：
127.0.0.1:6379> set name lin
OK
127.0.0.1:6379> save
OK
127.0.0.1:6379> set name lin1
OK
127.0.0.1:6379> bgsave
Background saving started

#### 7.5.模拟恢复数据:

创建键值：
127.0.0.1:6379> config get dir
"dir"
"/data/redis"
127.0.0.1:6379> set key 001
OK
127.0.0.1:6379> set kdy1 002
OK
127.0.0.1:6379> set kdy2 003
OK
127.0.0.1:6379> save
OK
[root@redis1 ~]# ll /data/redis/dump.rdb 
-rw-r--r-- 1 root root 145 9月  16 03:27 /data/redis/dump.rdb
[root@redis1 ~]# cp /data/redis/dump.rdb /opt                       #删除数据前将备份文件复制到其他目录

删除键值：
127.0.0.1:6379> del key1
(integer) 0
127.0.0.1:6379> get key1
(nil)

关闭服务，将原备份文件复制回save备份目录
127.0.0.1:6379> shutdown 
not connected> exit
[root@redis1 ~]# cp /optdump.rdb  /data/redis
cp：是否覆盖"/data/redis/dump.rdb"？ y

验证：
127.0.0.1:6379> mget key key1 key2
1)"001"
2)"002"
3)"003"

### 8、redis事务

redis 事务可以一次执行多条命令，并且具备以下3个特征：

1.单独的隔离操作：事务中的所有命令都会序列化、按顺序地执行。事务在执行的过程中，不会被其他客户端发送来的命令请求所打断。

2.没有隔离级别的概念：队列中的命令没有提交之前都不会实际的被执行，因为事务提交前任何指令都不会被实际执行，也就不存在”事务内的查询要看到事务里的更新，在事务外查询不能看到”这个让人万分头痛的问题

3.不保证原子性：redis同一个事务中如果有一条命令执行失败，其后的命令仍然会被执行，没有回滚

一个事务都会经历以下3个阶段：
(1)事务开始阶段（命令：multi）
(2)命令执行阶段
(3)事务结束阶段（命令：exec）

举例：
127.0.0.1:6379> multi
OK
127.0.0.1:6379> set a 123
QUEUED
127.0.0.1:6379> get a
QUEUED
127.0.0.1:6379> rename a abc
QUEUED
127.0.0.1:6379> exec
1）OK
2）"123"
3）OK



### 9、redis管理命令

1.键值管理命令

dbsize：显示当前库key的数量

keys \*:查看当前库所有key值      #属于高危操作，尤其对于数据量大的库来说
keys n*:匹配查询key值
exists  key值:确认key是否存在
del  key值:删除key
expire 秒数:设置key过期时间     （过期后从key中移出）
pexpire 毫秒：设置key过期时间
ttl key值 :返回过期时间 （-1代表永久，-2代表过期了）
persist  key值:移除key过期时间的配置
rename 旧key值 新key值:重命名key
type key值:返回值的类型

2.服务管理命令
select  编号数: 选择数据库（数据库编号0~15）
quit  :退出连接     或ctrl+d
info:获得服务的信息与统计
<font color='red'>monitor:实时监控</font>
config get *:获得所有服务配置

### 10、redis的数据类型：

#### 1.string(字符串)

string是redis最基本的数据类型。它的一个键对应一个值 ，一个值最大存储是512MB

基础操作：
127.0.0.1:6379> set a1 123                 #设置键值，可以覆盖原有值
OK

127.0.0.1:6379> getset a2 456            #获取a2原有值，并设置新值456
(nil)                                                #这里显示的是a2原有值 
127.0.0.1:6379> get a2
"456"

127.0.0.1:6379> setex a3 10 789         #建立新值时设置值的过期时间 
OK
127.0.0.1:6379> get a3
"789"
127.0.0.1:6379> ttl a3
(integer) 2
127.0.0.1:6379> get a3
(nil)

127.0.0.1:6379> setnx a2 11             #若该键不存在，则设置新值
(integer) 0                                         若该键存在，则不设置新值
127.0.0.1:6379> get a2
"456"
127.0.0.1:6379> setnx a4 11
(integer) 1
127.0.0.1:6379> get a4
"11"

127.0.0.1:6379> mset a5 22 a6 33        #批量设置键值
OK
127.0.0.1:6379> mget a5 a6                 #批量查询键值
1."22"
2."33"

127.0.0.1:6379> msetnx  a6 33  a8 18 a9  19	#批量设置键值，检测该键存不存在，若存在的，所有键值都不设置
(integer) 0



127.0.0.1:6379> append a1 123456        #追加键值长度
(integer) 9                                            #若该键并不存在,创建该键值，并返回当前 Value 的长度
127.0.0.1:6379> get a1                             该键已经存在，返回追加后 Value的长度
"123123456"

127.0.0.1:6379> incr a7                         #增加键值，初始值设为0,增加后结果为1
(integer) 1
127.0.0.1:6379> get a7
"1"
127.0.0.1:6379> incr a7
(integer) 2
127.0.0.1:6379> incr a7
(integer) 3

127.0.0.1:6379> decr a7 
127.0.0.1:6379> decrby a7  2                 #减少键值
(integer) 1
127.0.0.1:6379> get a7
"1"

127.0.0.1:6379> setrange a1 4 abc       #从第5个键值，按新键值的长度替换，本质是从0开始算起
(integer) 9
127.0.0.1:6379> get a1
"1231abc56"

127.0.0.1:6379> strlen a1                   #获取指定键值长度
(integer) 9

127.0.0.1:6379> getrange a1 2 7         #获取第2到第7个字节,若7超过value长度,
"31abc5"                                                            则截取第2个和后面所有的

应用场景：微博平台发微博，关注微博数，直播平台刷礼物，订阅，关注粉丝数

#### 2.hash类型（字典类型）

hash是一个键值对的集合，最接近mysql表结构的一种类型，主要是可以做数据库缓存

127.0.0.1:6379> hset class id 1                             #若字段id不存在,创建该字段及与其关联的Hashes集合, 
(integer) 1                                                                        Hashes中,字段为id ,并设value为1 ，若存在会覆盖原value

127.0.0.1:6379> hsetnx class name zhangsan          若字段name不存在,创建该字段及与其关联的Hashes集合, 
(integer) 1                                                                        Hashes中,字段为name ,并设value为zhangsan， 若字段field1存在,则无效

127.0.0.1:6379> hget class id                               #获取hash集合,字段为id的值
"1"
127.0.0.1:6379> hget class name
"zhangsan"

127.0.0.1:6379> hmset class age 18 address foshan         #批量创建多个字段
OK
127.0.0.1:6379> hmget class id name age address            #批量查询多个字段 
\1) "1"
\2) "zhangsan"
\3) "18"
\4) "foshan"

127.0.0.1:6379> hlen class                              #查询hash集合的字段数量
(integer) 4

127.0.0.1:6379> hexists class name              #查询hash集合是否有name字段
(integer) 1

127.0.0.1:6379> hkeys class                             #列出hash集合所有字段名
\1) "id"
\2) "name"
\3) "age"
\4) "address"
127.0.0.1:6379> hvals class                         #列出hash集合所有值
\1) "3"
\2) "zhangsan"
\3) "18"
\4) "foshan"
127.0.0.1:6379> hgetall class                       #列出hash集合所有字段名与其值
\1) "id"
\2) "1"
\3) "name"
\4) "zhangsan"
\5) "age"
\6) "18"
\7) "address"
\8) "foshan"

127.0.0.1:6379> hdel class address              #删除 hash 集合中字段名为 address 的字段
(integer) 1
127.0.0.1:6379> hkeys class
\1) "id"
\2) "name"
\3) "age"

127.0.0.1:6379> del class                         #删除 hash 集合  
(integer) 1

应用场景：存储部分变更的数据，如用户信息，游戏账号，装备信息等。

#### 3.list（列表）

应用场景
消息队列系统
比如sina微博
在Redis中我们的最新微博ID使用了常驻缓存，这是一直更新的。
但是做了限制不能超过5000个ID，因此获取ID的函数会一直询问Redis。
只有在start/count参数超出了这个范围的时候，才需要去访问数据库。
系统不会像传统方式那样“刷新”缓存，Redis实例中的信息永远是一致的。
SQL数据库（或是硬盘上的其他类型数据库）只是在用户需要获取“很远”的数据时才会被触发，
而主页或第一个评论页是不会麻烦到硬盘上的数据库了。

127.0.0.1:6379> lpush word hi                        若键值world不存在,创建该键及与其关联的List元素， 若List类型的key存在,则插入元素中
(integer) 1
127.0.0.1:6379> lpush word hello world           #在链表首部先插入hello ,在插入world
(integer) 2
127.0.0.1:6379> lrange word 0 2                     #取链表中的全部元素，从头开始,取索引为0,1,2的元素
\1) "world"
\2) "hello"
\3) "hi"
127.0.0.1:6379> lrange word 0 -1                    #取链表中的全部元素，其中0表示第一个元素,-1表示最后一个元素。
\1) "world"
\2) "hello"
\3) "hi"

127.0.0.1:6379> llen word                               #返回列表key值的长度
(integer) 3

27.0.0.1:6379> rpush word ni hao                        #在链表尾部先插入hao,在插入ni
(integer) 5
127.0.0.1:6379> lrange word 0 5
\1) "world"
\2) "hello"
\3) "hi"
\4) "ni"
\5) "hao"

127.0.0.1:6379> rpushx word  hello                      #若键值word存在，则插入hello，若不存在，则无效（需验证）
(integer) 5

127.0.0.1:6379> linsert word before hi 123            #在 hi 的前面插入新元素 123       
(integer) 6
127.0.0.1:6379> lrange word 0 100
\1) "world"
\2) "hello"
\3) "123"
\4) "hi"
\5) "ni"
\6) "hao"

127.0.0.1:6379> linsert word after hi 456           #在 hi 的之后插入新元素 456
(integer) 7
127.0.0.1:6379> lrange word 0 100
\1) "world"
\2) "hello"
\3) "1"
\4) "hi"
\5) "456"
\6) "ni"
\7) "hao"

127.0.0.1:6379> lset word 1 e                   #从头开始, 将索引为1的元素值,设置为新值 e,若没有索引,则返回错误信息
OK
127.0.0.1:6379> lrange word 0 100
\1) "world"
\2) "e"
\3) "1"

（trim）
127.0.0.1:6379> ltrim word 0 6                              #从头开始,保留索引为0-6的7个元素,其余全部删除
OK
127.0.0.1:6379> lrange word 0 100
\1) "world"
\2) "e"
\3) "123"
\4) "hi"
\5) "456"
\6) "ni"
\7) "hao"



127.0.0.1:6379> lpush word 123
(integer) 8
127.0.0.1:6379> lpush word 123
(integer) 9
127.0.0.1:6379> LRANGE word 0 100
\1) "123"
\2) "123"
\3) "world"
\4) "e"
\5) "123"
\6) "hi"
\7) "456"
\8) "ni"
\9) "hao"
127.0.0.1:6379> lrem word 2 123                      #从头部开始找,按先后顺序,寻找值为123的元素,删除2个,若存在第3个,则不删除
127.0.0.1:6379> LRANGE word 0 100
\1) "world"
\2) "e"
\3) "123"
\4) "hi"
\5) "456"
\6) "ni"
\7) "hao"

127.0.0.1:6379> del word                    #删除list类型key
(integer) 1



#### 4.set（集合）

set是string类型的无序集合，不可以重复

案例：在微博应用中，可以将一个用户所有的关注人存在一个集合中，将其所有粉丝存在一个集合。
Redis还为集合提供了求交集、并集、差集等操作，可以非常方便的实现如共同关注、共同喜好、二度好友等功能，
对上面的所有集合操作，你还可以使用不同的命令选择将结果返回给客户端还是存集到一个新的集合中。

127.0.0.1:6379> sadd man d1 d2 d3 d4 d5           #添加元素d1 d2 d3 d4 d5到集合man里
(integer) 5
127.0.0.1:6379> sadd woman d1 d6 d7 d8 d9
(integer) 5

127.0.0.1:6379> scard man                              #获取man 集合中元素的数量 
(integer) 5

127.0.0.1:6379> smembers man                        #查看man集合中的内容
\1) "d2"
\2) "d4"
\3) "d3"
\4) "d1"
\5) "d5"

127.0.0.1:6379> sismember man d1                    #判断 d1 是否已经存在，返回值为 1 表示存在。
(integer) 1

127.0.0.1:6379> srandmember man                     #随机的返回集合里某一元素
"d2"
127.0.0.1:6379> srandmember man
"d4"
127.0.0.1:6379> srandmember man
"d1"



127.0.0.1:6379> sunion man  woman                     #获取2个集合中的成员的并集
\1) "d4"
\2) "d7"
\3) "d8"
\4) "d5"
\5) "d3"
\6) "d6"
\7) "d1"
\8) "d9"
\9) "d2"

127.0.0.1:6379> sinter man woman                #获取2个集合中的成员的交集
\1) "d1"

127.0.0.1:6379> sdiff man woman                 #1和2比较,获得1独有的值（以左算，第一个为主）
\1) "d2"
\2) "d3"
\3) "d4"
\4) "d5"

![file://c:\users\admini~1\appdata\local\temp\tmpsrptxj\6.png](https://s2.loli.net/2022/03/08/dLpgPqXIAZJ18rK.png)

127.0.0.1:6379> srem man d5                 #从集合man里删除元素d5
(integer) 1
127.0.0.1:6379>  smembers man
\1) "d2"
\2) "d4"
\3) "d3"
\4) "d1"

127.0.0.1:6379> smove man woman d4              #将d4从 man 移到 woman
(integer) 1
127.0.0.1:6379> smembers woman
\1) "d9"
\2) "d4"
\3) "d7"
\4) "d8"
\5) "d6"
\6) "d1"



127.0.0.1:6379> sadd person d10
(integer) 1
127.0.0.1:6379> sdiffstore person  man woman           #2个集man 和woman比较,获取独有的元素,并存入person集合中，覆盖原有值
(integer) 3

127.0.0.1:6379> sinterstore person man woman            #把交集存入person集合中
(integer) 1
127.0.0.1:6379> smembers person
\1) "d1"

127.0.0.1:6379> sunionstore person man woman            #把并集存入person集合中
(integer) 8
127.0.0.1:6379> smembers person
\1) "d2"
\2) "d9"
\3) "d4"
\4) "d8"
\5) "d7"
\6) "d6"
\7) "d3"
\8) "d1"



#### 5.zset （SortedSet，有序集合)

应用场景：
排行榜应用，取TOP N操作
这个需求与上面需求的不同之处在于，前面操作以时间为权重，这个是以某个条件为权重，比如按顶的次数排序，
每次只需要执行一条ZADD命令即可。

127.0.0.1:6379> zadd top 0 e1 0 e2 0 e3 0 e4            添加值为0，成员分别e1，e2，e3，e4的有序集合top
(integer) 4

127.0.0.1:6379> zcard top                                   #获取top键中成员的数量
(integer) 4

127.0.0.1:6379> zrange top  0 -1 withscores             #返回所有成员和值,不加WITHSCORES,只返回成员
\1) "e1"
\2) "0"
\3) "e2"
\4) "0"
\5) "e3"
\6) "0"
\7) "e4"
\8) "0"


127.0.0.1:6379> zrank top e1                               #获取成员e1在集合中的位置索引值。0表示第一个位置
(integer) 0
127.0.0.1:6379> zrank top e3
(integer) 2

127.0.0.1:6379> zincrby top 2 e3                        #将成员 e3 的值增加2，并返回该成员更新后的分数
"2"
127.0.0.1:6379> zrange top  0 -1 withscores
\1) "e1"
\2) "0"
\3) "e2"
\4) "0"
\5) "e4"
\6) "0"
\7) "e3"
\8) "2"

127.0.0.1:6379> zscore top e3                       #获取成员e3的值 
"3"

127.0.0.1:6379> zcount top  1 3                     #获取值满足表达式 1 <= score <= 3 的成员的数量
(integer) 1

127.0.0.1:6379> zrangebyscore top  1 3          ##获取值满足表达式 1 <= score <= 2 的成员
\1) "e3"


127.0.0.1:6379>zrem top e1  e2                 删除多个成员变量,返回删除的数量
(integer) 2

127.0.0.1:6379> zremrangebyrank top 0 1         #删除位置索引满足表达式 0 <= rank <= 1 的成员
(integer) 2

\#-inf 表示第一个成员，+inf最后一个成员
\#limit限制关键字
\#2  3  是索引号
127.0.0.1:6379> zrangebyscore top -inf +inf limit 1 3       #返回索引是1、2、3的成员
\1) "e3"

127.0.0.1:6379> zremrangebyscore top 1 2        #删除分数 1<= score <= 2 的成员，并返回实际删除的数量
(integer) 0


\#原始成员:位置索引从小到大 zrang的为原始索引
      one  0
      two  1
\#执行顺序:把索引反转 zrevrange 为修订版 
      位置索引:从大到小
      one 1
      two 0
\#输出结果: two
       one
127.0.0.1:6379> zrevrange top 1 3                   #获取位置索引,为1,2,3的成员
\1) "e4"                

\#相反的顺序:从高到低的顺序
127.0.0.1:6379> zrevrangebyscore top 3 0        #获取分数 3>=score>=0的成员并以相反的顺序输出
\1) "e3"
\2) "e4"            

127.0.0.1:6379> zrevrangebyscore top 4 0 limit 1 2              #获取索引是1和2的成员,并反转位置索引
\1) "e4"

127.0.0.1:6379> zrevrange top 0 -1 WITHSCORES           #按位置索引从高到低,获取所有成员和分数
\1) "e3"
\2) "3"
\3) "e4"
\4) "0"