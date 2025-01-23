---
title: Vite & Deployment - React
date: 2023-12-20 19:44:22
categories:
 - front-end
tags:
 - front-end
---

## 1. Create project with Vite

```js
npm create vite@latest name-of-your-project -- --template react
cd <your new project directory>
npm install react-router-dom localforage match-sorter sort-by
npm run dev/npm run build
```

> The Proxy in vite.config.js just works for development mode. In production mode it doesn't work.

The production mode means you run `npm run build` which will generate a `dist` folder. Then you can deploy that folder into your server. 


## 2. Deploy to server

```js
scp -rp dist/* root@129.18.30.20:/var/www/html/
```

Then follow this: [Nginx - David's Blog](https://davidzhu.xyz/post/build-website/007-nginx/)

