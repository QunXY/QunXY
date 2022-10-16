# 09-03

# 一、mysql与mongodb数据异构平台互相迁移（mysql到mongodb，mongodb到mysql）。

示例sql：
select concat("hmset city_",id," id ",id," name ",name," countrycode ",countrycode," district ",district," population ",population) from city limit 10 into outfile '/tmp/hmset.txt'
db.t1.insert city_ ({id:1,name:sss,countrycode:xx, district:sss,population:1000})

## 1.myqsl到mongodb

**mysql：**

**导出数据**

```mysql
PangHu [(none)]source /opt/t100w.sql
PangHu [test]show tables;
+----------------+
| Tables_in_test |
+----------------+
| t100w          |
+----------------+
1 row in set (0.00 sec)
PangHu [test]select * from test.t100w limit 30 into outfile '/tmp/t100w.csv' fields terminated by ',';
Query OK, 30 rows affected (0.00 sec)
PangHu [test]desc t100w;				#可以看到头一行子列段(id,num,k1,k2.dt)，等会导入mongodb时要用到。
+-------+-----------+------+-----+-------------------+-----------------------------+
| Field | Type      | Null | Key | Default           | Extra                       |
+-------+-----------+------+-----+-------------------+-----------------------------+
| id    | int(11)   | YES  |     | NULL              |                             |
| num   | int(11)   | YES  |     | NULL              |                             |
| k1    | char(2)   | YES  |     | NULL              |                             |
| k2    | char(4)   | YES  |     | NULL              |                             |
| dt    | timestamp | NO   |     | CURRENT_TIMESTAMP | on update CURRENT_TIMESTAMP |
+-------+-----------+------+-----+-------------------+-----------------------------+
[root@home4 opt]# sz /tmp/t100w.csv 					#导出到桌面看一看
```

![image-20220903193311854](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209031933932.png)

**mongodb:**

**导入数据**

```mysql
[root@home2 opt]# mongoimport -uroot -p123 --port 27017 --authenticationDatabase admin -d test -c t100w --type=csv -f id,num,k1,k2,dt --file  /opt/t100w.csv 				    #-f 里填刚刚在mysql看到的表结构头行
2022-09-03T19:40:28.911+0800	connected to: localhost:27017
2022-09-03T19:40:28.916+0800	imported 30 documents
[root@home2 opt]# mongo -uroot -p123 -port 27017
MongoDB shell version v3.6.23
connecting to: mongodb://127.0.0.1:27017/?gssapiServiceName=mongodb
Implicit session: session { "id" : UUID("a3cfa9e1-03f5-4743-b5a5-09188ba3fa63") }
MongoDB server version: 3.6.23
Server has startup warnings: 
2022-09-03T18:23:09.319+0800 I CONTROL  [initandlisten] 
2022-09-03T18:23:09.319+0800 I CONTROL  [initandlisten] ** WARNING: Access control is not enabled for the database.
2022-09-03T18:23:09.320+0800 I CONTROL  [initandlisten] **          Read and write access to data and configuration is unrestricted.
2022-09-03T18:23:09.320+0800 I CONTROL  [initandlisten] 
> use test
switched to db test
> show tables
t100w
> db.t100w.find()
{ "_id" : ObjectId("63133d2c076c9549792e15e9"), "id" : 1, "num" : 25503, "k1" : "0M", "k2" : "IJ56", "dt" : "2019-08-12 11:41:16" }
{ "_id" : ObjectId("63133d2c076c9549792e15ea"), "id" : 2, "num" : 756660, "k1" : "rx", "k2" : "bc67", "dt" : "2019-08-12 11:41:16" }
{ "_id" : ObjectId("63133d2c076c9549792e15eb"), "id" : 3, "num" : 876710, "k1" : "2m", "k2" : "tu67", "dt" : "2019-08-12 11:41:16" }
{ "_id" : ObjectId("63133d2c076c9549792e15ec"), "id" : 4, "num" : 279106, "k1" : "E0", "k2" : "VWtu", "dt" : "2019-08-12 11:41:16" }
{ "_id" : ObjectId("63133d2c076c9549792e15ed"), "id" : 5, "num" : 641631, "k1" : "At", "k2" : "rsEF", "dt" : "2019-08-12 11:41:16" }
{ "_id" : ObjectId("63133d2c076c9549792e15ee"), "id" : 6, "num" : 584039, "k1" : "QJ", "k2" : "VWlm", "dt" : "2019-08-12 11:41:16" }
{ "_id" : ObjectId("63133d2c076c9549792e15ef"), "id" : 7, "num" : 541486, "k1" : "vc", "k2" : "ijKL", "dt" : "2019-08-12 11:41:16" }
{ "_id" : ObjectId("63133d2c076c9549792e15f0"), "id" : 8, "num" : 771751, "k1" : 47, "k2" : "ghLM", "dt" : "2019-08-12 11:41:16" }
{ "_id" : ObjectId("63133d2c076c9549792e15f1"), "id" : 9, "num" : 752847, "k1" : "aQ", "k2" : "CDno", "dt" : "2019-08-12 11:41:16" }
{ "_id" : ObjectId("63133d2c076c9549792e15f2"), "id" : 10, "num" : 913759, "k1" : "ej", "k2" : "EFfg", "dt" : "2019-08-12 11:41:16" }
{ "_id" : ObjectId("63133d2c076c9549792e15f3"), "id" : 11, "num" : 854170, "k1" : "sW", "k2" : "bcWX", "dt" : "2019-08-12 11:41:16" }
{ "_id" : ObjectId("63133d2c076c9549792e15f4"), "id" : 12, "num" : 857349, "k1" : 25, "k2" : "89kl", "dt" : "2019-08-12 11:41:16" }
{ "_id" : ObjectId("63133d2c076c9549792e15f5"), "id" : 13, "num" : 27778, "k1" : "Vs", "k2" : "mnij", "dt" : "2019-08-12 11:41:16" }
{ "_id" : ObjectId("63133d2c076c9549792e15f6"), "id" : 14, "num" : 636589, "k1" : "TM", "k2" : "34PQ", "dt" : "2019-08-12 11:41:16" }
{ "_id" : ObjectId("63133d2c076c9549792e15f7"), "id" : 15, "num" : 220092, "k1" : "j2", "k2" : "78op", "dt" : "2019-08-12 11:41:16" }
{ "_id" : ObjectId("63133d2c076c9549792e15f8"), "id" : 16, "num" : 944541, "k1" : "yu", "k2" : "EFDE", "dt" : "2019-08-12 11:41:16" }
{ "_id" : ObjectId("63133d2c076c9549792e15f9"), "id" : 17, "num" : 715885, "k1" : "pz", "k2" : "wxIJ", "dt" : "2019-08-12 11:41:16" }
{ "_id" : ObjectId("63133d2c076c9549792e15fa"), "id" : 18, "num" : 408111, "k1" : "2s", "k2" : "XYkl", "dt" : "2019-08-12 11:41:16" }
{ "_id" : ObjectId("63133d2c076c9549792e15fb"), "id" : 19, "num" : 4156, "k1" : "GB", "k2" : "PQab", "dt" : "2019-08-12 11:41:16" }
{ "_id" : ObjectId("63133d2c076c9549792e15fc"), "id" : 20, "num" : 959669, "k1" : "aa", "k2" : 8989, "dt" : "2019-08-12 11:41:16" }
Type "it" for more
> 																		#数据异构迁移成功
```



## 2.mongodb到mysql

**mongodb:**

**生成数据并导出**

```mysql
> use panghu
switched to db panghu
> for(i=1;i<100;i++){ db.test.insert({"id":i,"name":"panghu","age":18,"date":new Date()}); }
WriteResult({ "nInserted" : 1 })
[root@home2 ~]# mongoexport -uroot -p123 --port 27017 --authenticationDatabase admin -d panghu -c test --type=csv --noHeaderLine -f id,name,age,date -o /mongodb/test.csv
2022-09-03T19:03:29.547+0800	connected to: localhost:27017
2022-09-03T19:03:29.548+0800	exported 99 records
[root@home2 ~]# sz /mongodb/test.csv						#导出到桌面查看
```

![image-20220903190559060](https://typora-1312877059.cos.ap-nanjing.myqcloud.com/typora/202209031905205.png)

**mysql:**

**导入数据**

**因为mongodb只能导出合集(也就是表)内容，所以我们在导入前要在mysql先创建一个一模一样的表**

```mysql
PangHu [test]create database panghu charset utf8mb4;
Query OK, 1 row affected (0.00 sec)

PangHu [test]use panghu
Database changed

PangHu [panghu]create table test( id int(11) NOT NULL AUTO_INCREMENT, name varchar(255) NOT NULL, age int NOT NULL, date datetime NOT
NULL DEFAULT CURRENT_TIMESTAMP,PRIMARY KEY (`id`))charset utf8mb4;
Query OK, 0 rows affected (0.01 sec)

PangHu [panghu]LOAD DATA LOCAL INFILE '/opt/test.csv' INTO TABLE test CHARSET utf8mb4 FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' (`id`,`name`,`age`,`date`);
Query OK, 99 rows affected, 103 warnings (0.01 sec)
Records: 100  Deleted: 0  Skipped: 1  Warnings: 103

PangHu [panghu]select * from panghu.test limit 10;
+----+--------+-----+---------------------+
| id | name   | age | date                |
+----+--------+-----+---------------------+
|  1 | panghu |  18 | 2022-09-03 10:59:26 |
|  2 | panghu |  18 | 2022-09-03 10:59:26 |
|  3 | panghu |  18 | 2022-09-03 10:59:26 |
|  4 | panghu |  18 | 2022-09-03 10:59:26 |
|  5 | panghu |  18 | 2022-09-03 10:59:26 |
|  6 | panghu |  18 | 2022-09-03 10:59:26 |
|  7 | panghu |  18 | 2022-09-03 10:59:26 |
|  8 | panghu |  18 | 2022-09-03 10:59:26 |
|  9 | panghu |  18 | 2022-09-03 10:59:26 |
| 10 | panghu |  18 | 2022-09-03 10:59:26 |
+----+--------+-----+---------------------+
10 rows in set (0.00 sec)												#数据异构迁移成功

```

# 二、昨天脚本增加分片集群的功能（该功能下增加分片算法选择（1，id范围 2，id hash））

```shell
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
read -p "清输入你需要的分片数量:" Shardingnum
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
echo -e "\e[36m
Router:
$mongosnode 	

ShardingMain:
`cat /opt/Mastermem`

config server:
`cat /opt/configport | sed -n 's/127.0.0.1://p' | awk -F "[ ,]+" '{print $1}'`\e[0m"
rm -rf /opt/configport
rm -rf /opt/Mastermem
}





Id_Range (){
echo -e "\e[36m
_____________________________
|                            |
|         范围分片           |  
|                            |       
|   `date "+%F|%H:%M:%S"`      |
|____________________________|
(\__/) ||               
(•ㅅ•) ||               
/ 　 づv\e[0m"
read -p "请输入你router的端口号:" rport
read -p "请输入你要激活分片的库:" database
read -p "请输入你要激活分片的合集(表):" collection
mongo --port $rport admin << EOF
db.runCommand( { enablesharding : "$database" } )
use $database
db."$collection".ensureIndex( { id: 1 } )
use admin
db.runCommand( { shardcollection : "$database.$collection",key : {id: 1} } )
EOF

}

Id_Hash (){
echo -e "\e[36m
_____________________________
|                            |
|         哈希分片           |  
|                            |       
|   `date "+%F|%H:%M:%S"`      |
|____________________________|
(\__/) ||               
(•ㅅ•) ||               
/ 　 づv\e[0m"
read -p "请输入你router的端口号:" rport
read -p "请输入你要激活分片的库:" database
read -p "请输入你要激活分片的合集(表):" collection
mongo --port $rport admin << EOF
db.runCommand( { enablesharding : "$database" } )
use $database
db."$collection".ensureIndex( { id: "hashed" } )
use admin
sh.shardCollection( "$database.$collection", { id: "hashed" } )
EOF

}




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
|     6.分片集群             |
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
```

