---
title: git 工作流
date: 2025-03-21 13:05:20
categories:
  - git
tags:
  - git
---

## 1. 准备的事

一般入职后, 应该了解公司的开发要求, 一般会有文档, 大致内容有:

- 变量 函数 文件 命名规则 (数据库 表 列 等等)
- 注释规则
- 了解当前都是有什么分支, 一般的会有 master, develop, feature, hotfix, release 等主要分支
- git 分支命名规则, 提交信息格式 内容要求 如 `feat: xxx`, `fix: xxx`
- 一般习惯使用 rebase 还是 merge

## 2. 一般的工作流

### 2.1. 克隆仓库 & 本地初始化

克隆公司仓库 查看分支 

```shell
# 用 clone 命令会直接帮你在本地创建一个与远程关联好的仓库
git clone git@github.com:Company/xxx.git

cd xxx
git branch -a     # 查看所有本地/远程分支
```

切换到 develop 分支（如果团队约定 develop 是主要的开发分支）

```shell
# 假设默认分支是 master 或 main，你想基于 develop 开发：
git switch develop
```

### 2.2. 创建本地功能分支（Feature Branch）并开发

开始做一个新功能或需求，按团队约定应该基于 `develop` 分支拉出一个 feature 分支，比如 `feature/user-auth`:

```shell
git switch develop         # 确保当前在 develop 分支
git pull origin develop      # 再次确认 develop 是最新的
git switch -c feature/user-auth
```

这样就创建了一个名为 `feature/user-auth` 的分支, 并自动切换到该分支进行后续开发, 你在 `feature/user-auth` 上开发用户认证功能：增删改文件等, 开发告一段落后，将改动提交到本地仓库:

```shell
git status
git add .
git commit -m "feat: 实现基础的用户登录注册流程"

# 首次推送新分支时，需声明关联远程分支：
git push --set-upstream origin feature/user-auth
# 以后就可以直接用 git push 命令了
```

- 当你创建一个新的本地分支 比如通过 `git switch -c feature/user-auth`, 这个分支只存在于你的本地仓库, 远程仓库（比如 GitHub、GitLab）还不知道这个分支的存在, 如果你直接运行 `git push`, Git 会报错, 因为它不知道要把代码推送到远程的哪个分支
- 这时 `--set-upstream` 就派上用场了，它不仅推送代码，还在远程仓库创建对应的分支，并建立跟踪关系
- `--set-upstream`: 这个选项告诉 Git 在推送的同时, 建立本地分支 `feature/user-auth `与远程分支 `origin/feature/user-auth` 之间的关联关系

> 一旦这个跟踪关系建立完成
>
> 当你**处于 `feature/user-auth` 分支**并运行 `git push` 时，Git 会根据已建立的跟踪关系，自动将代码推送到 `origin/feature/user-auth` 分支，而无需再次手动指定远程分支
>
> 但这仅适用于**当前分支**。如果你当前不在 `feature/user-auth` 分支（比如切换到了 `develop` 分支），运行 `git push` 时，Git 只会推送**当前分支**到它所跟踪的远程分支（如果有跟踪关系的话），或者根据 Git 的默认推送策略执行操作，而不会自动推送 `feature/user-auth`

### 2.3. 保持分支“不过度落后”的同步操作

如果你的 `feature/user-auth` 分支开发周期较长，而 `develop` 分支上其他同事也在更新，担心合并冲突会越来越多，所以需要定期“同步”一下 `develop` 最新代码到你的 `feature/user-auth` 分支, 在开始操作前，先确认你的 `feature/user-auth` 分支没有未提交的更改：

```shell
git status
```

- 如果有未提交的更改，先用 git add 和 git commit 提交，或者用 git stash 暂时保存

```shell
git switch feature/user-auth # 确保当前在 feature/user-auth 分支上操作
git fetch origin 						# 拉取 合并 
git merge origin/develop
```

- 为什么不用 `git pull`: `git pull` 是 `git fetch` 和 `git merge` 的组合，会直接合并远程分支到本地分支

### 2.4. rebase vs merge

```shell
git fetch origin
git switch feature/user-auth
git rebase origin/develop
```

初始状态

```
origin/develop:   A --- B --- C
                  \
feature/user-auth:  D --- E
```

用 merge 

```
origin/develop:   A --- B --- C
                  \           \
feature/user-auth:  D --- E --- M (M 是合并提交)
```

用 rebase

```
origin/develop:   A --- B --- C
                              \
feature/user-auth:             D' --- E'
```

D' 和 E' 是 D 和 E 的新版本, 基于 C

- rebase 通过把 feature/user-auth 的提交搬到 origin/develop 最新点的方式来更新  feature/user-auth 内容, 因为这样可以保持线性历史
- rebase 让 feature/user-auth 的提交历史看起来像是直接从 origin/develop 的最新点开始，没有分叉和额外的合并提交。这种干净的线性历史更易读，尤其在将来合并回 develop 时
- merge 会引入一个合并提交（比如 M），记录了分叉和汇合的过程。虽然这保留了完整的历史，但在一些团队中（尤其是追求简洁历史的团队），可能会显得“杂乱”
- 如果 `feature/user-auth` 是你个人的特性分支（未被多人共享），rebase 是安全的，因为它重写历史不会影响他人
- 但如果 `feature/user-auth` 是多人协作的分支，rebase 可能会导致问题（其他人需要同步重写后的历史），这时 merge 更合适

`develop` 是公共分支, `feature/user-auth` 是你自己的分支, 不要在 公共 分支上做 rebase, 只可以在自己的私有分支做 rebase, 就是记住一句话, 不要随便用 rebase, 用之前确认好, `git rebase origin/develop` 的意思是在 `feature/user-auth` 做 rebase, 不要理解错了

### 2.5. 推送

**用 merge 后的推送**

```shell
git push
```

- 远程分支 origin/feature/user-auth 会更新为包含合并提交的历史（A -> B -> C -> D -> E -> M）
- 因为只是追加了新提交，推送是自然的增量更新，无需强制推送

**用 rebase 后的推送**

```shell
git push --force-with-lease
```

- 注意: `--force-with-lease` 不是 `--force`
- 因为 rebase 重写了 feature/user-auth 的提交历史（从 A -> D -> E 变成 A -> B -> C -> D' -> E'），本地和远程的历史不再匹配
- 普通 `git push` 会被拒绝（因为不是快进更新），需要用 `--force-with-lease` 强制覆盖远程分支
- `rebase`  推送需要强制（git push --force-with-lease），会覆盖远程历史，仅适合个人分支或提前沟通好的团队

### 2.6. PR

- 登录 Git 仓库平台（GitHub / GitLab），找到 `feature/user-auth` 分支，发起 Merge Request / Pull Request 到 `develop`

- 填写说明，例如 “新增用户登录和注册，数据库schema改动如下...”
- 通过同事的 Review 后，点击“合并”按钮把 `feature/user-auth` 合并进 `develop`
- 删掉远程 `feature/user-auth` 分支（可选），以及本地分支
- 你再切换回 develop 分支, 拉取最新改动, 准备下一个功能

## 3. 一些注意的地方

### 3.1. 公司内部 / 团队协作（常见场景）

一般在开发中,你拥有直接向团队的远程仓库推送代码的权限

所以：

1. 直接克隆公司（或团队）仓库到本地：`git clone git@github.com:Company/Project.git`
2. 在同一个仓库中创建分支（如 `feature/xxx`），再 push 分支到公司远程库 `origin` 的 `feature/xxx` 分支
3. 在 GitLab/GitHub 企业版上，对同一个远程仓库发起 Merge Request / Pull Request

这一套流程下, 不需要你先 fork 一份“自己的”仓库, 因为你已经是这个仓库的协作者, 有权限直接操作主仓库分支

### 3.2. 个人 / 开源项目贡献（Fork 工作流）

如果你想给某个 并非自己管理 的开源项目贡献代码，而你没有对它的仓库“写权限”，则必须先 Fork 一份到自己的 GitHub 账户下，做一个属于你自己的远程仓库, 典型流程：

1. 打开开源项目主页，点 Fork
2. 在你的个人 GitHub 账户下，就会生成一个“forked” 仓库（地址类似：`github.com/YourName/Project`）
3. 你再执行 `git clone git@github.com:YourName/Project.git`（从你自己的 fork 拉取到本地）
4. 在本地切分支开发，push 到你自己的 fork（也就是 origin 指向 `YourName/Project.git`）
5. 在 GitHub 上向 上游仓库（官方项目 `Company/Project.git`）提交 Pull Request

这样就实现了“没有写权限的外部贡献者”把代码贡献到开源项目的流程, 在开源世界里，经常会看到文档写到 `upstream` 和 `origin` 两个远程：

- `origin`：你自己 fork 的仓库地址（你有写权限）
- `upstream`：原始官方仓库地址（你没有写权限，只有读权限）
- 你会不定期执行 `git pull upstream main` (或 master, 或 develop) 来保持和官方仓库同步
