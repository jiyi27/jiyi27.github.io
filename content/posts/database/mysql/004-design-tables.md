---
title: 数据库表设计 悲观锁/乐观锁 Redis 高并发场景实践
date: 2025-02-17 19:20:35
categories:
 - 数据库
tags:
 - 数据库
 - 并发编程
 - 面试
---

## 1. 典型设计

一个帖子系统, 用户可以发帖, 点赞帖子, 给帖子发表评论, 点赞评论, 回复评论

```mysql
-- 用户表
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '用户ID',
    username VARCHAR(50) NOT NULL COMMENT '用户名',
    email VARCHAR(100) NOT NULL COMMENT '邮箱',
    password_hash VARCHAR(255) NOT NULL COMMENT '密码哈希',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    UNIQUE KEY idx_username (username),
    UNIQUE KEY idx_email (email)
) COMMENT '用户表';

-- 帖子表
CREATE TABLE posts (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '帖子ID',
    user_id BIGINT NOT NULL COMMENT '作者ID',
    title VARCHAR(200) NOT NULL COMMENT '标题',
    content TEXT NOT NULL COMMENT '内容',
    likes_count INT NOT NULL DEFAULT 0 COMMENT '点赞数',
    comments_count INT NOT NULL DEFAULT 0 COMMENT '评论数',
    status TINYINT NOT NULL DEFAULT 1 COMMENT '状态:1-正常,2-已删除',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    version INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号';
    KEY idx_user_id (user_id) COMMENT '用户ID索引,用于查询用户的帖子列表',
    KEY idx_created_at (created_at) COMMENT '创建时间索引,用于按时间排序'
) COMMENT '帖子表';

-- 帖子点赞表
CREATE TABLE post_likes (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '点赞ID',
    post_id BIGINT NOT NULL COMMENT '帖子ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    UNIQUE KEY idx_post_user (post_id, user_id) COMMENT '帖子用户联合唯一索引,防止重复点赞',
    KEY idx_user_id (user_id) COMMENT '用户ID索引,用于查询用户的点赞列表'
) COMMENT '帖子点赞表';

-- 评论表
CREATE TABLE comments (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '评论ID',
    post_id BIGINT NOT NULL COMMENT '帖子ID',
    user_id BIGINT NOT NULL COMMENT '评论者ID',
    parent_id BIGINT DEFAULT NULL COMMENT '父评论ID,回复评论时使用',
    content TEXT NOT NULL COMMENT '评论内容',
    likes_count INT NOT NULL DEFAULT 0 COMMENT '点赞数',
    replies_count INT NOT NULL DEFAULT 0 COMMENT '回复数',
    status TINYINT NOT NULL DEFAULT 1 COMMENT '状态:1-正常,2-已删除',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    version INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号';
    KEY idx_post_id (post_id) COMMENT '帖子ID索引,用于查询帖子的评论列表',
    KEY idx_user_id (user_id) COMMENT '用户ID索引,用于查询用户的评论列表',
    KEY idx_parent_id (parent_id) COMMENT '父评论ID索引,用于查询评论的回复列表'
) COMMENT '评论表';

-- 评论点赞表
CREATE TABLE comment_likes (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '点赞ID',
    comment_id BIGINT NOT NULL COMMENT '评论ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    UNIQUE KEY idx_comment_user (comment_id, user_id) COMMENT '评论用户联合唯一索引,防止重复点赞',
    KEY idx_user_id (user_id) COMMENT '用户ID索引,用于查询用户的点赞列表'
) COMMENT '评论点赞表';
```

## 2. 帖子中应该放点赞数和回复数吗

### 2.1. 数据一致性问题 - 事务

优点是读取性能好, 减少数据库压力 , 显示帖子列表时无需连表统计, 缺点是会有**写入一致性问题和并发问题**, 假设用户点赞一个帖子，我们需要做两件事：

1. 在 post_likes 表插入一条点赞记录
2. 在 posts 表把这个帖子的 likes_count 加1

```mysql
-- 第一步：插入点赞记录成功
INSERT INTO post_likes (post_id, user_id) VALUES (1, 1);

-- 第二步：更新帖子点赞数
-- 假设在这时候数据库突然崩溃了或者网络中断了
UPDATE posts SET likes_count = likes_count + 1 WHERE id = 1;
```

这就导致了数据不一致: post_likes 表显示用户点赞了, 但是 posts 表的点赞数没有增加, 我们可以通过加入事务来解决:

```sql
BEGIN;
    INSERT INTO post_likes (post_id, user_id) VALUES (1, 1);
    UPDATE posts SET likes_count = likes_count + 1 WHERE id = 1;
COMMIT;
```

通过使用事务, 若 `BEGIN ... COMMIT` 中的一个语句执行失败, 之前所有的操作都不会成功, 这就解决了数据一致性问题

### 2.2. 并发问题 - X锁

下面先说一下一个常见的**误解**, 假如帖子当前有100个赞，两个用户 A 和 B 同时点赞:

```mysql
-- 用户A的操作
UPDATE posts SET likes_count = likes_count + 1 WHERE id = 1;

-- 用户B的操作(同时进行, 则都会读取到 likes_count = 100)
UPDATE posts SET likes_count = likes_count + 1 WHERE id = 1;
```

有人会想到可能会出现下面问题：

1. A读取到 likes_count = 100, B读取到 likes_count = 100
3. A更新 likes_count = 101, B 更新 likes_count = 101

最终结果是 likes_count = 101，但实际上应该是102, 其实并不会出现这个问题, 这里需要指出两个关于事务和锁事实:

- 在 MySQL 中，默认情况下 `autocommit` 是开启的（即 `autocommit=1`）。在这个模式下，每条单独的 SQL 语句 (增删改, **除了查**) 都会被当作一个独立的事务来执行。`SELECT` 语句通常不涉及事务（除非是 `SELECT ... FOR UPDATE` 这种需要锁的语句）
- 在数据修改操作（Update、Delete、Insert）中, InnoDB 会**自动**对受影响的行加上行级的**排它锁**（X 锁）
- 锁只会在事务 commit 或者 rollback 的时候自动被释放, 这也是为什么锁必须配合事务使用

根据第二条事实, 我们知道当执行 `UPDATE posts SET likes_count = likes_count + 1 WHERE id = 1;` 时, MySQL 会自动为 id=1 的行加上一个 x 锁, 意味着在这个锁没有被释放前, 其它任何事务都不可以修改这行数据, 因为想要修改某行数据必须要获得这行数据的 x 锁 (MySQL 默认行为), 而这行数据的 x锁还没被释放, 

下面使用如下表格展示用户A和用户B并发执行更新时的操作流程, 假设初始状态：`posts` 表中 id=1 的记录 `likes_count=100`: 

| 时间 (T) | 用户A的操作                                                 | 用户B的操作                                                  | 备注说明                             |
|---------|------------------------------------------------------------|------------------------------------------------------------|--------------------------------------|
| T₀      | ——                                                         | ——                                                         | 初始状态：点赞数 100 |
| T₁      | 执行 `UPDATE ...` 加排他锁并将值由 100 更新为 101 | ——                                                         | 用户A自动获得行锁，其他事务无法修改该行 |
| T₂      | ——（等待提交或后续操作）                                    | 尝试执行相同 `UPDATE` 语句但因行被锁，进入等待状态          | 用户B操作被阻塞，等待用户A释放锁   |
| T₃      | 提交事务，释放锁                                            | ——                                                         | 用户A提交后，行更新为 101，释放了锁 |
| T₄      | ——                                                         | 获得锁后执行 `UPDATE ...` 将值由 101 更新为 102 | 用户B操作获得锁，基于最新数据进行更新 |
| T₅      | ——                                                         | 提交事务                                                    | 最终结果：点赞数102（累加 2） |

可以看出, 并不需要手动加x锁, 只需要使用事务保证操作的原子性就好了, 因为UPDATE 会自动获得 x 锁, 不必担心并发问题, 如下:

```mysql
BEGIN;
    -- 插入点赞记录
    INSERT INTO post_likes (post_id, user_id) VALUES (1, 1);
    -- 更新点赞数
    UPDATE posts SET likes_count = likes_count + 1 WHERE id = 1;
COMMIT;
```

至于防止用户重复点赞, 我们可以在 `(post_id, user_id)` 上建立索引, 若相同数据插入, `INSERT INTO post_likes (post_id, user_id) VALUES (1, 1);` 必然失败, 导致业务逻辑抛出异常, 下面的更新操作也不会发生, 然后我们捕获异常, 告诉用户点赞重复即可, 

### 2.3. 事务 + 悲观锁

既然每条修改语句都会先尝试获取排它锁, 然后才能修改数据, 为什么还会有并发问题呢? 上面的情况很简单, 所以没有问题, 我们来考虑一个复杂一些的问题, 

假设有一个库存系统，需要先判断库存是否充足，再扣减库存。如果不使用显式加锁，可能会出现多个事务同时读取相同库存数量，然后都判断库存足够，导致库存扣减错误。

| 时间 (T) | 用户A的操作                                   | 用户B的操作                                                  | 备注说明                                                     |
| -------- | --------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| T₀       | ——                                            | ——                                                           | 初始状态：库存 `stock = 10`                                  |
| T₁       | 查询库存,  stock = 10                         | ——                                                           | 用户A读取库存，未加锁（普通 SELECT）                         |
| T₂       | ——                                            | 查询库存,  `stock = 10`                                      | 用户B也读取库存，双方看到的都是相同的初始库存                |
| T₃       | 库存足够10 ≥ 8, 加 X 锁, 更新库存 10 - 8 = 2, | ——                                                           | 用户A更新时加锁，库存实际变为 2                              |
| T₄       | ——                                            | 库存足够10 ≥ 6, 尝试更新库存数据, 无法获取 x锁, 尝试更新失败 | 用户B的 UPDATE 操作因被 A 的锁阻塞，等待 A 提交              |
| T₅       | 提交事务，释放锁                              | ——                                                           | 用户A提交后，锁释放，此时数据库中库存为 2                    |
| T₆       | ——                                            | 获得x锁后执行 UPDATE 操作 10 - 6 = 4,                        | 用户B执行更新时，虽然其早先读取到库存为 10，但更新操作是基于当前实际库存（2）进行扣减，即 2 - 6 = -4 |
| T₇       | ——                                            | 提交事务                                                     | 最终库存变为 -4，出现库存不足但仍被扣减的问题                |

这种问题通常需要使用悲观锁（例如 `SELECT ... FOR UPDATE`）, 即使用显式加锁可以解决这个问题：

```sql
-- 开启事务保证多个操作的原子性(数据一致性)
BEGIN;
    -- 手工显式加x锁，防止其他事务在判断和扣减期间修改库存
    SELECT stock FROM products WHERE product_id = 100 FOR UPDATE;
    -- 根据读取的库存进行判断
    IF (stock >= 5) THEN
        UPDATE products SET stock = stock - 5 WHERE product_id = 100;
    END IF;
COMMIT;
```

这里我们在事务开始前显式添加了 x锁, 这意味着若其它事务想修改 `product_id = 100` 这行数据, **必须先拿到这一行的 x锁**, 而此时若事务 A 已经显式拿到了  `product_id = 100` 这一行数据的 x锁, 意味着事务 A 不结束, 该锁永远不会被释放, 也就是其它事务永远不可能拿到这行数据的x锁, 也就无法执行下面的流程 (比如: 查询编号为100的商品的剩余, 更新该行数据), 

注意这里添加事务是为了保留显式添加的锁直到整个事务结束, 

可以看出, 使用悲观锁（通过 `SELECT ... FOR UPDATE` 显示加 X 锁）的主要目的就是在执行更新前，确保读取到的数据是最新且不会被其他并发事务修改，从而**保证基于该数据做出的判断是可靠的**。如果判断通过，再执行更新操作，而这整个过程都在同一个事务内执行，确保了原子性和隔离性，避免数据竞争和不一致的问题。

> **小贴士**:  **`X锁` 的加锁方式有两种**，第一种是自动加锁，在对数据进行**增删改**的时候，都会默认加上一个`X锁`。还有一种是手工加锁，我们用一个`FOR UPDATE`给一行数据加上一个`X锁`, `X锁`在同一时刻只能被一个事务持有, 其它事务想获得, 必须等待

> 最常见的数据一致性问题就是多步骤其中一个步骤失败引起的, 比如假设你在银行 A 账户有 1000 元，你想转账 200 元到银行 B 账户, 正常情况下 从 A 账户扣除 200 元（余额变成 800）, 向 B 账户增加 200 元（余额变成 1200）, 假设在步骤 1 之后（A 账户变成 800），系统崩溃或网络异常，导致步骤 2 没有执行, 这就导致 A 账户已经减少了 200 元（800），但 B 账户仍然是 1000, 这也是数据一致性问题, 这种数据一致性问题我们可以添加事务 **利用事务的原子性**来解决, 
>
> 数据一致性问题分为好多种, 比如上面用户A, B同时点赞, 导致点赞数丢失的问题, 比如多个人给一个账户转 100 块钱,  A事务读取到此时账户余额为 100, B事务 也读取到账户余额为 100, 所以 A: 余额= 100 + 100 = 200, B事务 也是这样, 最后账户余额仅为 200 而不是 300, 导致数据一致性问题, 这种数据一致性问题可以**通过 x 锁解决**, 当然 MySQL 数据库默认加上了 x 锁, 我们不必担心
>
> 还有一种是需要判断再进行其他增减操作的, 比如高并发防止**库存超卖**, 我们需要先判断库存是否有剩余, 再进行扣减, 这个时候就有了两个操作 判断 + 扣除, 这个时候就需要使用悲观锁直接锁定或者使用乐观锁, 需要通过锁机制来确保“判断+扣减”作为一个整体原子操作执行, 通过一个版本号标识数据的状态, 在更新时检查版本是否一致, 如果一致, 说明数据未被其他线程修改, 可以安全更新；如果不一致，说明有并发修改，需要重试或失败处理。
>
> ```sql
> SELECT quantity, version FROM stock WHERE product_id = 1001;
> ...
> UPDATE stock 
> SET quantity = quantity - 2, version = version + 1 
> WHERE product_id = 1001 AND version = 1;
> ```

## 3. 帖子表放点赞数 高并发点赞 Redis + Kafka

首先看一下易错的实现:

```java
@Transactional
public void likePost(Long postId, Long userId) {
    String likesUsersKey = "post:" + postId + ":likes_users";
    String likesCountKey = "post:" + postId + ":likes_count";
    // 1. 检查是否已点赞, 检查和更新操作分离
    if (Boolean.TRUE.equals(redisTemplate.opsForSet().isMember(likesUsersKey, userId))) {
        return;
    }

    // 2. Redis 操作：添加用户 ID 到点赞集合 & 计数+1
    redisTemplate.opsForSet().add(likesUsersKey, userId);
    redisTemplate.opsForValue().increment(likesCountKey, 1);

    // 3. 发送 Kafka 事件 (type=like)
    String event = "like," + postId + "," + userId;
    kafkaTemplate.send("like-topic", event);
}
```

初学者可能会认为Redis 服务是一个单线程进程, 所以即使一个用户同时进行两次点赞, 也不会出现数据不一致问题, 因为在:

```java
redisTemplate.opsForSet().add(likesUsersKey, userId);
```

这一步就会失败(Set 集合天然唯一性), 自增1也不可能执行, 首先这么理解是不对的, `opsForSet().add(...);` 底层调用的是 Redis 的 SADD 命令, 如果添加的成员已经存在于集合中, Redis 不会抛出异常，而是简单地**忽略**该操作, 所以下面的代码(自增1)会继续执行, 那这就可能导致数据不一致问题:

| 步骤 | 线程A操作                               | 线程B操作                               | Redis 中的实际情况                       |
| ---- | --------------------------------------- | --------------------------------------- | ---------------------------------------- |
| 1    | `isMember(likes_users, 888)` 返回 false |                                         | `likes_users = {}`, `likes_count = 0`    |
| 2    |                                         | `isMember(likes_users, 888)` 返回 false | `likes_users = {}`, `likes_count = 0`    |
| 3    | `SADD(likes_users, 888)`，返回 1        |                                         | `likes_users = {888}`, `likes_count = 0` |
| 4    | `increment(likes_count)`，加 1          |                                         | `likes_users = {888}`, `likes_count = 1` |
| 5    |                                         | `SADD(likes_users, 888)`，返回 0        | `likes_users = {888}`, `likes_count = 1` |
| 6    |                                         | `increment(likes_count)`，又加 1        | `likes_users = {888}`, `likes_count = 2` |

从最终结果看, Set 中只有一个用户 (888), 但 `likes_count` 变成了 2, 这就是「点赞数比实际多」的不一致情况, 要解决这个问题可以利用 Redis 命令本身返回值并在代码中加以判断:

```java
public void likePost(Long postId, Long userId) {
    String likesUsersKey = "post:" + postId + ":likes_users";
    String likesCountKey = "post:" + postId + ":likes_count";

    // sAddRet 要么是 1（成功加入，不在集合中），要么是 0（已存在，没加入）
    Long sAddRet = redisTemplate.opsForSet().add(likesUsersKey, userId);
    if (sAddRet != null && sAddRet > 0) {
        // 只有在成功新加了用户的时候才执行加1
        redisTemplate.opsForValue().increment(likesCountKey, 1);
        // 同时再发Kafka事件
        String event = "like," + postId + "," + userId;
        kafkaTemplate.send("like-topic", event);
    }
}
```

这样只有在成功加入到集合的时候, 才进行加1操作, 所以解决了上面的问题, 这样虽然可以解决, Redis 遇到多个操作如 检查 + 更新 这种场景的时候, 还是应该考虑**利用分布式锁或者Lua脚本保证操作原子性**来解决问题, 

除此之外, 可以注意到上面的代码我们省略了 `isMember` 判断, 因为我们的实现依赖 `SADD` 的返回值来判定是否是第一次点赞,

> Spring 的 `@Transactional` 注解默认只对使用了关系型数据库（如 JPA / JDBC）的事务生效。对于 RedisTemplate 的操作，除非你做了额外的配置（例如启用 Redis 事务支持，或使用了 Lua 脚本实现原子性操作），否则 Redis 并不会因为 Spring 事务回滚而自动回滚。换句话说，一般情况下，Redis 操作默认是「非事务性」的，Spring 事务并不会对它生效。

## 4. 高并发防止库存超卖

### 4.1. Redis + Lua 脚本

除了悲观锁和乐观锁, 还可以使用 Redis 来解决这个问题, 首先可能会想到的是利用 Redis 单线程特性, 伪代码如下:

```java
public boolean deductStock(String productId, int amount) {
    String key = "stock:" + productId;
    // 1. 检查库存
    Integer stock = redis.get(key);
    if (stock == null || stock < amount) {
        return false; // 库存不足
    }

    // 2. 原子扣减
    Integer newStock = redis.decrBy(key, amount);
    if (newStock < 0) {
        // 库存不足，手动回滚
        redis.incrBy(key, amount);
        return false;
    }
    return true; // 扣减成功
}
```

假设初始库存为 5, 两个线程 T1 和 T2 同时尝试扣减 3 个库存:

| 时间步 | 线程 T1                        | 线程 T2                        | Redis 库存 | 备注                      |
| ------ | ------------------------------ | ------------------------------ | ---------- | ------------------------- |
| T1     | GET 返回 5，检查 5 >= 3        |                                | 5          | T1 检查通过               |
| T2     |                                | GET 返回 5，检查 5 >= 3        | 5          | T2 检查通过               |
| T3     | DECRBY 3，返回 2               |                                | 2          | T1 扣减成功，newStock = 2 |
| T4     | 检查 newStock = 2 >= 0，不回滚 |                                | 2          | T1 完成，库存合法         |
| T5     |                                | DECRBY 3，返回 -1              | -1         | T2 扣减，newStock = -1    |
| T6     |                                | 检查 newStock = -1 < 0，回滚 3 | 2          | T2 回滚，库存恢复到 2     |

库存最终值：2（T1 扣了 3，T2 扣了又回滚）, 似乎问题解决了, 但实际上这只是表面现象, 问题依然存在:

虽然 `decrBy` 本身是原子的, 但前面的检查（`get` 和判断库存是否足够）与扣减之间不是一个原子操作, 当 `decrBy` 执行后，如果结果小于 0，则会调用 `redis.incrBy` 补偿库存，并返回扣减失败。这样虽然能保证最终库存不会维持在负值，但**在短时间内可能出现库存负值的状态**，而且多个并发请求可能都进行补偿操作:

- 这会导致性能问题, 大量线程尝试扣减, 最终只有少数成功, 其他回滚, 浪费资源
- 严重的情况是由于网络延迟等原因导致补偿操作不成功, 从而引起实际上的超卖问题

所以你看, 即使 Redis 是单线程, 所有发送到 Redis 服务器的指令都是一个个串行执行, 依然可能会出现并发问题,  

**改进建议** 为了解决上述问题, 可以使用 Lua 脚本将库存检查和扣减操作封装成一个原子操作, 确保整个过程在 Redis 内部一次性执行, 从而消除检查与扣减之间的时间窗口, 例如, 可以使用如下 Lua 脚本来实现:

```lua
local stock = tonumber(redis.call('get', KEYS[1]))
if stock and stock >= tonumber(ARGV[1]) then
    return redis.call('decrby', KEYS[1], ARGV[1])
else
    return -1
end
```

伪代码:

```java
public boolean deductStock(String productId, int amount) {
    String key = "stock:" + productId;
    String luaScript = "local stock = tonumber(redis.call('GET', KEYS[1]))\n" +
                       "local amount = tonumber(ARGV[1])\n" +
                       "if stock == nil then return -1 end\n" +
                       "if stock < amount then return -2 end\n" +
                       "local newStock = stock - amount\n" +
                       "redis.call('SET', KEYS[1], newStock)\n" +
                       "return newStock";
    // Lua 脚本在 Redis 内部执行, 效率极高
    Long result = redis.eval(luaScript, Collections.singletonList(key), Collections.singletonList(String.valueOf(amount)));
    return result >= 0; // >= 0 表示扣减成功
}
```

**总结** 虽然这个方案通过补偿操作在逻辑上试图防止超卖，但由于库存检查与扣减操作之间不是原子性的，仍然存在在高并发场景下出现短暂负库存（即“超卖”）的风险。使用 Lua 脚本或分布式锁来保证整个扣减过程的原子性是更为稳妥的方案。

### 4.2. 分布式锁

在方案二（Lua 脚本）中, 我们将“检查库存”和“扣减库存”封装成一个原子操作, **完全在 Redis 内部执行**, 效率很高, 如果业务逻辑复杂, 例如扣减库存后需要异步更新数据库, 可以用 Redis 分布式锁来控制并发,

1. 获取锁： 使用 SETNX（Set if Not Exists）加锁：

```
SET lock:1001 1 EX 10 NX  # 设置锁，10秒过期
```

2. 扣减库存： 获取锁后，检查并扣减库存：

```
GET stock:1001
DECRBY stock:1001 2
```

3. 释放锁： 操作完成后删除锁

```
DEL lock:1001
```

伪代码:

```java
public boolean deductStock(String productId, int amount) {
    String lockKey = "lock:" + productId;
    String stockKey = "stock:" + productId;
    
    // 获取分布式锁
    boolean locked = redis.setNX(lockKey, "1", 10);
    if (!locked) {
        return false; // 获取锁失败, 被其他线程占用
    }
    
    try {
        // 检查库存
        Integer stock = redis.get(stockKey);
        if (stock == null || stock < amount) {
            return false;
        }
        
        // 扣减库存
        Integer newStock = redis.decrBy(stockKey, amount);
        if (newStock < 0) {
            redis.incrBy(stockKey, amount); // 回滚
            return false;
        }
        
        // 异步更新数据库
        asyncExecutor.submit(() -> {
            try {
                updateDatabase(productId, amount);
            } catch (Exception e) {
                // 数据库更新失败，回滚 Redis
                redis.incrBy(stockKey, amount);
                log.error("Database update failed, rolled back stock", e);
            }
        });
        return true;
    } finally {
        redis.del(lockKey); // 释放锁
    }
}
```

### 4.3. 总结

Lua 脚本适用场景: 业务逻辑简单，只涉及 Redis 数据操作, Lua 脚本只能操作 Redis 的数据, 无法直接与外部系统（如数据库、消息队列）交互, 

分布式锁适用场景: 库存扣减后需要与外部系统（如数据库）保持一致性
