---
title: DDoS Attack
date: 2023-09-09 09:29:57
categories:
  - networking
tags:
  - networking
  - cybersecurity
---

## 1. DDoS attack

A distributed denial-of-service (DDoS) attack is a malicious attempt to disrupt the normal traffic of a targeted server, service or network by overwhelming the target or its surrounding infrastructure with a flood of Internet traffic.

When a DDoS attack happens, a large volume of traffic is sent to a website. The site under attack typically crashes because the increased traffic exhausts the bandwidth limit or overloads the website’s servers.

{{% youtube "7kB9-nQJR44" %}}

video: https://youtu.be/7kB9-nQJR44?si=R8qrLRhRwlqofAu5

## 2. How does a DDoS attack work?

DDoS attacks are carried out with networks of Internet-connected machines.

These networks consist of computers and other devices (such as IoT devices)which have been infected with [malware](https://www.cloudflare.com/learning/ddos/glossary/malware/), allowing them to be controlled remotely by an attacker. These individual devices are referred to as [bots](https://www.cloudflare.com/learning/bots/what-is-a-bot/) (or zombies), and a group of bots is called a [botnet](https://www.cloudflare.com/learning/ddos/what-is-a-ddos-botnet/).

Once a botnet has been established, the attacker is able to direct an attack by sending remote instructions to each bot.

When a victim’s server or network is targeted by the botnet, each bot sends requests to the target’s [IP address](https://www.cloudflare.com/learning/dns/glossary/what-is-my-ip-address/), potentially causing the server or network to become overwhelmed, resulting in a [denial-of-service](https://www.cloudflare.com/learning/ddos/glossary/denial-of-service/) to normal traffic.

Because each bot is a legitimate Internet device, separating the attack traffic from normal traffic can be difficult.

## 3. How to identify a DDoS attack

The most obvious symptom of a DDoS attack is a site or service suddenly becoming slow or unavailable. But since a number of causes — such a legitimate spike in traffic — can create similar performance issues, further investigation is usually required. Traffic analytics tools can help you spot some of these telltale signs of a DDoS attack:

- Suspicious amounts of traffic originating from a single IP address or IP range
- A flood of traffic from users who share a single behavioral profile, such as device type, geolocation, or web browser version
- An unexplained surge in requests to a single page or endpoint
- Odd traffic patterns such as spikes at odd hours of the day or patterns that appear to be unnatural (e.g. a spike every 10 minutes)

## 4. Challenge Collapsar (CC) attack - DDoS

A Challenge Collapsar (CC) attack is an attack where standard HTTP requests are sent to a targeted web server frequently.

In 2004, a Chinese hacker nicknamed KiKi invented a hacking tool to send these kinds of requests to attack a NSFOCUS firewall named *Collapsar*, and thus the hacking tool was known as *Challenge Collapsar*, or *CC* for short. Consequently, this type of attack got the name *CC attack*. 

> DDoS is not a specific attack, but a general term for a large types of attacks. There are dozens of types, and new attack methods are constantly being invented. 

### 4.1. Intercept cc attack - intercept http request

**(1) Hardware firewall**

Set a physical firewall before your server machine which used to filter request, this is best way but most expensive too.

**(2) Software firewall **

Almost all OS has firewall installed，Linux server usually use [iptables](https://wiki.archlinux.org/index.php/Iptables_(简体中文)), intercept request from IP address  `1.2.3.4`, for example:

```shell
$ iptables -A INPUT -s 1.2.3.4 -j DROP
```

**(3) Web server**

Web can also used to intercept IP address `1.2.3.4`, on nginx:

```
location / {
  deny 1.2.3.4;
}
```

On Apache, modify the  `.htaccess` file:

```
<RequireAll>
    Require all granted
    Require not ip 1.2.3.4
</RequireAll>
```

Web server have a impact impact on the performance when used in firewall and cannot protect when there are huge DDoS attack.

Learn more: https://www.ruanyifeng.com/blog/2018/06/ddos.html

References:

- [What is a distributed denial-of-service (DDoS) attack? | Cloudflare](https://www.cloudflare.com/learning/ddos/what-is-a-ddos-attack/)
- [What is a distributed denial-of-service (DDoS) attack? | Cloudflare](https://www.cloudflare.com/learning/ddos/what-is-a-ddos-attack/)
- [Denial-of-service attack](https://en.wikipedia.org/wiki/Denial-of-service_attack)