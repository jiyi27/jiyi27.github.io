---
title: 零碎知识 + 踩坑 - Python
date: 2023-12-03 09:01:25
categories:
  - python
tags:
  - python
  - 零碎知识
  - 踩坑
---

## 1. 删除列表中除前两个元素外的所有元素

```python
def keep_first_two_del() -> None:
    global messages
    if len(messages) > 2:
        del messages[2:]  # 删除从第2个索引（第3个元素）到末尾
```

- `del messages[2:]`：从索引 2（第 3 个元素）开始删除到列表末尾
- 如果 messages = [1, 2, 3, 4, 5]，执行后变成 [1, 2]

```python
def keep_first_two_slice() -> None:
    global messages
    if len(messages) > 2:
        messages = messages[:2]  # 保留从开头到第2个元素
```

- `messages[:2]`：切片从开头到索引 2（不包括索引 2），即前两个元素

> `del messages[2:]`：直接修改原始列表, `del`是就地操作, 更高效
>
> `messages = messages[:2]`：创建新列表并重新赋值, 切片赋值创建新列表, 稍占内存

## 2. `from xxx import xxxx` vs `import xxx` 行为

### 2.1. `from xxx import xxxx`

在 Python 中, `from data import messages` 的语法会:

1. 加载指定的模块（如果尚未加载）
2. 从模块的命名空间中取出 `messages` 所绑定的对象
3. 在当前作用域中创建一个新的名称 `messages`, 并将它绑定到从模块中取出的对象上

这个新名称是一个独立的绑定, 它与模块中的原始名称（如 `data.messages`）没有动态关联, 换句话说, `from xxx import xxxx` 是“一次性拷贝引用”的操作, 而不是创建对模块属性的动态引用

```python
# 模块 data.py
value = 42

def change_value():
    global value
    value = 100
```

```python
# 然后在 main.py 中我们使用
from data import value, change_value

print("Before:", value)  # Before: 42
change_value()
print("After:", value)   # After: 42
```

- `from data import value` 将 `data.value` 的初始值（42）绑定到 `main.py` 中的 `value`
- `change_value()` 修改了 `data.value`, 将其重新绑定到 100
- 但 `main.py` 中的 value 仍然绑定到原始对象 42，因为它是导入时创建的独立名称绑定，而不是对 `data.value` 的动态引用

> 如果 value 是一个对象，修改它会发生什么？
>
> 如果 value 是一个可变对象（如列表、字典）, 通过 from xxx import xxxx 导入后, 修改这个对象的内容（原地修改）会同时影响模块中的 xxx.xxxx 和当前作用域的 xxxx, 因为它们指向同一个对象, 但如果重新绑定 xxxx（如赋值为一个新对象）, 则会断开这种关联
>
> **修改对象内容:**
>
> ```python
> # data.py
> value = [1, 2, 3]
> 
> def change_value():
>     global value
>     value = value[1:] # slice 会创建一个新对象, 因此 value 指向了一个不同的对象
> ```
>
> ```python
> # main.py
> from data import value
> 
> print("Before:", value)  # Before: [1, 2, 3]
> value.append(4)          # 修改对象内容
> print("After append:", value)  # After append: [1, 2, 3, 4]
> 
> # 检查 data.py 中的 value
> import data
> print("data.value:", data.value)  # data.value: [1, 2, 3, 4]
> ```
>
> - from data import value 让 main.py 的 value 和 data.value 指向同一个列表对象
> - value.append(4) 是原地修改这个共享对象，因此 data.value 也反映了变化
>
> **重新绑定**
>
> ```python
> # main.py
> from data import value, change_value
> 
> print("Before:", value)  # Before: [1, 2, 3]
> change_value()          # 模块内重新绑定
> print("After change_value:", value)  # After change_value: [1, 2, 3]
> 
> # 检查 data.py 中的 value
> import data
> print("data.value:", data.value)  # data.value: [2, 3]
> ```
>
> - change_value() 在 data.py 中重新绑定了 data.value 到 [2, 3]
> - 但 main.py 中的 value 仍然指向原来的 [1, 2, 3]，因为 from data import value 不会跟踪 data.value 的重新绑定

> **`from data import messages` 创建的是浅拷贝吗？**
>
> 严格来说，**`from data import messages` 并不创建浅拷贝**, 它只是将模块中 `messages` 所绑定的对象引用赋值给当前作用域中的名称 `messages`, 这不是拷贝（无论是浅拷贝还是深拷贝）, 而是直接共享同一个对象引用
>
> - 浅拷贝 shallow copy：会创建一个新对象, 但新对象中的元素是对原始对象元素的引用, 例如, `list.copy()` 或 `copy.copy()`
> - `from data import messages`: 浅拷贝创建一个新对象, from xxx import xxxx 不创建新对象, 而是共享引用

### 2.2. `import xxx`

相比之下，import xxx 的行为是：

1. 加载模块并将其作为对象引入当前作用域
2. 通过 `xxx.name` 访问模块的属性时，总是动态地查询模块的命名空间
3. 如果模块中的 `name` 被重新绑定，`xxx.name` 会反映最新的绑定

```python
# 使用相同的 data.py
value = 42

def change_value():
    global value
    value = 100
```

```python
# main.py
import data

print("Before:", data.value)  # Before: 42
data.change_value()
print("After:", data.value)   # After: 100
```

- import data 引入了模块对象 data

- data.value 是对 data 模块命名空间中 value 属性的直接引用

- 当 change_value() 修改 data.value 时，main.py 通过 data.value 访问时会看到最新的值（100）

## 3. 切片操作 浅拷贝

在 Python 中，切片操作（如 list[1:3]）会创建一个新的对象，但这是一个浅拷贝（shallow copy）, 浅拷贝意味着新对象会复制原始对象的顶层元素，但如果这些元素本身是可变对象（如列表、字典等），新对象中的元素仍然是对原始对象中对应元素的引用，而不是深层次的独立副本:

```python
# 原始列表
original = [[1, 2, 3], [4, 5, 6]]
# 通过切片创建新列表
sliced = original[:]

# 修改新列表中的子列表
sliced[0][0] = 99

print("原始列表:", original)  # [[99, 2, 3], [4, 5, 6]]
print("切片列表:", sliced)    # [[99, 2, 3], [4, 5, 6]]
```

- `sliced = original[:]` 通过切片创建了一个新列表 sliced，它是 original 的浅拷贝
- `sliced` 中的元素是对 original 中子列表 [1, 2, 3] 和 [4, 5, 6] 的引用，而不是全新的独立副本

> This is similar to reslicing in Golang, but not same, in Gloang the new slice shares a same underlying array with it resliced from, whereas Python will create a new list object directly. 
>
> ```golang
> // 原始切片
> original := []int{1, 2, 3, 4, 5}
> // 通过切片操作创建新切片
> sliced := original[1:3]
> 
> // 修改新切片
> sliced[0] = 99
> 
> fmt.Println("原始切片:", original) // [1 99 3 4 5]
> fmt.Println("新切片:", sliced)     // [99 3]
> ```
>
> - original 是一个切片，底层是一个数组 [1, 2, 3, 4, 5]
> - sliced := original[1:3] 创建了一个新切片，范围是索引 1 到 2（即 [2, 3]），但它仍然引用同一个底层数组

