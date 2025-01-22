---
title: HTTPS SSL TLS 
date: 2023-10-07 08:30:26
categories:
  - http
tags:
  - https
  - http
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

## 4. Details in TLS handshake - avoid man-in-middle attack

I have talked man-in-middle attack in other [post](https://davidzhu.xyz/post/cs-basics/002-ssh/), when a ssh connection is being established at the first time, it will notify us the fingerprint of the server which enables us can make sure to we are connecting the right server. But it's a little diffenent in SSL/TLS (HTTPS). The authenciation happens in the TLS handshake, the authenciation here means to prevent man-in-the-middle attack by verifying the identity of the remote server. 

Once the client and server have agreed to use TLS, they negotiate a [stateful](https://en.wikipedia.org/wiki/State_(computer_science)) connection by using a handshaking procedure (see [TLS handshake](https://en.wikipedia.org/wiki/Transport_Layer_Security#TLS_handshake)). The protocols use a handshake with an [asymmetric cipher](https://en.wikipedia.org/wiki/Asymmetric_cipher) to establish not only cipher settings but also a session-specific shared key with which further communication is encrypted using a [symmetric cipher](https://en.wikipedia.org/wiki/Symmetric_cipher). During this handshake, the client and server agree on various parameters used to establish the connection's security:

- The handshake begins when a client connects to a TLS-enabled server requesting a secure connection and the client presents a list of supported [cipher suites](https://en.wikipedia.org/wiki/Cipher_suite) ([ciphers](https://en.wikipedia.org/wiki/Encryption) and [hash functions](https://en.wikipedia.org/wiki/Hash_function)).
- From this list, the server picks a cipher and hash function that it also supports and notifies the client of the decision.
- The server usually then provides identification in the form of a [digital certificate](https://en.wikipedia.org/wiki/Public_key_certificate). The certificate contains the [server name](https://en.wikipedia.org/wiki/Hostname), the trusted [certificate authority](https://en.wikipedia.org/wiki/Certificate_authority) (CA) that vouches for the authenticity of the certificate, and the server's public encryption key. (**The digital certificate here is know as SSL/TLS certificate**)
- The client confirms the validity of the certificate before proceeding. (**The client verifies the identity of the remote server by check the digital certificate which is called SSL/TLS certificate here**)
- To generate the session keys used for the secure connection, the client either:
  - encrypts a [random number](https://en.wikipedia.org/wiki/Random_number_generation) (*PreMasterSecret*) with the server's public key and sends the result to the server (which only the server should be able to decrypt with its private key); both parties then use the random number to generate a unique session key for subsequent encryption and decryption of data during the session, or
  - uses [Diffie–Hellman key exchange](https://en.wikipedia.org/wiki/Diffie–Hellman_key_exchange) (or its variant [elliptic-curve DH](https://en.wikipedia.org/wiki/Elliptic-curve_Diffie–Hellman)) to securely generate a random and unique session key for encryption and decryption that has the additional property of [forward secrecy](https://en.wikipedia.org/wiki/Forward_secrecy): if the server's private key is disclosed in future, it cannot be used to decrypt the current session, even if the session is intercepted and recorded by a third party.

This concludes(ends) the handshake and begins the secured connection, which is encrypted and decrypted with the session key until the connection closes. If any one of the above steps fails, then the TLS handshake fails and the connection is not created.

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

