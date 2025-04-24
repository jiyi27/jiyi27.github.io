---
title: 浅谈IO模型 异步IO
date: 2025-04-24 22:35:26
categories:
 - 面试
tags:
 - 面试
 - 后端面试
---

## 1. 阻塞IO (Blocking IO)

阻塞IO是指在进行IO操作（如读写文件或网络通信）时，调用线程会一直等待直到操作完成。阻塞IO通常实现简单，但在**高并发场景下效率较低**，因为每个连接可能需要一个线程，线程切换和资源占用会成为瓶颈

- 传统的socket编程中 使用 `socket.recv()` 读取网络数据时，线程会等待直到数据到达
- MySQL客户端连接 传统数据库查询（如SELECT）通常是阻塞的，等待数据库返回结果

早期 Java 服务器为每个连接分配一个线程, 遇到高并发（如 C10K）时性能急剧下降, 促使了NIO（非阻塞IO）和 Netty 的流行

> **C10K（Concurrency 10K）问题** 指的是服务器如何高效地处理 1万个并发连接
>
> - 当并发连接数增加（例如C10K问题，即1万个并发连接），服务器需要创建大量线程（每个连接一个线程）
> - 因为线程很多, 操作系统需要处理大量**线程上下文切换**, 这会消耗大量CPU资源
>
> 因此在高并发场景下, BIO模型效率低下, 性能会急剧下降, 这也是为什么 C10K 问题推动了非阻塞 IO（NIO）和异步框架（如Netty）的流行

> **现在的 Spring MVC 不也是为每个连接分配一个线程吗？**
>
> Spring MVC 通常运行在 Servlet 容器（如Tomcat、Jetty）之上, 这些容器的线程模型决定了 Spring MVC 的并发处理方式, **现代Servlet 容器**并不为每个客户端连接分配一个专用线程，而是使用**线程池**和**事件驱动**机制: 在高并发场景下，线程池的大小远小于并发连接数, **线程可以复用**, 极大减少了线程切换和内存开销
>
> 不太懂现代 Servlet 容器的 IO 模型, 为什么是事件驱动?

## 2. 非阻塞IO (Non-blocking IO)

非阻塞IO允许线程在执行IO操作时立即返回，而不会等待操作完成。如果数据不可用，会返回一个错误或标志（如EAGAIN），调用者**需要轮询（polling）来检查状态**。

- **C语言的socket编程**：通过 `fcntl` 设置 `socket` 为 `O_NONBLOCK`, 调用 `recv` 时立即返回
- **Java NIO（New IO）**：使用 `SocketChannel` 配置为非阻塞模式，检查 `read()` 返回值

> 非阻塞IO虽然避免了线程阻塞，但**频繁轮询会消耗CPU资源**，因此单独使用非阻塞IO在高并发场景下效率也不高, **非阻塞IO常与IO复用结合使用**（如 `select` 或 `epoll`），单独使用效率低

### 2.1. 为什么非阻塞IO需要与IO复用结合？

先看看非阻塞 I/O 的使用场景 理解了非阻塞 IO 的使用场景, 才能更好的了解为什么和 IO 复用搭配使用更好, 假设你正在开发一个简单的TCP服务器, 需要同时处理多个客户端连接, 但没有使用IO复用机制:

```c
// 简单的非阻塞TCP服务器轮询示例
int main() {
    int server_fd, client_fds[MAX_CLIENTS] = {0};
    int client_count = 0;
    
    // 创建服务器socket并设置为非阻塞
    server_fd = socket(AF_INET, SOCK_STREAM, 0);
    fcntl(server_fd, F_SETFL, O_NONBLOCK);
    
    // 绑定和监听代码省略...
    
    while(1) {
        // 1. 轮询接受新连接
        struct sockaddr_in client_addr;
        socklen_t addr_len = sizeof(client_addr);
        int new_fd = accept(server_fd, (struct sockaddr*)&client_addr, &addr_len);
        
        if(new_fd > 0) {
            // 新连接成功
            printf("新客户端连接: %d\n", new_fd);
            fcntl(new_fd, F_SETFL, O_NONBLOCK);  // 设置客户端socket为非阻塞
            client_fds[client_count++] = new_fd;
        } else if(errno != EAGAIN && errno != EWOULDBLOCK) {
            // 真正的错误
            perror("accept失败");
        }
        
        // 2. 轮询检查每个客户端是否有数据可读
        for(int i = 0; i < client_count; i++) {
            char buffer[1024] = {0};
            int ret = recv(client_fds[i], buffer, sizeof(buffer), 0);
            
            if(ret > 0) {
                // 成功读取数据
                printf("从客户端%d接收: %s\n", client_fds[i], buffer);
                // 处理数据并回复
                send(client_fds[i], "已收到消息", 12, 0);
            } else if(ret == 0) {
                // 客户端关闭连接
                printf("客户端%d断开连接\n", client_fds[i]);
                close(client_fds[i]);
                // 移除该客户端
                client_fds[i] = client_fds[--client_count];
                i--;  // 重新检查当前位置
            } else if(errno != EAGAIN && errno != EWOULDBLOCK) {
                // 真正的错误
                perror("recv失败");
                close(client_fds[i]);
                client_fds[i] = client_fds[--client_count];
                i--;
            }
            // 如果errno是EAGAIN或EWOULDBLOCK，表示没有数据可读，继续轮询下一个
        }
        
        // 可选：短暂休眠以减少CPU使用
        usleep(1000);  // 休眠1毫秒
    }
    
    return 0;
}
```

在资源受限的嵌入式系统中，可能没有复杂的IO复用机制，需要轮询多个传感器：

```c
// 嵌入式系统传感器轮询示例
void main_loop() {
    // 初始化传感器
    init_sensors();
    
    while(1) {
        // 轮询温度传感器
        int temp_ready = check_temperature_sensor();
        if(temp_ready) {
            float temp = read_temperature();
            process_temperature_data(temp);
        }
        // 轮询湿度传感器
        ...
        
        // 执行其他任务
        perform_periodic_tasks();
        
        // 短暂休眠以节省电量
        sleep_ms(10);
    }
}
```

**轮询的主要问题**

- **CPU资源浪费**：大部分时间在检查没有变化的资源
- **响应延迟**：轮询间隔决定了响应延迟
- **扩展性差**：随着监控资源数量增加，性能下降

**轮询与IO复用的对比**

```c#
// 纯轮询方式
while(1) {
    for(int i = 0; i < 100; i++) {
        // 每次循环都要对100个socket调用recv系统调用
        ret = recv(sockets[i], buffer, sizeof(buffer), MSG_DONTWAIT);
        // 处理结果...
    }
    usleep(1000);
}

// IO复用方式 (epoll)
int epfd = epoll_create1(0);
// 注册100个socket到epoll...

while(1) {
    // 只有当有事件发生时才会返回
    int nfds = epoll_wait(epfd, events, MAX_EVENTS, -1);
    
    // 只处理有事件的socket，通常远少于100个
    for(int i = 0; i < nfds; i++) {
        int fd = events[i].data.fd;
        ret = recv(fd, buffer, sizeof(buffer), 0);
        // 处理结果...
    }
}
```

> - 非阻塞IO避免线程等待IO操作完成, 通过IO复用（如select、poll、epoll）高效监控多个IO描述符的状态, 从而**减少轮询开销并提升性能**
> - 除此之外, 主动轮询, 频繁调用 `recv()` 系统调用, 需要从用户态切换到内核态, 上下文切换也是一个不小的开销
>   - 这涉及到保存用户态的寄存器状态、切换到内核堆栈、执行内核代码等操作
>   - IO复用通过一次系统调用（例如 `select()` 或 `epoll_wait()`）监控多个 `socket` 的状态，而不是为每个 `socket` 单独调用 `recv()`

## 3. IO复用 (IO Multiplexing)

IO复用是指一个线程监控多个IO描述符, 当某个描述符就绪时通知应用程序, 常见的实现包括 `select`、`poll` 和 `epoll`

- **Nginx**：使用 `epoll`（Linux）或 `kqueue`（BSD）处理高并发连接
- **Redis**：基于 `epoll/select` 的单线程事件循环，高效处理客户端请求
- **libevent/libuv**：高性能事件循环库，广泛用于 Nginx、Node.js 等

### 3.1. select, poll, epoll, kqueue

IO 复用 如何监听的文件描述符? 比如是否可读, 可写等... 

IO复用机制通过不同的API和数据结构来监听文件描述符的状态：

| 机制   | 平台      | 监听方式             | 性能 | 最大连接数     |
| ------ | --------- | -------------------- | ---- | -------------- |
| select | 全平台    | `fd_set` 位图        | O(n) | 受限(通常1024) |
| poll   | 全平台    | `pollfd` 结构体数组  | O(n) | 不受限         |
| epoll  | Linux     | `epoll_event` 结构体 | O(1) | 不受限         |
| kqueue | BSD/macOS | `kevent` 结构体      | O(1) | 不受限         |

> **select epoll 核心区别：通知机制** **最本质的区别**: select 是主动轮询，而 epoll 是被动通知

> 既然 select 也是轮询, 和 非阻塞 IO 中的主动轮询有什么区别呢, 为什么要用 select?
>
> 在纯非阻塞 IO 轮询中, 应用程序直接轮询每个文件描述符, 假设我们有 100 个连接, 但在某一时刻只有 5 个连接有数据可读, 
>
> **纯非阻塞 IO 轮询**：
>
> ```c
> // 每次循环需要 100 次系统调用
> for (int i = 0; i < 100; i++) {
>     recv(sockets[i], buffer, sizeof(buffer), MSG_DONTWAIT);
>     // 95次调用会立即返回EAGAIN
> }
> ```
>
> **select 轮询**：
>
> ```c
> // 设置fd_set (一次系统调用)
> FD_ZERO(&read_fds);
> for (int i = 0; i < 100; i++) {
>     FD_SET(sockets[i], &read_fds);
> }
> 
> // select调用 (一次系统调用)
> select(max_fd + 1, &read_fds, NULL, NULL, NULL);
> 
> // 只对就绪的5个连接调用recv (5次系统调用)
> for (int i = 0; i < 100; i++) {
>     if (FD_ISSET(sockets[i], &read_fds)) {
>         recv(sockets[i], buffer, sizeof(buffer), 0);
>     }
> }
> ```

### 3.2. select epoll 区别

**系统调用开销**：

- select：每次调用都需要传递完整的文件描述符集合

- epoll：通过 epoll_ctl 注册一次，之后无需重复传递

**内存拷贝**：

- select：每次调用需要在用户空间和内核空间之间复制 fd_set

- epoll：通过 mmap 共享内存，减少数据拷贝

**就绪通知方式**：

- select：返回后需要遍历所有文件描述符检查状态

- epoll：只返回就绪的文件描述符列表

### 3.3. **实际应用中的IO复用**

Node.js使用 `libuv` 库实现事件循环，根据平台自动选择最优的IO复用机制：

```js
// Node.js服务器示例
const net = require('net');

const server = net.createServer((socket) => {
    console.log('客户端连接');
    
    // 监听可读事件
    socket.on('data', (data) => {
        console.log('收到数据:', data.toString());
        // 响应客户端
        socket.write('服务器已收到消息');
    });
    
    // 监听关闭事件
    socket.on('close', () => {
        console.log('客户端断开连接');
    });
    
    // 监听错误事件
    socket.on('error', (err) => {
        console.error('连接错误:', err);
    });
});

server.listen(8000, () => {
    console.log('服务器启动在端口8000');
});
```

Nginx使用事件驱动架构，根据平台选择最佳的IO复用机制：

```c
// Nginx事件处理伪代码
ngx_event_module_init() {
    // 根据平台选择最佳的IO复用机制
    if (epoll_supported) {
        use_epoll();
    } else if (kqueue_supported) {
        use_kqueue();
    } else if (poll_supported) {
        use_poll();
    } else {
        use_select();
    }
}

// 事件循环
ngx_process_events_and_timers() {
    // 等待事件
    events = io_multiplexing_wait();
    
    // 处理所有事件
    for (i = 0; i < events.count; i++) {
        event = events[i];
        
        if (event.read) {
            event.read_handler(event.connection);
        }
        
        if (event.write) {
            event.write_handler(event.connection);
        }
    }
    
    // 处理定时器事件
    process_timers();
}
```

> 应用总结:
>
> - **高并发Web服务器**：如Nginx，处理数千个并发连接
>
> - **单线程高性能系统**：如Redis，单线程处理大量客户端请求

## 4. 异步 IO (Asynchronous IO)

异步IO是指发起IO操作后立即返回, 操作系统在后台完成IO, 完成后**通过回调、协程或事件通知应用程序**

- **Node.js**：基于 `libuv` 的事件循环，异步处理文件、网络IO
- **Python FastAPI**：依赖 `asyncio` 和 `uvicorn`，通过 `async/await` 实现异步Web服务
- **Java Netty**：异步网络框架，基于NIO和事件驱动，广泛用于高性能服务器
- **Go语言的 goroutine**：通过轻量级协程和 `select` 实现异步IO效果
- **Linux AIO**：如 `libaio`，提供内核级异步文件IO

### 4.1. 异步 IO 的本质 ‼️

思考一个问题 异步 IO (Asynchronous IO) 的本质是什么? 和非阻塞 IO 的区别呢?

我的理解 异步的本质就是通过回调函数来执行, 可是异步好像也像是同步:

```js
const response = await fetch(....);
// 执行其他的任务
```

异步 IO 的本质是**允许程序在 IO 操作进行时继续执行其他任务, 而不是等待 IO 操作完成**, 异步 IO 确实常常通过回调函数实现, 但这只是实现机制之一, 而非本质, 异步 IO 的核心在于: **IO 操作的发起与结果的获取被分离**, 当 IO 操作完成后, 通过某种机制（回调函数、Promise、事件等）**通知程序处理结果**, 中间的等待时间可以用来做其他事情

上面的例子:

```js
const response = await fetch(...);
// 执行其他的
```

这里的 ⁠await 并不意味着同步。它只是让代码看起来像同步，但实际上：

1. `⁠fetch` 是异步操作，调用后立即返回 `Promise`
2. ⁠`await` 暂停当前函数的执行，**但不会阻塞 JavaScript 的主线程**
3. 在 IO 操作进行时，JavaScript 引擎可以执行其他任务（事件循环中的其他回调）
4. IO 完成后，事件循环会让暂停的函数继续执行

所以 ⁠`await` 是异步 IO 的语法糖, 让异步代码更易读, 但底层仍然是异步的

> 虽然异步 IO 和非阻塞 IO 都允许程序在 IO 操作进行时继续执行其他任务
>
> **非阻塞 IO**：
>
> - 非阻塞 IO 是指在发起 IO 操作时, 设置 IO 操作（如 socket 或文件描述符）为非阻塞模式, 如果 IO 操作无法立即完成, 系统调用会立即返回一个错误（如 `EAGAIN` 或 `EWOULDBLOCK`）, 而不是等待操作完成
> - 程序需要**轮询（polling）**或通过其他机制（如 `select`、`poll`、`epoll`）检查 IO 操作是否完成
> - 非阻塞 IO 的核心是**系统调用立即返回**, 但后续是否**需要程序主动检查**状态取决于具体实现
>
> ```c
> set_socket_nonblocking(socket);
> // 轮询检查 + 做其他的事情 同时发生
> while (true) {
>     if (socket_ready(socket)) {
>         read(socket, buffer);
>     }
>     // 做其他事情
> }
> ```
>
> **异步 IO**：
>
> - 异步 IO 是指程序发起 IO 操作后, **操作系统接管整个 IO 过程**, 程序无需主动关心操作状态, 当 IO 操作完成时, 操作系统通过**回调、事件通知或信号**等方式通知程序
> - 异步 IO 的核心是**完全将 IO 操作交给操作系统**, 程序只需在操作完成时处理结果, 中间**无需轮询**
>
> ```c
> async_read(socket, buffer, callback);
> // 直接做其他事情
> // 操作系统会在完成后调用 callback
> ```
>
> 有没有发现 异步IO 有点像 非阻塞IO + IO复用, 只不过是 IO 复用的部分, 自动帮你实现了?
>
> 确实很像, 但并不是, 但你可以把 异步IO看作是"非阻塞IO + IO复用 + 自动通知机制" 的组合
>
> | 模型     | 组成部分                             | 谁负责轮询/等待                |
> | -------- | ------------------------------------ | ------------------------------ |
> | 非阻塞IO | 仅非阻塞调用                         | 应用程序自己轮询               |
> | IO复用   | 非阻塞IO + 集中式事件监听            | 应用程序通过select/epoll等等待 |
> | 异步IO   | 非阻塞IO + 系统级事件监听 + 回调机制 | 操作系统/运行时负责            |
>
> 在很多系统中, 异步IO 的实现确实是建立在非阻塞IO 和 IO复用的基础上的:
>
> 1. **Node.js的libuv**：在Linux上，libuv使用epoll（一种IO复用机制）实现异步IO
> 2. **Windows的IOCP**：完整的异步IO实现
> 3. **Java的NIO**：基于非阻塞IO和Selector（IO复用）
>
> 以 Node.js 为例, 其事件循环大致如下:
>
> ```js
> // Node.js事件循环的简化伪代码
> while (true) {
>   // 1. 处理定时器回调
>   processTimerCallbacks();
>   
>   // 2. 处理IO回调（使用epoll/kqueue/IOCP等实现）
>   processIOCallbacks();
>   
>   // 3. 处理其他类型的事件...
>   processOtherEvents();
>   
>   // 如果没有待处理的事件，可能会退出
>   if (noMoreCallbacks && noMoreWork) {
>     break;
>   }
> }
> ```

> 在一些异步 IO 框架（如 Node.js 的 libuv）中，底层甚至可能使用 IO 复用机制（如 epoll 或 kqueue）来实现异步效果, 例如，Node.js 的事件循环会使用 epoll 监控 socket，并在就绪时触发回调，这让人感觉异步 IO 是“非阻塞 IO + IO 复用”的封装
>
> 但关键区别在于：
>
> - 异步 IO 更彻底地将 IO 操作的完成交给内核，程序无需主动执行后续的 IO 调用
> - 异步 IO 的通知是**操作完成**（数据已准备好），而 IO 复用通知的是**描述符就绪**（仍需程序执行 IO）
>
> **非阻塞 IO**：
>
> - 常用于高性能服务器开发，如 Nginx、Redis 等，它们通过事件循环和非阻塞 socket 处理大量并发连接
>
> - 适合需要细粒度控制 IO 行为的场景
>
> **异步 IO**：
>
> - 常用于需要简化并发处理的场景，如 Node.js 的异步文件操作、网络请求，或者数据库查询

## 5. 事件循环 和 IO 复用的关系

强调 epoll 相较 select 的性能优势（select的O(n) vs epoll的O(1)），并提到Nginx如何利用epoll实现高并发

事件循环是什么? 怎么实现的?

> 应用总结:
>
> - **高并发Web服务器**：如Node.js、FastAPI，处理大量HTTP请求
> - 提到 Node.js 如何通过 libuv 和 事件循环实现单线程高并发，或 FastAPI 如何利用 asyncio 优化 Python Web 性能
>
> 异步的本质就是通过回调函数来执行, 是这样吗, 异步好像也像是同步:
>
> ```js
> const response = await fetch(....);
> ...
> ```

### 5.1. 事件循环 Event Loop

事件循环 是一种编程架构，用于处理和协调异步操作（主要是 IO 操作，如网络请求、文件读写等），它通过一个循环不断检查是否有事件（如 IO 操作完成、定时器触发、用户输入等）需要处理，并在事件发生时调用相应的回调函数

**事件循环的核心思想：**

- **非阻塞**：事件循环允许程序在等待 IO 操作（如网络数据到达、文件读取完成）时不被阻塞，而是继续执行其他任务
- **事件驱动**：程序通过注册事件（event）和回调函数（callback），当事件发生时，事件循环触发对应的回调来处理结果

**事件循环的典型流程：**

1. 检查事件队列（或事件源）是否有待处理的事件（如 socket 可读、定时器到期）
2. 如果有事件，取出事件并执行对应的回调函数
3. 执行完回调后，继续循环检查队列，直到程序结束
4. 如果没有事件，事件循环可能进入休眠状态（阻塞等待新事件），以避免 CPU 空转
