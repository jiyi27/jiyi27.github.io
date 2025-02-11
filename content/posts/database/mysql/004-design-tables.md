---
title: 数据库设计 - 悲观锁/乐观锁 缓存
date: 2025-02-02 19:20:35
categories:
 - 数据库
tags:
 - 数据库
 - 并发编程
 - 面试
---

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

## 1. 帖子中应该放点赞数和回复数吗

优点是读取性能好, 减少数据库压力 , 显示帖子列表时无需连表统计, 

缺点是会有**写入一致性问题**, 

假设用户点赞一个帖子，我们需要做两件事：

1. 在 post_likes 表插入一条点赞记录
2. 在 posts 表把这个帖子的 likes_count 加1

如果不使用事务，可能出现以下问题：

```mysql
-- 第一步：插入点赞记录成功
INSERT INTO post_likes (post_id, user_id) VALUES (1, 1);

-- 第二步：更新帖子点赞数
-- 假设在这时候数据库突然崩溃了或者网络中断了
UPDATE posts SET likes_count = likes_count + 1 WHERE id = 1;
```

这就导致了数据不一致：post_likes 表显示用户点赞了, 但是 posts 表的点赞数没有增加, 

还会有**并发问题**, 想象一个具体的场景：帖子当前有100个赞，两个用户 A 和 B 同时点赞:

```mysql
-- 用户A的操作
UPDATE posts SET likes_count = likes_count + 1 WHERE id = 1;

-- 用户B的操作(同时进行)
UPDATE posts SET likes_count = likes_count + 1 WHERE id = 1;
```

可能出现的问题：

1. A读取到 likes_count = 100
2. B读取到 likes_count = 100
3. A更新 likes_count = 101
4. B更新 likes_count = 101

最终结果是 likes_count = 101，但实际上应该是102，因为发生了两次点赞。这些问题可以通过悲观锁和乐观锁解决, 但是也会引入额外的消耗:

此时有一个简单的解决办法, 使用事务 + 悲观锁:

```mysql
BEGIN;
    -- 1. 锁住这行数据,其他事务无法修改
    SELECT * FROM posts WHERE id = 1 FOR UPDATE;  
    -- 2. 插入点赞记录
    INSERT INTO post_likes (post_id, user_id) VALUES (1, 1);
    -- 3. 更新点赞数
    UPDATE posts SET likes_count = likes_count + 1 WHERE id = 1;
COMMIT;  -- 提交事务时才释放锁
```

综上, 添加计数字段(likes_count, comments_count)带来的问题：

- 并发问题：多人同时操作导致计数不准确
- 数据一致性问题：计数更新和实际操作需要同时成功或失败

解决方案必须同时使用事务和锁：

- 事务：保证关联操作的原子性（要么都成功，要么都失败）
- 锁：防止并发冲突

两种锁的选择：

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

## 2. 帖子表放点赞和回复数 高并发系统怎么优化

### 2.1. 使用缓存（Redis）

做法：点赞和评论操作先更新缓存（如 Redis 中的计数器），并采用原子操作保证计数准确；然后通过后台任务定期将缓存数据同步到 MySQL 中。

优点：利用内存数据库的高性能，可以应对高并发写入；同时减少数据库直接写操作，降低锁竞争。

缺点：增加了系统架构复杂度，需要额外处理缓存同步和可能的数据不一致问题。

### 2.2. 异步更新（延迟更新/批量更新）

做法：点赞和评论的原始数据依然记录在 `post_likes` 和 `comments` 表中；而 `posts` 表中的统计字段不是实时更新，而是通过定时任务或异步消息队列，定时聚合计算后批量更新。

优点：降低了对 `posts` 表的实时写入压力，能够平滑高并发下的更新流量，减少锁竞争问题。

缺点：数据实时性降低（**存在延迟**），对实时数据展示要求较高的场景可能不适用。

