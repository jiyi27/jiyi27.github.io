---
title: Vue 基础概念
date: 2025-04-17 20:42:20
categories:
 - 前端开发
tags:
 - 前端开发
 - vue
---

## 1. Single File Component

在 Vue.js 中, Single File Component 通常以 `.vue` 为后缀, 用于将一个组件的模板（HTML）、逻辑（JavaScript）和样式（CSS）封装在同一个文件中, 是 Vue 开发中非常核心的概念之一

```vue
<template>
  ...
</template>

<script>
  ...
</script>

<style scoped>
...
</style>
```

> `scoped` 的作用是将样式限制在当前组件的作用域内

## 2. API Styles

Options API 和 Composition API 都是 Vue 提供给开发者用来定义组件数据和逻辑的方式, 并且它们的主要目的之一是为 `<template>` 提供数据, 让模板可以通过数据绑定直接使用这些数据, 它们是Vue实现数据绑定的两种主要方式, 但它们的设计理念、使用场景和灵活性有所不同

### 2.1. Options API `data()`

**结构化选项**：通过固定的选项（如 data、methods、computed、watch 等）组织代码

**传统方式**：Vue 1.x 和 Vue 2.x的主流方式, Vue 3仍然支持

**数据定义**：通过 `data()` 返回一个对象，里面的属性是响应式的

```vue
<template>
  <p>{{ message }}</p>
  <button @click="updateMessage">更新</button>
</template>

<script>
export default {
  data() {
    return {
      message: "Hello from Options API"
    };
  },
  methods: {
    updateMessage() {
      this.message = "Updated!";
    }
  }
};
</script>
```

- `data()` 返回的对象中的属性（如message）自动绑定到组件实例, `<template>` 可以直接访问
- 方法（如`updateMessage`）通过 `this` 操作数据, 触发响应式更新

### 2.2. Composition API `<script setup>`

**函数式组织**：通过 `setup()` 函数或 `<script setup>` 以更灵活的方式组织代码，不受固定选项的限制

**Vue 3 引入**：旨在解决 Options API 在大型项目中代码分散和复用性差的问题

```vue
<template>
  <p>{{ message }}</p>
  <button @click="updateMessage">更新</button>
</template>

<script setup>
import { ref } from "vue";

const message = ref("Hello from Composition API");
const updateMessage = () => {
  message.value = "Updated!";
};
</script>
```

- `ref` 或 `reactive` 定义的变量（如 `message` ）在 `<script setup>` 中是顶层变量, **直接暴露给模板**
- 方法（如 `updateMessage` ）通过操作 `ref.value` 或 `reactive` 对象的属性更新数据，触发响应式更新

> **响应式 API** 是一组特定的函数, 专门用于创建和管理响应式数据:  `⁠ref()`, `reactive()`, ⁠`computed()`, `watch()`, `⁠watchEffect()`, 这些函数的主要目的是让数据变得"响应式"——当数据变化时, 视图会自动更新, **Composition API** 是 Vue 3 中组织组件代码的整体方法论, 它包括: 
>
> - 所有响应式 API 函数（上面提到的那些）
> - 组件生命周期函数（⁠onMounted、⁠onUpdated等）
> - 依赖注入函数（⁠provide、⁠inject）
> - `setup` 函数或 `⁠<script setup>` 语法

## 3. `reactive()`

### 3.1. 本质

It is important to note that the returned value from `reactive()` is a [Proxy](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Proxy) of the original object, which is not equal to the original object:

```js
const raw = {}
const proxy = reactive(raw)

// proxy is NOT equal to the original.
console.log(proxy === raw) // false
```

**Only the proxy is reactive** - mutating the original object will not trigger updates. This rule applies to **nested objects** as well. Due to deep reactivity, nested objects inside a reactive object are also proxies:

```js
const proxy = reactive({})

const raw = {}
proxy.nested = raw

console.log(proxy.nested === raw) // false
```

> 理解本质对于后面为什么解构 reactive 对象失去响应式的理解至关重要

### 3.2. 有限的值类型支持

**Limited value types:** it only works for object types (objects, arrays, and [collection types](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects#keyed_collections) such as `Map` and `Set`). It cannot hold [primitive types](https://developer.mozilla.org/en-US/docs/Glossary/Primitive) such as `string`, `number` or `boolean`.

这个很好理解, 因为 `reactive()` is a [Proxy](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Proxy) of the original object, 所以 primitive 类型肯定不行啦, 

### 3.3. 对解构操作不友好

```js
const state = reactive({ count: 0 })
let { count } = state
count++
```

- reactive 创建的对象是一个 **Proxy**，它包装了整个对象，使得对象的属性访问和修改具有响应式效
- 当你解构 `state（let { count } = state）`，`count` 只是从 `state` 中获取了属性值（`state.count` 的值），而不是保留对 `state.count` 的响应式引用
- 在 JavaScript 中，解构普通对象时会直接复制属性的值（对于原始类型如数字、字符串是值复制）因此，`count` 是一个普通的 JavaScript 变量（数字类型），与 `state` 的响应式系统完全脱离

> 在 JavaScript 中，解构操作（例如 `const { prop } = obj`）本质上是从对象中提取属性值，并将其赋值给新的变量, 解构的结果取决于属性值的类型：
>
> **基本类型（如 Number、String）**：提取的是值的副本（值传递）
>
> **引用类型（如 Object、Array）**：提取的是引用的副本（仍然指向相同的内存地址）
>
> **解构得到的是基本类型的副本，与原对象完全脱离**, 而reactive 又是基于对象代理, 所以解构一个代理对象获得的字段肯定也失去响应式啦, 因为 Vue 通过对象代理拦截对象属性, 你直接解构提取对象属性成一个 primitive 类型, 都不是对象了, 所以肯定 Vue 也无法监控进行响应式了

## 4. `ref`

```js
const state = ref({ count: 0, name: 'Vue' })

console.log(state.value) // { count: 0, name: 'Vue' }

// 修改对象内部的属性
state.value.count++ // 响应式更新
state.value.name = 'React' // 响应式更新

// 替换整个对象
state.value = { count: 10, name: 'Angular' } // 响应式更新
```

- `state` 是一个 `ref` 对象，访问其内容需要通过 `state.value`
- `state.value` 是一个 **响应式对象**，对其属性的操作（如 `state.value.count++`）会触发响应式更新, **无需再次使用 .value**
- 替换整个 `state.value`（如 `state.value = { ... }`）也会触发响应式更新，因为 `ref` 会跟踪 `.value` 的变化

## 5. `reactive()` vs `ref`  

### 5.1. 解构操作

两者解构后都会丢失响应性

```js
const state = reactive({ count: 0, name: 'Vue' });
const { count, name } = state; // 解构后，count 和 name 失去响应性

// 这不会影响原来的响应式对象
count++;
console.log(state.count); // 仍然是 0
```

```js
const state = ref({ count: 0, name: 'Vue' });
const { count, name } = state.value; // 解构后，count 和 name 失去响应性

// 对于基本类型的 ref
const count = ref(0);
const name = ref('Vue');
const { value: countValue } = count; // 解构后，countValue 失去响应性
```

### 5.2. 函数返回值的行为

```js
function useReactiveState() {
  const state = reactive({ count: 0 });
  return state; // 返回完整的响应式对象，保持响应性
}

const state = useReactiveState();
state.count++; // 仍然具有响应性
```

```js
function useRefState() {
  const count = ref(0);
  return count; // 返回 ref 对象，保持响应性
}

const count = useRefState();
count.value++; // 仍然具有响应性
```

> 看到这可以注意到 `ref` 和 `reactive` 创建对象的行为的不同, 前者不能创建 primitive 类型, 若想创建, 只能通过 `{ count: 0 }` 这种包装一层对象的方式来创建, 而后者可以直接创建

### 5.3. 常见操作对比

```js
// 组合式函数
function useCounter() {
  const count = ref(0);
  
  function increment() {
    count.value++;
  }
  
  return {
    count,    // 返回 ref，保持响应性
    increment // 返回方法
  };
}

// 使用
const { count, increment } = useCounter();
```

可以看到 `ref` 的实现简单明了, 然后来看一下 `reactive` 的实现:

```js
// 组合式函数
function useCounter() {
  const state = reactive({ count: 0 })
  
  function increment() {
    // 直接访问属性，不需要 .value
    state.count++
  }
  
  return {
    // 解构直接返回 state 对象或其属性
    count: state.count,
    increment
  }
}
```

注意这样写会有一个问题：当 `setup()` 返回 `state.count` 时，会丢失响应性，因为它被解构了, 模板中的 `count` 不会更新, 解决办法是**直接返回整个 reactive 对象**

```js
function useCounter() {
  const state = reactive({ count: 0 })
  
  function increment() {
    // 直接访问属性，不需要 .value
    state.count++
  }
  
  return {
    // 返回响应式状态
    state,
    increment
  }
}
```

## 6. Declaring Reactive State

In Composition API, the **recommended** way to **declare reactive state** is using the [`ref()`](https://vuejs.org/api/reactivity-core.html#ref) function:

```js
import { ref } from 'vue'

const count = ref(0)
```

You can mutate a ref directly in event handlers:

```vue
<button @click="count++">
  {{ count }}
</button>
```

- We did **not** need to append `.value` when using the ref **in the template**. For convenience, refs are automatically unwrapped when used inside templates.

- `ref` 或 `reactive` 定义的变量（如 `message` ）在 `<script setup>` 中是顶层变量, **直接暴露给模板**

For more complex logic, we can declare functions that mutate refs in the same scope and expose them as methods alongside the state:

```js
import { ref } from 'vue'

export default {
  setup() {
    const count = ref(0)

    function increment() {
      // .value is needed in JavaScript
      count.value++
    }

    return {
      count,
      increment
    }
  }
}
```

Exposed methods can then be used as event handlers:

```vue
<button @click="increment">
  {{ count }}
</button>
```





