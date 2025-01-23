---
title: HTTP Headers (2)
date: 2023-10-30 22:06:07
categories:
 - http
tags:
 - http
typora-root-url: ../../../static
---

### 1. Strict-Transport-Security

Q: Disable HTTP access to the domain, don’t even redirect or link it to SSL. Just inform the users this website is not accessible over HTTP and they have to access it over SSL. 

A: I can't see any technical reason why HTTP needs to be completely blocked either, and **many sites do forward HTTP to HTTPS. When doing this** it is highly advisable to implement HTTP Strict Transport Security (HSTS) which is a web security mechanism which declares that browsers are to only use HTTPS connections.

HSTS is implemented by specifying a **response header** such as `Strict-Transport-Security: max-age=31536000`. Complying user agents will automatically turn insecure links into secure links, thereby reducing the risk of man-in-the-middle attacks. 

Source: [security - Is redirecting http to https a bad idea? - Stack Overflow](https://stackoverflow.com/questions/4365294/is-redirecting-http-to-https-a-bad-idea)

Learn more: [Common Network Attacks - David's Blog](https://davidzhu.xyz/post/networking/004-common-attacks/)

### 2. keep-alive

HTTP keep-alive, a.k.a., HTTP persistent connection, is an instruction that allows a single TCP connection to remain open for multiple HTTP requests/responses.

By default, HTTP connections close after each request. When someone visits your site, their browser needs to create new connections to request each of the files that make up your web pages (e.g. images, Javascript, and CSS stylesheets), a process that can lead to high [page load times](https://www.imperva.com/learn/performance/page-load-time/).

Enabling the keep-alive header allows you to serve all web page resources **over a single TCP connection**. Keep-alive also reduces both CPU and memory usage on your server.

Learn more: [What is HTTP Keep Alive | Benefits of Connection Keep Alive | Imperva](https://www.imperva.com/learn/performance/http-keep-alive/)

### 3. user-agent

The **User-Agent** [request header](https://developer.mozilla.org/en-US/docs/Glossary/Request_header) is a characteristic string that lets servers and network peers identify the application, operating system, vendor, and/or version of the requesting [user agent](https://developer.mozilla.org/en-US/docs/Glossary/User_agent).
