### 1、Nginx四层负载均衡概述


nginx4层需要1.9版本以上

什么是四层负载均衡
<font color='red'>四层负载均衡是基于传输层协议包来封装的（如：TCP/IP）</font>，那我们前面使用到的七层是指的应用层，他的组装在四层的基础之上，无论四层还是七层都是指的OSI网络模型。

四层负载均衡应用场景
1、四层+七层来做负载均衡，四层可以保证七层的负载均衡的高可用性；如：nginx就无法保证自己的服务高可用，需要依赖LVS或者keepalive。
2、如：tcp协议的负载均衡，有些请求是TCP协议的（mysql、ssh），或者说这些请求只需要使用四层进行端口的转发就可以了，所以使用四层负载均衡。

四层负载均衡总结
1、四层负载均衡仅能转发TCP/IP协议、UDP协议、通常用来转发端口，如：tcp/22、udp/53；
2、四层负载均衡可以用来解决七层负载均衡端口限制问题；（七层负载均衡最大使用65535个端口号）
3、四层负载均衡可以解决七层负载均衡高可用问题；（多台后端七层负载均衡能同时的使用）
4、四层的转发效率比七层的高得多，但仅支持tcp/ip协议，不支持http和https协议；



### 2、配置4层nginx

修改配置文件

```
stream {
log_format  proxy       '$remote_addr $remote_port - [$time_local] $status $protocol '                   
                                    '"$upstream_addr" "$upstream_bytes_sent" "$upstream_connect_time"' ;     
    access_log  /var/log/nginx/proxy.log   proxy;
    #四层负载均衡是没有access的日志的，因为在nginx.conf的配置中，access的日志格式是配置在http下的，而四层复杂均衡配置实在http以外的；
   upstream tomcat {
        server 192.168.245.200:8080;
        server 192.168.245.200:8081;
        server 192.168.245.200:8082;
}
 upstream ssh {             
        server 10.0.0.7:22;     
        }     
   upstream mysql {             
        server 10.0.0.51:3306;     
        }
server {
        listen 80;
        proxy_pass  tomcat;
        proxy_connect_timeout 30;
        proxy_timeout 3s;
}
server {
        listen 444; 	
		#server_name 192.168.245.160;     	#此选项是不允许出现在4层代理的配置文件里  
        proxy_pass ssh;
        proxy_connect_timeout 30;
        proxy_timeout 3s;
}
server {
        listen 555;
        proxy_pass mysql;
        proxy_connect_timeout 30;
        proxy_timeout 3s;
}
}


```



创建存放四层负载均衡配置文件的目录

mkdir /usr/local/nginx/conf/4proxy	

vim /usr/local/nginx/conf/nginx.conf
include 4proxy/\*.conf;           #也可以直接把4层配置文件内容写在http模块之外，4层的配置文件与7层的配置文件不能在同一个目录或者同一个配置文件下
http {
    ............
\# vhost/*.conf;   #如果http模块里面有虚拟主机4层配置文件，可以注释，也可以改变7层配置文件存放的路径

}






### 3、haproxy

官网：https://www.haproxy.com/
下载界面：https://www.haproxy.org/

1.下载安装包
wget https://www.haproxy.org/download/2.5/src/haproxy-2.5.9.tar.gz

2.安装依赖包
yum -y install pcre-devel bzip2-devel  gcc  pcre-static  openssl openssl-devel systemd-devel.x86_64

编译安装
make TARGET=linux-glibc USE_OPENSSL=1 USE_SYSTEMD=1 USE_PCRE=1 USE_ZLIB=1  
make PREFIX=/usr/local/haproxy  install 
注意：
USE_OPENSSL=1       #开启https
USE_SYSTEMD=1       #指定为systemd模式
PREFIX=/usr/local/haproxy   #可指定安装目录



3.配置文件haproxy.cfg（没有配置文件，需要从模版文件里修改）
\# cp -rp /opt/haproxy-2.5.9/examples/option-http_proxy.cfg   /usr/local/haproxy/conf/

4.手动配置

```
global                                                      #全局配置模块
    log         127.0.0.1 local2
    #chroot      /var/lib/haproxy
    pidfile     /usr/local/haproxy/haproxy.pid
    maxconn     20000
    daemon
    stats socket /usr/local/haproxy/stats
    spread-checks 2
defaults                                                #默认配置模块
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    timeout http-request    2s
    timeout queue           3s
    timeout connect         1s
    timeout client          10s
    timeout server          2s
    timeout http-keep-alive 10s
    timeout check           2s
    maxconn                 18000 

frontend http-in                              #前端配置
    bind             *:9080					#默认端口为1080
    mode             http
    log              global
    capture request  header Host len 20
    capture request  header Referer len 60
    acl url_static   path_beg  -i /static /images /stylesheets
    acl url_static   path_end  -i .jpg .jpeg .gif .png .ico .bmp .css .js
    acl url_static   path_end  -i .html .htm .shtml .shtm .pdf .mp3 .mp4 .rm .rmvb .txt
    acl url_static   path_end  -i .zip .rar .gz .tgz .bz2 .tgz
    use_backend      static_group   if url_static		#如果符合url_static条件的，使用后端配置static_group
    default_backend  dynamic_group

backend static_group                    #后端静态配置
    balance            roundrobin
    option             http-keep-alive
    http-reuse         safe
    option httpchk     GET /index.html			#相当于nginx的location
    http-check expect  status 200
    server staticsrv1  192.168.245.200:80 check rise 1 maxconn 5000
    server staticsrv2  192.168.245.201:80 check rise 1 maxconn 5000

backend dynamic_group               #后端动态配置
    cookie appsrv insert nocache
    balance roundrobin
    option http-server-close
    option httpchk     GET /index.jsp
    http-check expect  status 200
    server appsrv1 192.168.245.200:8080  check rise 1 maxconn 3000 cookie appsrv1

listen report_stats                         #监听配置
        bind *:8081
        stats enable
        stats hide-version
        stats uri    /stats
        stats realm  "pls enter your name"
        stats auth   admin:admin
        stats admin  if TRUE
```



启动方法：
/usr/local/haproxy/sbin/haproxy -f /usr/local/haproxy/conf/haproxy.cfg          #启动程序 -f 配置文件

重启：
pkill  haproxy  &&  /usr/local/haproxy/sbin/haproxy -f /usr/local/haproxy/conf/haproxy.cfg

7.设置开机自启
vim /usr/lib/systemd/system/haproxy.service
[Unit]
Description=HAProxy Load Balancer
After=syslog.target network.target

[Service]
ExecStartPre=/usr/local/haproxy/sbin/haproxy  -f  /usr/local/haproxy/conf/haproxy.cfg   
ExecStart=/usr/local/sbin/haproxy -Ws -f /etc/haproxy/haproxy.cfg  -p /run/haproxy.pid
ExecReload=/bin/kill -USR2 $MAINPID

[Install]
WantedBy=multi-user.target

8.浏览器测试
http://192.168.245.200:9080/index.html



9.HAProxy调度算法：
HAProxy在balance中定义
1.roundrobin 根据服务器权重轮询的算法，可以自定义权重，它支持慢启动，并能在运行时修改权重，所以是一种动态算法。最多支持4095台后端主机。
2.static-rr 与roundrobin类似，static-rr也是一种轮询算法，但它是静态的，对后端主机数量无限制。
3.leastconn 最小连接数算法，一种可以根据后端主机连接数情况进行调度的动态算法，支持慢启动和运行时调整，<font color='red'>可将新的请求调度至连接数较少的后端主机</font>。与LVS中lc算法类似。
4.first 根据服务器标识顺序选择服务器，当服务器承载的连接数达到maxconn的值后便将新请求调度至下一台服务器。此算法只在一些特殊场景下使用。
5.source 对请求的源IP地址进行hash处理，根据hash运算处理结果调度至后端服务器。可使固定IP的请求始终调度至统一服务器。
6.uri 根据请求的uri进行hash处理并调度之后端主机。
7.url_param 将URL的参数进行判断并进行hash计算，参数可以自定义，任何的URL参数都可以。
8.hdr <name>根据请求中的HTTP报文首部的值进行hash计算并调度。name可以是GET、USERAGENT等首部名。
HAProxy可以选择普通hash算法也可以选择一致性hash算法。可用参数hash_type配



10.haproxy四层代理写法
直接增加listen段。注意关闭http相关
listen mysql-port
    bind 0.0.0.0:3600
    mode tcp
    balance leastconn
    server mysql01 192.168.245.175:3306 check rise 1
    server mysql02 192.168.245.176:3306 check rise 1



### 4、HAProxy的cookie配置基础





### 1.什么是cookie？


由于HTTP是一种无状态的协议，服务器单从网络连接上无从知道客户身份。怎么办呢？就给客户端们颁发一个通行证吧，每人一个，无论谁访问都必须携带自己通行证。这样服务器就能从通行证上确认客户身份了。这就是Cookie的工作原理。Cookie实际上是一小段的文本信息。客户端请求服务器，如果服务器需要记录该用户状态，就使用response向客户端浏览器颁发一个Cookie。客户端浏览器会把Cookie保存起来。当浏览器再请求该网站时，浏览器把请求的网址连同该Cookie一同提交给服务器。服务器检查该Cookie，以此来辨认用户状态。服务器还可以根据需要修改Cookie的内容。



### 2.为什么需要cookie？


举一个例子：客户端第一次访问某购物网站时，集群中负载均衡会根据设置好的算法分配至后端某服务器A，若负载均衡开启了cookie机制，则负载均衡会给客户端一个身份标识，以后只要是该客户访问网站，都会将请求发送至后端服务器A。这就绑定了用户和后端服务器。与ip_hash不同的是，这种方式的绑定更精细，设置更灵活，就算用户换IP也不会影响绑定。



### 3.cookie简单配置


基本格式：cookie <name> [ rewrite | insert | prefix ] [ indirect ] [ nocache ] [ postonly ] [ preserve ] [ httponly ] [ secure ] [ domain <domain> ]* [ maxidle <idle> ] [ maxlife <life> ]
<name>：is the name of the cookie which will be monitored, modified or inserted in order to bring persistence.
在上例配置中添加cookie配置，使客户端绑定至后端某台主机
frontend myweb
        bind *:80
        default_backend app
        stats enable #开启HAProxy的状态页功能
        stats auth admin:asd12345 #设置状态页登入密码

backend app
        balance leastconn
        cookie server insert nocache #在nocache中插入名为server的cookie键
        server app1 192.168.29.102:80 check cookie appsvr1 #server app1的键值为appsvr1
        server app2 192.168.29.103:80 check cookie appsvr2 #server app1的键值为appsvr2





### 5、haproxy配置文件详解

#### 全局配置 Global :

“global”配置中的参数为进程级别的参数，且通常与其运行的OS相关。

 \* 进程管理及安全相关的参数
   \- chroot <jail dir>：修改haproxy的工作目录至指定的目录并在放弃权限之前执行chroot()操作，可以提升haproxy的安全级别，
                                不过需要注意的是要确保指定的目录为空目录且任何用户均不能有写权限；
   \- **daemon**：让haproxy以守护进程的方式工作于后台，其等同于“-D”选项的功能，当然，也可以在命令行中以“-db”选项将其禁用；
   \- gid <number>：以指定的GID运行haproxy，建议使用专用于运行haproxy的GID，以免因权限问题带来风险；
   \- group <group name>：同gid，不过指定的组名；
   \- **log**  <address> <facility> [max level [min level]]：定义全局的syslog服务器，最多可以定义两个；
   \- log-send-hostname [<string>]：在syslog信息的首部添加当前主机名，可以为“string”指定的名称，也可以缺省使用当前主机名；
   \- nbproc <number>：指定启动的haproxy进程个数，只能用于守护进程模式的haproxy；
                                   默认只启动一个进程，鉴于调试困难等多方面的原因，一般只在单进程仅能打开少数文件描述符的场景中才使用多进程模式；
   \- pidfile：
   \- uid：以指定的UID身份运行haproxy进程；
   \- ulimit-n：设定每进程所能够打开的最大文件描述符数目，默认情况下其会自动进行计算，需要几个会自动调整。因此不推荐修改此选项；
   \- user：同uid，但使用的是用户名；
   \- stats：
   \- node：定义当前节点的名称，用于HA场景中多haproxy进程共享同一个IP地址时；
   \- description：当前实例的描述信息；

 \* 性能调整相关的参数
   \- maxconn <number>：设定每个haproxy进程所接受的最大并发连接数，其等同于命令行选项“-n”；“ulimit -n”自动计算的结果正是参照此参数设定的；
   \- maxpipes <number>：haproxy使用pipe完成基于内核的tcp报文重组，此选项则用于设定每进程所允许使用的最大pipe个数；每个pipe会打开两个文件描述符，因此，“ulimit -n”自动计算时会根据需要调大此值；默认为maxconn/4，其通常会显得过大，一般不需要调整；
   \- 
   \- noepoll：在Linux系统上禁用epoll机制；
   \- nokqueue：在BSE系统上禁用kqueue机制；
   \- nopoll：禁用poll机制；
   \- nosepoll：在Linux禁用启发式epoll机制；
   \- nosplice：禁止在Linux套接字上使用内核tcp重组，这会导致更多的recv/send系统调用；不过，在Linux 2.6.25-28系列的内核上，tcp重组功能有bug存在；
   \- spread-checks <0..50, in percent>：在haproxy后端有着众多服务器的场景中，在精确的时间间隔后统一对众服务器进行健康状况检查可能会带来意外问题；
                                                          此选项用于将其检查的时间间隔长度上增加或减小一定的随机时长；

​                                                          \##不要将检测报文在同一时刻 同时发送，对自己的负载大
​                                                          此选项可以分开 检测时间。

   \- tune.bufsize <number>：设定buffer的大小，同样的内存条件小，较小的值可以让haproxy有能力接受更多的并发连接，
                                          较大的值可以让某些应用程序使用较大的cookie信息；默认为16384，其可以在编译时修改，不过强烈建议使用默认值；

   \- tune.chksize <number>：设定检查缓冲区的大小，单位为字节；更大的值有助于在较大的页面中完成基于字符串或模式的文本查找，但也会占用更多的系统资源；不建议修改；
   \- tune.maxaccept <number>：设定haproxy进程内核调度运行时一次性可以接受的连接的个数，较大的值可以带来较大的吞吐率，
                                               默认在单进程模式下为100，多进程模式下为8，设定为-1可以禁止此限制；一般不建议修改；

​                                                一次系统调用能  处理的 请求数量。   

   \- tune.maxpollevents  <number>：设定一次系统调用可以处理的事件最大数，默认值取决于OS；其值小于200时可节约带宽，但会略微增大网络延迟，
                                                     而大于200时会降低延迟，但会稍稍增加网络带宽的占用量；
                                                  一次系统调用能 检查的  系统调用。   

   \- tune.maxrewrite <number>：设定为首部重写或追加而预留的缓冲空间，建议使用1024左右的大小；在需要使用更大的空间时，haproxy会自动增加其值；
   \- tune.rcvbuf.client <number>：
   \- tune.rcvbuf.server <number>：设定内核套接字中服务端或客户端接收缓冲的大小，单位为字节；强烈推荐使用默认值；
   \- tune.sndbuf.client：
   \- tune.sndbuf.server：

​                                    维持一个 客户端连接， 需要  一个 套接字文件， 但是需要 两个 缓冲空间， 一个负责发送，一个负责接收。


 \* Debug相关的参数
   \- debug
   \- quiet





#### 代理相关配置   

```
代理相关的配置可以如下配置段中。

defaults <name>

“defaults”     段用于为所有其它配置段提供默认参数，这配置默认配置参数可由下一个“defaults”所重新设定。

frontend <name>

 “frontend”     段用于定义一系列监听的套接字，这些套接字可接受客户端请求并与之建立连接。

backend  <name>

 “backend”      段用于定义一系列“后端”服务器，代理将会将对应客户端的请求转发至这些服务器。

listen   <name>

 “listen”        段通过关联“前端”和“后端”定义了一个完整的代理，通常只对TCP流量有用。



 所有代理的名称只能使用大写字母、小写字母、数字、-(中线)、_(下划线)、.(点号)和:(冒号)。
 此外，ACL名称会区分字母大小写。


```





#### 配置文件中的关键字参考 

##### 5.1 bind  



bind [<address>]:<port_range> [, ...]
bind [<address>]:<port_range> [, ...] interface <interface>

此指令仅能用于  frontend  和  listen  区段，用于定义一个或几个监听的套接字。  （##可以监听多个端口。）

常用方法：  *: 80

<address>：可选选项，其可以为主机名、IPv4地址、IPv6地址或*；省略此选项、将其指定为*或0.0.0.0时，将监听当前系统的所有IPv4地址；
<port_range>：可以是一个特定的TCP端口，也可是一个端口范围(如5005-5010)，代理服务器将通过指定的端口来接收客户端请求；
                     需要注意的是，每组监听的套接字<address:port>在同一个实例上只能使用一次，而且小于1024的端口需要有特定权限的用户才能使用，这可能需要通过uid参数来定义；
<interface>：指定物理接口的名称，仅能在Linux系统上使用；其不能使用接口别名，而仅能使用物理接口名称，而且只有管理有权限指定绑定的物理接口；



##### 5.2 mode    



mode { tcp|http|health }

设定实例的运行模式或协议。当实现内容交换时，前端和后端必须工作于同一种模式(一般说来都是HTTP模式)，否则将无法启动实例。

 **tcp：**    实例运行于纯TCP模式，在客户端和服务器端之间将建立一个全双工的连接，**且不会对7层报文做任何类型的检查**；
                此为默认模式，通常用于SSL、SSH、SMTP等应用；

 **http：**   实例运行于HTTP模式，客户端请求在转发至后端服务器之前将被深度分析，所有不与RFC格式兼容的请求都会被拒绝；

 **health：**实例工作于health模式，其对入站请求仅响应  “OK”  信息并关闭连接，且不会记录任何日志信息；
                  此模式将用于响应外部组件的健康状态检查请求；目前来讲，此模式已经废弃，因为tcp或http模式中的monitor关键字可完成类似功能；



##### 5.3  hash-type    



hash-type <method>

定义用于将hash码映射至后端服务器的方法；其不能用于frontend区段；可用方法有map-based和consistent，在大多数场景下推荐使用默认的map-based方法。

**map-based：**多数情况下推荐， hash表是一个包含了所有在线服务器的静态数组。其hash值将会非常平滑，会将权重考虑在列，但其为静态方法，
                      对在线服务器的权重进行调整将不会生效，这意味着其不支持慢速启动。此外，挑选服务器是根据其在数组中的位置进行的，
                      因此，当一台服务器宕机或添加了一台新的服务器时，大多数连接将会被重新派发至一个与此前不同的服务器上，对于缓存服务器的工作场景来说，此方法不甚适用。

**consistent：**一致性hash算法，hash表是一个由各服务器填充而成的树状结构；基于hash键在hash树中查找相应的服务器时，最近的服务器将被选中。
                   此方法是动态的，支持在运行时修改服务器权重，因此兼容慢速启动的特性。添加一个新的服务器时，仅会对一小部分请求产生影响，
                   因此，尤其适用于后端服务器为cache的场景。不过，此算法不甚平滑，派发至各服务器的请求未必能达到理想的均衡效果，
                   因此，可能需要不时的调整服务器的权重以获得更好的均衡性。

​                    \##用于 后端服务器经常性  增减。不会对调度方法产生太多影响， 均衡效果一般。  
​                        但是能获得比较好的命中率，**后端为缓存服务器时可以设置为这个选项**。





##### 5.4  log   



log global
log <address> <facility> [<level> [<minlevel>]]

为每个实例启用事件和流量日志，因此可用于所有区段。每个实例最多可以指定两个log参数，
不过，如果使用了“log global”且"global"段已经定了两个log参数时，多余了log参数将被忽略。

global：当前实例的日志系统参数同"global"段中的定义时，将使用此格式；每个实例仅能定义一次“log global”语句，且其没有任何额外参数；
<address>：定义日志发往的位置，
                 其格式之一可以为<IPv4_address:PORT>，其中的port为UDP协议端口，默认为514；
                格式之二为Unix套接字文件路径，但需要留心chroot应用及用户的读写权限；
<facility>：可以为syslog系统的标准facility之一；
<level>：定义日志级别，即输出信息过滤器，默认为所有信息；指定级别时，所有等于或高于此级别的日志信息将会被发送；



##### 5.5 maxconn   



maxconn <conns>

设定一个前端的最大并发连接数，因此，其不能用于backend区段。对于大型站点来说，可以尽可能提高此值以便让haproxy管理连接队列，
从而避免无法应答用户请求。当然，此最大值不能超出“global”段中的定义。

此外，需要留心的是，haproxy会为每个连接维持两个缓冲，每个缓冲的大小为8KB，再加上其它的数据，每个连接将大约占用17KB的RAM空间。
这意味着经过适当优化后，**有着1GB的可用RAM空间时将能维护40000-50000并发连接。**

如果为<conns>指定了一个过大值，极端场景下，其最终占据的空间可能会超出当前主机的可用内存，这可能会带来意想不到的结果；
因此，将其设定了一个可接受值方为明智决定。**其默认为2000。**



##### 5.6 default_backend    

default_backend <backend>

在没有匹配的  "use_backend"  规则时为实例指定使用的默认后端，因此，其不可应用于backend区段。
在"frontend"和"backend"之间进行内容交换时，通常使用"use-backend"定义其匹配规则；
而没有被规则匹配到的请求将由此参数指定的后端接收。

<backend>：指定使用的后端的名称；

使用案例：

use_backend     dynamic    if  url_dyn
use_backend     static        if  url_css url_img extension_img
default_backend   dynamic



##### 5.7 server      



server <name> <address>[:port] [param*]

为后端声明一个server，因此，不能用于  defaults  和   frontend   区段。

<name>：为此服务器指定的内部名称，其将出现在日志及警告信息中；如果设定了"http-send-server-name"，它还将被添加至发往此服务器的请求首部中；
<address>：此服务器的的IPv4地址，也支持使用可解析的主机名，只不过在启动时需要解析主机名至相应的IPv4地址；
[:port]：指定将连接请求所发往的此服务器时的目标端口，其为可选项；未设定时，将使用客户端请求时的同一相端口；
[param*]：为此服务器设定的一系参数；其可用的参数非常多，具体请参考官方文档中的说明，下面仅说明几个常用的参数；


 [param*]   服务器或默认服务器参数：

**backup：**sorry server  设定为备用服务器，仅在负载均衡场景中的其它server均不可用于启用此server；
**check：** 启动对此server执行健康状态检查，其可以借助于额外的其它参数完成更精细的设定，如：
**inter** <delay>：设定健康状态检查的时间间隔，单位为毫秒，默认为2000；也可以使用fastinter和downinter来根据服务器端状态优化此时间延迟；
**rise** <count>：设定健康状态检查中，某离线的server从离线状态转换至正常状态需要成功检查的次数；
**fail**  <count>：确认server从正常状态转换为不可用状态需要检查的次数；
            cookie <value>：为指定server设定cookie值，此处指定的值将在请求入站时被检查，第一次为此值挑选的server将在后续的请求中被选中，其目的在于实现持久连接的功能；
            maxconn <maxconn>：指定此服务器接受的最大并发连接数；如果发往此服务器的连接数目高于此处指定的值，其将被放置于请求队列，以等待其它连接被释放；
            maxqueue <maxqueue>：设定请求队列的最大长度；  队列 2000，超过的拒绝连接。
            observe <mode>：通过观察服务器的通信状况来判定其健康状态，默认为禁用，其支持的类型有“layer4”和“layer7”，“layer7”仅能用于http代理场景；
            redir <prefix>：启用重定向功能，将发往此服务器的GET和HEAD请求均以302状态码响应；需要注意的是，在prefix后面不能使用/，且不能使用相对地址，以免造成循环；

​            例如： server srv1 172.16.100.6:80 redir http://xxxxx.com   check
  **weight** <weight>：权重，默认为1，最大值为256，0表示不参与负载均衡；

**检查方法：** 不能用于frontend段

​        option httpchk
​        option httpchk <uri>
​        option httpchk <method> <uri>
​        option httpchk <method> <uri> <version>：

​        配置示例 ：

​    backend https_relay
​        mode tcp
​        option httpchk  OPTIONS  * HTTP/1.1\r\nHost:\ www.baby.com      ##转义

​     server apache1 192.168.1.1:443   check   port  80

​        使用案例：
​        server first  172.16.100.7:1080    cookie first  check inter 1000
​        server second 172.16.100.8:1080   cookie second check inter 1000





##### 5.8 capture request header   



capture request header <name> len <length>

捕获并记录指定的请求首部最近一次出现时的第一个值，仅能用于“frontend”和“listen”区段。捕获的首部值使用花括号{}括起来后添加进日志中。如果需要捕获多个首部值，它们将以指定的次序出现在日志文件中，并以竖线“|”作为分隔符。不存在的首部记录为空字符串，最常需要捕获的首部包括在虚拟主机环境中使用的“Host”、上传请求首部中的“Content-length”、快速区别真实用户和网络机器人的“User-agent”，以及代理环境中记录真实请求来源的“X-Forward-For”。

<name>：要捕获的首部的名称，此名称不区分字符大小写，但建议与它们出现在首部中的格式相同，比如大写首字母。需要注意的是，记录在日志中的是首部对应的值，而非首部名称。
<length>：指定记录首部值时所记录的精确长度，超出的部分将会被忽略。

可以捕获的请求首部的个数没有限制，但每个捕获最多只能记录64个字符。为了保证同一个frontend中日志格式的统一性，首部捕获仅能在frontend中定义。





##### 5.9 capture response header    



capture response header <name> len <length>

捕获并记录响应首部，其格式和要点同请求首部。

##### 5.10 stats enable      

启用基于程序编译时默认设置的统计报告，不能用于“frontend”区段。只要没有另外的其它设定，它们就会使用如下的配置：

  \- stats uri   : /haproxy?stats
  \- stats realm : "HAProxy Statistics"
  \- stats auth  : no authentication
  \- stats scope : no restriction

尽管“stats enable”一条就能够启用统计报告，但还是建议设定其它所有的参数，以免其依赖于默认设定而带来非期后果。下面是一个配置案例。

  backend public_www
    server websrv1 172.16.100.11:80
    stats enable
    stats hide-version
    stats scope   .
    stats uri     /haproxyadmin?stats
    stats realm   Haproxy\ Statistics
    stats auth    statsadmin:password
    stats auth    statsmaster:password

##### 5.11 stats hide-version     

stats hide-version

启用统计报告并隐藏HAProxy版本报告，不能用于“frontend”区段。默认情况下，统计页面会显示一些有用信息，包括HAProxy的版本号，然而，向所有人公开HAProxy的精确版本号是非常有风险的，因为它能帮助恶意用户快速定位版本的缺陷和漏洞。尽管“stats hide-version”一条就能够启用统计报告，但还是建议设定其它所有的参数，以免其依赖于默认设定而带来非期后果。具体请参照“stats enable”一节的说明。

##### 5.12 stats realm      

stats realm <realm>

启用统计报告并高精认证领域，不能用于“frontend”区段。haproxy在读取realm时会将其视作一个单词，因此，中间的任何空白字符都必须使用反斜线进行转义。此参数仅在与“stats auth”配置使用时有意义。

<realm>：实现HTTP基本认证时显示在浏览器中的领域名称，用于提示用户输入一个用户名和密码。

尽管“stats realm”一条就能够启用统计报告，但还是建议设定其它所有的参数，以免其依赖于默认设定而带来非期后果。具体请参照“stats enable”一节的说明。

##### 5.13 stats scope      

stats scope { <name> | "." }

启用统计报告并限定报告的区段，不能用于“frontend”区段。当指定此语句时，统计报告将仅显示其列举出区段的报告信息，所有其它区段的信息将被隐藏。如果需要显示多个区段的统计报告，此语句可以定义多次。需要注意的是，区段名称检测仅仅是以字符串比较的方式进行，它不会真检测指定的区段是否真正存在。

<name>：可以是一个“listen”、“frontend”或“backend”区段的名称，而“.”则表示stats scope语句所定义的当前区段。

尽管“stats scope”一条就能够启用统计报告，但还是建议设定其它所有的参数，以免其依赖于默认设定而带来非期后果。下面是一个配置案例。

backend private_monitoring
    stats enable
    stats uri     /haproxyadmin?stats
    stats refresh 10s

##### 5.14 stats auth      

stats auth <user>:<passwd>

启用带认证的统计报告功能并授权一个用户帐号，其不能用于“frontend”区段。

<user>：授权进行访问的用户名；
<passwd>：此用户的访问密码，明文格式；

此语句将基于默认设定启用统计报告功能，并仅允许其定义的用户访问，其也可以定义多次以授权多个用户帐号。可以结合“stats realm”参数在提示用户认证时给出一个领域说明信息。在使用非法用户访问统计功能时，其将会响应一个“401 Forbidden”页面。其认证方式为HTTP Basic认证，密码传输会以明文方式进行，因此，配置文件中也使用明文方式存储以说明其非保密信息故此不能相同于其它关键性帐号的密码。

尽管“stats auth”一条就能够启用统计报告，但还是建议设定其它所有的参数，以免其依赖于默认设定而带来非期后果。

##### 5.15 stats admin     

stats admin { if | unless } <cond>

在指定的条件满足时启用统计报告页面的管理级别功能，它允许通过web接口启用或禁用服务器，不过，基于安全的角度考虑，统计报告页面应该尽可能为只读的。此外，如果启用了HAProxy的多进程模式，启用此管理级别将有可能导致异常行为。

目前来说，POST请求方法被限制于仅能使用缓冲区减去保留部分之外的空间，因此，服务器列表不能过长，否则，此请求将无法正常工作。因此，建议一次仅调整少数几个服务器。下面是两个案例，第一个限制了仅能在本机打开报告页面时启用管理级别功能，第二个定义了仅允许通过认证的用户使用管理级别功能。

backend stats_localhost
    stats enable
    stats admin if LOCALHOST

backend stats_auth
    stats enable
    stats auth  haproxyadmin:password
    stats admin if TRUE

##### 5.16 option httplog      

option httplog [ clf ]

启用记录HTTP请求、会话状态和计时器的功能。

clf：使用CLF格式来代替HAProxy默认的HTTP格式，通常在使用仅支持CLF格式的特定日志分析器时才需要使用此格式。

默认情况下，日志输入格式非常简陋，因为其仅包括源地址、目标地址和实例名称，而“option httplog”参数将会使得日志格式变得丰富许多，其通常包括但不限于HTTP请求、连接计时器、会话状态、连接数、捕获的首部及cookie、“frontend”、“backend”及服务器名称，当然也包括源地址和端口号等。

##### 5.17 option logasap       

​     no option logasap

option logasap
no option logasap

启用或禁用提前将HTTP请求记入日志，不能用于“backend”区段。

默认情况下，HTTP请求是在请求结束时进行记录以便能将其整体传输时长和字节数记入日志，由此，传较大的对象时，其记入日志的时长可能会略有延迟。“option logasap”参数能够在服务器发送complete首部时即时记录日志，只不过，此时将不记录整体传输时长和字节数。此情形下，捕获“Content-Length”响应首部来记录传输的字节数是一个较好选择。下面是一个例子。

  listen http_proxy 0.0.0.0:80
      mode http
      option httplog
      option logasap
      log 172.16.100.9 local2



##### 5.18 option forwardfor       

option forwardfor [ except <network> ] [ header <name> ] [ if-none ]

允许在发往服务器的请求首部中插入“X-Forwarded-For”首部。

<network>：可选参数，当指定时，源地址为匹配至此网络中的请求都禁用此功能。
<name>：可选参数，可使用一个自定义的首部，如“X-Client”来替代“X-Forwarded-For”。有些独特的web服务器的确需要用于一个独特的首部。
if-none：仅在此首部不存在时才将其添加至请求报文问道中。

HAProxy工作于反向代理模式，其发往服务器的请求中的客户端IP均为HAProxy主机的地址而非真正客户端的地址，这会使得服务器端的日志信息记录不了真正的请求来源，“X-Forwarded-For”首部则可用于解决此问题。HAProxy可以向每个发往服务器的请求上添加此首部，并以客户端IP为其value。

需要注意的是，HAProxy工作于隧道模式，其仅检查每一个连接的第一个请求，因此，仅第一个请求报文被附加此首部。如果想为每一个请求都附加此首部，请确保同时使用了“option httpclose”、“option forceclose”和“option http-server-close”几个option。

下面是一个例子。

frontend www
    mode http
    option forwardfor except 127.0.0.1

##### 5.19 errorfile        

errorfile <code> <file>

在用户请求不存在的页面时，返回一个页面文件给客户端而非由haproxy生成的错误代码；可用于所有段中。

<code>：指定对HTTP的哪些状态码返回指定的页面；这里可用的状态码有200、400、403、408、500、502、503和504；
<file>：指定用于响应的页面文件；

例如：
errorfile 400 /etc/haproxy/errorpages/400badreq.http
errorfile 403 /etc/haproxy/errorpages/403forbid.http
errorfile 503 /etc/haproxy/errorpages/503sorry.http

##### 5.20 errorloc 和 errorloc302      

errorloc <code> <url>
errorloc302 <code> <url>


请求错误时，返回一个HTTP重定向至某URL的信息；可用于所有配置段中。

<code>：指定对HTTP的哪些状态码返回指定的页面；这里可用的状态码有200、400、403、408、500、502、503和504；
<url>：Location首部中指定的页面位置的具体路径，可以是在当前服务器上的页面的相对路径，也可以使用绝对路径；需要注意的是，如果URI自身错误时产生某特定状态码信息的话，有可能会导致循环定向；

需要留意的是，这两个关键字都会返回302状态吗，这将使得客户端使用同样的HTTP方法获取指定的URL，对于非GET法的场景(如POST)来说会产生问题，因为返回客户的URL是不允许使用GET以外的其它方法的。如果的确有这种问题，可以使用errorloc303来返回303状态码给客户端。

##### 5.21 errorloc303        

errorloc303 <code> <url>

请求错误时，返回一个HTTP重定向至某URL的信息给客户端；可用于所有配置段中。

<code>：指定对HTTP的哪些状态码返回指定的页面；这里可用的状态码有400、403、408、500、502、503和504；
<url>：Location首部中指定的页面位置的具体路径，可以是在当前服务器上的页面的相对路径，也可以使用绝对路径；需要注意的是，如果URI自身错误时产生某特定状态码信息的话，有可能会导致循环定向；

例如：

backend webserver
  server 172.16.100.6 172.16.100.6:80 check maxconn 3000 cookie srv01
  server 172.16.100.7 172.16.100.7:80 check maxconn 3000 cookie srv02
  errorloc 403 /etc/haproxy/errorpages/sorry.htm
  errorloc 503 /etc/haproxy/errorpages/sorry.htm





