#!/bin/sh
# 由于我这里是在Windows上装的虚拟机运行的这套环境  
# 因此需要停止安装过的服务，然后才能关闭虚拟机

# 停止 keepalived 服务
ansible keepalivedserver -b -i ./hosts_key -m shell -a "systemctl stop keepalived"

# 停止 haproxy 服务
ansible proxyservers -b -i ./hosts_key -m shell -a "systemctl stop haproxy"

# 停止 nginx 服务
ansible webservers -b -i ./hosts_key -m shell -a "systemctl stop nginx"

# 停止 PHP 服务
ansible webservers -b -i ./hosts_key -m shell -a "systemctl stop php-fpm"

# 停止 memcached 服务
ansible memservers -b -i ./hosts_key -m shell -a "systemctl stop memcached"

# 停止 MySQL 服务
ansible dbservers -b -i ./hosts_key -m shell -a "systemctl stop mysqld"

# 停止 zabbix httpd 服务
ansible zabbixserver -b -i ./hosts_key -m shell -a "systemctl stop httpd"

# 停止 zabbix agent 服务
ansible all -b -i ./hosts_key -m shell -a "systemctl stop zabbix-agent"

# 停止 zabbix server 服务
ansible zabbixserver -b -i ./hosts_key -m shell -a "systemctl stop zabbix-server"

# 停止 zabbix maridb 服务
ansible zabbixdbserver -b -i ./hosts_key -m shell -a "systemctl stop mariadb"

