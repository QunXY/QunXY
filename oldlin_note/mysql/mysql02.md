### **1、mysql数据库密码修改与找回**

#### **1.1、****修改密码：**

##### 方法1：

mysql> ALTER USER 'root'@'localhost' IDENTIFIED BY '123456';(第一次临时密码登录,需要先使用此命令修改)

![image-20220222111432966](https://s2.loli.net/2022/02/22/tcTCSnIEj4ANxly.png)

##### 方法2：

[root@mysql1 ~]# mysqladmin -u root -p'123456' password '456789' 

报错情况：

```mysql
[root@mysql02 ~]# mysqladmin -uroot -p'123456' password '456789'   #有一些命令默认连数据库是用/tmp/mysql.sock
mysqladmin: [Warning] Using a password on the command line interface can be insecure.
mysqladmin: connect to server at 'localhost' failed
error: 'Can't connect to local MySQL server through socket '/tmp/mysql.sock' (2)'
Check that mysqld is running and that the socket: '/tmp/mysql.sock' exists!
```

解决方案：

```mysql
[root@mysql02 ~]# mysqladmin -uroot -p'123456' password '456789' -S /data/mysql/mysql.sock  (放出警告但是已经修改成功)
mysqladmin: [Warning] Using a password on the command line interface can be insecure.
Warning: Since password will be sent to server in plain text, use ssl connection to ensure password safety.
```



实战：数据库卡死，如何解决

```mysql
[root@mysql2 ~]# mysql -uroot -p147369
mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 2
Server version: 5.7.30 MySQL Community Server (GPL)

Copyright (c) 2000, 2020, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> 


[root@mysql2 ~]# mysqladmin  -uroot -p'147369' shutdown -S /data/mysql/mysql.sock

在数据库里执行命令：
mysql> show databases;
ERROR 2006 (HY000): MySQL server has gone away
No connection. Trying to reconnect...
ERROR 2002 (HY000): Can't connect to local MySQL server through socket '/data/mysql/mysql.sock' (2)
ERROR: 
Can't connect to the server

```



##### 方法3：

mysql> update  mysql.user  set  password=PASSWORD("aa123456")  where user='root'  ;
ERROR 1054 (42S22): Unknown column 'password' in 'field list'
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\2.png](https://s2.loli.net/2022/02/14/uIHOX4Ml6xj9GsZ.png)
注：因为在mysql5.7的user表中的password字段已经更改成为authentication_string。所以需要下面这种写法

mysql> update  mysql.user  set  authentication_string=PASSWORD("123456")  where user='root'  ;
mysql> flush privileges;
或
mysql> update  mysql.user  set  authentication_string=PASSWORD("aa123456")  where user='root'  ;flush privileges;
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\3.png](https://s2.loli.net/2022/02/14/BIVdXn6itFmWAzZ.png)



#### **1.2、找回密码**

##### 方法1：

往配置文件/etc/my.cnf中添加参数：
[mysqld]
skip-grant-tables			#忽略用户权限表
[root@mysql1 ~]# systemctl reload mysqld  （重新载入不行）
[root@mysql1 ~]# mysql -uroot -p
Enter password: 				<font color='red'>#不敲密码</font>
ERROR 1045 (28000): Access denied for user 'root'@'localhost' (using password: NO)
[root@mysql1 ~]# systemctl restart  mysqld
[root@mysql1 ~]# mysql -uroot -p' '   <font color='red'>密码有一个空格，代表为空</font>
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 2
Server version: 5.7.30 MySQL Community Server (GPL)

Copyright (c) 2000, 2020, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> 此时可以用修改密码的方法去改密码

<font color='red'>重启数据库服务，可以实现无密码登录，对密码进行修改后，需要将skip-grant-tables参数删除</font>

##### 方法2：（注意杀死进程）

mysql_safe安全模式启动
[root@mysql1 ~]# systemctl stop mysqld                              #先关闭mysqld服务
[root@mysql1 ~]# mysqld_safe  --skip-grant-tables            #忽略用户权限表
                                            --skip-networking &                        #增加忽略远程登录参数，不允许远程登录

[root@mysql1 ~]# mysql -uroot -p                            #这时可以使用空密码登录
mysql> ALTER USER 'root'@'localhost' IDENTIFIED BY '123456';
ERROR 1290 (HY000): The MySQL server is running with the --skip-grant-tables option so it cannot execute this statement
mysql> flush privileges;                    #首先手工加载权限表

mysql> alter user root@'localhost' identified by '123456';          #再修改密码

[root@mysql1 ~]# systemctl restart mysqld
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\5.png](https://s2.loli.net/2022/02/14/Ji5CagAjUG12STp.png)

#### **1.3、免密登录**

##### 方法1：（企业中一般不允许做）

往配置文件/etc/my.cnf中添加参数：
[mysql]
password=123456
注意这里会又以前的mysql进程会和现进程产生冲突，使用ps -axu |grep mysql 再用kill 进程号
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\6.png](https://s2.loli.net/2022/02/14/Na87C3DcHOKrmfX.png)
[root@mysql1 ~]# systemctl restart mysqld
[root@mysql1 ~]# mysql   -uroot        #登录服务端

```
[root@mysql02 ~]# mysql -uroot 
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 3
Server version: 5.7.30 MySQL Community Server (GPL)

Copyright (c) 2000, 2020, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> 

```

##### 方法2：（在方法一之后运行时记得重启服务器）

[root@mysql1 ~]# mysql_config_editor set -G vml  -u root -p
Enter password:

配置完成之后就会在这个用户家目录下面生成一个.mylogin.cnf的二进制文件
[root@mysql1 ~]# ll -a ~/.mylogin.cnf
-rw------- 1 root root 100 8月  30 01:55 /root/.mylogin.cnf
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\8.png](https://s2.loli.net/2022/02/14/LEl5tg1F3QmOXpf.png)

print之后就可以发现，我们创建了一个标签，标签的名字就是vml，密码是加密的，我们这样就看不到密码了，并且这种存储方式是二进制的，相对比较安全
[root@mysql1 ~]# mysql_config_editor print --all
[vml]
user = root
password = **********

可以通过--login-path=vml这种方式进行免密码登录数据库　
[root@mysql1 ~]# mysql --login-path=vml



### 2**、数据库用户与权限管理**

#### 2.1、数据库用户管理

##### 2.1.1、查询数据库用户

mysql>select user,host,authentication_string from mysql.user;

![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\9.png](https://s2.loli.net/2022/02/14/DFLJHz59QI2bfBo.png)

##### 2.1.2、创建新用户

mysql>create user today@'localhost' identified by '123456';

![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\10.png](https://s2.loli.net/2022/02/14/wDT6tOqXUBe179R.png)

##### 2.1.3、更改用户账户密码

mysql>alter user today@'localhost' identified by '123';

![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\11.png](https://s2.loli.net/2022/02/14/inXgQWAEqT6ezdp.png)

##### 2.1.4、删除用户

mysql>drop user today@'localhost';

#### **2.2、权限管理**

mysql数据库是基于用户管理数据库权限，比如授权哪个用户管理哪个数据库，或者哪个用户对这个数据库有哪些操作权限
<font color='red'>注：在8.0之前是可以用授权grant建立用户并授权。8.0必须先建立用户再授权。</font>

授权语法：
grant  权限 on 对象 to 用户 identified by '密码'

##### 2.2.1、查看可授权限命令：

mysql>show privileges;
我们需要关注的权限：
alter,create,delete,drop,select,show,update.
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\12.png](https://s2.loli.net/2022/02/14/ucDlUkKQsCMdWvT.png)
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\13.png](https://s2.loli.net/2022/02/14/rncOMFfBi5Cs8eX.png)
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\14.png](https://s2.loli.net/2022/02/14/m4ShIZly5uCctkn.png)
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\15.png](https://s2.loli.net/2022/02/14/JpSYyd2s7AKFtkI.png)
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\16.png](https://s2.loli.net/2022/02/14/anUgJDA1bIWRyOC.png)
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\17.png](https://s2.loli.net/2022/02/14/6Q2zYuBCHZ13WDl.png)
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\18.png](https://s2.loli.net/2022/02/14/sIez1VMT2gPN85d.png)

##### 2.2.2、所有权限

ALL:
SELECT,INSERT, UPDATE, DELETE, CREATE, DROP, RELOAD, SHUTDOWN, 
PROCESS, FILE, REFERENCES, INDEX, ALTER, SHOW DATABASES, SUPER, 
CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, REPLICATION SLAVE, 
REPLICATION CLIENT, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, 
CREATE USER, EVENT, TRIGGER, CREATE TABLESPACE
ALL : 以上所有权限，一般是普通管理员拥有的
with grant option：超级管理员才具备的，给别的用户授权的功能

##### 2.2.3、对象：（只针对于库或者表）

\*.* 所有库权限
xxx.* 某库权限    
xxx.user xxx库的user表权限  mysql.user
xxx.user() 给某字段授权（用的很少）

##### 2.2.4、用户名@'白名单'

白名单支持的方式（地址列表允许白名单的ip登录）
举例：
today@'192.168.245.%' ：192.168.245.xx/24网段登录 
today@'%' ：任意地址
today@'192.168.245.200' ：只能通过该地址远程登录
today@'localhost' ：只能够通过本地登录（socket）
today@'mysql02' ：主机名
today@'192.168.245.7%' ：192.168.245.70-79网段登录

授权：（面试或笔试会考）
mysql> grant all on mysql.* to today@'192.168.245.%' identified by '123456';
grant all on mysql.* to today@'192.0168.78.%' identified by '123456';
mysql> grant all on *.* to today@'192.168.245.%' identified by '123456';
grant all on *.* to today@'192.168.78.%' identified by '123456';

##### 2.2.5、查看权限

mysql> show grants for today@'192.168.245.%';
![file://c:\users\admini~1\appdata\local\temp\tmpmc9tnh\19.png](https://s2.loli.net/2022/02/14/HUdYb3azqhsy9fr.png)

##### 2.2.6、回收权限

mysql>revoke select on mysql.* from today@'192.168.245.%';

mysql> select * from mysql.user;
ERROR 1142 (42000): SELECT command denied to user 'today'@'192.168.245.%' for table 'user'

### **3、数据库与shell的交互**

mysql常用参数：
-u                   用户
-p                   密码
-h                   IP
-P （大写）  端口
-S                   socket文件
<font color='red'>-e                  免交互执行命令</font>
<font color='red'><                    导入SQL脚本</font>
命令使用示例：
mysql -uroot -p -e "select user,host from mysql.user;"
Enter password:
mysql -uroot -p <world.sql
Enter password:

使用脚本运行数据库语句
[root@mysql1 opt]# cat a.sh 
\#!/bin/bash
mysql -uroot -p <<EOF
show databases;
EOF



实战：
为什么mysql启动会优先寻找/etc/my.cnf文件？
查看寻找配置文件顺序命令：
mysqld --help --verbose |grep my.cnf
/etc/my.cnf /etc/mysql/my.cnf /usr/local/mysql/etc/my.cnf ~/.my.cnf 
                      my.cnf, $MYSQL_TCP_PORT, /etc/services, built-in default
注:
默认情况下，MySQL启动时，会依次读取以上配置文件，如果文件内容有重复选项，
会以最后一个文件设置的为准。

但是，如果启动时加入了--defaults-file=xxxx时，以上的所有文件都不会读取，以默认文件为主.



### 4、多实例安装：

需求：一般来说是公司节省资源或者有其他需求，一台服务器安装多台数据库服务器实例。
前提：数据库版本唯一，（比如只有5.7）开启多实例。
操作步骤：

#### 4.1.关闭原有数据库，

systemctl  stop mysqld

#### 4.2.备份原有的my.cnf文件

cp /etc/my.cnf /etc/my.cnf.bak

#### 4.3.创建各个数据库实例所需目录。

mkdir -p /data/330{7,8,9}/data

#### 4.4.准备各个实例的配置文件：

cat > /data/3307/my.cnf <<EOF
[mysqld]
basedir=/usr/local/mysql
datadir=/data/3307/data
socket=/data/3307/mysql.sock
log_error=/data/3307/mysql.log

pid-file=/data/3307/mysql.pid

port=3307
server_id=7
log_bin=/data/3307/mysql-bin
EOF

cat > /data/3308/my.cnf <<EOF
[mysqld]
basedir=/usr/local/mysql
datadir=/data/3308/data
socket=/data/3308/mysql.sock
log_error=/data/3308/mysql.log

pid-file=/data/3308/mysql.pid

port=3308
server_id=8
log_bin=/data/3308/mysql-bin
EOF

cat > /data/3309/my.cnf <<EOF
[mysqld]
basedir=/usr/local/mysql
datadir=/data/3309/data
socket=/data/3309/mysql.sock
log_error=/data/3309/mysql.log

pid-file=/data/3309/mysql.pid

port=3309
server_id=9
log_bin=/data/3309/mysql-bin
EOF

#### 4.5.进行数据库初始化

/usr/local/mysql/bin/mysqld --initialize-insecure  --user=mysql --datadir=/data/3307/data --basedir=/usr/local/mysql
/usr/local/mysql/bin/mysqld --initialize-insecure  --user=mysql --datadir=/data/3308/data --basedir=/usr/local/mysql
/usr/local/mysql/bin/mysqld --initialize-insecure  --user=mysql --datadir=/data/3309/data --basedir=/usr/local/mysql

#### 4.6.授权刚才创建的目录。（更改目录用户以及用户组）

chown -R mysql.mysql /data/*

#### 4.7.创建systemd启动脚本(模板文件)：（基于centos7的方法）

vim /usr/lib/systemd/system/mysqld.service 
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
ExecStart=/xxx/bin/mysqld --defaults-file=/etc/my.cnf（多实例更改此处）
LimitNOFILE = 5000

[Unit] ： 服务的说明

 Description:描述服务 
 After:描述服务类别，在什么服务启动后再启动** 

 **[Service]服务运行参数的设置 
 Type=forking是后台运行的形式 
 ExecStart为服务的具体运行命令 
 ExecReload为重启命令
 ExecStop为停止命令 
 PrivateTmp=True表示给服务分配独立的临时空间
 <font color='red'>注意：[Service]的启动、重启、停止命令全部要求使用绝对路径</font> 
 [Install]运行级别下服务安装的相关设置，可设置为多用户，即系统运行级别为3**

**<font color='red'>注意： 对于新创建的service 文件，或者修改了的service文件，要通知systemd 重载此配置文件,而后可以选择重启</font>**

    [root@exercise1 ~]# systemctl daemon-reload 如下4.9

#### 4.8.生成各个实例的启动脚本：

cd /usr/lib/systemd/system/
cp mysqld.service mysqld3307.service
cp mysqld.service mysqld3308.service
cp mysqld.service mysqld3309.service
更改ExecStart处。
vim mysqld3307.service
ExecStart=/usr/local/mysql/bin/mysqld  --defaults-file=/data/3307/my.cnf
vim mysqld3308.service
ExecStart=/usr/local/mysql/bin/mysqld   --defaults-file=/data/3308/my.cnf
vim mysqld3309.service
ExecStart=/usr/local/mysql/bin/mysqld   --defaults-file=/data/3309/my.cnf

#### 4.9.启动服务：

需要重新载入systemd的脚本配置：
systemctl daemon-reload

#### 4.10.启动各个实例：

systemctl start mysqld3307.service
systemctl start mysqld3308.service
systemctl start mysqld3309.service

#### 4.11.验证：

netstat -lnp|grep 330*
mysql -S /data/3307/mysql.sock -e "select @@server_id"
mysql -S /data/3308/mysql.sock -e "select @@server_id"
mysql -S /data/3309/mysql.sock -e "select @@server_id"