---
title: Redis 数据结构
date: 2025-02-21 11:28:58
categories:
 - 数据库
tags:
 - 数据库
 - redis
---

## 1. String & Set

注意这里的 String 就是一个数据结构, 而不是一个值的类型, Redis 中 Set 只能用来存储 String 类型的值, 这里的 String 指的只是单纯的字符串, 而不是数据结构, 

### 1.1. String

```
SET user:001 "Alice"
SET user:001 '{"name": "Alice", "age": 25}'
SET counter 10
```

注意看上面的这些, 都是 String 数据结构, 其中 `user:001` 和 `counter` 是 Key, 后面的 字符串 "Alice", JSON 数据, 还有数字 是 Value,

可以看出, Redis 中的 String 有点像哈希表, 但不是, 因为它有一些更方便的操作, 比如:

```shell
GET user:001 # 获取 key user:001 值
INCR counter # 自增1
DECR counter # 自减1
INCRBY counter 5 # 自增5
```

### 1.2. Set

Set 只能存储字符串, 且字符串不能重复:

```
["123", "456", "Jack", "Alice", ...]
```

## 2. String 使用场景

### 2.1. 缓存热点数据

`SET user:1001:name "Shaowen Zhu" EX 3600` （存储用户名称，设置过期时间 1 小时）

`GET user:1001:name`（获取用户名称）

通过 `EX` 选项设置过期时间，自动过期释放内存，避免缓存雪崩

### 2.2. 分布式锁

**场景：** 在分布式系统中，多个进程可能会同时访问和修改共享资源，因此需要一个锁机制来避免并发冲突。

**实现方式：**

- `SETNX lock:order:12345 "locked"`（如果 key 不存在，则设置成功，表示获取到锁）
- `EXPIRE lock:order:12345 10`（设置超时时间，防止死锁）
- 操作完成后 `DEL lock:order:12345`（释放锁）

> 在 Redis 中，大部分**单个命令**都是原子操作，像 `SET`、`INCR`、`SETNX`、`DEL` 是绝对原子的，因为 Redis 是单线程执行命令的，这意味着 不会有其他操作在命令执行的过程中打断它。当然也有不是原子操作: `GETSET`, `MGET / MSET`, 

### 2.3. 计数器

**场景：** 需要对某个值进行频繁的递增或递减操作，比如访问量统计、点赞数、库存管理等。

**实现方式：**

- `INCR page:view:article:1001`（文章 1001 的浏览量 +1）
- `DECR product:stock:2001`（商品 2001 的库存 -1）
- `INCRBY user:1001:points 50`（用户 1001 的积分增加 50）

### 2.4. 短链接存储

**场景：** 实现短链接功能，如 `https://tinyurl.com/abcd` 映射到 `https://example.com/long-url`。

**实现方式：**

- `SET short:abcd "https://example.com/long-url"`
- `GET short:abcd`（通过短链接获取原始 URL）

> 可以发现 Redis 中习惯在 KEY 中通过 `:` 连接字符串, 这样可以清晰的表达出含义, 如: `page:view:article:1001`, 这就是一个字符串, 不是什么高级的东西, 

## 3. Set 使用场景

### 3.1. 数据去重与快速查重

利用 Set 元素不允许重复的特性，可以用来存储用户访问记录、去重 URL、或防止重复投票等场景。

例如：记录某个用户访问过的页面，避免重复统计。

```redis
# 添加用户访问记录（每个页面仅记录一次）
SADD user:123:visited "page1"
SADD user:123:visited "page2"
SADD user:123:visited "page1"  # 重复添加不会生效

# 判断用户是否已访问某个页面
SISMEMBER user:123:visited "page1"  # 返回 1 表示存在，0 表示不存在

# 获取该用户所有访问过的页面
SMEMBERS user:123:visited
```

### 3.2. 标签管理和推荐系统

在内容推荐场景中，可以使用 Set 来存储用户或内容的标签，然后利用集合的交集或并集进行推荐匹配。例如，根据用户关注的标签推荐相似内容。

```redis
# 给文章添加标签
SADD article:100:tags "tech" "ai" "redis"

# 用户兴趣标签
SADD user:123:tags "ai" "machine learning" "tech"

# 计算用户与文章标签的交集，判断兴趣匹配度
SINTER article:100:tags user:123:tags
```

`SINTER` 可计算出用户与文章之间的标签交集，判断用户对该文章的兴趣匹配情况，从而辅助推荐算法。

### 3.3. 黑名单/白名单管理

Set 常用于存储黑名单或白名单数据，由于其快速的查找特性，可以高效判断某个元素是否被列入名单，适用于安全控制、IP 屏蔽、广告过滤等场景。

```redis
# 添加IP到黑名单
SADD blacklist:ips "192.168.1.100" "10.0.0.5"

# 检查IP是否在黑名单中
SISMEMBER blacklist:ips "192.168.1.100"  # 返回 1 表示IP被屏蔽

# 移除IP
SREM blacklist:ips "10.0.0.5"
```

