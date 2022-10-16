# 2022-09-20

# 1，es集群搭建脚本增加es-head的功能插件

```shell
#!/bin/bash
ES (){
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
        echo "公钥存在,现在分别发送给Real Server和Director备用机"
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
        echo "公钥不存在，现在创建并分别发送给Real Server和Director备用机"
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

####下载elk集群需要的安装包,并分发给其他节点,配置主节点####
cd /usr/local/src
wget http://192.168.1.200/rpm/elk-package.zip
unzip elk-package.zip
wget  http://192.168.1.200/rpm/jdk-8u151-linux-x64.rpm
rpm -ivh jdk-8u151-linux-x64.rpm
cat >> /etc/profile << 'EOF'

#######################jdk################################
export JAVA_HOME=/usr/java/jdk1.8.0_151
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export PATH=$JAVA_HOME/bin:$PATH
EOF
cat >> /etc/security/limits.conf <<EOF
*                soft    nofile          65536
*                hard    nofile          65536
*                soft    nproc           2048
*                hard    nproc           2048
*                soft    memlock         unlimited
*                hard    memlock         unlimited
EOF
source /etc/profile
source /etc/security/limits.conf
yum install -y elasticsearch-7.7.1-x86_64.rpm
mkdir -p /data/es-data
chown -R elasticsearch:elasticsearch /data/es-data
chown -R elasticsearch:elasticsearch /var/log/elasticsearch/
cat > /etc/elasticsearch/elasticsearch.yml << EOF
# ======================== Elasticsearch Configuration =========================
#
# NOTE: Elasticsearch comes with reasonable defaults for most settings.
#       Before you set out to tweak and tune the configuration, make sure you
#       understand what are you trying to accomplish and the consequences.
#
# The primary way of configuring a node is via this file. This template lists
# the most important settings you may want to configure for a production cluster.
#
# Please consult the documentation for further information on configuration options:
# https://www.elastic.co/guide/en/elasticsearch/reference/index.html
#
# ---------------------------------- Cluster -----------------------------------
#
# Use a descriptive name for your cluster:
#
cluster.name: elk-cluster
#
# ------------------------------------ Node ------------------------------------
#
# Use a descriptive name for the node:
#
node.name: $hostname1
#
# Add custom attributes to the node:
#
#node.attr.rack: r1
#
# ----------------------------------- Paths ------------------------------------
#
# Path to directory where to store the data (separate multiple locations by comma):
#
path.data: /data/es-data
#
# Path to log files:
#
path.logs: /var/log/elasticsearch
#
# ----------------------------------- Memory -----------------------------------
#
# Lock the memory on startup:
#
#bootstrap.memory_lock: true
#
# Make sure that the heap size is set to about half the memory available
# on the system and that the owner of the process is allowed to use this
# limit.
#
# Elasticsearch performs poorly when the system is swapping the memory.
#
# ---------------------------------- Network -----------------------------------
#
# Set the bind address to a specific IP (IPv4 or IPv6):
#
network.host: $node1
#
# Set a custom port for HTTP:
#
http.port: 9200
#
# For more information, consult the network module documentation.
#
# --------------------------------- Discovery ----------------------------------
#
# Pass an initial list of hosts to perform discovery when this node is started:
# The default list of hosts is ["127.0.0.1", "[::1]"]
#
discovery.seed_hosts: ["$node1", "$node2", "$node3"]
#
# Bootstrap the cluster using an initial set of master-eligible nodes:
#
cluster.initial_master_nodes: ["$hostname1", "$hostname2", "$hostname3"]
#
# For more information, consult the discovery and cluster formation module documentation.
#
# ---------------------------------- Gateway -----------------------------------
#
# Block initial recovery after a full cluster restart until N nodes are started:
#
#gateway.recover_after_nodes: 3
#
# For more information, consult the gateway module documentation.
#
# ---------------------------------- Various -----------------------------------
#
# Require explicit names when deleting indices:
#
http.cors.enabled: true
http.cors.allow-origin: "*"
#action.destructive_requires_name: true
EOF
systemctl start elasticsearch

####开始配置其他节点####
scp -r /usr/local/src/elk-package.zip root@$node2:/usr/local/src
scp -r /usr/local/src/jdk-8u151-linux-x64.rpm root@$node2:/usr/local/src
scp -r /usr/local/src/elk-package.zip root@$node3:/usr/local/src
scp -r /usr/local/src/jdk-8u151-linux-x64.rpm root@$node3:/usr/local/src

#node2
ssh -t root@$node2 << eof
cd /usr/local/src/
unzip elk-package.zip
rpm -ivh jdk-8u151-linux-x64.rpm
cat >> /etc/profile << 'EOF'

#######################jdk################################
export JAVA_HOME=/usr/java/jdk1.8.0_151
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export PATH=$JAVA_HOME/bin:$PATH
EOF
cat >> /etc/security/limits.conf <<EOF
*                soft    nofile          65536
*                hard    nofile          65536
*                soft    nproc           2048
*                hard    nproc           2048
*                soft    memlock         unlimited
*                hard    memlock         unlimited
EOF
source /etc/profile
source /etc/security/limits.conf
mkdir -p /data/es-data
yum install -y elasticsearch-7.7.1-x86_64.rpm
chown -R elasticsearch:elasticsearch /data/es-data
chown -R elasticsearch:elasticsearch /var/log/elasticsearch/
eof
scp -r /etc/elasticsearch/elasticsearch.yml root@$node2:/etc/elasticsearch/elasticsearch.yml
ssh -t root@$node2 << eof
cat >> /etc/hosts <<EOF
$node1 $hostname1
$node2 $hostname2
$node3 $hostname3
EOF
sed -i 's/network.host: $node1/network.host: $node2/g' /etc/elasticsearch/elasticsearch.yml
sed -i 's/node.name: $hostname1/node.name: $hostname2/g' /etc/elasticsearch/elasticsearch.yml
systemctl start elasticsearch
eof

#node3
ssh -t root@$node3 << eof
cd /usr/local/src/
unzip elk-package.zip
rpm -ivh jdk-8u151-linux-x64.rpm
cat >> /etc/profile << 'EOF'

#######################jdk################################
export JAVA_HOME=/usr/java/jdk1.8.0_151
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export PATH=$JAVA_HOME/bin:$PATH
EOF
cat >> /etc/security/limits.conf <<EOF
*                soft    nofile          65536
*                hard    nofile          65536
*                soft    nproc           2048
*                hard    nproc           2048
*                soft    memlock         unlimited
*                hard    memlock         unlimited
EOF
source /etc/profile
source /etc/security/limits.conf
mkdir -p /data/es-data
yum install -y elasticsearch-7.7.1-x86_64.rpm
chown -R elasticsearch:elasticsearch /data/es-data
chown -R elasticsearch:elasticsearch /var/log/elasticsearch/
eof
scp -r /etc/elasticsearch/elasticsearch.yml root@$node3:/etc/elasticsearch/elasticsearch.yml
ssh -t root@$node3 << eof
cat >> /etc/hosts <<EOF
$node1 $hostname1
$node2 $hostname2
$node3 $hostname3
EOF
sed -i 's/network.host: $node1/network.host: $node3/g' /etc/elasticsearch/elasticsearch.yml
sed -i 's/node.name: $hostname1/node.name: $hostname3/g' /etc/elasticsearch/elasticsearch.yml
systemctl start elasticsearch
eof

}

es_head () {
yum install -y bzip2
cd /usr/local/src
wget http://192.168.1.200/220711-note/node-v10.24.0-linux-x64.tar.gz
tar -xf node-v10.24.0-linux-x64.tar.gz
mv node-v10.24.0-linux-x64  /usr/local/node
cat >> /etc/profile << 'EOF'
####################node########################
export NODE_HOME=/usr/local/node
export PATH=$NODE_HOME/bin:$PATH
EOF
source  /etc/profile
cd /usr/local/src
wget http://192.168.1.200/220711-note/elasticsearch-head-master.zip
unzip elasticsearch-head-master.zip
cd elasticsearch-head-master/
npm config set registry https://registry.npm.taobao.org
npm config set strict-ssl false
mkdir /tmp/phantomjs
wget http://192.168.1.200/220711-note/phantomjs-2.1.1-linux-x86_64.tar.bz2 -O /tmp/phantomjs/phantomjs-2.1.1-linux-x86_64.tar.bz2
npm install phantomjs-prebuilt@2.1.16 --ignore-scripts
npm install
echo -e "\e[33melasticsearch-head-master部署成功，请到/usr/local/src/elasticsearch-head-master目录下使用npm run start 命令启动前端程序\e[0m"
echo -e "\e[33m 如果连接不到节点，请先重启全部集群节点再启动head-master。\e[0m"

}





while true
do
echo -e "\e[36m
________________________________________________________________________________
|                            | 					 		|	
|       ElasticSearch        |                   使用手册              		|
|     1)ES集群搭建           |     默认执行脚本的主机为主节点机。1选项和2选     |
|     2)es-head功能插件	     |     项配合使用效果极佳。1选项中只需要输入节点    |
|            	             |	   2和3的ip和密码。最好用source启动该脚本   	|
|     `date "+%F|%H:%M:%S"`    |                                    		|
|  请用source指令启动该脚本  |	              					|
|  9.退出程序                |					 		|
|____________________________|__________________________________________________|
(\__/) ||                   
(•ㅅ•) ||               
/ 　 づv\e[0m"
read -p "请输入你的指示:" I
case $I in
1|ES集群搭建)
	ES;
	continue
	;;
2|es-head功能插件)
        es_head;
        continue
        ;;
9|退出程序)
	echo "谢谢使用"
	break
	;;
	*)
	exit
	esac
done
```

# 2，练习es集群种插入数据，可以通过curl或者head插件插入数据，研究下如何插入时增加分片等功能。

分片：

一.生成数据

两种方法：

1.curl

```
curl -XPOST '192.168.159.137:9200/class/student/1' -H 'Content-Type: application/json' -d '{ "name" : "natasha","age": "34","hobby" : [ "sports", "music" ]}'
```

2.elasticsearch-head-master进入网页选择复合查询生成

![image-20220920201743866](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209232253228.png)

输入文件栏输入class/student/1

命令行输入{ "name" : "natasha","age": "34","hobby" : [ "sports", "music" ]}

![image-20220920202034897](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209232253357.png)

提交请求后生成了数据

然后返回概览刷新一下

![image-20220920202214250](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209232253213.png)

就会出现了

