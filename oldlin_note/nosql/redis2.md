## 							     redis主从、哨兵、集群模式搭建与管理

### 1、redis主从搭建（Master-Replicaset） 原理

1.副本库通过slaveof  IP 6379命令,连接主库,并发送SYNC给主库 

2.主库收到SYNC,会立即触发BGSAVE,后台保存RDB,发送给副本库

3.副本库接收后会应用RDB快照

4.主库会陆续将中间产生的新的操作,保存并发送给副本库

5.到此,我们主复制集就正常工作了

6.再此以后,主库只要发生新的操作,都会以命令传播的形式自动发送给副本库.

7.所有复制相关信息,从info信息中都可以查到.即使重启任何节点,他的主从关系依然都在.

8.如果发生主从关系断开时,从库数据没有任何损坏,在下次重连之后,从库发送PSYNC给主库

9.主库只会将<font color='red'>从库缺失部分的数据</font>同步给从库应用,达到快速恢复主从的目的

1.2.主从数据一致性保证
min-slaves-to-write 1
min-slaves-max-lag  3

1.3.主库是否要开启持久化？
如果不开有可能，主库重启操作，造成所有主从数据丢失！

### 1.4. 主从复制实现

#### 单机环境：

1.4.1、准备两个或两个以上redis实例

mkdir /data/638{0..2}

配置文件示例：
cat >> /data/6380/redis.conf <<EOF
port 6380
daemonize yes
pidfile /data/6380/redis.pid
loglevel notice
logfile "/data/6380/redis.log"
dbfilename dump.rdb
dir /data/6380
requirepass 123456
masterauth 123456
EOF

cat >>   /data/6381/redis.conf <<EOF
port 6381
daemonize yes
pidfile /data/6381/redis.pid
loglevel notice
logfile "/data/6381/redis.log"
dbfilename dump.rdb
dir /data/6381
requirepass 123456
masterauth 123456
EOF

cat >>   /data/6382/redis.conf <<EOF
port 6382
daemonize yes
pidfile /data/6382/redis.pid
loglevel notice
logfile "/data/6382/redis.log"
dbfilename dump.rdb
dir /data/6382
requirepass 123456
masterauth 123456
EOF

启动：
redis-server /data/6380/redis.conf
redis-server /data/6381/redis.conf
redis-server /data/6382/redis.conf

主节点：6380
从节点：6381、6382

1.4.2、开启主从：
6381/6382命令行:

redis-cli -p 6381 -a 123456 SLAVEOF 127.0.0.1 6380   #redis 一样支持在命令行执行命令
redis-cli -p 6382 -a 123456 SLAVEOF 127.0.0.1 6380

解除：redis-cli -p 6381 -a 123456 SLAVEOF no one

1.4.3、查询主从状态
 redis-cli -p 6380 -a 123456 info replication
 redis-cli -p 6381 -a 123456 info replication
 redis-cli -p 6382 -a 123456 info replication



#### 多机环境 

配置文件修改：
vim /usr/local/redis/conf/redis.conf 
<font color='red'>bind 本机IP</font> 
daemonize yes
pidfile /var/run/redis_6379.pid
loglevel notice
logfile "/usr/local/redis/log/redis.log"
dbfilename dump.rdb
dir /data/redis
requirepass 123456
masterauth 123456

启动：

略

开启主从：

在从机上执行如下命令：

redis-cli -a 123456 <font color='red'>-h  本机IP</font> slaveof   主机IP 主机端口		#因为是多机环境，端口可以用6379

解除：redis-cli  -a 123456 -h 本机IP    slave no one

查询主从状态

redis-cli -a 123456 -h  本机IP info replication



###  2、哨兵（sentinel搭建过程）

生成配置文件：
cat>> /data/26380/sentinel.conf<<EOF
port 26380
daemonize yes
pidfile /data/26380/redis-sentinel.pid
logfile "/data/26380/redis-sentinel.log"
dir "/data/26380"
sentinel monitor today 127.0.0.1 6380 1   (1代指有几台哨兵选主机制)   
sentinel down-after-milliseconds today 3000         (3000为毫秒，这选项为每3秒检测主机是否宕机)
sentinel auth-pass today 123456 (主从密码要一致)
EOF

启动：
[root@db01 26380]# redis-sentinel /data/26380/sentinel.conf  

如果有问题：
1、重新准备1主2从环境
2、kill掉sentinel进程
3、删除sentinel目录下的所有文件
4、重新搭建sentinel


停主库测试：

[root@db01 ~]# redis-cli -p 6380 -a 123465 shutdown
[root@db01 ~]# redis-cli -p 6381 -a 123456 info replication


启动源主库（6380），看状态。

Sentinel管理命令：
redis-cli -p 26380
PING ：返回 PONG 。
SENTINEL masters ：列出所有被监视的主服务器
SENTINEL slaves <集群名> 

SENTINEL get-master-addr-by-name <集群名> ： 返回给定名字的主服务器的 IP 地址和端口号。 
SENTINEL reset <pattern> ： 重置所有名字和给定模式 pattern 相匹配的主服务器。    #生产环境上不能随便重置
SENTINEL failover <集群名> ： 当主服务器失效时， 在不询问其他 Sentinel 意见的情况下， 强制开始一次自动故障迁移。

### 3、redis cluster(集群)

高性能
1、在多分片节点中，将<font color='red'>16384</font>个槽位，均匀分布到多个分片节点中
2、存数据时，将key做crc16(key)算法解析,然后对16384进行取模，得出槽位值（0-16383之间）
3、根据计算得出的槽位值，找到相对应的分片节点的主节点，存储到相应槽位上
4、如果客户端当时连接的节点不是将来要存储的分片节点，分片集群会将客户端连接切换至真正存储节点进行数据存储

高可用：
在搭建集群时，会为每一个分片的主节点，对应一个从节点，实现slaveof的功能，同时当主节点down，实现类似于sentinel的自动failover的功能。

1、redis会有多组分片构成（3组）
2、redis cluster 使用固定个数的slot存储数据（一共16384slot）
3、每组分片分得1/3 slot个数（0-5500  5501-11000  11001-16383）
4、基于CRC16(key) % 16384 ====》值 （槽位号）。

4、规划、搭建过程：
6个redis实例，一般会放到3台硬件服务器
注：在企业规划中，一个分片的两个分到不同的物理机，防止硬件主机宕机造成的整个分片数据丢失。



redis集群搭建，5.0以上版本，5.0以下需要安装ruby。（未开启哨兵模式）
1。准备6个redis节点，每2个节点在一台服务器，并安装redis：（因为redis集群为去中心化设计，至少得3个节点，6个实例，3主3从，保证投票可用主。）
复制redis主程序到节点上：
scp -r redis/ root@192.168.245.151:/usr/local/
scp -r redis/ root@192.168.245.152:/usr/local/

创建集群配置以及数据目录：
redis1:
mkdir -p /data/redis_cluster/9000
mkdir -p /data/redis_cluster/9001

redis2:
mkdir -p /data/redis_cluster/9002
mkdir -p /data/redis_cluster/9003

redis3:
mkdir -p /data/redis_cluster/9004
mkdir -p /data/redis_cluster/9005

根据目录修改相应的配置：
举例模板为：
port 9000                #端口9000,9002,9004 
bind 本机ip             #默认ip为127.0.0.1 需要改为其他节点机器可访问的ip 否则创建集群时无法访问对应的端口，无法创建集群 
daemonize yes        #redis后台运行 
protected-mode no           #关闭保护模式
pidfile /data/redis_cluster/redis_9000.pid       #pidfile文件对应9000,9002,9004 
logfile /data/redis_cluster/redis_9000.log       # pidfile文件对应9000,9002,9004
cluster-enabled yes              #开启集群 把注释#去掉 
cluster-config-file nodes_9000.conf             #集群的配置 配置文件首次启动自动生成 9000,9002,9004 把注释#去掉 
cluster-node-timeout 15000                   #请求超时 默认15秒，可自行设置  把注释#去掉 
dir /data/redis_cluster/9000              #持久化日志存放地
appendonly yes                            #aof日志开启 有需要就开启，它会每次写操作都记录一条日志　

sed -i "s/port 6379/port 9000/" /data/redis_cluster/9002/redis.conf
sed -i "s/bind 127.0.0.1/bind 192.168.78.66 ::9000/" /data/redis_cluster/9002/redis.conf
sed -i "s/daemonize no/daemonize yes/" /data/redis_cluster/9002/redis.conf
sed -i "s/protected-mode yes/protected-mode no/" /data/redis_cluster/9002/redis.conf
sed -i "s#pidfile /var/run/redis_6379.pid#pidfile /data/redis_cluster/redis_9000.pid#" /data/redis_cluster/9002/redis.conf
sed -i "s#logfile /usr/local/redis/log/redis.log#logfile /data/redis_cluster/redis_9000.log #" /data/redis_cluster/9002/redis.conf
sed -i "s/# cluster-enabled yes/cluster-enabled yes#" /data/redis_cluster/9002/redis.conf
sed -i "s/# cluster-config-file nodes-6379.conf/cluster-config-file nodes-9000.conf #" /data/redis_cluster/9002/redis.conf
sed -i "s/# cluster-node-timeout 15000/cluster-node-timeout 15000/" /data/redis_cluster/9002/redis.conf
sed -i "s/appendonly no /appendonly yes /" /data/redis_cluster/9002/redis.conf
sed -i "s#dir /data/redis#dir /data/redis_cluster/9000#" /data/redis_cluster/9002/redis.conf
sed -i "s/requirepass 123456/#requirepass 123456/" /data/redis_cluster/9002/redis.conf	

#不修改密码会导致切换节点需要密码验证

在集群总目录下生成各个节点的配置
将按上述要求的模版修改的的redis.conf文件拷贝到以上各个目录中：
redis1:
cp redis.conf /data/redis_cluster/9000/
cp redis.conf /data/redis_cluster/9001/

redis2:
cp redis.conf /data/redis_cluster/9002/
cp redis.conf /data/redis_cluster/9003/

redis3:
cp redis.conf /data/redis_cluster/9004/
cp redis.conf /data/redis_cluster/9005/
（以上可以更改一个文件其余使用该文件修改端口即可）

修改端口：
redis1:
sed -i 's/9000/9001/g' /data/redis_cluster/9001/redis.conf

redis2:
sed -i 's/9000/9002/g' /data/redis_cluster/9002/redis.conf
sed -i 's/9000/9003/g' /data/redis_cluster/9003/redis.conf

redis3:
sed -i 's/9000/9004/g' /data/redis_cluster/9004/redis.conf
sed -i 's/9000/9005/g' /data/redis_cluster/9005/redis.conf

启动相关服务：
redis1:
redis-server /data/redis_cluster/9000/redis.conf
redis-server /data/redis_cluster/9001/redis.conf 

redis2: 
redis-server /data/redis_cluster/9002/redis.conf
redis-server /data/redis_cluster/9003/redis.conf 

redis3:
redis-server /data/redis_cluster/9004/redis.conf
redis-server /data/redis_cluster/9005/redis.conf 
检查服务：  
ps -ef | grep redis
netstat -anptl | grep redis

创建集群
原命令 redis-trib.rb 这个工具目前已经废弃，使用redis-cli (5.0之前版本使用redis-trib.rb)
[root@redis1 ~]#redis-cli --cluster create --cluster-replicas 1 192.168.245.150:9000 192.168.245.150:9001 192.168.245.151:9002 192.168.245.151:9003 192.168.245.152:9004 192.168.245.152:9005 
注： --cluster-replicas 1         #此参数表明主从复制按1：1配置

然后输入：yes确定等集群创建
出现如下字样表示集群创建成功：
[OK] All nodes agree about slots configuration.
\>>> Check for open slots...
\>>> Check slots coverage...
[OK] All 16384 slots covered

验证集群：
redis-cli -c -h 192.168.245.151 -p 9000（<font color='red'>注意-c选项启用集群链接。</font>）
cluster info
cluster nodes
显示集群信息，正常输出则集群成功。

 测试：

1.检验读写转换

192.168.245.150:9000> get name
-> Redirected to slot [5798] located at 192.168.245.152:9005
(nil)
192.168.245.152:9005> set name 123
OK
192.168.245.152:9005> get name
"123"
192.168.245.152:9005> get name1
-> Redirected to slot [12933] located at 192.168.245.150:9001
(nil)
192.168.245.150:9001> set name1 456
OK
192.168.245.150:9001> get name
-> Redirected to slot [5798] located at 192.168.245.152:9005
"123"



2.模拟主节点故障
[root@redis3 ~]# ps -ef |grep redis
root        819      1  0 09:06 ?        00:00:00 /sbin/dhclient -1 -q -lf /var/lib/dhclient/dhclient-e687996b-8045-48c2-a36c-eecb73174480-ens33.lease -pf /var/run/dhclient-ens33.pid -H redis3 ens33
root        974      1  0 09:08 ?        00:00:00 redis-server 192.168.245.152:9004 [cluster]
root        980      1  0 09:09 ?        00:00:00 redis-server 192.168.245.152:9005 [cluster]
[root@redis3 ~]# kill 974       #杀死其中一个主节点
[root@redis1 ~]# redis-cli -c -h 192.168.245.150 -p 9000
192.168.245.150:9000> cluster nodes
c5e81c7aee5eae0efe626025be696681e5dc7856 192.168.245.152:9005@19005 slave fa354c1e71b4439ee398f277868e59e087f62f07 0 1646874842317 9 connected
70d3d7d3c0294139ebb3726f3a3ff86b6dd96cc3 192.168.245.150:9000@19000 myself,master - 0 1646874840000 1 connected 1365-5460
0fbae08bc01dfe52aba798f6965682d7e86a0a5d 192.168.245.152:9004@<font color='red'>19004 master,fail</font> 0601272c5ab7acd9709e5fc863383451fa31869c 0 1646874843324 12 connected
d410574dd27bfa3a8b605649f759117b3e33005a 192.168.245.151:9003@19003 slave 70d3d7d3c0294139ebb3726f3a3ff86b6dd96cc3 0 1646874841311 4 connected
0601272c5ab7acd9709e5fc863383451fa31869c 192.168.245.150:9001@19001 master - 0 1646874842000 12 connected 0-999 6461-6826 10923-16383
fa354c1e71b4439ee398f277868e59e087f62f07 192.168.245.151:9002@19002 master - 0 1646874841000 9 connected 1000-1364 5461-6460 6827-10922
[root@redis3 ~]# redis-server /data/redis_cluster/9004/redis.conf       #重新拉起后
192.168.245.150:9000> cluster nodes
c5e81c7aee5eae0efe626025be696681e5dc7856 192.168.245.152:9005@19005 slave fa354c1e71b4439ee398f277868e59e087f62f07 0 1646874842317 9 connected
70d3d7d3c0294139ebb3726f3a3ff86b6dd96cc3 192.168.245.150:9000@19000 myself,master - 0 1646874840000 1 connected 1365-5460
0fbae08bc01dfe52aba798f6965682d7e86a0a5d 192.168.245.152:9004@<font color='red'>19004 slave </font>0601272c5ab7acd9709e5fc863383451fa31869c 0 1646874843324 12 connected
d410574dd27bfa3a8b605649f759117b3e33005a 192.168.245.151:9003@19003 slave 70d3d7d3c0294139ebb3726f3a3ff86b6dd96cc3 0 1646874841311 4 connected
0601272c5ab7acd9709e5fc863383451fa31869c 192.168.245.150:9001@19001 master - 0 1646874842000 12 connected 0-999 6461-6826 10923-16383
fa354c1e71b4439ee398f277868e59e087f62f07 192.168.245.151:9002@19002 master - 0 1646874841000 9 connected 1000-1364 5461-6460 6827-10922

添加主节点：
redis-cli --cluster add-node 127.0.0.1:9006 127.0.0.1:9000
转移slot（重新分片)
redis-cli --cluster reshard 127.0.0.1:9000
进入分片界面：
计算：
16384/节点数 计算每个节点上应有的槽点数
1.在交互界面填入该值。
2.接受槽点
2.选择all 意思为新节点的槽点来自其他所有节点。
3.是否接受分配：yes



![](https://s2.loli.net/2022/03/09/LOZcvWYICUFtbj8.png)





添加一个从节点
redis-cli --cluster add-node --cluster-slave --cluster-master-id 节点uuid 127.0.0.1:9007 127.0.0.1:9000

删除节点

将需要删除节点slot移动走
redis-cli --cluster reshard 127.0.0.1:9000
127.0.0.1:9006
0-1364 5461-6826 10923-12287
1365      1366     1365
删除一个节点
删除master节点之前首先要使用reshard移除master的全部slot,然后再删除当前节点
redis-cli --cluster del-node 127.0.0.1:9006 节点uuid





一些概念

### 缓存穿透

概念
访问一个不存在的key，缓存不起作用，请求会穿透到DB，流量大时DB会挂掉。
       
解决方案
采用布隆过滤器（插件），使用一个足够大的bitmap，用于存储可能访问的key，不存在的key直接被过滤；
访问key未在DB查询到值，也将空值写进缓存，但可以设置较短过期时间。

### 缓存雪崩

概念
大量的key设置了相同的过期时间，导致在缓存在同一时刻全部失效，造成瞬时DB请求量大、压力骤增，引起雪崩。

解决方案
1.可以给缓存设置过期时间时加上一个随机值时间，使得每个key的过期时间分布开来，不会集中在同一时刻失效。

2.Redis 故障宕机也可能引起缓存雪崩。这就需要构造Redis高可用集群

### 缓存击穿

概念
一个存在的key，在缓存过期的一刻，同时有大量的请求，这些请求都会击穿到DB，造成瞬时DB请求量大、压力骤增。
解决方案
在访问key之前，采用SETNX（set if not exists）来设置另一个短期key来锁住当前key的访问，访问结束再删除该短期key。

https://www.cnblogs.com/javalanguage/p/12401829.html

https://blog.csdn.net/weixin_40205234/article/details/124614720