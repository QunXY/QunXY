# CentOS7.6升级gcc到8.3.0版本



```sh
#!/bin/bash
#下载源码包，并解压
cd /usr/local/src
wget http://ftp.tsukuba.wide.ad.jp/software/gcc/releases/gcc-8.3.0/gcc-8.3.0.tar.gz
tar zxf gcc-8.3.0.tar.gz && cd gcc-8.3.0
yum -y install bzip2
yum -y install flex
#安装gcc依赖库
./contrib/download_prerequisites
#在新目录中配置、编译、安装
mkdir build 
cd build
../configure --prefix=/usr/local/gcc --enable-languages=c,c++ --disable-multilib
#编译时间-4核预计一个钟，尽量把虚拟机核心数给满
make -j$(nproc)
make install
#修改软链接后查看gcc版本
mv /usr/bin/gcc /usr/bin/gcc_old
ln -s /usr/local/gcc/bin/gcc /usr/bin/gcc
mv /usr/bin/g++ /usr/bin/g++_old
ln -s /usr/local/gcc/bin/g++ /usr/bin/g++
gcc -v
g++ --version
```



参考来源：[CentOS7升级gcc - 难止汗 - 博客园 (cnblogs.com)](https://www.cnblogs.com/NanZhiHan/p/11010130.html)

## 二进制安装：

```sh
mv /usr/bin/gcc /usr/bin/gcc_old
ln -s /usr/local/src/gcc-12.2.0/ /usr/bin/gcc
mv /usr/bin/g++ /usr/bin/g++_old
ln -s /usr/local/src/gcc-12.2.0/ /usr/bin/g++
gcc -v
g++ --version
```

