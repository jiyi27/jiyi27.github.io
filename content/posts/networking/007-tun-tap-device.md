---
title: TUN/TAP Devices
date: 2023-09-08 17:54:59
categories:
 - networking
tags:
 - networking
---

## 1. TUN/TAP Devices

In computer networking, **TUN** and **TAP** are two different kernel **virtual network devices**. Though both are for tunneling purposes, TUN and TAP can't be used together because they transmit and receive packets at different layers of the network stack. TUN (network TUNnel) devices are used for IP packet-level tunneling, while TAP (network TAP) devices are used for Ethernet frame-level tunneling.

> A network interface can be a physical device, called network interface controller (NIC), such as an ethernet card or wireless adapter, or a virtual device, such as a TUN or TAP interface. 
>
> Source: https://www.baeldung.com/linux/create-check-network-interfaces
>
> TUN/TAP provides packet reception and transmission for user space programs. It can be seen as a simple Point-to-Point or Ethernet device, which, instead of receiving packets from physical media, receives them from user space program and instead of sending packets via physical media writes them to the user space program. It interacts with user space program not the kernel. 
>
> Source: https://docs.kernel.org/networking/tuntap.html

## 2. TUN/TAP & Network Stack

TUN/TAP is an operating-system interface for creating network interfaces managed by userspace. This is usually used to implement userspace Virtual Private Networks[[1\]](https://www.gabriel.urdhr.fr/2021/05/08/tuntap/#fn1) (VPNs), for example with [OpenVPN](https://openvpn.net/), [OpenSSH](https://www.gabriel.urdhr.fr/2017/08/02/foo-over-ssh/#tuntap-forwarding) (`Tunnel` configuration or `-w` argument), [l2tpns](https://code.ffdn.org/l2tpns/l2tpns), etc.

```
+--------------------------------------------+
| Processes                                  |
+--------------------------------------------+
  ↕ Socket interface
+---------------------------------------------+
| Network Stack (kernel)                      |<--+
+---------------------------------------------+   |
  ↕ Eth. frame     ↕ Eth. frame    ↕ IP packet    |
+--------------+ +-------------+ +------------+   |
| enp2s0       | | tap0        | | tun0       |   |
+--------------+ +-------------+ +------------+   |
  ↑ Eth. frame     ↕ Eth. frame¹   ↕ IP packet¹   |
+--------------+ +-------------+ +------------+   |
| Driver       | | Process     | | Process    |   |
+--------------+ +-------------+ +------------+   |
  ↕ Eth. frame²    ↑               ↑              |
+--------------+   +---------------+--------------+
| Eth. Adapter  |  (encapsulated packets)
+--------------+
  ↕ Eth. frame
+--------------+
| Eth. Network |
+--------------+
Physical netdev    Ethernet VPN      IP VPN


¹: via /dev/net/tun
²: over PCI Express for example
```

There are many applications running on our OS (reside in user space), they send network packets with socket interface (on linux). All the packets through **socket interface** will go to one place: the **Network Stack** (resides in kernel). And the packets from the Network Stack only have two direction to go, one is the physical network interfce (**NIC**), another direction is the virtual network devices **tap/tun**, and we can get the packets from tap/tun which usually used in VPN application (resides in user space). Of course, VPN applicatipn (user space) can write packet into **tap/tun** devices and after written into tap/tun the packet will goes to **Network Stack**, and there are two direction again... 

You probably notice that if we use TUN/TAP devices to handle the packets from other normal  applications, the packet seem to go through the Network Stack twice: the normal applications write data into socket interface and these packets will go through Netwok Stack and intercepted by TUN/TAP devices, then after vpn handles these packets, these packet will be sent to Network Stack again, which probably not efficient. (Notice that in qemu-kvm, tap device works with bridge, and the packets goes to bridge directly without going through Network Stack which is more efficient)

Applications send or receive packet to/from socket interface:

```c
int socket = socket(AF_PACKET,SOCK_RAW,IPPROTO_IP)
```

VPN application send or receive packet to/from tun devices:

```c
// Request a TUN device
int fd = open("/dev/net/tun", O_RDWR);

// receives a (single) packet or frame from the virtual network interface;
// Read an IP packet (because TUN works on IP layer):
ssize_t count = read(fd, buffer, BUFFLEN);

// sends a (single) packet or frame to the virtual network interface;
write(...) 
```

Source: [TUN/TAP interface (on Linux) - /dev/posts/](https://www.gabriel.urdhr.fr/2021/05/08/tuntap/)

## 3. TUN vs. TAP

There are two types of virtual network interfaces managed by `/dev/net/tun`:

- TUN interfaces transport IP packets (layer 3);
- TAP interfaces transport Ethernet frames (layer 2).

### 3.1. TUN interfaces (L3)

TUN interfaces (`IFF_TUN`) transport layer 3 (L3) Protocol Data Units (PDUs):

- in practice, it transports IPv4 and/or IPv6 packets;
- `read()` gets a L3 PDU (an IP packet);
- you must `write()` L3 PDUs (an IP packet);
- there is no layer 2 (Ethernet, etc.) involved in the interface;

### 3.2. TAP interfaces (L2)

TAP interfaces (`IFF_TUN`) transport layer 2 (L2) PDUs:

- in practice, it transports Ethernet frames (i.e. this is a virtual Ethernet adapter);
- `read()` gets a L2 PDU;
- you must `write()` L2 PDUs.

Source: [TUN/TAP interface (on Linux) - /dev/posts/](https://www.gabriel.urdhr.fr/2021/05/08/tuntap/)

## 4. Set up TUN/TAP devices

Because TUN is a layer 3 connection, it acts as a point-to-point link. We’ll assign these parameters:

- local address (for your machine): 192.0.2.1
- remote address (for Scapy): 192.0.2.2

On Linux, you would use:

```shell
sudo ip link set tun0 up
sudo ip addr add 192.0.2.1 peer 192.0.2.2 dev tun0 
# sudo ip addr add 192.0.2.1 peer 192.0.2.2 dev tun0  up
```

On BSD and macOS, use:

```shell
sudo ifconfig tun0 up
sudo ifconfig tun0 192.0.2.1 192.0.2.2
# sudo ifconfig tun0 192.0.2.1 192.0.2.2 up
```

Source: https://scapy.readthedocs.io/en/latest/layers/tuntap.html#tuntapinterface-reference
