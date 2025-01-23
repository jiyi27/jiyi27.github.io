---
title: git merge vs git rebase
date: 2023-09-15 10:20:23
categories:
  - git
tags:
  - git
---

In Git, there are two main ways to integrate changes from one branch into another: the `merge` and the `rebase`. 

## 1. fast-forward vs three-way merge

There are two type of merge:

- three-way merge, 
  - happens when the branches' commit have diverged
  - will result a merge commit
- fast-forward merge, 
  - happens when there is a liner structure in the commit history
  - we usually prevent fast-forward merge, because **there is no merge commit**. 
  - can be suppressed with the `--no-ff` option

The liner structure commit structure looks like this:

```shell
      A---B fixbug
     /
...--E master
```

Branches' diverged commit structure looks like this:

```
      A---B fixbug
     /
...--E--F master
```

{{% youtube "zOnwgxiC0OA" %}}

Video: https://youtu.be/zOnwgxiC0OA

## 2. git rebase

> *The Golden Rule of Rebasing reads: “Never rebase while you’re on a public branch.”*
>
> Source: https://www.gitkraken.com/blog/golden-rule-of-rebasing-in-git

On `main` branch:

```shell
* commit 41bc8e89e60d75e21e034aaabcbd20103a61fca4 (HEAD -> main)
|     main: Fri 15 Sep 2023 13:01:02 ADT
| 
* commit 2220b67f9c8ccf5f47e51bff7bd3a3fca6e141b6
      main: Fri 15 Sep 2023 11:47:54 ADT
```

On `fixbug` branch:

```shell
* commit 0096a2dfa2b4e4c40011213b6cce12ee73833ca9 (HEAD -> fixbug)
|     fixbug: Fri 15 Sep 2023 11:48:53 ADT
| 
* commit fd900fa0c05632757f45fd6fee236eb84c99bb94
|     fixbug: Fri 15 Sep 2023 11:48:27 ADT
| 
* commit 2220b67f9c8ccf5f47e51bff7bd3a3fca6e141b6
      main: Fri 15 Sep 2023 11:47:54 AD
```

Now the **commit history of all branches** looks like this:

```shell
      A---B fixbug
     /
...--E---F main
```

Go to `main` branch and make rebase. 

```shell
$ git switch main
$ git rebase fixbug
Successfully rebased and updated refs/heads/main.
```

Check the log, you can see, these two branches combined but the commit histroy structure is linear:

```shell
* commit 918260ae4f0b7f7d573a9a640ce380ea0f861a6a (HEAD -> main)
|     main: Fri 15 Sep 2023 13:01:02 ADT
| 
* commit 0096a2dfa2b4e4c40011213b6cce12ee73833ca9 (fixbug)
|     fixbug: Fri 15 Sep 2023 11:48:53 ADT
| 
* commit fd900fa0c05632757f45fd6fee236eb84c99bb94
|     fixbug: Fri 15 Sep 2023 11:48:27 ADT
| 
* commit 2220b67f9c8ccf5f47e51bff7bd3a3fca6e141b6
      main: Fri 15 Sep 2023 11:47:54 ADT
```

Now **the commit history of `main` branch** looks like this (and you can delete `fixbug` branch):

```shell
      A---B---F' main
     /
...--E
```

As you can see, rebase just make a fast-forward merge happen even the branches has diverged. 

And note that the `F'` mean it's a copy of original commit `F` (git will do this internally), this is why we should not use rebase on a shared branch, `main` for example, because `rebase` will "change" the commit history of branch `main`. 

{{% youtube "zOnwgxiC0OA" %}}

## 3. git rebase vs merge

- Merge preserves commit history. 
  - Use merge on a **public branch**. 
- Rebase rewrites (makes copy) history.
  - Use rebase on a **private branch** to catch up update form remote. 
  - Why rebase rewrite commit history: https://youtu.be/zOnwgxiC0OA?si=CwbvoPI35pHgJ1pn&t=401
- `git push --force` on shared branches is an absolute no-no. 

> Note that we say use rebase on a private branch means we can use the command`git rebase master` on a private, please don't use `git rebase fixissue` on `master` branch which apparently is a publick branch. 
>
> Learn more: https://youtu.be/zOnwgxiC0OA?si=CwbvoPI35pHgJ1pn&t=401

{{% youtube "CRlGDDprdOQ" %}}

References:

- [Learn Git Rebase in 6 minutes // explained with live animations!](https://youtu.be/f1wnYdLEpgI?si=QTeScOvk_yNzzud-)
- [Git MERGE vs REBASE: The Definitive Guide](https://youtu.be/zOnwgxiC0OA?si=zUXhbnfTX7Ve8BiJ)
- [Git MERGE vs REBASE](https://youtu.be/CRlGDDprdOQ?si=zSduuwUYe6YpoVUG)