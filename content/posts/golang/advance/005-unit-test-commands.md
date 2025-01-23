---
title: Unit Test Basic Commands - Go
date: 2023-09-05 15:10:18
categories:
 - golang
 - advance
tags:
 - golang
 - unit test
---

## 1. Useful commands

```shell
$ go test -run "ExampleSession|TestSession" -v
```

> Note that the `-run` flag is used for specifying test functions, **not** benchmarks, **not** fuzz test. Because example test is similar to test function, you can specify both example and test function with `-run` flag. If you want to specify benchmarks, use `-bench` flag:

```shell
-bench regexp
	Run benchmarks matching the regular expression.
-run regexp
	Run only tests and examples matching the regular expression.

# Flags below can be used with flags above.
-race
	enable data race detection.
-cover
	enable code coverage instrumentation.
```

> Note that `-bench` does not disable the normal `test` selection. If you want run the benchmark test **only** you should pass `-run=xxx` to disable the normal test selection.

```shell
go test -run=xxx -bench 'BenchmarkDirectRead|BenchmarkLimitedRead'

# just one function, no single quote is fine: 
$ go test -run=xxx -bench BenchmarkStore
```
        
Learn more: [go command - cmd/go - Go Packages](https://pkg.go.dev/cmd/go#hdr-Testing_flags) 

## 2. `-bench` & `-benchmem`

The benchmark tool only reports heap allocations. Stack allocations via escape analysis are less costly, possibly free, so are not reported.

```shell
❯ go test -run=xxx -bench 'BenchmarkDirectRead|BenchmarkLimitedRead' -benchmem
BenchmarkDirectRead-8    38036484       31.47 ns/op      48 B/op      1 allocs/op
BenchmarkLimitedRead-8      12315       97480 ns/op      72 B/op      2 allocs/op
```

The `-8` indicates that these benchmarks were run with a GOMAXPROCS value of 8, meaning up to 8 OS threads were used concurrently. This is typically set to the number of CPU cores available.

`38036484`` for BenchmarkDirectRead and `12315`` for BenchmarkLimitedRead are the number of iterations the benchmark function was executed.

`48 B/op`: This means that on average, 48 bytes are being allocated per operation (op) in the benchmarked function.

Source:

- https://stackoverflow.com/questions/56832207/golang-benchmark-why-does-allocs-op-show-0-b-op
- https://stackoverflow.com/a/35588683/16317008

