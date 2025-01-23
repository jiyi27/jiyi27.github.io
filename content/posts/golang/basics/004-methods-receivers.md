---
title: Methods Receivers & Concurrency - Go
date: 2023-09-02 22:18:20
categories:
 - golang
 - basics
tags:
 - golang
 - concurrency
---

## 1. Different behaviors - pointer and value receiver

**修改能力**:

值接收器：方法内部操作的是结构体的副本，无法修改原始数据

指针接收器：方法可以直接修改原始结构体的数据

**内存效率**: 

```golang
type BigStruct struct {
    data [1024]int  // 很大的数组
}

// 值接收器：每次调用都会复制整个结构体
func (b BigStruct) Process() { }

// 指针接收器：只复制指针（8字节）
func (b *BigStruct) ProcessEfficient() { }
```

> **NOTE:** Generally, in practice, we seldom use pointer types whose base types are slice types, map types, channel types, function types, string types and interface types. The costs of copying values of these assumed base types are very small. 
>
> Source: https://go101.org/article/value-copy-cost.html

**表达意图:**

使用指针接收器更清晰地表达这是一个有状态的对象, 不需要拷贝值, 而是所有方法都访问相同的一个值. 

## 2. 例子

有如下接口, 

```go
type UserRepository interface {
	Create(user *types.User) error
	GetByID(id string) (*types.User, error)
}
```

即所有实现该接口的类型都可以, 比如指针:

```go
type PostgresUserRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresUserRepository(pool *pgxpool.Pool) repos.UserRepository {
	return &PostgresUserRepository{pool: pool}
}

func (s *PostgresUserRepository) Create(user *types.User) error {
	return nil
}

func (s *PostgresUserRepository) GetByID(id string) (*types.User, error) {
	return nil, nil
}
```

也就是说 `*PostgresUserRepository` 实现了 `UserRepository`, 因此 可以有如下代码:

```go
type UserHandler struct {
	userRepo UserRepository
}

func NewUserHandler(us repos.UserRepository) *UserHandler {
	return &UserHandler{userRepo: us}
}

repo := &PostgresUserRepository{} // 指针
svc := NewUserHandler(repo)       // repo 是接口类型, 指针 *PostgresUserRepository 实现了该接口
```

## 3. Method receivers in concurrency

I came across a satement about when to use value receiver but forget where I found:

> You should notice that ***value receivers* are concurrency safe, while *pointer receivers* are not concurrency safe.** So if there is no a lot copy, and you don't need modify any field of the value, try to use value receiver.

Is this correct, yes it's correct to some extend, but things probably are more complicated when come across concurrent programming. 

I find a good [blog](https://dave.cheney.net/2016/03/19/should-methods-be-declared-on-t-or-t) talks about this written by [Dave Cheney](https://dave.cheney.net/), and I'll share some parts of the blog here:

Obviously if your method mutates its receiver, it should be declared on `*T`. However, if the method does not mutate its receiver, is it safe to declare it on `T` instead `*T`?

It turns out that the cases where it is safe to do so are very limited. For example, it is well known that you should not copy a `sync.Mutex` value as that breaks the invariants of the mutex. As mutexes control access to other things, they are frequently wrapped up in a `struct` with the value they control:

```go
package counter

type Val struct {
        mu  sync.Mutex
        val int
}

func (v *Val) Get() int {
        v.mu.Lock()
        defer v.mu.Unlock()
        return v.val
}

func (v *Val) Add(n int) {
        v.mu.Lock()
        defer v.mu.Unlock()
        v.val += n
}
```

Most Go programmers know that it is a mistake to forget to declare the `Get` or `Add` methods on the pointer receiver `*Val`. However any type that embeds a `Val` to utilise its zero value, must also only declare methods on its pointer receiver otherwise it may inadvertently copy the contents of its embedded type’s values.

```go
type Stats struct {
        a, b, c counter.Val
}

func (s Stats) Sum() int {
        return s.a.Get() + s.b.Get() + s.c.Get() // whoops
}
```

A similar pitfall can occur with types that maintain slices of values, and of course there is the possibility for an [unintended data race](http://dave.cheney.net/2015/11/18/wednesday-pop-quiz-spot-the-race).

In short, I think that you should prefer declaring methods on `*T` unless you have a strong reason to do otherwise.



