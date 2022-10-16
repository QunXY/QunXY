

## elk1

ELK是Elasticsearch、Logstash、Kibana的简称，是近乎完美的开源实时日志分析平台。这三者是日志分析平台的核心组件，而并非全部。

### 概述

1. Elasticsearch
   是实时全文搜索和分析引擎，提供搜集、分析、存储数据三大功能，是一套开放REST和JAVA API等结构提供高效搜索功能，可扩展的分布式系统。它构建于Apache Lucene搜索引擎库之上。
   具有分布式，零配置，自动发现，索引自动分片，索引副本机制，restful 风格接口，多数据源，自动搜索负载等特点
2. Logstash
   它支持几乎任何类型的日志，包括系统日志、错误日志和自定义应用程序日志。
   它可以从许多来源接收日志，这些来源包括 syslog、消息传递（例如 RabbitMQ）和JMX，它能够以多种方式输出数据，包括电子邮件、websockets和Elasticsearch。
3. Kibana
   是一个基于Web的图形界面，用于搜索、分析和可视化存储在 Elasticsearch指标中的日志数据。
   它利用Elasticsearch的REST接口来检索数据，不仅允许用户创建他们自己的数据的定制仪表板视图，还允许他们以特殊的方式查询和过滤数据，Kibana 可以为 Logstash 和 Elasticsearch 提供友好的日志分析 web 界面，可以帮助你汇总、分析和搜索重要数据日志。

### 实验环境

实验机器准备：

| 主机名 | IP              | 角色        | 配置  |
| ------ | --------------- | ----------- | ----- |
| elk1   | 192.168.245.170 | es、es-head | 1核1G |
| elk2   | 192.168.245.171 | es          | 1核1G |
| elk3   | 192.168.245.172 | es、kibana  | 1核2G |
| elk4   | 192.168.245.173 | LogStash    | 2核2G |

### 修改与分发hosts文件

```
[root@elk1 ~]# vim /etc/hosts
# 添加以下内容
192.168.245.170 elk1
192.168.245.171 elk2
192.168.245.172 elk3
192.168.245.173 elk4

# 分发
[root@elk1 ~]# scp /etc/hosts 192.168.245.171:/etc/hosts
[root@elk1 ~]# scp /etc/hosts 192.168.245.172:/etc/hosts
[root@elk1 ~]# scp /etc/hosts 192.168.245.173:/etc/hosts
```

### 安装java环境

清理原环境的java：
rpm -qa | grep java
rpm -qa | grep jdk
如果有，yum remove相关包。

安装java环境：

mkdir /usr/java
tar -zxvf jdk-8u191-linux-x64.tar.gz -C /usr/java

设置java环境变量：

```
在最后一行添加： 
vim /etc/profile 
export JAVA_HOME=/usr/java/jdk1.8.0_191
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export PATH=$JAVA_HOME/bin:$PATH

```

加载环境变量生效

```
source /etc/profile
```

验证：

```
 java -version
```

### 安装elasticsearch 

 es官网：https://www.elastic.co/cn/

三个组件下载地址：https://www.elastic.co/cn/downloads/

<font color='red'>注：搭建elk版本要一致，如7.17版本就要es、logstash、kibama版本都为7.17</font>

三台安装es的机器都是一样的操作

#### 1.安装

上传elasticsearch-7.17.0到/opt目录下（elk1、elk2、elk3）

```
cd /opt/ && wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.17.0-x86_64.rpm

yum -y install elasticsearch-7.17.0-x86_64.rpm
```

#### 2.创建es的data目录和log目录

```
mkdir -p /opt/elasticsearch/data /opt/elasticsearch/log
```

#### 3.修改权限

```
chown -R elasticsearch:elasticsearch /opt/elasticsearch
```

#### 4.修改配置文件

```
cp /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.bak

vim /etc/elasticsearch/elasticsearch.yml
# 修改位置
cluster.name: elk	#集群名
node.name: elk1    # 改成对应的主机名
path.data: /opt/elasticsearch/data
path.logs: /opt/elasticsearch/log
network.host: 192.168.245.170    # 改成对应的IP
http.port: 9200
discovery.seed_hosts: ["elk1", "elk2", "elk3"]   # 能被发现的节点
cluster.initial_master_nodes: ["elk1", "elk2", "elk3"]   # 节点可以升级为主节点的选项
115 cluster.initial_master_nodes: ["elk3"]	#7.17.0版本新加这设置，需注释掉，否则会报错

# 此两项为添加项，主要为安装elasticsearch-head插件添加支持
http.cors.enabled: true
http.cors.allow-origin: "*"



# 分发
[root@elk1 ~]# scp /etc/elasticsearch/elasticsearch.yml 192.168.245.171:/etc/elasticsearch/elasticsearch.yml
[root@elk1 ~]# scp /etc/elasticsearch/elasticsearch.yml 192.168.245.172:/etc/elasticsearch/elasticsearch.yml


# 在elk2、elk3修改成对应的主机名和IP地址
```

#### 5.jvm内存调优                

 es吃资源严重，可以根据服务器情况合理调配

原则为：调整为物理内存的一半

```
/etc/elasticsearch/jvm.options
改：-Xms4G
   -Xmx4G

为：-Xms512M
   -Xmx512M
```



#### 6.启动与开机自启

```
systemctl start elasticsearch && systemctl enable elasticsearch

# 首次启动会很慢
# 成功浏览器打开ip:9200，如下图
```

![image-20220530113256864](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205301132943.png)

#### 7.检查端口

```
# 9200的端口
[root@elk1 ~]# netstat -lntp | grep 92
tcp6       0      0 192.168.245.171:9200     :::*                    LISTEN      880/java            
tcp6       0      0 192.168.245.171:9300     :::*                    LISTEN      880/java
```

#### 8.出现es报错，无法锁住内存（如果出现此错误）

```
# 在启动脚本里增加
vim /usr/lib/systemd/system/elasticsearch.service
[Service]
LimitMEMLOCK=infinity


# 重启服务
systemctl daemon-reload
systemctl start elasticsearch
```



### 安装node.js

Node.js 不是一门新的编程语言，也不是一个 JavaScript 框架，它是一套 JavaScript 运行环境，用来支持 JavaScript 代码的执行。

Node.js 官网中文版：https://nodejs.org/zh-cn/

#### 1.安装

下载nodejs工具包，上传node.js的包到elk的/opt目录下，版本为10.12版本

```
[root@elk1 opt]# cd /opt && wget https://nodejs.org/dist/v16.17.1/node-v16.17.1-linux-x64.tar.xz

[root@elk1 opt]# tar xvf node-v10.12.0-linux-x64.tar.gz
```

#### 2.添加环境变量

```
[root@elk1 opt]# mv node-v10.12.0-linux-x64 /usr/local/node

[root@elk1 opt]# vim /etc/profile
#set for nodejs
export NODE_HOME=/usr/local/node/
export PATH=$NODE_HOME/bin:$PATH

[root@elk1 opt]# source !$

# 验证
[root@elk01 opt]# node -v
v10.12.0                                #出现此结果，刚已正常运行
```

### 安装elasticsearch-head-master

#### 1.安装

上传elasticsearch-head-master的包到elk1的/opt目录下

```
[root@elk1 opt]# yum -y install unzip

[root@elk1 opt]# unzip elasticsearch-head-master.zip
```

#### 2.进入head目录进行安装

```shell
[root@elk1 opt]# cd elasticsearch-head-master

# 进行npm安装，因为用npm安装依赖包都是用国外的源，速度太慢，所以使用淘宝的镜像
# 方法一：
[root@elk1 elasticsearch-head-master]# npm config set registry https://registry.npm.taobao.org --global 

或者

[root@elk1 elasticsearch-head-master]# npm config set registry https://registry.npm.taobao.org

# 10版本会出现缺包，忽略那个包，使用骚操作，第一次更换为淘宝源后进行install使用Ctrl+c终止然后再执行一次install，一般就会忽略那个包，不报错

[root@elk1 elasticsearch-head-master]# npm install			#安装
[root@elk1 elasticsearch-head-master]# npm run start 		#启动
或
[root@elk1 elasticsearch-head-master]# npm run start >> /dev/null &

注：可能会出现卡住现象，推荐使用方法二

# 方法二:
# 使用cnpm命令并使用淘宝源
[root@elk1 elasticsearch-head-master]# npm install -g cnpm --registry=https://registry.npm.taobao.org
[root@elk1 elasticsearch-head-master]# cnpm install     #cnmp为使用国内源的node.js命令，c代表chinese
出现如下标记证明已安装好依赖包
✔ All packages installed

[root@elk1 elasticsearch-head-master]# cnpm run start  #前台运行，一退出就失效
或
[root@elk1 elasticsearch-head-master]# cnpm run start >> /dev/null &	#elasticsearch-head-masterr后台运行

#cnpm install 过程中可能出错，如下
killed: false,
  code: 2,
  signal: null,
  cmd:
   'tar jxf /tmp/phantomjs/phantomjs-2.1.1-linux-x86_64.tar.bz2' } Error: Command failed: tar jxf /tmp/phantomjs/phantomjs-2.1.1-linux-x86_64.tar.bz2
tar (child): bzip2：无法 exec: 没有那个文件或目录
tar (child): Error is not recoverable: exiting now
tar: Child returned status 2
tar: Error is not recoverable: exiting now

原因：缺少bzip2压缩工具包
yum install -y bzip2
```

#### 3.添加到开机自启

```
[root@elk1 elasticsearch-head-master]# vim /etc/rc.d/rc.local
[root@elk1 elasticsearch-head-master]# cnpm run start >>/dev/null &
[root@elk1 elasticsearch-head-master]# chmod +x /etc/rc.d/rc.local
```

#### 4.浏览器验证

浏览器输入http://192.168.245.170:9100/

![image-20220530154020688](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205301540748.png)

修改localhost为真实IP

![image-20220530154327990](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205301543048.png)

集群健康值介绍：

黄色：代表没有主分片数据丢失。

红色：代表有数据丢失

绿色：代表正常

五角星代表是主节点，圆代表是从节点，索引详细信息可点击某个索引，查看该索引的所有信息，包括mappings、setting等等

#### 5.添加索引

![image-20220530160045730](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205301600791.png)

![image-20220530161651484](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205301616545.png)

提示：es支持一个类似于快照的功能，方便我们用于数据备份，如上图的新建索引的副本数

Head插件小缺点：当我们索引特别多的时候，打开head至少需要五分钟。因为它要把所有的索引都扫描一遍进行展示，

这时候打开使用的带宽也会特别大（不会出现超时，一直等待就可以）



#### 6.es-head查询

格式为：

http://ip:port/

索引名/索引类型/_search

请求方式为GET

这种方式是查询该索引下的所有数据

![image-20221009110833389](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202210091109831.png)



如果要查询更为详细，可以在查询条件后面跟ID，比如

http://ip:port/

索引名/索引类型名/文档id

请求方式仍然是GET请求

![image-20221009111023344](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202210091110663.png)







### 安装kibana

#### 1.安装

上传kibana-7.17.0-x86_64.rpm到elk3的/opt目录（<font color='red'>不需要java环境</font>）

```
[root@elk3 opt]# cd /opt && wget https://artifacts.elastic.co/downloads/kibana/kibana-7.17.0-x86_64.rpm

[root@elk3 opt]# yum -y install kibana-7.17.0-x86_64.rpm
```

#### 2.修改配置文件

```
[root@elk3 opt]# cp /etc/kibana/kibana.yml /etc/kibana/kibana.yml.bak
[root@elk3 opt]# vim /etc/kibana/kibana.yml

# 修改配置文件如下，开启以下的配置
[root@elk3 opt]# grep -v "^#\|^$" /etc/kibana/kibana.yml
server.port: 5601
server.host: "192.168.245.172"
server.name: "elk3"
elasticsearch.hosts: ["http://192.168.245.172:9200"]
kibana.index: ".kibana"
i18n.locale: "zh-CN"
```

#### 3.启动服务并设置开机启动

```
[root@elk3 opt]# systemctl  start kibana  && systemctl enable  kibana

[root@elk3 opt]# netstat -auntlp |grep 5601   # 查状态是启动的，但是实际未必这么快，要看到端口出来了才行
```

#### 4.浏览器回到head，会发现多了kibana的索引

![image-20220531100412236](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205311004378.png)

#### 5.浏览器找开页面

浏览器输入http://192.168.245:22:5601/，如下图

![image-20220531100534517](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205311005614.png)

进入UI，如下图

![image-20220531100441111](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205311004225.png)



####  6.实战：搭建nginx，并实现反向代理以及密码验证登录



### 安装LogStash

工作原理：https://zhuanlan.zhihu.com/p/379656230

注意：你需要采集哪台服务器上的日志就在哪台机子上进行安装（<font color='red'>需要java环境</font> ）

上传logstash-7.17.0.rpm包到elk4的/opt目录

#### 1.安装

```
[root@elk4 ~]# cd /opt && wget https://artifacts.elastic.co/downloads/logstash/logstash-7.17.0-x86_64.rpm
[root@elk4 opt]# yum -y install logstash-7.17.0-x86_64.rpm
```

#### 2.添加环境变量

```
[root@elk4 opt]# vim /etc/profile
#set for logstash
export PATH=$PATH:$JAVA_HOME/bin:/usr/share/logstash/bin		
#yum安装elk，主程序一般安在/usr/share下面
```

#### 3.jvm内存调优                

 logstash吃资源严重，可以根据服务器情况合理调配

```
/etc/logstash/jvm.options
改：-Xms1G
   -Xmx1G

为：-Xms512M
   -Xmx512M
```



#### 4.创建logstash的data目录

```
mkdir -p /opt/logstash/data
```

#### 5.修改配置文件

```
vim /etc/logstash/logstash.yml
path.data: /opt/logstash/data
ath.logs: /var/log/logstash
```



#### 4.简单验证

```
[root@elk4 opt]# logstash -e 'input { stdin { } }  output { stdout {} }'

## 等待一段时间启动 Logstash，停留在交互位置
## 输入  hello world 回车，观察返回结果
## 成功如下图

# 注:
# -e 执行操作
# input 标准输入，{ stdin } 插件
# output 标准输出， { stdout } 插件
```

![image-20220530165118190](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205301651268.png)

#### 5.标准输出到elasticsearch中并保存下来

```
[root@elk4 opt]# logstash -e 'input { stdin { } } output { elasticsearch { hosts => ["192.168.245.170:9200"] } stdout { codec => rubydebug }}'

## stdin { } 为空时，需要手动交互输入内容，如果｛｝里有内容，在运行命令时，会自动输入
## 等待进入交互
## 输入hello word

```

![image-20220530165726369](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205301657458.png)

浏览器输入http://192.168.245.170:9100/，查看索引数据会发现成功写入

![image-20220530170137568](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205301701636.png)



#### 6.logstash的插件input与file使用（单机输出）

```
# 本地输入输出
[root@elk4 opt]# vim /etc/logstash/conf.d/systemd.conf
# 添加以下内容
input {
   file {
       path => "/var/log/messages"
       type => "system-log"
       start_position => "beginning"
   }
}
output {
     file {
       path => "/tmp/%{type}.%{+yyyy.MM.dd}"
     }
}


注：需要对收集的日志文件有读权限 chmod 644 
              对写入的文件有写权限 chmod 655
              
# 去到es集群的head页面(port:9100)刷新发现并没有出来，原因是没有权限
[root@elk4 conf.d]# vim /var/log/logstash/logstash-plain.log
# 解决方案
[root@elk4 conf.d]# chmod o+r /var/log/messages
```

```
# 语法检查
[root@elk4 opt]# logstash -f /etc/logstash/conf.d/systemd.conf -t   相当于nginx -t

# 当出现两个ok就行，如下图
```

![image-20220530171222113](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205301712173.png)

```shell
# 启动
# 方法一：		
[root@elk4 opt]# systemctl start logstash   # 虽然可以使用system管理启动（需要添加环境变量），但是会加载/etc/logstash/conf.d/所有配置文件，测试过会出现无法读取配置文件的情况，所以一般采用方法二
注：一定要检测端口是否拉起

# 方法二   #后台启动
[root@elk4 conf.d]# nohup logstash -f /etc/logstash/conf.d/systemd.conf &


# 然后复制会话，一个tail一个输入，如下图

[root@elk4 opt]# tail -f /tmp/system-log.2022.04.07

[root@elk4 opt]# echo "this is test" >> /var/log/messages
```

![image-20220530172025220](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205301720333.png)



#### 7.logstash导入es



##### 1.修改配置文件

```
[root@elk4 opt]# vim /etc/logstash/conf.d/system-log.conf
# 修改如下
input {
   file {
       path => "/var/log/messages"
       type => "system-log"
       start_position => "beginning"
   }
}
output {
     elasticsearch {
       hosts => ["192.168.245.17:9200"]
       index => "%{type}-%{+yyyy.MM.dd}"
     }
}
```

##### 2.检查

```
[root@elk4 conf.d]# logstash -f /etc/logstash/conf.d/system-log.conf -t
```

##### 3.启动

```
# 现在只有一个配置文件，可以system启动
vim /usr/share/logstash/bin/logstash.lib.sh
JAVA_HOME=/usr/java/jdk1.8.0_191		#要对应jdk路径

#生成system启动脚本
/usr/share/logstash/bin/system-install /etc/logstash/startup.options systemd 
[root@elk4 conf.d]# systemctl start logstash
[root@elk4 conf.d]# systemctl status logstash -l 观察其输出信息

# 扫描端口
[root@elk4 conf.d]# netstat -lntp | grep 9600   # 需要等一会，可能查状态是活跃的。但是未必启动这么快
```

##### 4.测试

```
[root@elk4 conf.d]# echo "this is test2" >> /var/log/messages


# 再去到es集群的head页面(port:9100)刷新发现出来了，如下图
```

![image-20220531110524890](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202210091721788.png)

