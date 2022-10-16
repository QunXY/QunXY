# 2022-09-21

# 1，keepalived+nginx/haproxy功能脚本

## keepalived+nginx:

```sh
Keepalived () {
ifconfig > /opt/address.txt
loope=`cat -n /opt/address.txt | grep BROADCAST |egrep "ens|eth" | wc -l`
for (( i=1;i<=$loope;i++ ))
do
	line=`cat -n /opt/address.txt | grep BROADCAST |egrep "ens|eth" | awk -F "[\t]+" '{print $1}' | sed -n "$i"p`
	sed -n "$line,$[$line+1]p" /opt/address.txt
done
read -p "请选择作为keepalived所复刻的虚拟网卡：" NC
Getline=`cat -n /opt/address.txt | grep -w $NC | awk -F "[\t]+" '{print $1}'`
NCIP=`sed -n "$Getline,$[$Getline+1]p" /opt/address.txt | grep -w broadcast | awk -F "[ ]+" '{print $3}'`
NCIPTAIL=`sed -n "$Getline,$[$Getline+1]p" /opt/address.txt | grep -w broadcast | awk -F "[. ]+" '{print $6}'`
VNCIP=`echo $NCIP | awk -F "$NCIPTAIL" '{print $1}'`233
rm -rf /opt/address.txt
read -p "请输入作为keepalived备机的IP：" SIP
read -p "请输入作为keepalived备机的IP：" SPW

####免密以便后续操作####
yum install -y expect
if [ -f /root/.ssh/id_rsa.pub ]
then
        echo "公钥存在，现在发送给keepalived备用机。"
expect <<-EOF
spawn ssh-copy-id root@$SIP
expect "yes/no"
send "yes\r"
expect "password:"
send "$SPW\r"
expect eof
EOF
else
        echo "公钥不存在，现在创建并发送给keepalived备用机。"
ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
expect <<-EOF
spawn ssh-copy-id root@$SIP
expect "yes/no"
send "yes\r"
expect "password:"
send "$SPW\r"
expect eof
EOF
fi

####下载keepalived，并配置主备####
systemctl stop firewalld
yum install -y keepalived
cat > /etc/keepalived/keepalived.conf << EOF
vrrp_script check_web {
   script "/etc/keepalived/check_web.sh"
   interval 5
}

vrrp_instance VI_1 {
    state MASTER
    interface $NC
    virtual_router_id 50
    priority 150
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        $VNCIP
    }
    
    track_script {
        check_web
    }
}
EOF

####编写启动脚本#####
cat > /etc/keepalived/check_web.sh << 'EOF'
#!/bin/bash
nginxpid=$(ps -C nginx --no-header|wc -l)
if [ $nginxpid -eq 0 ];then
	nginx
	sleep 3
	nginxpid=$(ps -C nginx --no-header|wc -l) 
	if [ $nginxpid -eq 0 ];then
		systemctl stop keepalived
	fi
fi
EOF
chmod +x /etc/keepalived/check_web.sh
systemctl enable keepalived
systemctl start keepalived

####配置备机的keepalived####
ssh -t root@$SIP << EOF
yum install -y keepalived
EOF
scp /etc/keepalived/keepalived.conf root@$SIP:/etc/keepalived/
scp /etc/keepalived/check_web.sh root@$SIP:/etc/keepalived/
ssh -t root@$SIP <<EOF
sed -i 's/state MASTER/state BACKUP/g' /etc/keepalived/keepalived.conf
sed -i 's/priority 150/priority 100/g' /etc/keepalived/keepalived.conf
chmod +x /etc/keepalived/check_web.sh
systemctl enable keepalived
systemctl start keepalived
EOF

}
```

## keepalived+HAProxy:

```shell
Keepalived () {
ifconfig > /opt/address.txt
loope=`cat -n /opt/address.txt | grep BROADCAST |egrep "ens|eth" | wc -l`
for (( i=1;i<=$loope;i++ ))
do
	line=`cat -n /opt/address.txt | grep BROADCAST |egrep "ens|eth" | awk -F "[\t]+" '{print $1}' | sed -n "$i"p`
	sed -n "$line,$[$line+1]p" /opt/address.txt
done
read -p "请选择作为keepalived所复刻的虚拟网卡：" NC
Getline=`cat -n /opt/address.txt | grep -w $NC | awk -F "[\t]+" '{print $1}'`
NCIP=`sed -n "$Getline,$[$Getline+1]p" /opt/address.txt | grep -w broadcast | awk -F "[ ]+" '{print $3}'`
NCIPTAIL=`sed -n "$Getline,$[$Getline+1]p" /opt/address.txt | grep -w broadcast | awk -F "[. ]+" '{print $6}'`
VNCIP=`echo $NCIP | awk -F "$NCIPTAIL" '{print $1}'`233
rm -rf /opt/address.txt
read -p "请输入作为keepalived备机的IP：" SIP
read -p "请输入作为keepalived备机的IP：" SPW

####免密以便后续操作####
yum install -y expect
if [ -f /root/.ssh/id_rsa.pub ]
then
        echo "公钥存在，现在发送给keepalived备用机。"
expect <<-EOF
spawn ssh-copy-id root@$SIP
expect "yes/no"
send "yes\r"
expect "password:"
send "$SPW\r"
expect eof
EOF
else
        echo "公钥不存在，现在创建并发送给keepalived备用机。"
ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
expect <<-EOF
spawn ssh-copy-id root@$SIP
expect "yes/no"
send "yes\r"
expect "password:"
send "$SPW\r"
expect eof
EOF
fi

####下载keepalived，并配置主备####
systemctl stop firewalld
yum install -y keepalived
cat > /etc/keepalived/keepalived.conf << EOF
vrrp_script check_haproxy {
   script "/etc/keepalived/check_haproxy.sh"
   interval 5
}

vrrp_instance VI_1 {
    state MASTER
    interface $NC
    virtual_router_id 50
    priority 150
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        $VNCIP
    }
    
    track_script {
        check_haproxy
    }
}
EOF

####编写启动脚本#####
cat > /etc/keepalived/check_haproxy.sh << 'EOF'
#!/bin/bash
LOGFILE="/var/log/keepalived-haproxy-state.log"
date >> $LOGFILE
A=`ps -C haproxy --no-header | wc -l`
if [ $A -eq 0 ];then
echo "fail: check_haproxy status" >> $LOGFILE
echo "Try to start haproxy service" >> $LOGFILE
  systemctl start haproxy
  sleep 2
  if [ `ps -C haproxy --no-header | wc -l` -eq 0 ];then
echo "Can not start haproxy service, so will stop keepalived service" >> $LOGFILE
        killall keepalived
fi
else
echo "success: check_haproxy status" >> $LOGFILE
fi
EOF
chmod +x /etc/keepalived/check_haproxy.sh
systemctl enable keepalived
systemctl start keepalived

####配置备机的keepalived####
ssh -t root@$SIP << EOF
yum install -y keepalived
EOF
scp /etc/keepalived/keepalived.conf root@$SIP:/etc/keepalived/
scp /etc/keepalived/check_haproxy.sh root@$SIP:/etc/keepalived/
ssh -t root@$SIP <<EOF
sed -i 's/state MASTER/state BACKUP/g' /etc/keepalived/keepalived.conf
sed -i 's/priority 150/priority 100/g' /etc/keepalived/keepalived.conf
chmod +x /etc/keepalived/check_haproxy.sh
systemctl enable keepalived
systemctl start keepalived
EOF

}
```

# 2，maven环境搭建更换maven源到阿里,elk练习别忘了（不会的看官网）

Maven是一个项目管理工具，它包含了一个项目对象模型（POM：Project Object Model），一组标准集合，一个项目生命周期（Project LifeCycle），一个依赖管理系统（Dependency managerment System），和用来运行定义在生命周期（phase）中插件（plugin）目标（goal）的逻辑。

 Maven有一个生命周期，当你运行mvn install的时候被调用。这条命令告诉Maven执行一系列的有序的步骤，直到到达你指定的生命周期。遍历生命周期旅途中的一个影响就是，Maven 运行了许多默认的插件目标，这些目标完成了像编译和创建一个JAR文件这样的工作。 此外，Maven能够很方便的帮你管理项目报告，生成站点，管理JAR文件，等等。

## maven环境搭建:

#### 一、安装Maven

安装前要看好所需的**Java**版本

这里我使用的**Java8**

![image-20220924200637980](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242006033.png)

![image-20220924195649222](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209241956406.png)

```shell
[root@home2 src]# wget https://dlcdn.apache.org/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz --no-check-certificate																#我下了最新版
[root@home2 src]# tar -xvf apache-maven-3.8.6-bin.tar.gz
[root@home2 src]# mv apache-maven-3.8.6 /usr/local/maven
[root@home2 src]# cat >> /etc/profile << 'EOF'
MAVEN_HOME=/usr/local/maven
export PATH=${MAVEN_HOME}/bin:${PATH}
EOF
[root@home2 src]# source /etc/profile
[root@home2 src]# mvn -v
Apache Maven 3.8.6 (84538c9988a25aec085021c365c560670ad80f63)
Maven home: /usr/local/maven
Java version: 1.8.0_151, vendor: Oracle Corporation, runtime: /usr/java/jdk1.8.0_151/jre
Default locale: zh_CN, platform encoding: UTF-8
OS name: "linux", version: "3.10.0-693.el7.x86_64", arch: "amd64", family: "unix"
```

#### 二、配置Maven

```shell
[root@home2 src]# vim /usr/local/maven/conf/settings.xml 
#配置本地仓库：
<!--localRepository
   | The path to the local repository maven will use to store artifacts.
   |
   | Default: ${user.home}/.m2/repository-->
  <localRepository>/usr/local/maven/repo</localRepository>
 #配置镜象：
  <mirror>
      <id>nexus-aliyun</id>
      <mirrorOf>central</mirrorOf>
      <name>Nexus aliyun</name>
      <url>http://maven.aliyun.com/nexus/content/groups/public</url>
    </mirror>
  </mirrors>
```

#### 三、创建helloworld项目

```sh
[root@home2 src]# mvn archetype:generate -DgroupId=helloworld -DartifactId=helloworld
```

![image-20220924204735954](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242047291.png)

```
直接回车
```

![image-20220924205127050](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242051393.png)

```
回车
```

**最后会生成你输入的项目信息，我这里全部回车所以是默认我刚刚执行命令的参数。**

![image-20220924205338084](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242053180.png)

![image-20220924205442490](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242054700.png)

项目创建成功！

```shell
[root@home2 src]# vim /usr/local/src/helloworld/pom.xml 					#根据它给的目录找到我们的pom.xml文件
```

![image-20220924205801456](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242058823.png)

在pom.xml文件中，首先描述了项目的定义，groupId:artifactId:packaging:version这个四元组能够唯一标记一个项目。我们不仅可以用这个四元组来标记我们的项目，也可以用来标记其它的项目，比如用来描述项目依赖关系。perperties中定义了项目的属性，也可以在这里定义变量并在其它的地方引用。至于最后的dependencies，则是描述了项目的依赖关系，Maven会根据依赖关系自动下载相应的文件并在编译时使用。

在大型项目开发中，往往会将其分成若干个子项目，每个子项目都有着自己的的pom.xml，它们与父pom.xml之间相当于继承的关系。
可以说，pom.xml文件的配置是整个Maven的核心重点，也是学习Maven过程中需要详细了解的内容。这里只给出了最简单的配置样例，详细了解可以查看官方文档。
接下来编译并运行Helloworld项目。
如果是第一次编译的话，需要联网，因为Maven会自动下载依赖包。

```shell
[root@home2 src]# cd /usr/local/src/helloworld
[root@home2 helloworld]# mvn install										#在项目目录下执行
```

![image-20220924210252150](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242102502.png)

用mvn install命令将一个项目安装到本地仓库。

![](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242105542.png)

打包成功后我们会发现项目中多了一个target文件夹，目录结构如下

![image-20220924210530311](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242105402.png)

可以看到，在package过程中，maven完成了**编译**、**测试代码**，**生成测试报告**，**生成jar包**等一系列工作。

**手动执行项目**

```shell
[root@home2 helloworld]# java -cp target/helloworld-1.0-SNAPSHOT.jar helloworld.App
```

![image-20220924210735496](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242107563.png)



## elk练习：

**前提：nginx必须设置json格式日志！**

#### 1.Elasticsearch+Logstash+Kibana:

**Logstash配置**

```yaml
input {
  file {
   path => "/var/log/messages"
   type => "system"
   start_position => "beginning"
  }
  file {
   path => "/var/log/nginx/accessjson.log"
   type => "nginx"
   start_position => "beginning"
  }
  file {
   path => "/usr/local/tomcat/logs/tomcat_access_log.*.txt"
   type => "tomcat"
   start_position => "beginning"
  }
}
filter {
 grok {
   match => {"message" => "%{IPV4:client_ip}"}
  }
}
output {
  if [type] == "system"{
     elasticsearch {
       hosts => ["192.168.159.137:9200","192.168.159.138:9200","192.168.159.139:9200"]
       index => "system-%{+yyyy.MM.dd}"
    }
  }
  if [type] == "nginx"{
     elasticsearch {
       hosts => ["192.168.159.137:9200","192.168.159.138:9200","192.168.159.139:9200"]
       index => "nginx-%{+yyyy.MM.dd}"
       }
  }
  if [type] == "tomcat"{
     elasticsearch {
       hosts => ["192.168.159.137:9200","192.168.159.138:9200","192.168.159.139:9200"]
       index => "tomcat-%{+yyyy.MM.dd}"
       }
  }
}
```

**启动：**

```shell
[root@home3 ~]# logstash -f /etc/logstash/conf.d/elk.conf
[INFO ] 2022-09-24 21:48:42.643 [Api Webserver] agent - Successfully started Logstash API endpoint {:port=>9600}
```

**kibana创建索引：**

![image-20220924215056830](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242151323.png)![](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242151193.png)![image-20220924215201588](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242152636.png)

**连接tomcat和nginx的web服务器并刷新产生日志，到kibana上查看**

**tomcat日志：**

![image-20220924215707553](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242157802.png)

**nginx日志：**

![image-20220924215802425](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242158561.png)

**system日志：**

![image-20220924215900108](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242159210.png)



#### 2.Elasticsearch+Filebeat+Kibana:

**Filebeat配置：**

```yaml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/nginx/accessjson.log
  fields:
    type: web
  fields_under_root: true
  tags: ["web"]
- type: log
  enabled: true
  paths:
    - /var/log/messages
  fields:
    type: system-log
  fields_under_root: true
  tags: ["system-log"]
output.elasticsearch:
  hosts: ["192.168.159.137:9200","192.168.159.138:9200","192.168.159.139:9200"]
  indices:
   - index: "system-log-%{+yyyy.MM.dd}"
     when.contains:
       tags: "system-log"
  indices:
   - index: "web-log-%{+yyyy.MM.dd}"
     when.contains:
       tags: "web"
       
[root@home3 ~]# systemctl restart filebeat					#重启
```

**kibana创建索引**

![image-20220924221345779](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242228631.png)![](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242228598.png)

**kibana查看：**

**system-log日志：**![image-20220924221628461](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242216573.png)

**web-log日志：**

![image-20220924222924654](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242229797.png)



#### 3.Elasticsearch+Filebeat+Logstash+Kibana:

**Filebeat配置：**

```yaml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/nginx/accessjson.log
  fields:
    type: web
  fields_under_root: true
  tags: ["web"]
- type: log
  enabled: true
  paths:
    - /var/log/messages
  fields:
    type: system-log
  fields_under_root: true
  tags: ["system-log"]
output.logstash:
  hosts: ["192.168.159.138:5044"]
[root@home3 ~]# systemctl restart filebeat
```

**Logstash配置：**

```yaml
input {
  beats {
    port => 5044
  }
}
filter {
 grok {
   match => {"message" => "%{IPV4:client_ip}"}
  }
}
output {
  if [type] == "web"{
     elasticsearch {
       hosts => ["192.168.159.137:9200","192.168.159.138:9200","192.168.159.139:9200"]
       index => "nginx-filebeat-%{+yyyy.MM.dd}"
    }
  }
  if [type] == "system-log"{
     elasticsearch {
       hosts => ["192.168.159.137:9200","192.168.159.138:9200","192.168.159.139:9200"]
       index => "system-filebeat-%{+yyyy.MM.dd}"
       }
  }
}
[root@home3 conf.d]# logstash -f /etc/logstash/conf.d/elk.conf
```

**kibana上创建索引并查看日志：**

![image-20220924235613834](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242356903.png)![image-20220924235640980](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242356022.png)

**system-fiebeat日志：**

![image-20220924235714892](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242357029.png)

**nginx-filebeat日志：**

![image-20220924235751193](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242357302.png)



#### 4.Elasticsearch+Filebeat+Logstash+Redis+Kibana:

**Filebeat配置：**

```yaml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/nginx/accessjson.log
  fields:
    type: web
  fields_under_root: true
  tags: ["web"]
- type: log
  enabled: true
  paths:
    - /var/log/messages
  fields:
    type: system-log
  fields_under_root: true
  tags: ["system-log"]
output.redis:
  hosts: ["192.168.159.138"]
  password: "123456"
  data_type: "list"
  keys:
    - key: "nginx-redis"
      when.contains:
        tags: "web"
    - key: "system-redis"
      when.contains:
        tags: "system-log"
  db: 0
  timeout: 5
[root@home3 ~]# systemctl restart filebeat									#重启
```

**为开启Logstash前：**

![image-20220924233826954](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242338997.png)

可以看到key已经存入redis中，但是开启Logstash的瞬间key会消失，因为我们存入的方式是**队列消息**（如publish 订阅）。获取到key的信息后会关闭订阅，所以并不是真正意义上的存入redis，而只是将数据过渡到Logstash再存入Elasticsearch中。

**Logstash配置：**

```shell
input {
  redis {
    host => "192.168.159.138"
    port => "6379"
    db => "0"
    password => "123456"
    key => "nginx-redis"
    data_type => "list"
  }
  redis {
    host => "192.168.159.138"
    port => "6379"
    db => "0"
    password => "123456"
    key => "system-redis"
    data_type => "list"
  }
}
output {
  if [type] == "web"{
     elasticsearch {
       hosts => ["192.168.159.137:9200","192.168.159.138:9200","192.168.159.139:9200"]
       index => "nginx-redis-%{+yyyy.MM.dd}"
    }
  }
  if [type] == "system-log"{
     elasticsearch {
       hosts => ["192.168.159.137:9200","192.168.159.138:9200","192.168.159.139:9200"]
       index => "system-redis-%{+yyyy.MM.dd}"
       }
  }
}
```

**kibana上创建索引并查看日志：**

![image-20220924234006507](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242340559.png)![image-20220924234101940](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242341984.png)

**nginx-redis日志：**

![image-20220924234127734](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242341844.png)

**system-redis日志：**

![image-20220924234139246](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209242341345.png)



# 3，sonarqube部署(部署作业)。研究（代码审计平台）

## 一、SonarQube

**SonarQube**是一个用于管理代码质量的开放平台，可以快速的定位代码中潜在的或者明显的错误。目前支持**java,C#,C/C++,Python,PL/SQL,Cobol,JavaScrip,Groovy**等二十几种编程语言的代码质量管理与检测。

### SonarQube特性

#### 持续检查

- 项目整体的健康程度

   项目的主页面会给出，项目整体的Bugs、Vulnerabilities、Code Smells

- 专注于漏洞
   water-leak-paradigm可以有效的管理代码质量：新特性，增加的，改变的
   （water-leak-paradigm是sonarqube研究的一种代码管理方法）
   在项目监测报告中，需要密切关注：New Bugs、New  Vulnerabilities

- 实施质量阈值
   在团队项目中，可以设置质量阈值（Quality Gate），用于监管质量

- 分支分析
   确保干净的代码才会被合并到主分支中

#### 七个维度检测代码质量

- 复杂度分布(complexity):代码复杂度过高将难以理解
- 重复代码(duplications):程序中包含大量复制、粘贴的代码而导致代码臃肿，sonar可以展示源码中重复严重的地方
- 单元测试统计(unit tests):统计并展示单元测试覆盖率，开发或测试可以清楚测试代码的覆盖情况
- 代码规则检查(coding rules):通过Findbugs,PMD,CheckStyle等检查代码是否符合规范
- 注释率(comments):若代码注释过少，特别是人员变动后，其他人接手比较难接手；若过多，又不利于阅读
- 潜在的Bug(potential bugs):通过Findbugs,PMD,CheckStyle等检测潜在的bug
- 结构与设计(architecture & design):找出循环，展示包与包、类与类之间的依赖、检查程序之间耦合度

![Development Cycle](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209250029500.png)

![img](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209250029201.webp)

#### 集群运作：

**1.用户本地使用IDE的插件进行代码分析**

**2.用户上传到源代码版本控制服务器**

**3.持续集成，使用Sonar Scanner进行扫描**

**4.将扫描结果上传到SonarQube服务器**

**5.SonarQube server将结果写入db**

**6.用户通过web ui查看扫描结果**

**7.SonarQube导出结果到其他需要的服务**



### 二、SonarQube部署

#### 1.环境配置

**修改内核设置**

```shell
[root@home2 ~]# vim /etc/sysctl.conf 
[root@home2 ~]# sysctl -p
vm.max_map_count = 262144
fs.file-max = 65536
[root@home2 ~]# vim /etc/security/limits.conf
*       soft    nofile  65536
*       hard    nofile  65536
*       soft    nproc   4096
*       hard    nproc   4096
```

**配置yum源，下载jdk11**

```shell
[root@home2 ~]# yum install -y vim lrzsz wget unzip epel-release
[root@home2 ~]# yum install -y java-11-openjdk java-11-openjdk-devel
[root@home2 ~]# vim /etc/profile
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.11.0.9-1.el7_9.x86_64
export CLASSPATH=.:$JAVA_HOME/jre/lib/rt.jar:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export PATH=$PATH:$JAVA_HOME/bin
[root@home2 ~]# source /etc/profile
[root@home2 ~]# java -version
openjdk version "11.0.16.1" 2022-08-12 LTS
OpenJDK Runtime Environment (Red_Hat-11.0.16.1.1-1.el7_9) (build 11.0.16.1+1-LTS)
OpenJDK 64-Bit Server VM (Red_Hat-11.0.16.1.1-1.el7_9) (build 11.0.16.1+1-LTS, mixed mode, sharing)
```

#### 2.安装postgresql

```
[root@home2 ~]# yum install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm -y
[root@home2 ~]# yum install postgresql10-contrib postgresql10-server -y
#初始化
[root@home2 ~]# postgresql-10-setup initdb
Initializing database ... OK
#备份配置文件
[root@home2 ~]# cp /var/lib/pgsql/10/data/pg_hba.conf{,.bak}	
#修改配置文件
[root@home2 ~]# vim /var/lib/pgsql/10/data/pg_hba.conf						#全部改为信任
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     trust
# IPv4 local connections:
host    all             all             127.0.0.1/32            trust
# IPv6 local connections:
host    all             all             ::1/128                 trust
# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     trust
host    replication     all             127.0.0.1/32            trust
host    replication     all             ::1/128                 trust
#启动并设置为开机自启动
[root@home2 ~]# systemctl start postgresql-10
[root@home2 ~]# systemctl enable postgresql-10.service
Created symlink from /etc/systemd/system/multi-user.target.wants/postgresql-10.service to /usr/lib/systemd/system/postgresql-10.service.
```

#### 3.创建用户及数据库

```
su - postgres
psql
CREATE DATABASE sonar TEMPLATE template0 ENCODING 'utf8' ;
create user sonar;
alter user sonar with password 'sonar';
alter role sonar createdb;
alter role sonar superuser;
alter role sonar createrole;
alter database sonar owner to sonar;
\q
exit
```

#### 4.安装SonarQube

```
[root@home2 ~]# adduser sonar
[root@home2 ~]# cd /usr/local/src
[root@home2 src]# wget -c https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-8.9.1.44547.zip
[root@home2 src]# unzip sonarqube-8.9.1.44547.zip 
[root@home2 src]# mv sonarqube-8.9.1.44547 /usr/local/sonarqube
[root@home2 src]# chown -R sonar:sonar /usr/local/sonarqube/
#修改配置文件
[root@home2 src]# vim /usr/local/sonarqube/conf/sonar.properties
sonar.jdbc.username=sonar
sonar.jdbc.password=sonar
sonar.jdbc.url=jdbc:postgresql://localhost/sonar
sonar.jdbc.maxActive=60
sonar.jdbc.maxIdle=5
sonar.jdbc.minIdle=2
sonar.jdbc.maxWait=5000
sonar.jdbc.minEvictableIdleTimeMillis=600000
sonar.jdbc.timeBetweenEvictionRunsMillis=30000
sonar.jdbc.removeAbandoned=true
sonar.jdbc.removeAbandonedTimeout=60

[root@home2 src]# vim /etc/profile
export SONAR_HOME=/usr/local/sonarqube
export SONAR_RUNNER_HOME=/usr/local/sonar-scanner
export PATH=$PATH:$SONAR_RUNNER_HOME/bin
export PATH=$PATH:$SONAR_HOME/bin
```

#### 5.启动SonarQube

```
#编写启动文件
[root@home2 src]# vim /etc/systemd/system/sonar.service
[Unit]
 
Description=SonarQube Server
 
After=syslog.target network.target
 
[Service]
 
Type=forking
 
ExecStart=/usr/local/sonarqube/bin/linux-x86-64/sonar.sh start
 
ExecStop= /usr/local/sonarqube/bin/linux-x86-64/sonar.sh stop
 
LimitNOFILE=65536
 
LimitNPROC=4096
 
User=sonar
 
Group=sonar
 
Restart=on-failure
 
[Install]
 
WantedBy=multi-user.target


#启动sonar
[root@home2 src]# systemctl restart sonar.service
[root@home2 src]# systemctl start sonar.service
[root@home2 src]# systemctl enable sonar.service
Created symlink from /etc/systemd/system/multi-user.target.wants/sonar.service to /etc/systemd/system/sonar.service.
[root@home2 src]# systemctl status sonar.service
```

![image-20220925011416287](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209250114522.png)

#### 6.web访问http://IP:9000

username：admin
password: admin

![image-20220925011519777](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209250115884.png)

**修改密码**

![image-20220925011613940](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209250116071.png)

**安装中文汉化包**

![image-20220925014622750](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209250146869.png)

**安装完会弹出Reset点击重启就行了。**

![image-20220925014706016](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209250147149.png)

![image-20220925014713467](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209250147606.png)