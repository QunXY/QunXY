## 使用 atlas实现mysql主从读写分离 

### 1.atlas简介

Atlas是由 Qihoo 360公司Web平台部基础架构团队开发维护的一个基于MySQL协议的数据中间层项目。它在MySQL官方推出的MySQL-Proxy 0.8.2版本的基础上，修改了大量bug，添加了很多功能特性。目前该项目在360公司内部得到了广泛应用，很多MySQL业务已经接入了Atlas平台，每天承载的读写请求数达几十亿条。同时，有超过50家公司在生产环境中部署了Atlas，超过800人已加入了我们的开发者交流群，并且这些数字还在不断增加。（简介内容摘自github官网 https://github.com/Qihoo360/Atlas/wiki/Atlas%E7%9A%84%E6%9E%B6%E6%9E%84）

1. 主要功能：
   1. 读写分离;
   2. 从库负载均衡;
   3. IP过滤;
   4. 自动分表;
   5. DBA可平滑上下线DB;
   6. 自动摘除宕机的DB
   
   
   
2. 系统主要架构：Atlas是一个位于应用程序与MySQL之间中间件。在后端DB看来，Atlas相当于连接它的客户端，在前端应用看来，Atlas相当于一个DB。Atlas作为服务端与应用程序通讯，它实现了MySQL的客户端和服务端协议，同时作为客户端与MySQL通讯。它对应用程序屏蔽了DB的细节，同时为了降低MySQL负担，它还维护了连接池。



**主要看中它有以下<font color='red'>优点</font>**： 

(1)、基于Mysql-proxy-0.8.2 进行修改，代码完全开源；
(2)、比较轻量级，部署配置也比较简单；
(3)、支持DB读写分离；
(4)、支持从DB读负载均衡，并自动剔除故障从DB；
(5)、支持平滑 ，上下线DB；
(6)、具备较好的安全机制 （IP 过滤、账号认证）；
(7)、版本更新、问题跟进、交流圈子都比较活跃。



### 2.部署

1.基于MHA基础上部署 atlas
（参照笔记mysql10部署MHA） 
接下来部署 atlas ，具体的搭建环境如下（所有操作系统均为CentOS7.4 64bit）：

|     IP 地址     | 主机名  |  角色  |
| :-------------: | :-----: | :----: |
| 192.168.188.128 | mysql01 | master |
| 192.168.188.129 | mysql02 | slave  |
| 192.168.188.130 | mysql03 | slave  |
| 192.168.188.131 | mysql04 | atlas  |

2、下载安装包方式：
可以到360 github mysql主页下载 wget https://github.com/Qihoo360/Atlas/releases/download/2.2.1/Atlas-2.2.1.el6.x86_64.rpm



3、安装 mysql
上传 Atlas-2.2.1.el6.x86_64.rpm 程序包到atlas主机上

```shell
[root@mysql04 opt]# yum -y install mariadb.x86_64
[root@mysql04 opt]# rpm -ivh Atlas-2.2.1.el6.x86_64.rpm
```

安装完成后会在/usr/local/mysql-proxy/目录下生成以下脚本文件

 ![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203081723976.png)

密码的生成

```shell
[root@mysql04 opt]# cd /usr/local/mysql-proxy/bin/
[root@mysql04 bin]# ./encrypt 123456    #此为授权用户密码
/iZxz+0GRoA=

[root@mysql04 bin]# ./encrypt mha123456
Iwco7/7Rn2Klybzq6fZMAQ==
```

备份配置文件

```shell
[root@mysql04 bin]# cd /usr/local/mysql-proxy/conf
[root@mysql04 conf]# cp test.cnf test.cnf.bak
[root@mysql04 conf]# vim test.cnf
[mysql-proxy]

#带#号的为非必需的配置项目

#管理接口的用户名
admin-username = user

#管理接口的密码
admin-password = pwd

#Atlas后端连接的MySQL主库的IP和端口，可设置多项，用逗号分隔
proxy-backend-addresses = 192.168.188.180:3306   #修改为主库IP，端口

#Atlas后端连接的MySQL从库的IP和端口，@后面的数字代表权重，用来作负载均衡，若省略则默认为1，可设置多项，用逗号分隔
proxy-read-only-backend-addresses = 192.168.188.129:3306@1,192.168.188.130:3306@1   #修改为从库IP，端口

#填写主从复制账号:生成好的密码
pwds = repl_user:/iZxz+0GRoA=,mha:Iwco7/7Rn2Klybzq6fZMAQ==   

#设置Atlas的运行方式，设为true时为守护进程方式，设为false时为前台方式，一般开发调试时设为false，线上运行时设为true,true后面不能有空格。
daemon = true

keepalive = true

#工作线程数，对Atlas的性能有很大影响，可根据情况适当设置
event-threads = 8

#日志级别，分为message、warning、critical、error、debug五个级别
log-level = message

#日志存放的路径
log-path = /usr/local/mysql-proxy/log

#SQL日志的开关，可设置为OFF、ON、REALTIME，OFF代表不记录SQL日志，ON代表记录SQL日志，REALTIME代表记录SQL日志且实时写入磁盘，默认为OFF
sql-log = ON   #开启sql日志

#Atlas监听的工作接口IP和端口
proxy-address = 0.0.0.0:1234   #可以自定义端口

#Atlas监听的管理接口IP和端口 
admin-address = 0.0.0.0:2345   #开启默认字符集

#分表设置，此例中person为库名，mt为表名，id为分表字段，3为子表数量，可设置多项，以逗号分隔，若不分表则不需要设置该项
#tables = person.mt.id.3

#默认字符集，设置该项后客户端不再需要执行SET NAMES语句
charset = utf8
```

启动atlas

```shell
[root@mysql04 conf]# cd ../
[root@mysql04 mysql-proxy]# cd bin/
[root@mysql04 bin]# ./mysql-proxyd test start
OK: MySQL-Proxy of test is started
```

注意：
运行文件是：mysql-proxyd(不是mysql-proxy）
test是conf目录下配置文件的名字

安装mysql客户端，不需要启动mysql服务端(但是前面已经安装)



使用atlas进入数据库
1.进入atlas的管理模式

**语法：mysql  -uuser -ppwd  -h atlas所在节点 -P2345**

```shell
[root@mysql04 bin]# mysql  -uuser -ppwd  -h 192.168.188.131 -P2345
```

查看mysql管理员模式容许操作：

```mysql
MySQL [(none)]> select * from help;
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203081902875.png)

查看主从库的读写情况： 

```mysql
MySQL [(none)]> select * from backends;
```

 ![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203081904641.png)

添加新节点：

```mysql
MySQL [(none)]> add slave 192.168.188.132:3306;
Empty set (0.00 sec)
```

 ![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203081906302.png)

节点下线

```mysql
MySQL [(none)]> set offline 4;
```

 ![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203081907691.png)

节点上线：       #不成功是因为这台机是虚假，这台机不存在

```mysql
MySQL [(none)]> set online 4;
```

 ![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203081908640.png)

删除节点

```mysql
MySQL [(none)]> remove backend 4;
Empty set (0.00 sec)

MySQL [(none)]> select * from backends;
```

 ![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203081909536.png)

以上操作均为临时操作，想永久保存，需要执行save config;



先在主库mysql5上授权：

```mysql
mysql>grant all on *.* to xiaohong@'%' identified by '123456';
```

```mysql
阿特拉斯所在[(none)]>SELECT * FROM pwds;查看用户
阿特拉斯所在[(none)]>add pwd xiaohong:123456; (将主库授权的用户放到atlas上)
```



### 读写分离测试

测试读操作：
mysql -umha -pmha123456 -h atlas所在节点 -P1234

```mysql
[root@mysql04 bin]# mysql -umha -pmha123456 -h 192.168.188.131 -P1234
```

```mysql
MySQL [(none)]> select @@server_id;
```

会发现轮询读操作。

 ![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203081918042.png)

测试写操作：

```mysql
MySQL [(none)]> begin;select @@server_id;commit;
```

用事务测试读写落点。

![image-20220509163528031](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202205091635085.png)
