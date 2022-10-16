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

