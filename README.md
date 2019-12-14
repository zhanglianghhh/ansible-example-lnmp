# ansible-example-lnmp

Ansible 自动化部署中小型 Web 架构

# 1. 主机部署模块规划

| 序号 | 主机名 | 操作系统版本 | 内网IP | 外网IP(模拟) | 部署模块 |
|--|--|--|--|--|--|
| 0 | 对外提供访问 |  |  | 10.0.0.170 | keepalived【无主机，只有一个虚拟VIP】 |
| 1 | ansi-haproxy01 | CentOS7.5 | 172.16.1.181 | 10.0.0.181 | zabbix-agent、haproxy |
| 2 | ansi-haproxy02 | CentOS7.5 | 172.16.1.182 | 10.0.0.182 | zabbix-agent、haproxy |
| 3 | ansi-web01 | CentOS7.5 | 172.16.1.183 | 10.0.0.183 | zabbix-agent、nginx+php、mysql(master) |
| 4 | ansi-web02 | CentOS7.5 | 172.16.1.184 | 10.0.0.184 | zabbix-agent、nginx+php、mysql(slave) |
| 5 | ansi-web03 | CentOS7.5 | 172.16.1.185 | 10.0.0.185 | zabbix-agent、nginx+php、mysql(slave)、memcached |
| 6 | ansi-manager | CentOS7.5 | 172.16.1.180 | 10.0.0.180 | Ansible、zabbix-server、zabbix-agent、mariadb「zabbix使用」 |

## 1.1. 所有主机添加用户账号
<b>说明：</b>

1、	运维人员使用的登录账号；

2、	所有的业务都放在 /app/ 下「yun用户的家目录」，避免业务数据乱放；

3、	该用户也被 ansible 使用，因为几乎所有的生产环境都是禁止 root 远程登录的（因此该 yun 用户也进行了 sudo 提权）。

```
# 使用一个专门的用户，避免直接使用root用户
# 添加用户、指定家目录并指定用户密码
# sudo提权
# 让其它普通用户可以进入该目录查看信息
useradd -u 1050 -d /app yun && echo '123456' | /usr/bin/passwd --stdin yun
echo "yun  ALL=(ALL)       NOPASSWD: ALL" >>  /etc/sudoers
chmod 755 /app/
```

备注：记得在管理机 172.16.1.180 上实现对其他机器的免密登录。

# 2. 系统架构
![image](https://raw.githubusercontent.com/zhanglianghhh/ansible-example-lnmp/master/ansible-example-lnmp.png)

# 3. 涉及目录或文件说明
# 3.1. 目录说明

group_vars 目录：存放主机清单中的组变量。all 为特殊组，对所有机器生效。

host_vars 目录：存放主机或主机别名变量。

roles 目录：存放所有角色信息。每个角色表示一个服务或功能。

# 3.2 文件说明

base_server.yml 文件：部署所需的基础环境或服务。包括：系统初始化或优化；zabbix所需的数据库；zabbix 客户端；zabbix 服务端部署。

busi_server.yml 文件：部署所需的业务组件。包括：MySQL数据库以及主从实现；memcached部署；nginx部署；PHP部署；反向代理服务部署；keepalived部署以及PHP与nginx、MySQL整合；PHP与memcached整合【最后这两个用于验证部署是否成功，整个链路是否通畅】。

deploy.sh 文件：发布文件，可直接执行，用于部署LNMP服务。

hosts_key 文件：主机清单文件。

hosts_key.bak1 文件：实际用不到该文件。只是为了对比 hosts_key 文件，且该文件头三行做了说明。请自行参见。

stop_server.sh 文件：用于停止所有服务。如果你是在个人电脑上通过虚拟机部署的，那么建议执行该文件后【服务全部停止后】，再关闭虚拟机。

# 4. 服务部署
执行 deploy.sh 脚本即可。

备注：如果是在个人电脑【内存最好是16G】通过虚拟机部署的，由于MySQL与PHP是编译安装的，因此整个过程预计耗时 40 分钟左右【根据自身电脑配置而定】。

# 5. 停止服务
执行 stop_server.sh 脚本即可。

# 6. 服务验证
## 6.1. zabbix监控
当基础服务部署完毕后，也就是zabbix部署完毕后，就可以前台网页安装zabbix了。本案例地址如下：

```
http://172.16.1.180/zabbix
```

前台网页安装步骤参见官方文档：

```
https://www.zabbix.com/documentation/4.0/manual/installation/install#installing_frontend
```

具体监控添加就不是本案例的事情了，这里就不说了。

## 6.2. MySQL数据库主从实现
在本案例中172.16.1.183为主库；172.16.1.184、172.16.1.185为从库。

可使用账号：user_test/11111 在172.16.1.183主库的test数据库创建表并写入数据，然后在两个从库上查看。

```
# 主从测试建表语句
CREATE TABLE user
  (
  id INT(11),
  name VARCHAR(25),
  deptId INT(11),
  salary FLOAT,
  PRIMARY KEY (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
```

## 6.3. PHP与nginx、MySQL、memcached整合验证 
<b>PHP info验证</b>

```
http://172.16.1.183:8090/test_info.php
http://172.16.1.184:8090/test_info.php
http://172.16.1.185:8090/test_info.php
```

<b>PHP连接MySQL验证</b>

```
http://172.16.1.183:8090/test_mysql.php
http://172.16.1.184:8090/test_mysql.php
http://172.16.1.185:8090/test_mysql.php
```

<b>PHP连接memcached验证【所有PHP共享一个memcached】</b>

```
http://172.16.1.183:8090/test_memcached.php
http://172.16.1.184:8090/test_memcached.php
http://172.16.1.185:8090/test_memcached.php
```

## 6.4. 反向代理服务验证

```
http://10.0.0.181:8888/haproxy-status   # 状态访问  验证信息：haproxy/haproxy
http://10.0.0.181/test_mysql.php        # 查看 test_mysql.php
http://10.0.0.181/test_memcached.php    # 查看 test_memcached.php

http://10.0.0.182:8888/haproxy-status   # 状态访问  验证信息：haproxy/haproxy
http://10.0.0.182/test_mysql.php        # 查看 test_mysql.php
http://10.0.0.182/test_memcached.php    # 查看 test_memcached.php
```

## 6.5. keepalived 验证【对外用户访问地址】

```
# VIP为 10.0.0.170
http://10.0.0.170:8888/haproxy-status
http://10.0.0.170/test_mysql.php
http://10.0.0.170/test_memcached.php
```

## 6.6. VIP 漂移验证
默认情况下 172.16.1.181 为 keepalived的主，172.16.1.182 为keepalived的从。因此此时VIP 10.0.0.170是在 172.16.1.181 机器上。

这时我们停止 172.16.1.181 机器上的 haproxy 服务，然后查看 keepalived服务是否被停止，且VIP 此时已经漂移到 172.16.1.182 上。

前台页面访问<b> http://10.0.0.170:8888/haproxy-status </b>时，此时是否为 172.16.1.182 的haproxy 信息。


---


如果觉得不错就关注下呗 (-^O^-) ！

![image](https://raw.githubusercontent.com/zhanglianghhh/ansible-example-lnmp/master/personflag.png)

---

