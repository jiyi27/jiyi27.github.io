---
title: Yeild & Generator Python 
date: 2023-11-23 16:04:26
categories:
  - python
tags:
  - python
typora-root-url: ../../../../static
---

## 1. Definition

`yield` is a keyword that is used like `return`, but it will make the function return a **generator**.

```python
def create_generator():
    print("create_generator")
    for i in range(10):
        yield i

ite = create_generator()
print(ite) # ite is a generator object
for i in ite:
    print(i)

# <generator object create_generator at 0x102d2bdd0>
# create_generator
# 0
# 1
# 2
```

When you call a function that contains a `yield` statement, you get a generator object, but **no code runs**. Then each time you extract from the generator, Python resumes the function from where it left off (from the `yield`), runs until the next `yield`, and then pauses again. 

## 2. Why `yield`

**Handling Large Data**: If you're working with a large amount of data that doesn't fit into memory, a generator can be a great solution. It allows you to process **one item at a time** rather than loading everything into memory at once.

> Yield is more efficient, memory-wise, and also sometimes execution-wise. If you iterate over a list of 1,000,000 elements, Python has to generate the entire list and store the contents in memory before beginning the first iteration. With a generator (using yield), the elements are created at the time of iteration, so 1,000,000 elements don’t need to be pre-calculated first and stored in memory.
>
> There are other benefits such as using generators with async or performing logic after certain iterations (that generators can potentially give better control over than iterating over a list), but in my opinion the main reason for using them is the memory and processing considerations.
>
> https://www.reddit.com/r/learnpython/comments/rzukrb/comment/hrxetbx/?utm_source=share&utm_medium=web2x&context=3

> Yep its 99% about memory. First time I used it was when I was working with huge amounts of data from a SQL server. Rather than do analysis on all 100,000,000 lines at once, not joking about how many, I pulled back 10k at a time used yield to send the 10k to the analysis function. Then sent the updated data on to the system that needed it. Used like 20MB of RAM as apposed to like 200GB. 
>
> https://www.reddit.com/r/learnpython/comments/rzukrb/comment/hrxhm46/?utm_source=share&utm_medium=web2x&context=3

## 3. Example - read large file

The files range between 1Gb and ~20Gb in length which is too big to read into RAM. So I would like to read the lines in chunks/bins of say 10000 lines at a time so that I can perform calculations on the final column in these bin sizes.

Instead of playing with offsets in the file, try to build and yield lists of 10000 elements from a loop:

```python
def read_large_file(file_handler, block_size=10000):
    block = []
    for line in file_handler:
        block.append(line)
        if len(block) == block_size:
            yield block
            block = []

    # don't forget to yield the last block
    if block:
        yield block

with open(path) as file_handler:
    for block in read_large_file(file_handler):
        print(block)
```

Learn more: [using a python generator to process large text files - Stack Overflow](https://stackoverflow.com/questions/49752452/using-a-python-generator-to-process-large-text-files)

## 4. Example - async

```python
from typing import Iterator, Any, cast
from openai import OpenAI

client = OpenAI()

def chat(messages: list, stream: bool) -> Iterator[str]:
    response_iter = cast(
        # The Any type is a special type that represents an unconstrained value
        # and is often used when the type of the value is not known or needs to be dynamically determined.
        Any,
        # client.chat.completions.create() won't return immediately, it will make requests to the API.
        # time.sleep(1), you can umcomment this to stimulate the time of the request.
        client.chat.completions.create(
            messages=messages,
            stream=stream,
            model="gpt-3.5-turbo-1106",
            max_tokens=200,
        ),
    )

    if stream:
        for response in response_iter:
            if response.choices[0].delta.content is not None:
                chunk = response.choices[0].delta.content
                yield chunk
    else:
        yield response_iter.choices[0].message.content


msg = [{"role": "user", "content": "Hello, help me write a essay about the history of the United States of America."}]
steam = True
ite = chat(msg, steam) # async: you will get a generator object, but no code in function chat() runs
for i in ite:
    print(i, end="", flush=True)
```

