---
title: Cookie & Session
date: 2023-08-17 07:39:56
categories:
  - cs basics
tags:
  - cs basics
---

众所周知，HTTP 是一个无状态协议，所以客户端每次发出请求时，下一次请求无法得知上一次请求所包含的状态数据，如何能把一个用户的状态数据关联起来呢？

比如在淘宝的某个页面中，你进行了登陆操作。当你跳转到商品页时，服务端如何知道你是已经登陆的状态？

## 1. cookie

首先产生了 cookie 这门技术来解决这个问题, cookie 是 http 协议的一部分, 它的处理分为如下几步:

- 服务器向客户端发送 cookie
  - 通常使用 HTTP 协议规定的 set-cookie 头操作
  - 规范规定 cookie 的格式为 name=value 格式, 且必须包含这部分
- 浏览器将 cookie 保存
- 每次请求浏览器都会将 cookie 发向服务器

> 浏览器可以自动发送 cookie, 即不用在前端写 js 代码手动发送, 服务器返回 cookie 的时需指定 Expires/MaxAge 参数, 客户端浏览器收到 response 后(也包括 cookie), 若 cookie 的 MaxAge 时间已过, 则浏览器会自动设置此 cookie 为 invalid, 之后发送请求并不会带上该 cookie, 另外 Expires/MaxAge只用指定其一, 但是未来兼容一些老浏览器如 IE, 有时候会同时设置 MaxAge 和 Expires 
>
> 了解更多: https://stackoverflow.com/a/35729939/16317008

其他可选的 cookie 参数会影响将 cookie 发送给服务器端的过程，主要有以下几种：

- path：表示 cookie 影响到的路径，匹配该路径才发送这个 cookie。
- expires 和 maxAge：告诉浏览器这个 cookie 什么时候过期，expires 是 UTC 格式时间，maxAge 是 cookie 多久后过期的相对时间。当不设置这两个选项时，会产生 session cookie，session cookie 是 transient 的，当用户关闭浏览器时，就被清除。一般用来保存 session 的 session_id。
- secure：当 secure 值为 true 时，cookie 在 HTTP 中是无效，在 HTTPS 中才有效。
- httpOnly：浏览器不允许脚本操作 document.cookie 去更改 cookie。一般情况下都应该设置这个为 true，这样可以避免被 xss 攻击拿到 cookie。

> 上面说到的 expires 格式是 UTC, 意味着服务器把 cookie 传给客户端时, 若设置了 expires, 则需要先处理一下时间即把格式转为 UTC 格式, 规定 expires 格式必须时 UTC 的原因是客户端与服务器可能不在同一个时区, 比如服务器所在位置时区为 UTC-3,  客户端的时区为 UTC, 此时服务器比 UTC 慢了三小时, 此时若服务器直接设置 cookie expires 为 Now() + 30, 指的是半小时后过期, 可是传到客户端立刻过期了, 因为客户端浏览器默认来自服务器的 cookie expires 是 UTC, 

下面就是服务器传回 cookie expires 没有为其指定时区的例子, 可以看到请求是 Jun 20 发出的, cookie 过期时间却是 Jun 19: 

![1](/005-session-cookie/1.png)

服务器端 Python Flask 处理 http request时, 设置 cookie 方式如下:

```python
@app.route("/")
def index():
    session = request.cookies.get('session_id')
    # 为客户端设置 cookie, 以便之后来自它的请求不用验证身份 login
    if session_id is None:
    	resp = make_response(render_template('index.html'))
    	resp.set_cookie('session', session,
                       # 这里使用相对时间, 不用设置时区
                    	 max_age=datetime.timedelta(minutes=2),
                    	 httponly=True)
    	# 其它逻辑 ...
    	return resp
    # 其它逻辑 ...
```

> All HTTP date/time stamps MUST be represented in Greenwich Mean Time (GMT), without exception. For the purposes of HTTP, GMT is exactly equal to UTC (Coordinated Universal Time). [source](https://stackoverflow.com/a/35729939/16317008)
>
> *Both GMT and UTC display the same time*. 

## 2. session

> Session 和 Cookie 的目的相同, 都是为了弥补 HTTP 协议无状态的缺陷, Session 和 Cookie 都是用来保存客户端状态信息的手段, 不同之处在于 Cookie 是存储在客户端浏览器方便客户端请求时使用, Session 是存储在服务端用于存储客户端连接状态信息的, 从存储的数据类型来看, Cookie仅支持存储字符串, Session可支持多种数据类型 [source](https://studygolang.com/articles/34361)

http 是无状态的, 即下一次请求无法得知上一次请求所包含的状态数据, 所以产生了 cookie, 使服务器可以“记住”客户端, 大致逻辑为:

- 服务器处理响应客户端时顺带返回一个 cookie object
- 客户端(浏览器) 发送 http request 时, 顺带发送一个 cookie object (若此时浏览器有相关cookie, 且没过期)

cookie 在服务器端产生, 之后在客户端和服务器之间往返发送, 因此 cookie 不能保存比较重要的隐私数据, 可是很多时候服务器需要临时记住客户端的信息, 此时就产生了 session 的概念, 即在服务器内存维护一个数据结构, 用来临时保存每个客户端的数据, 然后为每份数据设置一个 session_id, 处理 http request 时, 先查看其 cookie 里有没有 session_id 字段: 

- 若存在就根据此 id 确定该请求的身份, 这样服务器就知道你是上次访问过的某某某, 然后从服务器的存储中取出上次记录在你身上的数据, 

- 否则新建一个 session, 然后把该 session 的 session_id 放到 cookie 里, (在cookie里设置 seesion_id 字段), 这样, 服务器既能把用户的重要信息安全保存, 又能确认每个请求的身份, 即把重要信息存在服务器不外露, 通过 session_id 来匹配 session 和 http request, 

所以 cookie 就是用来传递 session_id 的东西, 而 session_id 则用来唯一标识 session, 即会话, session 就是个数据结构, 用来临时存储一个会话的信息, 如客户端A, B, 与 服务器 S 之间,则有两个 session, A - S, B - S

## 3. session 存储

Session在服务端是如何存储的呢？

服务端可采用哈希表来保存Session内容，一般而言可在内存中创建相应的数据结构，不过一旦断电内存中所有的会话数据将会丢失。因此可将会话数据写入到文件或保存到数据库，虽然会增加I/O开销，但可以实现某种程序的持久化，也更有利于共享。

session 可以存放在: 

- 内存
- cookie 本身
- redis 或 memcached 等缓存中
- 数据库中

缓存的方案比较常见, 存数据库的话, 查询效率相比前三者都太低, 不推荐

参考: 

- https://gist.github.com/HellMagic/6e49af318d45311ee2860ac7d7bf09f6
- [Go Session - Go语言中文网 - Golang中文社区](https://studygolang.com/articles/34361)

了解更多:

- [Go 每日一库之 gorilla/securecookie - 大俊的博客](https://darjun.github.io/2021/07/23/godailylib/gorilla/securecookie/)
- [Go 每日一库之 gorilla/sessions - 大俊的博客](https://darjun.github.io/2021/07/25/godailylib/gorilla/sessions/)