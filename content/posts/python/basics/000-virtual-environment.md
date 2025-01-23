---
title: Virtual Environment Python
date: 2023-11-09 19:12:40
categories:
  - python
tags:
  - python
---

## 1. Check Python environment

```shell
❯ ls /usr/bin/python* & ls /usr/local/bin/python*
/usr/local/bin/python3            /usr/local/bin/python3.10
/usr/bin/python3
```

> `/usr/bin` belongs to the system. Mess with it at your peril.
> `/usr/local/bin` is yours to fool with; if you mess something up in there, you can trash `/usr/local` and the system will chug along just fine. If you trash `/usr/bin`, you'll probably end up reinstalling the OS.

### 1.1. Multiple versions of Python interpreter

As you can see, there are two `python3` located at `/usr/bin/` and `/usr/local/bin/` respectively, and both of these dirs added into the `$PATH`, so when I input `python3` on my terminal, which `"python3"` will be chosen?

It depends on the `PATH` environment variable, the `PATH` variable determines the order in which directories are searched to find executable files. If `/usr/local/bin` appears before `/usr/bin` in the `PATH`, then `/usr/local/bin/python3` will be chosen when you enter "python3" in the terminal.

## 2. Environment variable `$PATH`

> The `PATH` environment variable is an essential component of any Linux system. If you ever use the command line at all, the system is relying on the `PATH` variable to find the location of the commands you are entering.

```shell
echo $path
/opt/homebrew/bin /opt/homebrew/sbin /usr/local/bin /usr/bin /bin /usr/sbin /sbin
```

Learn more: https://linuxconfig.org/linux-path-environment-variable

## 3. Virtual environment

**`venv`** (for Python 3) and **`virtualenv`** (for Python 2) allow you to manage separate package installations for different projects. They essentially allow you to create a “virtual” isolated Python installation and install packages into that virtual installation. When you switch projects, you can simply create a new virtual environment and not have to worry about breaking the packages installed in the other environments. It is always recommended to use a virtual environment while developing Python applications.

If you are using Python 2, replace `venv` with `virtualenv` in the below commands:

```shell
python3 -m venv env_310
source env/bin/activate
```
> This command will create a virtual environment in your current directory. The version of Python in the virtual environment using this command will be the same is the version of the python interpreter you used.
>
> Here the `python3` is 3.10, so the created env will use python 3.10 as interpreter, you can find the interpreter at `./env_310/bin/` folder. 

You can also create different virtual env in a same project so that you can switch different version of Python interpreter. 

```bash
# python3 is python 3.10 on my machine
$ python3 -m venv env_310

#  /usr/bin/python3 is python 3.9
$  /usr/bin/python3 -m venv env_309
```

Then there will be two virtual environments, you can switch to any version of the Python virtual environment by deactivating one and activating another.

```bash
$ source env_310/bin/activate
$ which python 
/Users/David/Codes/PyCharm/tgpt/env_310/bin/python
$ env_310 ❯ python --version      
Python 3.10.0
# switch to python 3.9
$ deactivate
$ source env_309/bin/activate
...
```

## 4. **Command `python -m <module-name>`**

```shell
python3 -m notebook
python3 -m pip ...

# if no -m, there will be an error
python3 notebook
// /Library/Developer/CommandLineTools/usr/bin/python3: can't open file '/Users/shaowen/notebook': [Errno 2] No such file or directory

python pip 
// python: can't open file '/Users/PyCharm/pythonProject/pip': [Errno 2] No such file or directory
```

What does `-m` in `python -m pip install <package>` mean? or while upgrading pip using `python -m pip install --upgrade pip`. What is difference when just running `pip install`.

> -m: run library module as a script (terminates option list)

```bash
python3 main.py
python3 -m main
python3 main // error
python3 -m main.py // warning remove '.py'
```

## 5. **`if __name__ == "__main__"`**

> This is useful because you **do not** want this code block to run when importing into other files, but you **do** want it to run when invoked from the command line.

```python
//cat.py:
if __name__ == "__main__":
    print('mow~')

//main.py:
import cat
print('hello')
```

Execute on shell:
```shell
python main.py
hello
# After the first line in cat.py is removed
python main.py
mow~
hello
```

## 6. `pip uninstall xxx` 

use `pip-autoremove` to remove a package plus unused dependencies.
```shell
pip list
# install pip-autoremove
pip install pip-autoremove
# remove "somepackage" plus its dependencies:
pip-autoremove xxx -y
```

https://stackoverflow.com/a/10284948/16317008

