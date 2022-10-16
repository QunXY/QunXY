禅道LNMP安装搭建：

```sh
#!/bin/bash
cd /opt
wget https://www.zentao.net/dl/zentao/12.5.3/ZenTaoPMS.12.5.3.zbox_64.tar.gz
tar xf ZenTaoPMS.12.5.3.zbox_64.tar.gz
cd zbox
systemctl  stop nginx
systemctl  stop mysqld
/opt/zbox/zbox start
echo "浏览器：<ip> 访问"
echo "禅道默认管理员帐号是 admin，密码 123456"
echo "数据库管理需要运行/opt/zbox/auth/adduser.sh来添加用户"
```

参考：[Centos7.6 在LNMP上部署禅道 - 人走茶良 - 博客园 (cnblogs.com)](https://www.cnblogs.com/aqicheng/p/10275704.html)

禅道默认管理员帐号是 admin，密码 123456

服务器： 127.0.0.1:mysql端口

用户名： root。（禅道默认的数据库用户名是 root）

密  码：123456。（ 禅道默认的数据库密码是123456）

数据库：zentao

登录数据库：/opt/zbox/bin/mysql -u root -P mysql端口 -p （比如：/opt/zbox/bin/mysql -u root -P 3306 -p）

导入数据库：/opt/zbox/bin/mysql -u root -P mysql端口 -p 要导入的库名 < XXXX.sql （比如：/opt/zbox/bin/mysql -u root -P 3306 -p zentao < zentao.sql）



源码：https://www.zentao.net/dl/zentao/12.5.3/ZenTaoPMS.12.5.3.zip

集成环境包-直接用：https://www.zentao.net/dl/zentao/12.5.3/ZenTaoPMS.12.5.3.zbox_64.tar.gz

![image-20220910215353293](https://boluo-1312891830.cos.ap-nanjing.myqcloud.com/%E7%AC%94%E8%AE%B0%E5%9B%BE%E7%89%87202209102153399.png)