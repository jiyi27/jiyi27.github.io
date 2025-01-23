---
title: Why Next.js Compared with Using React.js Directly
date: 2024-12-07 18:20:22
tags:
 - front-end
---

## **Can I use React without a framework?** 

You can definitely use React without a framework—that’s how you’d [use React for a part of your page.](https://react.dev/learn/add-react-to-an-existing-project#using-react-for-a-part-of-your-existing-page) **However, if you’re building a new app or a site fully with React, we recommend using a framework.**

Here’s why.

Even if you don’t need routing or data fetching at first, you’ll likely want to add some libraries for them. As your JavaScript bundle grows with every new feature, you might have to figure out how to split code for every route individually. As your data fetching needs get more complex, you are likely to encounter server-client network waterfalls that make your app feel very slow. As your audience includes more users with poor network conditions and low-end devices, you might need to generate HTML from your components to display content early—either on the server, or during the build time. Changing your setup to run some of your code on the server or during the build can be very tricky.

> As your JavaScript bundle grows with every new feature, you might have to figure out how to **split code for every route individually**. 
> React **默认情况**不做代码分割, 
>
> ```js
> // App.jsx
> import HomePage from './pages/Home'
> import AboutPage from './pages/About'
> import ProductPage from './pages/Product'
> // 打包时这些import会被合并到一个大的bundle.js中
> // 用户访问任何页面,都会加载整个bundle.js
> 
> function App() {
>   return (
>     <Routes>
>       <Route path="/" element={<HomePage />} />
>       <Route path="/about" element={<AboutPage />} />
>       <Route path="/product" element={<ProductPage />} />
>     </Routes>
>   )
> }
> ```
>
> **使用代码分割后**:
>
> ```js
> // 使用动态import
> const HomePage = lazy(() => import('./pages/Home'))
> const ProfilePage = lazy(() => import('./pages/Profile'))
> const SettingsPage = lazy(() => import('./pages/Settings'))
> 
> // 现在webpack/vite等构建工具会:
> // 1. 把每个页面的代码分别打包成单独的chunk文件
> // 2. 只在需要时才加载对应的chunk
> 
> ...
> ```



>As your data fetching needs get more complex, you are likely to encounter **server-client network waterfalls** that make your app feel very slow.
>
>传统的瀑布式获取方式:
>
>```js
>// 瀑布式请求 - 较慢
>async function loadProductPage() {
>  // 第1步: 获取商品信息
>  const product = await fetchProduct(productId);  // 等待1秒
>  
>  // 第2步: 必须等商品信息返回后才能获取卖家信息
>  const seller = await fetchSeller(product.sellerId);  // 再等1秒
>  
>  // 第3步: 必须等卖家信息返回后才能获取其他商品
>  const otherProducts = await fetchSellerProducts(seller.id);  // 再等1秒
>  
>  // 第4步: 最后获取评价
>  const reviews = await fetchReviews(otherProducts);  // 再等1秒
>}
>// 总共需要等待 4 秒
>```
>
>并行获取方式:
>
>```js
>// 并行请求 - 可能更快
>async function loadProductPage() {
>  // 同时发起多个请求
>  const [product, seller, otherProducts, reviews] = await Promise.all([
>    fetchProduct(productId),
>    fetchSeller(sellerId),
>    fetchSellerProducts(sellerId),
>    fetchReviews(productId)
>  ]);
>}
>// 总共只需要等待 1 秒
>```
>
>为什么说可能更快呢?
>
>使用 Promise.all 并行请求,如果其中一个请求特别慢,也会阻塞整个页面的渲染, 比如其他都很快, 其中一个请求耗费10s, 那就要等待10s



> As your audience includes more users with poor network conditions and low-end devices, **you might need to generate HTML from your components to display content early**—either on the server, or during the build time. 
>
> 这是在说有时候你应该使用 SSR 而不是 CSR, 可参考 frontend/next-js/003-ssr-csr.md

**These problems are not React-specific. This is why Svelte has SvelteKit, Vue has Nuxt, and so on.** To solve these problems on your own, you’ll need to integrate your bundler with your router and with your data fetching library. It’s not hard to get an initial setup working, but there are a lot of subtleties involved in making an app that loads quickly even as it grows over time. You’ll want to send down the minimal amount of app code but do so in a single client–server roundtrip, in parallel with any data required for the page. You’ll likely want the page to be interactive before your JavaScript code even runs, to support progressive enhancement. You may want to generate a folder of fully static HTML files for your marketing pages that can be hosted anywhere and still work with JavaScript disabled. Building these capabilities yourself takes real work.

> 不用 Next.js：用户访问时需要先下载整个 React 应用，然后等 JavaScript 运行，再请求新闻数据，最后才能看到内容。
>
> 用 Next.js：服务器直接返回已经包含新闻内容的 HTML，用户立即就能看到内容，体验更好。
>
> ```js
> // Vite + React 需要手动配置路由
> import { Routes, Route } from 'react-router-dom';
> 
> function App() {
>   return (
>     <Routes>
>       <Route path="/about" element={<About />} />
>       <Route path="/posts/:id" element={<Post />} />
>     </Routes>
>   )
> }
> ```
>
> ```js
> // Next.js 自动根据文件结构生成路由
> // pages/about.tsx -> /about
> // app/posts/[id]/page.tsx
> 
> 
> // app/about/page.tsx
> export default function About() {
>   return <div>About Page</div>
> }
> 
> // app/posts/[id]/page.tsx
> export default function Post({ params }: { params: { id: string } }) {
>   return <div>Post {params.id}</div>
> }
> ```

**React frameworks on this page solve problems like these by default, with no extra work from your side.** They let you start very lean and then scale your app with your needs. Each React framework has a community, so finding answers to questions and upgrading tooling is easier. Frameworks also give structure to your code, helping you and others retain context and skills between different projects. Conversely, with a custom setup it’s easier to get stuck on unsupported dependency versions, and you’ll essentially end up creating your own framework—albeit one with no community or upgrade path (and if it’s anything like the ones we’ve made in the past, more haphazardly designed).

If your app has unusual constraints not served well by these frameworks, or you prefer to solve these problems yourself, you can roll your own custom setup with React. Grab `react` and `react-dom` from npm, set up your custom build process with a bundler like [Vite](https://vitejs.dev/) or [Parcel](https://parceljs.org/), and add other tools as you need them for routing, static generation or server-side rendering, and more.

References: 

https://react.dev/learn/start-a-new-react-project#can-i-use-react-without-a-framework

https://www.reddit.com/r/nextjs/comments/17qbx9s/advice_on_choosing_nextjs_instead_of_plain_react/