---
title: DNS Spoofing - GFW
date: 2023-10-31 15:29:25
categories:
 - networking
tags:
 - cybersecurity
 - networking
typora-root-url: ../../../static
---

声明: 本文只用于学习目的, 请勿用于非法用途.

## 1. DNS spoofing

[DNS](https://www.cloudflare.com/learning/dns/what-is-dns/) cache poisoning is the act of entering false information into a DNS cache, so that DNS queries return an incorrect response and users are directed to the wrong websites. DNS cache poisoning is also known as 'DNS spoofing'.

### 1.1. DNS Caching

Learn more about DNS caching: [DNS Concepts (NameServer(NS), DNS Records and Caching) - David's Blog](https://davidzhu.xyz/post/networking/002-dns-basics/)

### 1.2. How do attackers poison DNS caches?

Attackers can poison DNS caches by impersonating [DNS nameservers](https://www.cloudflare.com/learning/dns/dns-server-types/), making a request to a DNS resolver, and then forging the reply when the DNS resolver queries a nameserver. This is possible because DNS servers use [UDP](https://www.cloudflare.com/learning/ddos/glossary/user-datagram-protocol-udp/) instead of [TCP](https://www.cloudflare.com/learning/ddos/glossary/tcp-ip/), and because currently there is no verification for DNS information.

DNS Cache Poisoning Process:

<img src="/005-gfw-dns/c.png" alt="c" style="zoom: 33%;" />

Poisoned DNS Cache:

<img src="/005-gfw-dns/d.png" alt="d" style="zoom: 33%;" />

If a DNS resolver receives a forged response, it accepts and caches the data uncritically because there is no way to verify if the information is accurate and comes from a legitimate source. 

Despite these major points of vulnerability in the DNS caching process, DNS poisoning attacks are not easy. Because the DNS resolver does actually query the authoritative nameserver, attackers have only a few milliseconds to send the fake reply before the real reply from the authoritative nameserver arrives.

> The way to prevent this is to set the /etc/host file directly, because checking host file happens before DNS resolution. 
>
> Learn more: [DNS Stub and Recursive Resolver - Config Files - David's Blog](https://davidzhu.xyz/post/networking/002-host-file-dns-stub-resolver/)

Learn more: [What is DNS cache poisoning? | DNS spoofing | Cloudflare](https://www.cloudflare.com/learning/dns/dns-cache-poisoning/)

## 2. GFW

### 2.1. HTTP 劫持

原文: [浅谈HTTP劫持、DNS污染的影响及解决办法（仅个人理解） | 逗比根据地](https://doubibackup.com/6t3mypbm-5.html#comments)

HTTP劫持很容易理解，因为HTTP传输协议是明文的，并且我的网站服务器是在海外，要访问我的网站就要通过中国的国际宽带出口，出去与我的网站建立连接。我的网站也是因为关键词的原因在经过出口的时候，被“**检查站：墙**”扫描到了违规关键词，于是掐断了TCP链接。所以当时用户访问网站会遇到：**链接已重置、该网站已永久移动到其他地址等等。**

HTTP劫持很容易解决，那就是**加上SSL证书，网站链接全部内容加密**，这样“检查站：墙”就无法解密数据分析关键词了。但是这不是绝对能解决这个问题的，如果你的网站只是误杀或者违规擦边球，那还好，如果是大型网站，就会特殊对待了。

HTTPS在建立加密连接的时候，需要一次握手，也就是达成链接协议建立加密连接，但是这次握手是明文的（建立加密链接首先就是链接双方信任，比如网站的SSL证书是自己签的，或者SSL证书到期或伪造的，在访问这个网站的时候浏览器就会进行提示，表示此网站不安全啥的。）握手是明文的就意味着，如果你的域名被重点关注，即使你加上了SSL证书，也会在首次握手的时候，被关键词匹配然后掐断链接。 learn more: [HTTPS SSL TLS - David's Blog](https://davidzhu.xyz/post/http/006-https-ssl/)

### 2.2. DNS污染投毒

我们假设A为用户端也就是你的电脑设备，B为DNS服务器，C为A到B链路中一个节点的网络设备（路由器、交换机、网关等）。

然后我们模拟一次被污染的DNS请求过程。

A访问一个网站，比如 `google.com` ，然后，A向B通过UDP方式发送查询请求，比如查询内容 `A google.com` ，这个数据库在前往B的时候要经过数个节点网络设备比如C，然后继续前往DNS服务器B。

然而在这个传输过程中，C针对这个数据包进行特征分析，（DNS端口为53，进行特定端口监视扫描，对UDP明文传输的DNS查询请求进行特征和关键词匹配分析，比如“google.com”是关键词，也或者是“A记录”），从而立刻返回一个错误的解析结果（比如返回了 `A 233.233.233.233` ）。

众所周知，作为链路上的一个节点，网络设备 C 必定比真正的 DNS 服务器 B 更快的返回结果到 用户电脑A，而目前的DNS解析机制策略有一个重要的原则，就是只认第一。因此 节点网络设备C所返回的查询结果就被 用户电脑A当作了最终结果，于是用户电脑A因为获得了错误的IP，导致无法正常访问 `google.com `。

验证污染 我的 doub.ssrshare.usm 主域名虽然在大部分地区解除了DNS污染，但是我的两个SS站域名并没有，所以我尝试对我的SS 子域名进行nslookup测试。

```shell
C:\Users\Administrator>nslookup ss.dou-bi.com 8.8.8.8
服务器: google-public-dns-a.google.com
Address: 8.8.8.8
 
非权威应答:
名称: ss.dou-bi.com
Addresses: 200:2:9f6a:794b::
8.7.198.45
```

我使用的是谷歌的 8.8.8.8 DNS，但是我得到的A记录 IP却是8.7.198.45，这个明显不是我的IP，看一下其他被DNS污染的域名就会发现都会有这个IP。很明显，我的 ss.dou-bi.com 域名受到了DNS污染。

**解决办法**

- **使用加密代理**，比如Shadowsocks，在加密代理里进行远程DNS解析，或者使用VPN上网。

- **修改hosts文件**，操作系统中Hosts文件的权限优先级高于DNS服务器，操作系统在访问某个域名时，会先检测HOSTS文件，然后再查询DNS服务器。可以在hosts添加受到污染的DNS地址来解决DNS污染和DNS劫持。

- **通过一些软件编程处理**，可以直接忽略返回结果是虚假IP地址的数据包，直接解决DNS污染的问题。如果你是Firefox用户，并且只用Firefox，又懒得折腾，直接打开Firefox的远程DNS解析就行了。在地址栏中输入：`about:config`找到 `network.proxy.socks_remote_dns` 一项改成true。

- **使用DNSCrypt软件**，此软件与使用的OpenDNS直接建立相对安全的TCP连接并加密请求数据，从而不会被污染。 对于被DNS污染的网站站长来说，最有效的方法就是 换域名或者IP 了。

### 2.3. ip黑名单

即使没有DNS污染 或者 你获得了正确的IP，你就能正常访问这些被屏蔽的网站了吗？

不，墙目前已经有了IP黑名单，针对谷歌这种网站已经不再是普通的DNS污染了，因为总会有办法访问被DNS污染的网站（比如指定Hosts）。

那么就直接把所有的谷歌IP拉黑不就好了？就算你获得了正确的谷歌IP，但是当你去访问这个IP的时候，墙会发现这个IP存在于黑名单中，于是直接阻断，于是浏览器就会提示：www.google.com 的响应时间过长等等

## 3. 常见代理方式

- VPN
  - 常见协议: IPSec, OpenVPN, L2TP, WireGuard
- Shadowsocks (代理服务器)
  - 常见协议: SOCKS5
- V2Ray (代理服务器)
  - 常见协议: VMess
- HTTP 代理 (代理服务器)
  - 已被封锁, 原因是HTTP代理并不对数据进行加密, 即使流量能够绕过初步的审查，传输的内容仍然是透明的，容易被监控。
  - 即使使用 HTTPS 也不会实现全局加密, 在建立 TLS 握手验证时还是需要一个HTTP明文连接

了解更多: [上网限制和翻墙基本原理 | superxlcr's notebook](https://superxlcr.github.io/2018/07/01/%E4%B8%8A%E7%BD%91%E9%99%90%E5%88%B6%E5%92%8C%E7%BF%BB%E5%A2%99%E5%9F%BA%E6%9C%AC%E5%8E%9F%E7%90%86/)