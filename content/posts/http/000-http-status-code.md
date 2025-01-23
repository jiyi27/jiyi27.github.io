---
title: HTTP Status Codes
date: 2023-10-26 15:30:05
categories:
 - http
tags:
 - http
---

## 2xx

- **200 OK**: Request is okay, entity body contains requested resource.
- **201 Created**: For requests that create server objects (e.g., PUT). The entity body of the response should contain the various URLs for referencing the created resource, with the *Location header* containing the most specific reference. The server must have created the object prior to sending this status code.


## Redirect

### 301: permanent redirect: 可能会修改请求方法

The HyperText Transfer Protocol (HTTP) 301 Moved Permanently redirect status response code indicates that the requested resource has been definitively moved to the URL given by the Location headers. A browser redirects to the new URL and search engines update their links to the resource. 根据描述可以看出, 301 是用来回复 GET 请求的, 与下面 303 刚好相反

> Although the specification requires the method and the body to remain unchanged when the redirection is performed, not all user-agents meet this requirement. Use the 301 code only as a response for GET or HEAD methods and use the 308 Permanent Redirect for POST methods instead, as the method change is explicitly prohibited with this status. [301 Moved Permanently - HTTP | MDN](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/301)

这段话指的是在处理 HTTP 重定向时，不同的状态码会对浏览器或用户代理（如 Web 浏览器）的行为有不同的指示，尤其是在处理 HTTP 方法（如 GET, POST, HEAD 等）和请求体的保留方面。

场景: 假设你有一个表单提交到 URL `http://example.com/form`，使用 POST 方法。由于某些原因，这个表单处理的 URL 永久变更到了 `http://example.com/new-form`。

常规做法: 使用 301 状态码来重定向到新的 URL。但是，根据 HTTP/1.0 标准，这可能会导致某些用户代理（特别是旧的浏览器或不完全遵循标准的客户端）在重定向时将 POST 请求改变为 GET 请求，这可能不是预期的行为。

场景: 同样的情况，表单从 `http://example.com/form` 移动到 `http://example.com/new-form`。

更安全的做法: 使用 308 Permanent Redirect。这个状态码明确禁止在重定向过程中改变请求方法。因此，如果原始请求是 POST，重定向后的请求也必须是 POST。这样可以确保重定向行为的一致性和预期性，不管用户代理是什么。

### 303: temporary redirect: 修改请求方法为 GET
  - 303: Seee Other, 看名字就可以知道是 303 是告诉浏览器去另一个页面, 注意是一个页面, 所以浏览器收到 303 请求后, 会用 GET 请求来访问重定向的 URL, 即使之前的请求是 POST 请求. 这个状态码经常是用来做表单提交后的重定向, 即用来回复 POST 和 PUT 请求.
  - The HyperText Transfer Protocol (HTTP) 303 See Other redirect status response code indicates that the redirects don't link to the requested resource itself, **but to another page** (such as a confirmation page, a representation of a real-world object). This response code is often sent back as a result of PUT or POST. The method used to display this redirected page is always GET. 
  - [303 See Other - HTTP | MDN](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/303)


### 307: temporary redirect: 不会修改请求方法和请求体

The method and the body of the original request are **reused** to perform the redirected request.

In the cases where you want the method used to **be changed to GET**, use 303 See Other instead. This is useful when you want to give an answer to a PUT method that is not the uploaded resources, but a confirmation message (like "You successfully uploaded XYZ"). 

The only difference between 307 and 302 is that 307 guarantees that **the method and the body** will not be changed when the redirected request is made. With 302, some old clients were incorrectly changing the method to GET: the behavior with non-GET methods and 302 is then unpredictable on the Web, whereas the behavior with 307 is predictable. For GET requests, their behavior is identical.

Learn more: [307 Temporary Redirect - HTTP | MDN](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/307)

### 308: permanent redirect, 不修改请求方法和请求体

The r**equest method and the body** will not be altered, whereas 301 may incorrectly sometimes be changed to a GET method. 

Learn more: [308 Permanent Redirect - HTTP | MDN](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/308)

### Redirect Code mistakes

Different redirect status code can **cause browser behave differently**. 

An unauthorized user make a request to `/home ` which needs authorized state to access, he will be redirect to `/login`, if server respond 308, then the unauthorized user will be redirect to `/login`, this woks fine. But 308 tell the brower all following http requests for `/home` need be redirected to `/login` even the user login successfully, you can clear the browser cache to reset, make sure don't repond a wrong status code. 
