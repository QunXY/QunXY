# 搭建Gtid（一主两从）+MHA高可用架构+atlas读写分离

## 一、前置环境搭建（gtid一主两从架构）

### 1.准备三台安装MySQL-5.7.38（同版本即可）的服务器，备份配置文件并清空环境。

```shell
服务器1：
[root@superwei-mk1 ~]# cp /etc/my.cnf /etc/my.cnf.bak
服务器2：
[root@superwei-mk2 ~]# cp /etc/my.cnf /etc/my.cnf.bak
服务器3：
[root@superwei-mk3 ~]# cp /etc/my.cnf /etc/my.cnf.bak
```

### 2.关闭三台服务器的安全配置（或者加入白名单）若已关闭则忽略

```
systemctl stop firewalld
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
systemctl disable firewalld
```

### 3.修改配置文件

```shell
# 注意自行修改路径！
# 服务器1配置文件：
[mysqld]
basedir=/usr/local/mysql
datadir=/usr/local/mysql/data
port=3306
socket=/usr/local/mysql/tmp/mysql.sock
log-error=/var/log/mysqld.log
pid-file=/usr/local/mysql/tmp/mysqld.pid
server-id=7
secure-file-priv=/tmp
autocommit=0
binlog_format=row
log-bin=/usr/local/mysql/mysql-bin
gtid-mode=on
enforce-gtid-consistency=true
# gtid的事务直接刷新到日志里，不进行缓存，高性能模式。
log-slave-updates=1

[mysql]
socket=/usr/local/mysql/tmp/mysql.sock
prompt=主库01 [\\d]>

[client]
socket=/usr/local/mysql/tmp/mysql.sock

# 服务器2配置文件：
[mysqld]
basedir=/usr/local/mysql
datadir=/usr/local/mysql/data
port=3306
socket=/usr/local/mysql/tmp/mysql.sock
log-error=/var/log/mysqld.log
pid-file=/usr/local/mysql/tmp/mysqld.pid
server-id=7
secure-file-priv=/tmp
autocommit=0
binlog_format=row
log-bin=/usr/local/mysql/mysql-bin
gtid-mode=on
enforce-gtid-consistency=true
log-slave-updates=1

[mysql]
socket=/usr/local/mysql/tmp/mysql.sock
prompt=从库01 [\\d]>

[client]
socket=/usr/local/mysql/tmp/mysql.sock

# 服务器3配置文件：
[mysqld]
basedir=/usr/local/mysql
datadir=/usr/local/mysql/data
port=3306
socket=/usr/local/mysql/tmp/mysql.sock
log-error=/var/log/mysqld.log
pid-file=/usr/local/mysql/tmp/mysqld.pid
server-id=7
secure-file-priv=/tmp
autocommit=0
binlog_format=row
log-bin=/usr/local/mysql/mysql-bin
gtid-mode=on
enforce-gtid-consistency=true
log-slave-updates=1

[mysql]
socket=/usr/local/mysql/tmp/mysql.sock
prompt=从库02 [\\d]>

[client]
socket=/usr/local/mysql/tmp/mysql.sock
```

### 4.初始化数据库

​		<font color='red'>如果--datadir=" "目录下有重要文件请及时备份，然后清空该目录。</font>

```shell
服务器1：
[root@superwei-mk1 ~]# /usr/local/mysql/bin/mysqld --initialize-insecure --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data
服务器2：
[root@superwei-mk2 ~]# /usr/local/mysql/bin/mysqld --initialize-insecure --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data
服务器3：
[root@superwei-mk3 ~]# /usr/local/mysql/bin/mysqld --initialize-insecure --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data
```

### 5.重启MySQL服务

```shell
服务器1：
[root@superwei-mk1 ~]# systemctl restart mysqld
服务器2：
[root@superwei-mk1 ~]# systemctl restart mysqld
服务器3：
[root@superwei-mk1 ~]# systemctl restart mysqld

注：如提示无mysqld服务，请现将mysqld添加至systend管理：
cp mysql/support-files/mysql.server /etc/init.d/mysqld
vim /usr/lib/systemd/system/mysqld.service
写入：
[Unit]
Description=MySQL Server
Documentation=man:mysqld(8)
Documentation=https://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target
[Install]
WantedBy=multi-user.target
[Service]
User=mysql
Group=mysql
ExecStart=/usr/local/mysql/bin/mysqld --defaults-file=/etc/my.cnf
LimitNOFILE = 5000

systemctl daemon-reload
systemctl start mysqld
systemctl status mysqld
```

### 6.构建主从：

主库创建用户（这里以Superwei-mk1为主库）：

```sql
(Superwei-mk1) [(none)]>grant replication slave on *.*  to repl@'%' identified by '123';

# 服务器2（mk2）创建主从关系（自动寻找binlog并备份）：
change master to
    ->  master_host='192.168.32.233',
    ->  master_user='repl',
    ->  master_password='123'
    ->  MASTER_AUTO_POSITION=1;

start slave；

# 服务器3（mk3）建立主从关系（指定binlog）：
CHANGE MASTER TO
    MASTER_HOST='192.168.32.233',
    MASTER_USER='repl',
    MASTER_PASSWORD='123',
    MASTER_LOG_FILE='mysql-bin.000001',
    MASTER_LOG_POS=154;
    MASTER_CONNECT_RETRY=10;
    
start slave；
```

服务器2（mk2）创建主从关系（自动寻找binlog并备份）：

```sql
(Superwei-mk2) [(none)]> change master to
    master_host='192.168.32.233',
    master_user='repl',
    master_password='123'
    MASTER_AUTO_POSITION=1;
(Superwei-mk2) [(none)]> start slave；
```

![image-20220828184829041](https://typora-1312877226.cos.ap-guangzhou.myqcloud.com/%E4%BD%9C%E4%B8%9A/image-20220828184829041.png)

服务器3（mk3）建立主从关系（指定binlog）：

```sql
(Superwei-mk3) [(none)]> CHANGE MASTER TO
    MASTER_HOST='192.168.32.233',
    MASTER_USER='repl',
    MASTER_PASSWORD='123',
    MASTER_LOG_FILE='mysql-bin.000001',
    MASTER_LOG_POS=154;
    MASTER_CONNECT_RETRY=10;   
(Superwei-mk3) [(none)]> start slave；
```

![image-20220828184841351](https://typora-1312877226.cos.ap-guangzhou.myqcloud.com/%E4%BD%9C%E4%B8%9A/image-20220828184841351.png)

```shell
# 注：开始我们可能会遇到密码丢失或不给登录的情况，如下报错。
ERROR 1045 (28000): Access denied for user 'root'@'localhost' (using password: YES)
# 解决方法：
# 开启后台运行模式：
mysqld_safe --skip-grant-tables --skip-networking&
# 在新窗口输入mysql进入数据库
# 然后切换到mysql数据库将密码清空：
use mysql;
update user set authentication_string='' where user='root';
# 设置加密规则并更新新密码，授权(直接复制这些SQL语句你的密码会更新为123456)
ALTER USER 'root'@'localhost' IDENTIFIED BY '123456' PASSWORD EXPIRE NEVER; 
alter user 'root'@'localhost' identified by '123456';
grant all privileges  on *.*  to "root"@'localhost';
flush privileges;
```

## 二、搭建mha

### 1.进入/etc/hosts添加以下内容

```shell
主机1：
192.168.32.233 superwei-mk1
192.168.32.144 superwei-mk2
192.168.32.152 superwei-mk3
主机2：
192.168.32.233 superwei-mk1
192.168.32.144 superwei-mk2
192.168.32.152 superwei-mk3
主机3：
192.168.32.233 superwei-mk1
192.168.32.144 superwei-mk2
192.168.32.152 superwei-mk3
```

### 2.在三台服务器上执行下面命令生成公钥，选用mk2作为manager。

```shell
[root@superwei-mk1 ~]# ssh-keygen -t rsa
[root@superwei-mk2 ~]# ssh-keygen -t rsa
[root@superwei-mk3 ~]# ssh-keygen -t rsa
服务器1将秘钥发送给服务器2：
[root@superwei-mk1 ~]# cd
[root@superwei-mk1 ~]# cd .ssh
[root@superwei-mk1 ~]# scp id_rsa.pub 192.168.32.144:/root/.ssh/mk1.pub
服务器3将秘钥发送给服务器2：
[root@superwei-mk3 ~]# cd
[root@superwei-mk3 ~]# cd .ssh
[root@superwei-mk3 ~]# scp id_rsa.pub 192.168.32.144:/root/.ssh/mk3.pub
服务器2生成新的公钥文件：
[root@superwei-mk2 ~]# cat *.pub >> authorized_keys
将新的公钥文件拷贝到其他几个主机的.ssh目录下即可
[root@superwei-mk2 ~]# scp authorized_keys superwei-mk1:/root/.ssh/
[root@superwei-mk2 ~]# scp authorized_keys superwei-mk3:/root/.ssh/
```

![image-20220828192655195](https://typora-1312877226.cos.ap-guangzhou.myqcloud.com/%E4%BD%9C%E4%B8%9A/image-20220828192655195.png)

测试一下：

```shell
[root@superwei-mk1 .ssh]# ssh superwei-mk2 date
The authenticity of host 'superwei-mk2 (192.168.32.144)' can't be established.
ECDSA key fingerprint is SHA256:pB24Cqcc73QvYl98NHmgldX1mVg9WUbiqq7KxrFHOe4.
ECDSA key fingerprint is MD5:26:26:79:69:2f:79:0a:04:bf:2f:be:2c:de:b9:6c:2f.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'superwei-mk2' (ECDSA) to the list of known hosts.
2022年 08月 28日 星期日 19:29:01 CST
[root@superwei-mk1 .ssh]# ssh superwei-mk3 date
The authenticity of host 'superwei-mk3 (192.168.32.152)' can't be established.
ECDSA key fingerprint is SHA256:Hej2t6F9m23s1Jb11DkZ6YtmTqVqklYnZFw0w6AuDfc.
ECDSA key fingerprint is MD5:7e:98:05:b8:a3:2a:32:42:75:45:c7:a1:93:75:00:f6.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'superwei-mk3,192.168.32.152' (ECDSA) to the list of known hosts.
2022年 08月 28日 星期日 19:29:24 CST
```

![image-20220828193017031](https://typora-1312877226.cos.ap-guangzhou.myqcloud.com/%E4%BD%9C%E4%B8%9A/image-20220828193017031.png)

### 3.三台服务器都做好软链接

```shell
[root@superwei-mk1 ~]# ln -s /usr/local/mysql/bin/mysqlbinlog /usr/bin/mysqlbinlog
[root@superwei-mk1 ~]# ln -s /usr/local/mysql/bin/mysql /usr/bin/mysql

[root@superwei-mk2 ~]# ln -s /usr/local/mysql/bin/mysqlbinlog /usr/bin/mysqlbinlog
[root@superwei-mk2 ~]# ln -s /usr/local/mysql/bin/mysql /usr/bin/mysql

[root@superwei-mk3 ~]# ln -s /usr/local/mysql/bin/mysqlbinlog /usr/bin/mysqlbinlog
[root@superwei-mk3 ~]# ln -s /usr/local/mysql/bin/mysql /usr/bin/mysql
```

### 4.下载mha-0.58及其依赖并安装。

```shell
# 服务器1：
[root@superwei-mk1 ~]# mkdir /mha
[root@superwei-mk1 ~]# cd /mha
# 下载mha-node需要的依赖。
[root@superwei-mk1 mha]# yum install perl-DBD-MySQL -y
# 解压mha-node包：
[root@superwei-mk1 mha]# rpm -ivh mha4mysql-node-0.58-0.el7.centos.noarch.rpm
# 数据库主节点授权：
mysql -uroot -p123456 -e "grant all privileges on *.* to mha@'%' identified by 'mha';"

# 服务器2（服务器2要多解压一个mha4mysql-manager包）：
[root@superwei-mk2 ~]# mkdir /mha
[root@superwei-mk2 ~]# cd /mha
# 下载mha-node需要的依赖。
[root@superwei-mk2 mha]# yum install perl-DBD-MySQL -y
# 解压mha-node包：
[root@superwei-mk2 mha]# rpm -ivh mha4mysql-node-0.58-0.el7.centos.noarch.rpm
# 把所有依赖都下下来。
[root@superwei-mk2 mha]# yum install *perl*
[root@superwei-mk2 mha]# rpm -ivh epel-release-7-14.noarch.rpm
[root@superwei-mk2 mha]# rpm -ivh perl-Config-Tiny-2.14-7.el7.noarch.rpm
[root@superwei-mk2 mha]# rpm -ivh perl-Time-HiRes-1.9725-3.el7.x86_64.rpm
[root@superwei-mk2 mha]# rpm -ivh perl-Parallel-ForkManager-1.18-2.el7.noarch.rpm
[root@superwei-mk2 mha]# rpm -ivh perl-MIME-Types-1.38-2.el7.noarch.rpm
[root@superwei-mk2 mha]# rpm -ivh perl-Mail-Sendmail-0.79-21.el7.noarch.rpm

# 服务器3：
[root@superwei-mk3 ~]# mkdir /mha
[root@superwei-mk3 ~]# cd /mha
下载mha-node需要的依赖。
[root@superwei-mk3 mha]# yum install perl-DBD-MySQL -y
解压mha-node包：
[root@superwei-mk3 mha]# rpm -ivh mha4mysql-node-0.58-0.el7.centos.noarch.rpm
```

### 5.配置manager端的配置文件。

```shell
# 创建配置目录：
[root@superwei-mk2 mha]# mkdir /etc/mha
# 创建日志目录
[root@superwei-mk2 mha]# mkdir -p /var/log/mha/app1
创建mha配置文件：
[root@superwei-mk2 mha]# vim /etc/mha/app1.cnf
写入：
[server default]
manager_log=/var/log/mha/app1/manager
manager_workdir=/var/log/mha/app1
master_binlog_dir=/usr/local/mysql/mysql-bin
user=mha
password=mha
ping_interval=2
repl_password=123
repl_user=repl
ssh_user=root
[server1]
hostname=192.168.32.233
port=3306
[server2]
hostname=192.168.32.144
port=3306
[server3]
hostname=192.168.32.152
port=3306
```

检查配置

```shell
[root@superwei-mk2 mha]# masterha_check_ssh  --conf=/etc/mha/app1.cnf
```

![image-20220828202826295](https://typora-1312877226.cos.ap-guangzhou.myqcloud.com/%E4%BD%9C%E4%B8%9A/image-20220828202826295.png)

```shell
# masterha_check_repl  --conf=/etc/mha/app1.cnf 
```

出现报错：

![image-20220829133607530](https://typora-1312877226.cos.ap-guangzhou.myqcloud.com/%E4%BD%9C%E4%B8%9A/image-20220829133607530.png)

观察错误发现是144主机上没有repl用户。

解决方法：

应该是在创建gtid主从架构时repl用户信息没有同步过来，在233主机上面再创一个repl，让其他从机同步就行了。

```sql
在主服务器：
mysql > grant replication slave on *.*  to repl@'%' identified by '123';
```

![image-20220829133803236](https://typora-1312877226.cos.ap-guangzhou.myqcloud.com/%E4%BD%9C%E4%B8%9A/image-20220829133803236.png)

## 三、搭建atlas实现读写分离

### 1.在manage节点下载并解压安装包：

``` 
rpm -ivh Atlas-2.2.1.el6.x86_64.rpm
```

![image-20220829134605460](https://typora-1312877226.cos.ap-guangzhou.myqcloud.com/%E4%BD%9C%E4%B8%9A/image-20220829134605460.png)

### 2.配置atlas

```
cd /usr/local/mysql-proxy/conf
mv test.cnf test.cnf.bak
vi test.cnf
写入：
[mysql-proxy]
admin-username = user
admin-password = pwd
proxy-backend-addresses = 192.168.32.233:3306
proxy-read-only-backend-addresses = 192.168.32.144:3306,192.168.32.152:3306
pwds = repl:3yb5jEku5h4=,mha:O2jBXONX098=
daemon = true
keepalive = true
event-threads = 8
log-level = message
log-path = /usr/local/mysql-proxy/log
sql-log=ON
proxy-address = 0.0.0.0:33060
admin-address = 0.0.0.0:2345
charset=utf8

启动atlas
/usr/local/mysql-proxy/bin/mysql-proxyd test start
```

测试读写分离：

```
mysql -umha -pmha -P 33060
select @@server_id;
```

![image-20220829140523225](https://typora-1312877226.cos.ap-guangzhou.myqcloud.com/%E4%BD%9C%E4%B8%9A/image-20220829140523225.png)

![image-20220829141649099](https://typora-1312877226.cos.ap-guangzhou.myqcloud.com/%E4%BD%9C%E4%B8%9A/image-20220829141649099.png)

```
begin;select @@server_id;commit;
```

![image-20220829141743393](https://typora-1312877226.cos.ap-guangzhou.myqcloud.com/%E4%BD%9C%E4%B8%9A/image-20220829141743393.png)

```
mysql -uuser -ppwd -h 192.168.32.144 -P2345
select * from help;
```

![image-20220829142405329](https://typora-1312877226.cos.ap-guangzhou.myqcloud.com/%E4%BD%9C%E4%B8%9A/image-20220829142405329.png)

### 3.查看所有节点

```
SELECT * FROM backends;
```

![image-20220829143224333](https://typora-1312877226.cos.ap-guangzhou.myqcloud.com/%E4%BD%9C%E4%B8%9A/image-20220829143224333.png)

### 4.删除节点

```
REMOVE BACKEND  2;
```

![image-20220829143338137](https://typora-1312877226.cos.ap-guangzhou.myqcloud.com/%E4%BD%9C%E4%B8%9A/image-20220829143338137.png)

### 5.增加节点：

```
ADD SLAVE 192.168.32.144:3306;
```

![image-20220829143522059](https://typora-1312877226.cos.ap-guangzhou.myqcloud.com/%E4%BD%9C%E4%B8%9A/image-20220829143522059.png)

### 6.密码加密

```shell
/usr/local/mysql-proxy/bin/encrypt weiwie
```

![image-20220829143710442](https://typora-1312877226.cos.ap-guangzhou.myqcloud.com/%E4%BD%9C%E4%B8%9A/image-20220829143710442.png)
