---
title: Spring Security 一根难啃的骨头
date: 2025-02-13 20:29:10
categories:
 - spring boot
tags:
 - spring boot
---

## 1. 前言

AuthenticationManager, AuthenticationProvider , ProviderManager, AuthenticationManager, DaoAuthenticationProvider, UserDetailsService, SecurityFilterChain, 这么多类和接口, 搞糊涂了已经, 去年学过一次 Spring Security, 感觉太复杂~~(没学会)~~, 就转战 Golang 了, 到最后找工作还是得面对 Java, 这不, 开始恶补 Spring...

## 2. 两种认证方式

我们最终的目的都是让服务器记住/区分客户端, 实现这个目的的方法有两种:

- 在服务端维护有状态的 Session
- 在客户端保存 JWT Token (通过 cookie 或其他方式保存)

Spring Security 既支持基于 Session 的有状态会话，也支持基于 Token (例如 JWT) 的无状态会话, 

在请求在进入 Controller 之前, **Spring Security 会预先拦截所有请求**, 如果用户访问受保护页面, Spring Security 会通过 cookie 或者 Authorization 等请求头检查客户端是否已认证, 如果没有认证, 请求将会被重定向到我们预先指定的路径, 比如 `\login`, 我们也可以向 Spring Security 指定哪些路径受保护, 哪些路径不受保护, 大致如下:
```java
public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    // 访问 /login /register 不需要认证
    http.authorizeHttpRequests(auth -> auth
            .requestMatchers("/login", "/register").permitAll()
            .anyRequest().authenticated()
    );
  
    // 使用默认表单页面登录 (不用自己实现登录页面)
    http.authenticationProvider(authenticationProvider())
      .formLogin(Customizer.withDefaults());
  
    // 指定 Session 模式: IF_REQUIRED 
    http.sessionManagement(session -> session
            .sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED)
            .maximumSessions(1)
            .expiredUrl("/login?expired")
    );

    return http.build();
}
```

上面代码我们使用的是  **Spring Security 提供的默认表单登录 + Session 管理状态 的方式**, 也就是说当我们第一次访问主页 `localhost:8080/`, 因为还没认证, 就会被重定向到 Spring Security 提供的默认表单登录页面, 如果验证成功 Spring Security 会自动维护一个 Session，返回给客户端一个 Cookie, 最后浏览器存有 `JSESSIONID` Cookie，让后续请求自动携带, 如下图:

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2025/02/304faf547af877e5f76bd7e7850647eb.png)

当然我们也可以通过第二种方式, 无状态 JWT 来实现认证, 此时的 SecurityFilterChain 代码大致如下:
```java
@Bean
public SecurityFilterChain securityFilterChain(
        HttpSecurity http,
        JwtAuthFilter jwtAuthenticationFilter) throws Exception {
  
    // 禁止 CSRF, 任何请求都可以发送到服务器
    http.csrf(AbstractHttpConfigurer::disable);
  
    // 指定无状态 Session
    http.sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS));

    http.authorizeHttpRequests(auth -> auth
            .requestMatchers("/api/users/login", "/api/users/register").permitAll()
            .anyRequest().authenticated()
    );
  
    // 添加自定义的 JWT 验证逻辑, 验证请求中的 JWT Token 是否有效
    http.addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

    return http.build();
}
```

```bash
$ curl -X POST -H "Content-Type: application/json" -d
'{"username":"user1","password":"ps123"}' http://localhost:8080/login -v
...
< HTTP/1.1 200
< X-XSS-Protection: 0
{"token":"eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ0ZXN0dXNlciIsImlhdCI6MTczOTU1OTk0NywiZXhwIjoxNzM5NjQ2MzQ3fQ.3o4g5OJVQSzrCJtoqNvnsV-PdgOMeGVdSuGhEuQy3WM"}
```

上面代码没有指定登录的验证方式, 也就是说当用户第一次访问受保护的路径时, Spring Security 不会帮我们重定向到登录页面, 而是返回 403/401 未授权, 客户端需要直接向路径比如  `\login` 发送登录请求, 以获取 JWT Token, 所以作为服务端, 我们应该实现一个 Controller, 接受登录请求:

```java
@PostMapping("/login")
public JwtResponse login(UserDTO.LoginRequest request) {
    // userService.login() 处理认证逻辑 校对密码
    // 若成功, 返回给用户 JWT Token
    return userService.login(request);
}
```

因此可以总结无论是基于 Session 还是 JWT, 客户端认证都包括两个阶段:

- 通过登录获取 Session ID 或 JWT Token
- 之后的每次请求自动携带 Session ID 或 JWT Token 用于认证

> 现在你应该知道 SecurityFilterChain 是干嘛的了, 还剩下 AuthenticationManager, AuthenticationProvider , ProviderManager, AuthenticationManager, DaoAuthenticationProvider, UserDetailsService, 我们慢慢来

## 3. 基于 Token (JWT) 的无状态会话

作为后端开发, 我们需要先介绍客户端和服务器认识(登录), 然后客户端访问一些资源就不用每次都登录了, 所以我们先说登录密码验证. 

### 3.1. 登录

传统的登录密码验证逻辑很简单, 客户端向 `/login` 发送请求, 服务器直接在 Controller 对应的方法中对比账号密码是否匹配, 而 Spring Security 并不是这么做的,  刚开始我搞不明白的是, 明明就是简单的账号密码比较, 为什么非要搞得那么麻烦, 

因为 Spring Security 的设计理念是“配置驱动”，它提供了大量的接口和类去处理各种场景：`UserDetailsService`、`PasswordEncoder`、`DaoAuthenticationProvider`、`AuthenticationManager`、`SecurityFilterChain` 等,

它的本意是: 你只要实现自己的一小部分逻辑（比如怎么查数据库获取密码）, 其他通用的部分（密码对比、账户状态检查、异常处理等）就交给框架内部的 `DaoAuthenticationProvider` 等组件去做. 

还是很难懂, 现在我们说的是登录, 所以看看 Spring Security 怎么进行账号密码验证, 在 Spring Security 中, 我们一般使用 **DaoAuthenticationProvider** 来进行 “用户名+密码” 认证, 它需要知道两件事：

- 如何加载用户信息: 也就是 **UserDetailsService**：通过用户名去数据库等地方查找用户，并返回一个实现了 `UserDetails` 的对象（包含用户名、密码、权限等）

- 如何验证密码: 也就是 **PasswordEncoder**：用来做密码加密或密码对比

 也就是说`DaoAuthenticationProvider` 有两个小弟:

-  `UserDetailsService` 用来加载用户数据(账号密码)
-  `PasswordEncoder`  用来加密 验证 密码

现在我们还要引入另外一个接口: 

**AuthenticationProvider 和 DaoAuthenticationProvider 的区别:**

- `AuthenticationProvider` 是一个 接口，定义了认证逻辑的标准
- `DaoAuthenticationProvider` 是 `AuthenticationProvider` 的一个 实现, 用于数据库用户名/密码认证

```java
@PostMapping("/login")
public ResponseEntity<UserDTO.JwtResponse> login(UserDTO.LoginRequest request) {
    // 1. 封装用户名密码
    UsernamePasswordAuthenticationToken authRequest =
            new UsernamePasswordAuthenticationToken(
      request.getUsername(), 
      request.getPassword());
    // 2. 调用 AuthenticationManager 进行认证
    // 如果认证不通过，authenticate(...) 会抛出异常, 由全局异常处理器处理
    Authentication authentication = authenticationManager.authenticate(authRequest);
    // 3. 如果认证通过，生成 JWT
    String jwt = jwtUtils.generateToken(authentication);
    // 4. 返回 JWT 给客户端（可放在 Body，也可放在 Header）
    return ResponseEntity.ok(new UserDTO.JwtResponse(jwt));
}
```

**ProviderManager 和 AuthenticationManager 的区别:**

- `AuthenticationManager` 是一个接口, 这个接口规定所有实现它的类, 都应该实现`authenticate(Authentication authentication)` 方法, 该方法是为了身份验证

- `ProviderManager` 是 `AuthenticationManager` 的一个 默认实现，负责管理多个 `AuthenticationProvider` 并协调认证过程

Spring Security 允许多个 `AuthenticationManager` 的实现, 但 `ProviderManager` 是默认实现, 我们来看一下 `AuthenticationManager` 接口的定义:

```java
public interface AuthenticationManager {
    Authentication authenticate(Authentication authentication) 
      throws AuthenticationException;
}
```

通过上面的代码我们也可以看出, 我们调用 `authenticationManager.authenticate(authRequest)` 方法进行验证密码匹配, 而且此函数返回一个 `Authentication` 对象, 看一下这个类的定义, 就知道是什么了:

```java
public interface Authentication extends Principal, Serializable {
    Collection<? extends GrantedAuthority> getAuthorities();

    Object getCredentials();

    Object getDetails();

    Object getPrincipal();

    boolean isAuthenticated();

    void setAuthenticated(boolean isAuthenticated) throws IllegalArgumentException;
}
```

> 现在你知道了 SecurityFilterChain, AuthenticationProvider, DaoAuthenticationProvider, UserDetailsService, PasswordEncoder, ProviderManager 和 AuthenticationManager

### 3.2. 验证 JWT Token

验证涉及的概念很少,  只需要自定义 JWT Token 验证逻辑, 加入到 Spring Security Chain 中, 这样之后每次请求来到服务器, 都会被 Spring Security Chain 拦截, 然后经过我们自定义的 JWT Token 验证逻辑, 若验证成功, 放行, 

如何自定义 JWT 验证逻辑呢? 答: 通过实现 `OncePerRequestFilter`, 

当然 `OncePerRequestFilter` 的作用可不止用来验证 JWT Token, 在 Spring Web 应用中, 我们经常会使用 `Filter` 进行请求的拦截, 比如：

- 认证与授权（如 JWT 解析）

- 记录请求日志

- 统一处理 CORS

- 请求参数或响应的预处理

默认的 `Filter` 可能会在一次请求的多个阶段执行多次（例如 `forward` 或 `include` 操作时），导致重复的逻辑执行。而 `OncePerRequestFilter` 解决了这个问题，保证了在同一个请求的整个生命周期内，该过滤器仅执行一次。`OncePerRequestFilter` 会检查当前请求的 `request` 是否已经被它处理过（通过 `request` 的 `attribute` 记录状态）。如果是第一次执行，则调用 **`doFilterInternal()`** 处理逻辑。如果该请求在后续的 `forward` 或 `include` 中再次经过这个过滤器，则不会再次执行 `doFilterInternal()`，而是直接放行。

所以我们要怎么通过实现 `OncePerRequestFilter` 来进行 JWT Token 验证呢? 来看大荧幕:

```java
@Component
public class JwtAuthFilter extends OncePerRequestFilter {
  
    // 注意这个函数的名字
    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain)
            throws ServletException, IOException {

        // 从 Authorization 请求头中获取 JWT Token
         String jwt = parseJwt(request);

        // 验证 token 是否有效
        if (jwt != null && jwtUtils.validateToken(jwt)) {...}
      
        // 转发到下一个 filter
        filterChain.doFilter(request, response);
    }

    private String parseJwt(HttpServletRequest request) {
        String headerAuth = request.getHeader("Authorization");
        if (StringUtils.hasText(headerAuth) && headerAuth.startsWith("Bearer ")) {
            return headerAuth.substring(7);
        }
        return null;
    }
}
```

当然上面的都是伪代码, 只要知道大致发生什么就可以了, 接下来, 就是最后一步, 把这个 filter 添加到 Spring Security Chain 中, 也就是最开始我们在 `securityFilterChain()` 方法中的语句:

```java
http.addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
```

> 现在你知道了 SecurityFilterChain, AuthenticationProvider, DaoAuthenticationProvider, UserDetailsService, PasswordEncoder, OncePerRequestFilter

## 4. 基于 Session 的有状态会话

### 4.1. 登录

我们已经知道, 要实现登录需要使用 DaoAuthenticationProvider 和 它的两个工具 UserDetailsService, PasswordEncoder, 

```java
@Slf4j
@Configuration
@RequiredArgsConstructor
public class SecurityConfig {
    private final UserRepository userRepository;

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public UserDetailsService userDetailsService() {
        return username -> {
            User user = userRepository.findByUsername(username)
                    .orElseThrow(() -> new UsernameNotFoundException("用户不存在"));

            log.info("用户信息: {}", user);

            // 把自己的 User 转换成 Spring Security 提供的 UserDetails 对象
            return new org.springframework.security.core.userdetails.User(
                    user.getUsername(),
                    user.getPasswordHash(),
                    Collections.emptyList()
            );
        };
    }

    @Bean
    public DaoAuthenticationProvider daoAuthenticationProvider() {
        DaoAuthenticationProvider provider = new DaoAuthenticationProvider();
        // 加入 DaoAuthenticationProvider 的两个小弟
        provider.setUserDetailsService(userDetailsService());
        provider.setPasswordEncoder(passwordEncoder());
        return provider;
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration authenticationConfiguration) throws Exception {
        return authenticationConfiguration.getAuthenticationManager();
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http.authorizeHttpRequests(auth -> auth
                .requestMatchers("/login", "/home").permitAll()
                .anyRequest().authenticated()
        );

        http.authenticationProvider(daoAuthenticationProvider())
          .formLogin(Customizer.withDefaults());

        http.sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED)
                .maximumSessions(1)
                .expiredUrl("/login?expired")
        );

        return http.build();
    }
}
```

`SecurityConfig` 基本上覆盖了我们上面讨论的所有的类和接口, 根据代码逻辑也可以看出:

- 我们向 DaoAuthenticationProvider 添加了它的两个小弟 UserDetailsService 和 PasswordEncoder
- 我们利用 UserDetailsService  指定如何加载用户信息(账号 密码), 然后返回一个 `UserDetails` 的对象 (包含用户名、密码、权限等）
- 我们利用 PasswordEncoder 进行加密 或者验证密码, umm, 这一点好像没显示出来, 应该在用户注册的逻辑里可以看到, 
- securityFilterChain() 方法中 我们指定了哪些路径受保护, 指定了采用 Spring Security 提供的表单进行登录, 也指定了 Session 采用 IF_REQUIRED 模式 而不是 STATELESS

> 你可能会注意到为什么我们没写密码比较逻辑, 这是因为 `DaoAuthenticationProvider` 会自动调用 `passwordEncoder().matches(rawPassword, encodedPassword)` 来验证密码, 如果密码正确, 就会为请求生成一个 JSESSIONID 放到 cookie 返回, 同时自动创建一个 Session, 
>
> 在 JWT 的情况, 我们之所以需要自己实现密码验证逻辑, 是因为我们关闭了 Session 模式, 且要返回给用户一个 JWT Token, 而不是返回  Spring Security 自动生成的 JSESSIONID, 所以我们需要自己判断密码是否正确, 若正确, 自己生成 JWT Token 并返回给客户端, 

上面的代码其实会遇到一个警告:

```java
Global AuthenticationManager configured with an AuthenticationProvider bean. UserDetailsService beans will not be used by Spring Security for automatically configuring username/password login. Consider removing the AuthenticationProvider bean. Alternatively, consider using the UserDetailsService in a manually instantiated DaoAuthenticationProvider. If the current configuration is intentional, to turn off this warning, increase the logging level of 'org.springframework.security.config.annotation.authentication.configuration.InitializeUserDetailsBeanManagerConfigurer' to ERROR
```

这个警告的主要原因是 Spring Security 发现了一个 `AuthenticationProvider` (即 `daoAuthenticationProvider()`)，所以不会自动使用 `UserDetailsService` 来配置基于用户名/密码的认证。

也就是说, 在默认情况下，如果我们的 `SecurityConfig` 只用提供 `UserDetailsService` 和 `PasswordEncoder ` 的定义, 不用手动为 DaoAuthenticationProvider 添加 这俩小弟, Spring Security 会自动执行以下步骤：

1. 创建 `DaoAuthenticationProvider` 并使用 `UserDetailsService` 进行认证
2. 创建 `AuthenticationManager`，并将 `DaoAuthenticationProvider` 添加进去
3. 允许基于用户名/密码的身份验证（即 `UsernamePasswordAuthenticationFilter`）

所以我们直接删除  `DaoAuthenticationProvider daoAuthenticationProvider(){...}` 函数让 Spring Security 自动管理就行了, 然后之前的代码:

```java
http.authenticationProvider(daoAuthenticationProvider())
  .formLogin(Customizer.withDefaults());
```

改为:

```java
http.formLogin(Customizer.withDefaults());
```

### 4.2. 验证 Session ID

这一步不用我们操作, Spring Security 会自动帮我们验证, 我们上面的代码:

```java
http.sessionManagement(session -> session
    .sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED)
    .maximumSessions(1)
    .expiredUrl("/login?expired")
);
```

启用了 会话管理，Spring Security 会:

1. 检查 Session ID 是否有效（自动解析 `JSESSIONID`）
2. 限制最多 1 个会话（如果用户在另一个地方登录，旧的 Session 会被踢下线）
3. 会话过期后跳转到 `/login?expired`

当然你可以自己实现自己的 Session ID 认证逻辑, 还记得上面我们提到的 `OncePerRequestFilter` 吗? 

```java
@Component
public class SessionValidationFilter extends OncePerRequestFilter {
    @Autowired
    private HttpSession session;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        if (session.getAttribute("SPRING_SECURITY_CONTEXT") == null) {
            response.sendRedirect("/login?expired");
            return;
        }
        filterChain.doFilter(request, response);
    }
}
```

然后注册到 `SecurityFilterChain`：

```java
@Bean
public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    // ...
    // 注册过滤器
    http.addFilterBefore(new SessionValidationFilter(), UsernamePasswordAuthenticationFilter.class);
    return http.build();
}
```

但这完全是不必要的，因为 Spring Security 已经自动处理了这个逻辑。

```
1. 用户发送 `POST /login` 请求
2. `SecurityFilterChain`（接口，定义 Spring Security 过滤器链）
   - 由 `DefaultSecurityFilterChain` 实现
   - 其中包含 `UsernamePasswordAuthenticationFilter`
   - `UsernamePasswordAuthenticationFilter` 解析请求，并调用 `AuthenticationManager`
3. `AuthenticationManager`（接口，定义认证管理逻辑）
   - 由 `ProviderManager` 实现
   - `ProviderManager` 遍历 `List<AuthenticationProvider>`
4. `AuthenticationProvider`（接口，定义认证提供者）
   - `DaoAuthenticationProvider`（`AuthenticationProvider` 的实现）
   - `DaoAuthenticationProvider` 调用 `UserDetailsService.loadUserByUsername()`
5. `UserDetailsService`（接口，定义用户数据加载逻辑）
   - 由 `MyUserDetailsService` 实现
   - `MyUserDetailsService` 查询数据库，返回 `UserDetails`（包含用户名、密码、权限）
6. `DaoAuthenticationProvider` 使用 `PasswordEncoder` 验证密码
   - `PasswordEncoder.matches(rawPassword, encodedPassword)`
   - 由 `BCryptPasswordEncoder` 实现
7. 如果认证成功：
   - `DaoAuthenticationProvider` 返回 `UsernamePasswordAuthenticationToken`（已认证的 `Authentication` 对象）
   - `ProviderManager` 返回 `Authentication`，认证完成
   - `SecurityContextHolder` 存储 `Authentication`，用户成功登录
8. 认证通过后，Spring Security 允许访问受保护资源
```

### 4.3. 自定义登录表单页面

上面我们提到, 我们不仅可以使用 Spring Security 自定义的表单页面, 还可以自己定义页面使用, 我们要做的就是在  `securityFilterChain()` 方法中, 替换之前指定默认表单的语句:

```java
public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    // 修改这个语句
    http.authenticationProvider(daoAuthenticationProvider())
      .formLogin(Customizer.withDefaults());
  ...
}
```

```java
public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    // 配置 URL 访问权限
    http.authorizeHttpRequests(auth -> {
        auth.requestMatchers("/login", "/css/**", "/js/**").permitAll();
        auth.anyRequest().authenticated();
    });

    // 配置表单登录
    http.formLogin(form -> {
        form.loginPage("/login");
        form.loginProcessingUrl("/login");
        form.defaultSuccessUrl("/home", true);
        form.permitAll();
    });

    // 配置登出
    http.logout(logout -> {
        logout.logoutUrl("/logout");
        logout.logoutSuccessUrl("/login?logout");
        logout.permitAll();
    });

    return http.build();
}
```

注意这种配置容易引起无限重定向问题,
``` 
This page isn’t working
localhost redirected you too many times.
Try deleting your cookies.
ERR_TOO_MANY_REDIRECTS
```

大致原因是没有实现 `/login` 路径的 GET 方法, 且没有设置为 所有用户都可以访问 `/login`, 如果你的 `loginPage("/login")` 其实返回的是某个 Thymeleaf 模板（或者前端页面），却没有对外暴露出可访问的 `GET /login` 路由（或者在控制器中又重定向到别的地方），就会导致访问 `/login` 时再次跳到另一个需要认证的路径，从而产生循环。

> Spring Security 中, 很多种认证方式, JWT 或者 http.formLogin 或者 httpBasic(Customizer.withDefaults()); 且他们可以同时存在, 但一般不会这么做, [了解更多](https://chatgpt.com/share/67aeb98d-7038-8002-afa9-c758167f6dea)
>
> 对于纯 REST API 场景，使用无状态认证（JWT 或 OAuth2）是主流做法，后端无需维护 Session，更适合前后端分离和分布式微服务场景。如果业务中尚有一部分需要基于 Session 的传统登录或后台管理，可以针对不同路径（`/home`, `/discuss`, `/api/users`, `/api/posts/[id]`）进行多 `HttpSecurity` 配置，把 JWT 和 FormLogin (Session) 并存。
