---
title: Curl Basics
date: 2023-09-22 22:58:30
categories:
 - http
tags:
 - http
---

## 1. POST data with Curl

The `Content-Type` header can be `application/json`, `application/x-www-form-urlencoded`, `multipart/form-data`, the first two is usually used with posting form data to server, the third is used to upload file to the server.

- The format of `application/json` is `'{"username":"davidzhu", "password":"778899a"}'`. 

- The format of `application/x-www-form-urlencoded` is `"username=davidzhu&password=778899a" `. 

e.g., 

POST **x-www-form-urlencoded format** form data to server:

```shell
# curl will set the request header to 'application/x-www-form-urlencoded' by default
curl localhost:8080/hello -d "username=davidzhu&password=778899a" 
```

POST **json format** data with curl:

```shell
# you need specify the Content-Type header to application/json explictly
curl -X POST [URL]
     -H "Content-Type: application/json" 
     -d '{"username":"davidzhu", "password":"778899a"}'
```

> Note that we use single quote to wrap the double quote which makes double quote lose its special meaning, it's just all about shell scripting, learn more: [Shell Script Basic Syntax - David's Blog](https://davidzhu.xyz/post/linux/002-bash-basics/#5-quotes)

Bad example:

```shell
# Bad example
curl localhost:8080/hello -d '{"username":"davidzhu", "password":"778899a"}'
```

The server will parse it wrong, because the data format is json obviously, but `curl` will set the `Content-Type` header to `application/x-www-form-urlencoded` by default. Therefore, don't write it wrong, otherwise, your server won't parse data from the request correctly. 

The content below form the [docs](https://reqbin.com/req/c-dwjszac0/curl-post-json-example) of curl, hope it will help:

To make a POST request with Curl, you can run the Curl command-line tool with the `-d` or `--data` command-line option and pass the data as the second argument. **Curl will automatically select the HTTP POST method and application/x-www-form-urlencoded content type** if the method and content type are not explicitly specified. [Source](https://reqbin.com/req/c-g5d14cew/curl-post-example) 

If you submit data using Curl and do not explicitly specify the [Content type](https://reqbin.com/req/c-woh4qwov/curl-content-type), Curl uses the application/x-www-form-urlencoded content type for your data. **Therefore, when sending JSON (or any other data type), you must specify the data type using the -H "Content-Type: application/json" command line parameter**.

```shell
$ curl localhost:8080/hello 
    -H "Content-Type: application/json"
    -d '{"Id": 79, "status": 3}'  
```

Learn more: [application/x-www-form-urlencoded and multipart/form-data](https://javarevisited.blogspot.com/2017/06/difference-between-applicationx-www-form-urlencoded-vs-multipart-form-data.html) 

Learn more about http request header: https://davidzhu.xyz/post/cs-basics/018-http-messages/

## 2. Query string with curl

```shell
$ curl -X POST "localhost:8080/postform?username=david&password=778899a"
# The code below won' work (you have to make it with double quote):
$ curl -X POST localhost:8080/postform?username=david&password=778899a # wrong
```

