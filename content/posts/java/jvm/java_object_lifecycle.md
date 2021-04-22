---
date: "2021-04-21T23:30:52+08:00"
title: "Java 对象的一生"
authors: ["zhannicholas"]
categories:
  - Java
tags:
  - GC
  - JVM
draft: false
toc: true
---

[The Truth About Garbage Collection](http://kwangshin.pe.kr/java/GC/JavaTM%20Platform%20Performance-%20Strategies%20and%20Tactics%20-%20Appendix%20A.pdf) 这篇文章挺好的，本文的很多内容也是基于这篇文章而来。

Java 是一门面向对象的编程语言，在程序的运行过程中，不断有新的对象被创建出来，也不断有对象被回收。JVM 中的对象从创建到回收，通常会经历以下大多数状态：

1. Created
2. In use (strongly reachable)
3. Invisible
4. Unreachable
5. Collected
6. Finalized
7. Deallocated

## Created

对象的创建通常会经历以下几个步骤：

1. 为对象分配空间
2. 开始构造对象
3. 调用父类的构造函数
4. 初始化实例与实例变量
5. 执行构造函数的剩余部分

这些操作的具体代价取决于 JVM 的实现，以及构造类的过程是如何实现的。对象被创建后，如果它被赋给某给变量（有变量引用了这个对象），它就会直接进入 In Use 状态。

## In Use

若对象被至少一个强引用持有，它就处于使用中（In Use）状态。JDK 1.1.x 中的所有引用都是强引用，JDK 1.2 则引入了三种其它的引用：软引用（soft reference）、弱引用（weak reference）和虚引用（phantom reference），三种引用的强度依次减弱。下面这段代码展示了创建对象并将其赋值给一些变量的过程：

```java
public class CatTest {
    static Vector catList = new Vector();
    static void makeCat() {
        Object cat = new Cat();
        catList.addElement(cat);
    }

    public static void main(String[] arg) {
        makeCat();
        // do more stuff
    }
}
```

下图显示了 `makeCat` 方法返回前，JVM 中对象的引用关系。此时，有两个引用指向了 `Cat` 对象：

![](/images/java/jvm/object-reference-graph.png)

当 `makeCat` 方法返回后，它的栈帧与方法内声明的所有临时变量都会被移除。如此一来，指向 `Cat` 对象的引用就只有静态变量 `catList` 了，它通过 `Vector` 间接指向 `Cat` 对象。

## Invisible

即使指向对象的强引用依然存在，但如果这些强引用对程序来说是 **不可访问的**，对象就会进入不可见状态（invisible）。并不是所有的对象都会进入这个状态，下面代码片段展示了一个不可见对象：

```java
public void run() {
    try {
        Object foo = new Object();
        foo.doSomething();
    } catch (Exception e) {
        // whatever
    }
    while (true) {  // loop forever
        // do stuff 
    }
}
```

以上代码创建了 `foo` 这个对象，当 `try` 语句块执行完成时，`foo` 就变得不可访问了（`foo` 只可在[ `try` 语句块](https://docs.oracle.com/javase/specs/jls/se11/html/jls-14.html#jls)内被访问，JLS11 中的 [Scope of a Declaration](https://docs.oracle.com/javase/specs/jls/se11/html/jls-6.html#jls-6.3) 部分对局部变量的作用域进行了详细说明）。在 `run` 方法返回之前，`foo` 都是强引用，并且是 GC Root，所以不能被回收，因此可能导致内存泄漏。在这种情况下，我们必须显式地将 `foo` 设置为 `null`，才能保证垃圾回收。

## Unreachable

当不存在从 GC Root 到对象的强引用（链）时，对象就处于不可达（unreachable）状态。处于不可达状态的对象就可以被回收了，但这并不意味着对象会被立即回收，JVM 可以在任何需要的时候进行回收操作。

循环引用并不一定会导致内存泄漏，举个例子：

```java
public void buildDog() {
    Dog newDog = new Dog();
    Tail newTail = new Tail();
    newDog.tail = newTail;
    newTail.dog = newDog;
}
```

下图展示了 `buildDog` 方法返回前对象的引用图。方法返回前，`newDog` 和 `newTail` 都是栈的局部变量，并且互相引用，它们都是 GC Root：

![](/images/java/jvm/reference-graph-before-buildDog-returns.png)

下图展示了 `buildDog` 方法返回后的对象引用图。这时，由于栈帧弹出，`Dog` 和 `Tail` 虽然相互引用，但是它们当中任何一个对 GC Roots 来说都是不可达的，所以它们可以被回收。

![](/images/java/jvm/reference-graph-after-buildDog-returns.png)

## Collected

当 GC 在识别出对象处于不可达状态，并做好了对该对象的内存空间进行重新分配的准备之后，对象就进入被收集（Collected）状态。如果对象没有 `finalize` 方法，它就会直接进入终结（Finalized）状态。若对象有 `finalize` 方法（具有 finalizer），并且没有执行过，`finalize` 方法会被执行（`finalize` 方法只会被执行一次）。

注：`finalize` 方法在 JDK9 中已被弃用，因为它可能带来性能问题，导致死锁、资源泄漏等。

## Finalized

若对象具有 `finalize` 方法，如果对象在 `finalize` 方法被执行后仍然是不可达的，对象的状态就是已终结（Finalized）。处于终结状态的对象正等待被回收。虽然 finalizer 的执行时机由 JVM 决定，但是有一点可以肯定：finalizer 会延长对象的生命周期，甚至让对象起死回生。

周志明老师的《深入理解Java虚拟机（第3版）》中就给出了一段对象自我拯救的代码：

```java
/**
 * 此代码演示了两点： 
 * 1.对象可以在被GC时自我拯救。 
 * 2.这种自救的机会只有一次，因为一个对象的finalize()方法最多只会被系统自动调用一次
 * @author zzm
 */
public class FinalizeEscapeGC {
 
    public static FinalizeEscapeGC SAVE_HOOK = null;
 
    public void isAlive() {
        System.out.println("yes, i am still alive :)");
    }
 
    @Override
    protected void finalize() throws Throwable {
        super.finalize();
        System.out.println("finalize mehtod executed!");
        FinalizeEscapeGC.SAVE_HOOK = this;
    }
 
    public static void main(String[] args) throws Throwable {
        SAVE_HOOK = new FinalizeEscapeGC();
 
        //对象第一次成功拯救自己
        SAVE_HOOK = null;
        System.gc();
        // 因为Finalizer方法优先级很低，暂停0.5秒，以等待它
        Thread.sleep(500);
        if (SAVE_HOOK != null) {
            SAVE_HOOK.isAlive();
        } else {
            System.out.println("no, i am dead :(");
        }
 
        // 下面这段代码与上面的完全相同，但是这次自救却失败了
        SAVE_HOOK = null;
        System.gc();
        // 因为Finalizer方法优先级很低，暂停0.5秒，以等待它
        Thread.sleep(500);
        if (SAVE_HOOK != null) {
            SAVE_HOOK.isAlive();
        } else {
            System.out.println("no, i am dead :(");
        }
    }
}
```

运行结果：

```txt
finalize mehtod executed ! 
yes,i am still alive : ) 
no,i am dead : (
```

由于 `finalize` 方法只会被系统自动调用一次，所以对象第一次自救成功，第二次却失败了。JLS11 的 [Finalization of Class Instances](https://docs.oracle.com/javase/specs/jls/se11/html/jls-12.html#jls-12.6) 部分对 Finalization 进行了详细的介绍，但考虑到它已经被 JDK 弃用，我们还是跳过吧。

## Deallocated

释放（Deallocated）状态是 GC 过程最后一步中对象的状态。在经过以上六个阶段之后，如果对象依然不可达，那么它就可以被释放了。何时以及如何释放对象所占内存依然是由 JVM 决定的。

## 小结

最后，借网上的一张图来结束本文，感谢[原作](http://javarefresh.com/lifecycle/javacycleLC.php)。

![](/images/java/jvm/java-object-life-cycle.png)

本文其实只涉及对象生命周期的一个宏观步骤，实际的对象的一生会更加复杂。对象是类的实例，对于一个新生对象，JVM 需要找到对象所属的类，如果类没有加载，还需要先进行类加载，然后为对象分配内存空间，初始化对象的属性为零值，对对象进行必要的设置……经过这一系列步骤，对象才得以诞生。随后，为了使用对象，我们需要进行对象的访问定位。用完之后，对象等待被垃圾回收，为其它新生对象留出宝贵的内存空间。对象的一生可不简单。

## 参考资料

1. [The Truth About Garbage Collection](http://kwangshin.pe.kr/java/GC/JavaTM%20Platform%20Performance-%20Strategies%20and%20Tactics%20-%20Appendix%20A.pdf).
2. 周志明. 深入理解Java虚拟机（第3版）. 机械工业出版社, 2019.