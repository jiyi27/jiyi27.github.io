---
title: AJAX Request Methods in JS
date: 2024-08-04 20:02:10
categories:
 - front-end
tags:
 - front-end
---

| Method         | Promise-based | Progress Tracking^ | Auto JSON Transform | Browser Support |
| -------------- | ------------- | ------------------ | ------------------- | --------------- |
| XMLHttpRequest | No            | Yes                | No                  | All browsers    |
| Fetch API      | Yes           | No                 | No                  | Modern browsers |
| Axios          | Yes           | Yes                | Yes                 | All browsers*   |
| jQuery.ajax()  | Optional      | Yes                | Yes                 | All browsers*   |

^ Note: Progress Tracking refers to the ability to monitor and report the progress of data transfer, typically during file uploads or downloads. This feature is particularly useful for large file transfers, allowing developers to create progress bars or provide status updates to users.

\* Note: Axios, jQuery are libraries that can be used in all browsers, but they may require polyfills for older browsers to ensure full functionality.

------

One of the good points of Axios over fetch is it treats any status code outside the 2xx range as an error, and do the parses JSON responses automatically. 

```js
let token = ''

loginForm.addEventListener('submit', async (e) => {
    e.preventDefault()
    const formData = {...}

    try {
        const response = await fetch(...)

        // We have to parse the response body as JSON to access it.
        const data = await response.json()
        console.log(data)
  
        // You have to check the status code, cause code 500, 400 is not treated as error in fetch().
        if (!response.ok) {
            console.log("Failed to login, status code: ", response.status)
            return
        }

        // Only set the token if login is successful.
        token = data.token
    } catch (error) {
        console.log("Failed to login: ", error)
    }
})
```

What I get:

```
{$id: "1", message: "Invalid username or password."}
Failed to login, status code: 400
```

If use Axios, we can write more concise code:

```js
loginForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const formData = {
        username: loginForm.loginUsername.value,
        password: loginForm.loginPassword.value
    };

    try {
        const response = await axios.post(`${API_URL}/api/auth/login`, formData, {
            headers: {
                'Content-Type': 'application/json'
            }
        });

        // No need to parse JSON, axios does it for us.
        // No need to check status code, axios throws error if status code is not 2xx.
        token = data.token;
    } catch (error) {
        // You can just use: console.error("Failed to login:", error);
        if (error.response) {
            console.error("Failed to login:", error.response.data);
        } else {
            console.error("Failed to login:", error);
        }
    }
});
```

Then I get:

```
Failed to login: {$id: "1", message: "Invalid username or password."}
```

