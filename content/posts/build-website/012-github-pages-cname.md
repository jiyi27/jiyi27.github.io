---
title: CNAME 指向 GitHub Pages 问题
date: 2024-04-07 21:43:22
categories:
 - build website
 - networking
tags:
 - build website
 - networking
---


我正使用 github pages 自定义域名功能, 然后我为我的域名yorforger.cc 添加了一个 CNAME 记录即: blog.yorforger.cc -> shwezhu.github.io

然后我在 GitHub pages 的自定义域名页面填入 blog.yorforger.cc, 然后一切工作正常, 我可以通过 blog.yorforger.cc 来访问我部署在 GitHub pages 上的博客. 

我还有个域名 yorblogger.top 托管在了 Cloudflare, 我就想 是不是 我可以给它添加一个 CNAME 记录, 比如: blog.yorblogger.top -> blog.yorforger.cc 

这样当我访问 blog.yorblogger.top, DNS 服务器会去查询  blog.yorforger.cc 的地址, 最后找到 shwezhu.github.io 然后访问我的博客, 但是当我尝试在浏览器访问blog.yorblogger.top  的时候, github 提示 404: There isn't a GitHub Pages site here. 

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2024/04/7f104bcc413e691178004d8951742056.jpg)

可以看到我确实通过 blog.yorblogger.top 访问到了 shwezhu.github.io, 但是 GitHub Pages 服务器返回了 404 错误, 这是为什么呢?

我看到了类似的问题 [Can github pages CNAME file contain more than one domain? - Stack Overflow](https://stackoverflow.com/questions/16454088/can-github-pages-cname-file-contain-more-than-one-domain)

> No, this is not possible. See the GitHub Help [docs](https://arc.net/l/quote/gmhptdpc) that explain this:
> Ensure you only have one domain listed in your CNAME file. If you wish to have multiple domains pointing to the same Pages, you will need to set up redirects for the other domains. Most domain registrars and DNS hosts offer this service to their customers.

根据文档, 我们需要设置重定向, 刚好 Cloudflare 也提供了这个服务, 具体可参考: [Redirect one domain to another](https://developers.cloudflare.com/fundamentals/setup/manage-domains/redirect-domain/)

根据文档, 随便为我的域名添加了个 A 记录, 然后设置重定向规则, 具体如下:

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2024/04/7d0a797bd3f1e98c7de8d7d7388fac0d.jpg)

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2024/04/176b23e1da3ae0cd1a52f0b8c1796558.jpg)

此时, 当我访问 yorblogger.top 时, 会自动重定向到 blog.yorforger.cc, 一切工作正常.

后来我想让 blog.yorblogger.top 重定向到 blog.yorforger.cc, 然后简单设置了一下:

- 在 DNS Record 把 www 记录改为 blog
- 去 Rules -> Redirect Rules 添加一个规则, 与上图相同只是把 hostname=yorblogger.top 改为 hostname=blog.yorblogger.top
