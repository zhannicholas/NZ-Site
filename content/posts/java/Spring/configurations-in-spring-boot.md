---
date: "2021-08-27T20:36:10+08:00"
title: "Spring Boot 中的配置体系"
authors: ["zhannicholas"]
categories:
  - Spring
tags:
  - Spring Boot
draft: false
toc: true
---

开发的同学可能都遇到过一个 Spring Boot 应用要在多个环境上部署，而每个环境的配置都不同的情况。比如，开发环境用一套配置，测试环境用另一套配置，生产环境又是一套新配置。如果我们把配置放在同一个地方，然后每次都根据不同的环境进行修改，可能要不了多久，我们的头就大了。因为，我们可能一不小心把开发环境的配置放到测试环境中去了……

为了方便我们在不同环境中运行应用程序，Spring Boot 允许我们将配置信息[外部化](https://docs.spring.io/spring-boot/docs/current/reference/html/features.html#features.external-config)。Spring Boot 支持多种外部化的配置源，包括 Java 的 properties 文件、YAML 文件、环境变量和命令行参数。

## 配置源

既然配置可以来自很多不同的地方，那么就有可能出现同一个配置项在多个配置源中出现的情况。所以 Spring Boot 有一个配置值覆盖规则，优先级高的配置会覆盖优先级低的，优先级从低到高依次为：

1. 默认属性（即通过 `SpringApplication.setDefaultProperties` 设置的属性）
2. `@Configuration` 类上的 `@PropertySource` 注解
3. 配置数据（比如 `application.properties`）。配置数据文件的优先级如下，当`.properties` 文件与 `.yml` 文件同时出现时，前者的优先级会高于后者：
    1. Jar 包内的 `application.properties` 和 `application.yml`
    2. Jar 包内特定 Profile 的 `application-{profile}.properties` 和 `application-{profile}.yml`
    3. Jar 包外的 `application.properties` 和 `application.yml`
    4. Jar 包外特定 Profile 的 `application-{profile}.properties` 和 `application-{profile}.yml`
4. 由 `RandomValuePropertySource` 配置的 `random.*` 属性值
5. 操作系统环境变量
6. Java 系统属性（`System.getProperties()`）
7. 来自 `java:comp/env` 的 JNDI 属性
8. `ServletContext` 的初始化参数
9. `ServletConfig` 的初始化参数
10. `SPRING_APPLICATION_JSON`（环境变量或系统属性中的单行 JSON） 中的属性值
11. 命令行参数
12. 测试上的 `properties` 属性。在 `@SpringBootTest` 和其它测试相关注解上有用
13. 测试上的 `@TestPropertySource` 注解
14. 当 devtools 激活时，`$HOME/.config/spring-boot` 目录下的 devtools 全局设置属性

### 命令行参数

默认情况下，`SpringApplication` 会将所有以 `--` 开头的命令行参数转换为 `property` 并将它们加入到 Spring 的 `Environment` 中。例如：
```sh
$ java -jar app.jar --name=value
```

如果你不希望 `SpringApplication` 将命令行参数添加到 `Environment`，可以使用 `SpringApplication.setAddCommandLineProperties(false)` 关闭此功能。

### SPRING_APPLICATION_JSON

环境变量和系统属性通常有一些限制，导致部分属性名无法使用。为了解决这个问题，Spring Boot 允许我们将一组属性放到单行 JSON 中。在 Spring Boot 应用启动时，所有的 `spring.application.json` 或 `SPRING_APPLICATION_JSON` 都会被解析并加入到 `Environment` 中。例如：
```sh
$ java -Dspring.application.json="{\"name\":\"value\"}" -jar app.jar
```

### 外部应用属性

在应用启动时，Spring Boot 会自动从下列位置查找和加载 `application.properties`、`application-{profile}.properties`、`application.yml` 和 `application-{profile}.yml`。其中，高优先级的配置项会覆盖低优先级的配置项，配置覆盖的优先级从低到高依次为：
1. classpath:
    * classpath 根目录
    * classpath 目录下的 `/config` 包
2. 当前目录：
    * 当前目录
    * 当前目录的 `/config` 子目录
    * `/config` 子目录的直接子目录

这里的 `application.properties` 的文件名也不是写死的，Spring Boot 允许我们通过 `spring.config.name` 这个环境属性定义自己喜欢的配置文件名。例如，以下命名告知 Spring Boot 去寻找 `myname.properties` 或 `myname.yml` 文件：
```sh
$ java -jar app.jar --spring.config.name=myname
```

此外，我们还可以通过 `spring.config.location` 和 `spring.config.additional-location` 环境属性 **显式** 指出配置文件的位置。由于Spring Boot 需要使用 `spring.config.name`、`spring.config.location` 和 `spring.config.additional-location` 来决定加载哪些配置文件，所以它们必须被定义成环境属性（通常是操作系统的环境变量、系统属性或命令行参数）。

### 配置随机值

有时候，我们可能希望某个配置项的值是随机生成的。如果每次都生成一个随机值放到配置文件中去，未免太过繁琐。这时，我们可以使用 `RandomValuePropertySource`，它支持随机产生整数、长整型数、UUID 和字符串。例如：
```yaml
my:
  number: "${random.int}"
  bignumber: "${random.long}"
  uuid: "${random.uuid}"
  name: "${random.value}"
```

## 使用 YAML

[YAML](https://yaml.org/) 是 JSON 的超集，在声明具有层次化的配置数据时非常方便。不过，YAML 文件中的配置在从层级结构转化为扁平结构之后，才能在 `Environment` 中使用。例如，下面的 YAML 文件：
```yaml
database:
  username: test-user
  password: test-password
```
会被扁平化为：
```properties
database.username=test-user
database.password=test-password
```

## 属性的注入与使用

Spring Boot 给我们提供了多种注入属性的方法，包括 `@Value` 和 `@ConfigurationProperties`。

### @Value

`@Value` 一般用于将单个属性注入到程序中。例如：
```java
@Value("${server.port}")
int port;
```

### @ConfigurationProperties

当配置信息有很多个时，`@Value` 的局限性就体现出来了。有多少个配置项，就需要写多少个 `@Value`😣。这时，我们可以使用 `@ConfigurationProperties`，它支持将多个配置项绑定到 Bean 的字段上。假设我们有一段数据库的配置信息：
```yaml
database:
  url: jdbc:postgresql:/localhost:5432/instance
  username: test-user
  password: test-password
```

我们可以通过 Java Bean 属性绑定的方式，将配置信息绑定到 Bean 的属性上：
```java
@ConfigurationProperties(prefix="database")
public class Database {
  String url;
  String name;
  String password;

  // getters and setters
}
```
也可以通过构造器绑定的方式，将配置信息绑定到 Bean 的属性上：
```java
public class Database {
  String url;
  String name;
  String password;

  public Database(String url, String name, String password) {
    this.url = url;
    this.name = name;
    this.password = password;
  }

  // getters
}
```

## Profiles

Spring Boot 允许我们根据不同的环境组织配置文件，让某些配置只在特定的环境下才生效，这就是 Profile。通过 `spring.profiles.active` 这个环境属性，我们可以决定激活哪些 profile。例如，我们可以将它配置在 `application.yml` 中，让 `dev` 和 `hsqldb` 两个 profile 生效：
```yaml
spring:
  profiles:
    active: "dev,hsqldb"
```
也可以通过命令行参数，只让 `dev` 这个 profile 生效：
```sh
$ java -jar app.jar --spring.profiles.active=dev
```
还可以通过环境变量等多种方式指定生效的 profile。如果没有指定生效的 profile 文件，默认的 profile 就会被启用。

## 参考资料

1. Spring Boot Documentation. [Externalized Configuration](https://docs.spring.io/spring-boot/docs/current/reference/html/features.html#features.external-config).