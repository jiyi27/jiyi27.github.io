---
title: Useful Redis Commands
date: 2023-09-30 16:40:58
categories:
 - database
tags:
 - database
 - redis
---

## 1. Install & run redis server

Install:

```shell
$ brew install redis
```

Run Redis in the foreground:

```shell
$ redis-server
```

As an alternative to running Redis in the foreground, you can also start the process in the background:

```shell
$ brew services start redis

$ brew services stop redis
```

## 2. Connect to redis server

Once Redis is running, you can connect it by running *Redis Command Line Interface* - `redis-cli`:

```shell
# run a client at terminal to connect Redis server
$ redis-cli
```

By default, `redis-cli` connects to the server at the address 127.0.0.1 with port 6379. To specify a different host name or an IP address:

```shell
$ redis-cli -h redis15.localnet.org -p 6390
```

By default, `redis-cli` uses a plain TCP connection to connect to Redis. You may enable SSL/TLS using the `--tls` option, along with `--cacert` or `--cacertdir` to configure a trusted root certificate bundle or directory.

If the target server requires authentication using a client side certificate, you can specify a certificate and a corresponding private key using `--cert` and `--key`.

### 3. `redis-cli MONITOR`

All commands received by the active Redis instance will be printed to the standard output:

```shell
$ redis-cli MONITOR
OK
1692367745.525689 [0 127.0.0.1:49963] "set" "name" "jack"
1692368601.032173 [0 127.0.0.1:49963] "set" "name" "john"
1692368645.284030 [0 127.0.0.1:49963] "get" "name"
```

This means you will get all the commands that your redis server received from clients, recall that `redis-cli` will connects to the server at the address 127.0.0.1 with port 6379. 

And if your application `C1` use a Redis server `S` to save data, your another application `C2` that connects to server `S` can get that data too. When you run `redis-cli`, it start a client, and you can input `keys *` to query all key saved on your Redis server. 

Of course using Redis just from the command line interface(*`redis-cli`*) is not enough as the goal is to use it from your application. In order to do so you need to download and install a Redis client library for your programming language. You'll find a [full list of clients for different languages in this page](https://redis.io/clients).
