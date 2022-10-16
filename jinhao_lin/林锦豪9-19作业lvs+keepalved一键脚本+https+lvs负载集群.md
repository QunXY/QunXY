# 2022-09-19

# 1，lvs+keepalived 一键脚本（跟着其他两个负载器一起增加功能，lvs只用dr模式）

```shell
LK () {
ifconfig > /opt/address.txt
loope=`cat -n /opt/address.txt | grep BROADCAST |egrep "ens|eth" | wc -l`
for (( i=1;i<=$loope;i++ ))
do
	line=`cat -n /opt/address.txt | grep BROADCAST |egrep "ens|eth" | awk -F "[\t]+" '{print $1}' | sed -n "$i"p`
	sed -n "$line,$[$line+1]p" /opt/address.txt
done
read -p "请选择作为Linux Virtual Server(Director)所复刻的虚拟网卡：" NC
VNC="$NC:0"
ifconfig $VNC down
Getline=`cat -n /opt/address.txt | grep -w $NC | awk -F "[\t]+" '{print $1}'`
echo $Getline
NCIP=`sed -n "$Getline,$[$Getline+1]p" /opt/address.txt | grep -w broadcast | awk -F "[ ]+" '{print $3}'`
echo $NCIP
NCIPTAIL=`sed -n "$Getline,$[$Getline+1]p" /opt/address.txt | grep -w broadcast | awk -F "[. ]+" '{print $6}'`
VNCIP=`echo $NCIP | awk -F "$NCIPTAIL" '{print $1}'`233
read -p "请输入作为Linux Virtual Server(Director)备用机的IP：" IP
read -p "请输入作为Linux Virtual Server(Director)备用机的密码: " bpassword
read -p "请输入作为Real Server1的IP：" RS1
read -p "请输入作为Real Server1的主机密码：" rspassword1
read -p "请输入作为Real Server2的IP：" RS2
read -p "请输入作为Real Server2的主机密码：" rspassword2
rm -rf /opt/address.txt

#########################生成密钥，分发密钥到RS1、RS2和备用机以便后续操作#########################
yum install -y expect
if [ -f /root/.ssh/id_rsa.pub ]
then
        echo "公钥存在,现在分别发送给Real Server和Director备用机"
expect <<-EOF
fpawn ssh-copy-id root@$IP
mxpect "yes/no"
send "yes\r"
expect "password:"
send "$bpassword\r"
expect eof
EOF
expect <<-EOF
spawn ssh-copy-id root@$RS1
expect "yes/no"
send "yes\r"
expect "password:"
send "$rspassword1\r"
expect eof
EOF
expect <<-EOF
spawn ssh-copy-id root@$RS2
expect "yes/no"
send "yes\r"
expect "password:"
send "$rspassword2\r"
expect eof
EOF
else
        echo "公钥不存在，现在创建并分别发送给Real Server和Director备用机"
ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
expect <<-EOF
spawn ssh-copy-id root@$IP
expect "yes/no"
send "yes\r"
expect "password:"
send "$bpassword\r"
expect eof
EOF
expect <<-EOF
spawn ssh-copy-id root@$RS1
expect "yes/no"
send "yes\r"
expect "password:"
send "$rspassword1\r"
expect eof
EOF
expect <<-EOF
spawn ssh-copy-id root@$RS2
expect "yes/no"
send "yes\r"
expect "password:"
send "$rspassword2\r"
expect eof
EOF
fi

#########################Director主机配置和备机配置#########################
#Master#
yum install -y keepalived ipvsadm
cat > /opt/Mconf.sh << EOF
#!/bin/bash
echo 1 > /proc/sys/net/ipv4/ip_forward
ifconfig $VNC down
ifconfig $VNC $VNCIP broadcast $VNCIP netmask 255.255.255.255 up
route add -host $VNCIP dev $VNC
ipvsadm -C
ipvsadm -A -t $VNCIP:80 -s wrr
ipvsadm -a -t $VNCIP:80 -r $RS1:80 -g -w 1
ipvsadm -a -t $VNCIP:80 -r $RS2:80 -g -w 1
EOF
source /opt/Mconf.sh
rm -rf /opt/Mconf.sh

#########################RS的配置#########################
cat > /opt/RSconf.sh << EOF
#!/bin/bash
ifconfig lo:0 down
ifconfig lo:0 $VNCIP broadcast $VNCIP netmask 255.255.255.255 up
route add -host $VNCIP lo:0
echo "1" >/proc/sys/net/ipv4/conf/lo/arp_ignore
echo "2" >/proc/sys/net/ipv4/conf/lo/arp_announce
echo "1" >/proc/sys/net/ipv4/conf/all/arp_ignore
echo "2" >/proc/sys/net/ipv4/conf/all/arp_announce
EOF
scp /opt/RSconf.sh root@$RS1:/opt/
ssh -t root@$RS1 <<EOF
source /opt/RSconf.sh
rm -rf /opt/RSconf.sh
EOF
scp /opt/RSconf.sh root@$RS2:/opt/
ssh -t root@$RS2 <<EOF
source /opt/RSconf.sh
rm -rf /opt/RSconf.sh
EOF
rm -rf /opt/RSconf.sh

#########################keepalived主备配置#########################
cat > /etc/keepalived/keepalived.conf << EOF
vrrp_instance VI_1 {
 state MASTER
 interface $NC
 virtual_router_id 88
 priority 100
 advert_int 1
 authentication {
 auth_type PASS
 auth_pass 1111
 }
 virtual_ipaddress {
 $VNCIP
 }
}
virtual_server $VNCIP 80 {
 delay_loop 6
 lb_algo rr
 lb_kind DR
 persistence_timeout 0
 protocol TCP
 real_server $RS1 80 {
 weight 1
 TCP_CHECK {
 connect_timeout 10
 nb_get_retry 3
 delay_before_retry 3
 connect_port 80
 }
 }
 real_server $RS2 80 {
 weight 1
 TCP_CHECK {
 connect_timeout 10
 nb_get_retry 3
 delay_before_retry 3
 connect_port 80
 }
 }
}
EOF

systemctl start keepalived

ssh -t root@$IP <<EOF
yum install -y keepalived ipvsadm
echo 1 > /proc/sys/net/ipv4/ip_forward
ipvsadm -C
EOF
scp /etc/keepalived/keepalived.conf root@$IP:/etc/keepalived/
ssh -t root@$IP <<EOF
sed -i 's/state MASTER/state BACKUP/g' /etc/keepalived/keepalived.conf
sed -i 's/priority 100/priority 90/g' /etc/keepalived/keepalived.conf
systemctl start keepalived
EOF

}
```

# 2，lvs实现https的负载集群（自己研究，最好写到脚本里）let s encrypt(免费的https工具)

```shell
HTTPS () {
read -p "请输入VIP：" VIP
read -p "请输入DR的IP：" DR
read -p "请输入DR的密码：" DR
read -p "请输入RS1的IP(LAN区段的)：" RS1
read -p "请输入RS1的密码：" RS1password
read -p "请输入RS2的IP(LAN区段的)：" RS2
read -p "请输入RS2的密码：" RS2password

####三方免密####
ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
expect <<-EOF
spawn ssh-copy-id root@$DR
expect "yes/no"
send "yes\r"
expect "password:"
send "$DRpassword\r"
expect eof
EOF
expect <<-EOF
spawn scp -r /root/.ssh $RS1:/root/
expect "yes/no"
send "yes\r"
expect "password:"
send "$RS1password\r"
expect eof
EOF
expect <<-EOF
spawn scp -r /root/.ssh $RS2:/root/
expect "yes/no"
send "yes\r"
expect "password:"
send "$RS2password\r"
expect eof
EOF
ssh -t root@$RS1 <<eof
yum install -y expect
ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa1
expect <<-EOF
spawn ssh-copy-id root@$RS2
expect "yes/no"
send "yes\r"
expect "password:"
send "$RS2password\r"
expect eof
EOF
eof

#####生成密钥对,自签署证书####
cd /etc/pki/CA/
(umask 077;openssl genrsa -out private/lvscakey.pem 2048)
openssl rsa -in private/lvscakey.pem -pubout
openssl req -new -x509 -key private/lvscakey.pem -out lvscacert.pem -days 1024 << EOF
CN
GD
FS
jh     
jh     
jh     

EOF
touch index.txt && echo 01 > serial
####RS1生成证书签署请求，并发送给CA####
ssh -t root@$RS2 << EOF
yum install -y mod_ssl
mkdir -p /etc/httpd/ssl
EOF

ssh -t root@$RS1 << EOF
yum install -y mod_ssl
mkdir -p /etc/httpd/ssl
cd /etc/httpd/ssl
(umask 077;openssl genrsa -out httpd.key 2048)
openssl req -new -key httpd.key -days 1024 -out httpd.csr << eof
CN
GD
FS
jh     
jh     
jh     

eof
scp httpd.csr $DR:/opt
EOF

####CA签署证书并发给客户端####
cd /opt
openssl ca -in /opt/httpd.csr -out httpd.crt -days 1024 << eof
y
y
eof
scp httpd.crt root@$RS1:/etc/httpd/ssl
scp /etc/pki/CA/lvscacert.pem root@$RS1:/etc/httpd/ssl

####将RS-1的证书和密钥发给RS-2####
ssh -t root@$RS1 << EOF
cd /etc/httpd/ssl
scp lvscacert.pem httpd.crt httpd.key root@$RS2:/etc/httpd/ssl
EOF

####修改https配置文件####
ssh -t root@$RS1 << EOF
cat > /etc/httpd/conf.d/ssl.conf << eof
#   Server Certificate:
# Point SSLCertificateFile at a PEM encoded certificate.  If
# the certificate is encrypted, then you will be prompted for a
# pass phrase.  Note that a kill -HUP will prompt again.  A new
# certificate can be generated using the genkey(1) command.
SSLCertificateFile /etc/httpd/ssl/httpd.crt

#   Server Private Key:
#   If the key is not combined with the certificate, use this
#   directive to point at the key file.  Keep in mind that if
#   you've both a RSA and a DSA private key you can configure
#   both in parallel (to also allow the use of DSA ciphers, etc.)
SSLCertificateKeyFile /etc/httpd/ssl/httpd.key

#   Server Certificate Chain:
#   Point SSLCertificateChainFile at a file containing the
#   concatenation of PEM encoded CA certificates which form the
#   certificate chain for the server certificate. Alternatively
#   the referenced file can be the same as SSLCertificateFile
#   when the CA certificates are directly appended to the server
#   certificate for convinience.
#SSLCertificateChainFile /etc/pki/tls/certs/server-chain.crt

#   Certificate Authority (CA):
#   Set the CA certificate verification path where to find CA
#   certificates for client authentication or alternatively one
#   huge file containing all of them (file must be PEM encoded)
SSLCACertificateFile /etc/httpd/ssl/cacert.pem
eof
systemctl restart httpd
EOF
ssh -t root@$RS2 << EOF
cat > /etc/httpd/conf.d/ssl.conf << eof
#   Server Certificate:
# Point SSLCertificateFile at a PEM encoded certificate.  If
# the certificate is encrypted, then you will be prompted for a
# pass phrase.  Note that a kill -HUP will prompt again.  A new
# certificate can be generated using the genkey(1) command.
SSLCertificateFile /etc/httpd/ssl/httpd.crt

#   Server Private Key:
#   If the key is not combined with the certificate, use this
#   directive to point at the key file.  Keep in mind that if
#   you've both a RSA and a DSA private key you can configure
#   both in parallel (to also allow the use of DSA ciphers, etc.)
SSLCertificateKeyFile /etc/httpd/ssl/httpd.key

#   Server Certificate Chain:
#   Point SSLCertificateChainFile at a file containing the
#   concatenation of PEM encoded CA certificates which form the
#   certificate chain for the server certificate. Alternatively
#   the referenced file can be the same as SSLCertificateFile
#   when the CA certificates are directly appended to the server
#   certificate for convinience.
#SSLCertificateChainFile /etc/pki/tls/certs/server-chain.crt

#   Certificate Authority (CA):
#   Set the CA certificate verification path where to find CA
#   certificates for client authentication or alternatively one
#   huge file containing all of them (file must be PEM encoded)
SSLCACertificateFile /etc/httpd/ssl/cacert.pem
eof
systemctl restart httpd
EOF

####DR上配置规则####
ipvsadm -A -t $VIP:443 -s rr
ipvsadm -a -t $VIP:443 -r $RS1 -m
ipvsadm -a -t $VIP:443 -r $RS2 -m
}
```

