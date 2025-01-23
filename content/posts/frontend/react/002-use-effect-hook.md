---
title: useEffect Hook in React
date: 2023-12-26 19:49:22
categories:
 - front-end
tags:
 - front-end
---

## 为什么 useEffect 不能是异步函数

异步函数隐式地返回一个`Promise`，而`useEffect`的设计是期望返回一个清理函数或者什么都不返回（`undefined`）。这个设计原则确保了React能够正确地处理副作用和它们的清理逻辑。

如果你需要在`useEffect`中执行异步操作，正确的做法是在`useEffect`的函数体内定义一个异步函数，并在该函数内执行异步操作，然后立即调用这个异步函数。例如：

```javascript
useEffect(() => {
  async function fetchData() {
    // 异步操作
    const data = await fetchSomeData();
    // 使用数据更新状态
    setState(data);
  }

  fetchData();

  // 清理函数（如果需要）
  return () => {
    // 清理逻辑
  };
}, [/* 依赖列表 */]);
```

这种模式允许在`useEffect`内部使用异步操作，同时遵循React的副作用处理规则。

> **函数组件在其主体内不应该执行有副作用的操作**，比如直接进行网络请求、订阅事件、直接操作DOM等。这些操作应该放在特定的生命周期方法或钩子（如`useEffect`）

## 2. When `useEffect` is called

**What does useEffect do?** By using this Hook, you tell React that your component needs to do something **after render**. React will remember the function `setup` you passed, and call it later after performing the DOM updates.

 `useEffect` 是在渲染逻辑之后执行的, 是可以有副作用的. 可以看出, `useEffect` 天生就是为了解决这个问题. 

```jsx
useEffect(setup, dependencies?)
```

```jsx
function MyComponent() {
    const [count, setCount] = useState(0);

    console.log("1. Component function is running (render phase)");

    useEffect(() => {
        setTimeout(() => {
            console.log("3. useEffect is called (after DOM updates)");
        }, 2000);
    });

    return (
        <div>
            <p>You clicked {count} times</p>
            <button onClick={() => setCount(count + 1)}>
                Click me
            </button>
        </div>
    );
}
```

When you reload the page, you will see the following in the console (Don't use `StrictMode`):

```bash
1. Component function is running (render phase)
2. useEffect is called (after DOM updates) # 2 seconds later will print
```

When you click the button, you will see the following in the console:

```bash
1. Component function is running (render phase)
You clicked 1 times
3. useEffect is called (after DOM updates) # 2 seconds later will print
```

Here's a simplified sequence of what happens:

1. Component Function Executes: The function component runs. During this execution, it can render JSX and call hooks like useState. (Reload page, in example above)

2. Render to DOM: React updates the DOM and the screen based on the returned JSX from the function. ('You click x times', in example above)

3. After Render: Once the rendering is complete and the DOM has been updated, useEffect is called. This is done **asynchronously**; it doesn't block the browser from updating the screen. (2 seconds later, in example above)


## 3. 副作用操作实例 fetch data

```jsx
import { useState, useEffect } from 'react';
import { fetchBio } from './api.js';

export default function Page() {
  const [person, setPerson] = useState('Alice');
  const [bio, setBio] = useState(null);
  useEffect(() => {
    fetchBio(person).then(result => {
        setBio(result);
    });
  }, [person]);

  return (
    <>
      <select value={person} onChange={e => {
        setPerson(e.target.value);
      }}>
        <option value="Alice">Alice</option>
        <option value="Bob">Bob</option>
        <option value="Taylor">Taylor</option>
      </select>
      <hr />
      <p><i>{bio ?? 'Loading...'}</i></p>
    </>
  );
}
```

There is a trick, `<p><i>{bio ?? 'Loading...'}</i></p>`, 'Loading...' will be used if `bio` is null or undefined. We write it in this way because useEffect is called after the initial rendering, so `bio` will be null or undefined at the first render.

## 4. Race conditions in useEffect

> You would typically notice a race condition (in React) when two slightly different requests for data have been made, and the application displays a different result **depending on which request completes first.** 

With `cleanup` function, we can "cancel" the previous request (because `active` is false, `setData(newData);` in the previous  `useEffect` won't be called), and only use the result of the latest request. 

```js
useEffect(() => {
  let active = true;

  const fetchData = async () => {
    setTimeout(async () => {
      const response = await fetch(`https://swapi.dev/api/people/${props.id}/`);
      const newData = await response.json();
      if (active) {
        setFetchedId(props.id);
        setData(newData);
      }
    }, Math.round(Math.random() * 12000));
  };

  fetchData();
  return () => {
    active = false;
  };
}, [props.id]);
```

1. Your `setup` code runs when your component is added to the page (mounts), this is useEffect gets called after the render phase. 
2. After every re-render of your component where the dependencies have changed:
   - First, your `cleanup` code runs with the old props and state.
   - Then, your `setup` code runs with the new props and state.
3. Your `cleanup` code runs one final time after your component is removed from the page (unmounts).

So, in the above example, the `cleanup` function of the previous `useEffect` call is called before the `setup` function of the current `useEffect` is called.

Learn more: [Race Condition useEffect](https://maxrozen.com/race-conditions-fetching-data-react-with-useeffect)
