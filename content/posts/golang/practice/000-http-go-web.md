---
title: Some HTTP Issues with Go
date: 2023-10-29 11:30:50
categories:
 - golang
 - practice
tags:
 - golang
 - http
---


## 1. `r.URL.Path` vs `r.URL.RawPath`

```go
func main() {
	u, err := url.Parse("http://example.com/x/xx%20a")
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("Path:", u.Path)
	fmt.Println("RawPath:", u.RawPath)
	fmt.Println("EscapedPath:", u.EscapedPath())
}
```

```go
Path: /x/xx a
RawPath: 
EscapedPath: /x/xx%20a
```

If url changes to "http://example.com/x/xx%2Fa", then will print:

```
Path: /x/xx/a
RawPath: /x/xx%2Fa
EscapedPath: /x/xx%2Fa
```

In general, code should call `EscapedPath()` instead of reading `u.RawPath` directly. 

Learn more: 

https://pkg.go.dev/net/url#URL.EscapedPath

[URL Encoding (Percent Encoding) - David's Blog](https://davidzhu.xyz/post/http/009-url-encoding/)

## 2. Relative path

You can write relative path directly for the endpoint, because the browser know the **Origin**, when you make HTTP request, it knows where should go.

```html
<form method="post" action="/login">
  ...
</form>
```

And it's ok to write relative path when redirect in Go code:

```html
// Redirect to login page.
http.Redirect(w, r, "/login", http.StatusFound)
```

## 3. Redirection

### 3.1. Redirect at front end

For redirection, you can use js code to redirect based on the status code passed from server:

```js
const response = await fetch("/login", {
  method: "POST",
  body: data,
})

if (!response.ok) {
  ...
  return
}
// If login successfully, redirect to /home
window.location = "/home"
```

### 3.2. Redirect at server with `Location` header

Learn more: [HTTP Headers - David's Blog](https://davidzhu.xyz/post/http/001-http-headers/)

### 3.3. Redirect at server with `http.Redirect()` method

See above **Relative path** section.

## 4. Check the type of the request

When You are starting a HTTP/s server You use either `ListenAndServe` or `ListenAndServeTLS` or both together on different ports. If You are using just one of them, then from `Listen..` it's obvious which scheme request is using and You don't need a way to check and set it. But if You are serving on both HTTP and HTTP/s then You can use `request.TLS` state. if its `nil` it means it's HTTP.

```golang
// TLS allows HTTP servers and other software to record
// information about the TLS connection on which the request
// was received. This field is not filled in by ReadRequest.
// The HTTP server in this package sets the field for
// TLS-enabled connections before invoking a handler;
// otherwise it leaves the field nil.
// This field is ignored by the HTTP client.
TLS *tls.ConnectionState
```

an example:

```go
func index(w http.ResponseWriter, r *http.Request) {
    scheme := "http"
    if r.TLS != nil {
        scheme = "https"
    }
    w.Write([]byte(fmt.Sprintf("%v://%v%v", scheme, r.Host, r.RequestURI)))
}
```

Source: https://stackoverflow.com/a/76143800/16317008

