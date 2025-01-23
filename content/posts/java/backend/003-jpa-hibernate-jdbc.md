---
title: ORM vs JPA vs Hibernate & JDBC vs MySQL Driver, Spring学习(三)
date: 2023-07-30 16:55:47
categories:
 - Java
 - Backend
tags:
 - Java
 - Database
---

## 1. ORM

Object-Relational Mapping (ORM) is a technique that lets you query and manipulate data from a database using an object-oriented paradigm. 

When most people say “ORM” they are referring to the **library** that implements this technique. 

Whichever ORM library you choose, they all use the same principles. There are a lot of ORM libraries around here:

- Java: [Hibernate](https://en.wikipedia.org/wiki/Hibernate_(framework)).
- PHP: Propel or Doctrine (I prefer the last one).
- Python: the Django ORM or SQLAlchemy (My favorite ORM library ever).
- C#: NHibernate or Entity Framework

至于Library和Framework, 知道各自的一个例子就行了, 比如JQuery就是Library(就实现了一些功能封装成代码让你用), 而Spring就属于框架, 至于 Spring 到底是什么, 我也刚开始学, 没有搞明白呢, 

> 注意: JPA 是一套规范，不是一套产品，那么像 Hibernate, TopLink, JDO 他们是一套产品，如果说这些产品实现了这个 Jpa 规范，那么我们就可以叫他们为 Jpa 的实现产品。[原文](http://www.ityouknow.com/springboot/2016/08/20/spring-boot-jpa.html)
> 

## 2. JDBC vs MySQL Connector

JDBC stands for Java Database Connectivity: [Java JDBC API](https://docs.oracle.com/javase/8/docs/technotes/guides/jdbc/)

Sometimes, I always mistake MySQL driver for JDBC, a little funny, Lol. JDBC is part of JDK, which is java's standard library, like code below`java.sql.*` belongs to **Java SE API**, which is also called **JDBC API**. 

So what is MySQL driver, like `com.mysql.cj.jdbc.Driver` which we often add dependency to our maven project. Actually `com.mysql.cj.jdbc.Driver` is **MySQL Connector**, and we don't use any of its code in our program, we just need to tell JDBC that which driver we use (`Class.forName("com.mysql.cj.jdbc.Driver");` ), and the `query` and `insert` statements are all executed by JDBC API (JDBC will commucate with mysql database with **MySQL Connector**, namely, mysql-jdbc-driver), 

After look at these codes below, you will understand,

`Database.java`:

```java
package database;
import java.sql.Connection;
import java.sql.SQLException;

public interface Database {
    public Connection connect() throws SQLException;
}
```

`MysqlDatabase.java`:
```java
package database;

// java.sql.* 属于 Java SE API, 这就是 JDBC API
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class MysqlDatabase implements Database{
    private final String url, user, password;

    public MysqlDatabase(String url, String user, String password) {
        this.url = url;
        this.user = user;
        this.password = password;
    }

    @Override
    public Connection connect() throws SQLException {
        try {
            // You must load jdbc driver, otherwise you will get null for connection.
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            // Instead of printing error simply, you should do some logging here
            System.err.println("Cannot find sql drive: com.mysql.jdbc.Driver");
            return null;
        }
        return DriverManager.getConnection(this.url, this.user, this.password);
    }
}
```

`GetTemperatureServlet.java`

```java
...
    public Connection getConnection() {
        Database database = new MysqlDatabase("jdbc:mysql://localhost:3306/greenhouse", "root", "778899");
        Controller controller = new Controller(database);
        Connection conn = null;
        try {
            conn = controller.getConnection();
        } catch (SQLException e) {
            logger.error(e.getMessage());
        }
        return conn;
    }

    public JsonArray getData(String sql, HttpServletResponse response) throws IOException {
        ResultSet resultSet = null;
        PreparedStatement statement = null;
        ArrayList<DataEntity> results = new ArrayList<>();
        Connection conn = getConnection();

        try {
            statement = conn.prepareStatement(sql);
            resultSet = statement.executeQuery();
            while (resultSet.next()) {
                results.add(new DataEntity(resultSet.getDouble(1), resultSet.getDate(2).toString()));
            }
        } catch (SQLException e) {
            ...
        }

        Gson gson = new Gson();
        JsonElement jsonElement = gson.toJsonTree(results, new TypeToken<ArrayList<DataEntity>>(){}.getType());
        ...
    }

```

As code above, `ResultSet`, `PreparedStatement` and `Connection` they are all belong to `java.sql.*` which is part of **java se api**, namely, **JDBC**. So now you know that we don't commucate with MySQL database with **MySQL Connector** directly, actually, we conmmucate with MySQL(retrive & insert data) with JDBC API(`java.sql.*`) and JDBC API commucate with **MySQL Connector**, and MySQL COnnector commucate with MySQL database. 

- [MySQL :: MySQL Connectors](https://www.mysql.com/products/connector/)

- [Overview (Java Platform SE 8 )](https://docs.oracle.com/javase/8/docs/api/)

![](/003-jpa-hibernate-jdbc/a.png)

![1](/003-jpa-hibernate-jdbc/1.png)

## 3. JPA vs Hibernate

- JPA (Java Persistence API) is a standard for ORM (Object Relational Mapping)
- Hibernate is a JPA provider 
- JDBC (Java Database Connectivity ) API belongs to Java SE API

We have known what is JDBC in the paragraph above, let's look at what is JPA. 

JPA is a standard for Object Relational Mapping (ORM). This is a technology which allows you to map between **objects** in code and **database tables**. This can **hide** the SQL from the developer so that all they deal with are Java classes, and the provider allows you to save them and load them magically. Mostly, XML mapping files or annotations on getters and setters can be used to tell the JPA provider which fields on your object map to which fields in the DB. The most famous JPA provider is [Hibernate](https://hibernate.org/), so it's a good place to start for concrete examples. 

所以JPA只是个Java的ORM标准, 而Hibernate实现了JPA, 

> Under the hood, Hibernate and most other providers for JPA write SQL and use JDBC API to read and write from and to the DB. Simply think, JPA is a Java ORM, and Hibernate implements JPA using JDBC API, 

参考:

- [java - JPA or JDBC, how are they different? - Stack Overflow](https://stackoverflow.com/questions/11881548/jpa-or-jdbc-how-are-they-different)