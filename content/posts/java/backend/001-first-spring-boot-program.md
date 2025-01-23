---
title: 创建Spring Boot项目及踩坑总结 Spring学习(一)
date: 2023-07-29 16:47:46
categories:
 - Java
 - Backend
tags:
 - Java
 - Spring Boot
---

## 错误总结

**(1) 所有Java代码**都要在`java`目录下, 即不可删除`java`目录, 否则, 运行`./mvnw clean package`报错, 你可以自己试试

```shell
├── pom.xml
├── src
│   ├── main
│   │   ├── java
│   │   │   └── com
│   │   │       ├── MyAppApplication.java
│   │   │       └── restservice
│   │   │           ├── Greeting.java
│   │   │           └── GreetingController.java
```

**(2) controller** 等组件所在文件夹需要在主类的同级或者次级目录, 否则运行程序访问`http://localhost:8080/greeting`会出现错误:

```shell
Whitelabel Error Page 
This application has no explicit mapping for /error, so you are seeing this as a fallback. 
Tue Jun 30 17:24:02 CST 2023 There was an unexpected error (type=Not Found, status=404). No message available 
```

主类就是被`@SpringBootApplication`修饰的那个类, 

正确结构:

```shell
├── java
│   └── com
│       ├── MyAppApplication.java
│       └── restservice
│           ├── Greeting.java
│           └── GreetingController.java
# or
├── java
│   └── com
│       ├── MyAppApplication.java
│       ├── Greeting.java
│       └── GreetingController.java
```

错误结构: 

```shell
├── java
│   ├── com
│   │   └── MyAppApplication.java
│   └── restservice
│       ├── Greeting.java
│       └── GreetingController.java
```

具体可参考: [spring - This application has no explicit mapping for /error - Stack Overflow](https://stackoverflow.com/questions/31134333/this-application-has-no-explicit-mapping-for-error)

## 新概念 Record Class

参照 `Greeting.java` 源码发现 `Greeting` 与传统的类不同, 没有构造函数, 更像是个函数, 

> One of the main advantages of **records over POJOs** is that they reduce the amount of boilerplate code needed to define a class. For example, a POJO might require a constructor, getters, setters, equals, hashCode, and toString methods, all of which must be manually defined. With records, all of these methods are automatically generated based on the record’s fields.  - [Java Records vs POJO](https://shixseyidrin.medium.com/java-records-vs-pojo-bb7dd26f43f0)

*POJO* Class: [What Is a Pojo Class? | Baeldung](https://www.baeldung.com/java-pojo-class)

## Jackson 

可能会好奇, 为什么没有用 json 库, 直接返回是一个Greeting对象,但得到的内容却是 json 格式的信息呢?  教程里给的解释:

> This application uses the Jackson JSON library to automatically marshal instances of type `Greeting` into JSON. Jackson is included by default by the web starter.

原来是 spring boot 集成了 Jackson, 代码里没有用相关的代码是因为Spring Boot 用了 *ObjectMapper* , 

>When using JSON format, Spring Boot will use an *ObjectMapper* instance to **serialize responses and deserialize requests**. [Spring Boot: Jackson ObjectMapper](https://www.baeldung.com/spring-boot-customize-jackson-objectmapper)

## 源码解释

 项目创建过程可参考: [Getting Started | Building a RESTful Web Service](https://spring.io/guides/gs/rest-service/)

```java
// MyApplicaiton.java
package com;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class MyAppApplication {
    public static void main(String[] args) {
        SpringApplication.run(MyAppApplication.class, args);
    }
}
```

 ```java
// Greeting.java
package com.restservice;
public record Greeting(long id, String content) { }
 ```

```java
// GreetingController.java
package com.restservice;

import java.util.concurrent.atomic.AtomicLong;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

// 此类被@RestController修饰, 当其所有methods返回一个类的对象时, spring将自动处理被返回的对象, 转为json格式返回
// @RestController = @Controller + @ResponseBody
@RestController
public class GreetingController {
    private static final String template = "Hello, %s!";
    private final AtomicLong counter = new AtomicLong();

    @GetMapping("/greeting")
    public Greeting greeting(@RequestParam(value = "name", defaultValue = "World") String name) {
        // 返回的Greeting会被spring自动转为json对象
        return new Greeting(counter.incrementAndGet(), String.format(template, name));
    }
}
```

- The `@GetMapping` annotation ensures that HTTP GET requests to `/greeting` are mapped to the `greeting()` method.
- There are companion annotations for other HTTP verbs (e.g. `@PostMapping` for POST). There is also a `@RequestMapping` annotation that they all derive from, and can serve as a synonym (e.g. `@RequestMapping(method=GET)`).
- `@RequestParam` binds the value of the query string parameter `name` into the `name` parameter of the `greeting()` method. If the `name` parameter is absent in the request, the `defaultValue` of `World` is used.
- This code uses Spring `@RestController` annotation, which marks the class as a controller where every method returns a **domain object** instead of a **view**. `@RestController` =  `@Controller` + `@ResponseBody`. `@Controller` is used to declare common web controllers which can return HTTP response but `@RestController` is used to create controllers for REST APIs which can return JSON. 
- The `Greeting` object must be converted to JSON. Thanks to Spring’s HTTP message converter support, you need not do this conversion manually. Because [Jackson 2](https://github.com/FasterXML/jackson) is on the classpath, Spring’s [`MappingJackson2HttpMessageConverter`](https://docs.spring.io/spring/docs/current/javadoc-api/org/springframework/http/converter/json/MappingJackson2HttpMessageConverter.html) is automatically chosen to convert the `Greeting` instance to JSON.
- `@SpringBootApplication` is a convenience annotation that adds all of the following:
  - `@Configuration`: Tags the class as a source of bean definitions for the application context.
  - `@EnableAutoConfiguration`: Tells Spring Boot to start adding beans based on classpath settings, other beans, and various property settings. For example, if `spring-webmvc` is on the classpath, this annotation flags the application as a web application and activates key behaviors, such as setting up a `DispatcherServlet`.
  - `@ComponentScan`: Tells Spring to look for other components, configurations, and services in the `com/example` package, letting it find the controllers.

最后一个没怎么看明白, 也不打算现在弄明白, 想着随着学习的深入, 慢慢的对 spring 有个更清晰的认识的时候, 就慢慢懂了, 

上面关于 `@RestController` 的解释: ... *every method returns a **domain object** instead of a **view***, 这里的view指的是返回html文件, 也就是说若你想提供处理restful api然后返回简单的json数据服务, 那就用 `@RestController` 修饰该 controller, 然后让该controller的每个方法都返回一个对象, 剩下的交给 spring 框架, 它会自动帮你把返回的对象转为json对象然后返回给客户端, 

If you use Maven, you can run the application by using `./mvnw spring-boot:run`. Alternatively, you can build the JAR file with `./mvnw clean package` and then run the JAR file, as follows:

```
java -jar target/gs-rest-service-0.1.0.jar
```

Now that the service is up, visit `http://localhost:8080/greeting`
