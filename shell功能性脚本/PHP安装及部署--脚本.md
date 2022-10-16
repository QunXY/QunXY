PHP安装及部署--脚本

```sh
#!/bin/bash
#清理环境
pkill php-fpm
rm -rf /usr/local/php
rm -rf /usr/bin/php-fpm
rm -rf /etc/init.d/php-fpm
#下载php.libzip.tar包
cd /opt
wget https://www.php.net/distributions/php-7.4.30.tar.gz
wget --no-check-certificate https://libzip.org/download/libzip-1.9.2.tar.gz
tar xf php-7.4.30.tar.gz
tar xf libzip-1.9.2.tar.gz
#自己排错需要的依赖
yum install autoconf  gcc  libxml2-devel openssl-devel curl-devel libjpeg-devel libpng-devel libXpm-devel freetype-devel libmcrypt-devel make ImageMagick-devel  libssh2-devel gcc-c++ cyrus-sasl-devel -y
#授权用户
groupadd www
useradd -g www www
#安装升级cmake
wget https://cmake.org/files/v3.5/cmake-3.5.2.tar.gz
tar xf cmake-3.5.2.tar.gz
cd cmake-3.5.2
./bootstrap --prefix=/usr
gmake -j $(nproc) && make install
#检测是否安装成功安装
cmake --version
#libzip预编译,安装
cd /opt/libzip-1.9.2
mkdir build
cd build 
cmake ..
make -j $(nproc) && make install
#安装需要依赖的oniguruma等库
cd /opt/libzip-1.9.2
mkdir build
cd build 
cmake ..
make -j $(nproc) && make install
#php预编译
cd /opt/php-7.4.30
#老刘头的
mkdir -p /usr/local/php/etc/php.d
./configure  --prefix=/usr/local/php \
        --with-config-file-path=/usr/local/php/etc \
        --with-config-file-scan-dir=/usr/local/php/etc/php.d \
        --disable-ipv6 \
        --enable-bcmath \
        --enable-calendar \
        --enable-exif \
        --enable-fpm \
        --with-fpm-user=www \
        --with-fpm-group=www \
        --enable-ftp \
        --enable-gd-jis-conv \
        --enable-gd-native-ttf \
        --enable-inline-optimization \
        --enable-mbregex \
        --enable-mbstring \
        --enable-mysqlnd \
        --enable-opcache \
        --enable-pcntl \
        --enable-shmop \
        --enable-soap \
        --enable-sockets \
        --enable-static \
        --enable-sysvsem \
        --enable-wddx \
        --enable-xml \
        --with-curl \
        --with-gd \
        --with-jpeg-dir \
        --with-freetype-dir \
        --with-xpm-dir \
        --with-png-dir \
        --with-gettext \
        --with-iconv \
        --with-libxml-dir \
        --with-mcrypt \
        --with-mhash \
        --with-mysqli \
        --with-pdo-mysql \
        --with-pear \
        --with-openssl \
        --with-xmlrpc \
        --with-zlib \
        --disable-debug \
        --disable-phpdbg
 #php编译安装
make -j $(nproc) && make install
/usr/local/php/bin/php -v
echo "以上为PHP安装的版本"
cd /opt/php-7.4.30
#配置php-fpm
cp /opt/php-7.4.30/php.ini-production /etc/php.ini
cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf
cp /opt/php-7.4.30/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
chmod +x /etc/init.d/php-fpm
/etc/init.d/php-fpm start
```



网页显示php配置：

```sh
#配置openresty(nginx加强版)
vim /usr/local/openresty/nginx/html/index.php
#写入
<?php phpinfo(); ?>
#
vim /usr/local/openresty/nginx/conf/nginx.conf
#文件最后一个括号内插入下面一行，也就是http{ }内最后面
include vhost/*.conf;
######
mkdir /usr/local/openresty/nginx/conf/vhost &&cd /usr/local/openresty/nginx/conf/vhost
vim myphp.conf <<EOF
server {
   root html;
   index  index.html  index.htm  index.php;

location ~ \.php$ {
        root            html;
        fastcgi_pass    127.0.0.1:9000;
        fastcgi_index   index.php;
        fastcgi_param   SCRIPT_FILENAME  /usr/local/openresty/nginx/html/$fastcgi_script_name;
        include         fastcgi_params;
  }
}
EOF
#打开网页输入https://<ip> 出现php页面-配置成功
```





#下面这个时网上找的预编译

```sh
 ./configure --prefix=/usr/local/php --with-curl --with-freetype-dir --with-gd --with-gettext --with-iconv-dir --with-kerberos --with-libdir=lib64 --with-libxml-dir --with-mysqli --with-openssl --with-pcre-regex --with-pdo-mysql --with-pdo-sqlite --with-pear --with-png-dir --with-jpeg-dir --with-xmlrpc --with-xsl --with-zlib --with-bz2 --with-mhash --enable-fpm --enable-bcmath --enable-libxml --enable-inline-optimization --enable-mbregex --enable-mbstring --enable-opcache --enable-pcntl --enable-shmop --enable-soap --enable-sockets --enable-sysvsem --enable-sysvshm --enable-xml --enable-zip --with-libzip=/usr/local/libzip
```

