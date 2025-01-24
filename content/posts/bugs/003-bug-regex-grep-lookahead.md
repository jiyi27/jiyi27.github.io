---
title: grep 不支持 Negative Lookahead 问题
date: 2023-05-02 22:29:30
categories:
 - Bugs
tags:
 - 正则表达式
---

刚开始使用`printf "123\n24567\n8930\n234\n" | egrep '(?<!2)3'`提示`egrep: repetition-operator operand invalid`, 然后查到可以使用参数`-P`, 如下:

<!--more-->

```shell
$ printf "123\n24567\n8930\n234\n" | grep -P '(?<!2)3' 
```

但是仍然报错和上面报错相同, 然后就考虑是不是版本问题, 

```shell
$ grep --v
grep (BSD grep, GNU compatible) 2.6.0-FreeBSD
```

尝试更新,

```shell
$ brew upgrade grep
Error: grep not installed
```

然后尝试安装, 

```shell
$ brew install grep
...
All commands have been installed with the prefix "g".
If you need to use these commands with their normal names, you
can add a "gnubin" directory to your PATH from your bashrc like:
PATH="/opt/homebrew/opt/grep/libexec/gnubin:$PATH"
```

安装成功, 然后根据提示往`.zshrc`添加对应环境变量`PATH`, 注意`$:PATH`的含义(追加),

查看版本,  

```shell
grep --v
grep (GNU grep) 3.10
Packaged by Homebrew
Copyright (C) 2023 Free Software Foundation, Inc.
```

现在支持上面语法`grep -P '(?<!2)3' `, 问题解决~