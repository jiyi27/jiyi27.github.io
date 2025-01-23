---
title: Go Scheduler (2)
date: 2023-05-28 18:06:20
categories:
 - golang
 - advance
tags:
 - golang
 - concurrency
typora-root-url: ../../../../static
---

## 0. Parrallelism is not concurrency

**Parallelism** is about multiple tasks or subtasks of the same task that literally run at the same time on a hardware with multiple computing resources like multi-core processor, while **concurrency** is about multiple tasks which start, run, and complete in overlapping time periods, in no specific order. 

## 1. Your program starts

When your Go program starts up, it’s given a **Logical Processor (P)** for every **virtual core** that is identified on the host machine. If you have a processor with multiple **hardware threads** per **physical core** (**Hyper-Threading**), each hardware thread will be presented to your Go program as a virtual core. To better understand this, take a look at the system report for my MacBook Pro. 

Hyper-Threading: one physical core corresponds to two virtual cores. And one virtual core can run one hadware thread at a same time. 

<img src="/004-go-scheduler-2/a.png" alt="a" style="zoom:33%;" /> 

You can see I have a single processor with 4 physical cores. What this report is not exposing is the number of hardware threads I have per physical core. The Intel Core i7 processor has Hyper-Threading, which means there are 2 hardware threads per physical core. This will report to the Go program that 8 virtual cores are available for executing OS Threads in parallel. 

To test this, consider the following program:

```go
func main() {
    // NumCPU returns the number of logical
    // CPUs usable by the current process.
    fmt.Println(runtime.NumCPU())
}
```

When I run this program on my local machine, the result of the `NumCPU()` function call will be the value of 8. Any Go program I run on my machine will be given 8 P’s. 

Every P is assigned an OS Thread (“M”). The ‘M’ stands for machine. This Thread is still managed by the OS and the OS is still responsible for placing the Thread on a Core for execution, as explained in the [last post](https://www.ardanlabs.com/blog/2018/08/scheduling-in-go-part1.html). This means when I run a Go program on my machine, I have 8 threads available to execute my work, each individually attached to a P.

Every Go program is also given an initial Goroutine (“G”), which is the path of execution for a Go program. A Goroutine is essentially a Coroutine but this is Go, so we replace the letter “C” with a “G” and we get the word Goroutine. You can think of Goroutines as application-level threads and they are similar to OS Threads in many ways. Just as **OS Threads are context-switched on and off a core, Goroutines are context-switched on and off an M.** 

The last piece of the puzzle is the **run queues**. There are two different run queues in the Go scheduler: the Global Run Queue (GRQ) and the Local Run Queue (LRQ). **Each P is given a LRQ that manages the Goroutines assigned to be executed within the context of a P**. (这句话也就说明了 多个goroutine映射到一个kernel thread, 减少kernel thread上下文切换的次数.) These Goroutines take turns being context-switched on and off the M assigned to that P. The GRQ is for Goroutines that have not been assigned to a P yet. There is a process to move Goroutines from the GRQ to a LRQ that we will discuss later.  

M和P是一一对应的关系, M机器即用来运行Goroutine的,  而P拥有一个runqueue, 这个runqueue里面有多个等待被M执行的goroutine, 在M上只能同时运行一个goroutine, 所以当go scheduler要switch 一个goroutine的时候, 这时候进行goroutine上下文切换, 注意这里不是对kernel thread, 即M进行上下文切换, 

<img src="/004-go-scheduler-2/b.png" alt="b" style="zoom:33%;" /> 

根据图可以看出, 一个kernel thread维护一个runqueue, 请参考: https://youtu.be/YHRO5WQGh0k

另外的我电脑是芯片是M1, 信息如下:

```
Total Number of Cores: 8 (4 performance and 4 efficiency)
```

执行上面Go程序, 仍为8, 推断M1没有利用Hyper-Threading技术, 这个技术是Intel的, 当然其他制造商也有类似技术, 

## 2. Cooperating scheduler

As we discussed in the first post, the OS scheduler is a **preemptive scheduler**. Essentially that means you can’t predict what the scheduler is going to do at any given time. The kernel is making decisions and everything is non-deterministic. Applications that run on top of the OS have no control over what is happening inside the kernel with scheduling unless they leverage synchronization primitives like [atomic](https://en.wikipedia.org/wiki/Linearizability) instructions and [mutex](https://en.wikipedia.org/wiki/Lock_(computer_science)) calls.

The Go scheduler is part of the Go runtime, and the Go runtime is built into your application. This means the Go scheduler runs in [user space](https://en.wikipedia.org/wiki/User_space), above the kernel. The current implementation of the Go scheduler is not a preemptive scheduler but a [cooperating](https://en.wikipedia.org/wiki/Cooperative_multitasking) scheduler. Being a cooperating scheduler means the scheduler needs well-defined user space events that happen at safe points in the code to make scheduling decisions.

What’s brilliant about the Go cooperating scheduler is that it looks and feels preemptive. You can’t predict what the Go scheduler is going to do. This is because decision making for this cooperating scheduler doesn’t rest in the hands of developers, but in the Go runtime. It’s important to think of the Go scheduler as a preemptive scheduler and since the scheduler is non-deterministic, this is not much of a stretch.

## 3. Goroutine states

Just like Threads, Goroutines have the same three high-level states. These dictate the role the Go scheduler takes with any given Goroutine. A Goroutine can be in one of three states: *Waiting*, *Runnable* or *Executing*.

**Waiting**: This means the Goroutine is stopped and waiting for something in order to continue. This could be for reasons like waiting for the operating system (system calls) or synchronization calls (atomic and mutex operations). These types of [latencies](https://en.wikipedia.org/wiki/Latency_(engineering)) are a root cause for bad performance.

**Runnable**: This means the Goroutine wants time on an M so it can execute its assigned instructions. If you have a lot of Goroutines that want time, then Goroutines have to wait longer to get time. Also, the individual amount of time any given Goroutine gets is shortened as more Goroutines compete for time. This type of scheduling latency can also be a cause of bad performance.

**Executing**: This means the Goroutine has been placed on an M and is executing its instructions. The work related to the application is getting done. This is what everyone wants.

## 4. Context switching

The Go scheduler requires well-defined user-space events that occur at safe points in the code to context-switch from. These events and safe points manifest themselves within function calls. Function calls are critical to the health of the Go scheduler. Today (with Go 1.11 or less), if you run any tight loops that are not making function calls, you will cause latencies within the scheduler and garbage collection. It’s critically important that function calls happen within reasonable timeframes.

*Note: There is a [proposal](https://github.com/golang/go/issues/24543) for 1.12 that was accepted to apply non-cooperative preemption techniques inside the Go scheduler to allow for the preemption of tight loops.*

There are four classes of events that occur in your Go programs that allow the scheduler to make scheduling decisions. This doesn’t mean it will always happen on one of these events. It means the scheduler gets the opportunity.

- The use of the keyword `go`
- Garbage collection
- System calls
- Synchronization and Orchestration

**System calls**

**If a Goroutine makes a system call that will cause the Goroutine to block the M**, sometimes the scheduler is capable of **context-switching the Goroutine off the M** and **context-switch a new Goroutine onto that same M**. However, sometimes a new M is required to keep executing Goroutines that are queued up in the P. How this works will be explained in more detail in the next section. 

**Synchronization and Orchestration**

If an atomic, mutex, or channel operation call will cause the Goroutine to block, the scheduler can context-switch a new Goroutine to run. Once the Goroutine can run again, it can be re-queued and eventually context-switched back on an M.

## 5. Asynchronous system calls

When the OS you are running on has the ability to handle a system call asynchronously, something called the [network poller](https://golang.org/src/runtime/netpoll.go) can be used to process the system call more efficiently. This is accomplished by using kqueue (MacOS), epoll (Linux) or iocp (Windows) within these respective OS’s.

Networking-based system calls can be processed asynchronously by many of the OSs we use today. This is where the network poller gets its name, since its primary use is handling networking operations. By using the network poller for networking system calls, the scheduler can prevent Goroutines from blocking the M when those system calls are made. This helps to keep the M available to execute other Goroutines in the P’s LRQ without the need to create new Ms. This helps to reduce scheduling load on the OS.

The best way to see how this works is to run through an example.

<img src="/004-go-scheduler-2/c.png" alt="c" style="zoom:33%;" />

Figure 3 shows our base scheduling diagram. Goroutine-1 is executing on the M and there are 3 more Goroutines waiting in the LRQ to get their time on the M. The network poller is idle with nothing to do.

<img src="/004-go-scheduler-2/d.png" alt="d" style="zoom:33%;" />

In figure 4, Goroutine-1 wants to make a network system call, so Goroutine-1 is moved to the network poller and the asynchronous network system call is processed. Once Goroutine-1 is moved to the network poller, the M is now available to execute a different Goroutine from the LRQ. In this case, Goroutine-2 is context-switched on the M.

<img src="/004-go-scheduler-2/e.png" alt="e" style="zoom:33%;" />

In figure 5, the asynchronous network system call is completed by the network poller and Goroutine-1 is moved back into the LRQ for the P. Once Goroutine-1 can be context-switched back on the M, the Go related code it’s responsible for can execute again. The big win here is that, to execute network system calls, no extra Ms are needed. The network poller has an OS Thread and it is handling an efficient event loop.

## 6. Synchronous system calls

What happens when the Goroutine wants to make a system call that can’t be done asynchronously? In this case, the network poller can’t be used and the Goroutine making the system call is going to block the M. This is unfortunate but there’s no way to prevent this from happening. One example of a system call that can’t be made asynchronously is file-based system calls. If you are using CGO, there may be other situations where calling C functions will block the M as well.

*Note: The Windows OS does have the capability of making file-based system calls asynchronously. Technically when running on Windows, the network poller can be used.*

Let’s walk through what happens with a synchronous system call (like file I/O) that will cause the M to block.

<img src="/004-go-scheduler-2/f.png" alt="f" style="zoom:33%;" />

Figure 6 is showing our basic scheduling diagram again but this time Goroutine-1 is going to make a synchronous system call that will block M1.

<img src="/004-go-scheduler-2/g.png" alt="g" style="zoom:33%;" />

In figure 7, the scheduler is able to identify that Goroutine-1 has caused the M to block. At this point, the scheduler detaches M1 from the P with the blocking Goroutine-1 still attached. Then the scheduler brings in a new M2 to service the P. At that point, Goroutine-2 can be selected from the LRQ and context-switched on M2. If an M already exists because of a previous swap, this transition is quicker than having to create a new M.

<img src="/004-go-scheduler-2/h.png" alt="h" style="zoom:33%;" />

In figure 8, the blocking system call that was made by Goroutine-1 finishes. At this point, Goroutine-1 can move back into the LRQ and be serviced by the P again. M1 is then placed on the side for future use if this scenario needs to happen again.

到这我们也可以理解为什么说P是连接M和G的桥梁, P维护一个runqueue, 里面存的是等待被M执行G, M执行G时从和他连接的那个P的runqueue里拿G, 至于谁更新P的runqueue, 谁负责把G context switch onto M或者off M, 是P自己呢?还是Go Scheduler负责呢?

这里也注意一下, M 可以被 (OS) contex-switched M off/onto the Core, G可以被 contex-switched M off/onto the M, 至于被谁, 那肯定是Go Scheduler了, 上面提到了: The Go scheduler requires well-defined user-space events that occur at safe points in the code to context-switch from. context-switch谁? 当然是 context-switch G onto/off from M 了, 

Source:

- [Scheduling In Go : Part II - Go Scheduler](https://www.ardanlabs.com/blog/2018/08/scheduling-in-go-part2.html)
- [GopherCon 2018: Kavya Joshi - The Scheduler Saga](https://www.youtube.com/watch?v=YHRO5WQGh0k&list=PLn7Fivb51OvJLdfD8KrhgiawFINb94j9X&index=1&t=1416s)

