---
title: Variable Parameter Python
date: 2023-09-07 22:51:26
categories:
  - python
tags:
  - python
typora-root-url: ../../../../static
---

### 1. Four types of parameter

1. Default argument
2. Keyword arguments (named arguments)
3. Positional arguments
4. Arbitrary arguments (variable-length arguments `*args` and `**kwargs`)

### 2. Parameters vs arguments

```python
# a and b here are pamameter
def my_sum(a, b): # function definition
  returen a + b
  
# a and 99 are arguments
my_sum(1, 99) # function call
```

### 3. Positional arguments vs keyword argumentss

```python
def add(lhs, rhs):
  ...
```

For this function we have many ways to call it,  `add(10, 20)`,  `add(lhs=10, rhs=20)` and  `add(10, rhs=20)`, 

- In `add(10, 20)`, `10`, `20` are positional arguments, 

-  In `add(lhs=10, rhs=20)`, `lhs=10` and ` rhs=20` are keyword arguments, 

- In `add(10, rhs=20)`, `10`  is positional arguments, `rhs=20` is keyword arguments, 

### 4. Arbitrary positional arguments (`*args`)

We can pass multiple arguments to the function. Internally all these values are represented in the form of a [tuple](https://pynative.com/python-tuples/). 

```python
def percentage(sub1, sub2, sub3):
    avg = (sub1 + sub2 + sub3) / 3
    print('Average', avg)

percentage(56, 61, 73)
```

This function works, but it’s limited to only three arguments. 

```python
# function with variable-length arguments
def percentage(*args):
    sum = 0
    for i in args:
        # get total
        sum = sum + i
    # calculate average
    avg = sum / len(args)
    print('Average =', avg)

percentage(56, 61, 73)
```

### 5. Arbitrary keyword arguments (**kwargs)

arbitrary keyword arguments use dictionary to store keyword arguments, 

```python
# function with variable-length keyword arguments
def percentage(**kwargs):
    sum = 0
    for sub in kwargs:
        # get argument name
        sub_name = sub
        # get argument value
        sub_marks = kwargs[sub]
        print(sub_name, "=", sub_marks)

# pass multiple keyword arguments
percentage(math=56, english=61, science=73)
```

Output:

```
math = 56
english = 61
science = 73
```

We can learn a lot from the source code if some python program:

```python
    def __prepare_create_request(
        cls,
        api_key=None,
        api_base=None,
        api_type=None,
        api_version=None,
        organization=None,
        **params,
    ):
        deployment_id = params.pop("deployment_id", None)
        engine = params.pop("engine", deployment_id)
        model = params.get("model", None)
        timeout = params.pop("timeout", None)
        stream = params.get("stream", False)
        headers = params.pop("headers", None)
```

- `model = params.get("model", None)` : It tries to retrieve the "model" key from the params dictionary, If that key exists, it uses that value, If that key does not exist, it uses the default value None.

- `deployment_id = params.pop("deployment_id", None)`: Same as `params.get()` but it will removes that key. 

References:

- [Python Function Arguments [4 Types] – PYnative](https://pynative.com/python-function-arguments/)
- [Dictionary - Python](https://docs.python.org/3/tutorial/datastructures.html)