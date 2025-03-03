---
title: 通过交叉编译理解 Docker 运行原理
date: 2025-02-26 18:31:22
categories:
 - docker
tags:
 - docker
 - 交叉编译
---

假设我们在 M1 的 Mac 上构建 Docker 镜像:

```dockerfile
FROM golang:alpine

WORKDIR /app
COPY ./ ./
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /server .

CMD ["./server"]
```

## 1. `docker build` 阶段

### 1.1 拉取基础镜像 `golang:alpine`

- 在 **M1 Mac (arm64)** 上执行 `docker build -t myserver .`

- Docker 引擎会看到 `FROM golang:alpine` 并去 Docker Hub 拉取对应的镜像

- **关键点**：`golang:alpine` 是一个多架构（multi-arch）镜像名，里面包含了 `amd64`、`arm64` 等不同架构的版本

- Docker 会自动检测到宿主机是 arm64, 于是它会拉取并使用 arm64 版的 `golang:alpine`, 这样, 构建时运行的容器基础环境就是 **arm64** 的 Alpine + Go

### 1.2 在容器（arm64）里执行构建步骤

进入到 `WORKDIR /app` 后，`COPY` 源码、`RUN go mod download` 都是在 **arm64** 架构的 Alpine 容器里进行的，没什么特别

### 1.3 编译 golang 源代码

现在最有意思的是这一行 `CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /server .`

- GOOS=linux：目标操作系统是 Linux（容器实际就是 Linux，但这里做了“明确指定”）
- GOARCH=amd64：目标 CPU 架构是 x86_64（amd64）
- 容器自身是 arm64 的 Go 工具链，但是 Go 提供了「交叉编译」能力，所以它可以编译出一个「amd64」二进制
- 因此此步骤结束后，容器中 `./server` 这个可执行文件将是**amd64 架构**的 Linux ELF

### 1.4. 结果

- 生成的二进制是「amd64」的

- 但它坐落在一个「arm64」用户态系统（Alpine）里
- 如果你在这个容器里尝试 `./server` 立即运行，很可能会报错：

> “exec format error” (因为是 amd64 指令集，无法在 arm64 CPU 上原生执行)。

然而在 `docker build` 阶段，Docker 不会去实际“运行”这个二进制（除了 CMD/ENTRYPOINT 之外），它只是把文件打包进镜像。

### 1.5 构建生成的镜像

`docker build` 成功后，会产出一个新的镜像，里头包含：

- 基础镜像那一套 arm64 的 Alpine Linux
- 以及我们刚刚编译好的 **amd64** 可执行文件 `/server`

这就导致了镜像本身是“arm64 用户态系统 + amd64 二进制”的“混搭”状态。

## 2. `docker run` 阶段

当你在 M1 Mac 上执行 `docker run myserver` 时，Docker 会尝试：

1. 启动一个容器，它的用户态依旧是「arm64 Alpine」
2. 在启动时，会执行 `CMD ["./server"]`（即 `/server`），这是一个 **amd64** 的二进制

此时，如果没有任何额外的配置，容器内会试图在 arm64 环境中直接跑 amd64 的 ELF 文件，通常会出现：

```
standard_init_linux.go:xxx: exec user process caused: exec format error
```

**为什么？** 因为 arm64 CPU 无法直接执行 amd64 指令集的二进制。

## 3. 在 Ubuntu + amd64 CPU 上

### 3.1. docker pull

假设 `yourrepo/myserver:latest` 是一个「多架构 manifest」镜像，包含了 **arm64** 和 **amd64** 两个版本

```
docker pull yourrepo/myserver:latest
```

当 Ubuntu（amd64）端尝试拉取时，Docker 会先匹配你本地主机是 `amd64`，接着去仓库搜 `myserver` 镜像是否包含 `linux/amd64` 的 manifest, 

最终下载下来的实际上是**amd64** 的用户态环境（如果用的是 Alpine，则它里面的 `/bin/sh`、`/usr/bin/go` 等都是 amd64 编译的）, 

与在 M1 Mac 上「自动拿到 arm64 版」是同样的机制，只是目标架构不同, 

> Docker Hub 上的很多官方镜像（例如 `golang:alpine`）是做了多架构支持的：它们在同一个镜像名后面，通过一个多架构 manifest，指向了多个真正的镜像文件（比如 amd64 版、arm64 版等）
>
> 当你 `docker pull` 时，Docker 会根据你当前的宿主机架构，去拉取并解压相匹配的镜像层（layer）。这就是为什么“同一个名称”的镜像，能自动匹配不同架构

### 3.2. 运行容器 docker run

执行 `CMD ["./server"]`

因为容器是「amd64 Alpine」, 里面的 `/server` 也是 amd64 二进制, CPU 指令集、用户态环境全部匹配，`./server` 可以直接原生执行, 不会出现在 M1 Mac 场景下的“exec format error”问题。

> 我们拉取的镜像已经是一个微型系统了, 而且包含了我们在 M1 系统编译好的 server amd64 架构的可执行文件,  执行 docker run 的时候, 只会执行: `CMD ["./server"]`, 上面的指令比如 `FROM`、`WORKDIR`、`COPY`、`RUN go mod download` 都是在**构建阶段 (`docker build`)** 执行的, 用来生产最终镜像。