---
title: 记录 CORS Preflight Request 错误前后端排查过程 
date: 2025-01-26 10:36:22
categories:
 - bugs
tags:
 - bugs
 - cors
 - golang
 - 后端开发
---

遇到的问题是, 一会有跨域请求错误, 一会没有, 真的是莫名其妙, 

```
Access to fetch at 'http://localhost:8080/api/terms/suggestions?query=aaa' from origin 'http://localhost:3000' has been blocked by CORS policy: Response to preflight request doesn't pass access control check: No 'Access-Control-Allow-Origin' header is present on the requested resource. If an opaque response serves your needs, set the request's mode to 'no-cors' to fetch the resource with CORS disabled.
```

当 query 字符串为长度大于 2 的时候, 浏览器就会发送 preflight request 请求, 如下图:

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2025/01/3a41d4bb6799ca575c2a60f333806d83.png)

先不说为什么出现跨域错误, 这个肯定是我后端没处理好, 后面再分析, 我们来看为什么因为 query 不同, 导致了浏览器发送 preflight request, 首先我的所有请求都加上了 `'Content-Type': 'application/json',`, 也就是是说, 我的所有请求都不是简单请求, 因此触发 preflight request 很正常, 可是, 为什么 `/suggestions?query = x`, `/suggestions?query = xx` 没有触发呢? 

--------

至于跨域错误是因为我后端没处理好, 原本代码如下:

```golang
mux.HandleFunc("GET /api/terms/suggestions", middleware.Use(h.GetTermSuggestions, middleware.Logger, middleware.CORS(nil)))
```

可以看出, 我只处理了 GET 请求, 忽略了 OPTION 请求, 这也是为什么明明使用了 CORS 中间件, 却总是不会被触发, 原来是下面这个请求根本没有对应的后端路径: 

```
OPTIONS http://localhost:8080/api/terms/suggestions?query=xxx
```

另外还有个容易出错的地方:

```golang
mux.HandleFunc("GET /api/terms/{id}", ...)
mux.HandleFunc("GET /api/terms/suggestions", ...)
```

第一个动态路由 API 会覆盖第二个 API, 因为 `{id}` 也是字符串, 所以不可以这么写, 

这么看来, 对每个 API 单独加中间件并不是一个明智的选择, 比如因为我忽略了 OPTION 请求, 导致 CORS 错误, 一直找不到原因, 所以中间件, 应该放到最开始处理的地方, 