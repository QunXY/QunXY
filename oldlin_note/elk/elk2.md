## elk2

### 实验环境

实验机器准备：

| 主机名 | IP              | 备注        | 配置  |
| ------ | --------------- | ----------- | ----- |
| elk1   | 192.168.245.170 | es、es-head | 1核1G |
| elk2   | 192.168.245.171 | es          | 1核1G |
| elk3   | 192.168.245.172 | es、kibana  | 1核2G |
| elk4   | 192.168.245.173 | LogStash    | 1核2G |

hosts映射参考elk1



### 1、增加多日志

#### 1.添加secure日志

##### 1.1、错误写法

```
vim /etc/logstash/conf.d/systemd.conf
input {
   file {
       path => "/var/log/messages"
       type => "system-log"
       start_position => "beginning"
   }
   file {
       path => "/var/log/secure"
       type => "secure-log"
       start_position => "beginning"
   }
}
output {											#这是错误写法
     elasticsearch  {
                hosts => ["192.168.245.170:9200"]
                index => "system-log-%{+yyyy.MM.dd}"
     }
     elasticsearch  {
                hosts => ["192.168.245.170:9200"]
                index => "secure-log-%{+yyyy.MM.dd}"
     }

}

```

可以看出，这样的写法可以在es上呈现，但type是只识别到一个

![image-20221010104308732](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202210101043863.png)



##### 1.2、正确的写法

```
# 写法一
[root@elk4 opt]# vim /etc/logstash/conf.d/systemd.conf
input {
   file {
       path => "/var/log/messages"
       type => "system-log"
       start_position => "beginning"
   }
   file {
       path => "/var/log/secure"
       type => "secure-log"
       start_position => "beginning"
   }
}
output {
     elasticsearch {
       hosts => ["192.168.245.170:9200"]
       index => "%{type}-%{+yyyy.MM.dd}"
     }
}


# 写法二
input {
   file {
       path => "/var/log/messages"
       type => "system-log"
       start_position => "beginning"
  }
   file {
       path => "/var/log/secure"
       type => "secure-log"
       start_position => "beginning"
  }
}
output {
     if [type] == "system-log"{
       elasticsearch {
         hosts => ["192.168.75.55:9200"]
         index => "system-log-%{+yyyy.MM.dd}"
     }
  }
     if [type] == "secure-log"{
       elasticsearch {
         hosts => ["192.168.75.55:9200"]
         index => "secure-log-%{+yyyy.MM.dd}"
     }   
  }
}
```

#### 2.修改权限

```
[root@elk4 opt]# chmod o+r /var/log/secure
```

#### 3.重启logstash

```
[root@elk4 conf.d]# systemctl restart logstash
# 如下图
```

![image-20221010111354579](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202210101113678.png)

```
往安全日志输入内容
[root@elk4 ~]# echo this is a good day  >> /var/log/secure
```

在kibana验证：

![image-20221010111519772](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202210101115876.png)



![image-20221010111628936](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202210101116034.png)



结论：logstash能正确区分systemd日志与secure日志



### 2、logstash与nginx相连接

#### 1.安装nginx

```
# nginx主体设置在/usr/local/nginx/
# 具体安装参考之前笔记或者使用脚本
```

#### 2.更改nginx访问日志格式

```
[root@elk4 ~]# cp /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf.bak

[root@elk4 ~]# vim /usr/local/nginx/conf/nginx.conf
# 放在http模块里
# 至于其他优化参考之前笔记
log_format log_json '{"@timestamp": "$time_local", '
                        '"client_ip": "$remote_addr", '
                        '"referer": "$http_referer", '
                        '"request": "$request", '
                        '"status": $status, '
                        '"bytes": $body_bytes_sent, '
                        '"agent": "$http_user_agent", '
                        '"x_forwarded": "$http_x_forwarded_for", '
                        '"up_addr": "$upstream_addr",'
                        '"up_host": "$upstream_http_host",'
                        '"up_resp_time": "$upstream_response_time",'
                        '"request_time": "$request_time"'
                        ' }';
access_log  logs/access.log  log_json;

# 重新加载
[root@elk4 ~]# nginx -s reload

# 查看访问日志
[root@elk4 ~]# vim /usr/local/nginx/logs/access.log

# 在与logstash建立连接就会发现这个会变成一大块；但是后期修改一个参数即可解决
```

#### 3.与logstash建立采集连接

```
[root@elk4 conf.d]# vim /etc/logstash/conf.d/nginx-access.conf
# 添加以下内容
input {
    file { 
      path => "/usr/local/nginx/logs/access.log"
      type => "nginx-access"
      start_position => "beginning"
    }
}
output {
     elasticsearch {
       hosts => ["192.168.245.170:9200"]
       index => "%{type}-%{+yyyy.MM.dd}"
     }
}


# 检查权限
[root@elk4 conf.d]# ll /usr/local/nginx/logs/access.log


# 语法检查
[root@elk4 conf.d]# logstash -f /etc/logstash/conf.d/nginx-access.conf -t
```

#### 4.重启logstash

```
[root@elk4 conf.d]# systemctl restart logstash   # 全部加载，保留系统日志也保留access

# 去到es集群的head页面(port:9100)刷新发现出来了，如下图
```

![image-20220531152302964](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205311523041.png)

#### 5.kibana查看索引

问题：去到http://192.168.245.22:5601/创建索引查看会发现JSON套JSON，并不是我们想要的结果，如下图

![image-20220531162631594](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205311626667.png)

#### 解决方案：

```
# 往配置项里面添加一句
[root@elk4 conf.d]# vim /etc/logstash/conf.d/nginx-access.conf
input {
    file {
      path => "/usr/local/nginx/logs/access.log"
      type => "nginx-access"
      start_position => "beginning"
      codec => "json"     # 解析为JSON格式
    }
}
output {
     elasticsearch {
       hosts => ["192.168.245.170:9200"]
       index => "%{type}-%{+yyyy.MM.dd}"
     }
}


# 重启
[root@elk4 conf.d]# systemctl restart logstash

# 此时再回kibana查看，在创建索引哪里选择更新字段再回到首页查看，问题解决，如下图
```

![](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202210082307051.png)





### 3、logstash与java类日志相连接

需要使用codec插件里的多行编码器multiline

测试一下

```
input {
      stdin {
        codec => multiline {
          pattern => "pattern, a regexp"
          negate => "true" or "false"
          what => "previous" or "next"
        }
      }
    }
output {
        stdout{
                codec => "rubydebug"

        }
}
[root@elk4 conf.d]# logstash -f java.conf
在命令行交互输入，识别到以数字开头的打印上一行，如果不是以数字开头的就叠加为一个事件
```

![image-20221010143933723](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202210101439786.png)

修改配置文件，导入es

```
input {
      file {
        path => "/opt/catalina.out"
        type => "java-log"
        start_position => "beginning"
        codec => multiline {
          pattern => "^[0-9]"
          negate => "true"
          what => "previous"
        }
      }
    }
output {
     elasticsearch  {
                hosts => ["192.168.245.170:9200"]
                index => "%{type}-%{+yyyy.MM.dd}"
                }
}
结果如下：
```



![image-20221010144907892](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202210101449006.png)







### 4、logstash与tomcat相连接

#### 1.安装tomcat

```
# tomcat主体设置在/usr/local/tomcat/
# 具体安装参考之前笔记或者使用脚本
```

#### 2.更改tomcat日志格式

```
[root@elk4 bin]# vim /usr/local/tomcat/conf/server.xml
# 拉到最后注释掉原来，采用更改的格式
# 原格式如下图
```

![image-20220531162153040](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205311621082.png)

注释掉

![image-20220531162216694](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205311622737.png)



```shell
# 更改样式
<Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
               prefix="tomcat_access_log" suffix=".log"
               pattern="{&quot;clientip&quot;:&quot;%h&quot;,&quot;ClientUser&quot;:&quot;%l&quot;,&quot;authenticated&quot;:&quot;%u&quot;,&quot;AccessTime&quot;:&quot;%t&quot;,&quot;method&quot;:&quot;%r&quot;,&quot;status&quot;:&quot;%s&quot;,&quot;SendBytes&quot;:&quot;%b&quot;,&quot;Query?string&quot;:&quot;%q&quot;,&quot;partner&quot;:&quot;%{Referer}i&quot;,&quot;AgentVersion&quot;:&quot;%{User-Agent}i&quot;}"/>
```

#### 3.重启tomcat

```
[root@elk4 bin]# /usr/local/tomcat/bin/catalina.sh stop
Using CATALINA_BASE:   /usr/local/tomcat
Using CATALINA_HOME:   /usr/local/tomcat
Using CATALINA_TMPDIR: /usr/local/tomcat/temp
Using JRE_HOME:        /usr
Using CLASSPATH:       /usr/local/tomcat/bin/bootstrap.jar:/usr/local/tomcat/bin/tomcat-juli.jar
[root@elk4 bin]# /usr/local/tomcat/bin/catalina.sh start
Using CATALINA_BASE:   /usr/local/tomcat
Using CATALINA_HOME:   /usr/local/tomcat
Using CATALINA_TMPDIR: /usr/local/tomcat/temp
Using JRE_HOME:        /usr
Using CLASSPATH:       /usr/local/tomcat/bin/bootstrap.jar:/usr/local/tomcat/bin/tomcat-juli.jar
Tomcat started.

# 查看日志是否转换
[root@elk4 bin]# vim /usr/local/tomcat/logs/tomcat_access_log.2022-04-09.log
```

#### 4.与logstash建立采集连接

```
# 更改文件名
[root@elk4 ~]# mv /etc/logstash/conf.d/nginx-access.conf /etc/logstash/conf.d/access.conf

# 添加读取Tomcat访问日志配置
[root@elk4 ~]# vim /etc/logstash/conf.d/access.conf
input {
    file {
      path => "/usr/local/nginx/logs/access.log"
      type => "nginx-access"
      start_position => "beginning"
      codec => "json"
    }
    file {
      path => "/usr/local/tomcat/logs/tomcat_access_log.*.log"
      start_position => "beginning"
      type => "tomcat-access"
      codec => "json"   # 如果不加这项，也会出现和nginx一样的问题，JSON套JSON
    }
}
output {
     elasticsearch {
       hosts => ["192.168.245.170:9200"]
       index => "%{type}-%{+yyyy.MM.dd}"
     }
}
```

#### 5.修改tomcat日志文件夹权限

```
[root@elk4 logs]# chmod 777 -R /usr/local/tomcat/logs/
# o+r都不行，要777才行			#7.17版本暂不需要
```

#### 6.重启logstash

```
[root@elk4 ~]# systemctl restart logstash

# 去到es集群的head页面(port:9100)刷新发现出来了，如下图
```

![image-20220531162105085](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205311621166.png)

![image-20221010151947962](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202210101519123.png)



### 5、logstash与rsyslog相连接

```
 记得开启rsyslog端口
 [root@elk4 ~]# vim /etc/rsyslog.conf   #在90行之后，插入
 *.*  @@192.168.245.173:514
 [root@elk4 tomcat]# systemctl restart rsyslog
```

修改配置文件

```
input {
  syslog {
    host => "192.168.245.173"
    port => "514"
    type => "rsyslog"
  }
}

output {
     elasticsearch  {
                hosts => ["192.168.245.170:9200"]
                index => "%{type}-%{+yyyy.MM.dd}"
                }
}
```

![image-20221010154336229](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202210101543338.png)



### 6、logstash与tcp相连接

nc命令详解https://blog.csdn.net/mr_wanter/article/details/125076995

```
安装nc命令
[root@elk4 opt]# yum install -y nc
```

修改配置文件

```
vim tcp.conf
input {
  tcp {
    host => "192.168.245.173"
    port => "666"
    type => "tcp-log"
  }
}

output {
        stdout {
                codec => "rubydebug"
        }
#     elasticsearch  {
#                hosts => ["192.168.245.170:9200"]
#                index => "%{type}-%{+yyyy.MM.dd}"
#                }

}
[root@elk4 conf.d]# logstash -f tcp.conf

在另一终端模拟输入命令：
[root@elk4 opt]# echo haha |nc 192.168.245.173 666
[root@elk4 opt]# echo 123456 |nc 192.168.245.173 666
结果如下：
```

![image-20221010155540207](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202210101555267.png)



![image-20221010155827114](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202210101558201.png)





## 3 Logstash编码插件(Codec)

其实我们就已经用过编码插件codec了，也就是这个rubydebug，它就是一种codec，虽然它一般只会用在stdout插件中，作为配置测试或者调试的工具。

编码插件(Codec)可以在logstash输入或输出时处理不同类型的数据，因此，Logstash不只是一个input-->filter-->output的数据流，而是一个input-->decode-->filter-->encode-->output的数据流。



```
    Codec支持的编码格式常见的有plain、json、json_lines等。
```

### 3.1 codec插件之plain

plain是一个空的解析器，它可以让用户自己指定格式，也就是说输入是什么格式，输出就是什么格式。下面是一个包含plain编码的事件配置文件：



```
input{
    stdin{}
}
output{
    stdout{
        codec => "plain"
	}
}
```

### 3.2 codec插件之json、json_lines

如果发送给logstash的数据内容为json格式,可以在input字段加入codec=>json来进行解析，这样就可以根据具体内容生成字段，方便分析和储存。如果想让logstash输出为json格式，可以在output字段加入codec=>json，下面是一个包含json编码的事件配置文件：



```
input {
    stdin {}
    }
output {
    stdout {
        codec => json
        }
}
```

这就是json格式的输出，可以看出，json每个字段是key:values格式，多个字段之间通过逗号分隔。有时候，如果json文件比较长，需要换行的话，那么就要用json_lines编码格式了。

## 4 Logstash过滤器插件(Filter)

### 4.1 Grok 正则捕获

grok是一个十分强大的logstash filter插件，他可以通过正则解析任意文本，将非结构化日志数据弄成结构化和方便查询的结构。他是目前logstash 中解析非结构化日志数据最好的方式。

Grok 的语法规则是：



```
	%{语法: 语义}
```

“语法”指的就是匹配的模式，例如使用NUMBER模式可以匹配出数字，IP模式则会匹配出127.0.0.1这样的IP地址：

例如输入的内容为：



```
192.168.50.21 [08/Oct/2021:23:24:19 +0800] "GET / HTTP/1.1" 403 5039
```

那么，%{IP:clientip}匹配模式将获得的结果为：



```
clientip: 192.168.50.21
```

%{HTTPDATE:timestamp}匹配模式将获得的结果为：



```
timestamp: 08/Oct/2021:23:24:19 +0800
```

而%{QS:referrer}匹配模式将获得的结果为：



```
referrer: "GET / HTTP/1.1"
```

下面是一个组合匹配模式，它可以获取上面输入的所有内容：



```
%{IP:clientip}\ \[%{HTTPDATE:timestamp}\]\ %{QS:referrer}\ %{NUMBER:response}\ %{NUMBER:bytes}	
```

通过上面这个组合匹配模式，我们将输入的内容分成了五个部分，即五个字段，将输入内容分割为不同的数据字段，这对于日后解析和查询日志数据非常有用，这正是使用grok的目的。

Logstash默认提供了近200个匹配模式（其实就是定义好的正则表达式）让我们来使用，可以在logstash安装目录下，例如这里是/usr/local/logstash/vendor/bundle/jruby/1.9/gems/logstash-patterns-core-4.1.2/patterns目录里面查看，基本定义在grok-patterns文件中。

从这些定义好的匹配模式中，可以查到上面使用的四个匹配模式对应的定义规则

| 匹配模式 | 正则定义规则                                |
| :------- | :------------------------------------------ |
| NUMBER   | (?:%{BASE10NUM})                            |
| HTTPDATE | %{MONTHDAY}/%{MONTH}/%{YEAR}:%{TIME} %{INT} |
| IP       | (?:%{IPV6}\|%{IPV4})                        |
| QS       | %{QUOTEDSTRING}                             |

示例：



```
input{
    stdin{}
}
filter{
    grok{
        match => ["message","%{IP:clientip}\ \[%{HTTPDATE:timestamp}\]\ %{QS:referrer}\ %{NUMBER:response}\ %{NUMBER:bytes}"]
    }
}
output{
    stdout{
        codec => "rubydebug"
    }
}
```

输入内容：



```
192.168.50.21 [08/Oct/2021:23:24:19 +0800] "GET / HTTP/1.1" 403 5039
```

### 4.2 时间处理(Date)

date插件是对于排序事件和回填旧数据尤其重要，它可以用来转换日志记录中的时间字段，变成LogStash::Timestamp对象，然后转存到@timestamp字段里，这在之前已经做过简单的介绍。

下面是date插件的一个配置示例：



```
input{
    stdin{}
}
filter {
    grok {
        match => ["message", "%{HTTPDATE:timestamp}"]
    }
    date {
        match => ["timestamp", "dd/MMM/yyyy:HH:mm:ss Z"]
    }
}
output{
    stdout{
        codec => "rubydebug"
    }
}
```

| 时间字段 | 字母 | 表示含义                                             |
| :------- | :--- | :--------------------------------------------------- |
| **年**   | yyyy | 表示全年号码。 例如：2021                            |
| **年**   | yy   | 表示两位数年份。 例如：2021年即为21                  |
| **月**   | M    | 表示1位数字月份，例如：1月份为数字1，12月份为数字12  |
| **月**   | MM   | 表示两位数月份，例如：1月份为数字01，12月份为数字12  |
| **月**   | MMM  | 表示缩短的月份文本，例如：1月份为Jan，12月份为Dec    |
| **月**   | MMMM | 表示全月文本，例如：1月份为January，12月份为December |
| **日**   | d    | 表示1位数字的几号，例如8表示某月8号                  |
| **日**   | dd   | 表示2位数字的几号，例如08表示某月8号                 |
| **时**   | H    | 表示1位数字的小时，例如1表示凌晨1点                  |
| **时**   | HH   | 表示2位数字的小时，例如01表示凌晨1点                 |
| **分**   | m    | 表示1位数字的分钟，例如5表示某点5分                  |
| **分**   | mm   | 表示2位数字的分钟，例如05表示某点5分                 |
| **秒**   | s    | 表示1位数字的秒，例如6表示某点某分6秒                |
| **秒**   | ss   | 表示2位数字的秒，例如06表示某点某分6秒               |
| **时区** | Z    | 表示时区偏移，结构为HHmm，例如：+0800                |
| **时区** | ZZ   | 表示时区偏移，结构为HH:mm，例如：+08:00              |
| **时区** | ZZZ  | 表示时区身份，例如Asia/Shanghai                      |

### 4.3 数据修改(Mutate)

1）正则表达式替换匹配字段

gsub可以通过正则表达式替换字段中匹配到的值，只对字符串字段有效，下面是一个关于mutate插件中gsub的示例（仅列出filter部分）：



```
filter {
    mutate {
        gsub => ["filed_name_1", "/" , "_"]
    }
}
```

这个示例表示将filed_name_1字段中所有"/"字符替换为"_"。

2）分隔符分割字符串为数组

split可以通过指定的分隔符分割字段中的字符串为数组，下面是一个关于mutate插件中split的示例（仅列出filter部分）：



```
filter {
    mutate {
        split => ["filed_name_2", "|"]
    }
}
```

这个示例表示将filed_name_2字段以"|"为区间分隔为数组。

3）重命名字段

rename可以实现重命名某个字段的功能，下面是一个关于mutate插件中rename的示例（仅列出filter部分）：



```
filter {
    mutate {
        rename => { "old_field" => "new_field" }
    }
}
```

这个示例表示将字段old_field重命名为new_field。

4）删除字段

remove_field可以实现删除某个字段的功能，下面是一个关于mutate插件中remove_field的示例（仅列出filter部分）：



```
filter {
    mutate {
        remove_field  =>  ["timestamp"]
    }
}
```

这个示例表示将字段timestamp删除。

5）综合示例



```
input {
    stdin {}
}
filter {
    grok {
        match => { "message" => "%{IP:clientip}\ \[%{HTTPDATE:timestamp}\]\ %{QS:referrer}\ %{NUMBER:response}\ %{NUMBER:bytes}" }
        remove_field => [ "message" ]
   }
date {
        match => ["timestamp", "dd/MMM/yyyy:HH:mm:ss Z"]
    }
mutate {
           rename => { "response" => "response_new" }
           convert => [ "response","float" ]
           gsub => ["referrer","\"",""]
           remove_field => ["timestamp"]
           split => ["clientip", "."]
        }
}
output {
    stdout {
        codec => "rubydebug"
    }
}
```

### 4.4 GeoIP 地址查询归类

GeoIP是最常见的免费IP地址归类查询库，当然也有收费版可以使用。GeoIP库可以根据IP 地址提供对应的地域信息，包括国别，省市，经纬度等，此插件对于可视化地图和区域统计非常有用。

下面是一个关于GeoIP插件的简单示例（仅列出filter部分）：



```
filter {
    geoip {
        source => "ip_field"
    }
}
```

其中，ip_field字段是输出IP地址的一个字段。

### 4.5 filter插件综合应用实例

下面给出一个业务系统输出的日志格式，由于业务系统输出的日志格式无法更改，因此就需要我们通过logstash的filter过滤功能以及grok插件来获取需要的数据格式，此业务系统输出的日志内容以及原始格式如下：



```
2021-10-09T0:57:42+08:00|~|123.87.240.97|~|Mozilla/5.0 (iPhone; CPU iPhone OS 11_2_2 like Mac OS X) AppleWebKit/604.4.7 Version/11.0 Mobile/15C202 Safari/604.1|~|http://m.sina.cn/cm/ads_ck_wap.html|~|1460709836200|~|DF0184266887D0E
```

可以看出，这段日志都是以“|~|”为区间进行分隔的，那么刚好我们就以“|~|”为区间分隔符，将这段日志内容分割为6个字段。这里通过grok插件进行正则匹配组合就能完成这个功能。

完整的grok正则匹配组合语句如下：



```
%{TIMESTAMP_ISO8601:localtime}\|\~\|%{IPORHOST:clientip}\|\~\|(%{GREEDYDATA:http_user_agent})\|\~\|(%{DATA:http_ref
```
