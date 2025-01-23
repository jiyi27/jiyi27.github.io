---
title: Nginx
date: 2023-12-30 14:01:50
categories:
 - build website
tags:
 - build website
 - cs basics
---

## 1. Common used commands

```shell
$apt install nginx # ubuntu
$apk add nginx # Alpine Linux

# start
$sudo systemctl start/stop/restart/status nginx
$sudo service nginx start/stop/restart/status
```

## 2. Basic configurations

### 2.1. Configuration file

```shell
$vi /etc/nginx/http.d/default.conf # Alpine Linux

server {
      listen 2087 ssl;
      server_name shaowenzhu.top www.shaowenzhu.top;
      ssl_certificate /root/tls/cert.pem;
      ssl_certificate_key /root/tls/cert.key;
      location / {
          root /var/www/html;
          try_files $uri $uri/ /index.html;
      }
      # You may need this to prevent return 404 recursion.
      location = /404.html {
              internal;
      }
}
```

> You can get free TLS certificate from Cloudflare but you need get a domain first. Learn more: [Coudflare TLS encryption 520 Error Code & too Many Redirections - David's Blog](https://davidzhu.xyz/post/build-website/008-enable-cloudflare-reverse-proxy/)

Because the 443 port is used by my file server, so I use 2087 port for my gbtbot server. I [use Cloudflare for reverse proxy](https://davidzhu.xyz/post/build-website/008-enable-cloudflare-reverse-proxy/), Cloudflare only allows the following ports: 443, 2053, 2083, 2087, 2096, 8443. So I choose 2087 port for this app. 

> Don't forget allow 2087 port on your server firewall with command `sudo ufw allow 2087`.

### 2.2. Static website

Then access my website by `https://shaowenzhu.top:2087/` will get the static html file under `/var/www/html`. 

With Vite, you can use `vite build` to build your project, then copy the `dist` folder to `/var/www/html`. 

```shell
➜  /etc tree -L 3 /var/www/html
/var/www/html
├── assets
│   └── index-r4STm7R-.js
├── index.html
└── vite.svg
```
