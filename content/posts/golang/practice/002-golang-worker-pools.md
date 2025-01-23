---
title: Go并发学习之实现一个Worker Pool
date: 2023-05-25 14:13:13
categories:
 - golang
 - practice
tags:
 - golang
 - concurrency
---

有人认为[Worker Pool在go里是anti-pattern](https://youtu.be/5zXAHh5tJqQ), 不管怎样, 先实现一个简单版本来帮助理解Worker Pool的概念, 实现之前我们先看看传统的线程池相关的:

- 线程池的概念: 预先创建多个线程，线程池里的线程等待处理新来的任务，处理完之后线程并不会被销毁而是等待下一个任务。
- 使用线程池的原因: 创建和销毁线程都消耗系统资源，如果你的程序需要**频繁地创建和销毁线程**那这时候就可以考虑使用线程池来提高程序的性能。

注意以上这两点针对是OS级线程的创建销毁, goroutine模型并不是这样, 很轻量, 这也是不需要 worker poll 的原因, 

另外线程池 thread pool 是不是 worker pool 看法不一, 下面这个描述感觉最贴切:

> The **worker pool pattern** is a design in which a fixed number of workers are given a stream of tasks to process in a queue. [Go Worker Pools](https://shopify.engineering/leveraging-go-worker-pools)

至于thread pool, 普遍看法是:

> A **thread pool** reuses previously created threads to execute current tasks and offers a solution to the problem of thread cycle overhead and resource thrashing. [Thread Pools Java](https://www.geeksforgeeks.org/thread-pools-java/)

所以这么看, worker pool也算是一个basic thread pool, 即*reuses previously created threads to execute current tasks*, 

---

用Go实现Worker Pool利用的是buffered channel的两个特性:即满的时候写入操作阻塞, 空的时候读取操作阻塞, 

具体方法是提前创建多个 goroutines, 然后这些线程持续监听同一个buffered channel, 如果该channel是空的, 那他们就阻塞等待下一个任务的到来:

```go
// var keysChannel = make(chan int, 6)
for key := range keysChannel {
		resultsChannel <- doResearch(key)
}
```

上面这个程序就是遍历一个buffered channel, 如果该channel是空的, 那该段代码就会阻塞, 直到新的数据写入`keysChannel` ,

```go
key := 0
for {
	time.Sleep(time.Second)
	keysChannel <- key
	key++
}
```

上面这段程序即模拟持续产生数据写入到buffered channel: `keysChannel`, 若`keysChannel`满了, 那`keysChannel <- key`就会阻塞, 

之前看到一句话描述线程池说 *once the threads finish the task assigned, they make themselves available again for the next task*, 这句话在这就很有迷惑性, 其它语言不知道线程池具体怎么实现, 但是在go里根据上面我们讨论的, 根本没有所谓的*make themselves (threads) available again for the next task*, 即线程一直都在监听, 只是他们完成一个任务后就会接着完成下一个, 直到他们监听的那个buffered channel为空, 这时候他们是阻塞状态, 

另外实现线程池还用到了一个struct, `sync.WaitGroup` , 主要需要了解它的三个函数, `wg.Add()`, `wg.Done()`, `wg.Wait()`, 其中`wg.Add(1)`的意思使`wg`的counter加1, `wg.Done()`使counter减1,  最后`wg.Wait()`阻塞直到counter为0, 我们一般的逻辑是创建多个线程的时候, 每创建一个线程就调用`wg.Add(1)`使counter++, 当线程要被销毁的时候调用`wg.Done()`是counter--,  然后在main线程里的最后调用`wg.Wait()`, 即等待所有线程执行完毕程序结束, 

注意该实现并不是oo的实现, 

```go
package main

import (
	"fmt"
	"sync"
	"time"
)

var keysChannel = make(chan int, 6)
var resultsChannel = make(chan string, 3)

func doResearch(key int) string{
	// assume this research operation consumes a lot of time
	time.Sleep(time.Second * 2)
	return fmt.Sprintf("One research finished, original key is: %v", key)
}

func createWorkerPool(numOfWorker int) {
	var wg sync.WaitGroup
	// create numOfWorker of workers
	for i := 0; i < numOfWorker; i++ {
		wg.Add(1)
		// create a goroutine that looks like can be "reused" by listening keysChannel until keysChannel is closed
		go func(wg *sync.WaitGroup) {
			// run forever until keysChannel is closed
			// because when keysChannel is empty, this code get blocked not break loop
			for key := range keysChannel {
				resultsChannel <- doResearch(key)
			}
			// worker() is a function represents a goroutine, before return, we should make wg--
			wg.Done()
		}(&wg)
	}
	wg.Wait()
	close(resultsChannel)
}

// when use channel, you have to figure out if you need to remind of other goroutines,
// if yes, figure out when to close
// when use sync.WaitGroup three operations you need to do: wg--, wg.Add(1), wg.wait()
// and don't forget to do wg--, otherwise the wg.wait() will never return
func main() {
	// 1. keep listening the resultChannel until resultsChannel is closed
	done := make(chan bool)
	go func(done chan bool) {
		for result := range resultsChannel {
			fmt.Printf("%v\n", result)
		}
		done <- true
	}(done)

	// 2. keep generating key every 1 sec
	// Imagine this function can continuously generate a request from a client every sec
	// And this request will be sent to keysChannel and will be processed by
	// our one of our workers that keep listening the keysChannel
	go func() {
		key := 0
		for {
			time.Sleep(time.Second)
			keysChannel <- key
			key++
		}
	}()

	// 3. create worker pool, and until wg.Wait() in the last line of this function returns
	createWorkerPool(3)

	<-done
	// It's OK to leave a Go channel open forever and never close it.
	// When the channel is no longer used, it will be garbage collected.
	// Close a channel only when it is essential to
	// inform the receiving goroutines that all data has been transmitted.
	// close(done)
}
```

参考:

- [Buffered Channels and Worker Pools in Go - golangbot.com](https://golangbot.com/buffered-channels-worker-pools/)