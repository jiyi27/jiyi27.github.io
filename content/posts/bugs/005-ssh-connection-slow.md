---
title: ssh session vary slow
date: 2023-09-25 14:30:22
categories:
 - Bugs
tags:
 - Bugs
 - ssh
---

Connecting to my aws server with ssh client is very slow, and after connected, the session is very slow too. 

Like input a command in the ssh session and you have to wait seconds to get the output, lots of latency. 

Then I think maybe there is a "bad" process which takes a lot of cpu usages makes my server in high load, or there is a high network traffic. Then I use `top` command to check, then I got this:

```shell 
$ top
60841 asterisk -11   0 1025372 325376   9300 R  99.9  32.9 980:16.51 asterisk
```

The asterisk which takes up 99.9% of my cup!!!

Thenk I kill it with

```shell
sudo kill 60841
```

Then my server works fine. 