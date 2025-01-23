---
title: Concurrency with Shared Variables
date: 2023-08-24 19:16:59
categories:
 - golang
 - advance
tags:
 - golang
 - concurrency
---

## 1. Concurrency Safe

In a program with two or more goroutines, the steps within each goroutine happen in the familiar order, but in general we don’t know whether an event *x* in one goroutine happens before an event *y* in another goroutine, or happens after it, or is simultaneous with it. When we cannot confidently say that one event *happens before* the other, then the events *x* and *y* are ***concurrent***. 

That function is ***concurrency-safe*** if it continues to work correctly even when called concurrently, that is, from two or more goroutines with no additional synchronization. We can generalize this notion to a set of collaborating functions, such as the methods and operations of a particular type. A type is ***concurrency-safe*** if all its accessible methods and operations are concurrency-safe.

Concurrency-safe types are the exception rather than the rule, so you should access a variable concurrently only if the documentation for its type says that this is safe. We avoid concurrent access to most variables either by *confining* them to a single goroutine or by maintaining a higher-level invariant of *mutual exclusion*. 

In contrast, exported package-level functions *are* generally expected to be concurrency-safe. Since package-level variables cannot be confined to a single goroutine, functions that modify them must enforce ***mutual exclusion***. 

## 2. Data Race

A ***data race*** occurs whenever two goroutines access the same variable ***concurrently*** and at least one of the accesses is a write. Notice that "access the same variable concurrently" means: there are two or more goroutines (threads) to access a same variable `x`, and we cannot assure the order of accessing variable `x`. 

Aussume we have these code:

```go
var balance int

func Deposit(amount int) { balance = balance + amount }

func Balance() int { return balance }
```

And there are two goroutines access `balance`  concurrently, 

```go
// Alice:
go func() {
    bank.Deposit(200)                // A1
    fmt.Println("=", bank.Balance()) // A2
}()

// Bob:
go bank.Deposit(100)                 // B
```

Alice deposits $200, then checks her balance, while Bob deposits $100. Since the steps `A1` and `A2` occur ***concurrently*** with `B`, we cannot predict the order in which they happen. Intuitively, it might seem that there are only three possible orderings, which we’ll call “Alice first,” “Bob first,” and “Alice/Bob/Alice.” The following table shows the value of the `balance` variable after each step. The quoted strings represent the printed balance slips. 

In all cases the final balance is $300. The only variation is whether Alice’s balance slip includes Bob’s transaction or not, but the customers are satisfied either way.

But this intuition is wrong. There is a fourth possible outcome, in which Bob’s deposit occurs in the middle of Alice’s deposit, after the balance has been read (`balance + amount`) but before it has been updated (`balance = ...`), causing Bob’s transaction to disappear. This is because Alice’s deposit operation `A1` is really a sequence of two operations, a read and a write; call them `A1r` and `A1w`. Here’s the problematic interleaving:

```shell
Data race
         0
A1r      0          ... = balance + amount
# happend in the middle, balance = 100 but A1 will make balance = balance + amount which equals to 200 above
B      100
A1w    200          balance = ...
A2  "= 200"
```

After `A1r`, the expression `balance + amount` evaluates to 200, so this is the value written during `A1w`, despite the intervening deposit. The final balance is only $200. 

We’ll repeat the definition, since it is so important: A data race occurs whenever two goroutines access the same variable concurrently and at least one of the accesses is a write. It follows from this definition that there are three ways to avoid a data race:

- first way: not to write the variable
  - try to use read only variable
- second way: avoid accessing the variable from multiple goroutines (*confined* to a single goroutine)
  - access the variable need to write in only one goroutine which called monitor goroutine
  - other goroutine want to modify this variable can notify the monitor goroutine of that variable
  - Since other goroutines cannot access the variable directly, they must use a channel to send the confining goroutine a request to query or update the variable. This is what is meant by the Go mantra “Do not communicate by sharing memory; instead, share memory by communicating.”

Here’s the bank example rewritten with the `balance` variable confined to a monitor goroutine called `teller`:

```go
// Package bank provides a concurrency-safe bank with one account.
package bank

var deposits = make(chan int) // send amount to deposit
var balances = make(chan int) // receive balance

func Deposit(amount int) { deposits <- amount }
func Balance() int       { return <-balances }

func teller() {
    var balance int // balance is confined to teller goroutine
    for {
        select {
        case amount := <-deposits:
            balance += amount
        case balances <- balance:
        }
    }
}

func init() {
    go teller() // start the monitor goroutine
}
```

You can see, when there are some variables in a package, we better tell user if it is concurrency-safe. 

The third way to avoid a data race is to allow many goroutines to access the variable, but only one at a time. This approach is known as ***mutual exclusion***.

## 3. Mutual Exclusion

### 3.1. Mutex vs Semaphore

A semaphore is a non-negative integer variable that is shared between various threads. Mutex is a specific kind of binary semaphore that is used to provide a locking mechanism. 

```
P(mutex);
execute CS;
V(mutex);
```

|                            Mutex                             |                          Semaphore                           |
| :----------------------------------------------------------: | :----------------------------------------------------------: |
|                    A mutex is an object.                     |                  A semaphore is an integer.                  |
|           Mutex works upon the locking mechanism.            |              Semaphore uses signaling mechanism              |
|                Operations on mutex:LockUnlock                |              Operation on semaphore:WaitSignal               |
|               Mutex doesn’t have any subtypes.               | Semaphore is of two types:Counting SemaphoreBinary Semaphore |
| A mutex can only be modified by the process that is requesting or releasing a resource. | Semaphore work with two atomic operations (Wait, signal) which can modify it. |
| If the mutex is locked then the process needs to wait in the process queue, and mutex can only be accessed once the lock is released. | If the process needs a resource, and no resource is free. So, the process needs to perform a wait operation until the semaphore value is greater than zero. |

### 3.2. Mutual Exclusion: `sync.Mutex`

In [Section 8.6](https://learning.oreilly.com/library/view/the-go-programming/9780134190570/ebook_split_081.html#id-exampleconcurrentwebcrawler), we used a buffered channel as a ***counting semaphore*** to ensure that no more than 20 goroutines made simultaneous HTTP requests. With the same idea, we can use a channel of capacity 1 to ensure that at most one goroutine accesses a shared variable at a time. A semaphore that counts only to 1 is called a ***binary semaphore***.

```go
var (
    sema    = make(chan struct{}, 1) // a binary semaphore guarding balance
    balance int
)

func Deposit(amount int) {
    sema <- struct{}{} // acquire token
    balance = balance + amount
    <-sema // release token
}

func Balance() int {
    sema <- struct{}{} // acquire token
    b := balance
    <-sema // release token
    return b
}
```

This pattern of *mutual exclusion* is so useful that it is supported directly by the `Mutex` type from the `sync` package. Its `Lock` method acquires the token (called a *lock*) and its `Unlock` method releases it:

```go
import "sync"

var (
    mu      sync.Mutex // guards balance
    balance int
)

func Deposit(amount int) {
    mu.Lock()
    balance = balance + amount
    mu.Unlock()
}

func Balance() int {
    mu.Lock()
    b := balance
    mu.Unlock()
    return b
}
```

### 3.3. Read/Write Mutexes: `sync.RWMutex`

Since the `Balance` function only needs to *read* the state of the variable, it would in fact be safe for multiple `Balance` calls to run concurrently, so long as no `Deposit` or `Withdraw` call is running. In this scenario we need a special kind of lock that allows read-only operations to proceed in parallel with each other, but write operations to have fully exclusive access. This lock is called a *multiple readers*, *single writer* lock, and in Go it’s provided by `sync.RWMutex`:

```go
var mu sync.RWMutex
var balance int

func Balance() int {
    mu.RLock() // readers lock
    defer mu.RUnlock()
    return balance
}
```

## 4. Memory Synchronization

You may wonder why the `Balance` method needs mutual exclusion, either channel-based or mutex-based. After all, unlike `Deposit`, it consists only of a single operation, so there is no danger of another goroutine executing “in the middle” of it. 

The reason is that synchronization is about more than just the order of execution of multiple goroutines; synchronization also affects memory.

In a modern computer there may be dozens of processors, **each with its own local cache of the main memory**. **For efficiency, writes to memory are buffered** within each processor and flushed out to main memory only when necessary. ***Synchronization primitives*** like ***channel communications*** and ***mutex operations*** cause the processor to flush out and commit all its accumulated writes so that the effects of goroutine execution up to that point **are guaranteed to be visible to** goroutines running on other processors.

Consider the possible outputs of the following snippet of code:

```go
var x, y int
go func() {
    x = 1                   // A1
    fmt.Print("y:", y, " ") // A2
}()
go func() {
    y = 1                   // B1
    fmt.Print("x:", x, " ") // B2
}()
```

Since these two goroutines are concurrent and access shared variables without mutual exclusion, there is a data race, so we should not be surprised that the program is not deterministic. 

```
y:0 x:1
x:0 y:1
x:1 y:1
y:1 x:1
```

The fourth line could be explained by the sequence `A1,B1,A2,B2` or by `B1,A1,A2,B2`, for example. However, these two outcomes might come as a surprise:

```
x:0 y:0
y:0 x:0
```

but depending on the compiler, CPU, and many other factors, they can happen too. What possible interleaving of the four statements could explain them?

Within a single goroutine, the effects of each statement are guaranteed to occur in the order of execution; goroutines are *sequentially consistent*. But in the absence of explicit synchronization using a channel or mutex, there is no guarantee that events are seen in the same order by all goroutines. Although goroutine *A* must observe the effect of the write `x = 1` before it reads the value of `y`, it does not necessarily observe the write to `y` done by goroutine *B*, so *A* may print a *stale* value of `y`.

It is tempting to try to understand concurrency as if it corresponds to *some* interleaving of the statements of each goroutine, but as the example above shows, this is not how a modern compiler or CPU works. Because the assignment and the `Print` refer to different variables, **a compiler may conclude that the order of the two statements** cannot affect the result, and swap them. If the two goroutines execute on different CPUs, each with its own cache, writes by one goroutine **are not visible to** the other goroutine’s `Print` until the caches are synchronized with main memory. 

All these concurrency problems can be avoided by the consistent use of simple, established patterns. Where possible, confine variables to a single goroutine; for all other variables, use mutual exclusion.

## 5. Race Conditions vs Data Race

A ***race condition*** is a flaw that occurs when the timing or ordering of events affects a program’s correctness. Generally speaking, some kind of external timing or ordering non-determinism is needed to produce a race condition; typical examples are context switches, OS signals, memory operations on a multiprocessor, and hardware interrupts.

A ***data race*** occurs whenever two goroutines access the same variable ***concurrently*** and at least one of the accesses is a write. 

Race conditions are pernicious because they may remain latent in a program and appear infrequently, perhaps only under heavy load or when using certain compilers, platforms, or architectures. This makes them hard to reproduce and diagnose.

```go
transfer1 (amount, account_from, account_to) {
  if (account_from.balance < amount) return NOPE;
  account_to.balance += amount;
  account_from.balance -= amount;
  return YEP;
}
```

Of course this is not how banks really move money, but the example is useful anyway because we understand intuitively that account balances should be non-negative and that a transfer must not create or lose money. When called from multiple threads without external synchronization, this function admits both data races (multiple threads can concurrently try to update an account balance) and race conditions (in a parallel context it will create or lose money). We can try to fix it like this:

```go
transfer2 (amount, account_from, account_to) {
  atomic {
    bal = account_from.balance;
  }
  if (bal < amount) return NOPE;
  atomic {
    account_to.balance += amount;
  }
  atomic {
    account_from.balance -= amount;
  }
  return YEP;
}
```

Here “atomic” is implemented by the language runtime, perhaps simply by acquiring a thread mutex at the start of the atomic block and releasing it at the end, perhaps using some sort of transaction, or perhaps by disabling interrupts — for purposes of the example it doesn’t matter as long as the code inside the block executes atomically.

transfer2 has no data races when called by multiple threads, but obviously it is an extremely silly function containing race conditions that will cause it to create or lose money almost as badly as the unsynchronized function. From a technical point of view, the problem with transfer2 is that it permits other threads to see memory states where a key invariant — conservation of money — is broken.

To preserve the invariant, we have to use a better locking strategy. As long as atomic’s semanatics are to end the atomic section on any exit from the block, the solution can be blunt:

```
transfer3 (amount, account_from, account_to) {
  atomic {
    if (account_from.balance < amount) return NOPE;
    account_to.balance += amount;
    account_from.balance -= amount;
    return YEP;
  }
}
```

This function is free of data races and also of race conditions.

Everything in this post is pretty obvious, but I’ve observed real confusion about the distinction between data race and race condition by people who should know better (for example because they are doing research on concurrency correctness). Muddying the waters further, even when people are perfectly clear on the underlying concepts, they sometimes say “race condition” when the really mean “data race.” Certainly I’ve caught myself doing this.

## 6. Conclusion

- ***concurrent*** envolves two or more threads, and it's all about the *unpredictable* order of the execution. 
- ***concurrency-safe type*** if that all its accessible methods and operations are concurrency-safe.
- A ***data race*** occurs whenever two goroutines access the same variable ***concurrently*** and at least one of the accesses is a write. 
  - data race can cause data lost, the bank example 
  - when there is data race, you'd better use ***Mutual Exclusion***: `sync.RWMutex`,  `sync.Mutex`

- Mutex vs Semaphore
- A ***race condition*** is a flaw that occurs when the timing or ordering of events affects a program’s correctness.

References:

- [9.1 Race Conditions | The Go Programming Language](https://learning.oreilly.com/library/view/the-go-programming/9780134190570/ebook_split_087.html)
- [Mutex vs Semaphore - GeeksforGeeks](https://www.geeksforgeeks.org/mutex-vs-semaphore/)
- [Race Condition vs. Data Race – Embedded in Academia](https://blog.regehr.org/archives/490)

