---
title: DNS Stub and Recursive Resolver - Config Files
date: 2023-10-13 14:03:57
categories:
 - networking
tags:
 - networking
---

## 1. `/etc/hosts` and `/etc/resolv.conf`

On Linux or a Mac, if you add this to `/etc/hosts`, facebook no longer exists:

```
127.0.0.1 facebook.com
```

`/etc/hosts` is used to resolve hostnames to IP addresses on a local machine. They're **looked at first**. 

Now... If you don't have an entry for a host in your host file, you need to ask someone what the IP is. That comes from a **resolver**.

## 2. Local resolver & recursive resolver 

> Recursive resolver usually located at remote acts as a DNS server, whereas, a DNS stub resolver running on client devices. 
>
> Most Internet users use a recursive resolver provided by their ISP, but there are other options available; for example [Cloudflare's 1.1.1.1](https://www.cloudflare.com/learning/dns/what-is-1.1.1.1/) or 8.8.8.8 provided by Google. 

```shell
$ cat /etc/resolv.conf
# This is /run/systemd/resolve/stub-resolv.conf managed by man:systemd-resolved(8).
# Do not edit.
nameserver 127.0.0.53
```

`127.0.0.53` is the DNS server address, you can also manually change it to the IP of any DNS server (for example, change it to the famous Google DNS 8.8.8.8).

`127.x.x.x` are loopback addresses that point to the local machine and are bound to the ***"lo"*** (loopback) network device. So who is this DNS server `127.0.0.53`?

```shell
$ sudo netstat -anp | grep 127.0.0.53
tcp        0      0 127.0.0.53:53           0.0.0.0:*               LISTEN      96729/systemd-resol 
udp        0      0 127.0.0.53:53           0.0.0.0:*                           96729/systemd-resol 
```

From the output, we can see that the process uses  `127.0.0.53:53`  called ***systemd-resolve***. In `/etc/resolv.conf` it says that it's maintained by the ***systemd-resolved*** service. So we can try to check its status with systemctl:

```shell
$ systemctl status systemd-resolved
● systemd-resolved.service - Network Name Resolution
     Loaded: loaded (/lib/systemd/system/systemd-resolved.service; enabled; vendor preset: enabled)
     Active: active (running) since Tue 2023-10-10 01:56:13 UTC; 3 days ago
     ....
```

We have know that the current DNS server on this machine is ***systemd-resolve*** which a DNS stub (client). So, what is the IP address of the actual DNS server? We can use the following command to check:

```shell
# $ systemd-resolve --status | grep "DNS Servers"
# In systemd 239 'systemd-resolve' has been renamed to 'resolvectl'
$ resolvectl status | grep 'DNS Servers'
       DNS Servers: 172.31.0.2
       
$ resolvectl status
Global
       Protocols: -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
resolv.conf mode: stub

Link 2 (eth0)
    Current Scopes: DNS
         Protocols: +DefaultRoute +LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
Current DNS Server: 172.31.0.2
       DNS Servers: 172.31.0.2
        DNS Domain: us-east-2.compute.internal
```

> ***DNS stub resolver*** used to initiate DNS queries, and it sends the DNS query to the **recursive resolver**, which then performs the actual DNS resolution process (usually provided by an internet service provider or a public DNS resolver like Google's 8.8.8.8). 

References: https://zhuanlan.zhihu.com/p/101275725

