---
title: 刷题常用语法  Python
date: 2025-02-02 15:28:52
categories:
 - 面试
tags:
 - 面试
 - 算法
 - python
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

