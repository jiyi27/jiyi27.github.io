---
title: Goroutines Model
date: 2023-08-24 14:58:18
categories:
 - golang
 - advance
tags:
 - golang
 - concurrency
---

## 1.  Two Styles of Concurrent Programming

Go enables two styles of concurrent programming.

- *communicating sequential processes* or *CSP*
  - goroutines and channels
- *shared memory multithreading*
  - traditional model
  - multiple threads

## 2. Goroutines vs OS Threads

- Creation and Destruction
  - Creating and destroying OS threads requires interacting with the operating system, involving system calls.
  - Go routines managed by Go scheduler, in user space, no system calls. 
- Context Switching
  - needs a full context switch in os thread
- Level of Operation
  - User Space Level vs Kernel Space Level
  - Goroutines are multiplexed onto a smaller number of OS threads.
- Stack Size
  - growable stack vs fixed-size stack

### 2.1. Growable Stacks

Each **OS thread** has a fixed-size block of memory (often as large as 2MB) for its *stack*. This fixed-size stack is simultaneously too much and too little. Yet despite their size, fixed-size stacks are not always big enough for the most complex and deeply recursive of functions. Changing the fixed size can improve space efficiency and allow more threads to be created, or it can enable more deeply recursive functions, but it cannot do both.

In contrast, a goroutine starts life with a small stack, typically 2KB. A goroutine’s stack, like the stack of an OS thread, holds the local variables of active and suspended function calls, but unlike an OS thread, **a goroutine’s stack is not fixed; it grows and shrinks as needed**. The size limit for a goroutine stack may be as much as 1GB.

### 2.2. Goroutine Scheduling

**OS threads are scheduled by the OS kernel**. Every few milliseconds, a hardware timer interrupts the processor, which causes a kernel function called the *scheduler* to be invoked. This function suspends the currently executing thread and saves its registers in memory, looks over the list of threads and decides which one should run next, restores that thread’s registers from memory, then resumes the execution of that thread. Because OS threads are scheduled by the kernel, passing control from one thread to another requires **a full *context switch*, that is, saving the state of one user thread to memory, restoring the state of another, and updating the scheduler’s data structures**. This operation is slow, due to its poor locality and the number of memory accesses required

The Go runtime contains its own scheduler that uses a technique known as ***m:n scheduling***, because it multiplexes (or schedules) *m* goroutines on *n* OS threads. The job of the Go scheduler is analogous to that of the kernel scheduler, but it is concerned only with the goroutines of a single Go program. 

Unlike the operating system’s thread scheduler, the Go scheduler is not invoked periodically by a hardware timer, but implicitly by certain Go language constructs. For example, when a goroutine calls `time.Sleep` or blocks in a channel or mutex operation, the scheduler puts it to sleep and runs another goroutine until it is time to wake the first one up. Because it doesn’t need a switch to kernel context, rescheduling a goroutine is much cheaper than rescheduling a thread.

## 3. Goroutine Model

go-routines are **user-space threads** not **kernel threads**, kernel threads created and managed by OS (sleep, wait, running), OS doesn't know user-space threads exist, Go shcduler multiplexes (or schedules) *m* goroutines on *n* OS threads, which is known as ***m:n scheduling***. 

Learn how goroutine works:

{% youtube YHRO5WQGh0k %}

### 3.1. Physical Thread vs Kernel Thread

> A "hardware thread" is just a confusing name for a logical core, aka execution context. It has nothing to do with software threads or kernel threads. One physical core may support more than 1 logical core, e.g. via hyperthreading or other SMT. 
>
> A hardware thread is a set of registers that are able to hold the [*context*](https://en.wikipedia.org/wiki/Context_switch) of a software thread. Having two "hardware threads" enables a single CPU to concurrently execute the instructions of two software threads without help from the OS. P.S.: If a software thread is like an automobile, then a hardware thread is like a lane on a highway in which the automobile can drive. OK, that's kind of a weak anaology, but what I'm trying to say is that a "hardware thread" and a thread in your program don't have much more in common with each other than the lane on the highway has in common with your car.
>
> --[multithreading - Kernel threads VS CPU threads - Stack Overflow](https://stackoverflow.com/questions/73308353/kernel-threads-vs-cpu-threads)

Learn more [Hyper-Threading & Physical Threads ](https://davidzhu.xyz/2023/05/28/Operating-System/001-cpu-architecture/) 

无论语言层面何种并发模型, 到了操作系统一定是运行在 kernel thread 上的, 上面我们说到Go的做法是把多个 user-space threads 映射到一个 kernel thread, 以减少kernel thread切换时带来的消耗, 那其他语言怎么做的呢? 在C++里, 是通过syscall直接调用OS的kernel thread, 线程所有的行为如创建, 终止, 切换等操作都由内核来完成, 一个用户态的线程对应一个系统线程, 这时候C++在频繁创建删除thread的时候就要考虑上下文切换的开销了, 因为操作的直接是kernel thread, 比如来一个tcp连接就创建一个thread, 开销太大了, 所以这时候就出现了线程池, 说到底我们就是想要减少kernel thread创建切换的次数, 以减少开销,  你看无论C++还是Go都有自己的解决办法, 前者是通过thread pool来对kernel thread重复利用, 而后者因为通过map 多个goroutine到较少个kernel thread, 实现对kernel thread的重复利用, 减少上下文切换的次数, 减少开销, 

## 4. Frequently Asked Questions (FAQ)

### 4.1. why goroutines instead of threads?

Goroutines are part of making concurrency easy to use. The idea, which has been around for a while, is to multiplex independently executing functions—coroutines—onto a set of threads. When a coroutine blocks, such as by calling a blocking system call, the run-time automatically moves other coroutines on the same operating system thread to a different, runnable thread so they won't be blocked. The programmer sees none of this, which is the point. The result, which we call goroutines, can be very cheap: they have little overhead beyond the memory for the stack, which is just a few kilobytes. 

To make the stacks small, Go's run-time uses resizable, bounded stacks. A newly minted goroutine is given a few kilobytes, which is almost always enough. When it isn't, the run-time grows (and shrinks) the memory for storing the stack automatically, allowing many goroutines to live in a modest amount of memory. The CPU overhead averages about three cheap instructions per function call. It is practical to create hundreds of thousands of goroutines in the same address space. If goroutines were just threads, system resources would run out at a much smaller number.

### 4.2. why is there no goroutine ID?

Goroutines do not have names; they are just anonymous workers. They expose no unique identifier, name, or data structure to the programmer. Some people are surprised by this, expecting the `go` statement to return some item that can be used to access and control the goroutine later.

The fundamental reason goroutines are anonymous is so that the full Go language is available when programming concurrent code. By contrast, the usage patterns that develop when threads and goroutines are named can restrict what a library using them can do.

Here is an illustration of the difficulties. Once one names a goroutine and constructs a model around it, it becomes special, and one is tempted to associate all computation with that goroutine, ignoring the possibility of using multiple, possibly shared goroutines for the processing. If the `net/http` package associated per-request state with a goroutine, clients would be unable to use more goroutines when serving a request.

Moreover, experience with libraries such as those for graphics systems that require all processing to occur on the "main thread" has shown how awkward and limiting the approach can be when deployed in a concurrent language. The very existence of a special thread or goroutine forces the programmer to distort the program to avoid crashes and other problems caused by inadvertently operating on the wrong thread.

For those cases where a particular goroutine is truly special, the language provides features such as channels that can be used in flexible ways to interact with it.

## 5. Conclusion

- OS thread has a fixed-size block of memory (as large as 2MB) for its *stack*.
- A goroutine starts life with a small stack, typically 2KB but goroutine’s stack is not fixed. 
- Thread stack holds the local variables of active and suspended function calls.
- OS threads are scheduled by the OS kernel, Go runtime contains its own scheduler that uses a technique known as ***m:n scheduling***, goroutine is much cheaper than rescheduling a thread. 

A great bolg: [Share memory by communicating · The Ethically-Trained Programmer](https://blog.carlmjohnson.net/post/share-memory-by-communicating/)


参考:

- [9.8 Goroutines and Threads | The Go Programming Language](https://learning.oreilly.com/library/view/the-go-programming/9780134190570/ebook_split_094.html)
- [Frequently Asked Questions (FAQ) - The Go Programming Language](https://go.dev/doc/faq)
- [GopherCon 2018: Kavya Joshi - The Scheduler Saga](https://www.youtube.com/watch?v=YHRO5WQGh0k)
- [multithreading - Kernel threads VS CPU threads - Stack Overflow](https://stackoverflow.com/questions/73308353/kernel-threads-vs-cpu-threads)
- 书籍《Go并发编程实战》
- [Effective Go - The Go Programming Language](https://go.dev/doc/effective_go#introduction)
- https://zhuanlan.zhihu.com/p/60613088