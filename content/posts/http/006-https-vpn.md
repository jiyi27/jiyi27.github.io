---
title: HTTPS vs VPN vs Proxy
date: 2023-09-10 10:54:30
categories:
 - http
tags:
 - cryptography
 - http
 - cybersecurity
---

HTTPS is used for encryption, VPN is too. What's difference?

In previou post we talked about [Is HTTPS Secure Enough?](), and we concluded that https is secure itself which means no one can decrypt the data without the session key. However there still are some security issues in HTTPS, the man-in-the-middle attack, for example. 

## Why do I need a VPN if https connections are secure?

A VPN will secure all of the traffic between point A and point B in a tunnel. This helps ensure that you are not having your traffic intercepted by anyone at, say, the coffee shop. 

HTTPS is a secure protocol between your browser and a particular website.

> Note that the tunnel in VPN is not a physical entity but rather a logical concept used to describe the secure pathway created for data transmission. Because tunneling involves repackaging the traffic data into a different form, perhaps with encryption as standard, it can hide the nature of the traffic that is run through a tunnel. [Tunneling protocol](https://en.wikipedia.org/wiki/Tunneling_protocol)
>
> This means the format of the packets transmitted between VPN clients and server are different from the format of OSI model, they are encapulated with tunneling protocol. Acts like your original packets transmitted in a magic container other people cannot know what's in it. Acs like a tunnel. 

However, HTTPS will only help with traffic over port 443, which mean it only provides encryption for data exchanged between a client and a specific server, it does not encrypt all your internet traffic. 

A VPN stops that because everything is connected securely through that pipe. The primary thing that a VPN helps with is what is know as a man in the middle attack: [Man-in-the-middle attack - Wikipedia](https://en.wikipedia.org/wiki/Man-in-the-middle_attack)

## VPN vs Proxy

> In computer networks, a proxy server is a server (a computer system or an application) that acts **as an intermediary** for requests from clients seeking resources from other servers. [Proxy server](https://en.wikipedia.org/wiki/Proxy_server)

> A virtual private network (VPN) is an encrypted connection between two or more computers. VPN connections take place over public networks, but the data exchanged over the VPN is still private because it is encrypted. [IPsec | Cloudflare](https://www.cloudflare.com/learning/network-layer/what-is-ipsec/)

What a VPN does logically is turn your internet connection into a *big Ethernet cable*. When you are logged on to a company's VPN, the effect is similar as though you took your computer to the company's building and directly connected it. VPNs (usually) use encryption so that intermediate systems between you and the company (such as your ISP or a malicious wireless network sniffer) cannot eavesdrop your traffic. 

Proxies, on the other hand, do not typically provide encryption for all traffic and may only encrypt specific types of traffic (such as HTTPS).

Proxies generally work on specific types of application traffic. For example, there are HTTP proxies, DNS proxies, etc. Although there are SOCKS proxies that proxy everything... 

> How do sites like Netflix know I'm using a VPN?
>
> This is often caused by many netflix uers use a same von to access thier streaming service. 
>
> We have known that: when you are logged on to a company's VPN, the effect is similar as though you took your computer to the company's building and directly connected it. 
>
> If eveybody drives the same car to Walmart, Walmart will sooner or later know it's a rental car, but they cannot track this car back to you because everybody drives the car with same the plate.

References: 

- [Why do I need VPN if https connections are secure? - Quora](https://qr.ae/pyL1RD)
- [security - What is the difference between a proxy and a VPN? - Super User](https://superuser.com/questions/257388/what-is-the-difference-between-a-proxy-and-a-vpn)
- [How do sites like Netflix know I'm using a VPN? : VPN](https://www.reddit.com/r/VPN/comments/5mh6uc/how_do_sites_like_netflix_know_im_using_a_vpn/)