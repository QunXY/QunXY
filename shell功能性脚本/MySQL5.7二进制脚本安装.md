MySQL5.7二进制脚本安装

```sh
#!/bin/bash
#mysql5.7 二进制安装脚本--肖钰群

#清理历史环境
yum -y remove `rpm -qa | grep mariadb`
/etc/init.d/mysqld stop
#创建用户和用户组
useradd mysql -s /sbin/nologin
#vim my.cnf配置文件
read -p "为防止冲突,请手动设定server_id:" id
echo "[mysqld]
user=mysql
basedir=/usr/local/mysql
datadir=/data/mysqldata
log_bin=/data/binlog/mysql-bin
server_id=$id
log-error=/var/log/mysql/error.log
pid-file=/data/mysqldata/mysql.pid
port=3306
socket=/tmp/mysql.sock
[mysql]
socket=/tmp/mysql.sock " > /etc/my.cnf
#删除相关目录，以防残留文件
rm -rf /data/mysqldata
rm -rf /var/log/mysql
rm -rf /data/binlog
#创建相关目录
mkdir -p /data/mysqldata
mkdir -p /var/log/mysql
mkdir -p /data/binlog
#解压
cd /opt
wget https://repo.huaweicloud.com/mysql/Downloads/MySQL-5.7/mysql-5.7.38-linux-glibc2.12-x86_64.tar.gz
tar -xf mysql-5.7.38-linux-glibc2.12-x86_64.tar.gz
mv mysql-5.7.38-linux-glibc2.12-x86_64  /usr/local/mysql
#设置权限
chown mysql:mysql -R /usr/local/mysql
chown mysql:mysql -R /var/log/mysql
chown mysql:mysql -R /data/mysqldata
chown mysql:mysql -R /data/binlog
#增加环境变量
echo 'export PATH=$PATH:/usr/local/mysql/bin' >> /etc/profile
source /etc/profile
#不生成密码初始化
mysqld --initialize-insecure  --user=mysql --basedir=/usr/local/mysql --datadir=/data/mysqldata
#复制启动脚本并生成系统命令
cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
ln -s /usr/local/mysql/bin/mysql /usr/bin/
#添加至systemd管理（开机自启）
chkconfig --add mysqld
/etc/init.d/mysqld start
systemctl status mysql
clear
echo -n "mysql5.7.38安装完毕！请手动添加密码！"
echo -n 'mysqladmin -u root -p password '
```

