---
title: C++ Class Definition Rules
date: 2023-05-16 22:36:06
categories:
 - c++
 - basics
tags:
 - c++
---

- Make any member function that does not modify the state of the class object `const`, so that it can be called by const objects.
- **Default parameters** for member functions should be declared in the class definition (in the header file), where they can be seen by whomever `#includes` the header.
- For classes used in only one file that aren’t generally reusable, define them directly in the single `.cpp` file they’re used in.
- For classes used in multiple files, or intended for general reuse, define them in a `.h` file that has the same name as the class.
- **Trivial member functions** (trivial constructors or destructors, access functions, etc…) can be defined inside the class. **Non-trivial member functions** should be defined in a `.cpp` file that has the same name as the class.
- Member functions defined inside the class definition are implicitly inline. Inline functions are exempt from the one definition per program part of the one-definition rule.

> **So why not put everything in a header file?**
> First, as mentioned above, defining members inside the class definition clutters up your class definition. Second, if you change any of the code in the header, then you’ll need to recompile every file that includes that header. This can have a ripple effect, where one minor change causes the entire program to need to recompile (which can be slow). If you change the code in a .cpp file, only that .cpp file needs to be recompiled!
> There are [a few cases](https://www.learncpp.com/cpp-tutorial/classes-and-header-files/) where it might make sense to violate the best practice of putting the class definition in a header and non-trivial member functions in a code file.

Separating the class definition and class implementation is very common for libraries that you can use to extend your program. Throughout your programs, you’ve #included headers that belong to the standard library, such as iostream, string, vector, array, and other. Notice that you haven’t needed to add iostream.cpp, string.cpp, vector.cpp, or array.cpp into your projects. Your program needs the declarations from the header files **in order for the compiler to validate you’re writing programs that are syntactically correct**. However, the implementations for the classes that belong to the C++ standard library are contained in a precompiled file that is linked in at the link stage. You never see the code.

Outside of some open source software (where both .h and .cpp files are provided), most 3rd party libraries provide only header files, along with a precompiled library file. There are several reasons for this: 1) It’s faster to link a precompiled library than to recompile it every time you need it, 2) a single copy of a precompiled library can be shared by many applications, whereas compiled code gets compiled into every executable that uses it (inflating file sizes), and 3) intellectual property reasons (you don’t want people stealing your code).

Having your own files separated into declaration (header) and implementation (code file) is not only good form, it also makes creating your own custom libraries easier. Creating your own libraries is beyond the scope of these tutorials, but separating your declaration and implementation is a prerequisite to doing so.

References: [13.11 — Class code and header files – Learn C++](https://www.learncpp.com/cpp-tutorial/class-code-and-header-files/)