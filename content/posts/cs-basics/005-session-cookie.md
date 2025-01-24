---
title: Session, JWT & Cookie
date: 2023-08-17 07:39:56
categories:
  - 计算机基础
tags:
  - 计算机基础
  - http
  - 后端开发
---

HTTP 是一个无状态协议, 对于每个用户 HTTP 请求, 服务器无法得知上一次请求所包含的状态, 可是在淘宝的某个页面中, 你进行了登陆操作, 当你跳转到商品页时, 服务端怎么记住你登陆的状态？

## 1. Cookie

首先产生了 cookie 这门技术来解决这个问题, cookie 是 http 协议的一部分, 它的处理分为如下几步:

- 服务器主动向客户端发送 cookie, 通常使用 HTTP 协议规定的 `set-cookie` 头操作
- 客户端浏览器自动保存 Cookie
- 每次请求浏览器都会自动将 cookie 发向服务器

这里有个问题, 用户会访问多个网站, 浏览器会保存来自不同网站服务器的 cookie, 浏览器怎么把知道应该把 cookie 发给正确的网站? 

答案是浏览器使用 Cookie 的域名 (Domain) 和路径 (Path) 属性来决定将哪些 Cookie 发送回哪个网站, 其实 Cookie 不仅仅是在一个值, 它是有很多属性的, 在后端服务器可以设置, 比如:

- path：表示 cookie 影响到的路径, 匹配该路径才发送这个 cookie
- expires 和 maxAge：expires 是 UTC 格式时间, maxAge 是 cookie 多久后过期的相对时间, 当不设置这两个选项时, cookie 默认是 transient，即当用户关闭浏览器时，就被清除
- secure: 仅HTTPS 中才有效
- httpOnly：禁止前端 JS 代码读取, 避免被 xss 攻击拿到 cookie

> 后端开发小贴士 1 ⚠️: 设置此属性前, 需要先即把格式转为 UTC 格式, 因为客户端和服务器的时区可能不一样, 比如客户端比服务器快几个小时, 若直接设置 expires = Now() + 30, 半小时后过期, 传到客户端立刻过期了, 因为客户端浏览器默认来自服务器的 cookie expires 是 UTC, 

> 后端开发小贴士 2 ⚠️ : All HTTP date/time stamps MUST be represented in Greenwich Mean Time (GMT), without exception. For the purposes of HTTP, GMT is exactly equal to UTC (Coordinated Universal Time). *Both GMT and UTC display the same time*. 
>
> [Stackoverflow](https://stackoverflow.com/a/35729939/16317008)

## 2. Session & JWT

Session 和 JWT 目的相同, 都是为了实现用户认证, 只不过前者在后端维护, 后者就是简单使用一个 token 来实现用户登录认证, Cookie 则是运输工具, 用来存储 Session ID 或者 JWT Token, 即: 服务器生成 Session ID 或 JWT Token, 然后把它们放到 Cookie 中, 之后每次发起请求时, 由浏览器自动发送给服务器, 实现服务器识别用户, 记住登录状态的目的, 

> 后端开发小贴士 3 ⚠️: Cookie 本质上是明文存储和传输的, 直接在 Cookie 中存储敏感信息（如密码、银行账号等）是非常危险的  

> 后端开发小贴士 4 ⚠️: Session在服务端是如何存储的呢？内存(一个多线程安全的map), Redis 缓存 (更好的横向拓展), 

了解更多: [Authentication: JWT usage vs session](https://stackoverflow.com/a/45214431/16317008)