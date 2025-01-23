---
title: Cloudflare 代理无法通过域名解析出 IP 问题
date: 2023-04-26 17:30:22
categories:
 - bugs
tags:
 - 建站
---

这几天弄服务器, 用ssh通过域名连接的时候总是出现超时(域名只有一个A记录即服务器IP), 问题下面是分析思路, 

<!--more-->

### 问题描述:

I'm trying to use `ssh` to connect my server with my domain name `ssh root@www.davidzhu.xyz`, but I always get timeout. However I can connect my server when use my server ip directly `ssh root@144.202.12.32`, so I use `dig` to check the ip address of my domain on DNS, the output is:

```shell
dig davidzhu.xyz  +short       
172.67.210.8
104.21.50.195

dig www.davidzhu.xyz  +short
172.67.210.8
104.21.50.195
```

But I only have one A record on my domain, this is the DNS Record of my domain name (the third one is about the google search console):

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2025/01/f025ec2ddc93a57d7c062cd2f3e590bb.png)

惊不惊讶, **`dig`返回的两个IP地址竟然都与我域名的A记录不同**!

----

### **更新:** 

原因是我的域名开启了 Cloudfalre 的 [reverse proxy](https://developers.cloudflare.com/fundamentals/concepts/how-cloudflare-works/), 通过域名获取到的是 Clouflare 的IP, 无法访问到我服务器真实IP:

> When you add your application to Cloudflare, we use this network to sit in between requests and your origin server. 
>
> Cloudflare does this by serving as a **reverse proxy** for your web traffic. All requests to and from your origin **flow through Cloudflare** and — as these requests pass through our network — we can apply various rules and optimizations to improve security, performance, and reliability.

关闭 Cloudflare 反向代理就可以通过域名获取到服务器真实IP了:

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2025/01/ad242ed1a2bba87d81f18f2a7fa1a64b.png)

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2025/01/a5091686a0a61fab1ed5ea3f604b9423.jpg)

此时可以看到现实 DNS Only, 使用 `dig xxx.com +short` 即可查到真实绑定 ip, 或者 `ping` 也可以. 

> 另外通过Cloudflare 域名托管机制(就是现在我们操作的, 中文里都叫托管更合适, 因为他会接管通往我们域名的所有流量), 就是域名被 Cloudflare 托管(Domain Hosting)后, **若想更换域名的 DNS Record, 只需要在上图中的 edit 上修改 A record 就行了**, 就是改成你的新的 VPS(服务器) 的 ipv4 地址, 不用去域名服务商那里修改 DNS Record 了, 因为在把域名托管给 Cloudflare 的时候已经在域名提供商那里把域名的 DNS 服务器设置成了 Cloudflare.  

如何让 Cloudfalre 托管我们的域名:: [Enable Coudflare Reverse Proxy - David's Blog](https://davidzhu.xyz/post/build-website/008-enable-cloudflare-reverse-proxy/)

---

另外如果使用了 cloudflare https 代理, 一般都是先修改域名的 NS 为 cloudfalre 指定的 NS, 但是有些电脑可能因为 DNS cache 问题, 通过 https 访问你的域名可能会失败, 此时应该尝试修改本地 DNS cache, 可以查一下 flush dns cache 的命令, 

注意, DNS cache 一般 chrome 保存了一份, 操作系统也会保存一份, 因此两个地方都要考虑进去, 

关于DNS: [DNS Concepts (NameServer(NS), DNS Records and Caching) - David's Blog](https://davidzhu.xyz/post/networking/002-dns-basics/)

了解更多: [HTTPS Works on some computers but not others? - Website, Application, Performance / Security - Cloudflare Community](https://community.cloudflare.com/t/https-works-on-some-computers-but-not-others/15922)

---

其实这样有个好处, 就是别人无法通过你的域名接触到你的服务器, 因为每次请求你的域名, 都要经过 Cloudfalre 中转才能到你的服务器, 另外通过nslookup, dig也无法查到你服务器的真实IP, 返回的都是 Cloudflare 的IP. 

> Because of [how Cloudflare works](https://developers.cloudflare.com/fundamentals/concepts/how-cloudflare-works/), all traffic to [proxied DNS records](https://developers.cloudflare.com/dns/manage-dns-records/reference/proxied-dns-records/) pass through Cloudflare before reaching your origin server. This means that your origin server will stop receiving traffic from individual visitor IP addresses and instead receive traffic from [Cloudflare IP addresses](https://www.cloudflare.com/ips), which are shared by all proxied hostnames.
>
> [Cloudflare IPs · Getting started · Learning paths](https://developers.cloudflare.com/learning-paths/get-started/concepts/cloudflare-ips/)
