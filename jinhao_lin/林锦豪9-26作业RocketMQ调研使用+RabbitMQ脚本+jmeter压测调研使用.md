# 2022-09-26

# 1，rocketmq研究使用。rabbitmq集群脚本（编写）

## 一、Rocketmq研究使用

RocketMQ是由阿里捐赠给Apache的一款低延迟、高并发、高可用、高可靠的分布式消息中间件。经历了**淘宝双十一的洗礼**。RocketMQ既可为分布式应用系统提供异步解耦和削峰填谷的能力，同时也具备互联网应用所需的海量消息堆积、高吞吐、可靠重试等特性。

### 核心概念

- **Topic**：消息主题，一级消息类型，生产者向其发送消息。
- **Message**：生产者向Topic发送并最终传送给消费者的数据消息的载体。
- **消息属性**：生产者可以为消息定义的属性，包含Message Key和Tag。
- **Message Key**：消息的业务标识，由消息生产者（Producer）设置，唯一标识某个业务逻辑。
- **Message ID**：消息的全局唯一标识，由消息队列RocketMQ系统自动生成，唯一标识某条消息。
- **Tag**：消息标签，二级消息类型，用来进一步区分某个Topic下的消息分类
- **Producer**：也称为消息发布者，负责生产并发送消息至Topic。
- **Consumer**：也称为消息订阅者，负责从Topic接收并消费消息。
- **分区**：即Topic Partition，物理上的概念。每个Topic包含一个或多个分区。
- **消费位点**：每个Topic会有多个分区，每个分区会统计当前消息的总条数，这个称为最大位点MaxOffset；分区的起始位置对应的位置叫做起始位点MinOffset。
- **Group**：一类生产者或消费者，这类生产者或消费者通常生产或消费同一类消息，且消息发布或订阅的逻辑一致。
- **Group ID**：Group的标识。
- **队列**：个Topic下会由一到多个队列来存储消息。
- **Exactly-Once投递语义**：Exactly-Once投递语义是指发送到消息系统的消息只能被Consumer处理且仅处理一次，即使Producer重试消息发送导致某消息重复投递，该消息在Consumer也只被消费一次。
- **集群消费**：一个Group ID所标识的所有Consumer平均分摊消费消息。例如某个Topic有9条消息，一个Group ID有3个Consumer实例，那么在集群消费模式下每个实例平均分摊，只消费其中的3条消息。
- **广播消费**：一个Group ID所标识的所有Consumer都会各自消费某条消息一次。例如某个Topic有9条消息，一个Group ID有3个Consumer实例，那么在广播消费模式下每个实例都会各自消费9条消息。
- **定时消息**：Producer将消息发送到消息队列RocketMQ服务端，但并不期望这条消息立马投递，而是推迟到在当前时间点之后的某一个时间投递到Consumer进行消费，该消息即定时消息。
- **延时消息**：Producer将消息发送到消息队列RocketMQ服务端，但并不期望这条消息立马投递，而是延迟一定时间后才投递到Consumer进行消费，该消息即延时消息。
- **事务消息**：RocketMQ提供类似X/Open XA的分布事务功能，通过消息队列RocketMQ的事务消息能达到分布式事务的最终一致。
- **顺序消息**：RocketMQ提供的一种按照顺序进行发布和消费的消息类型，分为全局顺序消息和分区顺序消息。
- **全局顺序消息**：对于指定的一个Topic，所有消息按照严格的先入先出（FIFO）的顺序进行发布和消费。
- **分区顺序消息**：对于指定的一个Topic，所有消息根据Sharding Key进行区块分区。同一个分区内的消息按照严格的FIFO顺序进行发布和消费。Sharding Key是顺序消息中用来区分不同分区的关键字段，和普通消息的Message Key是完全不同的概念。
- **消息堆积**：Producer已经将消息发送到消息队列RocketMQ的服务端，但由于Consumer消费能力有限，未能在短时间内将所有消息正确消费掉，此时在消息队列RocketMQ的服务端保存着未被消费的消息，该状态即消息堆积。
- **消息过滤**：Consumer可以根据消息标签（Tag）对消息进行过滤，确保Consumer最终只接收被过滤后的消息类型。消息过滤在消息队列RocketMQ的服务端完成。
- **消息轨迹**：在一条消息从Producer发出到Consumer消费处理过程中，由各个相关节点的时间、地点等数据汇聚而成的完整链路信息。通过消息轨迹，您能清晰定位消息从Producer发出，经由消息队列RocketMQ服务端，投递给Consumer的完整链路，方便定位排查问题。
- **重置消费位点**：以时间轴为坐标，在消息持久化存储的时间范围内（默认3天），重新设置Consumer对已订阅的Topic的消费进度，设置完成后Consumer将接收设定时间点之后由Producer发送到消息队列RocketMQ服务端的消息。
- **死信队列**：死信队列用于处理无法被正常消费的消息。当一条消息初次消费失败，消息队列RocketMQ会自动进行消息重试；达到最大重试次数后，若消费依然失败，则表明Consumer在正常情况下无法正确地消费该消息。此时，消息队列RocketMQ不会立刻将消息丢弃，而是将这条消息发送到该Consumer对应的特殊队列中。
  消息队列RocketMQ将这种正常情况下无法被消费的消息称为死信消息（Dead-Letter Message），将存储死信消息的特殊队列称为死信队列（Dead-Letter Queue）。

### 消息收发模型

消息队列RocketMQ支持发布和订阅模型，消息生产者应用创建Topic并将消息发送到Topic。消费者应用创建对Topic的订阅以便从其接收消息。通信可以是一对多（扇出）、多对一（扇入）和多对多。具体通信如下图所示。

![img](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209270820761.png)

- **生产者集群**：用来表示发送消息应用，一个生产者集群下包含多个生产者实例，可以是多台机器，也可以是一台机器的多个进程，或者一个进程的多个生产者对象。
  一个生产者集群可以发送多个Topic消息。发送分布式事务消息时，如果生产者中途意外宕机，消息队列RocketMQ服务端会主动回调生产者集群的任意一台机器来确认事务状态。
- **消费者集群**：用来表示消费消息应用，一个消费者集群下包含多个消费者实例，可以是多台机器，也可以是多个进程，或者是一个进程的多个消费者对象。
  一个消费者集群下的多个消费者以均摊方式消费消息。如果设置的是广播方式，那么这个消费者集群下的每个实例都消费全量数据。
  一个消费者集群对应一个Group ID，一个Group ID可以订阅多个Topic，如上图中的Group 2所示。Group和Topic的订阅关系可以通过直接在程序中设置即可。

### 应用场景

- **削峰填谷**：诸如秒杀、抢红包、企业开门红等大型活动时皆会带来较高的流量脉冲，或因没做相应的保护而导致系统超负荷甚至崩溃，或因限制太过导致请求大量失败而影响用户体验，消息队列RocketMQ可提供削峰填谷的服务来解决该问题。

  ![img](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209270825018.png)

- **异步解耦**：交易系统作为淘宝和天猫主站最核心的系统，每笔交易订单数据的产生会引起几百个下游业务系统的关注，包括物流、购物车、积分、流计算分析等等，整体业务系统庞大而且复杂，消息队列RocketMQ可实现异步通信和应用解耦，确保主站业务的连续性。

  ![img](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209270826763.png)

- **顺序收发**：细数日常中需要保证顺序的应用场景非常多，例如证券交易过程时间优先原则，交易系统中的订单创建、支付、退款等流程，航班中的旅客登机消息处理等等。与先进先出FIFO（First In First Out）原理类似，消息队列RocketMQ提供的顺序消息即保证消息FIFO。

- **分布式事务一致性**：交易系统、支付红包等场景需要确保数据的最终一致性，大量引入消息队列RocketMQ的分布式事务，既可以实现系统之间的解耦，又可以保证最终的数据一致性。

- **大数据分析**：数据在“流动”中产生价值，传统数据分析大多是基于批量计算模型，而无法做到实时的数据分析，利用阿里云消息队列RocketMQ与流式计算引擎相结合，可以很方便的实现业务数据的实时分析。

- **分布式缓存同步**：天猫双11大促，各个分会场琳琅满目的商品需要实时感知价格变化，大量并发访问数据库导致会场页面响应时间长，集中式缓存因带宽瓶颈，限制了商品变更的访问流量，通过消息队列RocketMQ构建分布式缓存，实时通知商品数据的变化。

### 分布式事务的数据一致性

注册系统注册的流程中，用户入口在网页注册系统，通知系统在邮件系统，两个系统之间的数据需要保持最终一致。

#### 普通消息处理

如上所述，注册系统和邮件通知系统之间通过消息队列进行异步处理。注册系统将注册信息写入注册系统之后，发送一条注册成功的消息到消息队列RocketMQ，邮件通知系统订阅消息队列RocketMQ的注册消息，做相应的业务处理，发送注册成功或者失败的邮件。

![img](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209270827983.png)

流程说明如下：

1. 注册系统发起注册。
2. 注册系统向消息队列RocketMQ发送注册消息成功与否的消息。
   2.1. 消息发送成功，进入3。
   2.2. 消息发送失败，导致邮件通知系统未收到消息队列RocketMQ发送的注册成功与否的消息，而无法发送邮件，最终邮件通知系统和注册系统之间的状态数据不一致。
3. 邮件通知系统收到消息队列RocketMQ的注册成功消息。
4. 邮件通知系统发送注册成功邮件给用户。

在这样的情况下，虽然实现了系统间的解耦，上游系统不需要关心下游系统的业务处理结果；但是数据一致性不好处理，如何保证邮件通知系统状态与注册系统状态的最终一致。

#### 事务消息处理

此时，需要利用消息队列RocketMQ所提供的事务消息来实现系统间的状态数据一致性。

![img](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209270827997.png)

流程说明如下：

1. 注册系统向消息队列RocketMQ发送半事务消息。
   1.1. 半事务消息发送成功，进入2。
   1.2. 半事务消息发送失败，注册系统不进行注册，流程结束。（最终注册系统与邮件通知系统数据一致）
2. 注册系统开始注册。
   2.1. 注册成功，进入3.1。
   2.2. 注册失败，进入3.2。
3. 注册系统向消息队列RocketMQ发送半消息状态。
   3.1. 提交半事务消息，产生注册成功消息，进入4。
   3.2. 回滚半事务消息，未产生注册成功消息，流程结束。
   说明 最终注册系统与邮件通知系统数据一致。
4. 邮件通知系统接收消息队列RocketMQ的注册成功消息。
5. 邮件通知系统发送注册成功邮件。（最终注册系统与邮件通知系统数据一致）
   关于分布式事务消息的更多详细内容，请参见事务消息。

### 大规模机器的缓存同步

双十一大促时，各个分会场会有玲琅满目的商品，每件商品的价格都会实时变化。使用缓存技术也无法满足对商品价格的访问需求，缓存服务器网卡满载。访问较多次商品价格查询影响会场页面的打开速度。

此时需要提供一种广播机制，一条消息本来只可以被集群的一台机器消费，如果使用消息队列RocketMQ的广播消费模式，那么这条消息会被所有节点消费一次，相当于把价格信息同步到需要的每台机器上，取代缓存的作用。

## 系统部署架构！！

系统部署架构如下图所示。

![img](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209270828922.png)

图中所涉及到的概念如下所述：

- **Name Server**：是一个几乎无状态节点，可集群部署，在消息队列RocketMQ版中提供命名服务，更新和发现Broker服务。
- **Broker**：消息中转角色，负责存储消息，转发消息。分为Master Broker和Slave Broker，一个Master Broker可以对应多个Slave Broker，但是一个Slave Broker只能对应一个Master Broker。Broker启动后需要完成一次将自己注册至Name Server的操作；随后每隔30s定期向Name Server上报Topic路由信息。
- **生产者**：与Name Server集群中的其中一个节点（随机）建立长链接（Keep-alive），定期从Name Server读取Topic路由信息，并向提供Topic服务的Master Broker建立长链接，且定时向Master Broker发送心跳。
- **消费者**：与Name Server集群中的其中一个节点（随机）建立长连接，定期从Name Server拉取Topic路由信息，并向提供Topic服务的Master Broker、Slave Broker建立长连接，且定时向Master Broker、Slave Broker发送心跳。Consumer既可以从Master Broker订阅消息，也可以从Slave Broker订阅消息，订阅规则由Broker配置决定。

## 安装RocketMQ

环境需要：jdk1.8+，maven，git

```shell
[root@home2 src]# git clone https://github.com/apache/rocketmq.gitgit clone
[root@home2 src]# cd rocketmq/
[root@home2 rocketmq]# mvn -Prelease-all -DskipTests clean install -U						#安装时间较久
```

![image-20220927091000181](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209270910520.png)

```shell
[root@home2 rocketmq]# cd distribution/target/rocketmq-5.0.1-SNAPSHOT
[root@home2 rocketmq-5.0.1-SNAPSHOT]# wget https://dlcdn.apache.org/rocketmq/5.0.0/rocketmq-all-5.0.0-bin-release.zip --no-check-certificate
[root@home2 rocketmq-5.0.1-SNAPSHOT]# unzip rocketmq-all-5.0.0-bin-release.zip 
[root@home2 rocketmq-5.0.1-SNAPSHOT]# cd rocketmq-all-5.0.0-bin-release
[root@home2 rocketmq-all-5.0.0-bin-release]# vim bin/runserver.sh 
[root@home2 rocketmq-all-5.0.0-bin-release]# vim bin/runbroker.sh 
			#两个都添加一下java的家目录,根据自身机子的内存更改一下Xms，Xmn，Xmx的值
```

![image-20220927092237436](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209270922542.png)

![image-20220927141134430](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209271411474.png)

```shell
[root@home2 rocketmq-all-5.0.0-bin-release]# nohup sh bin/mqnamesrv &
[root@home2 rocketmq-all-5.0.0-bin-release]# tail -f ~/logs/rocketmqlogs/namesrv.log
#查看namesrv状态
```

![image-20220927131422633](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209271314886.png)

```shell
[root@home2 rocketmq-all-5.0.0-bin-release]# tail -f ~/logs/rocketmqlogs/broker.log 
#查看broker状态
```

![image-20220927131106774](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209271311008.png)

测试：

```shell
[root@home2 rocketmq-all-5.0.0-bin-release]# export NAMESRV_ADDR=localhost:9876
[root@home2 rocketmq-all-5.0.0-bin-release]# sh bin/tools.sh org.apache.rocketmq.example.quickstart.Producer
											#生产者发送消息
```

![image-20220927131720171](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209271317487.png)

![image-20220927142616301](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209271426625.png)

这里卡住了暂时没法解决不知道啥情况



## 二、rabbitmq集群脚本

```shell
#!/bin/bash
setenforce 0
sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config
systemctl disable firewalld
systemctl stop firewalld
node1=`ifconfig | grep -w broadcast | awk -F "[ ]+" '{print $3}'`
hostname1=`hostname`
read -p "请输入你要设置的集群账户：" user
read -p "请输入你要设置的集群账户密码：" password
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
        echo "公钥存在,现在分别发送给RabbitMQ其他节点"
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
        echo "公钥不存在，现在创建并分别发送给RabbitMQ其他节点"
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

####搭建集群####
#配置主节点（默认为执行脚本的主机为主节点并且为磁盘节点）
cd /etc/yum.repos.d/
wget http://192.168.1.200/220711-note/rabbitmq_rabbitmq-server.repo
yum clean all
yum makecache
yum install -y rabbitmq-server
rabbitmq-plugins enable rabbitmq_management
systemctl start rabbitmq-server

#配置节点2（内存节点）
ssh -t root@$node2 << EOF
cat >> /etc/hosts <<eof
$node1 $hostname1
$node2 $hostname2
$node3 $hostname3
eof
cd /etc/yum.repos.d/
wget http://192.168.1.200/220711-note/rabbitmq_rabbitmq-server.repo
yum clean all 
yum makecache
yum install -y rabbitmq-server
rabbitmq-plugins enable rabbitmq_management
systemctl start rabbitmq-server
EOF
scp /var/lib/rabbitmq/.erlang.cookie root@$node2:/var/lib/rabbitmq/.erlang.cookie
ssh -t root@$node2 << EOF
systemctl restart rabbitmq-server
rabbitmqctl stop_app
rabbitmqctl join_cluster rabbit@"$hostname1" --ram
rabbitmqctl start_app
EOF


#配置节点3（内存节点）
ssh -t root@$node3 << EOF
cat >> /etc/hosts <<eof
$node1 $hostname1
$node2 $hostname2
$node3 $hostname3
eof
cd /etc/yum.repos.d/
wget http://192.168.1.200/220711-note/rabbitmq_rabbitmq-server.repo
yum clean all 
yum makecache
yum install -y rabbitmq-server
rabbitmq-plugins enable rabbitmq_management
systemctl start rabbitmq-server
EOF
scp /var/lib/rabbitmq/.erlang.cookie root@$node3:/var/lib/rabbitmq/.erlang.cookie
ssh -t root@$node3 << EOF
systemctl restart rabbitmq-server
rabbitmqctl stop_app
rabbitmqctl join_cluster rabbit@"$hostname1" --ram
rabbitmqctl start_app
EOF


#查看集群状态
rabbitmqctl add_user $user $password
rabbitmqctl set_user_tags $user administrator
rabbitmqctl cluster_status
```

# 2，jmeter压测工具调研使用。

## 一、简介：

**JMeter**是100%纯JAVA桌面应用程序，被设计为用于测试客户端/服务端结构的软件(例如web应用程序)。它可以用来测试静态和动态资源的性能，例如：静态文件，Java Servlet,CGI Scripts,Java Object,数据库和FTP[服务器](https://www.yisu.com/)等等。JMeter可用于模拟大量负载来测试一台服务器，网络或者对象的健壮性或者分析不同负载下的整体性能。

**Jmeter常用组件：**

1.测试计划：起点，所有组件的容器。

2.线程组：代表一定数量的用户。

3.取样器：像服务器发送请求的最小单位。

4.逻辑控制器：结合取样器实现一些复杂的逻辑。

5.前置处理器：在请求之后的工作。

6.后置处理器：在请求之后的工作。

7.断言：用于判断请求是否成功。

8.定时器：负责在请求之间的延时间隔。固定、高斯、随机。

9.配置元件：配置信息。

10.监听器：负责收集结果。

**顺序(重点！！！！)：**

测试计划->线程组->配置元件->前置处理器->定时器->取样器->后置处理器->断言->监听器。

其中逻辑控制器是穿插在里面的。



**作用域：**

必须组件：测试计划，线程组，取样器。

辅助组件：逻辑控制器，配置元件，前置处理器，定时器，后置处理器，断言，监听器。（也就是出去必须组件，剩下的都是辅助组件）

**辅助组件作用于父组件。同级组件，以及同级组件下的所有子组件。**

## 二、开始安装：

官网下载：https://jmeter.apache.org/download_jmeter.cgi

![image-20221001113336985](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210011133153.png)

**下载最新的，可以看到需求环境是Java8以上（我这里装了jdk17，因为我jdk8的做了一次发现报错了！！！！）**

```
[root@home2 ~]# java -version
java version "17.0.3.1" 2022-04-22 LTS
Java(TM) SE Runtime Environment (build 17.0.3.1+2-LTS-6)
Java HotSpot(TM) 64-Bit Server VM (build 17.0.3.1+2-LTS-6, mixed mode, sharing)
[root@home2 ~]# cd /usr/local/src/
[root@home2 src]# wget https://dlcdn.apache.org//jmeter/binaries/apache-jmeter-5.5.tgz --no-check-certificate
[root@home2 src]# tar -xvf apache-jmeter-5.5.tgz
[root@home2 src]# mv apache-jmeter-5.5 /usr/local/jmeter
[root@home2 src]# cd /usr/local/jmeter
[root@home2 jmeter]# cat >> /etc/profile << 'EOF'
> export PATH=/usr/local/jmeter/bin:$PATH
> EOF
[root@home2 jmeter]# source /etc/profile
```

**参数介绍：**

-h 帮助 -> 打印出有用的信息并退出

-n 非 GUI 模式 -> 在非 GUI 模式下运行 JMeter

-t 测试文件 -> 要运行的 JMeter 测试脚本文件

-l 日志文件 -> 记录结果的文件

-r 远程执行 -> 启动远程服务

-H 代理主机 -> 设置 JMeter 使用的代理主机

-P 代理端口 -> 设置 JMeter 使用的代理主机的端口号

## 三、可视化安装

因为jmeter的jmeter.sh，需要再可视化界面下才能运行，所以我在Centos安装可视化，接下来的操作都在可视化界面进行操作。

![image-20221001120546554](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210011205677.png)

```
[root@home2 bin]# yum upgrade -y
[root@home2 bin]# yum groupinstall  'Server with GUI' -y
重启后init 5开启可视化界面
[root@home2 bin]# init 5
```

![image-20221001123212365](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210011232607.png)

![image-20221001123232825](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210011232088.png)

**直接跳过在线账号连接**

![image-20221001123312259](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210011233500.png)

![image-20221001123409461](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210011234726.png)

![image-20221001123444721](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210011234965.png)

右键点击打开终端

![image-20221001123515919](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210011235305.png)

**先登录到root用户，以便后面操作不需要提权。**

![image-20221001141905435](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210011419552.png)

## 四、Jmeter的使用

**到jmeter的bin目录下输入sh jmeter.sh 启动jmeter**

![image-20221001123709512](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210011237636.png)

### 1.添加线程组

**“测试计划” -> “添加” -> “线程(用户)” -> “线程组”**

![image-20221001163544534](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210011635614.png)

这里可以配置线程组名称，线程数，准备时长（Ramp-Up Period(in seconds)）循环次数，调度器等参数： 

![image-20221001142233979](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210011422038.png)

线程组参数详解： 
1. 线程数：虚拟用户数。一个虚拟用户占用一个进程或线程。设置多少虚拟用户数在这里也就是设置多少个线程数。 
2. Ramp-Up Period(in seconds)准备时长：设置的虚拟用户数需要多长时间全部启动。如果线程数为10，准备时长为2，那么需要2秒钟启动10个线程，也就是每秒钟启动5个线程。 
3. 循环次数：每个线程发送请求的次数。如果线程数为10，循环次数为100，那么每个线程发送100次请求。总请求数为10*100=1000 。如果勾选了“永远”，那么所有线程会一直发送请求，一到选择停止运行脚本。 
4. 延迟创建线程直到（Delay Thread creation until needed）：直到需要时延迟线程的创建。 
5. 调度器：设置线程组启动的开始时间和结束时间(配置调度器时，需要勾选循环次数为永远) 
持续时间（秒）：测试持续时间，会覆盖结束时间 
启动延迟（秒）：测试延迟启动时间，会覆盖启动时间 

### 2. 添加HTTP请求

**取样器(sampler)**

**“线程组” -> “添加” -> “取样器” -> “HTTP请求”**

![image-20221001163614885](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210011636970.png)

![image-20221001171441270](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210011714335.png)

Http请求主要参数详解：

Web服务器 
协议：向目标服务器发送HTTP请求协议，可以是HTTP或HTTPS，默认为HTTP 
服务器名称或IP ：HTTP请求发送的目标服务器名称或IP 
端口号：目标服务器的端口号，默认值为80 （https的服务器端口号是443）
2.Http请求 
方法：发送HTTP请求的方法，可用方法包括GET、POST、HEAD、PUT、OPTIONS、TRACE、DELETE等。 
路径：目标URL路径（URL中去掉服务器地址、端口及参数后剩余部分） 
Content encoding ：编码方式，默认为ISO-8859-1编码，这里配置为utf-8
同请求一起发送参数 
在请求中发送的URL参数，用户可以将URL中所有参数设置在本表中，表中每行为一个参数（对应URL中的 name=value），注意参数传入中文时需要勾选“编码”

### 3. 添加察看结果树

**“线程组” -> “添加” -> “监听器” -> “察看结果树”**

![image-20221001144017479](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210011440574.png)

**点击运行，他会让我们存储.jmx文件，我们在jmeter目录新建一个data目录负责存储jmx。**

**这时，我们运行Http请求，修改响应数据格式为“HTML Source Formatted”，可以看到本次搜索返回结果页面标题为”jmeter_test_百度搜索“。**

![image-20221001172236814](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210011722897.png)

### 4 添加用户自定义变量

**“线程组” -> “添加” -> “配置元件” -> “用户定义的变量”**

![image-20221001174049652](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210011740750.png)

![image-20221001202405934](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210012024003.png)

并在HTTP请求中使用该参数，格式为：${n}

![image-20221001202426839](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210012024898.png)

### 5. 添加断言

**“HTTP请求” -> “添加”-> “断言” -> “响应断言”**

![image-20221001174748530](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210011747583.png)

![image-20221001202544990](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210012025055.png)

测试字段：文档 

模式匹配规则：包括

测试模式添加：${n}

### 6 .添加断言结果

**“HTTP请求” -> “添加”-> “监听器” -> “断言结果”**

![image-20221001175301247](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210011753302.png)

**运行一下查看结果**

![image-20221001175501344](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210011755426.png)

#### 执行性能测试

点击线程组，配置本次性能测试相关参数：线程数，循环次数，持续时间等，这里我们配置并发用户数为10，持续时间为60s

![image-20221001202818128](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210012028188.png)

### 7 .添加聚合报告

**“线程组” -> “添加” -> “监听器” -> “聚合报告”**

![image-20221001203011012](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210012030088.png)

**运行前先点击扫把清理一下之前生成的调试结果，然后再运行一遍**

![image-20221001175953970](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210011759068.png)

### 8. 分析测试报告

![image-20221001203258326](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202210012032407.png)

聚合报告参数详解：
1. Label：每个 JMeter 的 element（例如 HTTP Request）都有一个 Name 属性，这里显示的就是 Name 属性的值
2. #样本（#Samples）：请求数——表示这次测试中一共发出了多少个请求，如果模拟10个用户，每个用户迭代10次，那么这里显示100
3. 平均值（Average）：平均响应时间——默认情况下是单个 Request 的平均响应时间，当使用了 Transaction Controller 时，以Transaction 为单位显示平均响应时间
4. 中位数（Median）：也就是 50％ 用户的响应时间
5. 90%百分位（90% Line）：90％ 用户的响应时间（后面95%，99%如同）
6. 最小值（Min）：最小响应时间
7. 最大值（Max）：最大响应时间
8. 异常%（Error%）：错误率——错误请求数/请求总数
9. Throughput：吞吐量——默认情况下表示每秒完成的请求数（Request per Second），当使用了 Transaction Controller 时，也可以表示类似 LoadRunner 的 Transaction per Second 数
10. KB/Sec：每秒从服务器端接收到的数据量，相当于LoadRunner中的Throughput/Sec
