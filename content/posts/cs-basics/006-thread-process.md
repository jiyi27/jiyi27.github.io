---
title: Thread Stack and CPU Cores
date: 2023-05-27 18:05:16
categories:
 - cs basics
tags:
 - concurrency
 - cs basics
---

## 1. Thread

A thread is a segment or part of a process that executes some tasks of the process. A process can have multiple threads which can **run concurrently** within the process. Each thread has its own thread stack but multiple threads of a process share a common heap area of that process.

### 1.1. Thread stack

Each thread has its own call stack, "call stack" and "thread stack" are the same thing. Calling it a "thread stack" just emphasizes that the call stack is specific to the thread. 

The *stack* is used to store variables used on the inside of a function (including the `main()` function). It’s a LIFO, “**L**ast-**I**n,-**F**irst-**O**ut”, structure. Every time a function declares a new variable it is “pushed” onto the stack. Then when a function finishes running, all the variables associated with that function on the stack are deleted, and the memory they use is freed up. This leads to the “local” scope of function variables. The stack is a special region of memory, and automatically managed by the CPU – so you don’t have to allocate or deallocate memory. Stack memory is divided into successive frames where each time a function is called, it allocates itself a fresh **stack frame**. 

Note that there is generally a limit on the size of the stack – which can vary with the operating system (for example OSX currently has a default stack size of 8MB). If a program tries to put too much information on the stack, **stack overflow** will occur. Stack overflow happens when all the memory in the stack has been allocated, and further allocations begin overflowing into other sections of memory. Stack overflow also occurs in situations where recursion is incorrectly used.

## 2. Process

A program is a set of instructions. It is stored on a disk of a computer and hence it is **Passive**. When the same program is loaded into the main memory and the OS assigns some heap memory to this program(application) is under execution is called a **Process**. Hence a process is a program under execution. So we can say it is **Active**. A process can create child processes by using the **fork** system calls. 

## 3. Relationship between a thread and a CPU core

A CPU core is a physical processing unit in a computer’s central processing unit (CPU) that can execute instructions independently. A thread, on the other hand, is a unit of execution within a process, which represents a sequence of instructions that can be executed independently by a CPU.

In general, the number of threads that can be executed simultaneously on a CPU is limited by the number of cores available in the CPU. Each core can execute one thread at a time, so having multiple cores allows for multiple threads to be executed in parallel, potentially leading to improved performance. 

However, the relationship between threads and CPU cores is more complex than just one-to-one mapping.

In modern computer systems, threads can be scheduled dynamically on different cores by the operating system, and a single core can switch between multiple threads in order to maximize the utilization of available resources and CPU cores.

Additionally, some systems may also use techniques such as **hyper-threading**, where a single physical core is treated as multiple virtual cores, potentially allowing for even more threads to be executed simultaneously. 

Note that **simultaneous not equals to parallel. **

From this can also see the importance of those basic undergraduate courses, the principles of computer composition of a lot of content, including the CPU architecture, registers, buses, memory structure, how the CPU reads commands from the registers, which provides the basis for future operating system courses. For example, now we are learning about threads, processes, which are all part of the operating system curriculum, and hyper-threading, if you don't know how the CPU handles instructions and how it waits for the bus to send data, how can you understand the interrupt system very well? Golang is very popular now, it is very good at concurrency, Goroutine is very lightweight, but why is goroutine lightweight? You're probably going to get asked that in an interview, right? These are context switches, and you can't understand why goroutines are so powerful without learning the above, but that's just one example. This is just one example. Just one concurrency problem, and that's a lot of knowledge and lessons. The rest of the course such as the network, compilation principles, are very important, may not have an immediate effect, but they will be the future to support you the most solid foundation of the building.

Related article: 

[Context Switching - David's Blog](https://davidzhu.xyz/post/cs-basics/008-context-switching/)

[Hyper-Threading & Physical Threads - David's Blog](https://davidzhu.xyz/post/cs-basics/006-cpu-architecture/)

References:

- [Process and Thread Context Switching, Do You Know the Difference? ](https://medium.com/javarevisited/process-and-thread-context-switching-do-you-know-the-difference-updated-8fd93877dff6)
- [java - Difference between "call stack" and "thread stack" - Stack Overflow](https://stackoverflow.com/questions/31145052/difference-between-call-stack-and-thread-stack)
- [Memory in C – the stack, the heap, and static – The Craft of Coding](https://craftofcoding.wordpress.com/2015/12/07/memory-in-c-the-stack-the-heap-and-static/)

