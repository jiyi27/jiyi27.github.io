---
title: 正则表达式之关于'(? … )'的困惑
date: 2023-05-02 23:30:28
categories:
 - regex
tags:
 - regex
---

最初想筛选以`sh`结尾但前面没有`.`的文件, 对应的Regex为`(?<!\.)sh$`, 但是! 刚开始不知道`(?!)`,`(?=)`,`(?<!)`这种写法规则, 就在想用逻辑与写出以`sh`结尾的字符但不以`.sh`结尾, 但这本身就矛盾啊, 以`.sh`结尾本身就是以`sh`结尾啊,,, 研究了俩小时, 太菜了,,,, 又快凌晨一点了, 

在[StackOverflow](https://stackoverflow.com/a/2973495/16317008)看到一个好的回答, 

 Given the string `foobarbarfoo`:

```shell
bar(?=bar)     finds the 1st bar ("bar" which has "bar" after it)
bar(?!bar)     finds the 2nd bar ("bar" which does not have "bar" after it)
(?<=foo)bar    finds the 1st bar ("bar" which has "foo" before it)
(?<!foo)bar    finds the 2nd bar ("bar" which does not have "foo" before it)
```

You can also combine them:

```shell
(?<=foo)bar(?=bar)    finds the 1st bar ("bar" with "foo" before it and "bar" after it)
```

使用这种 lookaround 句型的时候要注意上面的写法, 即 `(?!bar)` 就是用来指定某个单词后**不含有**什么的, 还有一个重要的点如下:

>  In the meantime, if there is one thing you should remember, it is this: **a lookahead or a lookbehind does not "consume" any characters on the string**. This means that after the lookahead or lookbehind's closing parenthesis, the regex engine is left standing on the very same spot in the string from which it started looking: it hasn't moved. From that position, then engine can start matching characters again. 

即这些Lookaround只是用来检查check的, 是个附加条件:

```shell
$ printf "handle_test.go" | grep -P 'test(?=.)go'
```

凭直觉 `'test(?=.)go'` 匹配的是含有 `test` 且其后紧跟着 `.go`, 可是 `"handle_test.go"` 并不满足 `'test(?=.)go'`,  因为`(?=.)` 匹配到了 `.` 并没有消耗掉它, 要这么写才行: `'test(?=.).go'` ,但这样看着很奇怪 并不是这么用的, 其实直接写 `'test(?=.go)'` 就好了, 

参考:

- [Advanced Regex Tutorial—Regex Syntax](https://www.rexegg.com/regex-disambiguation.html#lookarounds)

- [lookaround - Regex lookahead, lookbehind and atomic groups - Stack Overflow](https://stackoverflow.com/questions/2973436/regex-lookahead-lookbehind-and-atomic-groups)
