---
title: Spring Security
date: 2025-02-13 20:29:10
categories:
 - java
tags:
 - java
 - spring
---

## 1. 前言

AuthenticationManager, AuthenticationProvider , ProviderManager, AuthenticationManager, DaoAuthenticationProvider, UserDetailsService, SecurityFilterChain, 这么多类和接口, 搞糊涂了已经, 去年学过一次 Spring Security, 感觉太复杂~~(没学会)~~, 就转战 Golang 了, 到最后找工作还是得面对 Java, 这不, 开始恶补 Spring...

## 2. 站在更高的角度看问题

```java
@Configuration
@RequiredArgsConstructor
public class SecurityConfig {
    private final CustomUserDetailsService customUserDetailsService;

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider();
        authProvider.setUserDetailsService(customUserDetailsService);
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http.authorizeHttpRequests(auth -> auth
                .requestMatchers("/login", "/home").permitAll()
                .anyRequest().authenticated()
        );
      
        http.authenticationProvider(authenticationProvider())
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













Spring Security 中, 有两种认证方式, JWT 或者 http.formLogin 或者 httpBasic(Customizer.withDefaults()); 且他们可以同时存在, 但一般不会这么做, https://chatgpt.com/share/67aeb98d-7038-8002-afa9-c758167f6dea



```java
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



SessionCreationPolicy 



```java
@Bean
public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    http.authorizeHttpRequests(auth -> auth
            .requestMatchers("/login", "/home").permitAll()
            .anyRequest().authenticated()
    );

    http.formLogin(form -> form
            .loginPage("/login")
            .permitAll()
    );

    http.sessionManagement(session -> session
            .sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED)
            .maximumSessions(1)
            .expiredUrl("/login?expired")
    );
    return http.build();
}
```

```java
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http.authorizeHttpRequests(auth -> auth
                .requestMatchers("/login", "/home").permitAll()
                .anyRequest().authenticated()
        );

        http.authenticationProvider(authenticationProvider()).formLogin(Customizer.withDefaults());

        http.sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED)
                .maximumSessions(1)
                .expiredUrl("/login?expired")
        );
        return http.build();
    }
```

