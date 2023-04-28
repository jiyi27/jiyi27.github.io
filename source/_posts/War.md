---
title: 手动部署War包到Tomcat上之何为War
date: 2023-04-27 21:30:48
categories:
 - Java
 - Backend
tags:
 - Java
 - Tomcat
 - War Files
---

**Web application resources or web application archives are commonly called WAR files.** A WAR file is used to deploy a Java EE web application in an application server. Inside a WAR file, all the web components are packed into one single unit. These include **JAR files**, **JavaServer Pages**, **Java servlets**, Java class files, XML files, HTML files, and other resource files that we need for web applications. 

[Maven](https://www.baeldung.com/maven) is a popular build management tool that is widely used in Java EE projects to handle build tasks like compilation, packaging, and artifact management. We can **use the Maven WAR plugin to build the project as a [WAR](https://www.baeldung.com/java-jar-war-packaging#war) file**. [Generate a WAR File in Maven | Baeldung](https://www.baeldung.com/maven-generate-war-file)

# Step 1: Add a new user with deployment rights to Tomcat

To perform a Maven Tomcat deploy of a `WAR` file you must first set up a **user** in Tomcat with the appropriate rights. You can do this with an edit of the `tomcat-users.xml` file, which can be found in Tomcat's `conf` sub-directory. Add the following entry **inside** the `tomcat-users` tag:

```xml
<user username="war-deployer" password="maven-tomcat-plugin" roles="manager-gui, manager-script, manager-jmx" />
```

Save the tomcat-users.xml file and restart the server to have the changes take effect.

重启Tomcat就是进到Tomcat的`bin`目录下, 执行`startup.sh`, `./shutdown.sh`, 其实你直接使用`startup.sh`命令开启Tomcat服务就会加载配置文件了, 上面说的重启是默认你的Tomcat一直处于运行状态. 现在你也应该启动Tomcat服务了, 启动后尝试访问`http://localhost:8080/`, 看看能不能正确访问Tomcat主页, 我在这一步就出现了问题, 访问的总是我以前的JSP应用, 我用IDEA开发的, 但我都没打开IDEA, 仍然可以访问到, 真是奇了怪了, 如下:

![](a.png)

然后我就[查到了一个博客](https://www.cnblogs.com/yayazi/p/7920257.html)说需要将Tomcat的首页的工程部署到Tomcat服务器上，部署步骤如下：

选择菜单栏“Run-->Edit Configuration...-->Deployment”, 选择右上角绿色“+”，选择“External Source...”，将Apache-tomcat的`webapps`目录下的ROOT文件夹选中，点击OK，及完成Tomcat的首页的工程的部署。选择ROOT文件后右侧Application Context 不填写。然后删除多余的`ROOT`下面的那个`ServletDemo:war exploded`, 如下图:

![](b.png)

然后我的还有个问题, 就是我IDEA上选择的Tomcat服务器不是我现在用的, 就是说我有个旧的Tomcat服务器, 我不知道, 然后IDEA用的一直是那个旧的(但我在上面部署位置的`ROOT`文件夹选择的是新的Tomcat下的文件), 所以就导致就算部署项目后, 我依然无法访问Tomcat的主页. 所以检查一下你是否选择了正确的Tomcat服务器, 

![](c.png)

这样配置好后再在IDEA点击运行, 就可以访问到Tomcat的主页了, 之后你关闭IDEA, 就可以直接进入Tomcat根目录的`bin`下通过执行`startup.sh`来启动Tomcat. 

有时候你会遇到其他情况, 比如8080端口被占用, 这时候解决办法也很简单

```shell
# 查看PID
lsof -n -i4TCP:8080 
# 删除8080端口对应的PID
kill -9 PID
```

说了那么多终于要进行下一步了, 

# Step 2: Tell Maven about the Tomcat deploy user

After you add the `war-deployer` user to Tomcat, register that `username` and `password` in Maven, along with a named reference to the server. The Maven-Tomcat plugin will use this information when it tries to [connect to the application server](https://www.theserverside.com/feature/Is-Apache-Tomcat-the-right-Java-application-server-for-you). Edit the `settings.xml` file and add the following entry **within** the `<server>` tag to create the named reference to the server:

```xml
<!-- Configure the Tomcat Maven plugin user -->
<server>
  <id>maven-tomcat-war-deployment-server></id>
  <username>war-deployer</username>
  <password>maven-tomcat-plugin</password>
</server>
```

> 注意, 上面提到的`settings.xml`文件在`Downloads/apache-maven-3.9.1/conf`下, 根据你的maven安装目录查找, 

另外这里加的账号密码就是上面在Tomcat添加用户时候的账号密码, 这是因为你进入Tomcat管理页面的时候需要,如果你不提供(下面配置`pom.xml`也会说到), 那生成war文件的时候maven就会报错, 

![](d.png)

点击后输入上面的`username`和对应的`password`, 即可进入管理页面如下:

![](e.png)

# Step 3: Register the tomcat7-maven-plugin in the POM

Now that Maven and Tomcat are configured, the next step is to edit the Java web application's POM file to reference the Tomcat Maven plugin. 

```xml
<plugin>
	<groupId>org.apache.tomcat.maven</groupId>
	<artifactId>tomcat7-maven-plugin</artifactId>
	<version>2.0</version>
	<configuration>
		<url>http://localhost:8080/manager/text</url>
		<path>/rps</path>
	</configuration>
</plugin>
```

运行`mvn install tomcat7:deploy`生成war的时候总是报错(如果你之前已经生成了War文件, 请记得去Tomcat根目录下的`webapp`目录下删除一生成的war文件, 否则也会报错, 和下面一样):

```shell
[ERROR] Failed to execute goal org.apache.tomcat.maven:tomcat7-maven-plugin:2.0:deploy (default-cli) on project ServletDemo: Cannot invoke Tomcat manager: Broken pipe -> [Help 1]
[ERROR] 
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR] 
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MojoExecutionException
```

如下加入上面我们在Tomcat Users里配置的账号密码(修改`pom.xml`后记得更新`pom.xml`), 如下: 

```xml
<plugin>
	<groupId>org.apache.tomcat.maven</groupId>
	<artifactId>tomcat7-maven-plugin</artifactId>
	<version>2.0</version>
	<configuration>
		<url>http://localhost:8080/manager/text</url>
		<path>/rps</path>
		<username>war-deployer</username>
		<password>maven-tomcat-plugin</password>
	</configuration>
</plugin>
```

> 提示: 点击IDEA软件的右上角有个浮动的更新小按钮即更新, 或者你可以查查命令行maven怎么更新`pom.xml`文件. 

然后重新运行`mvn install tomcat7:deploy`, 成功:

![](f.png)

然后去Tomcat根目录的`webapps`下查看生成的War, 可以看到生成了名为`rps`的web应用, 即这个名字取决于上面`pom.xml`填的内容, 

![](g.png)

# FInal Step: Verify

确保你已经开启Tomcat服务(即使你关闭了IDEA, IDEA和Tomcat是两个东西, IDEA是个IDE会用到Tomcat作为web服务器来部署web app), 然后访问通过`http://localhost:8080/`访问到Tomcat主页, 这时候你可以在链接🔗后加上`/rps`即`http://localhost:8080/rps/`就可以进入到你的那个web网页, 如下:

![](h.png)

# 思考总结

这时候其实我们也就知道了什么是根目录和url中神秘的路径问题, 你看我们若想访问`manager`页面, 这个页面的url是`http://localhost:8080/manager/`, 我们访问我们刚部署的页面是`http://localhost:8080/rps/`, 你看最后的这个路径及`/manager`, `/rps`都是tomcat的`webapps`目录下的文件, 所以`webapp`就是所谓的根目录, 我们访问什么都是根据它来的, 根据上图我们可以看到, `webapps`目录下还有`examples`等文件夹, 所以我们可以直接通过`http://localhost:8080/example/`访问. 但是又有个问题, Tomcat的主页也就是是`http://localhost:8080/`具体在哪呢? 按理说`webapps`下应该有个`index.html`文件呀, 可是却空空, 这是怎么回事, 怎么没有按我们上面推导的路径来呢?

还记不记得当时学习servlet的时候有个`web.xml`文件, 我们在这个文件里可以配置个welcome标签, 通过这个标签我们就可以直接指定一个html文件作为我们的主页而不是根目录下的`index.tml`文件, 同样, Tomcat当然也有这个文件 `TOMCAT_HOME/conf/web.xml`, 搜索`welcome`找到啦(在`tomcat/webapps/ROOT/index.jsp`):

```xml
  <!-- ==================== Default Welcome File List ===================== -->
  <!-- When a request URI refers to a directory, the default servlet looks  -->
  <!-- for a "welcome file" within that directory and, if present, to the   -->
  <!-- corresponding resource URI for display.                              -->
  <!-- If no welcome files are present, the default servlet either serves a -->
  <!-- directory listing (see default servlet configuration on how to       -->
  <!-- customize) or returns a 404 status, depending on the value of the    -->
  <!-- listings setting.                                                    -->
  <!--                                                                      -->
  <!-- If you define welcome files in your own application's web.xml        -->
  <!-- deployment descriptor, that list *replaces* the list configured      -->
  <!-- here, so be sure to include any of the default values that you wish  -->
  <!-- to use within your application.                                       -->

    <welcome-file-list>
        <welcome-file>index.html</welcome-file>
        <welcome-file>index.htm</welcome-file>
        <welcome-file>index.jsp</welcome-file>
    </welcome-file-list>
```

然后怎么覆盖这个home page呢? 刚好看到了下面这个回答, 看来和我们猜想的一样(真的是后看到的这个回答😭), 如下: 

In any web application, there will be a `web.xml` in the `WEB-INF/` folder. (别忘了我们之前学习JSP的时候可没少在这个文件夹花时间去配置servlet name和对应的jsp, 每创建一个新的servlet就要在这创建个新的servlet pattern)

If you dont have one in your web app, as it seems to be the case in your folder structure, the default **Tomcat** `web.xml` is under `TOMCAT_HOME/conf/web.xml`

Either way, the relevant lines of the web.xml are

```xml
<welcome-file-list>
        <welcome-file>index.html</welcome-file>
        <welcome-file>index.htm</welcome-file>
        <welcome-file>index.jsp</welcome-file>
</welcome-file-list>
```

so any file matching this pattern when found will be shown as the home page.

In Tomcat, a web.xml setting within your web app will override the default, if present.

Further Reading: [How do I override the default home page loaded by Tomcat?](http://wiki.apache.org/tomcat/HowTo#How_do_I_override_the_default_home_page_loaded_by_Tomcat.3F)

参考:

- [Step-by-step Maven Tomcat WAR file deploy example | TheServerSide](https://www.theserverside.com/video/Step-by-step-Maven-Tomcat-WAR-file-deploy-example)
- [tomcat启动成功浏览器却无法访问 - 掘金](https://juejin.cn/post/7133755807253921829)
- [web applications - How does Tomcat find the HOME PAGE of my Web App? - Stack Overflow](https://stackoverflow.com/a/3976385/16317008)

