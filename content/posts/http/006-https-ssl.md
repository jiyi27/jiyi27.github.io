---
title: HTTPS 连接建立过程 (TLS 握手)
date: 2023-10-07 08:30:26
categories:
  - http
tags:
  - http
  - https
  - ssl
  - 网络安全
---

## 1. HTTP vs HTTPS

Strictly speaking, HTTPS is not a separate protocol, but refers to use of ordinary HTTP over an encrypted SSL/TLS connection. 

Port 80 is typically used for unencrypted [HTTP](https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol) traffic while port 443 is the common port used for encrypted HTTP traffic which is called  [HTTPS](https://en.wikipedia.org/wiki/HTTPS). 

> Note that TLS is the successor of SSL, you can simply think they are same thing. 

 Source: https://en.wikipedia.org/wiki/HTTPS#Network_layers

## 2. What is TLS/SSL

SSL (Secure Sockets Layer) and its successor, TLS (Transport Layer Security), are protocols for establishing ***authenticated*** and ***encrypted*** links between networked computers.

HTTPS, HTTP, and TLS are all protocols. HTTPS utilizes the encryption and digital authentication provided by SSL/TLS, while SSL/TLS utilizes some cryptographic algorithms within the protocol in different phases, such as RSA is used at session key exchange stage, AES is used during data transfer. Encryption can be further divided into two types: 

- Symmetric Encryption Algorithms: AES, etc. 

- Asymmetric Encryption Algorithms (public key cryptography): RSA, ECC, etc.

## 3. The process of establishing a HTTPS connection

When we click a link on our browser will send a or multiple http requets to the target server, then the server will respond us with html file or some images or other resources. But transfer data there are other things needed to do under the hood:

- A tcp connection needed to be established (envolves three way handshake). 
- Make a [TLS handshake](https://www.cloudflare.com/learning/ssl/what-happens-in-a-tls-handshake/)
- After TLS handshake,  the secure communication begins (client makes http request, server makes response). 

During the TLS handshake, the client generates a session key and encrypts it with the public key of the server and then send the encrypted session key string to the server, then the server decrypt this  string to get the actual session key. Then they make communication with this session key. Now you should understand why I say TLS/SSL use both RSA and AES encryption algorithms at different phrases in previous part. 

> Note that SSL/TLS is a stateful protocol, whereas HTTP/HTTPS is a stateless protocol.  
>
> **TLS/SSL is stateful.** The web server and the client (browser) cache the session including the cryptographic keys to improve performance and do **not** perform key exchange for every request. [Source](https://stackoverflow.com/a/33681674/16317008)

## 4. Details in TLS handshake

I have talked man-in-middle attack in other [post](https://davidzhu.xyz/post/cs-basics/002-ssh/), when a ssh connection is being established at the first time, it will notify us the fingerprint of the server which enables us can make sure to we are connecting the right server. But it's a little diffenent in SSL/TLS (HTTPS). The authenciation happens in the TLS handshake, the authenciation here means to prevent man-in-the-middle attack by verifying the identity of the remote server. 

The protocols use a handshake with an [asymmetric cipher](https://en.wikipedia.org/wiki/Asymmetric_cipher) to establish not only cipher settings but also a session-specific shared key with which further communication is encrypted using a [symmetric cipher](https://en.wikipedia.org/wiki/Symmetric_cipher). During this handshake, the client and server agree on various parameters used to establish the connection's security:

- 客户端跟对方说："你好，我想安全地聊天，我可以用这些加密方式..."

- 对方回应："好的，那我们就用这种加密方式吧"

- 对方给你看他的 TLS 数字证书, 这个身份证上有：他的名字、公开的联系方式（公钥）、以及一个权威机构（CA）的盖章. 

- 浏览器验证证书是不是真的
- 建立专属密码阶段 客户端随机生成一个随机数, 

- 方式一：客户端随机生成一个随机数, 用对方的公开联系方式（公钥）加密后发给他
- 方式二：你们俩一起用一个特殊的数学方法（Diffie-Hellman）, 各自算出一个相同的暗号
- 你们用刚才约定的暗号加密之后的所有对话

> 最开始 (握手阶段) 用的是不对称加密, 之后实际传输数据是对称加密

Source: https://en.wikipedia.org/wiki/Transport_Layer_Security

Learn more: https://www.cloudflare.com/learning/ssl/what-happens-in-a-tls-handshake/

## 5. Two ways to get SSL/TLS certificate

There are several ways to obtain an SSL/TLS certificate: 

Purchase from a Certificate Authority (CA): Trusted CAs offer various types of certificates, such as domain validation (DV), organization validation (OV), and extended validation (EV). A CA is an outside organization, a trusted third party, that generates and gives out SSL certificates. The CA will also digitally sign the certificate with their own private key, **allowing client devices to verify it**. Once the certificate is issued, it needs to be installed and activated on the website's origin server. 

Technically, anyone can create their own SSL certificate by generating a public-private key pairing and including all the information mentioned above . Such certificates are called self-signed certificates because the digital signature used, instead of being from a CA, would be the website's own private key. While self-signed certificates provide encryption for your website or application, they are not trusted by default by web browsers or other client applications. Therefore, visitors accessing your site will typically see a warning message stating that the certificate is not trusted. Learn more: [How to generate a self-signed SSL certificate using OpenSSL?](https://stackoverflow.com/questions/10175812/how-to-generate-a-self-signed-ssl-certificate-using-openssl)

## 6. Is HTTPS secure enough?

Does an established HTTPS connection mean the line is really secure?

It's important to understand what SSL does and does not do, especially since this is a very common source of misunderstanding.

- It encrypts the channel
- It applies integrity checking
- It provides authentication

So, the quick answer should be: "yes, it is secure enough to transmit sensitive data". However, things are not that simple. There are a few issues here, **the major one being authentication**. Both ends need to be sure they are talking to the right person or institution and no man-in-the-middle attack or CSRF attacks. 

HTTPS is secure in encryption. HTTPS is secure itself but if we can totally trust HTTPS connection when exhcange privacy data is another thing. Although **no one can decrept the data without the session key**, there probably have man-in-the-middle attck or CSRF attck needs to be considered which make the hackers get your money without getting your sensitive data . If you can make sure the client is really that people you want talk as a server or you can make sure the server is the correct server you want to get, then https is safe. Can you make sure the server itself is a bad company? Which will sell your personal data to other perople. But this is another topic, haha, In the last I'll share a [answer](https://stackoverflow.com/a/5310027/16317008) here which is very comprehensive:

**Question:** Consider a scenario, where user authentication (username and password) is entered by the user in the page's form element, which is then submitted. The POST data is sent via HTTPS to a new page (where the php code will check for the credentials). If a hacker sits in the network, and say has access to all the traffic, is the Application layer security (HTTPS) enough in this case ?

**[Answer 1](https://stackoverflow.com/a/5310032/16317008):** Yes. In an HTTPS only the handshake is done unencrypted, but even the HTTP GET/POST query's are done encrypted.

It is however impossible to hide to what server you are connecting, since he can see your packets he can see the IP address to where your packets go. If you want to hide this too you can use a proxy (though the hacker would know that you are sending to a proxy, but not where your packets go afterwards).

**[Answer 2](https://stackoverflow.com/a/5310288/16317008):** HTTPS is sufficient "if" the client is secure. Otherwise someone can install a custom certificate and play man-in-the-middle. 

References:

- [Does an established HTTPS connection mean a line is really secure? - Information Security Stack Exchange](https://security.stackexchange.com/questions/5/does-an-established-https-connection-mean-a-line-is-really-secure)
- [php - POST data encryption - Is HTTPS enough? - Stack Overflow](https://stackoverflow.com/questions/5309997/post-data-encryption-is-https-enough)

