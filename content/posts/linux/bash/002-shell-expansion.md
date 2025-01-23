---
title: Shell Expansion
date: 2023-08-26 11:30:20
categories:
 - linux
tags:
 - linux
---

## 1. Shell expansion

When the shell receives a command, either from the user typing at the keyboard, or from a shell script, it breaks it up into words. After this happens, the shell performs seven operations on the words, which can change how they are interpreted. There are seven operations are collectively known as 'shell expansion'. 

The seven operations that the shell performs are:

1. Brace Expansion - expanding values between braces, such as `file{1..3}` into `file1 file2 file3`
2. Tilde Expansion - expanding the `~` tilde symbol for the home directory into the path to the home directory, such as `~/effective-shell` into `/home/dwmkerr/effective-shell`
3. Parameter Expansion - expanding terms that start with a `$` symbol into parameter values, such as `$HOME` into the value of the variable named `HOME`
4. Command Substitution - evaluation of the contents of `$(command)` sequences, which are used to run commands and return the results to the shell command line
5. Arithmetic Expansion - evaluation of the contents of `$((expression))` sequences, which are used to perform basic mathematical operations
6. Word Splitting - once all of the previous operations are run, the shell splits the command up into 'words', which are the units of text that you can run loops over
7. Pathname Expansion - the shell expands wildcards and special characters in pathnames, such as `*.txt` into the set of files that are matched by the sequence

**Brace Expansion**

```shell
mkdir /tmp/{one,two,three}
# The line above is expanded to:
mdkir /tmp/one /tmp/two /tmp/three

touch file{1..5}.txt
# The line above is expanded to:
touch file1.txt file2.txt file3.txt file4.txt file5.txt

for x in {0..10..2}; do print $x; done
# The line above is expanded to:
for x in 0 2 4 6 8 10; do print $x; done
```

**Parameter Expansion**

```shell
fruit=apples
echo "I like $fruit"
# The line above is expanded to:
echo "I like apples"
```

When using parameter expansion it is generally preferable to surround the name of the parameter with braces - this allows you to tell the shell unambiguously what the name of the parameter is. For example:

```shell
echo "My backup folder is: ${HOME}backup"
# The line above is expanded to:
echo "My backup folder is: /home/dwmkerrbackup"
```

You should use`"My backup folder is: ${HOME}backup"`, not `"I like $fruit" `style. 

**Tilde Expansion**

```shell
cd ~/effective-shell
# The line above is expanded to:
cd $HOME/effective-shell
```

Note that if you want check what the command  exactly is after expansion, check it with `echo`:

```shell
$ ls
one.txt
two.txt
three.dat
$ echo rm *.txt
rm one.txt two.txt
```

## 2. Wildcard pattern 

### 2.1. Wildcard pattern in shell

A string is a ***wildcard pattern*** if it contains one of the characters `?`, `*`, or `[`,  Globbing is the operation that expands a wildcard pattern into the list of **pathnames** matching the pattern.  Matching is defined by: 

- A `?` (not between brackets) matches any single character. 
- A `*` (not between brackets) matches any string, including the empty string.

Don't forget  `*` may lose its special meaning in double qoutes, but it depends, at some conditions, it won't lost its special meaning for globing wich is filepath expansion. Learn more: [Shell Script Basic Syntax - David's Blog](https://davidzhu.xyz/post/linux/002-bash-basics/)

```shell
# Expands to: tar xvf file1.tar file2.tar file42.tar ...
tar xvf *.tar
# Delete all files ends with .txt under current folder
rm *.txt
# with double, it won't be expanded
$ rm "*.txt"
rm: *.txt: No such file or directory
# search for a string in your current directory and all other subdirectories
$ grep -r ‘hello’ *  
a.txt:hello world
sub/c.txt:hello, this is...
sub/b.txt:hello, this is...
# check what the command is after expansion
$ echo grep -r ‘hello’ *
```

### 2.2. Metacharacter in regular expressions

In regular expression the  `*`  is a metacharacter that represents zero or more occurrences of the preceding element. 

```shell
$ printf "colour\ncolor\ncolouur\n" | egrep 'colou*r'                          
colour
color
colouur
```

References:

- [glob(7) - Linux manual page](https://man7.org/linux/man-pages/man7/glob.7.html)

- [Understanding Shell Expansion | Effective Shell](https://effective-shell.com/part-6-advanced-techniques/understanding-shell-expansion/)
