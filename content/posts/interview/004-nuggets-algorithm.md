---
title: 零碎知识 - 算法
date: 2025-02-02 15:28:52
categories:
 - 面试
tags:
 - 面试
 - 算法
 - 零碎知识
---

> 看到题目先在纸上写出 bruteforce, 然后思考怎么优化, 好处是如果你认真思考过题目你会更理解优化过的答案, 规定每一题的时间不超过一小时自己想 10 分钟, 没思路就去看别人的解题思路, 花15分钟左右去理解整个思路, 然后就自己尝试, 超过1小时了就直接看别人代码

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

## 2. 滑动窗口+暴力遍历 - 209 长度最小的子数组

注意子数组的意思是从一个数组任意截取连续的一段子数组, 不是从里面任取数字然后组合, 子序列也是这个概念, 

```python
def minSubArrayLen(s: int, nums: List[int]) -> int:
    result = float('inf')
    sum_val = 0
    sub_length = 0
    
    for i in range(len(nums)):  # 设置子序列起点为 i
        sum_val = 0
        for j in range(i, len(nums)):  # 注意第二层循环从 i 开始
            sum_val += nums[j]
            if sum_val >= s:
                sub_length = j - i + 1
                result = min(result, sub_length)
                break  # 一旦符合条件就 break
    
    return 0 if result == float('inf') else result
```

```python
def minSubArrayLen(target, nums):
    min_len = float('inf')
    i = 0
    sum = 0
    for j in range(len(nums)):
        sum += nums[j]
        while sum >= target:
            min_len = min(j - i + 1, min_len) # 注意 j - i + 1
            sum -= nums[i]
            i += 1 # python 不支持 i++, 精髓动态更新初始位置, 不断收缩窗口
    return min_len if min_len != float('inf') else 0 # 常用语法
```

## 3. 字典的使用 - 904. Fruit Into Baskets

找出下面代码的错误:

```python
def totalFruit(self, fruits):
    i = 0
    max_len = 0
    basket = Counter()
    for j in range(len(fruits)):
        while len(basket) <= 2:
            basket[fruits[j]] += 1
            max_len = (max_len, j - i + 1)
            j += 1
        i += 1
        del basket[fruits[i]]
    return max_len
```

1. **while 循环应当是用来收缩窗口的 (改变初始位置 `i`),** 如果用来扩大窗口, 会导致 `j` 不仅在 `for` 循环里被迭代，还在 `while` 里手动增加了 `j`，这会导致以下问题：无限循环或 IndexError
2. `max_len = (max_len, j - i + 1)` 是个容易犯错的地方, 忘了加 `max`
3. 直接 `del basket[fruits[i]]` 并不对, 想象我们的窗口是 [2, 3, 2, 2] 完整的数组是 [2, 3, 2, 2, 5], 
4. 此时篮子里的水果种类为 2, 所以我们让 `j` 往右移动继续扩大, 我们的滑动窗口变为 [2, 3, 2, 2, 5] , 此时篮子里有 3 类水果, 
5. 所以缩小窗口, 移动 `i`, 此时窗口为 [3, 2, 2, 5] , 若此时直接执行 `del basket[fruits[i]]`, 也就是把类别 2 的水果全部倒出, 就不合理, 因为我们有 3 个类别 2 的水果, 我们要做的应该是让 basket[2] - 1, 即丢掉一个种类为 2 的水果, 只有当 basket[2] = 0 的时候才可以删除 种类为 2 的水果, 
6. 然后我们继续让 i 往右移动, 刚好种类为 3 的水果就一个, 我们直接丢掉, 然后删除, 这样 篮子里就剩两个种类为 2 的元素, 此时滑动窗口为 [2, 2, 5]
7. 此时篮子里的水果种类为 2, 因此 这也是为什么, 我们需要 while 循环, 一直让 i 往右移动, 缩小窗口, 直到 篮子里的水果种类大于 2 为 false 的时候, 窗口右侧 j 才能继续移动, 

```python
def totalFruit(self, fruits):
    i = 0
    max_len = 0
    basket = Counter()
    for j in range(len(fruits)):
        while len(basket) > 2:
            basket[fruits[i]] -= 1
            if basket[fruits[i]] == 0:
                del basket[fruits[i]]
            i += 1
        basket[fruits[j]] += 1
        max_len = max(max_len, j - i + 1)

    return max_len
```

此时**仍有一处逻辑错误**, 请找出, 另外使用 `Counter()` 会造成不必要的开销, 在进行 `basket[fruits[i]] -= 1` 这种操作的时候, 会执行一些检查, 并不是直接操作, 所以我们换为 defaultdict 速度更快一些, 

```python
from collections import defaultdict

def totalFruit(self, fruits):
    i = 0
    max_len = 0
    basket = defaultdict(int)

    for j in range(len(fruits)):
        basket[fruits[j]] += 1  # 添加水果, 直接的整数增减

        while len(basket) > 2:
            basket[fruits[i]] -= 1
            if basket[fruits[i]] == 0:
                del basket[fruits[i]]
            i += 1  # 移动窗口

        max_len = max(max_len, j - i + 1)

    return max_len
```

## 4. 循环嵌套 58 Length of Last Word

找出下面代码的逻辑问题, 最开始的解决思路, len 记录单词的长度, 每次遇到空格就会跳出 while 循环, 然后更新重新计算新的单词的长度, 

```python
def lengthOfLastWord(self, s):
    len = 0
    for i in range(len(s)):
        len = 0
        while s[i] != ' ' and i < len(s):
            len += 1
            i += 1
    return len
```

关于 len 的重置有问题, 没有考虑最后有空格的情况, 比如 `"Hello World  "`, 我们期望 5，实际输出是 0, 因为遍历完最后一个单词跳出 while 后, i 仍没越界, 此时重新进入 for 循环, len 又被重置为零, 可是后面的都是空格, 也不会进入 while 循环, len 一直为 0, 

```python
def lengthOfLastWord(self, s):
    len = 0 # len 是个函数, 命名重复
    for i in range(len(s)):
        len = 0  # 这个重置会导致问题, 没有考虑最后有空格的情况
        # i < len(s) 这个检查并不安全, 应该先检查是否越界
        while s[i] != ' ' and i < len(s):
            len += 1
            i += 1 # 最严重的问题在这, 
    return len
```

`i` 在 while 循环中被改变了（`i += 1`），但是这个 `i` 也是 for 循环的控制变量。这会导致：

- 比如当 for 循环 i = 0 时
- while 循环增加 i 到 5
- 但 for 循环下一轮会让 i = 1，**又重新从头开始数**

所以**永远不要在两个地方修改循环变量**, 正确的写法如下:

```python
def lengthOfLastWord(self, s):
    s = s.strip() # 截取空格
    length = 0
    for i in range(len(s)):
        if s[i] != ' ':
            length += 1
        else:
            length = 0
    return length
```

但是这还不够高效, 可以直接从后面倒序遍历, 遇到空格就跳出:

```python
def lengthOfLastWord(self, s):
    s = s.strip()
    length = 0
    # 又一次出现了这个聪明的遍历方式
    for i in range(len(s) - 1, -1, -1):
        if s[i] != ' ':
            length += 1
        else:
            break
    return length
```

