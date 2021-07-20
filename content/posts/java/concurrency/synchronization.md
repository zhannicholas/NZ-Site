---
date: "2020-12-13T18:31:16+08:00"
title: "同步"
authors: ["zhannicholas"]
categories:
  - Java
tags:
  - Java
  - 并发
draft: false
toc: true
---
Java语言提供了多种线程间通信机制（同步、while轮询、等待/通知、管道等等），其中最基础的通信方式就是 **同步（synchronization）**。Java中的同步是通过`monitor`来实现的，每个Java对象都有一个与之相关联的`monitor`，线程可以在其上进行加锁和释放锁的操作。同一时刻只能有一个线程持有某个`monitor`的锁，任何其它尝试给该`monitor`加锁的线程在获得锁之前都会被阻塞。一个线程可以多次给某个`monitor`加锁，这就是锁的重入，多次加锁对应着多次解锁，因为每次`unlock`操作只会消除一次`lock`的效应。

## `Synchronized` 关键字

Java提供了一种内置的锁机制来支持原子性：同步代码块(Synchronized Block)。同步代码块就是用 `synchronized` 关键字修饰的代码块，它包括两个部分：作为锁的对象引用和由这个锁保护的代码块。

用关键字 `synchronized` 修饰的方法是一种横跨整个方法体的同步代码块，其中该同步代码块的锁就是和该方法相关的对象（方法执行期间 `this` 关键字所代表的对象）。静态 `synchronized` 方法以 `Class` 对象为锁：
```Java
static synchronized void staticMethod() {
	// do something
}
```
以下是以 `lock` 对象为锁：
```Java
synchronized（lock）{
	// 访问或修改由所保护的共享状态
}
```
而以下是以调用同步方法的<u>实例本身</u>为锁：
```Java
synchronized void instanceMethod() {
	// do somehing ...
}
```

同步代码块是可重入的。

## Java对象头

*[The Java® Virtual Machine Specification (Java SE 11 Edition)](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-2.html#jvms-2.5)* 本身并没有规定程序运行时对象的具体内存布局，因此在不同的虚拟机实现中，对象和数组的内存布局可能有所不同。下面主要关注 HotSpot VM 这一 JVM 实现。

HotSpot VM 使用了一种名为 **[OOPs(Ordinary Object Pointers)](https://github.com/openjdk/jdk11/blob/master/src/hotspot/share/oops)** 的数据结构表示指向对象的指针。虚拟机使用 [oopDesc](https://github.com/openjdk/jdk11/blob/master/src/hotspot/share/oops/oop.hpp#L55) 这个特殊的数据结构来描述所有的指针（包括对象和数组）。每个 oopDesc 都包含以下信息：

* [mark word](https://github.com/openjdk/jdk11/blob/master/src/hotspot/share/oops/markOop.hpp)。这一类用于存储对象自身的运行时数据，比如 HashCode、GC 分代年龄、锁状态标志、线程持有的锁、偏向线程 ID、偏向时间戳等，<u>在运行期间，Mark Work 里面存储的数据会随着锁标志的变化而变化</u>。
* [klass word](https://github.com/openjdk/jdk11/blob/master/src/hotspot/share/oops/klass.hpp)。这一部分主要包含的是语言级别的类信息（比如类名、修饰符、父类信息等），即类型的元数据，Java 通过这个指针确定对象是哪个类的实例。该部分可能被压缩。

对于 Java 对象（用 [instanceOop](https://github.com/openjdk/jdk11/blob/master/src/hotspot/share/oops/instanceOop.hpp) 表示）而言，对象头包括 mark word、klass word，可能还有对齐填充。

对于 Java 数组（用 [arrayOop](https://github.com/openjdk/jdk11/blob/master/src/hotspot/share/oops/arrayOop.hpp) 表示）而言，对象头包括 mark word、klass word、` sizeof(int)` 大小（一般为 4 字节）的数组长度，可能还有对齐填充。数组的对象头中还必须有一块用于记录数组长度的数据，因为 JVM 可以通过普通 Java 对象的元数据信息确定 Java 对象的大小，但是数组的长度是不确定的。

## 锁的状态级升级过程

锁一共有4种状态，级别从低到高分别是：无锁、偏向锁、轻量级锁和重量级锁。<u>锁的状态只支持升级，不支持降级</u>。

以下是锁的四种状态下 markd word 的简要内容：

| 锁状态   | 存储内容                                            | 最后两位（锁标志） |
| -------- | --------------------------------------------------- | ------------------ |
| 无锁     | hashCode、GC分代年龄、是否偏向锁（0）               | 01                 |
| 偏向锁   | 偏向线程ID、偏向时间戳、GC分代年龄、是否偏向锁（1） | 01                 |
| 轻量级锁 | 指向栈中锁记录的指针                                | 00                 |
| 重量级锁 | 指向互斥量（重量级锁）的指针                        | 10                 |

mark word 的具体细节可以查看 [OpenJDK 源码](https://github.com/openjdk/jdk11/blob/master/src/hotspot/share/oops/markOop.hpp#L35)，32 位和 64 位模式下存储的内容是不一样的。
### 无锁

不对资源进行锁定，所有的线程都能访问并修改共享资源，但每次只有一个线程能修改成功。

在无锁状态下，线程会不断尝试修改共享资源。如果没有冲突，就修改成功并退出，否则
继续循环尝试直到修改成功。

### 偏向锁

大多数情况下，锁不仅不存在竞争，而且总是被同一个线程多次获得。偏向锁就是指同一个同步代码块一直被一个线程访问，那么该线程就会自动能够获取锁，这能降低获取锁的代价。

当一个线程访问同步代码块并获取锁时，会在对象头和栈帧的锁记录里面存储偏向的线程ID，以后该线程在进入和退出同步代码块时不需要进行CAS操作来加锁和解锁，只需要简单的检测一下对象头的Mark Word里是否存储着指向当前线程的偏向锁。如果测试成功，表示线程已经获得了锁，否者则需要再检测Mark Word中偏向锁的标识是否为1（如果未设置，则使用CAS竞争锁，否则尝试使用CAS将对象头的偏向锁指向当前线程）。

偏向锁使用了一种等到竞争出现才释放锁的机制，所以当其它线程尝试竞争偏向锁时，持有偏向锁的线程才会释放锁。偏向锁的撤销需要等到全局安全点（这个时间点上没有正在执行的字节码）上才能进行。它会先暂停拥有偏向锁的线程，判断锁对象是否处于被锁定的状态。撤销偏向锁后恢复到无锁或轻量级锁状态。

由于难以维护，Java 15 已经准备[弃用偏向锁](https://openjdk.java.net/jeps/374)了。

### 轻量级锁

当偏向锁被其它线程访问时，偏向锁就会升级为轻量级锁，其它线程会通过自旋的方式尝试获取锁，不会阻塞。

当线程进入同步代码块时，若同步对象的锁状态为无锁状态，JVM 会再当前线程的栈帧中建立一个名为 Lock Record 的空间，用于存储对象目前的 Mark Word 的副本，然后将对象头中的 Mark Word 复制进去。复制成功后，JVM 会使用 CAS 操作尝试将对象的 Mark Word 更新为指向 Lock Record 的指针，并将 Lock Record 里的 owner 指针指向对象的 Mark Word。如果更新成功，该线程就获得了锁，对象头中的 Mark Word 会被设置为 **`00`**，表示此对象处于轻量级锁状态。若更新失败，JVM 会检查对象头的 Mark Word 是否指向当前线程的栈帧，如果是就说明当前线程已经拥有锁，就直接进入同步代码块继续执行，否则说明有多个线程在竞争该锁。

若当前只有一个等待线程，则该等待线程会以自旋的方式进行等待。当自旋超过一定次数，或者一个线程持有锁，一个线程在自旋，第三个线程又来访问时，轻量级锁会升级为重量级锁。

### 重量级锁

当锁升级为重量级锁时，Mark Word存 储的时指向重量级锁的指针，等待的线程会进入阻塞状态。

### 锁升级小结

偏向锁通过比对 Mark Word 来解决加锁问题，避免 CAS 操作；轻量级锁通过 CAS 操作和自旋解决加锁问题，避免线程阻塞和唤醒带来的性能损耗；重量级锁阻塞拥有锁的线程以外的所有线程。

## 从JVM视角看同步

JVM中的同步操作是通过 `monitor` 的进入与退出来实现的。其实现方式又可分为显式（通过使用 `monitorenter` 和 `monitorexit` 指令）和隐式（通过方法的调用与返回指令）两种。根据被修饰的代码块的形式不同，`synchronized` 关键字的使用可以分为两种情况：同步方法（`synchronized` 修饰的是静态方法或实例方法）和同步语句（`synchronized` 修饰的是一个代码块）。

### 同步方法

方法级别的同步操作是隐式实现的，不涉及 `monitorenter` 和 `monitorexit` 指令的使用，同步就是方法调用与返回的一部分。在运行时常量池中的 `method_info` 结构中，有一个叫做 `ACC_SYNCHRONIZED` 的标志位。方法调用指令会去检查这个标志位，当一个设置了 `ACC_SYNCHRONIZED` 的方法被调用时，执行线程会先进入 `monitor`，然后调用方法本身，最后不管方法是否正常执行完成都会退出 `monitor`。在执行线程拥有 `monitor` 的时间段内，其它线程是不可能再进入该 `monitor` 的。

### 同步代码块
下面是取自 JVM 11 规范中给出的一个例子。同步代码块
```java
void onlyMe(Foo f) {
    synchronized(f) {
        doSomething();
    }
}
```
会被编译成以下字节码：

```class
Method void onlyMe(Foo)
0   aload_1             // Push f
1   dup                 // Duplicate it on the stack
2   astore_2            // Store duplicate in local variable 2
3   monitorenter        // Enter the monitor associated with f
4   aload_0             // Holding the monitor, pass this and...
5   invokevirtual #5    // ...call Example.doSomething()V
8   aload_2             // Push local variable 2 (f)
9   monitorexit         // Exit the monitor associated with f
10  goto 18             // Complete the method normally
13  astore_3            // In case of any throw, end up here
14  aload_2             // Push local variable 2 (f)
15  monitorexit         // Be sure to exit the monitor!
16  aload_3             // Push thrown value...
17  athrow              // ...and rethrow value to the invoker
18  return              // Return in the normal case
Exception table:
From    To      Target      Type
4       10      13          any
13      16      13          any
```
不管方法正常退出还是异常退出，编译器都会确保每条 `monitorenter` 指令都有一条对应的 `monitorexit` 被执行。

## 参考资料
1. 方腾飞, 魏鹏, 程晓明. Java并发编程的艺术. 机械工业出版社, 2015.
2. 美团技术团队. [不可不说的Java“锁”事](https://tech.meituan.com/2018/11/15/java-lock.html).
3. [Intrinsic Locks and Synchronization](https://docs.oracle.com/javase/tutorial/essential/concurrency/locksync.html).
4. [The Java® Virtual Machine Specification (Java SE 11 Edition)](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-3.html#jvms-3.14).
5. [Memory Layout of Objects in Java](https://www.baeldung.com/java-memory-layout).