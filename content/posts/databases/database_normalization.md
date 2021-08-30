---
date: "2021-07-29T16:16:11+08:00"
title: "数据库规范化"
authors: ["zhannicholas"]
categories:
  - DB
tags:
  - 数据库
draft: false
toc: true
---

在关系数据库设计中，**[数据库规范化（Database normalization）](https://en.wikipedia.org/wiki/Database_normalization)** 是一个非常重要的概念。一般而言，关系数据库设计的目标是生成一组关系模式，使我们存储数据时避免不必要的冗余，同时让我们可以方便地获取数据。规范化就是组织数据库内数据的一个过程，包括创建数据表和建立这些表之间的关系。而在建立表间关系时，我们既要保护数据的完整性，又要消除冗余数据。冗余数据不仅会浪费磁盘空间，还会增加我们维护的成本。

## 相关术语

关系数据库设计中涉及很多专业术语，在进入到主要内容之前，我想先介绍下这些术语，确保我们能够在术语的使用上达成共识。

* **数据库表（Table）**：在关系数据库中，[数据库表](https://en.wikipedia.org/wiki/Table_(database))是一个逻辑概念，代表以表格的形式进行组织的一组相关数据构成的集合。它由行和列组成。
* **行（Row）**：数据库表中的每一[行](https://en.wikipedia.org/wiki/Row_(database))（或每一条 **记录（Record）**）都表示一组相关数据，表中的所有行的结构都是相同的。行又称 **元组（Tuple）**。
* **列（Column）**：在关系数据库中，[列](https://en.wikipedia.org/wiki/Column_(database))是一组特定类型数据构成的集合，集合中的每一项数据（字段）都分散在每一行中。如果一个表有 `N` 列，那么表中的每一条记录就会有 `N` 个字段。列又称 **属性（Attribute）**。

举个例子，我们有一个学生表 `student(stu_id, name, gender)`，在下面的 SQL 实现中：

```SQL
CREATE TABLE student(
  stu_id INTEGER NOT NULL,
  name VARCHAR(50) NOT NULL,
  gender INTEGER NOT NULL,
  PRIMARY KEY (id)
);
INSERT INTO student VALUES(1, "Mike", 1);
```

`create TABLE student(...);` 就代表一个表，`stu_id INTEGER NOT NULL` 就是表中的一列，`INSERT INTO student VALUES(1, "Mike", 1);` 就是我们插入表中的一行数据。简单来说，表关注的是数据的组织形式，行关注的是数据的相关性，列关注的是数据的类型。

### 数据库中的键

键（Key）是数据库表结构的重要组成部分，通常由表中一个或多个字段构成，用来唯一标识表中的一条记录。此外，键还被用来提高数据的完整性，建立表与表之间的关系。在关系数据模型中，键主要有三种：候选键、主键和外键。

* **超键（Superkey）**：[超键](https://en.wikipedia.org/wiki/Superkey)是一组能唯一标识出表中的每一行记录的属性集合。
* **候选键（Candidate key）**：若超键不包含多余的属性（即最小超键），那么这个超键就是[候选键](https://en.wikipedia.org/wiki/Candidate_key)。候选键是超键的子集，每个表都必须有至少一个候选键。例如，在学生表 `student(stu_id, name, gender)` 中，若 `stu_id` 和 `name` 都可以唯一确定出一名学生，那么 `stu_id` 和 `name` 都是候选键。组成候选键中的属性叫主属性（prime attributes），不包含在候选键中的属性就是非主属性。
* **主键（Primary key）**：既然候选键可以唯一标识出表中的每一行记录，那么我们就可以从候选键中选取一个作为[主键](https://en.wikipedia.org/wiki/Primary_key)，剩下的那些候选键就被称为替代键（Alternative key）。
* **外键（Foreign key）**：若表 A 中的属性集 S 不是表 A 的主键，但 S 是表 B 的主键，则 S 就是表 A 中指向表 B 的[外键](https://en.wikipedia.org/wiki/Foreign_key)。

## 范式

为了保证数据库的规范化，人们开发出了一系列的设计准则。这些准则就是我们常说的 **范式（normal form）**。范式也分为很多等级，按照数据的规范化程度，从低到高依次有：第一范式（1NF）、第二范式（2NF）、第三范式（3NF）、BC 范式（BCNF）、第四范式（4NF）、第五范式（5NF）。

满足最低要求的是第一范式，在第一范式的基础上进一步满足一些要求的是第二范式，在第二范式的基础上再进一步满足一些要求的是第三范式……，以此类推。数据库满足的范式越高，数据冗余就越小，一般数据表的数量也会越多。在实际应用中，我们通常只会用到前三个范式，所以本文也只会覆盖带前三个范式。

需要注意的是，范式只是用来指导数据库设计的，在大多数业务场景下是适用的。而对于一些特殊的业务场景，范式设计的表是无法满足需求的，这时就需要进行反范式设计。

### 第一范式

第一范式强调的是列的 **原子性**，要求表中的所有属性都是原子的，不可再分。

例如，当学生同时有座机和手机两个电话号码时，将座机和手机放在一列——`student(stu_id, name, phone)` 的表设计就不满足第一范式。这个时候，将电话拆分为两列：`student(stu_id, name, telephone, cellphone)`，第一范式就满足了。

### 第二范式

第二范式满足第一范式，并且：
* 任何非主属性都必须 **完全依赖** 候选键，而不能只依赖候选键中的部分属性。

例如，我们有一个 `stu_course(stu_id, course_id, course_name, stu_name, grade)`，主键为复合主键 `(stu_id, course_id)`。在这个表中，成绩是完全依赖于主键的，只有当学号和课程号确定了，才能确定成绩。而姓名是不完全依赖于主键的，因为只要学号确定了，姓名也就唯一确定了，不需要再使用课程号。所以，姓名是部分依赖于主键 `(stu_id, course_id)`的，学生课程表因此不满足第二范式。此外，课程名称也是部分依赖于主键的。那么如何解决这个问题呢，正确的做法是将 `stu_course(stu_id, course_id, course_name, stu_name, grade)` 拆分为三个表：`student(stu_id, stu_name)`、`course(course_id, course_name)` 和 `stu_course(stu_id, course_id, grade)`。

### 第三范式

第三范式满足第二范式，并且：
* 任何非主属性都必须直接依赖候选键，不能出现传递依赖。即不能出现非主属性 A 依赖非主属性 B，而属性 B 又直接依赖于候选键键的情况。

例如，我们有一个`student(stu_id, stu_name, dept_id, dept_name)`。这里，学号可以唯一确定学院编号，而学院编号可以唯一确定学院名称。这就出现了`学院名称 <- 学院编号 <- 学号`这样的传递依赖，因此不满足第三范式。解决办法就是将`student(stu_id, stu_name, dept_id, dept_name)`拆分为两个子表：`dept(dept_id, dept_name)`和`student(stu_id, stu_name, dept_id)`。

## 反范式

在大多数的业务场景下，范式设计的表都能满足需求。而对于一些特殊的业务场景，范式设计的表无法满足性能的需求。此时就需要根据业务场景，在范式的基础之上进行灵活设计，也就是反范式设计。


反范式设计主要从业务场景、响应时间和字段冗余三方面考虑。用一句话总结就是：用空间来换取时间，提高业务场景的响应时间，减少多表关联。

## 参考资料

1. Wikipedia. [Database normalization](https://en.wikipedia.org/wiki/Database_normalization).
2. [Database Keys](http://rdbms.opengrass.net/2_Database%20Design/2.1_TermsOfReference/2.1.2_Keys.html).