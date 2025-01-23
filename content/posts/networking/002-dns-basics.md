---
title: DNS Concepts (NameServer(NS), DNS Records and Caching)
date: 2023-10-31 09:50:20
categories:
 - networking
tags:
 - networking
typora-root-url: ../../../static
---

## 1. DNS

DNS stands for Domain Name System, and it is a distributed hierarchical system that translates human-readable domain names into IP addresses. The process of **DNS resolution** involves converting a hostname (such as www.example.com) into a computer-friendly IP address (such as 192.168.1.1). 

The main components of the DNS are DNS servers. All DNS servers fall into one of four categories: Recursive resolvers, root nameservers, TLD nameservers, and authoritative nameservers. 

### 1.1. DNS stub resolver

Before introduce the DNS servers, there is a software runs on the client whcih called DNS stub resolver should be noted. 

DNS stub resolver runs on the client machine, which is used to initiate DNS queries, and it sends the DNS query to the recursive resolver, which then performs the actual DNS resolution process (usually provided by your internet service provider (ISP) or a public DNS resolver like Google's 8.8.8.8 or Cloudflare's 1.1.1.1).  

Learn more: [DNS Stub and Recursive Resolver - Config Files - David's Blog](https://davidzhu.xyz/post/network/002-dns/)

### 1.2. Recursive resolver

As we mentioned above, recursive resolver performs the actual **DNS resolution** process, and it's a DNS server actually, usually provided by your internet service provider (ISP) or a public DNS resolver like Google's `8.8.8.8` or Cloudflare's `1.1.1.1`.  

A recursive resolver (also known as a DNS recursor) is the first stop in a DNS query. The recursive resolver acts as a middleman between a client and a DNS nameserver. When a recursive resolver receives a query from a stub resolver, a recursive resolver will either respond with cached data, or send a request to a *root nameserver*, followed by another request to a *TLD nameserver*, and then one last request to an *authoritative nameserver*. After receiving a response from the authoritative nameserver containing the requested IP address, the recursive resolver then sends a response to the client.

During this process, **the recursive resolver will cache information received from authoritative nameservers**. When a client requests the IP address of a domain name that was recently requested by another client, the resolver can circumvent the process of communicating with the nameservers, and just deliver the client the requested record from its cache.

### 1.3. Root nameserver & TLD nameserver

The 13 DNS root nameservers are known to every recursive resolver, and they are the first stop in a recursive resolver’s quest for DNS records. A root server accepts a recursive resolver’s query which includes a domain name, and the root nameserver responds by directing the recursive resolver to a TLD nameserver, based on the extension of that domain (.com, .net, .org, etc.). 

A TLD nameserver maintains information for all the domain names that share a common domain extension, such as .com, .net, or whatever comes after the last dot in a URL. For example, a .com TLD nameserver contains information for every website that ends in ‘.com’. If a user was searching for google.com, after receiving a response from a root nameserver, the recursive resolver would then send a query to a .com TLD nameserver, which would respond by pointing to the authoritative nameserver (see below) for that domain.

### 1.4. Authoritative nameserver

When a recursive resolver **receives a response from** a TLD nameserver, that response will direct the resolver to an authoritative nameserver. 

The authoritative nameserver contains information specific to the domain name it serves (e.g. google.com) and it can provide a recursive resolver with the IP address of that server found in the [DNS A record](https://www.cloudflare.com/learning/dns/dns-records/dns-a-record/), or if the domain has a [CNAME record](https://www.cloudflare.com/learning/dns/dns-records/dns-cname-record/) (alias) it will provide the recursive resolver with an alias domain, at which point the recursive resolver will have to perform a whole new DNS lookup to procure a record from an authoritative nameserver (often an A record containing an IP address).

> DNS A record is actually a map between the domain name and its ipv4 address. 
>
> DNS CNAME record is an alias for that domain.

After buy a domain on a website, the most common operations we use are that **change its nameservers** and **update its DNS records**:

<img src="/002-dns-basics/a.png" alt="a" style="zoom:33%;" />

Here, Change the NameServers option if to change the **authoritative nameserver** of your domain, and update the DNS records is to set ip address (A record) or alias (CNAME record) for your domain. 

![b](/002-dns-basics/b.png)

## 2. DNS queries

1. **Recursive query** - In a recursive query, a DNS client requires that a DNS server (typically a DNS recursive resolver) will respond to the client with either the requested resource record or an error message if the resolver can't find the record.
2. **Iterative query** - in this situation the DNS client will allow a DNS server to return the best answer it can. 
3. **Non-recursive query**: learn more: [What is DNS? | How DNS works | Cloudflare](https://www.cloudflare.com/learning/dns/what-is-dns/)

## 3. DNS caching

### 3.1. Browser DNS caching

Modern web browsers are designed by default to cache DNS records for a set amount of time. The purpose here is obvious; the closer the DNS caching occurs to the web browser, the fewer processing steps must be taken in order to check the cache and make the correct requests to an IP address. When a request is made for a DNS record, the browser cache is the first location checked for the requested record.

In Chrome, you can see the status of your DNS cache by going to `chrome://net-internals/#dns`.

![c](/002-dns-basics/c.png)

#### 3.2. Operating system (OS) level DNS caching

The operating system level DNS resolver is the second and last local stop before a DNS query leaves your machine. The process inside your operating system that is designed to handle this query is commonly called a “**stub resolver**” or **DNS client**. When a stub resolver gets a request from an application, it first checks its own cache to see if it has the record. If it does not, it then sends a DNS query (with a recursive flag set), outside the local network to a DNS recursive resolver inside the Internet service provider (ISP).

When the recursive resolver inside the ISP receives a DNS query, like all previous steps, it will also check to see if the requested host-to-IP-address translation is already stored inside its local persistence layer.

Source: [What is DNS? | How DNS works | Cloudflare](https://www.cloudflare.com/learning/dns/what-is-dns/)

> Note that checking `/etc/hosts` happens before DNS.

### 3.3. Recursive resolver caching

We have mentioned above, during DNS resolution process, **the recursive resolver will cache information received from authoritative nameservers**. 

A DNS resolver will save responses to IP address queries for a certain amount of time. In this way, the resolver can respond to future queries much more quickly, without needing to communicate with the many servers involved in the typical DNS resolution process.

