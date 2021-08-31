---
date: "2020-12-13T18:35:11+08:00"
title: "Java 线程池"
authors: ["zhannicholas"]
categories:
  - Java
tags:
  - Java
  - 并发
draft: false
toc: true
mathjax: true
---
线程池是管理一组同构工作线程的资源池，内部主要分为四部分：

* 线程池管理器：负责线程池的创建、销毁、添加任务等管理工作。
* 工作队列（Work Queue）：保存所有等待执行的任务。
* 工作者线程（Worker Thread）：从工作队列中取出一个任务并执行，然后返回线程池并等待下一个任务。
* 任务（Task）：实现了统一的接口，被工作者线程处理和执行。

与“为每个任务都创建一个线程”相比，使用线程池不仅可以平摊线程在创建和销毁过程中产生的巨大开销，还能提高程序的响应性（当请求到达时，工作线程通常已经存在，可以节省创建线程的时间）。通过调整线程池的大小，不仅可以创建足够多的线程以使 CPU 保持忙碌状态，还可以防止多线程相互竞争资源而使应用程序耗尽内存或失败。最后，线程池可以统一管理资源，方便我们对任务进行管理等。

## 设置线程池的大小

我们调整线程池大小的主要目的是为了充分利用 CPU 和内存等资源，从而最大限度地提高程序的性能。线程池的理想大小取决于被提交的任务的类型以及所部署系统的特性。通常不应该在代码中固定线程池的大小，而应该通过某种配置机制来提供，或者根据 `Runtime.getRuntime().availableProcessors()` 来获取可用处理器的数量之后动态计算。

如果线程池过大，那么大量的线程将在相对很少的 CPU 和内存资源上发生竞争，这不仅会导致更高的内存使用量，而且还可能耗尽资源。如果线程池过小，那么将导致许多空闲的处理器无法执行工作，从而降低吞吐率。

*Java Concurrency in Practice* 一书建议我们：对于计算密集型任务，在拥有 `N` 个处理器的系统上，当线程池的大小为 **`N+1`** 时，通常能实现最优的利用率（即使当计算密集型的线程偶尔由于缺页故障或者其他原因而暂停时，这个“额外”的线程也能确保 CPU 的时钟周期不被浪费）。对于包含I/O操作或其它阻塞操作的任务，由于线程并不会一直执行，因此线程池的规模应该更大。要正确的设置线程池的大小，必须估算出任务的等待时间与计算时间的比值。书中还给了我们另一个计算线程数的公式。

假设：

$$N_{cpu} = number\ of\ CPUs$$
$$U_{cpu} = target\ CPU\ utilization, 0\ \le \ U_{cpu} \le \ 1$$
$$\frac{W}{C} = ratio\ of\ wait\ time\ to\ compute\ time$$

若要使处理器达到期望的使用率，线程池的最有大小等于：

$$N_{threads} = N_{cpu} * U_{cpu} * (1 + \frac{W})$$

## 创建线程池

我们可以使用 `ThreadPoolExecutor` 来创建一个线程池：
```Java
public ThreadPoolExecutor(int corePoolSize,
                          int maximumPoolSize,
                          long keepAliveTime,
                          TimeUnit unit,
                          BlockingQueue<Runnable> workQueue,
                          ThreadFactory threadFactory,
                          RejectedExecutionHandler handler) {
    if (corePoolSize < 0 ||
        maximumPoolSize <= 0 ||
        maximumPoolSize < corePoolSize ||
        keepAliveTime < 0)
        throw new IllegalArgumentException();
    if (workQueue == null || threadFactory == null || handler == null)
        throw new NullPointerException();
    this.corePoolSize = corePoolSize;
    this.maximumPoolSize = maximumPoolSize;
    this.workQueue = workQueue;
    this.keepAliveTime = unit.toNanos(keepAliveTime);
    this.threadFactory = threadFactory;
    this.handler = handler;
}
```
`ThreadPoolExecutor` 的构造函数包含7个核心参数：
* `corePoolSize`：线程池的常驻核心线程数量。如果设置过小，可能导致频繁的创建和销毁线程，如果设置过大，又会造成系统资源的浪费，开发者应该根据实际业务场景来调整此值。
* `maximumPoolSize`：池内所允许的最大线程数量。
* `keepAliveTime`：当池内线程数量大于 `corePoolSize` 或当`allowCoreThreadTimeOut` 设置为 `true` 时，空闲线程在被销毁前的最大存活时间。
* `unit`：指定 `keepAliveTime` 参数的单位。
* `workQueue`：线程池执行的任务队列。当线程池中所有的线程都在处理任务时，新到来的任务就会在 `workQueue` 中排队等待执行。常用的任务队列有：有界队列 `ArrayBlockingQueue`、无界队列 `LinkedBlockingQueue` 和同步队列 `SynchronousQueue`（内部没有缓冲区）。
* `threadFactory`：执行器创建新线程时所使用的工厂，池中所有的线程都由它创建（通过 `addWorker()` 方法）。默认的线程工厂是 `DefaultThreadFactory`，它为线程指定了名字和优先级。我们可以通过实现 `ThreadFactory` 接口来实现更多自定义操作。
* `handler`：用来执行线程池的拒绝（饱和）策略。当 `workQueue` 满了并且线程池不能再创建线程来执行新提交的任务时，就会对新任务执行拒绝策略。拒绝策略其实是一种限流保护机制。

线程池的基本大小（corePoolSize）、最大大小（maximumPoolSize）以及存活时间（keepAliveTime）等因素共同负责线程的创建和销毁。基本大小也是线程池的目标大小，即在没有任务执行时线程池的大小，并且只有在工作队列满了的情况下才会创建超出这个数量的线程。线程池的最大大小表示可以同时活动的线程数量的上限。如果某个线程的空闲时间超过了存活时间，那么将被标记为可回收的，当线程池的当前大小超过了基本大小时，这个线程将被终止。

值得注意的是：在创建 `TreadPoolExecutor` 的初期，线程并不会立即启动，而是等到有任务提交时才会启动，除非调用 `prestartCoreThreads()`。

### 通过 Executors 快速创建线程池

Java类库中的 `Executors` 提供了不少创建线程池的静态工厂方法：
* `newFixedThreadPool()`。创建一个固定容量的线程池，每提交一个任务就创建一个线程，直到达到线程池的容量，这时线程池的规模将不再变化（在线程池关闭之前，若有线程因故终止，线程池将补充新的线程）。这种线程池一般适用于任务数量不均匀、对内存压力不敏感但对系统负载比较敏感的场景。
* `newCachedThreadPool()`。创建一个可缓存的线程池，如果线程池的当前规模超过了处理需求时，就回收空闲线程，而当需求增加时，就添加新的线程。它的特点在于线程池的规模几乎可以无限增加（实际上最大可以达到 `2^32 - 1`），非常适合用来执行要求低延迟的短期任务。
* `newSingleTreadExecutor()`。创建单个工作线程来执行任务，如果这个线程异常结束，则会创建另一个线程来替代。它能确保任务按照某种顺序串行执行（例如 FIFO、LIFO、优先级）。
* `newScheduledTreadPool()`。创建固定容量的线程池，并且以延迟或者定时任务的方式来执行任务，具体的实现主要有 3 种：
    
    ```java
    ScheduledExecutorService service = Executors.newScheduledThreadPool(10);
    
    service.schedule(new Task(), 10, TimeUnit.SECONDS);
    service.scheduleAtFixedRate(new Task(), 10, 10, TimeUnit.SECONDS);
    service.scheduleWithFixedDelay(new Task(), 10, 10, TimeUnit.SECONDS);
    ```
    * `schedule` 比较简单，表示延迟指定时间后执行一次任务，以上即 10 秒后执行一次任务就结束。
    * `scheduleAtFixedRate` 表示以固定频率执行任务，以上即表示第一次延迟 10 秒后每隔 10 秒执行一次任务。
    * `scheduleWithFixedDelay` 和第二种类似，区别在于对周期的定义。`sheculeAtFixedRate` 以任务开始的时间为起点计时，时间到就执行下一次任务，而不管任务执行要多久。而 `scheduleWithFixedDelay` 以任务结束时间为下一次循环的时间七点开始计时。
* `newSingleThreadScheduledExecutor()`。与 `newScheduledTreadPool()` 非常相似，它只是 `ScheduledThreadPool` 的一个特例，内部只有一个线程。
* `newWorkStealingPool()` 用于创建 `ForkJoinPool`。`ForkJoinPool` 也是线程池，但它与 `ThreadPoolExecutor` 有着很大不同。它非常适合用来执行可以产生子任务的任务（尤其是任务执行时长不均匀的场景），整个过程主要涉及两个步骤：首先是拆分任务（Fork）为子任务，然后是汇总（Join）子任务的结果得到任务的结果。此外，`ForkJoinPool` 的内部结构也与 `ThreadPoolExecutor` 大不相同：在 `ForkJoinPool` 中，每个线程都有自己独立的任务队列（是一个 Deque，用于存储分裂出来的子任务），而 `ThreadPoolExecutor` 中所有线程共用一个队列。

阿里巴巴的《Java开发手册》中为了规避资源耗尽的风险，禁止使用 `Executors` 类去创建线程池。这是因为 `Executors` 创建出来的线程池有一些弊端：

* `newFixedThreadPool()` 和 `newSingleThreadPool()` 创建出来的线程池允许的请求队列（`workQueue`）长度为 `Integer.MAX_VALUE`。如果线程池中任务的处理比较慢，那么随着请求的增多，队列中可能堆积大量的任务，进而占用大量内存，导致 OOM。
* `newCachedThreadPool()` 和 `newScheduledThreadPool()` 创建出来的线程池允许的线程的最大数量（`maximumPoolSize`）为 `Inteter.MAX_VALUE`，当任务数量特别多时，就可能导致大量的线程被创建，最终因超过操作系统的上限而无法再创建新线程，或者引发 OOM。

除了 `ForkJoinPool` 另外五种创建线程池的方法都可以认为是利用 `ThreadPoolExecutor` 来实现的，区别就在于传入的参数不同而已。

| 线程池                            | corePoolSize | maximumPoolSize   | keepAliveTime | workQueue--------|
| -------------------------------- | ------------ | ----------------- | ------------- | ------------------|
| newFixedThreadPool               | 构造函数传入 | 同 corePoolSize   | 0             | LinkedBlockingQueue |
| newCachedThreadPool              | 0            | Integer.MAX_VALUE | 60s           | SynchronousQueue |
| newSingleTreadExecutor           | 1            | 1                 | 0             | LinkedBlockingQueue |
| newScheduledTreadPool            | 构造函数传入 | Integer.MAX_VALUE | 0             | DelayedWorkQueue |
| newSingleThreadScheduledExecutor | 1            | Integer.MAX_VALUE | 0             | DelayedWorkQueue |

## 关闭线程池

我们可以通过调用线程池的 `shutdown()` 或 `shutdownNow()` 方法来关闭线程池。它们的原理一样：都是通过遍历线程池中的工作线程，然后调用线程的 `interrup()` 方法来中断线程，所以无法响应中断的任务可能永远无法终止。但它们之间存在一定的区别： `shutdown()` 方法将执行 **平缓** 的关闭过程：不再接受新任务，同时等待已经提交的任务执行完成（包括已提交但还未执行的任务）。`shutdownNow()` 方法将执行粗暴的关闭过程：尝试取消所有运行中的任务，并且不再启动队列中尚未开始执行的任务。等所有任务都完成后，线程池就转入 `Terminated(已终止)` 状态。

## Java线程池的复用原理

`ThreadPoolExecutor` 通过 `execute(Runnable command)` 方法来执行一个线程：
```Java
public void execute(Runnable command) {
    if (command == null)
        throw new NullPointerException();
    int c = ctl.get();
    if (workerCountOf(c) < corePoolSize) {
        if (addWorker(command, true))
            return;
        c = ctl.get();
    }
    if (isRunning(c) && workQueue.offer(command)) {
        int recheck = ctl.get();
        if (! isRunning(recheck) && remove(command))
            reject(command);
        else if (workerCountOf(recheck) == 0)
            addWorker(null, false);
    }
    else if (!addWorker(command, false))
        reject(command);
}
```
当提交一个新任务到线程池时，线程池的处理流程如下：

1. 如果线程池中正在执行的线程数少于线程池的基本大小（`corePoolSize`），则创建一个新的线程来执行任务。否则，进入下一步。
2. 尝试向往工作队列里加入一个线程，如果工作队列满了，进入下一步。
3. 尝试创建一个新线程来执行任务。如果失败，则采用给定的饱和策略来处理这个任务。

![](/images/java/concurrency/core-and-maximum-pool-size.png "线程创建的时机")

`execute()` 方法内部调用了 `addWorker(Runnable firstTask, boolean core)` 方法，它的参数说明如下：
* `firstTask`：线程应首先运行的任务，如果没有则可以设置为 `null`；
* `core`：判断是否可以创建线程数量的最大值，如果等于 `true` 则表示使用 `corePoolSize` 作为上限值创建 worker，`false` 则表示使用 `maximumPoolSize` 作为上限创建 worker。

## 拒绝策略

当线程池无法接收新的任务时，它会按照我们提供的拒绝策略来拒绝任务。通常有两种情况：

* 线程池内的工作已经饱和（即任务队列满了，运行中的线程数也达到了 `maximumPoolSize`），线程池没有能力继续处理新提交的任务
* 线程池被关闭（比如调用 `shutdown()` 方法）。即便此时线程池内部依然没有执行完成的任务正在执行，但线程池也不会接收任何新的任务

使用者可以通过调用 `ThreadPoolExecutor` 的 `setRejectedExecutionHandler(RejectedExecutionHandler handler)` 来修改其饱和策略。JDK 自带了几种不同的 `RejectedExecutionHandler` 实现，每种实现都对应着有不同的饱和策略：
* **`AbortPolicy`**：终止策略。这是默认的策略，该策略直接会抛出 `RejectedExecutionException`。调用者可以将其捕获，然后根据实际需求编写处理代码。
* **`DiscardPolicy`**：丢弃策略。新提交的任务被直接丢弃，调用者不会收到任何通知。这是有一定风险的，可能造成数据丢失。
* **`DiscardOldestPolicy`**：丢弃最老的任务。丢弃下一个将被执行的任务，然后尝试重新提交新的任务。这也存在数据丢失的风险。
* **`CallerRunsPolicy`**：由调用者执行。不丢弃任务，也不抛出异常，而是将任务退回给调用者。它不会在线程池中的某个线程中执行新提交的任务，而是在调用了`execute(Runnable command)`方法的线程（调用者线程）中继续执行该任务。这么做的好处是任务不会被丢弃，但是会减缓任务提交的速度，给了线程池一定的缓冲期。


## 参考资料
1. Brian Goetz, Tim Peierls, Joshua Bloch, Joseph Bowbeer, David Holmes, and Doug Lea. *Java Concurrency in Practice*. Addison-Wesley Professional, 2006.
2. 方腾飞, 魏鹏, 程晓明. Java并发编程的艺术. 机械工业出版社, 2015.