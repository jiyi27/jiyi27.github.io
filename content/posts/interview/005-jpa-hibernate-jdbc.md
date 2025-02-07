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

1. **JPA（Java Persistence API）**：它是 Java 官方定义的一个**ORM 规范（或接口标准）**，而不是一个具体的实现。换言之，JPA 相当于规定了“如何将 Java 对象与数据库表映射和交互”的一套接口和注解体系，但它自己并不提供具体的底层代码去完成这件事。
2. **JPA 的实现**：要想让 JPA 的接口和注解真的“跑起来”，就需要有一个具体的实现类库（provider）。常见的 JPA 实现有：
   - **Hibernate**（最常见、最流行的 JPA 实现）
   - **OpenJPA**（Apache 的实现）
3. **Spring Data JPA 与 JPA**：Spring Data JPA 不是一个独立的 JPA 实现，而是对 JPA 规范进行了一层更高级的封装，让我们用更少的代码、更简单的配置，就能完成数据库的 CRUD 操作。但它在底层依赖的仍然是这些“JPA 实现”之一（最常见就是 Hibernate）。

## 3. MyBatis

MyBatis 是一款半 ORM / 数据映射（Data Mapper）框架，与传统的 JDBC 相比更灵活且简化了数据访问的过程，但不像 Hibernate 那样做全量的实体与表的自动映射。

本质上还是你在 XML 或注解中编写 SQL，然后 MyBatis 帮你做参数注入、结果映射等工作。

MyBatis 并不实现 JPA 规范，因此 Spring Data JPA 不会用 MyBatis 作为 JPA provider。

> 注意 JPA 和 Spring JPA 并不是一个东西
>
> Under the hood, Hibernate and most other providers for JPA write SQL and use JDBC API to read and write from and to the DB. Simply think, JPA is a Java ORM, and Hibernate implements JPA using JDBC API. [java - JPA or JDBC, how are they different? - Stack Overflow](https://stackoverflow.com/questions/11881548/jpa-or-jdbc-how-are-they-different)

## 4. Hibernate、MyBatis、Spring Data JPA 和 JPA 的对比

**Hibernate**：既是单独的 ORM 框架，也是最常用的 JPA 实现之一。

**MyBatis**：非 JPA 实现，写 SQL 较多，灵活。

**Spring Data JPA**：基于 JPA 规范之上的高级抽象和封装，底层还要用 Hibernate/EclipseLink 来执行。

**JPA**：只是一套接口规范，没有实际功能实现，必须搭配“实现”才能使用。

## 5. 哪些属于“接口”？哪些属于“注解”？

**接口/类**

- JPA 规范：`EntityManager`, `EntityManagerFactory`, `Query` 等
- Hibernate：`Session`, `SessionFactory`, `Configuration` 等
- Spring Data JPA：`JpaRepository`, `CrudRepository`, `JpaSpecificationExecutor` 等

上述这些通常是你在写业务层（或持久层）代码时 **“调用”** 或 **“继承”** 的对象/接口。

**注解**

- JPA 规范注解：`@Entity`, `@Table`, `@Id`, `@Column`, `@OneToMany` 等
- Hibernate 专有注解：`@Type`, `@GenericGenerator`, `@BatchSize` 等
- Spring Data JPA 常用注解：`@EnableJpaRepositories`, `@Query`, `@Modifying` 等（当然，Spring 的 `@Autowired`, `@Repository` 等也经常配合使用）

> JPA 规范注解通常比较通用，例如 `@Entity`、`@Id`、`@Column`、`@GeneratedValue`、`@NamedQuery` 等，你在任何 JPA 实现（Hibernate、EclipseLink、OpenJPA）里都能用。
>
> Hibernate 专有注解通常会涉及自定义类型、缓存策略、特定的主键生成策略等。
>
> Spring Data JPA 的注解大多是为了让 Spring 容器去识别 Repository 接口或方法（比如 `@Query`），以及通过“约定优于配置”来帮助自动生成实现类。

## 6. 总结

- **JPA**：一套接口和注解标准（`javax.persistence` 或 `jakarta.persistence`），没有真正的实现，需要一个“JPA Provider”去执行实际的数据库交互。
- **Hibernate**：最常见的 JPA 实现（`org.hibernate.*`）。既能实现 JPA 规范，也提供很多额外的高级特性（缓存、批量处理、自定义类型等）。
- **Spring Data JPA**：在 JPA 之上做了进一步的封装（`org.springframework.data.jpa.*`），通过 Repository 接口、方法命名约定、自动生成实现等方式，极大减少了样板代码。但底层依旧要依赖 Hibernate/EclipseLink 等某种 JPA 实现来真正操作数据库。
- **如何区分**：**看包名**是最直接、最有效的方式；然后再看所用的注解或接口是否是规范性（JPA 通用）还是实现方（Hibernate / Spring Data）提供的扩展。

**示例**（标准 JPA 实体）：

```java
import javax.persistence.Entity;
import javax.persistence.Table;
import javax.persistence.Id;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Column;

@Entity
@Table(name = "users")  // 标准的 JPA 注解
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "username", nullable = false)
    private String username;

    // ... getters/setters ...
}
```

> **特点**：所有注解都来自 `javax.persistence.*`，这是纯粹的 JPA 规范写法。

**示例**（Spring Data JPA repository）：

```java
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface UserRepository extends JpaRepository<User, Long> {

    // 基于方法名解析，自动生成 SQL
    User findByUsername(String username);

    // 自定义查询
    @Query("SELECT u FROM User u WHERE u.username = ?1 AND u.active = true")
    User findActiveUserByUsername(String username);
}
```

> **特点**：
>
> - 继承了 `JpaRepository`（属于 `org.springframework.data.jpa.repository` 包）
> - 使用了 `@Query`（也在同一个包里）
> - 一般和 `@EnableJpaRepositories` 联合使用，Spring 会自动生成实现类并注入到容器中。

**示例**（Hibernate 专有的注解）：

```java
import org.hibernate.annotations.GenericGenerator;
import org.hibernate.annotations.Type;

@Entity
@Table(name = "products")
public class Product {

    @Id
    @GenericGenerator(name = "uuid-gen", strategy = "uuid2")
    @GeneratedValue(generator = "uuid-gen")
    private String id;

    @Type(type = "org.hibernate.type.TextType")
    private String description;

    // ...
}
```

> **特点**：虽然它依旧是一个 JPA 实体类，但使用了 `org.hibernate.annotations.*` 下的注解（`@GenericGenerator`, `@Type` 等），这些就是 **Hibernate 专有** 的功能。

因此，当你看到一个类或者注解时，先看一下它是从哪个包引入（import）的，基本就能确定它属于 JPA、Hibernate，还是 Spring Data JPA。这样也就能搞清楚某段代码是用来做“通用的持久化管理”（JPA），还是用来做“特定实现的高级特性”（Hibernate），亦或是“自动生成 Repository 接口实现”（Spring Data JPA）了。

## 7. 疑问

### 7.1. 是否可以“混用”不同注解？

还有个疑问, 就是这些来自 JPA 的注解, Spring JPA 的注解, 以及 Hibernate 的注解 和 他们的接口, 他们是可以互通的吗?  比如一个类或者一个方法上可以使用多个来自不同的注解? 

在实际开发中，**JPA、Hibernate、Spring Data JPA** 这三者之间的注解、接口确实可能会“混用”在同一个实体类或 Repository 接口里。

- **JPA 注解**：最基础、最通用，如 `@Entity`、`@Table`、`@Id` 等，任何 JPA Provider（Hibernate、EclipseLink 等）都能识别。
- **Hibernate 注解**：在实现 JPA 规范的同时，Hibernate 提供了一些特有的增强功能注解，比如 `@Type`, `@GenericGenerator`, `@BatchSize` 等。
- **Spring Data JPA 注解**：主要在 Repository 层（如 `@Query`, `@Modifying`）或配置层（如 `@EnableJpaRepositories`），用来配合 Spring 生态简化 CRUD。

```java
import javax.persistence.Entity;
import javax.persistence.Table;
import javax.persistence.Id;
import org.hibernate.annotations.GenericGenerator;

@Entity
@Table(name = "products")
public class Product {

    @Id
    @GenericGenerator(name = "uuid-gen", strategy = "uuid2")
    // ↑ 这里是 Hibernate 特有的主键生成策略
    private String id;

    // 其他字段省略 ...
}
```

`@Entity`、`@Table` 属于 **JPA 标准**，告诉任何 JPA Provider“这是一个实体”。

`@GenericGenerator` 属于 **Hibernate** 专有，用来指定主键生成策略。

这两种注解可以在同一个类中共存，**前提是**，底层你的 JPA Provider 选择的是 Hibernate，那么它能理解并执行 `@GenericGenerator` 的逻辑。

> **注意:** 如果将来你**切换**到 EclipseLink、OpenJPA 做底层实现，JPA 注解依然通用，但 `@GenericGenerator` 这种 **Hibernate 专属** 的功能就不会被新的实现识别。

### 7.2. Spring Data JPA 的注解能否与 JPA / Hibernate 注解并存？

也可以。一般来说，**Spring Data JPA 的注解**（如 `@Query`, `@Modifying` 等）是用在 **Repository 接口或方法上**，跟实体类注解（JPA/Hibernate）其实处于不同的“层次”：

```java
// 实体层（JPA 或 Hibernate 注解）
@Entity
@Table(name = "users")
public class User {
   @Id
   private Long id;
   // ...
}

// Repository 层（Spring Data JPA 注解）
public interface UserRepository extends JpaRepository<User, Long> {

    // 方法名解析
    User findByUsername(String username);

    // 自定义查询
    @Query("SELECT u FROM User u WHERE u.username = ?1")
    User findUserByUsername(String username);

    @Modifying
    @Query("UPDATE User u SET u.active = false WHERE u.username = ?1")
    int deactivateUser(String username);
}
```

这样一来，**实体类上**的注解大多属于 **JPA 规范**（可能也带一点 Hibernate 特有的注解），

**Repository 上**的注解属于 **Spring Data JPA**，它用来告诉 Spring 如何自动生成具体的持久化方法、或者如何执行自定义查询。

有时也会出现这种场景，比如你写了一个字段，既有 `@Column`（JPA 注解）指定数据库列信息，又有 `@Type`（Hibernate 注解）指定特定的映射类型，这在底层只要由 Hibernate 来运行，也是**允许**的。不同注解解析不同的功能点，大多情况下并不会互相冲突，**只要你明白这些注解各自负责什么即可**。

### 7.3. 这些注解、接口“互通”的实质含义

1. **JPA 注解**本质上是“通用协议”，告诉所有符合 JPA 规范的实现如何映射实体。
2. **Hibernate 注解**则是对这个“通用协议”的一个**专有扩展**，只有在使用 Hibernate 做 Provider 时，Hibernate 自己才能理解并执行；换成其他实现，就会被忽略或导致异常（如果该注解是强绑定特性）。
3. **Spring Data JPA 注解**主要是为了**简化业务层**或**简化配置**，与实体映射本身关系不大，但它的核心还是依赖 JPA（大多数情况下依赖 Hibernate）来真正执行数据库操作。

因此，从技术栈角度看，它们确实是在同一个“生态体系”下工作：

- Spring Data JPA 提供了便捷的 Repository 接口
- 底层还是要通过 JPA Provider（通常是 Hibernate）进行实体到数据库的操作
- JPA Provider 要么只认通用 JPA 注解，要么也会识别自己专有的扩展注解

他们“互通”不代表注解可以**替代**对方，而是指可以在同一个项目中共存、互相配合。例如：

- 你用 **JPA** 注解（`@Entity`、`@Id` 等）来定义实体的基本映射
- 需要 **Hibernate** 的特殊能力时，再额外加一些 `@org.hibernate.annotations.*` 的注解
- 在 **Spring Data JPA** 里的 Repository 层，用 `@Query`, `@Modifying` 等注解来实现特定的数据库操作逻辑

### 7.4. 需要注意的点

**避免使用过多专有注解**
如果你希望自己的代码尽量“可移植”，就尽量只用 JPA 标准注解。**Hibernate 专有**的注解能解决某些高级场景，但会让你的代码更依赖 Hibernate。如果项目没有强烈需要，就不要过度使用。

**冲突或覆盖问题**
大多数情况下，JPA 和 Hibernate 注解不会冲突，因为Hibernate 本身实现了JPA，而且两者的注解大多做的是不同维度的事情。

- 例如 `@Column(name="xxx")` 来定义列名是 JPA 基础映射；
- `@Type(type="...")` 是 Hibernate 特有的自定义类型映射。
  只有在出现“同一个配置由多个注解分别定义且含义冲突”时，才可能导致奇怪的问题。

**Spring Data JPA 注解主要针对 Repository**

- Spring Data JPA 的 `@Query`, `@Modifying` 等注解是给**接口方法**用的；
- 像 `@EnableJpaRepositories` 是给**配置类**或**启动类**用的；
- 它们基本不会跟 JPA/Hibernate 注解写在同一个地方，所以不太会有冲突问题。

**项目结构与分层**

- 你的 **实体类**（domain/model 层）可能主要写 **JPA** + **Hibernate**(可选)注解；
- **数据访问层**（repository/dao 层）则使用 **Spring Data JPA** 的接口和注解；
- 三者各司其职，互相协作。

