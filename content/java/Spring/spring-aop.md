---
date: "2021-08-23T23:06:54+08:00"
title: "Spring AOP"
authors: ["zhannicholas"]
categories:
  - Spring
tags:
  - Spring
draft: true
toc: true
---

我们常见的面向对象编程（Object Oriented Programming, OOP）通过封装、继承和多态将程序分解为各个层次的对象，而面向切面编程（Aspect Oriented Programming, AOP）则从不同的角度看待程序结构，将程序分解为不同的关注点（切面，Aspect），对 OOP 起到了补充完善的作用。举个例子，假设业务 A 和业务 B 都需要对用户的访问行为进行鉴权，在传统的 OOP 中，我们可能需要给两个业务都加上鉴权的代码，而采用 AOP 则只需要编写一遍代码，然后由两个业务共用。AOP 就是这样，它将公用的代码剥离出来集中管理，等到具体运行的时候，容器再动态织入这些公用代码。

AOP 的使用场景还是蛮多的，我们常见的参数校验、日志记录、异常处理、权限控制、事务处理、性能统计等都有 AOP 的用武之地。下面，我们就一起来学习一下 AOP 的一些核心概念和专业术语。

## AOP 基本概念

* **连接点（Join Point）**：程序执行过程中的某一点，比如异常的处理和方法的执行。**在 Spring AOP 中，连接点都指方法的执行。**
* **切入点（Pointcut）**：一组匹配连接点的正则表达式，决定是否需要执行通知（Advice）。
* **通知（Advice）**：在连接点与切入点匹配成功时执行的方法。
* **切面（Aspect）**：由切入点和通知组成的横切关注点的模块化实现单元，定义的是在哪些地方（切入点）执行哪些操作（通知）。比如事务管理。
* **目标对象（Target object）**：被一个或多个切面所通知的对象，又叫“advised object”。
* **AOP 代理（AOP proxy）**：一个 AOP 框架为了实现切面契约（比如方法执行的通知）而创建的对象，即目标对象的代理类。在 Spring 框架中，AOP 代理要么是 JDK 动态代理，要么是 CGLIB 代理。


## 通知（Advice）

Spring AOP 支持以下类型的通知：

* 前置通知（Before advice）：在连接点之前执行。
* 后置通知（After returning advice）：在连接点正常执行完成之后执行。
* 异常通知（After throwing advice）：在方法由于抛出异常而退出之后执行。
* 最终通知（After (finally) advice）：在连接点退出之后执行（不论是正常退出，还是异常退出）。
* 环绕通知（Around advice）：在连接点执行前后都执行。环绕通知也是 Spring AOP 中能力最强的通知，允许我们在方法调用前后进行个性化处理。




## 参考资料

1. Wikepedia. [Aspect-oriented programming](https://en.wikipedia.org/wiki/Aspect-oriented_programming).
2. Spring Framework Documentation. [Aspect Oriented Programming with Spring](https://docs.spring.io/spring-framework/docs/current/reference/html/core.html#aop).
3. [The AspectJTM Programming Guide](https://www.eclipse.org/aspectj/doc/released/progguide/index.html).