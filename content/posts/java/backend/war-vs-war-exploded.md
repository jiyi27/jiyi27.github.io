---
title: IDEA项目中的War和War Exploded的区别
date: 2023-04-25 14:27:35
categories:
 - Java
 - Backend
tags:
 - Java
---

在IDEA把webapp deploy到tomcat上的时候会看到以下设置:

![](/war-vs-war-exploded/a.png)

![](/war-vs-war-exploded/b.png)

上图中选择war或者war exploded的时候, 如果选择前者, on frame deactivation diaglog就不会有update resources选项:

![](/war-vs-war-exploded/c.png)

有很多疑问比如war和war exploded是什么, update resources和update classes and resources的区别是什么, 这都是干啥的?

## War & War exploded

在使用 IDEA 开发Java Web项目部署 Tomcat 的时候通常会出现下面的情况:

![](/war-vs-war-exploded/d.png)

是选择 `war` 还是 `war exploded`呢? 

看一下他们两个的区别:

- war：将Web Application以包的形式上传到服务器
- war exploded：将Web Application以当前文件夹的位置关系上传到服务器, 因此这种方式支持**hot deployment**，一般在开发的时候也是用这种方式. 

> **Hot deployment** is the process of adding new components (such as WAR files, EJB Jar files, enterprise Java beans, servlets, and JSP files) to a running server without having to stop the application server process and start it again.

所以现在知道上面为啥选择war的话, 在on frame deactivation diaglog就不会有update resources选项了吧. 

## Update Resources & Update Classes and Resources

![](/war-vs-war-exploded/e.png)

1. On Upate Action : update classes and resources 更新代码和资源
2. On Frame Deactivation : update classes and resources在IDE失去焦点时(你点开浏览器离开IDE的时候)更新并发布代码

如果On Upate Action选择了update classes and resources，然后On Frame Deactivation 选择了do nothing, 那你无论是修改了servlet, doGet等动态代码还是jsp，h5等静态资源代码，需要手动更新, 就是你得自己点击那个更新按钮, 然后再刷新浏览器页面, 你的修改才能生效:

![](/war-vs-war-exploded/f.png)

![](/war-vs-war-exploded/g.png)

如果On Upate Action和On Frame Deactivation都选择了update classes and resources，那就是每次修改了servlet代码或者jsp等静态代码后你都不用点击那个更新按钮了, 直接进入浏览器刷新页面就行,这样显然会浪费电脑资源,如果你不心疼cpu, 那就这样最好, 我是心疼, 所以我选择的如下:

![](/war-vs-war-exploded/h.png)

这样每次修改了servlet之后我点击更新按钮, 修改了jsp之后我就不用点击了, 直接进入浏览器刷新页面就可以了.

参考: 

- https://blog.csdn.net/u013626215/article/details/103685304



