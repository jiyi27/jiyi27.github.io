---
title: Pure Function & State & Event Loop - React
date: 2024-01-07 10:27:22
categories:
 - front-end
tags:
 - front-end
---

## State

When you call `useState`, you are telling React that you want this component to remember something:

```javascript
const [index, setIndex] = useState(0);
```

In this case, you want React to remember `index`.

> **State is tied to a position in the render tree**: When you give a component state, you might think the state “lives” inside the component. But the state is actually held inside React. React associates each piece of state it’s holding with the correct component by where that component sits in the render tree. [source](https://arc.net/l/quote/hwsdijzo)

Here’s how that happens in action:

```javascript
const [index, setIndex] = useState(0);
```

1. **Your component renders the first time.** Because you passed 0 to useState as the initial value for `index`, it will return [0, setIndex]. React remembers 0 is the latest state value.
2. **You update the state.** When a user clicks the button, it calls setIndex(index + 1). `index` is 0, so it’s setIndex(1). This tells React to remember index is 1 now and triggers another render.
3. **Your component’s second render.** React still sees useState(0), but because React remembers that you set `index` to 1, it returns [1, setIndex] instead.

> State is local to a **component instance** on the screen. In other words, if you render the same component twice, each copy will have completely isolated state! Changing one of them will not affect the other.

Learn more: 
- [State as a Snapshot – React](https://react.dev/learn/state-as-a-snapshot)
- [Queueing a Series of State Updates – React](https://react.dev/learn/queueing-a-series-of-state-updates)


## 什么是副作用

> Anything that results in changes that can be observed when the calculation is completed, beside the return value of the calculation itself, is a side effect. Calculation should return just result of the calculation. Anything else is side-effect. [source](https://www.reddit.com/r/reactjs/comments/8avfej/comment/dx218q1/?utm_source=share&utm_medium=web2x&context=3)

**Components should only return their JSX**, and not change any objects or variables that existed before rendering—that would make them impure! 

While functional programming relies heavily on purity, at some point, somewhere, something has to change. That’s kind of the point of programming! These **changes—updating the screen, starting an animation, changing the data (call setState)**—are called side effects. They’re things that happen “on the side”, not during rendering.

> 所以严格来说 console.log 也是副作用. 

In React, side effects usually belong inside event handlers. Event handlers are functions that React runs when you perform some action—for example, when you click a button. Even though event handlers are defined inside your component, they don’t run during rendering! So event handlers don’t need to be pure.

If you’ve exhausted all other options and can’t find the right event handler for your side effect, you can still attach it to your returned JSX with a useEffect call in your component. This tells React to execute it later, after rendering, when side effects are allowed. However, this approach should be your last resort.

> 修改或读取外部变量, 修改 props 是不被允许的, 在哪都不行, 你可以把 外部变量通过 props 传进来, 然后在组件内部读取. 

Learn more: [Keeping Components Pure – React](https://react.dev/learn/keeping-components-pure#side-effects-unintended-consequences)

## 函数组件无副作用

### Render logic must not

1. **Same inputs, same output**: 函数组件的输出（即渲染的UI）仅依赖于它的props和state。换句话说，给定相同的props和state，组件将始终渲染相同的输出。

2. **不改变外部状态**: 在理想情况下，函数组件不应该改变外部状态，不应该直接修改传入的props或外部的全局变量。
   - 注意 props, 和 外部的变量 就是不允许被修改的, 即使在 [event handler](https://react.dev/learn/responding-to-events) 中, 也不能修改, 这是 React 的设计哲学
   - state 是可以被修改的, 但是只能通过 `setState` 在 event handler 或一些 hooks中修改, 不能在渲染逻辑中修改, 否则会导致死循环.
   - 官方文档有例子, 在文章最后: https://react.dev/learn/keeping-components-pure

> The React philosophy is that props should be immutable and top-down. This means that a parent can send whatever prop values it likes to a child, but the child cannot modify its own props. What you do is react to the incoming props and then, if you want to, modify your child's state based on incoming props. [source](https://stackoverflow.com/a/26089687/16317008)

3. **无副作用操作**: 函数组件在其主体内(渲染逻辑中)不应该执行有副作用的操作，比如直接进行网络请求、订阅事件、直接操作DOM等。这些操作应该放在 [event handlers](https://react.dev/learn/responding-to-events) 或钩子（如`useEffect`）中。

> **Can event handlers have side effects?** Absolutely! Event handlers are the best place for side effects. Unlike rendering functions, event handlers don’t need to be pure, so it’s a great place to change something—for example, change an input’s value in response to typing, or change a list in response to a button press. However, in order to change some information, you first need some way to store it. In React, this is done by using state, a component’s memory. You will learn all about it on the next page. [source](https://arc.net/l/quote/pioepdhv)

### Render logic may

- Mutate objects that were newly created while rendering

```javascript
const MyComponent = () => {
  const user = { name: 'Alice' };
  user.name = 'Bob'; // Mutating a local object is fine
  return <div>{user.name}</div>;
};
```
- Throw errors

```javascript
const MyComponent = ({ id }) => {
  if (!id) {
    throw new Error('ID is required');
  }
  return <div>ID: {id}</div>;
};
```

> Strive to express your component’s logic in the JSX you return. When you need to “change things”, you’ll usually want to do it in an **[event handler](https://react.dev/learn/responding-to-events)**. **As a last resort, you can useEffect.** [source](hhttps://react.dev/learn/keeping-components-pure)

> It is useful to remember which operations on arrays mutate them, and which don’t. For example, push, pop, reverse, and sort will mutate the original array, but slice, filter, and map will create a new one. [source](https://react.dev/learn/keeping-components-pure)

