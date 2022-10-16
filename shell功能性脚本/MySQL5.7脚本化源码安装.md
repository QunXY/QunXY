MySQL5.7脚本化源码安装

```bash
#!/bin/bash

#清理环境
rpm -e --nodeps `rpm -qa |grep mariadb*`
#安装所需要的工具
yum install -y ncurses-devel
#openssl
yum install perl-ExtUtils-CBuilder perl-ExtUtils-MakeMaker -y
wget https://www.openssl.org/source/openssl-3.0.5.tar.gz -P /opt
cd /opt
tar xf openssl-3.0.5.tar.gz
cd openssl-3.0.5
./Configure
make -j$(nproc) && make install
#这是由于openssl库的位置不正确造成的。
ln -s /usr/local/lib64/libssl.so.3 /usr/lib64/libssl.so.3
ln -s /usr/local/lib64/libcrypto.so.3 /usr/lib64/libcrypto.so.3
#下载源码cmake包
wget https://github.com/Kitware/CMake/releases/download/v3.23.3/cmake-3.23.3.tar.gz -P /opt
#wget下载mysql5.7源码包
wget https://mirrors.aliyun.com/mysql/MySQL-5.7/mysql-boost-5.7.38.tar.gz -P /opt
#cmake安装
cd /opt
tar xf cmake-3.23.3.tar.gz && cd cmake-3.23.3
./configure
gmake -j$(nproc) && gmake install
#创建用户
groupadd  mysql
useradd -M -s /sbin/nologin mysql -g mysql
mkdir -p /data/mysqldata
#解压
echo "正在解压，请不要操作！"
cd /opt
tar xf mysql-boost-5.7.38.tar.gz -C /usr/local/src/
yum install -y openssl openssl-devel
cd /usr/local/src/mysql-5.7.38
#cmake编译，添加相关参数
cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
-DMYSQL_DATADIR=/data/mysqldata \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci \
-DSYSCONFDIR=/etc \
-DWITH_BOOST=/usr/local/src/mysql-5.7.38/boost \
-DWITH_EXTRA_CHARSETS=all
#跳过openssl版本检测 /usr/local/src/mysql-5.7.38/cmake/ssl.cmake
sed
#编译安装
make -j$(nproc) && make install
echo "export PATH=$PATH:/usr/local/mysql/bin" > /etc/profile
source /etc/profile
#将mysql安装后的目录的权限改成mysql:mysql
chown -R mysql:mysql /usr/local/mysql
cp /usr/local/mysql/support-files/my-default.cnf  /etc/my.cnf
#初始化
mysqld --initialize --user=mysql --datadir=/data/mysqldata --basedir=/usr/local/mysql
#提供服务脚本init	
cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
chmod +x /etc/init.d/mysqld
#添加为系统服务
chkconfig --add mysqld
chkconfig --list mysqld
systemctl start mysqld
#查看MySQL状态
systemctl status mysqld
# 添加环境变量
echo "PATH=$PATH:/usr/local/mysql/bin" >> /etc/profile
source /etc/profile
# 设置mysql用户和用户密码
echo "改密码：mysqladmin -u root password '123'"
```





报错openssl：

CMake Error at cmake/ssl.cmake:63 (MESSAGE):
  Please install the appropriate openssl developer package.

解决方案将cmake/ssl.cmake中找到关于OPENSSL（/OPENSSL_FOUND）的编译部分，并且加一行CRYPTO_LIBRARY，将蓝色两行注释掉相当于不检查openssl版本，之后可以正常编译。 

![img](https://i0.hdslb.com/bfs/article/542a4b431507b8c25fa1880d2375e0316ce636ba.png@942w_482h_progressive.webp)

作者：Hitch_hiker_ https://www.bilibili.com/read/cv17882632 出处：bilibili



参考文档：

[Centos7将openssl升级版本至 openssl-3.0.1 - 岁月星空 - 博客园 (cnblogs.com)](https://www.cnblogs.com/SyXk/p/15936668.html)

[(19条消息) Web服务器群集——LNMP应用部署源码安装和配置以及部署wordpress、discuz、Ecshop_stan Z的博客-CSDN博客](https://blog.csdn.net/Cantevenl/article/details/115184111)
