七层负载+集群（lnmp框架至少两台服务器）1主两从数据库架构（两从做四层负载）

环境：

```
系统：CentOS 7
主IP：192.168.112.128
从IP：192.168.112.129
从IP：192.168.112.130
```

### 脚本

```bash
#!/bin/bash
#author:肖钰群

#预先准备功能文件脚本到本地
cat >/opt/mysqlinstall.sh<<EOF
      echo "mysql安装-5.7.38！"
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
EOF

cat >/opt/nginxinstall.sh<<XYQEOF
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
XYQEOF
      
cat >/opt/phpinstall.sh<<XYQEOF
echo "php安装！"
#!/bin/bash
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
XYQEOF
cat >/opt/newyuminstall.sh<<XYQEOF
#新机yum源搭建
#!/bin/bash
#初始化环境搭建
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
XYQEOF
cat >/opt/nginxfuzai-djfl.sh<<XYQEOF
#nginx负载
#!/bin/bash
#实现七层负载+
read -p "一共需配置几台负载：" num
for ((i=1;i<=$num;i++))
do
read -p "请输入负载机$i的(IP:端口):" tip$i
done
read -p "请定义负载域名（server_name）:" name
cd /usr/local/nginx/conf/vhost/
cat >stream.conf<<eof
server{
	listen  80;
	server_name $name;
#动静分离(框架，未搭建动静分离)
	  location / {
            if ($request_uri ~* \.html$){
                   proxy_pass http://htmlservers;
           }   
            if ($request_uri ~* \.php$){
                   proxy_pass http://phpservers;
           }   
                   proxy_pass http://picservers;
        }
}
 upstream  htmlservers{   

 }
 upstream  phpservers{

 }
 upstream  picservers{

 }
 eof
for ((i=1;i<=$num;i++))
do
sed -i "/upstream  htmlservers{/a\   server $tip$i"
sed -i "/upstream  phpservers{/a\   server $tip$i"
sed -i "/upstream  picservers{/a\   server $tip$i"
done
echo "七层负载搭建成功，(test)文件请在nginx/html下面创建"
#生成静态测试文件
echo $tip1 > /usr/local/nginx/html/index.html
#生成动态测试文件
cat >/usr/local/nginx/html/test.php<<eof
$tip1
<?php
phpinfo();
?>
eof
#下载图片测试文件
wget -O /usr/local/nginx/html/test.png https://boluo-1312891830.cos.ap-nanjing.myqcloud.com/%E7%AC%94%E8%AE%B0%E5%9B%BE%E7%89%87202209170048139.png
#重启
nginx -s reload
XYQEOF

####进入无限循环
while true
do
echo -e "0)退出 \n1)nginx \n2)mysql \n3)php \n4)检测是否完成lnmp环境搭建 \n5)数据库主从搭建 \n6)HAProxy \n7)nginx与php通信配置 \n8)清除LNMP \n9)远程安装lnmp环境，mysql、nginx、php、yum环境搭建 \n10)yum环境搭建安装 \n11)tomcat+nginx动静分离实现 \n12)apache-tomcat安装 \n13)HAProxy添加新的负载均衡业务 \n14) \n15) \n66)nginx负载搭建（测试不建议使用）"
read -p "请输入你的选择:" temp
case $temp in
1|nginx)
      sh /opt/nginxinstall.sh
      ;;
2|mysql)
      sh /opt/mysqlinstall.sh
      ;;
3|php)
      sh /opt/phpinstall.sh
       ;;
4|lnmp) 
#检测是否完成lnmp环境搭建
ls /usr/local/nginx &>/dev/null
if test $? == 0 ; then echo "nginx校验成功！" ;fi
ls /usr/local/mysql &>/dev/null
if test $? == 0 ; then echo "mysql校验成功！" ;fi
ls /usr/local/php &>/dev/null
if test $? == 0 ; then echo "php校验成功！" ;fi
echo "以上三项校验成功则lnmp环境初步成功"
;;
5) 
#一键数据库主从搭建
#数据库角色           IP	       系统与MySQL版本	   有无数据
#主数据库	    192.168.112.128	CENTOS7 MySQL5.7.38     无数据
#从数据库1/2    192.168.112.129/130	CENTOS7 MySQL5.7.38	   无数据

#安装sshpass工具,脚本无交互远程登录
yum -y install sshpass
#免交户方式分发公钥
read -p "输入本机IP地址:" myip
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
sshpass -p$sshwd1 ssh -o StrictHostKeyChecking=no root@$sship1 "`cat /opt/mysqlinstall.sh`"
sshpass -p$sshwd2 ssh -o StrictHostKeyChecking=no root@$sship2 "`cat /opt/mysqlinstall.sh`"
else
#更改从机my.cnf -server_id
sshpass -p$sshwd1 ssh -o StrictHostKeyChecking=no root@$sship1 <<EOF
echo "`cat /etc/my.cnf`" > /etc/my.cnf
EOF
sshpass -p$sshwd2 ssh -o StrictHostKeyChecking=no root@$sship2 <<EOF
echo "`cat /etc/my.cnf`" > /etc/my.cnf
EOF
sshpass -p$sshwd1 ssh -o StrictHostKeyChecking=no root@$sship1 <<EOF
sed -i '6c server_id=7' /etc/my.cnf
EOF
sshpass -p$sshwd2 ssh -o StrictHostKeyChecking=no root@$sship2 <<EOF
sed -i '6c server_id=8' /etc/my.cnf
EOF
#重启从mysql
sshpass -p$sshwd1 ssh -o StrictHostKeyChecking=no root@$sship1 "/etc/init.d/mysqld restart"
sshpass -p$sshwd2 ssh -o StrictHostKeyChecking=no root@$sship2 "/etc/init.d/mysqld restart"
#sshpass执行远程命令,主库添加同步账户
read -p "输入主库MySQL密码:" mysql1
mysql -uroot -p$mysql1 -e  "grant replication slave on *.* to 'repl'@'%' identified by '123';flush privileges;"
mysql -uroot -p$mysql1 -e  "select user,host from mysql.user;"
#确保启动mysql服务
systemctl restart mysqld
sshpass -p$sshwd1 ssh -o StrictHostKeyChecking=no root@$sship1 "systemctl restart mysqld"
sshpass -p$sshwd2 ssh -o StrictHostKeyChecking=no root@$sship2 "systemctl restart mysqld"
#开启主从同步,ssh远程开启
sshpass -p$sshwd1 ssh -o StrictHostKeyChecking=no root@$sship1 <<EOF
mysql -uroot -p123456 -e "stop slave"
mysql -uroot -p123456 -e "change master to master_host='192.168.112.128',master_user='repl',master_password='123',master_auto_position=1;"
mysql -uroot -p123456 -e "start slave"
EOF
sshpass -p$sshwd2 ssh -o StrictHostKeyChecking=no root@$sship2 <<EOF
mysql -uroot -p$mysql1 -e  "change master to master_host="$myip",master_user='repl',master_password='123',master_auto_position=1;"
EOF
#查看gtid状态
clear
sshpass -p$sshwd1 ssh -o StrictHostKeyChecking=no root@$sship1 <<EOF
mysql -uroot -p$mysql1 -e 'show variables like "%GTID%";'
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
;; 
6) 
#HAPorxy-还未实现远程化安装
read -p "请设置HAProxy登录<ip>/haproxy-status的用户名：" user
read -p "请设置HAProxy登录<ip>/haproxy-status的密码：" password
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

#添加haproxy用户
useradd -s "/bin/nologin" haproxy1 -g 99
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
echo -e "浏览器登录状态页：<ip>/haproxy-status \n账号:$user \n密码:$password"

;;
2) ;;

;; 
7)
#nginx与php通信配置：
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
;;
8)
#停掉lnmp所有服务
pkill nginx
pkill mysql
pkill php-fpm
#删除文件
rm -rf /usr/local/nginx
rm -rf /usr/local/mysql
rm -rf /usr/local/php
#删除软链接
rm -rf /usr/bin/nginx
rm -rf /usr/bin/mysql
rm -rf /usr/bin/php-fpm
rm -rf /usr/bin/php
chkconfig --del mysqld
echo "清理完成，请手动清理 /etc/profile 相关环境"
;;
9)
#远程安装lnmp环境，mysql、nginx、php、yum环境搭建
read -pe "1)mysql 远程安装 \n2)nginx 远程安装 \n3)php 远程安装 \n4)yum源安装" installnmp
case $installnmp in
  1)
read -p "需要安装mysql的远程机有几台？" num
for ((a=0 ; a<$num ; a++))
do
read -p "你的远程$a-IP地址:" sship$a
read -p "你的远程$a-root登录密码:" sshwd$a
sshpass -p$sship$a ssh -o StrictHostKeyChecking=no root@$sshwd$a "`cat /opt/mysqlinstall.sh`"
done
;;
  2)
read -p "需要安装nginx的远程机有几台？" num
for ((a=0 ; a<$num ; a++))
do
read -p "你的远程$a-IP地址:" sship$a
read -p "你的远程$a-root登录密码:" sshwd$a
sshpass -p$sship$a ssh -o StrictHostKeyChecking=no root@$sshwd$a "`cat /opt/nginxinstall.sh`"
done
;;
  3)
read -p "需要安装php的远程机有几台？" num
for ((a=0 ; a<$num ; a++))
do
read -p "你的远程$a-IP地址:" sship$a
read -p "你的远程$a-root登录密码:" sshwd$a
sshpass -p$sship$a ssh -o StrictHostKeyChecking=no root@$sshwd$a "`cat /opt/phpinstall.sh`"
done
;;
  4)
  read -p "需要安装yum环境的远程机有几台？" num
for ((a=0 ; a<$num ; a++))
do
read -p "你的远程$a-IP地址:" sship$a
read -p "你的远程$a-root登录密码:" sshwd$a
sshpass -p$sship$a ssh -o StrictHostKeyChecking=no root@$sshwd$a "`cat /opt/newyuminstall.sh`"
done
;;
esac
;;
10)
   sh /opt/newyuminstall.sh
;;
11)
#nginx+tomcat动静分离
;;
12)
#tomcat安装
#清理java环境
rm -rf /usr/bin/java
rm -rf /usr/local/java
#搭建jdk环境
cd /usr/local/src
wget https://download.oracle.com/java/18/latest/jdk-18_linux-x64_bin.tar.gz
mkdir /usr/local/java/
tar -zxvf jdk-18_linux-x64_bin.tar.gz -C /usr/local/java/
cat >>/etc/profile<<eof
################java#####################
export JAVA_HOME=/usr/local/java/jdk-18.0.2.1
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
export PATH=${JAVA_HOME}/bin:$PATH
eof
source /etc/profile
ln -s /usr/local/java/jdk-18.0.2.1/bin/java /usr/bin/java
java -version
#java环境安装完成
#tomcat环境清理
rm -rf /usr/local/tomcat
rm -rf /usr/bin/tomcat
#tomcat
cd /usr/local/src
mkdir /usr/local/tomcat
wget --no-check-certificate https://dlcdn.apache.org/tomcat/tomcat-8/v8.5.82/bin/apache-tomcat-8.5.82.tar.gz 
tar xf apache-tomcat-8.5.82.tar.gz -C /usr/local/tomcat/
cd /usr/local/tomcat/apache-tomcat-8.5.82/bin
echo "export PATH=$PATH:/usr/local/tomcat/apache-tomcat-8.5.82/bin" >>/etc/profile
source /etc/profile
./catalina.sh start
echo "tomcat安装完成，浏览器访问<ip>:8080"
;;
13)
#9/18 增加功能（压缩，四层，七层，cookie等等）
echo -e "1)添加新的负载均衡业务 \n2)退出" hap
case $hap in
1)
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

;;
2)continue;;
esac
1);;
14)echo "正在努力写了......";;
15)echo "正在努力写了......";;
66)
   sh /opt/nginxfuzai-djfl.sh
;;
0)
      clear
      echo "谢谢使用！ ---肖钰群"
      break ;;   
*)echo "dnmd，请输入正确的指令！ ---肖钰群"
esac
done
```











### PHP安装成功：

![image-20220914205328481](https://boluo-1312891830.cos.ap-nanjing.myqcloud.com/%E7%AC%94%E8%AE%B0%E5%9B%BE%E7%89%87202209142053582.png)

![image-20220914210526698](https://boluo-1312891830.cos.ap-nanjing.myqcloud.com/%E7%AC%94%E8%AE%B0%E5%9B%BE%E7%89%87202209142105784.png)