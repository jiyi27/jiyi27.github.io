---
title: Don't Overuse Channel - Go
date: 2023-09-29 20:44:55
categories:
 - golang
 - practice
tags:
 - golang
---

In [previous post](https://davidzhu.xyz/post/golang/advance/006-closures-go/#21-pass-behaviour) we know that **don't mediate the access to shared memory with locks and mutexes** instead share that memory by communicating. However, is this always true? Sometimes you may want mutex and lock not channels, it depends on the situation. Channel is a way help mutiple groutines communicate with each other. I find some posts and share it here:

[**Use a sync.Mutex or a channel?**](https://github.com/golang/go/wiki/MutexOrChannel#use-a-syncmutex-or-a-channel)

One of Go's mottos is *"Share memory by communicating, don't communicate by sharing memory."*

That said, Go does provide traditional locking mechanisms in the [sync package](https://pkg.go.dev/sync/). Most locking issues can be solved using either channels or traditional locks. So which should you use?

Use whichever is most expressive and/or most simple.

A common Go newbie mistake is to over-use channels and goroutines just because it's possible, and/or because it's fun. Don't be afraid to use a [`sync.Mutex`](https://pkg.go.dev/sync/#Mutex) if that fits your problem best. Go is pragmatic in letting you use the tools that solve your problem best and not forcing you into one style of code.

As a general guide, though:

| **Channel**                                                  | **Mutex**     |
| ------------------------------------------------------------ | ------------- |
| passing ownership of data, distributing units of work, communicating async results | caches, state |

If you ever find your sync.Mutex locking rules are getting too complex, ask yourself whether using channel(s) might be simpler.

[**Wait Group**](https://github.com/golang/go/wiki/MutexOrChannel#wait-group)

Another important synchronisation primitive is sync.WaitGroup. These allow co-operating goroutines to collectively wait for a threshold event before proceeding independently again. 

Channel communication, mutexes and wait-groups are complementary and **can be combined.**

Source: [MutexOrChannel · golang/go Wiki](https://github.com/golang/go/wiki/MutexOrChannel)

----

**Mutexes are faster than channels.** My rule of thumb is, if you can do what you need to do with one mutex, there's no problem with that. For instance, **concurrent map access, or some integer you need atomically incremented**, or other such simple things. 

However, you want to **never try to take two locks**. This includes bearing in mind that *if you take a lock in your function, and call something else that takes a lock, that's two locks*. Threading hell is not caused by a single lock, it is caused by trying to use more than one at a time. At that point, you generally want channels and `select`. They don't magically solve the problem. Technically you can still deadlock with channels and `select`. 

Also, performance isn't everything, but I do find it helpful to bear in mind that when using *any* of these primitives, they aren't free, even if they are cheap, and they need to pay their way. In general the way you do that sort of thing is try to ensure that when you do take a lock or send a message over a channel, you do what you can to send as big a task or chunk of information as possible. Even in a local OS process, you need to be a bit careful not to design internal APIs in a way that two processes are constantly interacting over mutexes or channels. For instance, rather than a loop where you ask the user server for a user's real name one at a time, create an API where the user server will accept the full list and return the full set in one shot. Even 13.2ns is a couple hundred cycles, and that number is also the best case, it can get worse if there is contention.

Source: https://www.reddit.com/r/golang/comments/d85d0l/comment/f17m5e8/?utm_source=share&utm_medium=web2x&context=3

----

This is just an example for demonstrating passing behavior with function, don't over-use channel:

```go
func newChannelStore() *Store {
	s := &Store{ops: make(chan func(map[string]*Session))}
	go s.loop()
	return s
}

type Store struct {
	ops chan func(map[string]*Session)
}

func (s *Store) addSession(session *Session)  {
	s.ops <- func(m map[string]*Session) {
		// if the key has existed in map, change the value of the key.
		// if key doesn't exist, create a new one
		m[session.id] = session
	}
}

func (s *Store) getSession(id string) *Session {
	result := make(chan *Session, 1)
	s.ops <- func(m map[string]*Session) {
		// everything copied by value, session is a copy of m[id]
		// you should consider if session has pointer field
		session, ok := m[id]
		if !ok {
			result <- nil
			return
		}
		result <- session
	}
	// wait ops finish
	return <-result
}

func (s *Store) loop() {
	sessions := make(map[string]*Session)
	for op := range s.ops {
		op(sessions)
	}
}
```

The code below has a better performance compared with code above which achieves in channel style:

```go
func newMuxStore() *store {
	return &store{
		mu:       sync.RWMutex{},
		sessions: make(map[string]*Session),
	}
}

type store struct {
	mu    sync.RWMutex
	sessions map[string]*Session
}

func (m *store) addSession(session *Session) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.sessions[session.id] = session
}

func (m *store) getSession(id string) *Session {
	m.mu.RLock()
	defer m.mu.RUnlock()
	session, ok := m.sessions[id]
	if !ok {
		return nil
	}
	return session
}
```

`session.go`:

```go
func newSession(id string, value int) *Session {
	return &Session{
		id:    id,
		value: value,
		expiry:  time.Now().Add(time.Duration(10) * time.Second).Unix(),
	}
}

type Session struct {
	id    string
	value int
	expiry int64
}
```

