---
title: npm vs npx vs pnpm
date: 2024-12-08 15:20:22
tags:
 - front-end
---

```bash
$ npx create-next-app@latest learn-by-example --use-pnpm
✔ Would you like to use TypeScript? … No / Yes
✔ Would you like to use ESLint? … No / Yes
✔ Would you like to use Tailwind CSS? … No / Yes
✔ Would you like your code inside a `src/` directory? … No / Yes
✔ Would you like to use App Router? (recommended) … No / Yes
✔ Would you like to use Turbopack for `next dev`? … No / Yes
✔ Would you like to customize the import alias (`@/*` by default)? … No / Yes

$ pnpm add date-fns lucide-react
 
$ pnpm dlx shadcn@latest init

$ pnpm dlx shadcn@latest add textarea
```

## npm vs npx vs pnmp

```bash
# download and install Node.js
# https://nodejs.org/en/download/package-manager
brew install node@22
node -v # should print `v22.12.0`
npm -v # should print `10.9.0`

# install pnpm
# https://pnpm.io/installation
curl -fsSL https://get.pnpm.io/install.sh | sh -
```

`npm` comes with `Node.js`, and `npx` comes with `npm`. **In order to use `npm` or `npx`, you need install `node.js`.**   

```
Node.js installation
└── includes npm (Node Package Manager)
└── includes npx (Node Package Execute)
```

```bash
npx create-react-app my-app
npm install some-package
```

- NPM is a package manager for node.js, same as `pip` for python, `pnmp` is same as `npm`, but more efficient
- npx 是 npm 的一个工具, 它允许我们直接运行 npm 包中的命令行工具, 而不需要全局安装这些工具
- `create-next-app@latest`: 是 Next.js 官方提供的脚手架工具(scaffolding tool), create-next-app 是工具的名称, @latest 表示使用最新版本

举个例子来说明 npx 的作用:

```bash
# 不使用 npx 的话,我们需要先全局安装
npm install -g create-next-app
create-next-app my-project

# 使用 npx,可以直接运行而不需要安装
npx create-next-app@latest my-project
```

## pnpm

- 自己的项目添加依赖, 运行 `pnpm add xxx`, 不要在项目外运行这个指令
- 克隆的别人的项目, 进入项目后, 运行 `pnpm install` 安装所有依赖
-  查看 pnpm store 路径 `pnpm store path`
- 清除 pnpm stpre 缓存 [`pnpm store prune`](https://pnpm.io/cli/store#prune): removes *unreferenced packages* from the store. Unreferenced packages are packages that are not used by any projects on the system. Packages can become unreferenced after most installation operations, for instance when dependencies are made redundant.
- 查看所在项目已安装的所有依赖 `pnpm list` 

>  `pnpm add xxx` 虽然该命令会把依赖安装到 pnpm store 中, 但你仍应该在项目里运行这个指令, 而不是随意一个地方, 
>
> `pnpm add xxx`  会在运行该指令的地方 添加三个文件 `package.json`, `pnpm-lock.yaml`, `node_modules`, 其中 `node_modules` 包含了通过符号链接指向 pnpm store 中实际依赖包的链接, pnpm 使用符号链接来节省磁盘空间

其它用法, 类似 npm:

```bash
# 开发模式
$ pnpm run dev    # 启动开发服务器，实时编译，方便开发

# 生产模式
$ pnpm run build  # 构建优化后的生产环境代码
$ pnpm start      # 启动生产环境服务器
```

`pnpm run` is a command, and `dev`, `build`, and `start` are scripts/commands defined in your project's `package.json` file. 

Here's how a typical package.json might look:

```json
{
  "name": "your-project",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  }
}
```

You can try add a custom scripts to package.json, like:

```json
"scripts": {
  //...
  "custom": "echo 'my custom script'"
}
```

Then run: `pnpm run custom`

了解更多:

-  [Why does my `node_modules` folder use disk space if packages are stored in a global store?](https://pnpm.io/faq) 
- [How pnpm work](https://pnpm.io/motivation)

## folder structure of next.js project 

```
$ tree -a -L 1              
├── .next     # Auto-generated build output directory, created after running next build
├── next.config.ts       # Next.js configuration file in TypeScript
├── node_modules         # Dependencies installed by package manager (pnpm in this case)
├── package.json         # Project metadata and dependencies
├── public              # Static files served at runtime (images, fonts, etc.)
....
```

## learn to understand warnings

```bash
$ pnpm i @vercel/postgres
WARN Issues with peer dependencies found
.
└─┬ next 15.0.0
  ├── ✕ unmet peer react@"^18.2.0 || 19.0.0-rc-65a56d0e-20241020": found 19.0.0-rc-cd22717c-20241013
  └── ✕ unmet peer react-dom@"^18.2.0 || 19.0.0-rc-65a56d0e-20241020": found 19.0.0-rc-cd22717c-20241013
Done in 1.2s
```

- "peer dependencies" 通常翻译为"同级依赖", 它表示一个包要求宿主环境中必须安装特定的其他包才能正常工作, 举个例子：如果你安装一个 React 组件库, 若它将 React 列为 peer dependency, 这意味着这个组件库期望你的项目中已经安装了 React, 而不是它自己携带一个 React 副本
- `unmet peer react@"^18.2.0 || 19.0.0-rc-65a56d0e-20241020": found 19.0.0-rc-cd22717c-20241013`: 这个包（Next.js）要求项目使用的 React 版本必须是：应该为 18.2.0 或更高的 18.x 版本（ `^18.2.0` ）或者是特定的 RC 版本 `19.0.0-rc-65a56d0e-20241020`, 但是在项目中找到的是另一个 RC 版本：`19.0.0-rc-cd22717c-20241013`, 版本不匹配，所以系统发出警告