---
title: Loop Invariant
date: 2024-01-19 20:32:25 
categories:
  - 计算机基础
tags:
  - cs basics
---

## Definition

In simple words, a loop invariant is some predicate (condition) that holds for every iteration of the loop. For example, let's look at a simple for loop that looks like this:

```c
int j = 9;
for(int i=0; i<10; i++)  
  j--;
```

In this example it is true (for every iteration) that i + j == 9. A weaker invariant that is also true is that i >= 0 && i <= 10.

As people point out, the loop invariant must be true:

1. before the loop starts
2. **before** each iteration of the loop
3. after the loop terminates

> 就是正确的算法在循环的各个阶段, 总是存在一个固定不变的特性, 找出这个特性并且你写的代码可以证明其固定不变, 则可推断出你写的代码是正确的. 
> 如何证明那个特性(循环不变式)固定不变呢? 具体的说就是证明它满足上面的三个条件.

( although it can temporarily be false during the body of the loop ). On the other hand the **loop conditional** must be false after the loop terminates, otherwise the loop would never terminate. Thus the **loop invariant** and the **loop conditional** must be different conditions.

## Example

### Binary Search

**第一步确定循环不变量**：在每次迭代开始时以及循环结束时，如果目标元素存在于数组中，则它必定位于数组的 [low, high] 索引范围内 (左闭右闭区间)

**第二步根据循环不变量来验证自己写好的代码** (或者写代码的时候就开始验证):

```python
def search(self, nums, target):
    left = 0
    right = len(nums) - 1  # 记得减1, 因为我们循环不变量为左闭右闭区间
    while left < right:
        m = (left + right) // 2
        if target > nums[m]:
            left = m + 1
        elif target < nums[m]:
            right = m - 1
        else:
            return m
    return -1
```

**第三步验证**：

1. before the loop starts：若目标在数组中, 则其必在 [left, high] 区间内, 因此循环不变量成立
2. **before** each iteration of the loop: 每次迭代开始时, 我们都会将搜索区间减半, left = m + 1 或 right = m - 1, 排除了当前中间元素, 因此循环不变量成立
3. after the loop terminates: 循环结束后, 有可能是 left == right, 比如 [3, 3], 若元素的index就是3, 则错过了, 循环不变量不成立, 因此要 while 结束的条件要改为 left <= right 而不是 left < right

注意, 循环不变量本身用于确保算法逻辑的正确性，而不直接涉及到如何避免死循环, 若上面代码改为如下, 则会死循环:

```python
if target > nums[m]:
    left = m
elif target < nums[m]:
    right = m
```

而此时循环不变量仍然成立: 若存在, 目标元素在 [left, right] 区间内, 

〉 `left = m + 1`, 或 `right = m - 1` 保证了每次迭代都会排除至少一个元素, 避免了死循环的发生

结合以上各个算法，可以找出根据需要写二分查找的规律和具体步骤，比死记硬背要强不少，万变不离其宗嘛：

　　(1)大体框架必然是二分，那么循环的key与array[mid]的比较必不可少，这是基本框架;

　　(2)循环的条件可以先写一个粗略的，比如原始的while(left<=right)就行，这个循环条件在后面可能需要修改；

　　(3)确定每次二分的过程，要保证所求的元素必然不在被排除的元素中，换句话说，所求的元素要么在保留的其余元素中，要么可能从一开始就不存在于原始的元素中；

　　(4)检查每次排除是否会导致保留的候选元素个数的减少？如果没有，分析这个边界条件，如果它能导致循环的结束，那么没有问题；否则，就会陷入死循环。为了避免死循环，需要修改循环条件，使这些情况能够终结。新的循环条件可能有多种选择：while(left< right)、while(left< right-1)等等，这些循环条件的变种同时意味着循环终止时候选数组的形态。

　　(5)结合新的循环条件，分析终止时的候选元素的形态，并对分析要查找的下标是否它们之中、同时是如何表示的。

　　对于(3)，有一些二分算法实现不是这样的，它会使left或right在最后一次循环时越界，相应的left或right是查找的目标的最终候选，这一点在理解时需要注意。当然，不利用这个思路也可以写出能完成功能的二分查找，而且易于理解。

References:

- [algorithm - What is a loop invariant? - Stack Overflow](https://stackoverflow.com/questions/3221577/what-is-a-loop-invariant)
- [利用循环不变式写出正确的二分查找及其衍生算法 – KelvinMao Blog](https://kelvinmao.github.io/%E5%88%A9%E7%94%A8%E5%BE%AA%E7%8E%AF%E4%B8%8D%E5%8F%98%E5%BC%8F%E5%86%99%E5%87%BA%E6%AD%A3%E7%A1%AE%E7%9A%84%E4%BA%8C%E5%88%86%E6%9F%A5%E6%89%BE%E5%8F%8A%E5%85%B6%E8%A1%8D%E7%94%9F%E7%AE%97%E6%B3%95/)