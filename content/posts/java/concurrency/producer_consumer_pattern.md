---
date: "2021-04-26T22:44:40+08:00"
title: "生产者消费者模式"
authors: ["zhannicholas"]
categories:
  - 并发
tags:
  - 生产者消费者
draft: false
toc: true
---

生产者/消费者模式（Producer/Consumer Pattern）是一种非常常见的程序设计模式，广泛用于消息队列、解耦等场景中。简单来说，就是有一个共享的数据结构连接着生产者与消费者，生产者负责生产数据并将数据添加到共享数据结构中，而消费者负责从共享数据结构中取走数据并消费。如果生产者的生产速度特别快，而消费者的消费速度又特别慢，就会出现“产能过剩”的情况，反之则是“产能不足”。

上面提到的共享数据结构其实扮演了缓冲区的角色，它平衡了生产者与消费者之间的能力。当缓冲区满时，生产者被阻塞，但当消费者拿走数据空出位置之后，消费者就会通知生产者进行生产；而当缓冲区空时，消费者被阻塞，等待数据到来，在生产者将生产的数据放到共享数据结构之后，就会通知消费者去消费。

一般情况下，这个共享数据结构的空间是有限的，因此生产者-消费者问题又称有界缓冲区问题（bounded-buffer problem)）。

在 Java 中，实现生产者/消费者模式的方法又很多种，常见的有基于阻塞队列（BlockingQueue）的、也有基于 `Condition` 的，还有基于 `wait/notify` 的。

## 使用阻塞队列实现生产者/消费者模式

这时，阻塞队列承担的就是共享数据结构的功能。

```java
public class BlockingQueueProducerConsumer {
    public static void main(String[] args) {
        BlockingQueue<Object> buffer = new ArrayBlockingQueue<>(10);

        Runnable producer = () -> {
            while (true) {
                try {
                    buffer.put(new Object());
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        };

        Runnable consumer = () -> {
            while (true) {
                try {
                    buffer.take();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        };

        new Thread(producer).start();
        new Thread(producer).start();
        new Thread(consumer).start();
        new Thread(consumer).start();
    }
}
```

上面这段代码先是创建了一个用于生产者/消费者交流的缓冲区，随后分别开启两个生产者线程和两个消费者线程，生产者不断向 buffer 添加数据，而消费者不断从 buffer 消费数据。虽然这段代码看上去不涉及任何阻塞等待与唤醒，但是真相是阻塞等待与唤醒操作是 `ArrayBlockingQueue` 内部实现的。

## 使用 Condition 实现生产者/消费者模式

以下代码利用 `Condition` 实现生产者/消费者模式，其背后的思想与 `BlockingQueue` 非常相似：

```java
public class ConditionProducerConsumer {
    static class MyBlockingQueue {
        private Queue buffer;
        private int max = 16;
        private ReentrantLock lock = new ReentrantLock();
        private Condition notEmpty = lock.newCondition();   // 队列没空
        private Condition notFull = lock.newCondition();    // 队列没满

        public MyBlockingQueue(int size) {
            this.buffer = new LinkedList();
            this.max = size;
        }

        public void put(Object o) throws InterruptedException {
            lock.lock();
            try {
                while (buffer.size() == max) {
                    notFull.await();    // 自动释放lock并等待空间
                }
                buffer.add(o);
                notEmpty.signalAll();   // 唤醒消费者
            } finally {
                lock.unlock();
            }
        }

        public Object take() throws InterruptedException {
            lock.lock();
            try {
                while (buffer.size() == 0) {
                    notEmpty.await();   // 自动释放lock并等待数据
                }
                Object item = buffer.remove();
                notFull.signalAll();    // 唤醒生产者
                return item;
            } finally {
                lock.unlock();
            }
        }
    }

    public static void main(String[] args) {
        MyBlockingQueue buffer = new MyBlockingQueue(10);

        Runnable producer = () -> {
            for (int i = 0; i < 100; i++) {
                try {
                    buffer.put(new Object());
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        };

        Runnable consumer = () -> {
            for (int i = 0; i < 100; i++) {
                try {
                    buffer.take();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        };

        new Thread(producer).start();
        new Thread(consumer).start();
    }
}
```

首先代码中实现了一个简化版的阻塞队列，它充当的是缓冲区的角色。随后，定义了一个 `ReentrantLock` 类型的锁，并在它的基础上创建了两个 `Condition`：
 
 * `notEmpty`：表示缓冲区中有数据
 * `notFull`：表示缓冲区中有空闲空间

最后，是 `put()` 和 `take()` 这两个方法，分别用于往缓冲区中放数据和从缓冲区中取数据。由于生产者/消费者模式通常发生在多线程的场景下，所以我们需要保障线程安全。为此，`put()` 方法首先获取锁，然后在 `while` 循环中检测缓冲区是不是已经满了，入宫满了，则调用 `notFull.await()` 阻塞生产者并释放锁，如果没有满，则向缓冲区中添加数据并使用 `notEmpty.signalAll()` 通知所有正在等待的消费者并唤醒它们。最后在 `finally` 中保证释放锁。

`take()` 方法类似，它先通过 `while` 检查缓冲区是否为空，若为空则让消费者等待，否则从缓冲区中取走数据并通知生产者有空闲位置，最后释放锁。

## 使用 wait/notify 实现生产者/消费者模式

虽然使用方法不同，但它的原理与 `Condition` 非常类似：

```java
public class WaitNotifyProducerConsumer {
    static class MyBlockingQueue {
        private Queue buffer;
        private int max = 16;

        public MyBlockingQueue(int size) {
            this.buffer = new LinkedList();
            this.max = size;
        }

        public synchronized void put(Object o) throws InterruptedException {
            while (buffer.size() == max) {
                wait();    // 自动释放lock并等待空间
            }
            buffer.add(o);
            notifyAll();    // 唤醒消费者
        }

        public synchronized Object take() throws InterruptedException {
            while (buffer.size() == 0) {
                wait();   // 自动释放lock并等待数据
            }
            Object item = buffer.remove();
            notifyAll();    // 唤醒生产者
            return item;
        }
    }

    public static void main(String[] args) {
        MyBlockingQueue buffer = new MyBlockingQueue(10);

        Runnable producer = () -> {
            for (int i = 0; i < 100; i++) {
                try {
                    buffer.put(new Object());
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        };

        Runnable consumer = () -> {
            for (int i = 0; i < 100; i++) {
                try {
                    buffer.take();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        };

        new Thread(producer).start();
        new Thread(consumer).start();
    }
}
```