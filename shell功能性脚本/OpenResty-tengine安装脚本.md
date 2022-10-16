### OpenResty -tengine安装脚本

```shell
#!/bin/bash
#肖钰群9/8-尚观脚本作业
#注：此脚本编写环境：centos7
clear
read -p "安装OpenResty，请键入（1）or（2）or（3）
（1）二进制快速安装
（2）源码自定义安装
（3）tengine-2.1.0源码安装" temp
case $temp in

1)
	#添加yum源
	wget https://openresty.org/package/centos/openresty.repo
     mv openresty.repo /etc/yum.repos.d/
     yum check-update
     #安装openresty
     yum install -y openresty
     yum install -y openresty-resty
	;;
2)
	read -p "此脚本默认安装OpenResty-1.17.8.2版本，输入 yes 确认执行！" yes
	if test $yes == yes ; then
	cd /opt
	#安装依赖
	yum install readline-devel pcre-devel openssl-devel -y
	#下载tar包
	wget https://openresty.org/download/openresty-1.19.3.2.tar.gz
	tar xf openresty-1.19.3.2.tar.gz
	cd openresty-1.19.3.2
	#编译安装
	./configure
	make && make install
	#添加快捷启动
	cp -a /usr/local/openresty/bin/openresty /usr/bin/
	echo "默认安装路径：/usr/local/openresty"
	fi
	;;
3)
cd /opt
#安装依赖
yum -y install gcc openssl-devel pcre-devel zlib-devel
#下载tar包
wget http://tengine.taobao.org/download/tengine-2.1.0.tar.gz
#新建tengine用户组
groupadd -r nginx
useradd -r -g nginx -M nginx
#解压安装包：
tar -xf tengine-2.1.0.tar.gz
cd  tengine-2.1.0
#预编译
./configure --prefix=/usr/local/tengine-2.1.0
#编译安装
make && make install
#授权
chown -R nginx:nginx /usr/local/tengine-2.1.0
chmod -R 755 /usr/local/tengine-2.1.0
echo "安装目录：/usr/local/tengine-2.1.0"

;;
*)
	echo "error!";;
esac

```



### 启动脚本：

```sh
vim /etc/init.d/nginx
 
#!/bin/sh
#
# nginx - this script starts and stops the nginx daemin
#
# chkconfig:   - 85 15 
# description:  Nginx is an HTTP(S) server, HTTP(S) reverse \
#               proxy and IMAP/POP3 proxy server
# processname: nginx
# config:      /usr/local/nginx/conf/nginx.conf
# pidfile:     /usr/local/nginx/logs/nginx.pid
 
# Source function library.
. /etc/rc.d/init.d/functions
 
# Source networking configuration.
. /etc/sysconfig/network
 
# Check that networking is up.
[ "$NETWORKING" = "no" ] && exit 0
nginx="/usr/local/tengine-2.1.0/sbin/nginx"
prog=$(basename $nginx)
 
NGINX_CONF_FILE="/usr/local/tengine-2.1.0/conf/nginx.conf"
 
lockfile=/var/lock/subsys/nginx
 
start() {
    [ -x $nginx ] || exit 5
    [ -f $NGINX_CONF_FILE ] || exit 6
    echo -n $"Starting $prog: "
    daemon $nginx -c $NGINX_CONF_FILE
    retval=$?
    echo
    [ $retval -eq 0 ] && touch $lockfile
    return $retval
}
 
stop() {
    echo -n $"Stopping $prog: "
    killproc $prog -QUIT
    retval=$?
    echo
    [ $retval -eq 0 ] && rm -f $lockfile
    return $retval
}
 
restart() {
    configtest || return $?
    stop
    start
}
 
reload() {
    configtest || return $?
    echo -n $"Reloading $prog: "
    killproc $nginx -HUP
    RETVAL=$?
    echo
}
 
force_reload() {
    restart
}
 
configtest() {
  $nginx -t -c $NGINX_CONF_FILE
}
 
rh_status() {
    status $prog
}
 
rh_status_q() {
    rh_status >/dev/null 2>&1
}
 
case "$1" in
    start)
        rh_status_q && exit 0
        $1
        ;;
    stop)
        rh_status_q || exit 0
        $1
        ;;
    restart|configtest)
        $1
        ;;
    reload)
        rh_status_q || exit 7
        $1
        ;;
    force-reload)
        force_reload
        ;;
    status)
        rh_status
        ;;
    condrestart|try-restart)
        rh_status_q || exit 0
            ;;
    *)
        echo $"Usage: $0 {start|stop|status|restart|condrestart|try-restart|reload|force-reload|configtest}"
        exit 2
esac
```

```sh
chmod +x /etc/init.d/nginx
chkconfig --add nginx
chkconfig --list
chkconfig nginx on
service nginx start
```

