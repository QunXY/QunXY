ecshop lnmp环境部署

```
环境：centos7
ip:192.168.112.129
```



```bash
#!/bin/bash
#肖钰群
#关闭防火墙
systemctl stop firewalld
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
setenforce 0
iptables -F
#安装LAMP环境
yum install -y httpd php php-mysql php-gd php-mbstring
#还需要自己手动安装MySQL、nginx

#启动服务
systemctl enable --now httpd
systemctl enable --now mysqld

#手动上传ecshop电商网站包到/opt
read -p "手动上传ecshop电商网站包到/opt,上传成功输入yes！" temp
if test $temp == "yes" ; then
cd /opt
unzip ecshop.zip -d /var/www/html/
cd /var/www/html/ecshop
#授权
chown -R apache.apache /var/www/html/ecshop/
chmod -R 755 /var/www/html/ecshop/
#MYSQL 数据库授权用户
mysql -uroot -p123456 -e "grant all on ecshop.* to 'ecs'@'192.168.112.%' identified by '1234';flush privileges;"
#浏览器访问页面并初始化设置
echo "浏览器访问页面并初始化设置:http://192.168.112.129/ecshop/install/index.php"
echo -e "数据库登录：ecs \n密码：1234"
fi
```

```
grant all on ecshop.* to 'ecs'@'192.168.112.%' identified by '1234';
```

![image-20220913203805678](https://boluo-1312891830.cos.ap-nanjing.myqcloud.com/%E7%AC%94%E8%AE%B0%E5%9B%BE%E7%89%87202209132038847.png)

参考文档：

[搭建LNMP发布ecshop系统及压测启用opcache缓存与否的情况 - 今天又进步了 - 博客园 (cnblogs.com)](https://www.cnblogs.com/wawahaha/p/4612234.html)

[(19条消息) Web服务器群集——LNMP应用部署源码安装和配置以及部署wordpress、discuz、Ecshop_stan Z的博客-CSDN博客](https://blog.csdn.net/Cantevenl/article/details/115184111)

[搭建LAMP环境部署Ecshop电商网站 - Q公子 - 博客园 (cnblogs.com)](https://www.cnblogs.com/itwangqiang/p/14184241.html)