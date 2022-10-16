### 1、了解市面上的web服务器

偏向静态的web服务器
nginx
apache
IIS
lighttpd
tengine
openresty

偏向动态的web服务器
tomcat。

### 2、什么是NGINX

nginx是一个轻量级、高性能的web服务器和反向代理服务器，同时也是一个比较优秀的负载均衡服务器和缓存服务器，可以运行于多种平台
在连接高并发的情况下，能够支持高达 50,000 个并发连接数的响应。

3、nginx安装
3.1.yum安装
[root@nginx1 ~]# cat >> /etc/yum.repos.d/nginx.repo <<EOF

```
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
```

[root@nginx1 ~]# yum install -y nginx

3.2.编译安装
[root@nginx1 ~]# useradd -r nginx -s /bin/false 
[root@nginx1 ~]# cd /opt
[root@nginx1 opt]# wget http://nginx.org/download/nginx-1.20.1.tar.gz
[root@nginx1 opt]# tar -zxvf nginx-1.20.1.tar.gz   &&  cd nginx-1.20.1
[root@nginx1 nginx-1.20.1]# yum install -y gcc gcc-c++ automake openssl openssl-devel make pcre-devel gd-devel
gd-devel 在centos7.6里面是没有该安装包，需要配置网络源进行安装
[root@nginx1 nginx-1.20.1]# ./configure --prefix=/usr/local/nginx --user=nginx  --group=nginx --sbin-path=/usr/local/nginx/nginx --conf-path=/usr/local/nginx/conf/nginx.conf --error-log-path=/var/log/nginx/nginx.log --http-log-path=/var/log/nginx/access.log --modules-path=/usr/local/nginx/modules --with-select_module --with-poll_module --with-threads  --with-http_ssl_module --with-http_v2_module  --with-http_realip_module --with-http_image_filter_module --with-http_sub_module --with-http_flv_module --with-http_gunzip_module --with-http_gzip_static_module  --with-http_stub_status_module --with-stream

http://nginx.org/en/docs/configure.html 可查看源码安装，各配置项的具体含义



[root@nginx1 nginx-1.20.1]# make && make install
启动nginx
[root@nginx1 nginx]# ln -s /usr/local/nginx/nginx /usr/sbin/nginx

[root@nginx1 nginx]# nginx 
nginx: [emerg] getpwnam("nginx") failed				#





[root@nginx1 nginx-1.20.1]# nginx   
检验nginx是否正常运行
[root@nginx1 nginx-1.20.1]# ps -ef |grep nginx

![file://c:\users\admini~1\appdata\local\temp\tmpmxl0kh\1.png](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205181600141.png)

nginx 常用命令：

启动：直接运行nginx主程序

重启：nginx -s reload

关闭：nginx -s stop

检查配置文件是否有错：nginx -t 

显示版本：nginx -v

查看nginx版本与编译情况： nginx -V



#### 实战：如何添加或禁用功能

情况1：添加自身支持功能或删除功能：
./configure --help
1.进入源码解压目录重新编译，把之前编译的参数都带上，后面添加上需要新增的模块
2.执行之后make下，make后千万不要执行make install
3.执行make后，当前目录会生成一个objs目录，进入这个目录
4.目录下会产生一个新的nginx程序文件，这个就是新的程序文件，把之前的备份，产生新的拷贝过去
[root@nginx1 objs]# cp nginx /usr/sbin/nginx
5.[root@nginx1 objs]# nginx -V

情况2：添加第三方模块
--add-module=模块路径
接下来操作如情况1步骤1一致



### 3、nginx主配置文件解析：

配置 文件主要由四部分组成：
   main(全局设置)，HTTP(设置负载均衡服务器组)，
   server(虚拟主机配置)，和location(URL匹配特定位置设置)。

​           ![file://c:\users\admini~1\appdata\local\temp\tmpmxl0kh\1.png](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205181600962.png)

[root@nginx1 conf]# egrep -v "^.*#|^$" nginx.conf               #默认配置文件
worker_processes  1;                                                           #全局配置    
events {                                                                             #events事件模块
    worker_connections  1024;
}
http {                                                                                #http模块，具有全局作用（应用配置于所有虚拟主机）
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;
    server {                                                                        #server模块，相当于虚拟主机
        listen       80;
        server_name  localhost;
        location / {                                                               #location模块
            root   html;
            index  index.html index.htm;
        }
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }
}

配置文件详解（重点）：

#### 1）全局变量  部分：

----------------------------------------------------

#user  nobody ;            #Nginx的worker进程运行用户以及用户组
worker_processes  1;              #Nginx开启的进程数，建议设置为等于CPU总核心数。
#worker_processes auto;        ## 多核心CPU设置。cat  /proc/cpuinfo     查看当前CPU 的信息。
#worker_processes 4              # 4核CPU
#worker_cpu_affinity 0001 0010 0100 1000;     #不是二进制                                 
                                            ##CPU亲核，设置工作进程与 CPU 绑定。
                                          #指定了哪个cpu分配给哪个进程，一般来说不用特殊指定。如果一定要设的话，用0和1指定分配式.
                                             #这样设就是给1-4个进程分配单独的核来运行，出现第5个进程是就是随机分配了。
#error_log    logs/error.log  info;       #定义全局错误日志定义类型，[debug|info|notice|warn|crit]
#pid        logs/nginx.pid;                 #指定进程ID存储文件位置

worker_rlimit_nofile   65535;						#了解端口复用技术

                #一个nginx进程打开的最多文件描述符数目，理论值应该是最多打开文件数（ulimit -n）与nginx相除，
                但是nginx分配请求并不是那么均匀，所以最好与ulimit -n的值保持一致。
                
                ulimit -a  查看所有   ulimit -n 查看 最大文件数量   ulimit -u  查看最大进程数量 
                每个用户打开的文件数量   nofile     打开的进程数量  nproc
    
                #vim /etc/security/limits.conf
                *                soft    nproc          65535
                *                hard    nproc         65535
                *                soft    nofile          65535
                *                hard    nofile         65535
                注意：设置了这个后，修改worker_connections值时，是不能超过worker_rlimit_nofile的这个值。
                修改后，不需要重启， 退出当前会话，重新 登录即可读取新的配置值 

#### 2）事件驱动模型配置 部分：

----------------------------------------------------
events {
    

    use epoll;  #use [ kqueue | rtsig | epoll | /dev/poll | select | poll ];    ## epoll模型是 Linux 2.6以上版本内核中的高性能网络I/O模型，
                    如果跑在 FreeBSD 上面，就用kqueue模型。
 https://blog.csdn.net/weixin_30396699/article/details/99811523
 https://www.cnblogs.com/crazymakercircle/p/15411888.html

```
worker_connections  65535;      #每个进程可以处理的最大连接数，理论上每台nginx服务器的最大连接数为
                                worker_processes x worker_connections。
                                理论值：worker_rlimit_nofile  / worker_processes 
                                #注意：最大客户数也由系统的可用socket连接数限制（~ 64K），所以设									置不切实际的高没什么好处
```


​                                                    

     multi_accept on;        #off：一个工作进程只能同时接受一个新的连接。
     						  on：一个工作进程可以同时接受所有的新连接。
                                                    
     accept_mutex on         # 是否打开负载均衡互斥锁，默认是off关闭的 
     					on：nginx的多个woker进程将以串行方式接入新连接，大量并发时不如off。
    					off ：新连接将通报给所有worker进程。
    此两个设置一般取其一
}

注：

#### Nginx的请求方式处理

Nginx 是一个 高性能 的 Web 服务器，能够同时处理大量的并发请求 。它结合多进程机制和 异步机制 ，异步机制使用的是 异步非阻塞方式 ，接下来就给大家介绍一下 Nginx 的 多线程机制 和 异步非阻塞机制 。

3.1. 多进程机制
服务器每当收到一个客户端请求时，就有 服务器主进程 （ master process ）生成一个 子进程（ worker process ）出来和客户端建立连接进行交互，直到连接断开，该子进程就结束了。
使用 进程 的好处是 各个进程之间相互独立 ， 不需要加锁 ，减少了使用锁对性能造成影响，同时降低编程的复杂度，降低开发成本。
其次，采用独立的进程，可以让 进程互相之间不会影响 ，如果一个进程发生异常退出时，其它进程正常工作， master 进程则很快启动新的 worker 进程，确保服务不会中断，从而将风险降到最低。
缺点是操作系统生成一个 子进程 需要进行 内存复制 等操作，在 资源 和 时间 上会产生一定的开销。当有 大量请求 时，会导致 系统性能下降 。

3.2. 异步非阻塞机制
每个 工作进程 使用 异步非阻塞方式 ，可以处理多个客户端请求 。
当某个 工作进程 接收到客户端的请求以后，调用 IO 进行处理，如果不能立即得到结果，就去处理其他请求 （即为非阻塞 ），而客户端在此期间也无需等待响应 ，可以去处理其他事情（即为异步 ）
当 IO 返回时，就会通知此工作进程，该进程得到通知，暂时挂起当前处理的事务去 响应客户端请求 。

<font color='red'>举例：多食客点餐，服务员去厨房拿餐，先做好的就拿给食客（食客相当于客户端，服务员相当于worker进程，餐相当于数据）</font>

4. Nginx事件驱动模型
    在 Nginx 的 异步非阻塞机制 中， 工作进程在调用 IO 后，就去处理其他的请求，当 IO 调用返回后，会通知该工作进程 。
    对于这样的系统调用，主要使用 Nginx 服务器的事件驱动模型来实现，如下图所示：

  ​           ![file://c:\users\admini~1\appdata\local\temp\tmpmxl0kh\1.png](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205181600027.png)

如上图所示， Nginx 的 事件驱动模型 由 事件收集器 、 事件发送器 和 事件处理器 三部分基本单元组成。
• 事件收集器：负责收集 worker 进程的各种 IO 请求；

• 事件发送器：负责将 IO 事件发送到 事件处理器 ；

• 事件处理器：负责各种事件的 响应工作 。

事件发送器将每个请求放入一个 待处理事件列表 ，使用非阻塞 I/O 方式调用 事件处理器来处理该请求。
其处理方式称为 “多路 IO 复用方法” ，常见的包括以下三种：select 模型、 poll模型、 epoll 模型。

5. Nginx进程处理模型
Nginx 服务器使用 master/worker 多进程模式，多线程启动和执行的流程如下：
1. 主程序Master process启动后，通过一个 for 循环来接收和处理外部信号

2. 主进程通过 fork() 函数产生 worker 子进程 ，每个 子进程 执行一个 for 循环来实现 Nginx 服务器 对事件的接收 和 处理 

一般推荐 worker 进程数 与 CPU 内核数 一致，这样一来不存在 大量的子进程 生成和管理任务，避免了进程之间 竞争 CPU 资源 和 进程切换 的开销。
而且 Nginx 为了更好的利用 多核特性 ，提供了 CPU 亲缘性 的绑定选项，我们可以将某 一个进程绑定在某一个核上，这样就不会因为 进程的切换 带来 Cache 的失效。
对于每个请求，有且只有一个 工作进程 对其处理。首先，每个 worker 进程都是从 master进程 fork 过来。在 master 进程里面，先建立好需要 listen 的 socket（listenfd） 之后，然后再 fork 出多个 worker 进程。
所有 worker 进程的 listenfd 会在 新连接 到来时变得 可读 ，为保证只有一个进程处理该连接，所有 worker 进程在注册 listenfd 读事件前抢占 accept_mutex 
抢到 互斥锁 的那个进程注册 listenfd 读事件 ，在读事件里调用 accept 接受该连接。
当一个 worker 进程在 accept 这个连接之后，就开始读取请求 ， 解析请求 ， 处理请求，产生数据后，再返回给客户端 ，最后才断开连接 ，一个完整的请求就是这样。
我们可以看到，一个请求，完全由 worker 进程来处理，而且只在一个 worker 进程中处理。
如下图所示：

​           ![file://c:\users\admini~1\appdata\local\temp\tmpmxl0kh\1.png](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205181600090.png)

在 Nginx 服务器的运行过程中， 主进程 和 工作进程 需要进程交互。交互依赖于 Socket 实现的管道来实现。
5.1. 主进程与工作进程交互
这条管道与普通的管道不同，它是由 主进程 指向 工作进程 的单向管道 ，包含主进程向工作进程发出的指令工，作进程 ID 等。同时主进程与外界通过信号通信 ；每个子进程具备接收信号 ，并处理相应的事件的能力。
5.2. 工作进程与工作进程交互
这种交互和 主进程-工作进程 交互基本一致，但是会通过主进程间接完成，工作进程之间是相互隔离的。
所以当工作进程 W1 需要向工作进程 W2 发指令时，首先找到 W2 的 进程ID ，然后将正确的指令写入指向 W2 的 通道，W2 收到信号采取相应的措施。



2.很多人会误解 worker_connections  这个参数的意思，认为这个值就是nginx所能建立连接的最大值。
其实不然，这个值是表示每个 worker 进程所能建立连接的最大值，
所以，一个nginx能建立的最大连接数，应该是worker_connections X worker_processes。

当然，这里说的是最大连接数，对于HTTP请求本地资源来说，能够支持的最大并发数量是worker_connections * worker_processes
而如果是HTTP作为反向代理来说，最大并发数量应该是 worker_connections X worker_processes  /2。
因为作为反向代理服务器，每个并发会建立与客户端的连接和与后端服务的连接，会占用两个连接。



#### 3）设定 http 的部分：

---------------------------------------------------------------------

http { 

​           #文件类型与拆分配置文件设置：----------------------------------------------------------------------------------------------------

​                include mime.types;      #文件扩展名与文件类型映射表,设定mime类型,类型由mime.type文件定义 
​                default_type  application/octet-stream;         #默认文件类型
​                server_tokens off;          #不显示版本号          
​                include vhost/*.conf;           #附加子配置文件
​               \#include /etc/nginx/proxy.conf;             #反向代理配置，可以打开proxy.conf看看     
​               \#include /etc/nginx/fastcgi.conf;             #fastcgi配置，可以打开fastcgi.conf看看

​             #日志模块设置：---------------------------------------------------------------------------
​                \#生成日志的格式定义
​                log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
​                            '$status $body_bytes_sent "$http_referer" '
​                            '"$http_user_agent" "$http_x_forwarded_for"';

​                                \#定义日志的格式。后面定义要输出的内容。
​                                \#1.$remote_addr         与$http_x_forwarded_for 用以记录客户端的ip地址；
​                                \#2.$remote_user         用来记录客户端用户名称；
​                                \#3.$time_local         用来记录访问时间与时区；
​                                \#4.$request         用来记录请求的url与http协议；
​                                \#5.$status         用来记录请求状态； 
​                                \#6.$body_bytes_sent         记录发送给客户端文件主体内容大小；
​                                \#7.$http_referer         用来记录从那个页面链接访问过来的；
​                                \#8.$http_user_agent         记录客户端浏览器的相关信息

​                \#访问日志
​                access_log  /var/log/nginx/access.log  main;

​				#禁用访问日志

​				 access_log  off

​              \#数据传输模块设置：-----------------------------------------------------------------------------------------
​                sendfile   on;                   
​                \# sendfile 指令指定 nginx 是否调用 sendfile 函数（zero copy 方式）来输出文件，如果<font color='red'>对于普通应用，必须设为 on，</font>用来进行下载等应用磁盘IO重负载应用，可设置为 off，以平衡磁盘与网络I/O处理速度，降低系统的uptime.
​               <font color='red'> \# sendfile: 设置为on表示启动高效传输文件的模式。可以让Nginx在传输文件时直接在磁盘和tcp socket之间传输数据。</font>
​                如果这个参数不开启，会先在用户空间（Nginx进程空间）申请一个buffer，用read函数把数据从磁盘读到内核cache，
​               再从内核 cache读取到用户空间nginx 的buffer，再用write函数把数据从用户空间的buffer写入到内核的buffer，最后到tcp socket。
​                开启这个参数后可以让数据不用经过用户buffer。可加速web服务器在传输文件方面的效率。

​                \#tcp_nopush     on;                   #tcp_nopush：在linux的实现里，其实就是tcp_cork 。 而这个tcp_cork直接就禁止了小包的发送。也就是说，你的nginx发送的包要都是满的才发送。包都是满的，那ACK就少，网络利用率就起来了，但会增加延迟。默认 ：off

​                keepalive_timeout  65;      #连接超时时间，单位是秒 
​                tcp_nodelay  on;                    #启动TCP_NODELAY，就意味着禁用了 Nagle 算法，允许小包的发送。可降低延迟，但是会增加网络的负担。 关闭TCP_NODELAY，则是应用了 Nagle 算法。 数据只有在写缓存中累积到一定量之后，才会被发送出去，这样明显提高了 网络利用率（实际传输数据payload与协议头的比例大大提高）。但是这由不可避免地增加了延时。 默认： on

注：tcp_nopush与 tcp_nodelay尽量不要同时开启，选其一

​     #下载服务器模块设置：------------------------------------------------------------------
​                #autoindex on;                 #开启目录列表访问（网站以树目录展示），合适下载服务器，默认关闭。
​                charset utf-8;             #服务器 默认编码（若不设置，下载服务器有中文，会乱码）

​     #请求报文模块设置：------------------------------------------------------------------
​                \#server_names_hash_bucket_size 128;        #服务器名字的hash表大小
​                \#client_header_buffer_size 32k;                 #客户端请求头部的缓冲区大小
​                \#large_client_header_buffers 4 64k;         #header过大，它会使用large_client_header_buffers来读取
​                \#client_max_body_size 8m;                   #接收 客户端 主体 的最大体积，可以限制用户上传单个文件的大小。 

   #gzip压缩模块设置 :  --------------------------------------------              
​           	 gzip on;   #开启gzip压缩输出 
​            	gzip_min_length 1k;        #最小压缩文件大小
​           	 gzip_buffers 4 16k;         #压缩缓冲区
​            	gzip_http_version 1.1;         #压缩版本（默认1.1，前端如果是squid2.5请使用1.0）
​            	gzip_comp_level 2;          #压缩等级
​            	gzip_types text/plain application/x-javascript text/css application/xml;       
​            	#压缩类型，默认就已经包含text/html，所以下面就不用再写了，写上去也不会有问题，但是会有一个warn。
​            	gzip_vary on;                   #检查预压缩文件			



\#虚拟主机的配置 :--------------------------------------------

server {

​    listen  80;      #监听端口
​    server_name 192.168.1.11;    <font color='red'> #主机名：可以是域名或IP，域名可以有多个，用空格隔开， 多个虚拟主机主要依靠这一选项来区分，</font><font color='red'>重要！</font>

​    root /home/public;          #定义站点根目录
​     index index.html index.htm index.jsp;     #定义索引首页

​    error_page                      400 402 403 404 405 406 410 411 413 416 500 501 502 503 504  /error.html;            #定义错误页面
​    error_page                      505  /error.html;
​    root   html;



### 4、配置虚拟主机 

对于nginx来说，它有3种类型的虚拟主机，即<font color='red'>基于域名的虚拟主机</font>、<font color='red'>基于IP的虚拟主机</font>和<font color='red'>基于端口的虚拟主机</font>。

#### 4.1.配置基于域名的虚拟主机

1.创建基础站点目录
[root@nginx1 conf]# mkdir -p /www/web /www/blog
[root@nginx1 conf]# tree /www
/www
├── blog
└── web

2 directories, 0 files
[root@nginx1 conf]# chown -R nginx:nginx /www
[root@nginx1 conf]# ll /www
总用量 0
drwxr-xr-x 2 nginx nginx 6 3月  21 21:06 blog
drwxr-xr-x 2 nginx nginx 6 3月  21 21:06 web

2.配置默认站点目录首页文件
[root@nginx1 conf]# echo "welcome to web-server" >>/www/web/index.html
[root@nginx1 conf]# echo "welcome to blog-server" >>/www/blog/index.html
[root@nginx1 conf]# cat /www/web/index.html
welcome to web-server
[root@nginx1 conf]# cat /www/blog/index.html
welcome to blog-server

3.修改配置文件
增加两个server标签，配置如下：

    server {
            listen       80;
            server_name  web.lin.com;
            location / {
                root   /www/web;
                index  index.html index.htm;
            }
        }
        
    server {
        listen       80;
        server_name  blog.lin.com;
        location / {
            root   /www/blog;
            index  index.html index.htm;
        }
    }


[root@nginx1 conf]# nginx -t                    #自带语法检查
nginx: the configuration file /usr/local/nginx/conf/nginx.conf syntax is ok
nginx: configuration file /usr/local/nginx/conf/nginx.conf test is successful

平滑重启nginx服务
[root@nginx1 conf]# nginx -s reload           

测试：
1.在linux上：
[root@nginx1 conf]# curl web.lin.com
welcome to web-server
[root@nginx1 conf]# curl blog.lin.com
welcome to blog-server

2.在windows浏览器上：
修改windows本地hosts，实现域名转发

​           ![file://c:\users\admini~1\appdata\local\temp\tmpmxl0kh\1.png](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205181600014.png)

浏览器截图



注：对于nginx，这个server_name可以是一个域名，也可以是多个域名，域名之间用空格隔开，其格式如下：
server_name  web.lin.com   web.lin.com    web.lin.com;
因此，客户端访问这3个域名时，访问的是同一个站点。

在server_name中还可以使用通配符“*”，其格式如下：
server_name  \*.lin.com   web.lin.\*  ;

还有一种就是在server_name中使用正则表达式，使用“^”表示以某字符开始，使用“$”表示以某字符结尾，其格式如下：
server_name  ^web.lin.com$;

#### 4.2.配置基于IP的虚拟主机

1.新增ip地址
[root@nginx1 conf]# ifconfig ens33:1 192.168.245.233 netmask 255.255.255.0 up
[root@nginx1 conf]# ifconfig  ens33:1
ens33:1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.245.233  netmask 255.255.255.0  broadcast 192.168.245.255
        ether 00:50:56:33:e1:1d  txqueuelen 1000  (Ethernet)
        
2.基于4.1步骤1,2，不需要再创建目录首页文件

3.修改配置文件

    server {
            listen       80;
            server_name  192.168.245.200;
            location / {
                root   /www/web;
                index  index.html index.htm;
            }
        }
    
    server {
        listen       80;
        server_name  192.168.245.233;
        location / {
            root   /www/blog;
            index  index.html index.htm;
        }
    }


4.检查语法并重启
[root@nginx1 conf]# nginx -t                    
nginx: the configuration file /usr/local/nginx/conf/nginx.conf syntax is ok
nginx: configuration file /usr/local/nginx/conf/nginx.conf test is successful
[root@nginx1 conf]# nginx -s reload 

5.浏览器测试：
截图

#### 4.3.配置基于端口的虚拟主机

1.基于4.1步骤1,2，不需要再创建目录首页文件

2.修改配置文件

    server {
            listen       8001;
            server_name  192.168.245.200;
            location / {
                root   /www/web;
                index  index.html index.htm;
            }
        }
     
    server {
        listen       8002;
        server_name  192.168.245.200;
        location / {
            root   /www/blog;
            index  index.html index.htm;
        }
    }


3.检查语法并重启
[root@nginx1 conf]# nginx -t                    
nginx: the configuration file /usr/local/nginx/conf/nginx.conf syntax is ok
nginx: configuration file /usr/local/nginx/conf/nginx.conf test is successful
[root@nginx1 conf]# nginx -s reload 

4.浏览器测试：
截图



​																				





### 实战1：拆分主配置文件

1.创建虚拟主机配置文件存放目录
[root@nginx1 ~]# cd /usr/local/nginx/conf
[root@nginx1 conf]# mkdir vhost

2.拆分主配置文件
[root@nginx1 conf]# cat >vhost/web.conf <<eof
server {
        listen       8001;
        server_name  192.168.245.160;
        location / {
            root   /www/web;
            index  index.html index.htm index.php;
        }
    }

[root@nginx1 conf]# cat >vhost/blog.conf <<eof
server {
        listen       8002;
        server_name  192.168.245.160;
        location / {
            root   /www/blog;
            index  index.html index.htm index.php;
        }
    }

3.修改主配置文件
最终内容如下：
user  nginx;
worker_processes  auto;
error_log  /var/log/nginx/nginx.log info;
pid        logs/nginx.pid;
worker_rlimit_nofile   65535;
events {
    worker_connections  65535;
    use epoll;
    multi_accept on;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;
include     vhost/*.conf;

}



测试：







### 实战2：优化nginx错误页面

实现  404和500 系列的 错误自定义页面
https://blog.csdn.net/weixin_47455987/article/details/106208426             #错误请求码统计;                         

在 虚拟主机  web 上，

1、事先编辑好两个错误页面  
/www/web/error/40x.html 
/www/web/error/50x.html 


2、在虚拟主机段中，添加以下红色部分配置

server {
        listen   8001;
        server_name  192.168.245.160;
           location / {
            root   /www/web;
            index  index.html;
        }
      **error_page  403   404           /40x.html;    **     
     **error_page  500 502 503 504  /50x.html;**
		 location = /40x.html {
            root   /www/web;
        }

}

3、模拟故障

 [root@nginx1 blog]# cd /www/web

  [root@nginx1 blog]# mv index.html index.html.bak

3、测试，访问  192.168.245.160:8001/index.html   不存在的页面，看是否能够触发自定义404。

4、 404 页面 产生的过程:
       2次 location 的查找 

​        客户端请求 index.html
​         |
​        查询一次 /index.html     被   location /  命中。读取 其中的  root 选项，去root选项指定的系统目录下，查找 index.html 
​         |
​        未找到，触发了 404 错误
​         |
​         检查404 错误有没有被另外定义，如果有，系统会重定向到自定义的 404 页面的路径，如果没有，直接在页面显示
​         |
​         发起第二次  location 查询  /40x.html 
​         |
​         也是被   上述第二个location =/40x.html  命中， 取其中的  root 选项，去root选项指定的系统目录下，查找  40x.html
​         |
​         找到，并显示 404 自定义页面。



### 实战3：定义location匹配规则

**3.1.了解url和uri** 统一资源标志符URI就是在某一规则下能把一个资源独一无二地标识出来。拿人做例子，假设这个世界上所有人的名字都不能重复，那么名字就是URI的一个实例，通过名字这个字符串就可以标识出唯一的一个人。现实当中名字当然是会重复的，所以身份证号才是URI，通过身份证号能让我们能且仅能确定一个人。那统一资源定位符URL是什么呢。

也拿人做例子然后跟HTTP的URL做类比，就有：动物住址协议://地球/中国/东北省/吉林市/宽城区/某大学/12号宿舍楼/205号寝/李金睿。 可以看到，这个字符串同样标识出了唯一的一个人，起到了URI的作用，所以URL是URI的子集。URL是可以以描述人的位置来唯一确定一个人的。但如果这一个宿舍有相同名字的两个人时，相要区分他们，我们也可以用：URI==身份证号：**[123456789](http://tel:123456789)**来标识他。所以不论是用定位的方式还是用编号的方式，我们都可以唯一确定一个人，都是URl的一种实现，而URL就是用定位的方式实现的URI。

回到Web上，假设所有的Html文档都有唯一的编号，记作html:xxxxx，xxxxx是一串数字，即html文档的身份证号码，这个能唯一标识一个html文档，那么这个号码就是一个URI。而URL则通过描述是哪个主机上哪个路径上的文件来唯一确定一个资源，也就是定位的方式来实现的URI。对于现在网址我更倾向于叫它URL，毕竟它提供了资源的位置信息**

```
例：
https://img13.360buyimg.com/devfe/jfs/t10852/94/3121149093/1595/4d1f4721/5ce3b828Ne1fdf8f6.png
这例的URL是https://img13.360buyimg.com/devfe/jfs/t10852/94/3121149093/1595/4d1f4721/5ce3b828Ne1fdf8f6.png
URI是5ce3b828Ne1fdf8f6.png
```

**3.2.语法规则：**

<font color='red'>location [ =|~|~\*|!~|!~*|^~ ]   /uri/  {     ... } </font>

**3.3.匹配规则：**
location 路径正则匹配：   

| 符号 | 说明                                                         |
| ---- | ------------------------------------------------------------ |
| ~    | 正则匹配，区分大小写                                         |
| ~*   | 正则匹配，不区分大小写                                       |
| ^~   | 普通字符匹配以什么开头，如果该选项匹配，则，只匹配该选项，不再向下匹配其他选项 |
| =    | 普通字符匹配，精确匹配                                       |
| @    | 定义一个命名的 location，用于内部定向，例如 error_page，try_files |
| !~   | 表示区分大小写不匹配的正则（取反）                           |
| !~*  | 表示不区分大小写不匹配的正则 （取反）                        |
| /    | 通用匹配，任何请求都会匹配到，代表除域名外的整个URI          |

**3.4.location 匹配流程：**

第一步：当输入URL时，会通过域名或IP端口去找虚拟主机（即定位是哪一个虚拟主机是目标主机），

第二步，通过uri 匹配对应的location规则，找到location里面的内容家目录在哪，

第三步，再拿uri路径去真实服务器的内容家目录下找路径一致的文件，如果路径没有指向文件，默认是要打开首页文件，但路径指向特定文件，就是要打开此文件



3.5.匹配优先级：


路径匹配，优先级：（跟 location 的书写顺序关系不大）

![image-20220922111432996](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202209221114073.png)

https://www.cnblogs.com/lemon-le/p/8215320.html



**<font color='red'>location = / 时，它指向的家目录为/usr/local/nginx/html</font>**

![file://c:\users\admini~1\appdata\local\temp\tmpxrdcq0\1.png](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205181600270.png)

3.6.举例
通过一个实例，简单说明一下匹配优先级：
location = / {
 \# 精确匹配 / ，主机名后面不能带任何字符串
 [ configuration A ]
}

location / {
 \# 因为所有的地址都以 / 开头，所以这条规则将匹配到所有请求
 \# 但是正则和最长字符串会优先匹配
 [ configuration B ]
}

location /documents/ {
 \# 匹配任何以 /documents/ 开头的地址，匹配符合以后，还要继续往下搜索
 \# 只有后面的正则表达式没有匹配到时，这一条才会采用这一条
 [ configuration C ]
}

location ~ /documents/Abc {
 \# 匹配任何以 /documents/ 开头的地址，匹配符合以后，还要继续往下搜索
 \# 只有后面的正则表达式没有匹配到时，这一条才会采用这一条
 [ configuration CC ]
}

location ^~ /images/ {
 \# 匹配任何以 /images/ 开头的地址，匹配符合以后，停止往下搜索正则，采用这一条。
 [ configuration D ]
}

location ~* \.(gif|jpg|jpeg)$ {
 \# 匹配所有以 gif,jpg或jpeg 结尾的请求
 \# 然而，所有请求 /images/ 下的图片会被 config D 处理，因为 ^~ 到达不了这一条正则
 [ configuration E ]
}

location /images/ {
 \# 字符匹配到 /images/，继续往下，会发现 ^~ 存在
 [ configuration F ]
}

location /images/abc {
 \# 最长字符匹配到 /images/abc，继续往下，会发现 ^~ 存在
 \# F与G的放置顺序是没有关系的
 [ configuration G ]
}

location ~ /images/abc/ {
 \# 只有去掉 config D 才有效：先最长匹配 config G 开头的地址，继续往下搜索，匹配到这一条正则，采用
  [ configuration H ]
}

location ~* /js/.*/\.js按照上面的location写法，以下的匹配示例成立：
\1. / -> config A：
精确完全匹配，即使/index.html也匹配不了

\2. /downloads/download.html -> config B：
匹配B以后，往下没有任何匹配，采用B

\3. /images/1.gif -> configuration D：
匹配到F，往下匹配到D，停止往下

\4. /images/abc/def -> config D：
最长匹配到G，往下匹配D，停止往下你可以看到 任何以/images/开头的都会匹配到D并停止，FG写在这里是没有任何意义的，H是永远轮不到的，这里只是为了说明匹配顺序

\5. /documents/document.html -> config C：
匹配到C，往下没有任何匹配，采用C

\6. /documents/1.jpg -> configuration E：
匹配到C，往下正则匹配到E

\7. /documents/Abc.jpg -> config CC：
最长匹配到C，往下正则顺序匹配到CC，不会往下到E



**3.7.练习Location 的匹配规则 ：**

 客户端请求： 请写出下列请求的   返回值，分别应该是 多少。

1、再次创建一台虚拟主机，  192.168.245.160:8003  

2、在 http 段中，添加以下语句。  

```
server {
        listen       8003;
        server_name  _         ;		#主机名“_” 代表localhost
        

		location = /image {
        return   401;
		}

		location ^~ /image/dir1 {
     	return   403;
		}

		location  ~  \.html$ {
    	return   404;
		}

		location   /image {
     	return   402;
		}

		location   / {
     	return   200;
		}	
}
```

3、 保存退出，重新载入 nginx 
4、 找一个 linux 主机作为客户端， 用 curl 工具 执行相关的测试任务，以此来分析Location 的执行规则

| 请求的URL                                                | 请求报文的 URI     |
| -------------------------------------------------------- | ------------------ |
| curl  -I   http://192.168.245.200:8003                   | /                  |
| curl  -I   http://192.168.245.200:8003/image             | /image             |
| curl  -I   http://192.168.245.200:8003/image/dir1/1.html | /image/dir1/1.html |
| curl  -I   http://192.168.245.200:8003/image/1.html      | /image/1.html      |
| curl  -I  http://192.168.245.200:8003/notice             | /notice            |
| curl  -I  http://192.168.245.200:8003/notice.html        | /notice.html       |
| curl  -I  http://192.168.245.200:8003/image/dir2         | /image/dir2        |







3.8.if 判断语句 : 

在    location  中使用  if  语句可以实现条件判断，其通常有一个return语句，且一般与有着last或break标记的rewrite规则一同使用。
但其也可以按需要使用在多种场景下，需要注意的是，不当的使用可能会导致不可预料的后果。

语法： if (condition) { … }

if 可以支持如下条件判断匹配符号

=                 不带正则的，字符串判断
~ 					正则匹配 (区分大小写)
~* 				正则匹配 (不区分大小写)
!~                正则不匹配 (区分大小写)
!~*		        正则不匹配  (不区分大小写)

-f 和!-f 			用来判断是否存在文件
-d 和!-d 		用来判断是否存在目录
-e 和!-e 		用来判断是否存在文件或目录
-x 和!-x 		用来判断文件是否可执行


location / {

if ($request_method == "PUT") {


		proxy_pass  http://upload.gz.com:8005;
	} 



if ($request_uri  ~  "\.(jpg|gif|jpeg|png)$") {


		proxy_pass   http://myservers;
		break;
	}
}

**3.9.Location 与  if  的优先级问题：**


 有如下配置： 

​        location = /1.html {
​                return 400;
​        }

​        if ($request_uri = "/1.html"){
​                return 401;
​        }   

请求时 curl  -I   http://192.168.245.160:8003/1.html
返回 的是  401  码、**<font color='red'>在相等 条件下 ，  if  优先级  高于  location 。</font>**







### 实战4、**Nginx访问控制**  

**基于用户： 账号密码访问
基于主机： 某些IP允许，某些不允许。**

```
server {
        listen   8004;
        server_name  192.168.245.160;
        location / {   
                root   /www/deny;
                index  index.html;
        }
         error_page  404 403             /error/40x.html;
         error_page  500 502 503 504  /error/50x.html;
        
        location  ~ \.txt$ {    ##  用location 表示文件级别的访问控制
                root   /www/deny;       
                deny all;       ##拒绝所有主机连接
        
        }
        
        location = /nginx_status {
        auth_basic  "nginx access test!";      ##基于账号密码访问控制         
        auth_basic_user_file  /usr/local/nginx/conf/password.txt;    #需要创建文件    
        ##自行在 /usr/local/nginx/conf/password.txt 下用“ htpasswd  -mc  密码文件名   用户名 ” 命令创建
        #htpasswd 此命令需要安装httpd-toolsp工具包
         ##或者直接使用  abc:$apr1$5AdkC7aa$KkcOoAeYPHuh15gTjscYB1  密码:123456
        stub_status on;      ##启用状态查询模块。
        
        allow 192.168.245.1;   ## 主机访问控制 (--without-http_access_module禁用此模块)
        deny all;
        }
}
```





### 实战5：状态监控模块

编译安装Nginx时需要加上参数。 

--with-http_stub_status_module

![](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205181601689.png)

显示信息	含义
Active connections	Nginx 当前活跃连接数
server	Nginx 处理接收握手总次数
accepts	Nginx 处理接收总连接数
handled requests	总共处理请求次数
Reading	Nginx读取数据
Writing	Nginx写的情况
Waiting	Nginx 开启keep-alive长连接情况下,既没有读也没有写,建立连接情况

Active connections: 22	当前活动的连接数
server accepts           handled            requests	
27                           27                         434
27		从启动到现在接受的 请求数量
27		从启动到现在成功处理的 请求数
434 	总共 收到的请求数(requests)

Reading: 2 Writing: 1 Waiting: 19
Reading: 2	    正在读取客户端 Header的信息数	 请求头
Writing: 1		返回给客户端的 Header的信息数	 响应头
Waiting: 19	长连接模式下，保持连接的 等待的请求数



重启服务器 ，计数器会清理。。。



### 实战6：配置expires缓存功能

```
server {
        listen 8005;
        server_name 192.168.245.160;

        location ~ ^/(images|javascript|js|css|flash|media|static)/ {           #以下为设置静态资源，nginx自己处理
                root /www/expires;
                expires 3m;  #过期3个月，静态文件不怎么更新，过期可以设大一点，如果频繁更新，则可以设置得小一点。
        }

        location ~ .*.(gif|jpg|jpeg|png|bmp|swf)$ {            #图片缓存时间设置    
                expires 30d;    #过期30天
        }

        location ~ .*.(js|css)?$ {             #JS和CSS缓存时间设置
                expires 30m;       #保留30分钟
        }

        location ~ .*.(htm|html|gif|jpg|jpeg|png|bmp|swf|ioc|rar|zip|txt|flv|mid|doc|ppt|pdf|xls|mp3|wma)$ {        #所有静态文件由nginx直接读取不经过tomcat或rest
                 expires 15d;
        }


        location ~ .*.(js|css)?$ { 
                expires 1h;     #保留1小时
        }

```



### 实战7：Nginx地址重写 rewrite


一、什么是  Rewrite  ====================================================

​	Rewrite对称URL Rewrite，即 URL 重写，就是把传入Web的请求重定向到其他URL的过程。

1. URL Rewrite最常见的应用是URL伪静态化，是将动态页面显示为静态页面方式的一种技术。比如
   http://www.123.com/news/index.php?id=123   使用URLRewrite 转换后可以显示为 
   http://www.123.com/news/123.html对于追求完美主义的网站设计师，就算是网页的地址也希望看起来尽量简洁明快。

理论上，搜索引擎更喜欢静态页面形式的网页，搜索引擎对静态页面的评分一般要高于动态页面。
所以，UrlRewrite可以让我们网站的网页更容易被搜索引擎所收录。

2. 从安全角度上讲，如果在URL中暴露太多的参数，无疑会造成一定量的信息泄漏，可能会被一些黑客
   利用，对你的系统造成一定的破坏，所以静态化的URL地址可以给我们带来更高的安全性。

3. 实现网站地址跳转，例如用户访问360buy.com，将其跳转到 jd.com。
   例如当用户访问tianyun.com的80端口时，将其跳转到443端口。





rewrite语法格式及参数语法说明如下:

rewrite    \<regex>  	\<replacement>  	[flag];
    关键字      正则            替代内容             flag标记

​    关键字：其中关键字不能改变
​    正则：对uri  进行正则规则匹配
​    替代内容：将正则匹配的内容替换成replacement
​    flag标记：rewrite支持的flag标记

flag标记说明：
last             #本条规则匹配完成后，继续向下匹配新的location URI规则
break          #本条规则匹配完成即终止，不再匹配后面的任何规则
redirect       #返回302临时重定向，浏览器地址会显示跳转后的URL地址
permanent  #返回301永久重定向，浏览器地址栏会显示跳转后的URL地址



rewrite参数的标签段位置：


server,location,if



例子：

rewrite     ^/(.\*)          http://www.czlun.com/$1                  permanent;
说明：                                        
rewrite为固定关键字，表示开始进行rewrite匹配规则
正则部分是 ^/(.*) ，这是一个正则表达式，匹配完整的域名和后面的路径地址
replacement部分是http://www.czlun.com/$1 	<font color='red'>	##$1，是取自正则部分()里的内容。匹配成功后跳转到的URL。</font>
flag部分 permanent表示永久301重定向标记，即跳转到新的 http://www.czlun.com/$1 地址上



regex 常用正则表达式说明

|           |                                                              |
| --------- | ------------------------------------------------------------ |
| 字符      | 描述                                                         |
| \         | 将后面接着的字符标记为一个特殊字符或一个原义字符或一个向后引用。如“\n”匹配一个换行符，而“\$”则匹配“$” |
| ^         | 匹配输入字符串的起始位置                                     |
| $         | 匹配输入字符串的结束位置                                     |
| *         | 匹配前面的字符零次或多次。如“ol*”能匹配“o”及“ol”、“oll”      |
| +         | 匹配前面的字符一次或多次。如“ol+”能匹配“ol”及“oll”、“oll”，但不能匹配“o” |
| ?         | 匹配前面的字符零次或一次，例如“do(es)?”能匹配“do”或者“does”，"?"等效于"{0,1}" |
| .         | 匹配除“\n”之外的任何单个字符，若要匹配包括“\n”在内的任意字符，请使用诸如“[.\n]”之类的模式。 |
| (pattern) | 匹配括号内pattern并可以在后面获取对应的匹配，常用$0...$9属性获取小括号中的匹配内容，要匹配圆括号字符需要\(Content\) |




二、Rewrite相关指令 =======================================================


Nginx Rewrite相关指令有  if、rewrite、set、return等。


在匹配过程中可以引用一些Nginx的全局变量 ( 参加附录  )


三、Rewrite flag =======================================================

redirect 和 permanent区别则是返回的不同方式的重定向，对于客户端来说一般状态下是没有区别的。

而对于搜索引擎，相对来说301的重定向更加友好，如果我们把一个地址采用301跳转方式跳转的话，搜索引擎会把老地址的相关信息带到新地址，同时在搜索引擎索引库中彻底废弃掉原先的老地址。

使用302重定向时，搜索引擎(特别是google)有时会查看跳转前后哪个网址更直观，然后决定显示哪个，如果它觉得跳转前的URL更好的话，也许地址栏不会更改，那么很有可能出现URL劫持的现象。在做URI重写时，有时会发现URI中含有相关参数，如果需要将这些参数保存下来，并且在重写过程中重新引用，可以用到 ( ) 和 $N 的方式来解决。

if ($User-Agent ~ "Android|IPhone") {
    rewrite .* http://192.168.245.200  permanent
    }



Nginx配置rewrite过程介绍

（1）创建rewrite语句

vi conf/vhost/rewrite.conf
\#vi编辑虚拟主机配置文件
文件内容
server {
        listen 80;
        server_name web.ljr.com;
        rewrite ^/(.*) http://blog.ljr.com/$1 permanent;
}

server {
        listen 80;
        server_name blog.ljr.com;
        location / {
                root /www/rewrite;
                index index.html index.htm;
        }

}

或者

server {
        listen 80;
        server_name web.ljr.com  blog.ljr.com;
if ( $host != 'blog.ljr.com'  ) {
                rewrite ^/(.*) http://blog.ljr.com/$1 permanent;
        }
        location / {
                root /www/rewrite;
                index index.html index.htm;
        }

}



（2）重启服务


确认无误便可重启，操作如下：
nginx -t
\#结果显示ok和success没问题便可重启
nginx -s reload



（3）查看跳转效果

打开浏览器访问web.ljr.com
页面打开后，URL地址栏的web.ljr.com变成blog.ljr.com说明URL重写成功。



示例： 用if 判断和  rewrite 模块，实现站点间访问跳转。

192.168.245.200:8083/gz   跳转至   192.168.245.200
192.168.245.200:8083/bbs   跳转至    192.168.245.200:8081

在test 的虚拟主机上，添加以下语句。

​	location = /gz {
​				 rewrite  .*   http://192.168.245.200 permanent;
​				}

   if ($request_uri = "/bbs") {
				 rewrite  .*   http://192.168.245.200:8081 permanent;
				}





四、Rewrite匹配参考示例 =======================================================
例1：  #################################

如果访问  [www.gz1.com/static/1.html](http://www.gz1.com/static/1.html)      重写 为    [www.gz1.com/image/2.html](http://www.gz1.com/image/2.html)


location / {

​               }

location   /static {
          rewrite     .*      /image/2.html     permanent;
      }






例2：： #################################

\#http://www.tianyun.com/2015/ccc/bbb/2.html ==> http://www.tianyun.com/2014/ccc/bbb/2.html


location  /2015 {

​     rewrite   ^/2015/(.*)$    /2014/$1   permanent;

}

location / {

​               } 



例3：：  #################################

\#http://www.360buy.com/aaa/1.html ====> http://jd.com

if ( $host ~* 360buy\.com ) {
	rewrite   .*	  http://jd.com   permanent;
}



if ( $request_uri  ~*  player\..*\.com ) {
	rewrite   .*	http://www.XXXX.com   permanent;
}




实现 访问  web.com/gz      跳转至   [www.gz.com](http://www.gz.com)

​    \### rewrite  使用在  server 段  和  Location 段的 作用范围不一样！

   server {
        listen       80;
        server_name  web.com;
        charset utf-8;
        access_log  /usr/local/nginx/logs/news.com.access.log  main;
        error_page  404    /404.html;
        error_page  500 502 503 504  /50x.html;

​        if ($request_uri ~ ^/gz$ ){
​        rewrite  .*   http://www.gz.com  permanent;
​        }

location  / {
            root   /data/web-data/news.com;
            index  index.html index.htm;
                location  /pass.html {
                auth_basic  "nginx access test!";
                auth_basic_user_file  /usr/local/nginx/conf/passwd;
                }
                location ~ ^/.*\.txt$ {
                allow 192.168.10.21;
                deny all;
                }
        }



例4： ：  #################################

\#http://www.360buy.com/ccc/1.html ==> http://jd.com/ccc/1.html

if ( $host  ~*  360buy\.com ) {

​	rewrite   .*	  http://jd.com$request_uri   permanent;
}




例6： ：  #################################

\#http://www.tianyun.com/login/tianyun.html     ==>  http://www.tianyun.com/reg/login.php?user=tianyun

location /login {
           rewrite ^/login/(.*)\.html$   /reg/login.php?user=$1   permanent;
        }

例7：
\#http://www.tianyun.com/uplook/11-22-33.html  ==>  http://www.tianyun.com/uplook/11/22/33.html

location /uplook {
            rewrite    ^/uplook/([0-9]+)-([0-9]+)-([0-9]+)\.html$     /uplook/$1/$2/$3.html     permanent;
        }



例8:

set  指令    是用于定义一个变量，并且赋值。应用于server,location,if 环境。      

nginx Rewrite


if ($host  ~*  "^(.*)\.tmaill\.hk$" ) {
     set  $user  $1;
      rewrite   .*    http://www.tianyun.com/$user   permanent;
   }

return 指令用于返回状态码给客户端，应用于server，location，if环境。


例9：如果访问的.sh结尾的文件则返回403操作拒绝错误

location ~* \.sh$ {
	return  403;
	#return 403  http://www.tianyun.com;
}


例10：80 ======> 443              http://www.baidu.com:80   ==⇒  https://www.baidu.com:443



server {
        listen      80;
        server_name  [www.tianyun.com](http://www.tianyun.com)  tianyun.com;
      return   301    https://www.tianyun.com$request_uri;
        }

server {

​        listen      443;
​        server_name  [www.tianyun.com;](http://www.tianyun.com;)
​        ssl  on;
​        \#ssl_certificate          /usr/local/nginx/conf/cert.pem;
​        \#ssl_certificate_key  /usr/local/nginx/conf/cert.key;
​    }



[root@yangs ~]# curl -I http://www.tianyun.com

HTTP/1.1 301 Moved Permanently
Server: nginx/1.10.1
Date: Tue, 26 Jul 2016 15:07:50 GMT
Content-Type: text/html
Content-Length: 185
Connection: keep-alive
Location: https://www.tianyun.com/



 last,break详解: =========================

例1：============================

server {
        ...
		location  /break/ {
             rewrite   .*   /test/break.html   break;
        }   

​        location  /last/ {
​             rewrite   .*   /test/last.html   last; 
​        }   

​        location  /test/  {
​             rewrite  .*   /test/test.html  break;
​        }   
}

[root@root html]# mkdir test
[root@root html]# echo 'break' > test/break.html
[root@root html]# echo 'last' > test/last.html
[root@root html]# echo 'test...' > test/test.html

​        /var/www/html/
​                            |
​                           test 目录
​                            |
​                      break.html    last.html    test.html 
​                      break             last            test


http://192.168.10.33/break/1.html          break 

http://192.168.10.33/last/1.html      test   



last标记在本条 rewrite规则执行完后，会对其所在的  server { … }  标签重新发起请求; 
break 标记则在本条规则匹配完成后，停止匹配，不再做后续的匹配。

另有些时候必须使用last，比如在使用alias指令时，而使用proxy_pass指令时则必须使用break。



​           

### 实战8：nginx限流操作

![file://c:\users\admini~1\appdata\local\temp\tmpqpe0zl\1.png](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203251153359.png)
指令名称：limit_conn_zone
（nginx 1.18以后用 limit_conn_zone 取代了 limit_conn）
语法：limit_conn_zone key zone=name:size;
默认：no
区域：http
功能：该指令定义一个 zone，该 zone 存储会话的状态。
例如：上面的例子中，$binary_remote_addr  是 获取客户端ip地址的变量，长度为 4 字节，会话信息的长度为 32 字节。

指令名称：limit_conn
语法：limit_conn zone number;
默认：no
区域：http、server、location
功能：该指令用于为一个会话设定最大并发连接数。如果并发请求超过这个限制，那么将返回预定错误（limit_conn_status ）

指令名称：limit_conn_status
语法：limit_conn_status code;
默认：limit_conn_status 503;
区域：http、server、location
功能：设置要返回的状态码以响应被拒绝的请求

指令名称：limit_conn_log_level
语法：limit_conn_log_level info | notice | warn | error
默认值：error
区域：http、server、location
功能：该指令用于设置日志的错误级别，当达到连接限制时，将会产生错误日志。

上面的配置示例中，没有显式配置 limit_conn_status 、limit_conn_log_level ，如果没有配置，则启用它们的默认值。

方法二：
![file://c:\users\admini~1\appdata\local\temp\tmpqpe0zl\2.png](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203251153369.png)
limit_req_zone指令定义了流量限制相关的参数，而limit_req指令在出现的上下文中启用流量限制(示例中，对于”/login/”的所有请求)。

limit_req_zone指令通常在HTTP块中定义，使其可在多个上下文中使用，它需要以下三个参数：

Key - 定义应用限制的请求特性。示例中的 Nginx 变量$binary_remote_addr，保存客户端IP地址的二进制形式。这意味着，我们可以将每个不同的IP地址限制到，通过第三个参数设置的请求速率。(使用该变量是因为比字符串形式的客户端IP地址$remote_addr，占用更少的空间)
Zone - 定义用于存储每个IP地址状态以及被限制请求URL访问频率的共享内存区域。保存在内存共享区域的信息，意味着可以在Nginx的worker进程之间共享。定义分为两个部分：通过zone=keyword标识区域的名字，以及冒号后面跟区域大小。16000个IP地址的状态信息，大约需要1MB，所以示例中区域可以存储160000个IP地址。
Rate - 定义最大请求速率。在示例中，速率不能超过每秒1个请求。Nginx实际上以毫秒的粒度来跟踪请求，所以速率限制相当于每1000毫秒1个请求。因为不允许”突发情况”(见下一章节)，这意味着在前一个请求1000毫秒内到达的请求将被拒绝。
limit_req_zone指令设置流量限制和共享内存区域的参数，但实际上并不限制请求速率。所以需要通过添加

limit_req指令，将流量限制应用在特定的location或者server块。在上面示例中，我们对/login/请求进行流量限制。

现在每个IP地址被限制为每秒只能请求1次/login/，更准确地说，在前一个请求的1000毫秒内不能请求该URL。



### 实战9：防盗链功能

server {
        listen      80;
        server_name   jpg.com;
        location ~* \.(gif|jpg|jpeg|png)$ {

配置可以合法的refer，在这里配置加入白名单的请求 refer 域名。

​            valid_referers none blocked server_names *.jpg.com;
​            if ($invalid_referer) { 
​            return 403; 
​            } 
​        }
​        location / {
​            root   /data/jpg;
​            index  index.html index.htm;
​        }
​    }



location /images/ {
valid_referers none blocked www.example.com example.com;
if ($invalid_referer) {
return 403;
}
}

valid_referers可以配置多种属性，一般会有以下几种

blocked：Referer 来源不为空，但是里面的值被代理或者防火墙删除了
none：代表请求的 Referer 为空，也就是直接访问，比如在浏览器中直接访问图片 jpg.com/123.jpg，直接访问时，Referer 会为空。这里我没有加上none，也就表示直接访问是非法的。
server_names：Referer 来源包含当前的 server_names，即所有 server 节点的 server_name 的值，如果配置了 server_names，那么这些值都会是合法来源。
字符串：直接定义合法的域名，比如我定义了 [www.jpg.com](http://www.jpg.com) 和 jpg.com，Referer是这两个域名的话就会是合法来源。
正则表达式：通过正则表达式来定义合法的请求来源。



### 实战10、nginx平滑升级

方案一、依托web高可用架构，将流量从需要升级的节点，
切换到其他节点执行，线下升级

方案二、
将 代理服务器的 版本 从 1.18 升级到 1.20，平滑/在线 升级

<font color='red'>ps:旧版本程序需要先用绝对路径启动（因为可以调用系统变量）</font>
1、备份原始程序 
2、复制原始 编译参数  nginx -V 
3、编译  新程序到   make   阶段 （注意不要执行 make install ）
4、拷贝新版程序到 当前 nginx 文件夹  替换到原始版本，需要加 -f 参数，否则报文件正忙

[root@nginx	~]# cp -f  ~/nginx-1.20.1/objs/nginx  /usr/local/nginx/

5、检查新版程序运行情况
[root@nginx1 ~/nginx-1.20.1]# nginx -v
nginx version: nginx/1.20.1

6、kill  -USR2   旧版本的主进程号， 同时启动一个新程序的 Master进程，此时 新旧版本同时存在

旧版本 nginx 的主进程将重命名它的 pid 文件为 .oldbin(例如：/usr/local/nginx/logs/nginx.pid.oldbin)，
然后执行新版本的 nginx 可执行程序，依次启动新的主进程和新的工作进程。 

[root@nginx1	~]# ps axu | grep  master
root       1036  0.0  0.4  45976  2088 ?        Ss   09:57   0:00 nginx: master process /usr/local/nginx/sbin/nginx

[root@nginx1	~]# kill -USR2 1036

[root@nginx1	~]# ps axu | grep  master
root       1036  0.0  0.4  45976  2088 ?        Ss   09:57   0:00 nginx: master process /usr/local/nginx/sbin/nginx
root       3778  0.0  0.7  45936  3408 ?        S    10:58   0:00 nginx: master process /usr/local/nginx/sbin/nginx

7、 kill -WINCH  旧版本的主进程号 
（让旧版本的 worker 进程完成已有请求，且不再接受新请求，新请求发给新进程）

此时，新、旧版本的 nginx 实例会同时运行，共同处理输入的请求。
要逐步停止旧版本的 nginx 实例，你必须发送 WINCH 信号给旧的主进程，然后，它的工作进程就将开始从容关闭： 

[root@nginx1 ~]# ps axu | grep  nginx
root       1036  0.0  0.4  45976  2088 ?        Ss   09:57   0:00 nginx: master process /usr/local/nginx/sbin/nginx
nginx      1071  0.0  5.8  72600 28444 ?        S    10:23   0:00 nginx: worker process
root       3778  0.0  0.7  45936  3408 ?        S    10:58   0:00 nginx: master process /usr/local/nginx/sbin/nginx
nginx      3779  0.0  5.9  73072 28596 ?        S    10:58   0:00 nginx: worker process

[root@nginx1 ~]# kill -WINCH 1036

<font color='red'>一段时间后，旧的工作进程(worker process)处理了所有已连接的请求后退出，仅由新的工作进程来处理输入的请求了</font>

出现如下状态后，再进行下一步

[root@nginx1 ~]# ps axu | grep  nginx
root       1036  0.0  0.4  45976  2088 ?        Ss   09:57   0:00 nginx: master process /usr/local/nginx/sbin/nginx
root       3778  0.0  0.7  45936  3408 ?        S    10:58   0:00 nginx: master process /usr/local/nginx/sbin/nginx
nginx      3779  0.0  5.9  73072 28596 ?        S    10:58   0:00 nginx: worker process



8、关闭旧的主进程   （旧版本的 worker进程要全部关闭后）
[root@nginx1 ~]# kill -QUIT 1036

[root@nginx1 ~]# ps axu | grep  nginx
root       3778  0.0  0.7  45936  3408 ?        S    10:58   0:00 nginx: master process /usr/local/nginx/sbin/nginx
nginx      3779  0.0  5.9  73072 28848 ?        S    10:58   0:00 nginx: worker process



总结：-----------------------------------------

1、备份老程序
2、重新编译 （旧参数+ 新的参数）
3、新程序  强制 覆盖 旧 nginx 程序  cp  -f 
4、kill  -USR2  老进程
5、Kill  -WINCH  老进程
6、Kill  -QUIT  老进程

● Nginx 的信号控制
•     TERM, INT 快速关闭
•     QUIT 从容关闭
•     HUP 平滑重启，重新加载配置文件
•     USR1 重新打开日志文件，在切割日志时用途较大
•     USR2 平滑升级可执行程序
•     WINCH 从容关闭工作进程





### 实战11：设置伪静态页面（需要搭建论坛演示）

   1、静态网页与动态网页的区别
https://blog.csdn.net/qq_40843865/article/details/100099921

例：
静态网页
http://web.com/123.txt

动态网页
[https://s.taobao.com/search?q=%E5%9D%90%E5%9E%AB&imgfile=&commend=all&ssid=s5-e&search_type=item&sourceId=tb.index&spm=a21bo.2017.201856-taobao-item.1&ie=utf8&initiative_id=tbindexz_20170306](https://s.taobao.com/search?q=坐垫&imgfile=&commend=all&ssid=s5-e&search_type=item&sourceId=tb.index&spm=a21bo.2017.201856-taobao-item.1&ie=utf8&initiative_id=tbindexz_20170306)

2、伪静态页面

nginx下discuz伪静态规则

```
location ~ / {
rewrite ^([^\.]*)/topic-(.+)\.html$ $1/portal.php?mod=topic&topic=$2 last;
rewrite ^([^\.]*)/article-([0-9]+)-([0-9]+)\.html$ $1/portal.php?mod=view&aid=$2&page=$3 last;
rewrite ^([^\.]*)/forum-(\w+)-([0-9]+)\.html$ $1/forum.php?mod=forumdisplay&fid=$2&page=$3 last;
rewrite ^([^\.]*)/thread-([0-9]+)-([0-9]+)-([0-9]+)\.html$ $1/forum.php?mod=viewthread&tid=$2&extra=page%3D$4&page=$3 last;
rewrite ^([^\.]*)/group-([0-9]+)-([0-9]+)\.html$ $1/forum.php?mod=group&fid=$2&page=$3 last;
rewrite ^([^\.]*)/space-(username|uid)-(.+)\.html$ $1/home.php?mod=space&$2=$3 last;
rewrite ^([^\.]*)/blog-([0-9]+)-([0-9]+)\.html$ $1/home.php?mod=space&uid=$2&do=blog&id=$3 last;
rewrite ^([^\.]*)/(fid|tid)-([0-9]+)\.html$ $1/archiver/index.php?action=$2&value=$3 last;
rewrite ^([^\.]*)/([a-z]+[a-z0-9_]*)-([a-z0-9_\-]+)\.html$ $1/plugin.php?id=$2:$3 last;
index  index.html index.htm index.php;
}
```



![file://c:\users\admini~1\appdata\local\temp\tmpqrfsnn\1.png](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205191531625.png)



转化前：

![image-20220519153127515](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205191531598.png)

转化后的伪静态页面

![image-20220519153407678](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205191534749.png)





### 5、配置nginx支持PHP程序

对于apache来说，PHP是没有独立的进程的，它只是apache中一个模块而已，所以只需要在配置文件中开启并配置对该模块的支持即可
但对于nginx来说，php是有独立的进程的，它依靠fastcgi进程来运行，因些支持PHP的配置与前面的apache的配置有所不同

lnmp搭建
编译安装nginx
略
编译安装或二进制安装mysql
略
编译安装PHP

php官方网站：https://www.php.net/

1.安装epel源。
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo



yum install autoconf gcc libxml2-devel openssl-devel curl-devel libjpeg-devel libpng-devel libXpm-devel freetype-devel libmcrypt-devel make ImageMagick-devel libssh2-devel gcc-c++ cyrus-sasl-devel  sqlite-devel  oniguruma oniguruma-devel -y 

下载php安装包
![file://c:\users\admini~1\appdata\local\temp\tmpdbvqnw\1.png](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203231707275.png)

wget https://www.php.net/distributions/php-7.4.28.tar.gz

编译安装php源码包：

./configure \
--prefix=/usr/local/php \
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
输出Thank you for using php 没有报错即为正常；
make && make install

配置php所需要配置文件
cp /opt/php-7.4.28/sapi/fpm/init.d.php-fpm  /usr/local/php/php-fpm              #php主程序
chmod a+x /usr/local/php/php-fpm
cp /opt/php-7.4.28/php.ini-development  /usr/local/php/etc/php.ini                 #php主配置文件
cp /usr/local/php/etc/php-fpm.conf.default  /usr/local/php/etc/php-fpm.conf             #php-fpm 进程服务的配置文件
cp /usr/local/php/etc/php-fpm.d/www.conf.default   /usr/local/php/etc/php-fpm.d/www.conf       # php-fpm 进程服务的扩展配置文件

注：php-fpm启动后会先读php.ini，然后再读相应的conf子配置文件，conf配置可以覆盖php.ini的配置。启动php-fpm之后，会创建一个master进程，监听9000端口（可配置），master进程又会根据fpm.conf/www.conf去创建若干子进程，子进程用于处理实际的业务。

添加用户
useradd www -s /sbin/nologin

启动php服务：

```
[root@nginx1 opt]# ln -s /usr/local/php/php-fpm /usr/sbin/php-fpm
[root@nginx1 opt]# /usr/local/php/php-fpm start
出现done字样，表示php启动成功。
```





添加nginx与php通信配置：

```
server {
        listen 80;
        server_name 192.168.245.160;
        charset utf-8;
        root /www/php;
        index index.html index.htm index.php;	#在location外填写首页，只需要识别server_name+端口
        location ~* \.php$ {
                fastcgi_pass 127.0.0.1:9000;
                #fastcgi_pass unix:/dev/shm/php-cgi.sock;            #https://www.cnblogs.com/brady-wang/p/5962561.html
                #index index.html index.htm index.php;
                fastcgi_index index.php;
                include fastcgi.conf;
#FastCGI相关参数是为了改善网站的性能：减少资源占用，提高访问速度，其它相关参数配置请参照官方文档说明
                fastcgi_connect_timeout 300;                连接fastcgi超时时间，单位为秒
                fastcgi_send_timeout 300;                    请求fastcgi超时时间，单位为秒
                fastcgi_read_timeout 300;                     接收fastcgi的应答超时时间，单位为秒
                fastcgi_buffers 4 64k; 			 设定用来读取从FastCGI服务器端收到的响应信息的缓冲区大小和缓冲区数量
                fastcgi_buffer_size 64k;                      指定本地所需缓冲区大小来接收fastcgi的应答请求
                fastcgi_busy_buffers_size 128k;             繁忙时的缓冲区大小，默认值是 fastcgi_buffer_size 大小的2倍
                fastcgi_temp_file_write_size 128k;          写入缓存文件使用多大的数据块

       }
    }
```

验证

[root@nginx1 objs]# cd /www/php/

[root@nginx1 php]# vim index.php

<?php   
phpinfo();
?>

用浏览器打开：http://192.168.245.160:8006/，出现如下图所示，则证明nginx与PHP能正常构建使用

![image-20220519141507804](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205191415901.png)





搭建discuz论坛

![image-20220519143733929](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205191437032.png)

搭建wordpress个人博客 
![file://c:\users\admini~1\appdata\local\temp\tmpdbvqnw\2.png](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203231707164.png)

搭建禅道 
![file://c:\users\admini~1\appdata\local\temp\tmpdbvqnw\3.png](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203231707322.png)

搭建ecshop
https://www.zuimoban.com/ecshop/



​           

### 6、Nginx反向代理 ：

Nginx通过 proxy 模块实现反向代理功能。

针对于后端服务器来说

在作为web正向代理服务器时，nginx作为服务端
在作为web反向代理服务器时，nginx作为客户端，
并能够根据URI、客户端参数或其它的处理逻辑，将 用户请求调度至上游服务器上(upstream server)。
nginx在实现反向代理功能时的最重要指令为 proxy_pass，它能够将location定义的某URI代理至指定的上游服务器(组)上。  

#### 6.1、反向代理配置：

proxy  模块的指令（部分）：

proxy模块的可用配置指令非常多，它们分别用于定义proxy模块工作时的诸多属性，如连接超时时长、代理时使用http协议版本等。
下面对常用的指令做一个简单说明。

proxy_pass：            指定将请求代理至upstream server的URL路径；
proxy_set_header Host  $host;
proxy_set_header        X-Real-IP $remote_addr;      
\#proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_connect_timeout：  表示与后端服务器  创建 连接（握手）的超时时间，即发起握手等候响应的超时时间
                                        该指令设置与upstream server的连接超时时间，有必要记住，这个超时不能超过75秒。默认60s。
proxy_hide_header：        设定发送给客户端的报文中需要隐藏的首部；

proxy_set_header：     发送至  后端   server 的  报文的某首部进行重写；
proxy_redirect：               重写location并刷新从upstream server收到的报文的首部；
proxy_intercept_errors  on;    打开该选项，可以拦截来自后端服务器的  大于 3XX  的 错误信息，并
                                        且使用自己定义的  error  page  来显示这些错误页面 。
\#client_max_body_size 10m;              #允许客户端请求的最大单文件字节数
\#client_body_buffer_size 128;           #缓冲区代理缓冲用户端请求的最大字节数       
\#proxy_connect_timeout 90;          #nginx跟后端服务器连接超时时间(代理连接超时)        
\#proxy_send_timeout 90;             #后端服务器数据回传时间(代理发送超时)       
\#proxy_read_timeout 90;                 #连接成功后，后端服务器响应时间(代理接收超时)       
\#proxy_buffer_size 4k;                  #设置代理服务器（nginx）保存用户头信息的缓冲区大小        
\#proxy_buffers 4 32k;                   #proxy_buffers缓冲区，网页平均在32k以下的设置       
\#proxy_busy_buffers_size 64k;        #高负荷下缓冲大小（proxy_buffers*2）        
\#proxy_temp_file_write_size 64k;        #设定缓存文件夹大小，大于这个值，将从upstream服务器传



#### 6.2、反向代理与负载均衡模版：

```
upstream test {
server 192.168.245.161:8001;
server 192.168.245.162:8002;
}


server{
        listen 8007;
        server_name 192.168.245.160;
location  / {
        proxy_pass http://test;
        #proxy_set_header Host  $host;
        #proxy_set_header X-Real-IP   $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_redirect off;
        proxy_connect_timeout 30;
        proxy_send_timeout 15;
        proxy_read_timeout 15;
           }
}

```



以下情况需要注意！######################

#### 6.3、通用匹配代理

当用户指定访问特定文件时，可以通过通用匹配，反向代理指定的uri

location  /a1 {
        proxy_pass http://www.gz.com:8080/b1;

上面的例子中，用户访问的uri为/a1，转发后端的uri请求为/b1

<font color='red'>注，如果配置文件没写明，转发后端时会默认使用用户访问的uri</font>

例：

```
upstream test {
server 192.168.245.161:8001;
server 192.168.245.162:8002;
}

server{
        listen 8007;
        server_name 192.168.245.160;
location  / {
        proxy_pass http://test; 
           }
}
当用户输入http://192.168.245.160:8007/a1/b1/c1/123.jpg
转发后端收到的URL为：http://192.168.245.161:8001/a1/b1/c1/123.jpg
			  或：
				  http://192.168.245.162:8002/a1/b1/c1/123.jpg
```



#### 6.4、正则表达式  匹配代理  

如果location的URI是通过  模式匹配   定义的，其URI将直接被传递至上游服务器，而不能为其指定转换的另一个URI。
例如下面示例中的/bbs 将被代理为http://www.gz.com/bbs

​	location  ~  ^/bbs {
​		proxy_pass   http://www.gz.com;
​	}

 1、 **<font color='red'>location 后接URI使用  正则表达式  匹配的话， 则   proxy_pass  转发的地址中，不能填写 URI，不能修改 原</font><font color='red'>始请求的 URI地址</font>**
 2、**<font color='red'> location 部分没有使用正则，则 在转发至后端服务器时，可以 重写 URI  地址</font>**

错误示例： ================================

location  ~  ^/sport$  {
        proxy_pass http://192.168.10.61/car;
        }

报以下错误。

[root@nginx1 ~]# /usr/local/nginx/sbin/nginx -s reload
nginx: [emerg] "proxy_pass" cannot have URI part in location given by regular expression, or inside named location, 
or inside "if" statement, or inside "limit_except" block in /usr/local/nginx/conf/nginx.conf:43

#### 6.5、地址重写代理

如果在loation中使用的URL重定向，那么nginx将优先使用 重定向后的URI处理请求，而不再考虑 proxy_pass 字段 定义的 URI。

[root@server1 ~]# curl  -I http://www.news.com/sport          URI=/sport

location  /sport {
        rewrite  .*  /baby/index.html    break;
        proxy_pass http://192.168.10.61/car;	
               }

上面的例子中，转发 后端的  请求为 
         /baby/index.html  
         而不是 
         /car

 



#### 6.6、举例

就因为在配置时，少些了一个字符“/”，就造成访问不通报错，因而接到投诉。那么是怎么引起的呢？原因就是：Nginx在配置proxy_pass代理转接时，少些“/”字符造成的。

有同学就有疑问，加不加“/”,区别真的那么大吗？我们带着这个疑问，来探究下这个问题。

location目录匹配详解

nginx每个location都是一个匹配目录，nginx的策略是：访问请求来时，会对访问地址进行解析，从上到下逐个匹配，匹配上就执行对应location大括号中的策略，并根据策略对请求作出相应。

以访问地址：http://www.wandouduoduo.com/wddd/index.html为例，nginx配置如下：

```
location /wddd/  {                
    proxy_connect_timeout 18000; ##修改成半个小时                    
    proxy_send_timeout 18000;                
    proxy_read_timeout 18000;                
    proxy_pass http://127.0.0.1:8080;        
}
```

那访问时就会匹配这个location,从而把请求代理转发到本机的8080Tomcat服务中，Tomcat相应后，信息原路返回。总结：location如果没有“/”时，请求就可以模糊匹配以字符串开头的所有字符串，而有“/”时，只能精确匹配字符本身。

**下面举个例子说明：**

配置location /wandou可以匹配/wandoudouduo请求，也可以匹配/wandou*/duoduo等等，只要以wandou开头的目录都可以匹配到。而location /wandou/必须精确匹配/wandou/这个目录的请求,不能匹配/wandouduoduo/或/wandou*/duoduo等请求。

**proxy_pass有无“/”的四种区别探究**

访问地址都是以：http://www.wandouduoduo.com/wddd/index.html 为例。请求都匹配目录/wddd/

第一种：加"/"

```
location  /wddd/ {
    proxy_pass  http://127.0.0.1:8080/;
}
```

测试结果，请求被代理跳转到：http://127.0.0.1:8080/index.html

第二种: 不加"/"

```
location  /wddd/ {        
    proxy_pass http://127.0.0.1:8080;
}
```

测试结果，请求被代理跳转到：http://127.0.0.1:8080/wddd/index.html

第三种: 增加目录加"/"

```
location  /wddd/ {        
    proxy_pass http://127.0.0.1:8080/sun/;
}
```

测试结果，请求被代理跳转到：http://127.0.0.1:8080/sun/index.html

第四种：增加目录不加"/"

```
location  /wddd/ {
    proxy_pass http://127.0.0.1:8080/sun;
}
```

测试结果，请求被代理跳转到：http://127.0.0.1:8080/sun/index.html

**总结**

location目录后加"/",只能匹配目录，不加“/”不仅可以匹配目录还对目录进行模糊匹配。而proxy_pass无论加不加“/”,代理跳转地址都直接拼接。为了加深大家印象可以用下面的配置实验测试下：

```
server {   
  listen       80;   
  server_name  localhost;   # http://localhost/wddd01/xxx -> http://localhost:8080/wddd01/xxx

  location /wddd01/ {           
    proxy_pass http://localhost:8080;   
  }

  # http://localhost/wddd02/xxx -> http://localhost:8080/xxx   
  location /wddd02/ {           
    proxy_pass http://localhost:8080/;    
  }

  # http://localhost/wddd03/xxx -> http://localhost:8080/wddd03*/xxx   
  location /wddd03 {           
    proxy_pass http://localhost:8080;   
  }

  # http://localhost/wddd04/xxx -> http://localhost:8080//xxx，请注意这里的双斜线，好好分析一下。
  location /wddd04 {           
    proxy_pass http://localhost:8080/;   
  }

  # http://localhost/wddd05/xxx -> http://localhost:8080/hahaxxx，请注意这里的haha和xxx之间没有斜杠，分析一下原因。
  location /wddd05/ {           
    proxy_pass http://localhost:8080/haha;    
  }

  # http://localhost/api6/xxx -> http://localhost:8080/haha/xxx   
  location /wddd06/ {           
    proxy_pass http://localhost:8080/haha/;   
  }

  # http://localhost/wddd07/xxx -> http://localhost:8080/haha/xxx   
  location /wddd07 {           
    proxy_pass http://localhost:8080/haha;   
  } 
        
  # http://localhost/wddd08/xxx -> http://localhost:8080/haha//xxx，请注意这里的双斜杠。
  location /wddd08 {           
    proxy_pass http://localhost:8080/haha/;   
  }
}
```













​       



### 7、负载均衡分类

负载均衡通常分为硬件与软件两种
硬件：F5、7层或4层网络代理设备
软件：nignx、HAproxy、lvs等软件

#### nginx实现负载均衡的方式(面试极大机率问)（负载均衡算法）

1.轮询（默认）
每个请求按时间顺序依次分配到不同的后端服务器，后端服务器宕机时，能被自动剔除，且请求响应情况不会受到任何影响
2.weight
指定轮询概率，weight和访问比率成正比，用于后端服务器性能不均的情况。权重越高，被访问的概率就越大，常用于服务上线发布场景
3.ip_hash
每个请求按访问IP生成的hash结果分配，会让相同客户端IP请求相同的服务器
4.fair
动态根据后端服务器处理请求的响应时间来进行负载分配，响应时间短的优先分配，响应时间长的服务器分配的请求会减少。
但是nginx服务默认不支持该算法，如需要使用，要安装upstream_fair模块
5.url_hash
根据访问的URL计算出的hash结果来分配请求，每个请求的URL会指向后端某个固定的服务器，通常用在nginx作为静态资源服务器的场景，可以提高缓存效率
但是nginx服务默认不支持该算法，如需要使用，要安装hash软件包



1、热备：如果你有2台服务器，当一台服务器发生事故时，才启用第二台服务器给提供服务。服务器处理请求的顺序：AAAAAA突然A挂啦，BBBBBBBBBBBBBB.....
upstream mysvr { 
    server 127.0.0.1:7878;  
    server 192.168.10.121:3333 backup;  #热备     
}
2、轮询：nginx默认就是轮询其权重都默认为1，服务器处理请求的顺序：ABABABABAB....
upstream mysvr { 
    server 127.0.0.1:7878;
    server 192.168.10.121:3333;       
}
3、加权轮询：跟据配置的权重的大小而分发给不同服务器不同数量的请求。如果不设置，则默认为1。下面服务器的请求顺序为：ABBABBABB
upstream mysvr { 
    server 127.0.0.1:7878 weight=1;
    server 192.168.10.121:3333 weight=2;
}
4、ip_hash:nginx会让相同的客户端ip请求相同的服务器。
upstream mysvr { 
    server 127.0.0.1:7878; 
    server 192.168.10.121:3333;
    ip_hash;
}

关于nginx负载均衡配置的几个状态参数讲解。（面试可能问）
• down，表示当前的server暂时不参与负载均衡。

• backup，预留的备份机器。当其他所有的非backup机器出现故障或者忙的时候，才会请求backup机器，因此这台机器的压力最轻。

• max_fails，允许请求失败的次数，默认为1。当超过最大次数时，返回proxy_next_upstream 模块定义的错误。

• fail_timeout，在经历了max_fails次失败后，暂停服务的时间。max_fails可以和fail_timeout一起使用。

upstream mysvr { 
    server 127.0.0.1:7878 weight=2 max_fails=2 fail_timeout=2;
    server 192.168.10.121:3333 weight=1 max_fails=2 fail_timeout=1;    
}



设定负载均衡
upstream tomcat1 {
    #upstream的负载均衡，weight是权重，可以根据机器配置定义权重。weigth参数表示权值，权值越高被分配到的几率越大。
    server 127.0.0.1:8080 weight=1;
    server 192.168.1.116:8081 weight=1;
}

\#设定负载均衡的服务器列表,可以配置多个负载均衡的服务器列表
upstream  tomcat2 {
    #upstream的负载均衡，weight是权重，可以根据机器配置定义权重。weigth参数表示权值，权值越高被分配到的几率越大。     	      server 127.0.0.1:8080 weight=1;
    server 192.168.1.11:8081 weight=1;
}

}
    


​     
​    



