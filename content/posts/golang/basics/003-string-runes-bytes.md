---
title: string, bytes, runes and characters - Go
date: 2023-09-11 13:50:59
categories:
 - golang
 - basics
tags:
 - golang
---

## 0. Make it eassy

This is all this post is going to talk, if you know this, you don't need to go through all this post.

**a string literal is a slice of bytes:**

```go
func main() {
	str := "汉"
	for i:=0; i<len(str); i++{
		fmt.Printf("%x ", str[i])
	}
}
---------------------------
e6 b1 89 
```

**a string literal consists of one or more `rune` values:**

```go
func main() {
	str := "abc汉"
	for _, s := range str {
		fmt.Printf("%x ", s)
	}
	fmt.Println()
	for _, s := range str {
		fmt.Printf("%c ", s)
	}
}
--------------------------
61 62 63 6c49 
a b c 汉 
```

Note that the ways of iterating the string literal in the codes above are different. 

## 1. string literals are encoded in UTF-8

```go
str := "汉"
fmt.Printf("length of str: %d", len(str))
```

Output:

```go
length of str: 3
```

Why the output is 3? It's all about the encoding. 

Character `汉` is a chinese character which occupies 3 bytes in utf-8 encoding format, and its **[code point](https://en.wikipedia.org/wiki/Code_point)** is `6C49`. Code point is a concept defined in Unicode. If you are not familiar with these you can check my another post: https://davidzhu.xyz/post/cs-basics/001-encoding/ 

In Go, string *literals* always contain UTF-8 text as long as they have no byte-level escapes. Therefore, the length of `str` is 3 bytes. This is the string in Go runtime sourcode which will help you understand string in go:

```go
// src/runtime/string.go
type stringStruct struct {
  str unsafe.Pointer
  len int
}
```

> **Note that**: `'x'` represents a single character (called a rune), whereas `"x"` represents a string literal containing the character `x`. This is same as in c++ and c.
>
> **Size is not length**, the size of a stirng value is always 2 words, learn more: [Value Variable and Types - Go - David's Blog](https://davidzhu.xyz/post/golang/basics/001-value-variable-type/)

## 2. string is read-only slice of bytes

In Go, a string is in effect a **read-only slice of bytes**. We have disscussed slice in [previous post](https://davidzhu.xyz/post/golang/basics/016-slice-relearn/). 

```go
func main() {
    str := "汉"
    for i := 0; i < len(str); i++ {
       fmt.Printf("%x ", str[i])
    }
}
```

Output:

```
e6 b1 89 
```

As we saw, indexing a string yields its bytes, not its characters: a string is just a bunch of bytes. 

Here is another example that I want to talk:

```go
func main() {
	str := "汉"
	fmt.Printf("%x ", str)
	fmt.Println()
	for i := 0; i < len(str); i++ {
		fmt.Printf("%x ", str[i])
	}
}
```

Output:

```
6c49 
e6 b1 89 
```

That character `汉` has Unicode value `U+6C49` , this is just its Unicode code point, if we want wrtie this string into a file, we have to use a encoding scheme, gbk, utf-8 and other encoding scheme. After `汉` is encoded by utf-8, the value represents it is `e6 b1 89` Note that the value that written in the disk is `e6 b1 89 ` which stands for `汉` in utf-8. Learn more: https://davidzhu.xyz/post/cs-basics/001-encoding/ 

## 3. string is immutable

```go
func EchoCommandArgs() {
	var s string
	// The variable os.Args is a slice of strings.
	// range produces a pair of values: the index and the value of the element at that index.
	// we ignore index with _ marker here
	for _, arg := range os.Args[1:]{
		// s += ... will make a new string everytime, because string is immutable
		// The += statement makes a new string by concatenating the old string,
		// a space character, and the next argument, then assigns the new string to s.
		// The old contents of s are no longer in use, so they will be garbage-collected in due course.
		// If the amount of data involved is large, this could be costly.
		// A simpler and more efficient solution would be to use the Join function from the strings package
		s += arg
		s += " "
	}
	fmt.Println(s)
	fmt.Println(os.Args[1:])
	fmt.Println(strings.Join(os.Args[1:], " "))
}
---------------------------------------
$ go run main.go hello hi hi
hello hi hi 
[hello hi hi]
hello hi hi
```

## 4. `byte` & `rune`

A `byte` in Go is an unsigned 8-bit integer whose type is actually `uint8`, which can represent an ASCII character.

Go uses `rune`, which has type `int32`, to deal with multibyte characters. `rune` occupies 32bit (4 bytes) and is meant to represent a [Unicode](http://en.wikipedia.org/wiki/Unicode) [CodePoint](http://en.wikipedia.org/wiki/Code_point) which is 4 bytes. Source: https://stackoverflow.com/a/19325804/16317008

`汉` is a multibyte character. Here should note that we say "`rune` is used to deal with multibyte characters" doesn't mean it cannot represent singlebyte characters (ASCII), it's just a `int32` type, not something magic.  

```go
func main() {
	str := "abc汉"
	for _, c := range str {
		fmt.Printf("%T ", c)
	}
	fmt.Println()
	for _, c := range str {
		fmt.Printf("%x ", c)
	}
	fmt.Println()
	for i := 0; i < len(str); i++ {
		fmt.Printf("%x ", str[i])
	}
}
```

Output:

```
int32 int32 int32 int32 
61 62 63 6c49 
61 62 63 e6 b1 89 
```

As we see here from the output line-3, a string literal is just a slice of bytes, but the first two line prove that we can think a string literal  is just a slice of `rune` which is `int32`. 

Here is another example may help you to understand the string literal and `rune`:

```go
func isValid(s string) bool {
	for _, c := range s {
    // error: Invalid operation: c == "{" (mismatched types int32 and string)
		if c == "{":
			...
    // no error
    // `'x'` represents a single character (called a rune)
    // c is a rune here
    if c == '{' {
			
		}
	}
	return false
}
```

## 5. Go source code is UTF-8

Source code in Go is *defined* to be UTF-8 text; no other representation is allowed. That implies that when, in the source code, we write the text

```
`⌘`
```

the text editor used to create the program places the UTF-8 encoding of the symbol ⌘ into the source text. **When we print out the hexadecimal bytes, we’re just dumping the data the editor placed in the file**. 

> Recall the `汉` example we talked above, the real thing written in the disk is not its Unicode code point but the data encoded by uft-8 which is 3 bytes. 

In short, Go source code is UTF-8, so *the source code for the string literal is UTF-8 text*. If that string literal contains no escape sequences, which a raw string cannot, the constructed string will hold exactly the source text between the quotes. Thus by definition and by construction the raw string will always contain a valid UTF-8 representation of its contents. Similarly, unless it contains UTF-8-breaking escapes like those from the previous section, a regular string literal will also always contain valid UTF-8.

Some people think Go strings are always UTF-8, but they are not: only string literals are UTF-8. As we showed in the previous section, string *values* can contain arbitrary bytes; as we showed in this one, string *literals* always contain UTF-8 text as long as they have no byte-level escapes.

To summarize, strings can contain arbitrary bytes, but when constructed from string literals, those bytes are (almost always) UTF-8.

## 6. `[]byte` vs `[]rune` 

A slice of byte just a slice of `uint8`, just a list of small numbers (0~127). We usually use a `[]byte` slice when we want store ASCII characters which are singlebye characters, if you want store multibyte characters, you should use `[]rune` or the string literals. 

## 7. `[]byte`, `[]rune` and string conversion will makes copy

```go
func main() {
  // this is a slice not an array
  // you can replace []byte with []rune
	data := []byte{102, 97, 108, 99, 111, 110}
  // convert byte slice to string
	fmt.Println(string(data))
  // string to byte slice
  fmt.Println([]byte("falcon"))
}
----------------------------------------
[102 97 108 99 111 110]
falcon
[102 97 108 99 111 110]
```

The compiler will allocate a new piece of memory and copy the data over when you convet string to bytes or bytes to string. The reason is that `[]byte` is not immutable.  You can change the bytes within a slice. You can grow the slice by appending bytes to the end. But a string is immutable. You cannot change it and you cannot grow it without creating a whole new string. If a string and a `[]byte` were backed by the same memory, then the string would change when the `[]byte` was changed, and that might not be what you expect. 

So, each time you do `[]byte(“fred”)` or `string([]byte{0x40, 0x040})`, there’s an allocation and a copy. This is done by https://golang.org/pkg/runtime/?m=all#stringtoslicebyte and https://golang.org/pkg/runtime/?m=all#slicebytetostring. And this is normally the right thing to do and normally has no significant consequences. 

References:

- [Go byte - working with bytes in Golang](https://zetcode.com/golang/byte/)
- [[]byte vs string in Go](https://syslog.ravelin.com/byte-vs-string-in-go-d645b67ca7ff)
- [Strings, bytes, runes and characters in Go - The Go Programming Language](https://go.dev/blog/strings)
- [go - Cannot assign string with single quote in golang - Stack Overflow](https://stackoverflow.com/questions/34691045/cannot-assign-string-with-single-quote-in-golang)