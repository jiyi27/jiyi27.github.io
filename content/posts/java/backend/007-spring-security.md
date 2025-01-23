---
title: CSRF Filter & ProviderManager & AuthenticationProviders, Spring学习(七)
date: 2023-08-08 20:58:54
categories:
 - Java
 - Backend
tags:
 - Java
 - Spring Boot
---

{% youtube iJ2muJniikY %}

视频内容位置:

- Cross Site Request Forgery: `1:16:00`
  - [CSRF Spring](https://docs.spring.io/spring-security/reference/features/exploits/csrf.html)
- CSRF Filter 源码分析: ` 1:22:00` 
- Trace level log 分析: `1:26:00`

```yaml
logging:
  level:
    org.springframework.security: TRACE
```

![1](/007-spring-security/1.png)

#### ` 1:30:35` 理论: AuthenticationManager, ProviderManager, AuthenticationProvider 

> Authentication Object stands for either the request to login or the result of a successful login request , 


![2](/007-spring-security/2.png)

![3](/007-spring-security/3.png)

上图中, 如果账号密码正确, 则 ProviderManager 返回的 UsernamePasswordAuthenticationToken 就是同一个对象, 只不过内容从 password, username 变成了一个 richer object (内容更丰富), 如 UserDetails 对象可能包含 你喜欢的颜色, 生日, 等信息, 而 Authority 对象可能包含你的权限, 如 user 还是 admin, 

> [***`ProviderManager`***](https://docs.spring.io/spring-security/site/docs/6.1.2/api/org/springframework/security/authentication/ProviderManager.html) is the most commonly used implementation of [***`AuthenticationManager`***](https://docs.spring.io/spring-security/reference/servlet/authentication/architecture.html#servlet-authentication-authenticationmanager). 
>
> [***`AuthenticationProvider`***](https://docs.spring.io/spring-security/reference/servlet/authentication/architecture.html#servlet-authentication-authenticationprovider) is used by [***`ProviderManager`***](https://docs.spring.io/spring-security/site/docs/6.1.2/api/org/springframework/security/authentication/ProviderManager.html)  to perform a specific type of authentication.

```java
public interface AuthenticationManager {
  Authentication authenticate(Authentication authentication) throws AuthenticationException;
}

// 我们经常自己实现这个接口, 实现自定义 AuthenticationProvider
public interface AuthenticationProvider {

	Authentication authenticate(Authentication authentication)
			throws AuthenticationException;

	boolean supports(Class<?> authentication);
}
```

Basically `AuthenticationProvider` is the specialized version of the `ProviderManager` that says I only deal with username password authentication tokens, I only deal with robot authentications, I only deal with over 2 login authentication tokens. 

And this allows you to extend Spring Security in a very specific place for changing the way someone logs in, *without having to write a custom filter that takes the request*, that does some transformation, maybe you don't need to go that far, maybe you have special rules around, you know the email of the user that comes in, well here an `AuthenticationProvider` would be good enough. 

![4](/007-spring-security/4.png)

A `ProviderManager` just like this, kind of the same idea of the filters, but applied to transforming authentication requests into authenciated objects, it's a for loop over a list of `AuthenticationProvider`.

#### ` 1:35:50` 实践: AuthenticationProviders, ProviderManager, AuthenticationProvider 

Our website is great, it has two beautiful pages I can log in with username and password, or with Google login, and have a robot a robot account, I can hit my endpoints and get stuff with credentials that are not in the database for example,

The problem with my website is that I have a an admin called Daniel, he's really fine, he's neat,  he's kind he's very handsome, uh but he has really bad memory, and and for for the for the love of anything he cannot remember his password, that's very unfortunate, so we're going to make an escape hatch for Daniel so that he doesn't have to remember his password, and so we're going to do this by implementing a special `AuthenticationProvider`, 

``` java
public class DavidAuthenticationProvider implements AuthenticationProvider {
    @Override
    public Authentication authenticate(Authentication authentication) throws AuthenticationException {
        var username = authentication.getName();
        if ("david".equals(username)) {
            return UsernamePasswordAuthenticationToken.authenticated(
                    "david",
                    null,
                    AuthorityUtils.createAuthorityList("ROLE_admin")
            );
        }
        // What do we do in case it's not Daniel
        // Well we don't know what to do with this, like the user password this must be handled
        //by some other AuthenticationProvider, so to Signal this, we're returning null
        return null;
    }

    @Override
    public boolean supports(Class<?> authentication) {
        return UsernamePasswordAuthenticationToken.class.isAssignableFrom(authentication);
    }
}
```

- `UsernamePasswordAuthenticationToken`: 实现了 ` Authentication` 接口, 就像我们上节自定义的 ` RobotAuthentication`,  都是用来代表一个自定义的认证用户 (authentication request), 只不过我们的 ` RobotAuthentication` 用来代表通过 http header 认证的用户 (authentication request), 而前者则代表: An `Authentication` implementation that is designed for simple presentation of a username and password. 

- `isAssignableFrom()`: Determines if the class or interface represented by this Class object is either the same as, or is a superclass or superinterface of, the class or interface represented by the specified Class parameter. 
  - 别忘了 `Class<T>` 是个包装器, 参考: https://davidzhu.xyz/2023/08/05/Java/Basics/002-reflection-object-class
  - 因此 `supports()` 方法代表的意思是: If the `authentication` argument is an instance of `UsernamePasswordAuthenticationToken` or any of its subclasses, the method returns `true`, indicating that this `AuthenticationProvider` implementation supports the provided authentication object. Otherwise, it returns `false`.
- The `authenticate()` method is responsible for performing the authentication process based on the provided authentication object and returning a fully authenticated `Authentication` object if the authentication is successful.
  - when the `ProviderManager` calls this `authenticate()` method, it's going to always pass in a `UsernamePasswordAuthenticationToken` or a subclass. 

This is the same way as we did with the the filter:

- Do I want to handle this request, is it the right type?
  - `DavidAuthenticationProvider` 的 ` supports(Class<?> authentication)` 用来判断参数 authentication 是不是属于 UsernamePasswordAuthenticationToken子类或就是该类型, 若是才可进行处理
  - `RobotFilter` 的 ` doFilterInternal() ` 中我们判断 header 中是否有 "x-robot-password" 字段, 若无则直接调用 doFilter() 并 return, 
- And is the is the content of the payload the thing I care about?
  - `RobotFilter` 判断密码是否正确 
  - `DavidAuthenticationProvider` 判断用户名是否为 `david`

> The other thing that the `AuthenticationProvider` can do is throw in an `AuthenticationException`, so basically this account has expired and so you're not allowed to log in, or the credentials are wrong, 

> AuthenticationProvider can return three things, either an ***`authentication object`*** so the result of something that passed me credentials and they said the credentials are good, and ***`an exception`*** if I want to say stop processing this is invalid this should not go forever, or ***`null`*** if we delegate to the rest.

If nothing can authenticate, if every **provider** returns null, it will throw an exception in the end , and the `ProviderManager` will say no I don't care about this, 

We mount it into the filter chain, go to the `WebSecurityConfig`:

``` java
...
.formLogin(withDefaults())
.oauth2Login(withDefaults())
.addFilterBefore(new RobotFilter(), UsernamePasswordAuthenticationFilter.class)
// 在这
.authenticationProvider(new DavidAuthenticationProvider())
.build();
```

####   `1:41:20` 总结解释 为什么 我们应该自定义AuthenticationProvider 而不是 一个 FIlter

> Usually when you want to do a custom authentication, you should do a custom AuthenticationProvider rather than a full filter. 

When I log in `ProviderManager` produces an event, when I fail to log in and it also produces an event a spring event, so this means we can listen to those events and do stuff when an event is done. 

![5](/007-spring-security/5.png)

#### `1:45:00` Change our Custom RobotFilter to Custom AuthenticationProvider

源码: https://github.com/shwezhu/springboot-learning/tree/master/3-spring-security-authenciation-provider

注意结构, 比起下面这个:

```java
@Override
public Authentication authenticate(Authentication authentication) throws AuthenticationException {
    var authRequest = (RobotAuthentication) authentication;
    var password = authRequest.getPassword();
    if (this.passwords.contains(password)) {
        // 可以发现, 实现了Authentication接口的类一般有个 authenticated() 静态方法, 也可称为factory method
        // 比如我们的自定义RobotAuthentication,再比如UsernamePasswordAuthenticationToken
        return RobotAuthentication.authenticated();
    } else {
       throw new BadCredentialsException("You are not Mr Robot 🤖️");
    }
}
```

用这样的结构更好:

``` java
@Override
public Authentication authenticate(Authentication authentication) throws AuthenticationException {
    var authRequest = (RobotAuthentication) authentication;
    var password = authRequest.getPassword();
    if (!this.passwords.contains(password)) {
       throw new BadCredentialsException("You are not Mr Robot 🤖️");
    }
    return RobotAuthentication.authenticated();
}
```

#### ` 1:56:00` AuthenticationProvider 调用顺序及优点

```yaml
logging:
  level:
    org.springframework.security: TRACE
```

![7](/007-spring-security/7.png)

![8](/007-spring-security/9.png)

从图中可以看出 使用如下登录, 则会匹配到我们的 DavidAuthenticationProvider, 

```shell
$ curl -u "david:asd" http://localhost:8080/private -v
```

![9](/007-spring-security/8.png)

若使用正常用户密码登录, 则会跳过 DavidAuthenticationProvider, 使用 DaoAuthenticationProvider 验证, 

```shell
curl -u "user-1:asd" http://localhost:8080/private -v
```

看完上图会发现每次 RobotFilter 都先于 UsernamePasswordAuthenticationFilter 调用, 这是因为我们的 SecurityChain 配置代码:

```java
...
.addFilterBefore(new RobotFilter(authManager), UsernamePasswordAuthenticationFilter.class)
```

从上面的输出我们会发现: 

```shell
Invoking BasicAuthenticationFilter
Found username 'david' in Basic Authorization header
```

这是因为我们通过代码 

```java
...
.formLogin(withDefaults())
.httpBasic(withDefaults())
```

把 BasicAuthenticationFilter 加入到了 Security, 然后验证的时候正如输出那样, 一层一层的调用Filter, 进行匹配, 我们此时使用的是命令行 `curl -u ""` 进行验证的, 而 BasicAuthenticationFilter 就是做这个的, 如果我们把 BasicAuthenticationFilter 从我们的SecurityChian中移除也就是删除代码 `.httpBasic(withDefaults())`, 那我们通过 `curl -u` 提供的账号密码就不会被发现, 然后导致验证失败, 原因是所有的 filter 都被依次掉用完, 但依然没有发现匹配的,

![10](/007-spring-security/10.png)

通过这个我们也会发现, 如果使用自定义 filter 进行验证, 如使用 DavidFIlter, 而不是DavidAuthenticationProvider, 那我们还需要去验证 post 里面的账号密码, 具体分析参考视频 `1:58:15`

#### `1:59:25 ` FilterChain 调用顺序

#### `2:00:00` Recap

![11](/007-spring-security/11.png)

#### `2:01:35`  Configurers - "navigate Spring Security"

> Configurers are an abstraction that allows you to configure the filter chain and do multiple operations on the the HTTP builder(), 

![12](/007-spring-security/12.png)

![13](/007-spring-security/13.png)

`RobotLoginConfigurer.java`

```java
public class RobotLoginConfigurer extends AbstractHttpConfigurer<RobotLoginConfigurer, HttpSecurity> {

    private final List<String> passwords = new ArrayList<>();

    @Override
    public void init(HttpSecurity builder) throws Exception {
        // step 1
        // initializes a bunch of objects
        // -> AuthenticationProviders
        // all the AuthenticationProviders are populated at init() they're put in the builder,
        builder.authenticationProvider(new RobotAuthenticationProvider(passwords));
    }

    @Override
    public void configure(HttpSecurity builder) throws Exception {
        // step 2
        // this also initializes objects, but can reuse objects from step 1, even from other configurers
        // -> Filters
        // each filter chain may have their own AuthenticationManager
        var authenticationManager = builder.getSharedObject(AuthenticationManager.class);
        builder.addFilterBefore(new RobotFilter(authenticationManager), UsernamePasswordAuthenticationFilter.class);
    }

    public RobotLoginConfigurer password(String password) {
        this.passwords.add(password);
        return this;
    }
}
```

`WebSecurityConfig.java`

```java
@Bean
public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    http
        .authorizeHttpRequests(authorizeConfig -> {
                    authorizeConfig.requestMatchers("/").permitAll();
                    authorizeConfig.requestMatchers("/error").permitAll();
                    authorizeConfig.requestMatchers("/favicon.ico").permitAll();
                    authorizeConfig.anyRequest().authenticated();
                })
        .formLogin(withDefaults())
        // By calling httpBasic(), an instance of the BasicAuthenticationFilter is added to the filter chain.
        // https://stackoverflow.com/a/57577530/16317008
        // 为了实现通过 curl -u "user:password" http://localhost:8080/private 登录
        .httpBasic(withDefaults())
        .oauth2Login(withDefaults()) // return HttpSecurity
        .authenticationProvider(new DavidAuthenticationProvider()) // return HttpSecurity
        .apply(new RobotLoginConfigurer()) // return Configurer
        .password("beep-boop") // return Configurer
        .password("boop-beep");
    return http.build();
}
```

#### `2:10:40` Lambda DSL

