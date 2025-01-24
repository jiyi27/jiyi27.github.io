---
title: Static Linking Go Programs
date: 2023-10-10 12:09:35
categories:
 - golang
tags:
 - golang
 - 编译原理
---

## 1. Static linking on linux

Go creates **static binaries** by default unless you use cgo to call C code, in which case it will create a dynamically linked binary. The easiest way to check if your program is statically compiled is to run `file` on it. 

standard packages `os/user` and `net`  use cgo, so importing either (directly or indirectly) will result in a dynamic binary. 

> Note that `net` use cgo does't mean that all the codes in `net` are cgo, cgo is just used for Name Resolution(resolving domain names) and some teivial features in `net`. https://pkg.go.dev/net#section-documentation

I do this test on my Ubuntu server firstly without cgo:

```go
package main

import "fmt"

func main() {
	fmt.Println("hello")
}
```

```shell
# ubuntu @ ip-172-31-12-228 in ~/codes [19:40:23] 
$ go build -o server main.go

# ubuntu @ ip-172-31-12-228 in ~/codes [19:40:31] 
$ file server 
server: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, Go BuildID=hjbIteBvAg_rZ86av_gy/k1xYD8duMhRTtrThDrrX/5yBtTaOBDsf4F2IOwADX/U1b5vnivY9rWcRUWpC_A, with debug_info, not stripped

# ubuntu @ ip-172-31-12-228 in ~/codes [19:40:36] 
$ ldd server 
	not a dynamic executable
```

As you can see, I just use `fmt` package, and the executable file is statically linked. 

And then I change the go code to:

```go
package main

import (
	"fmt"
	"net/http"
)

func main() {
	srv := http.NewServeMux()
	srv.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		_, _ = fmt.Fprintln(w, "hello world")
	})
	fmt.Println("running...")
	_ = http.ListenAndServe(":8080", srv)
}
```

Then build it on Ubtutu machine:

```shell
# ubuntu @ ip-172-31-12-228 in ~/codes [19:47:06]
$ go build -o server main.go

# ubuntu @ ip-172-31-12-228 in ~/codes [19:47:31] 
$ file server 
server: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, Go BuildID=KCFaacb5_zSot7hqkTv8/oYQa-0nbl_Gq2_YxF6JO/BnF2hmfFNgVx-UHRKxMt/Oj91sMcK9_or35yi4Xd0, with debug_info, not stripped

# ubuntu @ ip-172-31-12-228 in ~/codes [19:47:39] 
$ ldd server 
	linux-vdso.so.1 (0x00007fff10cfb000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f4cd6200000)
	/lib64/ld-linux-x86-64.so.2 (0x00007f4cd6612000)
```

The binary file is dynamically linked as we expected. 

### 1.1. Disable dynamically linking with ` CGO_ENABLED=0` 

```shell
# ubuntu @ ip-172-31-12-228 in ~/codes [19:48:57] 
$ CGO_ENABLED=0 go build -o server main.go

# ubuntu @ ip-172-31-12-228 in ~/codes [20:11:01] 
$ file server 
server: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, Go BuildID=wGRY1RH-HeASVOwzThcj/lQNxgqzqGUe1P8n_WjN7/cEcN362GspK8XKl2L0AG/F7hVHMJfVIyYcLM6Jhz1, with debug_info, not stripped
```

> Note that the `CGO_ENABLED=0` is to disable cgo. It is disabled by default when cross-compiling. You can control this by setting the CGO_ENABLED environment variable when running the go tool: set it to 1 to enable the use of cgo, and to 0 to disable it. 
>
> If CGO_ENABLED=0 is set, the Go net package will not use cgo, and instead, it will use a pure Go implementation for its networking functionality. 
>
> Learn more: https://go-review.googlesource.com/c/go/+/12603/2/src/cmd/cgo/doc.go

## 2. Static linking on osx

On Mac, the behavior is totoally different, even don't use cgo the final executable will be dynamically linked.

```go
package main

import "fmt"

func main() {
	fmt.Println("hello")
}
```

Build on **MacOS machine**:

```shell
$ go build -o server main.go

$ file server 
server: Mach-O 64-bit executable arm64

# otool is similar to 'ldd' on linux
# -L print shared libraries used
$ otool -L server
server:
	/usr/lib/libSystem.B.dylib (compatibility version 0.0.0, current version 0.0.0)
	/usr/lib/libresolv.9.dylib (compatibility version 0.0.0, current version 0.0.0)
```

**`CGO_ENABLED=0` won't help on MaxOS**. And I found something could be explain this:

> I think this won't work on macOS, where **fully static builds are not allowed/supported by Apple**. Binaries should always go through libSystem, which is also why we changed the way Go calls the kernel in Go 1.12. So, pure Go binaries are already as static as they can be, as far as I can tell.
>
> I propose that on macOS `go build -static` simply tries to statically link cgo libraries, so that the final binary doesn't depend on third-party. So but just on system libraries. To do this, unfortunately, it looks like it's not sufficient to add the output of `pkg-config --static --libs` to `LDFLAGS` because that output still refers to each library as `-L/path/to -lfoo` (as this is the correct syntax when `--static` is passed to the linker, which we are not going to do in macOS). So, the output of `pkg-config` should be rewritten as `/path/to/libfoo.a` (using a similar library path search algorithm that the linker does).
>
> Source: https://github.com/golang/go/issues/26492#issuecomment-525527016

> Yes, I agree with Volker's comment that some systems don't really allow static binaries.
>
> Source: https://stackoverflow.com/a/61324538/16317008

Note that fully static builds are not allowed/supported by Apple doesn't mean we cannot create statically linked binaries on Mac, we can build the binary executable on other platforms, linux, for example. 

```go
package main

import (
	"fmt"
	"net/http"
)

func main() {
	srv := http.NewServeMux()
	srv.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		_, _ = fmt.Fprintln(w, "hello world")
	})
	fmt.Println("running...")
	_ = http.ListenAndServe(":8080", srv)
}
```

Build on MacOS machine with some flags:

```shell
$ GOOS=linux go build -o server main.go

$ file server                          
server: ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, Go BuildID=qAraNfnU-cYn-2KsoFx7/rrJYFJTR911CeHr08Y4E/uoFKsYV1LH9as_7QdMc7/fJ71_ARZOiNg7b4tLPIt, with debug_info, not stripped
```

As you can see, even we use the `net` package which uses cgo, it still can be statically with `GOOS=linux` flag, this is called cross compilation, learn more: [Cross Compilation - Go - David's Blog](https://davidzhu.xyz/post/golang/advance/011-cross-compilation/)

But the arch is arm64, not amd64, if you want build binary gonna runs on amd64, you should add `GOARCH=amd64` : 

```shell
$ GOOS=linux GOARCH=amd64 go build -o server main.go
```

## 3. `"-extldflags=-static"`

In previous part, we know that `CGO_ENABLED=0` will disable cgo, if we use `net` and we want statically linking, it's fine we just pass `CGO_ENABLED=0` to go build, then we will use pure go implementation of `net`. But what if we use a third party package that only implemented by cgo, [mattn/go-sqlite3](https://github.com/mattn/go-sqlite3) for example, and we want make it linked statically, apparently we can't use `CGO_ENABLED=0` to disable cgo. 

A simle cgo:

```go
package main

// typedef int (*intFunc) ();
//
// int
// bridge_int_func(intFunc f)
// {
//		return f();
// }
//
// int fortytwo()
// {
//	    return 42;
// }
import "C"
import "fmt"

func main() {
	f := C.intFunc(C.fortytwo)
	fmt.Println(int(C.bridge_int_func(f)))
	// Output: 42
}
```

Then compile it with `CGO_ENABLED=0` on Ubuntu machine:

```shell
$ CGO_ENABLED=0 go build -o server main.go
go: no Go source files

# ubuntu @ ip-172-31-12-228 in ~/codes [20:58:50] C:1
$ go build -o server main.go 

# ubuntu @ ip-172-31-12-228 in ~/codes [21:00:15] 
$ file server 
server: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=da0674602632e4f540cfe58f0be1ffa261f2eefe, for GNU/Linux 3.2.0, with debug_info, not stripped
```

Then we can use `-ldflags` to tell the C linker to statically link with `-extldflags`:

```go
-ldflags="-extldflags=-static"
```

```shell
# ubuntu @ ip-172-31-12-228 in ~/codes [21:00:18] 
$ go build -ldflags="-extldflags=-static" -o server main.go

# ubuntu @ ip-172-31-12-228 in ~/codes [21:01:41] 
$ file server 
server: ELF 64-bit LSB executable, x86-64, version 1 (GNU/Linux), statically linked, BuildID[sha1]=4031763b8f09ffcd1455840afe89c4644eca0088, for GNU/Linux 3.2.0, with debug_info, not stripped
```

Now it's statically linked. 

I hope you can understand the difference between `CGO_ENABLED=0` and `-ldflags="-extldflags=-static"` flag, and when you should use which one. Besides, you should know the different behavior on MacOS and Linux for statically linking in Go. And the two common command `ldd`,  `otool`, `file` will help you. 

Learn more: 

- [Statically compiling Go programs](https://www.arp242.net/static-go.html)
- [#!bash blog/2014/04/linking-golang-statically/](https://blog.hashbangbash.com/2014/04/linking-golang-statically/)
- [cgo | Dave Cheney](https://dave.cheney.net/tag/cgo)
- [Matt Turner - Statically Linking Go in 2022](https://mt165.co.uk/blog/static-link-go/index.html)
