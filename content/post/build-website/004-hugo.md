---
title: "Write Blog with Hugo & Deploy to Github Pages"
date: 2023-08-31 23:51:57
categories:
 - build website
tags:
  - hugo
---

## 1. Recover

```shell
$ brew install hugo
$ hugo new site blog && cd blog
```

## 2. Deploy to Github Pages

### 2.1. Local Repository

```shell
$ cd blogs/public/
$ git init
$ git remote add origin git@github.com:shwezhu/shwezhu.github.io.git
...
$ git branch -M master
$ git push origin master
```

### 2.2. Remote Repository

Go to Settings -> Pages -> Build and deployment

Source: depoly from a branch

Branch: choose `master`

Then go to Actions options, you can see your page is building in progess, when it finished, visit: https://your-username.github.io

> You probably need wait about 10 mintes even your the processof building bolgs has been finished, try to clear cache of your browser and restart your browser if you constantly get 404 page for yor website. 

## 3. Custom Domain (optional)

Update DNS Records of your domain according to the provided ip address by github:

![a](/004-hugo/a.png)

Go to Settings -> Pages -> Custom domain: input your domain. And wait about 15 mintes to take effect (try to clear your browser cache). 

If https cannot enable, try to remove your custom domain and wait minutes add again. The CNAME DNS Records has to be set to`www`, when I set `blog` the https cannot be enabled. 

Learn more: https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site

## 4. Issues - 404 page

Hugo will make the url into lowercase automatically, therefore, make sure all you blog files and folders under `/content/post/` are lowercase. Otherwise, you will get 404 for that blog. 

And if you didn't make it lowercase before generate html pages with `hugo` command, then you need delete all the generated html files under `/public/post/` then run `hugo` command again, this should work. 

## 5. Insert Images

Put images under `/static/file-name/` and insert image with`![](/file-name/xxx.png)`, 

On Typora, go to settings -> images -> When instert, choose custome folder and write someting like this:

```shell
/Users/David/blogs/static/${filename}
```

then, write `typora-root-url: ../../../static` at front matter of blog, if you don't know how to wtite, you can choose option: 

Fromat -> Image -> Use Image Root Path, then typora will add someting like `typora-root-url: ../../../static` in yur md file at the front matter part. Then both typora and website will disply image correctly. 

## 6. Backup & Recover

### 6.1. Backup

Please check: [Backup Blogs with Git - David's Blog](https://shaowenzhu.top/post/git/practice/003-blog-backup/)

### 6.2. Recover

```shell
hugo new site blogs
```

Copy the files stored in [github](https://github.com/shwezhu/shwezhu.github.io) into folder `blogs/`, then

```shell
hugo server
```

and visit localhost to check...

References: https://olowolo.com/post/hugo-quick-start/

