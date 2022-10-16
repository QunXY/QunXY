# 8-29作业

# 1，mha+atlas搭建以及修复脚本。

## 搭建：

```shell
#!/bin/bash
echo -e "\e[36m
____________________
|                   |
|       Atlas       |
| 		    |
|___________________|
(\__/) ||               
(•ㅅ•) ||               
/ 　 づv\e[0m"
read -p "请输入主库的主机ip" mip
read -p "请输入从库1的主机ip" sip1
read -p "请输入从库2的主机ip" sip2
read -p "请输入本机数据库密码" P
read -p "请输入你要添加的用户" user
read -p "请输入你要添加的用户的密码" password
cd /opt
wget http://192.168.1.200/rpm/Atlas-2.2.1.el6.x86_64.rpm
rpm -ivh  Atlas-2.2.1.el6.x86_64.rpm
cp /usr/local/mysql-proxy/conf/test.cnf /usr/local/mysql-proxy/conf/test.cnf.bak
echo $password | xargs -i mysql -uroot -p$P -e "grant all on *.* to $user@'%' identified by '{}';select user,host from mysql.user"
spassword=`/usr/local/mysql-proxy/bin/encrypt $password`
cat > /usr/local/mysql-proxy/conf/test.cnf << EOF
[mysql-proxy]
admin-username = user
admin-password = pwd
proxy-backend-addresses = $mip:3306
proxy-read-only-backend-addresses = $sip1:3306,$sip2:3306
pwds = $user:$spassword
daemon = true
keepalive = true
event-threads = 8
log-level = message
log-path = /usr/local/mysql-proxy/log
sql-log=ON
proxy-address = 0.0.0.0:33060
admin-address = 0.0.0.0:2345
charset=utf8
EOF
```

## 修复：

```shell
#/bin/bash
echo -e "\e[36m
____________________
|                   |
|       Atlas修复   |
| 		    |
|___________________|
(\__/) ||               
(•ㅅ•) ||               
/ 　 づv\e[0m"
newmaster=`grep "as a new master" /etc/mha/manager | tail -1 | awk -F '[ ,(]' '{print $2}'`
newmasterid=`mysql -uuser -ppwd -h127.0.0.1 -P 2345 -e "SELECT * FROM backends" | grep $newmaster | awk '{print $1}'`
mysql -uuser -ppwd -h127.0.0.1 -P 2345 -e "REMOVE BACKEND $newmasterid"
oldserver=`grep "Master .* is down" /etc/mha/manager | tail -1 | awk -F '[ ,(]' '{print $2}'`
ssh $oldserver "sh /root/Mha.sh" 
serverport=`grep "Master .* is down" /etc/mha/manager | tail -1 | awk -F '[ ,()]' '{print $3}'`
mysql -uuser -ppwd -h127.0.0.1 -P 2345 -e "add slave $serverport" 
mysql -uuser -ppwd -h127.0.0.1 -P 2345 -e "save config" 
```

# 2，mycat一键部署脚本（1，基础的读写分离功能）。

```shell
#!/bin/bash
echo -e "\e[36m
____________________
|                   |
|       MyCat       |
|                   |
|___________________|
(\__/) ||               
(•ㅅ•) ||               
/ 　 づv\e[0m"
read -p "请输入数据库账户:" user
read -p "请输入数据库密码:" password
read -p "请输入只读的ip:" IP2
read -p "请输入只读的port:" P2
read -p "请输入只写的ip:" IP1
read -p "请输入只写的port:" P1
mysql -u$user -p$password -h$IP2 -P$P2 -e "show databases;"
read -p "请输入要读写的库:" data
cd /opt
wget http://192.168.1.200/rpm/jdk-8u151-linux-x64.rpm
wget http://192.168.1.200/package/gz/Mycat-server-1.6.7.4-release-20200105164103-linux.tar.gz
rpm -ivh jdk-8u151-linux-x64.rpm
tar -xvf Mycat-server-1.6.7.4-release-20200105164103-linux.tar.gz
java -version
rm -rf jdk-8u151-linux-x64.rpm Mycat-server-1.6.7.4-release-20200105164103-linux.tar.gz
cat >> /etc/profile <<-EOF

#######################jdk################################
export JAVA_HOME=/usr/java/jdk1.8.0_151
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export PATH=$JAVA_HOME/bin:$PATH
#######################mycat################################
export PATH=/opt/mycat/bin:$PATH
EOF
source /etc/profile
ln -s /opt/mycat/bin/mycat /usr/bin/mycat

cp /opt/mycat/conf/schema.xml /opt/mycat/conf/schema.xml.bak
cat > /opt/mycat/conf/schema.xml << EOF
<?xml version="1.0"?>
<!DOCTYPE mycat:schema SYSTEM "schema.dtd">
<mycat:schema xmlns:mycat="http://io.mycat/">
<schema name="TESTDB" checkSQLschema="false" sqlMaxLimit="100" dataNode="dn1">
</schema>
    <dataNode name="dn1" dataHost="localhost1" database= "$data" />
    <dataHost name="localhost1" maxCon="1000" minCon="10" balance="1"  writeType="0" dbType="mysql"  dbDriver="native" switchType="1">
        <heartbeat>select user()</heartbeat>
    <writeHost host="db1" url="$IP1:$P1" user="$user" password="$password">
            <readHost host="db2" url="$IP2:$P2" user="$user" password="$password" />
    </writeHost>
    </dataHost>
</mycat:schema>
EOF

mycat start

mysql -uroot -p123456 -h127.0.0.1 -P8066 -e "use TESTDB;show tables;"
```

# 3，tikv调研以及部署使用（时间延期到数据库结课）。

TiKV 提供 raw 和 ACID 兼容的事务键值 API，广泛应用于在线服务服务，例如对象存储服务的元数据存储系统、推荐系统的存储系统、[在线特征存储](https://www.featurestore.org/)等。

TiKV 也被广泛用作数据库管理系统的存储层，例如：

- [TiDB](https://github.com/pingcap/tidb)：一个开源 MySQL 兼容的 NewSQL 数据库，支持混合事务和分析处理 (HTAP) 工作负载。
- [Zetta](https://github.com/zhihu/zetta)：一个开源 NoSQL 数据库，支持事务和 Cloud Spanner 等 API。
- [Tidis](https://github.com/yongman/tidis)：一个分布式 NoSQL 数据库，提供 Redis 协议 API（字符串、列表、哈希、集合、排序集），用 Go 编写。
- [Titan](https://github.com/distributedio/titan)：基于 TiKV 的 Redis 兼容层的分布式实现。
- [JuiceFS](https://github.com/juicedata/juicefs)：基于 TiKV 和 S3 的开源 POSIX 文件系统。

![image-20220910163812676](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209101638793.png)

TiKV优点:

**低延迟且稳定：**RawKV 的平均响应时间小于 1 毫秒（P99=10 毫秒）。

**高扩展性：**借助[Placement Driver](https://tikv.org/docs/5.1/reference/architecture/terminology/#placement-driver-pd)和精心设计的[Raft](https://raft.github.io/)组，TiKV 在水平可扩展性方面表现出色，可以轻松扩展到 100+ TB 的数据。横向扩展您的 TiKV 集群以适应数据大小的增长，而不会对应用程序产生任何影响。

**便于使用：**运行一个命令来部署一个包含生产环境所需的一切的 TiKV 集群。[使用TiUP](https://tikv.org/docs/5.1/reference/tiup/)或 TiKV 算子在集群中轻松扩展或扩展。

**易于维护：**TiKV 基于[Google Spanner](https://research.google/pubs/pub39966/)和[HBase](https://hbase.apache.org/)的设计，但管理更简单，不依赖任何分布式文件系统。

**一致的分布式事务：**与 Google 的[Spanner](https://research.google/pubs/pub39966/)类似，TiKV（TxnKV 模式）支持外部一致的分布式事务。

**可调节的一致性：**在 RawKV 和 TxnKV 模式下，您可以自定义一致性和性能之间的平衡。



## 部署Tikv

```shell
[root@home2 opt]# curl --proto '=https' --tlsv1.2 -sSf https://tiup-mirrors.pingcap.com/install.sh | sh
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 6971k  100 6971k    0     0  7371k      0 --:--:-- --:--:-- --:--:-- 7369k
WARN: adding root certificate via internet: https://tiup-mirrors.pingcap.com/root.json
You can revoke this by remove /root/.tiup/bin/7b8e153f2e2d0928.root.json
Successfully set mirror to https://tiup-mirrors.pingcap.com
Detected shell: bash
Shell profile:  /root/.bash_profile
/root/.bash_profile has been modified to add tiup to PATH
open a new terminal or source /root/.bash_profile to use it
Installed path: /root/.tiup/bin/tiup
===============================================
Have a try:     tiup playground
===============================================
[root@home2 opt]# source /root/.bash_profile
#查看版本决定下面用的启动命令
[root@home2 opt]# tiup -v
1.10.3 tiup
Go Version: go1.18.5
Git Ref: v1.10.3
GitHash: e198ac54996fa5a29f1961a460d6634ee9e75d26
#版本 >= 1.5.2：
[root@home2 opt]# tiup playground --mode tikv-slim
#版本 < 1.5.2：		
[root@home2 opt]# tiup playground					#我的是小于1.5.2的
```

![image-20220910171312115](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209101713216.png)

## 登录到Tidb数据库

```shell
[root@home2 ~]# mysql --comments --host 127.0.0.1 --port 4000 -u root -p
Enter password: 
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 407
Server version: 5.7.25-TiDB-v6.2.0 TiDB Server (Apache License 2.0) Community Edition, MySQL 5.7 compatible

Copyright (c) 2000, 2022, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| INFORMATION_SCHEMA |
| METRICS_SCHEMA     |
| PERFORMANCE_SCHEMA |
| mysql              |
| test               |
+--------------------+
5 rows in set (0.01 sec)
```

**部署成功**

**可以登陆 http://127.0.0.1:3000 监控tikv状态**