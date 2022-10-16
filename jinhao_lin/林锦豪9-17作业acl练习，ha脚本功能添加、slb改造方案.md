# 2022-09-17

# 1，haproxy的acl练习（笔记）

acl	<aclname>	<criterion>		[flags]				[operator]				[<values]

acl		名称				匹配规范			匹配模式			具体操作符			操作对象类型

#### 一、Header

##### 1.域名匹配

**nginx准备了两个web：**![image-20220918192020956](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209181920126.png)

![image-20220918192042215](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209181920364.png)

**tomcat准备一个：**![image-20220918192134145](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209181921177.png)

![image-20220918192228441](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209181922515.png)

```nginx
listen web
 bind 192.168.159.139:80
 mode http
 balance roundrobin
 cookie SERVER-COOKIE insert indirect nocache
 option forwardfor
 acl wp hdr_dom(host) www.Jhblog.com
 use_backend wordpress if wp
 acl zt hdr_dom(host) www.zentao.com
 use_backend zentao if zt
 acl jp hdr_dom(host) www.jpress.com
 use_backend jpress if jp
backend wordpress
 server web1 192.168.159.137:80 weight 1 check inter 3000 fall 3 rise 5
backend zentao
 server web2 192.168.159.137:8080 weight 1 check inter 3000 fall 3 rise 5
backend jpress
 server web3 192.168.159.138:8080 weight 1 check inter 3000 fall 3 rise 5
```

![image-20220918193418324](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209181934394.png)

**www.blog.com：**![image-20220918193542777](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209181935851.png)

**Request URL（请求URL 就是我们的输入）**

**可以看到Respon Headers (回应头) ：link（连接）到了www.jhblog.com。**

**www.zentao.com:**![image-20220918194226271](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209181942312.png)

**www.jpress.com:**![image-20220918194340695](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209181943735.png)

**查看状态：**![image-20220918194540873](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209181945935.png)

##### 2.浏览器类型匹配

```nginx
acl zt hdr_dom(host) www.zentao.com
 use_backend zentao if zt
acl redirect_test hdr(User-Agent) -m sub -i "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)"
 redirect prefix http://192.168.159.137 if redirect_test
 default_backend jpress
backend zentao
 server web1 192.168.159.137:8080 weight 1 check inter 3000 fall 3 rise 5
backend  jpress
 server web2 192.168.159.138:8080 weight 1 check inter 3000 fall 3 rise 5
```

**谷歌浏览器：**![image-20220918213837761](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209182138959.png)

**QQ浏览器：**![image-20220918213931634](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209182139804.png)



#### 二、Src

##### 基于源地址的访问控制

```nginx
 listen web
 bind 192.168.159.139:80
 mode http
 balance roundrobin
 cookie SERVER-COOKIE insert indirect nocache
 option forwardfor
 acl view_test src 192.168.1.28
 http-request deny if view_test
 default_backend default_web
backend zentao
 server web1 192.168.159.137:8080 weight 1 check inter 3000 fall 3 rise 5
backend default_web
 server web2 192.168.159.138:8080 weight 1 check inter 3000 fall 3 rise 5
```

![image-20220918210538679](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209182105736.png)

**访问之后直接跳到Jpress**

![image-20220918210558301](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209182105395.png)

#### 三.Path

##### 动静分离

```nginx
 acl image path_beg -i /gz /hai
 acl image path_end -i .jpg .png .gif
 use_backend static if image
 default_backend sb
backend static
 server web 192.168.159.138:80 weight 1 check inter 3000 fall 3 rise 5
backend sb
 server web 192.168.159.138:8080 weight 1 check inter 3000 fall 3 rise 5
 server zentao 192.168.159.137:8080  weight 1 check inter 3000 fall 3 rise 5
 server app 192.168.159.137:80 cookie app weight 1 check inter 3000 fall 3 rise 5
```

**输入1.jpg**

![image-20220918230218351](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209182302772.png)

**不输入走默认**

![image-20220918230249361](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209182302599.png)

**刷新轮循到wordpress**

![image-20220918230312346](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209182303435.png)

# 2，haproxy脚本完善，增加功能（压缩，四层，七层，cookie等等）

```sh
#!/bin/bash
Install (){
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
}

Compression () {
read -p "请输入需要添加压缩功能web名称(listen或frontend):" webname
conf=`find / -name haproxy.cfg | grep -w "etc"`
line=-`cat -n $conf | grep -w "$webname"  | awk -F "[listen frontend ]+" 'NR==1{print $2}'`
echo $line | xargs -i sed -i "{}a compression algo gzip deflate \ncompression type compression type text/plain text/html text/css text/xml text/javascript application/javascript" $conf

}

Load_Balance4 () {
read -p "请设置linsten监听的web名：" webname
read -p "请设置linsten监听的p+port(格式ip:port)：：" webip
read -p "请输入你要负载的server1的ip+port(格式ip:port)：" server1
read -p "请输入你要负载的server2的ip+port(格式ip:port)：" server2
read -p "请输入负载算法规则(1.roundrobin 2.leastconn 3.static-rr 4.source)：" rule
conf=`find / -name haproxy.cfg | grep -w "etc"`
cat >> $conf << EOF
listen $webname
 bind $webip
 mode tcp
 balance $rule
 server s1 $server1
 server s2 $server2
EOF

}

Load_Balance7 () {
read -p "请设置linsten监听的web名：" webname
read -p "请设置linsten监听的p+port(格式ip:port)：：" webip
read -p "请输入你要负载的server1的ip+port(格式ip:port)：" server1
read -p "请输入你要负载的server2的ip+port(格式ip:port)：" server2
read -p "请输入负载算法规则(roundrobin; leastconn; static-rr; source; random;)：" rule
conf=`find / -name haproxy.cfg | grep -w "etc"`
cat >> $conf << EOF
listen $webname
 bind $webip
 mode http
 log global
 option forwardfor
 balance $rule
 server s1 $server1
 server s2 $server2
EOF

}

Cookie () {
read -p "请输入你要添加cookie会话保持的web名：" webname
conf=`find / -name haproxy.cfg | grep -w "etc"`
line=`cat -n $conf | grep -w "$webname" | egrep -v "^$|#" | egrep -w "listen $webname|frontend $webname" | awk -F "[listen frontend ]+" 'NR==1{print $2}'`
nextline=`cat -n $conf | tail -n +$line | egrep "listen|frontend" | xargs -i echo -n {} | awk -F "[listen $webname listen frontend]+" '{print $2}'`
sed -n "$line,$[$nextline-1]p" $conf | egrep -v "^$|#"
read -p "请选择你要添加cookie会话保持的server名：" servername
echo $line | xargs -i sed -i "{}a cookie SERVER-COOKIE insert indirect nocache" $conf
row=`sed -n "$line,$[$nextline-1]p" $conf | egrep -v "^$|#" | grep "server $servername"`
sed -i "s/$row/$row cookie zentao/g" $conf

}

while true
do
echo -e "\e[36m
_____________________________
|                            | 
|      Haproxy               |
|     1)安装                 |
|     2)压缩报文             |
|     3)四层负载             |
|     4)七层负载             |
|     5)cookie               |
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
	Install;
	continue
	;;
2|压缩报文)
	Compression; 
	continue
	;;
3|四层负载)
        Load_Balance4;
        continue
        ;;
4|七层均衡)
        Load_Balance7;
        continue
        ;;
5|cookie)
        Cookie;
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

# 3，slb改造，将之前的nginx负载的集群进行负载改造，改造成haproxy考虑几个问题，如何改造，大概会遇到什么问题。解决方案，画架构图，整理文档和脚本。方案要写。

#### 一、分析Nginx和HAProxy

1.Nginx和HAProxy都能支持http/tcp/udp协议的负载均衡，HAProxy的负载均衡能力优于Nginx，并且拥有服务器健康检查功能和系统状态监控页面，但Nginx同时是一个高性能的HTTP和反向代理服务器，具有很高的稳定性，模块支持多。

2.鉴于HAProxy**负载能力强于**Nginx，并且对群集节点的健康检查功能强，Nginx的**高性能代理服务器**，**我们可以用HAProxy作为均衡负载代理，Nginx作为web服务。**

#### 二、改造流程

1.先在HAProxy配置好web集群所需的负载均衡设置，然后再卸掉Nginx所设置的负载均衡的配置。启动HAProxy系统，查看服务器监控状态，确认服务器状态都完好无误，然后重载Nginx（reload），将负载均衡全部转交给HAProxy。

#### 三、在搭建过程中可能遇到的问题

1.HAProxy不像Nginx采用类似编程语言的配置，用文档结构表示配置关系，看起来清晰。并且可以分多个文件编写，方便管理分类服务器。HAProxy的负载服务器编写都写入在配置文件中，这使得当负载所需的web服务增多时，编写配置文件和查看变得繁琐。

解决方案：严格规范对配置文件的书写，并指明编写内容和加以注释。

2.HAProxy的重载配置的功能需要重启进程，没有nginx的reload的平滑和友好。

解决方案：多用系统自带的状态监控功能，设置备用web服务器加入负载服务器中（高可用）。

#### 四、架构图

![image-20220919210317902](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209192103978.png)





