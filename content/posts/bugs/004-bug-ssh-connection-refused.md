---
title: SSH连接远程主机出现的Connection Refused问题
date: 2023-04-23 20:30:22
categories:
 - Bugs
tags:
 - ssh
---

```shell
ssh root@144.202.12.32
ssh: connect to host 144.202.12.32 port 22: Connection refused
```

查的一些博客说修改mac设置成允许远程连接(这其实是允许别人连接你的mac电脑比如`ssh localhost`), 还有修改服务器里的配置文件`/etc/ssh/ssh_config`, 22端口取消注释, 都没用, 

直接去服务器卸载ssh再重装就好了

```shell
sudo yum remove openssh-server
sudo yum install openssh-server

# sudo systemctl stop sshd
sudo systemctl start sshd
# 查看状态
service sshd status
```



