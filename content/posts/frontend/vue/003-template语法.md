---
title: Vue Template 语法
date: 2025-04-19 22:20:18
categories:
 - 前端开发
tags:
 - 前端开发
 - vue
---

## 1. 数据绑定 `v-bind`

```vue
<el-progress
  type="dashboard"
  :percentage="materialsStats.OverdueRate"
  :color="overdueRateColor"
  :stroke-width="8"
>
```

在 Vue.js 中，`:color` 和 `:percentage` 这种动态属性绑定语法（即 `v-bind` 的缩写）是用来**代替静态属性赋值**的

### 1.1. 静态属性赋值

原本 HTML 是“静态”的:

```html
<img src="logo.png" width="100">
```

在传统的 JavaScript 或 jQuery 开发中, 如果需要动态改变元素的属性, 开发者需要手动操作 DOM, 例如:

```js
document.querySelector('img').src = dynamicImageUrl;
```

很麻烦，而且代码结构不好维护

### 1.2. Vue 的目标是让“HTML 和数据同步”

Vue 设计的目标是：**让 HTML 结构能“响应式”地绑定数据**, 也就是数据变了, DOM 自动更新, 不用你手动操作 DOM, 所以 Vue 就引入了`v-bind` 指令：

```vue
<img v-bind:src="logoUrl">
```

意思是：把 `logoUrl` 这个变量的值绑定到 `img` 的 `src` 属性上, 因为 `v-bind:xxx="..."` 太常用了, Vue 就提供了简写:

```vue
<img :src="logoUrl">
```