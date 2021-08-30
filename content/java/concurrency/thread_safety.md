---
date: "2021-04-27T20:38:39+08:00"
title: "线程安全性"
authors: ["zhannicholas"]
categories:
  - Java
tags:
  - 并发
draft: false
toc: true
---

我们在工作中经常听人提起线程安全，但线程安全似乎没有一个明确的定义。*Java Concurrency in Practice* 这本 Java 并发宝典是这样解释线程安全的：

> 当多个线程访问某个类时，这个类始终都能表现出正确的行为，那么就称这个类是线程安全的。线程安全性对多个线程之间的操作提出了要求：多个线程之间的操作无论采用何种执行时序或交替方式，都要保证不变性条件不被破坏。
>
> 若一个类既不包含任何域，也不包含任何对其它类中域的引用，则称这个类是无状态的。**无状态的对象一定是线程安全的**。

同时，本文的绝大部分内容也来自这本书。

## 线程安全问题

如果线程不安全，会导致哪些问题呢？常见的问题有三类：

1. 运行结果错误
2. 对象逃逸
3. 活跃性问题

### 运行结果错误

最常见线程安全问题可能就是 **运行结果错误** 了。比如：

```java
public class UnsafeCounter {
    private static volatile int count = 0;

    public static void main(String[] args) throws InterruptedException {
        Runnable r = () -> {
            for (int i = 0; i < 1000; i++) {
                count++;
            }
        };

        Thread t1 = new Thread(r);
        t1.start();
        Thread t2 = new Thread(r);
        t2.start();
        // 等待两个线程运行结束
        t1.join();
        t2.join();
        System.out.println("count = " + count);
    }
}
```

这段代码定义了一个静态变量 `count`，然后启动两个线程，每个线程都对这个变量执行 1000 次递增操作。理论上，我们最终应该得到的 count 值为 2000，但实际上结果可能是 1662，也可能是 1713，每次运行的结果都还不一样。出问题的原因在于：`count++` 不是一个原子操作，它的执行步骤主要分为三步：

1. 读取 count 的值
2. 将 count 的值加一
3. 保存 count 的值

由于 CPU 是以时间片为单位进行线程调度的，每个线程都可以在给定时间片内使用 CPU，若时间片已经用完，操作系统就会暂停当前线程，然后把 CPU 分配给其它线程，当其它线程用完之后，被暂停的线程又会得到使用 CPU 的机会。在 `count++` 的三个步骤中，每一步操作都有可能被打断。这就是 **原子性问题**。虽然变量 `count` 被 `volatile` 修饰，但由于 `volatile` 只能保证可见性，并不能保证原子性，所以运行结果还是有问题的。

### 对象逃逸

#### 对象发布

**“发布”一个对象意味着使该对象能够被当前作用域以外的代码使用**。例如：将一个指向某一对象的引用保存到其它代码可以访问的地方，或者某一个非私有的方法中返回该引用，或者将该引用传递到其它类的方法中。

发布对象的最简单方法就是将对象的引用保存到一个公有的静态变量中。当发布一个对象时，该对象的非私有域中引用的所有对象也会被发布。还有一种发布对象或其内部状态的方法就是：发布一个内部类的实例。

#### 对象逃逸

逃逸”是指某个不应该被发布的对象被发布出去了。下面是一个例子：

```java
public class WrongInit {
    private Map<String, String> colorMap;

    public WrongInit() {
        new Thread(() -> {
            colorMap = new HashMap<>();
            colorMap.put("RED", "红");
            colorMap.put("ORANGE", "橙");
            colorMap.put("YELLOW", "黄");
            // ...
        }).start();
    }

    public Map<String, String> getColorMap() {
        return colorMap;
    }

    public static void main(String[] args) {
        WrongInit wrongInit = new WrongInit();
        System.out.println(wrongInit.getColorMap().get("RED"));
    }
}
```

这段代码并不会输出 `红`，而是会抛出 `NullPointerException`。这是因为 `colorMap` 的初始化放在了构造函数内的新线程中，而线程的启动是需要一定的时间的，但是主函数并没有等待就直接获取数据，这个时候 `colorMap` 可能并没有初始化好。

正常情况下，`colorMap` 应该在构造函数内被初始化好了才可让外界访问，以上代码就出现了 `colorMap` 的逃逸。对象逃逸会带来问题，因为：**只有当对象的构造函数返回时，对象才处于可预测的（predictable）、一致的（consistent）状态**。在错误的时间或地点发布或初始化可能导致线程安全问题。

### 活跃性问题

在线程的安全性和活跃性之间通常存在着某种制衡。我们使用加锁机制来确保线程安全，但如果过度的使用加锁，则可能导致 **顺序死锁（Lock-ordering Deadlock）**。同样，我们使用线程池和信号量来限制对资源的使用，但这些限制行为可能导致 **资源死锁（Resource Deadlock）**。Java 应用程序无法从死锁中恢复过来（恢复应用程序的唯一方式就是终止并重启它，并希望它不要再发生），因此在设计时一定要排除那些可能导致死锁出现的条件。

活跃性问题与前面提到的运行结果错误有着很大不同，当出现活跃性问题时，程序可能始终都得不到结果。常见的活跃性问题有三种，分别是：死锁、饥饿和活锁。

#### 死锁

**死锁（Deadlock）** 是指两个线程之间相互等待对方占有的资源（锁），但同时又互不相让，都想自己先执行。

##### 顺序死锁

以下代码可能导致顺序死锁：

```java
public class LeftRightDeadLock {
    private final Object left = new Object();
    private final Object right = new Object();

    public void leftRight() {
        synchronized (left) {
            synchronized (right) {
                // doSomething();
            }
        }
    }

    public void rightLeft() {
        synchronized (right) {
            synchronized (left) {
                // doSomethingElse();
            }
        }
    }

    public static void main(String[] args) {
        LeftRightDeadLock lrdl = new LeftRightDeadLock();
        new Thread(lrdl::leftRight).start();
        new Thread(lrdl::rightLeft).start();
    }
}
```

如下图所示：线程 A 调用的方法会尝试先获得 left 的锁再尝试获得 right 的锁，而线程 B 刚好相反，并且这两个线程的操作是交替执行，那么它们就会发生死锁。

![](/images/java/concurrency/unlucky-timing-in-leftRightDeadLock.png "顺序死锁")

以上发生死锁的原因是：两个线程试图以不同的顺序获得相同的锁。如果彼此按照相同的顺序来请求锁，那么就不会出现循环的加锁依赖性，也就不会产生死锁。换句话说：如果每个需要锁 L 和 M 的线程都以 **相同的顺序** 来获取锁 L 和 M ，就不会发生死锁。

##### 资源死锁

正如当多个线程相互持有彼此正在等待的锁而又不释放自己持有的锁时会发生死锁一样，当它们发生在相同的资源集合上等待时，也会发生死锁。

假设有两个资源池 L 和 M ，若在线程 A 持有 L 中的 S 并等待 M 中的 T 的同时，线程 B 持有 M 中的 T 并等待 L 中的 S ，则会出现死锁。这有点类似于顺序死锁中提到的交替执行导致死锁出现的情况。

另一种基于资源的死锁形式就是线程饥饿死锁（Thread-Starvation Deadlock）：只要资源池中的任务需要无限等待一些必须由池中的其它任务才能提供的资源或条件（例如一个任务等待另一个任务的执行结果），那么除非资源池足够大，否则将发生线程饥饿死锁。

例如：在单线程的 Executor 中，如果一个任务将另一个任务提交到同一个 Executor，并且等待这个被提交的任务的执行结果，那么通常会引发死锁。因为第二个任务将停留在工作队列中，并等待第一个任务完成，而第一个任务又无法完成，因为它在等待第二个任务的完成。这就是线程饥饿死锁。


#### 饥饿

**饥饿（Starvation）** 是指线程由于无法访问它所需要的资源而不能继续执行。比如，Java 应用程序对线程的优先级设置不当，导致部分线程无法获取 CPU 时间片。Java 中的线程是有优先级的。Java 中线程优先级分为 1 到 10，1 最低，10 最高，优先级越高的线程获得 CPU 时间片的概率越大。如果我们把某个线程的优先级设置为 1，这是最低的优先级，在这种情况下，这个线程就有可能始终分配不到 CPU 资源，而导致长时间无法运行。

#### 活锁

**活锁（Livelock）** 不会阻塞线程，但也不能继续执行，因为线程将不断重复执行相同的操作，而且总会失败。这就像两个过于礼貌的人在半路上面对面地相遇：他们彼此都给对方让路，然后又在另一条路上相遇了，并且他们就这样反复地避让下去。可以在重试机制中引入随机性来解决活跃性问题，这样能减少冲突。


## 线程安全问题出现的场景

线程安全问题最常出现在对共享变量或共享资源的访问中。前面提到的计数问题就是一个典型的例子。

有时，我们的操作是依赖时序的，而并发场景下可能出现执行顺序与我们预想不一致的情况。比如：

```java
if (x == 1) {
    x = 3 * x;
}
```

这段代码涉及先检查后计算的组合操作。但这个组合操作并不是原子操作，中间可能被打断。

我们使用其他类时，如果对方没有声明自己是线程安全的，那么这种情况下对其进行并发操作，就有可能会出现线程安全问题。

## 参考资料
1. Brian Goetz, Tim Peierls, Joshua Bloch, Joseph Bowbeer, David Holmes, and Doug Lea. *Java Concurrency in Practice*. Addison-Wesley Professional, 2006.