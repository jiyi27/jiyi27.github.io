---
title: Kafka 基础概念
date: 2025-02-22 16:10:27
categories:
 - 分布式
tags:
 - 分布式
 - 面试
 - Kafka
---

## 1. 几个重要概念

Kafka 几个常见概念: Producer, Consumer, Topic, Partition, Broker:

- 在 Kafka 中, 集群里的每一台服务器都被称为 **Broker**, 负责接收生产者发送的消息并存储这些消息

- Topic 是 Kafka 中消息的逻辑分组, 生产者按照消息所属 Topic 将消息发送到 Broker, 消费者从  Broker 中读取消息
- 每个 Topic 可以分成多个分区, 然后不同的分区可能会存储在不同的 Broker 上, 例如: `user-clicks` Topic 有 3 个分区, 可能分布在 2 个 Broker 上，Broker 1 存分区 0 和 1，Broker 2 存分区 2

> 注意 Broker 本身并不主动“分发”消息, 只负责存储消息并等待消费者主动拉取

分区（Partition）

- 每个 Topic 被分成多个分区，分区是 Kafka 数据的基本存储单位
- 例如，一个 Topic user-clicks 有 3 个分区：Partition 0、Partition 1、Partition 2

副本（Replica）

- 每个分区可以有多个副本（由复制因子 replication-factor 决定），这些副本分布在不同的 Broker 上

- 例如，replication-factor=2 表示每个分区有 2 个副本：一个主副本（Leader Replica）和一个从副本（Follower Replica）

> 在 Kafka 集群里，不是一台 Broker 扛所有活，而是多台 Broker 一起上。数据先按照 Topic 分类，每个 Topic 又被拆分成多个分区，这些分区会均匀分布到不同的 Broker 上。这样，生产者在写入数据、消费者在读取数据时，相关请求会自动分散到各个 Broker，从而实现负载均衡和高吞吐量。



