**apitestweb以及apitestmanager前后端分离项目部署练习**



```sh
#!/bin/bash
#清理环境
npm uninstall yarn -g
npm uninstall npm -g
yum remove nodejs npm -y
yum install -y bzip2
#node.js 可能需要的是12.0.0版本
cd /opt
wget https://registry.npmmirror.com/-/binary/node/v12.0.0/node-v12.0.0-linux-x64.tar.xz
tar xf node-v12.0.0-linux-x64.tar.xz
mv node-v12.0.0-linux-x64 /usr/local/node-v12.0.0
rm -rf /usr/bin/node
rm -rf /usr/bin/npm
ln -s /usr/local/node-v12.0.0/bin/node /usr/bin/node
ln -s /usr/local/node-v12.0.0/bin/npm /usr/bin/npm
echo 'PATH=$PATH:/usr/local/node-v12.0.0/bin' >> /etc/profile
source /etc/profile
#查看版本
node -v
npm -v
npm install -g cnpm --registry=https://registry.npm.taobao.org 
#yarn安装
npm install -g yarn
yarn -v
#Yarn、nmp淘宝源安装
yarn config set registry https://registry.npm.taobao.org -g
yarn config set sass_binary_site http://cdn.npm.taobao.org/dist/node-sass -g
#下载解压好,进入ApiTestWeb-master目录
mkdir /apitest 
cd /apitest
wget http://192.168.1.200/package/Apimanager/ApiTestWeb-master.zip
unzip ApiTestWeb-master.zip
cd /apitest/ApiTestWeb-master
###yarn构建
npm uninstall vue-cli -g
npm install -g @vue/cli
yarn remove node-sass
yarn add node-sass@6.0.1
node-sass -v
vue -V
vue upgrade
npm install -g npm-check-updates
ncu -u
####

yarn config set ignore-engines true
yarn install --ignore-scripts
yarn serve
yarn build
echo "浏览器输入测试：http://192.168.112.128:8010/"
fi
```

![image-20220909213449202](https://boluo-1312891830.cos.ap-nanjing.myqcloud.com/%E7%AC%94%E8%AE%B0%E5%9B%BE%E7%89%87202209092134279.png)



```sh
（重新安装vue-cli-serve）（卸载）npm uninstall -g @vue/cli（安装）npm install -g @vue/cli（本条解决办法参考源：https://blog.csdn.net/shi851051279/article/details/84928798）
```

![image-20220910212139868](https://boluo-1312891830.cos.ap-nanjing.myqcloud.com/%E7%AC%94%E8%AE%B0%E5%9B%BE%E7%89%87202209102121044.png)





安装完cnpm以后，在node项目中运行：cnpm install命令时，报出“Error：Cannot find module 'fs/promises”错误。

解决方案：
1、升级Node.js版本：

清理npm缓存：npm cache clean -f
安装版本管理工具：npm install -g n
升级到最新的版本：n latest（最新版本）n stable（最新稳定版本）



Error: Cannot find module 'fs/promises'

解决方法：锁定正常运行的版本即可，package.json中 "electron-updater": "^4.3.5" 改为 "electron-updater": "4.3.5" ；
