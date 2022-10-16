#!/bin/bash
Mongodb_install (){
echo -e "\e[36m
_____________________________
|                            |
|        Mongodb安装         |	
|               	     |	     
|   `date "+%F|%H:%M:%S"`      |
|____________________________|
(\__/) ||               
(•ㅅ•) ||               
/ 　 づv\e[0m"
######################获取yum源库，并下载mongodb######################
cat > /etc/yum.repos.d/mongodb-org.repo << 'EOF'
[mongodb-org] 
name = MongoDB Repository
baseurl = https://mirrors.aliyun.com/mongodb/yum/redhat/$releasever/mongodb-org/3.6/x86_64/
gpgcheck = 1 
enabled = 1 
gpgkey = https://www.mongodb.org/static/pgp/server-3.6.asc
EOF
yum clean all
yum makecache
yum install -y mongodb-org

######################让mongodb自己管理内存######################
cat >> /etc/rc.local << EOF
if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
  echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
   echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi
EOF
source /etc/rc.local

###################开启mongodb#########################
systemctl start mongod
systemctl enable mongod

}

Replication_Set (){
echo -e "\e[36m
_____________________________
|                            |
|        部署副本集          |  
|                            |       
|   `date "+%F|%H:%M:%S"`      |
|____________________________|
(\__/) ||               
(•ㅅ•) ||               
/ 　 づv\e[0m"
read -p "请输入副本集的节点数量:" num
num=$[28017+$num-1]
read -p "请输入你要作为主节点的端口号(28017~$num):" port
n=0
for (( i=28017;i<=$num;i++ ))
do
	mkdir -p /mongodb/$i/conf /mongodb/$i/data /mongodb/$i/log
	cat > /mongodb/$i/conf/mongod.conf << EOF
systemLog:
  destination: file
  path: /mongodb/$i/log/mongodb.log
  logAppend: true
storage:
  journal:
    enabled: true
  dbPath: /mongodb/$i/data
  directoryPerDB: true
  #engine: wiredTiger
  wiredTiger:
    engineConfig:
      cacheSizeGB: 1
      directoryForIndexes: true
    collectionConfig:
      blockCompressor: zlib
    indexConfig:
      prefixCompression: true
processManagement:
  fork: true
net:
  bindIp: 127.0.0.1
  port: $i
replication:
  oplogSizeMB: 2048
  replSetName: my_repl
EOF
	chown -R mongod:mongod /mongodb
	/bin/mongod -f /mongodb/$i/conf/mongod.conf
	if [ $i -ne $num ]
	then
		echo "{_id: $n, host: \"127.0.0.1:$i\"}," >> /opt/Slaveip.txt
	else
		echo "{_id: $n, host: \"127.0.0.1:$i\"}" >> /opt/Slaveip.txt
	fi	
	n=$[$n+1]
done
command=`cat /opt/Slaveip.txt`
mongo -port $port admin <<EOF
config = {_id: 'my_repl', members: [$command]}
rs.initiate(config)
exit
EOF
echo -e "\e[32m正在查询主从状态请耐心等待！\e[0m"
sleep 14
mongo -port $port admin <<EOF
rs.status()
exit
EOF
rm -rf /opt/Slaveip.txt

}

Arbiter (){
echo -e "\e[36m
_____________________________
|                            |
|          Arbiter           |  
|                            |       
|   `date "+%F|%H:%M:%S"`      |
|____________________________|
(\__/) ||               
(•ㅅ•) ||               
/ 　 づv\e[0m"
Nodenum=`ls /mongodb/ | wc -l`
if [ $[$Nodenum%2] -eq 0 ]
then
	echo -e "\e[32m您的节点数量为偶数,不需要部署Arbiter\e[0m"
else
	echo -e "\e[31m您的节点数量为奇数,部署Arbiter\e[0m"
	echo -e "\e[34m现在为您部署仲裁者Arbiter\e[0m"
	read -p "请输入你的主库(主节点)的端口:" port
	num=`ls /mongodb/ | sort -n | awk 'END{print $0}'`
	num=$[$num+1]
	mkdir -p /mongodb/$num/conf /mongodb/$num/data /mongodb/$num/log
	cat > /mongodb/$num/conf/mongod.conf << EOF
systemLog:
  destination: file
  path: /mongodb/$num/log/mongodb.log
  logAppend: true
storage:
  journal:
    enabled: true
  dbPath: /mongodb/$num/data
  directoryPerDB: true
  #engine: wiredTiger
  wiredTiger:
    engineConfig:
      cacheSizeGB: 1
      directoryForIndexes: true
    collectionConfig:
      blockCompressor: zlib
    indexConfig:
      prefixCompression: true
processManagement:
  fork: true
net:
  bindIp: 127.0.0.1
  port: $num
replication:
  oplogSizeMB: 2048
  replSetName: my_repl
EOF
	chown -R mongod:mongod /mongodb
	/bin/mongod -f /mongodb/$num/conf/mongod.conf
mongo -port $port admin <<EOF
rs.addArb("127.0.0.1:$num")
EOF

fi

}

Hidden_delay (){
echo -e "\e[36m
_____________________________
|                            |
|       hidden+delay         |  
|                            |       
|   `date "+%F|%H:%M:%S"`      |
|____________________________|
(\__/) ||               
(•ㅅ•) ||               
/ 　 づv\e[0m"
read -p "请输入你的主库(主节点)的端口号:" port
mongo --port $port admin <<EOF | grep -E 'name|stateStr|_id'
rs.status()
EOF

echo -e "\e[31m
+++++++++++++++++++++++++++++++
|			      |
|   从上往下排,按顺序往下排   |
|   第一个算0,第二个是1       |
|		              |
+++++++++++++++++++++++++++++++\e[0m"
read -p "请选择你要隐藏的节点(0~N):" node
read -p "请输入你要延迟的秒数:" seconds
mongo --port $port admin <<EOF
cfg=rs.conf() 
cfg.members[$node].priority=0
cfg.members[$node].hidden=true
cfg.members[$node].slaveDelay=$seconds
rs.reconfig(cfg)
EOF

}

Read_only () {
echo -e "\e[36m
_____________________________
|                            |
|         Read Only          |  
|                            |       
|   `date "+%F|%H:%M:%S"`      |
|____________________________|
(\__/) ||               
(•ㅅ•) ||               
/ 　 づv\e[0m"
read -p "请输入你副本集的主节点(端口号):" port
echo -e "\e[36m现在获取副本集中的从节点ip端口,配置所有从节点为只读。\e[0m"
Snum=`mongo -port $port admin << EOF | egrep 'name|stateStr' | grep SECONDARY | wc -l
rs.status()
EOF
`
if [[ $Snum -gt 0 ]]
then
for (( i=1;i<=$Snum;i++ ))
do
	Sport=`mongo -port $port admin << EOF | egrep 'name|stateStr' |xargs -i  echo -n {} | sed -n 's/name/\n/gp' | egrep -v 'PRIMARY|ARBITER' | tail -$Snum | awk '{print $2}' | awk -F "[: ,]+" '{print $2}' | sed -n ""$i"p"
rs.status()
EOF
`
	mongo -port $Sport admin << EOF
rs.secondaryOk()
EOF
done
else
	echo -e "\e[31m你没有从节点！请检测副本集部署。\e[0m"
fi
}

Sharding_built () {
echo -e "\e[36m
_____________________________
|                            |
|       搭建分片集群         |  
|                            |       
|   `date "+%F|%H:%M:%S"`      |
|____________________________|
(\__/) ||               
(•ㅅ•) ||               
/ 　 づv\e[0m"
read -p "清输入你需要的分片数量" Shardingnum
Nodenum=38017
##########################################分片##########################################
for (( i=1;i<=Shardingnum;i++ ))
do
	for (( j=1;j<=3;j++ ))
	do
		mkdir -p /mongodb/$Nodenum/conf  /mongodb/$Nodenum/log  /mongodb/$Nodenum/data
		cat >  /mongodb/$Nodenum/conf/mongodb.conf  <<EOF
systemLog:
  destination: file
  path: /mongodb/$Nodenum/log/mongodb.log   
  logAppend: true
storage:
  journal:
    enabled: true
  dbPath: /mongodb/$Nodenum/data
  directoryPerDB: true
  #engine: wiredTiger
  wiredTiger:
    engineConfig:
      cacheSizeGB: 1
      directoryForIndexes: true
    collectionConfig:
      blockCompressor: zlib
    indexConfig:
      prefixCompression: true
net:
  bindIp: 127.0.0.1
  port: $Nodenum
replication:
  oplogSizeMB: 2048
  replSetName: sh$i
sharding:
  clusterRole: shardsvr
processManagement: 
  fork: true
EOF
		chown -R mongod:mongod /mongodb
		/bin/mongod -f  /mongodb/$Nodenum/conf/mongodb.conf
		if [ $j -ne 3 ]
		then
			echo "127.0.0.1:$Nodenum," >> /opt/shardport$i
		else
			echo "127.0.0.1:$Nodenum" >> /opt/shardport$i	
		fi
		if [ $j -ne 3 ]
		then
			echo "{_id: $[$j-1], host: \"127.0.0.1:$Nodenum\"}," >> /opt/port.txt
		else	
			echo "{_id: $[$j-1], host: \"127.0.0.1:$Nodenum\",'arbiterOnly':true}" >> /opt/port.txt
			command=`cat /opt/port.txt`
			mongo -port $[$Nodenum-2] admin <<EOF
config = {_id: "sh$i", members: [$command]}
rs.initiate(config)
exit
EOF
			rm -rf /opt/port.txt	
			echo "$[$Nodenum-2]" >> /opt/Mastermem
		fi		
		Nodenum=$[$Nodenum+1]		
	done	
done
echo -e "\e[36m你的分片主节点端口分别为:
`cat /opt/Mastermem`\e[0m"
rm -rf /opt/Mastermem

##########################################config server##########################################
shnode=`ls /mongodb/ | grep "38*" | sort | awk 'END{print $0}'`
confignode=$[$shnode+1]
confignodes=$[$shnode+3]
n=0
for (( i=$confignode;i<=$confignodes;i++ ))
do
	if [ $i -ne $confignodes ]
	then
		echo "127.0.0.1:$i," >> /opt/configport
	else
		echo "127.0.0.1:$i" >> /opt/configport	
	fi
	mkdir -p /mongodb/$i/conf  /mongodb/$i/log  /mongodb/$i/data
	cat > /mongodb/$i/conf/mongodb.conf <<EOF
systemLog:
  destination: file
  path: /mongodb/$i/log/mongodb.conf
  logAppend: true
storage:
  journal:
    enabled: true
  dbPath: /mongodb/$i/data
  directoryPerDB: true
  #engine: wiredTiger
  wiredTiger:
    engineConfig:
      cacheSizeGB: 1
      directoryForIndexes: true
    collectionConfig:
      blockCompressor: zlib
    indexConfig:
      prefixCompression: true
net:
  bindIp: 127.0.0.1
  port: $i
replication:
  oplogSizeMB: 2048
  replSetName: configReplSet
sharding:
  clusterRole: configsvr
processManagement: 
  fork: true
EOF
	chown -R mongod:mongod /mongodb
	/bin/mongod  -f /mongodb/$i/conf/mongodb.conf 
	if [ $i -ne $confignodes ]
	then
		echo "{_id: $n, host: \"127.0.0.1:$i\"}," >> /opt/confignode.txt
	else
		echo "{_id: $n, host: \"127.0.0.1:$i\"}" >> /opt/confignode.txt
	fi	
	n=$[$n+1]
done
command=`cat /opt/confignode.txt`	
mongo -port $[$confignodes-2] admin <<EOF
config = {_id: 'configReplSet', members: [$command]}
rs.initiate(config)
EOF
rm -rf /opt/confignode.txt

##########################################mongos节点##########################################
configport=`cat /opt/configport | xargs -i echo -n {}`
shconode=`ls /mongodb/ | grep "38*" | sort | awk 'END{print $0}'`
mongosnode=$[$shconode+1]
mkdir -p /mongodb/$mongosnode/conf  /mongodb/$mongosnode/log 
cat > /mongodb/$mongosnode/conf/mongos.conf <<EOF
systemLog:
  destination: file
  path: /mongodb/$mongosnode/log/mongos.log
  logAppend: true
net:
  bindIp: 127.0.0.1
  port: $mongosnode
sharding:
  configDB: configReplSet/$configport
processManagement: 
  fork: true
EOF
chown -R mongod:mongod /mongodb
/bin/mongos -f /mongodb/$mongosnode/conf/mongos.conf
for (( i=1;i<=Shardingnum;i++ ))
do
	shardport=`cat /opt/shardport$i | xargs -i echo -n {}`
	mongo -port $mongosnode admin <<EOF
db.runCommand( { addshard : "sh$i/$shardport",name:"shard$i"} )
EOF
	rm -rf /opt/shardport$i
done
mongo -port $mongosnode admin <<EOF
sh.status();
EOF
rm -rf /opt/configport
}







Id_Range

Id_Hash









Sharding () {
while true
do
echo -e "\e[36m
_____________________________
|                            | 
|         分片集群           |
|      1.搭建		     |
|      2.范围算法	     |
|      3.哈希算法	     |
|                            |
|     `date "+%F|%H:%M:%S"`    |
|  请用source指令启动该脚本  |
|  8.返回主菜单  9.退出程序  |
|____________________________|
(\__/) ||               
(•ㅅ•) ||               
/ 　 づv\e[0m"
read -p "请输入你的指示:" I
case $I in
1|搭建)
	Sharding_built
	continue
	;;
2|算法范围)
        Id_Range
        continue
        ;;
3|哈希算法)
        Id_Hash
        continue
        ;;
8|返回主菜单)
	echo "返回主菜单"
	break
	;;
9|退出程序)
        echo "谢谢使用"
        exit
        ;;
        *)
        esac
done
}






while true
do
echo -e "\e[36m
_____________________________
|                            | 
|         Mongodb            |
|     1.Mongodb安装          |
|     2.部署副本集	     |	     
|     3.部署arbiter	     |
|     4.hidden+delay时延功能 |
|     5.只读    	     |
|     6.分片集群         |
|    			     |
|            	             |
|     `date "+%F|%H:%M:%S"`    |
|  请用source指令启动该脚本  |
|  9.退出程序                |
|____________________________|
(\__/) ||               
(•ㅅ•) ||               
/ 　 づv\e[0m"
read -p "请输入你的指示:" I
case $I in
1|Mongodb安装)
	Mongodb_install
	continue
	;;
2|部署副本集)
	Replication_Set
	continue
	;;
3|部署arbiter)
	Arbiter
	continue
	;;
4|hidden+delay时延功能)
        Hidden_delay
        continue
        ;;
5|只读)
        Read_only
        continue
        ;;
6|分片集群)
        Sharding
        continue
        ;;
9|退出程序)
	echo "谢谢使用"
	break
	;;
	*)
	exit
	esac
done

