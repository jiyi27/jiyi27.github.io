---
title: 用Python脚本给文章中英字符以及符号间加空格
date: 2023-06-01 10:41:24
categories:
  - python
tags:
  - python
---

强迫症, 读博客的时候中英字符或者标点符号后没有空格紧紧的贴在一块看着很不舒服, 于是想着能不能写个脚本来处理一下文章, bash太难用了(是我太菜), 于是用Python简单实现了一下, 

一些芝士在这说一下, 

### 1. Immutable Object in Python

Java虽然string是对象但primitive类型还不是对象, 与Java不同Python里如*integers*, *floats*, and *strings*都是对象, 并且与*integers*, *floats*一样, python里string对象也是immutable, 所以直接“修改”string会导致python重新创建新的string对象 销毁旧的:

```python
a = 'hello'
print(id(a))
# 4378912048
a += ' world'
print(id(a))
# 4380683504
```

因此每次修改(添加空格)都会重新重建一个新的string, 考虑到文章有的内容也不短, 那开销会不小, 具体做法分析参考: https://stackoverflow.com/q/1228299/16317008

### 2. 编码

另外是关于编码的问题, Unicode和utf-8, 

Python的string使用unicode来表示字符, 

> Python’s string type uses the Unicode Standard for representing characters, which lets Python programs work with all these different possible characters. 

Unicode就是赋予字符一个唯一的value, 如 'a'的unicode value是 0061, '汉'的unicode value是6C49, 

> Unicode (https://www.unicode.org/) is a specification that aims to list every character used by human languages and give each character its own unique code. 

而utf-8就是一个编码解码规范, 给我们一个unicode value如`6C49`, 我们把这个unicode value翻译成哪个字符呢? 根据不同的编码规则, `6C49`可以被翻译成不同的字符, 甚至两个, 因为有的编码比如ascii就是采用固定1子节编码, 通过查ascii表可知`6C`会被解释成字母`l`, 49会被解释成数字`1`, 但若采取utf-8进行解码, `6C49`就会被解释成汉字`汉`, utf-8是一种可变长度的编码, 

如果还不理解ascii, utf-8, unicode的关系, 看下面

UTF-8 is *an* encoding scheme. Other encoding schemes include UTF-16 and UTF-32. In modern times, ASCII is now a subset of UTF-8. UTF-8 is backwards compatible with ASCII. 

我们打开一个文本文件的时候需要指定其编码, 文本文件对你的电脑来说就是一串二进制数, 如果你不告诉他让他使用哪种编码方法来翻译这段字符, 那python程序怎么知道把这段二进制翻译成什么呢? 

我们linux下可以使用`xxd`以16进制输出指定文件内容, 加入我们有个`md`文件内容为

```
汉
```

使用`xxd`查看其二进制数据, 

```shell
$ xxd add_whitespace/article.md
00000000: e6b1 89  
```

真奇怪, 为什么一个汉字是3字节?  我们在python中明明使用两个字节表示的`汉`呀:

```python
>>> print('\u6C49')
汉
```

我查了一个gbk编码一个汉字是2字节, 若使用utf-8编码一个汉字则是3字节, 也就是说`text.md`可能使用的是utf-8编码, 验证一下:

```
$ file text.md
text.md: Unicode text, UTF-8 text
```

果然, 那为什么上面我们用两字节`\u6C49`就表示出`汉`了呢? 这就又说到了上面的编码方式utf-8, `\u6C49`只是Unicode code point, 并不是文件实际存的东西, 我们要存储这个汉字, 还需要使用编码方式, 比如utf-8, 我们看看utf-8编码unicode code的过程, 

```
Binary format of bytes in sequence

1st Byte    2nd Byte    3rd Byte    4th Byte    Number of Free Bits   Maximum Expressible Unicode Value
0xxxxxxx                                                7             007F hex (127)
110xxxxx    10xxxxxx                                (5+6)=11          07FF hex (2047)
1110xxxx    10xxxxxx    10xxxxxx                  (4+6+6)=16          FFFF hex (65535)
11110xxx    10xxxxxx    10xxxxxx    10xxxxxx    (3+6+6+6)=21          10FFFF hex (1,114,111)
```

所以, 上面的`6C49`经过utf-8编码变成:

```
# 6C49的二进制:0110 1100 0100 1001
11100110 10110001 10001001
```

把这个串二进制数转为16进制: `e6b1 89`与上面`xxd`输出一样, 这样也验证了utf-8编码unicode的过程, 

最后需要注意, 如果你直接把utf-8编码的文件转为其它编码比如gbk, 那转换之后你的文件肯定是乱码, 因为在你写入一些内容比如`汉`到你的文本文件, 此时这个文件的编码方式为`utf-8`, 那你保存此文件后, 此文件的内容已经是经过utf-8编码的unicode code, 即:`11100110 10110001 10001001`也就是`e6b1 89`就是上面的汉字`汉`, 此时你硬要把文件的编码方式改为gbk, 而gbk采用完全与utf-8不同的编码方式(2字节1个字符),  此时当其他软件是图打开你这个文本文件时, 就会查看你文件的编码信息, 他们看到是gbk编码, 那就会把`11100110 10110001 10001001`即`e6b1 89`中的前两个字节解释为一个字符, 然后他们查找`11100110 10110001`即`e6b1`, 那肯定匹配不到`汉`, 就会把`11100110 10110001`解释为不可打印字符或者英文或者其它语言,,,

一些工具可以实现不同编码的安全转换, 一个思路是, 我们知道这个文件是用的utf-8编码, 所以我们先把该文件的字符转换为unicode code, 然后再利用gbk进行编码这些unicode code, 具体做法如下:

```python
import sys

file_path = 'article_1.md'
with open(file_path, encoding="utf-8") as f:
    utf_8_str = f.read()
    if utf_8_str is None:
        print("Contents of Text cannot be None!")
        sys.exit()
    else:
        gbk_str = utf_8_str.encode("gbk")

with open("article_2.md", "wb") as f:
    f.write(gbk_str)
    f.encoding = "gbk"
```

注意, 上面代码`utf_8_str = f.read()`, 此时`utf_8_str`已经是unicode code, 第二我们写如文件时, 要以二进制写入, 不然你写入的就是长得像16进制数的字符串, 而不是真正的写入二进制数据, 

### 3. 实现

最后, python是值传递, 即我们无法传递一个变量给函数, 然后让函数修改它的值, 所以只能使用全局变量和类包装的形式来修改一个变量的值, 准确来说修改的只是变量的指向, 别忘了integer是不可变的, 所以我们执行`a+=1`的时候其实是python创建了个新的integer对象然后让变量`a`指向了一个新的integer value, 注意python里的变量都可以理解为reference, 这个reference不是c++里的reference, 而是Java里的reference类型, 别忘了哦, Java的变量分为两种, primitive和reference, 不知道可以参考: [C Go Java Python内存结构及对比 | 橘猫小八的鱼](https://davidzhu.xyz/2023/05/27/Other/c-go-java-python-memory-strucutre/)

上面说道使用全局变量和类包装的形式来修改一个变量的指向, 可是python有采用局部变量大于全局变量的约定, 即要是想在函数里修改全局变量, 我们必须在函数前声明`global xxx`, 这若是修改多个就很不美观, 所以最终采用使用包装类的方式来修改“全局”变量, 

```python
class Text:
    ch_flag = False
    en_flag = False
    back_quote_flag = False
    i = 0
    text = None


def add_space(before=True):
    if before:
        Text.text = Text.text[:Text.i] + ' ' + Text.text[Text.i:]
    else:
        Text.text = Text.text[:Text.i + 1] + ' ' + Text.text[Text.i + 1:]
    Text.en_flag = False
    Text.ch_flag = False
    Text.i += 1
```

若使用全局变量:

```python
ch_flag = False
en_flag = False
back_quote_flag = False
i = 0
text = None


def add_space(before=True):
    global text
    global i
    global en_flag
    global ch_flag
    if before:
        text = text[:i] + ' ' + text[i:]
    else:
        text = text[:i + 1] + ' ' + text[i + 1:]
    en_flag = True
    ch_flag = True
    i += 1
```

太丑了, 

### 4. 程序入口 `__name__=="__main__"`

`if __name__=="__main__"`: 就相当于Python 模拟的程序入口, 由于模块之间相互引用, 不同模块可能都有这样的定义, 而入口程序只能有一个, 选中哪个入口程序取决于 `__name__`的值:

```python
import sys


def main():
    # Check that exactly 1 command line argument was passed
    if len(sys.argv) != 2:
        print("Error: Incorrect number of arguments.")
        print("Usage: python file_path.py path/to/file.txt")
        exit(1)

    file_path = sys.argv[1]
    print(f"The file path is: {file_path}")


if __name__ == "__main__":
    main()
```

Python sets the global `__name__` of a module equal to `"__main__"` if the Python interpreter runs your code in the top-level code environment:

> “Top-level code” is the first user-specified Python module that starts running. It’s “top-level” because it imports all other modules that the program needs. ([Source](https://docs.python.org/3/library/__main__.html#what-is-the-top-level-code-environment))

```python
print("look here")
print(__name__)
 
if __name__ == '__main__':
    print("I'm test.py")
    
# print:    
look here
__main__
I'm test.py
```

### 5. 异常处理

```python
file_path = sys.argv[1]
    try:
        with open(file_path, encoding="utf-8") as f:
            Text.text = f.read()
            if Text.text is None:
                print("Contents of Text cannot be None!")
            else:
                formatting()
    except OSError as e:
        print(f"{type(e)}: {e}")
```

源码: https://github.com/shwezhu/PythonLearn/blob/main/add_whitespace/whitespace.py

参考:

- [Unicode HOWTO — Python 3.11.3 documentation](https://docs.python.org/3/howto/unicode.html#)
- [encoding - What is the difference between UTF-8 and Unicode? - Stack Overflow](https://stackoverflow.com/questions/643694/what-is-the-difference-between-utf-8-and-unicode)
- [utf 8 - ASCII vs Unicode + UTF-8 - Stack Overflow](https://stackoverflow.com/questions/21297704/ascii-vs-unicode-utf-8)
- [写 Python 脚本，一定要加上这个！-python写脚本](https://www.51cto.com/article/710215.html)
- [What Does if __name__ == "__main__" Do in Python? – Real Python](https://realpython.com/if-name-main-python/)
- [What is a good way to handle exceptions when trying to read a file in python? - Stack Overflow](https://stackoverflow.com/questions/5627425/what-is-a-good-way-to-handle-exceptions-when-trying-to-read-a-file-in-python)
