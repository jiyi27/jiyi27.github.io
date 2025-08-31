---
title: Close Channel Elegantly - Golang
date: 2025-08-30 16:30:18
categories:
 - golang
tags:
 - golang
 - 并发编程
---

## 1. 为什么没有 built-in 关闭 channel 的函数

In fact, even if there is a simple built-in `closed` function to check whether or not a channel has been closed, its usefulness would be very limited, just like the built-in `len` function for checking the current number of values stored in the value buffer of a channel. The reason is that the status of the checked channel may have changed just after a call to such functions returns, so that the returned value has already not been able to reflect the latest status of the just checked channel. Although it is okay to stop sending values to a channel `ch` if the call `closed(ch)` returns `true`, it is not safe to close the channel or continue sending values to the channel if the call `closed(ch)` returns `false`.

这段话主要在解释为什么没有内置的检查channel是否关闭的方法, 即使 Go 语言里真的提供了一个内置的 `closed` 函数, 它的实际作用也很有限, 调用 `closed(ch)` 或 `len(ch)` 时，拿到的只是某个瞬间的状态, 但在函数返回之后，channel 的状态就可能已经改变（比如刚被关闭，或者刚写入/读出一个值）因此结果不可靠：

- 如果 `closed(ch)` 返回 `true`，那还算安全，说明不能再往里发值了
- 但如果 `closed(ch)` 返回 `false`，并不能保证接下来继续写入是安全的，因为在下一瞬间可能就被其他 goroutine 关闭了

## 2. 关闭 Channel 的原则

One general principle of using Go channels is **don't close a channel from the receiver side and don't close a channel if the channel has multiple concurrent senders**. In other words, we should only close a channel in a sender goroutine if the sender is the only sender of the channel.

这里分很多情况, 一个sender 一个 receiver, 多个sender, 多个 receiver, 多个 sender, 一个 receiver, 第一种情况很好处理, 只在 sender 端关闭channel, 就不会出现问题, 因为尝试读的时候可以获取到是否channel关闭, 而写不行, 可能会 Panic

了解更多: https://go101.org/article/channel-closing.html