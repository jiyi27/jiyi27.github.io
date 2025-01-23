---
title: HTML Elements
date: 2024-05-05 17:20:20
categories:
 - front-end
 - html
---

CSS 内容, 并列的element放一块, 而不是分类放, 这样修改比较容易找位置看对比, 比如下面的内容, 最好是把 `course-details` 和 `course-title-description` 的 css 放一块, 这样我们想修改二者的css做对比的时候才比较好找他们对应的css, 而不是每次都得往下翻很久...

```html
<article className="course-card">
  <div className="course-title-description">
    ...
  </div>
  <div className="course-details">
    <div className="course-meta">
      ...
    </div>
    <div className="course-stats">
      ...
    </div>
  </div>
</article>
```

----------

```css
html {
    font-size: 10px;    /* 将根元素字体大小设为 10px */
}

.example2 {
    font-size: 1.6rem;  /* 现在等于 16px */
    margin: 2rem;       /* 现在等于 20px */
}
```

> rem 是 "root em" 的缩写, 基于根元素的字体大小来计算, em 是相对于父元素的字体大小计算的

--------

 `vw/vh` 是相对于视口（viewport）的单位, `%` 是相对于父元素的单位, 

`dvh` 会随着浏览器界面的变化动态调整, 当用户滚动页面时, 如果地址栏收起或展开(Safari经常这样), 使用 dvh 的元素高度会相应变化, 这可能会导致：导航栏高度不稳定, 页面内容跳动, 用户体验不连贯

`svh` 使用视口的最小可能高度，也就是当移动浏览器的工具栏/地址栏完全展开时的高度, 使用 `svh` 的优势在于, 导航栏高度始终基于最小视口高度计算, 即使地址栏收起，导航栏的高度也不会改变

`lvh` 使用视口的最大可能高度, 即当浏览器的工具栏/地址栏完全隐藏时的高度, 全屏背景图片或视频, 沉浸式体验的页面可以尝试, 

> 过度使用 vw/vh 可能导致频繁的重排, 影响性能

------------
