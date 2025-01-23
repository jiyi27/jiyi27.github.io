---
title: Spring Boot之何为内嵌Tomcat
date: 2023-04-28 15:02:55
categories:
 - Java
 - Backend
tags:
 - Java
 - Spring Boot
---

一直听说Spring Boot内嵌了Tomcat, 然后Spring Boot默认把应用打包为Jar, 这到底意味着什么呢, 为啥不直接用War包部署到外部服务器呢(外部的Tomcat)?  不了解War可以看看我的其它[War相关的文章](https://davidzhu.xyz/2023/04/27/Java/Backend/War/)或者站内搜War等关键字. 

在StackOverflow上看到一个[关于什么是内嵌Tomcat回答](https://stackoverflow.com/a/23176765/16317008), 看看咋说的

"Embedded" means that you program **ships with** the server within it as opposed to a web application being deployed to external server. With embedded server your application is packaged with the server of choice and responsible for server start-up and management.

From the user standpoint the difference is:

- Application with embedded server looks like a regular java program. You just launch it and that's it.
- Regular web application is usually a `war` archive which needs to be deployed to some server

Embedding a server is very useful for testing purposes where you can start or stop server at will during the test.

现在貌似懂点了, 就是Tomcat被被集成到了我们的项目里呗(Tomcat本质也就是个实现了Servlet和JSP标准的程序), 那我们去看看我们打包好的Spring Boot项目(一个Jar文件)里是不是有Tomcat, 

```shell
$ pwd
Downloads/SpringDemo-0.0.1-SNAPSHOT/BOOT-INF/lib/

$ ls | grep tomcat
tomcat-embed-core-10.1.7.jar
tomcat-embed-el-10.1.7.jar
tomcat-embed-websocket-10.1.7.jar
```

好家伙, 果然在里面, 

----

然后又看到一篇文章, 说的很清晰, 这里粘贴部分, 分享一下, 

Think about what you would need to be able to deploy your application (typically) on a virtual machine.

- Step 1 : Install Java
- Step 2 : Install the Web/Application Server (Tomcat/Websphere/Weblogic etc)
- Step 3 : Deploy the application war

What if we want to simplify this?

How about making the server a part of the application?

You would just need a virtual machine with Java installed and you would be able to directly deploy the application on the virtual machine. Isn’t it cool?

This idea is the genesis for Embedded Servers. When we create an application deployable, we would embed the server (for example, tomcat) inside the deployable.

For example, for a Spring Boot Application, you can generate an application jar which contains Embedded Tomcat. **You can run a web application as a normal Java application**! 

Embedded server implies that our deployable unit contains the binaries for the server (example, tomcat.jar). 这也就是我们上面看到的那几个文件`tomcat-embed-core-10.1.7.jar`等, 了解更多[Spring Boot and Embedded Servers - Tomcat](https://www.springboottutorial.com/spring-boot-with-embedded-servers-tomcat-jetty)

打开项目`pom.xml`可以看到依赖里并没tomcat相关的东西, 但是我们项目里却有tomcat那几个jar包, 这是为啥哩, 其实是因为下面的`spring-boot-starter-web`依赖tomcat, 自动为我们添加类似`spring-boot-starter-tomcat`这种了, 

```xml
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
```

看一下别人怎么说, 

The single spring-boot-starter-web dependency can pull in all dependencies related to web development. It also reduces the count of build dependency. The spring-boot-starter-web mainly depends on the following:

```
- org.springframework.boot:spring-boot-starter
- org.springframework.boot:spring-boot-starter-tomcat
- org.springframework.boot:spring-boot-starter-validation
- com.fasterxml.jackson.core:jackson-databind
- org.springframework:spring-web
- org.springframework:spring-webmvc
```

By default, the `spring-boot-starter-web` contains the below tomcat server dependency given:

```xml
<dependency>
<groupId>org.springframework.boot</groupId>
<artifactId>spring-boot-starter-tomcat</artifactId>
<version>2.0.0.RELEASE</version>
<scope>compile</scope>
</dependency>
```

The `spring-boot-starter-web` auto-configures the below things required for the web development:

- Dispatcher Servlet
- Error Page
- Embedded servlet container
- Web JARs for managing the static dependencies

[Difference Between Spring Boot Starter Web and Spring Boot Starter Tomcat - GeeksforGeeks](https://www.geeksforgeeks.org/difference-between-spring-boot-starter-web-and-spring-boot-starter-tomcat/)

----

说了那么多, 既然是生成的项目jar包内嵌服务器, 也就是说我们只要安装了Java(比如Java8以上), 那我们就可以运行我们的Spring Boot项目了, 不用额外安装Tomcat了, 

首先得先打包我们的项目吧, 在Spring Boot根目录运行`mvn clean install`

然后报错 (不出一点岔子就不正常了, 写代码嘛), 

```xml
[ERROR] Failed to execute goal org.springframework.boot:spring-boot-maven-plugin:2.3.5.RELEASE:repackage (repackage) on project SpringDemo: Execution repackage of goal org.springframework.boot:spring-boot-maven-plugin:2.3.5.RELEASE:repackage failed: Unsupported class file major version 61 -> [Help 1]
```

然后仔细看了一下发现上面说`org.springframework.boot:spring-boot-maven-plugin:2.3.5.RELEASE:repackage failed`, 好熟悉, 好像是之前刚开始初始化Spring Boot项目的时候IDEA提示`pom.xml`有错误(出现曲线下划线那种错, 不是运行报错), 出去强迫症想解决它,然后在StackOverflow在哪查到添加上版本信息就不会提示错误了, 于是我加了一行`<version>2.3.5.RELEASE</version>`,  如下:

```xml
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <version>2.3.5.RELEASE</version>
            </plugin>
        </plugins>
    </build>
```

加了版本信息后确实那个红色曲线消失, 也没影响我程序的正常运行(即在IDEA点击运行按钮那个斜三角按钮), 但是使用命令行`mvn clean install`就出现了刚刚的错误, 所以我把版本信息去掉了然后更新`pom.xml`, 然后`mvn clean install`正常运行, 

```xml
.....
[INFO] Installing /Users/David/Codes/IDEA/SpringDemo/target/SpringDemo-0.0.1-SNAPSHOT.jar to /Users/David/.m2/repository/com/choo/SpringDemo/0.0.1-SNAPSHOT/SpringDemo-0.0.1-SNAPSHOT.jar
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  4.091 s
[INFO] Finished at: 2023-04-29T16:22:17-03:00
[INFO] ------------------------------------------------------------------------
```

注意上面jar包输出路径, 然后进入到生成的jar包的路径里, 运行jar包(运行之前确保你的数据库服务已经正确开启, 可以正常连接, 如你使用了MySQL服务), 

```shell
java -jar SpringDemo-0.0.1-SNAPSHOT.jar
```

取决于你项目的REST API怎么设计的, 然后去浏览器访问`http://localhost:8080/find/temperature?from=2023-04-01&to=2023-04-02`, 得到如下数据, 访问成功:

```json
[{"id":1,"value":27.5,"createdDate":"2023-04-01T14:54:26"},{"id":2,"value":28.5,"createdDate":"2023-04-01T20:42:50"},{"id":3,"value":20.6,"createdDate":"2023-04-02T11:09:26"},{"id":4,"value":30.6,"createdDate":"2023-04-02T15:32:39"}]
```

你也可以使用`wget`发送`GET`请求, 

```xml
wget "http://localhost:8080/find/temperature?from=2023-04-01&to=2023-04-02"
```

总结下, 这次讨论我们理解了Jar是什么, 也知道了什么是所谓的内嵌Tomcat, 可以看到运行Jar包并不是像[之前讨论War](https://davidzhu.xyz/2023/04/27/Java/Backend/War/)那样, 还得把War部署到Tomcat的`webapps`目录下, 然后启动Tomcat, 再去访问对应url, 我们直接一个`java -jar`便可以运行我们的Java Web项目, 可谓是很方便, 但是需要注意如果你的应用用到了数据库, 那你仍需要在你执行该应用的机器上开启对应的数据库服务以及创建对应的表, 这跟tomcat没关系, SpringBoot只是内嵌了Tomcat并不是内嵌了你的数据库啥的, 

然后我们也就知道别人所说的那种, Spring Boot内嵌Tomcat, 然后默认项目打包成Jar而不是War到底是个什么玩意, 即就是把所有依赖和所有我们编写的源代码的字节码`.class`文件通过约定好的目录结构放到一起, 然后打包成一个jar, 上面说到的依赖比如`pom.xml`中的各种依赖以jar文件格式放到`SpringDemo-0.0.1-SNAPSHOT/BOOT-INF/lib`目录下, 然后`.class`文件都在`SpringDemo-0.0.1-SNAPSHOT/BOOT-INF/classes`下, 当然可能还包含其他的文件, 这你自己去探索吧, 

最后看一下项目生成的Jar的结构(依赖太多了, 删除了一部分):

```java
.
├── BOOT-INF
│   ├── classes
│   │   ├── application.properties
│   │   ├── com
│   │   │   └── choo
│   │   │       └── springdemo
│   │   │           ├── SpringDemoApplication.class
│   │   │           ├── Temperature.class
│   │   │           └── TemperatureRepository.class
│   │   └── static
│   │       └── index.html
│   ├── classpath.idx
│   ├── layers.idx
│   └── lib
│       ├── HikariCP-5.0.1.jar
│       ├── angus-activation-2.0.0.jar
│       ├── antlr4-runtime-4.10.1.jar
│       ├── spring-jcl-6.0.7.jar
│       ├── spring-jdbc-6.0.7.jar
│       ├── spring-orm-6.0.7.jar
│       ├── spring-tx-6.0.7.jar
│       ├── spring-web-6.0.7.jar
│       ├── spring-webmvc-6.0.7.jar
│       ├── tomcat-embed-core-10.1.7.jar
│       ├── tomcat-embed-el-10.1.7.jar
│       ├── tomcat-embed-websocket-10.1.7.jar
```

其实有时候对于一些概念区别, 读很多文章博客不如去自己实操一遍, 读多了可能觉得自己会了理解了, 但还是会云里雾里, 因为有的说的很泛, 总之别嫌麻烦, 多动手, 
