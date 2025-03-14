---
title: git branch git stash git add (stage)
date: 2023-04-22 00:47:50
categories:
  - git
tags:
  - git
---

## 1. Commands used in branch

You can use `git branch -h` to check these commands' explanation. 

- list all branch `git branch -a`

- which branch `git status`

- create branch `git branch <name>`

- 创建并切换分支：`git switch -c <branch-name>`
- 只用于切换分支：`git switch <branch-name>`

- delete fully merged branch `git branch -d <name>`
- delete branch (even if not merged) `git branch -D <name>`

- merge benach `issue003` into current branch `git merge <issue003>`

- `git branch -m feature-old feature-new`
  - 将当前分支或指定的分支从 `<old-branch-name>` 重命名为 `<new-branch-name>`
  - 如果 `<new-branch-name>` 已经存在，Git 会报错并拒绝执行重命名操作

- `git branch -M feature-old feature-new`
  - 如果 `<new-branch-name>` 已经存在，Git 会直接覆盖现有的 `<new-branch-name>` 分支，不会有任何警告
  - 假设你当前在 `dev` 分支，并且有一个分支叫 `test`：
  - 输入 `git branch -m test`，会将当前分支 `dev` 重命名为 `test`，但因为 `test` 已存在，会报错
  - 输入 `git branch -M test`，会将当前分支 `dev` 强制重命名为 `test`，并覆盖原来的 `test` 分支


## 2. Commit 时看清所在分支和目标分支

**错误例子**: 有两个分支 `main`和 `backup`, 我想要把文件 push 到 `backup` 分支上以用于备份, 可是我却每次在本地的 main 分支编辑博客, 导致往远程分支 `origin/backup` push 的时候说 everything is up-to-date. 然后到 github 看是否备份, 发现并没有备份, 就出现了这种摸不清头绪的问题. 

Git 的分支是独立的, 而且 git push 的行为依赖于你当前所在的分支, 

我在 `main` 分支上修改文件：

- 当我在 `main` 分支上编辑文件并提交 `git commit` 时, 这些更改只会被记录在 `main` 分支的提交历史中
- `backup` 分支的本地版本和远程版本 `origin/backup` 完全不会受到影响，因为分支是隔离的

推送时的默认行为：

- 当你运行 `git push` 时，默认情况下，Git 会推送当前所在分支的更改到远程对应的分支
- 假设你在 `main` 分支上，执行 `git push`（不带参数），Git 会将本地的 `main` 分支推送至 `origin/main`，而不是 `origin/backup`
- 如果你明确运行 `git push origin backup`, Git 会尝试推送本地的 `backup` 分支到 `origin/backup`, 但因为你在 `main` 上改的文件，`backup` 分支没有任何新提交，所以 Git 告诉你 everything is up-to-date

## 3. 修改绑定在分支上

### 3.1. 新建分支必须做一次 commit

创建的分支后必须在该分支下做一次commit, 分支创建才会生效, 如果创建并转到分支 `backup`

```shell
git switch -c backup
vi main.c
git switch master
```

若没做任何 commit 就转到分支 ` master`, 则分支 ` branch` 并没有成功创建, 此时从 ` master` 分支转到 `backup` 分支, 会报错`fatal: invalid reference: backup`

> 这些修改还没有绑定到任何分支, 如果你不小心在分支  ` master` 上提交了这些修改, 它们会被记录到分支  ` master` 的历史中, 而不是你原本计划的分支  `backup`

### 3.2. 切换分支前确保已经做了 commit

情况 1: 在分支 A 修改文件并 commit 后切换到分支 B

- 如果你在分支 A 上修改了一些文件或新建了文件, 然后执行了 `git commit`, 这些修改会被提交到分支 A 的历史记录中
- 之后, 当你切换到分支 B, 分支 B 的工作目录会反映分支 B 的状态, 而不会包含你在分支 A 上刚刚提交的修改
- 这是 Git 的正常行为: 每个分支都有自己独立的历史和文件状态, **切换分支时, 工作目录会更新到目标分支的最新提交状态**

情况 2: 在分支 A 修改文件但未 commit 就切换到分支 B

- 如果你在分支 A 上修改了文件（这些修改处于“工作目录”或“暂存区”，即未执行 git commit），然后直接切换到分支 B，Git 的行为取决于具体情况

  1. 如果修改的文件在分支 B 上不存在冲突：Git 会默认将这些未提交的修改“带到”分支 B, 你会在分支 B 的工作目录中仍然看到这些修改, 这种行为是为了避免丢失你的未提交工作

  1. 如果修改的文件在分支 B 上有冲突（例如，分支 B 上的同一个文件有不同的内容），Git 会阻止你切换分支，并提示你先提交（commit）或暂存（stash）这些修改

- 所以，未 commit 的修改实际上是“浮动的”，它们会跟随你切换分支，直到你将它们提交到某个分支上

> 这些**修改还没有绑定到任何分支**, 如果你不小心在分支 B 上提交了这些修改, 它们会被记录到分支 B 的历史中, 而不是你原本计划的分支 A

更好的建议是：在切换分支前, 确保你的修改要么被 commit, 要么被 stash, 例如：

- `git stash`：将未提交的修改保存起来, 之后可以切换分支
- 在需要时使用 `git stash pop` 恢复这些修改

> 注意 `git stash` 并不等于 `git add` (stage), `git add` 只是暂存修改, 未提交的修改依然是“浮动的”, 会跟随你切换分支, `git stash` 则是彻底把修改移除并保存, 切换分支时不会看到它们
>
> `git stash` 的作用是将当前未提交的修改（工作目录和暂存区的变化）保存到一个临时的“堆栈”中, 并将你的工作目录恢复到当前分支的最新提交状态（干净状态）
>
> - 执行 git stash 后, 分支 A 的未提交修改会被“藏起来”, 工作目录会变干净
> - 然后切换到分支 B 时, 分支 B 的工作目录只会反映分支 B 的提交状态, 不会看到分支 A 的未提交修改

