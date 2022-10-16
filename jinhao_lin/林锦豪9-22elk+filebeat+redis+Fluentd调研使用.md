# 2022-09-22

# 1，elk+filebeat+redis架构搭建与脚本。（梳理）

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

Kibana () {
IP=`ifconfig | grep -w broadcast | awk -F "[ ]+" '{print $3}'`
hostname=`hostname`
cd /usr/local/src
yum install -y kibana-7.7.1-x86_64.rpm
sed -i 's/#server.port: 5601/server.port: 5601/g' /etc/kibana/kibana.yml
echo $IP | xargs -i  sed -i 's/#server.host: "localhost"/server.host: "{}"/g' /etc/kibana/kibana.yml
echo $hostname | xargs -i sed -i 's/#server.name: "your-hostname"/server.name: "{}"/g' /etc/kibana/kibana.yml
echo $IP | xargs -i  sed -i 's/#elasticsearch.hosts: \["http\:\/\/localhost\:9200"\]/elasticsearch.hosts: \["http\:\/\/{}\:9200"\]/g' /etc/kibana/kibana.yml
sed -i 's/#kibana.index: ".kibana"/kibana.index: ".kibana"/g' /etc/kibana/kibana.yml
sed -i 's/#i18n.locale: "en"/i18n.locale: "zh-CN"/g' /etc/kibana/kibana.yml
systemctl  start kibana
systemctl enable  kibana

}

Filebeat () {
cd /usr/local/src
yum install -y filebeat-7.7.1-x86_64.rpm 

}

Logstash () {
cd /usr/local/src
yum install -y logstash-7.7.1.rpm
ln -s /usr/share/logstash/bin/logstash  /bin/

}

R_F_L () {
redis-server -v
if [ $? -eq 0 ]
then
	conf=`find / -name redis.conf | grep -w etc`
	Passwd=`grep -w requirepass $conf | egrep -v "^$|#" | awk -F "[requirepass ]+" '{print $2}'`
	IP=`grep -w bind $conf | egrep -v "^$|#" | awk -F "[bind ]+" '{print $2}'`
	Port=`grep -w port $conf | egrep -v "^$|#" | awk -F "[port ]+" '{print $2}'`
	logstashconf=`find / -name conf.d | grep logstash`
	filebeatconf=`find / -name filebeat.yml`
	line=`cat -n $filebeatconf | egrep -v "^$|#" | grep -w "filebeat.inputs:" | awk -F "[filebeat.inputs: ]+" '{print $2}'`
#修改filebeat配置文件
	echo $line | xargs -i sed -i "{}a - type: log\n  enabled: true\n  paths:\n    - /var/log/messages\n  fields:\n    type: system-redis-log\n  fields_under_root: true\n  tags: [\"system-redis-log\"]"  $filebeatconf
	cat >> $filebeatconf << EOF
output.redis:
  hosts: ["$IP"]
  password: "$Passwd"
  data_type: "list"
  keys:
    - key: "system-redis-log"
      when.contains:
        tags: "system-redis-log"
  db: 0
  timeout: 5
EOF
#编写logstash配置文件
	cat > $logstashconf/LRF.conf << EOF
input {
  redis {
    host => "$IP"
    port => "$Port"
    db => "0"
    password => "$Passwd"
    key => "system-redis-log"
    data_type => "list"
  }
}
output {
  if [type] == "system-redis-log"{
     elasticsearch {
       hosts => ["$IP:9200"]
       index => "system-redis-log-%{+yyyy.MM.dd}"
       }
  }
}
EOF

#启动redis,filebeat,logstash#
redis-server $conf
systemctl restart filebeat
nohup logstash -f $logstashconf/LRF.conf &

else
cd /usr/local/src
echo -e "\e[36m
_____________________________
|                            |
|        Redis安装           |	
|    请用source启动该脚本    |
|               	     |	     
|   `date "+%F|%H:%M:%S"`      |
|____________________________|
(\__/) ||               
(•ㅅ•) ||               
/ 　 づv\e[0m"
read -p "请输入你要设置的redis密码:" password
IP=`ifconfig | grep broadcast | awk -F "[ ]+" '{print $3}'`

################################安装依赖，下载redis并编译安装################################
yum install -y gcc gcc-c++ kernel-devel
yum install -y expect 
wget https://download.redis.io/releases/redis-5.0.14.tar.gz
tar -xvf redis-5.0.14.tar.gz
cd redis-5.0.14
make && make PREFIX=/usr/local/redis install

################################修改配置文件################################
mkdir /usr/local/redis/etc/
mkdir -p /data/redisdata
cp redis.conf /usr/local/redis/etc/
cd /usr/local/redis/bin/
cp redis-benchmark redis-cli redis-server /usr/bin/
Daemon=`cat /usr/local/redis/etc/redis.conf | grep -w "daemonize no"`
datadir=`cat /usr/local/redis/etc/redis.conf | grep -w  "dir"`
p=`cat /usr/local/redis/etc/redis.conf | grep -w "requirepass foobared"`
bindip=`cat /usr/local/redis/etc/redis.conf | grep -w "bind 127.0.0.1" | awk 'NR==2{print $0}'`
AOF=`cat /usr/local/redis/etc/redis.conf | grep -w "appendonly no"`
sed -i "s/$Daemon/daemonize yes/g" /usr/local/redis/etc/redis.conf
sed -i "s@$datadir@dir /data/redisdata@g" /usr/local/redis/etc/redis.conf
sed -i "s/$p/requirepass $password/g" /usr/local/redis/etc/redis.conf
sed -i "s/$bindip/bind $IP/g" /usr/local/redis/etc/redis.conf
sed -i "s/$AOF/appendonly yes/g" /usr/local/redis/etc/redis.conf

################################添加全局变量################################
cat >> /etc/profile << 'EOF'
#################Redis###################
export PATH="$PATH:/usr/local/redis/bin"
EOF
source /etc/profile

################################编写启动脚本################################
cat > redis << 'EOF'
#!/bin/bash
#chkconfig: 2345 80 90
# Simple Redis init.d script conceived to work on Linux systems
# as it does use of the /proc filesystem.

PATH=/usr/local/bin:/sbin:/usr/bin:/bin
REDISPORT=6379
EXEC=/usr/local/redis/bin/redis-server
REDIS_CLI=/usr/local/redis/bin/redis-cli
   
PIDFILE=/var/run/redis.pid
CONF="/usr/local/redis/etc/redis.conf"
   
case "$1" in
    start)
        if [ -f $PIDFILE ]
        then
                echo "$PIDFILE exists, process is already running or crashed"
        else
                echo "Starting Redis server..."
                $EXEC $CONF
        fi
        if [ "$?"="0" ] 
        then
              echo "Redis is running..."
        fi
        ;;
    stop)
        if [ ! -f $PIDFILE ]
        then
                echo "$PIDFILE does not exist, process is not running"
        else
                PID=$(cat $PIDFILE)
                echo "Stopping ..."
                $REDIS_CLI -p $REDISPORT SHUTDOWN
                while [ -x ${PIDFILE} ]
               do
                    echo "Waiting for Redis to shutdown ..."
                    sleep 1
                done
                echo "Redis stopped"
        fi
        ;;
   restart|force-reload)
        ${0} stop
        ${0} start
        ;;
  *)
    echo "Usage: /etc/init.d/redis {start|stop|restart|force-reload}" >&2
        exit 1
esac
EOF

################################将redis交给system管理################################
mv redis /etc/init.d/
chmod +x /etc/init.d/redis
chkconfig --add redis
chkconfig --level 2345 redis on
systemctl start redis 
systemctl enable redis
systemctl status redis

################################检查安装结果并返回给用户################################
redis-server -v
if [ $? -eq 0 ]
then
	echo -e "\e[32m 安装成功 \e[0m"
else
	echo -e "\e[31m 安装失败  \e[0m"
fi

conf=`find / -name redis.conf | grep -w etc`
Passwd=`grep -w requirepass $conf | egrep -v "^$|#" | awk -F "[requirepass ]+" '{print $2}'`
IP=`grep -w bind $conf | egrep -v "^$|#" | awk -F "[bind ]+" '{print $2}'`
Port=`grep -w port $conf | egrep -v "^$|#" | awk -F "[port ]+" '{print $2}'`
logstashconf=`find / -name conf.d | grep logstash`
filebeatconf=`find / -name filebeat.yml`
line=`cat -n $filebeatconf | egrep -v "^$|#" | grep -w "filebeat.inputs:" | awk -F "[filebeat.inputs: ]+" '{print $2}'`
echo $line | xargs -i sed -i "{}a - type: log\n  enabled: true\n  paths:\n    - /var/log/messages\n  fields:\n    type: system-redis-log\n  fields_under_root: true\n  tags: [\"system-redis-log\"]"  $filebeatconf
#修改filebeat配置文件
OP=`cat $filebeatconf | egrep -v "^$|#" | grep output`
sed -i "s/$OP/#$OP/g" $filebeatconf
cat >> $filebeatconf << EOF
output.redis:
  hosts: ["$IP"]
  password: "$Passwd"
  data_type: "list"
  keys:
    - key: "system-redis-log"
      when.contains:
        tags: "system-redis-log"
  db: 0
  timeout: 5
EOF
#编写logstash配置文件
cat > $logstashconf/LRF.conf << EOF
input {
  redis {
    host => "$IP"
    port => "$Port"
    db => "0"
    password => "$Passwd"
    key => "system-redis-log"
    data_type => "list"
  }
}
output {
  if [type] == "system-redis-log"{
     elasticsearch {
       hosts => ["$IP:9200"]
       index => "system-redis-log-%{+yyyy.MM.dd}"
       }
  }
}
EOF

#启动redis,filebeat,logstash#
redis-server $conf
systemctl restart filebeat
cd $logstashconf
nohup logstash -f LRF.conf &
fi

}

while true
do
echo -e "\e[36m
________________________________________________________________________________
|                            | 					 		|	
|       ElasticSearch        |                   使用手册              		|
|     1)ES集群搭建           |     默认执行脚本的主机为主节点机。1选项和2选     |
|     2)es-head功能插件	     |     项配合使用效果极佳。1选项中只需要输入节点    |
|     3)Kibana安装           |	   2和3的ip和密码。最好用source启动该脚本   	|
|     4)Filebeat安装	     |	   全部安装所需的包都在选项1ES集群搭建时	|
|     5)Logstash安装         |	   下载到/usr/local/src中了，后续选项都会	|
|     6)Redis安装+加入集群   |	   依赖与这个文件中的安装包！			|
|			     |     6选项会默认帮你获取系统日志，导入到ELK+Redis	|
|     `date "+%F|%H:%M:%S"`    |     +Filebeat中。能够自动判断你是否已经安装了    |
|  请用source指令启动该脚本  |	   redis，所以不用担心装了redis不能使用此功能   |
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
3|Kibana安装)
        Kibana;
        continue
        ;;
4|Filebeat安装)
        Filebeat;
        continue
        ;;
5|Logstash安装)
        Logstash;
        continue
        ;;
6|Redis安装+加入集群)
	R_F_L;
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

# 2，Fluentd调研使用（有兴趣和能力的可以安装做一下）

### 一、fluentd简介

**fluentd**是一个针对日志的收集、处理、转发系统。通过丰富的插件系统， 可以收集来自于各种系统或应用的日志，转化为用户指定的格式后，转发到用户所指定的日志存储系统之中。

通过 fluentd，你可以非常轻易的实现像追踪日志文件并将其过滤后转存到 MongoDB 这样的操作。fluentd 可以彻底的将你从繁琐的日志处理中解放出来。

用图来说明的话，没有使用fluentd以前，系统是这样的：

![查看源图像](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209252055639.jpeg)

用了之后：

![查看源图像](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209252055120.jpeg)

### 二、fluentd安装

home2，IP:192.168.159.137，CentOS 7.4.1708

**修改内核设置：**

```shell
[root@home2 src]#  cat << 'EOT' >> /etc/security/limits.conf
root soft nofile 65536
root hard nofile 65536
* soft nofile 65536
* hard nofile 65536
EOT
[root@home2 src]# cat << 'EOT' >> /etc/sysctl.conf
net.core.somaxconn = 1024
net.core.netdev_max_backlog = 5000
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_wmem = 4096 12582912 16777216
net.ipv4.tcp_rmem = 4096 12582912 16777216
net.ipv4.tcp_max_syn_backlog = 8096
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 10240 65535
EOT
#执行
[root@home2 src]# sysctl -p
```

**安装：**

```shell
[root@home2 src]# yum install -y nc
[root@home2 src]# curl -L https://toolbelt.treasuredata.com/sh/install-redhat-td-agent4.sh | sh
[root@home2 src]# systemctl start td-agent
[root@home2 src]# vim /etc/td-agent/td-agent.conf 
```

### 配置文件说明

- source: 定义数据源
- match: 定义数据的输出目标
- filter: 事件处理管道
- system: 设置系统范围配置
- label: 用来组织filter和match
- @include: 重用配置

### 三、测试

```html
[root@home2 src]# vim /etc/td-agent/td-agent.conf 						#尾行插入以下配置
<source>
  @type syslog
  port 5140
  bind 0.0.0.0
  tag demo
</source>

<match demo.**>
  @type file
  @id output_file
  path /var/log/td-agent/demo
</match>
```

用**netcat**网络工具执行（可执行Linux中与TCP、UDP或Unix套接字相关的任何操作）

```shell
[root@home2 src]# nc -vu 192.168.159.137 5140
Ncat: Version 7.50 ( https://nmap.org/ncat )
Ncat: Connected to 192.168.159.137:5140.
ljh													#输入数据
dly
+v
xyq
xw
qy
lz
[root@home2 src]# vim /var/log/td-agent/td-agent.log 				#查看日志
```

![image-20220925212345103](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209252123211.png)
