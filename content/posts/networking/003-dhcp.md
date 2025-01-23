---
title: DHCP Basics
date: 2023-10-30 23:43:06
categories:
 - networking
tags:
 - networking
---

## 1. Concepts

Every device on a TCP/IP-based network must have a unique unicast IP address to access the network and its resources. Without DHCP, IP addresses for new computers or computers that are moved from one subnet to another must be configured manually; IP addresses for computers that are removed from the network must be manually reclaimed.

With DHCP, this entire process is automated and managed centrally. The DHCP server maintains a pool of IP addresses and leases an address to any DHCP-enabled client when it starts up on the network. Because the IP addresses are dynamic (leased) rather than static (permanently assigned), addresses no longer in use are automatically returned to the pool for reallocation.

> The Dynamic Host Configuration Protocol (DHCP) is a network management protocol used on Internet Protocol (IP) networks for **automatically assigning IP addresses and other communication parameters to devices** connected to the network using a client–server architecture.  [Dynamic Host Configuration Protocol](https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol)

## 2. Process of DHCP

1. DHCP Discover: When a computer (client) joins a network, it sends out a DHCP Discover message as a broadcast to discover DHCP servers available on the network.
2. DHCP Offer: DHCP servers that receive the Discover message respond with a DHCP Offer message. This message contains configuration parameters, including IP address, subnet mask, default gateway, and **DNS server addresses**.
3. DHCP Request: The computer selects one of the DHCP Offers and sends a DHCP Request message to the chosen DHCP server, indicating its acceptance of the offered configuration.
4. DHCP Acknowledge: Upon receiving the DHCP Request, the DHCP server sends a DHCP Acknowledge message to the computer, confirming the lease of the offered configuration parameters. The computer now configures its network interface with the provided settings.

## 3. DHCP discover message & DHCP offer message

Learn more about these two messages' format: [Dynamic Host Configuration Protocol](https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol)

References: [Dynamic Host Configuration Protocol (DHCP) | Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/networking/technologies/dhcp/dhcp-top)