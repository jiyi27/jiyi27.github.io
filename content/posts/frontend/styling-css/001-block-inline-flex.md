---
title: Block vs Inline vs Flex
date: 2024-01-06 20:46:20
categories:
 - front-end
tags:
 - front-end
---

## 1. Block vs Inline vs Flex Elements

- block 元素独占一行, 宽度默认是父元素的 100%, 高度由内容决定
  - 特殊情况: button 默认是 inline-block, 支持设置宽高, **即使把 button 的 display 设置为 block, 其宽度依然不会是父元素的 100%, 而是由内容决定的.** 
  - 其他的 inline 元素, 如 `<span>`, `<a>`, `<strong>`, 如果设置为 block, 则其宽度会自动变为父元素的 100%. 

- inline 元素不会独占一行, 宽高度由内容决定
  - 不能设置宽高, 若要设置宽和高, 需要将其转换为块级元素. 如 `display: block` 或 `display: inline-block`. 
  - 不可以设置上下 padding 和 margin, 可以设置左右 padding 和 margin.
  - 特殊情况: `margin-left: auto`, `margin-right: auto` 无法适用 inline 元素. 这也是为什么 tailwind css 中 `mx-auto` 无法使 inline 元素水平居中的原因.

- inline-block, 既可以设置宽高, 也可以设置所有 padding 和 margin, 其他与 inline 元素一样.

- Flex 会让其内的元素会失去块级或内联特性, 即flex 子元素既不是块级元素, 也不是内联元素, 而是 flex 元素, 它们有自己的特性. 若同在 flex box内, 则 `<a>` 与 `<div>` 在显示上是完全一样的, 因为他们都是 flex items. 他们的显示方式取决于 fex-column 还是 flex-row

> flexbox 和 block container 是不同的概念, 即块级元素和inline元素重在强调 他们会占多大空间, 如何占 (一行还是可以并列) 而felx box在于强调它里面的元素是怎么安排的. (Flexbox and block containers are different concepts. Block and inline elements mainly **emphasize** the space they occupy and how they occupy it (whether they take up a full line or can be inline). Flexbox, on the other hand, focuses on how the elements inside are arranged.)

## 2. Flex 默认值 踩坑 重要‼️

由于 flex items 三属性 `flex-grow`, `flex-shrink`, `flex-basis` 的默认值分别是 0, 1, auto, 即 flex items 默认允许在必要情况下缩小, 比如有左右两个 flex items, 当左边的 flex items 的内容很多, 而右边的 flex items 的内容很少, 此时右边的 flex items 会被压缩, 以适应 flex container 的宽度, **即使右边的 flex items 设置了宽度, 也会被压缩.**

这就导致有时候会遇到明明设置了宽度, 却“不起作用”的情况, 其实就是被压缩了, 这时候就需要使用 `flex-none` (`0 0 auto`) 来禁止 flex items 在必要情况下缩小, 从而保证 flex items 的宽度不会被压缩.

如下, 若没有 `flex-none`, 因为段落内容较多, 会导致image被压缩, 即使设置了宽度, 
```jsx
<div className={'flex items-start p-3 max-h-80 border-b-2'}>
    <a href={`#`} className="flex-none">
        <img src={'#'} alt="User avatar" className="rounded-full h-11 w-11"/>
    </a>
    <p className={'mt-2'}>
        Compound indexes collect and sort data from two or more fields in each document in a collection. Data is grouped by the first field in the index and then by each subsequent field.
    </p>
</div>
```

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2024/08/289cb461d529a333865315227f29006a.png)

## 3. Flex: Main Axis vs Cross Axis

```jsx
<div className="flex flex-col">
    ...
</div>

<div className="flex flex-row">
    ...
</div>
```

> 为什么使用 class="flex flex-row" 只是用 class="flex-row" 不行吗?
> `flex` 确保元素变成一个 Flex 容器。`flex-row` 确保该容器内的项目沿着水平轴排列。

另外注意, **flex items 会自动填充满其 flex container 的沿着交叉轴方向的空间**, 也就是说, flex items 的宽度或高度会等于交叉轴的长度, 具体是高度还是宽度, 取决于主轴方向, **交叉轴方向就是主轴方向的垂直方向**. 

根据下面这个例子, 因为主轴方向是水平, 因此 flex items 的高度会等于 flex container 的高度, 至于宽度, 则是由其内容决定的 (flex-grow 默认值为 0).  

```jsx
<div className="flex flex-row h-64 border-2">
    <button className={'border-2'}>hello</button>
    <button className={'border-2'}>hello</button>
</div>
```

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2024/08/be19d5bccdb9e13c9239fc123b59393a.png)

> flex items 的三个属性 `flex-grow`, `flex-shrink`, `flex-basis` 的默认值是 flex-grow: 0, flex-shrink: 1, flex-basis: auto. 
> 注意这是 flex items 的属性, 不是 flex container 的属性. 
