---
title: Spring Security Authentication, Spring学习(五)
date: 2023-08-04 19:16:49
categories:
 - Java
 - Backend
tags:
 - Java
 - Spring Boot
---

## 0. 项目结构

```shell
└── src
    ├── main
    │   ├── java
    │   │   └── david
    │   │       └── zhu
    │   │           ├── SpringSecurityDemoApplication.java
    │   │           ├── WebController.java
    │   │           └── WebSecurityConfig.java
    │   └── resources
    │       ├── application.yaml
    │       ├── static
    │       └── templates
```

例子地址: https://github.com/shwezhu/springboot-learning/tree/master/spring-security-get-started-demo

## 1. 创建一个简单的 spring boot 项目 - `Controller` 类

创建一个 spring 项目思路, 首先要想到创建的一个类是 Controller, 因为我们要处理不同的 endpoints, 比如叫 `WebController.java`, 名子无所谓, 只要加上 `@Controller/@RestController` 的类都是 Controller, 然后考虑你的这个 Controller 是要返回简单的 json 对象还是 web 页面, 前者的话就选择 `@RestController` 修饰你的 Controller, 至于这两个注解的区别, 可以参考: [Spring Boot项目及踩坑总结 Spring学习(一)](https://davidzhu.xyz/2023/07/29/Java/Backend/001-first-spring-boot-program/) 

创建一个简单的 spring boot 项目, 依赖只选择 spring web, 之后慢慢添加各种依赖, 创建一个简单的 Controller, 如下:

![1](/005-spring-security/1.png)

由于没有使用 spring security, 现在这两个 endpoints 都可以通过 http://localhost:8080/private 或 http://localhost:8080 访问, 

## 2. 使用 spring security 保护 web application

在项目中添加 spring security 依赖, 此例使用的 gradle, 因此编辑 `build.gradle`, 添加:

```gradle
implementation 'org.springframework.boot:spring-boot-starter-security'
```

若你用的maven, 可以编辑 `pom.xml` 进行添加依赖, 添加完后 reload 配置然后直接运行项目, 此时两个endpoints, `/` 和 `/private` 都默认受到了保护, 需要登录才能访问, 

```shell
# -v, --verbose: Makes  the  fetching more verbose/talkative.
$ curl localhost:8080 -v
...
> GET / HTTP/1.1
> Host: localhost:8080
> Accept: */*
< HTTP/1.1 401 
< Set-Cookie: JSESSIONID=9342C2B61BCD3507B78E3602EC448A59; Path=/; HttpOnly
...
```

从输出可以看到 http code: 401, 

> 401 Unauthorized is the status code to return when the client provides no credentials or invalid credentials. 

只添加了 spring security 依赖, 然后运行项目, 我们的页面就被保护, 不得不说 spring 默默地在背后帮我们做了很多, 之所以需要登录才能访问那两个 endpoints的原因是在 spring security中 *everything is secure by default*, 但我们可以修改这些配置, 

在进行下一步的时候要注意, 即使我们试图访问一个不存在的页面比如 http://localhost:8080/foo , 得到的依旧是 401 forbidden code, 即会直接跳出登录页面, 而不是告诉你 404, 页面不存在, 即所有访问此网址的请求都被 spring security 拦截, 只有你成功登录, 才能访问页面, 此时因为页面不存在, 你得到的是 404 code, 注意此时默认用户名为 `user`, 密码会在程序运行中断输出, 可以尝试一下, 具体拦截过程如下, 可见主要是 `SecurityFilterChain` 类的作用, 

This section examines how form-based login works within Spring Security. First, we see how the user is redirected to the login form:

![7](/005-spring-security/7.png)

The preceding figure builds off our [`SecurityFilterChain`](https://docs.spring.io/spring-security/reference/servlet/architecture.html#servlet-securityfilterchain) diagram: 

1. First, a user makes an unauthenticated request to the resource (`/private`) for which it is not authorized.
2. Spring Security’s [`AuthorizationFilter`](https://docs.spring.io/spring-security/reference/servlet/authorization/authorize-http-requests.html) indicates that the unauthenticated request is *Denied* by throwing an `AccessDeniedException`.
3. Since the user is not authenticated, [`ExceptionTranslationFilter`](https://docs.spring.io/spring-security/reference/servlet/architecture.html#servlet-exceptiontranslationfilter) initiates *Start Authentication* and sends a redirect to the login page with the configured [`AuthenticationEntryPoint`](https://docs.spring.io/spring-security/reference/servlet/authentication/architecture.html#servlet-authentication-authenticationentrypoint). In most cases, the `AuthenticationEntryPoint` is an instance of [`LoginUrlAuthenticationEntryPoint`](https://docs.spring.io/spring-security/site/docs/6.1.2/api/org/springframework/security/web/authentication/LoginUrlAuthenticationEntryPoint.html).
4. The browser requests the login page to which it was redirected.
5. Something within the application, must [render the login page](https://docs.spring.io/spring-security/reference/servlet/authentication/passwords/form.html#servlet-authentication-form-custom).

过程可参考: [Form Login :: Spring Security](https://docs.spring.io/spring-security/reference/servlet/authentication/passwords/form.html)

## 3. 自定义 spring security - `WebSecurityConfig` 类

接下来我们创建一个新的类用来修改 spring security 的默认配置, 即指定 spring security 的行为, 比如指定访问哪个page需要认证才行, 支持什么方式登录, 如 form 登录, 谷歌登录,  以及登出行为和获取用户信息(我们登录需要比对用户信息吧, 密码是否匹配等), 我把这个类命名为 `WebSecurityConfig.java`, 这也是第二个重要的类, 第一个是第一节我们讲到的 Controller, 

```java
@Configuration
@EnableWebSecurity
public class WebSecurityConfig {
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        return http
                // authorizeHttpRequests(): Allows restricting access based upon the HttpServletRequest using RequestMatcher implementations (i.e. via URL patterns).
                .authorizeHttpRequests(
                        authorizeHttp -> {
                            // Method authenticated(): Specify that URLs are allowed by any authenticated user.
                            authorizeHttp.requestMatchers("/private").authenticated();
                            // exempt all http request from authentication except for "/private"
                            authorizeHttp.anyRequest().permitAll();
                        })
                // Enable form login, if I need login, show me a form
                // without this, when you access page that needs authentication will get Whitelabel Error Page with code 403
                .formLogin(withDefaults())
                .build();
    }

    // UserDetailsService, an interface, is used to retrieve user-related data.
    // It is used to retrieve user-related data from a data source, such as a database or a file for authentication and authorization purposes.
    // e.g., It has one method named loadUserByUsername() which can be overridden to customize the process of finding the user.
    // It is used by the DaoAuthenticationProvider to load details about the user during authentication.
    @Bean
    public UserDetailsService userDetailsService() {
        // We are using in memory user password for demo purpose
        return new InMemoryUserDetailsManager(
                User.builder()
                        .username("david")
                        // The {noop} prefix is a marker indicates that the password should be treated as plain text.
                        .password("{noop}asd")
                        .authorities("ROLE_user")
                        .build()
        );
    }
}
```

此时访问 http://localhost:8080/private , 我们会被自动转到登录页面, 账号密码不再是上面那节由spring自动生成, 而是我们自己制定的, 可以看代码中的注释, 注意此时我们用的 `InMemoryUserDetailsManager` 一般是作为demo来展示, 即创建了一个临时用户用于 form 登录, 实际开发 要从数据库或文件中获取用户的密码信息来比对, 具体方法之后会讲, 

如果此时你按照第二节我们所做的去尝试访问一个不存在的页面, http://localhost:8080/foo 会得到 Whitelabel Error Page with code 403, 你可以尝试一下, 看看, 这就和第二节我们得到的结果不同, 在第二节中我们会被跳转到登录页面, 这是因为什么呢? 为什么结果会不相同?

还记得上面我们说过 spring security 的设计哲学是 secure by default, 即在第二节中我们没有修改任何 spring security的行为, 只是添加了依赖, 所以此时访问所有的页面都需要登录, 即使是个不存在的页面, 但是在这节我们修改了 spring security的行为, 仔细看上面关于控制哪些endpoint不需要认证便可访问的代码你会发现我们并没有遵守这个原则, 我们正在做的是 expose everything, and secure some specific endpoints, 这是不对的, 我们要反过来写, 改成:

```java
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        return http
                .authorizeHttpRequests(
                        authorizeHttp -> {
                            authorizeHttp.requestMatchers("/").permitAll();
                            authorizeHttp.requestMatchers("/error").permitAll();
                            authorizeHttp.requestMatchers("/favicon.ico").permitAll();
                            // Method authenticated(): Specify that URLs are allowed by any authenticated user.
                            authorizeHttp.anyRequest().authenticated();
                        })
                // Enable form login, if I need login, show me a form
                // without this, when you access page that needs authentication will get Whitelabel Error Page with code 403
                .formLogin(withDefaults())
                .build();
    }
```

此时才是 *secure by default:* *expose some specific endpoints, and secure everything*, 你再访问 http://localhost:8080/foo , 就会跳转到登录页面, 

## 4. Single sign-on (SSO) 可跳过

Using SSO enables we can use open ID, 比如平时登录按钮下的 sign in with Google, 这种, 就是依靠的 Open ID, 在 spring 实现这个很简单, 

首先需要添加依赖, 编辑 `build.gradle` dependencies 部分, 添加:

```
implementation 'org.springframework.boot:spring-boot-starter-oauth2-client'
```

然后第二步就是 enable oauth2-login, 还记得上面那节里我们如何使能 form login 的吗, 类似地, 我们只用在使能 form login 的地方添加一行代码, to tell the `SecurityFilterChain` that we also want to be able to login in with oauth2 login, 

```java
// ....
.formLogin(withDefaults())
.oauth2Login(withDefaults()) // 新加的代码
.build();
// ...
```

第三步就是要在谷歌注册相关信息, 即我们在用谷歌登录, 也算是用了谷歌相关的service, 不能说直接不经过谷歌相关认证就用了吧, 此时我们先把文件 `java/resources/application.properties` 修改成 `application.yaml`, 内容为:

```
spring:
  security:
    oauth2:
      client:
        registration:
          google:
            client-id:
            client-secret:
```

然后剩下的就是从谷歌获取 client-id 和 client-secret, 具体配置可参考: [Setting up OAuth 2.0 - Google Cloud Platform Console Help](https://support.google.com/cloud/answer/6158849?hl=en)

![2](/005-spring-security/2.png)

然后点 create, 即可获得 client-id 和 client-secret, 然后填入 `application.yaml` 中, 记住哦, **提交远程仓库的时候别忘把这个文件加入到 `.gitignore` 中**, 然后运行程序就可以实现谷歌登录了, 

> **OAuth** (short for "Open Authorization") is **an open standard for access delegation**, commonly used as a way for internet users to grant websites or applications access to their information on other websites but without giving them the passwords. [OAuth](https://en.wikipedia.org/wiki/OAuth)

另外注意这个服务都是免费的, 不放心的话可以到 https://console.cloud.google.com/welcome/ 查看管理你的 project (看到有的一年订阅费要15k, 这是在自我安慰), 

![4](/005-spring-security/4.png)

![5](/005-spring-security/5.png)

![6](/005-spring-security/6.png)

## 5. 获取登录用户信息 - `Authentication Object`

这里就要提到一个重要的对象, 即 Authentication Object, 它代表 **either the request to login or the result of a successful login request** , 

- Authentication: represents the user. Contains:
  - ﻿﻿Principal: user "identity" (name, email...)
  - ﻿﻿GrantedAuthorities: "permissions" (roles,..)
  - isAuthenticated(): almost always true, 如果不是 true, 那这个 request 基本会被 blocked, 那我们也无法获得这个 Authentication 了, 因为 SecurityFilterChain 的这个代码: `authorizeHttp.anyRequest().authenticated()`, 即除了那几个 endpoints 的请求不需要认证, 其他的都需要 authenticated, 
  - ﻿﻿details: details about the request
  - ﻿﻿(Credentials): "password", often null

了解更多关于 Authentication: [Servlet Authentication Architecture :: Spring Security](https://docs.spring.io/spring-security/reference/servlet/authentication/architecture.html)

我们可以通过 Authentication object 来获取用户名密码等信息, 这也是第三个重要的类, 只不过这个类不是我们自定义的, 而是 spring 平台的, 了解更多: [Authentication (Spring Security 3.0.8.RELEASE API) ](https://docs.spring.io/spring-security/site/docs/3.0.x/apidocs/org/springframework/security/core/Authentication.html)

> Authentication Object: Represents the token for an authentication request or for an authenticated principal once the request has been processed by the [`AuthenticationManager.authenticate(Authentication)`](https://docs.spring.io/spring-security/site/docs/3.0.x/apidocs/org/springframework/security/authentication/AuthenticationManager.html#authenticate(org.springframework.security.core.Authentication)) method. Once the request has been authenticated, the `Authentication` will usually be stored in a thread-local `SecurityContext` managed by the [`SecurityContextHolder`](https://docs.spring.io/spring-security/site/docs/3.0.x/apidocs/org/springframework/security/core/context/SecurityContextHolder.html) by the authentication mechanism which is being used. In Spring Security, the term "authenticated principal" refers to the authenticated user or entity. It represents the currently logged-in user or entity who has successfully completed the authentication process. In most cases, **the framework transparently takes care of managing the security context and authentication objects for you.** [Authentication](https://docs.spring.io/spring-security/site/docs/3.0.x/apidocs/org/springframework/security/core/Authentication.html)

> 注意, authentication object 就在 `SecurityContext`, 它是 thread-local, 所以比如你的服务器 tomcat 有100个线程来处理 request, 每个线程内的 `SecurityContext`都不一样, 而且  `SecurityContext` global static, 除此之外, when a request comes in, runs on a thread, and when it's done, some other request is going to use this thread, and the `SecurityContext` will be clean before this, 
>
> 所以你可以在任何地方获取它, 即如果有时候你有个 Controller, 然后有四五个方法 nested, 不用像下面那样通过参数 inject authentication object, 太麻烦了, 可以直接获得, 
>
> `var authentication = SecurityContextHolder.getContext().getAuthentication();` 
>
> https://youtu.be/iJ2muJniikY?t=2085

![a](/005-spring-security/a.png)

看看 authentication 对象的方法: 

- `getPrincipal()`
  - The identity of the principal being authenticated. In the case of an authentication request with username and password, this would be the username. 
- `getCredentials()`
  - The credentials that prove the principal is correct. This is usually a password, but could be anything relevant to the `AuthenticationManager`.
  - 一个Credentials输出: `org.springframework.security.core.userdetails.User [Username=david, Password=[PROTECTED], Enabled=true, AccountNonExpired=true, credentialsNonExpired=true, AccountNonLocked=true, Granted Authorities=[ROLE_user]]`

修改前面定义的 Controller, inject Authentication object to the `/private` endpoint, 

```java
@RestController
public class WebController {
    @GetMapping("/")
    public String publicPage() {
        return "Hello David~";
    }

    @GetMapping("/private")
    public String privatePage(Authentication authentication) {
        return "Hi ~["
                + authentication.getName()
                + "]~, you've logged in. 🎉";
    }
}
```

然后运行项目, 登录后得到输出: 

```
Hi ~[david]~, you've logged in. 🎉
```

## 6. 查看 OpenID 用户邮箱 

修改 Controller 代码, 新加一个自定义方法, getName()

``` java
@RestController
public class WebController {
    @GetMapping("/")
    public String publicPage() {
        return "Hello David~";
    }

    @GetMapping("/private")
    public String privatePage(Authentication authentication) {
        return "Hi ~["
                + getName(authentication)
                + "]~, you've logged in. 🎉";
    }

    private static String getName(Authentication authentication) {
        return Optional.of(authentication.getPrincipal())
                .filter(OidcUser.class::isInstance)
                .map(OidcUser.class::cast)
                .map(OidcUser::getEmail)
                .orElseGet(authentication::getName);
    }
}
```

运行后选择谷歌登录, 输出: Hi ~[shehu@gmail.com]~, you've logged in. 🎉

## 7. 通过 debug 查看 `Authentication Object`

设置断点, 

![8](/005-spring-security/8.png)

访问 `/private` 页面输入密码登录, 返回 IDE, 

![9](/005-spring-security/9.png)

下面是通过 ouath Google 登录之后的 Authentication 信息, 

![10](/005-spring-security/10.png)

## 8. 总结

总结大概从 25:00 左右开始, 

{% youtube iJ2muJniikY %}

本文主要参考: https://youtu.be/iJ2muJniikY
