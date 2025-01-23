---
title: Shell Script Basic Syntax
date: 2023-09-01 12:23:59
categories:
 - linux
tags:
 - linux
---

## 1. Run a script

A hello world script:

```shell
#!/usr/bin/bash
echo "hello world"
```

The first here specifies which shell should execute this script, if you don't write, the default shell on your computer will run it, check all the shells on your computer:

```shell
$ cat /etc/shells      
# List of acceptable shells for chpass(1).
# Ftpd will not allow users to connect who are not using
# one of these shells.
/bin/bash
/bin/csh
/bin/dash
/bin/ksh
/bin/sh
/bin/tcsh
/bin/zsh
```

Don't write a wrong location of bash interpreter, `/bin/nmsd` below doesn't exist, execute this script will go wrong:

```shell
$ cat script.sh 
#!/bin/nmsd
echo "hello world"

$ chmod u+x script.sh 
$ ./script.sh 
zsh: ./a.sh: bad interpreter: /bin/ash: no such file or directory
```

`chmod u+x` will made the file executable for your user (it will only add it for your user, though it may be already executable by the group owner, or "other"). `chmod a+x` ('all plus executable bit') makes the file executable by everyone. The `u` is standing for "user". That means that the executable flag only applies to the current user of the file.

- **u for user** (the user who is owner of the file
- **g for group** (other users in the file group
- **o for others** (users not in the file group
- **a for all** (all users

## 2. Bash variables are untyped

Bash does not type variables like C and related languages, defining them as integers, floating points, or string types. In Bash, all variables are strings. A string that is an integer can be used in integer arithmetic, which is the only type of math that Bash is capable of doing. 

The assignment `VAR=10` sets the value of the variable `VAR` to 10. To print the value of the variable, you can use the statement `echo $VAR`. 

> *Note: The syntax of variable assignment is very strict. There must be no spaces on either side of the equal `=` sign in the assignment statement.*

It is not suitable for scientific computing or anything that requires decimals, such as financial calculations. 

## 3. for loop  and array

```shell
for item in (list)
do
	command_one
	command_two
	...
done
```

***e.g.,*** 

```shell
#!/usr/bin/bash
archs=(amd64 arm64 ppc64le ppc64 s390x)

for arch in ${archs}
do
	env GOOS=linux GOARCH=${arch} go build -o prepnode_${arch}
done
```

```shell
# rename all file under current folder form lowercase to capital
for file in *; 
do
	mv "$file" 	`echo $file |  tr 'a-z' 'A-Z'`
done
```

But this isn't the best choice, the command below will rename all files recursively which the code above cannot do, 

```shell
$ brew install rename
$ find . -depth -execdir rename -f 'y/A-Z/a-z/' {} \;
```

You probably wonder what is the `""`,  `*` and `;`  above, I'll explain it to you next. 

## 4. Control operators

- `;`: Will run one command after another has finished, irrespective of the outcome of the first. This means even there is wrong in fiest command, the second can execute. 
- `&&`: if the precceeding command goes wrong, the commands left won't be executed. 
-  `||`: It executes the command on the right only if the command on the left returned an error.

```shell
# even command `cd fd.sh` goes wrong, command `ls` can be executed 
$ cd fd.sh; ls
cd: not a directory: fd.sh
economic fd.sh    test.sh

$ cd fd.sh && ls
cd: not a directory: fd.sh

$ cd fd.sh || ls
cd: not a directory: fd.sh
economic fd.sh    test.sh
```

## 5. Quotes

### 5.1. Why need qoutes 

Quoting is used to remove the special meaning of ***metacharacters*** or words to the shell. Quoting can be used to disable special treatment for special characters, to prevent reserved words from being recognized as such, and to prevent ***parameter expansion***.

> **Metacharacter**: a character that, when unquoted, separates words. A metacharacter is a `space`, `tab`, `newline`, or one of the following characters: `*`,  `?`,  `|`,   `&`,   `;`,  `(`,  `)`,   `<`, or `>`, etc...
>
> **Parameter Expansion**: The `$` character introduces parameter expansion, command substitution, or arithmetic expansion. [source](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html)

For example, you want to print `<-$1500.**>; (update?) [y|n]`, but `<>*;$` has a special meaning in bash, and printing it directly won't work. 

You can use escape character `\` to solve this problem:

```shell
bash-3.2$ echo \<-\$1500.\*\*\>\; \(update\?\) \[y\|n\]
<-$1500.**>; (update?) [y|n]
```

But this is not elegant, you can use **single quote** to solve this problem:

```shell
bash-3.2$ echo '<-$1500.**>; (update?) [y|n]'
<-$1500.**>; (update?) [y|n]
```

Why does this work?  Because all special characters between single quotes lose their special meaning, I find a table will help:

| Sr.No. |                    Quoting & Description                     |
| :----: | :----------------------------------------------------------: |
|   1    | **Single quote ** All special characters between these quotes lose their special meaning. |
|   2    | **Backslash** `\` Any character immediately following the backslash loses its special meaning. |
|   3    | **Backquote**  Anything in between back quotes would be treated as a command and would be executed. |
|   4    | The characters ` $`  and '`' retain their special meaning within **double quotes**. |

### 5.2. Backqoute

You may wonder what does back quote mean in the table, I'll give you an example:

```shell
$ cat a.txt 
hello world
$ A=`cat a.txt`; echo "$A"
hello world
```

The code between back quotes will be executed, and if there is output, you can save it into a variable, 

### 5.3. Double quotes

Sometimes `*` may acts like it remains its spcecial meaning in double quotes:

- Without any special options:

  - Inside double quotes (`"`), the asterisk `*` retains its literal meaning and does not perform globbing (expansion to match filenames).

  - For example, `"*"` will be treated as a literal asterisk character.

- With some spcecial options:
  - `find . -name "*.sh" -type f `, in the command the `-name "*.sh"` the `"*.sh"` acts as a pattern, the double quotes prevent the shell from interpreting the asterisk as a wildcard character and expanding it to match filenames in the current directory. 
  - Therefore, in the given command, `"*.c"` is treated as a literal string by the shell. The `find` command receives the pattern `"*.c"` as an argument, and it performs the matching internally during its execution.
  - Which acts like the `*` doesn't lose its special meaning. 

## 6. `$` & `*` in bash

### 6.1. `$`

`$` has many use cases, I'll introduce one here, in bash scripting, variables are used to store values, the `$` symbol is used to retrieve the value of a variable Value.

```shell
name="Mark"; echo "My name is $name"
```

> ⚠ Don't forget `$` and 'back quote' sign retain their special meaning between double quote. 

### 6.2. `*`

> ⚠ `*` will lose its special meaning between double quote. 

The Shell (bash) considers an asterisk `*` to be a wildcard character that can match one or more occurrences of any character, including no character.

The “*” character is a shortcut for “everything”. Thus, if you enter `ls *`, you will see all of the contents of a given directory.  

- `ls *fq` lists every file that ends with a `fq`. 
- `ls /usr/bin/*.sh` This lists every file in `/usr/bin` directory that ends in the characters `.sh`. 
- `*` can be placed anywhere in your pattern: `ls Mov10*fq`

Now when you check the command we did before, you may understand:

```shell
# rename all file under current folder form lower-case to upper-case
for file in *; 
do
	mv "$file" 	`echo $file |  tr 'a-z' 'A-Z'`
done
```

## 5. Arithmetic expansion

> **Parameter Expansion**: The `$` character introduces parameter expansion, command substitution, or arithmetic expansion. [source](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html)

The behaviour of bash interpreter is different from other programming interpreter so if you write code like below:

```shell
#!/usr/bin/bash
$ a=3; b=5; c=a+b; echo $c
# Print: a+b 
```

You may not get the result you want, the correct way to do this:

```shell
$ a=3; b=5; c=$((a+b)); echo $c     
$ a=3; b=5; echo $((a+b))
$ a=3; b=5; let c="a+b"; echo $c
```

- `$((...))` is called [arithmetic expansion](http://pubs.opengroup.org/onlinepubs/009695399/utilities/xcu_chap02.html#tag_02_06_04), which is typical of the `bash` and `ksh` shells. This allows doing simple *integer* arithmetic, no floating point stuff though. The result of the expression replaces the expression, as in `echo $((1+1))` would become `echo 2`
- `((...))` is referred to as [arithmetic evaluation](https://wiki-dev.bash-hackers.org/syntax/ccmd/arithmetic_eval) and can be used as part of `if ((...)); then` or `while ((...)) ; do` statements. Arithmetic expansion `$((..))` substitutes the output of the operation and can be used to assign variables as in `i=$((i+1))` but cannot be used in conditional statements.
- `let` is a `bash` and `ksh` keyword which allows for variable creation with simple arithmetic evaluation. If you try to assign a string there like `let a="hello world"` you'll get a syntax error.

## 6. Conclusion

- There must be no spaces on either side of the equal `=` sign in the assignment statement.
- Three control operators: `;`, `||`, `&&`
- set defalul shell: `chsh -s /bin/zsh`, switch shell temporarily: `shell-name` + `enter`
- check version of shell: `echo "$ZSH_VERSION"`, `echo "$BASH_VERSION"`
- check all shells: `cat /etc/shells`

References:

- [bash - 'chmod u+x' versus 'chmod +x' - Ask Ubuntu](https://askubuntu.com/questions/29589)
- [Linux: Difference between "chmod +x" and "chmod u+x"](https://www.askingbox.com/question/linux-difference-between-chmod-x-and-chmod-u-x)
- [Quoting (Bash Reference Manual)](https://www.gnu.org/software/bash/manual/html_node/Quoting.html)
- [Unix / Linux - Shell Quoting Mechanisms](https://www.tutorialspoint.com/unix/unix-quoting-mechanisms.htm)
- [bash - Understanding backtick (`) - Unix & Linux Stack Exchange](https://unix.stackexchange.com/questions/48392/understanding-backtick)
- [Shell Expansions (Bash Reference Manual)](https://www.gnu.org/software/bash/manual/html_node/Shell-Expansions.html#Shell-Expansions)
- [The Shell | Introduction to the command line interface (Shell)](https://hbctraining.github.io/Intro-to-shell-flipped/lessons/02_wildcards_shortcuts.html)
