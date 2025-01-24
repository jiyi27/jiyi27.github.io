---
title: Gorilla Sessions RedisStore Source Code Analysis
date: 2023-10-01 12:12:50
categories:
 - golang
tags:
 - golang
 - redis
---

To prevent data race, `store.Get()` always creates a new session (or make a copy) and returns the session to user. 

```go
// Get a session.
// A copied one or new session.
session, _ = store.Get(req, "session-key")
// Add a value.
session.Values["foo"] = "bar"
// Save.
_ = sessions.Save(req, rsp)
```

Let's check the source code, the `Get()` method of Redistore:

```go
func (s *RediStore) Get(r *http.Request, name string) (*sessions.Session, error) {
	return sessions.GetRegistry(r).Get(s, name)
}

// GetRegistry returns a registry instance for the current request.
func GetRegistry(r *http.Request) *Registry {
	var ctx = r.Context()
	registry := ctx.Value(registryKey)
	if registry != nil {
		return registry.(*Registry)
	}
	newRegistry := &Registry{
		request:  r,
		sessions: make(map[string]sessionInfo),
	}
	*r = *r.WithContext(context.WithValue(ctx, registryKey, newRegistry))
	return newRegistry
}
```

For each request they are different, even that two request from a same client. So for each new request when the server call `store.Get()` there will be a registry created. Only when you call `store.Get()` more than once in a handler, the `registry := ctx.Value(registryKey)` will return a non-nil `registry`:

```go
// Get a session.
session, _ = store.Get(req, "session-key")
// Add a value.
session.Values["foo"] = "bar"
// Save.
_ = sessions.Save(req, rsp)
// Get session again
// because the req is same, the Registry
// will be the old one created druing the first store.Get() call.
session, _ = store.Get(req, "session-key")
```

After gets the `registry`, then its `Registry.Get()` will be called:

```go
// Get registers and returns a session for the given name and session store.
//
// It returns a new session if there are no sessions registered for the name.
func (s *Registry) Get(store Store, name string) (session *Session, err error) {
	if !isCookieNameValid(name) {
		return nil, fmt.Errorf("sessions: invalid character in cookie name: %s", name)
	}
  // because Registry is always created as a new one for each request
  // ok always equals to false
  // if you call store.Get() at a same handler twice or more, 
  // the Registry value will be the old one which created during the first store.Get() call
	if info, ok := s.sessions[name]; ok {
		session, err = info.s, info.e
	} else {
    // for each request, there will be a new session
    // a brand new or a copied one
		session, err = store.New(s.request, name)
		session.name = name
		s.sessions[name] = sessionInfo{s: session, e: err}
	}
	session.store = store
	return
}
```

Let's check how `store.New` work:

```go
func (s *RediStore) New(r *http.Request, name string) (*sessions.Session, error) {
	var err error
	session := sessions.NewSession(s, name)
	// make a copy
	options := *s.Options
	session.Options = &options
	session.IsNew = true
	if c, errCookie := r.Cookie(name); errCookie == nil {
    // verify the cookie
		err = securecookie.DecodeMulti(name, c.Value, &session.ID, s.Codecs...)
    // if the cookie is correct which means there is a corresponding session in the store
    // therefore, load from redistore
    // load() will makes a deep copy, which prevent data race
    // user can use the returned session safely
		if err == nil {
			ok, err := s.load(session)
			session.IsNew = !(err == nil && ok) // not new if no error and data available
		}
	}
	return session, err
}
```

Let's check `store.load()`

```go
// load reads the session from redis.
// returns true if there is a sessoin data in DB
func (s *RediStore) load(session *sessions.Session) (bool, error) {
	conn := s.Pool.Get()
	defer conn.Close()
	if err := conn.Err(); err != nil {
		return false, err
	}
	data, err := conn.Do("GET", s.keyPrefix+session.ID)
	if err != nil {
		return false, err
	}
	if data == nil {
		return false, nil // no data was associated with this key
	}
	b, err := redis.Bytes(data, err)
	if err != nil {
		return false, err
	}
	return true, s.serializer.Deserialize(b, session)
}
```

Source code: https://github.com/boj/redistore
