---
title: Rendering - React
date: 2024-01-07 19:27:22
categories:
 - front-end
tags:
 - front-end
---

## setState 同步 OR 异步

我们首先需要明确, 从 API 层面上说, 它就是普通的调用执行的函数, 自然是同步的. 这里所说的同步和异步指的是 API 调用后更新 DOM 是同步还是异步的. 

- 如果 setState 在 React 能够控制的范围被调用，它就是异步的。
  - 例如：合成事件处理函数, 生命周期函数, 此时会进行批量更新, 也就是将状态合并后再进行 DOM 更新。
- 如果 setState 在原生 JavaScript 控制的范围被调用，它就是同步的。
  - 例如：原生事件处理函数中, 定时器回调函数中, Ajax 回调函数中, 此时 setState 被调用后会立即更新 DOM 。

[一文彻底搞懂React的setState是同步还是异步 - 掘金](https://juejin.cn/post/7085897363314704414)

> React 通过异步更新状态，可以批量处理多个状态更新，而不是对每个状态更新都重新渲染组件。这种批处理方式减少了不必要的渲染次数，提高了应用的性能。(**batch multiple state updates together**, instead of re-rendering components for each individual state update.)

## setState 的坑

刚开始很容易写出以下错误代码:

```javascript
const [age, setAge] = useState(0);

function handleClick() {
  setAge(() => age + 1);
  // ...
```

这样访问准确来说并不是**上一次**的state, 而是组件在它**当时**状态值, 因为有可能发生多次连续的状态更新, 比如其它 event handler 也调用了 setAge 函数, 不要忘了这些 setXXX() 是异步的, 会被React集中到一起执行, 所以要确保 setAge() 更新的是上一次的值, 要使用（即 setXXX(previousState => newState)），这样可以确保你的更新基于最新的状态值。

正确方式如下:

```javascript
const [age, setAge] = useState(0);

function handleClick() {
  setAge(age => age + 1);
  // ...
```

注意第二个 setXXX() 的参数是一个匿名函数, 这个**匿名函数的参数**是上一次的 state, 由 React 负责传入, 返回值更新后的 state, 

## 组件渲染过程

This process of requesting and serving UI has three steps:

- **Triggering** a render
  - A render is triggered when a component’s `props` or `state` changes. 
  - A render can also be triggered by its parent component re-rendering.

> 这里注意, 使用自定义 hook 时, 其返回的 state 变化时, 也会触发组件的重新渲染. 并不是自定义 hook 的状态改变而导致的重新渲染, 而是自定义 hook 返回的 state 改变而导致的重新渲染. 自定义 Hooks 的主要优势在于它们允许你重用状态逻辑，而不是创建全新的状态机制。每次在组件中使用自定义 Hook 时 (若该 hook 中定义了 state `const [xxx, setXXX] = useState(xx)`) ，都相当于在该组件内部创建了一个新的独立状态 xxx, 因此当 hook 中调用 setXXX 时, 会触发该组件的重新渲染. 
  
- **Rendering** the component
  - The process of rendering is recursive. 
  
- React **commits** changes to the DOM
  - React will apply the minimal necessary operations (calculated while rendering!) to make the DOM match the latest rendering output. 
  - Think the [clock and input](https://react.dev/learn/render-and-commit) example. 

> The default behavior of rendering all components nested within the updated component is not optimal for performance if the updated component is very high in the tree. If you run into a performance issue, there are several opt-in ways to solve it described in the [Performance](https://reactjs.org/docs/optimizing-performance.html) section. **Don’t optimize prematurely!**

> When developing in “Strict Mode”, React calls each component’s function twice, which can help surface mistakes caused by impure functions. [Source](https://react.dev/learn/render-and-commit)

Learn more: [Render and Commit – React](https://react.dev/learn/render-and-commit)

## 组件渲染会导致异步函数暂停吗

React组件的重新渲染不会导致其中正在执行的异步函数暂停或中断, 

```javascript
function MyComponent() {
    console.log('组件开始渲染');

    // 异步函数
    setTimeout(() => {
        console.log('异步函数执行');
    }, 0);

    console.log('组件渲染中');

    // 组件渲染的返回
    return <div>Hello World</div>;
}

// 当MyComponent被渲染时
ReactDOM.render(<MyComponent />, document.getElementById('root'));
```

在这个例子中，当`MyComponent`组件开始渲染时，它首先打印`"组件开始渲染"`。接下来，尽管有一个`setTimeout`异步函数，它不会立即执行。相反，组件会继续执行下一行同步代码，打印`"组件渲染中"`。只有在所有同步代码执行完毕后，即组件渲染完成后，事件循环才会处理`setTimeout`中的异步回调，打印`"异步函数执行"`。

因此，在React中，组件的渲染过程是不会被其中的异步函数所打断的。同步代码总是在异步代码之前执行完毕。这保证了组件的渲染逻辑的一致性和可预测性。