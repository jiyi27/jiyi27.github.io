---
title: 后端八股文
date: 2025-01-22 15:30:20
categories:
 - 面试
tags:
 - 面试
 - 八股文
---

## 1. Sessions 状态管理

JWT由三部分组成, Header, Payload, Signature, JWT 的 Header 和 Payload 部分是经过 Base64 URL 编码的, 本质上是“明文”的, 不适合在Payload中存储敏感信息, 只有Signature部分是经过加密的, 用于验证数据的完整性. 了解更多: https://jwt.io/

> JWTs provide a means of maintaining session state on the client instead of doing it on the server. 
>
> With server-side sessions, you will either have to **store the session identifier in a database**, or else **keep it in memory** and make sure that the client always hits the same server. 
>
> Moving the session to the client means that you remove the dependency on a server-side session, but it imposes its own set of challenges.
>
> - Storing the token securely. (禁止 客户端 JS 代码访问 token, 可以把 token 放到 cookie 中, 然后设置该 cookie 为 HTTP only)
> - Transporting it securely. (后端设置 cookie, 只允许通过 HTTPS 传输)
>
> [Stackoverflow][https://stackoverflow.com/a/45214431/16317008]

## 2. AB 压测 大部分请求失败

有时候测试会遇到大部分请求都显示失败, 可是实际服务端却是执行成功了,  可能一个原因是 `ab` 运行负载测试时，它默认会检查所有响应的长度是否一致。如果服务器返回的响应长度不一致，`ab` 会报错，认为测试结果不可靠。`-l` 选项允许 `ab` 忽略这些长度变化。[了解更多](https://stackoverflow.com/a/28435814/16317008)

