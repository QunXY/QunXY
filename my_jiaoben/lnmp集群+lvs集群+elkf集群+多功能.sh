#!/bin/bash
#author:肖钰群
mydate=`date +%d/%m/%Y`
localhost=`hostname -s`
user=`whoami`
#开始循环体，es集群搭建脚本 增加es-head的功能插件，按[0]退出

clear
for ((;;)) 
do

cat <<EOF
--------------------------------------------------------------------------------------
作者:肖钰群              主机名:$localhost         日期：$mydate
--------------------------------------------------------------------------------------
0 : 退出
1 : web工具安装+lnmp集群搭建 +
2 : haproxy +
3 : lvsdr-keepalived
4 : es集群搭建 +
5 : Haproxy+keepalived(高可用集群部署)
66: 搭建yum
---------------------------------------------------------------------------------------
实验环境：
CentOS7
内存3G
三台服务器
-----------------------------------------------------------------------
EOF

echo -en "\t请选择你的功能[0,1,2,3,4,5,66]--->"
read choice
 case $choice in
 0)
 echo "谢谢使用！"
 exit
 ;;
 
 1|lnmp)
 #web工具安装+lnmp集群搭建
 for((;;))
 do
   cat <<EOF
  0 : 退出
  1 : nginx安装
  2 : mysql安装
  3 : php安装
  4 : 一键安装nmp
  5 : mysql主从搭建
  6 : nginx与php通信配置
EOF
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
 
 read -p "选择：" input1
 case $input1 in
 0)
 clear
 break;;
 1)
 nginxinstall;;
 2)
 mysqlinstall;;
 3)
 phpinstall;;
 4)
 nginxinstall
 mysqlinstall
 phpinstall
 ;;
 5)
 mysqlzhucong(){
#一键数据库主从搭建
#数据库角色           IP	       系统与MySQL版本	   有无数据
#主数据库	    192.168.112.128	CENTOS7 MySQL5.7.38     无数据
#从数据库1/2    192.168.112.129/130	CENTOS7 MySQL5.7.38	   无数据
#安装sshpass工具,脚本无交互远程登录
yum -y install sshpass
#免交户方式分发公钥
IP=`ifconfig | grep -w broadcast | awk -F "[ ]+" '{print $3}'`
read -p "你的从机1-IP地址:" sship1
read -p "你的从机1-root登录密码:" sshwd1
read -p "你的从机2-IP地址:" sship2
read -p "你的从机2-root登录密码:" sshwd2
#配置主从机的配置文件my.cnf
cat > /etc/my.cnf <<EOF
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
EOF
/etc/init.d/mysqld restart
#从机配置,远程执行本地脚本，从机安装mysql
read -p "是否需要从机安装mysql：1)是 *）否" mtemp
if test $mtemp == 1 ; then
sshpass -p$sshwd1 ssh -o StrictHostKeyChecking=no root@$sship1 "`mysqlinstall`"
sshpass -p$sshwd2 ssh -o StrictHostKeyChecking=no root@$sship2 "`mysqlinstall`"
else
#更改从机my.cnf -server_id
sshpass -p$sshwd1 ssh -o StrictHostKeyChecking=no root@$sship1 <<EOF
echo "`cat /etc/my.cnf`" > /etc/my.cnf
sed -i '6c server_id=7' /etc/my.cnf
EOF
sshpass -p$sshwd2 ssh -o StrictHostKeyChecking=no root@$sship2 <<EOF
echo "`cat /etc/my.cnf`" > /etc/my.cnf
sed -i '6c server_id=8' /etc/my.cnf
EOF
#重启从mysql
sshpass -p$sshwd1 ssh -o StrictHostKeyChecking=no root@$sship1 "/etc/init.d/mysqld restart"
sshpass -p$sshwd2 ssh -o StrictHostKeyChecking=no root@$sship2 "/etc/init.d/mysqld restart"
#sshpass执行远程命令,主库添加同步账户
read -p "输入主库MySQL密码:" mysql1
mysql -uroot -p$mysql1 -e  "grant replication slave on *.* to 'repl'@'%' identified by '123';flush privileges;"
#确保启动mysql服务
systemctl restart mysqld
#开启主从同步,ssh远程开启
sshpass -p$sshwd1 ssh -o StrictHostKeyChecking=no root@$sship1 <<EOF
mysql -uroot -p123456 -e "stop slave"
mysql -uroot -p123456 -e "change master to master_host="$IP",master_user='repl',master_password='123',master_auto_position=1;"
mysql -uroot -p123456 -e "start slave"
EOF
sshpass -p$sshwd2 ssh -o StrictHostKeyChecking=no root@$sship2 <<EOF
mysql -uroot -p123456 -e "stop slave"
mysql -uroot -p123456 -e "change master to master_host="$IP",master_user='repl',master_password='123',master_auto_position=1;"
mysql -uroot -p123456 -e "start slave"EOF
EOF
#查看主从同步状态
echo "$sship1 Running状态!"
sshpass -p$sshwd1 ssh -o StrictHostKeyChecking=no root@$sship1 <<EOF
mysql -uroot -p$mysql1 -e "show slave status\G" |grep Running
EOF
echo "$sship2 Running状态!"
sshpass -p$sshwd1 ssh -o StrictHostKeyChecking=no root@$sship1 <<EOF
mysql -uroot -p$mysql1 -e "show slave status\G" |grep Running
EOF
fi
echo "四个yes则搭建成功！"
 }
 mysqlzhucong
 ;;
 6)
 nptongxin(){
 #修改conf
sed -i '$i include vhost/*.conf;' /usr/local/nginx/conf/nginx.conf
#添加通信配置
mkdir /usr/local/nginx/conf/vhost
mkdir /usr/local/nginx/html/php
sed -i '58a location ~ \.php$ {\
        fastcgi_pass   127.0.0.1:9000;\
        include        fastcgi_params;\
        fastcgi_index  index.php;\
        fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;\
        fastcgi_param  PATH_INFO $fastcgi_script_name;\
    }\
    location ~ /\\.ht\
    {\
        deny  all;\
    }' /usr/local/nginx/conf/nginx.conf
	
echo '<?php 
phpinfo() 
?>' >/usr/local/nginx/html/php/index.php
    nginx && nginx -s reload
echo "浏览器输入<ip>/php/index.php"
 }
 nptongxin
 ;;
 esac
 
 done
 ;;
 
 2|hap)
 #haproxy +
 for((;;))
 do
   cat <<EOF
  0 : 退出
  1 : HAProxy安装
  2 : 添加（压缩，四层，七层，cookie）
  
EOF
 read -p "选择：" input1
 case $input1 in
  0)
  clear
  break;;
  
  1)
  haproxyinstall(){
  #安装依赖软件包
  yum -y install pcre-devel bzip2-devel  gcc  pcre-static  openssl openssl-devel
  # 解压源码包并编译
  cd /usr/local/src
  wget https://src.fedoraproject.org/repo/pkgs/haproxy/haproxy-1.8.12.tar.gz/
  tar xf haproxy-1.8.12.tar.gz
  cd haproxy-1.8.12
  #编译时需要指定内核版本，uname -r #查看内核版本
  make TARGET=linux310  ARCH=x86_64 PREFIX=/usr/local/haproxy  USE_OPENSSL=1
  make install  PREFIX=/usr/local/haproxy
  cp -r  examples/errorfiles  /usr/local/haproxy/
  mkdir -p /usr/local/haproxy/conf/
  mkdir -p /etc/haproxy
  mkdir -p /var/lib/haproxy/
  mkdir -p /usr/local/haproxy/log
  chown -R 99.99 /var/lib/haproxy/
  touch /usr/local/haproxy/log/haproxy.log
  ln -s /usr/local/haproxy/log/haproxy.log /var/log/haproxy.log
  cp /usr/local/src/haproxy-1.8.12/examples/haproxy.init /etc/rc.d/init.d/haproxy
  chmod +x /etc/rc.d/init.d/haproxy
  chkconfig haproxy on
  ln -s /usr/local/haproxy/sbin/haproxy /usr/sbin
  cat >/etc/haproxy<<EOF
global
maxconn 100000
chroot /usr/local/haproxy
stats socket /var/lib/haproxy/haproxy.sock mode 600 level admin
uid 99
gid 99
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
 stats auth   admin:123456
listen web_port
 bind 192.168.112.128:999
 mode http
 log global
 server web1 127.0.0.1:8080 check inter 3000 fall 2 rise 5
EOF
  service haproxy start
  }
  
  haproxyinstall;;
  
  2)
  #增加功能（压缩，四层，七层，cookie等等）
  haproxyadd(){
read -p "起一个业务名:" name
read -p "添加几台机做负载:" num
read -p "定义业务访问端口（空闲端口！）:" num
for ((i=0;i<$num;i++))
do
read -p "输入（IP$i:端口）" ipn$i
done
IP=`ifconfig | grep -w broadcast | awk -F "[ ]+" '{print $3}'`
cat >>/etc/haproxy/haproxy.cfg<<EOF
listen $name
#四层tcp/七层http
mode http
#压缩功能
compression algo gzip
#cookie
cookie SERVER-COOKIE insert indirect nocache
rdp-cookie
  bind $IP:
EOF
for ((i=0;i<$num;i++))
do
echo " server web$i $ipn$i weight 1 check inter 3000 fall 2 rise 5" >>/etc/haproxy/haproxy.cfg
done
  }
  
  haproxyadd;;
  
  esac
  
  done 
  ;;

 3|lvsdr)
 #lvs+keepalived
 for((;;))
 do
   cat <<EOF
  0 : 退出
  1 : lvs+dr模式+keepalived
  2 : lvs实现https的负载集群
  *3 : keepalived+haproxy
  
EOF
 read -p "选择：" input1
 case $input1 in
  0)
  clear
  break;;
  1)
  lvsdrinstall(){
  yum -y install sshpass
#用户输入
IP=`ifconfig | grep -w broadcast | awk -F "[ ]+" '{print $3}'`
IPtemp=`echo $IP|awk -F"." '{print $1"."$2"."$3"."}'`
read -p "你的二号(keepalived)节点IP地址:" ip1
read -p "你的一号(rs1)负载机IP地址:" ip2
read -p "你的二号(rs2)负载机IP地址:" ip3
read -p "你的二号(keepalived)节点密码:" wd1
read -p "你的一号(rs1)负载机登录密码:" wd2
read -p "你的一号(rs2)负载机登录密码:" wd3
#准备Real server节点2台配置脚本：
cat >/opt/lvs_rs.sh<<EOF
#! /bin/bash
vip="$IPtemp"38
ifconfig lo:0 $vip broadcast \$vip netmask 255.255.255.255 up
route add -host \$vip lo:0
echo "1" >/proc/sys/net/ipv4/conf/lo/arp_ignore
echo "2" >/proc/sys/net/ipv4/conf/lo/arp_announce
echo "1" >/proc/sys/net/ipv4/conf/all/arp_ignore
echo "2" >/proc/sys/net/ipv4/conf/all/arp_announce
EOF
cat >/etc/keepalived/keepalived.conf <<EOF
vrrp_instance VI_1 {
 state MASTER
 interface ens33
 virtual_router_id 51
 priority 100
 advert_int 1
 authentication {
 auth_type PASS
 auth_pass 1111
 }
 virtual_ipaddress {
 "$IPtemp"38
 }
}
virtual_server "$IPtemp"38 80 {
 delay_loop 6
 lb_algo rr
 lb_kind DR
 persistence_timeout 0
 protocol TCP
 real_server $ip2 80 {
 weight 1
 TCP_CHECK {connect_timeout 10
 nb_get_retry 3
 delay_before_retry 3
 connect_port 80
 }
 }
 real_server $ip3 80 {
 weight 1
 TCP_CHECK {
 connect_timeout 10
 nb_get_retry 3
 delay_before_retry 3
 connect_port 80
 }
 }
}
EOF
cat >/opt/lvs_dr.sh<<EOF
#! /bin/bash
echo 1 > /proc/sys/net/ipv4/ip_forward
ipv=/sbin/ipvsadm
vip="$IPtemp"38
rs1=\$ip2
rs2=\$ip3
ifconfig ens33:0 down
ifconfig ens33:0 \$vip broadcast \$vip netmask 255.255.255.255 up
route add -host \$vip dev ens33:0
\$ipv -C
\$ipv -A -t \$vip:80 -s wrr
\$ipv -a -t \$vip:80 -r \$rs1:80 -g -w 3
\$ipv -a -t \$vip:80 -r \$rs2:80 -g -w 1
EOF
#Director节点
yum install -y ipvsadm
sh /opt/lvs_dr.sh
#Real server + nginx服务的2个节点安装
sshpass -p$wd2 ssh -o StrictHostKeyChecking=no root@$ip2 "yum install epel-release nginx -y"
sshpass -p$wd3 ssh -o StrictHostKeyChecking=no root@$ip3 "yum install epel-release nginx -y"
sshpass -p$wd2 ssh -o StrictHostKeyChecking=no root@$ip2 <<EOF
`cat /opt/lvs_rs.sh`
EOF
sshpass -p$wd3 ssh -o StrictHostKeyChecking=no root@$ip3 <<EOF
`cat /opt/lvs_rs.sh`
EOF
#Lvs + keepalived的2个节点安装
yum install ipvsadm keepalived -y
sshpass -p$wd1 ssh -o StrictHostKeyChecking=no root@$ip1 "yum install ipvsadm keepalived -y"
#Director 上配置脚本二号(keepalived)

#keepalived节点配置(2节点)：
sshpass -p$wd1 ssh -o StrictHostKeyChecking=no root@$ip1 <<EOF
`cat /opt/lvs_dr.sh`
EOF
sshpass -p$wd1 ssh -o StrictHostKeyChecking=no root@$ip1 <<EOF
echo "`cat /etc/keepalived/keepalived.conf`" >/etc/keepalived/keepalived.conf
EOF
sshpass -p$wd1 ssh -o StrictHostKeyChecking=no root@$ip1 <<EOF
#sed -i 's/51/52/' /etc/keepalived/keepalived.conf
sed -i 's/state MASTER/state BACKUP/' /etc/keepalived/keepalived.conf
sed -i 's/priority 100/priority 90/' /etc/keepalived/keepalived.conf
echo 1 > /proc/sys/net/ipv4/ip_forward
EOF

#keepalived的2个节点执行如下命令，开启转发功能：
echo 1 > /proc/sys/net/ipv4/ip_forward
#启动keepalive,先主后从分别启动keepalive
service keepalived start
sshpass -p$wd1 ssh -o StrictHostKeyChecking=no root@$ip1 "service keepalived start"

#修改nginx内容方便区分  /usr/share/doc/HTML
sshpass -p$wd2 ssh -o StrictHostKeyChecking=no root@$ip2 "echo $ip2 > /usr/share/doc/HTML/index.html"
sshpass -p$wd3 ssh -o StrictHostKeyChecking=no root@$ip3 "echo $ip3 > /usr/share/doc/HTML/index.html"
sshpass -p$wd2 ssh -o StrictHostKeyChecking=no root@$ip2 "nginx"
sshpass -p$wd3 ssh -o StrictHostKeyChecking=no root@$ip3 "nginx"
  }
  lvsdrinstall
  ;;
  2)
  echo "正在写。。。"
  ;;
 esac
 done
 ;;
 
 4|elk)
cd /usr/local/src
#内网下载地址
read -p "是否需要下载集成安装包y/n?" inp
if test $inp == y ;then
wget http://192.168.1.200/rpm/elk-package.zip
unzip elk-package.zip
fi

 for((;;))
 do
   cat <<EOF
  0 : 退出
  1 : 安装Elasticsearch
  2 : 部署搭建head 插件
  3 : 安装Logstash
  4 : 安装Kibana
  5 : maven环境搭建并更换maven源到阿里
  6 : Filebeat安装
  7 : Redis安装
  * : 确认已连接公司内网
   --->ela集群搭建+ela-head插件(本脚本实现3节点搭建,更多节点自己加循环)
EOF
 read -p "选择：" input1
 case $input1 in
  0)
  clear
  break;;
  1)
 yum -y install sshpass
 clear
 IP=`ifconfig | grep -w broadcast | awk -F "[ ]+" '{print $3}'`
 systemctl stop firewalld
 read -p "你的elk02号IP地址:" ip1
 read -p "你的elk03号IP地址:" ip2
 read -p "你的elk02号节点密码:" wd1
 read -p "你的elk03号节点密码:" wd2
  javainstall(){
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
  }
  javainstall
  esins(){
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
rpm -ivh elasticsearch-7.7.1-x86_64.rpm
#elk01配置
rm -rf /data/ela-data
mkdir -p /data/ela-data
mkdir -p /data/ela-log
chown -R elasticsearch:elasticsearch /data/ela-data
chown -R elasticsearch:elasticsearch /data/ela-log
cat >>/etc/hosts<<EOF
$IP elk01
$ip1 elk02
$ip2 elk03
EOF

mv /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.bak
 
#grep -Ev "^$|#" elasticsearch.yml
cat >/etc/elasticsearch/elasticsearch.yml<<EOF
cluster.name: elk-cluster
node.master: true
node.data: true
node.name: elk01
path.data: /data/ela-data
path.logs: /data/ela-log
network.host: $IP
http.port: 9200
discovery.seed_hosts: ["$IP", "$ip1", "$ip2"]
cluster.initial_master_nodes: ["$IP", "$ip1", "$ip2"]
http.cors.enabled: true
http.cors.allow-origin: "*"
EOF
#设置堆内存容量
sed -i 's/Xms1g/Xms400m/'   /etc/elasticsearch/jvm.options
sed -i 's/Xmx1g/Xmx400m/'   /etc/elasticsearch/jvm.options
#启动服务并设置开机启动
echo "正在启动服务，请稍后..."
systemctl start elasticsearch
systemctl enable  elasticsearch
#elk02配置
sshpass -p$wd1 ssh -o StrictHostKeyChecking=no root@$ip1 <<EOF
systemctl stop firewalld
cat >>/etc/security/limits.conf<<eof
* soft nofile 65536
* hard nofile 65536
* soft nproc 2048
* hard nproc 2048
* soft memlock unlimited
* hard memlock unlimited
eof
cat >>/etc/hosts<<eof
$IP elk01
$ip1 elk02
$ip2 elk03
eof
wget http://192.168.1.200/rpm/elk-package.zip
unzip elk-package.zip
rpm -ivh elasticsearch-7.7.1-x86_64.rpm
rm -rf /data/ela-data
mkdir -p /data/ela-data
mkdir -p /data/ela-log
chown -R elasticsearch:elasticsearch /data/ela-data
chown -R elasticsearch:elasticsearch /data/ela-log
echo '`cat /etc/elasticsearch/elasticsearch.yml`' >/etc/elasticsearch/elasticsearch.yml
sed -i "s/elk01/elk02/" /etc/elasticsearch/elasticsearch.yml
sed -i "s/network.host: $IP/network.host: $ip1/" /etc/elasticsearch/elasticsearch.yml
sed -i 's/Xms1g/Xms400m/'   /etc/elasticsearch/jvm.options
sed -i 's/Xmx1g/Xmx400m/'   /etc/elasticsearch/jvm.options
echo "正在启动服务，请稍后..."
systemctl start elasticsearch
systemctl enable  elasticsearch
EOF
#elk03配置
sshpass -p$wd2 ssh -o StrictHostKeyChecking=no root@$ip2 <<EOF
systemctl stop firewalld
cat >>/etc/security/limits.conf<<eof
* soft nofile 65536
* hard nofile 65536
* soft nproc 2048
* hard nproc 2048
* soft memlock unlimited
* hard memlock unlimited
eof
cat >>/etc/hosts<<eof
$IP elk01
$ip1 elk02
$ip2 elk03
eof
wget http://192.168.1.200/rpm/elk-package.zip
unzip elk-package.zip
rpm -ivh elasticsearch-7.7.1-x86_64.rpm
rm -rf /data/ela-data
mkdir -p /data/ela-data
mkdir -p /data/ela-log
chown -R elasticsearch:elasticsearch /data/ela-data
chown -R elasticsearch:elasticsearch /data/ela-log
echo '`cat /etc/elasticsearch/elasticsearch.yml`' >/etc/elasticsearch/elasticsearch.yml
sed -i "s/elk01/elk03/" /etc/elasticsearch/elasticsearch.yml
sed -i "s/network.host: $IP/network.host: $ip2/" /etc/elasticsearch/elasticsearch.yml
sed -i 's/Xms1g/Xms400m/'   /etc/elasticsearch/jvm.options
sed -i 's/Xmx1g/Xmx400m/'   /etc/elasticsearch/jvm.options
echo "正在启动服务，请稍后..."
systemctl start elasticsearch
systemctl enable  elasticsearch
EOF

#配置完成！
#查看node节点是否加入 
clear
curl  http://$IP:9200/_cat/nodela?v
  }
  esins
  ;;
  
  2)
  jshead(){
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
echo "npm run start 开始执行"
  }
  jshead
  ;;
  
  3)
  logstashins(){
  cd /usr/local/src
  rpm -ivh logstash-7.7.1.rpm
  echo "logsta安装完毕"
  echo "配置logstash收集文件-->/etc/logstash/conf.d/"
  }
  logstashins
  ;;
  4)
  kibanains(){
  cd /usr/local/src
  rpm -ivh kibana-7.7.1-x86_64.rpm
  IP=`ifconfig | grep -w broadcast | awk -F "[ ]+" '{print $3}'`
  cat >>/etc/kibana/kibana.yml<<EOF
  server.port: 5601
server.host: "$IP"
server.name: "E1"
elasticsearch.hosts: ["http://$IP:9200"]
kibana.index: ".kibana"
i18n.locale: "zh-CN"
EOF
  systemctl  start kibana  
  systemctl enable  kibana
  echo "Kibana浏览器访问   http://$IP:5601"
  echo "可能需要等待 几十秒中..."
  }
  kibanains
  ;;
  5)
  mavenins(){
  cd /usr/local/src
  wget --no-check-certificate https://dlcdn.apache.org/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz
  mkdir -p /usr/local/maven
  tar -zxf apache-maven-3.8.6-bin.tar.gz -C /usr/local/maven
  cd /usr/local/maven/apache-maven-3.8.6/conf/
  mkdir -p /m2/repository
  cat >settings.xml<<EOF
<?xml version="1.0" encoding="UTF-8"?>
 
<settings xmlns="http://maven.apache.org/SETTINGS/1.2.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.2.0 https://maven.apache.org/xsd/settings-1.2.0.xsd">
 
  <localRepository>/m2/repository</localRepository>
  
  <pluginGroups>
  </pluginGroups>
 
  <proxies>    
  </proxies>
 
  <servers>
  </servers>
 
  <mirrors>
    <mirror>  
   	  <id>alimaven</id>  
   	  <name>aliyun maven</name>  
	  <url>http://maven.aliyun.com/nexus/content/groups/public/</url>  
   	  <mirrorOf>central</mirrorOf>          
    </mirror> 
  </mirrors>
 
  <profiles>
  </profiles>
</settings>
EOF
  cat >>/etc/profile<<EOF
#----------------------MAVEN-3.8.6-------------------------------
MAVEN_HOME=/usr/local/maven/apache-maven-3.8.6
PATH=$MAVEN_HOME/bin:$PATH
export MAVEN_HOME PATH
EOF
  source /etc/profile
  mvn -version
  echo "maven安装配置成功！"
  }
  mavenins
  ;;
  6)
  filebeatins(){
  cd /usr/local/src
  rpm -ivh filebeat-7.7.1-x86_64.rpm
  service filebeat start
  chkconfig filebeat on #开机启动
  echo "自行修改：主配置文件目录是 /etc/filebeat/filebeat.yml"
  echo "service filebeat start"
  }
  filebeatins
  ;;
  7)
  redisins(){
  cd /usr/local/src
  wget https://github.com/redis/redis/archive/7.0.5.tar.gz
  tar xf 7.0.5.tar.gz
  mkdir -p /usr/local/redis
  mv redis-7.0.5 /usr/local/redis
  cd /usr/local/redis/redis-7.0.5
  make
  make install PREFIX=/usr/local/redis
  echo -e "/usr/local/redis  \n./bin/redis-server& ./redis.conf  \n执行以上两条命令启动redis"
  }
  redisins
  ;;
 esac
 done
 ;;
 
 5)
  for((;;))
 do
   cat <<EOF
  0 : 退出
  1 : 
  2 : 
  3 : 
  * : 
EOF
 read -p "选择：" input1
 case $input1 in
  0)
  clear
  break;;
  
  1)
  
  ;;
  
  2)
  
  ;;
 
 esac
 done
 ;;
  
  
 66)
 yuminstall(){
 #yum源搭建
mount /dev/sr0 /mnt/
#永久挂载
echo "/dev/cdrom /mnt iso9660 defaults        0 0" >>/etc/fstab
mkdir /etc/yum.repos.d/bak
mv /etc/yum.repos.d/* /etc/yum.repos.d/bak
#连接外网
echo -e "DNS1=8.8.8.8\nDNS2=144.144.144.144" >>/etc/sysconfig/network-scripts/ifcfg-ens33
systemctl restart network
#yum配置文件
echo "
[local]
name=local
baseurl=file:///mnt
enable=1
gpgcheck=0
gpgkey=file:///mnt/RPM-GPG-KEY-CentOS-7">/etc/yum.repos.d/local.repo
echo "本地yum配置完成"
yum clean all
yum makecache fast
yum repolist
yum install -y wget
#禁用 yum插件 fastestmirror
cp -i /etc/yum/pluginconf.d/fastestmirror.conf /etc/yum/pluginconf.d/fastestmirror.conf.bak
# 备份源文件
sed -i '2s/enabled=1/enabled=0/g' /etc/yum/pluginconf.d/fastestmirror.conf
#修改yum的配置文件
cp -i /etc/yum.conf /etc/yum.conf.bak
sed -i 's/plugins=1/plugins=0/g' /etc/yum.conf
#添加清华源\阿里源\华为源、网易源
wget -O /etc/yum.repos.d/CentOS-ali.repo https://mirrors.aliyun.com/repo/Centos-7.repo
wget -O /etc/yum.repos.d/epel.repo https://mirrors.aliyun.com/repo/epel-7.repo
wget -O /etc/yum.repos.d/CentOS-huawei.repo https://repo.huaweicloud.com/repository/conf/CentOS-7-reg.repo
cat >/etc/yum.repos.d/qinghua.repo<<eof
[qinghua]
name=qinghua
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/7/os/x86_64/
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/centos/7/os/x86_64/RPM-GPG-KEY-CentOS-7
eof
cat >/etc/yum.repos.d/wangyi.repo<<eof
[wangyi]
name=wangyi
baseurl=http://mirrors.163.com/centos/7/os/x86_64/
gpgcheck=1
gpgkey=http://mirrors.163.com/centos/7/os/x86_64/RPM-GPG-KEY-CentOS-7
eof
yum clean all
yum makecache fast
yum repolist
yum -y install yum-utils
#关闭防火墙
systemctl stop firewalld 
systemctl disable firewalld
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
getenforce
#yum安装常用工具
yum install -y vim wget unzip lrzsz curl
#依赖
yum install -y make gcc-c++
 }
 
 yuminstall ;;
 
 *)echo -e "\033[42;37m\n\n\n\n\t\t别乱选 吊毛\n\n\n\n\033[0m" ;;
 
 
 
 esac


done
