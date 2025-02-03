---
title: 零碎知识 算法
date: 2025-02-02 15:28:52
categories:
 - 面试
tags:
 - 面试
 - 算法
 - 零碎知识
---

## 1. 列表常用操作

```python
# 844. Backspace String Compare
def backspaceCompare(s, t):
    s_arr = []
    t_arr = []
    for ch in s:
        if ch != '#':
            s_arr.append(ch) # 列表可以直接 append
        elif s_arr:
            s_arr.pop() # pop 之前要检查是否为空

    for ch in t:
        if ch != '#':
            t_arr.append(ch)
        elif t_arr:
            t_arr.pop()
    return t_arr == s_arr # 直接比较列表即里面的字符是否顺序全部相同
```

```python
def sortedSquares(self, nums: List[int]) -> List[int]:
    n = len(nums)
    ans = [0] * n  # 初始化 方便 index 访问
    start, end = 0, n - 1
    # 非常聪明的遍历方法, 不用重新倒序处理数组了
    for i in range(n - 1, -1, -1):
        if abs(nums[start]) >= abs(nums[end]):
            ans[i] = nums[start] * nums[start]
            start += 1
        else:
            ans[i] = nums[end] * nums[end]
            end -= 1
    return ans
```

