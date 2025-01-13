---
title: Hooks React - Next.js
date: 2024-12-11 20:50:01
tags:
 - front-end
---

> Always keep in mind: By default, React rerenders a component and all its children whenever the parent component rerenders - even if the props haven't changed.

文章推荐:

- [React Hooks 如何工作的](https://eliav2.github.io/how-react-hooks-work/)

## useCallback & useMemo

当一个组件被渲染, 它的所有子组件都会被重新渲染, 即使子组件没有任何变化, 若渲染子组件的代价很大, 父组件的频繁渲染则会导致效率问题, 我们可以 React.memo() 用来缓存整个组件, 让组件只有在其 props 改变的时候才会被重新渲染, 

当 props 为变量的时候还好, React.memo 会比较 props 的值, 看有没有变化, 进而判断子组件是不是应该被重新渲染, 我们知道函数或变量都可以当作 props 传递给子组件, 若父组件重新渲染, 那么函数也是重新定义的, 也就是说函数也就变了(函数是对象, 对象被重新创建, 地址会变), 这会导致子组件被重新渲染 , 即使我们使用了 React.memo(). 

这时候就需要 useCallback 和 useMemo 上场了, 我们可以使用 useCallback 或 useMemo 包装一下作为 props 传递给子组件的函数或变量, 这样即使父组件重新渲染, 他们也不会被重新创建, 进而子组件也不会因为 props 的 “改变”, 而重新渲染, 因为他们的值被缓存了, 也就是说我们拿空间 内存 和额外的比较逻辑 (判断 props 是否改变 ) 来减少子组件重新渲染的次数, 因此, 若子组件逻辑很简单, 不要使用这种优化, 因为可能会适得其反, 

```ts
function useCallback<T extends (...args: any[]) => any>(
  callback: T,
  dependencies: DependencyList
): T
function useMemo<T>(
  factory: () => T,
  dependencies: DependencyList
): T
```

useMemo, useCallback 都是使参数（函数）不会因为其他不相关的参数变化而重新渲染, 主要区别是 React.useMemo 将调用 fn 函数并返回其结果, 而 React.useCallback 只是返回 fn 函数而不调用它

- `useCallback` 接收一个函数并返回这个函数的缓存版本

- `useMemo` 接收一个工厂函数（factory function）并返回这个函数运行的结果

> useCallback 和 useMemo 不能滥用, 否则只会消耗性能, 利用闭包缓存上次结果, 成本为额外的缓存, 与比较逻辑, 不是绝对的优化, 而是一种成本的交换，并非使用所有场景

## Custom hooks

> A custom Hook is a JavaScript function whose name starts with ”`use`” and that may call other Hooks. [React docs](https://legacy.reactjs.org/docs/hooks-custom.html)

所有 Hooks 必须以 use 开头, 这不是约定, 而是 React 规则要求, 自定义 hooks 和 普通函数的区别:

- 自定义 hooks 可以使用其他 hooks, 而普通函数不能
- 自定义 hooks 能保持状态 (可以使用 useState) , 普通函数每次调用都是独立的

可以参考 [stack overflow](https://stackoverflow.com/a/64904812/16317008) 的一个回答: 

> React Hooks are JS functions with the power of react, it means that you can add some logic that you could also add into a normal JS function, but also you will be able to use the native hooks like useState, useEffect, etc, to power up that logic, to add it state, or add it side effects, memoization or more. So I believe hooks are a really good thing to **manage the logic of the components in a isolated way**.

这里有个例子可以帮助理解上面这段话, 尤其是最后一句:

```jS
// 组件变得非常简洁
function UserList() {
  const { data, loading, error } = useFetch('/api/users')

  if (loading) return <div>Loading...</div>
  if (error) return <div>Error: {error.message}</div>
  return <div>{data.map(user => <div>{user.name}</div>)}</div>
}

// 自定义 Hook, 保存状态, 独立组建逻辑
function useFetch(url) {
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    fetch(url)
      .then(res => res.json())
      ...
  }, [url])

  return { data, loading, error }
}
```

