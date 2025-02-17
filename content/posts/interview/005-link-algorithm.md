---
title: 算法题 链表系列
date: 2025-02-11 10:50:52
categories:
 - 面试
tags:
 - 面试
 - 算法
---

## 1. Dummy Head

链表 A B C, 我们若想移除 B, 需要 A.next = B.next, 所以当头部节点也有可能被移除的时候, 我们就需要一个 dummy 节点: D A B C, 从而实现 D.next = A.next 进而删除 A 节点,

除此之外, 我们并不能直接移动 dummy 节点, 因为我们要记住 头部节点的位置, 用于函数返回, 不管这个头部 是 A, B 或者 C,

我们要再使用一个节点 current, 通过 current = current.next 来遍历整个链表, 这样不管最后怎么变, dummy.next 都是最后形成的链表的第一个节点, 

```python
class ListNode(object):
    def __init__(self, val=0, next=None):
        self.val = val
        self.next = next
        
def removeElements(self, head, val):
    # 用于记住头部节点
    dummy = ListNode(0, head)
    current = dummy
    while current.next:
        if current.next.val == val:
            current.next = current.next.next
        else:
            current = current.next
    return dummy.next
```

## 2. 实现链表

在做涉及到 index 和 size 相关的问题时, 一定要考虑清楚,  index 是从 0 开始 还是从 1 开始, 这很重要, 它告诉了我们 index 是不是 可以等于 size, 还是 size = index + 1

```python
class Node:
    def __init__(self, val=0, next=None):
        self.val = val
        self.next = next

class MyLinkedList:

    def __init__(self):
        self.head = None
        self.size = 0  # 维护链表长度

    def get(self, index):
        if index < 0 or index >= self.size:
            return -1
        
        cur = self.head
        for _ in range(index):
            cur = cur.next
        return cur.val

    def addAtHead(self, val):
        # self.head 只是一个 reference, 指向在堆上的对象, 
        # 只有有引用指向对象, 对象就不会被清理
        # 这也是为什么我们可以这么操作
        node = Node(val, self.head)
        self.head = node
        self.size += 1  # 更新长度

    def addAtTail(self, val):
        # 链表相关的题, 每当访问某个节点的 next, 
        # 就要想一下, 该节点有没有可能为空
        if not self.head:
            self.head = Node(val)
        else:
            cur = self.head
            while cur.next:
                cur = cur.next
            cur.next = Node(val)
        self.size += 1  # 更新长度

    def addAtIndex(self, index, val):
        if index > self.size:
            return  # 超出范围，直接返回
        if index <= 0:
            self.addAtHead(val)
            return
        
        dummy = Node(0, self.head)
        cur = dummy
        for _ in range(index):
            cur = cur.next
        
        node = Node(val, cur.next)
        cur.next = node
        self.head = dummy.next
        self.size += 1  # 更新长度

    def deleteAtIndex(self, index):
        if index < 0 or index >= self.size:
            return  # 超出范围，直接返回
        
        dummy = Node(0, self.head)
        cur = dummy
        for _ in range(index):
            cur = cur.next
        
        if cur.next:
            cur.next = cur.next.next
        self.head = dummy.next
        self.size -= 1  # 更新长度
```

用到了 prev 和 head, 即每次交换都是 prev 和 head 往下移动, 前者代表虚拟节点, 后者代表要交换的第一个, 

first 和 second 则代表两个要交换的节点, 这样 prev first second 三个配合交换, 交换之后, prev 往下移动, head 往下移动, 继续重复 

```python
def swapPairs(self, head):
    if not head:
        return None
    if not head.next:
        return head
    dummy = ListNode(0)
    dummy.next = head
    prev = dummy

    while head and head.next:
        first = head
        second = head.next

        prev.next = second
        first.next = second.next
        second.next = first

        prev = first
        head = first.next

    return dummy.next
```

