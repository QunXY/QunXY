## 介绍：

MongoDB 是一个基于分布式文件存储的数据库。由 C++ 语言编写。旨在为 WEB 应用提供可扩展的高性能数据存储解决方案。
MongoDB 是一个介于关系数据库和非关系数据库之间的产品，是非关系数据库当中功能最丰富，最像关系数据库的

## 1.安装：

### 一，yum安装：

1.配置MongoDB的yum源

创建yum源文件：
vim 
添加以下内容：
cat >/etc/yum.repos.d/mongodb-org-4.2.repo<<EOF
[mongodb-org-4.2]
name=MongoDB Repository
baseurl=https://mirrors.tuna.tsinghua.edu.cn/mongodb/yum/el7-4.2/
gpgcheck=0
enabled=1
EOF
这里可以修改 gpgcheck=0, 省去gpg验证

安装命令：
yum -y install mongodb-org

### 二、二进制安装MongoDB

root用户下
在vi /etc/rc.local最后添加如下代码
if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
  echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
   echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi
        
cat  /sys/kernel/mm/transparent_hugepage/enabled        
cat /sys/kernel/mm/transparent_hugepage/defrag  
其他系统关闭参照官方文档：   

https://docs.mongodb.com/manual/tutorial/transparent-huge-pages/

为什么要关闭？
Transparent Huge Pages (THP) is a Linux memory management system 
that reduces the overhead of Translation Lookaside Buffer (TLB) 
lookups on machines with large amounts of memory by using larger memory pages.
However, database workloads often perform poorly with THP, 
because they tend to have sparse rather than contiguous memory access patterns. 
You should disable THP on Linux machines to ensure best performance with MongoDB.
############################################################################    

#### 2.1.创建所需用户和组

useradd mongod		注：企业一般会单独使用mongod用户去运行mongodb
passwd mongod

#### 2.2.创建mongodb所需目录结构

mkdir -p /mongodb/conf
mkdir -p /mongodb/log
mkdir -p /mongodb/data

#### 2.3.上传并解压软件到指定位置

[root@mongodb1 data]# cd   /data
[root@mongodb1 data]# tar xf mongodb-linux-x86_64-rhel70-3.6.12.tgz 
[root@mongodb1 data]#  cp -r /data/mongodb-linux-x86_64-rhel70-3.6.12/bin/ /mongodb

#### 2.4.设置目录结构权限

chown -R mongod:mongod /mongodb

#### 2.5.设置用户环境变量

vim /etc/profile
export PATH=/mongodb/bin:$PATH
source /etc/profile

#### 2.6.编写配置文件：

cat >  /mongodb/conf/mongo.conf <<EOF
systemLog:
   destination: file
   path: "/mongodb/log/mongodb.log"
   logAppend: true
storage:
   journal:
      enabled: true
   dbPath: "/mongodb/data/"
processManagement:
   fork: true
net:
   port: 38017
   bindIp: 127.0.0.1
EOF

#### 2.7.启动mongodb

方法1：（没有配置文件也可以启动）

mongod --dbpath=/mongodb/data --logpath=/mongodb/log/mongodb.log --port=38017 --logappend --fork 

方法2：（指定配置文件也可以启动）
mongod -f /mongodb/conf/mongo.conf   
mongod --config /mongodb/conf/mongo.conf



#### 2.8.关闭mongodb

mongod -f /mongodb/conf/mongo.conf --shutdown



#### 2.9.使用systemd管理mongodb 

[root@mongodb1 ~]# cat > /etc/systemd/system/mongod.service <<EOF
[Unit]
Description=mongodb 
After=network.target remote-fs.target nss-lookup.target
[Service]
User=mongod
Type=forking
ExecStart=/mongodb/bin/mongod --config /mongodb/conf/mongo.conf
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/mongodb/bin/mongod --config /mongodb/conf/mongo.conf --shutdown
PrivateTmp=true  
[Install]
WantedBy=multi-user.target
EOF



#### 2.10.登录mongodb

[mongod@mongodb1~]$ mongo      #这样登录默认端口27017

[mongod@mongodb1~]$ mongo    --port 38017 	#指定端口登录





## 3.mongodb常用基本操作

mongodb 默认存在的库
test:登录时默认存在的库

管理MongoDB有关的系统库
admin库:系统预留库,MongoDB系统管理库
local库:本地预留库,存储关键日志
config库:MongoDB配置信息库

show databases/<font color='red'>show dbs</font>  查看数据库
<font color='red'>show tables</font>/show collections 查看数据合集
use admin     到某库或者创建某库
<font color='red'>db</font>/db.getName() 查看所在库

命令种类
db 对象相关命令
db.[TAB][TAB]
db.help()
db.today.[TAB][TAB]
db.today.help()
rs 复制集有关(replication set):
rs.[TAB][TAB]
rs.help()
sh 分片集群(sharding cluster)
sh.[TAB][TAB]
sh.help()

mongodb对象操作
mongo         mysql
库    ----->  库
集合  ----->  表
文档  ----->  数据行

库的操作

use test
db.dropDatabase()   
{ "dropped" : "test", "ok" : 1 }

集合的操作
 app> db.createCollection('a')
{ "ok" : 1 }
app> db.createCollection('b')

创建数据库：
方法1：use 数据库名 即可
方法2：当插入一个文档的时候，一个集合就会自动创建。

use today
db.test.insert({name:"zhangsan"})
db.stu.insert({id:101,name:"zhangsan",age:20,gender:"m"})
show tables;
db.stu.insert({id:102,name:"lisi"})
db.stu.insert({a:"b",c:"d"})
db.stu.insert({a:1,c:2})



## 4.Mongodb CRUD操作



文档操作
数据录入：
for(i=0;i<10000;i++){db.log.insert({"uid":i,"name":"mongodb","age":6,"date":new
Date()})}



查询数据行数：
db.log.count()

全表查询：（默认20条数据）
db.log.find()

每页显示50条记录：
DBQuery.shellBatchSize=50;

按照条件查询
db.log.find({uid:999})



查询uid大于50的数据

db.log.find({uid:{'$gt':50}}).pretty()



以标准的json格式显示数据
db.log.find({uid:999}).pretty()
{
"_id" : ObjectId("5cc516e60d13144c89dead33"),
"uid" : 999,
"name" : "mongodb",
"age" : 6,
"date" : ISODate("2019-04-28T02:58:46.109Z")
}



删除集合中所有记录
> db.log.remove({})
> 查看集合存储信息
> db.log.totalSize() //集合中索引+数据压缩存储之后的大小



http://www.viiis.cn/news/show_108786.html



### 4.1、插入数据

• MongoDB提供了将文档插入到集合中的以下方法：

• db.collection.insertOne()

 将单个文档插入到集合中。

• db.collection.insertMany()

 将多个 文档插入到集合中。

• db.collection.insert()

 将单个文档或多个文档插入到集合中。

• db.collection.save()根据文档参数更新现有文档或插入新文档



### 4.2、查询数据

db.collection.find**（** query **，** projection **）**

选择集合或视图中的文档，并将光标返回 到所选文档

参数query类型是文件，可选的。用查询运算符指定选择过滤器要返回集合中的所有文档请忽略此参数或传递一个空的文档

参数projection类型是文件，可选的。指定在与查询过滤器匹配的文档中返回的字段。要返回匹配文档中的所有字段，

**返回：**一个光标匹配的文件query 标准。当find()方法“返回文档”时，该方法实际上将光标返回到文档。



•$or 或的关系，$in 匹配多个件键

虽然可以使用$or运算符来表达下面查询，但在同一字段上执行相等检查时，请使用$in运算符

而不是$or运算符。

db.inventory.find( { status: { $in: [ “A”, “D” ] } } ) 等同于SQL SELECT * FROM inventory WHERE status in (“A”, “D”)

使用$or需要： db.inventory.find({ $or: [ { "status" : "A" }, { "status": "D" }]})



•复合查询可以指定集合文档中多个字段的条件。AND连接连接复合查询的子句，以便查询选

择集合中符合所有条件的文档。$lt <、$lte <=、 $gt >、$gte >= 可以将其组合起来查找一个范围的值



例1：查询集合中status 等于 “A” 或 qty 小于30:

db.inventory.find( { status: “A”, qty: { $lt: 30 } } )等同于SQL SELECT * FROM inventory WHERE  status = “A” AND qty < 30



例2：复合查询文档选择集合中的所有文档，其中在所有文档status值为“A” **和** qty小于（$lt）30 *或* item从P字符开始。

db.inventory.find( {

 status: "A",

 $or: [ { qty: { $lt: 30 } }, { item: /^p/ } ]

} )

等同于sql SELECT * FROM inventory WHERE status = "A" AND ( qty < 30 OR item LIKE "p%")Mongodb CRUD



• 比较运算符

$eq 匹配等于指定值的值。

$gt 匹配大于指定值的值。

$gte 匹配大于或等于指定值的值。

$in 匹配数组中指定的任何值。

$lt 匹配小于指定值的值。

$lte 匹配小于或等于指定值的值。

$ne 匹配不等于指定值的所有值。

$nin不匹配数组中指定的值。

• 逻辑查询运算符

$and 使用逻辑连接查询子句AND返回与两个子句的条件相匹配的所有文档。

$not 反转查询表达式的效果，并返回与查询表达式*不*匹配的文档。

$nor 使用逻辑连接查询子句NOR返回所有无法匹配两个子句的文档。

$or 使用逻辑连接查询子句OR返回与任一子句的条件相匹配的所有文档。Mongodb CRUD



### 4.3、更新数据

•db.collection.updateOne(<filter>, <update>, <options>)即使可能有多个文档通过过滤条件匹配到，但是也最多也只更新一个文档

•db.collection.updateMany(<filter>, <update>, <options>) 更新所有通过过滤条件匹配到的文档. 

•db.collection.replaceOne(<filter>, <replacement>, <options>) 即使可能有多个文档通过过滤条件匹配到，但是也最多也只替换一个文档。

•db.collection.update()即使可能有多个文档通过过滤条件匹配到，但是也最多也只更新或者替换一个文档。

db.test.insert({“name”:“jia”,“age”:30})

db.test.update({“age”:30},{$set: {“id” : 100}})

db.test.update({"age":30},{$set: {"age" : 100}})Mongodb CRUD



### 4.4、删除数据：

•db.collection.remove() 删除单个文档或与指定过滤器匹配的所有文档。参数{}，清空集合

db.collection.drop**（）**此方法获取受影响的数据库上的写入锁定，并将阻止其他操作，直到其完成。不加参数删除所有数据包括索引

•db.collection.deleteOne() 最多删除与指定过滤器匹配的单个文档，即使多个文档可能与指定的过滤器匹配。

•db.collection.deleteMany() 删除与指定过滤器匹配的所有文档。







## 5.用户及权限管理

注意
验证库: 建立用户时use到的库，在使用用户时，要加上验证库才能登陆。

对于管理员用户,必须在admin下创建.
1. 建用户时,use到的库,就是此用户的验证库
2. 登录时,必须明确指定验证库才能登录
3. 通常,管理员用的验证库是admin,普通用户的验证库一般是所管理的库设置为验证库
4. 如果直接登录到数据库,不进行use,默认的验证库是test,不是我们生产建议的.
5. 从3.6 版本开始，不添加bindIp参数，默认不让远程登录，只能本地管理员登录。

用户创建语法
use admin 
db.createUser
({
    user: "<name>",
    pwd: "<cleartext password>",
    roles: [
       { role: "<role>",
     db: "<database>" } 
    ]
})

基本语法说明：
user:用户名
pwd:密码
roles:
    role:角色名
    db:作用对象 
role：root, readWrite,read   		

验证数据库：
mongo -u today -p 123 127.0.0.1/today

用户管理例子
创建超级管理员：管理所有数据库（必须use admin再去创建）
$ mongo
use admin
db.createUser(
{
    user: "root",
    pwd: "123456",
    roles: [ { role: "root", db: "admin" } ]
}
)
验证用户
db.auth('root','123456')

配置文件中，加入以下配置
security:
  authorization: enabled
重启mongodb
mongod -f /mongodb/conf/mongo.conf --shutdown 
mongod -f /mongodb/conf/mongo.conf 
登录验证
mongo -uroot -p123456  admin            #此命令意思是：去到admin库里查找root用户表
mongo -uroot -p123456  127.0.0.1/admin      #127.0.0.1相当于mysql -h 

查看用户:
use admin
db.system.users.find().pretty()
创建应用用户
use today
db.createUser(
    {
        user: "app01",
        pwd: "app01",
        roles: [ { role: "readWrite" , db: "today" } ]
    }
)

mongo  -uapp01 -papp01 app
查询mongodb中的用户信息
mongo -uroot -proot123 127.0.0.1/admin
db.system.users.find().pretty()

删除用户（root身份登录，use到验证库）
删除用户
db.createUser({user: "app02",pwd: "app02",roles: [ { role: "readWrite" , db: "today" } ]})
mongo -uroot -proot123 127.0.0.1/admin
use today
db.dropUser("app02")
用户管理注意事项

1. 建用户要有验证库，管理员admin，普通用户是要管理的库
2. 登录时，注意验证库
mongo -uapp01 -papp01 127.0.0.1:38017/today





## 6.Mongodb 存储引擎

• 存储引擎是数据库的一部分，负责管理数据在内存和磁盘上的存储方式。许多数据库支持多个存储引擎，其中不同的引擎在特定工作负载

上表现更好。例如，一个存储引擎可能为读取繁重的工作负载提供更好的性能，另一个可能支持更高的写入操作吞吐量。

• MongoDB支持多个存储引擎，因为不同的引擎对于特定的工作负载更好。选择合适的存储引擎可能会显着影响应用程序的性能。

• [WiredTiger是从MongoDB 3.2开始的默认存储引擎。它非常适合大多数工作负载，建议用于新的部署。](https://www.mongodb.com/docs/manual/core/wiredtiger/)

• MMAPv1是原始的MongoDB存储引擎，是3.2之前的MongoDB版本的默认存储引擎。

• [In-Memory是MongoDB中企业提供。它不是将文档存储在磁盘上，而是将它们保留在内存中，以获得更可预测的数据延迟](https://www.mongodb.com/docs/manual/core/inmemory/)











## 7.MongoDB复制集RS（ReplicationSet）

基本原理
基本构成是1主2从的结构，自带互相监控投票机制（Raft（MongoDB）  Paxos（mysql MGR 用的是变种））
如果发生主库宕机，复制集内部会进行投票选举，选择一个新的主库替代原有主库对外提供服务。同时复制集会自动通知
客户端程序，主库已经发生切换了。应用就会连接到新的主库。

Replication Set配置过程详解
规划
三个以上的mongodb节点（或多实例）
环境准备
多个端口：
38017、38018、38019、38020
多套目录：
mkdir -p /mongodb/38017/conf /mongodb/38017/data /mongodb/38017/log
mkdir -p /mongodb/38018/conf /mongodb/38018/data /mongodb/38018/log
mkdir -p /mongodb/38019/conf /mongodb/38019/data /mongodb/38019/log
mkdir -p /mongodb/38020/conf /mongodb/38020/data /mongodb/38020/log
多套配置文件
/mongodb/38017/conf/mongod.conf
/mongodb/38018/conf/mongod.conf
/mongodb/38019/conf/mongod.conf
/mongodb/38020/conf/mongod.conf
配置文件内容
cat > /mongodb/38017/conf/mongod.conf <<EOF
systemLog:
  destination: file
  path: /mongodb/38017/log/mongodb.log
  logAppend: true
storage:
  journal:
    enabled: true
  dbPath: /mongodb/38017/data
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
processManagement:
  fork: true
net:
  bindIp: 192.168.245.153,127.0.0.1
  port: 38017
replication:
  oplogSizeMB: 2048
  replSetName: my_repl
EOF
        

\cp  /mongodb/38017/conf/mongod.conf  /mongodb/38018/conf/
\cp  /mongodb/38017/conf/mongod.conf  /mongodb/38019/conf/
\cp  /mongodb/38017/conf/mongod.conf  /mongodb/38020/conf/

sed 's#38017#38018#g' /mongodb/38018/conf/mongod.conf -i
sed 's#38017#38019#g' /mongodb/38019/conf/mongod.conf -i
sed 's#38017#38020#g' /mongodb/38020/conf/mongod.conf -i
chown -R mongod:mongod /mongodb

启动多个实例备用
mongod -f /mongodb/38017/conf/mongod.conf
mongod -f /mongodb/38018/conf/mongod.conf
mongod -f /mongodb/38019/conf/mongod.conf
mongod -f /mongodb/38020/conf/mongod.conf
netstat -lnp|grep 380

配置普通复制集：
1主2从，从库普通从库
mongo --port 38017 admin

```
config = {_id: 'my_repl', members: [
                          {_id: 0, host: '192.168.245.153:38017'},
                          {_id: 1, host: '192.168.245.153:38018'},
                          {_id: 2, host: '192.168.245.153:38019'}]
          }  
rs.initiate(config)             #初始化复制集  
```

查询复制集状态
rs.status();

1主2从1个arbiter
mongo -port 38017 admin

```json
config = {_id: 'my_repl', members: [
                          {_id: 0, host: '192.168.245.153:38017'},
                          {_id: 1, host: '192.168.245.153:38018'},
                          {_id: 2, host: '192.168.245.153:38019'},
                          {_id: 3, host: '192.168.245.153:38020',"arbiterOnly":true}]
          }  
rs.initiate(config) 
```



复制集管理操作
查看复制集状态
rs.status();    //查看整体复制集状态
rs.isMaster(); // 查看当前是否是主节点
rs.conf()；   //查看复制集配置信息
添加删除节点
rs.remove("ip:port"); // 删除一个节点
rs.add("ip:port"); // 新增从节点
rs.addArb("ip:port"); // 新增仲裁节点

举例：
添加 arbiter节点
1、连接到主节点
mongo --port 38018 admin
2、添加仲裁节点
my_repl:PRIMARY> rs.addArb("192.168.245.153:38020")
3、查看节点状态
my_repl:PRIMARY> rs.isMaster
({
    "hosts" : [
        "192.168.245.153:38017",
        "192.168.245.153:38018",
        "192.168.245.153:38019"
    ],
    "arbiters" : [
        "192.168.245.153:38020"
    ]
})
rs.remove("ip:port"); // 删除一个节点
例子：
my_repl:PRIMARY> rs.remove("192.168.245.153:38019");
{ "ok" : 1 }
my_repl:PRIMARY> rs.isMaster()
rs.add("ip:port"); // 新增从节点
例子：
my_repl:PRIMARY> rs.add("192.168.245.153:38019")
{ "ok" : 1 }
my_repl:PRIMARY> rs.isMaster()

特殊从节点
介绍：
arbiter节点：主要负责选主过程中的投票，但是不存储任何数据，也不提供任何服务
hidden节点：隐藏节点，不参与选主，也不对外提供服务。
delay节点：延时节点，数据落后于主库一段时间，因为数据是延时的，也不应该提供服务或参与选主，所以通常会配合hidden（隐藏）
一般情况下会将delay+hidden一起配置使用



--副本集角色切换（不要人为随便操作）
use admin
admin> rs.stepDown()
注：
admin> rs.freeze(300) //锁定从，使其不会转变成主库
freeze()和stepDown单位都是秒。
设置副本节点可读：在副本节点执行
admin> rs.slaveOk()