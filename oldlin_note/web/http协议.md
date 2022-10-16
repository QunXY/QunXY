![image-20220919224806692](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202209192248068.png)



1.用户输入url域名

2.DNS解析：查找域名对应的ip地址（获得域名对应的ip地址）

3.tcp3次握手：用户通过ip地址与对应的服务器建立连接（与服务器连接）

4.http请求报文：建立tcp连接后，用户向服务器索要指定的内容（页面，图片，视频.…）（向服务索要内容）

5.服务器通过查找

6.http响应报文：找到后把用户要的内容，返还给用户（服务型响应用户）

7.tcp4次挥手：用户与服务器断开连接



http协议：

| 版本     |                                                              |
| -------- | ------------------------------------------------------------ |
| http 1.0 | 只保持短暂的连接，浏览器的每次请求都需要与服务器建立一个TCP连接 |
| http 1.1 | 支持http长连接(Keep-Alive)                                   |
| http 2.0 | 1.1超级升级版                                                |

https://http2.akamai.com/demo





![image-20220919231138919](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202209192311156.png)







请求报文



![image-20220919233948918](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202209192339252.png)







响应报文



![image-20220920082616456](https://note-1308251438.cos.ap-guangzhou.myqcloud.com/typora/202209200826551.png)



状态码

| 200  | 成功               |      |
| ---- | ------------------ | ---- |
| 30x  | 重定向出错，客户端 |      |
| 40x  | 服务端数据有问题   |      |
| 50x  | 重定向出错，服务端 |      |







小结

响应报文起始行：状态码

响应头：

o Server服务器名称及版本

o Content-Type:文件类型 mime types(媒体类型)

oContent-Length:文件大小字节)

空行

响应报文主体







3.衡量网站访问的指标

1.IP ：访问网站的独立的公网ip

2.PV ：page view页面访问量

3.UV： Unique Vistor独立访客数（用户）



统计方法

1.第三方工具统计

alexa.chinaz.com

2.运维统计

监控软件，piwik(matomo)https://demo.matomo.cloud/

三剑客



















































