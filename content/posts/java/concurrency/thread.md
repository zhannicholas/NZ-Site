---
date: "2020-12-13T18:32:20+08:00"
title: "线程"
authors: ["zhannicholas"]
categories:
  - Java
tags:
  - Java
  - 并发
draft: false
toc: true
---
进程（process）是资源分配的基本单元，而线程（thread）是程序执行的基本单元。一个进程可以包含多个线程，多个线程之间共享进程的资源。和进程相比，线程更加轻量化，所以线程又叫*轻量级进程*。

## 创建一个新线程的方法

网上好多资料都说有三种创建线程的方式：

1. 继承`Thread`类，重写`run()`方法。
2. 实现`Runnable`接口。
3. 实现`Callable`接口。

但本质上只有一种创建线程的方式，那就是构造一个 `Thread` 类。为什么这么说呢？我们来看上面几种方式的实际使用情况：

### 继承 Thread 类

```java
public class ExtendsThread extends Thread {
    @Override
    public void run() {
        System.out.println("通过继承 Thread 类来实现线程");
    }
}
```

通过继承 Thread 类来实现线程最大的缺点就是代码未来的可扩展性被限制。Java 是不支持多继承的，我们的类一旦继承了 Thread 类，那么后续就没有其它办法再继承其它类了。

### 实现 Runnable 接口

```java
class RunnableThread implements Runnable {
    @Override
    public void run() {
        System.out.println("通过实现 Runnable 接口来实现线程");
}
```

`Thread` 本身也实现了 `Runnable` 接口。

### 实现 Callable 接口

```java
class CallableTask implements Callable<Long> {
    @Override
    public Long call() throws Exception {
        System.out.println("通过实现 Callable 接口来实现线程");
        return System.currentTimeMillis();
    }
}

Executors.newSingleThreadExecutor().submit(new CallableTask());
```

实现 `Callable` 接口与实现 `Runnable` 接口最大的区别在于前者是有返回值的，而后者是无返回值的。

> The Callable interface is similar to Runnable, in that both are designed for classes whose instances are potentially executed by another thread. A Runnable, however, does not return a result and cannot throw a checked exception.

但是，不管是 `Runnable` 还是 `Callable`，它们都表示被线程执行的任务，它们本身并不是线程。接口的不同实现意味着线程运行时执行的内容不同而已。

说到创建线程，我们可能还会想到线程池。是的，线程池也可以创建线程，但最终的线程还是通过 `new Thread()` 创建出来的。这个你看了 `DefaultThreadFactory` 的源码就知道了：

```java
private static class DefaultThreadFactory implements ThreadFactory {
    private static final AtomicInteger poolNumber = new AtomicInteger(1);
    private final ThreadGroup group;
    private final AtomicInteger threadNumber = new AtomicInteger(1);
    private final String namePrefix;

    DefaultThreadFactory() {
        SecurityManager s = System.getSecurityManager();
        group = (s != null) ? s.getThreadGroup() :
                                Thread.currentThread().getThreadGroup();
        namePrefix = "pool-" +
                        poolNumber.getAndIncrement() +
                        "-thread-";
    }

    public Thread newThread(Runnable r) {
        Thread t = new Thread(group, r,
                                namePrefix + threadNumber.getAndIncrement(),
                                0);
        if (t.isDaemon())
            t.setDaemon(false);
        if (t.getPriority() != Thread.NORM_PRIORITY)
            t.setPriority(Thread.NORM_PRIORITY);
        return t;
    }
}
```

## 线程的启动与停止

### 线程的启动

线程的启动很简单，调用 `Thread` 类的 `start()` 方法即可。`start()` 方法最终会调用 `Runnable` 的 `run()` 方法来执行任务。

```java
/**
* If this thread was constructed using a separate
* {@code Runnable} run object, then that
* {@code Runnable} object's {@code run} method is called;
* otherwise, this method does nothing and returns.
* <p>
* Subclasses of {@code Thread} should override this method.
*
* @see     #start()
* @see     #stop()
* @see     #Thread(ThreadGroup, Runnable, String)
*/
@Override
public void run() {
    if (target != null) {
        target.run();
    }
}
```

那么，`start()` 与 `run()` 有何不同呢？首先，`run()` 方法是通过实现 `Runnable` 接口得来的，而 `start()` 是 `Thread` 类自身的一个方法，用于启动当前线程：

```java
/**
* Causes this thread to begin execution; the Java Virtual Machine
* calls the {@code run} method of this thread.
* <p>
* The result is that two threads are running concurrently: the
* current thread (which returns from the call to the
* {@code start} method) and the other thread (which executes its
* {@code run} method).
* <p>
* It is never legal to start a thread more than once.
* In particular, a thread may not be restarted once it has completed
* execution.
*
* @throws     IllegalThreadStateException  if the thread was already started.
* @see        #run()
* @see        #stop()
*/
public synchronized void start() {
    /**
    * This method is not invoked for the main method thread or "system"
    * group threads created/set up by the VM. Any new functionality added
    * to this method in the future may have to also be added to the VM.
    *
    * A zero status value corresponds to state "NEW".
    */
    if (threadStatus != 0)
        throw new IllegalThreadStateException();

    /* Notify the group that this thread is about to be started
    * so that it can be added to the group's list of threads
    * and the group's unstarted count can be decremented. */
    group.add(this);

    boolean started = false;
    try {
        start0();
        started = true;
    } finally {
        try {
            if (!started) {
                group.threadStartFailed(this);
            }
        } catch (Throwable ignore) {
            /* do nothing. If start0 threw a Throwable then
            it will be passed up the call stack */
        }
    }
}
```

另外，`start()` 方法通过 `synchronized` 来保证线程安全，并且只能调用一次，还会影响线程的状态（由NEW变为RUNNABLE），而`run()`只是一个普通方法，可以被多次调用，并且不会改变线程的状态。

### 停止线程

通常，我们不会手动停止一个线程，而是让线程运行到结束，自然停止。但是有许多特殊的情况需要我们提前停止线程，比如：用户突然关闭程序，或程序运行出错重启等。

#### 被弃用的方法

Java 在 `Thread` 类中提供了 `stop()` 方法，用于强行停止当前线程。但这个方法自 JDK1.2 开始就被标记为 `@Deprecated`，一同被标记的还有 `suspend()` 和 `resume()` 方法。为什么不再推荐使用它们了呢？因为 `stop()` 会直接停止当前线程，这样线程就没有足够的时间来处理停止前需要完成的工作，导致数据的完整性等问题。而 `suspend()` 和 `resume()` 的问题在于：调用 `suspend()` 的线程不释放锁就直接进入休眠，这可能导致死锁，因为如果线程在休眠期间持有锁的话，这把锁在线程被 `resume()` 之前是不会被释放的。

来看一个具体的例子：假设线程 A 调用 `suspend()` 让线程 B 挂起，线程 B 进入休眠，而线程 B 刚好持有锁 L。假设此时线程 A 想要访问线程 B 持有的锁 L，由于线程 B 没释放锁 L 就休眠了，所以线程 A 是拿不到锁 L 的，它就会陷入阻塞。这样一来，线程 A 和线程 B 都无法继续向下执行。

Java SE 的 API 文档里面其实也给出了这三个方法被弃用的原因（[ Why are Thread.stop, Thread.suspend and Thread.resume Deprecated?](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/lang/doc-files/threadPrimitiveDeprecation.html)），并给出了相关的替代方案。
#### 使用状态标记

对于大多数情况，JDK 建议我们使用一个状态变量来指示目标线程是否应该停止运行。目标线程周期性地检查这个状态变量的值，当状态变量暗示要停止目标线程时，就从 `run()` 方法返回。为了确保停止请求的及时传播，这个状态变量应该是 `volatile` 修饰的，或者对该变量的访问进行同步处理。

```java
private volatile Thread blinker;

public void stop() {
    blinker = null;
}

public void run() {
    Thread thisThread = Thread.currentThread();
    while (blinker == thisThread) {
        try {
            Thread.sleep(interval);
        } catch (InterruptedException e){
        }
        repaint();
    }
}
```

然而，并不是仅仅使用 `volatile` 标记状态变量就完事儿，我们还得倍加小心。下面是网上的一个例子：

```java
public class VolatileCannotStop {
    // 生产者
    static class Producer implements Runnable {
        public volatile  boolean canceled = false;
        private BlockingQueue<Integer> storage;
        public Producer(BlockingQueue<Integer> storage) {
            this.storage = storage;
        }

        @Override
        public void run() {
            int num = 0;
            try {
                while (num <= 100000 && !canceled) {
                    if (num % 50 == 0) {
                        storage.put(num);   // 阻塞操作
                        System.out.println(num + "是50的倍数，放入仓库");
                    }
                    num++;
                }
            } catch (InterruptedException e) {
                e.printStackTrace();
            } finally {
                System.out.println("生产者结束运行");
            }
        }
    }

    // 消费者
    static class Consumer {
        BlockingQueue storage;
        public Consumer(BlockingQueue storage) {
            this.storage = storage;
        }

        public boolean needMoreNums() {
            return Math.random() > 0.97;
        }
    }

    public static void main(String[] args) throws InterruptedException {
        BlockingQueue storage = new ArrayBlockingQueue(8);

        Producer producer = new Producer(storage);
        new Thread(producer).start();
        Thread.sleep(500);

        Consumer consumer = new Consumer(storage);
        while (consumer.needMoreNums()) {
            System.out.println(consumer.storage.take() + "被消费了");
            Thread.sleep(100);  // 这段时间内消费者又可以将 storage 塞满，然后阻塞
        }
        System.out.println("消费者不需要更多数据了");

        // 一旦消费者不需要更多数据了，我们就应该让生产者停下来，然而实际情况却是生产者停不下类
        producer.canceled = true;
        System.out.println(producer.canceled);
    }
}
```

直接来看 `main()` 方法，首先创建了生产者/消费者共用的仓库 `BlockingQueue storage`，仓库容量是 8，然后创建生产者并启动生产者线程，紧接着主线程进行 500 毫秒的休眠，保障生产者有足够的时间把仓库塞满，仓库被塞满后生产者就会阻塞，500 毫秒后消费者也被创建出来，并判断是否需要使用更多的数字，然后每次消费后休眠 100 毫秒，这样的业务逻辑是有可能出现在实际生产中的。

当消费者不再需要数据，就会将 `canceled` 的标记位设置为 true，理论上此时生产者会跳出 `while` 循环，并打印输出“生产者运行结束”。然而结果却不是我们想象的那样，尽管已经把 `canceled` 设置成 true，但生产者仍然没有停止，这是因为在这种情况下，生产者在执行 `storage.put(num)` 时发生阻塞，在它被叫醒之前是没有办法进入下一次循环判断 `canceled` 的值的，所以在这种情况下用 `volatile` 是没有办法让生产者停下来的。在这种情况下，应该使用 `interrupt()` 来中断，即使生产者处于阻塞状态，仍然能够感受到中断信号，并做响应处理。

#### 使用 interrupt

对于 Java 而言，最正确的停止线程的方式是使用 `interrupt()`。但 `interrupt()` 仅仅起到通知被停止线程的作用。而对于被停止的线程而言，它拥有完全的自主权，可以选择立即停止，也可以选择一段时间后停止，甚至可以选择压根不停止。不采用强制停止的做法的原因是：贸然强行停止线程可能造成一些安全问题，若要避免这些问题，就需要给目标线程一些时间进行收尾工作。

```java
while (!Thread.currentThread().isInterrupted() && has more work to do) {
    do more work
}
```

调用某个线程的 `interrupt()` 方法之后，这个线程的中断标记位就会被设置成 true。每个线程都有这样的标记位，当线程执行时，应该定期检查这个标记位，如果标记位被设置成 true，就说明有程序想终止该线程。下面是一个具体的例子：

```java
public class StopThread {
    public static void main(String[] args) throws InterruptedException {
        Thread t = new Thread(new Runnable() {
            @Override
            public void run() {
                int count = 0;
                while (!Thread.currentThread().isInterrupted() && count < 1000) {
                    System.out.println("count = " + (count++));
                }
            }
        });
        t.start();
        Thread.sleep(5);
        t.interrupt();
    }
}
```

程序还没打印完 1000 个数就会停下来，因为对应的线程被 `interrupt` 了。

休眠中的线程是可以感受到中断信号的，并且被中断的线程会抛出一个 `InterruptedException` 异常，同时清除中断信号，将中断标记位设置成 false。

## 线程的状态
Java线程在其生命周期中可能处于6种状态（这6中状态指的线程在JVM中的状态，并不是操作系统中线程的状态），在一个特定的时刻，线程只能处于其中的一个状态。

| 状态          | 说明                                                         |
| ------------- | ------------------------------------------------------------ |
| NEW           | A thread that has not yet started is in this state.          |
| RUNNABLE      | A thread executing in the Java virtual machine is in this state.             |
| BLOCKED       | A thread that is blocked waiting for a monitor lock is in this state.  |
| WAITING       | A thread that is waiting indefinitely for another thread to perform a particular action is in this state. |
| TIMED_WAITING | A thread that is waiting for another thread to perform an action for up to a specified waiting time is in this state. |
| TERMINATED    | A thread that has exited is in this state.                           |

```java
public enum State {
    /**
        * Thread state for a thread which has not yet started.
        */
    NEW,

    /**
        * Thread state for a runnable thread.  A thread in the runnable
        * state is executing in the Java virtual machine but it may
        * be waiting for other resources from the operating system
        * such as processor.
        */
    RUNNABLE,

    /**
        * Thread state for a thread blocked waiting for a monitor lock.
        * A thread in the blocked state is waiting for a monitor lock
        * to enter a synchronized block/method or
        * reenter a synchronized block/method after calling
        * {@link Object#wait() Object.wait}.
        */
    BLOCKED,

    /**
        * Thread state for a waiting thread.
        * A thread is in the waiting state due to calling one of the
        * following methods:
        * <ul>
        *   <li>{@link Object#wait() Object.wait} with no timeout</li>
        *   <li>{@link #join() Thread.join} with no timeout</li>
        *   <li>{@link LockSupport#park() LockSupport.park}</li>
        * </ul>
        *
        * <p>A thread in the waiting state is waiting for another thread to
        * perform a particular action.
        *
        * For example, a thread that has called {@code Object.wait()}
        * on an object is waiting for another thread to call
        * {@code Object.notify()} or {@code Object.notifyAll()} on
        * that object. A thread that has called {@code Thread.join()}
        * is waiting for a specified thread to terminate.
        */
    WAITING,

    /**
        * Thread state for a waiting thread with a specified waiting time.
        * A thread is in the timed waiting state due to calling one of
        * the following methods with a specified positive waiting time:
        * <ul>
        *   <li>{@link #sleep Thread.sleep}</li>
        *   <li>{@link Object#wait(long) Object.wait} with timeout</li>
        *   <li>{@link #join(long) Thread.join} with timeout</li>
        *   <li>{@link LockSupport#parkNanos LockSupport.parkNanos}</li>
        *   <li>{@link LockSupport#parkUntil LockSupport.parkUntil}</li>
        * </ul>
        */
    TIMED_WAITING,

    /**
        * Thread state for a terminated thread.
        * The thread has completed execution.
        */
    TERMINATED;
}

```

以下是线程之间的状态迁移图：

![Java thread state transfering](/images/java/concurrency/thread-state-transfering-diagram.png)


## 实现多线程同步的方法
Java主要提供了3中实现同步机制的方法：

1. 使用`synchronized`关键字。见[`Synchronized`关键字](./Synchronized.md)。
2. 使用`wait()`与`notify()`方法。
3. 使用`Lock`。见[Locks](./Locks.md)。

## Java中的原子操作
在Java中可以通过锁和循环CAS的方式实现原子操作。

JVM中的CAS操作是利用处理器提供的 **`COMPXCHG`**指令实现的。自旋CAS实现的基本思路是循环进行CAS操作直到成功为止。但CAS存在三个问题：
* **ABA问题**。可以使用版本号来解决。
* **循环时间长开销大**。这一般出现在自旋CAS长时间不成功的情况下。
* **只能保证一个共享变量的原子操作**。对于多个共享变量的原子操作，一般采用锁来解决，也可以将多个共享变量封装进一个对象，然后使用`AtomicReference`类来解决。

JVM内部实现了很多锁机制，有意思的是除了偏向锁，JVM实现锁的方式都用了循环CAS，即当一个线程进入同步代码块时使用循环CAS获取锁，离开同步代码块时使用循环CAS释放锁。

## 线程优先级
`Thread`类定义了三个和线程优先级的属性：
```java
/**
* The minimum priority that a thread can have.
*/
public static final int MIN_PRIORITY = 1;

/**
* The default priority that is assigned to a thread.
*/
public static final int NORM_PRIORITY = 5;

/**
* The maximum priority that a thread can have.
*/
public static final int MAX_PRIORITY = 10;
```

优先级越高的线程获得CPU时间片的概率越大，但这并不是意味着优先级越高的线程一定越先执行。Java中的线程的优先级可以通过方法`setPriority(int newPriority)`来设置，有效的优先级范围为：`1-10`。

## 常用方法

### `wait()`与`notify()`
若 `synchronized` 关键字修饰的某个共享资源 R 的锁已经被线程 T1 获得，其它需要资源 R 的锁才能运行的线程就会被阻塞直至 T1 释放 R 上的锁。一般情况下，这个锁是在同步代码块执行完才被释放的。

但是在同步代码块执行期间，已持有锁的线程 T1 可以调用资源 R 的 `wait()` 方法释放锁，然后进入等待状态，当前线程被挂起。锁的持有者可以调用 `notify()` 方法随机唤醒一个处于等待状态的线程，或 `notifyAll()` 方法去唤醒所有处于等待状态的线程。

只有持有与共享资源 R 相关联的 `monitor` 的锁的线程才应该去调用 `notify()` 或 `notifyAll()` 方法。一个线程可以通过3种方式获得与资源 R 相关联的 `monitor` 的锁，这三种方式刚好对应于同步代码块的三种形式。因为只有持有 `monitor` 的锁只有，才能进入同步代码块。

### `sleep()`与`wait()`
`sleep()` 与 `wait()` 都可以暂停线程执行，但它们还有一些区别：

1. 原理不同。`sleep()` 是 `Thread` 类的静态方法，是线程自己用来控制自身执行的，它可以使线程自己暂停一段时间，把执行的机会让给其它线程，等睡眠时间一到，便会自动“醒来”。而 `wait()` 是 `Object` 类的静态方法，用于线程间的通信，这个方法会使当前持有对象锁的线程释放锁并进入等待状态，直至其它线程调用对象的 `notify()` 或 `notifyAll()` 方法才会醒来。`wait()` 方法也支持设置超时时间。
2. 对锁的处理机制不同。调用 `sleep()` 方法只是让当前线程暂停一段时间，不涉及线程间通信，也不会释放锁。而调用 `wait()` 方法会释放锁。
3. 使用区域不同。`sleep()` 方法可以在任何区域使用。而由于调用 `wait()` 方法前必须先获得对象锁，因此只能在同步代码块内使用。
4. 对异常的处理方式不同。调用 `sleep()` 方法时必须处理 `InterruptedException` 异常。而调用 `wait()` 方法时不用关心异常处理。

### `sleep()`与`yield()`
`sleep()`方法与`yield()`方法都属于`Thread`类，它们的区别主要体现在：

1. 前者被调用后会立马进入阻塞状态，在一段时间内不会再执行。而后者只是使当前线程重新回到`RUNNABLE`状态，因此可能马上又被执行。
2. 前者在方法声明上抛出了`InterruptedException`异常，而后者没有声明任何异常。

### `join()`
JDK中对`join()`方法的解释为：Waits for this thread to die.

实际上，当线程A调用了线程B的`join()`方法后，线程A会让出CPU的执行权给线程B。直到线程B执行完成或者过了超时时间，线程A才会继续执行。

## 参考资料
1. Brian Goetz, Tim Peierls, Joshua Bloch, Joseph Bowbeer, David Holmes, and Doug Lea. *Java Concurrency in Practice*. Addison-Wesley Professional, 2006.
2. 方腾飞, 魏鹏, 程晓明. Java并发编程的艺术. 机械工业出版社, 2015.
