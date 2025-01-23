---
title: Pushed a Wrong File to Github - Solved
date: 2023-08-20 07:40:57
categories:
  - git
  - practice
tags:
  - git
---

## 问题描述

写完博客把内容 push 到了 GitHub, 发现有个文件 `a.txt`  不应该被追踪, `a.txt` 已经被追踪了, 

## 原因分析

首先你可能会想到 直接在本地删除  `a.txt`  commit, 然后 push 就行了, 可是即使这样 GitHub依然会有  `a.txt`  , 况且  `a.txt`  不能删除, 就是留在本地有用但是因为隐私不想放到GitHub, 而且这么做岂不是太粗鲁了, 

## 解决办法

解决方法不唯一, 这里介绍两个, 

其中一个可行的是在 GitHub 手动删除 `a.txt`  , 然后在本地进行 fetch, 再merge, ummm, 貌似比前面还粗鲁, 

比较优雅的做法是在本地仓库使用 ` git rm --cached <filename>` 让 `a.txt` 从 tracked -> untracked, 

然后把 `a.txt` 加入到 `.gitignore`, 再进行 commit 和 push, 此时 github 上的 `a.txt` 会消失
