---
title: Common Mistakes and Tricks Python
date: 2023-12-03 09:01:25
categories:
  - python
tags:
  - python
---

## 1. Slicing makes shallow copy of a list

I have talked this nature of slicing in [previous post](https://davidzhu.xyz/post/python/basics/001-collections/), currently I came across a weird behavior when improt a variable from another package. 

`messag.py`:

```python
messages = []

def with_user(msg: str) -> None:
    messages.append(msg)

def trim_last_two_messages() -> None:
    global messages
    print("in trim func, before trim, len of messages:" + str(len(messages)))
    if len(messages) > 2:
        messages = messages[:-2]
        print("in trim func, after trim, len of messages:" + str(len(messages)))

if __name__ == "__main__":
    pass
```

`main.py`:

```python
from message import messages
from message import with_user
from message import trim_last_two_messages

with_user('hello')
with_user('world')
with_user('foo')

print("main func, before trim:", messages)
trim_last_two_messages()
print("main func, after trim:", messages)
```

The output is:

```
main func, before trim: ['hello', 'world', 'foo']
in trim func, before trim, len of messages:3
in trim func, after trim, len of messages:1
main func, after trim: ['hello', 'world', 'foo']
```

But what I expected is:

```
main func, before trim: ['hello', 'world', 'foo']
in trim func, before trim, len of messages:3
in trim func, after trim, len of messages:1
main func, after trim: ['hello']
```

1. **Importing `messages`:** When you import `messages` from `message.py` into `main.py`, you are importing a reference to the same list object that exists in `message.py`.
2. **Appending Messages:** When you call `with_user`, it appends new messages to the `messages` list. Both `main.py` and `message.py` are still referring to the same list object.
3. **Trimming Messages:** In `trim_last_two_messages`, you are slicing the `messages` list (`messages = messages[:-2]`). This is where the key behavior occurs. Slicing a list in Python creates a new list object. So after this slicing operation, `message.py`'s `messages` now points to a new list object, but `main.py`'s `messages` still points to the original list object.

Because of this, changes made to the list in `message.py` (after the slicing operation) are not reflected in `main.py`, as they are now two different list objects.

Correct way (change the function in message.py):

```python
def trim_last_two_messages() -> None:
    global messages
    print("in trim func, before trim, len of messages:" + str(len(messages)))
    if len(messages) > 2:
        del messages[-2:]
        print("in trim func, after trim, len of messages:" + str(len(messages)))
```

**or** 

Change the code in `main.py`:

```py
import message

# use messages as this:
print(message.messages)
```

## 2. Performance of `del` vs `relicing`

```python
import timeit

# Test with a large list
large_list = list(range(1000000))  # a list with one million elements

def test_del_method():
    temp_list = large_list.copy()
    del temp_list[-2:]

def test_slice_method():
    temp_list = large_list.copy()
    temp_list = temp_list[:-2]

time_del = timeit.timeit(test_del_method, number=100)
time_slice = timeit.timeit(test_slice_method, number=100)

print(f"Time taken by del method: {time_del} seconds")
print(f"Time taken by slice method: {time_slice} seconds")
```

The output:

```
Time taken by del method: 0.312709417 seconds
Time taken by slice method: 0.683257708 seconds
```

