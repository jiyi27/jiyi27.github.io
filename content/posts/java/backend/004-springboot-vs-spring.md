---
title: Spring MVC, Spring Boot, Spring Cloud 区别和联系
date: 2025-03-04 08:32:22
categories:
 - spring boot
tags:
 - spring boot
 - 面试
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

## 3. Spring MVC 项目搭建

看下 Spring Boot 出现前是如何搭建 Spring MVC 项目的, Spring MVC 项目需要引入 `spring-webmvc` 模块的依赖, 最终下面是我们配置最简单的 `pom.xml` 内容:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.zzuhkp</groupId>
    <artifactId>mvc-demo</artifactId>
    <version>1.0-SNAPSHOT</version>
    <packaging>war</packaging>

    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <maven.compiler.source>1.8</maven.compiler.source>
        <maven.compiler.target>1.8</maven.compiler.target>
    </properties>
    
    <dependencies>
        <dependency>
            <groupId>org.springframework</groupId>
            <artifactId>spring-webmvc</artifactId>
            <version>5.2.6.RELEASE</version>
        </dependency>

        <dependency>
            <groupId>javax.servlet</groupId>
            <artifactId>javax.servlet-api</artifactId>
            <version>4.0.1</version>
            <scope>provided</scope>
        </dependency>

    </dependencies>

</project>
```

除了引入 `spring-webmvc` 的依赖, 由于我们还可能会使用到一些 `Servlet` 规范中的一些类, 我们还引入了 `Servlet` 的依赖, 而依赖引入只是万里长征的第一步, 由于 Java Web 开发中的接口都是 Servlet 提供的, 我们还需要配置 `spring-webmvc` 模块提供的 Servlet 接口的实现 `DispatcherServlet`, 这又是什么东西？当时作为新手我的也是一脸懵逼, 配置时我还得找到这个**类的全限定名**, 这对于新手来说也太不友好了, 又是一波复制粘贴, 最终配置出来下面的` web.xml` 文件:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="http://xmlns.jcp.org/xml/ns/javaee"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee
          http://xmlns.jcp.org/xml/ns/javaee/web-app_4_0.xsd"
         version="4.0">

    <servlet>
        <servlet-name>dispatcher</servlet-name>
        <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
    </servlet>
    <servlet-mapping>
        <servlet-name>dispatcher</servlet-name>
        <url-pattern>/</url-pattern>
    </servlet-mapping>
</web-app>
```

到这里就完了吗？显然不是, 我们还没有为 Spring 配置 bean, 对于 Spring MVC 来说, 我们需要把 Spring 的配置文件放在` /WEB-INF/${servlet-name}-servlet.xml` 中，其中 `${servlet-name}` 为 Servelt 的名称, 我们为 `DispatcherServlet` 取的名字是 dispatcher, 因此我们需要创建 `/WEB-INF/dispatcher-servlet.xml `作为配置文件, 这对新手又是一个挑战, 还得记住命名规范, 那能不能自己指定配置文件位置呢？可以, 配置一个 Servlet 的初始化参数 configurationLocation 指定配置文件, 好吧, 还得记住参数名称, 真是令人崩溃, 最后看下配置文件的内容吧:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:mvc="http://www.springframework.org/schema/mvc"
       xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd http://www.springframework.org/schema/mvc https://www.springframework.org/schema/mvc/spring-mvc.xsd http://www.springframework.org/schema/context https://www.springframework.org/schema/context/spring-context.xsd">

    <bean class="org.springframework.web.servlet.view.InternalResourceViewResolver">
        <property name="prefix" value="/WEB-INF/page"/>
        <property name="suffix" value=".jsp"/>
    </bean>

    <context:component-scan base-package="com.zzuhkp.mvc"/>
</beans>
```

最初的 Java Web 开发可没有前后端分离，为了根据视图名称查找到对应的 JSP 文件，我们配置一个 InternalResourceViewResolver 类型的视图解析器 bean，这是 Spring MVC 特有的一个 bean，又是一个新概念，视图解析器又是什么？此外，我们为了启用注解支持，我们添加了 context:compent-scan 标签指定了要 Spring 要扫描的包。bean 的配置还好，最要名的是 xml 配置的命名空间，就是最上面那一坨，除了复制粘贴谁能自己写出来呢？

写到这里，我已经近乎崩溃了，简直又经历了一次那段痛苦的历史。来个 Controller 测试下请求是否正常。

```java
@Controller
public class HelloController {

    @GetMapping("/hello")
    public String hello() {
        return "/hello";
    }
}
```

Controller 方法 String 类型的返回值将作为视图名，这里我们指定的是 /hello，也就是说有一个 /hello 对应的 jsp 文件，当请求 /hello 时我们将这个文件的内容返回给前端，结合我们前面配置的 InternalResourceViewResolver，它的位置应该是 /WEB-INF/page/hello.jsp，我们定义的文件内容如下:

```java
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <title>hello</title>
</head>
<body>
Hello,Spring MVC
</body>
</html>
```

最后整个项目结构如下:

```xml
.
├── pom.xml
└── src
    └── main
        ├── java
        │   └── com
        │       └── zzuhkp
        │           └── mvc
        │               └── HelloController.java
        └── webapp
            ├── WEB-INF
            │   ├── dispatcher-servlet.xml
            │   └── web.xml
            └── page
                └── hello.jsp
```

原文: https://blog.csdn.net/zzuhkp/article/details/123518033

## 4. 基于 Spring Boot 的 Spring MVC 项目搭建

总结基于 Spring Framework 的 Spring MVC 项目搭建有哪些问题呢？

首先概念过多，新人需要关注 spring-webmvc 中的众多概念，如 DispatcherServlet、视图解析器 InternalResourceViewResolver。其次配置过多，新人需要关注配置文件命名规范、xml 配置文件命名空间 等。

为了解决解决上述的问题，Spring Boot 遵循约定大于配置的开发原则，大大简化的 Spring 的配置。首先进行自动化配置，只要引入相关依赖就会自动进行一些默认的配置，其次如果默认的配置不满足要求还可以自定义配置覆盖默认的配置，大大降低了 Spring 应用上手的门槛。

将上述示例改造成基于 Spring Boot 的 Spring MVC 项目，首先看下 pom 文件内容。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>2.2.7.RELEASE</version>
    </parent>

    <groupId>com.zzuhkp</groupId>
    <artifactId>mvc-demo</artifactId>
    <version>1.0-SNAPSHOT</version>
    <packaging>jar</packaging>

    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <maven.compiler.source>1.8</maven.compiler.source>
        <maven.compiler.target>1.8</maven.compiler.target>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.apache.tomcat.embed</groupId>
            <artifactId>tomcat-embed-jasper</artifactId>
        </dependency>
    </dependencies>

</project>
```

和上述基于 Spring Framwork 的 pom 文件相比，主要有3处不同:

- Spring Boot 通过 spring-boot-starter-web 起步依赖，一次性引入所有 Web 开发相关的库（包括 Spring MVC、嵌入式 Tomcat 等），并通过 Spring Boot 的 BOM（Bill of Materials）自动管理版本兼容性
- 在传统的 Spring MVC 项目中，你需要创建一个 web.xml 文件（Web 应用的部署描述文件），告诉 Servlet 容器如何加载和运行 Spring 的核心 Servlet（即 DispatcherServlet）。Spring MVC 项目完成后，会被打包成一个 .war 文件（Web Application Archive），然后手动放到外部 Servlet 容器（如 Tomcat）的 webapps 目录下，由容器启动运行
- Spring Boot 在项目中内置了 Servlet 容器（默认是 Tomcat），开发者不需要手动配置 web.xml，也不需要单独安装 Tomcat。Spring Boot 把 Servlet 容器作为依赖嵌入到项目中，DispatcherServlet 的注册和初始化由 Spring Boot 的自动配置完成，无需显式定义

> 在 Java Web 开发中，Servlet 是一种用来处理 HTTP 请求的技术规范（由 Java EE 定义）。而 Servlet 容器（比如 Tomcat、Jetty）是一个运行环境，负责加载、执行 Servlet，并管理 HTTP 请求和响应的生命周期。
>
> Spring MVC 是基于 Servlet 构建的 Web 框架，核心组件 DispatcherServlet 是一个特殊的 Servlet，负责接收所有请求并分发给对应的控制器（Controller）。Spring Boot 虽然也依赖 Spring MVC，但对这些底层机制进行了封装和简化。

## 5. 总结

上面我们讨论了 Spring Boot 和 Spring Cloud 在配置依赖方面的区别和联系, 然后讨论了构建 Spring MVC 项目和 Spring Boot 项目各自的步骤, 

显然 Spring Cloud 是一个单独的框架, 有自己的组件, 我们可以在 Spring Boot 中使用 Spring Cloud, 但是 Spring Boot 的 BOM 只是管理了它自己核心组件的版本, 并不会管理 Spring Cloud 核心组件, 因此我们在使用他们两个的时候, 同时在 `pom.xml` 指定各自的 BOM 才是最佳实践, 方便他们各自管理各自组件的版本, 

然后通过讲解 Spring MVC 项目的构建过程, 我们发现, Spring MVC 利用 Java Servlet 规范通过 DispatcherServlet 实现前端控制器模式, 将 HTTP 请求分发给对应的 Controller 处理, 再通过视图解析器渲染最终响应, Tomcat、Jetty 等 Servlet 容器提供了运行环境和 Servlet 规范的实现, 而 Spring MVC 通过 DispatcherServlet 利用这些底层 API 来处理 Web 请求, Spring MVC 也可以与其他 Spring 模块（如 Spring Security、Spring Data 等）无缝集成, 所以Spring MVC 才是 Java Web 开发最基础最核心的东西, 

Spring MVC 虽然强大, 但配置复杂（ XML 文件、依赖管理、Servlet 容器 Tomcat）, 对新手不友好, 而 Spring Boot 则是构建于 Spring MVC 之上, 通过类似于 spring-boot-starter-web 的依赖包, 一次性引入所有相关库（如 Spring MVC、Tomcat、Jackson 等）, 并并保证版本兼容, 并且把 Servlet 容器嵌入到应用中, 使得项目可以打包为独立的 JAR 文件, 直接运行, 

所以 Spring Boot 本质就是构建于 Spring MVC 之上基于 Spring 生态的“快速开发框架”, 它帮我们集成了 Spring MVC 所有的基础配置, 包括 Servlet 路径, 视图, 以及 Servlet 容器 Tomcat, 除此之外还提前定义了 Spring 核心组件的依赖版本, 我们只要在 `pom.xml` 引入了 `<parent>...</parent>`, 当我们使用一些依赖比如 Spring Security, Spring Data JPA 等, 直接加到 `pom.xml` 中就行, 不用指定版本号或者担心以后更新引起版本冲突, 

