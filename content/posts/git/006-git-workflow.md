---
title: git 工作中用到的一些场景
date: 2025-03-21 13:05:20
categories:
  - git
tags:
  - git
---

## 1. 不要忘记的事

>  `git commit` 前确认当前分支, 避免在 main 分支直接修改, **本地修改应该提交到自己的分支上**
>
>  `git push` 永远不要直接 push 到 main 分支, 而应该 push 到功能分支或其他分支
>
>  谨慎用 `git pull`: `git pull origin master` 
>
>  - 从远程 `origin` 拉取 `master` 分支的最新提交
>  - 将这个远程 `master` 分支的内容**合并到当前所在的分支**，比如 `feat/message`
>
>  `git push origin master`
>
>  - 将本地的 `master` 分支推送到远程的 `origin` 仓库的 `master` 分支
>  - 与你当前所在的分支（如 `feat/message`）无关

## 1. 准备的事

马上入职了, 在高铁上研究一下, 五个小时, 足够了, 一般入职后, 应该了解公司的开发要求, 一般会有文档, 大致内容有:

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

> 如果是开源项目, 直接 fork 仓库, 然后 克隆自己 Forked 的仓库

### 2.2. 创建本地功能分支（Feature Branch）并开发

开始做一个新功能或需求，按团队约定应该基于 `develop` 分支拉出一个 feature 分支，比如 `feature/user-auth`:

```shell
git switch develop         # 确保当前在 develop 分支
git pull origin develop    # 再次确认 develop 是最新的
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

> **开源项目场景**
>
> - origin 默认指向你自己 Forked 的仓库（例如 https://github.com/your-username/original-repo.git）
> - 因此 `git fetch origin` 只会拉取你自己仓库的更新
> - 但在开源协作中，你通常需要获取**原始仓库**（别人的仓库）的最新更新，而不是自己仓库的更新, 问题在于，你还没有设置一个指向原始仓库的远程仓库（通常命名为 upstream）, 因此，单纯使用 fetch origin 无法达到拉取更新的目的
>
> ```shell
> # 添加原始仓库作为 upstream
> git remote add upstream https://github.com/original-owner/original-repo.git
> 
> # 使用 fetch 从 upstream 获取最新更改
> git fetch upstream
> 
> git checkout feature-branch
> git rebase/merage upstream/main
> ```

> 我们知道 在拉取更新的时候 一般会拉取某个特定的远程分支, 然后把它与我们的本地分支合并, 以便让自己的分支保持最新状态, 可是我们应该合并哪个分支？main 还是 develop 还是其他分支？
>
> - 查看项目文档：大多数开源项目会在 README 或 CONTRIBUTING.md 中说明分支使用规则，例如新特性应该基于 develop，bug 修复基于 main
> - 分支基础：创建本地分支时，通常是从某个远程分支（如 main 或 develop）拉取的, 保持与这个“基础分支”一致即可
> - 默认情况：如果项目没有明确说明，通常与 main（或 master）保持同步，因为它是默认的主分支
>
> 不是所有开发分支都合并到主分支，直接合并主分支就行？
>
> 不一定, 不同的项目有不同的分支管理策略：
>
> - 单一主分支模型：只有一个 main 分支，所有开发分支最终合并到 main, 这种情况下，直接与 main 保持同步即可
> - 多分支模型：例如有 main（稳定分支）和 develop（开发分支），新特性先合并到 develop，然后定期将 develop 合并到 main, 这种情况下，需要根据分支目的选择同步对象

### 2.4. git stash

在上一步确保自己分支最新, 通常的流程是:

- 使用 git fetch upstream 获取更新
- 使用 git merge upstream/main 或 git rebase upstream/main 将更新应用到本地分支

但是否需要使用 git stash 和 git stash pop，取决于你的**工作目录状态**, git stash 的作用是临时保存当前工作目录和暂存区的未提交更改, 并将工作目录恢复到干净状态, 它的必要性取决于以下情况:

如果你在 feature-branch 上修改了文件但尚未提交（即 git status 显示有改动）, 直接执行 git merge 或 git rebase 会失败, Git 会提示你先提交或处理这些更改, 因为合并操作需要一个干净的工作目录

**解决方法**：使用 git stash 保存未提交更改，拉取并合并更新后再恢复

```shell
# 隐藏更改
git stash
# 拉取更新
git fetch upstream main
# 合并更新
git merge upstream/main
# 弹出更改 继续工作
git stash pop
```

> 注意一般只有参加开源项目才会使用 `upstream`
>
> - 尽量在合并前提交更改 commit，保持工作目录干净，减少使用 git stash 的需求
>
> - 如果使用 git stash，注意合并后的冲突处理

### 2.5. rebase vs merge

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

### 2.6. 推送

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

### 2.7. PR

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

## 4. 实践

现在的情况, 有下面这几个分支:

```shell
  deps/update-requirements
  feature/add-redis-client
  feature/file-upload
  fix/fk-reference-cycle
  fix/init-data-migration
* main
  remotes/origin/HEAD -> origin/main
```

- 我在本地创建了新分支 deps/update-requirements 做了修改并提交, 推送到了远程仓库, 然后创建了 PR, 注意此时 PR 暂时没被接受

- 期间远程仓库有其他人做了提交

- 之后我又在本地创建了新分支 fix/fk-reference-cycle, 然后做了修改并提交, 然后推送到远程仓库, 然后创建了 PR, 注意此时 PR 暂时没被接受

- 期间远程仓库有其他人做了提交
- 之后相同, 创建提交推送 fix/init-data-migration, 创建 PR, 依然暂时没被接受
- 期间远程仓库有其他人做了提交

- 之后相同, 创建提交推送 feature/file-upload, 创建 PR, 依然暂时没被接受

- 期间远程仓库有其他人做了提交
- 此时之前所有的分支的 PR 都被合并到了 origin main 分支
- 然后我在本地创建新分支 feature/add-redis-client, fetch origin main, 然后 merge origin/mian, 所以此时 feature/add-redis-client 应该是最新的
- 然后我又转到了本地 main 分支, 执行 fetch origin main, 然后 merge origin/mian, 

> 此时, 我想知道的是, 我打算删除 deps/update-requirements, fix/fk-reference-cycle, fix/init-data-migration 分支, 因为我可以确定以后不会使用他们了, 请问在一般的开发工作流中, 我应该怎么删除这些分支, 我应该同时删除本地和远程分支吗? 给出理由

- 是的, 应该同时删除本地和远程分支
- 远程分支删除后，本地保留分支可能会导致误解，比如误以为这些分支还有未完成的工作
- 删除远程分支可以避免其他开发者误用这些已合并的分支，保持远程仓库的整洁和清晰
- 在 Git 工作流（如 Git Flow）中，已合并的分支通常会在 PR 完成后被删除，这是标准实践

**删除本地分支**

```shell
git branch -d deps/update-requirements
git branch -d fix/fk-reference-cycle
git branch -d fix/init-data-migration
```

- `git branch -d` 是删除本地分支的安全方式, 它会检查这些分支是否已合并到当前分支, 通常是 main
- 因为这些分支的 PR 已被合并到 `origin/main`，而你已经将本地的 `main` 分支更新到 `origin/main` 的最新状态（通过 fetch 和 merge），所以这些分支的更改已经包含在本地 main 中，Git 会允许删除它们

**删除远程分支**

```shell
git push origin --delete deps/update-requirements
git push origin --delete fix/fk-reference-cycle
git push origin --delete fix/init-data-migration
```

- `git push origin --delete <branch_name>` 会删除远程仓库中的对应分支

- 这些分支的 PR 已经合并到 `origin/main`，远程分支已无保留必要，删除它们是常见做法

> 另外此时我想回到本地的 feature/file-upload 分支进行一些新的修改, 可是我在本地分支  feature/file-upload  还没有进行 merge 远程最新提交, 此时我应该怎么做? 

**首先, 切换到这个分支 并 合并 `main` 分支到 `feature/file-upload`:**

```shell
git checkout feature/file-upload
git merge main
```

- 因为你的本地 `main` 分支已经通过 `fetch` 和 `merge` 更新到了 `origin/main` 的最新状态，你可以直接将 `main` 合并到 `feature/file-upload`

**进行新的修改** 合并完成后, `feature/file-upload` 分支就处于最新状态, 你可以开始进行新的修改并提交:

```shell
# 进行修改后
git add .
git commit -m "添加新的修改"
```

我在 main 分支上做了修改和提交, 其实我应该在 另外一个功能分支做 commit, 因此, 我应该撤销刚刚的提交:

```shell
 git reset --soft HEAD^1
```

