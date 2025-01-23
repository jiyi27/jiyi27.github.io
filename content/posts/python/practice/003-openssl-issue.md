---
title: urllib3 not compatible with openssl issue - python
date: 2023-10-07 12:01:25
categories:
  - python
tags:
  - python

typora-root-url: ../../../../static
---

> OpenSSL is an all-around cryptography library that offers an open-source application of the TLS protocol. It allows users to perform various SSL-related tasks, including CSR (Certificate Signing Request) and private keys generation, and SSL certificate installation. You can use OpenSSL's commands to generate, install and manage SSL certificates on various servers.  [What Is OpenSSL and How Does It Work?](https://www.ssldragon.com/blog/what-is-openssl/) 

OpenSSL is a library, so there should be API interfaces. However, the more common use of OpenSSL is as a command-line tool, which can be entered on a computer

```shell
$ openssl version   
LibreSSL 3.3.6
```

Why the output is LibreSSL? LibreSSL is another version of SSL implementation, which exists alongside OpenSSL. Learn more: [Why You Should Use LibreSSL Instead of OpenSSL](https://www.youtube.com/watch?v=n1uaoJyBwHk) 

OpenSSL is indeed a library, and HTTPS is based on SSL. When establishing a secure connection using SSL, operations such as SSL handshake and identity verification are required. For example, we write a program to make an HTTPS request to a server, do TLS handshake and verifying digital signatures on our own would be challenging. This is where OpenSSL comes in—it handles these complex operations. 

It's possible that some people may have noticed that when sending HTTP requests using Python, OpenSSL was not explicitly used. There are two reasons for this:

1. It could be because you were sending an HTTP request instead of an HTTPS request. You can check if the destination port is set to 80, which is the default port for HTTP.

2. The HTTP library you used in Python may have called the OpenSSL library at its lower levels to handle the complex operations on your behalf. However, you might not have noticed this because it happens behind the scenes. For example, the OpenAI package you mentioned that you recently used internally utilizes OpenSSL, but you wouldn't be able to detect it without examining the source code:

```python
import openai

openai.api_key = "Your Key"
# make https request here
response = openai.ChatCompletion.create(
    model="gpt-3.5-turbo",
    messages=[
        {"role": "user", "content": "Who won the 2018 FIFA world cup?"}
    ]
)
print(response['choices'][0]['message']['content'])
```

When I run the code above, there is an error:

```shell
ImportError: urllib3 v2.0 only supports OpenSSL 1.1.1+, currently the 'ssl' module is compiled with LibreSSL 2.8.3. See: https://github.com/urllib3/urllib3/issues/2168
```

`openai` package utilizes a Python package called urllib3, which is used for sending HTTP requests. urllib3 relies on a built-in Python library called ssl, which internally calls OpenSSL's related interfaces for tasks such as session creation and certificate verification. 

However, from your Python code's perspective, you're just using the ssl module's high-level API. You don't have to interact directly with OpenSSL - it's an implementation detail hidden by the SSLContext and socket wrapping methods. So in short, the Python SSL library uses the OpenSSL library under the hood to actually perform SSL handshakes, key generation, encryption, etc. But from a Python programmer's point of view, you just import ssl and call its APIs to establish encrypted SSL connections.

![b](/003-openssl-issue/b.png)

So, the error message above is stating that urllib3 version 2.0 only supports OpenSSL 1.1.1+ but the SSL library used on my computer is LibreSSL 2.8.3. (Remember,  `openssl version` earlier, the output is LibreSSL) Since urllib3 version 2.0 does not support the LibreSSL on your computer, the solution would be to switch to a different version of urllib3. 

```shell
pip3 uninstall urllib3 
pip3 install 'urllib3<2.0' 
```

Alternatively, I could consider upgrading or changing the version of LibreSSL on my computer to a version that is compatible with urllib3 2.0:

```shell
brew install openssl@1.1
```
