## 													[**wiki安装部署**](https://blog.csdn.net/tiny_du/article/details/119462042?utm_term=confluence如何部署&utm_medium=distribute.pc_aggpage_search_result.none-task-blog-2~all~sobaiduweb~default-6-119462042&spm=3001.4430)

Wiki系统属于一种人类知识网格系统，可以在Web的基础上对Wiki文本进行浏览、创建、更改，而且创建、更改、发布的代价远比HTML文本小；同时Wiki系统还支持面向社群的协作式写作，为协作式写作提供必要帮助；最后，Wiki的写作者自然构成了一个社群，Wiki系统为这个社群提供简单的交流工具。与其它超文本系统相比，Wiki有使用方便及开放的特点，所以Wiki系统可以帮助我们在一个社群内共享某领域的知识。

### **一.环境准备：**

confluence的运行是依赖java环境的，也就是说需要安装jdk并且要是1.7以上版本，如下：

![image-20220329164253042](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291642074.png)

### **二、安装mysql**

略 

### **三、援权confluence用户名、密码**

**（这里不能创建数据库，因为后面要配置数据库）:**

grant all on confluence.* to confluence@"%" identified by "confluence"; 

grant all on confluence.* to confluence@"localhost" identified by "confluence"; 

flush privileges;

![image-20220329164342716](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291643746.png)

### **四、安装及破解confluence**

 ![image-20220329164354103](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291643132.png)

**给bin文件提供执行权限**

 chmod 755 atlassian-confluence-6.7.1-x64.bin              

 ![image-20220329164448163](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291644186.png)

**执行这个文件进行安装**

confluence的安装需要手动输入，下面红色是提示输入信息，绿色是我实际的输入。

本实验指定了安装目录和数据目录，默认的安装目录很乱，后期数据量大不好维护，请提前安排好安装目录。

mkdir -p /home/soft/confluence 

mkdir -p /home/soft/application-data/confluence 

./atlassian-confluence-6.7.1-x64.bin              

​    ![0](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291641422.png)

安装好默认就是运行起来的，端口默认是8090。

 ![image-20220329164526021](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291645057.png)

然后就可以在浏览器上进行访问配置了。

### **五、配置过程**

#### **1、浏览器访问**

默认端口是8090，如果访问不到，可以查看是否防火墙导致的，如果是阿里云环境，请检查安全组。

可以选择中文环境，不得不说，confluence还是很给力的。

![image-20220329164544414](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291645487.png)

![image-20220329164600940](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291646996.png)



#### **2、配置选项**

如果是搭建测试可以选择使用安装，会有一段时间的试用期。

本实验选择的是产品安装，如果是生产使用，需要选择产品安装，默认是需要收费授权的。

但是可以破解，本实验只用于测试实验。

 ![image-20220329164708865](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291647906.png)

选择插件，点击第一步。

![image-20220329165010925](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291650962.png)

 然后就需要输入授权码了，需要把ID复制出来，后期会用的到。

​                B925-L24T-S6LL-5D1L              

 ![image-20220329165026615](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291650664.png)

#### **3、破解过程**

 首先需要在win电脑上安装java环境，伙伴们自行安装，这里不再介绍。

 打开破解程序。

  ![image-20220329165043475](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291650506.png)

**需要把服务器中confluence环境中的加密jar复制到桌面，并更改文件名称为atlassian-extras-2.4.jar**

下面是该文件的具体路径，和名称。

[root@localhost lib]# pwd 

/home/soft/confluence/confluence/WEB-INF/lib 

在这个目录下，名称是 atlassian-extras-decoder-v2-3.3.0.jar              

![image-20220329165121943](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291651966.png)

![image-20220329165135039](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291651078.png)

启动破解程序，按照下面的步骤，①：写入名字、②：将ID复制到栏目中、③：点击选择复制到桌面的文件、④：点击生成key。

![image-20220329165153026](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291651056.png)

第三步会打开一个新的界面，叫我们选择要修补的文件

  ![image-20220329165204931](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291652961.png)

选择刚刚我们放到桌面的哪个文件

在点击第四步就行了

  ![image-20220329165218823](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291652856.png)            

注意先不要把key导入到confluence的 授权码栏目中。 

需要先把刚才复制到桌面的jar文件，导入到confluence环境中，并改回原来的名字。

![image-20220329165322388](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291653444.png)

![image-20220329165332772](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291653805.png)

接下来重启confluence。重启文件在confluence目录下的bin目录下，可以看到confluence是在tomcat的基础进行更改的。

![image-20220329165341538](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291653572.png)

![image-20220329165351070](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291653109.png)

####  **4、进行验证**

 重启之后，重新访问confluence的8090 页面，将key进行导入，点击第一步。

 ![image-20220329165400997](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291654032.png)

####  **5、**[**选择数据库**](https://confluence.atlassian.com/doc/database-setup-for-mysql-128747.html)

 这边我选择的自己的数据库。

 ![image-20220329165427513](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291654561.png)

然后会提示说我们需要一个模块

![image-20220329165441073](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291654106.png)

![image-20220329165449171](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291654199.png)

把这个弄到/home/soft/confluence/confluence/WEB-INF/lib去

​                [root@localhost wiki]# cp ./mysql-connector-java-5.1.44-bin.jar   /home/soft/confluence/confluence/WEB-INF/lib              

![image-20220329165509032](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291655084.png)

刷新一下界面就可以看到要我们填数据库信息了

   ![image-20220329165518386](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291655430.png)

要把虚拟机的数据库服务起来

   ![image-20220329165529657](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291655690.png)

**配置 MySQL 服务器需要如下配置：**

```
[mysqld]
指定默认字符集为 utf8：

[mysqld]
...
character-set-server=utf8
collation-server=utf8_bin
...
将默认存储引擎设置为 InnoDB：

[mysqld]
...
default-storage-engine=INNODB
...
指定的值max_allowed_packet至少为 256M：

[mysqld]
...
max_allowed_packet=256M
...
将 的值指定 innodb_log_file_size 为至少 2GB：

[mysqld]
...
innodb_log_file_size=2GB
...
确保 sql_mode 参数未指定 NO_AUTO_VALUE_ON_ZERO

// remove this if it exists
sql_mode = NO_AUTO_VALUE_ON_ZERO
确保数据库的全局事务隔离级别已设置为 READ-COMMITTED。

[mysqld]
...
transaction-isolation=READ-COMMITTED
...
检查二进制日志格式是否配置为使用“基于行”的二进制日志，以及您的数据库用户是否可以创建和更改存储的函数。

[mysqld]
...
binlog_format=row
log-bin-trust-function-creators = 1
...
如果您使用的是 MySQL 5.7，请关闭“派生合并”优化器开关，因为这会导致仪表板加载缓慢。

optimizer_switch = derived_merge=off
重新启动 MySQL 服务器以使更改生效
```

​    ![image-20220329165619498](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291656537.png)

完成配置之后再去创建一个数据库

​                create database confluence;            

![image-20220329165635646](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291656667.png)

重启一下 Confluence，刷新一下界面

![image-20220329165654974](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291656015.png)

#### **6、加载内容**

然后开始加载内容，这边选择的是空白站点

 ![image-20220329165706032](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291657089.png)

然后配置用户管理。

![image-20220329165720210](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291657259.png)

账号admin 

密码123456              

![image-20220329165747148](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291657186.png)

  ![image-20220329165801591](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291658620.png)

### 六、进入wiki

​                192.168.27.171:8090              

   ![image-20220329165814416](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202203291658477.png)

