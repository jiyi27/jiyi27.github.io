---
title: Frontend JS Tricks
date: 2024-08-05 22:17:19
categories:
 - front-end
tags:
 - front-end
---

## 1. `e.preventDefault()`

```js
function sendMessage(e) {
    e.preventDefault()  // Submitting form would refresh the page, so we prevent page reload
    const input = document.querySelector('input')
    if (input.value) {
        ws.send(input.value)
        input.value = ""
    }
    input.focus()  // Focus the input after sending the message
}

document.querySelector('form').addEventListener('submit', sendMessage)
```

> Usually used to prevent page reload when submit form.

## 2. `defer` attribute of `<script>`

```html
<head>
    <meta charset="UTF-8">
    <title>Chat APP</title>
    <script defer src="js/app.js"></script>
</head>
<body>
  ...
```

> A boolean value used to execute the script only after the browser completes the rendering activity. 
>
> **Note:** The `defer` attribute can only be used when JavaScript is externally linked to the HTML file using the `src` attribute of the `<script>` tag. 

## 3. `innerHTML` property

**innerHTML** is a property of every element. It tells you what is between the starting and ending tags of the element, and it also let you sets the content of the element.

```html
<p class="myp"><a>hello hi ni</a></p>

<script>
  const myp = document.querySelector('.myp')
  console.log(myp.innerHTML)
</script>
```

This will print a stirng: 

```
<a>hello hi ni</a>
```

The `innerHTML` property is part of the Document Object Model (DOM) that allows Javascript code to manipulate a website being displayed. Specifically, it allows reading and replacing everything within a given DOM element (HTML tag).

## 4. Delay function

```js
function delay(minutes) {
    return new Promise(resolve => setTimeout(resolve, minutes * 1000 * 60));
}

// await delay(2)
```

## 5. Click copy

```html
<p id="url-text" style="display: none">{{.SharedUrl}}</p>
<button onclick="copyText()">share</button>

<script>
    function copyText() {
        const copyText = document.getElementById("url-text");
        navigator.clipboard.writeText(copyText.textContent)
            .then(() => {
                alert("successfully copied");
            })
            .catch(() => {
                alert("something went wrong");
            });
    }
</script>
```

## 6. Relative path

You can write relative path directly for the endpoint, because the browser know the **Origin**, when you make HTTP request, it knows where should go.

```html
<form method="post" action="/login">
  ...
</form>
```

And it's ok to write relative path when redirect in Go code:

```html
// Redirect to login page.
http.Redirect(w, r, "/login", http.StatusFound)
```
