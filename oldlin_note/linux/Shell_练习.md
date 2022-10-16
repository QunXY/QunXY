# Shell 练习

### 1.1.1 选择

#### 1.1.1.1 改变bash的提示符实际上就是改变变量（）

A:$HOME 

B:$PWD 

C:$PS1 

D:$PS2

#### 1.1.1.2 在shell脚本中，用来读取文件内各个域的内容并将其赋值给shell变量的命令是______

A:fold 

B:join 

C:tr 

D:read



#### 1.1.1.4 不是shell具有的功能和特点是（）

A：管道
 B：输入输出重定向
 C：执行后台进程
 D：处理程序命令

#### 1.1.1.5 退出交互模式的shell，应键入（）

A：<Esc> B：^q C：exit D：quit

#### 1.1.1.6 shell不仅仅是用户命令解释器，同时一种强大的编程语言，linux缺省的shell是

A:bash
 B:ruby
 C:PHP
 D:perl

#### 1.1.1.7 以下函数中，和其他函数不属于一类的是

Read pread write pwrite fseek lseek

#### 1.1.1.8 下列变量名中有效的shell变量名是:______

-2-time _2$3 trust_no_1 2004file

#### 1.1.1.9 下列对shell变量FRUTT操作，正确的是______

为变量赋值：$FRUTT=apple 显示变量的值：fruit=apple

显示变量的值：echo $FRUTT 判断变量是否有值：[ -f --$FRUTT || ]

#### 1.1.1.10在shell编程中关于$2的描述正确的是

程序后携带了两个位数参数  宏替换

程序后面携带的第二个位置参数  携带位置参数的个数

#### 1.1.1.11在shell环境下想把‘gyyx’值赋给变量company，下面哪个是正确的：

company = gyyx
 $company=gyyx
 company='gyyx'
 company=gyyx

#### 1.1.1.12下面sed删除行，下面哪个脚本是错误的是

sed -e '/man/d' filename
 sed -e '1,3d' filename
 sed -e '1,/man/d' filename
 sed -e '/man/3d' filename

#### 1.1.1.13下面表述错误的是

![0表示程序的执行名字](https://math.jianshu.com/math?formula=0表示程序的执行名字)n 表示程序的第n个参数值

$* 表示程序的所有参数个数 $$表示程序的PID

#### 1.1.1.14下列代码样例中，哪个存在错误：

for filename in $(ls) do cat $filename done

for((i=0;i<10;i++)) do echo $i done

x=1 sum=0 while [ $x -le 10 ] do let sum=sum+$x let x=x+1 done echo\ $sum

for $i in 1 2 3 4 5 do echo $i done

#### 1.1.1.15在shell脚本中，用来读取文件内各个域的内容并将其赋值给shell变量的命令是：

Fold join tr read

#### 1.1.1.16shell中如何跳出当前循环继续之后的循环

break continue exit kill

#### 1.1.1.17shell脚本中的注释符

\# // /**/ " "

#### 1.1.1.18采用bash执行shell脚本时加上哪个参数可以跟踪执行脚本过程

-x -u -f -p

#### 1.1.1.19以下命令执行后，结果为（）

Var1=abcdedf

Var2=abcded

Echo “$var1” |grep -q “$var2” && echo “yes” ||echo “no”

无结果  语法错误 yes no

#### 1.1.1.20在shell比较运算符中，数值测试“等于则为真”的是（）

-ne -ge -eq -le

### 1.1.2 填空

#### 1.1.2.1 在shell编程中，如果要访问变量值，可以变量前加一个——符号

#### 1.1.2.2 请说出以下符号在bash shell中的意义

$0 $n $# $？ $* $$ ${#aa}

#### 1.1.2.3 编写shell程序之前必须赋予该脚本_____

#### 1.1.2.4 Linux系统shell脚本第一行需写______代表什么意义_____

#### 1.1.2.5 编写shell脚本时注释符是_________

#### 1.1.2.6 shell命令“sed -i s/\r/ /g test.txt”实现的是_______

### 1.1.3 简答

#### 1.1.3.1 在shell中，$0,$n,$#,$*,$@,$？分别是什么含义？

#### 1.1.3.2 统计/var/log下文件的个数。

#### 1.1.3.3 如何将F1文件的运行结果输出到F2.txt里？

#### 1.1.3.4 写一个脚本实现判断192.168.1.0/24 网络里，当前在线的ip有哪些，能ping通则认为在哪

#### 1.1.3.5 根据以下信息：

IP_Address MAC_Address Interface Static

10.66.10.250  80:71:7A:33:CA:A7 br on

10.66.10.249 5C:50:15:7F:3B:F5 br on

将以上文件名称test.txt文件中IP_Address,MAC_Address, Interface三项下的内容取出来，值以“：”分割，并呈格式显示出来。注：

10.66.10.250:80:71:7A:33:CA:A7:br

10.66.10.249:5C:50:15:7F:3B:F5:br

#### 1.1.3.6 在shell中变量的赋值有四种方法，其中采用name=jfedu.net的方法称：

直接复制  使用read命令  使用命令行传参  使用命令输出

#### 1.1.3.7 编写一个脚本，5分钟检查一次日志，发现有暴力SSH破解现象的，提取此类IP地址，并去重，并按降序排序。

要求：同一个IP暴力破解超过10次，自动屏蔽IP地址，指定办公室IP地址（192.168.100.100）为可信任IP地址，不受屏蔽规则限制，以下为日志格式：

日志样式：

May  4  03:43:07  tz-monitor sshd{14003}: Failed password for root from 124.232.135.84 port 25251 ssh2

Myy 4 03:43:07  tz-monitor  sshd{14082}: invalid user postgres from 124.232.135.84

#### 1.1.3.8 检查OSPF route-ID配置，配置如下，请用shell编写代码，条件如下：a.检查ospf的route-id值，route-id值必须与interface LoopBack0的IP地址值相同，如果两个值不相等打印出ospf的route-id的值，并且ospf的route-id值必须以139开头，如139.xx.xx.xx，否则也打印出route-id的值

ofpf 100

route-id 139.11.0.1

area 0.0.0.0

network 139.11.0.1 0.0.0.0

network 140.11.0.0 0.0.0.3

network 140.11.0.8 0.0.0.3

network 140.11.0.16 0.0.0.3

network 140.11.0.24 0.0.0.3

network 140.11.0.32 0.0.0.3

interface LoopBack0

ip address 139.11.0.1 255.255.255.255

# 

#### 1.1.3.9 检查IP地址合规，请用shell编写代码，列出不以199或200开头的IP地址，如199.x.x.x 或200.x.x.x

Interface Physical Protocol  IP Adderss

Eth1/0/1 up up  199.11.250.1

Eth1/0/2 up up  200.11.250.5

Loop0  up up(s)  199.11.250.1

Vlan1  *down  down  unassigned

Vlan500 down  down  139.100.1.157

Vlan900 up up  140.11.250.41

#### 1.1.3.10处理以下文件内容，将域名提取并进行计数排序，如处理：



```cpp
http://www.baidu.com/index.html

http://www.baidu.com/1.html

http://post.baidu.com/index.html

http://mp3.baidu.com/index.html

http://www.baidu.com/3.html

http://post.baidu.com/2.html
```

得到如下结果：

域名的出现次数  域名

3 [www.baidu.com](https://links.jianshu.com/go?to=http%3A%2F%2Fwww.baidu.com)

2 post.baidu.com

1 mp3.baidu.com

可以使用bash/per/php任意一种

#### 1.1.3.11在单台服务器Linux操作系统环境下，写一行命令，将所有该机器的所有以“.log.bak“为后缀的文件，打包压缩并上传到ftp上，FTP地址为123.234.25.130的/home/bak文件夹

#### 1.1.3.12Linux脚本：现在要删除本机中若干文件，/root/file.list中记录了这些文件的绝对路径，请用脚本实现。/root/file.list内容范例：/tmp/1.file

#### 1.1.3.13说出shell的种类，已经常用的shell

#### 1.1.3.14下面代码会输出什么：

def f(x,1=[]);

for i in range(x);

1.append(i*i)

print 1

f(2)

f(3,[3,2,1])

f(3)

#### 1.1.3.15根据以下nginx日志信息格式，统计全天PV、UV及UV的前十、PV前十页面；分别列出状态码499、500、502按次数统计的前三位

36.110.86.173  - - [30/Otc2017:09:38:30 +0800] “POST /index.php?r=tuiguang%2Fdelete HTTP/1.1” 200  385  0.036 “[http://backend.lepu.cn/index.php?r=tuiguang%2Findex&id=535634](https://links.jianshu.com/go?to=http%3A%2F%2Fbackend.lepu.cn%2Findex.php%3Fr%3Dtuiguang%2Findex%26id%3D535634)“ “Mozilla/5.0  (windows  NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Fecko) Chrome/55.0.2883.87 Safari/537.36” “0.68”

全天PV：  全天UV： PV前十：

UV前十： 499前三： 500前三： 502前三：

#### 1.1.3.16创建一个函数，能接受两个参数；

（1）  第一个参数为URL，即可下载的文件；第二个参数为目录，即下载后保存位置；

（2）  如果用户给的目录不存在，则提示用户是否创建；如果创建就继续执行，否则函数返回一个51的错误值给调用脚本

（3）  如果给的目录存在，则下载文件；下载命令执行结束后测试文件下载成功，如果成功，则返回0给调用脚本，否则，返回52给调用脚本；

#### 1.1.3.17有一个长度为n序列，需要移除掉里面的重复元素，但是对于每种元素保留最后出现的那个。输入描述:输入包括两行

第一行为序列长度n(1≤ n≤ 50)

第二行为n个数scqucencel,以空格分隔

输出描述

输出消除重复元素之后的序列，以空格分隔，行末无空格

输入例子

100 100 100 99 99 99 100 100 100

输出例子

99 100

#### 1.1.3.18使用一个队列模拟一个栈，在空白处实现下面类中的方法即可。

class Queue(objec ):

defenqueue(self,item):

"''""入队""""

defdequcue(self):

""""出队"""

测试

q = Queue()

9 enqucue (1)

输出q [1]

q.enqueue(4)

输出q [1,4]

q.dequeue()

输出14

#### 1.1.3.19从一个网站上面分别下载100个图片，他们的网址是 [http://download.linekong.com/img/1.png](https://links.jianshu.com/go?to=http%3A%2F%2Fdownload.linekong.com%2Fimg%2F1.png) 、[http://download.linekong.com/img/2.png](https://links.jianshu.com/go?to=http%3A%2F%2Fdownload.linekong.com%2Fimg%2F2.png) ... [http://download.linekong.com/img/100.png](https://links.jianshu.com/go?to=http%3A%2F%2Fdownload.linekong.com%2Fimg%2F100.png) 批量下载100个图片文件，并找出大于500kb的文件

#### 1.1.3.20一个文本文件info.txt每行都是以逗号分隔，其中第二列都是数字，请对该文件按照第二列从小到大排列。

aa，101

bb，302

cc，222

dd，44

#### 1.1.3.21通过shell如何删除文档中的注释和空白行。

#### 1.1.3.22根据要求写出linux命令

a．显示当前目录的内容

b．以详细格式显示test用户的家目录内容，包含隐藏文件

c．进入根目录

d．显示/etc/passwd文本文件的内容

e．显示/etc/passwd文件的后十行内容

#### 1.1.3.23用netstat统计系统当前tcp连接的各种状态的连接数

#### 1.1.3.24写一个脚本，实现判断10.10.10.0/24网络里，当前在线的ip有哪些。注：能ping通则认为在线。

#### 1.1.3.25怎么把脚本添加到系统服务里，即使用service来调用。

#### 1.1.3.26统计指定文件中每个单词出现的次数；如



```bash
cat /etc/fstab

\# /etc/fstab

UUID=94e4e384-Oace-437f-bc96-057dd64f42ee / ext4 defaults.barrier=0 1 1

tmpfs  /dev/shm tmpfs defults 0 0
```

#### 1.1.3.27练习：写一个脚本

列出如下菜单给用户

disk) show disks info;

mem) show memory info;

cpu) show cpu info;

*) quit;

提示用户给出自己的选择，而后显示对应其选择的相应系统信息

#### 1.1.3.28请写出一个shell脚本希望把结构表显示出来

#### 1.1.3.29求出a.log中的waring 但是不包括waring的行

#### 1.1.3.30说明以下shell 代码，所完成的功能

n=1

while [ $n -lt 1000 ]

do

cd /root/perl_test/testdir

touch sn.txt

n=`expr $n + 1`

done

#### 1.1.3.31用最熟悉的脚本语言实现如下功能

如果在/home/pushmail目录下不存在leadtone目录，则创建该目录，并将/var/sync/bin目录下的所有文件拷贝到leadtone目承下，但是不能够拷贝文件长

度大于1M的文件。

#### 1.1.3.32根据要求写出linux命令

a．显示当前目录的内容

b．以详细格式显示test用户的家目录内容，包含隐藏文件

c．进入根目录

d．显示/etc/passwd文本文件的内容

e．显示/etc/passwd文件的后十行内容

#### 1.1.3.33查找含有特定字符的文件

#### 1.1.3.34Centos操作系统历史命令记录中，执行次数最多的5条

#### 1.1.3.35写一个脚本，判断一个指定的脚本是否是语法错误，如果有错误，则提醒用户键入Q或者q无视错误并退出其它任何键可以通过vim打开这个指定的脚本

#### 1.1.3.36用Shell编程，判断一文件是不是字符设备文件，如果是将其拷贝到 /dev 目录下

#### 1.1.3.37写一个脚本，实现批量添加20个用户，用户名为user01-20，密码user后面跟5个随机字符

#### 1.1.3.38统计nginx访问日志，找出访问次数前10的IP

#### 1.1.3.39找出在文件a中但不在文件b中的内容，用命令后编写脚本实现

#### 1.1.3.40对文件test中，1>第一列为aaa的行求和；2>对偶数行求和；3>求文件test中的最大值

#### 1.1.3.41Case语句的语法？while 语句的语法？continue命令的作用？

#### 1.1.3.42请写出下列shell脚本：使用for循环在/opt目录下通过随机小写10个字母加固定字符串test批量创建10个html文件，创建完成后将test全部改为test_done（for循环实现），并且html大写

#### 1.1.3.43在UNIX操作系统中，若用户键入的命令参数的个数为1时，执行cat ![1命令；若用户键入的命令个数为2时，执行cat >>](https://math.jianshu.com/math?formula=1命令；若用户键入的命令个数为2时，执行cat >>)2<$1命令，请将下面所示的shell程序的空缺部分补齐

Case （_____）in

cat $1

cat >>![2<](https://math.jianshu.com/math?formula=2<)1

*)echo 'defult...'

case

$#

$@

$$

$*

#### 1.1.3.44如何在每天23:59分时，将apache的accesslog中，访问次数最多的前10个ip以及访问量最多的10个文件保存到/var/Top.log中

#### 1.1.3.45写一个脚本，判断一个指定的脚本是否是语法错误。如果有错误，则提醒用户键入Q或q无视错误并退出其它任何键可以指定的脚本

#### 1.1.3.46shell脚本编程：求100以内的质数

#### 1.1.3.47如果有10个文件夹，每个文件夹都有1,000,000个url，每个url对应一个访问量，请问如何最快找出前1,000,000个访问量最高的url

#### 1.1.3.48创建一个shell脚本，它从用户那里接收10个数，并显示已输入的最大的数

#### 1.1.3.49设计一个shell程序，在每月第一天备份并压缩/etc目录的所有内容，存放在/root/bak目录里，且文件名为如下形式yymmdd_etc，yy为年，mm为月，dd为日。shell陈旭fileback存放在/usr/bin目录下

#### 1.1.3.50找出系统中父进程号为105的所有进程，并将其结束

#### 1.1.3.51如何从history记录中分析最近500次内执行最多的命令？如何查找当前目录90天以前的文件并将其删除？

#### 1.1.3.52写出命令统计当前连接到本机6379端口连接数最高的ip地址和连接个数，查看自己的ip地址，看这个ip地址所在网段都有哪些机器，任意查看此网段的另外一个ip地址有哪些端口开放了。简述tcp的几种连接状态，高并发服务器一般会遇到什么问题？

#### 1.1.3.53下面给出了一个shell程序，试对其行后有#（号码）形式的语句进行解释，并说明程序完成的功能



```bash
#!/bin/bash

DICNAME=`ls /root |grep bak`  #(1)

if [ -z "$DICNAME" ] then #(2)

mkdir /root/bak cd /root/bak #(3)

fi

YY=`date +%y` MM=`date +%m` DD=`date +%d` #(4)

BACKETC=$YY$MM$DD_etc.tar.gz #(5)

tar zcvf $BACKETC /etc #(6)

echo "fileback fiaished!"
```

#### 1.1.3.54试编写一个Shell程序，该程序能接收用户从键盘输入的100个整数，然后求出其总和、最大值及最小值

#### 1.1.3.55请用自己熟悉的脚本语言，快速替换notice服务下config.properties配置文件中所有变量值为jdbc.username,jdbc.password的值为blue和pass1234 说明：配置文件的目录/opt/blue/notice/conf/config.properties

config.properties文件格式如下：

zookeeper.server=127.0.0.1:2181

jdbc.driver=com.mysql.jdbc.Driver

jdbc.url=jdbc:[mysql://lx-db:3306/gudong](https://links.jianshu.com/go?to=mysql%3A%2F%2Flx-db%3A3306%2Fgudong)

jdbc.username=lanxin

jdbc.password=OnLIDX5

#### 1.1.3.56会哪些编程语言？写过哪种shell脚本？请现场编写一组

#### 1.1.3.57判断数字大于500则执行big.sh 小于等于500则退出脚本，并输出报错信息

#### 1.1.3.58处理以下文件内容，将域名取出并进行计数排序

[http://www.baidu.com/index.html](https://links.jianshu.com/go?to=http%3A%2F%2Fwww.baidu.com%2Findex.html)

[http://www.baidu.com/1.jpg](https://links.jianshu.com/go?to=http%3A%2F%2Fwww.baidu.com%2F1.jpg)

[http://post.baidu.com/index.php](https://links.jianshu.com/go?to=http%3A%2F%2Fpost.baidu.com%2Findex.php)

[http://mp3.baidu.com/index.jsp](https://links.jianshu.com/go?to=http%3A%2F%2Fmp3.baidu.com%2Findex.jsp)

[http://www.baidu.com/3.html](https://links.jianshu.com/go?to=http%3A%2F%2Fwww.baidu.com%2F3.html)

[http://post.baidu.com/2.bmp](https://links.jianshu.com/go?to=http%3A%2F%2Fpost.baidu.com%2F2.bmp)

得到如下结果：

域名的出现的次数  域名

3 [www.baidu.com](https://links.jianshu.com/go?to=http%3A%2F%2Fwww.baidu.com)

2 post.baidu.com

1 mp3.baidu.com

#### 1.1.3.59文件ip.txt中包含很多IP地址（以及其它非IP数据），请打印出满足A.B.C.D 其中A=172 C=130 D<=100 条件的所有IP（请用AWK实现）

#### 1.1.3.60请编写一个可递归创建3级hash目录的shell脚本，hash目录名分别为 a b c d e f 0 1 2 3 4 5 6 7 8 9 (请用bash实现)

#### 1.1.3.61统计web服务器上网络连接的各个状态（ESTABLISHED/SYN_SENT/SYN_RECV等）的个数并按倒序排列

#### 1.1.3.62脚本测试test.txt文件

1 2 3

4 5 6

7 8 9

打印出每一列的累加值

#### 1.1.3.63请在linux下写个bash shell 程序，目的如下：查找/opt/mp3目录下所有mp3后缀的文件，然后计算下每个md5值，文件名跟md5值写入新的文件mp3-md5.txt文件

#### 1.1.3.64请写出完成下面工作的Linux shell命令或脚本

（1）查看服务器的硬盘占用量

（2）将/usr/test目录下大于100K的文件转移到/tmp目录下

（3）杀死所有启动的servicefx_asr进程

（4）假设某nginx server的日志access.log如下：

198.24.230.194 - - [10/Oct/2015:10:23:50 +0800] “POST /asr/recognize HTTP/1.1 200 177 “-” ”-”

请查找在2015/10/10,10点这一个小时内，访问“/CheckAuth”接口的IP一共有几个，每个各访问了多少次

#### 1.1.3.65执行$ time sleep 2 输出如下

real 0m2.003s

user 0m0.004s

sys 0m0.000s

请说明real、user、sys三者具体代表的意思和区别

#### 1.1.3.66编写脚本完成以下工作

某目录下有两个文件a.txt和b.txt，文件格式为(ip username)，例如：

a.txt b.txt

127.0.0.1zhangsan 127.0.0..4lixiaoliu

127.0.0.1wangxiaoer 127.0.0.01lisi

127.0.0.2lisi

127.0.0.3wangwu

每个文件至少有100万行，请使用Linux命令完成下列工作

1）两个文件各自的IP数，以及总IP数

2）出现再b.txt而没有出现再a.txt的IP

3）每个username出现的次数，以及每个username对应的IP数

#### 1.1.3.67现在一个REST API服务（名称为ab-service），进程启动后占用8038端口进行网络通信。现需要一个Bash Shell脚本（start.sh），在一台Linux机器上启动这个服务，并通过8038端口对所有内外网IP服务。请写出完整的可运行脚本，并尽量考虑可能出现的情况并处理



