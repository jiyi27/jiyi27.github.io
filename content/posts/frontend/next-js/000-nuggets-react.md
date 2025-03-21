---
title: 零碎知识 - React(Typescript)
date: 2024-12-07 18:20:22
categories:
 - 前端开发
tags:
 - 前端开发
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



