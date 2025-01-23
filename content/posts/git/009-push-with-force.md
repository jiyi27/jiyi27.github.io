---
title: Git Push with force
date: 2023-09-14 10:00:23
categories:
  - git
tags:
  - git
---

## 1. `git push -f` is dangerous

The commit history on my local and remote repo are same:

```
second commit
first commit
```

Then I added a file `docs.md` driectly on github and make a commit so there is another new commit history on remote repo which is different form the commit history of my local repo. 

Commit history on **remote repo**:

```
create docs.md
second commit
first commit
```

Files on **remote repo**:

```
README.md
main.c
docs.md
```

Then I made some modifications on local repo and make a commit. 

Commit history on **local repo**:

```
third commit
second commit
first commit
```

Files on **local repo:**

```
README.md
main.c
```

Now when I try to push my local changes to github:

```
$ git push origin master
To github.com:shwezhu/test_repo.git
 ! [rejected]        master -> master (fetch first)
error: failed to push some refs to 'github.com:shwezhu/test_repo.git'
hint: Updates were rejected because the remote contains work that you do
hint: not have locally. This is usually caused by another repository pushing
hint: to the same ref. You may want to first integrate the remote changes
hint: (e.g., 'git pull ...') before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
```

This happens because the commit history of the master branch in local and remote repo are different. 

One way to slolve this is to fetch the remote and merge the changes (commit history will be merged too), then push will succeed. Learn more: [Push on Github get Rejected - Solved - David's Blog](https://davidzhu.xyz/post/git/practice/001-rejected-push-fix-conflicts/)

Another way is to use `git push -f` but this will overwirte your remote repo, which means **the commit history and the work place on remote rep will be overwritten **. 

After use  `git push -f`, the commit history and workplace of  the remote repo will looks exactly like the local:

```shell
third commit
second commit
first commit
```

Noew the file `docs.md` will miss which means **`git push -f` is dangerous.** 

## 2. `–force-with-lease`

Git’s `push --force` is destructive because it unconditionally overwrites the remote repository with whatever you have locally, possibly overwriting any changes that a team member has pushed in the meantime. However there is a better way; the option –force-with-lease can help when you do need to do a forced push but still ensure you don’t overwrite other’s work.

`--force` on shared branches is an absolute no-no. 

Learn more: [-force considered harmful; understanding git's -force-with-lease - Atlassian Developer Blog](https://blog.developer.atlassian.com/force-with-lease/)