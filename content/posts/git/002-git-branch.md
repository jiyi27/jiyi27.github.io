---
title: git branch
date: 2023-04-22 00:47:50
categories:
  - git
tags:
  - git
---

## 1. Commands used in branch

You can use `git branch -h` to check these commands' explanation. 

List branches:

- `git branch`,  local, equals to `ls ./.git/refs/heads/`
- `git branch -r`, remote
- `git branch -a`, all
- you can add `-v` option, `git branch -v -a`

Check which branch you are on:

- `git status`

Create branch:

- `git branch <name>`

Switch branch:

- `git switch <name>`, only can switch to the branches on your local repository
- `git checkout <name>`

Delete branch:

- delete fully merged branch: `git branch -d <name>`
- delete branch (even if not merged):  `git branch -D <name>`
- delete a fetched branch locally: `git branch -r -d <name>`, e.g., `git branch -r -d origin/master `

Merge benach `issue003` into current branch：

- `git merge <issue003>`

Rename Current Branch

- move/rename a branch and its [reflog](https://www.atlassian.com/git/tutorials/rewriting-history/git-reflog): `git branch -m <branch-name>` 
-  move/rename a branch, even if target exists: `git branch -M <branch-name>` 

## 2. 切换分支需要注意的事

### 2.1. 在本地修改远程对应分支

想要 push 到远程某个分支, 就必须在本地对应的分支修改文件, 否则会导致 push 到错误的分支, 

**错误例子**: 有两个分支`main`和`backup`, 我想要把文件 push 到 `backup` 分支上以用于备份, 可是我却每次在本地的 main 分支编辑博客, 导致往远程分支 `origin/backup` push 的时候说 everything is up-to-date. 然后到github看是否备份, 发现并没有备份, 就出现了这种摸不清头绪的问题. 

### 2.2. 新建分支必须做一次 commit

创建的分支后必须在该分支下做一次commit, 分支创建才会生效, 

如创建并转到分支 `backup`

```shell
git switch -c backup
```

若没做任何 commit 就转到分支 ` master`, 则分支 ` branch` 并没有成功创建, 此时从 ` master` 分支转到 `backup` 分支, 会报错`fatal: invalid reference: backup`,

### 2.3. 切换分支前确保已经做了 commit

正常情况下在一个分支 A 做一些修改或者新建文件, commit 后再切换到分支B, 在分支 B 无法看到刚在分支 A 做的修改, 

如果在切换分之前没有commit, 即使你在某分支新建文件或者修改(但没commit), 跳到其他分支后仍可以看到你在那个分支做的修改, 所以 **在切换分支前一定要确保你已经做了commit**. 

还有一种特殊情况, 比如在`master`分支创建文件`a.txt`, 然后commit, 此时若新建一个分支 `B`, 则在分支 `B` 可以看到 master 分支所有的文件, 这是因为 `B` 分支还没被创建 文件 `a.txt` 就已经存在了, 即新建分支的内容是在原有分支内容的基础上产生的, 如果现在 在`master`分支创建文件 `test.txt`, 然后commit, 再新建个分 支`dev`, 这时候 `dev` 可以看到`master`分支所有的文件 `a.txt`, `test.txt`, 但已存在的分支 `B` 看不到 `test.txt`. 

有时切换分支会出现错误:

```shell
$ git switch main 
error: Your local changes to the following files would be overwritten by checkout:
	content/posts/Merge&Rebase.md
Please commit your changes or stash them before you switch branches.
Aborting
#-------------------------#
$ git switch master
error: The following untracked working tree files would be overwritten by checkout:
	.DS_Store
Please move or remove them before you switch branches.
Aborting
```

所以结论是, **切换分支前, 一定要记得commit, 别在A分支修改你想提交到B分支的文件**.

了解 stash: [git-stash Documentation](https://git-scm.com/docs/git-stash) 
