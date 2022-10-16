# 2022-09-27

# 1，kafka、zookeeper 集群脚本

```shell
#!/bin/bash
setenforce 0
sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config
systemctl disable firewalld
systemctl stop firewalld
node1=`ifconfig | grep -w broadcast | awk -F "[ ]+" '{print $3}'`
hostname1=`hostname`
read -p "请输入集群节点2主机的ip：" node2
read -p "请输入集群节点2主机的主机名：" hostname2
read -p "请输入集群节点2主机的密码：" nd2pw
read -p "请输入集群节点3主机的ip：" node3
read -p "请输入集群节点3主机的主机名：" hostname3
read -p "请输入集群节点3主机的密码：" nd3pw
cat >> /etc/hosts <<EOF
$node1 $hostname1
$node2 $hostname2
$node3 $hostname3
EOF

#####生成公钥分发到集群节点，以便后续操作#####
yum install -y expect
if [ -f /root/.ssh/id_rsa.pub ]
then
        echo "公钥存在,现在分别发送给es集群其他节点"
expect <<-EOF
spawn ssh-copy-id root@$node2
expect "yes/no"
send "yes\r"
expect "password:"
send "$nd2pw\r"
expect eof
EOF
expect <<-EOF
spawn ssh-copy-id root@$node3
expect "yes/no"
send "yes\r"
expect "password:"
send "$nd3pw\r"
expect eof
EOF
else
        echo "公钥不存在，现在创建并分别发送给es集群其他节点"
ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
expect <<-EOF
spawn ssh-copy-id root@$node2
expect "yes/no"
send "yes\r"
expect "password:"
send "$nd2pw\r"
expect eof
EOF
expect <<-EOF
spawn ssh-copy-id root@$node3
expect "yes/no"
send "yes\r"
expect "password:"
send "$nd3pw\r"
expect eof
EOF
fi


#############################################################zookeeper#############################################################
####下载zookeeper集群需要的安装包,并分发给其他节点,配置主节点####
cd /usr/local/src
wget https://dlcdn.apache.org/zookeeper/zookeeper-3.7.1/apache-zookeeper-3.7.1-bin.tar.gz --no-check-certificate
tar -xvf apache-zookeeper-3.7.1-bin.tar.gz
mv apache-zookeeper-3.7.1-bin zookeeper
mv zookeeper/conf/zoo_sample.cfg zookeeper/conf/zoo.cfg
wget  http://192.168.1.200/rpm/jdk-8u151-linux-x64.rpm
rpm -ivh jdk-8u151-linux-x64.rpm
cat >> /etc/profile << 'EOF'

#######################jdk################################
export JAVA_HOME=/usr/java/jdk1.8.0_151
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export PATH=$JAVA_HOME/bin:$PATH
EOF

mkdir -p /data/zoodata
sed -i 's@dataDir=/tmp/zookeeper@dataDir=/data/zoodata@g' /usr/local/src/zookeeper/conf/zoo.cfg
cat >> /usr/local/src/zookeeper/conf/zoo.cfg << EOF
server.1=$node1:2888:3888
server.2=$node2:2888:3888
server.3=$node3:2888:3888
EOF
echo "1" > /data/zoodata/myid
/usr/local/src/zookeeper/bin/zkServer.sh start


#配置节点2
scp -r apache-zookeeper-3.7.1-bin.tar.gz jdk-8u151-linux-x64.rpm root@$node2:/usr/local/src
ssh -t root@$node2 << 'EOF'
cd /usr/local/src
tar -xvf apache-zookeeper-3.7.1-bin.tar.gz
mv apache-zookeeper-3.7.1-bin zookeeper
mv zookeeper/conf/zoo_sample.cfg zookeeper/conf/zoo.cfg
rpm -ivh jdk-8u151-linux-x64.rpm
cat >> /etc/profile << 'eof'

#######################jdk################################
export JAVA_HOME=/usr/java/jdk1.8.0_151
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export PATH=$JAVA_HOME/bin:$PATH
eof
EOF
ssh -t root@$node2 << EOF
cat >> /etc/hosts <<eof
$node1 $hostname1
$node2 $hostname2
$node3 $hostname3
eof
mkdir -p /data/zoodata
sed -i 's@dataDir=/tmp/zookeeper@dataDir=/data/zoodata@g' /usr/local/src/zookeeper/conf/zoo.cfg
cat >> /usr/local/src/zookeeper/conf/zoo.cfg << eof
server.1=$node1:2888:3888
server.2=$node2:2888:3888
server.3=$node3:2888:3888
eof
echo "2" > /data/zoodata/myid
/usr/local/src/zookeeper/bin/zkServer.sh start
EOF

#配置节点3
scp -r apache-zookeeper-3.7.1-bin.tar.gz jdk-8u151-linux-x64.rpm root@$node3:/usr/local/src
ssh -t root@$node3 << 'EOF'
cd /usr/local/src
tar -xvf apache-zookeeper-3.7.1-bin.tar.gz
mv apache-zookeeper-3.7.1-bin zookeeper
mv /usr/local/src/zookeeper/conf/zoo_sample.cfg zookeeper/conf/zoo.cfg
rpm -ivh jdk-8u151-linux-x64.rpm
cat >> /etc/profile << 'eof'

#######################jdk################################
export JAVA_HOME=/usr/java/jdk1.8.0_151
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export PATH=$JAVA_HOME/bin:$PATH
eof
EOF
ssh -t root@$node3 << EOF
cat >> /etc/hosts <<eof
$node1 $hostname1
$node2 $hostname2
$node3 $hostname3
eof
mkdir -p /data/zoodata
sed -i 's@dataDir=/tmp/zookeeper@dataDir=/data/zoodata@g' /usr/local/src/zookeeper/conf/zoo.cfg
cat >> /usr/local/src/zookeeper/conf/zoo.cfg << eof
server.1=$node1:2888:3888
server.2=$node2:2888:3888
server.3=$node3:2888:3888
eof
echo "3" > /data/zoodata/myid
/usr/local/src/zookeeper/bin/zkServer.sh start
EOF

#############################################################kafka#############################################################
####下载kafka集群需要的安装包,并分发给其他节点,配置broker1####
cd /usr/local/src
wget http://192.168.1.200/220711-note/kafka_2.12-2.8.2.tgz
tar -xvf kafka_2.12-2.8.2.tgz 
mv kafka_2.12-2.8.2 kafka
mkdir -p /data/kafkadata
sed -i 's@log.dirs=/tmp/kafka-logs@log.dirs=/data/kafkadata@g' /usr/local/src/kafka/config/server.properties
sed -i 's/broker.id=0/broker.id=1/g' /usr/local/src/kafka/config/server.properties
sed -i "s/zookeeper.connect=localhost:2181/zookeeper.connect=$node1:2181,$node2:2181,$node3:2181/g" /usr/local/src/kafka/config/server.properties
/usr/local/src/kafka/bin/kafka-server-start.sh -daemon /usr/local/src/kafka/config/server.properties

#配置broker2
scp -r kafka_2.12-2.8.2.tgz root@$node2:/usr/local/src
ssh -t root@$node2 << EOF
cd /usr/local/src
tar -xvf kafka_2.12-2.8.2.tgz
mv kafka_2.12-2.8.2 kafka
mkdir -p /data/kafkadata
sed -i 's@log.dirs=/tmp/kafka-logs@log.dirs=/data/kafkadata@g' /usr/local/src/kafka/config/server.properties
sed -i 's/broker.id=0/broker.id=2/g' /usr/local/src/kafka/config/server.properties
sed -i "s/zookeeper.connect=localhost:2181/zookeeper.connect=$node1:2181,$node2:2181,$node3:2181/g" /usr/local/src/kafka/config/server.properties
/usr/local/src/kafka/bin/kafka-server-start.sh -daemon /usr/local/src/kafka/config/server.properties
EOF

#配置broker3
scp -r kafka_2.12-2.8.2.tgz root@$node3:/usr/local/src
ssh -t root@$node3 << EOF
cd /usr/local/src
tar -xvf kafka_2.12-2.8.2.tgz
mv kafka_2.12-2.8.2 kafka
mkdir -p /data/kafkadata
sed -i 's@log.dirs=/tmp/kafka-logs@log.dirs=/data/kafkadata@g' /usr/local/src/kafka/config/server.properties
sed -i 's/broker.id=0/broker.id=3/g' /usr/local/src/kafka/config/server.properties
sed -i "s/zookeeper.connect=localhost:2181/zookeeper.connect=$node1:2181,$node2:2181,$node3:2181/g" /usr/local/src/kafka/config/server.properties
/usr/local/src/kafka/bin/kafka-server-start.sh -daemon /usr/local/src/kafka/config/server.properties
EOF
```

# 2，apollo配置中心搭建使用（延期到十月一假期以后）

## 一、apollo简介

Apollo（阿波罗）是一款可靠的分布式配置管理中心，诞生于携程框架研发部，能够集中化管理应用不同环境、不同集群的配置，配置修改后能够实时推送到应用端，并且具备规范的权限、流程治理等特性，适用于微服务配置管理场景。

服务端基于Spring Boot和Spring Cloud开发，打包后可以直接运行，不需要额外安装Tomcat等应用容器。

Java客户端不依赖任何框架，能够运行于所有Java运行时环境，同时对Spring/Spring Boot环境也有较好的支持。

.Net客户端不依赖任何框架，能够运行于所有.Net运行时环境。

Apollo支持4个维度管理Key-Value格式的配置：

1. application (应用)
2. environment (环境)
3. cluster (集群)
4. namespace (命名空间)

#### 1.配置基本概念

既然Apollo定位于配置中心，那么在这里有必要先简单介绍一下什么是配置。

按照我们的理解，配置有以下几个属性：

- **配置是独立于程序的只读变量**
  - 配置首先是独立于程序的，同一份程序在不同的配置下会有不同的行为。
  - 其次，配置对于程序是只读的，程序通过读取配置来改变自己的行为，但是程序不应该去改变配置。
  - 常见的配置有：DB Connection Str、Thread Pool Size、Buffer Size、Request Timeout、Feature Switch、Server Urls等。
- **配置伴随应用的整个生命周期**
  - 配置贯穿于应用的整个生命周期，应用在启动时通过读取配置来初始化，在运行时根据配置调整行为。
- **配置可以有多种加载方式**
  - 配置也有很多种加载方式，常见的有程序内部hard code，配置文件，环境变量，启动参数，基于数据库等
- **配置需要治理**
  - 权限控制
    - 由于配置能改变程序的行为，不正确的配置甚至能引起灾难，所以对配置的修改必须有比较完善的权限控制
  - 不同环境、集群配置管理
    - 同一份程序在不同的环境（开发，测试，生产）、不同的集群（如不同的数据中心）经常需要有不同的配置，所以需要有完善的环境、集群配置管理
  - 框架类组件配置管理
    - 还有一类比较特殊的配置 - 框架类组件配置，比如CAT客户端的配置。
    - 虽然这类框架类组件是由其他团队开发、维护，但是运行时是在业务实际应用内的，所以本质上可以认为框架类组件也是应用的一部分。
    - 这类组件对应的配置也需要有比较完善的管理方式。

#### 2.架构和模块

下图是Apollo的作者宋顺给出的架构图：

![图片](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210012128625.jpeg)

Apollo架构图by宋顺

如果没有足够的分布式微服务架构的基础，对携程的一些框架产品(比如Software Load Balancer(SLB))不了解的话，那么这个架构图第一眼看是不太好理解的(其实我第一次看到这个架构也没有看明白)。在这里我们先放一下，等我后面把这个架构再重新剖析一把以后，大家再回过头来看这个架构就容易理解了。

下面是Apollo的七个模块，其中四个模块是和功能相关的核心模块，另外三个模块是辅助服务发现的模块：

##### 四个核心模块及其主要功能

1. **ConfigService**

2. - 提供配置获取接口
   - 提供配置推送接口
   - 服务于Apollo客户端

3. **AdminService**

4. - 提供配置管理接口
   - 提供配置修改发布接口
   - 服务于管理界面Portal

5. **Client**

6. - 为应用获取配置，支持实时更新
   - 通过MetaServer获取ConfigService的服务列表
   - 使用客户端软负载SLB方式调用ConfigService

7. **Portal**

8. - 配置管理界面
   - 通过MetaServer获取AdminService的服务列表
   - 使用客户端软负载SLB方式调用AdminService

##### 三个辅助服务发现模块

1. **Eureka**

2. - 用于服务发现和注册
   - Config/AdminService注册实例并定期报心跳
   - 和ConfigService住在一起部署

3. **MetaServer**

4. - Portal通过域名访问MetaServer获取AdminService的地址列表
   - Client通过域名访问MetaServer获取ConfigService的地址列表
   - 相当于一个Eureka Proxy
   - 逻辑角色，和ConfigService住在一起部署

5. **NginxLB**

6. - 和域名系统配合，协助Portal访问MetaServer获取AdminService地址列表
   - 和域名系统配合，协助Client访问MetaServer获取ConfigService地址列表
   - 和域名系统配合，协助用户访问Portal进行配置管理

## 二、部署apollo

环境需求：java 1.8+

要配置好环境变量！

```shell
[root@home2 src]# java -version
java version "1.8.0_151"
Java(TM) SE Runtime Environment (build 1.8.0_151-b12)
Java HotSpot(TM) 64-Bit Server VM (build 25.151-b12, mixed mode)
```

MySQL:版本要求：5.6.5+

Apollo的表结构对`timestamp`使用了多个default声明，所以需要5.6.5以上版本。

连接上MySQL后，可以通过如下命令检查：

```sql
mysql> SHOW VARIABLES WHERE Variable_name = 'version';
+---------------+------------+
| Variable_name | Value      |
+---------------+------------+
| version       | 5.7.38-log |
+---------------+------------+
1 row in set (0.00 sec)
```

#### 1.下载Quick Start安装包

```shell
[root@home2 src]# wget https://github.com/apolloconfig/apollo-quick-start/archive/refs/heads/master.zip
[root@home2 src]# unzip master.zip
```

#### 2.创建数据库

SQL在这目录下：/usr/local/src/apollo-quick-start-master/sql/

```mysql
mysql> source apolloconfigdb.sql
mysql> source apolloportaldb.sql
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| ApolloConfigDB     |
| ApolloPortalDB     |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
6 rows in set (0.00 sec)
```

```shell
[root@home2 apollo-quick-start-master]# vim demo.sh 
																	#只修改数据库相关内容。
```

![image-20221002124704965](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210021247161.png)

**Quick Start脚本会在本地启动3个服务，分别使用8070, 8080, 8090端口，请确保这3个端口当前没有被使用。**

#### 3.启动apollo配置中心

```shell
[root@home2 apollo-quick-start-master]# ./demo.sh start
==== starting service ====
Service logging file is ./service/apollo-service.log
Application is running as root (UID 0). This is considered insecure.
Started [24243]
Waiting for config service startup....
Config service started. You may visit http://localhost:8080 for service status now!
Waiting for admin service startup
Admin service started
==== starting portal ====
Portal logging file is ./portal/apollo-portal.log
Application is running as root (UID 0). This is considered insecure.
Started [24434]
Waiting for portal startup...
Portal started. You can visit http://localhost:8070 now!
```

#### 4.到网页输入ip:8070登录Apollo

默认**账号/密码**：**apollo/admin**

![image-20221002131447150](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210021314366.png)

![image-20221002131537195](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210021315316.png)

#### 5.Apollo的使用

##### 5.1创建应用（项目）

![image-20221002132414720](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210021324821.png)

![image-20221002133201352](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210021332456.png)

输入项目信息

- 部门：选择应用所在的部门
- 应用AppId：用来标识应用身份的唯一id，格式为string，需要和客户端app.properties中配置的app.id对应
- 应用名称：应用名，仅用于界面展示
- 应用负责人：选择的人默认会成为该项目的管理员，具备项目权限管理、集群创建、Namespace创建等权限

![image-20221002133225235](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210021332327.png)

##### 5.2项目权限分配

**先去创建个用户方便后面添加用户使用**

![image-20221002134908829](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210021349937.png)

###### 5.2.1项目管理员权限

项目管理员拥有以下权限：

1. 可以管理项目的权限分配
2. 可以创建集群
3. 可以创建Namespace

创建项目时填写的应用负责人默认会成为项目的管理员之一，如果还需要其他人也成为项目管理员，可以按照下面步骤操作：

1. 点击页面左侧的“管理应用”![image-20221002133820114](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210021338938.png)
2. 搜索需要添加的成员并点击添加

![image-20221002135357850](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210021353954.png)

###### 5.2.2配置编辑、发布权限

配置权限分为编辑和发布：

- 编辑权限允许用户在Apollo界面上创建、修改、删除配置
  - 配置修改后只在Apollo界面上变化，不会影响到应用实际使用的配置
- 发布权限允许用户在Apollo界面上发布、回滚配置
  - 配置只有在发布、回滚动作后才会被应用实际使用到
  - Apollo在用户操作发布、回滚动作后实时通知到应用，并使最新配置生效

项目创建完，默认没有分配配置的编辑和发布权限，需要项目管理员进行授权。

1. 点击application这个namespace的授权按钮![image-20221002140140980](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210021401065.png)
2. 分配修改权限
3. 分配发布权限

![](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210021402464.png)

#### 5.3添加配置项

编辑配置需要拥有这个Namespace的编辑权限，如果发现没有新增配置按钮，可以找项目管理员授权。

###### 5.3.1通过表格模式添加配置

1. 点击新增配置![image-20221002140410617](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210021408054.png)
2. 输入配置项
3. 点击提交

![image-20221002140613209](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210021406346.png)

**添加成功**

![image-20221002140542570](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210021405628.png)

###### 5.3.2通过文本模式编辑

Apollo除了支持表格模式，逐个添加、修改配置外，还提供文本模式批量添加、修改。 这个对于从已有的properties文件迁移尤其有用。

1. 切换到文本编辑模式![image-20221002141034009](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210021411354.png)
2. 点击右侧的修改配置按钮![image-20221002141202595](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210021412653.png)
3. 输入配置项，并点击提交修改

![image-20221002141254181](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210021412248.png)

**修改成功**

![image-20221002141305213](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210021413282.png)



#### 5.4 发布配置

配置只有在发布后才会真的被应用使用到，所以在编辑完配置后，需要发布配置。

发布配置需要拥有这个Namespace的发布权限，如果发现没有发布按钮，可以找项目管理员授权。

1. 点击“发布按钮”![image-20221002141716528](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210021417586.png)
2. 填写发布相关信息，点击发布![](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210021417344.png)

**成功发布**

![image-20221002141835067](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210021418120.png)

#### 5.5应用读取配置

配置发布成功后，应用就可以通过Apollo客户端读取到配置了。

目前支持的语言客户端![](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210021457450.png)

**因为我们用的Quick-Start所以已经有了Springboot客户端了（折腾了我好久，才发现原来已经有了！！！）**

```
进入客户端的读取appid的文件，添加刚刚我们创建的appid。
[root@home2 apollo-quick-start-master]# vim client/META-INF/app.properties 
```

![image-20221002195832019](C:\Users\15893\AppData\Roaming\Typora\typora-user-images\image-20221002195832019.png)

**开启客户端**

```shell
[root@home2 apollo-quick-start-master]# ./demo.sh client
											#因为他是KV存储，所以我们输入Key能获取Value
											#输入我们刚刚新增的配置的Key
```

![image-20221002200122488](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210022001699.png)

#### 5.6 回滚已发布配置

如果发现已发布的配置有问题，可以通过点击『回滚』按钮来将客户端读取到的配置回滚到上一个发布版本。

这里的回滚机制类似于发布系统，发布系统中的回滚操作是将部署到机器上的安装包回滚到上一个部署的版本，但代码仓库中的代码是不会回滚的，从而开发可以在修复代码后重新发布。

Apollo中的回滚也是类似的机制，点击回滚后是将发布到客户端的配置回滚到上一个已发布版本，也就是说客户端读取到的配置会恢复到上一个版本，但页面上编辑状态的配置是不会回滚的，从而开发可以在修复配置后重新发布。

![image-20221002200439291](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210022004359.png)

**如果没有发生变化可以点击查看之前生效的版本**

![image-20221002200525639](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210022005739.png)

![image-20221002200609283](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210022006378.png)



# 3，elfk+kafka的架构搭建。（有能力研究脚本）

**搭建：脚本直接运行**

## elasticsearch+logstash+filebeat+kibana+kafka：

思路：用Filebeat收集日志，然后作为生产者将消息写入到Kafka中形成消息队列，之后让Lostash作为消费者消费消息，将获取到的消息日志写入到es集群节点中，最后实现刷盘，并用kibana添加索引。

**es+kafka集群节点1+日志收集（nginx）：home2，192.168.159.137**

**es+kafka集群节点2：home3，192.168.159.138**

**es+kafka集群节点2：home4，192.168.159.139**

## 一、nginx配置：

在http内容下加入json格式日志

```yaml
  log_format json  '{ "time_local": "$time_local", '
                          '"remote_addr": "$remote_addr", '
                          '"referer": "$http_referer", '
                          '"request": "$request", '
                          '"status": $status, '
                          '"bytes": $body_bytes_sent, '
                          '"agent": "$http_user_agent", '
                          '"x_forwarded": "$http_x_forwarded_for", '
                          '"up_addr": "$upstream_addr",'
                          '"up_host": "$upstream_http_host",'
                          '"upstream_time": "$upstream_response_time",'
                          '"request_time": "$request_time"'
' }';
    access_log  /var/log/nginx/access.log  json;
```

## 二、Filebeat配置：

```shell
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/nginx/access.log 
filebeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: false
setup.template.settings:
  index.number_of_shards: 1
setup.kibana:
output.kafka:
  hosts: ["192.168.159.137:9092","192.168.159.138:9092","192.168.159.139:9092"]
  topic: estest
  version: "0.10.2.0"
processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
  - add_kubernetes_metadata: ~
```

**阶段性测试一下：Filebeat是否能成为生产者把消息写入到kafka**

```shell
[root@home2 src]# filebeat -e -c /etc/filebeat/filebeat.yml							#顺带测试语法
```

选其中一个节点来消费topic estest的消息，这里我选了节点2（home3）。

登录web服务求刷新一下，生成访问日志数据。

可以看到Filebeat开始写入消息了

![image-20220927200630647](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209272006991.png)

节点2（home3）消费消息

```sh
[root@home3 src]# ./kafka/bin/kafktopics.sh --bootstrap-server 192.168.159.137:9092,192.168.159.138:9092,192.168.159.139:9092 --list
__consumer_offsets
estest											  #可以查看一下我们全部的topic，已经可以看到有estest生成了
ljh
[root@home3 src]# ./kafka/bin/kafka-console-consumer.sh --bootstrap-server 192.168.159.137:9092,192.168.159.138:9092,192.168.159.139:9092 --topic estest				
									#这里我怕先前有消息写入了，为了确保一致性我没有使用--from-beginning参数。
```

![image-20220927200724492](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209272007594.png)

## 三、Logstash配置：

```sh
input {
  kafka {
    type => "kafka"
    bootstrap_servers => "192.168.159.137:9092,192.168.159.138:9092,192.168.159.139:9092"
    topics => "estest"
    consumer_threads => 1
    codec => "json"
  }
}
output {
  elasticsearch {
    hosts => ["192.168.159.137:9200","192.168.159.138:9200","192.168.159.139:9200"]
    index => "nginx-kafka‐%{+YYYY.MM.dd}"
 }
}
```

测试通过

![image-20220927204752534](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209272047748.png)

## 四、开启架构所有服务，刷新web网页开始获取日志数据消息。

查看消费组及其详细信息

```shell
[root@home3 src]# ./kafka/bin/kafka-consumer-groups.sh --bootstrap-server 192.168.159.137:9092,192.168.159.138:9092,192.168.159.139:9092 --list
[root@home3 src]# ./kafka/bin/kafka-consumer-groups.sh --bootstrap-server 192.168.159.137:9092,192.168.159.138:9092,192.168.159.139:9092 --group logstash --describe
```

![image-20220927205258741](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209272052841.png)

网页输入ip:5601，登录到kibana添加索引

![image-20220927205451397](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209272054555.png)

![image-20220927205858655](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209272058748.png)

![image-20220927205914982](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209272059091.png)

这里我只是简单的搭起来了架构，然后收集日志数据。

其中可以添加很多操作：比如logstash匹配过滤，设置消费者组id（group_id），filebeat舍去不必要的字段，设置压缩类型设置负载。

