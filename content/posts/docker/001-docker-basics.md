---
title: Docker Basics
date: 2023-10-09 21:09:35
categories:
 - docker
tags:
 - docker
 - golang
---

## 1. Dockerfile example

```dockerfile
FROM golang:alpine

WORKDIR /app
COPY ./ ./
RUN go mod download
RUN go build -o server

ENTRYPOINT ["./server"]
CMD ["-p", "80"]

# docker build [--platform linux/amd64] -t shwezhu/file-server:v1.0 .
# [docker push shwezhu/file-server:v1.0]
# [docker pull davidzhu/file-server:v1.0]
# sudo docker run -d -p 80:80 --rm shwezhu/file-server:v1.0
```

## 2. Docker commands

```shell
#-------------- build and delete image --------------
$ docker build -t davidzhu/go-learning:v1.0 .
$ docker rmi shwezhu/file-station:v1	# if docker is in-use, delete with -f
$ docker rm container_id

# docker run 用于创建一个新的容器并在其中运行一个命令
# specify the container name, if not specified, generate a name for running contianer
$ docker run --name mysql-volume ...
# --rm automatically removes the container when it exits,
# -d: Run container in background
$ docker run -d -p 80:80 --rm file-server

# docker exec 用于在已经运行的容器中执行命令
# run a contianer, 'file-server' is the container name, not image
$ docker exec -it file-server bash # specify'bash' as the shell of container
$ docker exec -it file-server /bin/sh # specify '/bin/sh' as the shell of container

# publish and pull image from repo
$ docker push shwezhu/file-station:v1
$ docker pull davidzhu/file-station:v1

#-------------------- show info ------------------------
$ docker container ls -a
$ docker image ls -a
# check the output of the program running in the container
$ docker logs container_name

# volumes, mount the folder on the machine '~/root' to the '/app/root' dir of the container
$ docker run --name file-server --rm -d -p 80:80 -v ~/root:/app/root shwezhu/file-server:v1.0 ./server -p 80 
```

## 3. Build image

The `docker build` command is used to build a Docker image from a Dockerfile and a "context". 

During the build, those files (build context) are sent to the Docker **daemon** so that the **image** can use them as files. The **build context** is usually at the current folder.  

```shell
# -t image_name:tag_name
# . specifies the build context as the current directory
$ docker build -t go-learning:1 . 
```

> Learn more: [Multi-stage builds | Docker Docs](https://docs.docker.com/build/building/multi-stage/)

## 4. `.dockerignore` File

During the build, those files (build context) are sent to the Docker **daemon** so that the **image** can use them as files. 

When you build a Docker image, Docker takes all the files and directories in the build context and sends them to the Docker daemon, which then processes and includes them in the image. By using a `.dockerignore` file, you can specify patterns of files and directories that should be ignored during the build process. 

By excluding unnecessary files and directories, you can significantly **reduce the size of the Docker image**. This is particularly important when building images for production environments or when transferring images across networks.

## 5. Image vs container

**A container is an isolated place** where an application runs without affecting the rest of the system and without the system impacting the application. Because they are isolated, containers are well-suited for securely running software like databases or web applications that need access to sensitive resources without giving access to every user on the system. However, containers can be much more efficient than virtual machines because they don’t need the overhead of an entire operating system. They share a single kernel with other containers and boot in seconds instead of minutes.

**Images are read-only templates** containing instructions for creating a container. A Docker image creates containers to run on the Docker platform. Docker images are immutable, so you cannot change them once they are created. If you need to change something, create another container with your changes, then save those as another image. Or, just run your new container using an existing image as a base and change that one. 

An image is composed of multiple stacked layers, like layers in a photo editor, each changing something in the environment. Images contain the code or binary, runtimes, dependencies, and other filesystem objects to run an application. The image relies on the host operating system (OS) kernel. For example, to build a web server image, start with an image that includes Ubuntu Linux (a base OS). Then, add packages like Apache and PHP on top. 

**Think of a Docker container as a running image instance**. You can create many containers from the same image, each with its own unique data and state. Although images are not the only way to create containers, they are a common method.

Source: [Docker image vs container: What are the differences? | CircleCI](https://circleci.com/blog/docker-image-vs-container/)

## 6. Image with cross platform

Docker images are typically built for a specific CPU architecture, such as x86-64 (64-bit Intel/AMD processors). By default, Docker images are built for the architecture of the system where the image is built. However, it is possible to build and run Docker images for different architectures using a technique called multi-architecture or cross-platform support.

**Docker images can support multiple platforms**, which means that a single image may contain variants for different architectures, and sometimes for different operating systems, such as Windows. When you run an image with multi-platform support, Docker automatically selects the image that matches your OS and architecture. 

Most of the Docker Official Images on Docker Hub provide a [variety of architecturesopen_in_new](https://github.com/docker-library/official-images#architectures-other-than-amd64). For example, the `busybox` image supports `amd64`, `arm32v5`, `arm32v6`, `arm32v7`, `arm64v8`, `i386`, `ppc64le`, and `s390x`. When running this image on an `x86_64` / `amd64` machine, the `amd64` variant is pulled and run.

Learn more: [Multi-platform images | Docker Docs](https://docs.docker.com/build/building/multi-platform/)
