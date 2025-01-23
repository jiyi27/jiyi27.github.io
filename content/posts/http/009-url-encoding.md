---
title: URL Encoding (Percent Encoding)
date: 2023-11-20 22:29:19
categories:
 - http
tags:
 - http
typora-root-url: ../../../static
---

URLs can only be sent over the Internet using the [ASCII character-set](https://www.w3schools.com/charsets/ref_html_ascii.asp). Since URLs often contain characters outside the ASCII set, the URL has to be converted into a valid ASCII format.

**Percent encoding** replaces special characters with a "%" followed by two hexadecimal digits that represent the character's ASCII code. 

- URLs cannot contain white spaces. URL encoding normally replaces a white space with a plus (+) sign or with %20.
  - The whitespace character in ASCII has hexadecimal value 0x20
- In URLs, the forward slash (/) is used as a path separator to separate different elements of the URL. 
  - In the case of the forward slash, its ASCII code is 2f, so it is represented as %2f in a URL.

> If the special character (Chinese) doesn't exist in ASCII table, it will use the UTF-8 hexadecimal digits of that special character. 
>
> For example, if you want to include the Chinese characters "中国" (China) in a URL, its UTF-8 encoding would be "%E4%B8%AD%E5%9B%BD". Each Chinese character is encoded as its three-byte UTF-8 representation, prefixed with a percent sign.