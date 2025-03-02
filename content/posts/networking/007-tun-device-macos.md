---
title: Working with TUN Device on MacOS
date: 2023-09-12 08:31:59
categories:
 - 计算机网络
tags:
 - 计算机网络
 - vpn
---

## 1. TUN on MacOS

On macOS, the `utun` interface is a type of TUN device specifically designed for VPN connections to handle the network traffic **within the VPN tunnel** [regardless of whether VPN is enabled](https://apple.stackexchange.com/questions/310220/who-creates-utun0-adapter). 

I'll give you an example to demonstrate the realtionship between TUN device and utun interface, the code below written in Go is to create a TUN device:

```go
// New() creates a new TUN/TAP interface using config.
ifce, err := water.New(water.Config{DeviceType: water.TUN})
```

Before run this code there are 4 utun interfaces on my mac:

```shell
$ ifconfig
utun0: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 1380
	inet6 fe80::652e:88dd:ddb0:ad93%utun0 prefixlen 64 scopeid 0xf 
	nd6 options=201<PERFORMNUD,DAD>
...
utun4: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 1380
	inet6 fe80::e305:5ba8:574a:a5ac%utun4 prefixlen 64 scopeid 0x13 
	nd6 options=201<PERFORMNUD,DAD>
```

After I run the Go codes above with `sudo`, there are 5 utun interfaces but with no ip information:

```shell
$ ifconfig
...
utun4: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 1380
	inet6 fe80::e305:5ba8:574a:a5ac%utun4 prefixlen 64 scopeid 0x13 
	nd6 options=201<PERFORMNUD,DAD>
utun5: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 1500
```

> `utun*` is a **point-to-point** interface, also called a tunnel or a peer-to-peer interface, It doesn't behave like "shared medium" interfaces such as Wi-Fi or Ethernet, which connect you to multiple devices. Instead, it behaves like a cable that just has hosts on both ends. 
>
> There are no layer-2 headers, no MAC addresses, and no ARP on a point-to-point interface, because everything sent through it reaches the same destination (the "peer" host).
>
> Source: https://superuser.com/a/1446061/1689666

## 2. `utun` is an instance of TUN device

**You can think `utun*` is an instance of TUN device on Mac, a TUN device can have many instances.**

OS treat virtual network interface (tun/tap devices) as same to the physical network interface, which means virtual network interface can have anything (including ip address) that physical network interface have. 

`utun*` is just a network interface similar to `en0`, `lo0`, when you input `ifconfig` command, they will listed together:

```shell
$ ifconfig     
lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> mtu 16384
	options=1203<RXCSUM,TXCSUM,TXSTATUS,SW_TIMESTAMP>
	inet 127.0.0.1 netmask 0xff000000 
	inet6 ::1 prefixlen 128 
	inet6 fe80::1%lo0 prefixlen 64 scopeid 0x1 
	nd6 options=201<PERFORMNUD,DAD>
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	options=6463<RXCSUM,TXCSUM,TSO4,TSO6,CHANNEL_IO,PARTIAL_CSUM,ZEROINVERT_CSUM>
	ether d4:57:63:da:b6:98 
	inet6 fe80::475:ca98:8ecc:d86%en0 prefixlen 64 secured scopeid 0xc 
	inet 192.168.2.15 netmask 0xffffff00 broadcast 192.168.2.255
	inet6 fdd0:ed77:f347:4d69:859:d993:f358:5af9 prefixlen 64 autoconf secured 
	nd6 options=201<PERFORMNUD,DAD>
	media: autoselect
	status: active
en1: flags=8963<UP,BROADCAST,SMART,RUNNING,PROMISC,SIMPLEX,MULTICAST> mtu 1500
	options=460<TSO4,TSO6,CHANNEL_IO>
	ether 36:6b:75:95:04:c0 
	media: autoselect <full-duplex>
	status: inactive
utun0: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 1380
	inet6 fe80::652e:88dd:ddb0:ad93%utun0 prefixlen 64 scopeid 0xf 
	nd6 options=201<PERFORMNUD,DAD>
utun1: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 2000
	inet6 fe80::a13f:9a63:f8cb:4017%utun1 prefixlen 64 scopeid 0x10 
	nd6 options=201<PERFORMNUD,DAD>
...
```

Find more about what these interface are: https://stackoverflow.com/a/55232331/16317008

e.g.,

```shell
utun3: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 1500
        inet 10.8.0.18 --> 10.8.0.17 netmask 0xffffffff
```

With "normal" interfaces, configuring an address with subnet mask like `192.168.1.3/24` on eth0 is really just shorthand for saying "My address is `192.168.1.3` and I also have an on-link route `192.168.1.0/24 dev eth0`". The on-link route is derived from combining the address & subnet mask.

With point-to-point interfaces, it's actually the same idea. This example means "My address is `10.8.0.18` and I also have an on-link route `10.8.0.17/32 dev utun3`." In this case the autogenerated route is a /32, indicating only one host – the "peer".

*(Note: My examples use Linux iproute2-style syntax.)* So in the end, the difference between `10.8.0.17 netmask 0xffffffff` and `10.8.0.17/32` styles is just that automatic route. 

Source: https://superuser.com/a/1446061/1689666

## 3. Set up ip for `utun` interface

```shell
$ tldr ifconfig
- View network settings of an Ethernet adapter:
    ifconfig eth0

- Display details of all interfaces, including disabled interfaces:
    ifconfig -a

- Disable eth0 interface:
    ifconfig eth0 down

- Enable eth0 interface:
    ifconfig eth0 up

- Assign IP address to eth0 interface:
    ifconfig eth0 ip_address
```

For example, if you have two machines, one we label "local" with a LAN IP address like 192.168.0.12 and another we label "remote" with a LAN IP address like 192.168.1.14, you can assign tunnel IP addresses thusly:

```shell
ifconfig tun0 inet 10.0.0.1 10.0.0.2 up
```

on the local system, and:

```shell
ifconfig tun0 inet 10.0.0.2 10.0.0.1 up
```

on the remote system. Note the reversed perspective on the remote machine. Do not set your point to point addresses to anything on an existing subnet; it will not route properly.

> Note, if you set a wrong interface, you can cancle it with  `sudo ifconfig utun2 delete 10.1.0.10 10.1.0.20 ` or `ifconfig en1 delete 192.168.141.99` for differnt types of network interfaces.

Source: https://stackoverflow.com/a/17511998/16317008

## 4. Use TUN capture ip packets with Go on MacOS

```shell
go get -u github.com/songgao/water
```

```go
func main() {
	ifce, err := water.New(water.Config{DeviceType: water.TUN})
	if err != nil {
		log.Fatal(err)
	}

	log.Printf("Interface Name: %s\n", ifce.Name())

	packet := make([]byte, 1500)
	for {
		n, err := ifce.Read(packet)
		if err != nil {
			log.Fatal(err)
		}
		log.Printf("Packet Received: % x\n", packet[:n])
	}
}
```

```shell
# NOTE: replace utunx with the name printed on your go code above
$ sudo ifconfig utun5 10.1.0.10 10.1.0.20 up
```

Then :

```shell
ping -c 1 10.1.0.20
```

If no data printed on your go codes, restart your go codes and change a pair of ip addresses for utun interface.

Learn more: 

- [songgao/water: A simple TUN/TAP library written in native Go.](https://github.com/songgao/water)
- [TUN Device & utun Interface](https://davidzhu.xyz/post/cs-basics/011-tun-device/)
