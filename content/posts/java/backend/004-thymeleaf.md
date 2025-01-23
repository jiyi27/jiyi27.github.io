---
title: Thymeleaf, Spring学习(四)
date: 2023-08-01 13:55:48
categories:
 - Java
 - Backend
tags:
 - Java
 - Spring Boot
---

## 实现功能

- 访问 http://localhost:8080/ 的时候主页列出所有的猫猫信息(name+age), 

![1](/004-thymeleaf/1.png)

- 可通过参数查找某个猫猫信息如 http://localhost:8080/?name=Max, 如果猫猫Max存在将会列出其信息, 不存在则进行提示,

![2](/004-thymeleaf/2.png)

![3](/004-thymeleaf/3.png)

通过实现以上功能展示如何通过controller往html模板插入数据, 形成动态html页面, 

> 注意此例子中 html 模板就是 `index.html`, 更准确的说法是, 通过在html的一些标签里添加一些Thymeleaf属性, 然后html就成了html模板, 

源码: https://github.com/shwezhu/springboot-learning/tree/master/thymeleaf-example

## 项目结构

```
src
├── java
│   └── com
│       └── david
│           ├── ThymeleafExampleApplication.java
│           ├── bean
│           │   └── Cat.java
│           └── controller
│               └── MainController.java
└── resources
    ├── application.properties
    ├── static
    │   └── css
    │       └── main.css
    └── templates
        └── index.html
```

## 添加依赖

在`pom.xml`中加入并reload

```xml
<dependency>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-thymeleaf</artifactId>
</dependency>
```

注意, 从上面代码可以看出本例子用的是spring boot, 用spring配置起来会很麻烦, 

## 代码解释

理解了Thymeleaf的逻辑, 之后看着文档自己就能写了, 这里只讲一个, 对于下面代码, 当访问 http://localhost:8080/ 的时候, 得到页面如下:

![4](/004-thymeleaf/4.png)

首先若不在html文件中使用Thymeleaf的时候, controller代码如下:

```java
@RestController
public class GreetingController {
    @GetMapping("/greeting")
    public Greeting greeting(@RequestParam(value = "name", defaultValue = "World") String name) {
        // ...
       return new Greeting(); // 返回的Greeting会被spring自动转为json对象
    }
}
```

> 该controller是个简单的 restful api, 用来返回简单的json数据, 若不理解此段代码可以到[第一个Spring Boot项目及踩坑总结 Spring学习(一) ](https://davidzhu.xyz/2023/07/29/Java/Backend/001-first-spring-boot-program/)查看相关注解的解释, 

通过thymeleaf向html插入数据, 此时的controller如下, 

```java
@Controller
public class MainController {
    @GetMapping("/")
    public String home(Model model) {
        model.addAttribute("title", "hello little kittens");
        return "index";  // return index.html
    }
}
```

对应的`index.html`代码如下:

```html
<!DOCTYPE HTML>
<html lang="en" xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="utf-8">
    <title>Spring Boot Thymeleaf Example</title>
</head>

<body>
<h1>
		<span th:text="'Hello, ' + ${title}"></span>
</h1>

</body>
</html>
```

可以注意到controller的方法只是多了一个参数即类 `org.springframework.ui.Model` 的对象, 然后通过调用其对象的`addAttribute()`方法向将要返回的html中动态地插入数据, 此例中插入的数据为字符串`"hello little kittens"`, 往哪插入? 当然是`"title"` 属性, 然后就可以在`index.html`预访问`"title"` 的值, 注意, 这里说是**预防问**是因为变量`title`的数据还没到, 需要controller的方法执行到`return "index";` 的时候, 数据才算是真的到了 `index.html`, 数据处理的大致过程如下:

- 客户端发送http请求, Spring框架调用controller对应的函数
- controller对应方法的语句执行完毕(如查询数据库, 向Model对象添加属性), 函数返回字符串`"index"`, 
- Spring框架拿到该函数返回的字符串 `"index"`, Spring将会在项目template文件夹下查找文件 `index.html`  , 并配合thymeleaf之类的东西将 Model 对象的内容插入到`index.html`里对应的tag里, 如上面的例子就是把`"hello little kittens"`, 插入到标签 `<span th:text="'Hello, ' + ${title}"></span>`里, 
- 然后Spring返回最终形成的 `index.html` 给客户端

大概就是这个过程, 但细节应该不是, 比如插入数据的时候是spring做的还是thymeleaf, 这个感兴趣可以去谷歌, 这里只是叙述大致的处理过程, 以便编写thymeleaf代码有思路, 

所以你懂了吗? controller方法通过返回字符串来指定要返回的html文件, 而我们想要插入到html中的数据则通过调用`model.addAttribute()`来指定, 这个过程就相当于制造零件, 而零件的组装, 也就是汽车的样子, 就是我们编写的“特殊的”`index.html`文件,  也就是所谓的模板, 大概就是这么个过程, 希望可以帮助到你, 

其他内容可参考: [Introduction to Using Thymeleaf in Spring | Baeldung](https://www.baeldung.com/thymeleaf-in-spring-mvc#evaluation)

## 总结

总结下, Spring MVC, 到现在学了V和C, C即我们常写的Controller, V即是View, 就是每次 Controller 的method返回的那个view, 在Spring Boot目录结构一般如下, 

```shell
├── src
│   ├── main
│   │   ├── java
│   │   │   └── com
│   │   │       └── david
│   │   │           ├── ThymeleafExampleApplication.java
│   │   │           ├── bean
│   │   │           └── controller
│   │   └── resources
│   │       ├── application.properties
│   │       ├── static
│   │       │   └── css
│   │       │       └── main.css
│   │       └── templates
│   │           └── index.html
```

在HTML标签插入一些属性就成了Thymeleaf模板也就是项目中的 `index.html`, 如`<span th:text="${cat.name}" />`, 而controller通过设置`Model` 对象属性向`index.html`插入数据, 进而形成内容不同的 `index.html` 返回给客户端, 像是在搭积木, 

注意上面我们提到的 controller 只是个泛指, 实际上 controller 就是个普通的类, 被注解`@Controller`, `@RestController`, 修饰的就是 controller class, 然后该类的method一般被 `@GetMapping("/cat")`, `@PostMapping("/cat/add")` 等注解修饰, 来处理不同的http请求, 即真正处理http请求并返回html文件的是 controller class的method, 
