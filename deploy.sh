#!/bin/sh
# lnmp 部署脚本

# 基础组件部署
ansible-playbook -b -i ./hosts_key base_server.yml

# 业务组件部署
ansible-playbook -b -i ./hosts_key busi_server.yml

