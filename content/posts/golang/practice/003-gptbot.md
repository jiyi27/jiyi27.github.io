---
title: Golang Web - A Simple gptbot with Openai API
date: 2023-08-18 09:20:57
categories:
 - golang
 - practice
tags:
 - golang
---

## 1. Introduction

Source Code: [gptbot](https://github.com/shwezhu/gptbot)

## 2. Database - gorm

> Don't `Open` db connection for each request, initialize a global DB and use it for all requests.
>
> `Close` is one of the most misused methods, most application don't need it, be sure you really need it.
>
> it is not necessary to close when crash, and you can still `Close` DB connection in V2. 
>
> [jinzhu - creator of gorm](https://github.com/go-gorm/gorm/issues/3145)

```go
func main() {
	db, _ := gorm.Open(sqlite.Open("gpt_bot.db"), &gorm.Config{})
  store, _ := redistore.NewRediStore(10, "tcp", ":6379", "", []byte(os.Getenv("SESSION_KEY")))
  ...
  http.Handle("/login", LoginHandler(db, store))
}
```

As you can see, we use a global database connection here accross all handler, and it's worth noticing that **every HTTP request that comes in to the server gets its own goroutine**. Therefore, you have to consider data race in the handers. 

Because we share the `db` across all handlers, we have to consider that if `db` is thread-safe. I find [some answers](https://stackoverflow.com/questions/61822921/does-gorm-open-create-a-new-connection-pool-every-time-its-called) on stack overflow which explains well:

Does gorm.Open() create a new connection pool every time it's called?

yes, try to reuse the returned DB object. 

[gorm.Open](https://github.com/jinzhu/gorm/blob/v1.9.12/main.go#L58) does the following: (more or less):

1. lookup the driver for the given dialect
2. call `sql.Open` to return a `DB` object
3. call `DB.Ping()` to force it to talk to the database

This means that the recommendations for [sql.Open](https://golang.org/pkg/database/sql/#Open) apply to `gorm.Open`:

> **The returned DB is safe for concurrent** use by multiple goroutines and maintains its own pool of idle connections. Thus, the Open function should be called just once. It is rarely necessary to close a DB.

Also note that the connection pool can be configured as such, in both GORM v1 and v2:

```go
// SetMaxIdleConns sets the maximum number of connections in the idle connection pool.
db.DB().SetMaxIdleConns(10)
// SetMaxOpenConns sets the maximum number of open connections to the database.
db.DB().SetMaxOpenConns(100)
// SetConnMaxLifetime sets the maximum amount of time a connection may be reused.
db.DB().SetConnMaxLifetime(time.Hour)
// d, err := db.DB()
// d.SetMaxIdleConns(10)
```

## 3. Session - gorilla/session

### 3.1. encode before save

When try to save data in session, we usually use the `Values` field of session, for example,

```go
session.Values["username"] = "Jack"
```

The first problem I came across is that, you can save `int`, `bool`, `string` and other basic value into `session.Values[]` directly, but when you try to assign other type value, custom object, array to `session.Values["xxx"]` for example, you have to encode the value before assignment, so that `gorilla/session can` save data to Redis and read correctly for later request . Otherwise, you cannot get the value corrctly, I mean, after you **restart your server**, you cannot get the session stored in the Redis, **the `IsNew` will be always `true`,** this is because the encoing issues, 

I want to save a slice into session, which is chat history, so I have to encode it before assign it to `session.Values["messages"]`, I'll choose `encoding/json` here, you can choose other encoding tech, `encoding/gob `for example, 

```go
// chatHistory == []openai.ChatCompletionMessage
data, _ := json.Marshal(chatHistory)
session.Values["messages"] = data
```

Bacause `json.Marshal(chatHistory)` encodes the object I passed in and return as a `[]byte`, so the type of the variable `data` above is `[]byte`, so I set `session.Values["messages"]` as a emtpy byte slice at begining, when login, 

```go
func initSession(session *sessions.Session) error {
	session.Options.MaxAge = 20
	session.Values["authenticated"] = true
	session.Values["messages"] = []byte{}
	return nil
}
```

When you want get message that stored in session, you just need to get the encoded value which is  `[]byte`, and pass it to `json.Unmarshal()`, this function will convert the encoded value back to golang object, 

[go - gorilla/sessions persistent between server restarts? - Stack Overflow](https://stackoverflow.com/questions/45196950/gorilla-sessions-persistent-between-server-restarts)

### 3.2. reset MaxAge whenever call `session.Save`

I don't know if I did it wrong, or it's a bug in `gorilla/sessions`, for example, I set the `MaxAge` of the session to 60 seconds when user first logged in I create session, and for later request, for example, user will send request for talking with chatGPT, and during this process, the server will update the history message which stored in `session.Values["messages"]`, after update the value of  `session.Values["messages"]`, we should call `session.Save()` so that this update can be saved for later request, 

But this will make `session.Options.MaxAge` back to its defalult value, which is 30 days, so you should set it again when you call  `session.Save()`, 

```go
...
session.Values["messages"] = data
// set MaxAge whenever you call session.Save(r, w)
session.Options.MaxAge = 24 * 3600
_ = session.Save(r, w)
```

Otherwise, the session stored in Redis won't be deleted until 30 days later, and your user will keep logged in satus for 30 days, 

[go - Sessions variables in golang not saved while using gorilla sessions - Stack Overflow](https://stackoverflow.com/questions/21865681/sessions-variables-in-golang-not-saved-while-using-gorilla-sessions)

Return and wrap error in low layer function (try to provide more context info), only handle errors and log info on the top of the function call stack. 

```go
func parseUsernamePassword(r *http.Request) (*map[string]string, error) {
	userInfo := make(map[string]string)
	if err := r.ParseForm(); err != nil {
    // wrap error which can provide more context info
    // usually, say: "failed to" + "function name" + "error"
    // but not always
		return nil, fmt.Errorf("falied to parse username and password: %v", err)
	}
  ...
}

func updateMessage(w http.ResponseWriter, r *http.Request, store *redistore.RediStore) error {
	session, err := store.Get(r, "session_id")
	if err != nil {
		return fmt.Errorf("cannot update message: %v", err)
	}
  ...
	if err = session.Save(r, w); err != nil {
		return fmt.Errorf("cannot update message: %v", err)
	}
  ...
}
```

Learn more: [Error handling - Go - David's Blog](https://davidzhu.xyz/post/golang/basics/008-error-handling/)

## 4. Session or redis cache

I did some experiments , found that a query with gorm for sqlite3 takes about 380us, it's not that much, and there will no that many users can overwhelm my server, so I finally decide query the `tokens` value from database everytime when user make a request to chat with ChatGPT, 

```go
// https://stackoverflow.com/a/45791377/16317008
start := time.Now()
err = db.Limit(1).Find(&user, "username = ?", (*userInfo)["username"]).Error
t := time.Now()
fmt.Println(t.Sub(start))
--------------------------------
1.514166ms // first time
542.125µs
387.625µs
484.958µs
477.417µs
377.959µs
..
```

## 5. Session store

sessions need a place to store, in-memory, file or Redis, package [gorilla/sessions](https://github.com/gorilla/sessions) provides two way to save sessions, one is file, another is in-memory, 

```go
var store = sessions.NewCookieStore([]byte(os.Getenv("SESSION_KEY")))
// or 
var store =  NewFilesytemStore("path/to/file", []byte(os.Getenv("SESSION_KEY")))
```

I choose redis to save sessions with [redistore](https://github.com/boj/redistore) library, which implements a redis store based on [gorilla/sessions](https://github.com/gorilla/sessions), 

```go
var store, _ = redistore.NewRediStore(10, "tcp", ":6379", "", []byte(os.Getenv("SESSION_KEY")))
```

You can use [gorilla/sessions](https://github.com/gorilla/sessions) which help you save session in-memory, if you want save sessions on a redis server too, you have to install Redis on your computer, learn more about session and Redis: 

- [Introduce Redis | 橘猫小八的鱼](https://davidzhu.xyz/2023/08/18/Database/Redis/001-intro-redis/)
- [Cookie & Session | 橘猫小八的鱼](https://davidzhu.xyz/2023/08/17/CS-Basics/005-session-cookie/)
- [Go 每日一库之 gorilla/sessions - 大俊的博客](https://darjun.github.io/2021/07/25/godailylib/gorilla/sessions/)
- [GoAuthentication/readme.md at master · karankumarshreds/GoAuthentication](https://github.com/karankumarshreds/GoAuthentication/blob/master/readme.md)
