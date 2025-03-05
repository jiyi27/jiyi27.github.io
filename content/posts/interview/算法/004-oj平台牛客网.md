---
title: 国内面试 OJ 平台调试
date: 2025-02-14 22:21:39
categories:
 - 面试
tags:
 - 面试
---

```python
import sys

# split() 默认会去掉换行符和多余的空格
data = sys.stdin.read().split()
for i in range(0, len(data), 2):
    print(int(data[i]) + int(data[i+1]))
```

