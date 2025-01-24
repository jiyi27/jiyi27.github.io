---
title: Is Multithreaded Server Better than a Single Thread Server?
date: 2023-08-26 19:03:59
categories:
 - 计算机基础
tags:
 - 多线程
 - 后端开发
---

**Reference:** https://qr.ae/pyztor

*Why is a multithreaded web server better than a single thread server?* **It isn’t.**

There are four basic ways how a web server can handle concurrency:

1. forking an OS process per request (like old versions of Apache)
2. spawning an OS thread per request (like a new versions of Apache)
3. using a single-threaded event loop (like nginx)
4. using green threads or lightweight processes scheduled by a VM runtime instead of the OS (like in Erlang)

Currently the most common approaches are number 2 and 3.

There are pros and cons of both of them. For **I/O-bound** operations (a characteristic of a typical web server) you get **better performance** and **higher number of concurrent requests** when you use a **single-threaded event loop**. But the drawback is that you need to use exclusively asynchronous non-blocking I/O for all operations or otherwise you’ll block the event loop and lose performance. For that reason it’s easier to implement a multi-threaded server but you pay in performance.

For **CPU-bound** operations (less common for a usual web server, maybe more common for a computationally intensive API) it’s best to have **one OS thread or process per core**. It’s easy to do with single-threaded event loops because you can run a cluster of a number of processes one per core. It’s hard to do with multi-threaded servers because if spawning threads is your only way to handle concurrent requests then you cannot really control how many threads you will have - as you don’t control the number of requests. Once you have more threads than the number of CPU cores then you loose performance for **context switches** and you also use a lot of RAM.

That is why a **single-threaded nginx server** performs better than a multi-threaded Apache web server (and that is why nginx was created in the first place). Also **Redis**, a database known for exceptionally high performance is **single-threaded**.

A real example I can give you is this: My first web server was Apache running on a Linux machine with 500MB of RAM. It forked a new process for every request (it actually had a pool so there was not much forking involved but it had to keep those processes alive to reuse them and kill them once in a while to avoid resource leakage).

My OS used around 100MB of RAM. Every Apache process used 20MB of RAM. It meant that my server could only handle 20 concurrent requests and there was no way around it because I had no more RAM. The processes were mostly blocked on I/O so the CPU utilization was very low, every request above those 20 had to wait and if those 20 was e.g. long running downloads then my server was completely unresponsive.

When nginx web server was introduced it used a single-threaded event loop and didn’t block for any request. It could handle much more concurrent requests, having no problem with the mythical c10k problem - nginx was basically created to solve the c10k problem (10,000 concurrent requests).

Imagine how much RAM is wasted for 10,000 threads if you could even spawn that many and how much time is used for context switches.

**Memory usage of multi-threaded Apache vs single-threaded nginx:**

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2025/01/3753c8d5681b143ae824ebc3830d959d.png)

Incidentally, this is the reason why Ryan Dahl used a non-blocking I/O and a single-threaded event loop in Node.js and he still uses the same idea in Deno, because that is the way to write high performance network servers (contrary to what you might read in other answers here).

> Note that [nginx “core functionality” doc](https://nginx.org/en/docs/ngx_core_module.html#worker_processes) mentions that on most servers nginx defaults to multiple workers (which will be ran as threads) so it’s not always “single threaded.” [from a comment of this blog](https://www.quora.com/profile/Alex-Sergeyev)

