---
title: Go Modules and Environment
date: 2024-01-18 22:12:20
categories:
 - golang
 - basics
tags:
 - golang
---

## 初始化项目

```bash
$ mkdir my-project && cd my-project
$ go mod init github.com/username/my-project

# -------------------------

# 1. 初始化新项目
go mod init myproject

# 2. 下载缺失的依赖包并更新 go.mod
go mod tidy
```

这里解释一下 go mod tidy 的工作原理:

```bash
# 1. 首先在代码中引入包
import "github.com/gin-gonic/gin"

# 2. 然后执行 tidy 命令，它会：
# - 下载所需的依赖
# - 更新 go.mod 和 go.sum
# - 移除未使用的依赖
go mod tidy
```

可以看出 我们并不需要 `go get`, 想下载某个包, 直接在源代码里导入, 然后执行 `go mod tidy` 即可. 

## `go build` vs `go install`

1. 编译结果的存放位置

- `go build`: 在当前目录下生成可执行文件
- `go install`: 将生成的可执行文件放到 `$GOPATH/bin` 或 `$GOBIN` 目录

2. 编译结果的处理方式

- `go build`: 只生成可执行文件
- `go install`: 不仅生成可执行文件，还会将编译的中间文件放到 `$GOPATH/pkg` 目录下

3. 使用场景不同：

如果是在开发自己的项目，想要快速编译测试，使用 `go build`:

```bash
# 假设有个项目结构:
myproject/
  |- main.go
  |- utils/
      |- helper.go

# 在 myproject 目录下执行
$ go build
# 会在当前目录生成可执行文件 myproject 或 myproject.exe(Windows)

# 也可以指定输出文件名
$ go build -o app
# 会生成名为 app 的可执行文件
```

如果要安装工具**或者**部署到生产环境，使用 `go install`

```bash
# 安装远程包
# golangci-lint: 集成了多个 linter 的代码检查工具
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
# gopls: Go 官方的语言服务器，提供代码补全等功能
go install golang.org/x/tools/gopls@latest

# 安装后，这些工具会被放在 $GOBIN 目录下（默认是 $GOPATH/bin）
# 安装完成后，就可以直接在命令行中使用这些工具了，比如：
# 运行代码检查
golangci-lint run
```

## 安装/清理依赖

To add all dependencies for a package in your module, run a command like the one below ("." refers to the package in the current directory):
```shell
$go get .
$ go get github.com/example/xxmodule
```

> Go 模块会被下载到本地的模块缓存目录中, 一般在 `~/go/pkg/mod/`, 可以通过 `go env GOMODCACHE` 查看具体位置

```bash
# 删除模块
go clean -modcache github.com/example/xxmodule@v1.0.0
# 清除所有已下载的模块
go clean -modcache
# 列出所有已下载的模块
ls $(go env GOMODCACHE)
```

References: 

- [Go Modules Reference - The Go Programming Language](https://go.dev/ref/mod#go-mod-init)
- [Managing dependencies - The Go Programming Language](https://go.dev/doc/modules/managing-dependencies#naming_module)
