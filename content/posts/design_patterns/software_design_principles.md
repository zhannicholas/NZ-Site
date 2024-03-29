---
title: "软件设计原则"
date: 2018-09-29T20:51:23+08:00
draft: false
authors: ["zhannicholas"]
categories:
  - 软件设计
tags:
  - 设计原则
toc: true
---

在学习软件开发的过程中，我们或多或少都听过一些经典的设计原则，比如单一原则（DRY）、简单原则（KISS）、面向对象原则（SOLID）……这些设计原则都是前辈们在经验中总结出来的。在开发大型复杂软件的过程中，开发者面临软件的可维护性、可扩展性、灵活性、可重用性等诸多方面的挑战，灵活地使用设计原则能够帮助我们更好地面对这些挑战，设计出更加优秀的软件。

设计原则有很多，有些原则是之间是相互冲突的，而有些原则之间又是相互重复的。大家可能都有这样一个感觉——道理都懂，但是在实际运用时又会出现选择困难，不知从何下手。其实，设计原则是用来指导编程的，每个原则都有自己适用的范围，错误地使用各大原则很容易导致问题。下面是对常用设计原则的一个概括，这些原则不仅需要多看多理解，更要多实践。

## DRY 原则

**Don't Repeat Yourself**。《程序员修炼之道》一书中是这么解释 DRY 的：系统的每一个功能都应该有唯一的实现，如果多次遇到同样的问题，就应该抽象出一个共同的解决方法，而不要重复开发同样的功能代码。这个原则很简单，大家在平常的编程中也经常使用。我们常听说的“不要重复造轮子”就是对 DRY 的一种认知。

## KISS 原则

**Keep It Simple and Stupid**。保持代码的简单，快速迭代拥抱变化。编写可读性高的代码，能够减少他人阅读代码的时间投入。

## YAGNI 原则

**You Ain’t Gonna Need It**。有时候，很多开发者都会写一些多余的代码，想着万一以后可能会用上。但实际上，这些多的代码可能永远都不会用上，反而会对原来的代码造成污染，增加别人阅读理解代码的难度。YAGNI 希望我们不要写将来可能需要，但现在却用不上的代码。YAGNI 原则与 KISS 原则联系紧密，能够帮助更好地实现 KISS　原则。

## 迪米特法则(Law of Demeter, LoD)

**一个软件实体应当尽可能少的与其它实体发生作用**。如果一个系统符合迪米特法则，那么当其中的某一个模块发生改变时，就会尽量少的影响其它模块。在设计系统的时候，尽量减少对象之间的交互，如果两个对象之间不必彼此直接通信，那么这两个对象之间就不应当发生任何直接的作用。如果一个对象需要调用另一个对象的方法，可以通过一个第三者来完成这个调用。这就降低了对象之间的耦合度。

## SOLID 原则

在设计中使用这些原则，有助于提高设计模型的灵活性和可维护性，提高类的內聚度，降低类之间的耦合度。

### 单一职责原则(Single Responsibility Principle, SRP)

**职责** 可以理解为 **引起类变化的原因**。 **就一个类而言，应该只有一个引起它变化的原因** 。如果一个类具有多个职责，那么就有多个引起它变化的原因。过多的职责耦合在一起，当其中一个职责变化时，可能影响到其它职责的正常运作。因此，在设计类的时候，要将这些职责分离，将不同的职责封装在不同的类中。确保引起该类变化的原因只有一个，从而提高类的內聚度。

### 开闭原则(Open-Closed Principle, OCP)

**一个软件实体应当对扩展开放，对修改关闭** 。也就是说： 软件实体应该尽可能在不修改原有代码的情况下进行扩展 。为了满足开闭原则，需要对系统进行 **抽象化** 设计，抽象化是开闭原则的关键。可以先定义出 **抽象层** ，然后通过 **具体类** 来进行扩展。当需要修改系统的行为时，不需要改动抽象层，只需要添加新的具体类就能实现新的业务功能，这就在不修改原有代码的基础上完成了目标。

### 里氏替换原则(Liskov Substitution Principle, LSP)

**子类应当可以替换父类并出现在父类能够出现的任何地方** 。也就是说：在软件中将一个父类对象替换成它的子类对象，程序不会出现任何的问题，反过来则不然。里氏替换原则是实现开闭原则的重要方式之一。由于使用父类的地方都可以使用子类，因此在程序中应该尽量使用父类来对对象进行定义，而在运行的时候再确定子类类型，用子类替换父类对象。因此，可以将父类声明设计为抽象类或者接口，让子类继承父类或者实现父类接口并实现父类声明的方法。在运行的时候，子类实例替换父类实例，可以很方便的扩展系统的功能，增加新的功能可以通过增加新的子类来实现。

### 依赖倒置原则(Dependence Inversion Principle, DIP)

**抽象不应该依赖于细节，细节应当依赖于抽象** 。高层模块不应该依赖于低层模块，两者都应当依赖于 **抽象** 。也就是说：要针对接口编程，而不是针对实现编程。在程序设计中，尽量使用高层的抽象类来完成功能，而不要使用具体的类来做这些。为此，一个具体类应当只实现接口或者抽象类中声明过的方法，而不要有多余的方法，否则高层的抽象类无法调用到在子类新增加的方法。

引入抽象层之后，系统的灵活性变高。在程序中尽量使用抽象类进行编程，而将具体类写在配置文件中。如此一来，当系统需要扩展时，只需要对抽象层进行扩展并修改配置文件，无需改动原来的代码。

依赖注入的三种方式： **构造注入** 、 **设值注入** 、 **接口注入** 。

### 接口隔离原则(Interface Segregation Principle, ISP)

**使用多个专门的接口，而不使用一个总的接口** 。也就是说：客户端不应该依赖它不需要的接口。当一个接口太大的时候，需要将其划分为一些更小的接口。如果把接口比喻成角色，那么一个接口应当只扮演一个或者一类角色。

## 组合/聚合复用原则(Composite Reuse Principle, CRP)

**应当尽量使用对象组合，而不是继承来达到复用的目的**。继承复用会破坏封装性，因为继承会将父类的实现细节暴露给子类。当父类改变的时候，子类也必须跟着改变。组合/聚合关系可以将已有的对象纳入新的对象中，新对象可以调用已有对象的功能，而已有对象的内部对新对象是不可见的。相对于继承来说，这种方式的耦合度较低，已有对象的改变不会给新对象带来太大的影响。一般来说，如果两个类之间是 **Is-A** 关系，应当使用继承；如果两个类之间是 **Has-A** 关系，应当使用组合或者聚合。

## 参考资料

1. 刘伟. 设计模式的艺术：软件开发人员内功修炼之道. 清华大学出版社, 2013.