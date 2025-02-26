---
title: CGO Compile Error Building Docker Image
date: 2023-10-21 10:24:22
categories:
 - bugs
tags:
 - bugs
 - docker
 - 交叉编译
---


I choose a sqilte3 library which uses cgo, the Dockerfile:

```dockerfile
FROM golang:alpine

WORKDIR /app
COPY ./ ./
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /server .

CMD ["./server"]
```

> 在使用 docker 运行 golang 相关的程序的时候, 我们需要先选择基础镜像, 比如: `FROM golang:alpine`, 编译 golang 源码的时候, 需要指定构建的目的系统和CPU架构, 比如: `GOOS=linux`, 此时 选择 GOOS=linux 是因为我们选择基础镜像是 `golang:alpine` 是 Linux 系统, 而 `GOARCH=amd64` 是因为宿主机 CPU 架构是 amd64, 容器里的程序只能跑在与宿主机 CPU 架构兼容的环境上, 
>
> When cgo is enabled, the binary may link dynamically to C libraries, which can add dependencies on system-specific libraries. Disabling cgo (by setting `CGO_ENABLED=0`) helps produce a more self-contained binary, making cross-platform deployment easier.
>
> Learn more: 
>
> [Static Linking Go Programs - David's Blog](https://davidzhu.xyz/post/golang/advance/012-statically-linking/)
>
> [Cross Compilation - Go - David's Blog](https://davidzhu.xyz/post/golang/advance/011-cross-compilation/)

After build successfully and run image:

```shell
$ docker run -p 80:80 shwezhu/file-station:v1
2023/10/10 02:15:15 /app/main.go:12
[error] failed to initialize database, got error Binary was compiled with 'CGO_ENABLED=0', go-sqlite3 requires cgo to work. This is a stub
```

As you can see, apparently I will get an error, because my Go code use the `go-sqlite3 ` package which implemented by pure cgo, if I disable cgo with `CGO_ENABLED=0`, this will wrong. Then I change the dockerfile to:

```dockerfile
...
# Install gcc to compile cgo
RUN apk add --no-cache --update go gcc g++
RUN go build -o /server .

CMD ["./server"]
```

And build image with command:

```shell
$ docker build -t shwezhu/file-station:v2 .
```

There is an error when run the image on EC2 server:

```shell
$ docker run -p 80:80 shwezhu/file-station:v1
WARNING: The requested image's platform (linux/arm64) does not match the detected host platform (linux/amd64) and no specific platform was requested
```

Because my local machine is arm64, which means the image will be built to arm64 by default, but my EC2 server is linux/amd64, so there is an error occurred. With `--platform`, you can specify the platform this image built for:

```shell
$ docker build --platform linux/amd64 -t shwezhu/file-station:v2 .
```

*Go* is a statically *compiled* language. To execute a *Go* binary on a machine, it must be *compiled* for the matching operating system and processor architecture. So there is cross-compilation in Go. `--platform` is used to build [multi-platform docker images](https://docs.docker.com/build/building/multi-platform/), not build Go for another platform. You should know the difference between these concepts. 

