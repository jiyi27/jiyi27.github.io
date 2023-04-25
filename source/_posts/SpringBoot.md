---
title: Spring Boot和Spring框架的关系-笔记 
date: 2023-04-25 20:30:22
categories:
 - Java
 - Backend
tags:
 - Java
 - Spring Boot
---

# 什么是Spring Boot

刚开始接触Spring Boot， 查了查谷歌想弄明白Spring Boot是什么， 做个笔记整理一下，我会尽量标注出处（复制好多链接真的会很麻烦🥹），有的是来自已标注出处的文章，就不再重复标注。

Spring Boot 是由 Pivotal 团队提供的全新框架，其设计目的是用来简化新 Spring 应用的初始搭建以及开发过程。该框架使用了特定的方式来进行配置，从而使开发人员不再需要定义样板化的配置。用我的话来理解，就是 Spring Boot 其实不是什么新的框架，它默认配置了很多框架的使用方式，就像 Maven 整合了所有的 Jar 包，Spring Boot 整合了所有的框架。http://www.ityouknow.com/springboot/2016/01/06/spring-boot-quick-start.html

我们在使用Spring Boot时只需要配置相应的Spring Boot就可以用所有的Spring组件，简单的说，spring boot就是整合了很多优秀的框架。https://juejin.cn/post/6983583704949981191

用一句话实在难以概述 Spring Boot，如果一定要为它下一个定义的话，那么 Spring Boot 可以被理解为是一个用来简化 Spring 应用创建、开发和运行的框架。https://blog.csdn.net/zzuhkp/article/details/123518033

Spring Boot是一个基于Spring的套件，它帮我们预组装了Spring的一系列组件，以便以尽可能少的代码和配置来开发基于Spring的Java应用程序。https://www.liaoxuefeng.com/wiki/1252599548343744/1266265175882464

传播广的博客基本观点一致，即Spring Boot更像是一个依赖管理插件来方便管理用于Spring开发相关的依赖等，当然Spring Boot本身默认为我们配置了很多以来，省的我们一一列出。所以并不是说你学了Spring Boot就不用学Spring，Spring Boot里面的东西就是Spring的一个个部件。你学Spring Boot的时候也是在学Spring。

- Spring boot是Spring的引导，就是用于启动Spring的。

- spring boot使用了默认大于配置的理念，很多集成方案已经帮你选择好了，能不配置就不配置; Spring Boot的哲学就是约定大于配置; 既然很多东西都是一样的，为什么还要去配置。

可以看一下我的Spring Boot的这个maven配置文件(`pom.xml`)的内容，可能会帮助理解Spring Boot管理组件负责组装的本质, 然后也可以用来**对比**下面讲介绍的Spring框架的maven配置文件(`pom.xml`), 可以看到若我们使用Spring Boot, Maven的配置文件依赖中的前三个组件JPA, WEB以及TEST的GroupID都是SpringBoot`<groupId>org.springframework.boot</groupId>`：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.0.5</version>
        <relativePath/> <!-- lookup parent from repository -->
    </parent>
    <groupId>com.choo</groupId>
    <artifactId>SpringDemo</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <name>SpringDemo</name>
    <description>SpringDemo</description>
    <properties>
        <java.version>17</java.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>

        <dependency>
            <groupId>mysql</groupId>
            <artifactId>mysql-connector-java</artifactId>
            <version>8.0.32</version>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <version>2.3.5.RELEASE</version>
            </plugin>
        </plugins>
    </build>

</project>
```

# Spring Boot 是如何简化应用创建的？

关于简化应用创建，最近几年刚学编程的同学可能并没有太大的感触，5 年前的 Spring 项目搭建可真是一个痛苦的过程。

最初的 Java 项目如果依赖了第三方的库，是直接将 jar 包添加到类路径中的，每次创建一个项目都需要重复这个过程，如果依赖的第三方库比较少还好，如果依赖的比较多，依赖的 jar 包发生了相互依赖，并且版本还不同，那可就头痛了。

以 Spring 为例，如果我们引入了 `spring-webmvc` 模块，我们还要紧跟着把 `spring-webmvc` 模块依赖的 `spring-bean` 模块加入到类路径，由于 `spring-bean` 模块依赖了 `spring-core` 模块，还要添加 `spring-core `添加到类路径，而我们只是想用 `spring-webmvc` 模块而已。

好在后来出现了一些依赖管理工具，例如 maven、gradle、ant，由于目前在 Java 开发中 maven 用的比较多，后面我们就拿 maven 举例了。尽管有了 maven 管理依赖，但是由于 Spring 是一个 bean 的容器，因此还需要将 bean 的元信息进行配置，最初的 Spring 使用业界最为流行的 xml 配置 bean，后来 JDK 5 注解出现后才逐渐将配置迁移到注解，曾经一度出现了 xml 和注解混用的场景。

原文: https://blog.csdn.net/zzuhkp/article/details/123518033

# 基于 Spring Framework 的 Spring MVC 项目搭建

由于 Spring 主要应用于 Web 开发，下面看下 Spring Boot 出现前是如何搭建 Spring MVC 项目的。

Spring MVC 项目需要引入 `spring-webmvc` 模块的依赖，因此首先要找的就是 `spring-webmvc` 的坐标，对于新手来说一般就是在网上找一些 Spring MVC 的入门文章，直接复制 `spring-webmvc` 的坐标了，此外就是在 maven 仓库 中根据关键字搜索。不管怎样找坐标吧，最终我们配置最简单的 `pom.xml` 内容如下。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.zzuhkp</groupId>
    <artifactId>mvc-demo</artifactId>
    <version>1.0-SNAPSHOT</version>
    <packaging>war</packaging>

    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <maven.compiler.source>1.8</maven.compiler.source>
        <maven.compiler.target>1.8</maven.compiler.target>
    </properties>
    
    <dependencies>
        <dependency>
            <groupId>org.springframework</groupId>
            <artifactId>spring-webmvc</artifactId>
            <version>5.2.6.RELEASE</version>
        </dependency>

        <dependency>
            <groupId>javax.servlet</groupId>
            <artifactId>javax.servlet-api</artifactId>
            <version>4.0.1</version>
            <scope>provided</scope>
        </dependency>

    </dependencies>

</project>
```

除了引入 `spring-webmvc` 的依赖，由于我们还可能会使用到一些 `Servlet` 规范中的一些类，我们还引入了 `Servlet` 的依赖。而依赖引入只是万里长征的第一步，由于 Java Web 开发中的接口都是 Servlet 提供的，我们还需要配置 `spring-webmvc` 模块提供的 Servlet 接口的实现 `DispatcherServlet`。这又是什么东西？当时作为新手我的也是一脸懵逼，配置时我还得找到这个**类的全限定名**，这对于新手来说也太不友好了，又是一波复制粘贴。最终配置出来的` web.xml` 文件内容如下。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="http://xmlns.jcp.org/xml/ns/javaee"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee
          http://xmlns.jcp.org/xml/ns/javaee/web-app_4_0.xsd"
         version="4.0">

    <servlet>
        <servlet-name>dispatcher</servlet-name>
        <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
    </servlet>
    <servlet-mapping>
        <servlet-name>dispatcher</servlet-name>
        <url-pattern>/</url-pattern>
    </servlet-mapping>
</web-app>
```

到这里就完了吗？显然不是，我们还没有为 Spring 配置 bean。对于 Spring MVC 来说，我们需要把 Spring 的配置文件放在` /WEB-INF/${servlet-name}-servlet.xml` 中，其中 `${servlet-name}` 为 Servelt 的名称，我们为 `DispatcherServlet` 取的名字是 dispatcher，因此我们需要创建 `/WEB-INF/dispatcher-servlet.xml `作为配置文件。这对新手又是一个挑战，还得记住命名规范，那能不能自己指定配置文件位置呢？可以，配置一个 Servlet 的初始化参数 configurationLocation 指定配置文件，好吧，还得记住参数名称。真是令人崩溃，最后看下配置文件的内容吧。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:mvc="http://www.springframework.org/schema/mvc"
       xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd http://www.springframework.org/schema/mvc https://www.springframework.org/schema/mvc/spring-mvc.xsd http://www.springframework.org/schema/context https://www.springframework.org/schema/context/spring-context.xsd">

    <bean class="org.springframework.web.servlet.view.InternalResourceViewResolver">
        <property name="prefix" value="/WEB-INF/page"/>
        <property name="suffix" value=".jsp"/>
    </bean>

    <context:component-scan base-package="com.zzuhkp.mvc"/>
</beans>
```

最初的 Java Web 开发可没有前后端分离，为了根据视图名称查找到对应的 JSP 文件，我们配置一个 InternalResourceViewResolver 类型的视图解析器 bean，这是 Spring MVC 特有的一个 bean，又是一个新概念，视图解析器又是什么？此外，我们为了启用注解支持，我们添加了 context:compent-scan 标签指定了要 Spring 要扫描的包。bean 的配置还好，最要名的是 xml 配置的命名空间，就是最上面那一坨，除了复制粘贴谁能自己写出来呢？

写到这里，我已经近乎崩溃了，简直又经历了一次那段痛苦的历史。来个 Controller 测试下请求是否正常。

```java
@Controller
public class HelloController {

    @GetMapping("/hello")
    public String hello() {
        return "/hello";
    }
}
```

Controller 方法 String 类型的返回值将作为视图名，这里我们指定的是 /hello，也就是说有一个 /hello 对应的 jsp 文件，当请求 /hello 时我们将这个文件的内容返回给前端，结合我们前面配置的 InternalResourceViewResolver，它的位置应该是 /WEB-INF/page/hello.jsp，我们定义的文件内容如下:

```java
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <title>hello</title>
</head>
<body>
Hello,Spring MVC
</body>
</html>
```

最后整个项目结构如下:

```xml
.
├── pom.xml
└── src
    └── main
        ├── java
        │   └── com
        │       └── zzuhkp
        │           └── mvc
        │               └── HelloController.java
        └── webapp
            ├── WEB-INF
            │   ├── dispatcher-servlet.xml
            │   └── web.xml
            └── page
                └── hello.jsp
```

原文: https://blog.csdn.net/zzuhkp/article/details/123518033

# 基于 Spring Boot 的 Spring MVC 项目搭建

总结基于 Spring Framework 的 Spring MVC 项目搭建有哪些问题呢？

首先概念过多，新人需要关注 spring-webmvc 中的众多概念，如 DispatcherServlet、视图解析器 InternalResourceViewResolver。其次配置过多，新人需要关注配置文件命名规范、xml 配置文件命名空间 等。

为了解决解决上述的问题，Spring Boot 遵循约定大于配置的开发原则，大大简化的 Spring 的配置。首先进行自动化配置，只要引入相关依赖就会自动进行一些默认的配置，其次如果默认的配置不满足要求还可以自定义配置覆盖默认的配置，大大降低了 Spring 应用上手的门槛。

将上述示例改造成基于 Spring Boot 的 Spring MVC 项目，首先看下 pom 文件内容。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>2.2.7.RELEASE</version>
    </parent>

    <groupId>com.zzuhkp</groupId>
    <artifactId>mvc-demo</artifactId>
    <version>1.0-SNAPSHOT</version>
    <packaging>jar</packaging>

    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <maven.compiler.source>1.8</maven.compiler.source>
        <maven.compiler.target>1.8</maven.compiler.target>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.apache.tomcat.embed</groupId>
            <artifactId>tomcat-embed-jasper</artifactId>
        </dependency>
    </dependencies>

</project>
```

和上述基于 Spring Framwork 的 pom 文件相比，主要有4处不同。

- 引入了一个名为 spring-boot-starter-parent 的 parent，这是 Spring Boot 为简化 pom 文件配置提供的一个模块，内部管理了很多依赖，我们的 pom 继承这个 parent 之后很多依赖就可以省略版本号，如下面的 spring-boot-starter-web。
- 打包方式由 `war` 改成` jar`，Spring Boot 可内嵌 Servlet 容器，可直接使用 jar 包启动，因此无需打包为 war 再部署。
- 引入了 `spring-boot-starter-web` 依赖，这个依赖被称为 starter，`spring-boot-starter` 会引入一些本模块相关的依赖和自动化配置，`spring-boot-starter-web` 就内嵌了 Tomcat，并自动进行 Spring MVC 的配置，如` DispatcherServlet`。
- 引入了 `tomcat-embed-jasper` 依赖，这个依赖的作用在于支持内嵌 Tomcat 解析 jsp。
  Spring Boot 项目由于使用 jar 包启动，因此需要提供一个主类，我们定义的主类如下。

`jar`和`war`的区别:

> These files are simply zipped files using the java jar tool. These files are created for different purposes. Here is the description of these files:
>
> - **.jar files:** The .jar files **contain libraries, resources and accessories files** like property files.
> - **.war files:** The war file **contains the web application** that can be deployed on any servlet/jsp container. The .war file **contains jsp, html, javascript** and other files necessary for the development of web applications. https://stackoverflow.com/a/5871102/16317008

Spring Boot 项目由于使用 jar 包启动，因此需要提供一个主类，我们定义的主类如下:

```java
@SpringBootApplication
public class MvcApplication {

    public static void main(String[] args) {
        SpringApplication.run(MvcApplication.class, args);
    }

}
```

`@SpringBootApplication` 注解主要用于开启自动化配置，`main` 方法则用于启动 Spring 容器。至此一个 Spring Boot 项目其实已经搭建完成了，不再需要进行繁杂的 `web.xml` 配置及 Spring 配置。

虽然引入 `spring-boot-starter-web `之后自动进行了 Web 开发相关的配置，不过由于我们需要自定义 InternalResourceViewResolver 的使用的视图前缀和后缀，我们还需要进一步的配置。Spring Boot 支持将相关配置直接添加到` /application.properties`，看下我们的配置内容。

```properties
spring.mvc.view.prefix=/WEB-INF/page
spring.mvc.view.suffix=.jsp
```

注意, 我们配置数据库连接也是在`SpringDemo/src/mian/resources/application.properties`文件

```properties
spring.datasource.url=jdbc:mysql://${MYSQL_HOST:localhost}:3306/greenhouse
spring.datasource.username=root
spring.datasource.password=778899
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver
```

是不是很简单，JSP 文件和 Controller 未做变动，仍使用前面示例的代码。看下现在的项目结构:

```java
.
├── pom.xml
└── src
    └── main
        ├── java
        │   └── com
        │       └── zzuhkp
        │           └── mvc
        │               ├── HelloController.java
        │               └── MvcApplication.java
        ├── resources
        │   └── application.properties
        └── webapp
            └── WEB-INF
                └── page
                    └── hello.jsp
```

总结 Spring Boot 简化应用创建的方式为：使用 `spring-boot-starter-parent` 管理依赖版本、使用 `spring-boot-starter` 自动化配置、支持用户自定义配置覆盖默认配置。

原文: https://blog.csdn.net/zzuhkp/article/details/123518033

# Spring Boot 是如何简化应用开发的？

Spring Boot 自动化配置不仅作用于用于应用创建，减少配置就是减少开发工作量，因此对开发效率的提升也有一定帮助。除此之外，Spring Boot 还提供了一个模块 `spring-boot-devtools` 用于支持 Spring Boot 项目开发时的**热部署**，可以通过如下的方式进行引入。

```xml
<dependency>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-devtools</artifactId>
	<scope>runtime</scope>
	<optional>true</optional>
</dependency>
```

引入这个依赖后，当我们的类发生变化，Spring Boot 会自动进行重启，当然了这个重启不是完整的重启，因此速度上会快上不少。

原文: https://blog.csdn.net/zzuhkp/article/details/123518033

# Spring Boot 是如何简化应用运行的？

对于应用运行的简化，主要提现在内嵌 Servlet 容器，能够将我们的应用自动打成 jar 包启动。上面的示例是我们在 IDE 中运行的，为了打成 jar 包，我们需要引入一个 Spring Boot 专有的插件。

```xml
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
```

这个插件可以将 Spring Boot 项目依赖的所有 jar 包打包到一个 jar 包中，这个 jar 也被称为 `fat jar`。

原文: https://blog.csdn.net/zzuhkp/article/details/123518033

# 总结

Spring 官网将 Spring Boot 的核心特性总结为 6 点，在我们上述的例子中也基本有体现：

- 创建独立的 Spring 应用程序。
- 内嵌 Tomcat、Jetty 或 Undertow （无需部署 war 文件)。
- 提供 starter 简化配置。
- 尽量进行 Spring 和第三方库的自动化配置。
- 提供生产就绪功能，例如指标、健康检查和外部化配置。
- 完全无需代码生成，无需 XML 配置。

原文: https://blog.csdn.net/zzuhkp/article/details/123518033