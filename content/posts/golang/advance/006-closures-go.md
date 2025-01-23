---
title: Function Closures - Go
date: 2023-09-18 23:32:55
categories:
 - golang
 - practice
tags:
 - golang
---

Previous post: [First-Class Functions - Go - David's Blog](https://davidzhu.xyz/post/golang/basics/012-first-class-functions/)

## 1. What is closure

> Go functions may be closures. A closure is a function value that references variables from outside its body. The function may access and assign to the referenced variables; in this sense the function is "bound" to the variables.
>
> [Closures - A Tour of Go](https://go.dev/tour/moretypes/25)

```go
func adder() func(int) (int, *int) {
	sum := 0
	return func(x int) (int, *int) {
		sum += x
		return sum, &sum
	}
}

func main() {
	pos, neg := adder(), adder()
	for i := 1; i <= 3; i++ {
		sum, addr := pos(i)
		fmt.Println("pos:  ", sum, " ", addr)
		sum, addr = neg(-i)
		fmt.Println("neg: ", sum, " ", addr)
	}
}

//--------------------------
pos:   1   0x140000b0018
neg:  -1   0x140000b0020
pos:   3   0x140000b0018
neg:  -3   0x140000b0020
pos:   6   0x140000b0018
neg:  -6   0x140000b0020
```

As we see above,  when the anonymous function defined in the `adder()` access `sum`, it looks like accessing a global variable, even the function `adder()` has returned we still can access variable `sum`. However, there are "two" `sum` actually, they are isolated and each has its own address. 

You should note that we return an anonymous function here, function is first-class citizen in golang just like javascript, it's a gift don't fear it. 

## 2. Use cases

## 2.1. Pass behaviour

```go
type Mux struct {
	mu    sync.Mutex
	conns map[net.Addr]net.Conn
}

func (m *Mux) Add(conn net.Conn) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.conns[conn.RemoteAddr()] = conn
}

func (m *Mux) Remove(addr net.Addr) {
	m.mu.Lock()
	defer m.mu.Unlock()
	delete(m.conns, addr)
}

func (m *Mux) SendMsg(msg string) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	for _, conn := range m.conns {
		_, err := io.WriteString(conn, msg)
		if err != nil {
			return err
		}
	}
	return nil
}
```

Is this what we call idiomatic in Go? Maybe. This is our first proverb **don't mediate the access to shared memory with locks and mutexes** instead share that memory by communicating. 

```go
type Mux struct {
	add     chan net.Conn
	remove  chan net.Addr
	sendMsg chan string
}

func (m *Mux) Add(conn net.Conn) {
	m.add <- conn
}

func (m *Mux) Remove(addr net.Addr) {
	m.remove <- addr
}

func (m *Mux) SendMsg(msg string) error {
	m.sendMsg <- msg
	return nil
}

func (m *Mux) loop() {
  // only one goroutine can access this map, 
  // don't need lock
	conns := make(map[net.Addr]net.Conn)
	for {
		select {
		case conn := <-m.add:
			conns[conn.RemoteAddr()] = conn
		case addr := <-m.remove:
			delete(conns, addr)
		case msg := <-m.sendMsg:
			for _, conn := range conns {
				_, _ = io.WriteString(conn, msg)
			}
		}
	}
}
```

We don't need the mutex anymore because the shared sate this `conns` map is now local to the `loop()` function, it can't be mutated by anybody else. There cannot be a (data) race because it only exists within the scope of that function. 

But there's still a lot of hard-coded logic in here, `loop()` only knows how to do three things, it only knows how to `add`, `remove` and `sendMsg`. If we wanted to extend our `Mux`,  it would involve three things

- adding a channel
- adding a helper (function) to send data over that channel
- and then opening up the `select` logic inside loop and adding the knowledge of how to process  that data

But we can rewrite our `Mux` to use first-class functions **to pass the behavior we want to be executed** not the data to interpret. 

```go
type Mux struct {
	ops chan func(map[net.Addr]net.Conn)
}

func (m *Mux) Add(conn net.Conn) {
	m.ops <- func(m map[net.Addr]net.Conn) {
		m[conn.RemoteAddr()] = conn
	}
}

func (m *Mux) Remove(addr net.Addr) {
	m.ops <- func(m map[net.Addr]net.Conn) {
		delete(m, addr)
	}
}

func (m *Mux) SendMsg(msg string) error {
	m.ops <- func(m map[net.Addr]net.Conn) {
		for _, conn := range m {
			_, _ = io.WriteString(conn, msg)
		}
	}
	return nil
}

func (m *Mux) loop() {
	conns := make(map[net.Addr]net.Conn)
	for op := range m.ops {
		op(conns)
	}
}
```

But there are a few little problems to fix, the lack of error handling inside `sendMsg`,  if there's an error of writing to one of the connections that's just going to be discarded. To handle the error generated inside the anonymous function that we pass into loop we need to create a channel to communicate with the result of the operation. 

```go
func (m *Mux) SendMsg(msg string) error {
	result := make(chan error, 1)
	m.ops <- func(m map[net.Addr]net.Conn) {
		for _, conn := range m {
			_, err := io.WriteString(conn, msg)
			if err != nil {
				result <- err
				return
			}
		}
		result <- nil
	}
	return <-result
}

func (m *Mux) PrivateMsg(addr net.Addr, msg string) (int, error) {
	result := make(chan net.Conn, 1)
	m.ops <- func(m map[net.Addr]net.Conn) {
		result <- m[addr]
	}
	conn := <-result
	if conn == nil {
		return 0, fmt.Errorf("client %v not registered", addr)
	}
	return io.WriteString(conn, msg)
}
```

I was wondering can I just replace the channel with just a error value in `sendMsg()` method, like this:

```go
func (m *Mux) SendMsg(msg string) error {
	var result error
	m.ops <- func(m map[net.Addr]net.Conn) {
		for _, conn := range m {
			_, err := io.WriteString(conn, msg)
			if err != nil {
				result = err
				return
			}
		}
		result = nil
	}
	return result
}
```

The answer is no, I cann't, the `result` has to be a channel here. Because the closure defined in `SendMsg` is sent somewhere else (via the `m.ops` chan) to get executed - I need to get the `result` from the channel to block the `SendMsg` at the last `return <-result` - the `result` channel is a synchronization point. [source](https://www.reddit.com/r/golang/comments/16mfvne/comment/k19lmtm/?utm_source=share&utm_medium=web2x&context=3) 

- First class functions let you pass around behaviour, not just dead data that must be interpreted.
- First class functions aren't new or novel.
- Like the other features, first class functions should be used with restraint.
- First class functions are something that every Go programmer should have in their toolbox.
- First class functions aren't hard, just a little unfamiliar, and that is something that can be overcome with practice.

> Next time you define an API it has just one method I want you to ask yourself: should this really just be a function.

Don't overuse channel, learn more: https://davidzhu.xyz/post/golang/advance/008-do-not-overuse-cahnnel

Source: [dotGo 2016 - Dave Cheney - Do not fear first class functions](https://www.youtube.com/watch?v=5buaPyJ0XeQ&list=WL&index=1) 

{{% youtube "5buaPyJ0XeQ" %}}

## 2.2. Creating middleware

Middleware is basically a fancy term for reusable function that can run code both before and after your code designed to handle a web requst. In Go these are typically accomplished with closures, but in different programming languages they may be achieved in other ways.

Middleware is very helpful in scenarios where we need to perform common tasks on incoming HTTP requests, such as authentication, authorization, request validation, and logging. Middleware allows us to apply these tasks consistently across our application, reducing code duplication and making it easier to maintain and modify our code.

There are several middleware functions that are commonly used in web applications, including:

1. **Authentication middleware**: This middleware checks whether the user is authenticated and authorized to access the requested resource.
2. **Logging middleware**: This middleware logs information about incoming requests, including request method, URL, headers, and response status.
3. **Error handling middleware**: This middleware catches errors that occur during request handling and returns an appropriate error response to the client.
4. **Request validation middleware**: This middleware validates incoming requests to ensure that they meet certain criteria, such as HTTP method, headers, query parameters, and request body content.
5. **Caching middleware:** This middleware caches responses to certain requests to improve performance and reduce server load.
6. **Request Tracing**: This middleware is used to trace the path of a request through a web application. It captures relevant information about the request and logs it for monitoring and debugging purposes.

```go
func main() {
  http.HandleFunc("/hello", timed(hello))
  http.ListenAndServe(":3000", nil)
}

func timed(f func(http.ResponseWriter, *http.Request)) func(http.ResponseWriter, *http.Request) {
  return func(w http.ResponseWriter, r *http.Request) {
    start := time.Now()
    f(w, r)
    end := time.Now()
    fmt.Println("The request took", end.Sub(start))
  }
}

func hello(w http.ResponseWriter, r *http.Request) {
  fmt.Fprintln(w, "<h1>Hello!</h1>")
}
```

Notice that our `timed()` function takes in a function that could be used as a handler function, and returns a function of the same type, but the returned function is different that the one passed it. The closure being returned logs the current time, calls the original function, and finally logs the end time and prints out the duration of the request. All while being agnostic to what is actually happening inside of our handler function.

Now all we need to do to time our handlers is to wrap them in `timed(handler)` and pass the closure to the `http.HandleFunc()` function call.

References:

- [5 Useful Ways to Use Closures in Go - Calhoun.io](https://www.calhoun.io/5-useful-ways-to-use-closures-in-go/)
-  [Mastering Middleware in Go: Tips, Tricks, and Real-World Use Cases | by ansu jain | Medium](https://medium.com/@ansujain/mastering-middleware-in-go-tips-tricks-and-real-world-use-cases-79215e72b4a8) 
-  [Function Closures - A Tour of Go](https://go.dev/tour/moretypes/25)