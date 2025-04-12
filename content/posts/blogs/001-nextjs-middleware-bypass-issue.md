---
title: Next.js 中间件漏洞
date: 20235-04-12 17:46:35
categories:
 - 随笔
tags:
 - 随笔
 - 实事
---

## 1. CDN

最近 Next.js 被发现安全漏洞, 今天休息来学习一下, 想要明白还是要先理解 CDN, 中间件, 缓存投毒等一些概念, 先来说一下 CDN, CDN 就像是个缓存, 这里的缓存和 Redis 缓存的数据不是一个东西, CDN 缓存的是静态页面:

- Redis 缓存**后端**访问频繁的动态数据, 减少数据库压力, 提高 API 响应速度
- CDN 缓存**前端**静态 HTML, CSS 文件, 减少前端服务器的压力, 节约成本, CDN 服务器的带宽大比较便宜些

常见的 CDN 服务商有赛博菩萨 Cloudflare, 一般我们都是使用他的域名托管服务, 他就像一个中间件, 在用户和我们前端服务器之间, 当用户访问我们的网站(通过域名), DNS 查询指向 Cloudflare 的服务器 (托管域名之后), 而不再是我们的 前端服务器 (运行 Nginx 的地方), 一般 Nginx 用来返回静态页面, 部署博客的话应该会很熟悉, 当然他也有反向代理, 负载均衡的功能, 所以用户请求  `your_domain.com/index.html` 时, Cloudflare 可能直接返回缓存的 `index.html` 文件, 而不是转发到你的 Nginx 服务器, 当然如果 Cloudflare 没缓存, 它会请求你的 Nginx, Nginx 返回 index.html, 然后 Cloudflare 缓存后分发, 大致是这样的:

```
用户                 CDN 边缘节点              源服务器
 |                       |                      |
 |                       |                      |
 |                       |                      |
 |                       |                      |
 |                       |                      |
 |                       |                      |
 ↓                       ↓                      ↓
+------+    请求     +---------+    未命中    +-----------------+
|      | ---------> |         | -----------> |                 |
| 用户 |             | CDN节点 |               | 源服务器(Nginx)  |
|      | <--------- |         | <----------- |                 |
+------+    响应     +---------+    响应      +-----------------+
                         ↑                        |
                         |                        |
                         |                        |
                         |                        |
                         +------------------------+
                              缓存静态资源
```

> 为什么 Cloudflare 可以“拦截”用户请求?
>
> 我们主动把 your_domain.com 的 DNS 交给 Cloudflare 管理, 让它代理用户请求, 用户输入域名, DNS 解析到 Cloudflare 的边缘节点, Cloudflare 检查请求:
>
> - 静态文件（*.js、*.css）直接从缓存返回
> - 动态请求（/api/*）原封不动的发送到后端服务器

## 2. 中间件 Middlewares

中间件也是个中间人, 一般它在后端服务器内部, 就是前端的请求已经被转发到后端服务器了, 此时请求要先经过一系列的预处理(认证, 日志, CORS 等操作) 才能到达最终处理请求的 controller 层:

```

+--------+    请求     +-------------+    +-------------+    +-----------+
|        | ---------> | 中间件 1     | -> | 中间件 2     | -> | 路由/控制器 |
| 客户端  |            | (认证)       |    | (日志)       |    |           |
|        | <--------- |             | <- |             | <- |           |
+--------+    响应     +-------------+    +-------------+    +-----------+
```

一般中间件的常见作用都是和认证日志相关, 比如最常见的问题 跨域, 我们会单独写个中间件, 处理 来自 前端的 preflight 请求, 告诉前端浏览器我们的跨域规则(通过一些响应头), 又或者是处理认证, 检查 cookie 中的 JWT token, 若不存在 重定向到 `/login`, 或者根据预定义的路径 检查当前用户的权限, 是否可以访问, 返回 403 无权限:

```js
export function middleware(request) {
  const token = request.cookies.get('auth_token');
  if (!token) {
    return NextResponse.redirect('/login'); // 未登录，重定向到登录页
  }
  
  const user = verifyToken(token);
  if (user.role !== 'admin' && request.nextUrl.pathname.startsWith('/admin')) {
    return NextResponse.redirect('/403'); // 非管理员，拒绝访问
  }
  return NextResponse.next(); // 继续处理请求 发送到下一个中间件或者 controller 层
}
```

反正就是中间件很重要, 就像是个看门狗, 如果没有他失去了作用, 那所有请求都会直接到后端的 controller 层, 直接处理业务逻辑了, 当然有时候后端也会用到当前用户的信息, 比如用户创建一个帖子, 我么要知道创建者的 id, 比如 Spring Boot 喜欢通过依赖注入的方式在 Security Chain 中就根据 token 创建用户对象, 然后 controller, service 层都可以使用访问使用 `user.getId()`, 但是有的比如仅仅是 GET 请求, 就不需要 controller 获取当前用户信息了, 而是直接返回数据, 因为我们默认相信 中间件一定会被执行, 不然请求也不会到达 controller 层, 综上中间件通常负责**全局性**或**路径级别**的认证和授权检查:

- 检查用户是否登录（通过 cookie、JWT 或 session）
- 验证用户角色（例如，只有管理员才能访问 /admin）
- 设置请求上下文（如将用户 ID 附加到请求对象）

## 3. Next.js 中间件漏洞

首先和 Vercel 架构有关系, 刚开始使用 Next.js 的时候就觉得很方便, 直接免费部署到 Vercel 平台, CI CD 一键部署, 很是方便, 你以为你的中间件运行在 Node.js 服务器上? 并不是, Next.js 定义的中间件通常被 Vercel 抽取出来运行在边缘节点, 这时候就会出现一个问题, 就是上面我们说的:

用户访问一个受保护的资源(需要登录访问), 可是中间件发现用户没有登录, 因此返回重定向到登录页面, 这都没问题, 可是用户请求 `\login` 时依然请求会先到中间件, 而中间件运行在 边缘节点 上, 这就导致一个死循环, 因此 Next.js 需要区分“内部请求”和“外部请求”, CVE-2025-29927 的核心问题在于 Next.js 中间件处理 **内部请求头 x-middleware-subrequest** 的方式存在设计缺陷, 

### 3.1. **漏洞的触发机制**

- Next.js 使用 `x-middleware-subrequest` 头来标记“内部子请求”, 以防止中间件在处理同一请求时陷入无限循环
  - 例如, 当中间件重写路径（如将 /dashboard 重写为 /internal/dashboard）时, Next.js 会添加 `x-middleware-subrequest` 头, 告诉框架这是内部请求, 不需要再次运行中间件
- **漏洞点**：这个头原本设计为内部使用, 但 Next.js 没有验证它的来源, 允许外部请求伪造该头

攻击者只需在 HTTP 请求中添加:

```
x-middleware-subrequest: middleware:middleware:middleware
```

这会欺骗 Next.js, 认为这是一个内部请求, 直接**跳过中间件执行, 绕过所有认证、授权**或其他检查, 这就很严重了:

- 一个电商网站可能用中间件检查用户是否登录才能访问订单页面

- 一个 SaaS 平台可能用中间件限制只有管理员才能访问 `/admin`

### 3.2. 后果分析

一旦中间件被绕过, 所有依赖中间件的安全逻辑失效, 导致受保护资源完全暴露, 但是这里有个疑问 即使攻击者通过伪造 x-middleware-subrequest 头绕过了中间件的认证检查, 为什么后续的控制器（controller）层逻辑没有阻止未授权访问？

- 许多应用依赖中间件作为唯一的认证入口，控制器层可能不做重复验证
- 即使控制器层检查用户 ID, 攻击者可能通过其他方式（如缓存投毒、默认行为）利用绕过后的访问权限
- 某些资源直接暴露, 无需额外验证即可访问

许多开发者仅依赖中间件进行认证，没有实施多层防御:

```js
// 许多开发者的实际实现
export function middleware(request) {
  // 只在中间件中进行认证，没有在页面组件中重复验证
  if (request.nextUrl.pathname.startsWith('/admin') && !isAuthenticated(request)) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
}

// 页面组件可能缺乏二次验证
export async function getStaticProps() {
  // 假设中间件已经处理了认证，这里直接获取数据
  return {
    props: { data: await fetchSensitiveData() },
    revalidate: 60 // 使用ISR进行缓存
  };
}
```

参考: [Understanding CVE-2025-29927: The Next.js middleware authorization bypass vulnerability](https://securitylabs.datadoghq.com/articles/nextjs-middleware-auth-bypass/#understanding-cve-2025-29927-the-nextjs-middleware-authorization-bypass-vulnerability)

