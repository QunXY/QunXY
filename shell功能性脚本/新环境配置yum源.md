新机环境搭建

```sh
#!/bin/bash
#初始化环境搭建
read -p "请输入IP地址：" ipaddr
read -p "请输入GATEWAY：" gateway
echo "TYPE="Ethernet"
PROXY_METHOD="none"
BROWSER_ONLY="no"
BOOTPROTO="static"
DEFROUTE="yes"
NAME="ens33"
DEVICE="ens33"
ONBOOT="yes"
IPADDR=$ipaddr
DNS1=8.8.8.8
GATEWAY=$gateway
NETMASK=255.255.255.0" >> /etc/sysconfig/network-scripts/ifcfg-ens33

mount /dev/sr0 /mnt/
#永久挂载
echo "/dev/cdrom /mnt iso9660 defaults        0 0" >>/etc/fstab
rm -rf /etc/yum.repos.d/*
mkdir /etc/yum.repos.d/bak
#yum配置文件
echo "
[local]
name=local
baseurl=file:///mnt
enable=1
gpgcheck=0
gpgkey=file:///mnt/RPM-GPG-KEY-CentOS-7">/etc/yum.repos.d/local.repo
echo "本地yum配置完成"
yum clean all
yum install -y wget
#禁用 yum插件 fastestmirror
cp -i /etc/yum/pluginconf.d/fastestmirror.conf /etc/yum/pluginconf.d/fastestmirror.conf.bak		# 备份源文件
sed -i '2s/enabled=1/enabled=0/g' /etc/yum/pluginconf.d/fastestmirror.conf
#修改yum的配置文件
cp -i /etc/yum.conf /etc/yum.conf.bak
sed -i 's/plugins=1/plugins=0/g' /etc/yum.conf
#获取阿里云
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
cp -i /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.bak
wget -O /etc/yum.repos.d/epel.repo https://mirrors.aliyun.com/repo/epel-7.repo
yum clean all
yum makecache fast
yum repolist
#关闭防火墙
systemctl stop firewalld 
systemctl disable firewalld
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
getenforce

#yum安装常用工具
yum install -y tree iotop vim wget unzip at lsof sysstat psmisc expect lrzsz
yum -y install make bison-devel ncures-devel libaio perl-Data-Dumper net-tools bison bison-devel gcc-c++ cmake ncurses ncurses-devel openssh openssh-clients openssh-server man-pages-zh-CN

systemctl restart networ
```

