---
title: Collections in Python
date: 2023-06-17 22:51:31
categories:
  - python
tags:
  - python
---

## 1. List

### 1.1. Indexing

- right to left, use negative number, start from -1

- left to right, use positive number, start form 0

```python
arr = [1, 2, 3]
print(arr[-1]) # 3
print(arr[0]) # 1
print(arr[:-2]) # [1]
print(arr[-4]) # error: out of range
```

### 1.2. Reslice makes shallow copy

```python
cat = {
    "name": "Coco",
    "age": 3.5,
}

original_list = [cat, 2, 3, 4, 5]
copied_list = original_list[:3]

print("Original list:", original_list)
print("Copied list:", copied_list)

copied_list[1] = 999
copied_list[0]["name"] = "Bella"

print("Original list (after modification):", original_list)
print("Copied list (after modification):", copied_list)
```

Output:

```
Original list: [{'name': 'Coco', 'age': 3.5}, 2, 3, 4, 5]
Copied list: [{'name': 'Coco', 'age': 3.5}, 2, 3]
Original list (after modification): [{'name': 'Bella', 'age': 3.5}, 2, 3, 4, 5]
Copied list (after modification): [{'name': 'Bella', 'age': 3.5}, 999, 3]
```

> The [:] makes a **shallow copy** of the array, hence allowing you to modify your copy without damaging the original. The reason this also works for strings is that in Python, **Strings** are arrays of bytes representing Unicode characters. [What does [:] mean in Python?](https://blog.aaronmeese.com/what-does-mean-in-python-6831c027e43b)
>
> This is similar to reslicing in Golang, but not same, in Gloang the new slice shares a same underlying array with it resliced from, whereas Python will create a new list object directly. 

### 1.3. Reslicing in Golang and Python

**Python:** When you `new_list = old_list[start:end]`, a new list object is created and the elements from the specified slice are copied over (shallow copy) to this new list. This means the original list and the new list are completely independent of each other – changing one will not affect the other.

```python
# Python Example
original_list = [1, 2, 3, 4, 5]
sliced_list = original_list[:3]

original_list[0] = 99
sliced_list[1] = 101

print("Original list:", original_list)
print("Sliced list:", sliced_list)
# output
Original list: [99, 2, 3, 4, 5]
Sliced list: [1, 101, 3]
```

**Go:** the new slice created from reslicing does not copy the elements. Instead, it refers to the same underlying array as the original slice. 

```go
func main() {
	originalSlice := []int{1, 2, 3, 4, 5}
	newSlice := originalSlice[:3]

	originalSlice[0] = 99 // This also changes newSlice[0]
	newSlice[1] = 101  // This also changes originalSlice[1]

	fmt.Println("Original slice:", originalSlice)
	fmt.Println("New slice:", newSlice)
}

// ouput
Original slice: [99 101 3 4 5]
New slice: [99 101 3]
```

## 2. Dictionary

```python
dict = {'a': 1}
print(dict['b']) # Raise a KeyError
print(dict.get('b', 0)) # Print 0, with a default value 
```

e.g.,

```python
# calculate the frequency of the words
def count_words(word_list):
    word_count = {}
    for word in word_list:
        if word in word_count:
            word_count[word] += 1
        else:
            word_count[word] = 1
    return word_count
  
words = ["apple", "banana", "apple", "cherry", "banana", "apple"]
total, count = count_words(words)
```

## 3. Set

- Duplicates Not Allowed

  - Set items are unordered, unchangeable, and do not allow duplicate values.

- Unordered

  - Set items can appear in a different order every time you use them, and cannot be referred to by index or key.

- Unchangeable
  - Once a set is created, you cannot change its items, but you can remove items and add new items.


```python
# because duplicates not allowed, we can use this nature to remove duplicated words 
def find_missing_words(word_list_1, word_list_2):
    set1 = set(word_list_1)
    set2 = set(word_list_2)
    mis_words = set1 - set2
    return mis_words
```

