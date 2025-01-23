---
title: Goroutine & Channel - Go Basics
date: 2023-08-24 10:06:10
categories:
 - golang
 - basics
tags:
 - golang
 - concurrency
---

## 1. Goroutines

When a program starts, its only goroutine is the one that calls the `main` function, so we call it the *main goroutine*. The `go` statement itself completes immediately:

```go
f()    // call f(); wait for it to return
go f() // create a new goroutine that calls f(); don't wait
```

The code below will just print `hello`, this because when `main` function returns, all goroutines are abruptly terminated and the program exits. 

```go
func main() {
	go func() {
		time.Sleep(time.Millisecond * 100)
		fmt.Println("hello form another goroutine")
	}()
	fmt.Println("hello")
}
```

Other than (除了) by returning from `main` or exiting the program, there is no programmatic way for one goroutine to stop another, but there are ways to communicate with a goroutine to request that it stop itself.

## 2. Channels

A Go channel is a means of communication that enables data sharing between goroutines. Each channel has a type associated with it. 

```go
data := <- ch // read from a channel ch  
ch <- data // write to a channel ch
```

### 2.1. Unbuffered channel 

This creates an unbuffered channel of type `int`. An unbuffered channel is one that can only hold one value at a time. 

```go
ch := make(chan int)
```

Sends and receives on an unbuffered channel will block until the corresponding operation is ready to proceed. Run this will cause a dealock error, 

```go
func main() {
	ch := make(chan int)
  // This send operation will block until there is a receive operation
  // ready to proceed.
	ch <- 42
  // This receive operation will block until there is a send operation
  // ready to proceed.
	val := <-ch
	fmt.Println(val)
}
```

With the nature of unbuffered channel, we can do something like this:

```go
func main() {
	ch := make(chan bool)
	go func() {
		// Do some work
		ch <- true
	}()
	// Wait for the goroutine to finish on another goroutine,
	// main() function for example
	<-ch
}
```

### 2.2. Buffered channel

You can also specify the buffer size of a channel when creating it. A buffered channel allows for multiple values to be stored in the channel at once before they shall be read.

```go
ch := make(chan int, 3)
```

### 2.3. Buffered channel vs unbuffered channel 

`ch := make(chan int, 1)` is totally different from `ch := make(chan int)`, the code below won't get deadlock error: 

```go
func main() {
	ch := make(chan int, 1)
	ch <- 42
  // if you put another "ch <- 42" below, there will be a deadlock error
	val := <-ch
	fmt.Println(val)
}
```

### 2.4. Read & send on closed channel

#### 2.4.1 Read on a closed channel

A closed channel returns the default value of that type:

```go
func main() {
	c := make(chan bool, 1)
	c <- true
	fmt.Println(<-c)
	close(c)
	fmt.Println(<-c)
    fmt.Println(<-c)
}
------------------------------
true
false
false
```

We can also check whether a channel is open or closed with the help of the given syntax:

```go
ele, ok:= <- channel_name
```

If the value of `ok` is true, this indicates that the channel is open and read operations can be done. 

#### 2.4.2 Send and close a closed channel

Send or close a ***closed channel*** will cause panic. 

```go
ch = make(chan bool)
ch <- true
close(ch)
// this will get a panic
ch <- true
```

> Don't close a channel from the receiver side and don't close a channel if the channel has multiple concurrent senders. -> Don't close (or send values to) closed channels.
> Close channel elegantly: https://qcrao91.gitbook.io/go/channel/ru-he-you-ya-di-guan-bi-channel

### 2.5. Read & send on a nil channel

An attempt to **send/read** value on a ***nil channel*** will block that goroutine forerver.

```go
func main() {
	s := make(chan bool, 1)
	s<- true
	<-s
	go func() {
		s = nil
		s<- true
		fmt.Println("hello from goroutine 2")
	}()
	fmt.Println("hello from goroutine 1")
	time.Sleep(time.Second * 3)
	fmt.Println("hi from goroutine 1 after seconds")
}
---------------------------------------

hello from goroutine 1
hi from goroutine 1 after seconds
```

> If you don't know whether a channel is closed or not and blindly write to it, then you have a badly designed program. Redesign it so that there is no way to write into it after it is closed. [A comment from Stack Overflow](https://stackoverflow.com/questions/39213230/how-to-test-if-a-channel-is-close-and-only-send-to-it-when-its-not-closed)

How to know if a channel is closed only by sending value to it? Answer: You can't. 

learn more: https://stackoverflow.com/a/61101887/16317008

### 3. Should a channel has to be closed

It's OK to leave a Go channel open forever and never close it. When the channel is no longer used, **it will be garbage collected**.

> Note that it is only necessary to close a channel if the receiver is looking for a close. Closing the channel is a control signal on the channel indicating that no more data follows.
>
> [Design Question: Channel Closing](https://groups.google.com/d/msg/golang-nuts/pZwdYRGxCIk/qpbHxRRPJdUJ)

Source: https://stackoverflow.com/a/8593986/16317008

## 4. Use cases of channels

### 4.1. Synchronization between goroutines

Traditional threading models require the programmer to communicate between threads using shared memory. Typically, shared data structures are protected by locks, and threads will contend over those locks to access the data. Instead of explicitly using locks to mediate access to shared data, Go encourages the use of channels to pass references to data between goroutines. 

Channels **can be used to** ensure that one goroutine doesn't proceed until another goroutine has completed its work. This is particularly useful in scenarios where data needs to be shared between two or more goroutines, and it's important to ensure that the data isn't modified by multiple goroutines at the same time. 

> **NOTE:** Channels **can be used to** ensure one goroutine doesn't proceed until another goroutine has completed its work. Doesn't mean channels ensure that itself. You need to implement this by utilizing channel. This is the channel use case for notification. 

```go
// main goroutine won't exit until the worker goroutine has completed its work.
// this is channel's use case for notification
// you can use this to ensue that data isn't modified by multiple goroutines at a same time.
func main() {
	done := make(chan struct{})

	go func() {
		fmt.Println("working...")
		time.Sleep(time.Second)
		fmt.Println("done")
		done<- struct{}{}
	}()

	<-done
}
```

Actually, in essence, synchronization between goroutines implemented by channel is just a channel's use case for notification. 

> The code above only can limit one groutine access the data at a time, if you want to prevent concurrent modifications to a variable **while retaining the ability to read**, which means enables more than one groutine to access the data, you'd typically embed a [sync.RWMutex](https://golang.org/pkg/sync/#RWMutex). This is no exemption. 

When you pass a data let's say `cat` to an unbuffered channel in a goroutine `g1`, this operation let's say `ch <- cat` will block until another goroutine let's say`g2` takes `cat` out from the channel. After the `g2` got data, this is done,  `ch <- cat`  won't block. Then `g2` can do anything to your `cat` and `g1` can also access `cat`, which means you have to consider data race even you send your data with channel. For example. when you pass a `cat` to a channel, what if `cat` has a slice or a pointer in its field? Whenver use channel pass value, you should remember that everything passed by value in go, and the direct value not the underlying value. You pass a pointer to a channel, there is a copy for an address, not the underlying value that pinter point to. 

But there is an exception, you pass a simple value to channel not struct value, not slice, not a map or pointer value, just a `int`, `string` value because these simple value has no underlying values, and everything passed by value, when a `int` passed to a channel, there is a copy for that `int` value, therefore you don't need to consider data race. 

For large objects like arrays or large structs, passing a pointer is usually the logical thing to do to avoid expensive copies. But you should consider and promise that when one gouroutine **write the data**, there is no other goroutine access that data. You can use `sync.RWMutex`, you can add another for notification after the writing operation is done by using the blocking nature of a channel. 

Learn more: [go - does passing pointer through channel break the csp design?](https://stackoverflow.com/questions/70456785/golang-does-passing-pointer-through-channel-break-the-csp-design)

### 4.2. Use channels for notifications

Notifications can be viewed as special requests/responses in which the responded values are not important. Generally, we use the blank struct type `struct{}` as the element types of the notification channels, for the size of type `struct{}` is zero, hence values of `struct{}` doesn't consume memory.

### 4.3. Use Channels as counting semaphores

This is the buffered channel's use case, this blog gives an excellent example:  [Share memory by communicating · The Ethically-Trained Programmer](https://blog.carlmjohnson.net/post/share-memory-by-communicating/) 

```go
// Share memory by communicating
// https://blog.carlmjohnson.net/post/share-memory-by-communicating/

package semaphores

type Semaphore struct {
	acquire chan bool
	release chan struct{}
	stop chan chan struct{}
}

func New(n int) *Semaphore {
	s := Semaphore{
		acquire:  make(chan bool),
		release:  make(chan struct{}),
		stop:     make(chan chan struct{}),
	}
	go s.start(n)
	return &s
}

func (s *Semaphore) start(max int) {
	count := 0

	for {
		var acquire = s.acquire

		// nil always blocks sends and read operation
		if count >= max {
			acquire = nil
		}

		select {

		case acquire <- true:
			count++

		case s.release <- struct{}{}:
			count--

		case wait := <-s.stop:
			close(s.acquire)

			// Drain remaining calls to Release
			for count > 0 {
				s.release <- struct{}{}
				count--
			}
			close(wait)
			return
		}
	}
}

// Acquire a closed channel returns its default value as many times as it is called.
// if s.acquire is closed, the Acquire() get called in other goroutine will return false immediately
// if s.acquire is not closed, and no data written into it, Acquire() will block
func (s *Semaphore) Acquire() bool {
	return <-s.acquire
}

func (s *Semaphore) Release() {
	<-s.release
}

func (s *Semaphore) Stop() {
	blocker := make(chan struct{})
	s.stop <- blocker
	<-blocker
}
```

References:

- [Share Memory By Communicating - The Go Programming Language](https://go.dev/blog/codelab-share)
- [Understanding Go Channels: An Overview for Beginners](https://www.atatus.com/blog/go-channels-overview/)
- [Closing the Channel in Golang - Scaler Topics](https://www.scaler.com/topics/golang/closing-the-channel-in-golang/)
- [Share memory by communicating · The Ethically-Trained Programmer](https://blog.carlmjohnson.net/post/share-memory-by-communicating/)

Learn more: [Channel Use Cases -Go 101](https://go101.org/article/channel-use-cases.html) 
