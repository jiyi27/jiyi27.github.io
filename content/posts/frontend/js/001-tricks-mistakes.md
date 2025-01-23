---
title: Tricks & Mistakes in Javascript
date: 2024-03-12 10:55:20
categories:
  - javascript
  - basics
tags:
  - javascript
---

## 1. Minor tricks

### 1.1. array

> It is useful to remember which operations on arrays mutate them, and which don’t. For example, `push`, `pop`, `reverse`, and sort will mutate the original array, but `slice`, `filter`, and `map` will create a new one.
>
> `filter()` creates a **shallow copy** of a portion of a given array. 

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

```js
// state 后期可以用数据库代替
const UsersState = {
    users: [],
    setUsers: function (newUsersArray) {
        this.users = newUsersArray
    }
}

// 从UsersState中删除指定的用户
function userLeavesApp(id) {
    UsersState.setUsers(
        // filter 返回一个新数组 浅拷贝 shallow copy
        // filter() creates a shallow copy of a portion of a given array
        UsersState.users.filter(user => user.id !== id)
    )
}

// 在用户加入聊天室时激活用户，并确保 UsersState 中没有重复的用户
function activateUser(id, name, room) {
    const user = { id, name, room }
    UsersState.setUsers([
        ...UsersState.users.filter(user => user.id !== id),
        user
    ])
    return user
}
```

### 1.2. string length

The `length` of a String value is the length of the string in **UTF-16 code units** not the number of characters. learn more: [String: length - JavaScript | MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/length)

```js
console.log('a'.length); // 1
console.log('汉'.length); // 1
console.log('😀'.length); // 2
```

> 1 UTF-16 code unit = 16 bits = 2 bytes

### 1.3. encding string to utf-8 in JS

TextEncoder: [TextEncoder - Web APIs | MDN](https://developer.mozilla.org/en-US/docs/Web/API/TextEncoder)

### 1.4. localStorage

`localStorage` calculates its size limit based on the number of UTF-16 code units, not bytes. You can use the `length` property to get the number of code units in a string.

```js
function setLocalStorageSize() {
    localStorage.clear();
    if (localStorage && !localStorage.getItem('size')) {
        let i = 0;
        try {
            // Roughly 10240000 UTF-16 code units.
            for (i = 250; i <= 10000; i += 250) {
                // A character is 1B, (i * 1024) = i * 1KB
                localStorage.setItem('test', new Array((i * 1024) + 1).join('a'));
            }
        } catch (e) {
            localStorage.removeItem('test');
            // size in utf-16 code units, not bytes.
            localStorage.setItem('size', String(i - 250));
            console.log('localStorage size: ' + (i - 250) + '*1024 code units');
        }
    }
}
// will print: 5000*1024 code units
```

If you change the code above to:

```js
localStorage.setItem('test', new Array((i * 1024) + 1).join('汉'));
```

Stil will print: 5000*1024 code units, because `汉` is 1 UTF-16 code unit same as `a`.

But if you change the code above to:

```js
localStorage.setItem('test', new Array((i * 1024) + 1).join('😀'));
```

Will print: 2500*1024 code units, because `😀` is 2 UTF-16 code units.

## 2. Spread operator

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

## 3. Falsy values

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

## 4. Catching errors

### 4.1. Catching errors in async functions

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

### 4.2. Forget catching errors in neasted promises

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

## 5. `await xxxx` won't return a promise but the actual result of the promise

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

