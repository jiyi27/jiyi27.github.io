---
title: EF Core Basics
date: 2024-07-21 09:42:36
categories:
 - C#
tags:
 - C#
 - .Net
 - ORM
---

## 1. Rider EF Core - Migrations

Install `Microsoft.EntityFrameworkCore.Design`, which requires `Microsoft.EntityFrameworkCore.Relational`, so you need install both. I think the reason is I use `MySQL`: `Pomelo.EntityFrameworkCore.MySql` not `Microsoft.EntityFrameworkCore.SqlServer` which is for SqlServer. 

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2024/07/59a2dbaca023bf392c27b1fee76301ae.jpg)

> Note that because the dependency of  `Pomelo.EntityFrameworkCore.MySql` , the version of design and relational an other should be <= 1.xxxx. So I choose 9.0.0-preview.1.24081.2

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2024/07/c39483831dbc9c97e1723ea70991f405.jpg)

Everytime update database with migrations, there is warning: 

```
The Entity Framework tools version '8.0.7' is older than that of the runtime '9.0.0-preview.1.24081.2'. Update the tools for the latest features and bug fixes. See https://aka.ms/AAc1fbw for more information.
```

To resolve this issue:

```bash
❯ dotnet tool update --global dotnet-ef
Tool 'dotnet-ef' was reinstalled with the stable version (version '8.0.7').

~
❯ dotnet tool update --global dotnet-ef --version 9.0.0-preview.1.24081.2
Tool 'dotnet-ef' was successfully updated from version '8.0.7' to version '9.0.0-preview.1.24081.2'.
```

