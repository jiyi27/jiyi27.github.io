---
title: Spring Boot 踩坑汇总
date: 2025-02-16 12:49:20
categories:
 - spring boot
tags:
 - spring boot
 - bugs
 - 零碎知识
---

## 1. `ResponseStatusException` 总是返回 403

Service 层的部分代码:

```java
if (isPostLiked(postId, userId)) {
    throw new ResponseStatusException(HttpStatus.CONFLICT, "已经点赞过该帖子");
}
...
```

可是每次执行到这里, 客户端收到的总是 403 forbidden, 而不是 409, 刚开始猜想是这个异常被框架的某个部分吞了, 然后全都自动翻译成 403, 其实并不是这样, 我在[官方文档](https://docs.spring.io/spring-security/reference/servlet/authorization/authorize-http-requests.html#_all_dispatches_are_authorized)找到了对应的描述:

> The `AuthorizationFilter` runs not just on every request, but on every dispatch. This means that the `REQUEST` dispatch needs authorization, but also `FORWARD`s, `ERROR`s, and `INCLUDE`s. 

当 ResponseStatusException 被抛出时, Spring MVC **不会直接把 409 发送给客户端**, 而是会**触发 `ERROR` Dispatch**, `ERROR` dispatch 不是一个真正的 HTTP 请求, 而是在服务器内部重新分发请求的机制, 这个机制不是客户端发起的，而是服务器自己创建的, 目的是：

- 让 Spring 的全局异常处理（比如 `@ControllerAdvice`）有机会处理这个错误
- 让 `/error` 端点（如果有）可以生成友好的错误页面或 JSON 响应

Spring Security 认为 `ERROR` dispatch 是新的请求, 默认情况下，`ERROR` dispatch 需要单独授权, 否则可能会被拦截, 导致 `403 Forbidden`, 

所以直接修改 Spring Security 配置代码:

```java
http.authorizeHttpRequests(auth -> auth
    .requestMatchers("/api/users/login", "/api/users/register").permitAll()
    // 允许所有人访问错误页面（防止 Spring Security 拦截 500, 400 等错误页面）
    .dispatcherTypeMatchers(DispatcherType.ERROR).permitAll()
    .anyRequest().authenticated()
);
```

参考: [Why is Spring ResponseStatusException 400 translated into 403](https://stackoverflow.com/a/76951737/16317008)