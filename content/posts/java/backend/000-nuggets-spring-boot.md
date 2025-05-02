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

当 ResponseStatusException 被抛出时, Spring MVC **不会直接把 409 发送给客户端**, 而是会**触发 `ERROR` Dispatch**, 注意 `ERROR` dispatch 不是一个真正的 HTTP 请求, 而是在服务器内部重新分发请求的机制, 这个机制不是客户端发起的，而是服务器自己创建的, 目的是：

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

可以在 `application.properties` 里打开 Spring 的 `DispatcherServlet` 日志：

```
logging.level.org.springframework.web.servlet.DispatcherServlet=DEBUG
```

然后在 Controller 里故意抛出 `ResponseStatusException`，查看日志：

```
DEBUG org.springframework.web.servlet.DispatcherServlet: "ERROR" dispatch for GET "/like"
```

参考: [Why is Spring ResponseStatusException 400 translated into 403](https://stackoverflow.com/a/76951737/16317008)

## 2. Spring Data JPA 命名规则

Spring Data JPA 会根据 方法名 解析出 SQL 查询语句, 它的解析规则是：

1. `findBy + 字段名` → 根据字段名查询
2. `findBy + 字段名1 + And + 字段名2` → 根据多个字段查询
3. `findBy + 字段名 + OrderBy + 排序字段 + Desc/Asc` → 带排序的查询
4. `countBy + 字段名` → 统计数量
5. `existsBy + 字段名` → 判断数据是否存在

所以在查询的时候 JPA 只解析 `find（实体）By（字段）`, 不会解析 `find（字段）By（字段）`, 也就是说如果你想查询某个字段, 抱歉只能通过 `@Query`, 单凭 JPA 解析方法自动生成 SQL 并不行, 因为 JPA 只可以查询实体, 比如下面这个:

```java
public interface UserRepository extends JpaRepository<User, Long> {
  List<User> findByName(String name);
  List<User> findByNameAndAge(String name, Integer age);
}
```

这样的可以自动解析, 因为要查询的是单个或者多个 `User`, 如果你要是想查询 name, 写出下面的语句:

```java
List<String> findNamesByAge(Integer age);
```

编译时不报错, 等到运行的时候就会抛出异常, 到时候你会发现此方法最后返回的并不是 `List<String>` 而是 `User` 类型, 意外吧, 是的, 你的函数声明只是个摆设, Spring Data JPA 解析的 SQL 才决定了最终返回的类型, 

