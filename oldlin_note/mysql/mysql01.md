### **1.   yum安装Mysql**

1..1   LAMP架构：
Linux+Apache+Mysql+PHP
 官方网站：
http://www.mysql.com/
Download MySQL Community Server 链接：
http://dev.mysql.com/downloads/mysql/
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\1.png](https://s2.loli.net/2022/02/14/hC8LKbonwsFv1Yt.png) 

CentOS 7.0 中，已经使用 MariaDB 替代了 MySQL 数据库。 扩展：
随着 Oracle 买下 Sun ， MySQL 也落入了关系型数据库王者之手。而早在 2009 年，考虑到     Oracle 的名声以及其入手之后闭源的可能性，MySQL 之父的 Michael 便先行一步，以他女儿 Maria  的名字开始了 MySQL 的另外一个衍生版本：MariaDB 。 Michael 的名声很好，很快追随者很快排  满了八条街，主流的 Linux 发行商基本上都开始转而支持使用 MariaDB 以规避 MySQL 不确定性的  风险以及对 Michael 的看好。而 MariaDB 则被看作 MySQL 的替代品，原因很简单作为 MySQL    之父的 Michael 可以引导过去开源成功的 MySQL ，自然在其主导下的 MariaDB 也自然很值得期待。 左手把 MySQL 卖掉挣得大笔银子，右手再创分支 ，开启新的衣钵，这便是技术强者的快意人生，一  壶浊酒喜相逢，多少 IT 事，都付笑谈中。   （2018 年 Oracle 公司以 10 亿美元收购 SUN ）

希望大家通过自身的努力，在未来也可以一个很好的薪资待遇。
MariaDB 的前世今生 ：
2009 年   Michael Widenius 迈克尔·维德纽斯 ，创建新项目mariadb 以规避 mysql 关系型 数据库闭源的风险．直到 5.5 的版本，一直按照 MySQL 的版本进行发行。使用者基本上不会感受到 和 MySQL 不同的地方。
2012 年   MariaDB 开始按照自己的节奏和版本发行方式进行发行，初始版本为：10.0.0 ，此 版本以 MySQL5.5 为基础，同时合并了 MySQL5.6 的相关功能。
mariadb 官网： https://downloads.mariadb.org/
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\2.png](https://s2.loli.net/2022/02/14/F7pgftqd3GIumey.png) 

以rpm包的方式安装LAMP。
一、安装需要的软件包
centos7上执行以下语句
[root@mysql1 ~]#yum -y install httpd mariadb-server mariadb php php-mysql 
centos6上执行以下语句
[root@mysql1 ~]# yum install httpd mysql-server mysql php php-mysql -y
注:
httpd       # web 服务器
mariadb -server   #mysql 数据库
mariadb        # mysql 服务器 linux 下客户端
php      #php 相关文件
php-mysql                    #php 程序连接 mysql 使用的模块

查看某个命令由哪个包安装
[root@mysql1 ~]# rpm -qf `which mysql`

查看apache版本：
[root@mysql1 ~]# httpd -v

查看mysql数据版客户端版本
[root@mysql1 ~]# mysql -V

优化httpd启动效率 
改95 #ServerName www.example.com:80
为96 ServerName 192.168.245.175:80           #本机IP

启动服务LAMP相关服务：
[root@mysql1 ~]# systemctl start   httpd   

[root@mysql1 ~]# systemctl enable   httpd 

启动数据库服务

[root@mysql1 ~]# systemctl start   mariadb
[root@mysql1 ~]# systemctl enable   mariadb
[root@mysql1 ~]#systemctl status   mariadb



**1.3   实战-安装MySQL数据库并去除安全隐患**
1.3.1   Mariabd 安全配置向导
安装完mariadb -server后，运行mysql_secure_installation去除安全隐患。
[root@mysql1 ~]# rpm -qf /usr/bin/mysql_secure_installation   #查看此命令的安装 包
mariadb -server- 5.5.56-2 .el7.x86 64
[root@mysql1 ~]# systemctl start mariadb   
[root@mysql1 ~]# mysql_secure_installation mysql_secure_installation会执行几个设置：
a)为root用户设置密码 
b)删除匿名账号
c)取消root用户远程登录
d)删除test库和对test库的访问权限  （任何人都能登录，不安全，会被黑客入侵）
e)刷新授权表使修改生效
通过这几项的设置能够提高 MySQL 库的安全。建议生产环境中 MySQL 安装这完成后一定要 运行一次mysql_secure_installation ，
步骤请参看下面的命令:
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\3.png](https://s2.loli.net/2022/02/14/kXHxjScfARtuzMO.png)
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\4.png](https://s2.loli.net/2022/02/14/7zqEm6F4ZLwXATp.png)



测试数据库连接：
连接mysql数据库，连接本机可以去掉- h
\#mysql
或：
\# mysql - h IP - u USER -pPASS
Mysql的超级管理员是root拥有最MySQL数据库的最高权限。 
例：
\# mysql - u root -p123456 – h 192.168.245.175 
mysql> exit;     #退出MySQL

[root@mysql01 ~]# mysql -u root -p

```
MariaDB [(none)]> show databases;     #没有test数据库     #执行时，所有命令以；号结尾
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
+--------------------+
3 rows in set (0.00 sec)
MariaDB [(none)]> exit #退出命令可以加分号，也可以不加分号。

```



**1.4  实战1：升级MySQL版本到5.7版本并迁移数据**
1．创建数据库
MariaDB [(none)]> create database test1;
MariaDB [(none)]> use test1;
MariaDB [test1]> create table person(
    -> id int,
    -> name varchar(10)
    -> );
2..备份数据
mysqldump  -u  root  -p123456  -B迁移的库名> 导出名称.sql
举例：
[root@mysql ~]# mysqldump -u root -p123456 -B test1> /opt/test1.sql
[root@mysql01 ~]# ll /opt/test1.sql 
-rw-r--r-- 1 root root 1952 8月  26 15:45 /opt/test1.sql

3．删除旧版本mariadb
[root@mysql tmp]# yum -y remove mariadb*
[root@mysql tmp]# whereis mysql
mysql: /usr/lib64/mysql
[root@mysql tmp]# rm -rf /usr/lib64/mysql
[root@mysql opt]# find / -name '*mysql*'

3．yum 安装MySQL 5.7的方法

（1） CentOS 7版本下载
方法一：
[root@mysql~]#rpm -ivh https://repo.mysql.com//yum/mysql-5.7-community/el/7/x86_64/mysql57-community-release-el7-10.noarch.rpm

方法二：下载软件包，再拉进liunx里面安装：
[root@mysql tmp]# 
rpm -ivh mysql57-community-release-el7-10.noarch.rpm

[root@mysql ~]# yum list  #刷新yum 源缓存。
[root@mysql ~]# yum -y install mysql-community-server	#安装MySQL 5.7。
[root@mysql ~]# systemctl start mysqld	#启动MySQL会生成临时密码。



（2） 第一次通过# grep "password" /var/log/mysqld.log 命令获取MySQL的临时密码
[root@mysql ~]# grep 'password'  /var/log/mysqld.log 
2018-08-01T09:59:33.918961Z 1 [Note] A temporary password is generated for root@localhost: buL.UJp!T2Od	#临时密码
2018-08-01T09:59:40.752851Z 2 [Note] Access denied for user 'root'@'localhost' (using password: NO)

注：
若无法生成临时密码，则可能因为之前有安装过数据库，其中/var/lib/mysql的数据需要删除再重启mysql
[root@mysql ~]# rm -rf /var/lib/mysql
[root@mysql ~]# systemctl restart mysqld



[root@mysql ~]# mysql -u root -p'buL.UJp!T2Od'   #注意临时密码要引号

用该密码登录到服务端后，必须马上修改密码，不然操作查询时报错误
刚开始设置的密码必须符合长度，且必须含有数字，小写或大写字母，特殊字符。

（3） 如果想设置简单密码，如下操作：
方法一：首先，修改validate_password_policy参数的值
mysql> set global validate_password_policy=0;
Query OK, 0 rows affected (0.03 sec)

\# 定义复杂度的级别：
0：只检查长度。
1：检查长度、数字、大小写、特殊字符。
2：检查长度、数字、大小写、特殊字符字典文件

mysql> set global validate_password_length=1;#定义长度 默认是8位数；修改为1后密码长度>=4位数
Query OK, 0 rows affected (0.01 sec)

举例实验：
mysql>  ALTER USER 'root'@'localhost' IDENTIFIED BY '123';
ERROR 1819 (HY000): Your password does not satisfy the current policy requirements

mysql>  ALTER USER 'root'@'localhost' IDENTIFIED BY '123456';
Query OK, 0 rows affected (0.01 sec)
\#修改root用户密码

mysql> flush privileges; 
Query OK, 0 rows affected (0.01 sec)

方法二：在/etc/my.cnf 可关闭密码强度审计插件，重启MySQl服务。
在[myqld]末行;
validate-password=OFF     #不使用密码强度审计插件

[root@mysql ~]# systemctl restart mysqld
mysql> set password for 'root'@'localhost'= password('1');
Query OK, 0 rows affected, 1 warning (0.01 sec)
mysql> flush privileges; 
Query OK, 0 rows affected (0.01 sec)
注：用这种方法可以让密码长度至少为1位数      但在生产环境中决不可以用简单的密码



实例：输入密码报错

ERROR 1045 (28000): Access denied for user 'root'@'localhost' (using password: YES)

原因：需要输入密码，但密码敲错了

ERROR 1045 (28000): Access denied for user 'root'@'localhost' (using password: NO)

原因：不需要输入密码，但你输入密码





4．导入数据库
[root@mysql ~]#mysql -uroot -p123456 <导出名称.sql  #迁移数据库完成！

举例：
[root@mysql tmp]# mysql -uroot -p123456 </opt/test1.sql
[root@mysql ~]# mysql  -u root  -p123456

```
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
| test1              |
+--------------------+
5 rows in set (0.00 sec)

```



测试网站是否支持PHP
[root@mysql1 ~]#   cd /var/www/html/ 
[root@mysql1   html]# vim index.php
<?php              
    phpinfo();
?>      
测试：
[root@mysql1 html]# systemctl restart httpd 
重启 web 
http://192.168.1.63/index.php

**1.5  实战-搭建LAMP环境部署Ucenter和Ucenter -home网站**
搭建 LAMP 环境部署 Ucenter 和 Ucenter- home 网站，搭建一个类似微博网的社交网站
www.weibo.com
 ![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\5.png](https://s2.loli.net/2022/02/14/c4IkYf8ThjGv6PW.png)

UCenter  用户中心，实现用户的统一登录登出，积分的兑换，TAG的互通等，在安装UCenter  Home 、 Discuz! 、SupeSite、X -Space 等应用前必须先安装UCenter。本教程讲解的即是如何全新 安装UCenter1.5.0。
http://www.discuz.net
Discuz! 论坛，百万站长的选择，定会给您带来非凡的论坛体验。Discuz! 7.0.0 的推出使Discuz! 的用户体验又上升到了一个新的高度。本教程讲解的即是如何全新安装Discuz! 7.0.0 FULL （集成了  UCenter 安装的版本） 。
UCenter Home 个人家园 ，给社区中的会员一个可以安家的地方，在这里会员可以交朋友，写记 录，发日志，贴照片，玩游戏...使会员可以牢牢的黏在你的社区里。本教程讲解的即是如何全新安装   UCenter Home 1.5 。
SupeSite 社区门户，实现CMS  的功能，拥有强大的模型功能，对Discuz! 和UCenter Home  的 完美聚合，是您将社区中所有信息进行整合展示的最佳平台。
上传到 linux 上：

到服务器上/root目录下：
[root@mysql1 ~]# unzip -d ./ucenter   UCenter_1.5.2_SC_UTF8.zip
[root@mysql1 ~]# cd ./ucenter 
[root@mysql1 ucenter]# ls
advanced readme upload utilities
[root@mysql1 ucenter]# mkdir /var/www/html/ucenter   #创建目录 
[root@mysql1 ucenter]# cp -rp upload/* /var/www/html/ucenter   
[root@mysql1 ucenter]# cd /var/www/html/ucenter

修改文件权限：
[root@mysql1 ucenter]# ls - ld data
drwxr-xr-x 8 root root 99 1月   22 2009 data       
[root@mysql1 ucenter]# ps -aux | grep httpd
root      10971  0.0  0.6 332700 13468 ?        Ss   14:48   0:01 /usr/sbin/httpd -DFOREGROUND
apache    10973  0.0  0.5 334356 11872 ?        S    14:48   0:00 /usr/sbin/httpd -DFOREGROUND
apache    10975  0.0  0.5 334688 11940 ?        S    14:48   0:01 /usr/sbin/httpd -DFOREGROUND
root      11130  0.0  0.0 112676   984 pts/0    R+   15:54   0:00 grep --color=auto httpd
........

[root@mysql1 ucenter]#   id apache
uid=48(apache) gid=48(apache) 组=48(apache)
[root@mysql1 ucenter]# chown apache:apache data/ - R
或：
[root@mysql1 ucenter]# chmod - R 777 data     #给777权限可以吗？
\# 不可以777权限 很容易让黑客上传木马并提权   。

1.5.1   安装网站模版：
安装UCenter ：
打开：http://192.168.1.63/ucenter/install/
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\6.png](https://s2.loli.net/2022/02/14/8nqK4ku3WYdHsRF.png)
要安这个打开：
[root@mysql1 ~]# vim /etc/php.ini #php运用程序的配置文件
改：211 short_open_tag = Off
为：211 short_open_tag = On

开启 PHP 短标签功能。 开启 PHP 短标签功能 ： 禁用 PHP 短标签功能 ：
\#重新加载配置文件
php 代码开始标志的缩写形式       <? 。。。?>            php 代码开始标志的完整形式为：  <?php   。。。 ?>

[root@mysql1 ~]# systemctl reload   httpd     #实际工作中，不要restart ，尽量reload
测试：http://192.168.1.63/ucenter/install/
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\7.png](https://s2.loli.net/2022/02/14/8nqK4ku3WYdHsRF.png)

需要这个 data 目录可写：

![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\8.png](https://s2.loli.net/2022/02/14/zkFQlJsEqNZBCvO.png) 

说明：
1.数据库服务器：如果数据库和WEB不在同一台主机时，需要指定数据库服务器的连接IP
数据库用户名：如果数据库登录用户不是root时，需要指定对应的用户名

2.如果出现连接不了数据库的错

登录数据库，修改root可以远程连接

```
mysql> use mysql;
mysql> select host,user from user;
+-----------+---------------+
| host      | user          |
+-----------+---------------+
| localhost | root          |
| localhost | mysql.session |
| localhost | mysql.sys     |
+-----------+---------------+
mysql> update user set host='%' where user='root';
mysql> flush privileges;
```



![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\9.png](https://s2.loli.net/2022/02/14/kXf8tSG6KHR9dMl.png) 

注：这个注册码很不清楚，多按F5刷新几次就可以了
要记录创始人用户名：UCenter Administrator 密码：123456      
创建一个用户和密码。用于管理 UCenter Home                              
创建一个用户并设置密码，这个用户用于后期当 uchome 的管理员。

 


![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\10.png](https://s2.loli.net/2022/02/14/Yj9osCLB31SMgba.png) 

1.5.2   安装UCenter_Home_
[root@mysql1 ~]# unzip -d ./uchome UCenter_Home_2.0_SC_UTF8.zip 
[root@mysql1 ~]# cd ./uchome
[root@mysql1 uchome]# ls
2.0_changelog.txt read000000000000000000000000me.txt update upload


[root@mysql1 uchome]# cp -rp upload/* /var/www/html/ 
[root@mysql1 uchome]# cd /var/www/html/
[root@mysql1 html]# cp config.new.php config.php          
[root@mysql1 html]# chown apache:apache config.php     
[root@mysql1 html]# chown apache:apache   attachment/  data/   uc_client/ -R
 安装：
 http://192.168.1.63/install

![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\11.png](https://s2.loli.net/2022/02/14/qcna5YdiCFHgf89.png)

UCenter  的 URL ：http:// 192.168.1.63/ucenter
UCenter 创始人密码：123456

![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\12.png](https://s2.loli.net/2022/02/14/1fXGMOAanBrF4H8.png)



![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\13.png](https://s2.loli.net/2022/02/14/fLjiuqFW4IvMeRt.png)



补全discuz论坛安装步骤



### 2、mysql二进制包安装

#### 2.1.二进制包下载

![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\14.png](https://s2.loli.net/2022/02/14/cNJ2tT84FxYmIp3.png) 

#### 2.2.删除旧版本mariadb

[root@mysql tmp]# yum -y remove mariadb*
[root@mysql tmp]# whereis mysql
mysql: /usr/lib64/mysql
[root@mysql tmp]# rm -rf /usr/lib64/mysql
[root@mysql opt]# find / -name '*mysql*'

#### 2.3.解压二进制包

[root@mysql1 opt]# cd /opt && wget https://downloads.mysql.com/archives/get/p/23/file/mysql-5.7.30-linux-glibc2.12-x86_64.tar.gz

[root@mysql1 opt]#tar -zxvf mysql-5.7.30-linux-glibc2.12-x86_64.tar.gz -C /usr/local/
[root@cheichi opt]# cd /usr/local/
[root@mysql1 local]#mv mysql-5.7.30-linux-glibc2.12-x86_64 mysql
[root@mysql1 mysql]# pwd
/usr/local/mysql

#### 2.4.创建用户

[root@mysql1 mysql]# useradd mysql -s /sbin/nologin

#### 2.5.创建数据存储目录

[root@mysql1 mysql]# mkdir -p /data/mysql

#### 2.6.创建日志目录

[root@mysql1 mysql]# mkdir -p /var/log/mysql

#### 2.7.设置权限

[root@mysql1 mysql]# chown mysql:mysql -R /usr/local/mysql  /data/mysql  /var/log/mysql

#### 2.8.增加环境变量：

请使用多种方法：

[root@mysql1 mysql]# echo "export PATH=$PATH:/usr/local/mysql/bin" >>/etc/profile && source /etc/profile

#### 2.9.修改基本配置文件：    

vim /etc/my.cnf （mysql配置文件，安装完mysql后形成）
[mysqld]          #服务端配置      
user=mysql #指定用户
basedir=/usr/local/mysql        #应用程序所在目录
datadir=/data/mysql             #数据库数据存储目录路径
server_id=1                         #id号,主从中主要用，指定master id
port=3306                           #默认端口号
socket=/data/mysql/mysql.sock        #默认sock连接的接口

[mysql]         #客户端配置  
socket=/data/mysql/mysql.sock 

[mysqld_safe]
log-error=/var/log/mysql/mysql.log      #错误日志存放路径
pid-file=/data/mysql/mysql.pid          #进程pid文件

#### 2.10.初始化数据库：

第一种：
mysqld --initialize  --user=mysql --basedir=/usr/local/mysql --datadir=/data/mysql
会生成临时密码复杂密码，过期180天，需使用临时密码登录数据库并更改密码。
会严格管理密码，需要3种密码复杂度要求
修改管理员密码：ALTER USER 'root'@'localhost' IDENTIFIED BY '123456';

第二种：
不生成临时密码初始化方法：
mysqld --initialize-insecure  --user=mysql --basedir=/usr/local/mysql --datadir=/data/mysql

报错
[root@mysql1 mysql]# mysqld --initialize-insecure  --user=mysql --basedir=/usr/local/mysql --datadir=/data/mysql
mysqld: error while loading shared libraries: libaio.so.1: cannot open shared object file: No such file or directory

安装依赖包
[root@mysql1 bin]# yum install libaio libaio-devel -y



#### 2.11.复制启动脚本并使用systemctl管理

[root@mysql1 mysql]# cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld(编译安装mysql.server会变成mysql.server.sh 记得改)
[root@mysql1 mysql]# chmod +x /etc/init.d/mysqld
[root@mysql1 mysql]# chkconfig --add mysqld   （开机自启）

#### 2.12.启动数据库

[root@mysql1 mysql]# systemctl start mysqld

#### 2.13.两种登录方法：

Socket方式(仅本地)：不依赖于ip和端口
mysql -uroot -p -S /data/mysql/mysql.sock
TCP/IP方式（远程、本地）：
mysql -uroot -p -h 远程数据ip -P3306

\#systemctl restart mysql
[root@mysql1 mysql]# mysql -u root -p
ERROR 2002 (HY000): Can't connect to local MySQL server through socket '/data/mysql/mysql.sock' (2)
[root@mysql1 mysql]# mysql -uroot  -S /data/mysql/mysql.sock

### 3、源码安装MySQL5.7：

从MySQL5.7版本开始，安装MySQL需要依赖 Boost  的C++扩展
[Boost库](https://baike.baidu.com/item/Boost库)是一个可移植、提供[源代码](https://baike.baidu.com/item/源代码)的C++库，作为标准库的后备，是C++标准化进程的开发引擎之一。 
Boost库由C++标准委员会库工作组成员发起，其中有些内容有望成为下一代C++标准库内容。
在C++社区中影响甚大，是不折不扣的“准”标准库。Boost由于其对跨平台的强调，对标准C++的强调，与编写平台无关。

![image-20220823093930124](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202208230939222.png)

#### **3.1从mysql 5.5起，mysql 源码安装开始使用 cmake了**

删除旧版本mariadb
[root@mysql tmp]# yum -y remove mariadb*
[root@mysql tmp]# whereis mysql
mysql: /usr/lib64/mysql
[root@mysql tmp]# rm -rf /usr/lib64/mysql
[root@mysql opt]# find / -name '*mysql*'

#### 3.2.安装相关依赖：

[root@mysql1 local]# yum -y install gcc-c++  ncurses   ncurses-devel cmake

#### 3.3.解压包：

[root@mysql1 local]#tar -xf mysql-boost-5.7.30.tar.gz -C /opt
[root@mysql1 local]#mv mysql-5.7.30  mysql

mysql-boost-5.7.30.tar.gz包含了boost库

![image-20220823174045793](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202208231740845.png)

进入到解压以后的mysql目录，执行以下操作。

#### 3.4.cmake编译，添加相关参数：

[root@houst local]# cd mysql
cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \ #设定程序安装路径
-DMYSQL_DATADIR=/data/mysql \ #设定mysql数据存储目录
-DDEFAULT_CHARSET=utf8 \ #设定默认字符集
-DDEFAULT_COLLATION=utf8_general_ci \ #设定字符集引擎
-DMYSQL_TCP_PORT=3306 \ #设定默认端口
-DMYSQL_UNIX_ADDR=/data/mysql/mysql.sock \ #设定套接字文件目录
-DWITH_MYISAM_STORAGE_ENGINE=1 \ #开启myisam引擎默认支持
-DWITH_INNOBASE_STORAGE_ENGINE=1 \ #开启innodb引擎的默认支持
-DDOWNLOAD_BOOST=1 \ #开启默认下载boost
-DWITH_BOOST=/opt/mysql/boost \ #设定boost包存放位置
-DWITH_INNODB_MEMCACHED=ON #开启innodb缓存

```
[root@mysql1 opt]# cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_DATADIR=/data/mysql -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DMYSQL_TCP_PORT=3306 -DMYSQL_UNIX_ADDR=/data/mysql/mysql.sock -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DDOWNLOAD_BOOST=0 -DWITH_BOOST=/opt/mysql/boost -DWITH_INNODB_MEMCACHED=ON 

```

**注：下载boost可以使用迅雷下载后，再解压到指定目录，此时需关闭默认下载**

报错：openssl以及openssl扩展未安装
解决：yum install openssl openssl-devel -y

![image-20220221164450658](https://s2.loli.net/2022/02/21/d1mchAKRVTLxnog.png)

报错：warning bison 不存在
解决：yum install bison* -y

编译失败时，需要执行make clean，然后删除CMakeCache.txt文件

进行完这个后，再make  后在进行make install 

#### 3.5.从二进制包安装2.4开始执行步骤

