---
title: Docker Architecture
date: 2023-10-11 10:38:35
categories:
 - docker
tags:
 - docker
typora-root-url: ../../../static
---

##  1. Docker architecture

Docker uses a client-server architecture. The **Docker client** talks to the **Docker daemon**, which does the heavy lifting of building, running, and distributing your **Docker containers**. The Docker client and daemon can run on the same system, or you can connect a Docker client to a remote Docker daemon. The Docker client and daemon communicate using a REST API, over UNIX sockets or a network interface. 

<img src="/002-docker-architecture/a.png" alt="a" style="zoom:50%;" />

Learn more about the Cocker client(`docker`), Docker daemon(`dockerd`) and Docker objects (images, containers): https://docs.docker.com/get-started/overview/

## 2. Docker build architecture

Docker Build implements a client-server architecture, where:

- Buildx is the client and the user interface for running and managing builds
- BuildKit is the server, or builder, that handles the build execution.

![b](/002-docker-architecture/b.png)

As of Docker Engine 23.0 and Docker Desktop 4.19, Buildx is the default build client.

In newer versions of Docker Desktop and Docker Engine, you're using Buildx by default when you invoke the `docker build` command. In earlier versions, to build using Buildx you would use the `docker buildx build` command.

Sourcce: [Docker Build architecture | Docker Docs](https://docs.docker.com/build/architecture)

Learn more: [Builders | Docker Docs](https://docs.docker.com/build/builders/)