---
title: MPLS
date: 2023-11-17 08:27:59
categories:
 - networking
tags:
 - networking
typora-root-url: ../../../static
---

## 1. OSPF, BGP and MPLS

- OSPF: OSPF is an interior gateway protocol (IGP) used for routing within an autonomous system (AS). It determines the best paths for routing packets based on metrics such as bandwidth, delay, and cost.
- ﻿﻿BGP: BGP is an exterior gateway protocol (EGP) used for routing between autonomous systems. It enables the exchange of routing information between different networks and determines the best paths between ASes.
- ﻿﻿MPLS: MPLS is not a routing protocol but a forwarding mechanism that operates at the network layer. It uses labels to encapsulate packets, creating virtual paths called Label Switched Paths (LSPs). MPLS allows for efficient forwarding and traffic engineering by quickly switching packets based on labels instead of performing complex IP routing.

> **Routers** refer to internal **routing tables** to make decisions about how to route packets along network paths. A routing table records the paths that packets should take to reach every destination that the router is responsible for. 

## 2. MPLS

### 2.1. Basic concepts

In a network that uses MPLS, each packet is assigned to a class called a forwarding equivalence class (FEC). The network paths that packets can take are called label-switched paths (LSP). A packet's class (FEC) determines which path (LSP) the packet will be assigned to. Packets with the same FEC follow the same LSP.

Each packet has one or more **labels** attached, and all labels are contained in an **MPLS header**, which is added on top of all the other headers attached to a packet. **FECs** are listed within each packet's labels. Routers do not examine the packet's other headers; they can essentially ignore the IP header. Instead, they examine the packet's label and direct the packet to the right **LSP**.

Because MPLS-supporting routers only need to see the MPLS labels attached to a given packet, MPLS can work with almost any protocol (hence the name "multiprotocol"). It does not matter how the rest of the packet is formatted, as long as the router can read the MPLS labels at the front of the packet.

<img src="/008-mpls/aa.png" alt="aa" style="zoom:33%;" />

- Label value: the name says it all, this is where you will find the value of the label.
- EXP: these are the three experimental bits. These are used for QoS, normally the IP precedence value of the IP packet will be copied here.
- S: this is the “bottom of stack” bit. With MPLS it’s possible to add more than one label, you’ll see why in some of the MPLS VPN lessons. When this bit is set to one, it’s the last MPLS header. When it’s set to zero then there is one or more MPLS headers left.
- TTL: just like in the IP header, this is the time to live field. You can use this for traces in the MPLS network. Each hop decrements the TTL by one.

### 2.2. FECs

> FEC is a term used in MPLS networks to describe a set of incoming packets with similar characteristics, allowing those packets to be allocated the same label and forwarded down the same LSP (Label Switched Path). [FEC - Forwarding Equivalence Class](https://www.mpirical.com/glossary/fec-forwarding-equivalence-class.)

In previous part we said: **FECs** are listed within each packet's labels. But, wait, how?

An FEC is a set of packets that a single router:

(1) Forwards to the same next hop;

(2) Out the same interface; and

(3) With the same treatment (such as queuing).

### 2.3. Step-by-Step a packet in MPLS network

1. **Packet Enters the MPLS Network:**
   - Imagine a data packet entering an MPLS network at an 'ingress router'.
   - The ingress router examines the header of the packet (like destination IP address).
2. **Label Assignment:**
   - Based on this examination, the router assigns a 'label' to the packet. This label is a short, fixed-length identifier.
   - The process of assigning a label is known as 'label imposition'.
   - Each label corresponds to a pre-determined path through the network, known as a Label Switched Path (LSP).
3. **Packet Travels through the MPLS Network:**
   - Once the packet has been labeled, it is sent into the MPLS network.
   - As it reaches each router (or label switch router, LSR) in the MPLS network, the router does not need to examine the IP header. Instead, it looks at the label.
   - Based on the label, the LSR quickly determines where to send the packet next. This is a process called 'label switching'.
   - The LSR may also swap the packet's existing label with a new label before forwarding it (label swapping). This is done to maintain the correct routing path as defined by the LSP.
4. **Approaching the Exit of the MPLS Network:**
   - As the packet approaches the end of its path through the MPLS network, it reaches an 'egress router'.
   - The egress router removes the MPLS label from the packet, a process known as 'label popping'.
5. **Packet Leaves the MPLS Network:**
   - After the label is removed, the packet is forwarded based on its original IP header.
   - It is now back in a standard IP-based network and can be routed to its final destination using traditional IP routing methods.

## 3. OSPF, BGP and MPLS

So each packet has a LSP theoretically? which means each packet belongs to a FEC, and each FEC has a LSP, the LSP built by using the routing table formed by OSPF and BGP

Yes, your understanding is on the right track. In MPLS (Multiprotocol Label Switching) networks, the concept of Forwarding Equivalence Classes (FECs) and Label Switched Paths (LSPs) is fundamental. Let's break down these concepts:

### 3.1. Forwarding Equivalence Class (FEC)

- A FEC is essentially a group of IP packets that are forwarded in the same manner (same path, same treatment).
- Each packet that enters an MPLS network is assigned to a FEC.
- The assignment is based on criteria like destination IP address, IP protocol type, source IP address, and even Layer 4 ports.
- The idea is that all packets within a FEC will follow the same LSP and receive similar forwarding treatment.

Label Switched Path (LSP)

- An LSP is a pre-established path that packets in a particular FEC will follow through the MPLS network.
- LSPs are set up by the MPLS control plane, which can use signaling protocols like RSVP-TE or LDP.
- Once an LSP is established, labels are assigned and used to forward the packets along this path.

### 3.2. Interaction with OSPF and BGP

- OSPF and BGP are used to form the routing table, which provides the necessary information about network topology and available paths.
- OSPF is typically used within an autonomous system (internal routing), while BGP is used between autonomous systems (external routing).
- The information from OSPF and BGP helps in determining the best paths for the LSPs.
- Once the best paths are identified, MPLS signaling protocols set up LSPs along these paths, and labels are distributed to the routers (LSRs) on these paths.

### 3.3. Practical Example

- Imagine a packet entering an MPLS network destined for a specific IP address.
- This packet is assigned to a FEC based on its destination IP.
- An LSP for this FEC has already been established using OSPF or BGP routing information.
- The ingress router assigns an MPLS label to the packet based on its FEC.
- The packet is then forwarded through the MPLS network, with each router making forwarding decisions based solely on the MPLS label.
- When the packet reaches the egress router of the MPLS network, the MPLS label is removed, and the packet is forwarded based on its original IP header.

In this way, each packet is associated with a FEC, and each FEC has its LSP. The LSPs are constructed using the routing tables formed by OSPF and BGP, ensuring that packets are forwarded efficiently and along optimal paths within the MPLS network. 

References: 

- [What is MPLS (multiprotocol label switching)? | Cloudflare](https://www.cloudflare.com/learning/network-layer/what-is-mpls/)
- [MPLS Labels and Devices](https://networklessons.com/mpls/mpls-labels-and-devices)
- [Understanding the Role of FECs in MPLS | Network World](https://www.networkworld.com/article/2350449/understanding-the-role-of-fecs-in-mpls.html)

