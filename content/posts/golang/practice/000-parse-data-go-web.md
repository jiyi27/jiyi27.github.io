---
title: Parse Data - Go Web
date: 2023-09-23 18:08:55
tags:
 - golang
 - http
---

## 1. Parse Query String and `x-www-form-urlencoded` Format Body

```go
if e := r.ParseForm(); err != nil {
  err = fmt.Errorf("failed to parse username and password: %v", e)
  return
}
username = r.Form.Get("username")
password = r.Form.Get("password")
```

According to  [Golang docs](https://pkg.go.dev/net/http#Request.ParseForm), `r.ParseForm()` will try to parse both query string and request body in Go, but there is a condition: the `Content-Type` header of the reuqest must be `application/x-www-form-urlencoded`. Otherwise, the request body will be ignored by `r.ParseForm()`, it just tries to parse query string resides in the URL. 

> If you don't know query string or `application/x-www-form-urlencoded`: https://blog.yorforger.cc/p/http-headers-1/

First, there is a simple handler which parses form data or query string:

```go
func handlePostForm(w http.ResponseWriter, r *http.Request) {
	// r.ParseForm() parses username and password in form or query string.
  // And puts the parsed data into r.Form which is a map value.
	if err := r.ParseForm(); err != nil {
		http.Error(w, fmt.Sprintf("failed to parse username and password: %v", err),
			http.StatusMethodNotAllowed)
		return
	}
	username := r.Form.Get("username")
	password := r.Form.Get("password")
	if username == "" || password == "" {
		http.Error(w, "failed to parse username and password: no username or password",
			http.StatusMethodNotAllowed)
		return
	}
	_, _ = fmt.Fprint(w, fmt.Sprintf("username:%v password:%v\n", username, password))
}

func main() {
	mux := http.NewServeMux()
  // Add pattern and its handdler into mux
	mux.HandleFunc("/postform", handlePostForm)
  // http.ListenAndServe will call mux.ServerHTTP(w, r)
	_ = http.ListenAndServe(":8080", mux)
}
```

And the request below will get same result:

```shell
$ curl -X POST "localhost:8080/postform?username=david&password=778899a"
$ curl -X POST localhost:8080/postform -d "username=davidzhu&password=778899a"
```

But the code below won't work, because the `Content-Type` header is not `application/x-www-form-urlencoded`:

```shell
$ curl -X POST localhost:8080/postform 
	-d "username=davidzhu&password=778899a" 
	-H "Content-Type: application/json"
	
failed to parse username and password: no username or password
```

## 2. `RawQuery` vs `Query()`

If there are whitespaces in query string, the [whitespace will be encoded](https://stackoverflow.com/a/1211256/16317008) to `%20` or `+` automatically, js code:

```javascript
async function getUrl(filepath) {
    const url = "?asset=" + "back ground.png"
    let response = await fetch(url)
    ...
}
```

The request URL will be: `http://localhost:8080?filepath=back%20ground.png`. Therefore, if you use `r.URL.RawQuery` in Go:

```go
log.Println(r.URL.RawQuery)
log.Println(r.URL.Query())
```

This will print:

```
2023/10/29 12:19:36 filepath=back%20ground.png
2023/10/29 12:19:36 map[filepath:[back ground.png]]
```

As you can see, `r.URL.RawQuery` isn't friendly to string with whitespace, you should try to use `r.URL.Query()` to emliminate the `%20` characters. 

So the recommended way is as below:

```go
func (s *server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// handle asset.
	const assetPrefix = "asset="
	if strings.HasPrefix(r.URL.RawQuery, assetPrefix) {
    // r.URL.Query() returns a map[string][]string
		assetName := r.URL.Query()[strings.TrimSuffix(assetPrefix, "=")][0]
		s.asset(w, r, assetName)
		return
	}
  ...
}
```

## 3. Parse Json Data from Request Body

```go
func handlePostBody(w http.ResponseWriter, r *http.Request) {
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
	if err != nil {
		http.Error(w, fmt.Sprintf("failed to decode post body:%v", err),
			http.StatusMethodNotAllowed)
	}
	_, _ = fmt.Fprint(w, fmt.Sprintf("username:%v password:%v\n", user.Username, user.Password))
}
```

The command below won't work:

```shell
$ curl -X POST localhost:8080/postbody 
	-d "username=davidzhu&password=778899a" 
	-H "Content-Type: application/json"
failed to decode post body:invalid character 'u' looking for beginning of value
username: password:
```

Because the data format isn't correct, this will work:

```shell
$ curl localhost:8080/postbody -d '{"username":"davidzhu", "password":"778899a"}' 
```
