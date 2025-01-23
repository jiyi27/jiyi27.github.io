---
title: MIME Types
date: 2023-11-06 22:06:07
categories:
 - http
tags:
 - http
---

## 1. Background

When I first started writing backend code, if the server return a file (any type), and I would add a `Content-Type` header and set its value to `application/octet-stream`:

```go
w.Header().Set("Content-Disposition", "attachment; filename="+strconv.Quote(info.Name()))
w.Header().Set("Content-Type", "application/octet-stream")
http.ServeFile(w, r, filePath)
return
```

I don't know what does this mean, but it works. Haha, it's not a good habit, so I decide to take some time to learn it. 

## 2. MIME types 

A **media type** (also known as a **Multipurpose Internet Mail Extensions or MIME type**) indicates the nature and format of a document, file, or assortment of bytes. 

### 2.1. Structure of a MIME type

```
type/subtype
```

The **type** represents the general category into which the data type falls, such as `video` or `text`.

The **subtype** identifies the exact kind of data of the specified type the MIME type represents. For example, for the MIME type `text`, the subtype might be `plain` (plain text), `html` ([HTML](https://developer.mozilla.org/en-US/docs/Glossary/HTML) source code), or `calendar` (for iCalendar/`.ics`) files.

An optional **parameter** can be added to provide additional details:

```
type/subtype;parameter=value
```

For any MIME type whose main type is `text`, you can add the optional `charset` parameter to specify the character set used for the characters in the data. If no `charset` is specified, the default is [ASCII](https://developer.mozilla.org/en-US/docs/Glossary/ASCII) (`US-ASCII`) unless overridden by the [user agent's](https://developer.mozilla.org/en-US/docs/Glossary/User_agent) settings. To specify a UTF-8 text file, the MIME type `text/plain;charset=UTF-8` is used.

There are two classes of type: **discrete** and **multipart**: https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_Types#types

## 3. Common MIME types

### 3.1. application/octet-stream

This is the default for binary files. As it means *unknown binary* file, **browsers usually don't execute it, or even ask if it should be executed**. They treat it as if the [`Content-Disposition`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition) header was set to `attachment`, and propose a "Save As" dialog.

### 3.2. text/plain

This is the default for textual files. Even if it really means "unknown textual file," **browsers assume** they can display it.

### 3.3. text/css

CSS files used to style a Web page **must** be sent with `text/css`. If a server doesn't recognize the `.css` suffix for CSS files, it may send them with `text/plain` or `application/octet-stream` MIME types. If so, they **won't be recognized as CSS by most browsers and will be ignored**.

Learn more: [Common MIME types - HTTP | MDN](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types)

References: [MIME types (IANA media types) - HTTP | MDN](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_Types)
