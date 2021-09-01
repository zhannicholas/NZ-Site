---
date: "2021-09-01T09:46:58+08:00"
title: "Java 中的原子类"
authors: ["zhannicholas"]
categories:
  - Java
tags:
  - Java
  - 并发
draft: false
toc: true
---

一谈到原子类（或原子变量），我们可能就会想知道它和我们编程中常说的原子性（Atomicy）之间是否有关系。若一组操作具备“要么全部成功，要么全部失败，不能一部分成功一部分失败”的性质，那么这组操作就是原子操作，这组操作具备原子性。

在 Java 中，原子操作可以通过锁和循环 CAS 的方式实现。其中 CAS 操作是利用处理器提供的 `COMPXCHG` 指令实现的。自旋 CAS 实现的基本思路是循环进行 CAS 操作直到成功为止。但 CAS 存在三个问题：
* **ABA问题**。可以使用版本号来解决。
* **循环时间长开销大**。这一般出现在自旋CAS长时间不成功的情况下。
* **只能保证一个共享变量的原子操作**。对于多个共享变量的原子操作，一般采用锁来解决，也可以将多个共享变量封装进一个对象，然后使用`AtomicReference`类来解决。

JVM 内部实现了很多锁机制，有意思的是除了偏向锁，JVM 实现锁的方式都用了循环 CAS，即当一个线程进入同步代码块时使用循环 CAS 获取锁，离开同步代码块时使用循环 CAS 释放锁。CAS 最直接的体现就是 `java.util.concurrent.atomic` 包下定义的各种无锁原子类，这些原子类都支持单个变量上的原子操作。举个例子，`i++` 在并发环境中并不是线程安全的，要保证线程安全，我们需要给 `i++` 加锁。实际上，我们也可以直接使用原子类提供的 `getAndIncrement` 方法完成同样的操作。由于原子类底层采用的 CAS 实现，在并发竞争不是特别激烈的情况下，效率要高于同步互斥锁。

根据操作类型的不同，可以大致将 `java.util.concurrent.atomic` 下的原子类分成六种：

| 类型                                    | 具体类                                                       |
| --------------------------------------- | ------------------------------------------------------------ |
| 基本类型原子类（AtomicXxx）             | AtomicInteger, AtomicLong, AtomicBoolean                     |
| 引用类型原子类（AtomicXxxReference）    | AtomicReference, AtomicStampedReference, AtomicMarkableReference |
| 数组类型原子类（AtomicXxxArray）        | AtomicIntegerArray, AtomicLongArray, AtomicReferenceArray    |
| 字段更新原子类（AtomicXxxFieldUpdater） | AtomicIntegerFieldUpdater, AtomicLongFieldUpdater, AtomicReferenceFieldUpdater |
| 加法器（Adder）                         | LongAdder, DoubleAdder                                       |
| 累加器（Accumulator）                   | LongAccumulator, DoubleAccumulator                           |

下面分别最这六大类型的原子类进行介绍。

## 基本类型原子类

基本类型原子类包括三种：`AtomicInteger`、`AtomicLong` 和 `AtomicBoolean`。其中 `AtomicInteger` 和 `AtomicLong` 是对 `int`、`long` 的封装，而 `AtomicBoolean` 内部封装的变量的类型并不是 `boolean`，而是 `int`，它用 `0` 和 `1` 分别表示 `false` 和 `true`。三种类型都提供了对内部封装变量的原子性访问和更新操作，我们可以在并发环境中放心使用。

以 `AtomicInteger` 为例，它给我们提供的常用方法有：
* `get()`：获取封装变量的当前值
* `getAndSet(int newValue)`：获取封装变量的当前值，然后将变量的值设置为新的值
* `getAndIncrement()`：获取封装变量的当前值，然后将变量的值加一
* `getAndDecrement()`：获取封装变量的当前值，然后将变量的值减一
* `getAndAdd(int delta)`：获取封装变量的当前值，然后将变量的值加上 `delta`
* `compareAndSet(int expectedValue, int newValue)`：如果封装变量的当前值为 `expectedValue`，则原子性地将变量的值设置为 `newValue`。这个方法就是原子类 CAS 的具体体现。

`AtomicInteger` 其实还给我们提供了很多实用的方法，这里就不一一列举了。`AtomicLong` 和 `AtomicBoolean` 提供的方法也与 `AtomicInteger` 类似，这些原子类的内部都依赖 JDK 提供的 `Unsafe` 类，它提供了硬件级别的原子操作，允许调用方直接操作内存中的数据。

## 引用类型原子类

引用类型原子类也包括三种：`AtomicReference`、`AtomicStampedReference` 和 `AtomicMarkableReference`。引用类型原子类与基本类型原子类的区别在于：引用类型原子类保证的是基本类型的原子性，而引用类型原子类保证的是对象的原子性。

`AtomicReference` 内部维护了一个对象的引用，而`AtomicStampedReference` 和 `AtomicMarkableReference` 都是 `AtomicReference` 的增强版本。其中 `AtomicStampedReference` 内部维护了一个 `int` 类型的 `stamp` 变量，它同对象引用一起原子性地更新，用于解决 CAS 中可能出现的 ABA 问题。而 `AtomicMarkableReference` 内部则维护了一个 `boolean` 类型的 `mark` 变量，它同对象引用一起原子性地更新，可以用来标识对象的状态等。

## 数组类型原子类

数组类型原子类也包括三种：`AtomicIntegerArray`、`AtomicLongArray`、`AtomicReferenceArray`，它们内部分别维护了一个 `int[]`、`long[]` 和 `Object[]` 类型的数组，对数组中每一个元素的读写操作都具备原子性。

## 字段更新原子类

字段更新原子类也包括三种：`AtomicIntegerFieldUpdater`、`AtomicLongFieldUpdater` 和 `AtomicReferenceFieldUpdater`，分别用于原子性更新对象的 `int`、`long` 和引用类型的字段。三者都要求被原子更新的字段被 `volatile` 修饰，因为它们三个都会在构造函数内检查被更新的字段是否被 `volatile` 修饰，如果被更新的字段不是 `volatible` 的，就会抛出异常。 

## 加法器

加法器有两种：`DoubleAdder` 和 `LongAdder`。二者都继承自 `Stripe64`，该类引入了分段累加的概念，内部有两个参数参与累加，其中一个是 `long` 类型的 `base`，另一个是 `Cell[]` 类型的 `cells`。其中，`base` 是在竞争不激烈的情况下使用的，累加结果会被直接改到它上面，而 `cells` 是在竞争激烈的情况下使用的，各个线程分散累加自己所对应的那个 `Cell`，这就降低了冲突的概率，提供了并发性。

加法器实现求和的关键在于 `sum()` 函数，它先加上 `base` 的值，然后再依次累加各个 `Cell` 中的值，最终得到总和。既然 `base` 和 `cells` 都定义在 `Stripe64` 中，那么 `DoubleAdder` 是如何实现 `double` 数据的求和的呢？答案在于在 Java 中，`double` 和 `long` 都占 8 个字节，二者在一定条件下可以互相表示。所以 `DoubleAdder` 在累加时调用了 `Double.doubleToRawLongBits(double value)` 计算出 `double` 变量的 `long` 值，求和时调用了 `longBitsToDouble(long bits)` 计算出 `long` 变量对应的 `double` 值。

加法器就像是基本类型原子类的微缩版本，前者主要负责执行加法，而后者还提供了更多高级的操作。在线程竞争没那么激烈的情况下，二者的吞吐量相差不大，而在线程竞争激烈的情况下，加法器求和的吞吐量就高得多了。不过，这更高的吞吐量是有代价的，那就是更多的空间消耗。

## 累加器

和加法器类似，累加器也有两种：`DoubleAccumulator` 和 `LongAccumulator`。累加器和加法器很相似，实际上，累加器是一个更加通用的加法器，它增强了加法器的功能，允许我们提供自定义的累加函数。

## 参考资料

1. [Atomic Variables](https://docs.oracle.com/javase/tutorial/essential/concurrency/atomicvars.html).