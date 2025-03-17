---
title: Spring Cloud 组件理解
date: 2025-03-17 17:28:20
categories:
 - 面试
tags:
 - 面试
 - java后端面试
---

## 1. Spring Cloud Loadbalancer 

Spring Cloud Loadbalancer 并不是一个独立运行的服务 比如监听某个端口的进程, 而是一个 JAR 包, 集成到你的应用 比如 Gateway 或微服务 中, 在你的应用进程内部运行, 作为一个功能模块, Spring Cloud Loadbalancer 的工作原理是：

1. **依赖服务注册中心**: 它从服务注册中心（如 Eureka）获取服务实例列表
2. **执行负载均衡逻辑**: 在客户端本地（即你的应用进程中），根据配置的算法选择一个实例（通常是 IP + 端口）
3. **返回实例地址**: 将选中的实例地址交给调用方（比如 Gateway 或 RestTemplate），由调用方发起实际请求

它不需要监听端口，因为它不是服务端，而是客户端逻辑的一部分

## 2. Spring Cloud Gateway

职责: Spring Cloud Gateway 是一个 API 网关, 它是整个系统的边界层, 面对外部客户端, 负责请求的分配和转发, 核心功能:

- 路由：将外部请求转发到对应的微服务

- 过滤：对请求进行预处理（如认证、限流）或响应处理（如添加头信息）

- 负载均衡：内置支持负载均衡 (通过调用 Spring Cloud Loadbalancer 实现)

> 如果 Gateway 可以负载均衡，为什么还需要 Spring Cloud Loadbalancer？
>
> 虽然 Gateway 可以做负载均衡, 但它只是“使用者”, 而 Spring Cloud Loadbalancer 是“提供者”, Loadbalancer 的存在是为了解耦负载均衡逻辑, 使其可以被多个组件复用, 而不仅仅局限于 Gateway, 

### 2.1. Loadbalancer 在 Gateway 中工作方式

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: order-service-route
          uri: lb://order-service
          predicates:
            - Path=/orders/**
```

当 Spring Cloud Gateway 配置了 `lb://service-name` 时, 背后依赖 Spring Cloud Loadbalancer 来完成实例选择:

- 客户端发送请求 GET /orders/list 到 Gateway
- Gateway 解析 lb://order-service，识别这是一个需要负载均衡的路由
- Gateway 调用 Spring Cloud Loadbalancer
- Loadbalancer 从服务注册中心获取 order-service 的实例列表（比如 192.168.1.1:8081、192.168.1.2:8082、192.168.1.3:8083）
- Loadbalancer 根据算法（默认轮询）选择一个实例，比如 192.168.1.2:8082
- Gateway 拿到这个地址，将请求转发到 http://192.168.1.2:8082/orders/list

### 2.2. Loadbalancer 在微服务间调用中的工作方式

在微服务直接调用（不经过 Gateway）时，比如使用 `@LoadBalanced` 的 `RestTemplate` 客户端，Loadbalancer 的作用也是一样的:

```java
@RestController
class OrderController {
    @Autowired
    private RestTemplate restTemplate;

    @GetMapping("/pay")
    public String pay() {
        // 注意这里是通过服务名称访问
        String url = "http://payment-service/pay";
        return restTemplate.getForObject(url, String.class);
    }
}

@Bean
@LoadBalanced
public RestTemplate restTemplate() {
    return new RestTemplate();
}
```

- 这里的 `"http://payment-service/pay"` 不是 具体的 IP 地址，而是一个 服务名称
- `@LoadBalanced`：启用 Spring Cloud 负载均衡功能, 让 `RestTemplate` 去注册中心查询 `payment-service` 的真实地址
- 获取所有可用实例, 可能有多个, 启动负载均衡策略, RestTemplate 发送 HTTP 请求 到选定的 `payment-service` 实例

> Spring Cloud Gateway 的负载均衡功能（lb:// 前缀）依赖于 Spring Cloud 生态中的负载均衡机制，而这个机制默认由 Spring Cloud Loadbalancer 提供, 但这种依赖并不是 Gateway 项目直接引入的，而是通过 Spring Cloud 依赖管理间接实现的, 
>
> 在 Spring Boot 和 Spring Cloud 项目中，依赖管理通常通过 **Spring Cloud BOM（Bill of Materials）** 来统一处理版本和组件集成。Spring Cloud Gateway 和 Spring Cloud Loadbalancer 都属于 Spring Cloud 生态的一部分，当你引入 spring-cloud-starter-gateway 时，负载均衡相关的依赖会通过依赖链条隐式引入

## 3. Spring Cloud Circuit Breaker

### 3.1. 如何使用

熔断 Circuit Breaker 是一种用于提高系统稳定性和容错能力的设计模式, 当服务调用失败率过高或响应时间过长时, 熔断器会切断请求, 防止系统雪崩, 并提供降级逻辑, Resilience4j 本质上是 一个独立的熔断库, 并不属于 Spring Cloud, 但 Spring Cloud 已经将 Resilience4j 集成到 Spring Cloud Circuit Breaker 组件中, 作为 Hystrix 的替代方案, 

添加 Spring Cloud Resilience4j 依赖:

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-circuitbreaker-resilience4j</artifactId>
</dependency>
```

在 `application.yml` 配置熔断器规则：

```yaml
resilience4j:
  circuitbreaker:
    instances:
      externalService: # 熔断器名称，对应 @CircuitBreaker(name = "externalService")
        failureRateThreshold: 50 # 失败率达到 50% 触发熔断
        slowCallRateThreshold: 100 # 100% 慢调用视为失败
        slowCallDurationThreshold: 2s # 超过 2 秒的调用视为慢调用
        waitDurationInOpenState: 5s # 熔断后 5 秒进入半开状态
        permittedNumberOfCallsInHalfOpenState: 3 # 半开状态下允许 3 次测试请求
        slidingWindowSize: 10 # 统计 10 次请求
        minimumNumberOfCalls: 5 # 至少 5 次请求后才计算熔断
```

Spring Cloud 提供 `@CircuitBreaker`，但建议使用 `@Retryable` 或 `@TimeLimiter` 结合 `@CircuitBreaker` 以支持异步调用:

```java
@Service
public class ExternalApiService {

    private final RestTemplate restTemplate = new RestTemplate();

    @CircuitBreaker(name = "externalService", fallbackMethod = "fallback")
    @TimeLimiter(name = "externalService")
    @Retryable
    public CompletableFuture<String> fetchData() {
        return CompletableFuture.supplyAsync(() -> {
            ResponseEntity<String> response = restTemplate.getForEntity("http://some-external-api.com/data", String.class);
            return response.getBody();
        });
    }

    public CompletableFuture<String> fallback(Throwable ex) {
        return CompletableFuture.completedFuture("Fallback response");
    }
}
```

- `@CircuitBreaker(name = "externalService", fallbackMethod = "fallback")` 进行熔断

- `@TimeLimiter(name = "externalService")` 处理超时

- `@Retryable` 进行重试

- `fetchData()` 异步调用 API

> Spring Cloud Circuit Breaker 是一个 抽象层, 它允许开发者使用不同的熔断实现，例如：Resilience4j, Sentinel, Hystrix（已经被废弃）

### 3.2. 解决的问题

**防止雪崩效应（Cascading Failure）**

在微服务架构中，服务之间通常是链式调用，如果某个服务（比如订单服务）响应变慢或不可用，所有依赖它的服务（比如支付、推荐）都会受影响，最终可能导致整个系统瘫痪,

在高并发环境下，如果一个服务响应变慢，大量线程会阻塞等待返回，导致线程池被耗尽，影响其他正常请求

> **为什么大量流量会冲垮服务器? ** 答案: CPU & 内存负载过高，导致崩溃
>
> **线程池 & 连接池耗尽:** 现代 Web 服务器（如 Tomcat、Spring Boot 内置 Netty）在处理 HTTP 请求时，通常会使用**线程池**，而不是无限制创建新线程, 当请求量超出线程池或连接池的限制，服务器可能会崩溃或严重降级:
>
> - 由于线程池满了, 新请求只能等待，或者直接被拒绝
> - 如果请求等待时间过长, 大量超时会导致请求积压, 最终服务器负载飙升, 崩溃
>
> **数据库 & 依赖服务承受不住**: 现代 Web 应用通常会依赖数据库、缓存（Redis）、第三方 API, 如果大量请求涌入, 这些依赖服务可能也会被压垮, 假设数据库可以承受 每秒 500 次查询（QPS）, 如果流量稳定, 数据库可以正常处理, 假设一秒内突然有 10,000 次查询，数据库无法处理, 数据库连接池满了，新请求需要等待连接释放, 超时 & 失败请求会导致更多重试，形成恶性循环，最终数据库崩溃,

## 4. 有了 Gateway 还需要 Nginx 吗

- 如果你的所有服务都经过 Spring Cloud Gateway 进行流量管理，并且不涉及**静态资源托管**，Nginx 的作用可能较小
- 通过 Nginx 实现 WAF（Web 应用防火墙）、DDoS 保护、IP 黑名单、限流等安全策略，减轻 Spring Cloud Gateway 的负担
- 如果 Spring Cloud Gateway 由于重启或崩溃导致短暂不可用，Nginx 仍能提供基本的流量调度（比如返回静态页面）



