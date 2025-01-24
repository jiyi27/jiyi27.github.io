---
title: Dockerfile Synatax
date: 2023-10-11 12:27:35
categories:
 - docker
tags:
 - docker
---

## 1. WORKDIR

```dockerfile
WORKDIR /path/to/workdir
```

The `WORKDIR` instruction sets the working directory for any `RUN`, `CMD`, `ENTRYPOINT`, `COPY` and `ADD` instructions that follow it in the `Dockerfile`. If the `WORKDIR` doesn't exist, it will be created even if it's not used in any subsequent `Dockerfile` instruction.

The `WORKDIR` instruction can be used multiple times in a `Dockerfile`. If a relative path is provided, it will be relative to the path of the previous `WORKDIR` instruction. For example:

```dockerfile
WORKDIR /a
WORKDIR b
RUN pwd
```

The output of the final `pwd` command in this `Dockerfile` would be `/a/b`.

If not specified, the default working directory is `/`. In practice, if you aren't building a Dockerfile from scratch (`FROM scratch`), the `WORKDIR` may likely be set by the base image you're using.

Therefore, **to avoid unintended operations in unknown directories, it is best practice to set your `WORKDIR` explicitly.**

## 2. COPY

We usually the following code in `Dockerfile`:

```dockerfile
...
WORKDIR /app
COPY ./test ./
```

The `COPY ./test ./` will be executed when building the image, what `COPY ./test ./` does is **copy** all the files under `./test` on your computer into the `/app` folder of the container. Because `./` means current folder, and we set  our current folder to `/app` by using `WORKDIR /app` in `Dockerfile`. 

> Note that  `.dockerignore` file is not considered here, if you add `.dockerignore` file, then before execute `COPY ./test ./`,  docker will check the `.dockerignore` file first, if the file in the `./test` folder machs the file list in `.dockerignore` file, then `COPY ./test ./` will skip that file. 

And note that the build command `docker build -t docker-learning:v1 .`, the last `.` sign is used to specify the context, in `COPY ./test ./`, the `./test` is the `test` folder under the context. 

## 3. RUN vs CMD vs ENTRYPOINT

### 3.1. Example

*ENTRYPOINT* sets the process to run, while ***CMD* supplies default arguments to that process**.

```dockerfile
WORKDIR /app
COPY ./ ./
RUN go mod download
RUN go build -o server

ENTRYPOINT ["./server"]
CMD ["-p", "80"]
```

When run image:

```shell
docker run -p 80:80 --rm file-server:v1.0
```

The command `./server -p 80` will run in the container. By the way, thr `CMD` could be overwritten by `docker run`:

```shell
...

ENTRYPOINT ["./server"]
CMD ["-p", "9000"]
```

When run image:

```shell
sudo docker run -p 8080:8080 --rm file-server:v1.0 -port 8080
```

The command `./server -port 8080` will run, not `./server -p 9000`

### 3.2. Concepts

- **`ENTRYPOINT`** is the process that’s executed inside the container.
  - Images can only have one `ENTRYPOINT`. If you repeat the Dockerfile instruction more than once, the last one will apply. When an image is created without an ENTRYPOINT, Docker defaults to using `/bin/sh -c`.
- **`CMD`** is the default set of arguments that are supplied to the ENTRYPOINT process.
  - There can only be one `CMD` instruction in a `Dockerfile`. If you list more than one `CMD` then only the last `CMD` will take effect.
  - `CMD` - command triggers while we launch the created docker image.
- **`RUN`** - command triggers while we build the docker image.

```dockerfile
ENTRYPOINT ["./server"]
CMD ["-p", "80"]
# same as: CMD ["./server", "-p", "80"]
```

## 4. `docker run` vs `ENTRYPOINT`

The [`docker run` command](https://docs.docker.com/engine/reference/commandline/run) starts a new container using a specified image. When no further arguments are given, the process that runs in the container will exactly match the ENTRYPOINT and CMD defined in the image.

```bash
# Executes /usr/bin/my-app help
$ docker run my-image:latest
```

Technically, it is possible to override the ENTRYPOINT using `docker run` by setting its `--entrypoint` flag. Although this is rarely required, the technique can be useful if you want to launch a shell inside a container, such as to inspect the contents of an image’s filesystem:

```bash
# Executes bash -c "ls /"
$ docker run --entrypoint bash my-image:latest -c "ls /"
```

Note that there is no `bash` under the `/bin` folder of  `alpine:latest` linux system which our container based on, there just two shells: `ash ` and `sh`. So the command above will get an error. 

```shell
docker: Error response from daemon: failed to create task for container: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: exec: "bash": executable file not found in $PATH: unknown.
```

You can try:

```shell
$ docker run --entrypoint /bin/sh docker-learning:v1 -c "cat /etc/shells"
# valid login shells
/bin/sh
/bin/ash
```

Or

```shell
$ docker run docker-learning:v1 cat /etc/shells  
# valid login shells
/bin/sh
/bin/ash
```

Both of these are same, because the default entrypoint is `/bin/sh -c`. 

Reference: 

- [Dockerfile reference | Docker Docs](https://docs.docker.com/engine/reference/builder/)
- [Docker ENTRYPOINT and CMD : Differences & Examples](https://spacelift.io/blog/docker-entrypoint-vs-cmd)







