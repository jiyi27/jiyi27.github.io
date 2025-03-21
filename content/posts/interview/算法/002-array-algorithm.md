---
title: 算法题 数组系列
date: 2025-02-02 15:28:52
categories:
 - 面试
tags:
 - 面试
 - 算法面试
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
# 977. Squares of a Sorted Array
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

```python
 matrix = [[0] * n for _ in range(m)]  # 初始化 n×m 矩阵
```

```python
# 切片 反转整个字符串, 切片和操作不会改变原字符串, 
# 它们会返回一个新字符串, 因为字符串 immutable
s = "abcdefg"
print(s[::-1])  # "gfedcba"

s = "abcdefg"
print(s[::-2])  # "geca"  -> 每隔2个字符倒序取

s = "abcdefg"
print(s[:4])   # "abcd"  -> 取前4个字符
print(s[4:])   # "efg"   -> 从索引4开始取到结尾

s = "abcdefg"
k = 3
result = s[k:] + s[:k]  # 交换前 k 个字符和剩余部分
print(result)  # "defgabc"

# 541. 反转字符串 II
def reverseStr(self, s: str, k: int) -> str:
    s = list(s)
    for i in range(0, len(s), k * 2):
        s[i: i + k] = s[i: i + k][::-1]  # 创建该切片的反转副本
    return ''.join(s)
```

## 2. 滑动窗口+暴力遍历 - 209 长度最小的子数组

注意子数组的意思是从一个数组任意截取连续的一段子数组, 不是从里面任取数字然后组合, 子序列也是这个概念, 

```python
def minSubArrayLen(s: int, nums: List[int]) -> int:
    # float('-inf') 负无穷大
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

> Find the longest continuous sub array that has exactly 2 distinct elements.

找出下面代码的错误:

```python
def totalFruit(self, fruits):
    i = 0
    max_len = 0
    basket = Counter()
    for j in range(len(fruits)):
        while len(basket) <= 2:
            basket[fruits[j]] += 1
            max_len = max(max_len, j - i + 1)
            j += 1
        i += 1
        del basket[fruits[i]]
    return max_len
```

1. **while 循环应当是用来收缩窗口的 (改变初始位置 `i`),** 如果用来扩大窗口, 会导致 `j` 不仅在 `for` 循环里被迭代，还在 `while` 里手动增加了 `j`，这会导致以下问题：无限循环或 IndexError
3. 直接 `del basket[fruits[i]]` 并不对, 想象我们的窗口是 [2, 3, 2, 2] 完整的数组是 [2, 3, 2, 2, 5], 此时篮子里的水果种类为 2, 所以我们让 `j` 往右移动继续扩大, 我们的滑动窗口变为 [2, 3, 2, 2, 5] , 此时篮子里有 3 类水果, 因此缩小窗口, 移动 `i`, 此时窗口为 [3, 2, 2, 5] , 若此时直接执行 `del basket[fruits[i]]`, 也就是把类别 2 的水果全部倒出, 就不合理, 因为我们有 3 个类别 2 的水果, 我们要做的应该是让 basket[2] - 1, 即丢掉一个种类为 2 的水果, 只有当 basket[2] = 0 的时候才可以删除 种类为 2 的水果
6. 然后我们继续让 i 往右移动, 刚好种类为 3 的水果就一个, 我们直接丢掉, 然后删除, 这样 篮子里就剩两个种类为 2 的元素, 此时滑动窗口为 [2, 2, 5]
7. 此时篮子里的水果种类为 2, 因此 这也是为什么, 我们需要 while 循环, 一直让 i 往右移动, 缩小窗口, 直到 篮子里的水果种类大于 2 为 false 的时候, 窗口右侧 j 才能继续移动

使用 `Counter()` 会造成不必要的开销, 在进行 `basket[fruits[i]] -= 1` 这种操作的时候, 会执行一些检查, 并不是直接操作, 所以我们换为 defaultdict 速度更快一些:

```python
def totalFruit(self, fruits):
    i = 0  # 滑动窗口的左边界
    max_len = 0  # 记录最大长度
    basket = {}  # 记录当前窗口内的水果种类和数量

    for j in range(len(fruits)):  # 遍历水果数组，j 是右指针
        basket[fruits[j]] = basket.get(fruits[j], 0) + 1  # 统计当前窗口内的水果数量

        # 如果窗口内的水果种类超过 2 种，移动左指针 i 缩小窗口
        while len(basket) > 2:
            basket[fruits[i]] -= 1  # 减少左边水果的个数
            if basket[fruits[i]] == 0:  # 如果某种水果数量变为 0，则从字典中删除
                del basket[fruits[i]]
            i += 1  # 左指针右移，缩小窗口
        
        # 记录当前窗口的最大长度
        max_len = max(max_len, j - i + 1)

    return max_len
```

虽然这题也是找连续子数组长度, 都使用双指针解决问题, 但与 209 长度最小的子数组 还是不同, 不同的地方是判断条件, 也就是收放窗口的条件, 之前的那道题的条件是判断 sum 总和和target的大小关系, 若 sum 更大, 则可以持续缩放窗口(while 循环条件), 而这道题的判断条件是数组中元素种类, 而且根据题意, 我们不可以简单的直接删除一个元素, 而是元素个数为0的时候才可以删除, 因此我们不仅需要元素种类, 而且需要知道该种类对应的元素个数, 因此只能使用哈希表, 不能使用比如 Set 这种一维数组, 

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

## 5. 代码输入输出调试

https://kamacoder.com/problempage.php?pid=1070

```python
import sys

def main():
  	input = sys.stdin.read # 读取
    data = input().split()  # 读取并拆分输入 (空白字符拆分
    index = 0
    n = int(data[index])  # 读取数组大小, 不要忘了 data 是字符数组
    index += 1

    nums = []
    for i in range(n):
        nums.append(int(data[index + i]))  # 读取数组的数值
    index += n  # 读取完 nums 后移动 index

    # 构建前缀和数组
    sums = [0] * n # 初始化 不要忘了
    sums[0] = nums[0]
    for i in range(1, n):
        sums[i] = sums[i - 1] + nums[i]

    result = []
    while index < len(data):
        left = int(data[index]) # 转换为整数
        right = int(data[index + 1])
        index += 2  # 移动到下一个查询

        if left == 0:
            result.append(sums[right])
        else:
            result.append(sums[right] - sums[left - 1])

    for res in result:
        print(res)

if __name__ == "__main__":
    main()
```

## 6. 二维数组

开发商购买土地: https://kamacoder.com/problempage.php?pid=1044

```
3 3
1 2 3
2 1 3
1 2 3
```

```python
def main():
    import sys
    
    input = sys.stdin.read 
    data = input().split()
    
    index = 0
    n = int(data[index])
    m = int(data[index + 1])
    index += 2
    
    nums = []
    sum = 0
    for i in range(n):
        row = []
        for j in range(m):
            num = int(data[index])
            row.append(num)
            index += 1 
            sum += num
        nums.append(row)
    
    horizontal = [0] * n
    for i in range(n):
        for j in range(m):
            horizontal[i] += nums[i][j]
    
    vertical = [0] * m
    for j in range(m):
        for i in range(n):
            vertical[j] += nums[i][j]
            
    result = float('inf')
    horizontalCut = 0
    for i in range(n):
        horizontalCut += horizontal[i]
        # horizontalCut - (sum - horizontalCut) = 两个区域的差 取绝对值
        result = min(result, abs(sum - 2 * horizontalCut))
    
    verticalCut = 0
    for j in range(m):
        verticalCut += vertical[j]
        result = min(result, abs(sum - 2 * verticalCut))
        
    print(result)

if __name__ == "__main__":
    main()
```

```python
class Solution(object):
    def generateMatrix(self, n):
        """
        :type n: int
        :rtype: List[List[int]]
        """
        top = left = 0
        bottom = right = n - 1
        square = n * n
        result = [[0] * n for _ in range(n)]
        
        num = 1
        while num <= square:
            # 从左到右填充
            for col in range(left, right + 1):
                result[top][col] = num
                num += 1
            top += 1
            
            # 从上到下填充
            for row in range(top, bottom + 1):
                result[row][right] = num
                num += 1
            right -= 1
            
            # 从右到左填充
            if top <= bottom:
                for col in range(right, left - 1, -1):
                    result[bottom][col] = num
                    num += 1
                bottom -= 1
                
            # 从下到上填充
            if left <= right:
                for row in range(bottom, top - 1, -1):
                    result[row][left] = num
                    num += 1
                left += 1
            
        return result
```

我们的遍历范围在 **左闭右闭**（即 `[left, right]` 或 `[top, bottom]`），也就是说，遍历时包括起点 `start` 和终点 `end`。这就是为什么我们在 `range()` 里要 `+1` 或 `-1` 来确保终点被包含。

**从右到左填充**

- 这一部分填充的是 **当前最底部的行** (`bottom` 行)。
- 但此时，`top` 已经向下移动了一格 (`top += 1`)，所以需要 **额外判断 `top <= bottom`**，确保当前 `bottom` 这行仍然 **未被填充过**。
- 如果 `top > bottom`，说明 `bottom` 这一行已经被上面的填充覆盖了，不需要执行这一步。

**从下到上填充**

- 这一部分填充的是 **当前最左侧的列** (`left` 列)。
- 但此时，`right` 已经向左移动了一格 (`right -= 1`)，所以需要 **额外判断 `left <= right`**，确保当前 `left` 这列仍然 **未被填充过**。
- 如果 `left > right`，说明 `left` 这一列已经被右边的填充覆盖了，不需要执行这一步。

在进入循环时，`top <= bottom` 和 `left <= right` 一定成立，因为矩阵初始是完整的，所以不需要额外判断。

