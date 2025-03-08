---
title: Spring Cloud 核心组件和配置
date: 2025-03-07 08:28:52
categories:
 - spring boot
tags:
 - spring boot
---

## 1. 两个配置文件

在 Spring Cloud 项目中, 配置文件分为两类: 

`bootstrap.yml`

- **作用**：用于指定 Spring Cloud Config Server 的地址, 帮助服务从远程拉取具体配置
- **存放位置**：每个服务的本地项目中（src/main/resources 目录下）

`application.yml`

- **作用**：包含服务的具体配置信息, 如端口、Eureka 注册地址、数据库连接等
- **存放位置**：集中存储在 GitHub 仓库中, 由 Config Server 管理

一般 Config Server 只用配置 `application.yml` 文件, 指定监听端口, 不用向 Eureka 注册, 因为它属于一个独立运行的服务, 负责为其他服务如用户认证, 订单服务, Eureka Server, Gateway 等提供配置文件, 

所以 Config Server 的配置文件  `application.yml`  内容大致如下, 不需要 `bootstrap.yml`:

```yaml
spring:
  application:
    name: skymates-config-server
  cloud:
    config:
      server:
        git:
          uri: https://github.com/jiyi27/skymates.git
          search-paths: configs
          default-label: master
server:
  port: 8888
```

其他微服务**只需要在本地配置 `bootstrap.yml` 文件, 用于指定 Config Server 服务器位置 和 自己需要的配置文件名字**, 这也是为什么 Config Server 不需要向 Eureka Server 注册的原因, 因为其他微服务已经知道他的位置, 每个微服务直接从 Config Server 动态拉取自己的配置文件, Eureka Server 的  `bootstrap.yml` 文件内容:

```yaml
spring:
  cloud:
    config:
      uri: http://localhost:8888
      # 当你配置了 name: eureka-server 时，Config Server 会尝试加载类似于 eureka-server.yml、
      # eureka-server.properties 或其他符合命名规则的配置文件
      name: eureka-server
      profile: default
      label: master
```

Gateway  `bootstrap.yml` 文件内容:

```yaml
spring:
  cloud:
    config:
      uri: http://localhost:8888
      # 指定 name: gateway 时, 当在 Config Server 加载配置文件的时候
      # Config Server 尝试加载类似于 gateway.yml、gateway.properties 或其他符合命名规则的配置文件
      name: gateway
      profile: default
      label: master
```

User-Service  `bootstrap.yml` 文件内容:

```yaml
spring:
  cloud:
    config:
      uri: http://localhost:8888
      # 指定 name: content-service 时, 当在 Config Server 加载配置文件的时候
      # Config Server 尝试加载类似于 content-service.yml、content-service.properties 或其他符合命名规则的配置文件
      name: content-service
      profile: default
      label: master
```

然后我们需要单独为这些服务创建具体的配置文件,  指定如端口、Eureka 注册地址、数据库连接, 把这些文件放到 `github.com/jiyi27/skymates/configs` 目录下:

```shell
$ ls configs
eureka-server.yml   gateway.yml         user-service.yml
```

其中 `eureka-server.yml` 内容:

```yaml
spring:
  application:
    name: skymates-eureka-server
server:
  port: 8761
eureka:
  client:
    register-with-eureka: false
    fetch-registry: false
    # 这个 URL 不是直接在浏览器访问的页面, 直接访问地址是 http://localhost:8761
    # 它是一个 RESTful API 端点, 返回的数据通常是 JSON 或 XML 格式, 供其它微服务客户端解析服务信息
    service-url:
      defaultZone: http://localhost:8761/eureka/
```

`gateway.yml` 内容:

```yaml
spring:
  application:
    name: skymates-gateway
  cloud:
    gateway:
      routes:
        - id: user-service-route
          uri: lb://skymates-user-service
          predicates:
            - Path=/user/**
          filters:
            - StripPrefix=1
        - id: content-service-route
          uri: lb://skymates-content-service
          predicates:
            - Path=/content/**
          filters:
            - StripPrefix=1
server:
  port: 8083
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
```

`user-service.yml` 内容:

```yaml
spring:
  application:
    # 定义当前应用程序的名, 会被发送到 Eureka 服务器, 作为服务注册时的服务名
    # 这样 Eureka 就知道了有一个 skymates-user-service 服务, ip地址为 xxx, 服务端口为server.port
    # Gateway 就可以进行负载均衡路由转发: uri: lb://skymates-user-service
    name: skymates-user-service
  datasource:
    url: jdbc:mysql://localhost:3306/skymates?serverTimezone=UTC
    username: root
    password: 778899
    driver-class-name: com.mysql.cj.jdbc.Driver
  jpa:
    database-platform: org.hibernate.dialect.MySQL8Dialect
    hibernate:
      ddl-auto: update
jwt:
  secret: MY_JWT_SECRET_KEY_EXAMPLE_123456
  expiration: 86400000
server:
  port: 8081
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
```

> 注意一般有  `bootstrap.yml` 文件的服务 需要添加依赖: 
>
> ```xml
> <!-- 注册 Eureka -->
> <dependency>
>     <groupId>org.springframework.cloud</groupId>
>     <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
> </dependency>
> 
> <!-- 从 Config Server 拉配置 -->
> <dependency>
>     <groupId>org.springframework.cloud</groupId>
>     <artifactId>spring-cloud-starter-config</artifactId>
> </dependency>
> 
> <!-- 解析 bootstrap.yml 配置文件 -->
> <dependency>
>     <groupId>org.springframework.cloud</groupId>
>     <artifactId>spring-cloud-starter-bootstrap</artifactId>
> </dependency>
> ```
>
> 如果依赖 spring-cloud-starter-netflix-eureka-client 没有加, 尽管你在 `application.yml` 中写了 `eureka.client.service-url.defaultZone`, 也不会真的注册

## 2. 核心组件 启动步骤

### 2.1. 启动步骤

根据以上配置, 我们可以按照下面顺序启动各个微服务:

**启动 Config Server**：

- 运行 skymates-config-server 项目
- Config Server 从 GitHub 仓库的 configs 目录拉取所有配置文件，监听端口 8888

**启动 Eureka Server**：

- 运行 skymates-eureka-server 项目
- 从 Config Server 拉取 eureka-server.yml，启动服务发现功能，监听端口 8761

**启动 Gateway**：

- 运行 skymates-gateway 项目
- 从 Config Server 拉取 gateway.yml，注册到 Eureka Server，监听端口 8080

**启动 User Service**：

- 运行 skymates-user-service 项目
- 从 Config Server 拉取 user-service.yml，注册到 Eureka Server，监听端口 8081

### 2.2. Gateway 运行过程

**Gateway 启动**：

- 加载本地 `bootstrap.yml`，读取 Config Server 地址 http://localhost:8888
- 向 Config Server 请求 `gateway.yml`（基于 `bootstrap.yml` 中的 `name: gateway`）
- Config Server 从 GitHub 仓库的 configs 目录返回 `gateway.yml`
- Gateway 加载 `gateway.yml`, 获取路由规则和 Eureka 注册地址 http://localhost:8761/eureka/
- Gateway 向 Eureka Server 注册自己, 服务名为 skymates-gateway (基于 `gateway.yml` 中的 `name: skymates-gateway`)
- Gateway 开始监听端口 8080，准备接收请求

**请求转发**：

- 客户端发送请求 http://localhost:8080/user/profile
- Gateway 根据  `gateway.yml` 中定义的路由规则`Path=/user/**` 匹配到 user-service-route
- 使用 lb://skymates-user-service, 从 Eureka Server 获取 User Service 的实例地址（例如 http://localhost:8081）
- Gateway 将请求转发到 http://localhost:8081/profile, 完成路由

> 你可能会疑惑, Eureka Server 是怎么知道每个服务的名字的, 其实每个服务的配置文件中都有自己的名字, 当它们向 Eureka Server 注册的时候, Eureka Server 会根据他们提供的名字并解析出他们的 host ip 地址和对方提供的端口号, 比如 `user-service.yml` 有相关定义: 
>
> ```yaml
> spring:
>   application:
>     name: skymates-user-service
> ...
> ```