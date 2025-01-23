---
title: Test & Benchmark - Go
date: 2023-09-30 09:58:56
categories:
 - golang
 - practice
tags:
 - golang
 - unit test
---

## 1. Benchmark

### 1.1. `b.N` loop

Functions of the form

```
func BenchmarkXxx(*testing.B)
```

are considered benchmarks, and are executed by the `go test` command when its `-bench` flag is provided. Benchmarks are run sequentially. 

A sample benchmark function looks like this:

```go
func BenchmarkRandInt(b *testing.B) {
    for i := 0; i < b.N; i++ {
        rand.Int()
    }
}
```

The benchmark function must run the target code b.N times. During benchmark execution, **b.N is adjusted until the benchmark function lasts long enough to be timed reliably**. The output

```
BenchmarkRandInt-8   	68453040	        17.8 ns/op
```

means that the loop ran 68453040 times at a speed of 17.8 ns per loop.

### 1.2. Ignore expensive setup with timer

If a benchmark needs some **expensive setup before running**, the timer may be reset:

```go
func BenchmarkBigLen(b *testing.B) {
    big := prepare()
    // note this will reset the timer
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        big.Len()
    }
}
```

Or something like this:

```go
func BenchmarkFib(b *testing.B) {
	for n := 0; n < b.N; n++ {
		b.StopTimer()  // pause timer
		prepare()      // prepare, initial setup
		b.StartTimer() // continue counting
		funcUnderTest() // the function was tested 
	}
}
```

### 1.3. `RunParallel()`

If a benchmark needs to test performance in a parallel setting, it may use the `RunParallel` helper function; such benchmarks are intended to be used with the `go test -cpu` flag:

```go
func main() {
	testing.Benchmark(func(b *testing.B) {
		templ := template.Must(template.New("test").Parse("Hello, {{.}}!"))
		b.RunParallel(func(pb *testing.PB) {
			// Each goroutine has its own bytes.Buffer.
			var buf bytes.Buffer
			for pb.Next() {
				// The loop body is executed b.N times total across all goroutines.
				buf.Reset()
				templ.Execute(&buf, "World")
			}
		})
	})
}

```

The body function will be run in each goroutine. It should set up any goroutine-local state and then iterate until pb.Next returns false. It should not use the StartTimer, StopTimer, or ResetTimer functions, because they have global effect. It should also not call Run. 

### 1.4. Skip test

- `TestSomething(t *testing.T)` this is called *test function*
- `func BenchmarkXxx(*testing.B)` this is called *benchmark function*

`go test` run your benchmark function and does not disable run the test functions in the package. If you want to skip the test function, you can do so by passing a regex to the `-run` flag that will not match anything. I usually use

```shell
go test -run=XXX -bench=.
```

Learn more: [Unit Test Basic Commands - Go - David's Blog](https://davidzhu.xyz/post/golang/advance/005-unit-test-commands/)

### 1.5. A note on compiler optimisations

Before concluding I wanted to highlight that to be completely accurate, any benchmark should be careful to avoid compiler optimisations eliminating the function under test and artificially lowering the run time of the benchmark.

```go
var result int

func BenchmarkFibComplete(b *testing.B) {
    var r int
    for n := 0; n < b.N; n++ {
        // always record the result of Fib to prevent
        // the compiler eliminating the function call.
        r = Fib(10)
    }
    // always store the result to a package level variable
    // so the compiler cannot eliminate the Benchmark itself.
    result = r
}
```

References:

- https://pkg.go.dev/testing#hdr-Benchmarks
- https://pkg.go.dev/testing#B.RunParallel
- [How to write benchmarks in Go | Dave Cheney](https://dave.cheney.net/2013/06/30/how-to-write-benchmarks-in-go)

