---
title: encoding/gob & encoding/json in Go
date: 2023-08-31 11:38:20
categories:
 - golang
 - basics
tags:
 - golang
---

## 1. Why do we need encoding

> To transmit a data structure across a network or to store it in a file, it must be encoded and then decoded again. Cause computer just know binary. 

There are many encodings available, of course: [JSON](http://www.json.org/), [XML](http://www.w3.org/XML/), Google’s [protocol buffers](http://code.google.com/p/protobuf), and more. And now there’s another, provided by Go’s [gob](https://go.dev/pkg/encoding/gob/) package. 

## 2. encoding/gob

### 2.1. Why gob

Why define a new encoding? It’s a lot of work and redundant at that. Why not just use one of the existing formats? Well, for one thing, we do! Go has [packages](https://go.dev/pkg/) supporting all the encodings just mentioned (the [protocol buffer package](http://github.com/golang/protobuf) is in a separate repository but it’s one of the most frequently downloaded). And for many purposes, including communicating with tools and systems written in other languages, they’re the right choice.

But for a Go-specific environment, such as communicating between two servers written in Go, there’s an opportunity to build something much easier to use and possibly more efficient.

> Gob is much more preferred when communicating between Go programs. However, gob is currently supported only in Go and, well, [C](https://code.google.com/archive/p/libgob/), so only ever use that when you're sure no program written in any other programming language will try to decode the values. [source](https://stackoverflow.com/questions/41179453/difference-between-encoding-gob-and-encoding-json) 

### 2.2. Google’s Protocol Buffers misfeatures

Gobs implements thress important features compared with Google's Protocol Buffers:

- The type being encoded does't need to be a struct, it can be a map, slice, array etc...
- Don't need all fields of a type exist when decoding and encoding. 
- If the varibale being transmitted has "zero value" for its type, it doesn't need to be transmitted. Decoder know its type, it will set its default value automatically. 

### 2.3. How does gob work - value of encoded gob data is just integer

The **encoded gob data** isn’t about types like `int8` and `uint16`. Instead, somewhat analogous to constants in Go, its integer values are abstract, sizeless numbers, either signed or unsigned. When you encode an `int8`, its value is transmitted as an unsized, variable-length integer. When you encode an `string`, its value is also transmitted as an unsized, variable-length integer.

```go
func main() {
	// Initialize the encoder and decoder.  Normally enc and dec would be
	// bound to network connections and the encoder and decoder would
	// run in different processes.
	var network bytes.Buffer        // Stand-in for a network connection
	enc := gob.NewEncoder(&network) // Will write to network.
	dec := gob.NewDecoder(&network) // Will read from network.
	message := "hello, there"
	// Encode (send) the value.
	_ = enc.Encode(message)
	fmt.Println(network.Bytes())
	// Decode (receive) the value.
	var ms string
	_ = dec.Decode(&ms)
	fmt.Println(network.Bytes())
	fmt.Println(ms)
}
------------------------------------------
[15 12 0 12 104 101 108 108 111 44 32 116 104 101 114 101]
[]
hello, there
```

As you can see, all **encoded data** is a variable-length integer, `bytes.Buffer` is just a struct, network is an object of it,  `network.Bytes()` returns a slice holding the unread portion of the buffer so it print `[]` on second line, 

```go
type Buffer struct {
	buf      []byte // contents are the bytes buf[off : len(buf)]
	off      int    // read at &buf[off], write at &buf[len(buf)]
	lastRead readOp // last read operation, so that Unread* can work correctly.
}
```

Besides, `enc.Encode(message)` does two things: encode message and transmit it, similar to`dec.Decode(&ms)`.

### 2.4. Values are flattened

> A stream of gobs is **self-describing**. Each data item in the stream is preceded by a specification of its type, expressed in terms of a small set of predefined types. **Pointers are not transmitted, but the things they point to are transmitted**; that is, the values are flattened. Nil pointers are not permitted, as they have no value. **Recursive types work fine**, but recursive values (data with cycles) are problematic. [source](https://pkg.go.dev/encoding/gob#pkg-overview)

I find a [blog](https://gist.github.com/soroushjp/0ec92102641ddfc3ad5515ca76405f4d), which implement a function that can deep copy a map with gobs, even the map has a map inside. Golang: deepcopy `map[string]interface{}.` Could be used for any other Go type with minor modifications.

```go
// Package deepcopy provides a function for deep copying map[string]interface{}
// values. Inspired by the StackOverflow answer at:
// http://stackoverflow.com/a/28579297/1366283
//
// Uses the golang.org/pkg/encoding/gob package to do this and therefore has the
// same caveats.
// See: https://blog.golang.org/gobs-of-data
// See: https://golang.org/pkg/encoding/gob/
package deepcopy

import (
	"bytes"
	"encoding/gob"
)

func init() {
	gob.Register(map[string]interface{}{})
}

// Map performs a deep copy of the given map m.
func Map(m map[string]interface{}) (map[string]interface{}, error) {
	var buf bytes.Buffer
	enc := gob.NewEncoder(&buf)
	dec := gob.NewDecoder(&buf)
	err := enc.Encode(m)
	if err != nil {
		return nil, err
	}
	var copy map[string]interface{}
	err = dec.Decode(&copy)
	if err != nil {
		return nil, err
	}
	return copy, nil
}
```

### 2.5. Types on the wire

The first time you send a given type, the gob package includes in the data stream a description of that type. In fact, what happens is that the encoder is used to encode, in the standard gob encoding format, **an internal struct** that describes the type and gives it a unique number. (Basic types, plus the layout of the type description structure, are predefined by the software for bootstrapping.) After the type is described, it can be referenced by its type number.

Thus when we send our first type `T`, the gob encoder sends a description of `T` and tags it with a type number, say 127. All values, including the first, are then prefixed by that number, so a stream of `T` values looks like:

```go
("define type id" 127, definition of type T)(127, T value)(127, T value), ...
```

CommonType holds elements of all types. It is a historical artifact, kept for binary compatibility and exported only for the benefit of the package's encoding of type descriptors. It is not intended for direct use by clients.

```go
type CommonType struct {
	Name string
	Id   typeId
}
```

### 2.6. Functions and channels

Functions and channels will not be sent in a gob. Attempting to encode such a value at the top level will fail. A struct field of chan or func type is treated exactly like an unexported field and is ignored.

### 2.7. gob.Register method

Register records a type, identified by a value for that type, under its internal type name. That name will identify the concrete type of a value sent or received as an interface variable. **Only types that will be transferred as implementations of interface values need to be registered.** Expecting to be used only during initialization, it panics if the mapping between types and names is not a bijection. 

```go
func Register(value any)
```

If you're dealing with concrete types (structs) only, you don't really need it. Once you're dealing with interfaces you must register your concrete type first. 

For example, let's assume we have these struct and interface (the struct implements the interface):

```golang
type Getter interface {
    Get() string
}

type Foo struct {
    Bar string
}

func (f Foo) Get() string {
    return f.Bar
}
```

To send a `Foo` over gob **as a `Getter`** and decode it back, we must first call

```golang
gob.Register(Foo{})
```

So the flow would be:

```golang
// init and register
buf := bytes.NewBuffer(nil)
gob.Register(Foo{})    
// create a getter of Foo
g := Getter(Foo{"wazzup"})
// encode
enc := gob.NewEncoder(buf)
enc.Encode(&g)
// decode
dec := gob.NewDecoder(buf)
var gg Getter
if err := dec.Decode(&gg); err != nil {
    panic(err)
}
```

Now try removing the `Register` and this won't work because gob wouldn't know how to map things back to their appropriate type.

### 2.8. gob.Register 

When there is an interface, be careful, you should figure out all the possiable concrete types (implementations) of the interface would be, and if these concrete type is not primitive type, you need register for them. **You don't need to register for interface itself**. 

```go
gob.Register(map[string]int{})
expectedCopy := map[string]interface{}{
	"id": "0007",
	"cats": map[string]int{
		"kitten": 3,
		"milo":   1,
	},
}
```

If you don't register for `map[string]int` you will get an error 

```
error: gob: type not registered for interface: map[string]int
```

All of this because we have `map[string]interface{}`, there is an interface, according to [gob package](https://pkg.go.dev/encoding/gob), **Only types that will be transferred as implementations of interface values need to be registered.** 

You need to register for nothing if `expectedCopy` type is `map[string]map[string]int` (because there is no interface):

```go
// don't need this: gob.Register(map[string]map[string]int{})
// don't need this: gob.Register(map[string]int{})
expectedCopy := map[string]map[string]int{
	"cats": map[string]int{
		"kitten": 3,
		"milo":   1,
	},
}
```

Note that you **don't need to register for a slice of primitive type or primitive type itself** when they are the implementations of an interface, because Go has done that for you:

```go
func registerBasics() {
	Register(int(0))
  ...
	Register(float32(0))
	Register(complex64(0i))
	Register([]uint(nil))
  ...
	Register([]bool(nil))
	Register([]string(nil))
}
```

Therefore, if you want encode `expectedOriginal` below, you need register for nothing:

```go
// Go has done this for use: gob.Register([]string{})
expectedOriginal: map[string]interface{}{
	"cats": []string{"Coco", "Bella"},
},
```

If the implementation's type of the interface is a custom type, you have to register for that type:

```go
type Cat struct {
	Name string
}
// you have to register for Cat
gob.Register(Cat{})
expectedOriginal := map[string]interface{}{
	"cats": Cat{Name: "jack"},
}
```

Similarly to we have talked above:

```go
// don't need this: gob.Register(Cat{})
// there is no interface
expectedOriginal := map[string]Cat {
	"cats": Cat{Name: "jack"},
}
```

And don't forget, the first letter of the field of Cat must be Capital, namely, expored fields, otherwise, it (the field) won't encode by gob. 

```go
type Cat struct {
	Name string
}

func main() {
	m := map[interface{}][]Cat{
		"cats": []Cat{{Name: "jack"}},
	}
	buf := new(bytes.Buffer)
	enc := gob.NewEncoder(buf)
	dec := gob.NewDecoder(buf)
	if err := enc.Encode(m); err != nil {
		fmt.Sprintf("failed to copy map: %v", err)
	}
	result := make(map[interface{}][]Cat)
	if err := dec.Decode(&result); err != nil {
		fmt.Sprintf("failed to copy map: %v", err)
	}
	fmt.Println(result)
}
```

## 3. encoding/json

- `Marshal()` → to encode GO values to JSON in string format
- `Unmarshal()` → to decode JSON data to GO values

```go
func Marshal(v interface{}) ([]byte, error)
func Unmarshal(data []byte, v interface{}) error
```

### 3.1. `json.Marshal()`

```go
type Cat struct {
	// lowercase field cannot be exported
	// `json:"name"` makes "Name" to "name" in json string after apply json.Marshal()
  // check in output
	Name string `json:"name"`
	Age int
	IsAdult bool
}

func main() {
	data, _ := json.Marshal(Cat{
		Name: "Kitten",
		Age: 2,
		IsAdult: true,
	})
	println(data)
	println(string(data))

	data, _ = json.Marshal("Hello")
	println(data)
	println(string(data))
}
----------------------------------
[40/48]0x140000161b0
{"name":"Kitten","Age":2,"IsAdult":true}
[7/8]0x1400001c1a8
"Hello"
```

> ⚠️Note: *Channel*, complex, and *function* values cannot be encoded in JSON. Attempting to encode such a value causes *Marshal* to return an UnsupportedTypeError. [json package - encoding/json - Go Packages](https://pkg.go.dev/encoding/json)

In the past, if you use `json.Marshal()` to encode map, you need to ensure that the type of the key is strin, otherwise, it will fail, It's not because of Go, but because of Json: Json does not support anything else than strings for keys.

Learn more: https://stackoverflow.com/questions/24284612/failed-to-json-marshal-map-with-non-string-keys

But now you can use `json.Marshal()` to encode the map whose key's type is int, but not float:

```go
m := make(map[float32]string)
m[3] = "helllo"
b, err := json.Marshal(m)
if err != nil {
  panic(err)
}
// panic: json: unsupported type: map[float32]string
```

Therefore, you may want do something like this:

```go
// JSONSerializer encode the session map to JSON.
type JSONSerializer struct{}

// Serialize to JSON. Will err if there are unmarshalable key values
func (s JSONSerializer) Serialize(ss *sessions.Session) ([]byte, error) {
	m := make(map[string]interface{}, len(ss.Values))
	for k, v := range ss.Values {
		ks, ok := k.(string)
		if !ok {
			err := fmt.Errorf("Non-string key value, cannot serialize session to JSON: %v", k)
			fmt.Printf("redistore.JSONSerializer.serialize() Error: %v", err)
			return nil, err
		}
		m[ks] = v
	}
	return json.Marshal(m)
}
```

Code from: https://github.com/boj/redistore

Now support for non string key types for maps for json Marshal/UnMarshal has been added through the use of [TextMarshaler](https://golang.org/pkg/encoding/#TextMarshaler) and [TextUnmarshaler](https://golang.org/pkg/encoding/#TextUnmarshaler) interfaces [here](https://go-review.googlesource.com/c/go/+/20356/1). You could just implement these interfaces for your key types and then `json.Marshal` would work as expected. Learn more: https://stackoverflow.com/a/55879732/16317008

### 3.2. `json.Unmarshal()`

```go
func main() {
	data, _ := json.Marshal(Cat{
		Name: "Kitten",
		Age: 2,
		IsAdult: true,
	})

	cat := Cat{}
	 _ = json.Unmarshal(data, &cat)
	fmt.Println(cat)
}
----------------------------------
{Kitten 2 true}
```

### 3.3. `json.NewDecoder()` & `json.Unmarshal()`

- Use `json.Decoder` if your data is coming from an `io.Reader` stream, or you need to decode multiple values from a stream of data.
- Use `json.Unmarshal` if you already have the JSON data in memory.

If you check the signature, you should understand:

```go
func NewDecoder(r io.Reader) *Decoder

func Unmarshal(data []byte, v any) error
```

Source: https://stackoverflow.com/a/21198571/16317008

References:

- [Gobs of data - The Go Programming Language](https://go.dev/blog/gob)
- [gob package - encoding/gob - Go Packages](https://pkg.go.dev/encoding/gob)
- [difference between encoding/gob and encoding/json](https://stackoverflow.com/questions/41179453/difference-between-encoding-gob-and-encoding-json) 
- [go - What's the purpose of gob.Register method? - Stack Overflow](https://stackoverflow.com/questions/32676898/whats-the-purpose-of-gob-register-method/32677598#32677598)
- [go - gob.Register() by type or for each variable? - Stack Overflow](https://stackoverflow.com/questions/31467602/gob-register-by-type-or-for-each-variable)

Learn more: 

- [Golang Benchmark: gob vs json](https://gist.github.com/evalphobia/a2ba2636acbc112f68dcd89e8b81d349)
- [gob - The Go Programming Language](https://www.cs.ubc.ca/~bestchai/teaching/cs416_2015w2/go1.4.3-docs/pkg/encoding/gob/index.html)
