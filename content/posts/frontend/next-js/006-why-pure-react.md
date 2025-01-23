---
title: Why a Component Needs to be a Pure Function - React.js
date: 2024-12-12 08:38:30
tags:
 - front-end
---

> 永恒不变的真理: 默认情况下, 当一个组件重新渲染时, React 将递归渲染它的所有子组件

Pure 函数就是 只要输入相同, 则输出一定相同, 在 React Component 中 pure component 可以理解为 只要传入的 props 相同, 用户操作(比如点击按钮) 相同, 那 render 阶段返回的 html 就应该相同, 可能总结也不准确, 所以我们来讨论什么行为是 impure, 只要不犯错, 那做的都是对的

--------

错误做法:

```ts
// ❌ Bad: Modifying props during render
function RichTextEditor({ content }) {
  // 开发者想在每次渲染时更新内容的最后修改时间
  content.lastModified = Date.now();
  content.version++;
  
  return <div>
    <Editor content={content} />
    <div>Last modified: {content.lastModified}</div>
  </div>;
}
```

正确做法：

```ts
// 让父组件传入一个修改函数控制更新
function RichTextEditor({ content, onContentChange }) {
  const handleChange = (newContent) => {
    onContentChange({
      ...newContent,
      lastModified: Date.now(),
      version: (newContent.version || 0) + 1
    });
  };

  return <div>
    <Editor 
      content={localContent}
      onChange={handleChange}
    />
    <div>Last modified: {localContent.lastModified}</div>
  </div>;
}
```

为什么这么操作是 pure?

这个组件在渲染过程中只做了两件事：

1. 定义了一个事件处理函数 handleChange
2. 返回 JSX

关键是：它没有直接修改传入的 content 对象, handleChange 虽然会触发修改，但它是事件处理函数，不是在渲染过程中执行的

------

错误做法:

```ts
// ❌ Bad: Modifying props during render
function SignupForm({ formData }) {
  // 开发者想在渲染时添加验证状态
  formData.errors = validateFields(formData);
  formData.isValid = Object.keys(formData.errors).length === 0;
  
  return <form>
    <input value={formData.email} />
    {formData.errors.email && <span>{formData.errors.email}</span>}
  </form>;
}
```

正确做法：

```ts
function SignupForm({ initialData }) {
  const [formData, setFormData] = useState(initialData);
  const [errors, setErrors] = useState(...);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
    
    const newErrors = {};
    if (name === 'email' && !/^\S+@\S+$/i.test(value)) {
      newErrors.email = '请输入有效的邮箱';
    }
    setErrors(newErrors);
  };

  return (
    <form>
      <input
        name="email"
        value={formData.email || ''}
        onChange={handleChange}
      />
      {errors.email && <span>{errors.email}</span>}
    </form>
  );
}
```

> 修改 props 有两个选择
>
> 第一种: 父组件传递一个 修改函数, 然后在子组件的 event handler 调用这个函数来修改 props, 如第一个例子
>
> 第二种: 通过 useState() 创建一个 props 副本, 在 event handler 种调用 setState 修改, 如第二个例子

-------

```ts
// ❌ Impure: Performing side effects during render phase
function SearchBar() {
  // Wrong: API call during render
  const results = fetch(`/api/search?q=test`);
  
  return <div>{results}</div>;
}

// ✅ Pure: Move side effect to event handler
function SearchBar() {
  const [results, setResults] = useState(null);
  
  const handleSearch = async (query) => {
    const data = await fetch(`/api/search?q=${query}`);
    setResults(data);
  };
  
  return <div>
    <input onChange={e => handleSearch(e.target.value)} />
    {results && <div>{results}</div>}
  </div>;
}

// ❌ Impure: Modifying DOM in render
function NotificationBell() {
  // Wrong: DOM manipulation during render
  if (hasNewNotifications) {
    document.title = `(${count}) New Messages`;
  }
  
  return <bell-icon />;
}

// ✅ Pure: Handle in click event
function NotificationBell() {
  const handleClick = () => {
    // OK to modify DOM in event handler
    document.title = `(${count}) New Messages`;
  };
  
  return <bell-icon onClick={handleClick} />;
}

// ❌ Impure: Local storage operations during render
function UserPreferences({ theme }) {
  // Wrong: localStorage operation during render
  localStorage.setItem('theme', theme);
  
  return <div className={theme}>...</div>;
}

// ✅ Pure: Handle in effect or event
function UserPreferences({ theme }) {
  // Option 1: Handle in effect if needs to sync with prop
  useEffect(() => {
    localStorage.setItem('theme', theme);
  }, [theme]);
  
  // Option 2: Handle in event if user-triggered
  const handleThemeChange = (newTheme) => {
    localStorage.setItem('theme', newTheme);
  };
  
  return <div className={theme}>
    <button onClick={() => handleThemeChange('dark')}>Dark</button>
  </div>;
}

// ❌ Impure: WebSocket connection during render
function ChatRoom() {
  // Wrong: Creating WebSocket during render
  const ws = new WebSocket('ws://chat');
  
  return <div>Chat Room</div>;
}

// ✅ Pure: Handle connection in effect
function ChatRoom() {
  useEffect(() => {
    const ws = new WebSocket('ws://chat');
    return () => ws.close(); // Cleanup on unmount
  }, []);
  
  return <div>Chat Room</div>;
}
```

> In React, **side effects usually belong inside [event handlers.](https://react.dev/learn/responding-to-events)** Event handlers are functions that React runs when you perform some action—for example, when you click a button. Even though event handlers are defined *inside* your component, they don’t run *during* rendering! **So event handlers don’t need to be pure.** 
>
> If you’ve exhausted all other options and can’t find the right event handler for your side effect, you can still attach it to your returned JSX with a [`useEffect`](https://react.dev/reference/react/useEffect) call in your component. This tells React to execute it later, after rendering, when side effects are allowed. **However, this approach should be your last resort.**