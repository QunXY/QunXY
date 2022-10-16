MySQL5.7多实例安装

```sh
#!/bin/bash
##前提：数据库版本唯一，（比如只有5.7）开启多实例。一台服务器安装多台数据库服务器实例。
read -p "请确认你的母版本mysql安装目录在/usr/local/mysql 下" var1
if test $var1 -eq 0 ; then 

/etc/init.d/mysqld stop
#备份原有的my.cnf文件
mv /etc/my.cnf /etc/my.cnf.bak
#创建各个数据库实例所需目录-
mkdir -p /data/330{7,8,9}/data

#准备各个实例的配置文件
cat > /data/3307/my.cnf <<EOF
[mysqld]
basedir=/usr/local/mysql
datadir=/data/3307/data
socket=/data/3307/mysql.sock
log_error=/data/3307/mysql.log
port=3307
server_id=7
log_bin=/data/3307/mysql-bin
EOF

cat > /data/3308/my.cnf <<EOF
[mysqld]
basedir=/usr/local/mysql
datadir=/data/3308/data
socket=/data/3308/mysql.sock
log_error=/data/3308/mysql.log
port=3308
server_id=8
log_bin=/data/3308/mysql-bin
EOF

cat > /data/3309/my.cnf <<EOF
[mysqld]
basedir=/usr/local/mysql
datadir=/data/3309/data
socket=/data/3309/mysql.sock
log_error=/data/3309/mysql.log
port=3309
server_id=9
log_bin=/data/3309/mysql-bin
EOF

#进行数据库初始化
mysqld --initialize-insecure  --user=mysql --datadir=/data/3307/data --basedir=/usr/local/mysql
mysqld --initialize-insecure  --user=mysql --datadir=/data/3308/data --basedir=/usr/local/mysql
mysqld --initialize-insecure  --user=mysql --datadir=/data/3309/data --basedir=/usr/local/mysql
#授权刚才创建的目录。（更改目录用户以及用户组）
chown -R mysql.mysql /data/*
#创建systemd启动脚本(模板文件)--> 键盘接收
echo "[Unit]
Description=MySQL Server
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target
[Install]
WantedBy=multi-user.target
[Service]
User=mysql
Group=mysql
ExecStart=/usr/local/mysql/mysqld --defaults-file=/etc/my.cnf
LimitNOFILE = 5000" >/etc/systemd/system/mysqld.service
#生成各个实例的启动脚本
cd /etc/systemd/system
cp mysqld.service mysqld3307.service
cp mysqld.service mysqld3308.service
cp mysqld.service mysqld3309.service
#更改ExecStart处
sed -i 's/=\/etc\/my.cnf/=\/data\/3307\/my.cnf/' mysqld3307.service
sed -i 's/=\/etc\/my.cnf/=\/data\/3308\/my.cnf/' mysqld3308.service
sed -i 's/=\/etc\/my.cnf/=\/data\/3309\/my.cnf/' mysqld3309.service
#启动服务-需要重新载入systemd的脚本配置
systemctl daemon-reload
systemctl start mysqld3307.service
systemctl start mysqld3308.service
systemctl start mysqld3309.service
#验证
netstat -lnp|grep 330
mysql -S /data/3307/mysql.sock -e "select @@server_id"
mysql -S /data/3308/mysql.sock -e "select @@server_id"
mysql -S /data/3309/mysql.sock -e "select @@server_id"

if test $? -eq 0 ; then
echo 'nice!'
else
exit
fi

fi

```

