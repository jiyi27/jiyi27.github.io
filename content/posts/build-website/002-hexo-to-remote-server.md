---
title: 部署博客到服务器 - Hexo
date: 2023-04-23 19:54:52
categories:
 - build website
tags:
 - hexo
---

## 1. 安装Nginx和git (服务器端)

### 1.1. Installing the Nginx Web Server

```zsh
sudo yum install nginx

sudo systemctl enable nginx
sudo systemctl start nginx
```

### 1.2. Adjusting Firewall Rules

Run the following command to permanently enable HTTP connections on port 80:

```shell
sudo firewall-cmd --permanent --add-service=http
```

To verify that the http firewall service was added correctly, you can run:

```shell
sudo firewall-cmd --permanent --list-all
```

You’ll see output like this:

```zsh
public
  target: default
  icmp-block-inversion: no
  interfaces: 
  sources: 
  services: cockpit dhcpv6-client http ssh
  ports: 
  protocols: 
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 
```

To apply the changes, you’ll need to reload the firewall service:

```zsh
sudo firewall-cmd --reload
```

## 2. 创建新的用户 `git` (服务端)

```zsh
useradd git
passwd git

# 给git用户配置sudo权限
chmod 740 /etc/sudoers
vim /etc/sudoers
# 找到root ALL=(ALL) ALL，在它下方加入一行
git ALL=(ALL) ALL

chmod 400 /etc/sudoers
```

### 2.1. 添加公钥认证

```
su git
cd

mkdir -p ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh

#把本地电脑ssh的公钥加进去  ~/.ssh/id_rsa.pub 
vim ~/.ssh/authorized_keys    
```

### 2.2. git-hooks 自动部署

注意, 现在服务器有两个用户`git`和`root`, 然后他们只有自己的home目录是独立的, 而根目录下的比如`/etc/`, `/usr`这都是他们两个用户共享的, 看下面的输出你就知道什么意思了, 

```zsh
ls -a /home/git/
.  ..  .bash_logout  .bash_profile  .bashrc  .ssh  .viminfo

# 因为我们是在用户git下访问的, 所以得用sudo才能访问root用户的文件
sudo ls -a /root/
.   .bash_logout   .bashrc  .cshrc  .ssh     .viminfo
..  .bash_profile  .cache   .pki    .tcshrc
```

好了不解释了, 开始设置git-hook以及服务器文件相关配置:

```zsh
# 新建目录，这是git仓库的位置
sudo mkdir -p /var/repo
# 这里是我们网站网页的位置 
sudo mkdir -p /var/www/hexo

# 创建个bare repository 
cd /var/repo  
sudo git init --bare blog.git
sudo vim /var/repo/blog.git/hooks/post-update
```

`post-update`的内容如下:

```zsh
#!/bin/bash
git --work-tree=/var/www/hexo --git-dir=/var/repo/blog.git checkout -f
```

给`post-update`授权:

```zsh
cd /var/repo/blog.git/hooks/
sudo chown -R git:git /var/repo/
sudo chown -R git:git /var/www/hexo

# 赋予其可执行权限
sudo chmod +x post-update
```

## 3. 配置Nginx

```zsh
cd /etc/nginx/conf.d/
sudo vim blog.conf
```

`blog.conf`的内容如下(注意因为我为域名添加个A记录然后`www`作为HOSTNAME, 如果你的域名只有一个A记录然后HOSTNAME还是空, 那你就填二级域名就好了`davidzhu.xyz`这样, 不懂的话请看我的[域名分级和DNS记录之何为www](https://www.davidzhu.xyz/2023/04/23/Build-Website/Domain-Name-DNS-Records/)：
```zsh
server {
    listen    80 default_server;
    listen    [::] default_server;
    server_name    www.davidzhu.xyz;
    root    /var/www/hexo;
}
```

```zsh
nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful

nginx -s reload
```

## 4. 在本地安装Hexo

Installing Hexo is quite easy and only requires the following beforehand:

- Node.js (Should be at least Node.js 10.13, recommends 12.0 or higher)
- Git
- `node -v`查看是否安装了node

### 4.1 Install Node.js

#### 4.1.1. Install nvm

```zsh
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash

source ~/.bashrc

source ~/.zshrc
```

`bash` is an sh-compatible command language interpreter that executes commands read from the standard input or from a file.

We strongly recommend using a Node version manager like nvm to install `Node.js` and `npm`. We do not recommend using a Node installer, since the Node installation process installs npm in a directory with local permissions and can cause permissions errors when you run npm packages globally.

#### 4.1.2. Install node

```
nvm install node # "node" is an alias for the latest version

# uninstall, 19.8.1是node的版本
nvm uninstall 19.8.1

# 尽量使用16.0.0版本的, 不然会出现问题: node: /lib64/libm.so.6: version `GLIBC_2.27' not found (required by node)
nvm install 16.0.0
```

- [install nvm](https://github.com/nvm-sh/nvm)
- [Downloading and installing Node.js and npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm)

### 4.2. 安装Hexo

安装hexo以及相关插件, 

```
sudo npm install hexo-cli hexo-server hexo-deployer-git -g
```

## 5. 在本地配置hexo

### 5.1. 初始化hexo

```zsh
hexo init ~/blog
```

### 5.2. 配置hexo

#### 5.2.1 设置主题和deploy

```
cd ~/blog

git clone https://github.com/next-theme/hexo-theme-next themes/next
```

编辑`_config.yml`

```
vi _config.yml 
```

找到theme, 改为next, 顺便也改一下deploy设置, 找到对应内容改为如下:

```zsh
# Extensions
## Plugins: https://hexo.io/plugins/
## Themes: https://hexo.io/themes/
theme: next

# Deployment
## Docs: https://hexo.io/docs/one-command-deployment
# 必须填ip地址
deploy:
  type: git
  repo: root@144.202.12.32:/var/repo/blog.git
  branch: master
```

在deploy之前需要在服务器的root用户加上本地电脑的公钥(`~/.ssh/id_rsa.pub`), 否则你没权限提交git, 和github同理, 我猜的, 

```
vi /root/.ssh/authorized_keys
```

```zsh
# 清除缓存
hexo clean
# 生成静态页面
hexo generate
# 注意要使用这个命令 否则使用hexo deploy的时候会出现找不到git报错
npm install hexo-deployer-git --save
# 将本地静态页面目录部署到云服务器
hexo deploy
```
## 6. 修改git用户默认shell环境

```zsh
vim /etc/passwd
# 修改最后一行
# 将/bin/bash修改为/usr/bin/git-shell
```

## 7. bug总结

首先, `/Users/shaowen/blog/_config.yml`里的内容, delopy那部分, 不可以填错, master分支是master, 不是main, 也可以是main但是现在没空研究具体怎么操作, 

其次浏览器出错说403 forbidden, 这种情况就去看看网页目录下有没有文件, 即我们在本地电脑的部署的hexo可能并没有成功的部署到服务器, 因为权限问题或者服务器的那个hooks脚本没有执行权限导致无法自动更新,

你可以把hooks也就是`/var/repo/blog.git/hooks/post-update`里命令的复制出来在服务器执行一下,看看会不会有效果, 

- https://blog.kisnows.com/2016/03/10/Hexo部署到VPS并启用HTTPS/

