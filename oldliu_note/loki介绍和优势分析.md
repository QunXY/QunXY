# 总结下loki的优点

## 1.低索引开销
- loki和es最大的不同是 loki只对标签进行索引而不对内容索引
- 这样做可以大幅降低索引资源开销(es无论你查不查，巨大的索引开销必须时刻承担)

## 2.并发查询+使用cache
- 同时为了弥补没有全文索引带来的查询降速使用，Loki将把查询分解成较小的分片，可以理解为并发的grep
- 同时支持index、chunk和result缓存提速


## 3.和prometheus采用相同的标签，对接alertmanager
- Loki和Prometheus之间的标签一致是Loki的超级能力之一

## 4.使用grafana作为前端，避免在kibana和grafana来回切换


# 架构说明
- 地址 https://grafana.com/docs/loki/latest/architecture/

## 架构说明
![image](./loki.png)

## 组件说明

### promtail 作为采集器，类比filebeat

### loki相当于服务端，类比es

> loki 进程包含 四种角色

- querier 查询器
- ingester 日志存储器 
- query-frontend 前置查询器
- distributor 写入分发器

> 可以通过loki二进制的 -target参数指定运行角色


## read path
- 查询器接收HTTP / 1数据请求。
- 查询器将查询传递给所有ingesters 请求内存中的数据。
- 接收器接收读取的请求，并返回与查询匹配的数据（如果有）。
- 如果没有接收者返回数据，则查询器会从后备存储中延迟加载数据并对其执行查询。
- 查询器将迭代所有接收到的数据并进行重复数据删除，从而通过HTTP / 1连接返回最终数据集。

## write path
![](/img/bVcRVFp)

- 分发服务器收到一个HTTP / 1请求，以存储流数据。
- 每个流都使用散列环散列。
- 分发程序将每个流发送到适当的inester和其副本（基于配置的复制因子）。
- 每个实例将为流的数据创建一个块或将其追加到现有块中。每个租户和每个标签集的块都是唯一的。
- 分发服务器通过HTTP / 1连接以成功代码作为响应。


# 使用本地化模式安装
## 下载promtail和loki二进制

```shell script
wget  https://github.com/grafana/loki/releases/download/v2.2.1/loki-linux-amd64.zip

wget https://github.com/grafana/loki/releases/download/v2.2.1/promtail-linux-amd64.zip
```

## 找一台 linux机器做测试


##  安装promtail


```shell script

mkdir /opt/app/{promtail,loki} -pv 
/bin/cp -f  promtail-linux-amd64 /opt/app/promtail/promtail
# promtail配置文件
cat <<EOF > /opt/app/promtail/promtail.yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /var/log/positions.yaml # This location needs to be writeable by promtail.

client:
  url: http://localhost:3100/loki/api/v1/push

scrape_configs:
 - job_name: system
   pipeline_stages:
   static_configs:
   - targets:
      - localhost
     labels:
      job: varlogs  # A `job` label is fairly standard in prometheus and useful for linking metrics and logs.
      host: yourhost # A `host` label will help identify logs from this machine vs others
      __path__: /var/log/*.log  # The path matching uses a third party library: https://github.com/bmatcuk/doublestar

EOF



# service文件

cat <<EOF >/etc/systemd/system/promtail.service
[Unit]
Description=promtail server
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/opt/app/promtail/promtail -config.file=/opt/app/promtail/promtail.yaml
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=promtail
[Install]
WantedBy=default.target
EOF

systemctl daemon-reload
systemctl restart promtail 
systemctl status promtail 


```


##  安装loki
```shell script

mkdir /opt/app/{promtail,loki} -pv 
/bin/cp -f loki-linux-amd64 /opt/app/loki/loki
# promtail配置文件
cat <<EOF> /opt/app/loki/loki.yaml
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

ingester:
  wal:
    enabled: true
    dir: /opt/app/loki/wal
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 1h       # Any chunk not receiving new logs in this time will be flushed
  max_chunk_age: 1h           # All chunks will be flushed when they hit this age, default is 1h
  chunk_target_size: 1048576  # Loki will attempt to build chunks up to 1.5MB, flushing first if chunk_idle_period or max_chunk_age is reached first
  chunk_retain_period: 30s    # Must be greater than index read cache TTL if using an index cache (Default index read cache TTL is 5m)
  max_transfer_retries: 0     # Chunk transfers disabled

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /opt/app/loki/boltdb-shipper-active
    cache_location: /opt/app/loki/boltdb-shipper-cache
    cache_ttl: 24h         # Can be increased for faster performance over longer query periods, uses more disk space
    shared_store: filesystem
  filesystem:
    directory: /opt/app/loki/chunks

compactor:
  working_directory: /opt/app/loki/boltdb-shipper-compactor
  shared_store: filesystem

limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h

chunk_store_config:
  max_look_back_period: 0s

table_manager:
  retention_deletes_enabled: false
  retention_period: 0s

ruler:
  storage:
    type: local
    local:
      directory: /opt/app/loki/rules
  rule_path: /opt/app/loki/rules-temp
  alertmanager_url: http://localhost:9093
  ring:
    kvstore:
      store: inmemory
  enable_api: true
EOF

# service文件

cat <<EOF >/etc/systemd/system/loki.service
[Unit]
Description=loki server
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/opt/app/loki/loki -config.file=/opt/app/loki/loki.yaml
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=loki
[Install]
WantedBy=default.target
EOF

systemctl daemon-reload
systemctl restart loki 
systemctl status loki 


```

## grafana 上配置loki数据源
## 在grafana explore上配置查看日志
> 查看日志  `rate({job="message"} |="kubelet" `
![](/img/bVcRVFs)

> 算qps  `rate({job="message"} |="kubelet" [1m])`
![](/img/bVcRVFt)


# 只索引标签
> 之前多次提到loki和es最大的不同是 loki只对标签进行索引而不对内容索引
> 下面我们举例来看下


# 静态标签匹配模式
> 以简单的promtail配置举例

## 配置解读
```yaml
scrape_configs:
 - job_name: system
   pipeline_stages:
   static_configs:
   - targets:
      - localhost
     labels:
      job: message
      __path__: /var/log/messages
```

- 上面这段配置代表启动一个日志采集任务
- 这个任务有1个固定标签`job="syslog"`
- 采集日志路径为 `/var/log/messages` ,会以一个名为filename的固定标签
- 在promtail的web页面上可以看到类似prometheus 的target信息页面
![](/img/bVcRVFx)


## 查询的时候可以使用和prometheus一样的标签匹配语句进行查询
- `{job="syslog"}`
```yaml
scrape_configs:
 - job_name: system
   pipeline_stages:
   static_configs:
   - targets:
      - localhost
     labels:
      job: syslog
      __path__: /var/log/syslog
 - job_name: system
   pipeline_stages:
   static_configs:
   - targets:
      - localhost
     labels:
      job: apache
      __path__: /var/log/apache.log
```
- 如果我们配置了两个job，则可以使用`{job=~”apache|syslog”} ` 进行多job匹配
- 同时也支持正则和正则非匹配

# 标签匹配模式的特点
## 原理
- 和prometheus一致，相同标签对应的是一个流
> prometheus 处理series的模式
- prometheus中标签一致对应的同一个hash值和refid(正整数递增的id)，也就是同一个series
    - 时序数据不断的append追加到这个memseries中
    - 当有任意标签发生变化时会产生新的hash值和refid，对应新的series
    
> loki处理日志的模式
- 和prometheus一致，loki一组标签值会生成一个stream
    - 日志随着时间的递增会追加到这个stream中，最后压缩为chunk
    - 当有任意标签发生变化时会产生新的hash值，对应新的stream

## 查询过程
- 所以loki先根据标签算出hash值在倒排索引中找到对应的chunk?
- 然后再根据查询语句中的关键词等进行过滤，这样能大大的提速
- 因为这种根据标签算哈希在倒排中查找id，对应找到存储的块在prometheus中已经被验证过了
    - 属于开销低
    - 速度快

# 动态标签和高基数
> 所以有了上述知识，那么就得谈谈动态标签的问题了

## 两个概念
> 何为动态标签：说白了就是标签的value不固定

> 何为高基数标签：说白了就是标签的value可能性太多了，达到10万，100万甚至更多

## promtail支持在 pipline_stages中用正则匹配动态标签
- 比如apache的access日志
```shell script
11.11.11.11 - frank [25/Jan/2000:14:00:01 -0500] "GET /1986.js HTTP/1.1" 200 932 "-" "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.1.7) Gecko/20091221 Firefox/3.5.7 GTB6"
```

- 在promtail中使用regex想要匹配 `action`和`status_code`两个标签
```yaml
- job_name: system
   pipeline_stages:
      - regex:
        expression: "^(?P<ip>\\S+) (?P<identd>\\S+) (?P<user>\\S+) \\[(?P<timestamp>[\\w:/]+\\s[+\\-]\\d{4})\\] \"(?P<action>\\S+)\\s?(?P<path>\\S+)?\\s?(?P<protocol>\\S+)?\" (?P<status_code>\\d{3}|-) (?P<size>\\d+|-)\\s?\"?(?P<referer>[^\"]*)\"?\\s?\"?(?P<useragent>[^\"]*)?\"?$"
    - labels:
        action:
        status_code:
   static_configs:
   - targets:
      - localhost
     labels:
      job: apache
      env: dev
      __path__: /var/log/apache.log
```

- 那么对应action=get/post 和status_code=200/400则对应4个流
```shell script
11.11.11.11 - frank [25/Jan/2000:14:00:01 -0500] "GET /1986.js HTTP/1.1" 200 932 "-" "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.1.7) Gecko/20091221 Firefox/3.5.7 GTB6"
11.11.11.12 - frank [25/Jan/2000:14:00:02 -0500] "POST /1986.js HTTP/1.1" 200 932 "-" "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.1.7) Gecko/20091221 Firefox/3.5.7 GTB6"
11.11.11.13 - frank [25/Jan/2000:14:00:03 -0500] "GET /1986.js HTTP/1.1" 400 932 "-" "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.1.7) Gecko/20091221 Firefox/3.5.7 GTB6"
11.11.11.14 - frank [25/Jan/2000:14:00:04 -0500] "POST /1986.js HTTP/1.1" 400 932 "-" "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.1.7) Gecko/20091221 Firefox/3.5.7 GTB6"
```

- 那四个日志行将变成四个单独的流，并开始填充四个单独的块。
- 如果出现另一个独特的标签组合（例如status_code =“ 500”），则会创建另一个新流

## 高基数问题
- 就像上面，如果给ip设置一个标签，现在想象一下，如果您为设置了标签ip，来自用户的每个不同的ip请求不仅成为唯一的流
- 可以快速生成成千上万的流，这是高基数，这可以杀死Loki
- 所以为了避免高基数则应该避免使用这种取值分位太大的标签


# 如果字段没有被当做标签被索引，会不会导致查询很慢
> Loki的超级能力是将查询分解为小块并并行分发，以便您可以在短时间内查询大量日志数据
## 全文索引问题
- 大索引既复杂又昂贵。通常，日志数据的全文索引的大小等于或大于日志数据本身的大小
- 要查询日志数据，需要加载此索引，并且为了提高性能，它可能应该在内存中。这很难扩展，并且随着您摄入更多日志，索引会迅速变大。
- Loki的索引通常比摄取的日志量小一个数量级，索引的增长非常缓慢

## 那么如何加速查询没有标签的字段
> 以上边提到的ip字段为例
- 使用过滤器表达式查询
```shell script
{job="apache"} |= "11.11.11.11"
```

## loki 查询时的分片 (按时间范围分段grep)
- Loki将把查询分解成较小的分片，并为与标签匹配的流打开每个区块，并开始寻找该IP地址。
- 这些分片的大小和并行化的数量是可配置的，并取决于您提供的资源
- 如果需要，您可以将分片间隔配置为5m，部署20个查询器，并在几秒钟内处理千兆字节的日志
- 或者，您可以发疯并设置200个查询器并处理TB的日志！

## 两种索引模式对比
- es的大索引，不管你查不查询，他都必须时刻存在。比如长时间占用过多的内存
- loki的逻辑是查询时再启动多个分段并行查询

## 在日志量少的时候少加标签
- 因为每多加载一个chunk就有额外的开销
- 举例 如果该查询是{app="loki",level!="debug"}
- 在没加level标签的情况下只需加载一个chunk 即app="loki"的标签
- 如果加了level的情况，则需要把level=info,warn,error,critical 5个chunk都加载再查询

## 在需要标签时再去添加
- 当chunk_target_size=1MB时代表 以1MB的压缩大小来切割块
- 对应的原始日志大小在5MB-10MB，如果日志在 max_chunk_age时间内能达到10MB，考虑添加标签

## 日志应当按时间递增
- 这个问题和tsdb中处理旧数据是一样的道理
- 目前loki为了性能考虑直接拒绝掉旧数据