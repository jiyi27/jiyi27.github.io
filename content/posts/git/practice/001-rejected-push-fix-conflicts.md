---
title: Push on Github get Rejected - Solved
date: 2023-08-15 22:18:50
categories:
  - git
  - practice
tags:
  - git
---

## Problem

 GitHub 新建一个 repository, 并选择了自动创建 `README.md`, 在本地初始化项目后进行push, 报错:

```shell
$ git push -u origin master
To github.com:shwezhu/gptbot.git
 ! [rejected]        master -> master (fetch first)
error: failed to push some refs to 'github.com:shwezhu/gptbot.git'
hint: Updates were rejected because the remote contains work that you do
hint: not have locally. This is usually caused by another repository pushing
hint: to the same ref. You may want to first integrate the remote changes
hint: (e.g., 'git pull ...') before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
```

## 原因分析

远程仓库存在本地仓库没有的 commit, 导致 push 被拒绝, 

## 解决办法

fetch 下来查看都是什么 commit, 再决定是否进行 merge, 

```shell
# git fetch <remote> <branch>, <branch> is optional
git fetch origin

# list all branches
git branch -v -a
* master                a48d922 Rework handler
  remotes/origin/master f6c60de Initial commit

# check the work on the remote
git checkout origin/master
Note: switching to 'origin/master'

# 切换远程分支后, workplace 只剩下一个 `README.md` 文件, 
# 发现没什么问题, 切换回本地原分支,  (假装查看变化)
git switch master

# 注意 如果查看变化后你不想合并这个远程分支 直接删除该分支即可
# git branch -r -d origin/master, 必须加上 -r 否则报错找不到分支
git merge origin/master
fatal: refusing to merge unrelated histories

git merge origin/master --allow-unrelated-histories
Merge made by the 'ort' strategy.
 README.md | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 README.md
 
# 查看 commit history
git log
commit 14daf2d5ae37dea131416629c6df22e1fe8ab456 (HEAD -> master)
Merge: a48d922 f6c60de
Author: David Zhu <shaowenzhu@dal.ca>
Date:   Tue Aug 15 23:03:47 2023 -0300

    Merge remote-tracking branch 'origin/master'

commit f6c60de218933dcb40e507a88998318b4644034c (origin/master)
Author: David Zhu <shwezhu@qq.com>
Date:   Wed Aug 16 06:29:10 2023 +0800

    Initial commit

commit a48d922d19e96b76f71dd09e0048f16d8feea03d
Author: David Zhu <shaowenzhu@dal.ca>
Date:   Tue Aug 15 19:28:27 2023 -0300

    Rework handler
   
# 此时再 push
git push -u origin master
```

## 总结

- 通过 `git fetch origin` 拉取远程仓库的commit

- 通过 `git branch -v -a` 查看所有分支, 选择是否进行merge
- 执行 merge 时 git 会自动做一次 commit
- `git merge origin/master --allow-unrelated-histories`



