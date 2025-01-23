---
title: git fetch - the Essence of "origin"
date: 2023-04-21 21:46:44
categories:
  - git
tags:
  - git
---

## 1. `git fetch`

The `git fetch` command downloads commits, files, and refs from a remote repository into your local repo. Fetching is what you do when you want to see what everybody else has been working on. **Git isolates fetched content from existing local content; it has absolutely no effect on your local development work**. 

Fetch all of the branches from the repository. This also downloads all of the required commits and files from the other repository.

```shell
$ git fetch <remote>
```

Same as the above command, but only fetch the specified branch.

```shell
# e.g., git fetch origin master
$ git fetch <remote> <branch>
```

## 2. What is `origin` 

`<remote>` here is the url of the remote repository, we usually set an alias (often set as `origin`) so that we can refer it conveniently. Check here, we set the alias when specify the remote repository to local:

```shell
# means: origin=git@github.com:shwezhu/MyProject.git
git remote add origin git@github.com:shwezhu/your-repo.git
```

You can set the alias to other name like this:

```shell
git remote add my-repo-github git@github.com:shwezhu/your-repo.git
```

But you have to use `my-repo-github` when you want to refer that url:

```shell
# equals to: git fetch git@github.com:shwezhu/your-repo.git your-branch
git push my-repo-github your-branch
git fetch my-repo-github your-branch
```

You can change the alias:

```shell
git remote rename repo origin
```

## 3. `git remote` command

The `git remote` command is also a convenience or 'helper' method for modifying a repo's `./.git/config` file. The commands presented below let you manage connections with other repositories. The following commands will modify the repo's `/.git/config` file. The result of the following commands can also be achieved by directly editing the `./.git/config` file with a text editor. 

```shell
git remote add <name> <url>
```

Create a new connection to a remote repository. After adding a remote, you’ll be able to use `＜name＞` as a convenient shortcut for `＜url＞` in other Git commands. 

References:

- [Git Remote | Atlassian Git Tutorial](https://www.atlassian.com/git/tutorials/syncing)
- [Git Fetch | Atlassian Git Tutorial](https://www.atlassian.com/git/tutorials/syncing/git-fetch)

