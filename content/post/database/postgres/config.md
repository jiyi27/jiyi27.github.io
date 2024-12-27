---
title: PostgreSQL COnfiguration
date: 2024-12-27 17:51:35
tags:
 - database
 - postgres
---

Mac

```bash
$ brew install postgresql@15
$ brew services start postgresql@15

$ psql postgres 
$ CREATE ROLE admin WITH LOGIN PASSWORD '778899' CREATEDB
$ SET ROLE admin; # 切换角色
```

> PostgreSQL 安装后会自动创建一个名为 `postgres` 的数据库, 所以 `psql postgres` 的意思是连接到 `postgres` 数据库 
>
> 默认情况下, PostgreSQL 使用当前系统用户的名称作为数据库用户名, 如果你的系统登录用户名是 david，PostgreSQL 会假定你也有一个名为 david 的数据库用户，并尝试以这个用户登录
>
> 所以当你输入 `psql postgres`, 默认用户是 `david`, 数据库就是你指定的  `postgres`, 所在的 schema 默认是 `public`

--------

PostgreSQL 和 MySQL 的主要区别:

```bash
PostgreSQL 组织层次：
Instance (服务)
└── Database
    └── Schema (默认是 public)
        └── Table/Function/View/Trigger/Index 等对象

MySQL 组织层次：
Instance (服务)
└── Database
    └── Table/Function/View 等对象
```

PostgreSQL 有 schema 概念，主要用于组织数据库对象(表 函数 视图):

```bash
-- 创建并使用不同的 schema
CREATE SCHEMA api_v1;
CREATE SCHEMA api_v2;

-- 在不同 schema 中创建同名表
CREATE TABLE api_v1.users (...);
CREATE TABLE api_v2.users (...);
```

---------

常用指令

```bash
$ psql -U admin -d skymates
psql (15.10 (Homebrew))
Type "help" for help.

skymates=>
```

```postgresql
skymates=> \du -- 查看所有用户
                                   List of roles
 Role name |                         Attributes                         | Member of
-----------+------------------------------------------------------------+-----------
 admin     | Create DB                                                  | {}
 david     | Superuser, Create role, Create DB, Replication, Bypass RLS | {}

skymates=>CREATE DATABASE mydb; -- 创建数据库
skymates=> \c mydb -- 切换数据库
You are now connected to database "mydb" as user "admin".
mydb=>

skymates=> \l -- 查看所有数据库
                                         List of databases
   Name    | Owner | Encoding | Collate | Ctype | ICU Locale | Locale Provider | Access privileges
-----------+-------+----------+---------+-------+------------+-----------------+-------------------
 mydb      | admin | UTF8     | C       | C     |            | libc            |
 postgres  | david | UTF8     | C       | C     |            | libc            |
 skymates  | david | UTF8     | C       | C     |            | libc            |
```

`\d` 是一个通用的描述命令，它的行为会根据后面的参数有所不同：

```postgresql
\dt -- 只列出表(tables)
\dv -- 只列出视图(views)
\di -- 只列出索引(indexes)
\ds -- 只列出序列(sequences)
\df -- 只列出函数(functions)
\dn -- 只列出模式(schemas)
```

-----------

创建表

```sql
-- 如果需要 UUID 支持，首先确保启用 uuid-ossp 扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 创建用户表
CREATE TABLE users (
    -- 使用 UUID 作为主键，默认使用 uuid_generate_v4() 生成
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- 用户名：非空且唯一，设置合理的长度限制
    username VARCHAR(50) NOT NULL UNIQUE,
    
    -- 密码哈希：非空，建议使用 bcrypt 等算法处理后存储
    hashed_password VARCHAR(100) NOT NULL,
    
    -- 邮箱：非空且唯一，并添加邮箱格式验证
    email VARCHAR(255) NOT NULL UNIQUE,
    
    -- 头像URL：允许为空
    avatar_url TEXT,
    
    -- 创建时间：自动设置为当前时间
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- 更新时间：自动在记录更新时更新
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建更新时间触发器
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 添加触发器到用户表
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 创建索引以提高查询性能
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
```

