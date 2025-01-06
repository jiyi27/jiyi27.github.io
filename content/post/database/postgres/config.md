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

创建用户表和启动基础拓展:

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

验证:

```postgresql
\d users
```

创建术语相关表:

```postgresql
-- 上面已经启用 UUID 扩展, 这里不用执行
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 术语类别表
CREATE TABLE term_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) NOT NULL UNIQUE,
    parent_id UUID DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 专业术语表
CREATE TABLE terms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    term VARCHAR(100) NOT NULL UNIQUE,  -- UNIQUE 会自动创建唯一索引
    text_explanation TEXT,
    video_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 术语-类别关系表
CREATE TABLE term_category_relations (
    term_id UUID NOT NULL,
    category_id UUID NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (term_id, category_id),
    FOREIGN KEY (term_id) REFERENCES terms(id),
    FOREIGN KEY (category_id) REFERENCES term_categories(id)
);

-- 为 terms 表创建更新时间触发器, triggers.handle_record_update() 在创建 users 表时创建的
CREATE TRIGGER handle_terms_update
    BEFORE UPDATE ON terms
    FOR EACH ROW
    EXECUTE FUNCTION triggers.handle_record_update();

-- 因为 UNIQUE 会自动创建唯一索引, 我们不用单独为 terms 表在 term 列创建 index
-- CREATE INDEX idx_terms_term ON terms(term);
-- 只用为 term_category_relations 创建组合索引
CREATE INDEX idx_term_category_relations_category_term 
    ON term_category_relations(category_id, term_id);
```

验证:

```postgresql
skymates=# \d
                List of relations
 Schema |          Name           | Type  | Owner
--------+-------------------------+-------+-------
 public | term_categories         | table | david
 public | term_category_relations | table | david
 public | terms                   | table | david
 public | users                   | table | david
(4 rows)

-- 查看具体某个表的详细结构（包含索引、触发器等）
\d+ terms
\d+ term_categories
\d+ term_category_relations
```

解释:

```mysql
-- 术语类别表
CREATE TABLE term_categories (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '类别ID，主键',
    name VARCHAR(50) NOT NULL UNIQUE COMMENT '类别名称',
    description TEXT COMMENT '类别描述',
    parent_id BIGINT DEFAULT 0 COMMENT '父类别ID，0表示顶级类别',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间'
);
-- 专业术语表
CREATE TABLE terms (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '术语ID，主键',
    term VARCHAR(100) NOT NULL UNIQUE COMMENT '术语名称',
    text_explanation TEXT COMMENT '文本解释',
    video_url VARCHAR(500) COMMENT '视频URL',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_term (term) COMMENT '术语名称索引，提高搜索效率'
);
-- 术语-类别关系表
CREATE TABLE term_category_relations (
    term_id BIGINT NOT NULL COMMENT '术语ID，外键',
    category_id BIGINT NOT NULL COMMENT '类别ID，外键',
    PRIMARY KEY (term_id, category_id) COMMENT '联合主键，确保关系唯一',
    FOREIGN KEY (term_id) REFERENCES terms(id) COMMENT '外键关联到术语表',
    FOREIGN KEY (category_id) REFERENCES term_categories(id) COMMENT '外键关联到类别表',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX idx_category_term (category_id, term_id) COMMENT '类别ID和术语ID的组合索引'
);
```

**term_category_relations 的作用是什么?** 

术语-类别关系表(term_category_relations)的主要作用是实现术语和类别之间的多对多(many-to-many)关系映射, 因为:

1. 一个术语可以属于多个类别
2. 一个类别可以包含多个术语

如果没有这个关系表:

1. 如果在terms表中直接添加category_id字段,一个术语就只能属于一个类别
2. 如果在terms表中存储多个category_id,会违反数据库设计范式,不利于数据维护和扩展

通过这个关系表,我们可以:

1. 灵活地管理术语和类别之间的对应关系
2. 方便地查询某个术语属于哪些类别
3. 方便地查询某个类别下包含哪些术语
4. 维护数据的一致性(通过外键约束)

**INDEX idx_category_term 的作用是什么, 有必要建立组合索引吗?** 

idx_category_term 组合索引的作用是优化按类别查询术语的场景, 

```mysql
INDEX idx_category_term (category_id, term_id)
```

注意顺序先后, category_id 在前, term_id 在后, 也就是说建立了组合索引后, 所有数据, 会分块存储, 即所有 category_id 相同的 term_id 会在一块, 比如:

```mysql
001 jkys
001 rrjso
001 jsjksj
002 sjss
002 kio
...
```

而不是乱序排放, 这样每次, 我们查询某个类别下的所有名词的 id, 直接就能获得了, 而不是遍历整个 term_category_relations 表, 

我们一般查询某个类别下的所有术语, 执行一下语句:

```mysql
-- 查询数据库类别下的所有术语
SELECT t.term
FROM term_category_relations r
JOIN terms t ON r.term_id = t.id
WHERE r.category_id = 001;
```

查询步骤是 先去 term_category_relations 拿到所有 category_id = 001 的数据, 然后获取其 term_id (每行数据都有一个 term_id), 然后拿着 term_id 去 terms 表中查询所有名词术语, 

