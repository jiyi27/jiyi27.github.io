---
title: Get Free TLS certificate with Cloudflare
date: 2023-11-15 20:09:22
categories:
 - build website
tags:
 - build website
typora-root-url: ../../../static
---

## 1. Hosting your domain on Cloudflare (Enable CDN)

```
client <----tls-1----> cloudflare <----tls-2----> your server
```

> **Note:** You cannot login your server with `ssh user@your_domain` any more after enabling Cloudflare. You need to login with `ssh user@your_ip`. Cause the Cloudflare acts as a reverse proxy, it only forwards the http/https traffic to your server, and [only on some specific ports](https://developers.cloudflare.com/fundamentals/reference/network-ports/). 

There are two steps to add your domain to Cloudflare:

- Add your domain to Cloudflare
- Create and install TLS certificate to your server

> Cloudflare does this by serving as a [reverse proxy](https://www.cloudflare.com/learning/cdn/glossary/reverse-proxy/) for your web traffic. Actually, Clooudflare achieves this by using its CDN service, which caches your website's static content and serves it to your visitors from the nearest Cloudflare data center.
> Refer to our Load Balancing reference architecture to learn more about advanced ways to forward traffic to your origins, as well as our [CDN reference architecture](https://developers.cloudflare.com/reference-architecture/architectures/cdn/) to learn more about how Cloudflare processes and optimizes your web traffic.

### 1.1. Add your domain to Cloudflare

Go to this website: https://dash.cloudflare.com/

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2024/08/5ec8185791f488d73320ceadd0db79dc.png)

And you will get instructions for updating your nameserver of your domain. After change your nameserver, waite about one hour, your site will be **active** on Cloudflare. Then you can choose the TLS encryption mode:

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2024/08/3ff225afee4374761c3943c1c6ed009a.png)

> **Note:** choose `full mode`, don't use `flexbile mode`, otherwise you **probably would** get [ERR_TOO_MANY_REDIRECTS](https://developers.cloudflare.com/ssl/troubleshooting/too-many-redirects/) when access your website. 

### 1.2. Install TLS certificate

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2024/08/d3d8aa4e52defcc7961fe8fad4d3eb88.png)

The generated two files `cert.pem` and `cert.key` is used for encryption between your server and Cloudflare. 

You can use these two file like this:

```go
... 
func main() {
    http.HandleFunc("/hello", HelloServer)
    err := http.ListenAndServeTLS(":443", "./conf/cert.pem", "./conf/cert.key", nil)
    if err != nil {
        log.Fatal("ListenAndServe: ", err)
    }
}
```

> **Note**: don't add the keep-alive header when handle request on your server, otherwise you may get a 520 error when you access your website on browser: `Error 520: Web server is returning an unknown error` 
>
> ```go
> w.Header().Set("Connection", "Keep-Alive")
> w.Header().Set("Keep-Alive", "timeout=2, max=1000")
> ```

Learn more: https://luyuhuang.tech/2020/06/03/cloudflare-free-https.html

> After config this, the DNS needs time to take effect (you change the nameservers of your domain to Cloudfalre from the defatult nameservers, this needs time to take effect) 
>
> If there still no HTTPS connection but the cloudflare displays your website **is active** on their service, you may try to check if your server is listening on 443 port and try to flush the DNS cache of your client computer (chrome + system DNS cache). Learn more: [DNS Concepts (NameServer(NS), DNS Records and Caching) - David's Blog](https://davidzhu.xyz/post/networking/002-dns-basics/)

BTW, you can check if your domain is proxied by the Cloudflare with nslookup command, which will get the `A Record` by default (IPv4) address of your domain, but in this case, with Cloudfalre proxy, you should get the ip of Cloudfalre Name Server. 

```shell
❯ nslookup shaowenzhu.top
Non-authoritative answer:
Name:	shaowenzhu.top
Address: 172.67.171.207 # not my domain's real ip, it's Cloudfalre
Name:	shaowenzhu.top
Address: 104.21.47.185 # not my domain's real ip, it's Cloudfalre

```

Learn more: [Add a site · Cloudflare Fundamentals docs](https://developers.cloudflare.com/fundamentals/setup/account-setup/add-site/)

## 2. Change A record

If you changed a vps, all you need to do is to change the A record of your domain on Cloudflare, you don't need to change the A record on your domain register website.

> Cloudflare serves as a **reverse proxy**, directing all traffic for the specified proxied domain to the target IP address.

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2024/08/af17da33f67f363301b8d14cf87428ea.png)

## 3. Allow custom port

The default port of https is 443. If you want to use other ports, you need to allow them with firewall first on your server.

Cloudflare only allows the following **HTTPS** ports:

443
2053
2083
2087
2096
8443

Very easy, you don't need to do anything on Cloudflare, just allow the port on your server. Then you can access your website with `https://your_domain:port`. And your traffic will be encrypted by Cloudflare. 

Learn more:

[How to allow custom port - Website, Application, Performance / Security - Cloudflare Community](https://community.cloudflare.com/t/how-to-allow-custom-port/175855)

[Network ports · Cloudflare Fundamentals docs](https://developers.cloudflare.com/fundamentals/reference/network-ports/)

Learn more about CDN: 

[What is a content delivery network (CDN)? | How do CDNs work? | Cloudflare](https://www.cloudflare.com/learning/cdn/what-is-a-cdn/)

[Reference Architecture: Cloudflare Content Delivery Network (CDN) · Cloudflare Reference Architecture docs](https://developers.cloudflare.com/reference-architecture/architectures/cdn/)