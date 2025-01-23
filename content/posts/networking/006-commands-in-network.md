---
title: Tools Commonly Used in Networking
date: 2023-10-31 15:23:08
categories:
 - networking
tags:
 - networking
---

## 1. `nslookup`

### 1.1. Query `A Record` 

```shell
# basic DNS lookup
$ nslookup google.com                             
Server:		192.168.2.1
Address:	192.168.2.1#53

Non-authoritative answer:
Name:	google.com
Address: 142.250.81.238
```

### 1.2. Reverse DNS look-up

```shell
$ nslookup 18.219.46.189                          
Server:		192.168.2.1
Address:	192.168.2.1#53

Non-authoritative answer:
189.46.219.18.in-addr.arpa	name = ec2-18-219-46-189.us-east-2.compute.amazonaws.com.

Authoritative answers can be found from:
46.219.18.in-addr.arpa	nameserver = ns1-24-us-east-2.ec2-rdns.amazonaws.com.
```

### 1.3. Query name server

```shell
$ nslookup -type=ns google.com
Server:		192.168.2.1
Address:	192.168.2.1#53

Non-authoritative answer:
google.com	nameserver = ns1.google.com.
google.com	nameserver = ns3.google.com.
....
```

When using the nslookup utility to query Domain Name System (DNS) servers, you could see the message “Non-authoritative answer.” This tells you that the DNS server you’re asking can’t ensure that it has the official, up-to-date information for the domain name or IP address you’re seeking up and is instead giving you a cached response that it got from another DNS server. 

Please note that getting non-authoritative answers doesn't mean incorrect or unreliable. However, if you need the **most accurate and up-to-date information**, it is recommended to use authoritative DNS servers for queries. 

Reference: 

[Nslookup Command in Linux with Examples - GeeksforGeeks](https://www.geeksforgeeks.org/nslookup-command-in-linux-with-examples/)

[Why is “Non-authoritative answer” given by nslookup? DNS Explained](https://ioflood.com/blog/what-is-the-meaning-of-non-authoritative-answer-given-by-nslookup-dns-demystified/)

### 1.4. Get authoritative answer

**Step 1:** Use the `nslookup` command to query the SOA (Start of Authority) record of the domain name. The SOA record contains information about the authoritative name servers for the domain. 

```bash
❯ nslookup -type=soa davidzhu.xyz
Non-authoritative answer:
...

Authoritative answers can be found from:
davidzhu.xyz	nameserver = ns1.dnsowl.com.
davidzhu.xyz	nameserver = ns2.dnsowl.com.
davidzhu.xyz	nameserver = ns3.dnsowl.com.
```

**Step 2:** Identify the primary name server from previous response:

```shell
❯ nslookup davidzhu.xyz ns1.dnsowl.com
Server:		ns1.dnsowl.com
Address:	162.159.27.173#53

Name:	davidzhu.xyz
Address: 185.199.108.153
```

## 2. `dig`

**dig** command stands for ***Domain Information Groper***. It is used for retrieving information about DNS name servers. Dig command replaces older tools such as [nslooku](https://www.geeksforgeeks.org/nslookup-command-in-linux-with-examples/)p and the [host](https://www.geeksforgeeks.org/host-command-in-linux-with-examples/).

### 2.1. Query `A Record` 

To query domain “A” record with `+short`:

```shell
$ dig geeksforgeeks.org +short
34.218.62.116
```

Specify DNS server:

```shell
$ dig geeksforgeeks.org +short @8.8.8.8
```

> By default, dig command will query the name servers listed in “/etc/resolv.conf” to perform a DNS lookup. We can change it by using @ symbol followed by a hostname or IP address of the name server. 
>
> Learn more about `/etc/resolv.conf` and `/etc/hosts`: [DNS Stub and Recursive Resolver - Config Files - David's Blog](https://davidzhu.xyz/post/networking/002-host-file-dns-stub-resolver/)

### 2.2. Reverse DNS lookup

```shell
❯ dig -x 18.219.46.189 +short
ec2-18-219-46-189.us-east-2.compute.amazonaws.com.
```

### 2.3. Query name server

```shell
❯ dig davidzhu.xyz NS +short
ns1.dnsowl.com.
ns2.dnsowl.com.
ns3.dnsowl.com.
```

## 3. dig vs nslookup

1. `dig` Process:
   - `dig` follows the standard DNS resolution process, starting with a query to the **root name servers** to obtain the list of TLD name servers.
   - It then queries a TLD name server to obtain the authoritative name servers for the domain.
   - After obtaining the **authoritative name servers**, `dig` sends a direct query to one of these name servers to retrieve the A record for the domain.
   - The response obtained from `dig` is typically authoritative, as it comes directly from the authoritative name server responsible for the domain.
2. `nslookup` Process:
   - `nslookup` queries the DNS server configured on the local system by default. This DNS server may be provided by the ISP or manually configured.
   - The response from `nslookup` may be non-authoritative, indicating that the DNS server providing the response is not the authoritative server for the queried domain. It may have obtained the response from its cache or forwarded the query to another DNS server.

In summary, `dig` directly queries authoritative name servers to obtain DNS information, resulting in authoritative responses. On the other hand, `nslookup` queries the local DNS server, which may or may not provide authoritative responses, depending on its configuration and the nature of the query.

