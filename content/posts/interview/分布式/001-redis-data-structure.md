---
title: Redis 五种数据类型
date: 2025-02-21 11:28:58
categories:
 - 面试
tags:
 - 面试
 - 缓存面试
 - 分布式面试
---

## 1. Redis  仅仅是缓存吗

Redis 最广为人知的用途是**缓存**, 它通过内存存储提供超高的读写性能, 常用于减轻数据库压力:

- 缓存热点数据
- 会话存储
- 页面缓存

但 Redis 的功能远不止缓存：

- 数据结构存储：支持字符串、列表、集合、哈希等，类似一个内存数据库
- 消息队列：通过 Pub/Sub 或 List 实现轻量级消息传递
- 分布式锁：在分布式系统中用于同步
- 高可用与分布式：通过主从复制、哨兵模式、集群模式支持分布式架构

## 2. String

### 2.1. 常见操作

```
SET user:001 "Alice"
SET user:001 '{"name": "Alice", "age": 25}'
SET counter 10
```

`user:001` 和 `counter` 是 Key, 后面的 字符串 `"Alice"`, `{"name": "Alice", "age": 25}`, 还有数字 `10` 是 Value, Redis 中的 String 有点像哈希表, 但不是

```shell
GET user:001 # 获取 key user:001 值
INCR counter # 自增1
DECR counter # 自减1
INCRBY counter 5 # 自增5
```

> 虽然 Redis 是用 C 语言写的, 但是 Redis 并没有使用 C 的字符串表示, 而是自己构建了一种 **简单动态字符串**（Simple Dynamic String）相比于 C 的原生字符串, Redis 的 SDS 不光可以保存文本数据还可以保存二进制数据, 并且获取字符串长度复杂度为 O(1)（C 字符串为 O(N)）, 除此之外, Redis 的 SDS API 是安全的, 不会造成**缓冲区溢出**:
>
> **Buffer Overflow** 是一种常见的程序错误, 通常发生在程序试图向一个固定大小的内存缓冲区写入超出其容量的数据时导致的数据覆盖相邻内存，导致程序行为异常或崩溃, 在 C 语言中，字符串操作尤其容易引发缓冲区溢出, 因为 C 的原生字符串（以空字符 `\0` 结尾的字符数组）不自带长度信息, 操作时需要程序员手动确保不会越界


### 2.2. 一些拓展

String 是一种二进制安全的数据类型, 可以用来存储任何类型的数据比如字符串、数字、序列化后的对象（如 JSON、Protobuf 等）

> 严格来说, String 本身并不直接存储“类型”, 而是存储数据的字节表示, 在编程中, “类型”（data type）指的是数据的种类以及与之相关的操作规则, 每种“类型”都有自己的**语义**（含义）和**操作方式**, 这些是由编程语言或程序逻辑定义的, 当我们说 String 存储数据时, String 本身并不知道或关心数据的“类型”, 它只是一个**字节序列**（byte sequence）的容器, 换句话说, String 存储的是数据的**二进制表示**, 而不是数据的高级语义或类型信息:
>
> - **字节表示**：任何数据（无论是整数、浮点数、文本、图片还是对象）在计算机底层都是以二进制形式（0 和 1 的序列）存储的, 这些二进制数据可以看作一串字节（每个字节是 8 位）
> - **String 的角色**：在二进制安全的 String 实现中（例如 Redis 或 PHP 的字符串）, String 只是把这些字节原封不动地保存下来, 它不关心这些字节是表示一个整数、一个图片，还是一个序列化后的对象
>
> 举个例子:
>
> - 整数 42 的二进制表示可能是 00101010（取决于编码方式，比如 32 位整数）
> - 文本 "hello" 的 UTF-8 编码可能是字节序列 01101000 01100101 01101100 01101100 01101111
> - 一个序列化后的 JSON 对象 `{"name": "Alice"}` 也是一串字节，可能看起来像 7b226e616d65223a2022416c696365227d（十六进制表示）
>
> 当你把这些数据存进 Redis String 时, String 只负责保存这些字节的顺序和内容,, 它不会记录“这是个整数”或“这是个 JSON 对象”这样的类型信息, Redis String 作为二进制安全的数据类型, 负责存储数据, 但数据的**语义**（如整数、浮点数、对象）需要由程序逻辑解析, 例如, 一个序列化后的 JSON 对象存储在 String 中, 程序需要调用 JSON 解析器来还原对象

> 在某些编程语言或系统中（例如 Redis、PHP等），String 被称为**二进制安全**（binary-safe）的数据类型，意思是它可以安全地存储和处理任意的二进制数据，而不会因为数据中包含特定的字符（如空字符 `\0`）或其他控制字符而导致数据被截断或错误解析, 并非所有语言或系统的 String 都是二进制安全的, 例如:
>
> - 在 C 中，字符串通常不是二进制安全的（因为以 `\0` 结尾）
> - 在 Java 中, String 是基于 Unicode 的, 主要用于文本, 处理二进制数据更常用 `byte[]`

## 3. Set

Set 只能存储字符串, 且字符串不能重复:

```
["123", "456", "Jack", "Alice", ...]
```

> 注意 Redis String 是一个数据结构, 不是一个值的类型, Redis 中 Set 只能用来存储 String 类型的值, 这里的 String 指的只是单纯的字符串, 而不是前面的数据结构

## 4. List

Redis 中的 List 其实就是链表数据结构的实现, 很多语言都内置了链表的实现, 但是 C 语言并没有实现链表, 因此 Redis 实现了自己的链表, Redis 的 List 的实现是一个 双向链表, 

`List` 可以用来做消息队列, 只是功能过于简单且存在很多缺陷, 不建议这样做, 相对来说, Redis 5.0 新增加的一个数据结构 `Stream` 更适合做消息队列一些, 只是功能依然非常简陋, 和专业的消息队列相比, 还是有很多欠缺的地方比如消息丢失和堆积问题不好解决

## 5. Hash

大部分编程语言都提供了 哈希（`hash`）类型, 它们的叫法可能是 哈希、字典, 在 `Redis` 中, 哈希类型 是指键值本身又是一个 键值对结构:

```bash
HMSET user:1001 name "Alice" age 25 city "Beijing"
```

- 这里 user:1001 是 Redis 的键（key）
- 这个键对应的值是一个哈希，包含多个键值对：name: "Alice"，age: 25，city: "Beijing"
- 在这个哈希里，name、age、city 是 field，"Alice"、25、Beijing 是对应的值

类似下面这种:

```
key: user:1001
value: { name: "Alice", age: 25, city: "Beijing" }
```

你可以用命令单独访问某个 field 的值，比如:

```
HGET user:1001 name
```

可以看出 Redis 中的 哈希表 和 普通键值对不同:

```
key: username
value: "Alice"
```

Redis 是一个高效的键值数据库, 为了保证性能和一致性, 它要求所有存储的数据在底层都以字符串的形式保存, 因此:

- **Field**：哈希的字段（比如上面的 name、age、city）必须是字符串类型

- **Value**：每个字段对应的值（比如 "Alice"、25、Beijing）也必须是字符串

```
HMSET user:1001 friends ["Bob", "Charlie"]  # 错误！
```

那如果我们想存用户的信息, 而用户又存在这样的数组字段, 应该怎么办呢?

答案是把整个用户信息（比如 name、age、city、friends 等）**序列化**为一个 JSON 字符串, 直接存到 Redis 的 String 类型的一个键里, 每次读写时, 客户端负责解析和序列化 JSON

```json
{
  "name": "Alice",
  "age": 25,
  "city": "Beijing",
  "friends": ["Bob", "Charlie"]
}
```

用 Redis 哈希存储：

```python
# 用 SET 命令存储 JSON 字符串
SET user:1001 "{\"name\":\"Alice\",\"age\":25,\"city\":\"Beijing\",\"friends\":[\"Bob\",\"Charlie\"]}"

# 获取 JSON 字符串
GET user:1001
# 返回: "{\"name\":\"Alice\",\"age\":25,\"city\":\"Beijing\",\"friends\":[\"Bob\",\"Charlie\"]}"
```

```python
import json
json_str = redis_client.get("user:1001")
user_info = json.loads(json_str)  # 转为字典
# user_info = {"name": "Alice", "age": 25, "city": "Beijing", "friends": ["Bob", "Charlie"]}

# 要更新某个字段（比如加朋友或改 city），需要, 读取整个 JSON, 在客户端修改, 序列化后写回
# 添加新朋友
user_info["friends"].append("Alice")
redis_client.set("user:1001", json.dumps(user_info))
# 或者改城市
user_info["city"] = "Shanghai"
redis_client.set("user:1001", json.dumps(user_info))
```

虽然这种方式直接存整个 JSON 对象, 看着很容易理解, 但缺点也很明显**更新效率低**：每次修改（即使只改 name 或加一个朋友）, 都要：

1. 读整个 JSON（GET）
2. 客户端解析
3. 修改后序列化
4. 写回整个 JSON（SET）

这对频繁更新的场景效率较低, 那有没有更好的办法?

用 Redis 哈希存储基本信息（name、age、city 等）作为单独的字段, 把复杂结构（比如 friends 列表）序列化为 JSON 字符串存到一个字段, 这样结合了哈希的结构化和 JSON 的灵活性:

```
# 存储用户信息
HMSET user:1001 name "Alice" age "25" city "Beijing" friends "[\"Bob\", \"Charlie\"]"

# 获取所有字段
HGETALL user:1001
# 返回: {"name": "Alice", "age": "25", "city": "Beijing", "friends": "[\"Bob\", \"Charlie\"]"}
```

```python
import json
user_info = redis_client.hgetall("user:1001")
friends = json.loads(user_info["friends"])  # 转为列表 ["Bob", "Charlie"]

# 更新基本信息, 直接修改某个字段
HSET user:1001 city "Shanghai"

# 更新朋友列表
# 客户端先读取，修改，再写回
friends.append("Alice")
redis_client.hset("user:1001", "friends", json.dumps(friends))
```

- 基本字段（name、city）可直接修改，效率高
- friends 列表用 JSON 存储，灵活支持列表或其他复杂结构
- 所有信息在一个键（user:1001）下
