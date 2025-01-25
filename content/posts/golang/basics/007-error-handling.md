---
title: Error handling - Go
date: 2023-09-08 09:13:06
categories:
 - golang
tags:
 - golang
 - 错误异常处理
---

## 0. Use `%w` instead of `%v` or `%s`

> Should I use %s or %v to format errors? `return fmt.Errorf("malformed import path %q: %v", path, err)`
>
> Neither. Use `%w` in 99.99% of cases. In the other 0.001% of cases, `%v` and `%s`probably "should" behave the same, except when the error value is `nil`, but there are no guarantees. The friendlier output of `%v` for `nil` errors may be reason to prefer `%v` (see below). 
>
> As of Go 1.13, you can use the `%w` verb, only for `error` values, which wraps the error such that it can later be unwrapped with [`errors.Unwrap`](https://golang.org/pkg/errors/#Unwrap), and so that it can be considered with [`errors.Is`](https://golang.org/pkg/errors/#Is) and [`errors.As`](https://golang.org/pkg/errors/#As).
>
> [Stackoverflow](https://stackoverflow.com/a/61287626/16317008)

```go
type ErrorKind int

const (
    KindDatabase ErrorKind = iota
    KindNotFound
    //KindValidation
    //KindUnauthorized
)

type ServerError struct {
    Kind    ErrorKind
    Message string
    Err     error
}

// *ServerError implements error interface
func (e *ServerError) Error() string {
    if e.Err != nil {
       return fmt.Sprintf("%s: %v", e.Message, e.Err)
    }
    return e.Message
}

// 这里添加 Is() 方法是为了 自定义 通过 errors.Is(err, target error) 比较错误时的比较逻辑
// 可以看到函数体中 我们先把 target 转为 *ServerError 再进行判断
// 这是因为 target 类型是 error 接口, 无法访问 Kind field 
// 可是为什么我们的 Is() 函数的参数是 error 类型, 而不能是 *ServerError 类型呢?
// 还记得前面我们说的为什么要定义这个函数吗, 为了使用 errors.Is() 来比较两个我们的自定义错误是不是同一个 ErrorKind
// 你不知道的是 errors.Is() 内部会尝试调用两个参数的 Is() 方法 来判断两个 error 是否相等, 
// 若我们的 Is() 方法的参数是 *ServerError 类型, 则会导致调用失败,
// 因为 errors.Is(err, target error) 中的 err 和 target 都是 error 类型, 而不是 *ServerError 类型
func (e *ServerError) Is(target error) bool {
    // 将 target (interface) 转换为 *ServerError 类型, 并将结果存储在 t 中
    var t *ServerError
    ok := errors.As(target, &t)

    if !ok {
       return false
    }
    return e.Kind == t.Kind
}

func NewDatabaseError(msg string, err error) *ServerError {
    return &ServerError{
       Kind:    KindDatabase,
       Message: msg,
       Err:     err,
    }
}

func NewNotFoundError(msg string, err error) *ServerError {
    return &ServerError{
       Kind:    KindNotFound,
       Message: msg,
       Err:     err,
    }
}
```

```go
func main() {
    // 创建两个基础错误
    baseErr1 := NewDatabaseError("connection failed", nil)
    baseErr2 := NewDatabaseError("query failed", nil)
    // 它们的 Kind 相同，但 Message 不同

    // 1. 直接比较
    fmt.Println(errors.Is(baseErr1, baseErr2)) // true
    // 为什么是 true？因为我们的 Is() 方法只比较 Kind 字段
    
    // 2. 使用 %w 包装
    wrap1 := fmt.Errorf("operation failed: %w", baseErr1)
    fmt.Println(errors.Is(wrap1, baseErr2)) // true
    // 为什么是 true？因为：
    // - %w 保持了错误链，errors.Is 可以通过 Unwrap 找到 baseErr1
    // - 然后调用 baseErr1.Is(baseErr2)
    // - 发现两者的 Kind 都是 KindDatabase，返回 true

    // 3. 使用 %v 包装
    wrap2 := fmt.Errorf("operation failed: %v", baseErr1)
    fmt.Println(errors.Is(wrap2, baseErr2)) // false
    // 为什么是 false？因为：
    // - %v 只是创建了一个新的字符串错误，切断了错误链
    // - wrap2 变成了一个普通的 error，没有 Unwrap 方法
    // - errors.Is 无法找到原始的 baseErr1
    // - 所以无法调用 baseErr1.Is(baseErr2)
    
    // 4. 验证错误种类
    dbErr := NewDatabaseError("some error", nil)
    notFoundErr := NewNotFoundError("not found", nil)
    fmt.Println(errors.Is(dbErr, notFoundErr)) // false
    // 为什么是 false？因为：
    // - dbErr.Is(notFoundErr) 比较了两者的 Kind
    // - 一个是 KindDatabase，一个是 KindNotFound，不相等
    
    // 5. 错误链示例
    origErr := errors.New("原始错误")
    serverErr := NewDatabaseError("db error", origErr) // origErr 存储在 Err 字段
    wrapServerErr := fmt.Errorf("wrap: %w", serverErr)
    
    fmt.Printf("serverErr: %v\n", serverErr)      // 输出: db error: 原始错误
    fmt.Printf("wrapServerErr: %v\n", wrapServerErr) // 输出: wrap: db error: 原始错误
}
```

`errors.Is(err, target error)` 的工作流程：

- 先尝试 Unwrap 找到原始错误
- 然后调用其参数 `err ` 和 `target` 各自的 Is() 方法进行比较
- 如果找不到原始错误（比如用 %v 包装），就无法进行比较

这也是为什么例子 `1.` 会返回 true, 也是为什么我们要自定义 `Is()` 函数 

关键点解释：

1. `*ServerError` 的 `Is()` 方法的参数为什么是 `error` 而不是 `*ServerError`：
   - `errors.Is(err, target error)` 会尝试在这两个参数上调用 `Is` 方法
   - 如果我们的 `Is` 方法参数是 `*ServerError`，那么当 `target` 是普通的 `error` 时，就无法调用这个方法
   - 所以参数必须是 `error` 接口类型，然后在方法内部用 `errors.As` 转换为具体类型

2. `%w` vs `%v` 的区别：
   - `%w` 维持错误链，让 `errors.Is` 能够找到并使用原始错误的比较逻辑
   - `%v` 创建新的错误，切断错误链，使得无法使用原始错误的比较逻辑

3. `ServerError` 的 `Is` 方法实现：
   - 只比较 `Kind` 字段，忽略 `Message` 和 `Err` 字段
   - 使得同类型的错误（比如所有数据库错误）可以被认为是相等的
   - 这种设计允许我们基于错误类型而不是具体消息来处理错误

## 1.`error` interface

The `error` type is an interface type. An `error` variable represents any value that **can** describe itself as a string.

```go
type error interface {
    Error() string
}
```

Interface `error` is a built-in type, as with all other built in types, is [predeclared](https://go.dev/doc/go_spec.html#Predeclared_identifiers) in the [universe block](https://go.dev/doc/go_spec.html#Blocks). The most commonly-used `error` implementation is the [errors](https://go.dev/pkg/errors/) package’s **unexported** `errorString` type.

```go
// errorString is a trivial implementation of error.
type errorString struct {
    s string
}

func (e *errorString) Error() string {
    return e.s
}
```

`errorString` is an unexported type which means we cannot use it directly outside of [errors](https://go.dev/pkg/errors/) package, but we can use `New` function declared in the same package to create a value of `errorString`. 

``` go
// New returns an error that formats as the given text.
func New(text string) error {
    return &errorString{text}
}
```

The type of function returns is an `error` but it actually returns a pointer, a little weird probably for newb from c++. In Go everything can implement a interface an `int`, `string` even a `pointer`. It's all about if the method set of that type contians all the methods declared in a interface, learn more: [Methods Receivers & Concurrency - Go - David's Blog](https://davidzhu.xyz/post/golang/basics/013-methods-receivers/#3-pointer-receiver---a-practical-example)

## 2. Summarize the context

### 2.1. Ways to create an error value

You can create an `error` with these functions:

- `errors.New()`, 
- `fmt.Errorf()`, often used to provide conetxt. 
- Use a custom error type, typically used for provide error details. 

### 2.2. Summarize the context when create an error value

**It is the error implementation’s responsibility to summarize the context.** The error returned by `os.Open` formats as “open /etc/passwd: permission denied,” not just “permission denied.” 

```go
func Sqrt(f float64) (float64, error) {
    if f < 0 {
    	return 0, fmt.Errorf("math: square root of negative number %g", f)
		}
    // implementation
}
```

```go
if err != nil {
  return nil, fmt.Errorf("math: failed to calculate sqrt: %v", err)
}
```

## 3. Some common ways for error handling 

We have talked that there are three ways to create an error, now let's discuss how to use them in practice. 

### 3.1. Create error value with a custom error type - provide details

In many cases `fmt.Errorf` is good enough, but since `error` is an interface, you can use arbitrary data structures as error values, to allow callers to inspect the details of the error. 

The [json](https://go.dev/pkg/encoding/json/) package specifies a `SyntaxError` type that the `json.Decode` function returns when it encounters a syntax error parsing a JSON blob.

```go
type SyntaxError struct {
    msg    string // description of error
    Offset int64  // error occurred after reading Offset bytes
}

func (e *SyntaxError) Error() string { return e.msg }
```

The `Offset` field isn’t even shown in the default formatting of the error, but callers can use it to add file and line information to their error messages:

```go
if err := dec.Decode(&val); err != nil {
    if serr, ok := err.(*json.SyntaxError); ok {
        // serr.Offset provide detials about error
        line, col := findLine(f, serr.Offset)
        return fmt.Errorf("%s:%d:%d: %v", f.Name(), line, col, err)
    }
    return err
}
```

### 3.2. Don't return error dirctly - avoid repetitive error handling

#### 3.2.1. Return a `bool` value instead to indicate an abnormal state

Here’s a simple example from the `bufio` package’s [`Scanner`](https://go.dev/pkg/bufio/#Scanner) type. Its [`Scan`](https://go.dev/pkg/bufio/#Scanner.Scan) method performs the underlying I/O, which can of course lead to an error. Yet the `Scan` method does not expose an error at all. Instead, it returns a boolean, and a separate method, to be run at the end of the scan, reports whether an error occurred. Client code looks like this:

```go
scanner := bufio.NewScanner(input)
for scanner.Scan() {
    token := scanner.Text()
    // process token
}
if err := scanner.Err(); err != nil {
    // process the error
}
```

Sure, there is a nil check for an error, but it appears and executes only once. The `Scan` method could instead have been defined as

```go
func (s *Scanner) Scan() (token []byte, error)
```

and then the example user code might be (depending on how the token is retrieved),

```
scanner := bufio.NewScanner(input)
for {
    token, err := scanner.Scan()
    if err != nil {
        return err // or maybe break
    }
    // process token
}
```

This isn’t very different, but there is one important distinction. In this code, the client must check for an error on every iteration, but in the real `Scanner` API, the error handling is abstracted away from the key API element, which is iterating over tokens. With the real API, the client’s code therefore feels more natural: loop until done, then worry about errors. Error handling does not obscure the flow of control.

#### 3.2.1. Return nothing 

```go
_, err = fd.Write(p0[a:b])
if err != nil {
    return err
}
_, err = fd.Write(p1[c:d])
if err != nil {
    return err
}
_, err = fd.Write(p2[e:f])
if err != nil {
    return err
}
// and so on
```

The code above is very repetitive. A function literal closing over the error variable would help:

```go
var err error
write := func(buf []byte) {
    if err != nil {
        return
    }
    _, err = w.Write(buf)
}
write(p0[a:b])
write(p1[c:d])
write(p2[e:f])
// and so on
if err != nil {
    return err
}
```

This pattern works well, but requires a closure in each function doing the writes; a separate helper function is clumsier to use because the `err` variable needs to be maintained across calls (try it).

We can make this cleaner, more general, and reusable by borrowing the idea from the `Scan` method above.

I defined an object called an `errWriter`, something like this:

```go
type errWriter struct {
    w   io.Writer
    err error
}
```

and gave it one method, `write.` It doesn’t need to have the standard `Write` signature, and it’s lower-cased in part to highlight the distinction. The `write` method calls the `Write` method of the underlying `Writer` and records the first error for future reference:

```go
func (ew *errWriter) write(buf []byte) {
    if ew.err != nil {
        return
    }
    _, ew.err = ew.w.Write(buf)
}
```

As soon as an error occurs, the `write` method becomes a no-op but the error value is saved.

Given the `errWriter` type and its `write` method, the code above can be refactored:

```go
ew := &errWriter{w: fd}
ew.write(p0[a:b])
ew.write(p1[c:d])
ew.write(p2[e:f])
// and so on
if ew.err != nil {
    return ew.err
}
```

This is cleaner, even compared to the use of a closure, and also makes the actual sequence of writes being done easier to see on the page. There is no clutter anymore. Programming with error values (and interfaces) has made the code nicer.

In fact, this pattern appears often in the standard library. The [`archive/zip`](https://go.dev/pkg/archive/zip/) and [`net/http`](https://go.dev/pkg/net/http/) packages use it. More salient to this discussion, the [`bufio` package’s `Writer`](https://go.dev/pkg/bufio/) is actually an implementation of the `errWriter` idea. Although `bufio.Writer.Write` returns an error, that is mostly about honoring the [`io.Writer`](https://go.dev/pkg/io/#Writer) interface. The `Write` method of `bufio.Writer` behaves just like our `errWriter.write` method above, with `Flush` reporting the error, so our example could be written like this:

```go
b := bufio.NewWriter(fd)
b.Write(p0[a:b])
b.Write(p1[c:d])
b.Write(p2[e:f])
// and so on
if b.Flush() != nil {
    return b.Flush()
}
```

There is one significant drawback to this approach, at least for some applications: there is no way to know how much of the processing completed before the error occurred. If that information is important, a more fine-grained approach is necessary. Often, though, an all-or-nothing check at the end is sufficient.

We’ve looked at just one technique for avoiding repetitive error handling code. Keep in mind that the use of `errWriter` or `bufio.Writer` isn’t the only way to simplify error handling, and this approach is not suitable for all situations. The key lesson, however, is that errors are values and the full power of the Go programming language is available for processing them.

References:

- [Error handling and Go - The Go Programming Language](https://go.dev/blog/error-handling-and-go)
- [Errors are values - The Go Programming Language](https://go.dev/blog/errors-are-values)