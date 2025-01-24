---
title: 虚拟内存
date: 2025-01-22 14:58:10
categories:
 - 计算机基础
tags:
 - 操作系统
---

## 1. Virtual Memory

Virtual memory is a memory management technique that gives applications the impression that they have contiguous working memory (a continuous and complete address space), even though physical memory may be fragmented and some data may be temporarily stored on external disk storage, being swapped between them as needed.

> A memory management unit (MMU) is **a computer hardware unit** that examines all memory references on the memory bus, translating these requests, known as virtual memory addresses, into physical addresses in main memory. [Memory management unit](https://en.wikipedia.org/wiki/Memory_management_unit)

```risc
ld r1, 400(r2)
```

This instruction means to load data into register r1 from the address calculated by adding an offset of 400 to the content of register r2.

1. Calculate the Virtual Address:
   - Assume the register r2 currently holds the virtual address 0x1000 (4096 in decimal).
   - The offset 400 (0x190) is added to the content of r2.
   - Therefore, the calculated virtual address is 0x1000 + 0x190 = 0x1190 (virtual address).
2. Virtual to Physical Address Translation:
   - The MMU receives the virtual address 0x1190 and begins to look up the page table for the current process.
   - Suppose the page table entry shows that this virtual address maps to the physical address 0x5000.
   - The page offset (offset within the page) remains 0x190.
   - Thus, the complete physical address is 0x5000 + 0x190 = 0x5190.
3. Access Physical Memory and Execute Instruction:
   - Once the physical address is determined, the MMU instructs the system to load data from physical address 0x5190.
   - The data is loaded into register r1.

## 2. How Does Virtual Memory Work

RISC is a type of microprocessor design. Both MIPS and ARM are types of RISC architectures. MIPS gives each program its own 32-bit address space. Programs can only access any byte in their own address space.

1) What if we don't have enough memory? 
2) Holes in our address space? 
3) Keeping programs secure with virtual memory. 

[Virtual Memory: 4 How Does Virtual Memory Work?](https://www.youtube.com/watch?v=59rEMnKWoS4&list=PLiwt1iVUib9s2Uo5BeYmwkDFUh70fJPxX&index=4)

## 3. How does a game that is several hundred gigabytes run on a computer with only a few gigabytes of memory?

It's Not All Loaded at Once:

- Games, even huge ones, don't need all their data in memory at the same time. Think of a vast open-world game: you only need the data for the area immediately around your character.
- The game constantly loads and unloads data as you move through the world. This is called **streaming**.
- The operating system (OS) swaps data between your RAM and your storage drive (HDD or SSD). This means less frequently used game data sits on the drive until needed.

## 4. Segment Fault

A segmentation fault is a specific type of error that occurs when a program tries to access a segment of memory that it doesn’t have the permissions to access or that doesn’t exist, leading to the program’s abrupt termination by the operating system. 

[Understanding Segmentation Fault: What it is & How to Fix it](https://www.percona.com/blog/segmentation-fault-a-dba-perspective/)