---
title: Regex Basics
date: 2023-05-01 23:14:22
categories:
 - regex
tags:
 - regex
---

## 1. `?`, `*`, `.`, `+`

| `+`  | one occurrences of the preceding element         |
| ---- | ------------------------------------------------ |
| `*`  | zero or more occurrence of the preceding element |
| `?`  | zero or one occurrences of the preceding element |
| `.`  | matches any single character (exclude newlines)  |

## 2. `\b`

To match "port" and "ports" but not match "export", "portable", "important", use \bports?\b. Here, \b indicates a boundary, where there cannot be other word characters on either side. Word characters refer to English letters, numbers and underscore "_". So \bports?\b will match "port" or "ports" only if they appear as a full word by themselves, not as part of another word.

```shell
$ printf "The port is...\nTo export it...\nThere are many ports...\nportable" | egrep '\bports?\b'
The port is...
There are many ports...
```

Please note that Bash generally uses "double quotes" to quote strings, in order to avoid potential misparsing, we should use 'single quotes' when quoting any regular expressions.

>  You should always [quote](https://www.gnu.org/software/bash/manual/bash.html#Quoting) regular expressions for `grep`--and [single quotes](https://www.gnu.org/software/bash/manual/bash.html#Single-Quotes) are usually best. https://askubuntu.com/a/957504/1690738

## 3. `[]`

A string of characters enclosed in square brackets (`[]`) matches any **one character** in that string. If the first character in the brackets is a caret (`^`), it matches any character *except* those in the string. For example, `[abc]` matches a, b, or c, but not x, y, or z. However, `[^abc]` matches x, y, or z, but not a, b, or c.

A minus sign (-) within square brackets indicates a range of consecutive ASCII characters. For example, `[0-9]` is the same as `[0123456789]`. 

If any special character, such as backslash (`\`), asterisk (`*`), or plus sign (`+`), is immediately after the left square bracket, it doesn't have its special meaning and is considered to be one of the characters to match.

|                | Match      | Not match     |
| -------------- | ---------- | ------------- |
| `[0-9]`        | 1, 2, 3    | 12, 01, 22    |
| `[a-zA-Z0-9_]` | a, E, 2, _ | ab, 56        |
| `END[.]`       | END.       | END;   END DO |

- `[ \t\n]`, "任何一个空白类字符",  注意`[ \t\n]`是前面故意有个空格, 
-  `[^ \t\n]`, "任何一个非空白类字符"

计数用, 表达 「前面的样版重复出现多少次」 的 quantifier:

- `{5}` 重复 5 次
- `{3,7}` 重复 3 到 7 次
- `{3,}` 重复至少 3 次
-  `{0,}`重复出现任意次, 包含 0 次
- `{1,}` 重复出现任意次, 至少 1 次

国内的手机号是11位, 所以要查手机号, 我们可以简单的查找大于等于11位数字的字符串, 下面用7位的举例子, 

```shell
$ printf "12345\n12345678\n123\n234567\n1234567" | egrep '[0-9]{7}'        
12345678
1234567
```

如果想要查找就是准确的7位的数字呢?

```shell
$ printf "12345\n12345678\n123\n234567\n1234567" | ggrep -E '\b[0-9]{7}\b' 
1234567
```

## 4. `$` & `^`

`$` The pattern `hello$` will match the word "hello" only if it appears at the end of a line.

```shell
$ printf "My name is Jack\nHi Jack, this is John\nYou and Jack will come..\ndfHelloJack" | egrep 'Jack$'
My name is Jack
dfHelloJack
```

 `^` Can be used to match the start of a line. For instance, the pattern `^Hello` will match any line that begins with "Hello."

For example, the pattern `^hello$` will only match the exact string "hello" and not "hello world" or "say hello."

```shell
$ printf "Hell 123\n123456\n123\n123 hello" | egrep '^\d+$'        
123456
123
$ printf "Hell 123\n123456\n123\n123 hello" | egrep '\d{3}'        
Hell 123
123456
123
123 hello
$ printf "Hell 123\n123456\n123\n123 hello" | egrep '\b\d{3}\b'    
Hell 123
123
123 hello
```

## 5. e.g.

在一篇文章当中, 抓出所有 「看起来像是机场代码的字符串」 (例如 TPE 台北, KHH 高雄, LAX 洛杉矶, ... 等等): `\b[A-Z][A-Z][A-Z]\b`。 这里的 `[A-Z]` 是 [ABCDEFGHIJKLMNOPQRSTUVWXYZ] 的简写, 意思是 「任何一个大写字母」

如何在一大片文本, 银行账号, 信用卡号... 当中, 找出看来像是移动电话号码的字符串, 例如 0912345678 或是 0912-345678 或是 0912-345-678 之类的? `09\d\d-?\d\d\d-?\d\d\d` 这里的` \d` 是 [0-9] 的简写, 这又是 [0123456789] 的简写, 意思是 「任何一个数字字符」

想要找一组数字 ip (例如 168.95.1.1 或 163.17.9.176 之类的) 印象中在某个文件内曾看过, 但既不记得精确的数字, 也不记得在那个文件看过, 该怎么办? 可以搜索 `\d+\.\d+\.\d+\.\d+` 抓出所有数字 ip。 这里的` +` 表示 「前面的东西, 可以重复出现 1 次, 2 次, 3 次, ... 任意次」。 因为 . 在 regexp 当中有特殊的意义: 「任何一个字符」; 但在这里我们就是要找 "." 于是在前面加上 \ 以取消它的特殊意义。

可以把一个文本文件里面的所有空白列都删掉吗? 这个 regexp 可以抓出所有空白列: `^\s*$`。 在 regexp 最前面放一个 `^` 表示您只对 「出现在一列之首」 的样版有兴趣; 在 regexp 的最后面放一个 `$` 表示您只对 「出现在一列之尾」 的样版有兴趣。 `\s` 是` [\t\n]` 的简写, 意思是 「任何一个空白字符」 (包含空格, tab, 等等)。 `*` 表示 「前面的东西, 可以重复出现 0 次, 1 次, 2 次, ... 任意次」。 这个样版翻译成中文, 就是 「从头到尾都是一片空白的那种列」。

| `\`     | `\` is used to escape special chars: `\*`matches `*` |
| ------- | ---------------------------------------------------- |
| [abc]   | any of a, b, or c                                    |
| [^abc]  | not a, b, or c                                       |
| [a-g]   | character between a & g                              |
| [^adgf] | 代表不是a, d, g或f的字符                                |

```shell
# 忽略大小写
$ printf "Hello\nHeal\ntold\nhello" | egrep '(?i)LL' 
Hello
hello
# 找出带后缀的文件
$ ls /etc/ | egrep '\.\w+$'  
```

References:

- [Regexp 是什么东东?](https://www.cyut.edu.tw/~ckhung/b/re/intro.php)

- [Top 15 Commonly Used Regex - Digital Fortress](https://digitalfortress.tech/tips/top-15-commonly-used-regex/)

- [Perl 常用的 regexp 规则列表](https://www.cyut.edu.tw/~ckhung/b/re/rules.php)
