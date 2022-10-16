#!/bin/bash
#配置阿里云 的  epel   yum 源  


cat >/etc/yum.repos.d/base.repo<<'EOF'
[base]
name=base
baseurl=https://mirrors.aliyun.com/centos/7/os/x86_64/
enabled=1
gpgcheck=0

[extras]
name=extras
baseurl=https://mirrors.aliyun.com/centos/7/extras/x86_64/
enabled=1
gpgcheck=0
EOF
cat >/etc/yum.repos.d/base.repo<<'EOF'
[epel]
name=Extra Packages for Enterprise Linux 7 - $basearch
baseurl=http://mirrors.aliyun.com/epel/7/$basearch
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
EOF

yum clean all && yum makecache fast
yum install ansible -y 
