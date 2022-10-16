

keepalived官网：https://www.keepalived.org/index.html

### 1、Keepalived 定义:   

keepalived是一个用C语言编写的路由软件

 Keepalived 是一个基于 VRRP 协议来实现的 LVS服务  高可用方案，可以利用其来避免单点故障。
   一个LVS服务会有2台服务器运行Keepalived，一台为主服务器（MASTER），一台为备份服务器（BACKUP），
   但是对外表现为一个虚拟IP（VIP），

   主服务器会发送特定的消息给备份服务器，当备份服务器收不到这个消息的时候，即主服务器宕机的时候， 
   备份服务器就会接管虚拟IP，继续提供服务，从而保证了高可用性。

   Keepalived是VRRP的完美实现，因此在介绍keepalived之前，先介绍一下VRRP的原理。



### 2、VRRP 协议简介:   

​        在现实的网络环境中，两台需要通信的主机大多数情况下并没有直接的物理连接。
​        对于这样的情况，它们之间路由怎样选择？主机如何选定到达目的主机的下一跳路由，这个问题通常的解决方法有二种：
​       

• 在主机上使用动态路由协议(RIP、OSPF等)
• 在主机上配置静态路由

很明显，在主机上配置动态路由是非常不切实际的，因为管理、维护成本以及是否支持等诸多问题。
    配置静态路由就变得十分流行，但路由器 (或者说默认网关default gateway) 却经常成为单点故障。
    

    VRRP的目的就是为了解决静态路由单点故障问题，VRRP通过  竞选(election)机制
    来动态的将路由任务交给LAN(局域网)中虚拟路由器中的某台VRRP路由器目标，将多个具有相同属性的真实设备 整合成一个虚拟设备，提供高可用的能力。

### 3、VRRP 工作机制:   

​       在一个VRRP虚拟路由器中，有多台物理的VRRP路由器，但是这多台的物理的机器并不能同时工作，
​       而是由一台称为MASTER的负责路由工作，其它的都是BACKUP，MASTER并非一成不变，VRRP让每个VRRP路由器参与竞选，
​       最终获胜的就是MASTER。
​       MASTER拥有一些特权，比如，拥有虚拟路由器的IP地址，我们的主机就是用这个IP地址作为静态路由的。
​       拥有特权的MASTER要负责转发 哪些交给网关地址的 包 和 响应探测ARP的请求。

​       VRRP通过竞选协议来实现虚拟路由器的功能，所有的协议报文都是通过IP多播(multicast)包(多播地址224.0.0.18)形式发送的。
​       虚拟路由器由VRID(范围0-255) 和 一组IP地址组成，对外表现为一个周知的MAC地址。
​       所以，在一个虚拟路由 器中，不管谁是MASTER，对外都是相同的 MAC和IP  (称之为VIP)。
​       客户端主机并不需要因为MASTER的改变而修改自己的路由配置，对客户端来说，这种主从的切换是透明的。
​  ​       在一个虚拟路由器中，只有作为MASTER 的 VRRP路由器会一直发送  VRRP 通告信息(VRRPAdvertisement message)，
​       BACKUP不会抢占 MASTER，除非它的优先级 (priority)更高。
当MASTER不可用时 (BACKUP收不到通告信息)， 多台  BACKUP  中优先级最高的这台会被抢占为MASTER。
​       这种抢占是非常快速的(<1s)，以保证服务的连续性。由于安全性考虑，VRRP包使用了加密协议进行加密。



### 4、VRRP 工作流程:    


(1).初始化：

​            路由器启动时，对比各个节点的优先级（0-255），发送VRRP通告信息，
​            并发送广播ARP信息通告路由器IP地址对应的MAC地址为路由虚拟MAC，设置通告信息定时器准备定时发送VRRP通告信息，
​            转为MASTER状态；否则进入BACKUP状态，设置定时器检查定时检查是否收到MASTER的通告信息。

(2).Master

​          。设置定时通告定时器；
​          。用VRRP虚拟MAC地址响应路由器IP地址的ARP请求；
​          。转发目的MAC是VRRP虚拟MAC的数据包；
​          。如果是虚拟路由器 VIP 的 拥有者，将实际负责 接受目的地址是虚拟路由器IP的数据包，否则丢弃；
​          。当收到shutdown的事件时删除定时通告定时器，发送优先权级为0的通告包，转初始化状态；
​          。如果定时通告定时器超时时，发送VRRP通告信息；
​          。收到VRRP通告信息时，如果优先权为0，发送VRRP通告信息；
​              否则判断  优先级是否高于本机，或相等而且实际IP地址大于本地实际IP，设置定时通告定时器，复位主机超时定时器，
​              转BACKUP状态；否则的话，丢弃该通告包；

(3).Backup

​         \- 设置主机超时定时器；
​         \- 不能响应针对虚拟路由器IP的ARP请求信息；
​         \- 丢弃所有目的MAC地址是虚拟路由器MAC地址的数据包；
​         \- 不接受目的是虚拟路由器IP的所有数据包；
​         \- 当收到shutdown的事件时删除主机超时定时器，转初始化状态；
​         \- 主机超时定时器超时的时候，发送VRRP通告信息，广播ARP地址信息，转MASTER状态；
​         \-  收到VRRP通告信息时，如果优先权为0，表示进入MASTER选举；
​            否则判断数据的优先级是否高于本机，如果高的话承认MASTER有效，复位主机超时定时器；否则的话，丢弃该通告包；

对ARP查询处理

​       当内部主机通过ARP查询虚拟路由器IP地址对应的MAC地址时，MASTER路由器回复的MAC地址为虚拟的VRRP的MAC地址，而不是实际网卡的 MAC地址，
​       这样在路由器切换时让内网机器觉察不到；
​      

​       而在路由器重新启动时，不能主动发送本机网卡的实际MAC地址。
​       如果虚拟路由器开启的ARP代理 (proxy_arp)功能，代理的ARP回应也回应VRRP虚拟MAC地址。
​ KeepAlived  启动后的三个进程。      ​       
  A）core是keepalived的核心，负责主进程的启动和维护，全局配置文件的加载解析等 。
 B）check负责healthchecker(健康检查)，包括了各种健康检查方式，以及对应的配置的解析包括LVS的配置解析 。
 C）vrrp，VRRPD子进程，VRRPD子进程就是来实现VRRP协议的 。
​       

​     我们可以 将LVS相关的配置（例如realserver、调度算法、工作模式等）
​     写入到keepalived配置中，由keepalived 接管LVS的配置，
​    ​ 其实这部分配置工作和使用 ipvsadm 是差不多的。
​    keepalived的配置主要有全局配置段和VRRP配置段两部分，如果需要配置lvs，还需要有lvs相关的配置：



### 5、安装keepalived

yum install -y keepalived

源码安装
[keepalived源码编译安装_wyl9527的博客-CSDN博客_keepalived编译安装](https://blog.csdn.net/wyl9527/article/details/86616655)
 yum install -y libnfnetlink-devel libnl libnl-devel 

备份配置文件
cp 		/etc/keepalived/keepalived.conf 		/etc/keepalived/keepalived.conf_bak
![file://c:\users\admini~1.des\appdata\local\temp\tmpj2el1i\1.png](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203271219600.png)

### 6、修改keepalived配置文件

#### 6.1、抢占模式：

nginx1
vim /etc/keepalived/keepalived.conf
global_defs {
   router_id nginx1
}

vrrp_instance VI_1 {
    state MASTER
    interface ens33
    virtual_router_id 50
    priority 150
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        192.168.245.175
        

}

}

nginx2
vim /etc/keepalived/keepalived.conf
global_defs {
   <font color='red'>router_id nginx2</font>
}

vrrp_instance VI_1 {
    <font color='red'>state <font color='red'>BACKUP</font></font>
    interface ens33
    virtual_router_id 50
   <font color='red'> priority 100</font>
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        192.168.245.175    

}

}

启动：systemctl start keepalived

检查vip，使用ip a命令查看IP，ifconfig命令查看不了虚拟IP





####  6.2、非抢占模式      (一般应用在测试、维护期间)

  1、两个节点的state都必须配置为BACKUP
  2、两个节点都必须加上nopreempt
  3、其中一个节点的优先级必须要高于另外一个
nginx1
vim /etc/keepalived/keepalived.conf
global_defs {
   router_id nginx1
}

vrrp_instance VI_1 {
    <font color='red'>state BACKUP</font>
    <font color='red'>nopreempt</font>
    interface ens33
    virtual_router_id 50
   <font color='red'> priority 150</font>
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        192.168.200.16
        

}

}

nginx2
vim /etc/keepalived/keepalived.conf
global_defs {
   router_id nginx2
}

vrrp_instance VI_1 {
    <font color='red'>state BACKUP</font>
    <font color='red'>nopreempt</font>
    interface ens33
    virtual_router_id 50
    <font color='red'>priority 100</font>
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        192.168.200.16
        

}

}

例：当有一种情况发生，当某一服务短时间内经常宕机，造成短时间内VIP经常漂移

这时也可以用非抢占模式

排查出为什么某一服务短时间内经常宕机



例：出现脑裂问题，怎么处理
一般解决方法：直接kill其中一台keepalived



### 7、nginx+keepalived联动

编写脚本略，并授权
chmod 744 nginx-keepalived.sh

```
vrrp_script check_nginx {
        script "/etc/keepalived/nginx-keepalived.sh"
        interval 5
}

vrrp_instance VI_1 {
        .............
       #调用并运行该脚本
       track_script {
                check_nginx 
      }

}
```



执行脚本没有权限问题，添加这两段到global_defs项里（keepalived2.0版本之后需要加多下面两句话）
script_user root
enable_script_security

