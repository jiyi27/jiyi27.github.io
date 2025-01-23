---
title: Interfaces Basics - Go
date: 2023-12-07 15:12:32
categories:
 - golang
 - basics
tags:
 - golang
---

## 1. Type `Admin` isn't `*Adimin`

I found an [interesting question](https://stackoverflow.com/questions/37851500/how-to-copy-an-interface-value-in-go/37851764#37851764) on stackoverflow, this is the code:

```go
type User interface {
	Name() string
	SetName(name string)
}

type Admin struct {
	name string
}

func (a *Admin) Name() string {
	return a.name
}

func (a *Admin) SetName(name string) {
	a.name = name
}
```

OP tries to copy `user1`'s value below:

```go
func main() {
    var user1 User
    user1 = &Admin{name:"user1"}

    fmt.Printf("User1's name: %s\n", user1.Name())

    var user2 User
    user2 = user1
    user2.SetName("user2")

    fmt.Printf("User2's name: %s\n", user2.Name()) // print: "user2"
    fmt.Printf("User1's name: %s\n", user1.Name()) // print: "user2" too, How to make the user1 name does not change？
}
```

Everything pass by value in Golang, even assignment will make a copy. Therefore, I tried something like this:

```go
var user1 User
user1 = &Admin{name:"user1"}
fmt.Printf("User1's name: %s\n", user1.Name())
var user2 User
user2 = *user1 // got an error: Invalid indirect of 'user1' (type 'User')
```

The erorr says that user's type is `User` not `*User`, so cannot dereference it. Why `user1 = &Admin{name:"user1"}` works fine?

An error occurred again below:

```go
var user1 User
user1 = Admin{name:"user1"} 
// error: Cannot use 'Admin{name:"user1"}' (type Admin) as the type User Type does not implement 'User' as the 'Name' method has a pointer receiver. 
```

This is confusing, it says type `Admin` doesn't implement interface `User`. You may wonder, you lied, `Admin` has implemented all methods of `User`, but wait, really?

In fact, it's not type `Admin` implementing interface `User` but type `*Admin`. Checking the definition of `Name()` and `SetName()` above, both of these two method have a pointer receiver, not a value receiver. This means **the `Name()` and `GetName()` method are in the [method set](https://golang.org/ref/spec#Method_sets) of the `*Admin` type, but not in that of `Admin`.**

## 2. Any types can implement an interface

"Any types can implement an interface." is not accurate. 

Any type can have its [method set](https://golang.org/ref/spec#Method_sets), and if there are all the methods of an interfacce in that type's method set, we say this type implements this interface. This type can be a struct, function, map, array even an integer. 

### 2.1. Array

Get multiple parameters from cli with `flag` package:

```go
func Var(value Value, name string, usage string)
```

According to the [docs](https://pkg.go.dev/flag#Var), custom a type `userFlag` to implement interface `flag.Value`:

```go
type usersFlag []user

func (u *usersFlag) String() string {
	return fmt.Sprintf("%v", *u)
}

func (u *usersFlag) Set(value string) error {
	values := strings.Split(value, ":")
	if len(values) != 3 {
		return fmt.Errorf("wrong format of auth, format: path:username:password")
	}
	*u = append(
		*u,
		user{
			username: values[1],
			password: values[2],
			path:     formatPath(values[0]),
		},
	)
	return nil
}
```

Then you can use as follows:

```go
type Param struct {
	users []user
}

func (p *Param) init() {
	var users usersFlag

	flag.Var(&users, "auth", fmt.Sprintf("-auth <path:username:password>\n"+
		"specify user for HTTP Basic Auth"))

	flag.Parse()
	p.users = users
}
```

### 2.2. function

There is another function called `http.Handle()` can be used to set routing info and callback, which has a different parameter compared with function `http.HandleFunc()`:

```go
func Handle(pattern string, handler Handler)
```

The second pamrameter is a `Handler` which is an interface type defined in http package:

```go
type Handler interface {
	ServeHTTP(ResponseWriter, *Request)
}
```

Function type `customHandler` implements interface `http.Handler`:

```go
type customHandler func(http.ResponseWriter, *http.Request)

func (mwh customHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		http.Error(w, "method not supported", http.StatusMethodNotAllowed)
		return
	}
	_, _ = fmt.Fprintf(w, "do something before custom handler mwh(w, r)")
	mwh(w, r)
}

func main() {
	callback := customHandler(func(w http.ResponseWriter, r *http.Request) {
		_, _ = fmt.Fprintf(w, "hello there")
	})
	
  // customHandler implemented interface http.Handler, so its object can passed here
	http.Handle("/hello", callback)
	log.Fatal(http.ListenAndServe(":8080", nil))
}
```

**NOTE:** for struct, when you gengerate a value ("object") you should use curly brcket `{}` as below:

```go
type Cat struct {
  name string
  age int
}

cat := Cat{name: "Kitten", age: 3}
```

for a function  type, we use parentheses to produce a value of that type:

```go
type myWebHandler func(http.ResponseWriter, *http.Request)

callback := myWebHandler(func(w http.ResponseWriter, r *http.Request) {
		_, _ = fmt.Fprintf(w, "hello there")
})
```

## 3. Essence of interface variables


An interface is conceptually a `struct` with two fields. If we were to describe an interface in Go, it would look something like this.

```go
type interface struct {
       Type uintptr     // points to the type of the interface implementation
       Data uintptr     // holds the data for the interface's receiver
}
```

`Type` points to a structure that describes the type of the value that implements this interface. `Data` points to the value of the implementation itself. The contents of `Data` are passed as the receiver of any method called via the interface.

The [Go memory model](http://golang.org/ref/mem) says that writes to a single machine word will be atomic, but interfaces are two word values. It is possible that another goroutine may observe the contents of the interface value while it is being changed. 

Learn more: https://dave.cheney.net/2014/06/27/ice-cream-makers-and-data-races
