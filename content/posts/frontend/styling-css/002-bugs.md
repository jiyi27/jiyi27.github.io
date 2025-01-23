---
title: Tailwind CSS Commonly Used Class
date: 2024-01-06 12:46:22
categories:
 - front-end
tags:
 - front-end
typora-root-url: ../../../static
---

**调试 bug:** 加上样式后 刷新页面 样式不符合预期时 可以进入开发者模式 查看真正被应用的元素样式 因为可能是缓存问题

----

block 元素水平居中: `mx-auto`, 注意对 inline 无效, 原因: `margin-left: auto`, `margin-right: auto` 无法适用 inline 元素.

```
<nav className="fixed bottom-0 left-0 right-0 z-50 bg-white dark:bg-gray-900 border-t dark:border-gray-800 safe-area-pb">
            <div className="mx-auto px-4 max-w-lg">
                <div className="flex justify-around items-center h-16">
                	<Link>
                		...
                	</Link>
                	<Link>
                		...
                	</Link>
                	<Link>
                		...
                	</Link>
                	....
```

----

元素变形(变窄), 要想到元素是不是因为 flex 自动挤压导致, 加上 `shrink-0` 看看变化, 注意  `shrink-0` 就是 css 中的 `flex-shrink`

> flex items 三属性 `flex-grow`, `flex-shrink`, `flex-basis` 的默认值分别是 0, 1, auto, 即 flex items 默认允许在必要情况下缩小, 比如有左右两个 flex items, 当左边的 flex items 的内容很多, 而右边的 flex items 的内容很少, 此时右边的 flex items 会被压缩, 以适应 flex container 的宽度, **即使右边的 flex items 设置了宽度, 也会被压缩.**

-----------

写菜单栏的时候, 菜单栏展开后会将下面的内容挤下去, 像下面这样:

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2024/08/a199c94496cc4d1f2fbfdd7fd09478c4.jpg)

基本上菜单栏都很窄, 所以当菜单栏展开时, 我希望的是不影响下面的内容, 但是正常情况下两个元素要么是 inline 那种可以在同一行, 要么是 block 那种独占一行, 无法实现我想要的效果. 此时就可以使用 absolute 来实现, 如下:

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2024/08/997c2961834e857ceb3fbc392b90cb56.jpg)

此时也应该注意覆盖的问题, 若对话框宽度为 100vw, 可能会覆盖掉对话框, 因此要将 z-index 设置大一些. 

> Absolute positioned elements are removed from the normal flow, and **can overlap elements**.

-----
