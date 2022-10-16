#！/bin/bush 

yum install -y sshpass
clear
. /etc/init.d/functions   ##调用这个文件
IP=`ifconfig | grep -w broadcast | awk -F "[ ]+" '{print $3}'`
IPtemp=`echo $IP|awk -F"." '{print $1"."$2"."$3"."}'`
for ip in {80,81,90} ##简单示范具体多少台据情况而定
do
##前提是密码统一的情况
sshpass -p12345 ssh-copy-id -i ~/.ssh/id_rsa.pub root@$IPtemp$ip -o StrictHostKeyChecking=no &>/dev/null
if [ $? -eq 0 ]
then
action "主机$IPtemp$ip          [分发成功]"  /bin/true
else
action  "主机$IPtemp$ip         [分发失败] " /bin/false
fi

done
