---
title: JDBC, JPA, ORM Hibernate
date: 2025-02-06 23:15:20
categories:
 - 面试
tags:
 - 面试
 - java
---

## 1. JDBC vs MySQL Connector

> JDBC（Java Database Connectivity）是 Java 访问数据库的最底层标准规范和 API。它提供了连接数据库、执行 SQL、获取结果集等核心功能。
>
> 后面提到的 MyBatis、Hibernate、Spring Data JPA 都是基于 JDBC 来执行底层 SQL 操作的。
>
> 可以直接编写 SQL、使用 `PreparedStatement` 等 API 来执行操作。

Sometimes, I always mistake MySQL driver for JDBC, a little funny, lol. JDBC is part of JDK, which is java's standard library, like code below`java.sql.*` belongs to **Java SE API**, which is also called **JDBC API**. 

We often add `com.mysql.cj.jdbc.Driver` dependency to our maven project. Actually `com.mysql.cj.jdbc.Driver` is **MySQL Connector**. 

```java
package database;

// java.sql.* 属于 Java SE API, 这就是 JDBC API
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class MysqlDatabase {
    @Override
    public Connection connect() throws SQLException {
        // You must load jdbc driver, otherwise you will get null for connection.
        Class.forName("com.mysql.cj.jdbc.Driver");
        return DriverManager.getConnection(this.url, this.user, this.password);
    }
}
```

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2025/02/79dc888c7c722f47ead990dff67223ee.png)

As shown above `java.sql.SQLException` and `java.sql.Connection` are all belong to `java.sql.*` which is part of **java se api**, namely, **JDBC**. So we don't commucate with MySQL database with **MySQL Connector** directly, actually, we conmmucate with MySQL(retrive & insert data) by "talking" to JDBC API, then JDBC API commucate with **MySQL Connector**, and MySQL Connector commucate with MySQL database. 

## 2. JPA 是什么

1. JPA（Java Persistence API）：JPA 规定了“如何将 Java 对象与数据库表映射和交互”的**一套接口和注解体系**，但它自己并不提供具体的底层代码去完成这件事
2. JPA 的实现：要想让 JPA 的接口和注解真的“跑起来”，就需要有一个具体的实现类库（provider）。常见的 JPA 实现有：
   - Hibernate（最常见、最流行的 JPA 实现）
   - OpenJPA（Apache 的实现）
3. Spring Data JPA 与 JPA：Spring Data JPA 不是一个独立的 JPA 实现，而是对 JPA 规范进行了一层更高级的封装，让我们用更少的代码、更简单的配置，就能完成数据库的 CRUD 操作。但它在底层依赖的仍然是这些“JPA 实现”之一（最常见就是 Hibernate）

```java
import jakarta.persistence.*;

@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(unique = true, nullable = false)
    private String email;

    // Getters and Setters...
}
```

这里 `@Entity` 和 `@Table` 是 JPA 规范的一部分，它们只是 **告诉 JPA Provider（比如 Hibernate）**，这个类需要映射到数据库表。但真正解析这些注解并生成 SQL 语句的是 Hibernate。

Hibernate 在运行时生成的 SQL:

```sql
CREATE TABLE users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL
);
```

你写的是 JPA 代码，但实际 SQL 是 Hibernate 生成的。**JPA 只定义规则，Hibernate 负责执行。**

> 所有注解都来自 `javax.persistence.*`, 这是纯粹的 JPA 规范写法

## 3. Spring Data JPA + JPA + Hibernate

```java
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
}
```

这里 `findByEmail(String email)` 方法没有实现，为什么它还能执行数据库查询呢？这是 **Spring Data JPA + JPA + Hibernate** 三者协作的结果。

当你调用：

```java
Optional<User> user = userRepository.findByEmail("test@example.com");
```

Spring Data JPA、JPA（EntityManager）和 Hibernate 会分别执行自己的工作：

**1️⃣ Spring Data JPA（提供 Repository 代理）**

Spring Data JPA 看到 `UserRepository` 继承了 `JpaRepository`，就会：

- 自动生成 `findByEmail` 方法的实现
- 调用 JPA 的 `EntityManager` API 进行查询

📌 这里的关键点：

- 你没有手写 SQL，但 Spring Data JPA 根据方法名 解析出查询意图
- 它会调用 JPA（EntityManager） 来执行查询

**2️⃣ JPA（EntityManager 提供查询 API）**

Spring Data JPA 内部会使用 JPA 的 `EntityManager` 执行查询：

```java
entityManager.createQuery("SELECT u FROM User u WHERE u.email = :email", User.class);
```

📌 JPA（EntityManager）在这里的角色：

- 提供 API 让 Spring Data JPA 调用（比如 `createQuery()`）
- 不会解析和执行 SQL，它只是 JPA 标准的实现者

**3️⃣ Hibernate（JPA Provider 解析 & 执行 SQL）**

Hibernate 作为 JPA Provider，接手 `EntityManager` 提供的查询请求，并执行 SQL：

- 解析 JPQL：

  ```sql
  SELECT u FROM User u WHERE u.email = :email
  ```

- 转换成原生 SQL（针对 MySQL、PostgreSQL 等数据库生成 SQL）：

  ```sql
  SELECT * FROM users WHERE email = 'test@example.com' LIMIT 1;
  ```

- 执行 SQL，从数据库查询结果，并返回 `User` 实例。

📌 Hibernate 负责的部分：

- 解析 JPA 的查询语法（JPQL）
- 生成 SQL 并执行
- 把数据库查询结果转换成 Java 对象

**完整流程总结**

| **步骤** | **执行者**               | **作用**                                      |
| -------- | ------------------------ | --------------------------------------------- |
| **1**    | **Spring Data JPA**      | 解析 `findByEmail` 方法，调用 `EntityManager` |
| **2**    | **JPA（EntityManager）** | 负责 API 调用，准备 JPQL 查询                 |
| **3**    | **Hibernate**            | 解析 JPQL，转换为 SQL，并执行查询             |
| **4**    | **数据库**               | 运行 SQL，返回数据                            |
| **5**    | **Hibernate**            | 解析 SQL 结果，转换成 `User` 对象             |
| **6**    | **Spring Data JPA**      | 返回 `User` 对象给调用者                      |

**总结**

- Spring Data JPA 让你不用手写 SQL，直接调用 `JpaRepository` 方法
- JPA（EntityManager） 只是提供 API，不会执行 SQL
- Hibernate 作为 JPA Provider，负责执行 SQL，并转换结果

💡 **最终的 SQL 查询是 Hibernate 负责执行的**，Spring Data JPA 和 JPA 只是提供 API 和接口，真正的数据库操作全靠 Hibernate。

## 4. MyBatis

MyBatis 是一款半 ORM / 数据映射（Data Mapper）框架，与传统的 JDBC 相比更灵活且简化了数据访问的过程，但不像 Hibernate 那样做全量的实体与表的自动映射。

本质上还是你在 XML 或注解中编写 SQL，然后 MyBatis 帮你做参数注入、结果映射等工作。

MyBatis 并不实现 JPA 规范，因此 Spring Data JPA 不会用 MyBatis 作为 JPA provider。

> 注意 JPA 和 Spring JPA 并不是一个东西
>
> Under the hood, Hibernate and most other providers for JPA write SQL and use JDBC API to read and write from and to the DB. Simply think, JPA is a Java ORM, and Hibernate implements JPA using JDBC API. [java - JPA or JDBC, how are they different? - Stack Overflow](https://stackoverflow.com/questions/11881548/jpa-or-jdbc-how-are-they-different)

## 5. 总结

| 组件                | 主要职责                                   | 作用层                            |
| ------------------- | ------------------------------------------ | --------------------------------- |
| **JPA**             | 定义标准 API，声明 Entity、关系映射        | **Model 层**（数据对象定义）      |
| **Hibernate**       | 实现 JPA 规范，处理 SQL 生成、缓存、事务等 | **持久化层**（数据库交互底层）    |
| **Spring Data JPA** | 提供 `JpaRepository` 等工具，简化 DAO 访问 | **Repository 层**（数据访问接口） |

**JPA（Model 层）：**

```java
import jakarta.persistence.*;

@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(unique = true, nullable = false)
    private String email;

    // Getters and Setters...
}
```

> - `@Entity`：标明该类是 JPA 实体
> - `@Table(name = "users")`：指定数据库表名
> - `@Id`、`@GeneratedValue`：定义主键及其生成策略
> - `@Column`：指定字段约束

**Spring Data JPA（Repository 层）**

Spring Data JPA 让我们可以不写 SQL 也能操作数据库：

```java
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
}
```

> - `JpaRepository<User, Long>`：提供了 CRUD 方法
>- `findByEmail(String email)`：Spring Data JPA 会自动生成查询 SQL

**Hibernate（持久化层）**

Hibernate 作为 JPA Provider，在后台实际执行 SQL 语句, 当我们调用 `userRepository.findByEmail("test@example.com")` 时，Hibernate 会生成 SQL 查询：

```java
SELECT * FROM users WHERE email = 'test@example.com' LIMIT 1;
```

