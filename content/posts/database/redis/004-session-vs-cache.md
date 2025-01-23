---
title: Caching & Session Management
date: 2023-10-02 09:37:58
categories:
 - database
tags:
 - database
 - redis
---

## 1. Session

Session is a server-side state management technique that allows the storage and retrieval of user-specific data across multiple requests. It provides a way to maintain state for individual users during their interaction with a web application. Here are some key points about session:

1. Session data is stored on the server, usually in memory or in a session store.
2. Each user is assigned a unique session ID, typically stored as a cookie or in the URL.
3. Session data is private to each user and cannot be accessed by other users.
4. Session data can be accessed and modified throughout the user's session on any page of the application.
5. Session data is available only as long as the session is active. It expires after a certain period of inactivity or can be explicitly cleared.

Sessions are commonly used to store user-specific information such as **user's authorization state, user's privilege**, user preferences, and temporary data needed during the user's session. And recently, I'm writing a chatgpt bot which needs remember user's chat history, this is just a temporary data which need isolated with each user and not that important, session is perfect to store it. 

Learn more: [Session Management - AWS](https://aws.amazon.com/caching/session-management/)

## 2. Caching

Caching is a mechanism used to temporarily store frequently accessed or expensive-to-compute data in order to improve application performance and reduce database or server load. It involves storing data in memory or another fast-access storage location. Here are some key points about caching:

1. Cached data is stored on the server or in a distributed cache, such as Redis or Memcached.
2. Cached data is typically shared among all users of an application and can be accessed across multiple requests.
3. Cached data is often used to store static or infrequently changing data that is expensive to compute or retrieve from a database.
4. Cached data can be set to expire after a certain period or manually invalidated to ensure fresh data is retrieved when necessary.

Caching can help optimize application performance by reducing the need to fetch data from slower data sources, such as databases or external APIs. **It is commonly used to cache database query results, rendered views, frequently accessed configuration settings,** or other expensive computations. 

Don’t use cache to store anything you can’t regenerate. Cache can be deleted in the middle of the session, or even in the middle of a non-atomic operation. Learn more: https://www.v2ex.com/t/109856

## 3. Additional: session management 

There are various ways to manage user sessions including s**toring those sessions locally** to the node responding to the HTTP request **or** designating a layer in your architecture which can **store those sessions in a scalable and robust manner**. Common approaches used include utilizing Sticky sessions or using a Distributed Cache for your session management. 

### 3.1. Sticky Sessions with Local Session Caching

Sticky sessions, also known as *session affinity*, allow you to route a site user to the particular web server that is managing that individual user’s session. The session’s validity can be determined by a number of methods, including a client-side cookies or via configurable duration parameters that can be set at the load balancer which routes requests to the web servers.

Some advantages with utilizing sticky sessions are that it’s cost effective due to the fact you are storing sessions on the same web servers running your applications and that retrieval of those sessions is generally fast because it eliminates network latency. A drawback for using storing sessions on an individual node is that in the event of a failure, you are likely to lose the sessions that were resident on the failed node. In addition, in the event the number of your web servers change, for example a scale-up scenario, it’s possible that the traffic may be unequally spread across the web servers as active sessions may exist on particular servers. If not mitigated properly, this can hinder the scalability of your applications. 

### 3.2. Distributed Session Management

In order to address scalability and to provide a shared data storage for sessions that can be accessible from any individual web server, you can abstract the HTTP sessions from the web servers themselves. A common solution to for this is to leverage an [In-Memory Key/Value store](https://aws.amazon.com/elasticache/) such as [Redis](https://aws.amazon.com/redis/) and [Memcached](https://aws.amazon.com/memcached/).

While Key/Value data stores are known to be extremely fast and provide sub-millisecond latency, the added network latency and added cost are the drawbacks. An added benefit of leveraging Key/Value stores is that they can also be utilized to cache any data, not just HTTP sessions, which can help boost the overall performance of your applications.

A consideration when choosing a distributed cache for session management is determining how many nodes may be needed in order to manage the user sessions. Generally speaking, this decision can be determined by how much traffic is expected and/or how much risk is acceptable. In a distributed session cache, the sessions are divided by the number of nodes in the cache cluster. In the event of a failure, only the sessions that are stored on the failed node are affected. If reducing risk is more important than cost, adding additional nodes to further reduce the percent of stored sessions on each node may be ideal even when fewer nodes are sufficient.

Another consideration may be whether or not the sessions need to be replicated or not. Some key/value stores offer replication via read replicas. In the event of a node failure, the sessions would not be entirely lost. Whether replica nodes are important in your individual architecture may inform as to which key/value store should be used. [ElastiCache](https://aws.amazon.com/elasticache/) offerings for In-Memory key/value stores include [ElastiCache for Redis](https://aws.amazon.com/elasticache/redis/), which can support replication, and [ElastiCache for Memcached](https://aws.amazon.com/elasticache/memcached/) which does not support replication.

There are a number of ways to store sessions in Key/Value stores. Many application frameworks provide libraries which can abstract some of the integration plumbing required to GET/SET those sessions in memory. In other cases, you can write your own session handler to persist the sessions directly.  

Source: https://aws.amazon.com/caching/session-management/

## 4. Conclusion

Sessions are used to store user-specific data across requests, while caching is used to store frequently accessed or expensive-to-compute data to improve application performance, **they’re just unrelated things**. Both mechanisms have their own specific use cases and can be used together to enhance the functionality and performance of application.

Session data could be [stored in many places](https://aws.amazon.com/caching/session-management/), using a MySQL database for example might be acceptable if that is your existing backend. Or you can store session in a central cache server, such as Redis. As you can see, cache is just a way to store data, session can be cached with Redis server or cached just in loacl memory, cache and session is like the car and high way, they are not same thing. But you should note that adding a cache layer will make your application complexed:

> “The real problem is that programmers have spent far too much time worrying about efficiency in the wrong places and at the wrong times; **premature optimization** is the root of all evil (or at least most of it) in programming.” - [Donald Knuth](https://en.wikipedia.org/wiki/Donald_Knuth)

Therefore, premature optimization is always a disaster. It's not too late to add caching when actual bottlenecks are discovered after deployment or users' feedback. 

Reference: [What is the Difference between session and caching?](https://net-informations.com/faq/asp/caching.htm)
