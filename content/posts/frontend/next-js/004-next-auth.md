---
title: NextAuth V5
date: 2024-12-08 17:13:20
tags:
 - front-end
---

NextAuth v5 配置通常分为两个文件(在根目录)：`auth.config.ts` 和 `auth.ts`

当有新的请求进来时，Next.js 首先会检查 middleware.ts 中的 config 配置：

```ts
// middleware.ts
export default NextAuth(authConfig).auth;

// 不匹配 /api 路径, 不匹配 /_next/static 路径...
export const config = {
    matcher: ['/((?!api|_next/static|_next/image|.*\\.png$).*)'],
};
```

如果请求路径匹配上述规则，Next.js 就会执行 `middleware.ts` 中默认导出的函数, 也就是上面的 `export default NextAuth(authConfig).auth`

注意, 这里的 `NextAuth(authConfig).auth` 函数和 `auth.ts` 导出的那个 auth 函数是一样的, 但他们并不是同一个函数, 可以看到 `auth.ts` 和 `middleware.ts` 都用到了 `auth.config.ts`, 就是通过 `NextAuth(authConfig)` 来导出 auth 函数. 

```ts
// auth.ts
export const { auth, signIn, signOut } = NextAuth({
  ...authConfig,
  providers: [...]
})
```

这个 auth 函数主要就是会执行 `authConfig` 中的 authorized 回调, 也就是`auth.config.ts` 中的 authorized callback, 根据 authorized 的返回值决定是否允许访问:

```ts
// auth.config.ts
export const authConfig = {
    pages: {
        signIn: '/login',
    },
    callbacks: {
        authorized(...) {...},
    },
    providers: [],
} satisfies NextAuthConfig;
```

可以看出, 在 `auth.ts` 中我们只是将 `auth.config.ts` 的 `authConfig` 展开了, 其实可以不需要 `auth.config.ts` 文件, 直接把这个配置写到 `auth.ts` 中就行, 但是不推荐这么做, 如果合并的话, 那 `middleware.ts` 只能通过导入 `auth.ts` 来使用 `auth` 函数, 可是 `auth.ts`  中还有其他东西, 比如 providers, 这样的话 中间件会导入整个 `auth.ts` 文件, 数据库客户端 (prisma)所有认证提供商 (GitHub 等), 这样的话, 中间件就会变的很大, 

当我们登录的时候, 基本上可以看到的执行顺序是:

```
1. auth.config.ts 文件被加载
2. middleware.ts 文件被加载 (仅在初始编译项目后执行一次, 之后不会被重复加载)
3. auth.ts 文件被加载
4. authorized callback 被执行 { url: '/dashboard', isLoggedIn: false }
4. authorized callback 被执行 { url: '/login', isLoggedIn: false }
4. authorized callback 被执行 { url: '/dashboard', isLoggedIn: false }
4. authorized callback 被执行 { url: '/login', isLoggedIn: false }
4. authorized callback 被执行 { url: '/login', isLoggedIn: false }
5. authorize callback 被执行 (仅在登录时)
```

可以看出, 只要访问符合 middleware 规则的 url, 那 authorized callback 就会被执行一次, 也就是我们导出的 `export default NextAuth(authConfig).auth;` 

------

**Error `headers()` should be awaited**

```bash
Error:  In route /login a cookie property was accessed directly with `cookies().set('authjs.session-token', ...)`. `cookies()` should be awaited before using its value.

Error:  In route /login headers were iterated over. `headers()` should be awaited before using its value.

.....
```

This is due to updating to Next15. Headers, Page/Layout Params and cookies are now asynchronous. [click to learn more](https://nextjs.org/docs/messages/sync-dynamic-apis)

[Solution](https://www.reddit.com/r/nextjs/comments/1g9l35r/comment/lu4d2ik/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button): try `$pnpm i next-auth@beta`

