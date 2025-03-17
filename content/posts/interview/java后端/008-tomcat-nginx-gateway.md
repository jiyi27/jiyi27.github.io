---
title: Tomcat Nginx Gateway LoadBalancer
date: 2025-03-17 20:28:20
categories:
 - 面试
tags:
 - 面试
 - java后端面试
---

## 1. 写在前面

好多网关路由转发的功能, 感觉有的都重复了, 在这里讨论一下, 主要目的是明白各自存在的意义, 首先是 Tomcat, 这是个 Servlet 容器, 至于 Servlet 是什么, umm, 如果你以前写过 JSP 那一套肯定是了解的, 但现在基本上直接学习 Spring Boot, 不会接触到 Servlet, JSP, 最多也是调试看日志的时候看到一些比如 DispatcherServlet 相关的错误, 可以说 Spring MVC 就是基于 Servlet 的 Web 框架, 它通过一个核心的 DispatcherServlet 来分发请求到不同的控制器, 但底层仍然依赖 Tomcat 这样的容器来运行

### 1.1. 从最基础的 Java Web Servlet + JSP 说起

Servlet 是 JavaEE 体系里定义的一套 接口/规范, 最初的目标是取代 CGI 处理 HTTP 请求, Tomcat 是一个 Servlet 容器, 它实现了 Servlet 规范, 因此, 只要你编写的代码符合 Servlet 规范, 就可以直接部署在 Tomcat 上跑

#### 1.1.1. 如何操作

开发者编写一个继承 HttpServlet 的类，重写 `doGet()` 或 `doPost()` 方法:

```java
public class MyServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.setContentType("text/html");
        PrintWriter out = resp.getWriter();
        out.println("<html><body>Hello, World!</body></html>");
    }
}
```

在 `web.xml` 中配置 URL 映射：

```xml
<servlet>
    <servlet-name>MyServlet</servlet-name>
    <servlet-class>com.example.MyServlet</servlet-class>
</servlet>
<servlet-mapping>
    <servlet-name>MyServlet</servlet-name>
    <url-pattern>/hello</url-pattern>
</servlet-mapping>
```

#### 1.1.2. Tomcat 做了什么

1. 打开一个 ServerSocket，监听某个端口（默认 8080）
2. 当有 HTTP 请求进来时，会将请求解析成 HttpServletRequest / HttpServletResponse 对象
3. 根据配置（如 `web.xml` 中的 `<servlet>` / `<servlet-mapping>`）, Tomcat 会将请求分发给对应的 Servlet
4. Tomcat 接收到 `/hello` 请求后，调用 `MyServlet` 的 `doGet()` 方法
5. Servlet 接口定义了一系列生命周期方法，比如 `init()`, `service()`, `destroy()` 等，最核心的就是 `service()` 方法(或 doGet/doPost...)，用来处理请求并写出响应

#### 1.1.3. 现存问题

- 每个功能（如登录、列表页）都需要一个 Servlet, 代码重复严重（比如每次都要设置响应类型、获取参数）

- 配置繁琐, 所有 Servlet 都要在 `web.xml` 中手动映射

### 1.2. Spring MVC：在 Servlet 基础上的进一步抽象

Spring MVC 出现是为了解决 Servlet + JSP 的问题, 它引入了 MVC（Model-View-Controller）模式, 通过一个核心 Servlet（DispatcherServlet）统一处理请求, 并将逻辑分层,

#### 1.2.1. 两个核心组件

- **DispatcherServlet**：Spring MVC 的入口, 是一个特殊的 Servlet，配置为拦截所有请求 `/*`

- **Controller**：替代了分散的 Servlet，集中处理业务逻辑

```java
@Controller
public class HelloController {
    @RequestMapping("/hello")
    public String sayHello(Model model) {
        model.addAttribute("message", "Hello, World!");
        return "hello"; // 逻辑视图名
    }
}
```

```xml
<servlet>
    <servlet-name>dispatcher</servlet-name>
    <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
</servlet>
<servlet-mapping>
    <servlet-name>dispatcher</servlet-name>
    <url-pattern>/*</url-pattern>
</servlet-mapping>
```

#### 1.2.2. 请求步骤

1. 用户访问 http://localhost:8080/myapp/hello

2. Tomcat 接收请求，根据 web.xml 路由到 DispatcherServlet

3. DispatcherServlet：

   - 根据 @RequestMapping("/hello") 找到 HelloController 的 sayHello 方法

   - 执行方法，生成 Model 数据（"message"）

   - 通过 ViewResolver 将 "hello" 解析为 hello.jsp

   - 渲染 JSP，返回 HTML 响应

#### 1.2.3. 优缺点

优点: 请求分发自动化, 不需要为每个 URL 写一个 Servlet

缺点: 配置复杂（XML 或注解）部署仍需手动打包 WAR 文件, 放入 Tomcat

### 1.3. Spring Boot：进一步简化部署与配置

- 在传统的 Spring MVC 项目中, 你需要单独安装 Tomcat, 然后把打好的 `.war` 包部署到 Tomcat 的 `webapps` 目录下

- Spring Boot 则自带一个 嵌入式 Tomcat, 你只要在 `pom.xml` 里加上依赖, Spring Boot 会自动把 Tomcat 打包进来

- 在 Spring MVC 时代，为了让 DispatcherServlet 工作，你往往需要在 `web.xml` 配置 `<servlet>` + `<servlet-mapping>` 

- 在 Spring Boot 中, 几乎可以“零配置”——因为 Spring Boot Starter 以及 自动配置(Auto Configuration) 会帮你自动注册 DispatcherServlet、自动扫描 `@Controller`、自动创建上下文等等

> 要记住：尽管我们用 Spring Boot，但底层还是 **Tomcat + DispatcherServlet** 在跑，只不过这一切都被 Boot 帮我们封装好了：
>
> 1. 你用 `SpringApplication.run(...);` 启动项目时, Spring Boot会：
>
>    - 创建一个 Spring 上下文(ApplicationContext)，加载各种自动配置类
>
>    - 初始化并启动一个 Tomcat 容器（默认监听 8080 端口）
>
>    - 注册 DispatcherServlet 并进行 URL 映射(默认 `/*`)，使它成为整个应用的前端控制器
>
> 2. 当请求进入时, Tomcat 依旧会解析 HTTP 消息头、消息体，生成 `HttpServletRequest / HttpServletResponse`
>
> 3. Tomcat 将请求分发给对应的 Servlet；在 Spring Boot 里，几乎所有请求都指向 DispatcherServlet
>
> 4. DispatcherServlet 查找对应的 Handler（`@Controller` / `@RestController` 上的各种映射），执行相关方法，得到返回值
>
> 5. 如果返回的是视图名，就会交给视图解析器去找模板进行渲染；如果是 `@ResponseBody` 或 `@RestController`，就会把返回对象序列化为 JSON 响应
>
> 6. 最终 Tomcat 将响应通过网络发回给客户端
>
> 所以可以看到, 本质上还是 Servlet 容器 + Servlet 规范在支撑所有这些流程, Spring Boot 并没有发明新的东西, 只是封装集成得更紧密, 让我们省去了许多“手动调度、配置、部署”的繁琐步骤

所以 Spring Boot 本质就是构建于 Spring MVC 之上基于 Spring 生态的“快速开发框架”, 它帮我们集成了 Spring MVC 所有的基础配置, 包括 Servlet 路径, 视图, 以及 Servlet 容器 Tomcat, 除此之外还提前定义了 Spring 核心组件的依赖版本, 我们只要在 `pom.xml` 引入了 `<parent>...</parent>`, 当我们使用一些依赖比如 Spring Security, Spring Data JPA 等, 直接加到 `pom.xml` 中就行, 不用指定版本号或者担心以后更新引起版本冲突, 

## 2. Tomcat vs Nginx

- **Tomcat**: Apache Tomcat 是一个开源的 Java Servlet 容器, 主要用于运行 Java 应用程序, 支持 Java Servlet、JavaServer Pages (JSP) 和 WebSocket 等技术，常用于处理动态内容

- **Nginx**: 用于提供静态内容（如 HTML、CSS、图片等）, 或者作为反向代理将请求分发到后端服务器, 它的核心职责是接收客户端请求、分发流量、管理静态资源，以及将动态请求代理到后端服务

## 3. 为什么有了 Nginx 还需要 Spring Cloud Gateway

Gateway 可以与 Spring Cloud Eureka, Spring Cloud Loadbalancer 合作使用, 可以用来通过 请求路径 如 `Path=/product/**`  和 `uri: lb://product-service` 来找到服务位置, 而 Nginx 不可以, 

Gateway 专为微服务设计，与 Spring 生态深度集成；Nginx 是通用工具，集成微服务生态麻烦

### 3.1. 服务发现与动态路由

Gateway 可以与 Spring Cloud Eureka 集成, 通过 `uri: lb://product-service` 这样的配置, 自动从 Eureka 中查找 `product-service` 的实例 IP 和端口, 结合 Spring Cloud LoadBalancer, 它还能动态选择一个健康的实例发送请求:

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: product_route
          uri: lb://product-service  # 动态找到服务
          predicates:
            - Path=/product/**
```

Gateway 不需要知道具体的服务地址，服务实例增加或减少时，它会自动适应, 在微服务架构中，服务地址经常变化，Gateway 的动态性非常适合这种场景, Nginx 是一个独立的 Web 服务器，需要在配置文件中手动指定后端地址, 如果服务地址变了比如新增实例或实例宕机, 你得手动更新配置并重载 Nginx:

```
upstream product_service {
    server 192.168.1.10:8080;
    server 192.168.1.11:8081;
}
location /product {
    proxy_pass http://product_service;
}
```

## 3.2. 灵活的路由与业务逻辑

Spring Cloud Gateway 可以基于路径 `Path=/product/**`、请求方法`Method=GET` 等条件定义路由规则, 通过过滤器 Filter，可以轻松实现认证、添加请求头、限流等功能:

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: product_route
          uri: lb://product-service
          predicates:
            - Path=/product/**
          filters:
            - AddRequestHeader=X-Authenticated, true  # 添加请求头
            - name: AuthenticationFilter  # 自定义认证逻辑
```

## 4. Nginx 使用场景

假设你想搭建一个简单的 Web 服务器，监听 80 端口，并根据路径转发请求：

```
http {
    server {
        listen 80;                  # 监听 80 端口
        server_name example.com;    # 域名

        location / {                # 根路径返回欢迎信息
            return 200 "Welcome to Nginx!";
        }

        location /api {             # /api 路径代理到后端
            proxy_pass http://backend:8080;
        }
    }
}
```

假设你有两台后端服务器，想实现简单的负载均衡：

```
http {
    upstream backend_servers {
        server 192.168.1.10:8080;   # 第一台后端服务器
        server 192.168.1.11:8080;   # 第二台后端服务器
    }

    server {
        listen 80;
        server_name example.com;

        location / {
            proxy_pass http://backend_servers;  # 转发到 upstream
            proxy_set_header Host $host;
        }
    }
}
```

- 默认情况下, 当 Nginx 代理请求到后端服务器时, 它可能会使用后端服务器的 IP 地址作为 `Host`，例如 `192.168.1.10:8080`，而不是 `example.com`
- `proxy_set_header Host $host;` 主要用于保持客户端请求的 `Host` 头不变, 让后端服务器知道用户访问的是哪个域名

假设你想将所有 /old-page 的请求重定向到 /new-page：

```
http {
    server {
        listen 80;
        server_name example.com;

        location /old-page {
            rewrite ^/old-page(.*)$ /new-page$1 permanent;  # 永久重定向 (301)
        }

        location /new-page {
            return 200 "This is the new page!";
        }
    }
}
```

- 用户访问 example.com/old-page 时，Nginx 将其重定向到 example.com/new-page，并返回 "This is the new page!"

- permanent 表示使用 301 重定向，告诉浏览器永久更新地址

限制请求速率, 防止服务器过载或抵御 DDoS 攻击, 限制每个 IP 每秒只能发送 2 个请求:

```
http {
    limit_req_zone $binary_remote_addr zone=mylimit:10m rate=2r/s;

    server {
        listen 80;
        server_name example.com;

        location / {
            limit_req zone=mylimit burst=5;  # 允许突发 5 个请求
            return 200 "Hello, Nginx!";
        }
    }
}
```

为网站启用 HTTPS，并将 HTTP 请求重定向到 HTTPS：

```
http {
    server {
        listen 80;
        server_name example.com;
        return 301 https://$host$request_uri;  # 重定向到 HTTPS
    }

    server {
        listen 443 ssl;
        server_name example.com;

        ssl_certificate /etc/nginx/ssl/cert.pem;      # 证书文件
        ssl_certificate_key /etc/nginx/ssl/key.pem;   # 私钥文件

        location / {
            return 200 "Secure Page!";
        }
    }
}
```

## 5. 有了 Gateway 还需要 Nginx 吗?

尽管 Gateway 功能强大，但在某些场景下，Nginx 仍然有不可替代的优势。以下是几个需要 Nginx 的理由和示例：

### 5.1. **理由 1：高性能和外部流量处理**

- 场景：你的系统需要应对高并发外部流量（如网站有 10 万 QPS）
- 问题：Gateway 运行在 JVM 上, 性能受限于 Java 的内存管理和线程模型, 在高并发场景下, 容易成为瓶颈, 性能不如 Nginx（C 语言实现，异步非阻塞 I/O）在高并发场景下，Gateway 可能成为瓶颈
- 解决方案：用 Nginx 作为最外层入口，分担流量压力

```
upstream gateway_cluster {
    server gateway1:8080;
    server gateway2:8080;
    server gateway3:8080;
}

server {
    listen 80;
    server_name example.com;
    location / {
        proxy_pass http://gateway_cluster;  # 负载均衡到多个 Gateway
    }
}
```

> 在没有 Nginx 的情况下，Gateway（如果它直接对外提供 HTTPS 接口）就需要自行完成整个 TLS 协议的握手和加解密工作，这部分本身会消耗一定的 CPU 资源，并且会让 Gateway 直接面对海量外部连接；而有了 Nginx 以后：
>
> - 当客户端发起 HTTPS 请求时，Nginx 负责完成 SSL/TLS 握手和加解密的全过程，然后再将解密后的明文流量转发给 Gateway
> - Gateway 只需要处理已经解密的流量，不再承担这部分 CPU 与网络资源负担，能专注于业务层面的路由或规则处理

流量削峰: Nginx 可以同时保持 10 万个前端连接 client -> Nginx, Nginx 并不“一对一”地为这 10 万前端连接都新建一个后端连接, 而是维持一组「后端连接池」, 例如 500 条（实际可配置）与 Gateway 的 TCP 连接, 这些连接都处于 Keep-Alive 状态, 当 Nginx 收到前端请求时, 会在这个连接池里“找一个”空闲连接, 发给 Gateway, 如果所有后端连接都暂时在忙, 那剩下的新请求可以在 Nginx 层面进行排队或等待, 不至于一股脑儿挤给 Gateway,

```
# 定义后端（上游）服务器组
upstream gateway_servers {
    server gateway1:8080;
    server gateway2:8080;

    # 保持最多 64 条保持存活的后端连接（示例数字）
    keepalive 64;  
}

server {
    listen 80;
    server_name example.com;

    location / {
        # 代理到定义好的上游
        proxy_pass http://gateway_servers;

        # 使用HTTP/1.1并开启keep-alive
        proxy_http_version 1.1;
        proxy_set_header Connection "";
    }
}
```

- `proxy_http_version 1.1` 这个设置告诉 Nginx 在把 HTTP 请求转发给后端服务器 比如你的 gateway1:8080 和 gateway2:8080时, 使用 HTTP/1.1 协议, HTTP/1.1 有一个重要特点, 它支持持久连接, 意思是 TCP 连接建立后不会立刻关闭, 可以重复使用来处理多个 HTTP 请求

- `keepalive 64` 这个设置告诉 Nginx：在和后端服务器通信时, 尽量保持最多 64 个连接处于“存活”状态, 也就是说, 这些 TCP 连接不会在请求完成后马上关闭, 而是留着待命, 方便下次处理 HTTP 请求直接复用

想象 Nginx 和后端服务器之间像打电话：

- 如果没有 `keepalive`, 每次 Nginx 要找后端服务器, 就得重新拨号、接通、说完挂断, 下次请求又得重复这个过程，很费时间
- 加了 `keepalive 64`, Nginx 就像跟后端说：“我们别挂电话，我留 64 条线开着，有新请求直接用这些线聊

> 持久连接（Keep-Alive）：HTTP/1.1 默认支持持久连接，允许在同一个 TCP 连接上处理多个 HTTP 请求，而无需每次请求都重新建立连接, 这减少了连接建立的开销，提高了性能

### 5.2. 理由 2：静态资源分发

- 场景：你的应用需要提供大量静态资源（如图片、CSS、JS 文件）

- 问题：Gateway 不是为静态资源分发设计的，效率不如 Nginx

- 解决方案：用 Nginx 直接处理静态资源，动态请求交给 Gateway

```
server {
    listen 80;
    server_name example.com;

    location /static {
        root /var/www/static;  # 直接提供静态文件
    }

    location / {
        proxy_pass http://gateway:8080;  # 动态请求给 Gateway
    }
}
```

### 5.3. 理由 3：HTTPS 和安全

**场景**：需要为网站启用 HTTPS 或抵御 DDoS 攻击

**问题**：Gateway 可以配置 HTTPS，但 Nginx 在 SSL 终止和安全防护（如限流、IP 黑名单）方面更成熟

**解决方案**：用 Nginx 处理 HTTPS 和安全，再转发到 Gateway

```
server {
    listen 443 ssl;
    server_name example.com;
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;

    location / {
        proxy_pass http://gateway:8080;
    }
}
```



