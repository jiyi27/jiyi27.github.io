---
title: HTTP Messages
date: 2023-09-23 09:51:30
categories:
 - http
tags:
 - http
typora-root-url: ../../../static
---

## 1. Intro of HTTP messages

There are two types of messages: ***requests*** sent by the client to trigger an action on the server, and ***responses***, the answer from the server.

HTTP requests, and responses, share similar structure and are composed of:

1. A `start-line` describing the requests to be implemented, or its status of whether successful or a failure. This start-line is always a single line.
2. An optional set of `HTTP headers` specifying the request, or describing the body included in the message.
3. A `blank line` indicating all meta-information for the request has been sent.
4. An optional `body` containing data associated with the request (like content of an HTML form), or the document associated with a response. The presence of the body and its size is specified by the start-line and HTTP headers.

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2024/08/a4f4596c8e375a14960ad3c0db7c931d.png)

The `start-line` and `HTTP headers` of the HTTP message are collectively known as the ***head*** of the requests, whereas its `payload` is known as the ***body***.

## 2. HTTP Requests

### 2.1. Start line

A start line contains three parts:

- Their *start-line* contain three elements:
  - An HTTP method, a verb (like `GET`, `PUT` or `POST`) or a noun (like HEAD or OPTIONS), that describes the action to be performed. 

> GET 请求的结果可被浏览器和其他中间件(代理服务器)缓存，并且可能会被重复执行（例如，用户刷新页面时）。
> 如果你是在用户点击某个按钮后通过 GET 请求来处理点赞功能，那么理论上，仅当用户再次点击这个按钮时，该 GET 请求才会被重新发送。如果你的前端逻辑确保了每次点击都对应一个点赞操作，那么不会因为浏览器页面刷新而导致重复提交。然而，即使是这种情况，使用 GET 请求来处理点赞动作仍然不是最佳实践，原因包括：
> 非幂等性：点赞操作是非幂等的，因为每次操作都改变了服务器上的状态（即增加了点赞计数）。而 GET 请求应当是幂等的，即多次执行相同的请求应该具有相同的副作用。在这种情况下，多次点击按钮会导致多次点赞，违反了 GET 请求的幂等性原则。

- The *request target* 
  - Usually a URL
  - Sometimes url followed by a `'?'` and **query string**: `http://example.com/?bar1=a&bar2=b`

- The *HTTP version*

```
POST www.example.com/test.html?username=alibaba HTTP/1.1
```

### 2.2. Headers

An HTTP header consists of its case-insensitive name followed by a colon (`:`), then by its value. Whitespace before the value is ignored. This is an HTTP header:

```
Content-Type: text/html; charset=utf-8
```

Usually, a request or response consist of many headers:

```
GET /home.html HTTP/1.1
Host: developer.mozilla.org
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:50.0) Gecko/20100101 Firefox/50.0
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: en-US,en;q=0.5
Accept-Encoding: gzip, deflate, br
Referer: https://developer.mozilla.org/testpage.html
Connection: keep-alive
```

As you can see above, there are 7 headers in this request, a header like a key-value string, **different header usually has different syntax and its own type**. For example:

The type of [`Accept header`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept) is a [ Request header](https://developer.mozilla.org/en-US/docs/Glossary/Request_header), and its syntax is below:

``` 
Accept: <MIME_type>/<MIME_subtype>
Accept: <MIME_type>/*
Accept: */*

// Multiple types, weighted with the quality value syntax:
Accept: text/html, application/xhtml+xml, application/xml;q=0.9, image/webp, */*;q=0.8
```

The type of  [`Content-Type header`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Type) is [Representation header](https://developer.mozilla.org/en-US/docs/Glossary/Representation_header), and its syntax:

```
Content-Type: text/html; charset=utf-8
Content-Type: multipart/form-data; boundary=something
```

The offcial way to indicate aobve is:

Many different headers can appear in an HTTP request. They can be divided in several groups:

- [General headers](https://developer.mozilla.org/en-US/docs/Glossary/General_header), like [`Via`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Via), apply to the message as a whole.
- [Request headers](https://developer.mozilla.org/en-US/docs/Glossary/Request_header), like [`User-Agent`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/User-Agent) or [`Accept`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept), modify the request by specifying it further (like [`Accept-Language`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Language)), by giving context (like [`Referer`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Referer)), or by conditionally restricting it (like [`If-None`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-None)).
- [Representation headers](https://developer.mozilla.org/en-US/docs/Glossary/Representation_header) like [`Content-Type`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Type) that describe the original format of the message data and any encoding applied (only present if the message has a body).

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2024/08/9e388793983a1fdf0afb5f3e51305a73.png)

### 2.3. Body

The final part of the request is its body. Not all requests have one: requests fetching resources, like `GET`, `HEAD`, `DELETE`, or `OPTIONS`, usually don't need one. Some requests send data to the server in order to update it: as often the case with `POST` requests (containing HTML form data).

Bodies can be broadly divided into two categories:

- Single-resource bodies, consisting of one single file, defined by the two headers: [`Content-Type`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Type) and [`Content-Length`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Length).
- [Multiple-resource bodies](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types#multipartform-data), consisting of a multipart body, each containing a different bit of information. This is typically associated with [HTML Forms](https://developer.mozilla.org/en-US/docs/Learn/Forms).

## 3. HTTP Responses

HTTP Reponse also contains three parts:

- Status line
  -  Three part:  *protocol version*, a *status code*, a *status text* (A brief, purely informational, textual description of the status code to help a human understand the HTTP message.)
  - `HTTP/1.1 404 Not Found`

- Headers
  - Same as http request.

- Body
  - Same as http request.

Reference: [HTTP Messages - HTTP | MDN](https://developer.mozilla.org/en-US/docs/Web/HTTP/Messages)
