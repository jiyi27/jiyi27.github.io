---
title: Tricks & Mistakes in Javascript
date: 2024-01-02 10:55:20
categories:
  - javascript
  - basics
tags:
  - javascript
---

## 0. Minor tricks

### 0.1. array

> It is useful to remember which operations on arrays mutate them, and which don’t. For example, `push`, `pop`, `reverse`, and sort will mutate the original array, but `slice`, `filter`, and `map` will create a new one.

```js
if (isEmpty) {
    postList = <h1>No posts found.</h1>
} else {
    // return a new array
    postList = posts.map(post => (
        <SimplePostCard post={post} key={post._id} onDelete={() => handleDeletePost(post._id)}/>
    ));
}
```

### 0.2. string length

The `length` of a String value is the length of the string in **UTF-16 code units** not the number of characters. learn more: [String: length - JavaScript | MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/length)

```js
console.log('a'.length); // 1
console.log('汉'.length); // 1
console.log('😀'.length); // 2
```

> 1 UTF-16 code unit = 16 bits = 2 bytes

### 0.3. encding string to utf-8 in JS

TextEncoder: [TextEncoder - Web APIs | MDN](https://developer.mozilla.org/en-US/docs/Web/API/TextEncoder)

## 1. Spread operator

[Spread operator `...`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Spread_syntax#description):

- Function arguments list (myFunction(a, ...iterableObj, b))
- Array literals ([1, ...iterableObj, '4', 'five', 6])
- Object literals ({ ...obj, key: 'value' })

```js
// We pass a function as argument to setPost(), like a callback, which will return a new state object.
// React will call this callback with the previous state `post` as argument.
setPost(prevPost => ({
        ...prevPost, // object spread syntax
        comments: [data, ...prevPost.comments], // array spread syntax
        engagement: {
            ...prevPost.engagement, // object spread syntax
            numComments: prevPost.engagement.numComments + 1,
        }
    }));
```

> Arrow function will return the value of the expression by default, so we don't need to use `return` keyword.

## 2. Falsy values

In JavaScript, we have 6 falsy values:

- false
- 0 (zero)
- ‘’ or “” (empty string)
- null
- undefined
- NaN

All these return false when they are evaluated.

```js
// this just for simplicity, no this syntax
if(false/0/''/null/undefined/NaN) {
  console.log("never executed")
}
```

## 3. Catching errors

### 3.1. Catching errors in async functions

In JavaScript, `try...catch` blocks are designed to handle errors in synchronous code. However, they do not work as expected with asynchronous code, unless used in conjunction with async/await.

```js
function fetchData() {
    return new Promise((resolve, reject) => {
        // Simulate an asynchronous operation that fails
        setTimeout(() => reject(new Error("Failed to fetch data")), 1000);
    });
}

// The catch block here does not catch the error from fetchData()
function main() {
    try {
        fetchData().then((data) => {
            console.log(data);
        });
    } catch (error) {
        console.error('Error:');
    }
}
```

**Correct approach:**

```js
fetchData()
  .then(data => console.log(data))
  .catch(error => console.error('Error:', error));
```

```js
async function loadData() {
  try {
    const data = await fetchData();
    console.log(data);
  } catch (error) {
    console.error('Error:', error);
  }
}
```

### 3.2. Forget catching errors in neasted promises

```js
function fetchPosts() {
        fetch(`/posts`, {
            method: 'GET',
        })
            .then((res) => {
                if (res.status === 401) {
                    return redirect('/login');
                }

                // Catch block here does not catch errors from res.json()
                res.json().then(data => setPosts(data));
            })
            .catch((err) => {
                console.error('error fetching post:', err);
            });
    }
```

Your current code handles errors from the `fetc`h` call itself but does not handle potential errors that may occur during the parsing of the response with `res.json()`. This could be improved by adding a `.catch` block specifically for this parsing stage.

Since you are using `.then()` for promise resolution, it's fine. However, consider using an `async` function with `await` for better readability and easier error handling. This is more of a stylistic choice but can improve the clarity of your code.

```js
async function fetchPosts() {
    try {
        const res = await fetch(`/posts/${props.id}/`, {
            method: 'GET',
            credentials: 'include',
        });

        if (!res.ok) {
            if (res.status === 401) {
                // Handle unauthorized access
                return redirectToLogin(); // Assuming redirectToLogin is a defined function
            }
            throw new Error('Network response was not ok.');
        }

        const data = await res.json();
        setPosts(data);
    } catch (err) {
        console.error('Error fetching posts:', err);
        // Handle the error gracefully here
    }
}
```

## 4. `await xxxx` won't return a promise but the actual result of the promise

```js
async function handleGetPosts(req, res) {
    const posts = await fetchPosts(10);

    posts
    .then(...)
    .catch(...);
}

// You will get TypeError: posts.then is not a function
```

The issue in your code is that you're using `await` incorrectly with the `fetchPosts` function. When you use `await`, it waits for the promise to resolve and returns the result directly. Therefore, `posts` in your code is not a promise but the actual result of the promise. 

```js
async function handleGetPosts(req, res) {
    try {
        const posts = await fetchPosts(10);
        ...
    } catch (err) {
        ...
    }
}
```

