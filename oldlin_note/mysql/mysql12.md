## 使用mycat实现mysql分库分表

### 1.mycat准备如以下图架构：

![image-20220507141912731](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205071419818.png)

​		 **简易说明：**
​			**<font color='red'>双箭头为互为主从结构。</font>**
​			**<font color='red'>单箭头为主从结构。</font>**

#### 1.1、实验环境

| 主机名  |       IP        | 端口号 | server-id |     身份     |
| :-----: | :-------------: | :----: | :-------: | :----------: |
| mysql7  | 192.168.188.128 |  3307  |     7     | master,slave |
| mysql7  | 192.168.188.128 |  3308  |     8     | master,slave |
| mysql7  | 192.168.188.128 |  3309  |     9     |    slave     |
| mysql7  | 192.168.188.128 |  3310  |    10     |    slave     |
| mysql8  | 192.168.188.129 |  3307  |    17     | master,slave |
| mysql8  | 192.168.188.129 |  3308  |    18     | master,slave |
| mysql8  | 192.168.188.129 |  3309  |    19     |    slave     |
| mysql8  | 192.168.188.129 |  3310  |    20     |    slave     |
| mysql03 | 192.168.188.130 |  8066  |     -     |    mycat     |



#### 		1.2、备份原配置文件

```shell
[root@mysql7 ~]# mv /etc/my.cnf /etc/my.cnf.bak   #根据前文可以知道启动数据库环境变量先找它，要把它先搞掉
```

#### 1.3、关闭所有机子原有的MySQL服务

```shell
systemctl stop mysqld
systemctl status mysqld
```



### 2. 创建相关目录初始化数据

**所有作为主从机子都要操作**

```shell
mkdir -p /data/33{07..10}/data   #创建目录
```

```shell
#初始化
mysqld --initialize-insecure  --user=mysql --basedir=/usr/local/mysql --datadir=/data/3307/data

mysqld --initialize-insecure  --user=mysql --basedir=/usr/local/mysql --datadir=/data/3308/data

mysqld --initialize-insecure  --user=mysql --basedir=/usr/local/mysql --datadir=/data/3309/data

mysqld --initialize-insecure  --user=mysql --basedir=/usr/local/mysql --datadir=/data/3310/data
```

```shell
chkconfig  --del mysqld   #取消centos6的服务启动方式，之前我是这样设置启动方式
```



### 3. 准备配置文件和启动脚本

**注：**

1. **<font color='red'>根据上面配置主从如果采用的是binlog的形式搭建主从，会发现在mysql7的3307创建的库能同步到同机子的3309，也能同步到</font><font color='red'>mysql8的3307却不能同步到mysql8的3309。同理在mysql8创建，mysql7的3309也是没有同步到。原因就是中继日志并没有</font><font color='red'>写进binlog日志，所以无法同步。下面我采用的是基于gtid搭建的主从。</font>**
2. **<font color='red'>log-slave-updates=1    #互为主从必须加这一选项</font>**

#### mysql7

```shell
[root@mysql7 ~]# cat > /data/3307/my.cnf << EOF
[mysqld]
basedir=/usr/local/mysql
datadir=/data/3307/data
socket=/data/3307/mysql.sock
port=3307
log-error=/data/3307/mysql.log
log_bin=/data/3307/mysql-bin
binlog_format=row
server-id=7
gtid-mode=on
enforce-gtid-consistency=true
log-slave-updates=1   #互为主从必须加这一选项
EOF
```

```shell
[root@mysql7 ~]# cat > /data/3308/my.cnf << EOF
[mysqld]
basedir=/usr/local/mysql
datadir=/data/3308/data
port=3308
socket=/data/3308/mysql.sock
log-error=/data/3308/mysql.log
log_bin=/data/3308/mysql-bin
binlog_format=row
server-id=8
gtid-mode=on
enforce-gtid-consistency=true
log-slave-updates=1   #互为主从必须加这一选项
EOF
```

```shell
[root@mysql7 ~]# cat > /data/3309/my.cnf << EOF
[mysqld]
basedir=/usr/local/mysql
datadir=/data/3309/data
socket=/data/3309/mysql.sock
port=3309
log-error=/data/3309/mysql.log
log_bin=/data/3309/mysql-bin
binlog_format=row
server-id=9
gtid-mode=on
enforce-gtid-consistency=true
log-slave-updates=1   #互为主从必须加这一选项
EOF
```

```shell
[root@mysql7 ~]# cat > /data/3310/my.cnf << EOF
[mysqld]
basedir=/usr/local/mysql
datadir=/data/3310/data
socket=/data/3310/mysql.sock
port=3310
log-error=/data/3310/mysql.log
log_bin=/data/3310/mysql-bin
binlog_format=row
server-id=10
gtid-mode=on
enforce-gtid-consistency=true
log-slave-updates=1   #互为主从必须加这一选项
EOF
```



**创建systemd启动脚本**

```shell
[root@mysql7 ~]# vim /etc/systemd/system/mysqld.service
[Unit]
Description=MySQL Server
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target
[Install]
WantedBy=multi-user.target
[Service]
User=mysql
Group=mysql
ExecStart=/xxx/bin/mysqld --defaults-file=/etc/my.cnf
LimitNOFILE = 5000
```

```shell
[root@mysql7 ~]# cd /etc/systemd/system
[root@mysql7 system]# cp mysqld.service mysqld3307.service
[root@mysql7 system]# cp mysqld.service mysqld3308.service
[root@mysql7 system]# cp mysqld.service mysqld3309.service
[root@mysql7 system]# cp mysqld.service mysqld3310.service
```

```shell
[root@mysql7 system]# sed -i 's#ExecStart=/xxx/bin/mysqld --defaults-file=/etc/my.cnf#ExecStart=/usr/local/mysql/bin/mysqld  --defaults-file=/data/3307/my.cnf#' mysqld3307.service
[root@mysql7 system]# sed -i 's#ExecStart=/xxx/bin/mysqld --defaults-file=/etc/my.cnf#ExecStart=/usr/local/mysql/bin/mysqld  --defaults-file=/data/3308/my.cnf#' mysqld3308.service
[root@mysql7 system]# sed -i 's#ExecStart=/xxx/bin/mysqld --defaults-file=/etc/my.cnf#ExecStart=/usr/local/mysql/bin/mysqld  --defaults-file=/data/3309/my.cnf#' mysqld3309.service
[root@mysql7 system]# sed -i 's#ExecStart=/xxx/bin/mysqld --defaults-file=/etc/my.cnf#ExecStart=/usr/local/mysql/bin/mysqld  --defaults-file=/data/3310/my.cnf#' mysqld3310.service
```



#### mysql8

```shell
cat > /data/3307/my.cnf << EOF
[mysqld]
basedir=/usr/local/mysql
datadir=/data/3307/data
socket=/data/3307/mysql.sock
port=3307
log-error=/data/3307/mysql.log
log_bin=/data/3307/mysql-bin
binlog_format=row
server-id=17
gtid-mode=on
enforce-gtid-consistency=true
log-slave-updates=1
EOF
```

```shell
cat > /data/3308/my.cnf << EOF
[mysqld]
basedir=/usr/local/mysql
datadir=/data/3308/data
port=3308
socket=/data/3308/mysql.sock
log-error=/data/3308/mysql.log
log_bin=/data/3308/mysql-bin
binlog_format=row
server-id=18
gtid-mode=on
enforce-gtid-consistency=true
log-slave-updates=1
EOF
```

```shell
cat > /data/3309/my.cnf << EOF
[mysqld]
basedir=/usr/local/mysql
datadir=/data/3309/data
socket=/data/3309/mysql.sock
port=3309
log-error=/data/3309/mysql.log
log_bin=/data/3309/mysql-bin
binlog_format=row
server-id=19
gtid-mode=on
enforce-gtid-consistency=true
log-slave-updates=1
EOF
```

```shell
cat > /data/3310/my.cnf << EOF
[mysqld]
basedir=/usr/local/mysql
datadir=/data/3310/data
socket=/data/3310/mysql.sock
port=3310
log-error=/data/3310/mysql.log
log_bin=/data/3310/mysql-bin
binlog_format=row
skip-name-resolve
server-id=20
gtid-mode=on
enforce-gtid-consistency=true
log-slave-updates=1
EOF
```



**创建systemd启动脚本**

```shell
[root@mysql8 ~]# vim /etc/systemd/system/mysqld.service
[Unit]
Description=MySQL Server
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target
[Install]
WantedBy=multi-user.target
[Service]
User=mysql
Group=mysql
ExecStart=/xxx/bin/mysqld --defaults-file=/etc/my.cnf
LimitNOFILE = 5000
```

```shell
[root@mysql8 ~]# cd /etc/systemd/system
[root@mysql8 system]# cp mysqld.service mysqld3307.service
[root@mysql8 system]# cp mysqld.service mysqld3308.service
[root@mysql8 system]# cp mysqld.service mysqld3309.service
[root@mysql8 system]# cp mysqld.service mysqld3310.service
```

```shell
[root@mysql8 system]# sed -i 's#ExecStart=/xxx/bin/mysqld --defaults-file=/etc/my.cnf#ExecStart=/usr/local/mysql/bin/mysqld  --defaults-file=/data/3307/my.cnf#' mysqld3307.service
[root@mysql8 system]# sed -i 's#ExecStart=/xxx/bin/mysqld --defaults-file=/etc/my.cnf#ExecStart=/usr/local/mysql/bin/mysqld  --defaults-file=/data/3308/my.cnf#' mysqld3308.service
[root@mysql8 system]# sed -i 's#ExecStart=/xxx/bin/mysqld --defaults-file=/etc/my.cnf#ExecStart=/usr/local/mysql/bin/mysqld  --defaults-file=/data/3309/my.cnf#' mysqld3309.service
[root@mysql8 system]# sed -i 's#ExecStart=/xxx/bin/mysqld --defaults-file=/etc/my.cnf#ExecStart=/usr/local/mysql/bin/mysqld  --defaults-file=/data/3310/my.cnf#' mysqld3310.service
```



### 4.配置host文件

```shell
#所有机子都要操作		#如果mycat机子上不写，启动非常缓慢
#分别在集群机器上执行

cat >>/etc/hosts << EOF
192.168.245.147 mysql6
192.168.245.148 mysql7
192.168.245.149 mycat
EOF
```



### 5.修改权限，启动多实例

```shell
chown -R mysql.mysql /data/*
systemctl daemon-reload
systemctl start mysqld3307.service
systemctl start mysqld3308.service
systemctl start mysqld3309.service
systemctl start mysqld3310.service
netstat -lnp|grep 330*
```

```shell
mysql -uroot -S /data/3307/mysql.sock -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '123456';"
mysql -uroot -S /data/3308/mysql.sock -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '123456';"
mysql -uroot -S /data/3309/mysql.sock -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '123456';"
mysql -uroot -S /data/3310/mysql.sock -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '123456';"
```



### 6.开始配置主从环境

#### 红色集群

```shell
# mysql7

#用于配置主从的用户
mysql -uroot -p123456  -S /data/3307/mysql.sock -e "grant replication slave on *.* to repl_user@'%' identified by '123456';"
mysql -uroot -p123456 -S /data/3307/mysql.sock -e 'flush privileges;'

#用于mycat远程连接的用户
mysql -uroot -p123456  -S /data/3307/mysql.sock -e "grant all  on *.* to root@'%' identified by '123456';"
mysql -uroot -p123456 -S /data/3307/mysql.sock -e 'flush privileges;'
```

```shell
# mysql8
mysql -uroot -p123456 -S /data/3307/mysql.sock -e"CHANGE MASTER TO MASTER_HOST='mysql7',MASTER_USER='repl_user',MASTER_PASSWORD='123456',MASTER_PORT=3307,MASTER_AUTO_POSITION=1,MASTER_CONNECT_RETRY=10; "

#CHANGE MASTER TO
#    -> MASTER_HOST='mysql7',
#    -> MASTER_PORT=3307,
#    -> MASTER_USER='repl_user',
#    -> MASTER_PASSWORD='123456',
#    -> MASTER_AUTO_POSITION=1,
#   -> MASTER_CONNECT_RETRY=10; 


mysql -uroot -p123456 -S /data/3307/mysql.sock -e "start slave;"

mysql -uroot -p123456 -S /data/3307/mysql.sock -e "show slave status\G"
```

```shell
# mysql7

mysql -uroot -p123456 -S /data/3307/mysql.sock -e "CHANGE MASTER TO MASTER_HOST='mysql8',MASTER_USER='repl_user',MASTER_PASSWORD='123456',MASTER_PORT=3307,MASTER_AUTO_POSITION=1,MASTER_CONNECT_RETRY=10; "

#CHANGE MASTER TO
#    -> MASTER_HOST='mysql8',
#    -> MASTER_PORT=3307,
#    -> MASTER_USER='repl_user',
#    -> MASTER_PASSWORD='123456',
#    -> MASTER_AUTO_POSITION=1,
#    -> MASTER_CONNECT_RETRY=10; 


mysql -uroot -p123456 -S /data/3307/mysql.sock -e "start slave;"

mysql -uroot -p123456 -S /data/3307/mysql.sock -e "show slave status\G"
```

```shell
# mysql7
mysql -uroot -p123456 -S /data/3309/mysql.sock -e"CHANGE MASTER TO MASTER_HOST='mysql7',MASTER_USER='repl_user',MASTER_PASSWORD='123456',MASTER_PORT=3307,MASTER_AUTO_POSITION=1,MASTER_CONNECT_RETRY=10; "

#CHANGE MASTER TO
#    -> MASTER_HOST='mysql7',
#    -> MASTER_PORT=3307,
#    -> MASTER_USER='repl_user',
#    -> MASTER_PASSWORD='123456',
#    -> MASTER_AUTO_POSITION=1,
#    -> MASTER_CONNECT_RETRY=10; 


mysql -uroot -p123456 -S /data/3309/mysql.sock -e "start slave;"

mysql -uroot -p123456 -S /data/3309/mysql.sock -e "show slave status\G"
```

```shell
# mysql8
mysql -uroot -p123456 -S /data/3309/mysql.sock -e "CHANGE MASTER TO MASTER_HOST='mysql8',MASTER_USER='repl_user',MASTER_PASSWORD='123456',MASTER_PORT=3307,MASTER_AUTO_POSITION=1,MASTER_CONNECT_RETRY=10; "

#CHANGE MASTER TO
#    -> MASTER_HOST='mysql8',
#    -> MASTER_PORT=3307,
#    -> MASTER_USER='repl_user',
#    -> MASTER_PASSWORD='123456',
#    -> MASTER_AUTO_POSITION=1,
#    -> MASTER_CONNECT_RETRY=10; 


mysql -uroot -p123456 -S /data/3309/mysql.sock -e "start slave;"

mysql -uroot -p123456 -S /data/3309/mysql.sock -e "show slave status\G"
```

#### 蓝色集群

```shell
# mysql7

#用于配置主从的用户
mysql -uroot -p123456  -S /data/3308/mysql.sock -e "grant replication slave on *.* to repl_user@'%' identified by '123456';"
mysql -uroot -p123456 -S /data/3307/mysql.sock -e 'flush privileges;'

#用于mycat远程连接的用户
mysql -uroot -p123456  -S /data/3308/mysql.sock -e "grant all  on *.* to root@'%' identified by '123456';"
mysql -uroot -p123456 -S /data/3308/mysql.sock -e 'flush privileges;'
```

```shell
# mysql8

mysql -uroot -p123456 -S /data/3308/mysql.sock -e"CHANGE MASTER TO MASTER_HOST='mysql7',MASTER_USER='repl_user',MASTER_PASSWORD='123456',MASTER_PORT=3308,MASTER_AUTO_POSITION=1,MASTER_CONNECT_RETRY=10; "

#CHANGE MASTER TO
#    -> MASTER_HOST='mysql7',
#    -> MASTER_PORT=3308,
#    -> MASTER_USER='repl_user',
#    -> MASTER_PASSWORD='123456',
#    -> MASTER_AUTO_POSITION=1,
#    -> MASTER_CONNECT_RETRY=10; 


mysql -uroot -p123456 -S /data/3308/mysql.sock -e "start slave;"

mysql -uroot -p123456 -S /data/3308/mysql.sock -e "show slave status\G"
```

```shell
# mysql7
mysql -uroot -p123456 -S /data/3308/mysql.sock -e"CHANGE MASTER TO MASTER_HOST='mysql8',MASTER_USER='repl_user',MASTER_PASSWORD='123456',MASTER_PORT=3308,MASTER_AUTO_POSITION=1,MASTER_CONNECT_RETRY=10; "

#CHANGE MASTER TO
#    -> MASTER_HOST='mysql8',
#    -> MASTER_PORT=3308,
#    -> MASTER_USER='repl_user',
#    -> MASTER_PASSWORD='123456',
#    -> MASTER_AUTO_POSITION=1,
#    -> MASTER_CONNECT_RETRY=10; 


mysql -uroot -p123456 -S /data/3308/mysql.sock -e "start slave;"

mysql -uroot -p123456 -S /data/3308/mysql.sock -e "show slave status\G"
```

```shell
# mysql8
mysql -uroot -p123456 -S /data/3310/mysql.sock -e"CHANGE MASTER TO MASTER_HOST='mysql8',MASTER_USER='repl_user',MASTER_PASSWORD='123456',MASTER_PORT=3308,MASTER_AUTO_POSITION=1,MASTER_CONNECT_RETRY=10; "

#CHANGE MASTER TO
#    -> MASTER_HOST='mysql8',
#    -> MASTER_PORT=3308,
#    -> MASTER_USER='repl_user',
#    -> MASTER_PASSWORD='123456',
#    -> MASTER_AUTO_POSITION=1,
#    -> MASTER_CONNECT_RETRY=10; 


mysql -uroot -p123456 -S /data/3310/mysql.sock -e "start slave;"

mysql -uroot -p123456 -S /data/3310/mysql.sock -e "show slave status\G"
```

```shell
# mysql7
mysql -uroot -p123456 -S /data/3310/mysql.sock -e"CHANGE MASTER TO MASTER_HOST='mysql7',MASTER_USER='repl_user',MASTER_PASSWORD='123456',MASTER_PORT=3308,MASTER_AUTO_POSITION=1,MASTER_CONNECT_RETRY=10; "


#CHANGE MASTER TO
#    -> MASTER_HOST='mysql7',
#    -> MASTER_PORT=3308,
#    -> MASTER_USER='repl_user',
#    -> MASTER_PASSWORD='123456',
#    -> MASTER_AUTO_POSITION=1,
#    -> MASTER_CONNECT_RETRY=10; 


mysql -uroot -p123456 -S /data/3310/mysql.sock -e "start slave;"

mysql -uroot -p123456 -S /data/3310/mysql.sock -e "show slave status\G"
```



### 7.检测主从状态

两台机子都操作

```shell
mysql -uroot -S /data/3307/mysql.sock -p123456 -e "show slave status\G" |grep -i running
mysql -uroot -S /data/3308/mysql.sock -p123456 -e "show slave status\G" |grep -i running
mysql -uroot -S /data/3309/mysql.sock -p123456 -e "show slave status\G" |grep -i running
mysql -uroot -S /data/3310/mysql.sock -p123456 -e "show slave status\G" |grep -i running
```

注：如果中间出现错误，在每个节点进行执行以下命令，从步骤5从头执行

```shell
mysql -uroot -S /data/3307/mysql.sock -p123456 -e "stop slave; reset slave all;"
mysql -uroot -S /data/3308/mysql.sock -p123456 -e "stop slave; reset slave all;"
mysql -uroot -S /data/3309/mysql.sock -p123456 -e "stop slave; reset slave all;"
mysql -uroot -S /data/3310/mysql.sock -p123456 -e "stop slave; reset slave all;"
```



### 8.配置java

上传安装包到mysql03的/opt/下

#### 8.1.清理原环境的java：

```shell
[root@mysql03 ~]# rpm -qa | grep java
[root@mysql03 ~]# rpm -qa | grep jdk
```

如果有，yum remove相关包



#### 8.2.安装java环境：

```shell
[root@mysql03 ~]# cd /opt/
[root@mysql03 opt]# tar zxf jdk-8u191-linux-x64.tar.gz 
[root@mysql03 opt]# mv ./jdk1.8.0_191   /usr/java
```



#### 8.3.设置java环境变量:

```shell
[root@mysql03 ~]# vim /etc/profile
#最后一行添加：
export JAVA_HOME=/usr/java
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export PATH=$JAVA_HOME/bin:$PATH

[root@mysql03 ~]# source !$
```

验证

```shell
[root@mysql03 opt]# java -version
java version "1.8.0_191"
Java(TM) SE Runtime Environment (build 1.8.0_191-b12)
Java HotSpot(TM) 64-Bit Server VM (build 25.191-b12, mixed mode)
```



mycat官方文档，有两个版本，一个是mycat1，一个是mycat2

https://www.yuque.com/ccazhw



### 9.安装mycat：

#### 9.1.解压mycat的tar包：

```shell
[root@mysql03 opt]# tar zxf Mycat-server-1.6.7.4-release-20200105164103-linux.tar.gz 
```

#### 9.2.将解压后获得的mycat目录放到固定路径下。此处放在/usr/local下:

```shell
[root@mysql03 opt]# mv ./mycat/ /usr/local/mycat
```

#### 9.3.设置mycat的环境变量：

```shell
[root@mysql03 opt]# vim /etc/profile
export PATH=/usr/local/mycat/bin:$PATH
#生效：
[root@mysql03 opt]# source !$
source /etc/profile
```



### 10.mycat工作原理简图：

![file://c:\users\admini~1\appdata\local\temp\tmpsn4zsu\2.png](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203171913497.png)



#### 启动：

```shell
[root@mysql03 opt]# mycat start
Starting Mycat-server...
[root@mysql03 opt]# netstat -lntp |grep 8066
tcp6       0      0 :::8066                 :::*                    LISTEN      11537/java
```



```
#报错
ERROR  | wrapper  | 2022/09/03 12:23:35 | Startup failed: Timed out waiting for a signal from the JVM.
ERROR  | wrapper  | 2022/09/03 12:23:35 | JVM did not exit on request, terminated
[root@mysql03 opt]# netstat -lntp |grep 8066
无法显示端口

修改/usr/local/mycat/conf/wrapper.conf
改:wrapper.ping.timeout=120
为:wrapper.ping.timeout=3600
   wrapper.startup.timeout=7200

[root@mysql03 opt]# mycat start
Starting Mycat-server...
[root@mysql03 opt]# netstat -lntp |grep 8066
tcp6       0      0 :::8066                 :::*                    LISTEN      11537/java

```

使用另一种方法启动：

```
[root@mycat bin]# ./startup_nowrap.sh 
"/usr/local/java/bin/java" -DMYCAT_HOME="/usr/local/mycat" -classpath "/usr/local/mycat/conf:/usr/local/mycat/lib/classes:/usr/local/mycat/lib/annotations-13.0.jar:/usr/local/mycat/lib/asm-4.0.jar:/usr/local/mycat/lib/commons-collections-3.2.1.jar:/usr/local/mycat/lib/commons-lang-2.6.jar:/usr/local/mycat/lib/curator-client-2.11.0.jar:/usr/local/mycat/lib/curator-framework-2.11.0.jar:/usr/local/mycat/lib/curator-recipes-2.11.0.jar:/usr/local/mycat/lib/disruptor-3.3.4.jar:/usr/local/mycat/lib/dom4j-1.6.1.jar:/usr/local/mycat/lib/druid-1.0.26.jar:/usr/local/mycat/lib/ehcache-core-2.6.11.jar:/usr/local/mycat/lib/fastjson-1.2.58.jar:/usr/local/mycat/lib/guava-19.0.jar:/usr/local/mycat/lib/hamcrest-core-1.3.jar:/usr/local/mycat/lib/hamcrest-library-1.3.jar:/usr/local/mycat/lib/jline-0.9.94.jar:/usr/local/mycat/lib/joda-time-2.9.3.jar:/usr/local/mycat/lib/jsr305-2.0.3.jar:/usr/local/mycat/lib/kotlin-stdlib-1.3.50.jar:/usr/local/mycat/lib/kotlin-stdlib-common-1.3.50.jar:/usr/local/mycat/lib/kryo-2.10.jar:/usr/local/mycat/lib/leveldb-0.7.jar:/usr/local/mycat/lib/leveldb-api-0.7.jar:/usr/local/mycat/lib/log4j-1.2.17.jar:/usr/local/mycat/lib/log4j-1.2-api-2.5.jar:/usr/local/mycat/lib/log4j-api-2.5.jar:/usr/local/mycat/lib/log4j-core-2.5.jar:/usr/local/mycat/lib/log4j-slf4j-impl-2.5.jar:/usr/local/mycat/lib/mapdb-1.0.7.jar:/usr/local/mycat/lib/minlog-1.2.jar:/usr/local/mycat/lib/mongo-java-driver-3.11.0.jar:/usr/local/mycat/lib/Mycat-server-1.6.7.4-release.jar:/usr/local/mycat/lib/mysql-binlog-connector-java-0.16.1.jar:/usr/local/mycat/lib/mysql-connector-java-5.1.35.jar:/usr/local/mycat/lib/netty-3.7.0.Final.jar:/usr/local/mycat/lib/netty-buffer-4.1.9.Final.jar:/usr/local/mycat/lib/netty-common-4.1.9.Final.jar:/usr/local/mycat/lib/objenesis-1.2.jar:/usr/local/mycat/lib/okhttp-4.2.2.jar:/usr/local/mycat/lib/okio-2.2.2.jar:/usr/local/mycat/lib/reflectasm-1.03.jar:/usr/local/mycat/lib/sequoiadb-driver-1.12.jar:/usr/local/mycat/lib/slf4j-api-1.6.1.jar:/usr/local/mycat/lib/univocity-parsers-2.2.1.jar:/usr/local/mycat/lib/velocity-1.7.jar:/usr/local/mycat/lib/wrapper.jar:/usr/local/mycat/lib/zookeeper-3.4.6.jar" -server -Xms2G -Xmx2G -XX:+AggressiveOpts -XX:MaxDirectMemorySize=2G io.mycat.MycatStartup >> "/usr/local/mycat/logs/console.log" 2>&1 &

[root@mycat bin]# netstat -ntpl |grep 8066
tcp6       0      0 :::8066                 :::*                    LISTEN      1811/jav 
```





#### 连接mycat：

```shell
[root@mysql03 opt]# mysql -uroot -p123456 -h 127.0.0.1 -P8066
```

 ![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203191039809.png)

**查询发现默认会有一个库和两张表，其实这是默认配置文件里面写好的。mycat呈现的是虚拟表也就是逻辑表**



#### 配置文件介绍

**bin 目录**
**程序目录**

**配置文件目录**
 **conf**

**主配置文件：节点信息、读写分离、高可用设置、调用分片策略..**
**schema.xml**

**分片策略的定义、功能、使用方法**
**rule.xml**

**mycat服务有关配置： 用户、网络、权限、策略、资源...**
**server.xml**

**分片策略参数定义文件**
**xx.txt文件**

**Mycat 相关日志记录配置**
**log4j2.xml**

**logs**
**wrapper.log : 启动日志** 
**mycat.log ：工作日志(成功启动后才有)**



### 11.做数据库的基本分片配置：

#### 11.1.备份原有的配置文件

```shell
[root@mysql03 opt]# cp /usr/local/mycat/conf/schema.xml /usr/local/mycat/conf/schema.xml.bak
```

#### 11.2.配置读写分离

需要先在mysql7创建一个测试库，库里面要有表

```shell
[root@mysql7 system]# mysql -uroot -p123456 -S /data/3307/mysql.sock -e "create database today charset utf8;"
mysql: [Warning] Using a password on the command line interface can be insecure.
[root@mysql7 system]# mysql -uroot -p123456 -S /data/3307/mysql.sock -e "show databases;"

[root@mysql7 system]# mysql -uroot -p123456 -S /data/3307/mysql.sock -e "create table today.test(id int);"
mysql: [Warning] Using a password on the command line interface can be insecure.
[root@mysql7 system]# mysql -uroot -p123456 -S /data/3307/mysql.sock -e "insert into today.test values(1),(2),(3),(4),(5),(6),(7);"
mysql: [Warning] Using a password on the command line interface can be insecure.

或者

[root@mysql7 system]# mysql -uroot -p123456 -S /data/3307/mysql.sock -e 'create database today charset utf8; create table today.test(id int); insert into today.test values(1),(2),(3),(4),(5),(6),(7); show databases; select * from today.test;'
```

```shell
[root@mysql7 system]# mysql -uroot -p123456 -S /data/3309/mysql.sock -e "use today; show tables; select *  from today.test;"
mysql: [Warning] Using a password on the command line interface can be insecure.
+-----------------+
| Tables_in_today |
+-----------------+
| test            |
+-----------------+
+------+
| id   |
+------+
|    1 |
|    2 |
|    3 |
|    4 |
|    5 |
|    6 |
|    7 |
+------+

```



```shell
[root@mysql03 opt]# vim /usr/local/mycat/conf/schema.xml
<?xml version="1.0"?>
<!DOCTYPE mycat:schema SYSTEM "schema.dtd">
<mycat:schema xmlns:mycat="http://io.mycat/">

        <schema name="TESTDB" checkSQLschema="false" sqlMaxLimit="100" dataNode="dn1">
        </schema>
        <dataNode name="dn1" dataHost="localhost1" database="today" />
        <dataHost name="localhost1" maxCon="1000" minCon="10" balance="1" writeType="0" dbType="mysql" dbDriver="native" switchType="1" >
                <heartbeat>select user()</heartbeat>
                <writeHost host="a1" url="mysql7:3307" user="root"
                                   password="123456">
                    <readHost host="a2" url="mysql7:3309" user="root"
                                   password="123456"/>
                </writeHost>
        </dataHost>
</mycat:schema>
```

重启mycat

```shell
[root@mysql03 opt]# mycat restart
Stopping Mycat-server...
Stopped Mycat-server.
Starting Mycat-server...
```

进入mycat查看。

```
[root@mysql03 opt]# mysql -uroot -p123456 -h 127.0.0.1  -P 8066
```

**注：当配置好配置文件时，进入testdb慢，优先考虑用户授权的问题**



```mysql
mysql> select @@server_id;                      #读在从机上
+-------------+
| @@server_id |
+-------------+
|           9 |
+-------------+
1 row in set (0.00 sec)

mysql> begin;select @@server_id;commit;         #写在主机上
Query OK, 0 rows affected (0.00 sec)

+-------------+
| @@server_id |
+-------------+
|           7 |
+-------------+
1 row in set (0.01 sec)

Query OK, 0 rows affected (0.00 sec)
```

<font color='red'>**总结：** </font>
**以上案例实现了1主1从的读写分离功能，写操作落到主库，读操作落到从库.如果主库宕机，从库不能在继续提供服务了。**



#### 11.2.设置高可用读写分离：

```shell
[root@mysql03 opt]# vim /usr/local/mycat/conf/schema.xml

<?xml version="1.0"?>
<!DOCTYPE mycat:schema SYSTEM "schema.dtd">
<mycat:schema xmlns:mycat="http://io.mycat/">

        <schema name="TESTDB" checkSQLschema="false" sqlMaxLimit="100" dataNode="dn1">
        </schema>
        <dataNode name="dn1" dataHost="localhost1" database="today" />
        <dataHost name="localhost1" maxCon="1000" minCon="10" balance="1"
                          writeType="0" dbType="mysql" dbDriver="native" switchType="1" >
                <heartbeat>select user()</heartbeat>
                <writeHost host="a1" url="mysql7:3307" user="root"
                                   password="123456">
                    <readHost host="a2" url="mysql7:3309" user="root"
                                   password="123456"/>
                </writeHost>
                <writeHost host="a3" url="mysql8:3307" user="root"		#在同一个datanode里添加切换主机
                                   password="123456">
                    <readHost host="a4" url="mysql8:3309" user="root"
                                   password="123456"/>
                </writeHost>
        </dataHost>
</mycat:schema>

#注释去掉再写进配置文件
```

**说明：配置多节点高可用读写分离，增加writehost 与readhost相关行，可多行配置。**

**<font color='red'>注意：节点宕机，则写入配置的读写节点全部被mycat剔除集群。</font>**

重启mycat

```shell
[root@mysql03 opt]# mycat restart
Stopping Mycat-server...
Mycat-server was not running.
Starting Mycat-server...
```

测试：

关闭一节点

```shell
[root@mysql7 system]# systemctl stop mysqld3307.service
```

进入mycat查看

```shell
[root@mysql03 opt]# mysql -uroot -p123456 -h 127.0.0.1  -P 8066
```

```shell
mysql> select @@server_id;                  #读在从机上
+-------------+
| @@server_id |
+-------------+
|          19 |
+-------------+
1 row in set (0.00 sec)

mysql> begin;select @@server_id;commit;            #写在主机上
Query OK, 0 rows affected (0.00 sec)

+-------------+
| @@server_id |
+-------------+
|          17 |
+-------------+
1 row in set (0.01 sec)

Query OK, 0 rows affected (0.00 sec)
```



#### 11.3参数介绍

##### 11.3.1.balance属性

1. <font color='red'>**balance="0", 不开启读写分离机制，所有读操作都发送到当前可用的writeHost上。**</font>

     

2. <font color='red'>**balance="1"，全部的readHost与standby writeHost参与select语句的负载均衡，简单的说，（备用主库）**</font>
     **<font color='red'>当双主双从模式(M1->S1，M2->S2，并且M1与 M2互为主备)，正常情况下，M2,S1,S2都参与select语句的负载均衡。</font>**

     

3. <font color='red'>**balance="2"，所有读操作都随机的在writeHost、readhost上分发。**</font>



##### 11.3.2.writeType属性

写操作，负载均衡类型，目前的取值有2种：

1. **<font color='red'>writeType="0", 所有写操作发送到配置的第一个writeHost，</font>**
**<font color='red'>第一个挂了切到还生存的第二个writeHost，重新启动后已切换后的为主，切换记录在配置文件中:dnindex.properties .</font>**
2. <font color='red'>**writeType=“1”，所有写操作都随机的发送到配置的writeHost，但不推荐使用**</font>



##### 11.3.3.switchType属性节点切换：

-1 表示不自动切换

1 默认值，自动切换

2 基于MySQL主从同步的状态决定是否切换 ，心跳语句为 show slave status



##### 11.3.4.连接有关

maxCon="1000"：最大的并发连接数

minCon="10" ：mycat在启动之后，会在后端节点上自动开启的连接线程（相当于连接池）。

\<heartbeat>select user()\</heartbeat> 监测心跳

##### 11.3.5.dbDriver

指定连接后端数据库使用的Driver，目前可选的值有`native`和`JDBC`。使用native的话，因为这个值执行的是二进制的mysql协议，所以可以使用**mysql8.0之前的版本**和maridb。其他类型的数据库和**mysql8.0之后的版本**则需要使用JDBC驱动来支持。



<font color='red'>参考：官方文档</font>  [入门篇4-7](</https://www.yuque.com/ccazhw/tuacvk/gmbnwu#6gZs6)





#### 11.4.单独到表的操作：

注意：
在外面创建相应的表和库

```shell
[root@mysql7 ~]# systemctl start mysqld3307.service   #重新拉起3307
```



```shell
[root@mysql03 opt]# vim /usr/local/mycat/conf/schema.xml

<?xml version="1.0"?>
<!DOCTYPE mycat:schema SYSTEM "schema.dtd">
<mycat:schema xmlns:mycat="http://io.mycat/">

        <schema name="TESTDB" checkSQLschema="false" sqlMaxLimit="100" dataNode="dn1">      #dataNode="dn1"设置有时会让逻辑库"TESTDB"把dn1节点下的所有表都显示出来，在设置单独到表操作时最好把此设置删除
               <table name="test" dataNode="dn1" />			#添加此行设置
        </schema>
        <dataNode name="dn1" dataHost="localhost1" database="today" />
        <dataHost name="localhost1" maxCon="1000" minCon="10" balance="1"
                          writeType="0" dbType="mysql" dbDriver="native" switchType="1" >
                <heartbeat>select user()</heartbeat>
                <writeHost host="a1" url="mysql7:3307" user="root"
                                   password="123456">
                    <readHost host="a2" url="mysql7:3309" user="root"
                                   password="123456"/>
                </writeHost>
                <writeHost host="a3" url="mysql8:3307" user="root"
                                   password="123456">
                    <readHost host="a4" url="mysql8:3309" user="root"
                                   password="123456"/>
                </writeHost>
          </dataHost>
</mycat:schema>
```



实验，在mysql7创建第二张表：

```shell
[root@mysql7 ~]# mysql -uroot -p123456 -S /data/3307/mysql.sock -e 'create table today.test2(id int); insert into today.test2 values(1),(2),(3),(4),(5),(6),(7); show databases; select * from today.test;'

[root@mysql7 ~]# mysql -uroot -p123456 -S /data/3307/mysql.sock -e 'use today; show tables;'
mysql: [Warning] Using a password on the command line interface can be insecure.
+-----------------+
| Tables_in_today |
+-----------------+
| test            |
| test2           |
+-----------------+
```

重启mycat

```shell
[root@mysql03 opt]# mycat restart
```

进入mycat查看

```shell
mysql -uroot -p123456 -h 127.0.0.1  -P 8066
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203191235923.png)



#### 11.5.水平分库

```shell
[root@mysql03 opt]# vim /usr/local/mycat/conf/schema.xml
```

```shell
<?xml version="1.0"?>
<!DOCTYPE mycat:schema SYSTEM "schema.dtd">
<mycat:schema xmlns:mycat="http://io.mycat/">

        <schema name="TESTDB" checkSQLschema="false" sqlMaxLimit="100" dataNode="dn1">      #此配置只是mycat逻辑库的内容
               <table name="user" dataNode="dn1" />			#水平分库主要由dataNode设置决定
               <table name="order1" dataNode="dn2"/>
        </schema>                                               
        <dataNode name="dn1" dataHost="localhost1" database="taobao" />
        <dataNode name="dn2" dataHost="localhost2" database="taobao" />

        <dataHost name="localhost1" maxCon="1000" minCon="10" balance="1"
                          writeType="0" dbType="mysql" dbDriver="native" switchType="1" >
                <heartbeat>select user()</heartbeat>
                <writeHost host="a1" url="mysql7:3307" user="root"
                                   password="123456">
                    <readHost host="a2" url="mysql7:3309" user="root"
                                   password="123456"/>
                </writeHost>
                <writeHost host="a3" url="mysql8:3307" user="root"
                                   password="123456">
                    <readHost host="a4" url="mysql8:3309" user="root"
                                   password="123456"/>
                </writeHost>
        </dataHost>
        
       <dataHost name="localhost2" maxCon="1000" minCon="10" balance="1"
                          writeType="0" dbType="mysql" dbDriver="native" switchType="1" >
                <heartbeat>select user()</heartbeat>
                <writeHost host="a1" url="mysql7:3308" user="root"
                                   password="123456">
                    <readHost host="a2" url="mysql7:3310" user="root"
                                   password="123456"/>
                </writeHost>
                <writeHost host="a3" url="mysql8:3308" user="root"
                                   password="123456">
                    <readHost host="a4" url="mysql8:3310" user="root"
                                   password="123456"/>
                </writeHost>
        </dataHost>
</mycat:schema>
```

重启mycat

```shell
[root@mysql03 ~]# mycat restart
Stopping Mycat-server...
Stopped Mycat-server.
Starting Mycat-server...
```

实例：
创建测试库和表:

```shell
mysql -uroot -p123456 -S /data/3307/mysql.sock -e "create database taobao charset utf8;"

mysql -uroot -p123456 -S /data/3308/mysql.sock -e "create database taobao charset utf8;"

mysql -uroot -p123456 -S /data/3307/mysql.sock -e "use taobao;create table user(id int,name varchar(20))";

mysql -uroot -p123456 -S /data/3308/mysql.sock -e "use taobao;create table order1(id int,name varchar(20))"

mysql -uroot -p123456 -S /data/3307/mysql.sock -e "use taobao ; show tables ; "

mysql -uroot -p123456 -S /data/3308/mysql.sock -e "use taobao ; show tables ;"
```

进入mycat查看:

**mycat中对 user 和 order 数据插入**

```shell
[root@mysql03 ~]# mysql -uroot -p123456 -h 127.0.0.1  -P 8066
```

```mysql
insert into user values(1,'a'),(2,'b'),(3,'c');

insert into order1 values(1,'x'),(2,'y');
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203191602041.png)

```shell
[root@mysql7 ~]# mysql -uroot -p123456 -S /data/3307/mysql.sock -e "show tables from taobao"
mysql: [Warning] Using a password on the command line interface can be insecure.
+------------------+
| Tables_in_taobao |
+------------------+
| user             |
+------------------+


[root@mysql7 ~]# mysql -uroot -p123456 -S /data/3308/mysql.sock -e "show tables from taobao"
mysql: [Warning] Using a password on the command line interface can be insecure.
+------------------+
| Tables_in_taobao |
+------------------+
| order1           |
+------------------+


[root@mysql7 ~]# mysql -uroot -p123456 -S /data/3307/mysql.sock -e "select * from taobao.user"
mysql: [Warning] Using a password on the command line interface can be insecure.
+------+------+
| id   | name |
+------+------+
|    1 | a    |
|    2 | b    |
|    3 | c    |
+------+------+


[root@mysql7 ~]# mysql -uroot -p123456 -S /data/3308/mysql.sock -e "select * from taobao.order1"
mysql: [Warning] Using a password on the command line interface can be insecure.
+------+------+
| id   | name |
+------+------+
|    1 | x    |
|    2 | y    |
+------+------+
```



#### 11.6.垂直分表：

**分片：对一个"bigtable"，比如说xxx表**

  **(1)行数非常多，比如数据800w条**
  **(2)访问非常频繁**

**分片的目的：**
**（1）将大数据量进行分布存储**
**（2）提供均衡的访问路由**

**分片策略：**
**<font color='red'>范围 range  800w条数据  1-400w为1张表 400w01-800w为另一张表</font>**
**<font color='red'>取模 mod    取余数</font>**
**枚举** 
**哈希 hash** 
**时间 流水**

**优化关联查询**
**全局表**
**ER分片**
**范围分片：**
**比如说t3表**
**(1)行数非常多，2000w（1-1000w:sh1   1000w01-2000w:sh2）**
**(2)访问非常频繁，用户访问较离散**



#### 11.7.用范围策略分表

```shell
[root@mysql03 opt]# vim /usr/local/mycat/conf/schema.xml
```

```shell
<schema name="TESTDB" checkSQLschema="false" sqlMaxLimit="100" dataNode="dn1"> 
        #只修改此行，其它配置不动 <table name="t3" dataNode="dn1,dn2" rule="auto-sharding-long" />
</schema>  
    <dataNode name="dn1" dataHost="localhost1" database= "taobao" /> 
    <dataNode name="dn2" dataHost="localhost2" database= "taobao" />  
```

```shell
#查看分片规则配置文件：
[root@mysql03 ~]# vim /usr/local/mycat/conf/rule.xml
<tableRule name="auto-sharding-long">
                <rule>
                        <columns>id</columns>
                        <algorithm>rang-long</algorithm>
                </rule>             
<function name="rang-long"
    class="io.mycat.route.function.AutoPartitionByLong">
    <property name="mapFile">autopartition-long.txt</property>		#查看下rang-long规则需要调用哪个文件！！
</function>
```

在conf目录下

```shell
[root@mysql03 ~]# vim /usr/local/mycat/conf/autopartition-long.txt
0-10=0
11-20=1
```

**注意，注释掉文件原来自带的配置参数**

创建测试表：

```shell
[root@mysql7 ~]# mysql -uroot -p123456 -S /data/3307/mysql.sock -e "use taobao;create table t3 (id int not null primary key auto_increment,name varchar(20) not null);"
mysql: [Warning] Using a password on the command line interface can be insecure.


[root@mysql7 ~]# mysql -uroot -p123456 -S /data/3308/mysql.sock  -e "use taobao;create table t3 (id int not null primary key auto_increment,name varchar(20) not null);"
mysql: [Warning] Using a password on the command line interface can be insecure.
```

测试：
重启mycat

```shell
[root@mysql03 ~]# mycat restart
Stopping Mycat-server...
Stopped Mycat-server.
Starting Mycat-server...
```

```shell
[root@mysql03 ~]# mysql -uroot -p123456 -h 127.0.0.1 -P 8066
```

```mysql
insert into t3(id,name) values(1,'a');
insert into t3(id,name) values(2,'b');
insert into t3(id,name) values(3,'c');
insert into t3(id,name) values(4,'d');
insert into t3(id,name) values(11,'aa');
insert into t3(id,name) values(12,'bb');
insert into t3(id,name) values(13,'cc');
insert into t3(id,name) values(14,'dd');
```

```shell
[root@mysql7 ~]# mysql -uroot -p123456 -S /data/3307/mysql.sock -e "select *  from taobao.t3;"
mysql: [Warning] Using a password on the command line interface can be insecure.
+----+------+
| id | name |
+----+------+
|  1 | a    |
|  2 | b    |
|  3 | c    |
|  4 | d    |
+----+------+
[root@mysql7 ~]# mysql -uroot -p123456 -S /data/3308/mysql.sock -e "select *  from taobao.t3;"
mysql: [Warning] Using a password on the command line interface can be insecure.
+----+------+
| id | name |
+----+------+
| 11 | aa   |
| 12 | bb   |
| 13 | cc   |
| 14 | dd   |
+----+------+
```



#### 11.8.取模分片（mod-long）：

以节点数n为基准，则取模标签的范围为0-(n-1)。
取模分片（mod-long）：
取余分片方式：分片键（一个列）与<font color='red'>节点数量</font>进行取余，得到余数，将数据写入对应节点

```shell
[root@mysql03 ~]# vim /usr/local/mycat/conf/schema.xml
```

在配置文件里增加改行：

```shell
<schema name="TESTDB" checkSQLschema="false" sqlMaxLimit="100" dataNode="dn1"> 
        <table name="t3" dataNode="dn1,dn2" rule="auto-sharding-long" />
        <table name="t4" dataNode="dn1,dn2" rule="mod-long" />			#添加一行不同分表规则
</schema>  
    <dataNode name="dn1" dataHost="localhost1" database= "taobao" /> 
    <dataNode name="dn2" dataHost="localhost2" database= "taobao" />  
```

```shell
[root@mysql03 ~]# vim /usr/local/mycat/conf/rule.xml
#根据节点数进行修改count后面数值：
#根据修改规则可以知道引用的是mod-long，约在114行
114 <property name="count">2</property>
```

创建测试表：

```shell
[root@mysql7 ~]# mysql -uroot -p123456 -S /data/3307/mysql.sock -e "use taobao;create table t4 (id int not null primary key auto_increment,name varchar(20) not null);"
mysql: [Warning] Using a password on the command line interface can be insecure.


[root@mysql7 ~]# mysql -uroot -p123456 -S /data/3308/mysql.sock -e "use taobao;create table t4 (id int not null primary key auto_increment,name varchar(20) not null);"
mysql: [Warning] Using a password on the command line interface can be insecure.
```

重启mycat 

```shell
[root@mysql03 ~]# mycat restart
Stopping Mycat-server...
Stopped Mycat-server.
Starting Mycat-server...
```

测试： 

```shell
[root@mysql03 ~]# mysql -uroot -p123456 -h127.0.0.1 -P8066
```

```mysql
use TESTDB
insert into t4(id,name) values(1,'a');
insert into t4(id,name) values(2,'b');
insert into t4(id,name) values(3,'c');
insert into t4(id,name) values(4,'d');
```

分别登录后端节点查询数据

```shell
[root@mysql7 ~]# mysql -uroot -p123456 -S /data/3307/mysql.sock  -e "use taobao; select * from t4;"
mysql: [Warning] Using a password on the command line interface can be insecure.
+----+------+
| id | name |
+----+------+
|  2 | b    |
|  4 | d    |
+----+------+


[root@mysql7 ~]# mysql -uroot -p123456 -S /data/3308/mysql.sock  -e "use taobao; select * from t4;"
mysql: [Warning] Using a password on the command line interface can be insecure.
+----+------+
| id | name |
+----+------+
|  1 | a    |
|  3 | c    |
+----+------+
```



### 12.管理类操作

```shell
[root@mysql03 ~]# mysql -uroot -p123456 -h127.0.0.1 -P9066		#管理端口不同
```

```shell
#查看帮助

show @@help;

#查看Mycat 服务情况

show @@server ;

#查看分片信息

show @@datanode;

#查看数据源

show @@datasource

#重新加载配置信息

reload @@config     : schema.xml            

reload @@config_all   : #所有配置重新加载
```



### 13.修改逻辑库：

```shell
# 总配置文件
schema.xml

<schema name="taobao" checkSQLschema="false" sqlMaxLimit="100" dataNode="dn1">

</schema>

# 修改server.xml

# 总配置模板：带两个逻辑库。
<user name="root" defaultAccount="true">
                <property name="password">123456</property>
                <property name="schemas">class1,class2</property>
                <property name="defaultSchema">class1</property>
                <!--No MyCAT Database selected 错误前会尝试使用该schema作为schema，不设置则为null,报错 -->

                <!-- 表级 DML 权限设置 -->
                <!--            
                <privileges check="false">
                        <schema name="TESTDB" dml="0110" >
                                <table name="tb01" dml="0000"></table>
                                <table name="tb02" dml="1111"></table>
                        </schema>
                </privileges>           
                 -->
        </user>

        <user name="user">
                <property name="password">user</property>
                <property name="schemas">class1,class2</property>
                <property name="readOnly">true</property>
                <property name="defaultSchema">class1</property>
        </user>


# 举例：添加一个逻辑库

schema.xml

<schema name="class1" checkSQLschema="false" sqlMaxLimit="100" dataNode="sh1">

</schema>

server.xml

<property name="schemas">class1,class2</property>
```

**`schema`标签用于定义MyCat实例中的逻辑库，MyCat可以有多个逻辑库，每个逻辑库都有自己的相关配置。可以使用 `schema` 标签来划分这些不同的逻辑库。**

**如果不配置 `schema` 标签，所有的表配置，会属于同一个默认的逻辑库。**



### 14.Mycat使用的原则

#### (1)分库分表原则：

原则一：能不分就不分。
    分表是为了解决的问题，但是也会带来性能上的损失。 所以分片第一原则是：能不分就不分。对于1000 万以内的表，不建议分片，通过合适的索引，读写分离等方式，可以很好的解决性能问题。
原则二：分片数量尽量少，分片尽量均匀分布在多个 DataHost 上
    因为一个查询 SQL 跨分片越多，则总体性能越差，虽然要好于所有数据在一个分片的结果，只在必要的时候进行扩容，增加分片数量。
原则三：分片规则需要慎重选择。  
    分片规则的选择，需要考虑数据的增长模式，数据的访问模式，分片关联性问题，以及分片扩容问题，最近的分片策略为范围分片，枚举分片，一致性 Hash 分片，这几种分片都有利于扩容
原则四：尽量不要在一个事务中的 SQL 跨越多个分片，分布式事务一直是个不好处理的问题
原则五：查询条件尽量优化，尽量避免 Select * 的方式，大量数据结果集下，会消耗大量带宽和 CPU 资源，查询尽量避免返回大量结果集，并且尽量为频繁使用的查询语句建立索引。

#### (2)数据拆分原则

1. 达到一定数量级才拆分（ 800 万左右）。


2. 不到 800 万但跟大表（超 800 万的表）有关联查询的表也要拆分，在此称为大表关联表。


3. 大表关联表如何拆：
   小于 100 万的使用全局表；
   大于 100 万小于 800 万跟大表使用同样的拆分策略；
   无法跟大表使用相同规则的，可以考虑从 java 代码上分步骤查询，不用关联查询，或者采用特例使用全局表。
   
4. 使用全局表。   #全局表：逻辑库后面直接接实际数据库的表内容
    全局表的作用：可充当数据字典表，这张数据表会在所有的数据库中存在，但对外而言，只是一个逻辑数据库存在的数据表，当对该表进行变更操作时，所有数据库的该表都会发生相应的变化。

	

  满足于global表的条件是：很少对表进行并发 update，如多线程同时 update 同一条 id=1 的记录(多线程 update，但不是操作同一行记录是可以的，多线程 update 全局表的同一行记录会死锁)。批量 insert没问题。
  符合使用全局表的特征：
    变动不频繁，很少对表进行并发更新
    数据量总体变化不大
    数据规模不大，很少有超过数十万条记录。
    

5. 拆分字段是不可修改的


6. 拆分字段只能是一个字段，如果想按照两个字段拆分，必须新建一个冗余字段，冗余字段的值使用两个字段的值拼接而成（如大区+年月拼成 zone_yyyymm 字段）。


7. 拆分算法的选择和合理性评判：按照选定的算法拆分后每个库中单表不得超过 800 万


8. 能不拆的就尽量不拆。如果某个表不跟其他表关联查询，数据量又少，直接不拆分，使用单库即可。

#### (3)DataNode 的分布问题

DataNode 代表 MySQL 数据库上的一个 Database，因此一个分片表的 DataNode 的分布可能有以下3种：

1. 都在一个 DataHost 上.


2. 在几个 DataHost 上，但有连续性，比如 dn1 到 dn5 在 Server1 上， dn6 到 dn10 在 Server2上，依次类推.


3. 在几个 DataHost 上，但均匀分布，比如 dn1,dn2,d3 分别在 Server1,Server2,Server3 上， dn4 到 dn6 又重复如此.
第一种情况不大推荐。至于是采用数据连续性分布还是数据均匀分布要看具体情况。如果是要考虑高并发的IO的分布、热数据处理、尽可能提高sql响应时间，采取数据均匀分布；如果是考虑业务数据冷热分布，方便进行数据归档，则考虑数据连续分布。

#### (4)分片规则

分片规则用于定义数据与分片的路由关系，也就是 insert， delete， update， select的基本 sql 操作中，如何将 sql 路由到对应的分片执行。
在分片之前，应该考虑以下因素：
分片要考虑数据的增长情况，是实时大量增长还是缓慢增长,数据和数据之间的关联关系。
通过抓取系统中实际执行的SQL，分析SQL的运行规律，频率、响应时间、对系统性能和功能的影响程度。
要保证系统中不同数据表的可靠性，以及操作模式。
业务的特点：系统中哪些业务操作是严格事务的，哪些是普通事务或可以无事务的。
要考虑数据的备份模式，对系统的影响。

分片后，SQL性能的损耗，据测算大约20%左右，因此在作分片处理的时候需要考虑
分片数据如何插入，在插入数据的时候，应考虑到数据分布多节点的特点，根据分片规则定位数据对应到相应的节点，分解SQL进行插入。
分片数据如何关联查询，应尽量避免大的关联查询，尽量使用小的事务，尽量使用简单的查询，尽量在前端进行一些数据处理操作。
分片数据删除。由于数据是分布在各个数据节点，进行数据删除的时候，尽量避免join操作。应该对数据进行分析，根据分片规则定位数据，在对应分片删除相应数据。
分片数据修改。把查询条件识别出来，然后执行一下分片函数即可定位到节点，再执行对应的SQL即可，对了提高执行效率，尽量避免join操操作，必须避免对分片键进行修改的操作。

分片键的选择需要考虑
尽可能将数据均匀的分布到各个节点
该业务字段是最频繁的或者最重要的查询条件
尽量避免跨库join操作；
尽量减少表join操作，可以考虑全局表，可以考虑适当的冗余字段等。

常用分片规则算法：
取模分库：mod-long
范围分库：auto-sharding-long
Hash分库：hash-int
分片枚举：hash-int
截取数字 hash ：sharding-by-stringhash
自然月分库：sharding-by-month
按日期(天)：sharding-by-date
日期范围hash：range-date-hash
冷热数据：sharding-by-hotdate
ER模型分库：childTable
自定义分库：CustomRule(该方式需要自己实现分库算法)

#### (5)配置文件：

conf目录下面的三个配置文件：
schema.xml中定义逻辑库，表、分片节点等内容，逻辑库标签、datanode标签、datahost标签；
rule.xml中定义分片规则，包括分片规则标签和分片函数标签；
server.xml中定义用户以及系统相关变量，包括system标签、用户标签、防火墙标签等；



