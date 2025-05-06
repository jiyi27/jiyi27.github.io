---
title: Kafka 链接失败 - 8080 被占用
date: 2025-02-22 11:12:22
categories:
 - bugs
tags:
 - bugs
 - kafka
---

Spring Boot 应用在尝试连接 Kafka 时，不断抛出连接错误，提示无法连接到 localhost:127.0.0.1:9092 的 Kafka 节点:

```
[Consumer clientId=consumer-like-group-1, groupId=like-group] Connection to node -1 (localhost/127.0.0.1:9092) could not be established. Node may not be available.
```

检查 Kafka `/opt/homebrew/etc/kafka/server.properties` 配置:

```
broker.id=0
```

只有这一行, 然后添加:

```
broker.id=0
listeners=PLAINTEXT://0.0.0.0:9092
advertised.listeners=PLAINTEXT://localhost:9092
```

成功解决问题, 

在 Kafka 中，listeners 与 advertised.listeners 这两个配置项常常是“能否连通”的关键。简单来说：

- listeners：定义 Kafka Broker 实际监听的地址和端口, 告诉 Kafka Broker 监听在哪个接口上接收请求
- advertised.listeners：Kafka “向外宣传”自己的地址，告诉客户端要用哪个 IP/域名 + 端口来连

他们两个什么区别, 为什么都要单独设置, 而不是设置一个相同的值?

```
listeners=PLAINTEXT://0.0.0.0:9092
```

`0.0.0.0` 表示监听所有网络接口，意味着 Kafka 允许来自任何 IP 地址的连接, 这样做的好处是，它允许本地机器和远程机器都可以连接到这个 Broker, 

如果你希望 Kafka 被远程访问，比如生产者和消费者运行在不同的机器上，你应该设置 `advertised.listeners` 为你的主机名或外部 IP：

```
listeners=PLAINTEXT://0.0.0.0:9092
advertised.listeners=PLAINTEXT://your-public-ip:9092
```

- `listeners=0.0.0.0:9092` 允许 Kafka 在所有网络接口上监听连接

- `advertised.listeners=your-public-ip:9092` 确保客户端能够正确地连接到 Kafka

上面说的是服务端, 当客户端启动时(Spring Boot 代码)，会用 `bootstrap.servers` 提供的地址列表来**初次连接** Kafka 集群。这个配置仅用于入口，帮助客户端找到集群中任意一个 broker，从而获取集群的元数据（例如 topic 信息、分区信息以及其它 broker 的地址）。配置内容可以是一台或多台 broker 的地址。通常，在单机开发环境中你可以设置为 `localhost:9092`，但在生产环境中，为了容错，通常会配置多个 broker 的地址。

```java
public ConsumerFactory<String, String> consumerFactory() {
    // 配置 Kafka 消费者
    Map<String, Object> configs = new HashMap<>();
    // 这些地址就是 broker 的公共 IP
    configs.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, "broker1:9092,broker2:9092,broker3:9092");
    ...
    return new DefaultKafkaConsumerFactory<>(configs);
}
```

-----

运行程序, 发现 8080 端口被占用, 查看谁占用的, 然后关闭, 结果 8080 仍然被占用, 很奇怪, 输出如下:

```shell
# david @ Davids-Mac-mini in ~ [22:40:51]
$ lsof -i :8080
COMMAND   PID  USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
java    85160 david   54u  IPv6 0xb9edb27e9f8be53e      0t0  TCP *:http-alt (LISTEN)

# david @ Davids-Mac-mini in ~ [22:40:58]
$ kill 85160

# david @ Davids-Mac-mini in ~ [22:41:09]
$ lsof -i :8080
COMMAND   PID  USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
java    85345 david   54u  IPv6 0x84534af2d36abf6d      0t0  TCP *:http-alt (LISTEN)
```

查看谁运行的 找出所有 Java 进程:

```shell
$ ps aux | grep java
```

发现一堆输出, 查了一下是 zookeeper 相关的东西, 

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2025/02/8d06ca0c59cc392b20d402e9a3e0e563.png)

`/opt/homebrew/opt/openjdk/bin/java -Dzookeeper.log.dir=...`：进程执行的完整命令，说明这是一个 Java 进程，并且和 **Zookeeper** 相关, 

关闭 zookeeper 服务:

```
$ brew services stop zookeeper
```

成功解决问题

> 因为通过 Homebrew 方式安装的 Zookeeper 默认会开启一个内置的 AdminServer（Zookeeper 3.5+ 版本开始就有这个特性），该服务的默认端口是 8080。当你 kill 了对应的 Java 进程后，brew services 还在负责“托管”并自动重启 Zookeeper 服务，所以很快就会有新的进程继续监听 8080 端口。

