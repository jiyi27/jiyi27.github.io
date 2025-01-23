---
title: Syntax Basics
date: 2024-07-21 19:36:36
tags:
 - c#
---

## 1. Auto-implemented Properties

There are many ways to define the property of class, one basic pattern is using a private **backing field** for setting and retrieving the property value. 
```c#
public class TimePeriod
{
    private double _seconds;

    public double Hours
    {
        get { return _seconds / 3600; }
        set
        {
            if (value < 0 || value > 24)
                throw new ArgumentOutOfRangeException(nameof(value),
                      "The valid range is between 0 and 24.");

            _seconds = value * 3600;
        }
    }
}
```

But some simple properties we don't want complex task, just to retrive its value and set it, here comes the auto-implemented properties:

```c#
public class Genre
{
    public string Name { get; set; }
}
```

Equals to:
```c#
public class Genre
{
    private string name; // backing field created auto by compiler
    public string Name
    {
        get => name;
        set => name = value;
    }
}
```

> - Declare only the [get](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/keywords/get) accessor, which makes the property immutable everywhere except in the type's constructor.
> - Declare an [init](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/keywords/init) accessor instead of a `set` accessor, which makes the property settable only in the constructor or by using an [object initializer](https://learn.microsoft.com/en-us/dotnet/csharp/programming-guide/classes-and-structs/object-and-collection-initializers).
> - Declare the [set](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/keywords/set) accessor to be [private](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/keywords/private). The property is settable within the type, but it's immutable to consumers.

## 2. Field vs Property

If a class in C# has fields without explicit get and set accessors, they are fields:

```c#
public class Cat
{
    public string Name;
    public int Age;
}
```

Fields: A field is a variable declared directly in a class. It's typically used for storing data.

```c#
public class Person
{
    public string name; // This is a field
    private int age; // This is also a field, but private
}
```

Properties:A property is a member that provides a flexible mechanism to read, write, or compute the value of a private field.

```c#
public class Person
{
    private string _name; // Backing field
    public string Name   // This is a property
    {
        get { return _name; }
        set { _name = value; }
    }

    public int Age { get; set; } // Auto-implemented property
}
```

