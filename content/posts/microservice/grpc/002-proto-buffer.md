---
title: Ptotocol Buffers
date: 2024-01-19 00:01:08
categories:
 - grpc
tags:
 - grpc
---

## 1. Quick start

Execute the following commands at your terminal, you don't need to execute them under your project folder, just execute them anywhere, it will install the `protoc` compiler and the `protoc-gen-go` and `protoc-gen-go-grpc` plugins into your `$GOPATH/bin` folder.

```shell
# install protoc compiler
$ brew install protobuf
$ protoc --version  # Ensure compiler version is 3+

# install plugins for 
$ go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
$ go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
```

> Update your `$PATH` so that the protoc compiler can find the plugins: `export PATH="$PATH:$(go env GOPATH)/bin"`

## 2. Usage

`protoc` 命令的基本用法是 `protoc [OPTION] PROTO_FILES`, 其中 `OPTION` 包括搜索路径参数, 语言插件参数等, `PROTO_FILES` 是要编译的 `.proto` 文件. 可以通过 `protoc --help` 查看所有参数. 下面主要介绍 `[OPTION]` 参数.

### 2.1. 搜索路径参数
- `-IPATH` 或 `--proto_path=PATH`: 指定搜索 `.proto` 文件的目录
  - 如: `-I.` 表示在当前目录下搜索
  - 如果不指定该参数，则默认在当前路径下进行搜索

### 2.2. 语言插件 `protoc-gen-go`

protoc 本身支持多种语言, --cpp_out=，--python_out=等, 但不支持 Go 由google维护，需要安装 protoc 插件：

```shell
$ go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
```

[之前介绍了 `go install`](https://davidzhu.xyz/post/golang/basics/000-modules-env/)会把 `protoc-gen-go` 安装到 `$GOPATH/bin` 目录下, 之后就可以在 `protoc` 命令中使用 `--go_out` 等参数了. 

> 注意: protoc-gen-go 要求 pb (`.proto`) 文件中必须指定 go 包的路径, 例如 `option go_package = "github.com/shwezhu/consignment-service/proto/consignment"`. 
> 文件结构: `consignment-service/proto/consignment/consignment.proto` 

```shell
$ protoc I. --go_out=. --go_opt=paths=source_relative \
    --go-grpc_out=. --go-grpc_opt=paths=source_relative \
    chat.proto

# or
$ protoc I. --go_out=. --go_opt=paths=import \
    --go-grpc_out=. --go-grpc_opt=paths=import \
    chat.proto
```

解释:

- `--go_out=.`
  - 作用: 指定go代码生成的基本路径
  - 属于哪个插件：这个参数是为 protoc-gen-go 插件设置的
- `--go_opt=paths=source_relative`
  - 属于哪个插件：这同样是为 protoc-gen-go 插件设置的
  - 一般有两个值: `paths=source_relative` 和 `paths=import`
  - `paths=source_relative`: 例如你的 `.proto` 文件位于 `proto/myapp/myproto.proto`, 若使用 `paths=source_relative` 选项，生成的 Go 文件将会在类似 `myapp/myproto.pb.go` 的路径下
  - `paths=import`: 例如你在 `myproto.proto` 文件中指定了 `option go_package = "github.com/example/project/proto";`，那么无论 `.proto` 文件的实际位置在哪里，生成的 Go 文件都将使用这个路径作为包路径
- `--go-grpc_out=.`
  - 属于哪个插件：这个参数是为 protoc-gen-go-grpc 插件设置的
- - `--go-grpc_opt=paths=source_relative`
  - 属于哪个插件：这是为 protoc-gen-go-grpc 插件设置的

> `protoc-gen-go` vs `protoc-gen-go-grpc`: The old-way is using `protoc-gen-go` that generates both serialization of the protobuf messages and grpc code. Now `protoc-gen-go` no longer supports generating gRPC service definitions. For gRPC code, a new plugin called `protoc-gen-go-grpc` was developed by Go gRPC project. [source](https://stackoverflow.com/a/64849053/16317008)

### 2.3. grpc go 插件

`protoc-gen-go` 纯粹用来生成pb(`.proto`)序列化相关的文件, 不再承载 gRPC 代码生成功能, 生成gRPC相关代码需要安装 grpc-go 相关的插件 `protoc-gen-go-grpc`, 安装命令如下:

```shell
$ go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
```

插件 `protoc-gen-go-grpc` 也有两个参数, 类似 `protoc-gen-go` 插件的 `--go_out`, `--go_opt` 参数, 分别是 `--go-grpc_out`, `--go-grpc_opt`, 用法也是一样的,

## 3. Example 

文件结构如下:

```shell
❯ tree -L 4
.
├── Makefile
├── go.mod
├── proto
│   └── calculator.proto
```

`calculator.proto`:
```protobuf
syntax = "proto3";

// "./pb" 指定了生成的 Go 文件将被放置在相对路径 ./pb 的目录下
// 这里的相对路径是相对于 protoc 命令执行的目录, 而不是相对于 .proto 文件的目录
// protoc-gen-go 要求 `.proto` 文件必须指定 go 包的路径
option go_package = "./pb";

service Calculator {
  rpc Add(CalculationRequest) returns (CalculationResponse);
  rpc Subtract(CalculationRequest) returns (CalculationResponse);
  rpc Multiply(CalculationRequest) returns (CalculationResponse);
  rpc Divide(CalculationRequest) returns (CalculationResponse);
  rpc Sum(NumbersRequest) returns (CalculationResponse);
}

message CalculationRequest {
  int64 a = 1;
  int64 b = 2;
}

message CalculationResponse { int64 result = 1; }

message NumbersRequest { repeated int64 numbers = 1; }
```

`Makefile`:
```shell
# run: make generate
generate:
	protoc --proto_path=proto proto/*.proto --go_out=. --go-grpc_out=.

# 1. 上面使用的所有路径都是相对 protoc 命令执行时所在的目录

# 2. --proto_path=proto: 指定 .proto 文件的搜索路径, 在这，编译器会在名为 proto 的目录下查找 .proto 文件,
# 你也可以使用 -IPATH 命令行参数来指定搜索路径 如 protoc -I. --go_out=. --go-grpc_out=. proto/*.proto
# proto/*.proto : 指定要编译的 .proto 文件，这里我们指定了 proto 目录下的所有 .proto 文件,
# 不指定会报错, 因为 protoc 需要知道要编译哪个文件, 你可以使用如 proto/xxx.proto

# 3. --go_out=.: 还记得我们在 .proto 文件中指定了 go_package="./pb" 吗,
# --go_out=. 为 go_package 指定了所在的工作目录, 举例:
# 若你使用 --go_out=abc, go_package="./pb", 则生成的文件会放在 abc/pb 目录下, 前提是你得先创建 abc 目录
# 我们在这指定的是 --go_out=., 所以最终生成的文件会放到 ./pb 目录下
```

执行 `make generate` 命令, 文件结构如下:

```shell
❯ tree -L 4
.
├── Makefile
├── go.mod
├── pb
│   ├── calculator.pb.go
│   └── calculator_grpc.pb.go
├── proto
│   └── calculator.proto
```

安装 grpc 包, 编写程序:

```shell
❯ go get google.golang.org/grpc
```

创建文件 `server/main.go` (我省略了一些代码):

```go
package main

type server struct {
	pb.UnimplementedCalculatorServer
}

func (s *server) Add(
	ctx context.Context,
	in *pb.CalculationRequest,
) (*pb.CalculationResponse, error) {
	return &pb.CalculationResponse{
		Result: in.GetA() + in.GetB(),
	}, nil
}

func main() {
	listener, err := net.Listen("tcp", ":8080")
	if err != nil {
		log.Fatalln("failed to create listener:", err)
	}

	s := grpc.NewServer()
	// binds the Calculator service implementation to the gRPC server s.
	pb.RegisterCalculatorServer(s, &server{})
	if err := s.Serve(listener); err != nil {
		log.Fatalln("failed to serve:", err)
	}
}
```

最后文件结构如下:

```shell
❯ tree -L 4
.
├── Makefile
├── go.mod
├── go.sum
├── pb
│   ├── calculator.pb.go
│   └── calculator_grpc.pb.go
├── proto
│   └── calculator.proto
└── server
    └── main.go
```

运行服务器:

```shell
❯ go run server/main.go
```

## 4. References

[(1) When RESTful architecture isn't enough...](https://www.youtube.com/watch?v=_4TPM6clQjM&t=5s)

