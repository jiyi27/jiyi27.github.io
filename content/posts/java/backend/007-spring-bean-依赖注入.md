---
title: Spring Bean 和依赖注入
date: 2025-02-16 12:49:20
categories:
 - spring boot
tags:
 - spring boot
 - bugs
 - 零碎知识
---

## 1. Spring Bean

写配置代码的时候注意到 `SecurityConfig` 类由 `@Configuration` 修饰, 它的方法都是由 `@Bean` 修饰, 我们来研究一下

`@Bean` 注解是 Spring 框架中的一个注解, 它用于在 Java 配置类（即标注了 `@Configuration` 的类）中定义 Spring 容器管理的 Bean, **将方法的返回实例对象注册为 Spring 容器的 Bean**, 类似 `@Component`、`@Service`、`@Repository` 等注解, 他们都是用来把类的实例对象注册为 Spring Bean, 以下是一些关键点:

- Java 配置类: 通常使用 `@Configuration` 注解标注, 包含一个或多个 `@Bean` 方法
- `@Bean` 注解: 用于将方法的返回值注册为 Spring 容器的 Bean

- `@Component`、`@Service`、`@Repository` 等注解通常用于类级别, 自动检测和注册 Bean, 而 `@Bean` 则用于方法级别, 提供了更细粒度的控制

如果某个类不是你定义的, 不能直接用 `@Component` 进行注入 (因为是类级别), 可以写个方法返回该类的实例, 然后使用 `@Bean` 将该方法的返回值自动注册为 Bean, 

比如 `UserDetailsService` 和 `PasswordEncoder` 都不是我们定义的, 而是 Spring Security 定义的接口, 而 `@Component` `@Service` 这种注解一般都是定义某个类的时候加上去的, 所以我们只能写个方法, 返回 `UserDetailsService` 和 `PasswordEncoder` 类型的对象, 然后把这个方法标注为 `@Bean`

## 2. 实际例子

假设你有一个简单的 Spring Boot 应用程序, 结构如下:

```
com.example.demo
│
├── DemoApplication.java
├── service
│   └── MyService.java
└── repository
    └── MyRepository.java
```

`DemoApplication.java`

```java
package com.example.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class DemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }
}
```

- `@SpringBootApplication` 注解会自动启用组件扫描, 默认扫描 ⁠`com.example.demo` 包及其子包

`MyService.java`

```java
package com.example.demo.service;

import org.springframework.stereotype.Service;

@Service
public class MyService {
    public void doSomething() {
        System.out.println("Service is doing something.");
    }
}
```

- `⁠@Service` 注解表明 ⁠`MyService` 是一个服务层组件，`Spring` 会自动创建其实例并注册为 `Bean`

`⁠MyRepository.java`

```java
package com.example.demo.repository;

import org.springframework.stereotype.Repository;

@Repository
public class MyRepository {
    public void save() {
        System.out.println("Data saved.");
    }
}
```

- `⁠@Repository` 注解表明 ⁠`MyRepository` 是一个数据访问层组件，Spring 会自动创建其实例并注册为 Bean

**工作机制**

- **组件扫描**：当应用程序启动时，Spring 会扫描 ⁠`com.example.demo` 包及其子包, 寻找标注了 ⁠`@Component`, `@Service`, `@Repository`, `⁠@Controller` 等注解的类

- **Bean 注册**：Spring 自动创建这些类的实例, 并将它们注册到应用程序上下文中

- **依赖注入**：在需要使用这些 Bean 的地方, Spring 会自动注入它们, 例如, 在另一个类中可以通过 ⁠`@Autowired` 注解注入 ⁠`MyService` 和 ⁠`MyRepository`

