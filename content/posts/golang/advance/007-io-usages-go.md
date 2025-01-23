---
title: Useful Types and Packages for IO - Go
date: 2023-09-26 17:03:55
categories:
 - golang
 - advance
tags:
 - golang
---

## 1. `bytes` & `strings` packages

Package `strings` implements simple functions to manipulate UTF-8 encoded strings.

Package `bytes` implements functions for the manipulation of byte slices. It is analogous to the facilities of the [strings](https://pkg.go.dev/strings) package.


### 1.1. Make http request

When send POST request with json body, you can write code like this:

```go
jsonBytes := []byte(`{"username":"coco", "password":"778899a"}`)
r, _ := http.NewRequest("POST", "/login", bytes.NewReader(jsonBytes))
r.Header.Set("Content-Type", "application/json")
w := httptest.NewRecorder()
...
```

And at the server side, decode the request body:

```go
func handleLogin(w http.ResponseWriter, r *http.Request) {
	user := struct {
		Username string `json:"username"`
		Password string `json:"password"`
	}{}
	decoder := json.NewDecoder(r.Body)
	_ = decoder.Decode(&user)
	fmt.Println(user)
}
```

Because the third parameter of`http.NewRequest()` required to be an `io.Reader`,  we use `bytes.NewReader()` to wrap `jsonBytes` at client side. 

```go
func NewRequest(method, url string, body io.Reader) (*Request, error) 
```

You can use other type which implements the `io.Reader` at client to call `http.NewRequest()`:

```go
jsonString := `{"username":"coco", "password":"778899a"}`
r, _ := http.NewRequest("POST", "/login", strings.NewReader(jsonString))
r.Header.Set("Content-Type", "application/json")
...
```

As you can see the package `bytes` and `strings` are just different for processing byte slices and strings, `strings.NewReader()` wraps a string value into an `io.Reader` whereas `bytes.NewReader` converts a byte slice into an `io.Reader`. 

`strings.NewRecoder()`:

```go
func NewReader(s string) *Reader
```

`bytes.NewReader`:

```go
func NewReader(b []byte) *Reader
```

## 2. `bytes.Buffer ` type

A `Buffer` is a variable-sized buffer of bytes with `Read` and `Write` methods. This means it has implemented `io.Reader` and `io.Writer` interface. 

```go
// A Buffer is a variable-sized buffer of bytes with Read and Write methods.
// The zero value for Buffer is an empty buffer ready to use.
type Buffer struct {
	buf      []byte // contents are the bytes buf[off : len(buf)]
	off      int    // read at &buf[off], write at &buf[len(buf)]
	lastRead readOp // last read operation, so that Unread* can work correctly.
}
```

## 3. `bufio` package

Buffered I/O is a technique that allows a program to read or write data in chunks rather than one byte at a time. This is useful because it allows the program to read or write data more efficiently. It also allows the program to read or write data more predictably.

### 3.1. `bufio.Reader` & `io.Reader`

> To create a buffered reader (`bufio.Reader`), you can use the `bufio.NewReader` function. This function takes an `io.Reader` as an argument. This means that you can pass in any type that implements the `io.Reader` interface. This includes `os.File`, `strings.Reader`, and `bytes.Buffer`.

Note that until we introdeced two Readesr: `io.Reader` and `bufio.Reader`.  `bufio.Reader` just wraps an `io.Reader` and provides additional buffering functionality, such as `ReadLine()`, `ReadString()`, and `ReadBytes()`. 

```go
func (b *Reader) ReadLine() (line []byte, isPrefix bool, err error)
```

`ReadLine()` is a low-level line-reading primitive. Most callers should use `ReadBytes('\n')` or `ReadString('\n')` instead or use a `bufio.Scanner`.

```go
func (b *Reader) ReadString(delim byte) (string, error)
```

`ReadString()` reads until the first occurrence of delim in the input, returning a string containing the data up to and including the delimiter. 

The following program reads the content of a file line-by-line delimited with value `'\n'` :

```go
func main() {
	file, err := os.Open("./planets.txt")
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	defer file.Close()
	reader := bufio.NewReader(file)

	for {
		line, err := reader.ReadString('\n')
		if err != nil {
			if err == io.EOF {
				break
			} else {
				fmt.Println(err)
				os.Exit(1)
			}
		}
		fmt.Print(line)
	}

}
// credit: https://medium.com/learning-the-go-programming-language/streaming-io-in-go-d93507931185
```

### 3.2. `bufio` vs. `io` package

The main difference between buffered I/O and normal I/O is that buffered I/O reads or writes data in chunks rather than one byte at a time. While on the other side normal I/O reads or writes data one byte at a time. This might not seem like a big difference but it can make a big difference in performance.

In a case where you are reading or writing a lot of data, buffered I/O can be much faster than normal I/O. To see this, we can compare the performance of buffered I/O and normal I/O using benchmarks.

```go
func funcToWithIO() {
	file, err := os.Open("file.txt")
	if err != nil {
		fmt.Println(err)
		return
	}
	defer file.Close()

	data := make([]byte, 100)
	for {
		_, err := file.Read(data)
		if err == io.EOF {
			break
		}
		if err != nil {
			fmt.Println(err)
			return
		}
	}
}

func funcToWithBufio() {
	file, err := os.Open("file.txt")
	if err != nil {
		fmt.Println(err)
		return
	}
	defer file.Close()

	reader := bufio.NewReader(file)
	data := make([]byte, 100)
	for {
		_, err := reader.Read(data)
		if err == io.EOF {
			break
		}
		if err != nil {
			fmt.Println(err)
			return
		}
	}
}

func createFile() {
	file, err := os.Create("file.txt")
	if err != nil {
		fmt.Println(err)
		return
	}
	defer file.Close()

	for i := 0; i < 1000000; i++ {
		file.Write([]byte("Hello World!"))
	}
}

func main() {
	createFile()
	funcToWithIO()
	funcToWithBufio()
}
```

Test file:

```go
func BenchmarkFuncToWithIO(b *testing.B) {
	for i := 0; i < b.N; i++ {
		funcToWithIO()
	}
}

func BenchmarkFuncToWithBufio(b *testing.B) {
	for i := 0; i < b.N; i++ {
		funcToWithBufio()
	}
}
```

```shell
$ go test -bench 'BenchmarkFuncToWithIO|BenchmarkFuncToWithBufio'
goos: darwin
goarch: arm64
pkg: leetcode
BenchmarkFuncToWithIO-8               18          62718294 ns/op
BenchmarkFuncToWithBufio-8           469           2531219 ns/op
PASS
```

Source: https://www.kelche.co/blog/go/golang-bufio/
