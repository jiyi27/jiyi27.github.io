---
title: Wireshark Basics 
date: 2023-09-13 16:52:30
categories:
 - networking
tags:
 - networking
typora-root-url: ../../../static
---

## 1. Structure

![a](/001-wireshark/aaa.png)

## 2. Capture filter

### 2.1. Selcet netowk interface

- `en0` 
  - Physical network interface
- utun0~4
  - VIrtual netwrok interface used for tunneling, learn more: [Working with TUN Device on MacOS - David's Blog](https://davidzhu.xyz/post/networking/007-tun-device-macos/)
- loopback interface: 127.0.0.1
  - When you run a echo server and client on your local machine, you should select the `loopback` interface, not the `en0` interface. 

### 2.2. Specify filter rules

Filter by port and protocol:

```shell
port 9000
```

Wireshark can only capture some specific ports that for HTTP package by default, so if you gonna capture HTTP package, make sure use the correct ports or goto settings to change the default ports. If you ignore this, like to capture HTTP on port 9000, you probably jut get TCP package.  

You can find the allowed HTTP port on `Preferences->Protocols->HTTP`

Learn more: [CaptureFilters - Wireshark](https://wiki.wireshark.org/CaptureFilters)

## 3. Display filter

Learn more: [DisplayFilters](https://wiki.wireshark.org/DisplayFilters)

## 4. Practical examples 

Client:

```go
func main() {
	// Three-way handshake included this step
	// Note that we're connecting to port 9000 on the server,
	// not use port 9000 to connect the server.
	conn, err := net.Dial("tcp", ":9000")
	if err != nil {
		log.Fatalf("couldn't connect to the server: %v", err)
	}
	buf := make([]byte, 15)
	// send data to server, the data will be copied into kernel space
	// and encapsulated into tcp segment -> ip packet -> ethernet frame
	if _, err := conn.Write([]byte("Hi, I am Coco\n")); err != nil {
		log.Fatalf("couldn't send request: %v", err)
	} else {
		// Read data from server, the data are copied from kernel space
		// what happens in kernel space (network stack):
		// ethernet frame -> ip packet -> tcp segment
		// the data will be forwarded to this program.
		// If the connection is closed, return error: io.EOF
		_, err = conn.Read(buf)
		if err != nil {
			log.Fatalf("couldn't read server response: %v", err)
		}
		fmt.Println(string(buf))
	}
	_ = conn.Close()
}
```

Server:

```go
func main() {
	// Obtain the port
	port := fmt.Sprintf(":%s", os.Args[1])
	// Create a tcp listener on the given port
	listener, err := net.Listen("tcp", port)
	if err != nil {
		fmt.Println("failed to create listener, err:", err)
		os.Exit(1)
	}
	fmt.Printf("listening on %s\n", listener.Addr())
	// listen for new connections
	for {
		// Three-way handshake included
		// this connection will be assigned a new port (different from the port this server is listening)
		// for sending and receiving data
		conn, err := listener.Accept()
		if err != nil {
			fmt.Println("failed to accept connection, err:", err)
			continue
		}
		// Pass an accepted connection to a handler goroutine
		go handleConnection(conn)
	}
}

func handleConnection(conn net.Conn) {
	defer conn.Close()
	buf := make([]byte, 15)
	for {
		// read client request data, same as client side
		// if the connection is closed, return error: io.EOF
		_, err := conn.Read(buf)
		if err != nil {
			if err != io.EOF {
				log.Println("failed to read data, err:", err)
			}
			fmt.Println("connection closed by client:", conn.RemoteAddr())
			return
		}
		fmt.Printf("request: %s", buf)
		line := fmt.Sprintf("%s", buf)
		// Same as on client side
		_, _ = conn.Write([]byte(line))
	}
}
```

Run server and client:

```shell
# server
$ go run main.go 9000
# client
$ go run main.go
```

Wireshark:

![a](/001-wireshark/a.png)

The first three is the three-way handshake packet, 

```
[SYN] seq=0 len=0
[SYN] seq=0 ack=1 len=0
[SYN] seq=1 ack=1 len=0
```

Note that the length of the fifth packet:

```shell
# ACK sent with data
[PSH, ACK] ... len=14
```

![b](/001-wireshark/b.png)

`len` is the data's length, the first there packets are just three-way handshake there is no data sent, so `len=0`.

The last four packets are TCP termination four-way hand-shake:

```shell
# ACK sent with FIN, this ACK is used to 
# ack=16 confirms that client has received the 15 byte sent by server 
# and client expects seq=16 from server
[FIN, ACK] seq=15 ack=16 len=0
[ACK] seq=16 ack=16
```

> The TCP `ACK` flag is used to confirm the last received byte by receiver.
>
> The `PSH` flag, on the other hand, is used to tell the server to push data to the application layer immediately. 

