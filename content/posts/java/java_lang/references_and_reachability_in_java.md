---
date: "2021-04-20T21:40:00+08:00"
title: "Java 中的引用与对象可达性"
authors: ["zhannicholas"]
categories:
  - Java
tags:
  - Java
draft: false
toc: true
---

JDK 1.2 之后，Java 将引用分为强引用（Strongly Reference）、软引用（Soft Reference）、弱引用（Weak Reference）和虚引用（Phantom Reference）四种，这四种引用的强度依次减弱，它们与 Java 的对象回收有着很大的关系。

> A reference object encapsulates a reference to some other object so that the reference itself may be examined and manipulated like any other object. Three types of reference objects are provided, each weaker than the last: soft, weak, and phantom. Each type corresponds to a different level of reachability. 

这段话已经描述得很清楚了：Java 中有三种引用对象（reference object），它们封装了一些其它的对象，从而让我们可以像操作其它对象一样操作引用本身，不同引用对象的可达性不同。

除开与 Finalization 有关的类，下图展示了 `java.lang.ref` 包中的类结构：

![](/images/java/java_lang/reference-class-hierarchy.png)

`Reference` 对象用于维持对其它对象的引用，但 GC 仍然可以回收这些被引用的其它对象。当 GC 决定回收某个引用对象关联的对象时，它会将对应的引用对象放入与之关联的引用队列（`ReferenceQueue`）中，这样我们就可以得到对象被回收的通知了。

## 对象可达性

在进行垃圾回收之前，第一件事情就是找出垃圾。引用计数算法和可达性分析算法是两种常见的判断垃圾的方法，JVM 是通过分析对象的可达性来判断是否应该将其回收的。

### GC Roots

可达性分析算法的基本思路是通过一系列被称为“GC Roots”的根对象作为起始节点集，从这些结点开始，根据引用关系向下搜索，搜索路径即为引用链（Reference Chain），如果某个对象没有任何路径可以到达 GC Roots，则说明这个对象不再被使用，即为垃圾。

![](/images/java/java_lang/gc_roots_and_object_reachability.png)

在 Java 中，可以作为GC Roots的对象有以下几种：

* JVM 栈中引用的对象，比如线程方法的参数、局部变量、临时变量等；
* 方法区中静态属性引用的对象，比如 Java 类的引用类型的静态变量；
* 方法区中常量引用的对象，比如字符串常量池中的引用；
* Native 方法栈中 JNI 引用的对象；
* JVM 内部的引用，比如基本数据类型对应的 Class 对象、一些常驻的异常对象（NullPointerException、OutOfMemeryError 等）、系统类加载器；
* 所有被同步锁（synchronized）持有的对象；
* 反映 JVM 内部情况的 JMXBean、JVMTI 中注册的回调、Native 代码缓存等；

Eclipse 的内存分析工具列举出了各种具体的 [GC Root](https://help.eclipse.org/2021-03/index.jsp?topic=%2Forg.eclipse.mat.ui.help%2Fconcepts%2Fgcroots.html)

### 对象的五种可达性

Java 中的对象可达性有五种不同的程度：强可达（strongly reachable）、软可达（softly reachable）、弱可达（weakly reachable）、虚可达（phantom reachable）和不可达（unreachable）。以下关于可达性的描述，取自 [java.lang.ref](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/lang/ref/package-summary.html#reachability) 包的文档：

> Going from strongest to weakest, the different levels of reachability reflect the life cycle of an object. They are operationally defined as follows:
>
> * An object is strongly reachable if it can be reached by some thread without traversing any reference objects. A newly-created object is strongly reachable by the thread that created it.
>
> * An object is softly reachable if it is not strongly reachable but can be reached by traversing a soft reference.
>
> * An object is weakly reachable if it is neither strongly nor softly reachable but can be reached by traversing a weak reference. When the weak references to a weakly-reachable object are cleared, the object becomes eligible for finalization.
>
> * An object is phantom reachable if it is neither strongly, softly, nor weakly reachable, it has been finalized, and some phantom reference refers to it.
>
> * Finally, an object is unreachable, and therefore eligible for reclamation, when it is not reachable in any of the above ways.

## 强引用

强引用指程序代码中普遍存在的引用赋值（比如`Object strongReference = new Object()`这种关系）。在任何情况下，只要强引用的关系还在，垃圾收集器就不会回收被引用的对象。当内存不足时，JVM 宁愿抛出 `OutOfMemorryError`，也不会回收具有强引用的对象。当一个强引用对象不再使用时，若要让 GC 回收它，我们需要让它变得不可达（实际上，GC 也只回收不可达对象）。

```java
void test() {
    Object strongReference = new Object();  // 强引用
    strongReference = null; //  对象可以被 GC 回收了
}
```

在上面这段代码中，`new Object()` 会在堆中创建一个对象，而指向这个对象的是栈中的引用 `strongReference`。当方法调用完成，方法栈退出，`strongReference` 不复存在，这个对象就可以被回收了。若 `strongReference` 是全局变量，则需要手动将其设置为 `null`，去除其对对象的引用，对象才能被回收。

## 软引用

被软引用关联对象即软可达对象，它们是一些还有用但非必须的对象，在系统将要发生内存溢出之前，会被二次回收，如果这次回收之后的内存依然不够，JVM 才会抛出 OutOfMemoryError。**JVM 保证在抛出 OutOfMemoryError 之前回收所有被软引用关联的软可达对象**。JDK 1.2 之后提供了 `SoftReference` 类来表示软引用。

> Soft references are most often used to implement memory-sensitive caches.

创建软引用对象的方法有两种。

第一种是创建不与任何引用队列关联的软引用对象：
```java
Object referent = new Object();
SoftReference<Object> softReference = new SoftReference<>(referent);
```

我们也可以使用带 `ReferenceQueue` 的构造函数，如果软引用所引用的对象被回收，JVM 就会自动将这个软引用加入到与之关联的引用队列中：
```java
ReferenceQueue<Object> referenceQueue = new ReferenceQueue<>();
SoftReference<Object> softReference = new SoftReference<>(obj, referenceQueue);
```

`Reference` 类提供的 `get` 和 `clear` 方法分别可以用来获取和重置对应的引用：

```java
Object referent = softReference.get();
softReference.clear();
Object referent2 = softReference.get();  // null
```

实际上，由于对象可能被 GC 回收，所以在进行下一步操作时，我们需要对 `get` 方法返回的 referent 进行检查：

```java
Object referent = softReference.get();
if (referent != null) {
  // 对象还没有被 GC 回收
  // 用作缓存时，可直接返回对象
} else {
  // 对象已经被 GC 回收
  // 用作缓存时，需要重新实例化引用对象
}
```

## 弱引用

被弱引用关联的对象即弱可达对象，它描述的也是非必须对象，其强度比软引用更弱。被弱引用关联的对象，只能生存到下一次垃圾回收。当垃圾收集器开始工作，无论当前内存是否不足，都会回收掉被弱引用关联的对象。JDK 1.2 之后提供了 `WeakReference` 类来表示弱引用。

弱引用与软引用之间最大的区别在于：被弱引用指向的对象只在两次 GC 之间存活，而被软引用指向的对象在 JVM 内存紧张的时候才被回收，它是可以经历多次 GC 的。

> Weak references are most often used to implement canonicalizing mappings.

创建弱引用对象的方法也有两种，不关联任何引用队列的和关联引用队列的：

```java
Object referent = new Object();
ReferenceQueue referenceQueue = new ReferenceQueue();

WeakReference weakReference1 = new WeakReference<>(referent);
WeakReference weakReference2 = new WeakReference<>(referent, referenceQueue);
```

弱引用的其它使用与软引用类似，不再赘述。

JDK 提供了一个基于弱引用实现的 `HashMap` 集合—— `WeakHashMap`，其中的 `Entry` 继承了 `WeakReference`，`Entry` 中使用弱引用指向 Key，使用强引用指向 Value。当没有强引用指向 Key 的时候，Key 可以被 GC 回收。当再次操作 `WeakHashMap` 的时候，就会遍历关联的引用队列，从 `WeakHashMap` 中清理掉相应的 `Entry`。


## 虚引用

虚引用是最弱的一种引用关系，又称“幽灵引用”或“幻影引用”。一个对象是否有虚引用，完全不会对其生存时间构成影响，也无法通过虚引用来获取一个对象的实例。JDK 1.2 之后提供了 `PhantomReference` 类来表示虚引用。虚引用主要用来跟踪对象被 GC 回收的活动。 虚引用与软引用和弱引用的一个区别在于：虚引用必须和引用队列一起使用。当垃圾回收器准备回收一个对象时，如果发现它还有虚引用，就会在回收对象的内存之前，把这个虚引用加入到与之关联的引用队列中。


```java
Object referent = new Object();
ReferenceQueue referenceQueue = new ReferenceQueue();

// 创建虚引用时，必须和一个引用队列相关联
PhantomReference phantomReference = new PhantomReference<>(referent, referenceQueue);
```
弱引用的其它使用与软引用类似，不再赘述。

## 参考资料
1. 周志明. 深入理解Java虚拟机（第3版）. 机械工业出版社, 2019.
2. [Package java.lang.ref](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/lang/ref/package-summary.html).