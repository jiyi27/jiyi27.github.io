---
title: Render Phases - React.js
date: 2024-12-16 23:38:39
tags:
 - front-end
---

[一篇文章](https://eliav2.github.io/how-react-hooks-work/)总结的比较好, 渲染的两个阶段: Render, Commit:

**Render**

- construction of sub React-tree by recursively calling the React component function body (or the render method on class components)- in this article we call this **update phase**.
- passing this React-tree to the renderer that will figure out what’s sections of the DOM needs to be updated.

**Commit**

- the renderer updates the DOM using [React’s “diffing” algorithm](https://reactjs.org/docs/reconciliation.html#the-diffing-algorithm).
- now the browser DOM is fully updated in memory but the browser has not painted it to the UI(the event loop has not yet ended). means that any access to the DOM here will get the updated DOM properties(such location and dimensions), but changes has not flushed to the UI just yet.
- *useLayoutEffect cleanup from previous render* 
- **[useLayoutEffect](https://reactjs.org/docs/hooks-reference.html#uselayouteffect)** is now called.
- javascript event loop has ended, and the browser paints the updated DOM (the UI is fully updated).
- *useEffect cleanup from previous render*
- **[useEffect](https://reactjs.org/docs/hooks-reference.html#useeffect)** is now called (asynchronously).

注意这里的 `useEffect cleanup from previous render`, 清理实际上指的是 执行 useEffect 返回的函数,  即 useEffect 函数体会在 commit 阶段执行然后返回一个清理函数(可选), 在下次 commit 阶段时, React 会先调用上次 useEffect 返回的清理函数, 然后再执行 useEffect, 

返回清理函数可以防止内存泄漏, 不要忘了, useEffect 是用来执行副作用的地方, 比如我们可能在 useEffect 中建立了 TCP 连接, 组件多次渲染, 我们建立多个TCP连接, 可是同时只保存一个连接才是合理的, 这时候清理之前的, 就显得很必要:

```js
// 1. 数据获取 - 最常见的用例
const UserProfile = () => {
  ...
  useEffect(() => {
    // 定义异步函数来获取用户数据
    const fetchUser = async () => {
      const response = await fetch('https://api.example.com/user');
      ...
    };

    fetchUser();
    
    // 清理函数 - 组件卸载时取消请求
    return () => {
      // 如果使用 axios，可以用 cancelToken
      // 如果使用 AbortController，可以在这里 abort
    };
  }, []); // 空依赖数组意味着只在组件挂载时执行一次

  return loading ? <div>Loading...</div> : <div>{user?.name}</div>;
};
```

又或者是定时器, 有可能发生的是, 上次渲染因调用 useEffect 启动的定时器还没结束, 又发生了一次新的渲染, 此时在调用 useEffect 之前, 清理掉之前的的定时器:

```js
// 2. 监听状态变化 - 响应特定状态的变化
const SearchComponent = () => {
  const [searchTerm, setSearchTerm] = useState('');
  const [results, setResults] = useState([]);

  useEffect(() => {
    // 防抖处理，避免频繁请求
    const debounceTimeout = setTimeout(async () => {
      if (searchTerm.length >= 2) {
        const response = await fetch(`/api/search?q=${searchTerm}`);
        ...
      }
    }, 500);

    // 清理函数 - 取消之前的延时操作
    return () => clearTimeout(debounceTimeout);
  }, [searchTerm]); // 依赖于 searchTerm，每次搜索词变化都会触发

  return (
    <input
      value={searchTerm}
      onChange={(e) => setSearchTerm(e.target.value)}
    />
  );
};
```

1. 用户快速输入 abc
2. SearchComponent 被渲染三次, 因为 searchTerm 改变了三次, a -> ab -> abc
3. 输入b的时候, 组件被重新渲染( render 阶段), React 执行上次 useEffect 返回的清理函数(commit 阶段), 即 定时器被清理, 请求也不会发出
4. 输出 c, 此时组件重新被渲染, 同理, 执行清理函数, 再次调用 useEffect, 即只会执行一次请求

-----

都知道, 在 Render Phase 已经完成了所有数据的计算和完整的 Virtual DOM 的生成, Commit Phase 则负责把这些变更实际应用到浏览器的 DOM 中, 并处理副作用 useEffect, 

可是有个问题, 组件已经渲染完了, 再执行 useEffect 还有什么意义呢, useEffect 不就是为了拉取数据 然后插入到组件吗? 看例子:

```ts
function UserProfile() {
  const [user, setUser] = useState(null);

  // 第一次渲染
  console.log("1. Render Phase 执行");
  const content = user 
    ? <h1>Welcome, {user.name}</h1> 
    : <h1>Loading...</h1>;

  useEffect(() => {
    console.log("3. Commit Phase 之后执行 Effect");
    // 获取数据
    fetch('/api/user')
      .then(r => r.json())
      .then(userData => {
        console.log("4. 数据到达，调用 setUser");
        setUser(userData);
      });
  }, []);

  console.log("2. 返回 JSX");
  return content;
}
```

执行的逻辑是

1. 组件首次渲染，显示 "Loading..."
2. DOM 更新完成
3. useEffect 执行，发起 API 请求
4. 数据返回后，setUser 触发新的渲染
5. 组件重新渲染，这次显示 "Welcome, [name]"

所以 useEffect 不是为了"把数据插入已渲染的视图"，而是：

1. 触发一个新的数据获取流程
2. 通过 setState 引发新的**渲染周期**

```ts
// 🚫 错误理解：视图是个框架，等着数据填充
<div id="user">{等待 useEffect 填充数据}</div>

// ✅ 正确理解：每次都是完整的渲染
// 第一次渲染
<div id="user">Loading...</div>

// 数据到达后的第二次渲染
<div id="user">Welcome, Alice</div>
```

useEffect 的依赖是空数组, 表示只在组件首次渲染后执行一次, 之后不会再执行, 

