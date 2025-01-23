---
title: Asp .Net Core Model Binding
date: 2024-07-26 19:42:36
tags:
 - c#
---

### 1. Data Source

By default, model binding gets data in the form of key-value pairs from the following sources in an HTTP request:

1. Form fields (case insensitive)
2. The request body (For [controllers that have the [ApiController\] attribute](https://learn.microsoft.com/en-us/aspnet/core/web-api/?view=aspnetcore-8.0#binding-source-parameter-inference).)
3. Route data
4. Query string parameters
5. Uploaded files

### 2. Simple types

[Model Binding in ASP.NET Core | Microsoft Learn](https://learn.microsoft.com/en-us/aspnet/core/mvc/models/model-binding?view=aspnetcore-8.0#simple-types)

### 3. Complex Type

A complex type must have a **public default constructor** and **public writable properties** to bind. When model binding occurs, the class is instantiated using the public default constructor.

> **Note:**  When you use the `[ApiController]` attribute, ASP.NET Core automatically handles model validation for you. If the model state is invalid, it returns a 400 Bad Request response with validation errors before your action method is even executed. Therefore, `if (!ModelState.IsValid){...}` is not needed in this case. 

Now we can talk about the model binding's behaviours, let's talk when error happens first. We know that the complex type must have `public default constructor` and `public writable properties`, otherwise binding process fails. 

```c#
[ApiController]
[Route("/")]
public class WeatherForecastController : ControllerBase
{
    [HttpPost]
    public IActionResult CreateCat(Cat cat)
    {
        Console.WriteLine($"Cat Info: {cat.Name}, Age: {cat.Age}");
        return Ok(cat);
    }
}

public class Cat
{
    public string Name;
    public int Age;
}
```

### 3.1. No `public writable properties`

We make a post request and get a empty json response:

```bash
❯ curl -X POST http://localhost:5079/ \
  -H "Content-Type: application/json" \
  -d '{"Name":"Jelly", "Age":2}'
{}
```

Then the web server's console output:

```c#
Cat Info: , Age: 0
```

Why? Because class `Cat` has two fields not **public writable properties**. 

If we change our code like this:

```c#
public class Cat
{
    public string Name { get; set; }
    public int Age { get; set; }
}
```

Then we get the response as we expected:

```bash
❯ curl -X POST http://localhost:5079/ \
  -H "Content-Type: application/json" \
  -d '{"Name":"Jelly", "Age":2}'
{"name":"Jelly","age":2}

❯ curl -X POST http://localhost:5079/ \
  -H "Content-Type: application/json" \
  -d '{"Name":"Jelly"}'
{"name":"Jelly","age":0}

❯ curl -X POST http://localhost:5079/ \
  -H "Content-Type: application/json" \
  -d '{"Age":2}'
{"type":"https://tools.ietf.org/html/rfc9110#section-15.5.1","title":"One or more validation errors occurred.","status":400,"errors":{"Name":["The Name field is required."]},"traceId":"00-8ac6e0182eaa34cbbfa93a2ea031d780-220d5f992ad3ab26-00"}
```

### 3.2. No `public default constructor`

```c#
public class Cat
{
    public Cat(string name, int age)
    {
        Name = name;
        Age = age;
    }
    
    public string Name { get; }
    public int Age { get;}
}
```

This no public default constructor `public Cat() {}`,  but it still works, and works totally same as we don't declare constructor explicitly, it seems related to that Since 3.0 .NET Core [uses the newer System.Text.Json serializer by default](https://learn.microsoft.com/en-us/aspnet/core/migration/22-to-30?view=aspnetcore-3.1&tabs=visual-studio#newtonsoftjson-jsonnet-support). Learn more: https://stackoverflow.com/a/60406568/16317008

Now cannot find the documents talk about this, but we can know that we don't need to declare the constructor, and the deserialization behavior in asp .net web controller:

- Don't need declare constructor explicitly for the DTO class. 
- It's case insensitive. 
- In addition to missing required properties causing serialization to fail, missing non-nullable properties will also cause serialization to fail. If fails, client will get error message for 500 bad request. 
- Furthermore, fields will be ignored.

