---
title: Wget Connecting Timeout Issue
date: 2024-03-29 20:28:22
categories:
 - build website
tags:
 - build website
typora-root-url: ../../../static
---

## 1. Issue

When I use `wget` to download some files, I got the following error:

```shell
$sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
Connecting to raw.githubusercontent.com (raw.githubusercontent.com)|2606:50c0:8002::154|:443...
```

You can use `curl` to replace `wget`, or you can get the ip address of the domain and add it to `/etc/hosts` file.

```shell
185.199.108.133 raw.githubusercontent.com
```

You can find the ip address with `dig/ping` command or on the some online tool website. ping probably won't work. 