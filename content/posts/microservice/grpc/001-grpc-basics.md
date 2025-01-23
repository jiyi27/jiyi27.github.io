---
title: Intro to gRPC 
date: 2023-11-05 16:01:06
categories:
 - grpc
tags:
 - grpc
---

## 1. Differences between gRPC and REST APIs

1. gRPC utilizes `HTTP/2` whereas REST utilizes `HTTP 1.1`
2. gRPC utilizes the *protocol buffer data format* as opposed to the standard *JSON data format* that is typically used within REST APIs
3. With gRPC you can utilize `HTTP/2` capabilities such as server-side streaming, client-side streaming or even bidirectional-streaming should you wish.

Source: [Go gRPC Beginners Tutorial | TutorialEdge.net](https://tutorialedge.net/golang/go-grpc-beginners-tutorial/)

## 2. Helloworld 

### 2.1. Intsall protoc and plugins

[Ptotocol Buffers - David's Blog](https://davidzhu.xyz/post/golang/grpc/002-proto-buffer/)

### 2.2. Install gRPC in your project

```
❯ go get -u google.golang.org/grpc 
```

### 2.3. HelloWorld example

[Go gRPC Beginners Tutorial | TutorialEdge.net](https://tutorialedge.net/golang/go-grpc-beginners-tutorial/)




