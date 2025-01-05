---
title: PostgreSQL COnfiguration
date: 2024-12-27 17:51:35
tags:
 - database
 - postgres
---

安装

```bash
$ brew install postgresql@15
$ brew services start postgresql@15
```

登录

```bash
$ psql postgres
psql (15.10 (Homebrew))
Type "help" for help.

postgres=# SELECT current_user;
 current_user
--------------
 david
(1 row)

postgres=# ALTER USER current_user WITH PASSWORD '778899';
ALTER ROLE

postgres=# \c skymates ;
You are now connected to database "skymates" as user "david"

skymates=# \d users
                                  Table "public.users"
     Column      |           Type           | Collation | Nullable |      Default
-----------------+--------------------------+-----------+----------+--------------------
 id              | uuid                     |           | not null | uuid_generate_v4()
 username        | character varying(50)    |           | not null |
 hashed_password | character varying(100)   |           | not null |
 email           | character varying(255)   |           | not null |
 avatar_url      | text                     |           |          |
 created_at      | timestamp with time zone |           |          | CURRENT_TIMESTAMP
 updated_at      | timestamp with time zone |           |          | CURRENT_TIMESTAMP
Indexes:
    "users_pkey" PRIMARY KEY, btree (id)
    "users_email_key" UNIQUE CONSTRAINT, btree (email)
    "users_username_key" UNIQUE CONSTRAINT, btree (username)
Triggers:
    handle_users_update BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION triggers.handle_record_update()
```

>PostgreSQL 安装后会自动创建一个名为 `postgres` 的数据库, 所以 `psql postgres` 的意思是连接到 `postgres` 数据库 
>
>默认情况下, PostgreSQL 使用当前系统用户的名称作为数据库用户名, 且不需要密码, 你可以给他添加一个密码, 之后登录`psql -U david -d your-database`
>
>所以当你输入 `psql postgres`, 默认用户是 `david`, 数据库就是你指定的  `postgres`, 所在的 schema 默认是 `public`

-----

常用命令

```postgresql
\l          	  -- 列出所有数据库
\du             -- 列出所有用户
\dt             -- 列出当前数据库的所有表
\d table_name   -- 显示表结构


-- 查看当前用户
SELECT current_user;
-- 切换用户
SET ROLE new_username;

-- 创建数据库
CREATE DATABASE mydb;
-- 查看当前数据库
SELECT current_database();
-- 切换数据库
\c database_name
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

-----------

创建表

```sql
-- 1. 首先创建一个专门管理触发器的 schema
CREATE SCHEMA IF NOT EXISTS triggers;

-- 2. 创建一个通用的触发器函数，它可以处理多个操作
CREATE OR REPLACE FUNCTION triggers.handle_record_update()
RETURNS TRIGGER AS $$
BEGIN
    -- 1. 更新 updated_at 时间戳
    NEW.updated_at = CURRENT_TIMESTAMP;
    
    -- 2. 这里可以添加其他的更新操作
    -- 例如：记录修改历史
    -- INSERT INTO audit_logs (table_name, record_id, changed_at, old_data, new_data)
    -- VALUES (TG_TABLE_NAME, NEW.id, CURRENT_TIMESTAMP, row_to_json(OLD), row_to_json(NEW));
    
    -- 3. 未来可以在这里添加更多的操作
    -- 比如：发送通知、更新缓存、触发其他表的更新等
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 3. 如果需要 UUID 支持，首先确保启用 uuid-ossp 扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 4. 创建用户表
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) NOT NULL UNIQUE,
    hashed_password VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. 为表添加触发器
CREATE TRIGGER handle_users_update
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION triggers.handle_record_update();
```

```postgresql
-- 验证
\d users
```

