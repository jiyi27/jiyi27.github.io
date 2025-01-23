---
title: Tunneling Protocols
date: 2023-09-10 08:27:59
categories:
 - networking
tags:
 - networking
---

## VPN

VPN（Virtual Private Network）的核心特性之一就是使用隧道协议（Tunneling Protocol）。通过这些隧道协议，VPN 能够保证数据在不安全的网络中的安全传输，使得VPN在保护在线隐私和绕过网络限制方面非常有效。

常见的隧道协议包括：
- **IPsec (Internet Protocol Security)**：用于在IP通信过程中确保数据的完整性、认证和机密性。
- **OpenVPN**：一个基于SSL/TLS的开源VPN协议，提供高度的安全性和灵活性。
- **WireGuard**：一个较新的协议，旨在提供更高的速度和更先进的加密技术。
- **SSL/TLS (Secure Sockets Layer/Transport Layer Security)**：SSL VPN usually connects using a Web browser, whereas an IPSec VPN generally requires client software on the remote system.
  - SSL VPN is a component of virtually every Web browser. Any OS that runs a browser is supported.

> OpenVPN 是一个独立的 VPN 协议，它不使用像 PPTP、L2TP 或 IPsec 这样的标准隧道协议。相反，OpenVPN 使用自己的协议，基于 SSL/TLS 来提供加密和安全连接。它是一个开源的软件应用程序，允许创建安全的点对点或站点对站点连接 OpenVPN 的关键特性包括：
> 1. **自定义加密协议**：虽然基于 SSL/TLS，但 OpenVPN 有其独特的实现方式，允许高度的定制和灵活性。
> 2. **身份验证**：支持各种认证机制，包括证书、预共享密钥和用户认证。
> 3. **跨平台兼容性**：OpenVPN 可以在多种操作系统上运行，包括 Windows、macOS、Linux 和移动平台。

## 1. Tunneling

In [previous post](https://davidzhu.xyz/post/networking/007-tun-tap-device/), we know that ***TUN*** and ***TAP*** are two different kernel virtual network devices, which are used for **tunneling** purposes. In this post, we'll discuss what is tunneling and coomon tunneling protocols. 

In the physical world, tunneling is a way to cross terrain or boundaries that could not normally be crossed. Similarly, in networking, tunnels are a method for transporting data across a network using protocols that are not supported by that network. **Tunneling works by encapsulating packets: wrapping packets inside of other packets.** 

> Encapsulating packets within other packets is called "tunneling." 

Because tunneling involves repackaging the traffic data into a different form, perhaps with encryption as standard, it can hide the nature of the traffic that is run through a tunnel. 

> Encapsulation:
>
> Data traveling over a network is divided into packets. A typical packet has two parts: the **header**, which indicates the packet's destination and which protocol it uses, and the **payload**, which is the packet's actual contents. 
>
> **An encapsulated packet is essentially a packet inside another packet**. In an encapsulated packet, the header and payload of the first packet goes inside the payload section of the surrounding packet. **The original packet itself becomes the payload.** 

> A VPN just uses one of the tunneling protocols, therefore, when you know how each tunneling protocol works, you will know the essence of VPN of that type. 

## 2. Types of Tunneling protocol

In addition to **GRE, IPsec, IP-in-IP, and SSH**, other tunneling protocols include:

- Point-to-Point Tunneling Protocol (PPTP)
- Secure Socket Tunneling Protocol (SSTP)
- Layer 2 Tunneling Protocol (L2TP)
- Virtual Extensible Local Area Network (VXLAN)

## 3. IPsec - Network layer

The IPsec protocol suite operates at the **network layer** of the OSI model. Within the term "IPsec," "IP" stands for "**Internet Protocol**" and "sec" for "secure."  IPsec usually uses port 500.

The Internet Protocol is the main routing protocol used on the Internet; it designates where data will go using [IP addresses](https://www.cloudflare.com/learning/dns/glossary/what-is-my-ip-address/). IPsec is secure because it **adds encryption and authentication** to this process. 

### 3.1. Why IPSec is important?

Networking protocol suites like **TCP/IP are only concerned with connection and delivery**, and messages sent are not concealed. Anyone in the middle can read them. IPsec, and other protocols that encrypt data, essentially put an envelope around data as it traverses networks, keeping it secure. 

### 3.2. How does IPsec work?

IPsec connections include the following steps:

**Key exchange:** [Keys](https://www.cloudflare.com/learning/ssl/what-is-a-cryptographic-key/) are necessary for encryption;

**Packet headers and trailers:** IP packets contain both a payload and a header. IPsec adds several headers to data packets containing authentication and encryption information. IPsec also adds trailers, which go after each packet's payload instead of before.

Learn more: [What is IPsec? | How IPsec VPNs work | Cloudflare](https://www.cloudflare.com/learning/network-layer/what-is-ipsec/)

### 3.3. IPsec tunnel and IPsec transport mode

1. **Tunnel Mode**：
   - 在隧道模式下，IPsec对整个IP数据包（包括头部信息）进行加密。
   - 这意味着原始的IP数据包被封装在一个新的IP数据包中。新的数据包有一个新的IP头部。
   - 隧道模式常用于VPN（Virtual Private Network，虚拟私人网络），允许不同网络之间安全地传输数据。

2. **Transport Mode**：
   - 在传输模式下，IPsec只加密IP数据包的有效载荷（Payload），而不加密头部信息。

### 3.4. What protocols are used in IPsec?

In [networking](https://www.cloudflare.com/learning/network-layer/what-is-the-network-layer/), a protocol is a specified way of formatting data so that any networked computer can interpret the data. **IPsec is not one protocol, but a suite of protocols**. The following protocols make up the IPsec suite:

**Authentication Header (AH):** The AH protocol ensures that data packets are from a trusted source and that the data has not been tampered with, like a tamper-proof seal on a consumer product. These headers do not provide any encryption; they do not help conceal the data from attackers.

**Encapsulating Security Protocol (ESP):** ESP encrypts the IP header and the payload for each packet — unless transport mode is used, in which case it only encrypts the payload. ESP adds its own header and a trailer to each data packet.

**Security Association (SA):** SA refers to a number of protocols used for negotiating encryption keys and algorithms. One of the most common SA protocols is Internet Key Exchange (IKE).

Finally, while the **Internet Protocol (IP)** is not part of the IPsec suite, IPsec runs directly on top of IP.

### 3.5. How does IPsec impact MSS and MTU?

IPsec protocols add several headers and trailers to packets, all of which take up several bytes. For networks that use IPsec, either the MSS and MTU have to be adjusted accordingly, or packets will be fragmented and slightly delayed. Usually, the MTU for a network is 1,500 bytes. A normal IP header is 20 bytes long, and a TCP header is also 20 bytes long, meaning each packet can contain 1,460 bytes of payload. However, **IPsec adds an Authentication Header, an ESP header, and associated trailers**. These add 50-60 bytes to a packet, or more.

## 4. GRE - Network Layer

Encapsulating packets within other packets is called "tunneling." GRE tunnels are usually configured between two routers, with each router acting like one end of the tunnel. The routers are set up to send and receive GRE packets directly to each other. **Any routers in between those two routers** will not open the encapsulated packets; they only reference the headers surrounding the encapsulated packets in order to forward them.

GRE enables the usage of protocols that are not normally supported by a network, because the packets are wrapped within other packets that do use supported protocols. To understand how this works, think about the difference between a **car** and a **ferry**. A **car** travels over roads on land, while a **ferry** travels over **water**. A **car** cannot normally travel on **water** — however, a **car** can be loaded onto a **ferry** in order to do so. 

For instance, suppose a company needs to set up a connection between the [local area networks (LANs)](https://www.cloudflare.com/learning/network-layer/what-is-a-lan/) in their two different offices. Both LANs use the latest version of the [Internet Protocol](https://www.cloudflare.com/learning/network-layer/internet-protocol/), IPv6. But in order to get from one office network to another, traffic must pass through a network managed by a third party — which is somewhat outdated and only supports the older IPv4 protocol.

With GRE, the company could send traffic through this network by encapsulating IPv6 packets within IPv4 packets. Referring back to the analogy, the **IPv6 packets are the car**, the IPv4 packets are the ferry, and the **third-party network is the water**.

### 4.1. What goes in a GRE header?

GRE adds two headers to each packet: the GRE header, which is 4 bytes long, and an IP header, which is 20 bytes long. The GRE header indicates the protocol type used by the encapsulated packet. The IP header encapsulates the original packet's header and payload. This means that a GRE packet usually has two IP headers: one for the original packet, and one added by the GRE protocol. Only the routers at each end of the GRE tunnel will reference the original, non-GRE IP header.

### 4.2. How does the use of GRE impact MTU and MSS requirements?

Like any protocol, using GRE adds a few bytes to the size of data packets. This must be factored into the MSS and MTU settings for packets. If the MTU is 1,500 bytes and the MSS is 1,460 bytes (to account for the size of the necessary IP and [TCP](https://www.cloudflare.com/learning/ddos/glossary/tcp-ip/) headers), the addition of GRE 24-byte headers will cause the packets to exceed the MTU:

*1,460 bytes [payload] + 20 bytes [TCP header] + 20 bytes [IP header] + 24 bytes [GRE header + IP header] = 1,524 bytes*

As a result, the packets will be fragmented. Fragmentation slows down packet delivery times and increases how much compute power is used, because packets that exceed the MTU must be broken down and then reassembled.

This can be avoided by reducing the MSS to accommodate the GRE headers. If the MSS is set to 1,436 instead of 1,460, the GRE headers will be accounted for and the packets will not exceed the MTU of 1,500:

*1,436 bytes [payload] + 20 bytes [TCP header] + 20 bytes [IP header] + 24 bytes [GRE header + IP header] = 1,500 bytes*

While fragmentation is avoided, the result is that payloads are slightly smaller, meaning it will take extra packets to deliver data. For instance, if the goal is to deliver 150,000 bytes of content (or about 150 kB), and if the MTU is set to 1,500 and no other layer 3 protocols are used, compare how many packets are necessary when GRE is used versus when it is not used:

- Without GRE, MSS 1,460: **103** packets
- With GRE, MSS 1,436: **105** packets

The extra two packets add milliseconds of delay to the data transfer. However, the usage of GRE may allow these packets to take faster network paths than they could otherwise take, which can make up for the lost time.

## 5. SSH Tunneling  - Application layer

The Secure Shell (SSH) protocol sets up encrypted connections between client and server, and can also be used to set up a secure tunnel. SSH operates at layer 7 of the OSI model, the application layer. By contrast, IPsec, IP-in-IP, and GRE operate at the network layer.

A *[Secure Shell](https://en.wikipedia.org/wiki/Secure_Shell) (SSH) tunnel* consists of an encrypted tunnel created through an [SSH protocol](https://en.wikipedia.org/wiki/Secure_Shell) connection. Users may set up SSH tunnels to transfer [unencrypted](https://en.wikipedia.org/wiki/Unencrypted) traffic over a network through an [encrypted](https://en.wikipedia.org/wiki/Encrypted) channel. It is a software-based approach to network security and the result is transparent encryption. 

References:

- [What is IPsec? | How IPsec VPNs work | Cloudflare](https://www.cloudflare.com/learning/network-layer/what-is-ipsec/)
- [What is tunneling? | Tunneling in networking | Cloudflare](https://www.cloudflare.com/learning/network-layer/what-is-tunneling/)
- [Tunneling protocol](https://en.wikipedia.org/wiki/Tunneling_protocol)
- [What is GRE tunneling? | How GRE protocol works | Cloudflare](https://www.cloudflare.com/learning/network-layer/what-is-gre-tunneling/)
