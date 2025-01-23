---
title: DNS 基础概念
date: 2024-04-07 00:15:30
categories:
 - build website
 - networking
tags:
 - build website
 - networking
typora-root-url: ../../../static
---

## 1. DNS Hierarchy

DNS服务器怎么会知道每个域名的IP地址呢？答案是分级查询, 仔细看下面DNS解析过程，每个域名的尾部都多了一个点`.`

![](/001-domain-name-dns-records/c.png)

多出的那个`.`是Root Level Domain, 比如`www.example.com`真正的名字是`www.example.com.root`然后上图就简写为`www.example.com.` 因为根域名`.root`对于所有域名都是一样的，所以平时是省略的。

> 域名的层级结构: `hostname.SLD.TLD.root`, **hostname 也叫 subdomain**. 

## 2. HOSTNAME vs SLD

HOSTNAME 和二级域名(SLD)是不一样的, 二级域名是指`example.com`里面的`example`, 而HOSTNAME是指`www.example.com`里面的`www`. 

HOSTNAME 的作用是为了区分同一个域名下的不同服务, 比如`www.example.com`和`blog.example.com`是同一个域名下的不同服务, 现在都是采用微服务分布式架构, 即每个服务通常不在一个主机, 这样用户访问`www.example.com`和`blog.example.com`时就会访问到不同的服务器, 从而提供不同的服务. 如下图可以看出一个 HOSTNAME 可以对应一个 IP:

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/001-domain-name-dns-records%2F01.jpg)

## 3. DNS Records

### 3.1. A Record

常见的 DNS Records 有 `A`, `CNAME`, `TXT`, 其中 `A` 记录是最常见的, 用于将域名指向一个 ipv4 IP地址, `CNAME` 记录用于将域名指向另一个域名. 

当你想给域名添加一个 ip 地址时, 只能添加 `A` 记录. 添加 A 记录时需要指定 HOSTNAME 和 IP, 其中 `HOSTNAME` 可以填`@`或者`www`或`blog`等, `@`代表空即不填, 

一般域名自带默认的 DNS Records, 所以买了域名之后做的第一件事就应该删除这些默认记录, 不然等你又添加了一个A记录, 这时候你的域名就会被解析到多个IP(默认的和你刚添加的), 那浏览器访问你域名的时候, 选择哪个呢? 我查了一下论坛, 有人说是choose randomly, 所以如果你不删除域名所有的默认DNS Records, 那浏览器访问你域名的时候就有可能选择“错误”的ip, 

> Yes you can. It is called round-robin DNS, and **the browser just chooses one of them randomly**. It is a well used method of getting cheap load balancing, but if one host goes down, users will still try to access it. https://serverfault.com/q/528742/761923

### 3.2. CNAME Record

Use a CNAME record instead of an A record when one domain or subdomain is just another name for a different domain. **All CNAME records must point to a domain, never to an IP address**. 

假设你有个主网站 example.com，它有一个A记录指向IP地址 123.45.67.89。若你还想通过 www.example.com 访问这个网站，有两个办法, 

- 再创建一个A记录 host name 写为 www 指向 123.45.67.89, (注意对于 example.com 的A记录 host name 是空).

- 创建一个 CNAME 记录, Host Name 写为 www, 指向 example.com

第二种办法的工作原理：

- example.com A记录 -> 123.45.67.89
- www.example.com CNAME记录 -> example.com

当用户尝试访问 www.example.com 时，DNS解析流程如下：

- DNS查找 www.example.com 的记录。
- 找到CNAME记录，了解到 www.example.com 是 example.com 的别名。
- 接着，DNS会解析 example.com 的A记录，获取其IP地址 123.45.67.89。
- 用户的请求最终被定向到IP地址 123.45.67.89，也就是 example.com 所在的服务器。

添加 CNAME 有什么优点呢? 比如你的服务器IP地址发生变化, 此时只需要更新 example.com 的A记录就行了, 如果全都使用A记录，你需要手动更新 example.com 和 www.example.com 的 A 记录, 

> Github Pages 的 custom domain 就可以使用 CNAME 记录, 即只需简单给你的域名添加一个 CNAME 记录, 指向 `username.github.io` 即可, **不用修改任何 NS 服务器**. 注意添加 CNAME 记录时, 我的 HOSTNAME 填的是 `blog`, 即 `blog.example.com` 指向 `username.github.io`, 你也可以把 HOSTNAME 设置为空, 若为空则代表你的主域名 `example.com` 指向 `username.github.io`, 根据个人喜好来设置. 

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2024/04/f356b3dd152035f92b0ae20335413ab0.jpg)

### 3.3. TTL Field

另外 DNS Records 有一个字段叫 TTL, 这里介绍一下: Time to Live (TTL) is a field on DNS records that controls how long each record is valid and — as a result — how long it takes for record updates to reach your end users. Longer TTLs speed up DNS lookups by increasing the chance of cached results, but a longer TTL also means that updates to your records take longer to go into effect.

## 4. 总结

买过来域名, 根据不同情况可能做的修改如下:

- 无托管域名, 则直接去你的域名注册商那里添加 DNS Records, 一般是添加 A 记录, 指向你的服务器 IP 地址 即可. 
- 若要将域名托管到其他地方 (如 Cloudflare), 则只需要修改域名的 Nameserver 为 Cloudflare 指定的的 Nameserver 即可. 之后在 Cloudflare 上即添加管理不同类似的 DNS Records. 

References:

- [Time to Live (TTL) · Cloudflare DNS docs](https://developers.cloudflare.com/dns/manage-dns-records/reference/ttl/)
- [什么是 DNS CNAME 记录？ | Cloudflare](https://www.cloudflare.com/zh-cn/learning/dns/dns-records/dns-cname-record/)
- [What is DNS Hierarchy?](https://www.educative.io/answers/what-is-dns-hierarchy)
