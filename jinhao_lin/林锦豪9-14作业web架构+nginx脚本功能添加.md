# 2022-09-14

# 1，七层负载+集群（lnmp框架至少两台服务器）一主两从数据库架构（两从做四层负载）有能力脚本实现。

#### 一、部署LNMP环境，其中数据库搭建多实例一主两从（两台机同时进行）

```shell
#################################################数据库一主二从#####################################################
#安装MySQL5.7（安装脚本)
[root@mgr1 ~]# sh mysql-5.7.38_binary_install.sh 
[root@mgr2 ~]# sh mysql-5.7.38_binary_install.sh 
#安装多实例从库
[root@mgr1 ~]# sh mysql_sameversion__multiple_instances.sh
+-----------------------+
|			|
|    谨慎输入数值！	|
|			|
|			|
+-----------------------+
请输入你所需的实例数量2
#配置Gtid主从
```

![image-20220914195631735](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209141956103.png)

```shell
##################################################php、nginx安装####################################################
[root@mgr1 ~]# sh php_install.sh
[root@mgr2 ~]# sh php_install.sh
[root@mgr1 opt]# sh nginx_install.sh
[root@mgr2 opt]# sh nginx_install.sh
```

#### 二、检查环境状态

**MySQL**

![image-20220914204638334](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209142046432.png)

**PHP**

![image-20220914204724660](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209142047757.png)

**Nginx**

![image-20220914204825860](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209142048954.png)

#### 三、搭建禅道（两台机）

```shell
[root@mgr1 opt]# cd /opt
[root@mgr1 opt]# wget https://www.zentao.net/dl/zentao/17.6/ZenTaoPMS.17.6.php7.2_7.4.zip
[root@mgr1 opt]# unzip ZenTaoPMS.17.6.php7.2_7.4.zip
[root@mgr1 opt]# mv  zentaopms /data/
[root@mgr1 opt]# cd /data/zentaopms/
[root@mgr1 zentaopms]# mkdir /etc/nginx/myhost
[root@mgr1 zentaopms]# vim /etc/nginx/nginx.conf
http {
include myhost/*.conf;
##############################################nginx配置文件#########################################################
[root@mgr1 zentaopms]# vim /etc/nginx/myhost/ZenTao.conf
server
{
    listen          80;
    server_name     192.168.159.148;
    index           index.html index.htm index.php;
    root            /data/zentaopms/www;
    location /
    {
        if (!-e $request_filename){ rewrite (.*) /index.php last;}
    }
    location ~ \.php$ {
        fastcgi_pass   127.0.0.1:9000;
        include        fastcgi_params;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
        fastcgi_param  PATH_INFO $fastcgi_script_name;
    }
    location ~ /\.ht
    {
        deny  all;
    }
}

[root@mgr1 zentaopms]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@mgr1 zentaopms]# nginx -c /etc/nginx/nginx.conf						#不读一下配置文件可能找不到PID
[root@mgr1 zentaopms]# nginx -s reload
##########################################到php.ini中添加mysql.socket###############################################
[root@mgr1 zentaopms]# vim /usr/local/php/etc/php.ini
1006 pdo_mysql.default_socket=/tmp/mysql.sock
1156 mysqli.default_socket =/tmp/mysql.sock
[root@mgr1 zentaopms]# systemctl restart php-fpm
[root@mgr1 zentaopms]# nginx -s reload
```

**进入网页开始安装**

![image-20220914214739916](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209142147079.png)

![image-20220914214932653](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209142149749.png)

![image-20220914214955271](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209142149368.png)

![image-20220914215142502](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209142151626.png)

![image-20220914215334738](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209142153822.png)

![image-20220914215358053](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209142153192.png)

![image-20220914215522415](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209142155707.png)

![](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209142155303.png)

![image-20220914215624617](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209142156730.png)

**搭建结束**

#### 四、设置七层负载和两从四层负载

**在第三台机器上写入负载配置文件**

###### 四层负载

```nginx
[root@home4 opt]# vim /etc/nginx/nginx.conf
stream {
    server {
    listen 33060;
    proxy_pass mysql;
    }
    upstream mysql {
    server 192.168.159.148:3307;
    server 192.168.159.148:3308;
    }
    server {
    listen 33062;
    proxy_pass mysql2;
    }
    upstream mysql2 {
    server 192.168.159.149:3307;
    server 192.168.159.149:3308;
    }

}
```

**用本机ip+我们设置的stream端口（33060）登录mysql查看端口是否会切换。**

![image-20220914232214408](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209142322504.png)

**用本机ip+我们设置的stream端口（33062）登录mysql查看端口是否会切换。**

![image-20220914234737429](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209142347472.png)

**四层负载设置成功**

###### 七层负载

```nginx
[root@home4 ~]# vim /etc/nginx/vhost/stream.conf
upstream web {
        server www.jhz1.com;
        server www.jhz2.com;
        }
server {
        listen 80;
        server_name 192.168.159.139;
        location / {
        proxy_pass http://web;
        proxy_set_header X-Real-IP  $remote_addr;
        proxy_redirect off;
        #proxy_set_header Host  $host;
        #proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_connect_timeout 30;
        proxy_send_timeout 15;
        proxy_read_timeout 15;
        }
}
```

**用第三台机子的ip去访问网页（192.168.159.139）**

**默认轮循所以，第二次打开的时候是JHproject2**

![image-20220914230312681](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209142303955.png)

**七层负载设置成功**



## 2，增加nginx脚本功能（反向代理，负载均衡，代理缓存控制，增加模块，以及平滑升级）

```nginx
#!/bin/bash
Yum (){
yum install yum-utils -y
cat > /etc/yum.repos.d/nginx.repo <<'EOF'
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/$releasever/$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF
yum-config-manager --enable nginx-mainline -y
echo 'y'| yum install nginx -y 

}


Source_code (){
yum install -y openssl-devel openssl pcre pcre-devel gcc gcc-c++ zlib zlib-devel 
cd /opt
wget https://nginx.org/download/nginx-1.22.0.tar.gz
tar -xvf nginx-1.22.0.tar.gz
cd nginx-1.22.0
useradd -s /sbin/nologin nginx
./configure --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib64/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-compat --with-file-aio --with-threads --with-http_addition_module --with-http_auth_request_module --with-http_dav_module --with-http_flv_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-mail --with-mail_ssl_module --with-stream --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic -fPIC' --with-ld-opt='-Wl,-z,relro -Wl,-z,now -pie'
make && make install 
mkdir -p /var/cache/nginx/

}


Proxy () {
read -p "请输入你请求反向代理的URL(ip:port或www.xxx.com)：" URL
ip=`ifconfig | grep -w broadcast | awk -F "[ ]+" '{print $3}'`
nxconf=`find / -name nginx.conf`
line=`cat -n $nxconf | grep -i http | awk -F "[ http]+" 'NR==1{print $2}'`
dir=`echo $nxconf | awk -F '/nginx.conf' '{print $1}'`
mkdir -p $dir/vhost
cat $nxconf | grep $dir/vhost
if [ $? -eq 0 ]
then
	echo "子配置文件夹已存在无需配置"
else
	echo $line | xargs -i sed -i "{}a include $dir/vhost/*.conf;" $nxconf
fi
cat > $dir/vhost/proxy.conf << EOF
server {
	listen       80;
	server_name  $ip;

	location / {
		root   html;
		index  index.html index.htm index.php;
		proxy_pass  http://$URL
		proxy_set_header X-Real-IP  '$remote_addr';
	        proxy_redirect off;
        	proxy_connect_timeout 30;
        	proxy_send_timeout 15;
        	proxy_read_timeout 15;
	}
}
EOF
nginx -c $nxconf
nginx -s reload
}

Load_Balance4 (){
read -p "请输入你要nginx监听的端口：" port
read -p "自定义代理名：" name
read -p "负载的服务器(ip+port)：" ip
nxconf=`find / -name nginx.conf`
cat >> $nxconf << EOF
stream {
    server {
    listen $port;
    proxy_pass $name;
    }
    upstream $name {
    server $ip;
    }
}
EOF
nginx -c $nxconf
nginx -s reload

}

Load_Balance7 (){
read -p "请输入你要进行负载的服务器1(ip:port或www.xxx.com)：" URI1
read -p "请输入你要进行负载的服务器2(ip:port或www.xxx.com)：" URI2
read -p "自定义代理名：" name
ip=`ifconfig | grep -w broadcast | awk -F "[ ]+" '{print $3}'`
nxconf=`find / -name nginx.conf`
line=`cat -n $nxconf | grep -i http | awk -F "[ http]+" 'NR==1{print $2}'`
dir=`echo $nxconf | awk -F '/nginx.conf' '{print $1}'`
mkdir -p $dir/vhost
cat $nxconf | grep $dir/vhost
if [ $? -eq 0 ]
then
        echo "子配置文件夹已存在无需配置"
else
        echo $line | xargs -i sed -i "{}a include $dir/vhost/*.conf;" $nxconf
fi
cat > $dir/vhost/balance.conf << EOF
upstream $name {
        server $URI1;
        server $URI2;
        }
server {
        listen 80;
        server_name $ip;
        location / {
        proxy_pass http://$name;
        proxy_set_header X-Real-IP  '$remote_addr';
        proxy_redirect off;
        #proxy_set_header Host  '$host';
        #proxy_set_header X-Forwarded-For   '$proxy_add_x_forwarded_for';
        proxy_connect_timeout 30;
        proxy_send_timeout 15;
        proxy_read_timeout 15;
        }
}
EOF
nginx -c $nxconf
nginx -s reload

}

Load_Balance (){
while true
do
echo -e "\e[36m
______________________________
|                             |
|        负载均衡             |
|    1.四层负载		      |    
|    2.七层负载       	      |         
|    3.返回主菜单             |
|    4.退出程序		      |	
|                             |
|  `date "+%F %H:%M:%S"`        |
|_____________________________|
(\__/) ||               
(•ㅅ•) ||               
/ 　 づv\e[0m"
read -p "请输入你的指示:" I
case $I in
1|四层负载)
	Load_Balance4
	continue
	;;
2|七层负载)
	Load_Balance7
	continue
	;;
3|返回主菜单)
	echo "返回主菜单"
	break
	;;
4|退出程序)
	echo "谢谢使用"
	exit
	;;
	esac
done
}

Proxy_cache () {
read -p "输入你需要添加缓存的配置文件(*.conf)：" conf
conf=`find / -nmae $conf`
proxyline=`cat -n $conf | grep proxy_pass | awk '{print $1}'`
ip=`ifconfig | grep -w broadcast | awk -F "[ ]+" '{print $3}'`
nxconf=`find / -name nginx.conf`
line=`cat -n $nxconf | grep -i http | awk -F "[ http]+" 'NR==1{print $2}'`
dir=`echo $nxconf | awk -F '/nginx.conf' '{print $1}'`
mkdir -p $dir/vhost
cat $nxconf | grep $dir/vhost
if [ $? -eq 0 ]
then
        echo "子配置文件夹已存在无需配置"
else
        echo $line | xargs -i sed -i "{}a include $dir/vhost/*.conf;" $nxconf
fi
cat $nxconf | grep  proxy_cache_path
if [ $? -eq 0 ]
then
        echo "缓存目录已配置"
else
	echo $line | xargs -i sed -i "{}a  proxy_cache_path $dir/cache/first levels=1:2  keys_zone=first:20m  max_size=1g;" $nxconf
	echo $proxyline | xargs -i sed -i "{}a proxy_buffer_size 4k;" $conf
	echo $proxyline | xargs -i sed -i "{}a proxy_buffers 32 4k;" $conf
	echo $proxyline | xargs -i sed -i "{}a proxy_busy_buffers_size 64k;;" $conf
	echo $proxyline | xargs -i sed -i "{}a proxy_cache  first;" $conf
	echo $proxyline | xargs -i sed -i "{}a proxy_cache_valid   200  10m;" $conf
	echo $proxyline | xargs -i sed -i '{}a add_header   X-cache   "$upstream_cache_status  from  $server_addr";' $conf
	
fi
if [ -f $dir/cache ]
then
	echo "缓存文件夹已存在"
else
	mkdir -p $dir/cache/first
	chown -R nginx $dir/cache/first
fi
nginx -c $nxconf
nginx -s reload

}

Add_Module (){
echo "请在解压完二进制包生成的目录下运行此选项!"
a=`find / -name "nginx" | grep /sbin/nginx`
$a -V
read -p "请输入你nginx的安装目录" dir
./configure --help
read -p "请输入你添加的新模块" module
./configure --prefix=$dir --with-$module
make
mv $a "$a".bak
cp objs/nginx $a
$a -s reload

}

Update (){
cd /opt
a=`find / -name "nginx" | grep /sbin/nginx`
$a -V
read -p "请输入你已经安装的nginx家目录" dir
read -p "请输入你要升级的nginx版本号(例：1.14.0):" V
yum install -y gcc gcc-c++ pcre pcre-devel openssl openssl-devel zlib zlib-devel
wget http://nginx.org/download/nginx-"$V".tar.gz
cd nginx-"$V".tar.gz
./configure --prefix=$dir --user=nginx --group=nginx --with-http_ssl_module --with-http_gzip_static_module --with-poll_module --with-file-aio --with-http_realip_module --with-http_addition_module --with-http_addition_module --with-http_random_index_module --with-http_stub_status_module --with-pcre --with-stream
make 
mv $a "$a"_old
cp objs/nginx $a
b=`find / -name nginx.pid`
process=`cat $b`
kill -USR2 $process
kill -WINCH $process
kill -QUIT $process
$a -s reload
$a -V
}

while true
do
echo -e "\e[36m
_____________________________
|                            | 
|         Nginx              |
|     1)yum安装		     |
|     2)源码安装             |
|     3)反向代理             |
|     4)负载均衡             |
|     5)代理缓存             |
|     6)增加模块             |
|     7)平滑升级             |
| 			     |
|            	             |
|     `date "+%F|%H:%M:%S"`    |
|  请用source指令启动该脚本  |
|  9.退出程序                |
|____________________________|
(\__/) ||               
(•ㅅ•) ||               
/ 　 づv\e[0m"
read -p "请输入你的指示:" I
case $I in
1|yum安装)
	Yum	
	continue
	;;
2|源码安装)
	Source_code; 
	continue
	;;
3|反向代理)
        Proxy;
        continue
        ;;
4|负载均衡)
        Load_Balance;
        continue
        ;;
5|代理缓存)
        Proxy_cache;
        continue
        ;;
6|增加模块)
        Add_Module;
        continue
        ;;
7|平滑升级)
        Update;
        continue
        ;;
9|退出程序)
	echo "谢谢使用"
	break
	;;
	*)
	exit
	esac
done
```

