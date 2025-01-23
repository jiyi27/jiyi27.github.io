---
title: Go File Server Cannot Handle Large Files
date: 2023-11-30 21:43:22
categories:
 - bugs
tags:
 - bugs
 - golang
---

## 1. Problem description

I've discussed how to use Cloudflare as a [reverse proxy](https://www.cloudflare.com/learning/cdn/glossary/reverse-proxy/) for my web traffic in [previous post](https://blog.yorforger.cc/post/build-website/008-cloudflare-cdn/). 

I write a [file server](https://github.com/shwezhu/file-server) in Go, when attempting to upload a file of approximately 200 MB, it becomes very slow (always uploading) and never succeed. Upon monitoring the server using tools like `htop`, it seems that the server might be unaware of the incoming large file upload. I come across a error by chance:  **413 Request Entity Too Large**. 

## 2. Cloudflare

Then I found this is because the limitation of Couldflare proxy:

> There’s a **body size** limit of 100 MB on Free and Pro, 200 MB on Business and [50074](https://community.cloudflare.com/t/community-tip-fixing-error-500-internal-server-error/44453) MB on Enterprise. Only Enterprise customers can request to have the body size limit increased. 
>
> Each user can only upload files with maximum size of 100MB at a time **if your website is proxied by Cloudflare.** 
>
> [Does the 100 Mb limit apllies to all users on my website?](https://community.cloudflare.com/t/does-the-100-mb-limit-apllies-to-all-users-on-my-website/297261)

So this is the thing, then I try to access my website directly by IP address (bypass the Cloudflare proxy). 

## 3. VPS RAM

Then I can see my file server handling the incoming request whose body larger than 100MB, I use `htop` to check the RAM usage status on my VPS, I can see the ram increase from 50MB to 100MB then 200MB, then my file server get killed by the OS. 

My VPS RAM is 512MB, and there is 460MB left, I don't know why the OS kill my file server program. 

## 4. Golang

Besides, when I tried to upload some files whose size is around 60MB, the RAM usage of my VPS increase from 50MB (total) to around 100MB, this makes sense, because the file server needs load the whole file to the RAM and copy the content to the disk. 

But after handling this request, the RAM usage is still around 100MB, if I upload another file (60MB), then the RAM usage increases to around 160MB. I thought there is memory leak on my program. But I was wrong. I found a post and share it here:

> Go does not release memory it allocated from the OS immediately. The reason is probably that allocating memory is costly (needs system calls) and the chance is high that it will be needed in the near future anyway again. But, if memory gets long enough unused it will be released eventually so that the **RSS** of the process decreases again.
>
> Learn more: https://stackoverflow.com/a/49843380/16317008

> RSS indicates the actual physical memory consumed by a process, while VSZ includes not only the physical memory but also the virtual memory. 
>
> Learn more: https://stackoverflow.com/a/21049737/16317008
