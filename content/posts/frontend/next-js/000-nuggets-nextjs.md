---
title: 前端开发零碎知识点
date: 2024-12-07 18:20:22
categories:
 - 前端开发
tags:
 - 前端开发
 - next.js
 - 零碎知识
---

```ts
type SortOption = 'latest' | 'hot' | 'mostLiked';

// 不推荐, 若代码没有使用所有选项, 编译器会警告未使用变量, 其实是使用了, 只不过在运行时才能确定, 但编译器不知道, 不利于多人维护, 比如人家看没有使用的变量, 直接就删除了, 但用户通过点击选项来选择排序, 这是运行时才能确定的
const sortFunctions = React.useMemo(() => ({
    latest: (a: Post, b: Post) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
    hot: (a: Post, b: Post) => (b.likesCount * 2 + b.commentsCount) - (a.likesCount * 2 + a.commentsCount),
    mostLiked: (a: Post, b: Post) => b.likesCount - a.likesCount
}), []);

// 解决办法, 指定 key 的类型
const sortFunctions: Record<SortOption, (a: Post, b: Post) => number> = React.useMemo(() => ({
    latest: (a: Post, b: Post) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
    hot: (a: Post, b: Post) => (b.likesCount * 2 + b.commentsCount) - (a.likesCount * 2 + a.commentsCount),
    mostLiked: (a: Post, b: Post) => b.likesCount - a.likesCount
}), []);
```

> `Record<K, V>` 是 TypeScript 的一个工具类型, K 是键的类型, V 是值的类型
>
> 类似 map, 但这里更适合用 Record, 因为 key 类型固定, 不需要动态增删排序... 而且, 访问方式也不一样, Record 更直观:
>
> `const sortFn = sortFunctions.latest` / `const sortFn = sortFunctionsMap.get('latest')`

----

```ts
const wrapperRef = useRef<HTMLDivElement>(null);
```

`useRef<HTMLDivElement>(null)` 返回的类型是: `RefObject<HTMLElement | null>` 说明 `wrapperRef` 的类型是 `RefObject`, 注意 `HTMLElement | null` 不是指 `wrapperRef` 可能是 HTMLElement 或 null, 它们的类型没有半毛钱关系, 可以看一下  `RefObject` 的定义:

```ts
interface RefObject<T> {
    /**
     * The current value of the ref.
     */
    current: T;
}
```

看到了吧, `<HTMLElement | null>` 指的是 其属性 `current` 的类型, 

----

用户余额是个比较常访问的信息, 我们把它放到 session 中, 因为频繁从数据库查询数据会浪费时间, 可是每次我们修改内存中的 session, 就会造成与数据库数据不一致, 所以我想的是每次 session 过期, 通过 channel 传给用户, 以便 session 数据可以在被删除前写入数据库信息, 可是为这种情况写个 单独 gc 合适并不合适, 

```go
// 更好的方法, 写时同步更新
type Session struct {
    values map[string]interface{}
    onUpdate func(key string, value interface{})
}

func (s *Session) Set(key string, value interface{}) {
    s.values[key] = value
    if s.onUpdate != nil {
        // 异步更新数据库
        go s.onUpdate(key, value)
    }
}
```

----

> A `fetch()` promise **only rejects** when the request fails, for example, because of a badly-formed request URL or a network error. A `fetch()` promise *does not* reject if the server responds with HTTP status codes that indicate errors (`404`, `504`, etc.). https://developer.mozilla.org/en-US/docs/Web/API/Window/fetch

在 JavaScript 中，Promise（承诺）有三种状态：

1. pending（等待中）- 初始状态
2. fulfilled（已完成）- 操作成功完成
3. rejected（已拒绝）- 操作失败

`fetch()` 返回的 Promise 只会在以下情况下变成 rejected（拒绝）状态：

- 网络错误, 比如无法连接服务器
- URL 格式错误, 比如 URL 语法不正确

HTTP 错误状态（比如 404 或 500）不会导致 fetch reject, 服务器返回错误响应也不会导致 fetch reject

```js
// 这个请求会 reject，因为 URL 格式错误
fetch('not-a-valid-url')
  .then(response => console.log('这里不会执行'))
  .catch(error => console.log('会执行这里，因为 URL 无效'));

// 这个请求不会 reject，即使返回 404
fetch('https://api.example.com/not-exist')
  .then(response => {
    // 这里会执行！即使是 404 错误
    // 需要手动检查 response.ok 或 response.status
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    return response.json();
  })
	.catch(error => console.log('会捕获：网络错误、HTTP 错误状态、JSON 解析错误等'));
```

> Fetch API: how to determine if an error is a network error
>
> When using `fetch`, you can't differentiate network errors from other errors caused by building an incorrect request, as both are thrown as `TypeError`. (See https://developer.mozilla.org/en-US/docs/Web/API/fetch#exceptions). (即不止网络错误为 TypeError, 还有其他错误都会出发 TypeError, 所以不能仅凭 TypeError 判断是否为网络错误.) 
>
> This is quite a flaw, as application defects that cause an incorrectly built request may go unnoticed, masked as if they were circumstantial network errors.
>
> https://stackoverflow.com/a/70103102/16317008

------

可选定义真的是搞的头大, 我们来看一下:

```ts
interface User {
    name?: string;   // name 是可选的
    age: number;     // age 是必需的
}

// 1. 创建对象 - 正确的方式
const user1: User = {
    age: 25          // ✅ 正确，name 是可选的可以不传
};

const user2: User = {
    name: 'Tom',     // ✅ 正确，提供了可选的 name
    age: 25
};

const user3: User = {
    name: undefined, // ✅ 正确，显式设置为 undefined
    age: 25
};

// 2. 访问字段
function processUser(user: User) {
    // 访问必需字段 age - 直接访问
    console.log(user.age);  // ✅ 安全，因为 age 一定存在

    // 访问可选字段 name - 需要安全访问
    console.log(user.name?.toUpperCase());  // ✅ 安全，如果 name 不存在返回 undefined
    
    // 使用默认值
    const displayName = user.name ?? '匿名用户';
    
    // if 判断
    if (user.name) {
        console.log(user.name.toUpperCase());  // 在这个块中 name 一定存在
    }
}

// 3. 解构赋值
function printUser(user: User) {
    const { name, age } = user;
    console.log(name ?? '匿名', age);  // age 直接使用，name 需要考虑默认值
}
```

-----



