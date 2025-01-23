---
title: Statically Linking in C
date: 2023-11-03 10:49:20
categories:
 - c++
tags:
 - c
 - c++
---

## 1. Compilation process in C

C/C++ programs are built in two main phases (ignore the preprocess, assemble):

1. Compilation - produces object code (`.obj`, `.o`)
   ```shell
   # Compile source code into an object file without linking:
   gcc -c path/to/source.c
   ```
   - The extension of the ***object file*** in DOS is `.obj`, and in UNIX, the extension is `.o`. 

2. Linking - produces executable code (.exe or .dll)

   - ***executable file*** with an extension of `exe` in DOS and `.out` in UNIX OSL

## 2. Static linking and dynamic linking

### 2.1. Static linking - portable, fast

Mainly, all the programs written in C use library functions. These library functions are pre-compiled, and the object code of these library files is stored with `.lib` (or `.a`) extension. **The main working of the linker** is to combine the ***object code*** of library files with the ***object code*** of our program. The output of the linker is the executable file. So the **static Linking creates larger binary files**.  Note that this is the process of static linking, and `.lib` and `.a` is static library in windows and linux respectively. 

In static linking, everything is bundled into your application, you don’t have to worry that the client will have the right library (and version) available on their system. Since all library code have connected at compile time, the final executable has no dependencies on the library at run time. You have everything under your control and there is no dependency.

One major advantage of static libraries being preferred even now “is speed”. There will be no dynamic querying of symbols in static libraries.

One drawback of static libraries is, for any change(up-gradation) in the static libraries, you have to recompile the main program every time.

### 2.2. Dynamic linking - smaller binary 

Dynamic Linking doesn’t require the code to be copied, it is done by just placing name of the library in the binary file. The actual linking happens when the program is run, when both the binary file and the library are in memory. 

Source: [Static and Dynamic Libraries | Set 1 - GeeksforGeeks](https://www.geeksforgeeks.org/static-vs-dynamic-libraries/)

## 3. Static library vs dynamic library

- Static library: windows `.lib`,  linux `.a` 

- Dynamic library (shared library): windows `.dll`, linux `.so` 

Static library `.lib` is just a bundle of `.obj` files and therefore isn't a complete program. It hasn't undergone the second (linking) phase of building a program. Dlls, on the other hand, are like exe's and therefore are complete programs.

**If you build a static library**, it isn't linked yet and therefore consumers of your static library will have to use the same compiler that you used (if you used g++, they will have to use g++). If the static library uses C++ library, such as `#include <iostream>`. 

If instead you built a dll (and built it [correctly](http://www.codeproject.com/Articles/28969/HowTo-Export-C-classes-from-a-DLL)), you have built a complete program that all consumers can use, no matter which compiler they are using. There are several restrictions though, on exporting from a dll, if cross compiler compatibility is desired.

Source: https://stackoverflow.com/a/25209275/16317008

## 4. Example in practice

Dynamic linking means the use of shared libraries. Shared libraries usually end with `.so` (short for "shared object") or `.dylib` on MacOS.

Another thing to note is that when a bug is fixed in a shared library, every application that references this library will profit from it. This also means that if the bug remains undetected, each referencing application will suffer from it (if the application uses the affected parts).

It can be very hard for beginners **when an application requires a specific version of the library, but the linker only knows the location of an incompatible versio**n. In this case, you must help the linker find the path to the correct version.

Although this is not an everyday issue, understanding dynamic linking will surely help you in fixing such problems.

Fortunately, the mechanics for this are quite straightforward. To detect which libraries are required for an application to start, you can use `ldd`, which will print out the shared libraries used by a given file. 

```
$ ldd my_app 
	linux-vdso.so.1 (0x00007ffd1299c000)
	libmy_shared.so => not found
	libc.so.6 => /lib64/libc.so.6 (0x00007f56b869b000)
	/lib64/ld-linux-x86-64.so.2 (0x00007f56b8881000)
```

Note that the library `libmy_shared.so` is part of the repository but is not found. This is because the **dynamic linker**, which is responsible for loading all dependencies into memory before executing the application, cannot find this library in the standard locations it searches.

Errors associated with linkers finding incompatible versions of common libraries (like `bzip2`, for example) can be quite confusing for a new user. One way around this is to add the repository folder to the environment variable `LD_LIBRARY_PATH` to tell the linker where to look for the correct version. In this case, the right version is in this folder, so you can export it:

```bash
$ LD_LIBRARY_PATH=$(pwd):$LD_LIBRARY_PATH
$ export LD_LIBRARY_PATH
```

Now the dynamic linker knows where to find the library, and the application can be executed. You can rerun `ldd` to invoke the dynamic linker, which inspects the application's dependencies and loads them into memory. The memory address is shown after the object path:

```bash
$ ldd my_app 
	linux-vdso.so.1 (0x00007ffd385f7000)
	libmy_shared.so => /home/stephan/library_sample/libmy_shared.so (0x00007f3fad401000)
	libc.so.6 => /lib64/libc.so.6 (0x00007f3fad21d000)
	/lib64/ld-linux-x86-64.so.2 (0x00007f3fad408000)
```

To find out which linker is invoked, you can use `file`:

```bash
$ file my_app 
my_app: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=26c677b771122b4c99f0fd9ee001e6c743550fa6, for GNU/Linux 3.2.0, not stripped
```

The linker `/lib64/ld-linux-x86–64.so.2` is a symbolic link to `ld-2.30.so`, which is the default linker for my Linux distribution:

```bash
$ file /lib64/ld-linux-x86-64.so.2 
/lib64/ld-linux-x86-64.so.2: symbolic link to ld-2.31.so
```

Looking back to the output of `ldd`, you can also see (next to `libmy_shared.so`) that each dependency ends with a number (e.g., `/lib64/libc.so.6`). The usual naming scheme of shared objects is:

```text
**lib** XYZ.so **.<MAJOR>** . **<MINOR>**
```

On my system, `libc.so.6` is also a symbolic link to the shared object `libc-2.30.so` in the same folder:

```bash
$ file /lib64/libc.so.6 
/lib64/libc.so.6: symbolic link to libc-2.31.so
```

If you are facing the issue that an application will not start because the loaded library has the wrong version, it is very likely that you can fix this issue by inspecting and rearranging the symbolic links or specifying the correct search path (see "The dynamic loader: ld.so" below).

For more information, look on the [`ldd` man page](https://www.man7.org/linux/man-pages/man1/ldd.1.html).

Source: [How to handle dynamic and static libraries in Linux | Opensource.com](https://opensource.com/article/20/6/linux-libraries)

> Note that the dynamic linker on MacOS is called `dyld`, try `man dyld` to check the details. Learn more: https://stackoverflow.com/a/34905091/16317008

```go
func main() {
	fmt.Println("hello")
}
// go build -o server main.go
```

Then check the shared libraries this executable file `server` required:

```shell
# otool -L: print shared libraries used
$ otool -L server           
server:
	/usr/lib/libSystem.B.dylib (compatibility version 0.0.0, current version 0.0.0)
	/usr/lib/libresolv.9.dylib (compatibility version 0.0.0, current version 0.0.0)
```

> `ldd` is on linux, on MaxOS you should use `otool`