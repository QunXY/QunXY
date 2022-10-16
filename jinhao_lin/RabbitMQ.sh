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
