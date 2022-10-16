#!/bin/bash
#author:xiaoyuqun

nginxinstall(){
echo "nginx安装-1.22.0！"
#清理环境
pkill nginx
rm -rf /usr/local/nginx
rm -rf /usr/bin/nginx
#环境依赖搭建
yum install  gcc  zlib zlib-devel  pcre pcre-devel openssl openssl-devel -y
#添加 Nginx 用户
groupadd  -g 88 nginx
useradd  -g nginx -M -s /sbin/nologin -u 88 nginx
#下载解压编译安装
cd /opt
wget http://nginx.org/download/nginx-1.22.0.tar.gz
tar xf nginx-1.22.0.tar.gz
cd nginx-1.22.0
./configure --user=nginx  --group=nginx --prefix=/usr/local/nginx --with-http_stub_status_module  --with-http_sub_module  --with-http_ssl_module  --with-pcre --with-stream
make && make install
#添加环境变量
export PATH=$PATH:/usr/local/nginx/sbin
echo 'export PATH=$PATH:/usr/local/nginx/sbin' >> /etc/profile
source /etc/profile
clear
nginx -v
echo -n "nginx安装完成！ 以上为版本信息"
 }
nginxinstall

mysqlinstall(){
 pkill mysql
#清理历史环境
yum -y remove `rpm -qa | grep mariadb`
/etc/init.d/mysqld stop
rm -rf /usr/local/mysql
rm -rf /opt/mysql*
#创建用户和用户组
useradd mysql -s /sbin/nologin
#vim my.cnf配置文件
cat > /etc/my.cnf <<eof
[mysqld]
user=mysql
basedir=/usr/local/mysql
datadir=/data/mysqldata
log_bin=/data/binlog/mysql-bin
server_id=6
log-error=/var/log/mysql/error.log
pid-file=/data/mysqldata/mysql.pid
port=3306
socket=/tmp/mysql.sock
#gtid主从配置
log-bin=mysql-bin
gtid-mode=on
enforce-gtid-consistency=on
binlog-format=row
log-slave-updates=1
skip-slave-start=1
[mysql]
socket=/tmp/mysql.sock
eof
#删除相关目录，以防残留文件
rm -rf /data/mysqldata
rm -rf /var/log/mysql
rm -rf /data/binlog
#创建相关目录
mkdir -p /data/mysqldata
mkdir -p /var/log/mysql
mkdir -p /data/binlog
#下载解压
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
mysql -e "set password for root@localhost = password('123456');"
echo -n "mysql5.7.38安装完毕！密码:123456"
 }
mysqlinstall

phpinstall(){
 #清理环境
pkill php-fpm
rm -rf /usr/local/php
rm -rf /usr/bin/php-fpm
rm -rf /etc/init.d/php-fpm
#下载php.libzip.tar包
cd /opt
wget https://www.php.net/distributions/php-7.4.30.tar.gz
wget --no-check-certificate https://libzip.org/download/libzip-1.9.2.tar.gz
tar xf php-7.4.30.tar.gz
tar xf libzip-1.9.2.tar.gz
#自己排错需要的依赖
yum install -y autoconf  gcc  libxml2-devel openssl-devel curl-devel libjpeg-devel libpng-devel libXpm-devel freetype-devel libmcrypt-devel make ImageMagick-devel  libssh2-devel gcc-c++ cyrus-sasl-devel sqlite-devel
#授权用户
groupadd www
useradd -g www www
#安装升级cmake
wget https://cmake.org/files/v3.5/cmake-3.5.2.tar.gz
tar xf cmake-3.5.2.tar.gz
cd cmake-3.5.2
./bootstrap --prefix=/usr
gmake -j $(nproc) && make install
#检测是否安装成功安装
cmake --version
#libzip预编译,安装
cd /opt/libzip-1.9.2
mkdir build
cd build 
cmake ..
make -j $(nproc) && make install
#安装需要依赖的oniguruma等库
cd /opt
yum install http://rpms.remirepo.net/enterprise/7/remi/x86_64/oniguruma5php-6.9.8-1.el7.remi.x86_64.rpm -y
yum install http://rpms.remirepo.net/enterprise/7/remi/x86_64/oniguruma5php-devel-6.9.8-1.el7.remi.x86_64.rpm -y
#php预编译
cd /opt/php-7.4.30
#老刘头的
mkdir -p /usr/local/php/etc/php.d
./configure  --prefix=/usr/local/php \
        --with-config-file-path=/usr/local/php/etc \
        --with-config-file-scan-dir=/usr/local/php/etc/php.d \
        --disable-ipv6 \
        --enable-bcmath \
        --enable-calendar \
        --enable-exif \
        --enable-fpm \
        --with-fpm-user=www \
        --with-fpm-group=www \
        --enable-ftp \
        --enable-gd-jis-conv \
        --enable-gd-native-ttf \
        --enable-inline-optimization \
        --enable-mbregex \
        --enable-mbstring \
        --enable-mysqlnd \
        --enable-opcache \
        --enable-pcntl \
        --enable-shmop \
        --enable-soap \
        --enable-sockets \
        --enable-static \
        --enable-sysvsem \
        --enable-wddx \
        --enable-xml \
        --with-curl \
        --with-gd \
        --with-jpeg-dir \
        --with-freetype-dir \
        --with-xpm-dir \
        --with-png-dir \
        --with-gettext \
        --with-iconv \
        --with-libxml-dir \
        --with-mcrypt \
        --with-mhash \
        --with-mysqli \
        --with-pdo-mysql \
        --with-pear \
        --with-openssl \
        --with-xmlrpc \
        --with-zlib \
        --disable-debug \
        --disable-phpdbg
 #php编译安装
make -j $(nproc) && make install
/usr/local/php/bin/php -v
echo "以上为PHP安装的版本"
cd /opt/php-7.4.30
#配置php-fpm
cp /opt/php-7.4.30/php.ini-production /etc/php.ini
cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf
cp /opt/php-7.4.30/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
ln -s -f phar.phar /usr/local/php/bin/phar
chmod +x /etc/init.d/php-fpm
/etc/init.d/php-fpm start
if test $? == 0 ; then echo "启动成功！" ;fi
 }
phpinstall



