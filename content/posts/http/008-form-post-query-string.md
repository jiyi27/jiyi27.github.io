---
title: Form Data & Query String
date: 2023-11-04 00:02:19
categories:
 - http
tags:
 - cybersecurity
 - http
typora-root-url: ../../../static
---

## 1. Form data vs query string

### 1.1. Client side

Query string resides in the url:

```
http://www.blabla.com?a=1&b=2
```

Form data is sent with the request body. Therefore, when there is sensitive data, we usually put data in the form not the query string. Because the requested URL might show up in **Web server logs** and **browser history/bookmarks** which is not a good thing. [source](https://stackoverflow.com/a/830092/16317008)

### 1.2. Server side

#### 1.2.1. Go web

For all requests, `ParseForm()` parses the **raw query** from the URL and updates r.Form. For POST, PUT, and PATCH requests, **it also reads the request body**, parses it as a form and puts the results into both r.PostForm and r.Form. When the `Content-Type` is not application/x-www-form-urlencoded, the request Body is not read. 

Learn more: [Some HTTP Issues with Go - David's Blog](https://davidzhu.xyz/post/golang/practice/012-http-related/#4-parse-form-and-query-string)

#### 1.2.2. Spring web

If your server is wiritten in Java Spring, and you need to POST form data to the server, you need to set your `Content-Type` header of your request to `application/json`. 

When we write test we usually use `curl` command, looks like this:

```shell
$ curl localhost:8080/hello -d '{"username":"davidzhu", "password":"778899a"}'
```

However, this command with `-d` option will set `Content-Type` header to `application/x-www-form-urlencoded`  by default, which is not accepted on Spring's side.

Therefore you have to set `Content-Type` explicitly:

```shell
$ curl localhost:8080/postbody 
		-d '{"username":"davidzhu", "password":"778899a"}' 
		-H "Content-Type: application/json"
```

Note the format of the `-d` is josn format not url query string format: `"username=davidzhu&password=778899a"`, this format is `application/x-www-form-urlencoded`, not `application/json`. 

Source: https://stackoverflow.com/a/7173011/16317008

Learn more about curl post: https://reqbin.com/req/c-dwjszac0/curl-post-json-example

## 2. POST data to server

The **HTTP `POST` method** sends data to the server. The type of the body of the request is indicated by the [`Content-Type`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Type) header.

A `POST` request is typically sent via an [HTML form](https://developer.mozilla.org/en-US/docs/Learn/Forms) and results in a change on the server. In this case, the content type is selected by putting the adequate string in the [`enctype`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/form#enctype) attribute of the [`form`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/form)  element or the [`formenctype`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input#formenctype) attribute of the [`input`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input) or [`button`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/button) elements:

![cc](/008-form-post-query-string/cc.png)

References: https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/POST

## 3. POST data to server - example

Let's say there is a html file looks like this:

```html
<form action="http://localhost:8080/postform" method="post" class="form-example">
    <div class="form-example">
        <label for="username">username</label>
        <input type="text" name="usernam" id="username" required />
    </div>
    <div class="form-example">
        <label for="password">password</label>
        <input type="password" name="passwor" id="password" required />
    </div>
    <div class="form-example">
        <input type="submit" value="register" />
    </div>
</form>
```

When I click the regiser buttion to submit the form, the http request looks like this:

![c](/008-form-post-query-string/c.png)

![d](/008-form-post-query-string/d.png)

As you can see **the form data resides in the request body, not in the URL.**  

Sometimes you send data to server with query string **or** with form. Although, data in this two cases reside in different places, former located in the URL, latter at the payload (request body), these two cases may result same thing (the server will get same data), which may give you a wrong impression that form data wil be put into URL too. 

```shell
$ curl -X POST localhost:8080/postform -d "username=davidzhu&password=778899a" 
$ curl -X POST "localhost:8080/postform?username=david&password=778899a"
```

The server may get same data for these two command, this is because the server may try to parse the query string and form data at the same time, I have talked this in [previous post](https://davidzhu.xyz/post/golang/practice/012-http-related/#4-parse-form-and-query-string). 

## 4. Form data restriction

As we talk above, form data can only be these three type by by default:`application/x-www-form-urlencoded`, `multipart/form-data`, `text/plain`, and you have to set the `Content-Type` to the corresponding type with correct format. 

If you want `application/json` type, you need encode the form data into josn at client and decode the request body at server side. Besides, don't forget to set the `Content-Type` header to `application/json` which will tell the server the data format resides in the request body. 

[An answer](https://stackoverflow.com/a/22195153/16317008) from stackoverflow, hope it will help:

**HTML provides no way to generate JSON from form data**. If you really want to handle it from the client, then you would have to resort to using JavaScript to:

1. gather your data from the form via DOM
2. organise it in an object or array
3. generate JSON with [JSON.stringify](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/stringify)
4. POST it with [XMLHttpRequest](https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/Using_XMLHttpRequest)

You'd probably be better off sticking to `application/x-www-form-urlencoded` data and processing that on the server instead of JSON. Your form doesn't have any complicated hierarchy that would benefit from a JSON data structure.

This is same in Go, if you want send json data in the request body, you should encode it into bytes and decode request body at server:

client:

```go
// string in back quote is raw string which means
// the double quote here will lose its special meaning
// decode the json string into 
reader_json := strings.NewReader(`{"username": "david", "password": "my_password"}`)
r, _ := http.NewRequest(http.MethodPost, "/postbody", reader_json)
r.Header.Set("Content-Type", "application/json")
...
```

server:

```go
// Parse username and password in form.
type info struct {
  Username string `json:"username"`
  Password string `json:"password"`
}
user := info{}
// note that r.Body is an io.Reader
// which means decoder.Decode() method will consume data stroed in r.Body
// you cannot read same data twice
decoder := json.NewDecoder(r.Body)
err := decoder.Decode(&user)
print(user.password)
print(user.username)
```
