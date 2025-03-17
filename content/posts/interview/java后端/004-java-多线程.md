---
title: Java 多线程 并发编程
date: 2025-03-11 12:30:20
categories:
 - 面试
tags:
 - 面试
 - java后端面试
---

## 1. 并行 并发

并行：多核 CPU 上的多任务处理，多个任务在同一时间真正地同时执行

并发：单核 CPU 上的多任务处理，多个任务在同一时间段内交替执行，通过时间片轮转实现交替执行

## 2. 进程和线程

线程是进程的一个执行单位, 进程就是启用的一个程序, 比如本地启动 MySQL 服务, MySQL 服务创建和管理多个线程来分别处理客户端连接、查询解析、后端IO操作、缓存管理等，借此提升性能和响应能力

## 3. 线程安全的理解

线程安全主要涉及到多个线程同时尝试访问同一个共享数据, 能否正确处理共享数据的问题, 就是线程安全的关键:

- 首先通过的就是锁机制, 互斥锁, 保证同一时刻只有一个线程修改共享数据
- 而锁机制就会引起锁的强占, 所以要确保线程不会因为死锁问题导致无法继续执行

> 协程更轻量, 不属于操作系统级别, 而是属于更高一层对线程的包装, 不涉及系统调用, 因此等待到执行状态也不需要上下文切换, 或者说很代价很小, 因此也不用使用线程池这种东西了

## 4. Java 线程间通信方式 - 共享内存

线程之间想要进行通信, 可以通过消息传递和共享内存两种方法来完成, 那 Java 采用的是共享内存的并发模型, 而 Golang 使用的就是前者 CSP, 利用 Channel 传递消息, 正如他的 Slogan: Don't communicate by sharing memory, share memory by communicating.

各有优缺点吧, 前者不需要锁机制了, 所有消息数据串行发送, 后者则需要锁来控制

- CSP 避免了共享内存带来的竞争条件, 天然线程安全, 缺点是 Channel 通信需要额外的同步和数据拷贝, 在某些低延迟场景下可能不如共享内存高效
- CSP 适合 适合高并发、事件驱动的场景, 如 Web 服务器、微服务, 用 goroutine 处理 HTTP 请求，通过 Channel 传递任务结果
- 共享内存模型数据不一致的风险较高, 需要使用锁来实现线程安全问题, 比较复杂, 容易出 bug

> **共享内存模型如何保证线程安全:** Java 的并发主要依赖线程和共享内存, 线程通过访问共享对象（如变量、集合等）来进行通信, 为了避免竞争条件和数据不一致问题, Java 提供了同步机制 ,如 synchronized 关键字、锁（Lock）、以及并发工具类（java.util.concurrent 包，例如 ConcurrentHashMap、ExecutorService 等）
>
> 线程间同步实现方式: 各种锁, 互斥锁, 读写锁, 信号量, 注意互斥锁和读写锁不同, 

## 5. 线程创建方式

Java 中创建线程主要有三种方式，分别为继承 Thread 类、实现 Runnable 接口、实现 Callable 接口

```java
class ThreadTask extends Thread {
    public void run() {
        System.out.println("看完二哥的 Java 进阶之路，上岸了!");
    }

    public static void main(String[] args) {
        ThreadTask task = new ThreadTask();
        task.start();
    }
}

class RunnableTask implements Runnable {
    public void run() {
        System.out.println("看完二哥的 Java 进阶之路，上岸了!");
    }

    public static void main(String[] args) {
        RunnableTask task = new RunnableTask();
        Thread thread = new Thread(task);
        thread.start();
    }
}
```

> 调用 start()方法时会执行 run()方法，那怎么不直接调用 run()方法？
>
> 当调用`start()`方法时, 会**启动一个新的线程**, 并让这个新线程调用`run()`方法, 如果直接调用`run()`方法, 那么`run()`方法就在当前线程中运行, 没有新的线程被创建, 也就没有实现多线程的效果

## 6. Java 线程安全如何实现

使用共享对象, 多个线程可以访问和修改同一个对象, 从而实现信息的传递, 但是我们需要有锁的机制来保证线程安全, 在多线程编程中, 线程之间共享变量时可能会出现问题：

- 可见性问题：一个线程改了变量，其他线程看不到最新值
- 原子性问题：多个线程同时改变量，导致结果出错

### 6.1. `volatile` 

在 Java 中, 为了优化性能, 编译器和 CPU 可能会对代码的指令进行重排序, 也就是说, 代码的实际执行顺序可能与你写的顺序不同, volatile 关键字的一个重要作用是**禁止指令重排序**, 并确保变量的读写操作按照程序员预期的顺序执行, 同时保证内存可见性 (一个线程改了变量，其他线程立刻能看到)

禁止指令重排序的场景单例模式的双重检查锁:

```java
public class Singleton {
    private static Singleton instance;
    private Singleton() {}
    public static Singleton getInstance() {
        if (instance == null) { // 第一次检查
            synchronized (Singleton.class) {
                if (instance == null) { // 第二次检查
                    instance = new Singleton(); // 创建实例
                }
            }
        }
        return instance;
    }
}
```

在上面的代码中，instance = new Singleton(); 看似是一行简单的赋值，但实际上 JVM 会将其分解为以下步骤：

1. 分配内存空间
2. 初始化对象（调用构造方法）
3. 将 instance 引用指向这块内存

由于指令重排序的存在，JVM 和 CPU 可能会将步骤 3（赋值）提前到步骤 2（初始化）之前。假设有两个线程 A 和 B：

- 线程 A 执行 getInstance()，进入同步块，开始创建对象
- 线程 A 执行到“分配内存并赋值”（步骤 1 和 3），但还未完成初始化（步骤 2）
- 此时线程 B 调用 getInstance()，看到 instance 不为 null（因为已经被赋值），直接返回未初始化的对象
- 结果：线程 B 拿到了一个未完全初始化的 Singleton 对象，可能导致空指针异常或逻辑错误

```java
public class Singleton {
    private static volatile Singleton instance; // 添加 volatile

    private Singleton() {}

    public static Singleton getInstance() {
        if (instance == null) {
            synchronized (Singleton.class) {
                if (instance == null) {
                    instance = new Singleton();
                }
            }
        }
        return instance;
    }
}
```

volatile 如何解决问题？

1. **禁止指令重排序**：volatile 确保 instance = new Singleton(); 的三个步骤（分配内存、初始化、赋值）按照代码顺序执行，不会将赋值提前到初始化之前
2. **内存可见性**：线程 A 修改 instance 后，线程 B 能立即看到最新的值，而不是缓存中的旧值

结果：线程 B 要么看到 instance 是 null（等待初始化），要么看到一个完全初始化的对象，不会出现“半初始化”状态, 

虽然 `volatile` 可以禁止指令重排序，但它不能保证操作的原子性，比如 `++` 操作仍然不是线程安全的：

```java
volatile int counter = 0;

void threadFunc() {
    counter++; // 这个操作不是原子的
}
```

### 6.2. `synchronized` 

- 保证**互斥性**：同一时间只有一个线程能执行锁住的代码

- 保证**可见性**：进入锁时加载最新值，退出锁时刷新修改

- 保证**原子性**：锁内的操作不会被打断

```java
public class CounterExample {
    private int count = 0;

    public synchronized void increment() {
        count++; // 线程安全
    }

    public synchronized int getCount() {
        return count; // 线程安全
    }
}
```

**两种用法**

1. **同步方法**：锁住整个方法（例子如上）
2. **同步块**：锁住部分代码，灵活性更高

```java
public class BlockExample {
    private int count = 0;
    private final Object lock = new Object();

    public void increment() {
        synchronized (lock) { // 只锁关键部分
            count++;
        }
    }
}
```

> 前面说到 进入 `synchronized` 块时, 线程会从主内存加载变量的最新值, 退出时，会将修改后的值刷新回主内存, 为什么有时需要一起用？
>
> - 因为 synchronized 只保证锁内代码的可见性，而锁外的代码仍然可能依赖线程本地缓存的旧值
> - volatile 可以确保即使在无锁的情况下，读线程也能立即看到变量的最新值
>
> ```java
> public class TaskQueue {
>     private int taskCount = 0; // 任务计数
>     private boolean hasNewTask = false; // 是否有新任务
>     private final Object lock = new Object();
> 
>     // 生产者：添加任务
>     public void produceTask() {
>         synchronized (lock) {
>             taskCount++; // 增加任务数
>             hasNewTask = true; // 标记有新任务
>         }
>     }
> 
>     // 消费者：检查是否有新任务
>     public boolean hasNewTask() {
>         return hasNewTask; // 无锁读取，可能看不到最新值
>     }
> 
>     // 消费者：获取任务数并处理
>     public int consumeTask() {
>         synchronized (lock) {
>             if (hasNewTask) {
>                 hasNewTask = false; // 重置标志
>                 return taskCount; // 返回任务数
>             }
>             return 0;
>         }
>     }
> }
> ```

## 7. ReentrantLock vs ReadWriteLock

### 7.1. ReentrantLock

`ReentrantLock` Java `java.util.concurrent.locks` 包中的显式锁，提供比 `synchronized` 更灵活的功能, 

在锁竞争激烈时，可以通过 `tryLock(timeout)` 避免线程无限等待:

```java
ReentrantLock lock = new ReentrantLock();
public boolean tryMethod() throws InterruptedException {
    if (lock.tryLock(1, TimeUnit.SECONDS)) {
        try {
            // 获取锁成功
            return true;
        } finally {
            lock.unlock();
        }
    }
    return false; // 超时未获取锁
}
```

当需要按照线程请求顺序分配锁（避免线程饥饿）时，可以配置公平锁

```java
ReentrantLock lock = new ReentrantLock(true); // 公平锁
```

实际示例对比:

```java
public class Counter {
    private int count = 0;
    public synchronized void increment() {
        count++;
    }
}

public class Counter {
    private int count = 0;
    private final ReentrantLock lock = new ReentrantLock();
    public void increment() {
        lock.lock();
        try {
            count++;
        } finally {
            lock.unlock();
        }
    }
}
```

### 7.2. ReadWriteLock

在 Java 中，ReadWriteLock（通常通过其实现类 ReentrantReadWriteLock 使用）是一种**专门为读多写少场景**设计的锁机制。与 ReentrantLock 相比，它提供了更细粒度的并发控制，允许多个线程同时读取，但写操作是独占的。

```java
ReentrantReadWriteLock rwLock = new ReentrantReadWriteLock();
Map<String, String> cache = new HashMap<>();

public String get(String key) {
    rwLock.readLock().lock();
    try {
        return cache.get(key);
    } finally {
        rwLock.readLock().unlock();
    }
}

public void put(String key, String value) {
    rwLock.writeLock().lock();
    try {
        cache.put(key, value);
    } finally {
        rwLock.writeLock().unlock();
    }
}
```



