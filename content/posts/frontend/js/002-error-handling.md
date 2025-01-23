---
title: Error Handling Javascript
date: 2023-12-17 23:30:29
categories:
  - javascript
  - basics
tags:
  - javascript
---

## 1. Error handling with promise objects

### 1.1. Rejection handler

In JavaScript, when a promise is rejected, the control is passed to the **nearest rejection handler**. This is typically managed through `.catch()` blocks or through the **rejection parameter** in `.then()` method. 

1. The error will be catght by the **rejection parameter** of the `then()` method:

```js
const promise1 = new Promise((resolve, reject) => {
    setTimeout(() => {
        reject('Error in promise1');
    }, 1000);
});

const promise2 = promise1.then(
    value => console.log(value),
    error => {
        console.error('Caught in first handler:', error);
        // not re-throwing or returning another rejected promise, so flow goes to next then's fulfillment handler
    }
).then(
    () => console.log('This will still execute.'),
    error => console.error('Caught in second handler:', error)
).catch(
    error => console.error('Caught in catch:', error)
);
```

Output:

```
Caught in first handler: Error in promise1
This will still execute.
```

2. The error will be catght through `.catch()` blocks

```js
const promise1 = new Promise((resolve, reject) => {
    setTimeout(() => {
        reject('Error in promise1');
    }, 1000);
});

const promise2 = promise1.then(
    value => console.log(value),
).then(
    () => console.log('This will still execute.'),
    error => console.error('Caught in second handler:', error)
).catch(
    error => console.error('Caught in catch:', error)
);
```

Output:

```js
Caught in second handler: Error in promise1
```

### 1.2. Any errors will be caught before `catch()`

```js
// any errors happen in main block, will be caught
main().catch(err => console.log(err));

async function main() {
    await simulateDatabaseConnection();
    console.log('Connected to the database successfully')
}

async function simulateDatabaseConnection() {
    // Simulating a database connection attempt that could fail
    let isConnected = false;

    // Simulating an asynchronous operation using a Promise
    return new Promise((resolve, reject) => {
        setTimeout(() => {
            if (isConnected) {
                resolve('Connected to the database successfully');
            } else {
                reject('Failed to connect to the database');
            }
        }, 1000); // Simulating a delay of 1 second
    });
}

// print:
Failed to connect to the database. 
```

Another example:

```js
fetch('/article/promise-chaining/user.json')
  .then(response => response.json())
  .then(user => fetch(`https://api.github.com/users/${user.name}`))
  .then(response => response.json())
  .then(githubUser => new Promise((resolve, reject) => {
    let img = document.createElement('img');
    img.src = githubUser.avatar_url;
    img.className = "promise-avatar-example";
    document.body.append(img);

    setTimeout(() => {
      img.remove();
      resolve(githubUser);
    }, 3000);
  }))
  .catch(error => alert(error.message));
```

Normally, such `.catch` doesn’t trigger at all. But if any of the promises above rejects (a network problem or invalid json or whatever), then it would catch it.

## 2. `try` & `catch`

This is similar to other languages, any errors happen in the `try` block will be caught by catch:

```js
const promise = new Promise((resolve, reject) => {
    setTimeout(() => {
        reject('Error in promise');
    }, 1000);
});

async function exampleFunction() {
    try {
        await promise;
        console.log('This line will not execute if promise rejects');
    } catch (error) {
        console.error('Error caught in async function:', error);
    }
}

(async () => {
    await exampleFunction()
})()

// Error caught in async function: Error in promise
```

[Error handling with promises](https://javascript.info/promise-error-handling)
