---
title: Common Network Attacks
date: 2023-10-30 22:44:57
categories:
 - networking
tags:
 - cybersecurity
 - http
 - networking
typora-root-url: ../../../static
---

## 1. Man-in-the-middle attack

Learn more: 

https://davidzhu.xyz/post/cs-basics/002-ssh/

[HTTPS SSL TLS - David's Blog](https://davidzhu.xyz/post/cs-basics/003-ssl-secure-communication/#4-details-in-tls-handshake---avoid-man-in-middle-attack)

## 2. DDoS attack

Learn more: [DDoS Attack - David's Blog](https://davidzhu.xyz/post/networking/004-ddos-attack/)

## 3. CSRF attack

Learn more: [CSRF Attack and CORS - David's Blog](https://davidzhu.xyz/post/http/007-csrf-attack/)

## 4. SSL stripping 

SSL stripping attacks, also known as SSL strip, SSL downgrade, or HTTP downgrade attacks, strip the encryption offered by HTTPS, reducing the connection to the less-secure HTTP. 

In order to [“strip” the SSL](https://avicoder.me/2016/02/22/SSLstrip-for-newbies/), an attacker intervenes in the redirection of the HTTP to the secure HTTPS protocol and intercepts a request from the user to the server. The attacker will then continue to establish an HTTPS connection between himself and the server, and an unsecured HTTP connection with the user, acting as a “bridge” between them.

<img src="/004-common-attacks/a.png" alt="a" style="zoom:50%;" />

How can the SSL strip trick both the browser and the website’s server? The SSL strip takes advantage of the way most users come to SSL websites. The majority of visitors connect to a website’s page that redirects through a 302 redirect, or they arrive on an SSL page via a link from a non-SSL site. If the victim wants, for instance, to buy a product and types the URL www.buyme.com in the address bar, the browser connects to the attacker's machine and waits for a response from the server. In an SSL strip, the attacker, in turn, forwards the victim’s request to the online shop’s server and receives the secure HTTPS payment page. For example https://www.buyme.com. At this point, the attacker has complete control over the secure payment page. He downgrades it from HTTPS to HTTP and sends it back to the victim’s browser. The browser is now redirected to http://www.buyme.com. From now onward, all the victim’s data will be transferred in plain text format, and the attacker will be able to intercept it. Meanwhile, the website’s server will think that it has successfully established the secure connection, which indeed it has—but with the attacker’s machine, not the victim’s.

### 4.1. Enable SSL sitewide at all websites

To mitigate this threat, financial institutions and technology firms have [already enabled](https://venafi.com/blog/https-should-be-implemented-everywhereincluding-static-websites/) HTTPS on a site-wide basis. Enabling HTTPS encrypts the connection between a browser and the website, thereby securing sensitive data transmissions. Therefore it makes perfect sense for banks and high-profile technology firms to enable HTTPS on their dynamic websites because of the transaction of important and sensitive information.

### 4.2. Why enable HSTS?

In addition to enabling HTTPS on a site-wide basis, corporations should weigh the benefits of enabling [HSTS](https://www.globalsign.com/en/blog/what-is-hsts-and-how-do-i-use-it/) (HTTP Strict Transport Security), which is a web security policy mechanism that helps to protect websites against SSL stripping attacks and cookie hijacking. **It allows** **web servers to declare that** web browsers should interact with them using only secure HTTPS connections, and never via the insecure HTTP protocol.

When a web application issues HSTS Policy to user browsers, conformant user browsers will [automatically redirect](https://www.owasp.org/index.php/HTTP_Strict_Transport_Security_Cheat_Sheet) any insecure HTTP requests to HTTPS for the target website. In addition, when a man-in-the-middle attacker attempts to intercept traffic from a victim using an invalid certificate, HSTS does not allow the user to override the invalid certificate warning message. By having a HSTS policy installed, it will be nearly impossible for the attackers to intercept any information at all!

Source: [What Are SSL Stripping Attacks? | Venafi](https://venafi.com/blog/what-are-ssl-stripping-attacks/)

## 5. DNS 

### 5.1. DNS hijacking

To prevent DNS hijacking, first, you have to know the different kinds of attacks. DNS hijacking can take four different forms:

1. **Local DNS hijacking:** An attacker installs [Trojan software](https://www.fortinet.com/resources/cyberglossary/trojan-horse-virus) on a user's computer, then modifies the local DNS settings (cahnge its DNS server to a Rogue DNS server). 
2. **DNS hijacking using a router:** Many routers have weak firmware or use the default passwords they were shipped with. Attackers can take advantage of this to hack a router and change its DNS settings, which will affect everyone that uses that router. 
3. **Man-in-the-middle (MITM) attacks:** Attackers use [man-in-the-middle attack techniques](https://www.fortinet.com/resources/cyberglossary/man-in-the-middle-attack) to intercept communications between users and a [DNS server](https://www.fortinet.com/resources/cyberglossary/dynamic-dns). They then direct the target to malicious websites. 


Learn more [What Is DNS Hijacking? How to Detect & Prevent It | Fortinet](https://www.fortinet.com/resources/cyberglossary/dns-hijacking)

### 5.2. DNS spoofing vs DNS (cache) poisoning

- **DNS Poisoning**: 
   - **Definition**: The attacker inserts false address records into the DNS server's cache, causing the server to return incorrect IP addresses for domain names.
   - **Target**: The attack is on the DNS server.
   - **Example**: If `www.example.com` is supposed to resolve to IP `1.2.3.4`, in a DNS poisoning attack, the DNS server might be tricked into resolving it to `5.6.7.8`.

- **DNS Spoofing**:
   - **Definition**: The attacker intercepts and responds to DNS requests with false information, usually **before** the legitimate response is received.
   - **Example**: When a user tries to access `www.example.com`, an attacker might intercept this request and send a fake response directing the user to IP `5.6.7.8` instead of the real IP `1.2.3.4`.

Learn more: [GFW and DNS Poisoning - David's Blog](https://davidzhu.xyz/post/networking/005-gfw-dns/)

### 5.3. Others

1. **DNS Poisoning vs DNS Spoofing**:
   - DNS Poisoning: Inject false DNS info to the real server's cache.
   - DNS Spoofing: Send false response back with a malicious DNS server.

2. **Purpose of MAC Address Spoofing**:
   - To make a switch forward packets to an attacker's device by mimicking a legitimate MAC address.

3. **Use of ICMP Redirects in Man-in-the-Middle Attacks**:
   - An attacker sends forged "ICMP redirect messages" to mislead a host into changing its routing table, diverting traffic through the attacker's machine.

