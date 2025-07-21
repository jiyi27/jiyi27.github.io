---
title: Godot Scenes vs Nodes
date: 2025-07-21 22:02:10
categories:
 - 游戏开发
tags:
 - 游戏开发
 - godot
---

创建整个游戏场景: 点击编辑器上面的 + 号 (Add a new scene), 点击左侧栏 2D Scene 命名为 Game 作为一个 Scene 的根节点

创建一个角色: 点击编辑器上面的 + 号 (Add a new scene), 点击左侧栏 Other Node 选择 CharacterBody2D 作为该 Scene 的根节点

其实从工具栏也可以看出, 2D Scene 和 CharacterBody2D 一样都是一个节点, 只不过性质属性用途不一样而已

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2025/07/339b052d57bb006408fb6934d4f291db.png)

> game 和 player 都是一个 scene, 每个 scene 都是一个文件 `xxx.tscn`
>
> 只不过他们的根节点不同, 一个是 2D Scene 一个是 CharacterBody2D
>
> 所以从上面的截图中也可以看出 他们的图标是不一样的

