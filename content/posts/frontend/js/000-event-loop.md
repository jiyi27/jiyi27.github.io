---
title: Event Loop in Browser 
date: 2024-01-27 22:54:02
categories:
  - javascript
tags:
  - javascript
---

## 浏览器 JS 异步执行的原理

JS 是单线程的，也就是同一个时刻只能做一件事情，为什么浏览器可以同时执行异步任务呢？

因为浏览器是多线程的，当 JS 需要执行异步任务时，浏览器会另外启动一个线程去执行该任务。也就是说，“JS 是单线程的”指的是执行 JS 代码的线程只有一个，是浏览器提供的 JS 引擎线程（主线程）。浏览器中还有定时器线程和 HTTP 请求线程等，这些线程主要不是来跑 JS 代码的。

以 Chrome 为例，浏览器不仅有多个线程，还有多个进程，如渲染进程、GPU 进程和插件进程等。而每个 tab 标签页都是一个独立的渲染进程，所以一个 tab 异常崩溃后，其他 tab 基本不会被影响。作为前端开发者，主要重点关注其渲染进程，渲染进程下包含了 JS 引擎线程、HTTP 请求线程和定时器线程等，这些线程为 JS 在浏览器中完成异步任务提供了基础。

## 事件驱动浅析

浏览器异步任务的执行原理背后其实是一套事件驱动的机制。NodeJS 和浏览器的设计都是基于事件驱动的，简而言之就是由特定的事件来触发特定的任务，这里的事件可以是用户的操作触发的，如 click 事件；也可以是程序自动触发的，比如浏览器中定时器线程在计时结束后会触发定时器事件。

了解更多: [面试必问之 JS 事件循环(Event Loop)，看这一篇足够 - 知乎](https://zhuanlan.zhihu.com/p/580956436)

## JavaScript Event Loop 浏览器

nodes.js 的事件循环与浏览器的事件循环有所不同，这里只讨论浏览器的事件循环。

1. **调用栈（Call Stack）**：
   - 调用栈是一个LIFO（后进先出）结构，用于跟踪程序中的函数调用。
   - 当一个函数被执行时，它被添加到调用栈的顶部；当函数执行完毕时，它被从栈顶移除。

2. **事件队列（Event Queue）**：
   - 当异步事件（如用户输入、文件读取等）发生时，相关的回调函数被添加到事件队列中。
   - 事件队列是一种FIFO（先进先出）结构。
   - 事件队列分为两种：宏任务（Macro Tasks）和微任务（Micro Tasks）队列. 

3. **宏任务（Macro Tasks）与微任务（Micro Tasks）**：
   - 宏任务包括脚本执行、setTimeout、setInterval等。
   - 微任务通常来自Promise、MutationObserver等。
   - 在每次宏任务执行完毕后，会处理所有的微任务队列，然后再执行下一个宏任务。
   - 也有人这样去理解：微任务是在当前事件循环的尾部去执行；宏任务是在下一次事件循环的开始去执行。

事件循环的作用是监控 Call Stack 和 Event Queue. 如果 Call Stack 为空，事件循环会查看 Event Queue。如果事件队列中有等待的回调函数，事件循环会将它们依次移动到 Call Stack 中进行执行。这个循环过程是持续不断的，这就是为什么它被称为“事件循环”。

References: 
- [面试必问之 JS 事件循环(Event Loop)，看这一篇足够 - 知乎](https://zhuanlan.zhihu.com/p/580956436)
- [Difference between the Event Loop in Browser and Node Js? - DEV Community](https://dev.to/jasmin/difference-between-the-event-loop-in-browser-and-node-js-1113)
- [The event loop - JavaScript | MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Event_loop)
- [The Node.js Event Loop, Timers, and process.nextTick() | Node.js](https://nodejs.org/en/guides/event-loop-timers-and-nexttick)