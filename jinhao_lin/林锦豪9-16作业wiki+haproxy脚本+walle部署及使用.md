# 2022-09-16

# 1，企业级wiki confluence搭建。java项目练手

#### 一、准备环境

```shell
#关闭防火墙
[root@home4 ~]# systemctl stop firewalld
[root@home4 ~]# systemctl disable firewalld
#安装jdk
[root@home4 ~]# wget http://192.168.1.200/rpm/jdk-8u151-linux-x64.rpm
[root@home4 ~]# rpm -ivh jdk-8u151-linux-x64.rpm 
准备中...                          ################################# [100%]
正在升级/安装...
   1:jdk1.8-2000:1.8.0_151-fcs        ################################# [100%]
[root@home4 ~]# vim /etc/profile
export JAVA_HOME=/usr/java/jdk1.8.0_151
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export PATH=$JAVA_HOME/bin:$PATH
[root@home4 ~]# source !$
#安装mariadb
[root@home4 ~]# yum install mariadb* -y
[r[root@home4 ~]# systemctl start mariadb
[root@home4 mysql]# mysql_secure_installation

NOTE: RUNNING ALL PARTS OF THIS SCRIPT IS RECOMMENDED FOR ALL MariaDB
      SERVERS IN PRODUCTION USE!  PLEASE READ EACH STEP CAREFULLY!

In order to log into MariaDB to secure it, we'll need the current
password for the root user.  If you've just installed MariaDB, and
you haven't set the root password yet, the password will be blank,
so you should just press enter here.

Enter current password for root (enter for none): 
OK, successfully used password, moving on...

Setting the root password ensures that nobody can log into the MariaDB
root user without the proper authorisation.

Set root password? [Y/n] y
New password: 
Re-enter new password: 
Password updated successfully!
Reloading privilege tables..
 ... Success!


By default, a MariaDB installation has an anonymous user, allowing anyone
to log into MariaDB without having to have a user account created for
them.  This is intended only for testing, and to make the installation
go a bit smoother.  You should remove them before moving into a
production environment.

Remove anonymous users? [Y/n] y
 ... Success!

Normally, root should only be allowed to connect from 'localhost'.  This
ensures that someone cannot guess at the root password from the network.

Disallow root login remotely? [Y/n] n
 ... skipping.

By default, MariaDB comes with a database named 'test' that anyone can
access.  This is also intended only for testing, and should be removed
before moving into a production environment.

Remove test database and access to it? [Y/n] y
 - Dropping test database...
 ... Success!
 - Removing privileges on test database...
 ... Success!

Reloading the privilege tables will ensure that all changes made so far
will take effect immediately.

Reload privilege tables now? [Y/n] y
 ... Success!

Cleaning up...

All done!  If you've completed all of the above steps, your MariaDB
installation should now be secure.

Thanks for using MariaDB!
[root@home4 mysql]# mysql -uroot -p12345

MariaDB [(none)]> create database confluence default character set utf8 collate utf8_bin;

MariaDB [(none)]> grant all on confluence.* to 'wiki'@'%' identified by '12345' with grant option;

MariaDB [(none)]> grant all on confluence.* to 'wiki'@localhost identified by '12345' with grant option;


MariaDB [(none)]> flush privileges;

MariaDB [(none)]> SET global TRANSACTION ISOLATION LEVEL READ COMMITTED;

MariaDB [(none)]> quit
Bye
#设置事务隔离级别为RC
[root@home4 mysql]# vim /etc/my.cnf
[mysqld]
binlog_format=mixed
character-set-server = utf8
transaction-isolation = READ-COMMITTED
[root@home4 mysql]# systemctl restart mariadb
```

#### 二、安装confluence

```shell
#将提前准备好的安装包拉进服务器
[root@home4 opt]# rz -E
rz waiting to receive.
[root@home4 opt]# ll
总用量 580640
-rw-r--r-- 1 root root 594569303 9月  16 22:20 atlassian-confluence-6.7.1-x64.bin
-rw-r--r-- 1 root root       310 8月  11 13:28 ifcfg-ens33.bak
[root@home4 opt]# chmod 755 atlassian-confluence-6.7.1-x64.bin 
[root@home4 opt]# ./atlassian-confluence-6.7.1-x64.bin  			#安装一路回车，需要你交互的地方一律回车就行
Confluence 7.19.1 can be accessed at http://localhost:8090			#输入ip+8090端口访问
```

**选择产品安装(稍后破解)**

![image-20220916225001655](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209162250792.png)

![image-20220916225117166](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209162251296.png)

![image-20220916225137077](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209162251222.png)

**不用动就先留在这个界面**

#### 三、破解并获取密钥

```shell
[root@home4 opt]# cd /opt/atlassian/confluence/confluence/WEB-INF/lib/
#把atlassian-extras-decoder-v2-3.3.0.jar 拉到windows上
[root@home4 lib]# sz atlassian-extras-decoder-v2-3.3.0.jar 
```

![image-20220916225655085](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209162256168.png)

![image-20220916225718360](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209162257403.png)

**把他名字改成atlassian-extras-2.4.jar（为了等会破解工具能选择他）**

![image-20220916205033611](C:\Users\15893\AppData\Roaming\Typora\typora-user-images\image-20220916205033611.png)

**因为我windows已经安装了jdk环境了所以就不演示了**

**去cmd控制台打开我们的破解工具confluence_keygen.jar：**

![image-20220916211331276](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209162113347.png)

![image-20220916211400487](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209162114561.png)

**ServerID：填刚刚在安装界面第二步的ID如图所示**

![image-20220916225939195](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209162259249.png)

**填完是这样**

![image-20220916230124467](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209162301524.png)

**Name随便取，然后点击.patch!**

**选择我们从linux中拉取出来的jar包**

![image-20220916213417449](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209162134494.png)

**会显示成功，成功后会在atlassian-extras-2.4.jar所在的目录会生成一个新的atlassian-extras-2.4.jar**

![image-20220916230349371](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209162303408.png)

![image-20220916213636037](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209162136087.png)

**他会自动备份的所以别担心，接下来我们把这个新生成的jar包重新拉回linux中把名字改回atlassian-extras-decoder-v2-3.4.6.jar**

```shell
#我不放心所以我挪走了一份之前的 这一步你们可以去掉
[root@home4 lib]# mv atlassian-extras-decoder-v2-3.3.0.jar /opt
```

```shell
#拉回来改回之前的名字
[root@home4 lib]# rz -E
rz waiting to receive.
[root@home4 lib]# mv atlassian-extras-2.4.jar atlassian-extras-decoder-v2-3.3.0.jar
```

#### 四、重新启动，获取密钥，回到网页输入密钥。

```shell
[root@home4 lib]# sh /opt/atlassian/confluence/bin/stop-confluence.sh
[root@home4 lib]# sh /opt/atlassian/confluence/bin/start-confluence.sh
```

**点击.gen!,回到刚刚需要密钥的网页，将获取的密钥输入进去。**

![image-20220916230854150](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209162308189.png)

![image-20220916230823643](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209162308759.png)

#### 五、开始安装

**选择MySQL**

![image-20220916231046485](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209162310577.png)

**把mysql-connector-java-5.1.44-bin.jar也扔进类库里(/opt/atlassian/confluence/confluence/WEB-INF/lib)**

**然后再重启**

```shell
[root@home4 lib]# sh /opt/atlassian/confluence/bin/stop-confluence.sh
[root@home4 lib]# sh /opt/atlassian/confluence/bin/start-confluence.sh
```

**选择MySQL填入相关信息，测试连接，通过就下一步。**

![image-20220916231703837](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209162317928.png)

**选择空白站点**

![image-20220916232111874](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209162321003.png)

**配置系统管理员账号信息等**

![image-20220916232300170](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209162323270.png)

![image-20220916232356774](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209162323904.png)

![image-20220916232448026](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209162324115.png)

**设置成功！这一路走来真不容易/(ㄒoㄒ)/~~**

![image-20220916233122733](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209162331825.png)

![image-20220916233151917](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209162331005.png)

#### 拓展：

```shell
[root@home4 lib]# vim /opt/atlassian/confluence/conf/server.xml 				
可以在这改服务器的相关设置（端口号那些）
[root@home4 confluence]# vim /var/atlassian/application-data/confluence/confluence.cfg.xml
这里改数据源配置
```



# 2，haproxy一键脚本。

```shell
#!/bin/bash
echo -e "\e[36m
______________________________
|                             |
|       HAProxy安装           |
|                             |
|  `date "+%F %H:%M:%S"`        |
|_____________________________|
(\__/) ||               
(•ㅅ•) ||               
/ 　 づv\e[0m"
read -p "请设置HAProxy的用户名：" user
read -p "请设置HAProxy的密码：" password
#####安装依赖#####
yum install -y libtermcap-devel ncurses-devel libevent-devel readline-devel gcc gcc-c++ glibc glibc-devel pcre pcre-devel openssl openssl-devel systemd-devel net-tools vim iotop bc zip unzip zlib-devel lrzsz tree screen lsof tcpdump wget ntpdate

####安装lua####
cd /usr/local/src
curl -R -O http://www.lua.org/ftp/lua-5.4.4.tar.gz
tar zxf lua-5.4.4.tar.gz
cd lua-5.4.4
make all test
./src/lua -v
if [ $? -eq 0 ]
then 
	echo -e "\e[32m lua安装成功 \e[0m"
else
	echo -e "\e[31m lua安装失败 \e{0m"
fi

####安装HAProxy#####
cd /usr/local/src
wget http://192.168.1.200/220711-note/haproxy-2.6.5.tar.gz
tar xvf haproxy-2.6.5.tar.gz
cd haproxy-2.6.5
make  ARCH=x86_64 TARGET=linux-glibc USE_PCRE=1 USE_OPENSSL=1 USE_ZLIB=1 USE_SYSTEMD=1 USE_LUA=1 LUA_INC=/usr/local/src/lua-5.4.4/src/ LUA_LIB=/usr/local/src/lua-5.4.4/src/ PREFIX=/usr/local/haproxy
make install PREFIX=/usr/local/haproxy
cp haproxy /usr/sbin/
/usr/local/haproxy/sbin/haproxy -v
if [ $? -eq 0 ]
then
        echo -e "\e[32m HAProxy安装成功 \e[0m"
else
        echo -e "\e[31m HAProxy安装失败 \e{0m"
fi

####HAProxy启动脚本####
cat > /usr/lib/systemd/system/haproxy.service << 'EOF' 
[Unit]
Description=HAProxy Load Balancer
After=syslog.target network.target
[Service]
ExecStartPre=/usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -c -q
ExecStart=/usr/sbin/haproxy -Ws -f /etc/haproxy/haproxy.cfg -p /var/lib/haproxy/haproxy.pid
ExecReload=/bin/kill -USR2 $MAINPID
[Install]
WantedBy=multi-user.target
EOF

####HAProxy配置文件####
useradd -s /sbin/nologin haproxy
IP=`ifconfig | grep -w broadcast | awk -F "[ ]+" '{print $3}'`
uid=`cat /etc/passwd | grep haproxy | awk -F ":" '{print $3}'`
gid=`cat /etc/passwd | grep haproxy | awk -F ":" '{print $4}'`
mkdir -p /etc/haproxy
cat > /etc/haproxy/haproxy.cfg << EOF
global
maxconn 100000
chroot /usr/local/haproxy
global
maxconn 100000
chroot /usr/local/haproxy
stats socket /var/lib/haproxy/haproxy.sock mode 600 level admin
uid $uid
gid $gid
daemon
#nbproc 4
#cpu-map 1 0
#cpu-map 2 1
#cpu-map 3 2
#cpu-map 4 3
pidfile /var/lib/haproxy/haproxy.pid
log 127.0.0.1 local3 info
defaults
option http-keep-alive
option forwardfor
maxconn 100000
mode http
timeout connect 300000ms
timeout client 300000ms
timeout server 300000ms
listen stats
mode http
bind 0.0.0.0:9999
stats enable
log global
stats uri     /haproxy-status
stats auth   $user:$password
listen web_port
bind $IP:80
mode http
log global
server web1 127.0.0.1:8080 check inter 3000 fall 2 rise 5
EOF
mkdir /var/lib/haproxy
chown -R $uid:$gid /var/lib/haproxy/ 

####启动HAProxy####
kill `lsof -i:80 | awk 'NR==2{print $2}'`
systemctl start haproxy
systemctl enable haproxy
systemctl status haproxy
if [ $? -eq 0 ]
then
        echo -e "\e[32m HAProxy启动成功 \e[0m"
else
        echo -e "\e[31m HAProxy启动失败 \e{0m"
fi
```







# 3，walle一键部署代码系统搭建。（有能力写脚本，研究下使用。）