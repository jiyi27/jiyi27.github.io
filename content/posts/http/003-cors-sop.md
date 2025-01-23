---
title: Cross-origin Request HTTP
date: 2023-10-06 20:28:50
categories:
 - http
tags:
 - http
---

## 0. CORS Issue 1

Safari shows in console:

```
[Error] Preflight response is not successful
[Error] XMLHttpRequest cannot load [https://xxxxxxxxxxxx](https://xxxxxxxxxxxx/) due to access control checks.
```

Chrome shows in console:

```
Access to XMLHttpRequest at 'https://xxxxxxxxxxx' from origin 'xxxx' has been blocked by CORS policy: Response to preflight request doesn't pass access control check: No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

This means the OPTIONS calls is failing, even if all the headers (allow-origin etc....) are available server-side.

> 说到 CORS 前，需要了解“同源”概念。同源即协议、域名和端口三者完全相同。浏览器使用同源政策，目的是为了保证用户信息的安全，防止恶意的网站窃取数据，不同源的访问会受到限制（主要是 Cookie / Local Storage 访问、iframe DOM 访问、发起 HTTP 请求）。 
> 对于 HTML 标签的外部链接如 `<img>、<audio>、<video>、<script>`，没有跨域问题。不过对于这样的外部链接请求不会带上 Cookie。
> 对于 JavaScript 发起 HTTP 请求，三要素有任何之一不匹配即是跨域，浏览器即会出于安全考虑进行限制，这时就需要使用 CORS （Cross-origin resource sharing）。CORS 主要由服务器端实现，对用户透明。
> Source: https://ogr.xyz/p/js-cors/

## 1. CORS Issue 2

My frontend application is deployed on `http://localhost:5173`, and backend application is deployed on `http://localhost:8080`. The frontend application sends HTTP requests to the backend application through `fetch`, but it fails with the following error:

```shell
# 显然服务器没有处理 OPTIONS 请求
Access to fetch at 'http://localhost:8080/' from origin 'http://localhost:5173' has been blocked by CORS policy: Response to preflight request doesn't pass access control check: It does not have HTTP ok status. 

Access to fetch at 'http://localhost:8080/api/chat' from origin 'http://localhost:5173' has been blocked by CORS policy: Request header field content-type is not allowed by Access-Control-Allow-Headers in preflight response.
```

This is the famous CORS issue, and it is caused by the **same-origin policy** (SOP) enforced by web browsers. 

CORS is a feature built into browsers for added security. **It prevents any random website from using your authenticated cookies** to send an API request to your bank's website and do stuff like secretly withdraw money. 

想象一下, 如果你点进了一个恶意网站, 这个网站有个JS脚本使用比如 fetch 向你银行 /api/transfers 发送了一个请求 (origin 是恶意网站), 如果浏览器没有 same-origin policy 限制, 那么这个请求就会被发送出去, 而且会自动带上你的银行网站的 cookie (若银行后台也允许任意 cors, 这就意味着可以通过银行后台的验证), 这样恶意网站就可以做一些你不知道的事情, 比如转账, 提现等等. 

但是, 有了 same-origin policy 限制, 那么这个请求就不会被浏览器发送出去, 因为这个请求的 origin 和你银行网站的 origin 不一样, 所以浏览器会阻止这个请求. Origin 是浏览器自动添加的请求头, 你不能修改它. Origin 包括三部分: 协议, 域名, 端口. 上面的例子 origin 就是 `http://localhost:5173` 和 `http://localhost:8080`, 前端页面的 js 代码是在 `http://localhost:5173` 运行的, 所以它的 origin 是 `http://localhost:5173`, 而后端的 API 是在 `http://localhost:8080` 运行的, 所以它的 origin 是 `http://localhost:8080`. 

如果你的后端服务器不允许CORS, 那么除了跟你后端服务器同源(Origin)的前端页面, 其他的前端页面都不能在浏览器访问你的后端 API. 当然你可以在终端使用 curl 命令访问你的后端 API, 因为 curl 命令不是浏览器, 它不会自动添加 origin 请求头. 另外 React 的 create-react-app 也有一个 proxy 功能, 可以让你在开发环境下绕过 CORS 限制, 但是这个代理功能**只在开发环境下有效**, 生产环境下还是要你自己配置后端服务器的 CORS.

## 2. How to fix CORS issue

### 2.1. 简单场景

解决的办法很简单, 在后端 API 的响应头里添加 `Access-Control-Allow-Origin: *` 就可以了. 但这仅限于一些简单的场景, 如 GET 请求. 可参考: [Golang CORS Guide: What It Is and How to Enable It](https://www.stackhawk.com/blog/golang-cors-guide-what-it-is-and-how-to-enable-it/)

### 2.2. 复杂场景

如果你的 API 是 POST 请求, 并且需要带上一些请求头, 那么你可能还需要在响应头里添加 `Access-Control-Allow-Headers: *`, 这样才能让浏览器发送 POST 请求, 并且带上你需要的请求头. (具体规定可参考: https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) 这也是为什么在有的前端JS fetch代码里, 你后端简单设置 `Access-Control-Allow-Origin: *` 就可以了, 但是有的并不会成功. 

除了设置上面两个响应头, 你还需要处理 OPTIONS 请求, 这是因为浏览器在发送跨域请求时, 会先发送一个 OPTIONS 请求, 用来询问服务器是否允许跨域请求, 如果服务器不允许, 那么浏览器就不会发送真正的请求. 

比如我的后端 API 需要客户端带上一个请求头 `Content-Type: application/json` 和 `Content-Type: xxxx`, 那么我就需要在响应头里添加 `Access-Control-Allow-Headers: Content-Type, Content-Type`, 或者 `Access-Control-Allow-Headers: *`, 这样浏览器发送HTTP请求时才会带上这两个请求头.  

使用 Golang 处理的话, 大致逻辑如下:

```go
func (s *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	enableCors(&w)
	// Handle CORS preflighted request sent by browser.
	if (*r).Method == "OPTIONS" {
		return
	}

  // 真正的处理逻辑
	s.mux.ServeHTTP(w, r)
}

func enableCors(w *http.ResponseWriter) {
	(*w).Header().Set("Access-Control-Allow-Origin", "*")
	(*w).Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
	// We need to allow the Authorization header to be sent to the backend.
	(*w).Header().Set("Access-Control-Allow-Headers", "*")
	(*w).Header().Set("Access-Control-Max-Age", "86400")
}
```

## 3. CORS vs SOP

The Same-Origin Policy (SOP) is a security feature **enforced by web browsers** that restricts web pages (javascript) from interacting with resources (such as making requests or accessing data) from different origins. 

**CORS allows servers** to specify which origins are allowed to access their resources, even if they are from different origins. It provides a set of HTTP headers that the server includes in its responses to explicitly permit cross-origin requests from specific origins. 

References:

[Cross-Origin Resource Sharing (CORS) - HTTP | MDN](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)

[Same-origin policy - Web security | MDN](https://developer.mozilla.org/en-US/docs/Web/Security/Same-origin_policy)

[JavaScript CORS 跨域请求](https://ogr.xyz/p/js-cors/)
