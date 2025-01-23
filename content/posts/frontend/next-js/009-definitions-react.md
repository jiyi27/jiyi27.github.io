---
title: Definitions in React
date: 2024-12-16 22:12:30
tags:
 - front-end
---

Source: https://eliav2.github.io/how-react-hooks-work/

- **browser DOM** - a tree of HTML elements. These elements make up everything the user sees in the browser, including this very page.
- **React** - A library for manipulating React components.
- **React component** - function(or class) that holds stateful logic managed by React lib, that component usually returns a React Element based on the stateful logic of the same component. React have class components, and functional components(FC).
- **React Element** - React Element is what returned from React function component or from the render method of React class component.
- **React component VS React Element** - you can think of React component as a recipe for a cake, and the React element as the cake itself. in more technical terms, you can think of React element as instance of React Component, but the constructor would be the render method of class component, or the return statement of FC.
- **Stateful logic/state** - variables that hold data of the current state of the component. this data can be changed over time based on events or usage. these variables are stored and managed by React lib(it means for example that when you wish to change the state you will ask React to do it by using setState and React would schedule this change, you cannot directly change these values).
- **React tree** - a tree of React Elements(like the tree you can see in React devtools), which is managed and used internally by React. this is not the same as the browser’s DOM tree(however, it will later help React create and update the DOM tree on each render).
- **React renderer** - ReactDOM in web(or React-native in mobile) - a library that knows how to manipulate React tree and ‘render’ it into the browser’s DOM in the desired location(in React apps usually to `root` element). The renderer manages a Virtual DOM (VDOM) which is created and updated based on the given React tree.
- **phase** - this is not an official term, I’m using this term in this tutorial to describe a certain point of time in a React component. update: [also React calls this phase](https://reactjs.org/docs/strict-mode.html#detecting-unexpected-side-effects).
- **render** - Explained in detail later in [Render cycle](https://eliav2.github.io/how-react-hooks-work/#render-cycle) section.
- **update phase** - in this article when we say that a component ‘updates’, we are saying that the function component body re-executed. this is a the first phase of a render cycle.
- **Effects phase** - the effects phase is made of 4 distinct phases. Explained later.
- **React hook** - A primitive that shares stateful logic with the parent Component. The hook and the parent component updates are triggers in the same phase, and the effects of the hook and the FC also fire in the same phase(demonstrated [later](https://eliav2.github.io/how-react-hooks-work/#uselog)). React hook is allowed to be called only at the [top level of FC](https://reactjs.org/docs/hooks-rules.html#only-call-hooks-at-the-top-level). the reason for that is because internally[ React relies on the order in which Hooks are called](https://reactjs.org/docs/hooks-rules.html#explanation).