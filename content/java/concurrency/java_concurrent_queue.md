---
date: "2021-08-31T21:11:09+08:00"
title: "Java 中的并发队列"
authors: ["zhannicholas"]
categories:
  - Java
tags:
  - Java
  - 并发
draft: false
toc: true
---

并发队列（或线程安全的队列）是在我们在进行多线程并发编程时经常使用的一种数据结构。并发队列不仅具备基本队列的所有特性，还是线程安全的。由于并发队列在实现时已经考虑了各种线程安全问题，所以我们可以在并发环境中直接使用，而不用担心出现线程安全问题，有利于降低开发难度和工作量。

![Java 并发队列](/images/java/concurrency/java_concurrent_queue.png "Java 并发队列")

Java 中的并发队列可以分为阻塞队列和非阻塞队列两大类。

## 阻塞队列

除了队列的基本功能外，阻塞队列最大的特点在于 **阻塞**：在读取元素时，若队列为空，则阻塞读取操作直到队列非空；在写入元素时，若队列已满，则阻塞写入操作直到队列中出现可用空间。

阻塞队列的典型代表是 `BlockingQueue` 接口的各个实现类，主要有 `ArrayBlockingQueue`、`LinkedBlockingQueue`、`SynchronousQueue`、`DelayQueue`、`PriorityBlockingQueue` 和 `LinkedTransferQueue`。

根据阻塞队列容量的大小，又可以将其分为有界队列和无界队列。有界队列的典型代表是 `ArrayBlockingQueue`，一旦队列满了就无法入队新的元素了，因为它不会扩容。无界队列的典型代表是 `LinkedBlockingQueue`，其容量最大为 `Integer.MAX_VALUE`，即 `2^31 - 1`，这么大的容量几乎不可能被填满，故可以近似看成无限容量。

在阻塞队列中有很多相似的方法，比较容易混淆。因此，有必要对它们进行分类整理，根据方法是否抛出异常、是否返回特殊值、是否阻塞、是否具有超时时间，JDK 已经分类好了：

|         | Throws exception | Special value | Blocks         | Times out            |
| ------- | ---------------- | ------------- | -------------- | -------------------- |
| Insert  | add(e)           | offer(e)      | put(e)         | offer(e, time, unit) |
| Remove  | remove()         | poll()        | take()         | poll(time, unit)     |
| Examine | element()        | peek()        | not applicable | not applicable       |

根据操作类型的不同，特殊值（Special Value）略有差异：布尔类型的特殊值为 `false`，对象类型的特殊值为 `null`。

## 非阻塞队列

非阻塞队列家族则没有阻塞队列家族这么庞大，典型代表是 `ConcurrentLinkedQueue`，其内部通过 CAS 保证线程安全，不会阻塞线程，适合并发不是特别剧烈的场景。