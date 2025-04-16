---
title: Redis 常见数据类型的使用场景
date: 2025-04-13 21:56:20
categories:
 - 面试
tags:
 - 面试
 - 缓存面试
---

## 1. String

### 1.1. 缓存热点数据

在高并发系统中，频繁查询数据库会导致性能瓶颈，使用 Redis String 缓存数据库查询结果（如用户信息、商品详情）可以显著降低数据库压力：

```python
user_id = 1001
cached_user = redis_client.get(f"user:{user_id}")
if cached_user:
    return json.loads(cached_user)
else:
    user = db.query(User).get(user_id)  # 从数据库查询
    redis_client.setex(f"user:{user_id}", 3600, json.dumps(user))  # 缓存 1 小时
    return user
```

> Redis 中习惯在 KEY 中通过 `:` 连接字符串, 这样可以清晰的表达出含义, 如: `page:view:article:1001`, 就是一个字符串, 不是什么高级的东西

### 1.2. 分布式锁

在分布式系统中，防止多个服务同时操作同一资源（如库存扣减），Redis String 结合 SETNX（set if not exists）实现简单分布式锁

- `SETNX lock:order:12345 "locked"`（如果 key 不存在，则设置成功，表示获取到锁）
- `EXPIRE lock:order:12345 10`（设置超时时间，防止死锁）
- 操作完成后 `DEL lock:order:12345`（释放锁）

> 在 Redis 中，大部分**单个命令**都是原子操作，像 `SET`、`INCR`、`SETNX`、`DEL` 是绝对原子的，因为 Redis 是单线程执行命令的，这意味着 不会有其他操作在命令执行的过程中打断它，当然也有不是原子操作: `GETSET`, `MGET / MSET`

### 1.3. 计数器

记录网站的访问量、文章的点赞数、商品的浏览量等，Redis String 支持原子操作 INCR 和 DECR，非常适合计数场景

```
INCR article:view:2001  # 文章 ID 2001 浏览量 +1
GET article:view:2001   # 获取当前浏览量
```

### 1.4. 短链存储

实现短链接功能，如 `https://tinyurl.com/abcd` 映射到 `https://example.com/long-url`

```python
def generate_short_code(url):
    """生成短链代码（如 6 位随机字符串或基于 URL 的哈希）"""
    # 简单示例：随机 6 位字符
    characters = string.ascii_letters + string.digits
    return ''.join(random.choice(characters) for _ in range(6))

def create_short_url(long_url, expire_seconds=2592000):
    """创建短链并存储"""
    short_code = generate_short_code(long_url)
    # 确保 short_code 唯一，实际中可能需要重试或哈希
    while redis_client.exists(f"short:{short_code}"):
        short_code = generate_short_code(long_url)
    redis_client.setex(f"short:{short_code}", expire_seconds, long_url)
    return short_code

def get_long_url(short_code):
    """根据短链获取原始网址"""
    long_url = redis_client.get(f"short:{short_code}")
    return long_url.decode() if long_url else None
```

## 2. Set

### 2.1. 数据去重与快速查重

利用 Set 元素不允许重复的特性，可以用来存储用户访问记录或防止重复投票 点赞等场景

### 2.2. 共同关注/好友推荐

社交平台中，查找用户共同关注的人，或基于共同关注推荐新好友

```redis
SADD user:1001:follows "user:2001" "user:2002" "user:2003"
SADD user:1002:follows "user:2002" "user:2003" "user:2004"
SINTER user:1001:follows user:1002:follows  # 交集：共同关注 ["user:2002", "user:2003"]
```

### 2.3. 黑名单/白名单管理

Set 常用于存储黑名单或白名单数据，由于其快速的查找特性，可以高效判断某个元素是否被列入名单，适用于安全控制、IP 屏蔽、广告过滤等场景

```redis
# 添加IP到黑名单
SADD blacklist:ips "192.168.1.100" "10.0.0.5"

# 检查IP是否在黑名单中
SISMEMBER blacklist:ips "192.168.1.100"  # 返回 1 表示IP被屏蔽

# 移除IP
SREM blacklist:ips "10.0.0.5"
```

## 3. Redis Hash 

### 3.1. 用户信息存储

Redis Hash 是一个键值对集合，每个 Hash 包含多个字段和对应的值，你可以单独操作某个字段（增、删、改、查），而不必操作整个数据结构,

**对比 JSON 字符串**：如果用 String 类型存储对象（例如用户信息），通常会将整个对象序列化为 JSON 字符串`{"id":"1001","name":"Alice","email":"alice@example.com"}`要修改某个字段（如只改 `name`），需要：

1. 获取整个 JSON 字符串（GET）
2. 反序列化解析为对象
3. 修改字段
4. 序列化回 JSON
5. 再存回 Redis, 这会导致额外的 CPU 和内存开销，且操作复杂

```python
HMSET user:1001 id "1001" name "Alice" email "alice@example.com"
HSET user:1001 name "Bob"  # 只修改 name 字段
HGET user:1001 name       # 只获取 name 字段
```

### 3.2. 配置管理

存储系统配置项（如 API 密钥、开关状态）

```
HMSET config:api rate_limit "100" enabled "true"
HGET config:api rate_limit  # 获取限流配置
```

### 3.3. 购物车管理

存储用户购物车，商品 ID 作为字段，数量作为值

```
HSET cart:user:1001 product:001 2 product:002 1  # 购买 2 件 product:001，1 件 product:002
HINCRBY cart:user:1001 product:001 1  # 增加 1 件
HGETALL cart:user:1001  # 获取购物车内容
```

## 4. List

### 4.1. 简单的消息队列

一个电商平台需要处理订单支付后的通知（如发送邮件或短信）， 前端提交订单后，后台将通知任务放入队列，消费者异步处理, 优点：

- LPUSH 和 BRPOP 提供高效的队列操作

- BRPOP 的阻塞机制减少轮询，提高性能

- 适合轻量级队列，简单易用

**场景**

- 假设订单支付后，需发送一封确认邮件
- 生产者（订单服务）将任务推入 Redis List，消费者（邮件服务）从队列取出任务

```python
# 生产者：订单支付后推送任务
def add_notification_task(order_id, user_email):
    task = f"send_email:{order_id}:{user_email}"
    r.lpush("notification_queue", task)  # 推入队列头部
    print(f"Task added for order {order_id}")

# 消费者：邮件服务处理任务
def process_notification():
    while True:
        # 阻塞等待任务，最多等 10 秒
        task = r.brpop("notification_queue", timeout=10)
        if task:
            _, task_data = task  # task 是 (key, value) 元组
            print(f"Processing: {task_data.decode()}")
            # 解析任务并发送邮件（伪代码）
            order_id, email = task_data.decode().split(":")[1:]
            send_email(email, f"Order {order_id} confirmed!")
```

> 思考： 如何保证消息队列的可靠性？

### 4.2. 任务堆栈（撤销操作）

一个在线文档编辑器需要支持“撤销”功能，记录用户的每次操作（如文本插入、删除），用户点击撤销时回退到上一步：

- 用户每次编辑，操作记录压入 List

- 点击撤销，从 List 顶部弹出最近的操作并执行反向逻辑

```python
# 记录用户编辑操作
def record_edit(user_id, operation):
    key = f"edit_history:{user_id}"
    r.lpush(key, operation)  # 压入操作
    r.ltrim(key, 0, 99)  # 限制最多 100 条历史
    print(f"Recorded: {operation}")

# 撤销操作
def undo_edit(user_id):
    key = f"edit_history:{user_id}"
    operation = r.lpop(key)  # 弹出最近操作
    if operation:
        print(f"Undoing: {operation.decode()}")
        # 执行反向操作（伪代码）
        reverse_operation(operation.decode())
    else:
        print("No operations to undo")

# 测试
record_edit("user123", "insert:text:hello")
record_edit("user123", "delete:char:5")
undo_edit("user123")  # 输出: Undoing: delete:char:5
```

### 4.3. 时间线

一个社交平台需要展示用户**最新的 10 条动态**（如朋友圈或微博），按发布时间倒序排列, 优点：

- LPUSH 保证最新动态在列表头部，天然按时间倒序

- LRANGE 高效获取指定范围的数据

- 适合实时更新和展示有序内容

**场景：**

- 用户发布动态时，记录动态 ID 和内容到 List

- 前端请求时，取出最新的 N 条动态展示

```python
# 用户发布动态
def post_update(user_id, content):
    post_id = int(time.time() * 1000)  # 用时间戳作为 ID
    post_data = f"{post_id}:{user_id}:{content}"
    r.lpush("timeline:global", post_data)  # 推入全局时间线
    r.ltrim("timeline:global", 0, 999)  # 限制 1000 条
    print(f"Posted: {content}")

# 获取最新动态
def get_recent_posts(limit=10):
    posts = r.lrange("timeline:global", 0, limit - 1)  # 取最新 10 条
    return [p.decode() for p in posts]

# 测试
post_update("user123", "Hello, world!")
post_update("user456", "Nice day!")
recent_posts = get_recent_posts()
for post in recent_posts:
    print(post)
```

> 注意 List 不适合排行榜, 因为他不会排序, 可以考虑使用堆来实现
