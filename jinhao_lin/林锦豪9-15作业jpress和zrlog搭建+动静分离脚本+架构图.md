# 2022-09-15

# 1，jpress和zrlog-ROOT练习做完。

## jpress：

**一、下载jpress.war包，设置虚拟主机**

```shell
[root@home3 ~]# mkdir -p /data/jpress
[root@home3 ~]# cd /data/jpress/
[root@home3 jpress]# wget http://192.168.1.200/package/war/jpress-v3.3.0.war
[root@home3 ~]# vim /usr/local/tomcat/conf/server.xml								#添加一个虚拟主机
<Host name="www.test.com"  appBase="/data/jpress"
            unpackWARs="true" autoDeploy="true">
        <Context path="" docBase="jpress-v3.3.0" />
[root@home3 jpress]# sh /usr/local/tomcat/bin/catalina.sh stop
[root@home3 jpress]# sh /usr/local/tomcat/bin/catalina.sh start
```

**二、进入网页输入我们设置的hostname+端口8080（tomacat默认监听端口）开始安装**

![image-20220915181614934](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209151816112.png)

**填入相关信息**

![image-20220915181634005](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209151816133.png)

![image-20220915181820874](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209151818029.png)



![image-20220915183134498](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209151831696.png)

**挺无语的验证码永远刷不出来**

## zrlog:

**一、下载zrelog-ROOT.war包，设置虚拟主机**

```shell
[root@home3 jpress]# cd ..
[root@home3 data]# cd ~
[root@home3 ~]# cd /data
[root@home3 data]# mkdir zrlog
[root@home3 data]# cd zrlog/
[root@home3 zrelog]# wget http://192.168.1.200/package/war/zrlog-ROOT.war
[root@home3 zrelog]# vim /usr/local/tomcat/conf/server.xml
<Host name="www.zr.com"  appBase="/data/zrlog"
            unpackWARs="true" autoDeploy="true">
        <Context path="" docBase="zrlog-ROOT" />
[root@home3 zrelog]# mysql -uroot -p123 -h192.168.159.138 -P3306				#创zrlog库
mysql> create database zrlog
    -> ;
Query OK, 1 row affected (0.00 sec)

mysql> quit
Bye

[root@home3 zrelog]# sh /usr/local/tomcat/bin/catalina.sh stop
[root@home3 zrelog]# sh /usr/local/tomcat/bin/catalina.sh start
```

**二、修改windows的host文件，进入网页输入我们设置的hostname+端口8080（tomacat默认监听端口）开始安装**

![image-20220915200906833](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209152009925.png)

![image-20220915201126755](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209152011844.png)

![image-20220915201137943](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209152011054.png)

![image-20220915201145546](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209152011640.png)

**安装成功**

![image-20220915201210542](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209152012661.png)



# 2，动静分离脚本（php和tomcat两个方向）

```shell
PHP (){
read -p "请输入你要加入PHP动态分离的文件(?.conf)：" conf
read -p "请输入你要查看PHP文件目录：" dirphp
dirphp=`find / -name $dirphp`
nconf=`find / -name nginx.conf | grep nginx/nginx.conf`
confdir=`find / -name $conf`
line=`cat -n $confdir | grep -i location | awk -F "[ ]+" 'NR==1{print $2}'`
echo $line | xargs -i sed -i "{}i location ~ \.php$ { \nroot $dirphp; \nfastcgi_pass   127.0.0.1:9000; \ninclude        fastcgi_params; \nfastcgi_index  index.php; \nfastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name; \nfastcgi_param  PATH_INFO \$fastcgi_script_name; \n}" $confdir
nginx -c $nconf
nginx -s reload
}

Tomcat () {
read -p "请输入你要加入Tomcat动态分离的文件(?.conf)：" conf
nconf=`find / -name nginx.conf | grep nginx/nginx.conf`
confdir=`find / -name $conf`
line=`cat -n $confdir | grep -i location | awk -F "[ ]+" 'NR==1{print $2}'`
echo $line | xargs -i sed -i '{}i location ~ \.(jsp|do)$ { \nproxy_pass http://127.0.0.1:8080; \n}' $confdir
nginx -c $nconf
nginx -s reload
}


D_S (){
while true
do
echo -e "\e[36m
______________________________
|                             |
|        动静分离             |
|    1.php                    |    
|    2.tomcat                 |         
|    3.返回主菜单             |
|    4.退出程序               | 
|                             |
|  `date "+%F %H:%M:%S"`        |
|_____________________________|
(\__/) ||               
(•ㅅ•) ||               
/ 　 づv\e[0m"
read -p "请输入你的指示:" I
case $I in
1|php)
        PHP
        continue
        ;;
2|tomcat)
        Tomcat
        continue
        ;;
3|返回主菜单)
        echo "返回主菜单"
        break
        ;;
4|退出程序)
        echo "谢谢使用"
        exit
        ;;
        esac
done
}
```

# 3，设计架构图（负载，lnmp/lnmt）传统架构设计图。（考虑10w并发）

**因为nginx处理并发量连接数2~3万，使用五台机器搭建Nginx负载均衡，用哈希算法将请求分发到tomcat节点上。再通过Redis存放热点数据，加快对热点数据查询的速度，布隆过滤器防止缓存穿透。搭建MySQL主从同步，用MHA实现高可用，并使用MyCat实现主写从读（读写分离）。**



![image-20220915235138940](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209152351985.png)













