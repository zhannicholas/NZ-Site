---
date: "2021-12-08T19:13:20+08:00"
title: "Java Performance: Heap Memory and Native Best Practices"
authors: ["zhannicholas"]
categories:
  - 读书笔记
tags:
  - Java
draft: false
toc: true
---

> Notes from *Java Performance, 2nd Edition by Scott Oaks.*


We have two conflicting goals here. The first general rule is to create objects sparingly and to discard them as quickly as possible. Using less memory is the best way to improve the efficiency of the garbage collector. On the other hand, frequently re-creating some kinds of objects can lead to worse overall performance (even if GC performance improves). If those objects are instead reused, programs can see substantial performance gains.

## Heap Analysis

### Heap Histograms

Heap histograms are a quick way to look at the number of objects within an application without doing a full heap dump. If a few particular object types are responsible for creating memory pressure in an application, a heap histogram is a quick way to find that.

Heap histograms can be obtained by using `jcmd`:
```shell
$ jcmd <process_id> GC.class_histogram
```
`jmap` can show heap histograms too:
```shell
$ jmap -histo <process_id>
```
The output from `jmap` includes objects that are eligible to be collected (dead objects). To force a full GC prior to seeing the histogram, run this command instead:
```shell
$ jmap -histo:live <process_id>
```

### Heap Dumps

To perform a deeper heap analysis, a *heap dump* is required. There are many tools can look at heap dumps. For example:
```shell
$ jcmd <process_id> GC.heap_dump /path/to/heap_dump.hprof
```

```shell
$ map -dump:live,file=/path/to/heap_dump.hprof <process_id>
```
`live` option in `jmap` will force a full GC to occur before the heap is dumped.

GUI tools like `jvisualvm` and `mat` can also dump heaps.

The first-pass analysis of a heap generally involves **retained memory**. The retained memory of an object is the amount of memory that would be freed if the object itself were eligible to be collected.

#### Shallow, Retained, and Deep Object Sizes

The **shallow size** of an object is the size of the object itself. If the object contains a reference to another object, the 4 or 8 bytes of the reference is included, but the size of the target object is not included.

The **deep size** of an object includes the size of the object it references.

Objects that retain a large amount of heap space are often called the *dominators* of the heap.

### Out-of-Memory Errors

The JVM throws an out-of-memory error under these circumstances:
* No native memory is available for the JVM.
* The metaspace is out of memory.
  * This error can have two root causes: The first is simply that the application uses more classes than can fit in the metaspace you’ve assigned. The second case is trickier: it involves a classloader memory leak.
* The Java heap itself is out of memory: the application cannot create any additional objects for the given heap size.
* The JVM is spending too much time performing GC.

#### Automatic Heap Dumps

Out-of-memory errors can occur unpredictably, making it difficult to know when to get a heap dump. Several JVM flags can help:
* `-XX:+HeapDumpOnOutOfMemoryError`: Turning on this flag (which is false by default) will cause the JVM to create a heap dump whenever an out-of-memory error is thrown.
* `-XX:HeapDumpPath=<path>`: This specifies the location where the heap dump will be written; the default is *java_pid.hprof* in the application’s current working directory. The path can specify either a directory (in which case the default filename is used) or the name of the actual file to produce.
* `-XX:+HeapDumpAfterFullGC`: This generates a heap dump after running a full GC.
* `-XX:+HeapDumpBeforeFullGC`: This generates a heap dump before running a full GC.

## Using Less Memory

The first approach to using memory more efficiently in Java is to use less heap memory.

There are mainly three ways to use less memory: reducing object size, using lazy initialization of objects, and using canonical objects.

### Reducing Object Size

Defining only required instance variables is one way to save space in an object. The less obvious case involves using smaller data types.

object sizes are always padded so that they are a multiple of 8 bytes.

The JVM will also pad objects that have an uneven number of bytes so that arrays of that object fit neatly along whatever address boundaries are optimal for the underlying architecture.

Even `null` instance variables consume space within object classes.

The OpenJDK project has a separate downloadable tool called `jol` that can calculate object sizes.

### Using Lazy Initialization

If objects are expensive to create, and it definitely makes sense to keep that object around rather than re-create it on demand. This is a case where lazy initialization can help.

Lazy initialization is best used when the operation in question is only infrequently used.

### Using Immutable and Canonical Objects

If something reduces to its most basic form, then it's canonical. These singular representations of immutable objects are known as the *canonical version* of the object.

Strings can call the `intern()` method to find a canonical version of the string.

To canonicalize an object, create a map that stores the canonical version of the object. To prevent a memory leak, make sure that the objects in the map are weakly referenced.

## Object Life-Cycle Management

### Object Reuse

Object reuse is commonly achieved in two ways: object pools and thread-local variables.

Overall, the longer objects are kept in the heap, the less efficient GC will be. So: object reuse is bad.

*Soft references*, which are discussed later in this section, are essentially a big pool of reusable objects.

The reason for reusing objects is that many objects are expensive to initialize, and reusing them is more efficient than the trade-off in increased GC time.

Thread-local objects are always available within the thread and needn’t be explicitly returned.

Microbenchmarking threads that contend on a lock is always unreliable.

### Soft, Weak, and Other References

An ordinary instance variable that refers to an object is a strong reference.

The `-XX:+PrintReferenceGC` flag (which is `false` by default). This allows you to see how much time is spent processing those references.

#### Soft References

Soft references are used when the object in question has a good chance of being reused in the future, but you want to let the garbage collector reclaim the object if it hasn’t been used recently. Soft references are essentially one large, least recently used (LRU) object pool.

When, exactly, is a soft reference freed? First the referent must not be strongly referenced elsewhere. If the soft reference is the only remaining reference to its referent, the referent is freed during the next GC cycle only if the soft reference has not recently been accessed. If we use pseudocode to display when a soft reference is freed, it will be:
```
long ms = SoftRefLRUPolicyMSPerMB * AmountOfFreeMemoryInMB;
if (now - last_access_to_reference > ms)
   free the reference
```

If the JVM completely runs out of memory or starts thrashing too severely, it will clear all soft references.

#### Weak References

objects that are only weakly referenced are reclaimed at every GC cycle. objects that are only weakly referenced are reclaimed at every GC cycle.

This is what is meant by simultaneous access in weak references It is as if we are saying to the JVM: “Hey, as long as someone else is interested in this object, let me know where it is, but if they no longer need it, throw it away and I will re-create it myself.” Compare that to a soft reference, which essentially says: “Hey, try to keep this around as long as there is enough memory and as long as it seems that someone is occasionally accessing it.”

Don’t make the mistake of thinking that a weak reference is just like a soft reference except that it is freed more quickly: a softly referenced object will be available for (usually) minutes or even hours, but a weakly referenced object will be available for only as long as its referent is still around (subject to the next GC cycle clearing it).

#### Finalizers and Cleaners

The finalizer queue is the reference queue used to process the Finalizer references when the referent is eligible for GC.

In JDK 11, it’s much easier to use the new `java.lang.ref.Cleaner` class in place of the `finalize()` method.

### Compressed Oops

Using simple programming, 64-bit JVMs are slower than 32-bit JVMs. This performance gap is because of the 64-bit object references: the 64-bit references take up twice the space (8 bytes) in the heap as 32-bit references (4 bytes). That leads to more GC cycles, since there is now less room in the heap for other data.

*Oops* stands for *ordinary object pointers*, which are the handles the JVM uses as object references.

Two implications: 
* For heaps that are between 4 GB and 32 GB, use compressed oops. Compressed oops are enabled using the `-XX:+UseCompressedOops` flag.
* A program that uses a 31 GB heap and compressed oops will usually be faster than a program that uses a 33 GB heap.

## Native Memory Best Practices

In Unix-based systems, programs like `top` and `ps` can show you that data at a basic level; on Windows, you can use `perfmon` or `VMMap`.

Every time the JVM creates a thread, the OS allocates some native memory to hold that thread’s stack. 

In Unix systems, the footprint of an application can be estimated by the *resident set size (RSS)* of the process. On Windows systems, the equivalent idea is called the *working set* of an application, which is what is reported by the task manager.

The distinction between allocated and reserved memory comes about as a result of the way the JVM (and all programs) manage memory. 
* *Reserve memory* means the operating system promises that when the JVM attempts to allocate additional memory when it increases the size of the heap, that memory will be available.
* The (actually allocated) memory is known as the committed memory. The amount of committed memory will fluctuate as the heap resizes; in particular, as the heap size increases, the committed memory correspondingly increases.

### Native Memory Tracking

Using the option `-XX:NativeMemoryTracking=off|summary|detail` enables this visibility. By default, Native Memory Tracking (NMT) is off. 

If the summary or detail mode is enabled, you can get the native memory information at any time from jcmd:
```shell
$ jcmd <process_id> VM.native_memory summary
```

### Native NIO buffers

Native byte buffers are important from a performance perspective, since they allow native code and Java code to share data without copying it.

The total amount of memory that can be allocated for direct byte buffers is specified by setting the `-XX:MaxDirectMemorySize=N` flag.

In particular, native memory is never compacted. Hence, allocation patterns in native memory can lead to the same fragmentation.

It is possible to run out of native memory in Java because of native memory fragmentation.

## JVM Tunings for the Operating System

### Large Pages

A page is a unit of memory used by operating systems to manage physical memory. It is the minimum unit of allocation for the operating system.

Large pages must be enabled at both the Java and OS levels. At the Java level, the `-XX:+UseLargePages` flag enables large page use; by default, this flag is `false`. Not all operating systems support large pages, and the way to enable them obviously varies.

Linux refers to large pages as huge pages.

#### Linux transparent huge pages

Linux kernels starting with version 2.6.32 support transparent huge pages. These offer (in theory) the same performance benefit as traditional huge pages, but they have some differences from traditional huge pages.
* First, traditional huge pages are locked into memory; they can never be swapped. For Java, this is an advantage. Transparent huge pages can be swapped to disk, which is bad for performance.
* Second, allocation of a transparent huge page is also significantly different from a traditional huge page. Traditional huge pages are set aside at kernel boot time; they are always available. Transparent huge pages are allocated on demand.
* Third, transparent huge pages are configured differently at both the OS and Java levels.

Because of the differences in swapping and allocation of transparent huge pages, they are often not recommended for use with Java; certainly their use can lead to unpredictable spikes in pause times.

#### Windows large pages

Windows large pages can be enabled on only server-based Windows versions.