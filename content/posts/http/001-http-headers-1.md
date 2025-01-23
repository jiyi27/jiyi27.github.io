---
title: HTTP Headers (1)
date: 2023-10-26 09:58:10
categories:
 - http
tags:
 - http
typora-root-url: ../../../static
---

### 0. Header types

Headers can be grouped according to their contexts:

- [Request headers](https://developer.mozilla.org/en-US/docs/Glossary/Request_header) contain more information about the resource to be fetched, or about the client requesting the resource.
- [Response headers](https://developer.mozilla.org/en-US/docs/Glossary/Response_header) hold additional information about the response, like its location or about the server providing it.
- [Representation headers](https://developer.mozilla.org/en-US/docs/Glossary/Representation_header) contain information about the body of the resource, like its [MIME type](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types), or encoding/compression applied.
- [Payload headers](https://developer.mozilla.org/en-US/docs/Glossary/Payload_header) contain representation-independent information about payload data, including content length and the encoding used for transport.

Learn more: [HTTP headers - HTTP | MDN](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers)

### 1. `Content-Type` 

Common values of `Content-Type` header can be `application/json`, `application/x-www-form-urlencoded`, `multipart/form-data`, the first two is usually used with posting form data to server, the third is used to upload file to the server.

- `application/x-www-form-urlencoded`: the keys and values are encoded in key-value tuples separated by `'&'`, with a `'='` between the key and the value. 
  - The format of `application/x-www-form-urlencoded` is `"username=davidzhu&password=778899a" `. 
- The format of `application/json` is `'{"username":"davidzhu", "password":"778899a"}'`. 
- `multipart/form-data`: each value is sent as a block of data ("body part"), with a user agent-defined delimiter ("boundary") separating each part. The keys are given in the `Content-Disposition` header of each part. Usually used to send form data that contains both files and strings. Learn more: check `FormData()` object. 
- `text/plain`

> **Note 1:** If you don't set `Content-Type` header explicitly, the browser will set Content-Type header to `multipart/form-data` automatically. 
>
> **Note 2:** Query String vs `application/x-www-form-urlencoded`
>
> Query string: Appended to the URL after a question mark (?). 
>
> `application/x-www-form-urlencoded`: Sent in the request body

### 2. `Access-Control-Allow-Origin`

> `Access-Control-Allow-Origin` header allows servers to specify which origins **are allowed to access their resources**, even if they are from different origins. 

Learn more: [Cross-origin Request HTTP - David's Blog](https://davidzhu.xyz/post/http/003-cors-sop/)

### 3. `Location`

The **`Location`** response header indicates the URL to redirect a page to. It only provides a meaning when served with a `3xx` (redirection) or `201` (created) status response.

```go
func (s *server) handleMkdir(w http.ResponseWriter, r *http.Request, currentPath string) error {
	// Parse form.
	if err := r.ParseForm(); err != nil {
		err = fmt.Errorf("failed to parse folder name: %v", err)
		return err
	}
  ...

	// clean url and redirect
	r.URL.RawQuery = ""
	w.Header().Set("Location", r.URL.String())
	w.WriteHeader(http.StatusSeeOther)

	return nil
}
```

> Note that `Location` is a response header. 
>
> Ajax call in js doesn't need redirection to go back to the current page. 

Status code 303: [HTTP Status Codes - David's Blog](https://davidzhu.xyz/post/http/002-http-status-codes/)

### 4. `Cache-Control`

`cache-control: no-cache`: This directive means that cached versions of **the requested resource** cannot be used without first checking to see if there is an updated version. `max-age=0` is *a workaround for no-cache* , because many old (HTTP/1.0) cache implementations don't support no-cache. 

`cache-control: private`: A response with a `private` directive can only be cached by the client and never by an intermediary agent, such as a [CDN](https://www.cloudflare.com/learning/cdn/what-is-a-cdn/) or a proxy. These are often resources containing private data, such as a website displaying a user’s personal information. 

`cache-control: public`: Conversely, the `public` directive means the requested resource can be stored by any cache.

When we access a web page, there may have multiple http requests being made, such as `favicon.ico`, `xxx.js`, `xxx.json`, `xxx.png`, for each of these resources there is a http request needed to be sent, and indeed there is a corresponding http response. These resourses are called **the requested resources** above we mentioned. So each of the repsonse have their own http headers:

![a](/001-http-headers/a.png)

![b](/001-http-headers/b.png)

Browser caching is a great way to both preserve resources and improve user experience on the Internet, but without cache-control, it would be very brittle. Every resource on every site would be bound by the same caching rules, meaning that sensitive information would be cached the same way as public information, and **frequently-updated resources would be cached for the same amount of time as ones that rarely change**. 

The code below is written in Go which responsible for handle assets request from client, `favicon.ico` for example.

```go
func RenderAsset(w http.ResponseWriter, r *http.Request, assetPath string) {
	header := w.Header()
	header.Set("Cache-Control", "public, max-age=0")
	http.ServeFile(w, r, filename)
}
```

> **Browser caching** is when a web browser saves website resources so it doesn’t have to fetch them again from a server. For example, a background image on a website might be saved locally in cache so that when a user visits that page for the second time, the image will load from the user’s local files and the page will load much faster.

> **Cookies are HTTP Headers**. The header is called `Cookie:`, and it contains your cookie.

Learn more: [What is cache-control? | Cache explained | Cloudflare](https://www.cloudflare.com/learning/cdn/glossary/what-is-cache-control/)

### 5. `Authorization ` & `WWW-Authenticate`

HTTP supports the use of several authentication mechanisms to control access to pages and other resources. These mechanisms are all based around the use of the `401` status code and the `WWW-Authenticate` response header.

The most widely used **HTTP authentication mechanisms** are:

- **Basic:** the client sends the user name and password as unencrypted base64 encoded text. It should only be used with HTTPS, as the password can be easily captured and reused over HTTP.

- **Digest:** the client sends a hashed form of the password to the server. Although, the password cannot be captured over HTTP, it may be possible to replay requests using the hashed password.
- **NTLM:** this uses a secure challenge/response mechanism that prevents password capture or replay attacks over HTTP. However, the authentication is per connection and will only work with HTTP/1.1 persistent connections. For this reason, it may not work through all HTTP proxies and can introduce large numbers of network roundtrips if connections are regularly closed by the web server.

In this section, we will just discuss the **Basic authentication mechanism**:

If an HTTP receives an anonymous request for a protected resource it can force the use of Basic authentication by rejecting the request with a `401` (Access Denied) status code and setting the `WWW-Authenticate` response header as shown below:

```http
HTTP/1.1 401 Access Denied
WWW-Authenticate: Basic realm="My Server"
Content-Length: 0
```

The word **Basic** in the **WWW-Authenticate** selects the authentication mechanism that the HTTP client must use to access the resource. The **realm** string can be set to any value to identify the secure area and may used by HTTP clients to manage passwords. Most web browsers will display a login dialog when this response is received, allowing the user to enter a username and password. This information is then used to retry the request with an `Authorization` request header:

```http
GET /securefiles/ HTTP/1.1
Host: www.httpwatch.com
Authorization: Basic aHR0cHdhdGNoOmY=
```

The **Authorization** specifies the authentication mechanism (in this case **Basic**) followed by the username and password. Although, the string **aHR0cHdhdGNoOmY=** may look encrypted it is simply a base64 encoded version of <username>:<password>. In this example, the un-encoded string **"httpwatch:foo"** was used and would be readily available to anyone who could intercept the HTTP request.

- The HTTP **`Authorization`** **request header** can be used to provide credentials that authenticate a user agent with a server, allowing access to a protected resource.

- The HTTP **`WWW-Authenticate`** **response header** defines the [HTTP authentication](https://developer.mozilla.org/en-US/docs/Web/HTTP/Authentication) methods ("challenges") that might be used to gain access to a specific resource. 

Learn more: http://www.httpwatch.com/httpgallery/authentication/

> The **`Authorization`** header is usually, but not always, sent after the user agent first attempts to request a protected resource without credentials. The server responds with a [`401`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/401) `Unauthorized` message that includes at least one [`WWW-Authenticate`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/WWW-Authenticate) header. This header indicates what authentication schemes can be used to access the resource (and any additional information needed by the client to use them). 

> **Warning:** The "Basic" authentication scheme used in the diagram above sends the credentials **encoded but not encrypted**. This would be completely insecure unless the exchange was over a secure connection (HTTPS/TLS).

```go
func(w http.ResponseWriter, r *http.Request) {
  
  username, password, ok := r.BasicAuth()
  if ok {
    usernameMatch := subtle.ConstantTimeCompare(usernameHash[:], expectedUsernameHash[:]) == 1
    passwordMatch := subtle.ConstantTimeCompare(passwordHash[:], expectedPasswordHash[:]) == 1
    if usernameMatch && passwordMatch {
      ...
      return
    }
  }
  w.Header().Set("WWW-Authenticate", `Basic realm="restricted", charset="UTF-8"`)
  http.Error(w, "Unauthorized", http.StatusUnauthorized)
}
```

`Basic realm="restricted"`, what does this mean?

In short, endpoints in the same realm should share credentials. If your credentials work for a endpoint with the realm `"restricted"`, it should be assumed that the same username and password combination should work for another endpoint with the same realm.

How to group pages (endpoints) with realm?

`realm` value doesn't have magic, you still need apply the auth middleware for each endpoint at server side. But different value of realm will instruct browser use different credentials (username, password) for the different request url automatically. The concept of realms in the context of authentication is primarily used to instruct the client (typically a web browser) to send different credentials for different request URLs automatically. The server-side implementation still requires applying the authentication middleware to each endpoint. 

Code credit to: [Go BasicAuth](https://www.alexedwards.net/blog/basic-authentication-in-go)

HTTP authentication framework: [HTTP authentication - HTTP | MDN](https://developer.mozilla.org/en-US/docs/Web/HTTP/Authentication)

Learn more: [Authorization - HTTP | MDN](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Authorization)

### 6. cookie

There are two headers related to cookie, one is `Set-Cookie` header another is `Cookie` header. 

After receiving an HTTP request, a server can send one or more [`Set-Cookie`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie) headers with the response. The browser usually stores the cookie and sends it with requests made to the same server inside a [`Cookie`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cookie) HTTP header.

For example, a response from server contains cookie headers may looks like this:

```
HTTP/2.0 200 OK
Content-Type: text/html
Set-Cookie: yummy_cookie=choco
Set-Cookie: tasty_cookie=strawberry

[page content]
```

A HTTP request may looks like this below:

```
GET /sample_page.html HTTP/2.0
Host: www.example.org
Cookie: yummy_cookie=choco; tasty_cookie=strawberry
```

Therefore, when I want set cookie manually for my http request, I'll probably do something like this (I do this in Go):

```go
req, _ := http.NewRequest(http.MethodPost, "/chat", your_encoded_message)
// set content-type header
req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
// set cookie header (cookie is a key value data)
req.Header.Set("Cookie", "session_id=xxxxxxxxxxx")
...
```

If I want get cookie from repsonse, I'll probably retrieve the cookie like this:

```go
response := makeRequest(...)
my_cooke := response.Header().Get("Set-Cookie") 
```

Cookie is just a header which having no doubt resides in the header of HTTP mesages, don't overthinking. 

Reference: https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies#creating_cookies
