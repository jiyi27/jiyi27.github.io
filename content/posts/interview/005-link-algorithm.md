---
title: 算法题 链表系列
date: 2025-02-11 10:50:52
categories:
 - 面试
tags:
 - 面试
 - 算法
---

## 1. 常用技巧 dummy head

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

