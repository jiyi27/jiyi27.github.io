---
title: Promise Object in Javascript
date: 2023-11-28 12:34:29
categories:
  - javascript
  - basics
tags:
  - javascript
---

## 1. Concurrency models

- Processes
- Threads (system or green)
- **Futures**
  - Asynchronous operations, non-blocking, single-threaded
- Coroutines
- CSP
- Actor

Learn more: [java - What's the difference between a Future and a Promise? - Stack Overflow](https://stackoverflow.com/questions/14541975/whats-the-difference-between-a-future-and-a-promise)

## 2. Promise object

- A wrapper for a resolved value or a reason that it's not resolved yet.
- But with some powerful methods, allow you handle different situations.
- Like the `then` chain, the `catch`
- Non-blocking: enable you to write asynchronous code in a synchronous manner.
  - Most important feature.
- There are more complicated methods, 

The `Promise` object has several fields and methods, including:

1. **`state`**: A **private** field that represents the current state of the promise (`pending`, `fulfilled` or `rejected`).
2. **`result`**: A **private** field that holds the result value if the promise is fulfilled or the reason if it is rejected.
3. **`then()`**, **`catch()`**, **`finally()`** methods, only get executed when the state of Promise object is `fulfilled` or `rejected`. 

## 3 Use `await/async` with Promise object

```js
async function main() {
    let response
    try {
        // 'response' is not a Promise object, 
        // it's the resolved value the in the Promise object
        response = await fetch('https://www.google.com');
    } catch (err) {
        console.error("an err happened");
        return
    }
    console.log(response.ok);
}

main().then()
```

You may wonder why we need call `then()` after `main()`, the reason is that `async functions` always return a promise implicitly.

> If the return value of an `async` function is not explicitly a promise, **it will be implicitly wrapped in a promise**. An `async` function is really just a fancy Promise wrapper.

If you call main like this:

```js
...

await main();
```

There will be an error: 

```
await main();
^^^^^

SyntaxError: await is only valid in async functions and the top level bodies of modules
```

This is another syntax to call async function:

```js
(async () => {
  await main()
})()
```

## Use `then()` with Promise object

```js
fetch('https://www.google.com')
    .then(response => console.log(response.status))
    .catch(err => console.error("An err occurred."))
```

Because `fetch()` retuens a Promise object, we can call `then()` directly, this looks more concise than ealier example. 

But we usually use `await/async` instead of `then()` for readability in real world projects, because we need handle errors and consider different situations.

```js
async function fetchMessage(messages) {
        setLoading(true)
        controller.current = new AbortController()
        try {
            const response = await fetch(fetchPath, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': localStorage.getItem('token'),
                },
                body: JSON.stringify({messages}),
                signal: controller?.current?.signal,
            });
            const data = await response.json();
            setLoading(false)

            if (!response.ok) {
                // remove the last message
                setMessages((messages) => messages.slice(0, -1));
                message.error({
                    content: "获取信息失败, 请联系截图主人喵~: " + data.error,
                    duration: 5,
                });
                return;
            }

            return data;
        } catch (e) {
            setLoading(false)
            // remove the last message
            setMessages((messages) => messages.slice(0, -1));

            if (e.name === 'AbortError') {
                return
            }

            message.error("获取信息失败, 请联系截图主人喵~: " + e);
        }
    }
```