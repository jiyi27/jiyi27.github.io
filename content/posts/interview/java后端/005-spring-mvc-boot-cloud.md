---
title: Spring MVC, Spring Boot, Spring Cloud 区别和联系
date: 2025-03-04 08:32:22
categories:
 - 面试
tags:
 - 面试
 - java后端面试
---

## 1. Spring Boot 依赖管理

```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.1.2</version>  <!-- 这里指定 Spring Boot 版本 -->
</parent>

<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
    </dependency>
</dependencies>
```

当你在使用 Spring Boot 开发项目时, 通常会在 ⁠pom.xml 文件中指定一个父 POM, 上面我们的代码 `<parent>...</parent>` 就是干的这个事的, 

可以发现我们不用指定 `spring-boot-starter-security` 的版本, 就是因为我们引入了 Spring Boot 的父 POM, 而它又继承了`spring-boot-dependencies` 这个 BOM, 在这个 BOM 文件中, Spring Boot 定义了所有核心组件的版本号, 比如 Spring Security、Spring MVC、Spring Data, 

所以当我们添加一个 Spring Boot 的核心组件, 比如:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
```

并不需要写 `<version>`, 因为 `spring-boot-dependencies` 已经预先定义了与 Spring Boot 3.1.2 兼容的 Spring Security 版本(比如 6.2.1), Maven 会自动从父 POM 中读取这些版本号,

即使你不继承 ⁠spring-boot-starter-parent, 你仍然可以通过导入 ⁠spring-boot-dependencies BOM 来管理依赖版本:

```xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-dependencies</artifactId>
            <version>3.0.0</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>

<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
</dependencies>
```

在这个例子中，我们通过 ⁠`dependencyManagement` 导入了 ⁠spring-boot-dependencies，这使得我们可以在 ⁠dependencies 中添加 ⁠spring-boot-starter-web 时不需要指定版本号，因为版本已经在 BOM 中定义好了。

> `<dependencyManagement>...</dependencyManagement>` 和 `<parent>...</parent>` 分别用来导入 BOM 和 POM, 他们两个导入一个就行了, Spring Boot BOM 被 Spring Boot POM 继承, 所以导入后者的目的也是导入前者, 
>
> `spring-boot-dependencies` 是一个巨大的依赖清单, 里面列出了所有 Spring Boot 生态中**常用依赖**的版本, 当 Maven 解析 `pom.xml` 时, 它会优先使用父 POM 中定义的版本号, 这样就避免了加入新的组件时手动指定版本的麻烦, 也保证了所有组件的兼容性, 

一般组件 artifactId 为 `spring-boot-starter-xxx` 格式, 都是 Spring Boot 核心组件, 不用再刻意指定版本号了, 而其他的组件仍需要指定, 比如:

```xml
<!-- MySQL 数据库驱动 -->
<dependency>
    <groupId>mysql</groupId>
    <artifactId>mysql-connector-java</artifactId>
    <version>8.0.33</version> <!-- 确保这里是最新版本 -->
</dependency>

<!-- Lombok 在 编译时 生成 getter/setter，但 运行时不需要 Lombok 依赖，所以 provided 是合适的 -->
<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <version>1.18.36</version>
    <scope>provided</scope>
</dependency>
```

## 2. Spring Cloud 依赖管理

Spring Cloud 建立在 Spring Boot 之上, 但特殊的地方是它也有自己的组件, 与 Spring Boot 类似, 需要引入 `spring-cloud-dependencies` 进行版本管理, `spring-cloud-dependencies` 是一个独立的 BOM 文件, 里面定义了 Spring Cloud 所有组件（比如 Eureka、Feign、Config Server 等）的版本号。

当我们同时使用 Spring Boot 和 Spring Cloud 的时候, 大致的 `pom.xml` 文件:

```xml
<!-- 使用 Spring Boot 父 POM -->
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.4.3</version>
    <relativePath/> <!-- lookup parent from repository -->
</parent>

<!-- 引入 Spring Cloud BOM 来统一管理 Spring Cloud 相关组件的版本 -->
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-dependencies</artifactId>
            <version>2024.0.0</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>

<dependencies>
    <!-- Spring Boot Web 依赖 -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>

    <!-- Spring Cloud Config，用于集中化配置管理 -->
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-config</artifactId>
    </dependency>

    <!-- Spring Cloud Netflix Eureka Client，用于服务注册与发现 -->
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
    </dependency>

    <!-- 根据需要还可以添加其他 Spring Cloud 或 Spring Boot 组件 -->
</dependencies>
```

> 当我们说使用 Spring Boot 和 Spring Cloud 的时候, 使用的并不是他们本身, 而是他们的核心组件
>
> Spring Boot 管理自己的核心组件（Spring Security、Spring Data、Spring Web 等
> Spring Boot 不管理 Spring Cloud 相关组件（Eureka、Feign、Gateway、Sleuth 等

## 3. 总结

上面我们讨论了 Spring Boot 和 Spring Cloud 在配置依赖方面的区别和联系, 显然 Spring Cloud 是一个单独的框架, 有自己的组件, 我们可以在 Spring Boot 中使用 Spring Cloud, 但是 Spring Boot 的 BOM 只是管理了它自己核心组件的版本, 并不会管理 Spring Cloud 核心组件, 因此我们在使用他们两个的时候, 同时在 `pom.xml` 指定各自的 BOM 才是最佳实践, 方便他们各自管理各自组件的版本, 

所以 Spring Boot 本质就是构建于 Spring MVC 之上基于 Spring 生态的“快速开发框架”, 它帮我们集成了 Spring MVC 所有的基础配置, 包括 Servlet 路径, 视图, 以及 Servlet 容器 Tomcat, 除此之外还提前定义了 Spring 核心组件的依赖版本, 我们只要在 `pom.xml` 引入了 `<parent>...</parent>`, 当我们使用一些依赖比如 Spring Security, Spring Data JPA 等, 直接加到 `pom.xml` 中就行, 不用指定版本号或者担心以后更新引起版本冲突

