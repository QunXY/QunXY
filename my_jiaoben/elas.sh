#!/bin/bash
#Elasticsearch  7.5 部署
#author:肖钰群
mydate=`date +%d/%m/%Y`
localhost=`hostname -s`
user=`whoami`
#开始循环体，ela集群搭建脚本 增加ela-head的功能插件，按[0]退出

#提前执行，防止冗余
yum -y install sshpass
clear
IP=`ifconfig | grep -w broadcast | awk -F "[ ]+" '{print $3}'`
systemctl stop firewalld
read -p "你的elk02号IP地址:" ip1
read -p "你的elk03号IP地址:" ip2
read -p "你的elk02号节点密码:" wd1
read -p "你的elk03号节点密码:" wd2
hostnamectl set-hostname elk01
clear
#
#进入循环
for ((;;)) 
do
cat <<EOF
----------------------------------------------------------------------
使用者:$user              主机名:localhost         日期：$mydate
----------------------------------------------------------------------
0 : 退出
1 : 配置Java环境
2 : ela集群搭建+ela-head的功能(本脚本实现3节点搭建,更多节点自己加循环)
3 ：配置内核参数
* : 【请确认你已经开启了另外两台节点】
-----------------------------------------------------------------------
实验环境：
CentOS7
3台节点，elk01，elk02，elk03
虚拟机内存 2G
-----------------------------------------------------------------------
EOF

echo -en "\t请选择你的功能[0,1,2,3]--->"
read choice
 case $choice in
  0)exit;;
  1)
#脚本编写
cd /usr/local/src
wget  http://192.168.1.200/rpm/jdk-8u151-linux-x64.rpm
rpm -ivh jdk-8u151-linux-x64.rpm
#本地和远程安装部署
sshpass -p$wd1 ssh -o StrictHostKeyChecking=no root@$ip1 <<EOF
cd /usr/local/src
wget  http://192.168.1.200/rpm/jdk-8u151-linux-x64.rpm
rpm -ivh jdk-8u151-linux-x64.rpm
EOF
sshpass -p$wd2 ssh -o StrictHostKeyChecking=no root@$ip2 <<EOF
cd /usr/local/src
wget  http://192.168.1.200/rpm/jdk-8u151-linux-x64.rpm
rpm -ivh jdk-8u151-linux-x64.rpm
EOF
clear
echo "JAVA环境部署完毕！请输入<2>进行ela集群部署！"
  ;;
  2)
#改内核参数
cat >>/etc/security/limits.conf<<EOF
* soft nofile 65536
* hard nofile 65536
* soft nproc 2048
* hard nproc 2048
* soft memlock unlimited
* hard memlock unlimited
EOF
#安装ElasticSearch
cd /usr/local/src
#内网下载地址
wget http://192.168.1.200/rpm/elasticsearch-7.5.1-x86_64.rpm
rpm -ivh elasticsearch-7.5.1-x86_64.rpm
#elk01配置
rm -rf /data/ela-data
mkdir -p /data/ela-data
mkdir -p /data/ela-log
chown -R elasticsearch:elasticsearch /data/ela-data/
chown -R elasticsearch:elasticsearch /data/ela-log/
cat >/etc/elasticsearch/elasticsearch.yml<<EOF
cluster.name: elk-cluster
node.master: true
node.data: true
node.name: elk01
path.data: /data/ela-data
path.logs: /data/ela-log
network.host: $IP
discovery.seed_hosts: ["$IP","$ip1","$ip2"]
cluster.initial_master_nodela: ["$IP","$ip1","$ip2"]
http.cors.enabled: true
http.cors.allow-origin: "*"
EOF

#启动服务并设置开机启动
echo "正在启动服务，请稍后..."
systemctl start elasticsearch
systemctl enable  elasticsearch
#elk02配置
sshpass -p$wd1 ssh -o StrictHostKeyChecking=no root@$ip1 <<EOF
systemctl stop firewalld
wget http://192.168.1.200/rpm/elasticsearch-7.5.1-x86_64.rpm
rpm -ivh elasticsearch-7.5.1-x86_64.rpm
echo '`cat /etc/elasticsearch/elasticsearch.yml`' >/etc/elasticsearch/elasticsearch.yml
sed -i "s/elk01/elk02/" /etc/elasticsearch/elasticsearch.yml
sed -i "s/network.host: $IP/network.host: $ip1/" /etc/elasticsearch/elasticsearch.yml
rm -rf /data/ela-data
mkdir -p /data/ela-data
mkdir -p /var/log/elasticsearch
chown -R elasticsearch:elasticsearch /data/ela-data/
chown -R elasticsearch:elasticsearch /var/log/elasticsearch/
echo "正在启动服务，请稍后..."
systemctl start elasticsearch
systemctl enable  elasticsearch
EOF
#elk03配置
sshpass -p$wd2 ssh -o StrictHostKeyChecking=no root@$ip2 <<EOF
systemctl stop firewalld
wget http://192.168.1.200/rpm/elasticsearch-7.5.1-x86_64.rpm
rpm -ivh elasticsearch-7.5.1-x86_64.rpm
echo '`cat /etc/elasticsearch/elasticsearch.yml`' >/etc/elasticsearch/elasticsearch.yml
sed -i "s/elk01/elk03/" /etc/elasticsearch/elasticsearch.yml
sed -i "s/network.host: $IP/network.host: $ip2/" /etc/elasticsearch/elasticsearch.yml
rm -rf /data/ela-data
mkdir -p /data/ela-data
mkdir -p /var/log/elasticsearch
chown -R elasticsearch:elasticsearch /data/ela-data
chown -R elasticsearch:elasticsearch /var/log/elasticsearch
echo "正在启动服务，请稍后..."
systemctl start elasticsearch
systemctl enable  elasticsearch
EOF

#配置完成！
#查看node节点是否加入节点 
clear
curl  http://$IP:9200/_cat/nodela?v
read -p "--->敲入任意键进入NODE.JS安装，部署搭建head 插件<---" tempxxx

#elk01
cd /usr/local/src
wget https://nodejs.org/dist/v10.24.0/node-v10.24.0-linux-x64.tar.xz
tar xf node-v10.24.0-linux-x64.tar.xz
mv node-v10.24.0-linux-x64 /usr/local/node-v10.24
rm -rf /usr/bin/node /usr/bin/npm
ln -s /usr/local/node-v10.24/bin/node /usr/bin/node
ln -s /usr/local/node-v10.24/bin/npm /usr/bin/npm
#此处加个判断比较好
cat >>/etc/profile<<eof
###################NODE.JS10.24################
export PATH=/usr/local/node-v10.24/bin:\$PATH
eof
source /etc/profile
#内网下载地址
yum -y install unzip bzip2
cd /data
wget http://192.168.1.200/220711-note/elasticsearch-head-master.zip -O /data/head-master.zip
rm -rf elasticsearch-head-master
unzip /data/head-master.zip
cd /data/elasticsearch-head-master
npm config set registry https://registry.npm.taobao.org
npm config set strict-ssl false
mkdir /tmp/phantomjs
wget http://192.168.1.200/220711-note/phantomjs-2.1.1-linux-x86_64.tar.bz2 -O /tmp/phantomjs/phantomjs-2.1.1-linux-x86_64.tar.bz2
npm install phantomjs-prebuilt@2.1.16 --ignore-scripts
npm install
npm run start
  ;;

  *)
  clear
  echo "别乱选 吊毛" ;;
 elaac
done
