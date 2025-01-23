---
title: ChatGPT Bot
date: 2023-11-14 00:07:25
categories:
  - python
tags:
  - python
typora-root-url: ../../../../static
---

## 1. Official Docs

- Make request for the RESTful API of OpenAI: [API Reference - OpenAI API](https://platform.openai.com/docs/api-reference/chat/create)
- Error status code for HTTP response: [Error codes - OpenAI API](https://platform.openai.com/docs/guides/error-codes)
- Stream [cookbook.openai.com/examples/how_to_stream_completions](https://cookbook.openai.com/examples/how_to_stream_completions)
  - [How to Print ChatGPT API Response as a Stream – PuppyCoding](https://puppycoding.com/2023/07/08/stream-chatgpt-response/)
- Cookbook: https://cookbook.openai.com/

![aa](/002-chatgpt-ai-bot-1/aa.png)

## 2. Stream message

If you write code like this:

```python
respense = openai.create(...)
for chunk in response:
    if chunk.choices[0].delta.content is not None:
          print(chunk.choices[0].delta.content, end="", flush=True)
```

You probably won't get the result you want, your program will print line by line, not word by word. 

The actual reason is that Python buffers the chunks before printing them, whereas we want them printed as soon as they’re ready. To do this, we add a `flush = True` parameter to tell Python to flush the buffer with each chunk.

```python
def handle_stream(response):
  for chunk in response:
      if chunk.choices[0].delta.content is not None:
          print(chunk.choices[0].delta.content, end="", flush=True)
  print()
```

> Normally output to a file or the console is buffered, with text output at least **until you print a newline**. The flush makes sure that any output that is buffered goes to the destination. https://stackoverflow.com/a/15608262/16317008


### 3. Task types

- [Completions](https://platform.openai.com/docs/api-reference/completions): Given a prompt, the model will return one or more predicted completions. 

```shell
POST https://api.openai.com/v1/completions
```

- [Chat](https://platform.openai.com/docs/api-reference/chat): Given a list of messages describing a conversation, the model will return a response.

```shell
POST https://api.openai.com/v1/chat/completions
```

- [Images](https://platform.openai.com/docs/api-reference/images): Given a prompt and/or an input image, the model will generate a new image.

```shell
POST https://api.openai.com/v1/images/generations
```

## 4. Openai package error: urllib3 only supports OpenSSL

After import openai package, an error occurred:

```
ImportError: urllib3 v2.0 only supports OpenSSL 1.1.1+, currently the 'ssl' module is compiled with LibreSSL 2.8.3. See: https://github.com/urllib3/urllib3/issues/2168
```

[urllib3](https://urllib3.readthedocs.io/en/stable/) is a Python package for making HTTP requests, which is an HTTP client (like a browser):

```python
>>> import urllib3
>>> resp = urllib3.request("GET", "https://httpbin.org/robots.txt")
>>> resp.status
200
>>> resp.data
b"User-agent: *\nDisallow: /deny\n"
```

Solution: https://davidzhu.xyz/post/python/practice/003-openssl-issue/

References: 

- [A Complete Guide to the ChatGPT API](https://www.makeuseof.com/chatgpt-api-complete-guide/?newsletter_popup=1)
- [Fixing ImportError: urllib3 v2.0 only supports OpenSSL 1.1.1+ | Level Up Coding](https://levelup.gitconnected.com/fixing-importerror-urllib3-v2-0-5fbfe8576957)
- [python - ImportError: urllib3 v2.0 only supports OpenSSL 1.1.1+, currently the 'ssl' module is compiled with LibreSSL 2.8.3 - Stack Overflow](https://stackoverflow.com/questions/76187256/importerror-urllib3-v2-0-only-supports-openssl-1-1-1-currently-the-ssl-modu)
- [OpenAI ChatGPT (GPT-3.5) API error: "'messages' is a required property" when testing the API with Postman - Stack Overflow](https://stackoverflow.com/questions/75971578/openai-chatgpt-gpt-3-5-api-error-messages-is-a-required-property-when-tes)
- [GPT - OpenAI API](https://platform.openai.com/docs/guides/gpt/chat-completions-vs-completions)
- [GPT-3.5-turbo how to remember previous messages like Chat-GPT website - API - OpenAI Developer Forum](https://community.openai.com/t/gpt-3-5-turbo-how-to-remember-previous-messages-like-chat-gpt-website/170370/6)