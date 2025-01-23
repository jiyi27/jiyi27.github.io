---
title: Cross Compilation - Go
date: 2023-10-10 11:09:35
categories:
 - golang
 - advance
tags:
 - golang
---

## 1. What is cross compilation?

[Cross-compilation](http://en.wikipedia.org/wiki/Cross_compilation) is the process of compiling code for runing on a different OS. 

## 2. An example

There is [a question](https://stackoverflow.com/questions/23072889/why-go-programs-need-runtime-support/23072968#23072968) on Stackoverflow:

It's said that Golang is the *compiled* language, but what does it mean by *compiled*? If golang application is compiled to machine code, why can't I just distribute the binary (of course on corresponding arch and platform) instead of `go install` stuff?

> Once you compile a binary you *can* distribute it onto machines with the same architecture. You don't need go real time envorionment such as `go install,` `go run,` etc, which are just necessary for compilation. 

The go code:

```go
func main() {
	srv := http.NewServeMux()
	srv.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		_, _ = fmt.Fprintln(w, "hello world")
	})
	fmt.Println("running...")
	_ = http.ListenAndServe(":8080", srv)
}
```

Compile go program on my local machine MacOS:

```shell
$ go  build -o server main.go 
$ file server 
server: Mach-O 64-bit executable arm64
$ uname -m
arm64
```

Then copy this file to my Ubuntu server and try to run it:

```shell
# ubuntu @ ip-172-31-12-228 in ~ [13:38:04] 
$ uname -m
x86_64

# ubuntu @ ip-172-31-12-228 in ~ [13:38:09] 
$ file server
server: Mach-O 64-bit arm64 executable, flags:<|DYLDLINK|PIE>

# ubuntu @ ip-172-31-12-228 in ~ [13:38:17] 
$ ./server 
zsh: exec format error: ./serve
```

Then I tried add `GOOS=linux` when compile it on my Mac,  and it works:

```shell
$ GOOS=linux GOARCH=amd64 go build -o server main.go 
```

Run on my Ubuntu server:

```shell
# Note the output 'statically linked'
$ file server 
server: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, Go BuildID=UPJ7jqIdP4OxbRX0df1Y/Xoh0f7edlCBhoN_dKDuV/xIAf8LzXqSyYE4r7v3Rq/Jq_3l1_5WQhsiIkApqgj, with debug_info, not stripped

$ ./server
running...
```

So once you compile a binary you *can* distribute it onto machines **with the same architecture**. You don't need go real time envorionment to run it. This is the power of compiled language. 

## 3. Cross-compilation

I found [a post](https://opensource.com/article/21/1/go-cross-compiling), share it here:

The Bash shell and the Python interpreter are available on most Linux servers of any architecture. Hence, everything had worked well before.

However, now I was dealing with a **compiled language**, Go, which produces an executable binary. The compiled binary consists of [opcodes](https://en.wikipedia.org/wiki/Opcode) or assembly instructions that **are tied to a specific architecture**. That's why I got the format error. Since the Arm64 CPU (where I ran the binary) could not interpret the binary's x86-64 instructions, it errored out. Previously, the shell and Python interpreter took care of the underlying opcodes or architecture-specific instructions for me.

I checked the Golang docs and discovered that to produce an Arm64 binary, all I had to do was set two environment variables when compiling the Go program before running the `go build` command.

`GOOS` refers to the operating system (Linux, Windows, BSD, etc.), while `GOARCH` refers to the architecture to build for.

```shell
$ env GOOS=linux GOARCH=arm64 go build -o prepnode_arm64
```

### 3.1. What about other architectures?

x86 and Arm are two of the five architectures I test software on. I was worried that Go might not support the other ones, but that was not the case. You can find out which architectures Go supports with:

```shell
$ go tool dist list
aix/ppc64
android/386
android/amd64
android/arm
android/arm64
darwin/amd64
darwin/arm64
windows/386
windows/amd64
.....
```

Generatiing binaries for all of the architectures under my test is as simple as writing a tiny shell script from my x86 laptop:

```bash
#!/usr/bin/bash
archs=(amd64 arm64 ppc64le ppc64 s390x)

for arch in ${archs}
do
	env GOOS=linux GOARCH=${arch} go build -o prepnode_${arch}
done
```

