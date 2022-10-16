分片集群原理：

​           ![file://c:\users\admini~1\appdata\local\temp\tmpabchky\1.png](https://s2.loli.net/2022/03/11/UIa4PSXDuqG5Zjf.png)

# MongoDB Sharding Cluster 分片集群

环境规划
10个实例：38017-38026
（1）router(mongos):     38017
（2）configserver:38018-38020     3台构成的复制集（1主两从，不支持arbiter）38018-38020（复制集名字configsvr）
（3）shard节点：
sh1：38021-23    （1主两从，其中一个节点为arbiter，复制集名字sh1）
sh2：38024-26    （1主两从，其中一个节点为arbiter，复制集名字sh2）

## Shard节点配置过程

目录创建：
[root@mongodb2 opt]# mkdir -p /mongodb/38021/conf  /mongodb/38021/log  /mongodb/38021/data
[root@mongodb2 opt]# mkdir -p /mongodb/38022/conf  /mongodb/38022/log  /mongodb/38022/data
[root@mongodb2 opt]# mkdir -p /mongodb/38023/conf  /mongodb/38023/log  /mongodb/38023/data

[root@mongodb3 opt]# mkdir -p /mongodb/38024/conf  /mongodb/38024/log  /mongodb/38024/data
[root@mongodb3 opt]# mkdir -p /mongodb/38025/conf  /mongodb/38025/log  /mongodb/38025/data
[root@mongodb3 opt]# mkdir -p /mongodb/38026/conf  /mongodb/38026/log  /mongodb/38026/data



复制主程序：
[root@mongodb2 opt]# cp -r bin /mongodb/
[root@mongodb3 opt]# cp -r bin /mongodb/



修改配置文件：
第一组复制集搭建：21-23（1主 1从 1Arb）

```yaml
cat >  /mongodb/38021/conf/mongodb.conf  <<EOF
systemLog:
  destination: file
  path: /mongodb/38021/log/mongodb.log   
  logAppend: true
storage:
  journal:
    enabled: true
  dbPath: /mongodb/38021/data
  directoryPerDB: true
  #engine: wiredTiger
  wiredTiger:
    engineConfig:
      cacheSizeGB: 1
      directoryForIndexes: true
    collectionConfig:
      blockCompressor: zlib
    indexConfig:
      prefixCompression: true
net:
  bindIp: 192.168.245.154,127.0.0.1
  port: 38021
replication:
  oplogSizeMB: 2048
  replSetName: sh1
sharding:   
  clusterRole: shardsvr
processManagement: 
  fork: true
EOF
```


\cp  /mongodb/38021/conf/mongodb.conf  /mongodb/38022/conf/
\cp  /mongodb/38021/conf/mongodb.conf  /mongodb/38023/conf/

sed 's#38021#38022#g' /mongodb/38022/conf/mongodb.conf -i
sed 's#38021#38023#g' /mongodb/38023/conf/mongodb.conf -i

第二组节点：24-26(1主1从1Arb)

```
cat > /mongodb/38024/conf/mongodb.conf <<EOF
systemLog:
  destination: file
  path: /mongodb/38024/log/mongodb.log   
  logAppend: true
storage:
  journal:
    enabled: true
  dbPath: /mongodb/38024/data
  directoryPerDB: true
  wiredTiger:
    engineConfig:
      cacheSizeGB: 1
      directoryForIndexes: true
    collectionConfig:
      blockCompressor: zlib
    indexConfig:
      prefixCompression: true
net:
  bindIp: 192.168.245.155,127.0.0.1
  port: 38024
replication:
  oplogSizeMB: 2048
  replSetName: sh2
sharding:
  clusterRole: shardsvr
processManagement: 
  fork: true
EOF
```



\cp  /mongodb/38024/conf/mongodb.conf  /mongodb/38025/conf/
\cp  /mongodb/38024/conf/mongodb.conf  /mongodb/38026/conf/
sed 's#38024#38025#g' /mongodb/38025/conf/mongodb.conf -i
sed 's#38024#38026#g' /mongodb/38026/conf/mongodb.conf -i

检查/mongod目录权限
[root@mongodb2 opt]# chown -R mongod:mongod /mongodb

分片集群的安装：
启动所有节点，并搭建复制集
/mongodb/bin/mongod -f  /mongodb/38021/conf/mongodb.conf 
/mongodb/bin/mongod -f  /mongodb/38022/conf/mongodb.conf 
/mongodb/bin/mongod -f  /mongodb/38023/conf/mongodb.conf 

/mongodb/bin/mongod -f  /mongodb/38024/conf/mongodb.conf 
/mongodb/bin/mongod -f  /mongodb/38025/conf/mongodb.conf 
/mongodb/bin/mongod -f  /mongodb/38026/conf/mongodb.conf  
ps -ef |grep mongod

[root@mongodb2 opt]# mongo --port 38021

```
use  admin
config = {_id: 'sh1', members: [
                          {_id: 0, host: '192.168.245.154:38021'},
                          {_id: 1, host: '192.168.245.154:38022'},
                          {_id: 2, host: '192.168.245.154:38023',"arbiterOnly":true}]
           }

rs.initiate(config)

 
```

[root@mongodb3 opt]# mongo --port 38024

```
use admin
config = {_id: 'sh2', members: [
                          {_id: 0, host: '192.168.245.155:38024'},
                          {_id: 1, host: '192.168.245.155:38025'},
                          {_id: 2, host: '192.168.245.155:38026',"arbiterOnly":true}]
           }

rs.initiate(config)
```



## config节点配置

目录创建
mkdir -p /mongodb/38018/conf  /mongodb/38018/log  /mongodb/38018/data
mkdir -p /mongodb/38019/conf  /mongodb/38019/log  /mongodb/38019/data
mkdir -p /mongodb/38020/conf  /mongodb/38020/log  /mongodb/38020/data
修改配置文件：

```
cat > /mongodb/38018/conf/mongodb.conf <<EOF
systemLog:
  destination: file
  path: /mongodb/38018/log/mongodb.conf
  logAppend: true
storage:
  journal:
    enabled: true
  dbPath: /mongodb/38018/data
  directoryPerDB: true
  #engine: wiredTiger
  wiredTiger:
    engineConfig:
      cacheSizeGB: 1
      directoryForIndexes: true
    collectionConfig:
      blockCompressor: zlib
    indexConfig:
      prefixCompression: true
net:
  bindIp: 192.168.245.153,127.0.0.1
  port: 38018
replication:
  oplogSizeMB: 2048
  replSetName: configReplSet
sharding:
  clusterRole: configsvr
processManagement: 
  fork: true
EOF
```



\cp /mongodb/38018/conf/mongodb.conf /mongodb/38019/conf/
\cp /mongodb/38018/conf/mongodb.conf /mongodb/38020/conf/
sed 's#38018#38019#g' /mongodb/38019/conf/mongodb.conf -i
sed 's#38018#38020#g' /mongodb/38020/conf/mongodb.conf -i

启动节点，并配置复制集

/mongodb/bin/mongod  -f /mongodb/38018/conf/mongodb.conf 
/mongodb/bin/mongod  -f /mongodb/38019/conf/mongodb.conf 
/mongodb/bin/mongod  -f /mongodb/38020/conf/mongodb.conf 

[root@mongodb1 mongodb]# mongo --port 38018

```
use  admin
 config = {_id: 'configReplSet', members: [
                          {_id: 0, host: '192.168.245.153:38018'},
                          {_id: 1, host: '192.168.245.153:38019'},
                          {_id: 2, host: '192.168.245.153:38020'}]
           }
rs.initiate(config)  
```

注：configserver 可以是一个节点，官方建议复制集。configserver不能有arbiter。
新版本中，要求必须是复制集。
注：mongodb 3.4之后，虽然要求config server为复制集，但是不支持arbiter

## mongos节点配置：

创建目录：
mkdir -p /mongodb/38017/conf  /mongodb/38017/log 
配置文件：

```
cat > /mongodb/38017/conf/mongos.conf <<EOF
systemLog:
  destination: file
  path: /mongodb/38017/log/mongos.log
  logAppend: true
net:
  bindIp: 192.168.245.153,127.0.0.1
  port: 38017
sharding:
  configDB: configReplSet/192.168.245.153:38018,192.168.245.153:38019,192.168.245.153:38020
processManagement: 
  fork: true
EOF
```



启动mongos
/mongodb/bin/mongos -f /mongodb/38017/conf/mongos.conf 

分片集群添加节点
 连接到其中一个mongos（10.0.0.51），做以下配置
（1）连接到mongs的admin数据库

su - mongod

[root@mongodb1 mongodb]# mongo --port 38017 admin 

（2）添加分片
db.runCommand( { addshard : "sh1/192.168.245.154:38021,192.168.245.154:38022,192.168.245.154:38023",name:"shard1"} )
db.runCommand( { addshard : "sh2/192.168.245.155:38024,192.168.245.155:38025,192.168.245.155:38026",name:"shard2"} )
（3）列出分片
mongos> db.runCommand( { listshards : 1 } )
（4）整体状态查看
mongos> sh.status();



## 分片配置及测试

### 集合分片

1.激活数据库分片功能
mongo --port 38017 admin
admin> db.runCommand({ enablesharding:"所操作的数据库名称"})

2.指定分片键对集合分片

创建索引
use test
test>db.vast.createIndex({id:1})

3.开启分片
use admin
admin> db.runCommand({shardcollection:"test.vast",key:{id:1}})

4.集合分片验证
admin>use test
test>for(i=1;i<=1000000;i++){db.vast.insert({"id":i,"name":"zhangsan","age":6,"date":new Date()});}
test>db.vast.stats()

5.分片结果测试
shard1:
[root@mongodb2 ~]# mongo --port 38021
db.vast.count();

shard2:
[root@mongodb2 ~]# mongo --port 38024
db.vast.count();

### Hash分库：

对today库下的vast表进行hash
创建索引
1.开启分片功能
mongo --port  38017 admin
use admin
admin> db.runCommand({ enablesharding:"today"})

2.对于today库下的vast表建立hash索引
admin>use today
today>db.a1.createIndex({id:"hashed"})
db.vast.dropIndex({id:"hashed"})                    #删除索引

3.开启分片
use admin
admin> db.runCommand({shardcollection:"today.a1",key:{id:"hashed"}})

4.集合分片验证
use today
for(i=1;i<1000000;i++){db.a1.insert({"id":i,"name":"lisi","age":18,"date":new Date()});}

5.分片结果测试

```
shard1:
[root@mongodb2 ~]# mongo --port 38021
sh1:PRIMARY> use today
switched to db today
sh1:PRIMARY> db.a1.count();
4993
```



```
shard2:
[root@mongodb3 ~]# mongo --port 38024
sh2:PRIMARY> use today
switched to db today
sh2:PRIMARY> db.a1.count();
5007
```



分片集群的查询及管理
 判断是否Shard集群
 admin> db.runCommand({ isdbgrid : 1})
 列出所有分片信息
 admin> db.runCommand({ listshards : 1})
列出开启分片的数据库
admin> use config
config> db.databases.find( { "partitioned": true } )
或者：
config> db.databases.find() //列出所有数据库分片情况

查看分片的片键
config> db.collections.find().pretty()
{
    "_id" : "test.vast",
    "lastmodEpoch" : ObjectId("58a599f19c898bbfb818b63c"),
    "lastmod" : ISODate("1970-02-19T17:02:47.296Z"),
    "dropped" : false,
    "key" : {
        "id" : 1
    },
    "unique" : false
}
查看分片的详细信息
admin> sh.status()
删除分片节点（谨慎）
（1）确认blance是否在工作
sh.getBalancerState()
（2）删除shard2节点(谨慎)
mongos> db.runCommand( { removeShard: "shard2" } )
注意：删除操作一定会立即触发blancer。



balancer操作 (针对于分片集群)
介绍
mongos的一个重要功能，自动巡查所有shard节点上的chunk的情况，自动做chunk迁移。
什么时候工作？
1、自动运行，会检测系统不繁忙的时候做迁移
2、在做节点删除的时候，立即开始迁移工作
3、balancer只能在预设定的时间窗口内运行

有需要时可以关闭和开启blancer（备份的时候）
mongos> sh.stopBalancer()
mongos> sh.startBalancer()

自定义 自动平衡进行的时间段
https://docs.mongodb.com/manual/tutorial/manage-sharded-cluster-balancer/#schedule-the-balancing-window

use config
sh.setBalancerState( true )
db.settings.update({ _id : "balancer" }, { $set : { activeWindow : { start : "3:00", stop : "5:00" } } }, true )

sh.getBalancerWindow()
sh.status()

关于集合的balancer（了解下）
关闭某个集合的balance
sh.disableBalancing("today.a1")
打开某个集合的balancer
sh.enableBalancing("today.a1")
确定某个集合的balance是开启或者关闭
db.getSiblingDB("config").collections.findOne({_id : "students.grades"}).noBalance;

### 备份恢复(5.0版本之后需要单独安装)

![image-20220914162117199](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202209141621312.png)



#### 备份恢复工具介绍：

（1）mongoexport/mongoimport
（2）mongodump/mongorestore
 备份工具区别在哪里？

####  应用场景总结:

1.mongoexport/mongoimport导出的格式：json，csv 
1).异构平台迁移  mysql  <---> mongodb
2).同平台，跨大版本：mongodb 5.0  ----> mongodb 6.0

2.mongodump/mongorestore
日常备份恢复时使用.

##### 导出工具mongoexport

mongoexport具体用法如下所示：
$ mongoexport --help  
参数说明：
-h:指明数据库宿主机的IP
-u:指明数据库的用户名
-p:指明数据库的密码
-d:指明数据库的名字
-c:指明collection的名字
-f:指明要导出那些列
-o:指明到要导出的文件名
-q:指明导出数据的过滤条件
--authenticationDatabase admin

1.单表备份至json格式
mongoexport -uroot -p123456 --port 38017 --authenticationDatabase admin -d today -c a1 -o /opt/a1.json
[mongod@mongodb1 bin]$ mongoexport  --port 38017  -d today -c a1 -o /mongodb/a1.json    #没有设置密码
注：备份文件的名字可以自定义，默认导出了JSON格式的数据。

2.单表备份至csv格式
如果我们需要导出CSV格式的数据，则需要使用--type=csv参数：
举例：
 mongoexport -uroot -p123456 --port 38017 --authenticationDatabase admin -d today -c a1 --type=csv -f uid,name,age,date  -o /mongodb/log.csv

 [mongod@mongodb1 bin]$ mongoexport --port 38017 -d today -c a1 --type=csv -f id,name,age  -o /mongodb/a1.csv

#####  导入工具mongoimport

$ mongoimport --help
参数说明：
-h:指明数据库宿主机的IP
-u:指明数据库的用户名
-p:指明数据库的密码
-d:指明数据库的名字
-c:指明collection的名字
-f:指明要导入那些列
-j, 同时运行的插入操作的数量（默认为1）。

数据恢复:
1.恢复json格式表数据到b1
举例：
mongoimport -uroot -p123456 --port 38017 --authenticationDatabase admin -d today -c b1 /mongodb/log.json

[mongod@mongodb1 bin]$ mongoimport  --port 38017  -d today -c b1 /mongodb/a1.json

2.恢复csv格式的文件到b2
如果要导入CSV格式文件中的内容，则需要通过--type参数指定导入格式，具体如下所示：
注意：
（1）csv格式的文件头行，有列名字
mongoimport   -uroot -proot123 --port 38017 --authenticationDatabase admin   -d today -c b2 --type=csv --headerline --file  /mongodb/log.csv
<font color='red'>--headerline:指明第一行是列名，不需要导入</font>

[mongod@mongodb1 bin]$ mongoimport    --port 38017   -d today -c b2 --type=csv --headerline --file  /mongodb/log.csv

（2）csv格式的文件头行，没有列名字
mongoimport   -uroot -proot123 --port 38017 --authenticationDatabase admin   -d today -c log3 --type=csv -f id,name,age,date --file  /mongodb/log.csv

[mongod@mongodb1 bin]$ mongoimport    --port 38017   -d today -c b2 --type=csv -f id,name,age --file  /mongodb/log.csv



##### 异构平台迁移案例

mysql   -----> mongodb  
today数据库下books表进行导出，导入到mongodb

（1）mysql开启安全路径
vim /etc/my.cnf   --->添加以下配置
secure-file-priv=/tmp

（2）重启数据库生效
systemctl restart mysqld

（3）导出mysql的books表数据
source /root/today.sql

select * from today.books into outfile '/tmp/books1.csv' fields terminated by ',';

（4）处理备份文件
mysql> desc test.salaries;
+-----------+---------+------+-----+---------+-------+
| Field     | Type    | Null | Key | Default | Extra |
+-----------+---------+------+-----+---------+-------+
| id        | int(11) | NO   |     | NULL    |       |
| emp_no    | int(11) | NO   |     | NULL    |       |
| salary    | int(11) | NO   |     | NULL    |       |
| from_date | date    | NO   |     | NULL    |       |
| to_date   | date    | NO   |     | NULL    |       |
+-----------+---------+------+-----+---------+-------+
5 rows in set (0.00 sec)


vim /tmp/books.csv   ----> 添加第一行列名信息

id,emp_no,salary,from_date,to_date

(4)在mongodb中导入备份
mongoimport -uroot -proot123 --port 38017 --authenticationDatabase admin -d today  -c books --type=csv -f ID,Name,CountryCode,District,Population --file  /tmp/books1.csv

mongoimport  --port 38017  -d today  -c b2 --type=csv -f id,emp_no,salary,from_date,to_date --file  /tmp/books1.csv

use today
db.books.find({CountryCode:"CHN"});

-------------
today共100张表，全部迁移到mongodb

select table_name ,group_concat(column_name) from columns where table_schema='today' group by table_name;

select * from today.books into outfile '/tmp/today_books.csv' fields terminated by ',';

select concat("select * from ",table_schema,".",table_name ," into outfile '/tmp/",table_schema,"_",table_name,".csv' fields terminated by ',';")
from information_schema.tables where table_schema ='today';

导入：
提示，使用infomation_schema.columns + information_schema.tables

mysql导出csv：
select * from test_info   
into outfile '/tmp/test.csv'   
fields terminated by ','　　　 ------字段间以,号分隔
optionally enclosed by '"'　　 ------字段用"号括起
escaped by '"'   　　　　　　  ------字段中使用的转义符为"
lines terminated by '\r\n';　　------行以\r\n结束

mysql导入csv：
load data infile '/tmp/test.csv'   
into table test_info    
fields terminated by ','  
optionally enclosed by '"' 
escaped by '"'   
lines terminated by '\r\n'; 



##### mongodump和mongorestore

原理：
mongodump能够在Mongodb运行时进行备份，它的工作原理是对运行的Mongodb做查询，然后将所有查到的文档写入磁盘。
但是存在的问题时使用mongodump产生的备份不一定是数据库的实时快照，如果我们在备份时对数据库进行了写入操作，
则备份出来的文件可能不完全和Mongodb实时数据相等。另外在备份时可能会对其它客户端性能产生不利的影响。
mongodump用法如下：
$ mongodump --help
参数说明：
-h:指明数据库宿主机的IP
-u:指明数据库的用户名
-p:指明数据库的密码
-d:指明数据库的名字
-c:指明collection的名字
-o:指明到要导出的文件名
-q:指明导出数据的过滤条件
-j, --numParallelCollections=  number of collections to dump in parallel (4 by default)
--oplog  备份的同时备份oplog
mongodump和mongorestore基本使用
全库备份
mkdir /mongodb/backup
mongodump  -uroot -proot123 --port 38017 --authenticationDatabase admin -o /mongodb/backup
备份today库
$ mongodump   -uroot -proot123 --port 38017 --authenticationDatabase admin -d today -o /mongodb/backup/

备份today库下的log集合
$ mongodump   -uroot -proot123 --port 38017 --authenticationDatabase admin -d today -c log -o /mongodb/backup/
压缩备份
$ mongodump   -uroot -proot123 --port 38017 --authenticationDatabase admin -d oldlao -o /mongodb/backup/ --gzip
 mongodump   -uroot -proot123 --port 38017 --authenticationDatabase admin -o /mongodb/backup/ --gzip
$ mongodump   -uroot -proot123 --port 38017 --authenticationDatabase admin -d app -c vast -o /mongodb/backup/ --gzip
恢复today库
$ mongorestore   -uroot -proot123 --port 38017 --authenticationDatabase admin -d today1  /mongodb/backup/today
恢复oldlao库下的t1集合
[mongod@db03 today]$ mongorestore   -uroot -proot123 --port 38017 --authenticationDatabase admin -d today -c t1  --gzip  /mongodb/backup.bak/today/b1.bson.gz 
drop表示恢复的时候把之前的集合drop掉(危险)
$ mongorestore  -uroot -proot123 --port 38017 --authenticationDatabase admin -d today --drop  /mongodb/backup/today