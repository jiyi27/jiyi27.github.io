---
title: HEAD and Three Trees - Git
date: 2023-09-15 10:18:30
categories:
  - git
tags:
  - git
---

## 1. Three trees

Git as a system manages and manipulates three trees in its normal operation:

| Tree              | Role                              |
| :---------------- | :-------------------------------- |
| HEAD              | Last commit snapshot, next parent |
| Index             | Proposed next commit snapshot     |
| Working Directory | Sandbox                           |

The Git index is a critical data structure in Git. It serves as the “staging area” between the files you have on your filesystem and your commit history. When you run `git add`, the files from your working directory are hashed and stored as objects in the index, leading them to be “staged changes”. When you run `git commit`, the staged changes as stored in the index are used to create that new commit.

## 2. HEAD

### 2.1. HEAD is YOU

`HEAD`is a symbolic reference pointing to wherever you are in your commit history. It follows you wherever you go, whatever you do, like a shadow. If you make a commit, `HEAD` will move. If you checkout something, `HEAD` will move. Whatever you do, if you have moved somewhere new in your commit history, `HEAD` has moved along with you. To address one common misconception: you cannot detach yourself from `HEAD`. That is not what a detached HEAD state is. If you ever find yourself thinking: "oh no, i'm in detached HEAD state! I've lost my HEAD!" Remember, it's your HEAD. HEAD is you. You haven't detached from the HEAD, you and your HEAD have detached from something else.

Acutally, HEAD is just a special pointer that points to the **local branch** you’re currently on.

```shell
$ cat .git/HEAD                 
ref: refs/heads/hugo-blog
```

Sometimes you'll get something like this:

```
a3c485d9688e3c6bc14b06ca1529f0e78edd3f86
```

That's what happens when `HEAD` points directly to a commit. This is called a detached HEAD, because `HEAD` is pointing to something other than a branch reference.

> In Git, HEAD refers to the currently checked-out branch’s latest commit. However, in a *detached* HEAD state, the HEAD does not point to any branch, but instead points to a **specific commit** or the **remote repository**. 

### 2.2. What can HEAD attach to?

`HEAD` can point to a commit, yes, but typically it does not. Let me say that again. Typically `HEAD` does not point to a commit. It points to a branch reference. It is *attached* to that branch, and when you do certain things (e.g., `commit` or [`reset`](https://stackoverflow.com/a/54934887/7936744)), the attached branch will move along with `HEAD`. 

`HEAD` is you. It points to whatever you checked out, wherever you are. **Typically that is not a commit, it is a local branch.** If `HEAD` *does* point to a commit (or tag), even if it's the same commit (or tag) that a branch also points to, you (and `HEAD`) have been detached from that branch. Since you don't have a branch attached to you, the branch won't follow along with you as you make new commits. The `HEAD`, however, will.

{{% youtube "GN36mrrM12k" %}}

Source: 

https://stackoverflow.com/a/54935492/16317008

https://circleci.com/blog/git-detached-head-state/

https://youtu.be/GN36mrrM12k?si=S6_VTBQDZgG_fHre
