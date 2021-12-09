---
date: "2021-12-09T19:39:05+08:00"
title: "Java Performance: Threading and Synchronization Performance"
authors: ["zhannicholas"]
categories:
  - 读书笔记
tags:
  - Java
draft: false
toc: true
mathjax: true
---

> Notes from *Java Performance, 2nd Edition by Scott Oaks.*

## Thread Pools and ThreadPoolExecutors

Threads can be managed by custom code in Java, or applications can utilize a thread pool.

Thread pools have a minimum and maximum number of threads. The minimum number of threads is kept around, waiting for tasks to be assigned to them. Because creating a thread is a fairly expensive operation, this speeds up the overall operation when a task is submitted: it is expected that an already existing thread can pick it up. On the other hand, threads require system resources—including native memory for their stacks—and having too many idle threads can consume resources that could be used by other processes. The maximum number of threads also serves as a necessary throttle, preventing too many tasks from executing at once.

### Setting the Maximum Number of Threads

There is no simple answer to exact maximum number of threads; it depends on characteristics of the workload and the hardware on which it is run. In particular, the optimal number of threads depends on how often each individual task will block.

### Setting the Minimum Number of Threads

Once the maximum number of threads in a thread pool has been determined, it’s time to determine the minimum number of threads needed.

The argument for setting the minimum number of threads to less than maximum number of threads is that it prevents the system from creating too many threads, which saves on system resources. It is true that each thread requires a certain amount of memory, particularly for its stack.

By default, when you create a `ThreadPoolExecutor`, it will start with only one thread. but you can pre-create some threads (using the `prestartAllCoreThreads()` method).

Keeping idle threads around usually has little impact on an application. Usually, the thread object itself doesn’t take a very large amount of heap space. The exception is to use too much thread-local storage.

### Thread Pool Task Sizes

The tasks pending for a thread pool are held in a queue or list; when a thread in the pool can execute a task, it pulls a task from the queue. As a result, thread pools typically limit the size of the queue of pending tasks. In any case, when the queue limit is reached, attempts to add a task to the queue will fail.

### Sizing a ThreadPoolExecutor

The `ThreadPoolExecutor` decides when to start a new thread based on the type of queue used to hold the tasks. There are three possibilities:

* **`SynchronousQueue`**: new tasks will start a new thread if all existing threads are busy and if the pool has less than the number of maximum threads. However, this queue has no way to hold pending tasks: if a task arrives and the maximum number of threads is already busy, the task is always rejected. So this choice is good for managing a small number of tasks, but otherwise may be unsuitable. 
* **Unbounded queues**: When the executor uses an unbounded queue (such as `LinkedBlockedingQueue`), no task will ever be rejected (since the queue size is unlimited). In this case, the executor will use at most the number of threads specified by the core thread pool size: the maximum pool size is ignored.
* **Bounded queues**: Executors that use a bounded queue (e.g., `ArrayBlockingQueue`) employ a complicated algorithm to determine when to start a new thread. An additional thread will be started only when the queue is full, and a new task is added to the queue. The idea behind this algorithm is that the pool will operate with only the core threads (four) most of the time, even if a moderate number of tasks is in the queue waiting to be run. That allows the pool to act as a throttle (which is advantageous).

## The ForkJoinPool

The `ForkJoinPool` class is designed to work with divide-and-conquer algorithms: those where a task can be recursively broken into subsets. The subsets can be processed in parallel, and then the results from each subset are merged into a single result.

A thread inside a thread-pool executor cannot add another task to the queue and then wait for it to finish: once the thread is waiting, it cannot be used to execute one of the subtasks. `ForkJoinPool`, on the other hand, allows its threads to create new tasks and then suspend their current task. While the task is suspended, the thread can execute other pending tasks.

## Thread Synchronization

Strictly speaking, the atomic classes do not use synchronization, at least in CPU programming terms. Atomic classes utilize a **Compare and Swap (CAS)** CPU instruction, while synchronization requires exclusive access to a resource.

### Costs of Synchronization

Synchronized areas of code affect performance in two ways. First, the amount of time an application spends in a synchronized block affects the scalability of an application. Second, obtaining the synchronization lock requires CPU cycles and hence affects performance.

when an application is split up to run on multiple threads, the speedup it sees is defined by an equation known as *Amdahl’s law*:
$$
Speedup = \frac{1}{(1 - P) + P/N}
$$
`P` is the amount of the program that is run in parallel, and `N` is the number of threads utilized (assuming that each thread always has available CPU). That is why limiting the amount of code that lies in the serialized block is so important.

Uncontended `synchronized` locks are known as *uninflated locks*, and the cost of obtaining an uninflated lock is on the order of a few hundred nanoseconds. Uncontended CAS code will see an even smaller performance penalty.

### Avoiding Synchronization

If synchronization can be avoided altogether, locking penalties will not affect the application’s performance. Two general approaches can be used to achieve that.
* The first approach is to use different objects in each thread so that access to the objects will be uncontended.
* The second way to avoid synchronization is to use CAS-based alternatives.

In the general case, the following guidelines apply to the performance of CAS-based utilities compared to traditional synchronization:
* If access to a resource is uncontended, CAS-based protection will be slightly faster than traditional synchronization. If the access is always uncontended, no protection at all will be slightly faster still and will avoid corner-cases like the one you just saw with the register flushing from the `Vector` class.
* If access to a resource is lightly or moderately contended, CAS-based protection will be faster (often much faster) than traditional synchronization.
* As access to the resource becomes heavily contended, traditional synchronization will at some point become the more efficient choice. In practice, this occurs only on very large machines running many threads.
* CAS-based protection is not subject to contention when values are read and not written.

## JVM Thread Tunings

### Tuning Thread Stack Sizes

To change the stack size for a thread, use the `-Xss=N` flag (e.g., `-Xss=256k`).

### Biased Locking

The theory behind biased locking is that if a thread recently used a lock, the processor’s cache is more likely to still contain data the thread will need the next time it executes code protected by that same lock.

In the applications where different threads are equally likely to access the contended locks, a small performance improvement can be obtained by disabling biased locking via the `-XX:-UseBiasedLocking` option. Biased locking is enabled by default.

## Monitoring Threads and Locks

When analyzing an application’s performance for the efficiency of threading and synchronization, we should look for two things: the overall number of threads (to make sure it is neither too high nor too low) and the amount of time threads spend waiting for a lock or other resource.

The first caveat in looking at thread stacks is that the JVM can dump a thread’s stack only at safepoints. Second, stacks are dumped for each thread one at a time, so it is possible to get conflicting information from them: two threads can show up holding the same lock, or a thread can show up waiting for a lock that no other thread holds.

Thread stacks can show how significantly threads are blocked (since a thread that is blocked is already at a safepoint).