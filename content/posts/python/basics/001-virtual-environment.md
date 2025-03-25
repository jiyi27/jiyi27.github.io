---
title: Python 虚拟环境 Conda Venv
date: 2023-11-09 19:12:40
categories:
  - python
tags:
  - python
---

## 1. 为什么需要虚拟环境

在工作时通常会接触到不同的工程项目, 而每个项目可能会使用到不同的 Python 版本, 比如项目 A 使用 Python 2.X, 项目 B 使用 Python 3.10, 有的又使用 Python 3.7, 这些并不是根本原因, 主要原因是 Python 生态系统中的库通常对 Python 版本有严格要求, 新库利用新特性, 要求最低 Python 版本, 旧库未更新, 可能不支持新版 Python, 所以我们无法直接用一个最新的版本来充当万用表:

- 3.6 → 3.7: 依赖字典非有序性的代码可能失效
- 3.7 → 3.8: `async` 和 ⁠`await` 成为关键字, 使用这些作为变量名的代码会失败

在这种场景之下, 只有一个唯一的全局解释器仅仅只能满足其中一个项目的需要, 所以就需要一种机制可以让我们随时创建或删除不同的 Python 解释器, 于是虚拟环境（Virtual environment）也就应运而生, 使用虚拟环境的好处在于:

- 同一机器上并行使用不同 Python 版本
- 不同项目可使用同一库的不同版本而不冲突, 防止"依赖地狱" 避免全局安装导致的复杂依赖关系问题

## 2. 常见创建虚拟环境的工具

### 2.1. venv

`venv` 是 Python 内置的一个模块, 也就是说我们可以直接使用 python 解释器去创建, 不用特意安装:

```shell
$ python3 -m venv .skymates_env
$ source .skymates_env/bin/activate

# 可以看到使用的是虚拟环境里的 python 解释器 和 pip
$ which python
/Users/David/Downloads/aaa/.skymates_env/bin/python
$ which pip
/Users/David/Downloads/aaa/.skymates_env/bin/pip
$ python --version
Python 3.10.0
```

> - 虚拟环境目录名前面的 `.` 是个习惯, 因为它与项目无关, 我们选择隐藏它, 就像 `.git` 文件夹, 你也可以不加前面的 `.`
> - `-m`: run library module as a script
>
> - 使用 `venv` 有个不方便的地方就是对于 python 版本的控制, 我们环境的版本是由 `python3 -m venv .skymates_env` 中 执行此命令的 解释器版本决定的, 如果想换个不同解释器版本, 就要使用不同的解释器来执行, 比如: `/usr/bin/python3.12  -m venv .skymates_env`, 使用  `venv` 的主要目的就是方便创建一个隔离的环境, 隔离不同项目的依赖

### 2.2. conda

相信有相当一大部分比例的已经事先学习过 Python 的新手, 又或是如果从事数据分析、机器学习等数据科学相关工作的人, 在学习或使用过程会经常接触到一个名为 [Anaconda](https://sspai.com/link?target=https%3A%2F%2Fwww.anaconda.com%2F) 的 Python 发行版本, 在 Anaconda 中不仅内置了一个 Python 解释器, 同时还内置了许多常用的数据科学软件包或工具, 但 Anaconda 为人所诟病的地方也在于它内置了太多东西，其中的大多数又用不到，导致最终体积较大, 当然 Anaconda 还有另外一个精简版 [Miniconda](https://sspai.com/link?target=https%3A%2F%2Fdocs.conda.io%2Fen%2Flatest%2Fminiconda.html)，它只包含了少量的一些依赖库或包，有效减轻了电脑磁盘的负担, 

`venv` 需要手动指定 Python 版本（如 `python3.9 -m venv env`），而 `conda` 可以在创建环境时直接指定 Python 版本:

```shell
$ conda create --name my_env python=3.10
```

Conda 最大的一个优势就是它除了能安装 Python 依赖库或包之外, 还能安装其他语言的一些依赖（比如 R 语言）, 同时像 [Tensorflow](https://sspai.com/link?target=https%3A%2F%2Ftensorflow.google.cn%2F)、[Pytorch](https://sspai.com/link?target=https%3A%2F%2Fpytorch.org%2F) 这种业内常见的深度学习框架，往往会存在由 C/C++ 语言编写的部分，这些部分在安装时需要预先编译，而使用 Conda 安装时会自动连同已经事先编译好的二进制部分一起安装到虚拟环境中，**避免了因操作系统不同而导致的编译问题**, 

不像 `pip` 或 `virtualenv` 这样的工具我们能够单独安装, 要使用 Conda 我们通常会捆绑使用 Anaconda 或者 Miniconda, 直接根据自己的需求去官网下载安装就好了, 

使用 Conda 创建虚拟环境:

```shell
$ conda create --name my_env python=3.9
```

然后激活虚拟环境时只需要通过同样的 `active` 命令来操作即可:

```shell
$ conda active myenv
```

我们也可以将 Conda 作为 `pip` 工具来安装依赖:

```shell
$ conda install pandas seaborn
```

> 在使用 Conda 时, 建议不要混用 conda install 和 pip install 来安装 Python 的依赖包, 因为 Python 解释器自带 pip 工具，而 Conda 也有自己的包管理机制，二者虽然都能安装依赖，但管理方式和环境隔离的实现有所不同，混用可能会导致依赖冲突或环境不一致的问题, Conda 官方建议优先使用 conda install, 如果 Conda 无法满足需求, 再使用 pip install, 但要确保在 Conda 安装所有基础依赖后再用 pip

## 3. Conda 管理机制

### 3.1. 虚拟环境存储位置

我们知道使用 `venv` 创建虚拟环境时, 比如 `python3 -m venv .skymates_env`, 会在项目根目录创建一个虚拟环境目录, 之后我们通过 `pip install` 安装的依赖都是安装到 `.skymates_env` 目录下的, 而 `conda` 会**将环境创建在全局的 envs 目录下**（默认在 ~/anaconda3/envs/ 或 Miniconda 安装路径下），而不是项目根目录

```shell
$ conda env list
# conda environments:
base                   /opt/miniconda3
my_project_env         /opt/miniconda3/envs/my_project_env
travel_ai_env          /opt/miniconda3/envs/travel_ai_env
```

`my_project_env` 是 Conda 环境的名称, 用于方便管理环境, 当你运行 `conda activate my_project_env` 时, Conda 知道要切换到 `/opt/miniconda3/envs/my_project_env`, 这个文件夹是 Conda 环境在文件系统中的实际存储位置, 里面包含了 Python 解释器、所有安装的包和环境变量, 

### 3.2. 依赖管理

```shell
$ conda env export > environment.yml
$ conda env create -f environment.yml
```

将当前 Conda 环境的完整配置（包括所有安装的包及其版本）导出到一个名为 `environment.yml` 的文件中, 用来记录当前环境的完整状态, 方便在其他机器上或将来重新创建相同的环境

```yaml
name: myenv
channels:
  - conda-forge
  - defaults
dependencies:
  - python=3.9
  - numpy=1.21.2
  - pandas=1.3.4
```

> **还有必要使用 requirements.txt 吗？**
>
> `requirements.txt` 是 Python 生态中更传统的依赖管理方式, 通常与 `pip` 配合使用, 如果你完全依赖 Conda, `environment.yml` 已经足够, 通常不需要额外的 `requirements.txt`
>
> - environment.yml: 记录整个 Conda 环境的配置, 包括 Python 版本、非 Python 依赖（如 numpy 的底层库）和渠道信息
> - equirements.txt: 只记录 Python 包及其版本, 通常不包括非 Python 依赖或渠道信息

### 3.3. 常用命令

创建虚拟环境:

```shell
$ conda create -n ENV_NAME python=3.9
```

> Conda 会先检查你的系统中是否已经存在 Python 3.9（比如在 base 环境或其他地方）, 如果没有, Conda 会尝试从默认的包仓库下载 Python 3.9 的安装包, 下载完成后，Conda 会在新环境（ENV_NAME）中安装 Python 3.9, 这个 Python 解释器是独立的, 位于 `/path/to/anaconda3/envs/ENV_NAME/bin/python`, 不会影响系统中的其他 Python 版本

列出当前环境中的所有包:

```shell
$ conda list
```





```shell
conda activate ENV_NAME
conda deactivate
conda env remove -n ENV_NAME
conda install PACKAGE_NAME
conda install PACKAGE_NAME=VERSION
conda update PACKAGE_NAME # 更新包
conda update --all # 更新所有包
conda remove PACKAGE_NAME
conda clean --all # 清理未使用的包和缓存
```

