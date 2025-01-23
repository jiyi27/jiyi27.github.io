---
title: Backup Blogs with Git - Sovled
date: 2023-09-01 14:12:50
categories:
  - git
  - practice
tags:
  - git
---

## Problem

On github `shwezhu.github.io` repository I have two branch already, one is `master` for static html files that is generate web page, another is `backup` for backup of my hexo themes files and blogs. 

I want backup the hugo theme files with my blog files. 

## Solution

I'm using hugo now but I don't want to override or delete the theme files for hexo, therefore, I cannot just fetch remote branch `backup` and merge it with my local branch and then push. This will override the files stored on `backup` before. 

```shell
# should not do this
git fetch origin backup
git branch -a
git merge origin/backup --allow-unrelated-histories
```

So I create a new branch called `backup-hugo`, and push all files to this branch. 

```shell
cd blogs
git init
# you can add .gitignore here
git add .
git commit...
git branch -M backup-hugo # rename current branch
git push -u origin backup-hugo
```

## Other Findings

During this process, when I do commit I got wrong message that there is another git repository under `themes/even/`, however, I have do `git add .`, what should I do now is to go to `themes/even/` and delete `.git` file, then undo `git add` which is called unstage file from index area, 

```shell 
cd themes/even.
rm -rf .git
cd .. && cd ..
git rm --cached themes/even/.git
git add .
git commit...
```

`git rm --cached` is a very useful command, it can make file from tracked to untracked status. 