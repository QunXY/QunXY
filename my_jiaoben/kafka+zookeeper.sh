#!/bin/bash
#Mr.xiaoyuqun
#kafka、zookeeper 集群脚本

#https://blog.csdn.net/weixin_45397785/article/details/118253978

#server01
 systemctl stop firewalld
 yum -y install sshpass
 clear
 IP=`ifconfig | grep -w broadcast | awk -F "[ ]+" '{print $3}'`
 read -p "你的二号机IP地址:" ip1
 read -p "你的三号机IP地址:" ip2
 read -p "你的二号机密码:" wd1
 read -p "你的三号机密码:" wd2
 
 #jdk安装
 cd /usr/local/src && wget http://192.168.1.200/rpm/jdk-8u151-linux-x64.rpm
 rpm -ivh jdk-8u151-linux-x64.rpm
 
 #kafka、zookeeper
 cd /usr/local/src 
 wget https://dlcdn.apache.org/zookeeper/zookeeper-3.7.1/apache-zookeeper-3.7.1-bin.tar.gz
 wget https://archive.apache.org/dist/kafka/2.8.2/kafka_2.12-2.8.2.tgz
 tar xf apache-zookeeper-3.7.1-bin.tar.gz
 tar xf kafka_2.12-2.8.2.tgz
 mv apache-zookeeper-3.7.1-bin /opt/apache-zookeeper-3.7.1
 mkdir /opt/apache-zookeeper-3.7.1/data
 mkdir /opt/apache-zookeeper-3.7.1/dataLog
 cd /opt/apache-zookeeper-3.7.1/data
 echo 1 > myid
 cp zoo_sample.cfg zoo.cfg
 
 cat >zoo.cfg<<eof
tickTime=2000
initLimit=10
syncLimit=5
clientPort=2181
dataDir=/opt/apache-zookeeper-3.7.1/data  
dataLogDir=/opt/apache-zookeeper-3.7.1/dataLog  
server.1=$IP:2888:3888  
server.2=$ip1:2888:3888
server.3=$ip2:2888:3888 
eof

chmod 777 -R /opt/apache-zookeeper-3.3.7.1
/opt/apache-zookeeper-3.3.7.1/bin/zkServer.sh start

#export ZOOKEEPER_HOME=/opt/apache-zookeeper-3.3.7.1
#export PATH=$PATH:$ZOOKEEPER_HOME/bin
#jps

#配置kafka
cd /usr/local/src
tar -xvf kafka_2.12-2.8.2.tgz
mv kafka_2.12-2.8.2.tgz /opt/kafka_2.12-2.8.2
cd /opt/kafka_2.12-2.8.2
sed -i 's/broker.id=0/broker.id=1/' /opt/kafka_2.12-2.8.2/config/server.properties
sed -i 's/log.dirs=\/tmp\/kafka-logs/log.dirs=\/kafka_2.12-2.8.2\/kafka-logs/' /opt/kafka_2.12-2.8.2/config/server.properties
sed -i "s/zookeeper.connect=localhost:2181/zookeeper.connect=$IP:2181,$ip1:2182,$ip2:2183" /opt/kafka_2.12-2.8.2/config/server.properties
mkdir /opt/kafka_2.12-2.8.2/kafka-logs
#
cat >> /etc/profile<<eof
#-------------------------kafka---------------------------
export KAFKA_HOME=/opt/kafka_2.12-2.8.2
export PATH=$PATH:$KAFKA_HOME/bin
eof
#启动
/opt/kafka_2.12-2.8.2/binkafka-server-start.sh -daemon /opt/kafka_2.12-2.8.2/config/server.properties 

#测试

#./bin/kafka-topics.sh --create --zookeeper master:2181, slave1:2182, slave2:2183 --replication-factor 3 --partitions 3 --topic test
#/kafka-topics.sh  --zookeeper localhost:2181 --list
#./kafka-console-producer.sh  --bootstrap-server master:9092 --topic test
#./kafka-console-consumer.sh --zookeeper master:2181 --topic test --from-beginning
 
