---
title: 数据库表设计 事务 悲观锁/乐观锁 缓存
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

最终结果是 likes_count = 101，但实际上应该是102。

其实并不会出现这个问题, 这里需要指出两个关于事务和锁事实:

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

> **数据一致性:** 数据一致性问题分为好多种, 比如上面用户A, B同时点赞, 导致点赞数丢失的问题, 还有个常见的例子(库存扣减、银行转账等操)比如多个人给一个账户转 100 块钱,  A事务读取到此时账户余额为 100, B事务 也读取到账户余额为 100, 所以 A: 余额= 100 + 100 = 200, B事务 也是这样, 最后账户余额仅为 200 而不是 300, 导致数据一致性问题, **这种数据一致性问题可以通过 x 锁来解决,** 
>
> 数据一致性问题还有其他类型, 比如假设你在银行 A 账户有 1000 元，你想转账 200 元到银行 B 账户, 正常情况下 从 A 账户扣除 200 元（余额变成 800）, 向 B 账户增加 200 元（余额变成 1200）, 假设在步骤 1 之后（A 账户变成 800），系统崩溃或网络异常，导致步骤 2 没有执行, 这就导致 A 账户已经减少了 200 元（800），但 B 账户仍然是 1000, 这也是数据一致性问题, **这种数据一致性问题我们可以添加事务 利用事务的原子性来解决**, 
>
> 还有另一种常见的数据一致性问题, 缓存与数据库不一致, 用户 A 购买商品
>
> - 读取缓存，库存为 10
> - 购买 2 个，库存变成 8，更新数据库
> - 更新缓存（库存改为 8）
>
> 用户 B 也购买商品
>
> - 读取缓存，发现库存仍然是 10（因为缓存可能未及时更新）
> - 购买 3 个，库存变成 7，更新数据库
> - 更新缓存（库存改为 7）
>
> 用户 A 的库存更新在数据库执行后，但缓存还没更新时，用户 B 读取的库存数据是错误的，导致超卖问题, 这种问题可以通过**写回数据库后删除缓存**或**使用事务机制**, 确保数据库和缓存的同步

### 2.4. 悲观锁和乐观锁常见实现

```mysql
-- 方案1：事务 + 悲观锁
BEGIN;
    SELECT * FROM posts WHERE id = 1 FOR UPDATE;  -- 悲观锁
    INSERT INTO post_likes (post_id, user_id) VALUES (1, 1);
    UPDATE posts SET likes_count = likes_count + 1 WHERE id = 1;
COMMIT;

-- 方案2：事务 + 乐观锁
-- 优点: 并没有加实际意义上的锁, 其它用户插入也不用等待
-- 缺点: 需要重试机制, 如果更新失败版本号检查不匹配，需要重试
BEGIN;
    INSERT INTO post_likes (post_id, user_id) VALUES (1, 1);
    -- 更新时检查版本号
    UPDATE posts 
    SET likes_count = likes_count + 1,
        version = version + 1 
    WHERE id = 1 AND version = 5;  -- 乐观锁通过版本号检查, 如果版本号不匹配，说明数据被其他人修改过
COMMIT;
```

因为帖子系统, 查询点赞和回复数非常的频繁, 比如用户刷新主页, 进入帖子, 都会引起查询, 这也是论坛的主要功能, 所以还是帖子表和评论表还是应该放点赞和回复数的, 对于中小型系统, 上面的问题通过悲观锁+事务其实就可以解决了, 因为并发量并不会特别高, 又不是微博, X那种高互动的网站, 

## 3. 帖子表放点赞和回复数 高并发系统怎么优化

### 3.1. 使用缓存（Redis）

做法：点赞和评论操作先更新缓存（如 Redis 中的计数器），并采用原子操作保证计数准确；然后通过后台任务定期将缓存数据同步到 MySQL 中

优点：利用内存数据库的高性能，可以应对高并发写入；同时减少数据库直接写操作，降低锁竞争

缺点：增加了系统架构复杂度，需要额外处理缓存同步和可能的数据不一致问题

### 3.2. 异步更新（延迟更新/批量更新）

做法：点赞和评论的原始数据依然记录在 `post_likes` 和 `comments` 表中；而 `posts` 表中的统计字段不是实时更新，而是通过定时任务或异步消息队列，定时聚合计算后批量更新

优点：降低了对 `posts` 表的实时写入压力，能够平滑高并发下的更新流量，减少锁竞争问题

缺点：数据实时性降低（**存在延迟**），对实时数据展示要求较高的场景可能不适用

