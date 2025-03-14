---
title: git rm & git restore
date: 2023-05-05 09:31:30
categories:
  - git
tags:
  - git
---

Remember that each file in your **working directory** can be in one of **two states**: *`tracked`* or *`untracked`*. Tracked files are files that were in the last **snapshot**, as well as any newly **staged files**; they can be `unmodified`, `modified`, or `staged`. In short, tracked files are files that Git knows about. As you edit files, Git sees them as modified, because you’ve changed them since your last commit. As you work, you selectively stage these modified files and then commit all those staged changes, and the cycle repeats.

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2025/03/a419c42b18cc5936bf3d95ccb67fddcb.png)

Some commands are used frequently, the commands below will make a diffference on ***Git repository*** but won't change the ***wok place*** (file system):

```shell
# just untrack file
git rm --cached file-name
# just unstatge file
git restore --staged file-name
```

The commands below will change both work place and Git repository:

```shell
# untrack file & rm file
git rm file-name
# unstatge file & discard uncommitted local changes
git restore file-name
```