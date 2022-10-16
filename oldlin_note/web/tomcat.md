### 1、tomcat及JSP的概述：



Tomcat 服务器是一个免费的开放源代码的  Web 应用服务器 (*.jsp)。
它既能支持http协议，解析html，同时也能解析 java 页面。

<font color='red'>一般用于小型企业的jsp页面，因为一个tomcat最大连接数一般在1024以下，处理能力有限。</font>

Tomcat是Apache 软件基金会（Apache Software Foundation）的 Jakarta 项目中的一个核心项目，由Apache、Sun 和其他一些公司及个人共同开发而成。
由于有了Sun 的参与和支持，最新的Servlet 和JSP 规范总是能在Tomcat 中得到体现，Tomcat 5 支持最新的Servlet 2.4 和JSP 2.0 规范。
因为Tomcat 技术先进、性能稳定，而且免费，因而深受Java 爱好者的喜爱并得到了部分软件开发商的认可，成为目前比较流行的Web 应用服务器。

Tomcat 很受广大程序员的喜欢，因为它运行时占用的系统资源小，扩展性好，支持负载平衡与邮件服务等开发应用系统常用的功能；
而且它还在不断的改进和完善中，任何一个感兴趣的程序员都可以更改它或在其中加入新的功能。

Tomcat 是一个小型的轻量级应用服务器，在中小型系统和并发访问用户不是很多的场合下被普遍使用，是开发和调试JSP 程序的首选。
对于一个初学者来说，可以这样认为，当在一台机器上配置好Apache 服务器，可利用它响应对HTML 页面的访问请求。
实际上Tomcat 部分是Apache 服务器的扩展，但它是独立运行的，所以当你运行tomcat 时，
它实际上作为一个与Apache 独立的进程单独运行的。 

这里的诀窍是，当配置正确时，Apache 为HTML页面服务，而Tomcat 实际上运行JSP 页面和Servlet。
另外，Tomcat和IIS、Apache、nginx等Web服务器一样，具有处理HTML页面的功能，另外它还是一个Servlet和JSP容器，
独立的Servlet容器是Tomcat的默认模式。不过，Tomcat处理静态HTML的能力不如Apache服务器。

 了解JSP

 JSP：全名为JAVA Server Pages，中文名叫JAVA服务器页面， 是由Sun Microsystems公司倡导、许多公司参与一起建立的一种动态网页技术标准。JSP技术有点类似ASP技术，它是在传统的网页HTML（标准通用标记语言的子集）文件(*.htm,*.html)中插入JAVA程序段(Scriptlet)和JSP标记(tag)，从而形成JSP文件，后缀名为(*.jsp)。 用JSP开发的Web应用是跨平台的，既能在Linux下运行，也能在其他操作系统上运行。

关于JAVA
JDK : JAVA  development kit  (套件) 。简单的说 JDK 是面向开发人员使用的 SDK，它提供了 JAVA的开发环境和运行环境。就是JAVA开发工具，是进行JAVA开发的基础。

JDK(JAVA Development Kit)是Sun Microsystems针对JAVA开发人员的产品。自从JAVA推出以来，JDK已经成为使用最广泛的JAVA SDK。JDK 是整个JAVA的核心，包括了JAVA运行环境，JAVA工具和JAVA基础的类库。JDK是学好JAVA的第一步。而专门运行在x86平台的Jrocket在服务端运行效率也要比Sun JDK好很多。从SUN的JDK5.0开始,提供了泛型等非常实用的功能，其版本也不断更新，运行效率得到了非常大的提高。

SDK：Software Development Kit，软件开发工具包，一般都是一些软件工程师为特定的软件包、软件框架、硬件平台、操作系统等建立应用软件时的开发工具的集合。可以包括函数库、编译程序等。

JRE：JAVA Runtime Enviroment 是指 JAVA 的运行环境，是面向 JAVA 程序的使用者，而不是开发者，运行JAVA程序所必须的环境的集合，包含JVM标准实现及JAVA核心类库。JAVA Runtime Environment（包括JAVA Plug-in）是Sun的产品，包括两部分：JAVA Runtime Environment和JAVA Plug-in。JRE是可以在其上运行、测试和传输应用程序的JAVA平台。它包括JAVA虚拟机（JVM）、JAVA核心类库和支持文件。它不包含开发工具(JDK)--编译器、调试器和其它工具。JRE需要辅助软件--JAVA Plug-in--以便在浏览器中运行applet。

JVM：JAVA virtual machine JVM 就是我们常说的 JAVA 虚拟机。JVM是一种用于计算设备的规范，它是一个虚构出来的计算机，是通过在实际的计算机上仿真模拟各种计算机功能来实现的。JVM是JAVA的核心和基础，在JAVA编译器和OS平台之间的虚拟处理器。它是一种基于下层的操作系统和硬件平台并利用软件方法来实现的抽象的计算机，可以在上面执行JAVA的字节码程序。JAVA编译器只需面向JVM，生成JVM能理解的代码或字节码文件。JAVA源文件经编译器，编译成字节码程序，通过JVM将每一条指令翻译成不同平台机器码，通过特定平台运行在JDK的安装目录里你可以找到 JRE目录里面有两个文件夹bin 和 lib,在这里可以认为 bin 里的就是 JVM， lib 中则是 JVM 工作所需要的类库，而 JVM 和 lib 和起来就称为 JRE。



### 2、常用JSP WEB服务器 :



Web服务器是运行及发布Web应用的容器，只有将开发的Web项目放置到该容器中，才能使网络中的所有用户通过浏览器进行访问。
开发Java Web应用所采用的服务器主要是与JSP/Servlet兼容的Web服务器，
比较常用的有Tomcat、Resin、JBoss、 和 WebLogic 等。

Tomcat 服务器
目前最为流行的Tomcat服务器是Apache-Jarkarta开源项目中的一个子项目，是一个小型、轻量级的支持JSP和Servlet 技术的Web服务器，
也是初学者学习开发JSP应用的首选。

Resin 服务器
Resin是Caucho公司的产品，是一个非常流行的支持Servlet和JSP的服务器，速度非常快。
Resin本身包含了一个支持HTML的Web服务器，这使它不仅可以显示动态内容，
而且显示静态内容的能力也毫不逊色，因此许多网站都是使用Resin服务器构建。

JBoss服务器
JBoss是一个种遵从JavaEE规范的、开放源代码的、纯Java的EJB服务器，对于J2EE有很好的支持。
JBoss采用JML API实现软件模块的集成与管理，其核心服务又是提供EJB服务器，不包含Servlet和JSP的Web容器，
不过它可以和Tomcat完美结合。

WebLogic 服务器
WebLogic 是BEA公司的产品，可进一步细分为 WebLogic Server、WebLogic Enterprise 和 WebLogic Portal 等系列，
其中 WebLogic Server 的功能特别强大。WebLogic 支持企业级的、多层次的和完全分布式的Web应用，并且服务器的配置简单、界面友好。
对于那些正在寻求能够提供Java平台所拥有的一切应用服务器的用户来说，WebLogic是一个十分理想的选择。



undertow

服务器（未来趋势）
Undertow 是红帽公司开发的一款基于 NIO 的高性能 Web 嵌入式服务器。
特点：轻量级：它是一个 Web 服务器，但不像传统的 Web 服务器有容器概念，它由两个核心 Jar 包组成，加载一个 Web 应用可以小于 10MB 内存
Servlet3.1 支持：它提供了对 Servlet3.1 的支持
WebSocket 支持：对 Web Socket 完全支持，用以满足 Web 应用巨大数量的客户端
嵌套性：它不需要容器，只需通过 API 即可快速搭建 Web 服务器

推荐阅读：
https://blog.csdn.net/qq_39865635/article/details/90375762





### 3、Servlet 是什么？

Servlet（Server Applet）是Java Servlet的简称，是运行在 Web 服务器或应用服务器上的 程序，称为小服务程序或服务连接器，
是用Java编写的服务器端程序，具有独立于平台和协议的特性，主要功能在于交互式地浏览和生成数据，生成动态Web内容。

服务器上需要一些程序，常常是根据用户输入，去访问数据库的程序。
这些通常是使用公共网关接口（Common Gateway Interface，CGI）应用程序完成的。

然而，在服务器上运行 Java，这种程序可使用 Java 编程语言实现。
在通信量大的服务器上，JavaServlet 的优点在于它们的执行速度更快于 CGI 程序。
各个用户请求被激活成单个程序中的一个线程，而无需创建单独的进程，这意味着服务器端处理请求的系统开销将明显降低。

一个 Servlet 就是 Java 编程语言中的一个类，它被用来扩展服务器的性能

Servlet 架构
下图显示了 Servlet 在 Web 应用程序中的位置。
![file://c:\users\admini~1\appdata\local\temp\tmph9nced\1.png](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291401253.png)

Servlet 的主要功能在于交互式地浏览和修改数据，生成动态 Web 内容。这个过程为：

1.客户端发送请求至服务器端；
2.服务器将请求信息发送至 Servlet；
3.Servlet 生成响应内容并将其传给服务器。响应内容动态生成，通常取决于客户端的请求；
4.服务器将响应返回给客户端。




Servlet 任务

Servlet 执行以下主要任务：
• 读取客户端（浏览器）发送的显式的数据。这包括网页上的 HTML 表单，或者也可以是来自 applet 或自定义的 HTTP 客户端程序的表单。
• 读取客户端（浏览器）发送的隐式的 HTTP 请求数据。这包括 cookies、媒体类型和浏览器能理解的压缩格式等等。
• 处理数据并生成结果。这个过程可能需要访问数据库，执行 RMI 或 CORBA 调用，调用 Web 服务，或者直接计算得出对应的响应。
• 发送显式的数据（即文档）到客户端（浏览器）。该文档的格式可以是多种多样的，包括文本文件（HTML 或 XML）、二进制文件（GIF 图像）、Excel 等。
• 发送隐式的 HTTP 响应到客户端（浏览器）。这包括告诉浏览器或其他客户端被返回的文档类型（例如 HTML），设置 cookies 和缓存参数，以及其他类似的任务。

Servlet 包
Java Servlet 是运行在带有支持 Java Servlet 规范的解释器的 web 服务器上的 Java 类。
Servlet 可以使用 javax.servlet 和 javax.servlet.http 包创建，它是 Java 企业版的标准组成部分，
    Servlet框架是由2个Java包组成：(1)javax.servlet   和  (2)javax.servlet.http 
       (1)javax.servlet包中定义了所有Servlet类都必须实现的接口和类。 
       (2)javax.servlet.http包中定义了采用HTTP通信的HttpServlet类

Java 企业版是支持大型开发项目的 Java 类库的扩展版本。
这些类实现 Java Servlet 和 JSP 规范。当前二者相应的版本分别是 Java Servlet 2.5 和 JSP 2.1。
Java Servlet 就像任何其他的 Java 类一样已经被创建和编译。在您安装 Servlet 包并把它们添加到您的计算机上的 Classpath 类路径中之后，
您就可以通过 JDK 的 Java 编译器或任何其他编译器来编译 Servlet。


设置 Web 服务器：Tomcat
在市场上有许多 Web 服务器支持 Servlet。有些 Web 服务器是免费下载的，Tomcat 就是其中的一个。
Apache Tomcat 是一款 Java Servlet 和 JavaServer Pages 技术的开源软件实现，
可以作为测试 Servlet 的独立服务器，而且可以集成到 Apache Web 服务器

![file://c:\users\admini~1\appdata\local\temp\tmph9nced\2.png](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291401260.png)


生命周期

init( ),service( ),destroy( )是Servlet生命周期的方法。
代表了Servlet从“出生”到“工作”再到“死亡 ”的过程。
Servlet容器（例如TomCat）会根据下面的规则来调用这三个方法：


1.init( ),
当Servlet第一次被请求时，Servlet容器就会开始调用这个方法来初始化一个Servlet对象出来，
但是这个方法在后续请求中不会在被Servlet容器调用，就像人只能“出生”一次一样。
我们可以利用init（ ）方法来执行相应的初始化工作。调用这个方法时，
Servlet容器会传入一个ServletConfig对象进来从而对Servlet对象进行初始化。

2.service( )方法，
每当请求Servlet时，Servlet容器就会调用这个方法。就像人一样，需要不停的接受老板的指令并且“工作”。
第一次请求时，Servlet容器会先调用init( )方法初始化一个Servlet对象出来，然后会调用它的service( )方法进行工作，
但在后续的请求中，Servlet容器只会调用service方法了。

3.destory()
当要销毁Servlet时，Servlet容器就会调用这个方法，就如人一样，到时期了就得死亡。
在卸载应用程序或者关闭Servlet容器时，就会发生这种情况，一般在这个方法中会写一些清除代码。

流程如下：

一个客户端的请求到达 Server
Server 创建一个请求对象，处理客户端请求，
Server 创建一个响应对象，响应客户端请求
Server 激活 Servlet 的 service() 方法，传递请求和响应对象作为参数给到Service方法
service() 方法获得关于请求对象的信息，处理请求，访问其他资源，获得需要的信息
service() 方法使用响应对象的方法，将响应传回Server，最终到达客户端。
service()方法可能激活其它方法以处理请求，如 doGet() 或 doPost() 或程序员自己开发的新的方法。对于更多的客户端请求，
Server 创建新的请求和响应对象，仍然激活此 Servlet 的 service() 方法，将这两个对象作为参数传递给它。

如此重复以上的循环，但无需再次调用 init() 方法。一般 Servlet 只初始化一次，
当 Server 不再需要 Servlet 时（一般当 Server 关闭时），Server 调用 Servlet 的 destroy() 方法。


1.第一个到达服务器的 HTTP 请求被委派到 Servlet 容器。
2.Servlet 容器在调用 service() 方法之前加载 Servlet。
3.然后 Servlet 容器处理由多个线程产生的多个请求，每个线程执行一个单一的 Servlet 实例的 service() 方法。

推荐阅读：
https://blog.csdn.net/qq_19782019/article/details/80292110



### 4、Tomcat安装

tomcat官网http://tomcat.apache.org/

安装JDK（tomcat8.5.x要求JDK不低于1.7）
略

下载安装包
[root@nginx opt]# wget https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.78/bin/apache-tomcat-8.5.78.tar.gz

解压即用
[root@nginx opt]# tar -zxvf apache-tomcat-8.5.78.tar.gz
[root@nginx opt]# mv apache-tomcat-8.5.78 /usr/local/tomcat
[root@nginx opt]# cd /usr/local/tomcat/bin
启动tomcat
[root@nginx bin]# ./catalina.sh start

验证是否启动成功
[root@nginx bin]# ps -ef |grep tomcat
或
[root@nginx bin]# netstat -ntpl |grep 8080
浏览器上访问：http://本机IP:8080

### 5、tomcat 目录中的基本组成：

├── bin              #用以启动、关闭 Tomcat 或者其它功能的脚本（.bat文件和.sh文件）
├── conf            #用以配置 Tomcat 的 XML 及 DTD 文件
├── lib                #存放web应用能访问的JAR包
├── LICENSE
├── logs             #<font color='red'>Catalina.out</font>和其它Web应用程序的日志文件
├── NOTICE
├── RELEASE-NOTES
├── RUNNING.txt
├── temp             #临时文件
├── webapps     <font color='red'>#webapps/ROOT是Web应用内容家目录</font>
└── work             #用以产生由 JSP编译出的Servlet的.java和.class文件
                               \#Tomcat将jsp生成的servlet源文件和字节码文件放到此目录



企业中java类程序最常见的错误：oom内存问题
**jvm调优**
https://www.cnblogs.com/baihuitestsoftware/articles/6483690.html

设置内存最小可用512m，最大可用1024m
vim catalina.sh
添加一行
226  JAVA_OPTS='-Xms512m -Xmx1024m'



关闭tomcat另一种关闭方法：

server.xml  8005端口

telnet 127.0.0.1 8005后输入大写SHUTDOWN



常见java日志报错排错位置：
![file://c:\users\admini~1\appdata\local\temp\tmph9nced\3.png](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291401269.png)





### 6、Tomcat Server处理一个http请求的过程 

假设来自客户的请求为： http://localhost:8080/wsota/wsota_index.jsp －－＞tomcat(ip)

1) 请求被发送到本机端口8080，被在那里侦听的Coyote HTTP/1.1 Connector获得 
2) Connector把该请求交给它所在的Service的Engine来处理，并等待来自Engine的回应 
3) Engine获得请求 localhost/wsota/wsota_index.jsp，由主机名 来  搜索它所拥有 的 所有虚拟主机列表。 
4) Engine匹配到名为localhost的Host（即使匹配不到也把请求交给该Host处理，因为该Host被定义为该Engine的默认主机）
5) localhost Host获得请求/wsota/wsota_index.jsp ，匹配它所拥有的所有 Context  
6) Host匹配到路径为/wsota 的 Context（如果匹配不到就把该请求交给路径名为""的Context去处理） 
7) path="/wsota"的Context获得请求/wsota_index.jsp，在它的mapping table中寻找对应的servlet 
8) Context匹配到URL PATTERN为*.jsp的servlet，对应于JspServlet类 
9) 构造HttpServletRequest对象和HttpServletResponse对象，作为参数调用JspServlet的doGet或doPost方法 
10) Context把执行完了之后的HttpServletResponse对象返回给Host 
11) Host把HttpServletResponse对象返回给Engine 
12) Engine把HttpServletResponse对象返回给Connector 
13) Connector把HttpServletResponse对象返回给客户browser 





### 7、tomcat多实例安装

复制两个实例
[root@nginx1 local]# cp -a tomcat tomcat_8081
[root@nginx1 local]# cp -a tomcat tomcat_8082

修改8080与8005端口
[root@nginx1 local]#sed -i 's/8080/8081/g' tomcat_8081/conf/server.xml 
[root@nginx1 local]# sed -i 's/8080/8082/g' tomcat_8082/conf/server.xml 
[root@nginx1 local]# sed -i 's/8005/8006/g' tomcat_8081/conf/server.xml 
[root@nginx1 local]# sed -i 's/8005/8007/g' tomcat_8082/conf/server.xml

启动两个实例 
[root@nginx1 bin]# /usr/local/tomcat_8081/bin/catalina.sh start
[root@nginx1 bin]# /usr/local/tomcat_8082/bin/catalina.sh start

修改nginx虚拟主机文件
vim tomcat-proxy.conf
upstream tomcat {
        server 192.168.245.200:8080;
        server 192.168.245.200:8081;
        server 192.168.245.200:8082;
}
server {
        listen 80;
        server_name a1.com;
location  / {
        proxy_pass http://tomcat;
        access_log /var/log/a1.access.log proxy;
        \#proxy_set_header Host  $host;
        \#proxy_set_header X-Real-IP   $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_redirect off;
        proxy_connect_timeout 30;
        proxy_send_timeout 15;
        proxy_read_timeout 15;
           }
}

验证：在浏览器打开http://a1.com/



### 8、创建虚拟主机

```
vim /opt/tomcat/conf/server.xml
    <Engine name="Catalina" defaultHost="localhost">
      <Realm className="org.apache.catalina.realm.LockOutRealm">
        <Realm className="org.apache.catalina.realm.UserDatabaseRealm"
               resourceName="UserDatabase"/>
      </Realm>
      
      <Host name="bbs1.uplooking.com"  appBase="/webapps"
            unpackWARs="true" autoDeploy="true"  deployOnStartup="true">
        <Valve className="org.apache.catalina.valves.AccessLogValve" directory="/opt/tomcat/logs"
               prefix="bbs1.uplooking.com_access_log." suffix=".txt"
               pattern="%h %l %u %t &quot;%r&quot; %s %b" />
        <Context path="" docBase="/webroot/bbs1.uplooking.com" />
      </Host>

      <Host name="bbs2.uplooking.com"  appBase="/opt/tomcat/webapps"
            unpackWARs="true" autoDeploy="true"  deployOnStartup="true">
        <Valve className="org.apache.catalina.valves.AccessLogValve" directory="/opt/tomcat/logs"
               prefix="bbs2.uplooking.com_access_log." suffix=".txt"
               pattern="%h %l %u %t &quot;%r&quot; %s %b" />
        <Context path="" docBase="/webroot/bbs2.uplooking.com" />
      </Host>
    </Engine>
```



​          

### 9、优化：

8.1、网络优化：
首先需要保证内网数据传输的可达性，减少丢包率，优化相关的网络硬件配置。

修改server.xml  
   <Connector port="8080" protocol="HTTP/1.1"
               connectionTimeout="20000"
               redirectPort="8443" 
               compression="on"             #开启压缩功能
               compressionMinSize="50"          #启用压缩的输出内容大小，当被压缩的对象大小大于等于该配置时才会被压缩，默认2KB
               noCompressionUserAgents="firefox,chrome"           #对配置的浏览器不启用压缩
               compressableMimeType="text/html,text/xml,text/javascript,text/css,text/plain"/>      #被压缩的文件类型

8.2、服务自身优化
tomcat服务有阻塞与非阻塞模式

BIO模式：
阻塞式I/O操作，一个线程处理一个请求，高并发时，线程数会增多，浪费服务器资源，
tomcat7默认使用这种模式，tomcat8取消了BIO模式

NIO模式：
非阻塞式I/O操作，利用java的异步I/O处理，可以通过少量的线程来处理大量的请求，tomcat8默认使用这种模式

修改server.xml
56 <Executor name="tomcatThreadPool" namePrefix="catalina-exec-"
        maxThreads="150"                #最大线程数配置，生产环境中可取500~800，根据业务需求调
        prestartminSpares = "true"      #如果设置的不是true，minSpareThreads设置的参数值无效
        maxQueueSize = "100"            #线程数满时，最大允许等待的队列数，超过此配置则拒绝连接请求
        minSpareThreads="4"/>           #初始化创建的线程数（最小空闲线程数）

72行后添加
 <Connector executor="tomcatThreadPool"
        port="8080" 
        protocol="org.apache.coyote.http11.Http11NioProtocol"       #上述网络优化里的开启NIO模式
        connectionTimeout="20000"       #连接超时，单位是毫秒
        minSpareThreads="100"              #最小空闲线程数
        maxSpareThreads="1000"              #最大空闲线程数
        minProcessors="100"                 #最小空闲连接线程数
        maxProcessors="1000"                 #最大空闲连接线程数
        maxConnections="1000"                #最大连接线程数
        enableLookups="false"               #禁用DNS查询，提高性能
        maxPostsize="10485760"             #限制提交请求包的大小，10485760为10M
        compression="on"                        #开启压缩
        disableUploadTimeout="ture"         #开启上传超时模式
        compressionMinSize="2048"         #包大小为至少为2G时进行压缩，单位为M
        acceptorThreadCount="2"         #用于接收连接线程的数量，多核cpu一般配置为2
        redirectPort="8443" />



### 10、配置管理界面

10.1、创建管理Manger App用户

```
[root@nginx1 ~]# vim /usr/local/tomcat/conf/tomcat-users.xml
49<!--
  <role rolename="tomcat"/>
  <role rolename="role1"/>
  <user username="tomcat" password="tomcat" roles="tomcat"/>
  <user username="both" password="tomcat" roles="tomcat,role1"/>
  <user username="role1" password="tomcat" roles="role1"/>
-->
#去掉注释<!--    --> 修改为如下， 
<role rolename="admin-gui"/>
<role rolename="admin-script"/>
<role rolename="manager-gui"/>
<role rolename="manager-script"/>
<role rolename="manager-jmx"/>
<role rolename="manager-status"/>
<user username="admin" password="123456" roles="manager-gui,manager-script,manager-jmx,manager-status,admin-script,admin-gui"/>
 
或者
简单配置：
<role rolename="manager-gui"/>
<user username="tomcat" password="123456" roles="manager-gui"/>
```

10.2、重启tomcat

[root@nginx1 conf]# /usr/local/tomcat/bin/catalina.sh stop

[root@nginx1 conf]# /usr/local/tomcat/bin/catalina.sh start

10.3、在浏览器登录：http://192.168.245.160:8080

![image-20220526153903719](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205261539785.png)



![image-20220526153818634](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205261538690.png)

![image-20220526154154999](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205261541082.png)



角色说明

1：“manager-gui”：Allows access to the html interface（允许通过web的方式登录查看服务器信息）。
2：“manager-script”: Allows access to the plain text interface（允许以纯文本的方式访问）。
3：“manager-jmx”: Allows access to the JMX proxy interface（允许jmx的代理访问）。
4：“manager-status”: Allows access to the read-only status pages（允许以只读状态访问）。
5: admin-gui: 允许访问HTML GUI
6 : admin-script: 允许访问文本接口

官方说明[http:#tomcat.apache.org/tomcat-9.0-doc/manager-howto.html#Configuring_Manager_Application_Access](http://tomcat.apache.org/tomcat-9.0-doc/manager-howto.html#Configuring_Manager_Application_Access)



10.4、可能会出现的问题：

![image-20220526154427921](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205261544995.png)

解决方法如下：

```
[root@nginx1 local]# vim /usr/local/tomcat/webapps/manager/META-INF/context.xml
 
注释掉这段代码就可以了
<Context antiResourceLocking="false" privileged="true" >
 <!-- <Valve className="org.apache.catalina.valves.RemoteAddrValve"
         allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" />
  <Manager sessionAttributeValueClassNameFilter="JAVA\.lang\.(?:Boolean|Integer|Long|Number|String)|org\.apache\.catalina\.filters\.CsrfPreventionFilter\$LruCache(?:\$1)?|JAVA\.util\.(?:Linked)?HashMap"/> -->
</Context>
 
或者改为
 
<Valve className="org.apache.catalina.valves.RemoteAddrValve"
allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1|\d+\.\d+\.\d+\.\d+" />
```

<font color='red'>tomcat8以上还要增加以下配置</font>

```
 [root@nginx1 ~]# vim /usr/local/tomcat/conf/Catalina/nginx1/manager.xml
 内容如下：
<Context privileged="true" antiResourceLocking="false"
          docBase="${catalina.home}/webapps/manager">
     <Valve className="org.apache.catalina.valves.RemoteAddrValve" allow="^.*$" />
 </Context>
```

重启tomcat




### 11、jar打包与解包

语法：

jar -cvf 打包的包名（可以是xxx.jar，也可以是xxx.war）  打包文件

jar -xvf  解包的包名

当把war放在tomcat内容家目录时，会自动解压war包，但jar包不会

也可以进入到首页manager app里进行部置war

注：

[jar与war的区别](https://www.zmbg.com/article/18773.html)



![image-20220526143458135](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205261434192.png)

![image-20220526143423197](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205261434256.png)

### 12、lnmT架构搭建并测试连接mysql

搭建nginx

略

搭建mysql

略

搭建tomcat

略

创建测试数据

[root@nginx1 ~]# mysql -uroot -p123456
create database tomcat;        #测试数据库，为了和后面方便测试，这里创建tomcat
use tomcat
create table tt(id int,name varchar(128));                #创建测试表
insert into tt values (1,"老林真帅"),(2,"老林无敌棒");    #创建测试数据
grant all on tomcat.* to tomcat@'%' identified by 'tomcat';    授权tomcat用户能连接数据库
flush privileges;

测试JSP链接MySQL

           Jsp链接mysql，官方提供了工具：安装mysql-connector
安装mysql-connector

[root@nginx1 conf]# wget https://downloads.mysql.com/archives/get/p/3/file/mysql-connector-java-5.1.36.tar.gz

[root@nginx1 ~]# tar xvf mysql-connector-java-5.1.36.tar.gz -C /usr/local/src/
[root@nginx1 ~]# cd /usr/local/src/mysql-connector-java-5.1.36/
[root@nginx1 ~]# cp /usr/local/src/mysql-connector-java-5.1.36/mysql-connector-java-5.1.36-bin.jar /usr/local/tomcat/lib/                  #只需要复制到tomcat的lib目录下，重启tomcat就可以生效
[root@nginx1 ~]# /usr/local/tomcat/bin/catalina.sh stop

[root@nginx1 conf]# /usr/local/tomcat/bin/catalina.sh start

```jsp
标准配置如下：
[root@nginx1 ~]# cat /usr/local/tomcat/webapps/ROOT/mysql.jsp
<%@ page contentType="text/html;charset=utf-8"%>
<%@ page import="java.sql.*"%>
<html>
<body>
<%
Class.forName("org.gjt.mm.mysql.Driver").newInstance();
String url ="jdbc:mysql://localhost/tomcat?			user=tomcat&password=123456&useUnicode=true&characterEncoding=utf-8";	#此处的locathost指的是本地数据库，如果数据库不在本地，需要修改为数据库所在的服务器的IP，记得也要修改用户密码。
Connection conn= DriverManager.getConnection(url);
Statement stmt=conn.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE,ResultSet.CONCUR_UPDATABLE);
String sql="select * from tt";			#执行的数据库语句
ResultSet rs=stmt.executeQuery(sql);
while(rs.next()){%>
step:<%=rs.getString(1)%>				#这里是获取数据库tomcat.tt表的第一行内容
context:<%=rs.getString(2)%><br><br>	#这里是获取数据库tomcat.tt表的第二行内容
<%}%>
<%out.print("Congratulations!!! JSP connect MYSQL IS OK!!");%>
<%rs.close();
stmt.close();
conn.close();
%>
%</body>
%</html>
```

测试结果如下：

![image-20220526160039621](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205261600659.png)