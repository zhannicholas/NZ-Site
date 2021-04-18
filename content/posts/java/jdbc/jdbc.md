---
date: "2021-04-18T23:00:39+08:00"
title: "JDBC"
authors: ["zhannicholas"]
categories:
  - Java
tags:
  - JDBC
draft: false
toc: true
---

JDBC（Java DataBase Connectivity）是 Java 程序与关系型数据库交互的统一 API，它由两部分 API 组成：

1. 面向 Java 开发者的 Java API，这一部分 API 独立于各个数据库产品的接口规范，是标准又统一的 Java　API。
2. 面向数据库驱动程序开发者的 API，由数据库厂商实现，用于连接具体的数据库产品。

## 使用 JDBC 操作数据库的核心步骤

在实际开发 Java 程序时，我们可以通过 JDBC 连接到数据库，完成各种数据库操作。以下就是执行 SELECT 语句时发生的 JDBC 操作：

1. 注册数据库驱动类，给出数据库连接信息（数据库地址、用户名、密码等）
2. 创建 `Connection` 连接到数据库（调用 `DriverManager.getConnection()` 方法）
3. 创建 `Statement` 对象（调用 `Connection` 的 `createStatement()` 或 `prepareStatement()` 方法）
4. 通过 `Statement` 对象执行 SQL，得到 `ResultSet` 对象（查询结果集）
5. 从 `ResultSet` 中读取数据
6. 关闭 `ResultSet`、`Statement` 及 `Connection` 对象

## 数据库连接池

为什么要使用数据库连接池？数据库连接是整个服务中比较珍贵的资源之一，因为建立数据库连接涉及鉴权、握手等一系列网络操作。使用池化技术缓存数据库连接带来的好处还有很多，例如：

* 实现连接重用，从而提高系统的响应速度
* 控制数据库连接数量上限，防止连接过多造成数据库假死
* 统一连接管理，避免连接泄漏

连接池的连接数量上限一定要根据实际情况仔细选取。如果设置得过大，可能导致数据库因连接过多而假死或崩溃，从而影响服务的可用性。如果设置得过小，则可能无法让数据库达到最佳性能，造成资源浪费。

## ORM 框架

ORM 框架的核心功能是：根据配置（一般是配置文件或者 Java 注解）实现对象模型（Java 程序）与关系模型（数据库）之间的映射。

![对象模型与关系模型的映射](/images/java/jdbc/object-model-and-relation-model.png)

### 常见的 ORM 框架

#### Hibernate

Hibernate 是一个老牌的 ORM 框架，在 Java 生态中久负盛名。它支持多种异构数据的持久化，支持全文搜索（Hibernate Search）和数据校验（validation），还提供了 NoSQL 的解决方案（Hibernate OGM）。

使用 Hibernate ORM 进行 Java 开发时，可以使用映射文件或注解定义 Java 类与数据库表之间的映射关系，使用到的映射关系文件后缀为 `.hbm.xml`。`hbm.xml` 映射文件将数据库表与 Java 对象进行关联，让数据库表中的每一行记录都可以被转换为一个对应的 Java 对象。这样一来，Java 开发者只需要使用面向对象的思维就可完成数据库的设计。

除了完成对象模型与关系模型的双向映射外，Hibernate 还可以帮助我们屏蔽不同数据库之间 SQL 的差异（通过数据库方言实现）。在开发过程中，我们只需要使用 Hibernate 提供的 API 就可以完成数据库操作，并不需要直接编写 SQL 语句，因为 Hibernate 封装了数据库层面的全部操作。Hibernate 提供的 `Criteria` API 是一套面向对象的 API，使用它操作数据库时，我们只需要关注这套 API 本身以及返回的 Java 对象，并不需要考虑数据库底层实现的差异。

除了 `Criteria` API 之外，Hibernate 还提供了一套面向对象的查询语言——HQL（Hibernate Query Language），它的语句结构与 SQL 语句的结构十分类似，二者的本质区别在于：前者是面向对象的，后者是面向关系型数据库的。在使用 HQL 时，也不需要考虑底层数据库的差异，Hibernate 会自动将 HQL 转换为合法的 SQL 语句。

不管是 `Criteria` API，还是 HQL，最终二者都会转化为 SQL，由于 SQL 是生成出来的，所以复杂情况下生成的 SQL 可能会非常难于理解。

Hibernate 默认提供了一级缓存（默认开启）和二级缓存（需要配置开启），支持延迟加载，可以避免无效查询。

不过，Hibernate 无法在面向对象模型中找到数据库中所有概念的映射，例如索引、函数、存储过程等。

### JPA

JPA（Java Persistence API） 是 JDK5.0 后提出的 Java 持久化规范，目的在于整合市面上已有的 ORM 框架。JPA 本身只是一个规范，没有提供具体的实现，Hibernate、OpenJPA、EclipseLink 等都是 JPA 规范的具体实现。JPA 由三个核心部分组成：ORM 映射元数据、操作实体对象的 API 和面向对象的查询语言 JPQL，三者的作用和 Hibernate 中的 `hbm.xml`、`Criteria` API 和 HQL 非常类似。

虽然很多 ORM 框架都实现了 JPA 规范，但是它们各自在 JPA 的基础上又有所修改，这就导致我们在使用 JPA 的时候，无法进行底层 ORM 框架的无缝切换，但是 Spring Data JPA 可以帮我们实现无缝切换。

### MyBatis

另一个流行的 ORM 框架是 MyBatis，它的一个重要功能是帮助 Java 开发者封装重复性的 JDBC 代码——通过 `Mapper` 映射配置文件及相关注解，将 `ResultSet` 结果映射为 Java 对象。很多人将 Hibernate 与 Mybatis 进行比较，认为前者是一个全自动的 ORM 框架，后者是一个半自动的 ORM 框架。Mybatis 并没有实现 JPA，但是相对 Hibernate 以及各类 JPA 框架的实现来说，它更加灵活、轻量级和可控。

此外，Mybatis 还提供了一个非常强大的功能——动态 SQL。这一特性可以帮助我们更好地处理可能动态变化的复杂查询条件，减少出错率。

### 实际工作中对持久层框架的选择

从性能角度来看，Hibernate、Spring Data JPA 对 SQL 语句的掌握、SQL 手工调优、多表连接查询等方面不如 MyBatis 直接使用原生 SQL 语句那么方便、高效。

从可移植性角度来看，Hibernate 帮助我们屏蔽了底层数据库方言的差异，Spring Data JPA 帮助我们屏蔽了 ORM 的差异，而 MyBatis 由于直接手工编写原生 SQL，会与具体的数据库完全绑定。

从开发效率来看，Hibernate、Spring Data JPA 处理中小型项目的效率略高于 MyBatis，但这个主要要看需求和开发者的技术栈。


## 参考资料

1. [Mybatis](https://mybatis.org/mybatis-3/zh/index.html).
2. [Hibernate](https://hibernate.org/).
3. [JDBC 4.2 Specification](https://download.oracle.com/otn-pub/jcp/jdbc-4_2-mrel2-eval-spec/jdbc4.2-fr-spec.pdf).
4. [Spring Data JPA](https://spring.io/projects/spring-data-jpa).