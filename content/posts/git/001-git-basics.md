---
title: git rm & git restore
date: 2023-05-05 09:31:30
categories:
  - git
tags:
  - git
typora-root-url: ../../../static
---

## 1. Status Switch

Remember that each file in your **working directory** can be in one of **two states**: *`tracked`* or *`untracked`*. Tracked files are files that were in the last **snapshot**, as well as any newly **staged files**; they can be `unmodified`, `modified`, or `staged`. In short, tracked files are files that Git knows about. As you edit files, Git sees them as modified, because you’ve changed them since your last commit. As you work, you selectively stage these modified files and then commit all those staged changes, and the cycle repeats.

![a](/001-git-basics/a.png)

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

## 2. Untrack File

```shell
git rm file-name
git rm --cached file-name
```

The "rm" command helps you to remove files from a Git repository. It allows you to not only delete a file from the *repository*, but also - if you wish - from the *filesystem*.

Deleting a file from the filesystem can of course easily be done in many other applications, e.g. a text editor, IDE or file browser. But deleting the file from the *actual Git repository* is a separate task, for which `git rm` was made.

- ***`--cached`***
  - **Removes the file only from the Git repository, but not from the filesystem.** By default, the `git rm` command deletes files both from the Git repository as well as the filesystem. Using the `--cached` flag, the actual file on disk will *not* be deleted.

- ***`-r`***
  - **Recursively removes folders.** When a path to a directory is specified, the `-r` flag allows Git to remove that folder including all its contents.

### 3. Unstage File

```shell
git restore file-name
git restore --staged file-name
```

The "restore" command helps to unstage or even discard uncommitted local changes. On the one hand, the command can be used to undo the effects of `git add` and unstage changes you have previously added to the ***Staging Area***. 

- ***`--staged`***
  - **Removes the file from the Staging Area, but leaves its actual modifications untouched.** By default, the `git restore` command will discard any local, uncommitted changes in the corresponding files and thereby restore their last committed state. With the `--staged` option, however, the file will only be removed from the Staging Area - but its actual modifications will remain untouched.

- ***`--source <ref>`***
  - **Restores a specific revision of the file.** By default, the file will be restored to its last committed state (or simply be unstaged). The `--source` option, however, allows you to restore the file at a *specific revision*.

```shell
$ git restore --source 7173808e index.html
$ git restore --source master~2 index.html
```

The first example will restore the file as it was in commit #7173808e, while the second one will restore it as it was "two commits before the current tip of the master branch".

## 3. Stage File

```shell
git add file-name
```

It adds changes to Git's ***Staging Area*** (index), the contents of which can then be wrapped up in a new revision with the `git commit` command.

## 4. Conclusion

- Git repository, Work place (Filesystem,  Working tree), Staging Area (Index), 
- Stage the file: `git add <filename>`
- Unstage: ` git restore --staged <filename>`, `git restore <filename>`
- Untrack: ` git rm --cached <filename>`, `git rm <filname>` 

References:

- https://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository
- https://www.git-tower.com/learn/git/commands/git-rm
- https://www.git-tower.com/learn/git/commands/git-restore
