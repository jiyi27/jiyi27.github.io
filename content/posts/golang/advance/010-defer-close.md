---
title: Don't Defer Close() on Writable Files - Go Notes
date: 2023-10-05 18:52:56
categories:
 - golang
 - advance
tags:
 - golang
---

Why would you get an error from `Close()` but not an earlier `Write()` call? To answer that we need to take a brief, high-level detour into the area of computer architecture.

Generally speaking, as you move outside and away from your CPU, actions get orders of magnitude slower. Writing to a CPU register is very fast. Accessing system RAM is quite slow in comparison. Doing I/O on disks or networks is an eternity.

If every `Write()` call committed the data to the disk synchronously, the performance of our systems would be unusably slow. While synchronous writes are very important for certain types of software (like databases), most of the time it’s overkill.

The pathological case is writing to a file one byte at a time. Hard drives – brutish, mechanical devices – need to physically move a magnetic head to the position on the platter and possibly wait for a full platter revolution before the data could be persisted. SSDs, which store data in blocks and have a finite number of write cycles for each block, would quickly burn out as blocks are repeatedly written and overwritten.

Fortunately this doesn’t happen because multiple layers within hardware and software implement caching and write buffering. When you call `Write()`, your data is not immediately being written to media. The operating system, storage controllers and the media itself are all buffering the data in order to batch smaller writes together, organizing the data optimally for storage on the medium, and deciding when best to commit it. This turns our writes from slow, blocking synchronous operations to quick, asynchronous operations that don’t directly touch the much slower I/O device. Writing a byte at a time is never the most efficient thing to do, but at least we are not wearing out our hardware if we do it.

Of course, the bytes do have to be committed to disk at some point. The operating system knows that when we close a file, we are finished with it and no subsequent write operations are going to happen. It also knows that closing the file is its last chance to tell us something went wrong.

On POSIX systems like Linux and macOS, closing a file is handled by the `close` system call. The BSD man page for `close(2)` talks about the errors it can return:

```
ERRORS
     The close() system call will fail if:

     [EBADF]            fildes is not a valid, active file descriptor.

     [EINTR]            Its execution was interrupted by a signal.

     [EIO]              A previously-uncommitted write(2) encountered an input/output
                        error.
```

`EIO` is exactly the error we are worried about. It means that we’ve lost data trying to save it to disk, and our Go programs should absolutely not return a `nil` error in that case.

On Twitter, [Ben Johnson suggested](https://twitter.com/benbjohnson/status/874286396411961345) that `Close()` may be safe to run multiple times on files, like so:

```go
func doSomething() error {
    f, err := os.Create("foo")
    if err != nil {
        return err
    }
    defer f.Close()

    if _, err := f.Write([]byte("bar"); err != nil {
        return err
    }
    return f.Close()
}
```

The docs for `*os.File` [on its behavior](https://golang.org/pkg/os/#File.Close) saying: *Close will return an error if it has already been called*. But since we are ignoring the error from the `defer`, this doesn’t matter. 

Source: [Don't defer Close() on writable files – joe shaw](https://www.joeshaw.org/dont-defer-close-on-writable-files/)

