## MySQL 高可用集群架构-MHA 架构

### **MHA 简介**

MHA（Master High Availability）目前在 MySQL 高可用方面是一个相对成熟的解决方案，它由 日本 DeNA 公司 youshimaton （现就职于 Facebook 公司）开发，是一套优秀的作为 MySQL 高可用性环境下故障切换和主从提升的高可用软件。在 MySQL 故障切换过程中，MHA 能做到在 0~30 秒之内 自动完成数据库的故障切换操作，并且在进行故障切换的过程中，MHA 能在最大程度上保证数据的一致性，以达到真正意义上的高可用。
该软件由两部分组成：MHA Manager （管理节点）和 MHA Node （数据节点）。MHA Manager 可以单独部署在一台独立的机器上管理多个 master-slave 集群，也可以部署在一台 slave 节点上。MHA Node 运行在每台 MySQL 服务器上，MHA  Manager 会定时探测集群中的 master 节点，当 master 出现故障时，它可以自动将“<font color='red'>最新数据的 slave</font>” 提升为新的 master ，然后将所有其他的 slave 重新指向新 的master。整个故障转移过程对应用程序完全透明。

目前 MHA 主要支持一主多从的架构，<font color='red'>要搭建 MHA,要求一个复制集群中必须最少有三台数据库服务器，一主二从</font>，即一台充当 master ，一台从机充当备用master ，另外一台充当从库，因为至少需要三台服务器。MHA 适合任何存储引擎, 只要能主从复制的存储引擎它都支持，

下图展示了如何通过 MHA Manager 管理多组主从复制。

![file://c:\users\admini~1\appdata\local\temp\tmpl4ezg9\1.png](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203071920725.png)

#### 原理

MHA 工作原理总结为如下：
（1）从宕机崩溃的 master 保存二进制日志事件（binlog events ）(数据节点操作)
（2）识别含有最新更新的 slave ；
（3）应用差异的中继日志（relay log ）到其他的 slave ；
（4）应用从 master 保存的二进制日志事件（binlog events）（管理节点操作）
（5）提升一个 slave 为新的master ；
（6）使其他的 slave 连接新的 master 进行复制 。



#### 组成

MHA 软件由两部分组成，<font color='red'>Manager (管理节点)</font>工具包和 <font color='red'>Node （数据节点）</font>工具包，具体的说明如下。

Manager 工具包主要包括以下几个工具：

masterha_check_ssh              检查 MHA 的SSH配置状况
masterha_check_repl             检查 MySQL 复制状况
masterha_check_status          检测当前 MHA 运行状态
masterha_manger                 启动 MHA
masterha_master_monitor      检测 master 是否宕机
masterha_master_switch        手工转移故障
masterha_conf_host              添加或删除配置的 server 信息
masterha_secondary_check    从远程服务器建立TCP连接
masterha_stop                      停止 MHA

Node 工具包（这些工具通常由 MHA Manager 的脚本触发，无需人为操作）主要包括以下几个工具：

save_binary_logs         保存和复制master 的二进制日志
apply_diff_relay_logs   识别差异的中继日志事件并将其差异的事件应用于其他的 slave
purge_relay_logs         清除中继日志（不会阻塞 SQL 线程）



#### 机器环境

| 主机名  | 服务器IP地址    | 数据库角色 | MHA角色  |
| ------- | --------------- | ---------- | -------- |
| mysql01 | 192.168.188.128 | 主库       | 管理节点 |
| mysql02 | 192.168.188.129 | 从库       | 数据节点 |
| mysql03 | 192.168.188.130 | 从库       | 数据节点 |



#### 数据库环境

**3台服务器安装好mysql服务，并配置好主从同步复制**

- [x] 1.配好网络 (vim /etc/sysconfig/network-scripts/ifcfg-ens33)                           
- [x] 2.配好主机名 (vim /etc/hostname)
- [x] 3.设别名 (vim /etc/hosts ==> 映射)
- [x] 4.重新生成auto.cnf文件 (根据之前设置在了/data/mysql/下，所以rm -rf /data/mysql/auto.cnf)
- [x] 5.修改server-id (vim /etc/my.cnf)
- [x] 6.主从配置文件 (开启binlog日志与relay日志) 
- [x] 7.从机也需要添加主从复制用户
- [x] 8.三台机子都设置免密互信(ssh-keygen、ssh-copy-id)



```shell
#在主从机上
[root@mysql01 ~]# vim /etc/my.cnf
[mysqld]
log-slave-updates=1                     #开启此参数，可以让从库binlog转为主库binlog

[root@mysql01 ~]# systemctl restart mysql
```

mysql01主库

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203071944775.png)

mysql02从库

 ![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203071945750.png)

mysql03从库

 ![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203071945134.png)



8. 添加命令
   所有服务器节点均需要执行（因为mha会执行数据库命令，但是要指定路径）

   ```shell
   #mysql01主机
   [root@mysql01 ~]# ln -s /usr/local/mysql/bin/mysqlbinlog /usr/local/bin/mysqlbinlog
   [root@mysql01 ~]# ln -s /usr/local/mysql/bin/mysql /usr/local/bin/mysql
   #mysql02从机
   [root@mysql02 ~]# ln -s /usr/local/mysql/bin/mysqlbinlog /usr/local/bin/mysqlbinlog
   [root@mysql02 ~]# ln -s /usr/local/mysql/bin/mysql /usr/local/bin/mysql
   #mysql03从机
   [root@mysql03 ~]# ln -s /usr/local/mysql/bin/mysqlbinlog /usr/local/bin/mysqlbinlog
   [root@mysql03 ~]# ln -s /usr/local/mysql/bin/mysql /usr/local/bin/mysql
   ```

9. 部署MHA软件
    9.1.所有节点安装依赖包
    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
    需要安装最新的epel源（这里用的是阿里云的epel源）
    wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
    需要做哪步？

10. 下载管理节点manager与数据节点node

    https://github.com/yoshinorim/mha4mysql-node/releases
    https://github.com/yoshinorim/mha4mysql-manager/releases

11. 安装数据节点

    ```shell
    [root@mysql01 opt]# yum install -y perl-DBD-MySQL
    [root@mysql02 opt]# yum install -y perl-DBD-MySQL
    [root@mysql03 opt]# yum install -y perl-DBD-MySQL
    
    [root@mysql01 opt]# rpm -ivh mha4mysql-node-0.58-0.el7.centos.noarch.rpm
    [root@mysql02 opt]# rpm -ivh mha4mysql-node-0.58-0.el7.centos.noarch.rpm
    [root@mysql03 opt]# rpm -ivh mha4mysql-node-0.58-0.el7.centos.noarch.rpm
    ```

12. 安装管理节点

    ```shell
    [root@mysql01 opt]# yum install -y perl-Config-Tiny epel-release perl-Log-Dispatch perl-Parallel-ForkManager perl-Time-HiRes
    
    [root@mysql01 opt]# rpm -ivh mha4mysql-manager-0.58-0.el7.centos.noarch.rpm
    ```



### MHA高可用方案配置

#### 1.授权数据库管理账户

<font color='red'>所有的</font>服务器节点均需授权

```mysql
mysql> grant all privileges on *.* to mha@'%' identified by 'mha123456';
Query OK, 0 rows affected, 1 warning (0.00 sec)

mysql> flush privileges;
Query OK, 0 rows affected (0.00 sec)
```

#### 2.创建MHA配置文件

只需要在manager管理节点上进行
创建所需要的目录

```shell
[root@mysql01 opt]# mkdir -p /opt/mha/conf /opt/mha/log /opt/mha/work

[root@mysql01 opt]# tree /opt/mha
/opt/mha
├── conf
├── log
└── work
```

创建MHA的配置文件

```shell
[root@mysql01 opt]# vim /opt/mha/conf/mha.conf
[server default]
user=mha                            #MHA管理用户
password=mha123456            #MHA管理用户的密码
ping_interval=2                     #用于检测master是否正常,每2秒ping一次
repl_user=repl_user              #主从复制的用户
repl_password=123456          #主从复制的密码
ssh_user=root                       #远程登录的用户

manager_workdir=/opt/mha/work/mha-work.log           #MHA工作日志目录
manager_log=/opt/mha/log/mha.log                     #MHA日志目录
master_binlog_dir=/data/binlog                     #MHA寻找主库binlog日志的目录

[server1]
hostname=192.168.188.128    #主库ip或主机名#
port=3306

[server2]
hostname=192.168.188.129     #从库1ip或主机名
port=3306
no_master=1                 #开启从库不变成主库的参数

[server3]
hostname=192.168.188.130     #从库2ip或主机名
port=3306
candidate_master=1                  #当主库故障时，优先成为主库
check_repl_delay=0                  #默认是落后100m日志量就不会选为主,此处改为0 则跳过日志量差异检查，强制为主库
```

#### 3.检测MHA配置

##### 3.1.检测SSH登录

```shell
[root@mysql01 opt]# masterha_check_ssh  --conf=/opt/mha/conf/mha.conf
```

**出现“All SSH connection tests passed successfully.”这一提示为成功**

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203072037388.png)

##### 3.2.检测当前主从同步状态

```shell
[root@mysql01 opt]# masterha_check_repl  --conf=/opt/mha/conf/mha.conf
```

出现“MySQL Replication Health is OK.”这一提示为成功

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203072038307.png)

##### 3.3.检查 MHA Manager 的状态

```shell
[root@mysql01 opt]# masterha_check_status --conf=/opt/mha/conf/mha.conf
mha is stopped(2:NOT_RUNNING).
#注意：如果正常，会显示"PING_OK" ，否则会显示"NOT_RUNNING"，这代表 MHA 监控没有开启。
```

##### 3.4.开启 MHA 服务

```shell
[root@mysql01 log]# nohup masterha_manager --conf=/opt/mha/conf/mha.conf  --remove_dead_master_conf  --ignore_last_failover < /dev/null >/opt/mha/log/mha.log 2>&1 &
[1] 3000
```

启动参数介绍：
--remove_dead_master_conf #该参数代表当发生主从切换后，老的主库的 IP 将会从配置文件中移除。（可选择性使用）
--mha_log            #日志存放位置
--ignore_last_failover      #在默认情况下，如果 MHA 检测到连续发生宕机，且两次宕机间隔不足 8 小时的话，则不会进行 Failover ，之所以这样限制是为了避免 ping-pong效应。该参数代表 忽略上次 MHA 触发切换产生的文件，默认情况下，MHA 发生切换后会在日志目录，也就是上面我设置 的/mha/log产生 failover.complete 文件，下次再次切换的时候如果发现该目录下存在该文件将不允许触发切换，除非在第一次切换后收到删除该文件，为了方便，这里设置为--ignore_last_failover。



##### 3.5.查看 MHA Manager 监控是否正常

```shell
[root@mysql01 log]# masterha_check_status --conf=/opt/mha/conf/mha.conf   #此时查看状态已经是启动
mha (pid:3000) is running(0:PING_OK), master:192.168.188.128
```

可以看见已经在监控了，而且 master 的主机为 192.168.188.128



#### 4.测试MHA故障

关闭mydql01数据库

```shell
[root@mysql01 opt]# systemctl stop mysqld
```

由于MHA至少需要3台数据库，所以此时MHA关闭

```shell
[root@mysql01 log]# masterha_check_status --conf=/opt/mha/conf/mha.conf
mha is stopped(2:NOT_RUNNING).
```

```shell
[root@mysql01 log]# grep -i "All other slaves should start" /opt/mha/log/mha.log
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203072056967.png)

 从库mysql02：

```mysql
mysql> show slave status\G
```

 ![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203072059799.png)

重新启动mysql01数据库，执行主从同步操作

```mysql
mysql> show slave status;
Empty set (0.00 sec)
```

**会发现原本作为主库的mysql01重启后不再具有主从关系，所以需要手动添加回去。如下图，主库故障后从库顶上做主库然后配置文件里面就会移除掉故障机的配置信息**

<font color='red'>注：此时要检测三台机是否有主从关系</font>

```shell
[root@mysql01 log]# vim /opt/mha/conf/mha.conf
```

 ![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203072103577.png)

```shell
#添加信息回去
#[server x ]
#hostname=产生故障的IP或主机名
#port=3306

[root@mysql01 log]# vim /opt/mha/conf/mha.conf
[server1]
hostname=192.168.188.128    
port=3306
```

```mysql
#在mysql01操作，重新指向mysql03做mysql03的从机，mysql03情况如下图

mysql> CHANGE MASTER TO
    -> MASTER_HOST='192.168.188.130',
    -> MASTER_USER='repl_user',
    -> MASTER_PASSWORD='123456',
    -> MASTER_LOG_FILE='mysql-bin.000014',
    -> MASTER_LOG_POS=1016,
    -> MASTER_CONNECT_RETRY=10;
Query OK, 0 rows affected, 2 warnings (0.00 sec)
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203072115850.png)

```mysql
mysql> start slave;
Query OK, 0 rows affected (0.00 sec)

mysql> show slave status\G
```

 ![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203072117212.png)

```shell
[root@mysql01 log]# nohup masterha_manager --conf=/opt/mha/conf/mha.conf  --remove_dead_master_conf  --ignore_last_failover < /dev/null >/opt/mha/log/mha.log 2>&1 &
[1] 3950

#此时主库已切换成mysql0
[root@mysql01 log]# masterha_check_status --conf=/opt/mha/conf/mha.conf
mha (pid:3950) is running(0:PING_OK), master:192.168.188.130
```

#### 5.弊端

<font color='red'>**只要宕机过一次，就会结束mha后台进程；那么就需要重新配好宕机的机器与其他机器的主从关系，然后在管理节点上的mha配置文件添加宕机的信息回去重新运行mha**</font>



### 使用MHA自带的脚本master_ip_failover来实现VIP切换

```shell
[root@mysql01 opt]# mkdir -p /opt/mha/scripts
[root@mysql01 opt]# cd /opt/mha/scripts
#把脚本拉进/opt/mha/scripts
[root@mysql01 scripts]# vim master_ip_failover
#往第34行添加以下配置
my $vip ='192.168.188.180/24';       #空闲ip
my $key ='1';
my $ssh_start_vip = "/sbin/ifconfig ens33:$key $vip";
my $ssh_stop_vip = "/sbin/ifconfig ens33:$key down";
```

1.解决中文字符

```shell
[root@mysql01 scripts]# yum -y install dos2unix && dos2unix /opt/mha/scripts/master_ip_failover
已加载插件：fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirrors.aliyun.com
 * extras: mirrors.aliyun.com
 * updates: mirrors.aliyun.com
软件包 dos2unix-6.0.3-7.el7.x86_64 已安装并且是最新版本
无须任何处理
dos2unix: converting file /opt/mha/scripts/master_ip_failover to Unix format ...
```

给予执行权：

```shell
[root@mysql01 scripts]# chmod a+x /opt/mha/scripts/master_ip_failover
```

2.往**管理节点**里添加配置项

```shell
[root@mysql01 scripts]# vim /opt/mha/conf/mha.conf
master_ip_failover_script=/opt/mha/scripts/master_ip_failover
```

3.重启MHA：

需要先关闭 MHA 服务

```shell
[root@mysql01 scripts]# masterha_stop --conf=/opt/mha/conf/mha.conf
```

再启动

```shell
[root@mysql01 scripts]# nohup masterha_manager --conf=/opt/mha/conf/mha.conf  --remove_dead_master_conf  --ignore_last_failover < /dev/null >/opt/mha/log/mha.log 2>&1 &
```

验证：
主库能自动生成VIP，即为成功，因为此时模拟宕机已经转换成mysql03为主库所以在mysql03机子上验证

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203080911981.png)



### MHA邮件报警

1.解压安装包

```shell
[root@mysql4 opt]# unzip MHAemail.zip

drwxr-xr-x  3 root root        19 9月  19 2020 email_2019-最新

[root@mysql4 opt]# cp email_2019-最新/email/* /usr/local/bin

[root@mysql4 opt]# cd /usr/local/bin

[root@mysql4 opt]# chmod +x  /usr/local/bin/*			#添加执行权限

[root@mysql4 opt]# cat testpl				#修改邮箱信息

#!/bin/bash
/usr/local/bin/sendEmail -o tls=no -f 发件箱 -t 收件箱 -s smtp.126.com:25 -xu 发件箱用户 -xp 发件箱授权码 -u "MHA Waring" -m "YOUR MHA MAY BE FAILOVER" &>/tmp/sendmail.log


实例：
/usr/local/bin/sendEmail -o tls=no -f 13929903359@163.com -t 429496374@qq.com -s smtp.163.com:25 -xu 13929903359 -xp TNAVVPFJWZLWLCES -u "MHA Waring" -m "YOUR MHA MAY BE FAILOVER" &>/tmp/sendmail.log

```

2.测试发送是否成功：

```shell
[root@mysql4 opt]# ./testpl

[root@mysql4 opt]# cat /tmp/sendmail.log

Mar 16 10:18:17 mycat sendEmail[1650]: Email was sent successfully!         #发送成功
```

3.往管理节点里添加配置项：

```shell
vim /mha/conf/mha.conf  

report_script=/usr/local/bin/send
```

