---
title: Maven的相关概念与常用指令 Spring学习(二)
date: 2023-07-30 14:11:30
categories:
 - Java
 - Backend
tags:
 - Java
 - Spring Boot
---

## 1. Install Maven

**1.Go to Maven [Download site]( https://maven.apache.org/download.cgi)**

![](/002-maven/a.png)

**2.Set Environment Variables**

```shell
tar -xvf apache-maven-3.6.3-bin.tar.gz

export M2_HOME="/Users/shaowen/Downloads/Programs/apache-maven-3.9.1"
PATH="${M2_HOME}/bin:${PATH}"
export PATH

source .bash_profile
mvn -version
```

## 2. Maven Artifact 

> In Maven terminology, the artifact is the resulting output of the maven build, generally a `jar` or `war` or other executable file. Artifacts in maven are identified by a coordinate system of groupId, artifactId, and version. Maven uses the `groupId`, `artifactId`, and `version` to identify dependencies (usually other jar files) needed to build and run your code. - https://stackoverflow.com/a/2487510/16317008

> An artifact is a file, usually a JAR, that gets deployed to a Maven repository. 
>
> A Maven build produces one or more artifacts, such as a compiled JAR and a "sources" JAR.
>
> Each artifact has a group ID (usually a reversed domain name, like com.example.foo), an artifact ID (just a name), and a version string. The three together uniquely identify the artifact.
>
> A project's dependencies are specified as artifacts. - https://stackoverflow.com/a/2487511/16317008

之前写的关于如何发布 war 到 tomcat 服务器的文章, 用的就是 maven build war, 当然 maven 也可以把我们的项目 build 成 jar 文件, 所以 artifact 在 maven 中的意思就是 maven 的输出, maven 所build的文件, 我们的 spring boot 项目也是一个 artifact, 与其说 spring boot 项目不如说是 maven 项目, 因为如过我们不用 gradle 的话, 那每个spring boot 项目的根目录下都会有一个 `pom.xml` 文件, 在其开头你可以看到 groupid, artifactid等标签,这不就是标注一个 artifact 的标签吗, 然后`pom.xml` 中的dependency标签里的依赖就是一个个的 maven artifacts, 这其实就是第三方把她们的maven项目打包成jar供我们使用, 我们只用添加依赖就好, 至于这些依赖(artifacts)下载安装后都保存在了 Maven repository,  具体把maven 项目build 成 war/jar package可参考:

- [手动部署War包到Tomcat上之何为War](https://davidzhu.xyz/2023/04/27/Java/Backend/War/)
- [创建第一个Spring Boot项目及注意事项](https://davidzhu.xyz/2023/07/29/Java/Backend/1-first-spring-boot-program/)

## 3. Maven Repository

Maven Repository有3种类型: 

1. Local Repository
2. Central Repository
3. Remote Repository

Maven Local Repository 是本机中的一个目录, 如果目录不存在, 执行maven时就会先创建它, 默认情况下, maven本地存储库是`%USER_HOME%/.m2` , 我们可以在maven配置文件查看local repository, 位置在 maven 安装路径下, `MAVEN_HOME/conf/settings`:

![1](/002-maven/1.png)

查看 `.m2` 的内容, 

```shell
$ ls ~/.m2/repository/
antlr                    commons-codec            junit
aopalliance              commons-collections      log4j
logkit									 mysql ....

$ ls .m2/repository/log4j/log4j/1.2.12 
_remote.repositories  log4j-1.2.12.jar.sha1 log4j-1.2.12.pom.sha1
log4j-1.2.12.jar      log4j-1.2.12.pom
```

阅读更多: [ Maven-Repository存储库 ](https://www.cnblogs.com/jhno1/p/15134027.html)

## 4. Artifact & Group 

创建好maven项目后, 在项目根目录下有个`pom.xml`文件, 这个就是maven的配置文件, 你可以在里面添加各种依赖, 比如想用mysql driver, gson, log4j等第三方库的时候, 直接在dependencies标签下添加:

```xml
<dependency>
    <groupId>mysql</groupId>
    <artifactId>mysql-connector-java</artifactId>
    <version>8.0.32</version>
</dependency>
```

那么问题来了, 上面dependence标签下的artifactId和groupId是什么呢? 仔细观察`pom.xml`内容你会发现, 在其开头也是这些奇怪的标签:

```xml
<groupId>com.example</groupId>
<artifactId>ServletDemo</artifactId>
<version>1.0-SNAPSHOT</version>
<name>ServletDemo</name>
<packaging>war</packaging>
```

其中，`groupId`类似于Java的包名，通常是公司或组织名称，`artifactId`类似于Java的类名，通常是项目名称，再加上`version`，一个Maven工程就是由`groupId`，`artifactId`和`version`作为唯一标识, 

在Maven项目中，类的`classpath`路径是由Maven依赖管理机制决定的。Maven通过`pom.xml`管理项目依赖，当我们使用`<dependency>`声明一个依赖后，Maven会根据`pom.xml`文件中的配置将依赖下载到本地仓库，然后将其添加到项目的`classpath`中。

## 5. 查看classpath

Mac, Linux查看当前maven项目的classpath, 注意要在项目的根目录下输入此命令, 不然会提示错误找不到`pom.xml`文件, 
```shell
mvn -q exec:exec -Dexec.executable=echo -Dexec.args="%classpath"
/Users/shaowen/Codes/IDEA/ServletDemo/target/classes:/Users/shaowen/.m2/repository/com/mysql/mysql-connector-j/8.0.32/mysql-connector-j-8.0.32.jar:/Users/shaowen/.m2/repository/log4j/log4j/1.2.17/log4j-1.2.17.jar
```

可以看到, classpath路径的第一个是`/Users/shaowen/Codes/IDEA/ServletDemo/target/classes/`, 这个文件夹下面就是我们project/src/main/java/下的类, 编译成的class文件 都放这下面了. 所以项目就是这么找到我们编写的类的, 

了解更多关于输出classpath: https://stackoverflow.com/a/45043803/16317008

## 6. Common Maven Commands

| Maven Command                                                | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| mvn --version                                                | Prints out the version of Maven you are running.             |
| mvn clean                                                    | Clears the `target` directory into which Maven normally builds your project. |
| mvn package                                                  | Builds the project and packages the resulting JAR file into the `target` directory. |
| mvn package -Dmaven.test.skip=true                           | Builds the project and packages the resulting JAR file into the `target` directory - without running the unit tests during the build. |
| mvn clean package                                            | Clears the `target` directory and Builds the project and packages the resulting JAR file into the `target` directory. |
| mvn clean package -Dmaven.test.skip=true                     | Clears the `target` directory and builds the project and packages the resulting JAR file into the `target` directory - without running the unit tests during the build. |
| mvn verify                                                   | Runs all integration tests found in the project.             |
| mvn clean verify                                             | Cleans the target directory, and runs all integration tests found in the project. |
| mvn install                                                  | Builds the project described by your Maven POM file and installs the resulting artifact (JAR) into your local Maven repository |
| mvn install -Dmaven.test.skip=true                           | Builds the project described by your Maven POM file without running unit tests, and installs the resulting artifact (JAR) into your local Maven repository |
| mvn clean install                                            | Clears the `target` directory and builds the project described by your Maven POM file and installs the resulting artifact (JAR) into your local Maven repository |
| mvn clean install -Dmaven.test.skip=true                     | Clears the `target` directory and builds the project described by your Maven POM file without running unit tests, and installs the resulting artifact (JAR) into your local Maven repository |
| mvn dependency:copy-dependencies                             | Copies dependencies from remote Maven repositories to your local Maven repository. |
| mvn clean dependency:copy-dependencies                       | Cleans project and copies dependencies from remote Maven repositories to your local Maven repository. |
| mvn clean dependency:copy-dependencies package               | Cleans project, copies dependencies from remote Maven repositories to your local Maven repository and packages your project. |
| mvn dependency:tree                                          | Prints out the dependency tree for your project - based on the dependencies configured in the pom.xml file. |
| mvn dependency:tree -Dverbose                                | Prints out the dependency tree for your project - based on the dependencies configured in the pom.xml file. Includes repeated, transitive dependencies. |
| mvn dependency:tree -Dincludes=com.fasterxml.jackson.core    | Prints out the dependencies from your project which depend on the com.fasterxml.jackson.core artifact. |
| mvn dependency:tree -Dverbose -Dincludes=com.fasterxml.jackson.core | Prints out the dependencies from your project which depend on the com.fasterxml.jackson.core artifact. Includes repeated, transitive dependencies. |
| mvn dependency:build-classpath                               | Prints out the classpath needed to run your project (application) based on the dependencies configured in the pom.xml file. |

**注意(1):** `mvn install` 说的是把你的 maven 项目构建成 jar或者war, 然后放到 `.m2/respository/` 下, 而不是下载安装 `pom.xml` 中的依赖到本地仓库, 具体输出:

```shell
[INFO] Building jar: /Users/David/Codes/IDEA/my-app/target/my-app-0.0.1-SNAPSHOT.jar
[INFO] 
[INFO] --- spring-boot:3.1.2:repackage (repackage) @ my-app ---
[INFO] Replacing main artifact /Users/David/Codes/IDEA/my-app/target/my-app-0.0.1-SNAPSHOT.jar with repackaged archive, adding nested dependencies in BOOT-INF/.
[INFO] 
[INFO] --- install:3.1.1:install (default-install) @ my-app ---
[INFO] Installing /Users/David/Codes/IDEA/my-app/target/my-app-0.0.1-SNAPSHOT.jar to /Users/David/.m2/repository/com/example/my-app/0.0.1-SNAPSHOT/my-app-0.0.1-SNAPSHOT.jar
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  2.483 s
[INFO] Finished at: 2023-07-30T13:56:58-03:00
[INFO] ------------------------------------------------------------------------
```

**注意(2):**

> Keep in mind, that when you execute the `clean` goal of Maven, the `target` directory is removed, meaning you lose all compiled classes from previous builds. That means, that Maven will have to build all of your project again from scratch, rather than being able to just compile the classes that were changed since last build. This slows your build time down. However, sometimes it can be nice to have a clean, fresh build, e.g. before releasing your product to the world - mostly for your own "feeling" of knowing everything was built from scratch and working. - [Maven Commands](https://jenkov.com/tutorials/maven/maven-commands.html)

## 7. Executing Build Life Cycles, Phases and Goals

When you run the `mvn` command you pass one or more arguments to it. These arguments specify either a build life cycle, build phase or build goal. For instance to execute the `clean` build life cycle you execute this command:

```
mvn clean
```

To execute the `site` build life cycle you execute this command:

```
mvn site
```

### 7.1. Executing the Default Life Cycle

The `default` life cycle is the build life cycle which generates, compiles, packages etc. your source code.

You cannot execute the `default` build life cycle directly, as is possible with the `clean` and `site`. Instead you have to execute a specific build phase within the `default` build life cycle.

The most commonly used build phases in the `default` build life cycle are:

| Build Phase | Description                                                  |
| ----------- | ------------------------------------------------------------ |
| `validate`  | Validates that the project is correct and all necessary information is available. This also makes sure the dependencies are downloaded. |
| `compile`   | Compiles the source code of the project.                     |
| `test`      | Runs the tests against the compiled source code using a suitable unit testing framework. These tests should not require the code be packaged or deployed. |
| `package`   | Packs the compiled code in its distributable format, such as a JAR. |
| `install`   | Install the package into the local repository, for use as a dependency in other projects locally. |
| `deploy`    | Copies the final package to the remote repository for sharing with other developers and projects. |

Executing one of these build phases is done by simply adding the build phase after the `mvn` command, like this:

```
mvn compile
```

This example Maven command executes the `compile` build phase of the `default` build life cycle. This Maven command also executes all earlier build phases in the `default` build life cycle, meaning the `validate` build phase.

### 7.2. Executing Build Phases

You can execute a build phase located inside a build life cycle by passing the name of the build phase to the Maven command. Here are a few build phase command examples:

```
mvn pre-clean
mvn compile
mvn package
```

Maven will find out what build life cycle the specified build phase belongs to, so you don't need to explicitly specify which build life cyle the build phase belongs to.

本节来自: [Maven Commands](https://jenkov.com/tutorials/maven/maven-commands.html)
