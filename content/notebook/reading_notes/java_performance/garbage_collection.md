---
date: "2021-12-07T20:00:10+08:00"
title: "Java Performance: Garbage Collection"
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

One of the most attractive features of programming in Java is that developers needn’t explicitly manage the life cycle of objects: objects are created when needed, and when the object is no longer in use, the JVM automatically frees the object.

## Garbage Collection Overview

At a basic level, GC consists of finding objects that are in use and freeing the memory associated with the remaining objects (those that are not in use).

JVM periodically search the heap for unused objects by starting with objects that are GC roots, which are objects that are accessible from outside the heap.

The performance of GC is dominated by these basic operations: finding unused objects, making their memory available, and compacting the heap. 

The pauses when all application threads are stopped are called **stop-the-world pauses**. These pauses generally have the greatest impact on the performance of an application, and minimizing those pauses is one important consideration when tuning GC.

### Generational Garbage Collectors

Though the details differ somewhat, most garbage collectors work by splitting the heap into generations. These are called the **old (or tenured) generation** and the **young generation**. The young generation is further divided into sections known as **eden** and the **survivor spaces** (though sometimes, eden is incorrectly used to refer to the entire young generation).

The rationale for having separate generations is that many objects are used for a very short period of time.

The garbage collector is designed to take advantage of the fact that many (and sometimes most) objects are only used temporarily. This is where the generational design comes in. Objects are first allocated in the young generation, which is a subset of the entire heap. When the young generation fills up, the garbage collector will stop all the application threads and empty out the young generation. Objects that are no longer in use are discarded, and objects that are still in use are moved elsewhere. This operation is called a minor GC or a young GC.

This design has two performance advantages. First, because the young generation is only a portion of the entire heap, processing it is faster than processing the entire heap. The second advantage arises from the way objects are allocated in the young generation. Since all surviving objects are moved, the young generation is automatically compacted when it is collected: at the end of the collection, eden and one of the survivor spaces are empty, and the objects that remain in the young generation are compacted within the other survivor space.

As objects are moved to the old generation, eventually it too will fill up, and the JVM will need to find any objects within the old generation that are no longer in use and discard them. The simpler algorithms stop all application threads, find the unused objects, free their memory, and then compact the heap. This process is called a **full GC**, and it generally causes a relatively long pause for the application threads.

On the other hand, it is possible to find unused objects while application threads are running. Because the phase where they scan for unused objects can occur without stopping application threads, these algorithms are called **concurrent collectors**. They are also called low-pause (and sometimes, incorrectly, pauseless) collectors since they minimize the need to stop all the application threads.

When using a concurrent collector, an application will typically experience fewer (and much shorter) pauses. The biggest trade-off is that **the application will use more CPU overall**. In other words, the benefit of avoiding long pause times with a concurrent collector comes at the expense of extra CPU usage.

### GC Algorithms

#### The serial garbage collector

The **serial garbage collector** is the simplest of the collectors. This is the default collector if the application is running on a client-class machine (32-bit JVMs on Windows) or on a single-processor machine.

The serial collector uses a single thread to process the heap. It will stop all application threads as the heap is processed (for either a minor or full GC). During a full GC, it will fully compact the old generation.

The serial collector is enabled by using the `-XX:+UseSerialGC` flag.

#### The throught collector

In JDK 8, the **throughput collector** is the default collector for any 64-bit machine with two or more CPUs. Because it uses multiple threads, the throughput collector is often called the **parallel collector**.

The throughput collector stops all application threads during both minor and full GCs, and it fully compacts the old generation during a full GC. 

To enable it where necessary, use the flag `-XX:+UseParallelGC`.

#### The G1 GC collector

The **G1 GC (or garbage first garbage collector)** uses a concurrent collection strategy to collect the heap with minimal pauses. It is the default collector in JDK 11 and later for 64-bit JVMs on machines with two or more CPUs.

G1 GC divides the heap into regions, but it still considers the heap to have two generations.

G1 GC is enabled by specifying the flag `-XX:+UseG1GC`.

G1 GC operates on discrete regions within the heap. Each region (there are by default around 2,048) can belong to either the old or new generation, and the generational regions need not be contiguous.

G1 GC is called a concurrent collector because the marking of free objects within the old generation happens concurrently with the application threads.

Full GC in G1 GC collector is triggered primarily four times:
* Concurrent mode failure: G1 GC starts a marking cycle, but the old generation fills up before the cycle is completed. In that case, G1 GC aborts the marking cycle.
* Promotion failure: G1 GC has completed a marking cycle and has started performing mixed GCs to clean up the old regions. Before it can clean enough space, too many objects are promoted from the young generation, and so the old generation still runs out of space.
* Evacuation failure: When performing a young collection, there isn’t enough room in the survivor spaces and the old generation to hold all the surviving objects.
* Humongous allocation failure: Applications that allocate very large objects can trigger another kind of full GC in G1 GC.
* Metadata GC threshold： Metaspace is not collected via G1 GC, but still when it needs to be collected in JDK 8, G1 GC will perform a full GC (immediately preceded by a young collection) on the main heap.

G1 has multiple cycles (and phases within the concurrent cycle). A well-tuned JVM running G1 should experience only young, mixed, and concurrent GC cycles.

##### Tuning G1 GC

The major goal in tuning G1 GC is to make sure that no concurrent mode or evacuation failures end up requiring a full GC. 

But one of the goals of G1 GC is that it shouldn’t have to be tuned that much. To that end, G1 GC is primarily tuned via a single flag: the same `-XX:MaxGCPauseMillis=N` flag.

Two sets of threads are used by G1 GC. The first set is controlled via the `-XX:ParallelGCThreads=N` flag. This value affects the number of threads used for phases when application threads are stopped. The second flag is `-XX:ConcGCThreads=N`, which affects the number of threads used for the concurrent remarking. The default value for the `ConcGCThreads` flag is defined as follows: `ConcGCThreads = (ParallelGCThreads + 2) / 4`.

If you want G1 GC run more (or less) frequently, use `-XX:InitiatingHeapOccupancyPercent=N` flag to indicate the G1 GC start background marking cycle. The default value of this flag is 45.

#### The CMS collector

**CMS collector** stops all application threads during a minor GC, which it performs with multiple threads.

CMS is officially deprecated in JDK 11 and beyond, and its use in JDK 8 is discouraged. The major flaw in CMS is that it has no way to compact the heap during its background processing. If the heap becomes fragmented (which is likely to happen at some point), CMS must stop all application threads and compact the heap, which defeats the purpose of a concurrent collector. This concurrent mode failure is a major reason CMS is deprecated.

CMS is enabled by specifying the flag `-XX:+UseConcMarkSweepGC`, which is false by default.

The primary concern when tuning CMS is to make sure that no concurrent mode or promotion failures occur.

CMS uses the `MaxGCPauseMllis=N` and `GCTimeRatio=N` settings to determine how large the heap and the generations should be.

Each CMS background thread will consume 100% of a CPU on a machine. 

### Causing and Disabling explicit garbage collection

GC is typically caused when the JVM decides GC is necessary: a minor GC will be triggered when the new generation is full, a full GC will be triggered when the old generation is full, or a concurrent GC (if applicable) will be triggered when the heap starts to fill up.

Java provides a mechanism for applications to force a GC to occur: the `System.gc()` method. Calling that method is almost always a bad idea. This call always triggers a full GC (even if the JVM is running with G1 GC or CMS), so application threads will be stopped for a relatively long period of time. And calling this method will not make the application any more efficient.

Explicit GCs can be prevented by including `-XX:+DisableExplicitGC` in the JVM arguments. By default, that flag is false.

### Choosing a GC Algorithm

The trade-off between G1 GC and other collectors involves having available CPU cycles for G1 GC background threads, so let’s start with a CPU-intensive batch job. In a batch job, the CPU will be 100% busy for a long time, and in that case the serial collector has a marked advantage. That’s what I mean when I say that when you choose G1 GC, sufficient CPU is needed for its background threads to run. 

If we’re more interested in interactive processing and response times, the throughput collector has a harder time beating G1 GC. If your server is short of CPU cycles such that the G1 GC and application threads compete for CPU, then G1 GC will yield worse response times.

### Experimental GC Algorithms

The pause times of an application are dominated by the time spent moving objects and making sure references to them are up-to-date.

Two experimental collectors are designed to address this problem. The first is the Z garbage collector, or ZGC; the second is the Shenandoah garbage collector. ZGC first appeared in JDK 11; Shenandoah GC first appeared in JDK 12 but has now been backported to JDK 8 and JDK 11.

o use these collectors, you must specify the `-XX:+UnlockExperimentalVMOptions` flag (by default, it is `false`). Then you specify either `-XX:+UseZGC` or `-XX:+UseShenandoahGC` in place of other GC algorithms.

Both collectors allow concurrent compaction of the heap, meaning that objects in the heap can be moved without stopping all application threads. This has two main effects:
* First, the heap is no longer generational.
* The second is that the latency of operations performed by the application threads can be expected to be reduced.

JDK 11 also contains a collector that does nothing: the **epsilon collector**. 

## Basic GC Tuning

### Sizing the Heap

If the heap is too small, the program will spend too much time performing GC and not enough time performing application logic. The time spent in GC pauses is dependent on the size of the heap, so as the size of the heap increases, the duration of those pauses also increases. 

A severe performance penalty happens when the OS swaps data from disk to RAM (which is an expensive operation to begin with). Hence, the first rule in sizing a heap is never to specify a heap that is larger than the amount of physical memory on the machine.

The size of the heap is controlled by two values: an initial value (specified with `-XmsN`) and a maximum value (`-XmxN`). Heap sizing is one of the JVM’s core ergonomic tunings.

Having an initial and maximum size for the heap allows the JVM to tune its behavior depending on the workload.

A good rule of thumb is to size the heap so that it is 30% occupied after a full GC.

If you know exactly what size heap the application needs, you may as well set both the initial and maximum values of the heap to that value (e.g., `-Xms4096m -Xmx4096m`). That makes GC slightly more efficient, because it never needs to figure out whether the heap should be resized.

### Sizing the Generations

The performance implication of different generation sizes should be clear: if there is a relatively larger young generation, young GC pause times will increase, but the young generation will be collected less often, and fewer objects will be promoted into the old generation. But on the other hand, because the old generation is relatively smaller, it will fill up more frequently and do more full GCs. Striking a balance is key.

The command-line flags to tune the generation sizes all adjust the size of the young generation; the old generation gets everything that is left over. A variety of flags can be used to size the young generation:
* `-XX:NewRatio=N`: Set the ratio of the young generation to the old generation.
* `-XX:NewSize=N`: Set the initial size of the young generation.
* `-XX:MaxNewSize=N`: Set the maximum size of the young generation.
* `-XmnN`: Shorthand for setting both NewSize and MaxNewSize to the same value.

The `NewRatio` value is used in this formula: `Initial Young Gen Size = Initial Heap Size / (1 + NewRatio)`

By default, then, the young generation starts out at 33% of the initial heap size.

#### Adaptive and Static Heap Size Tuning

At a global level, adaptive sizing can be disabled by turning off the `-XX:-UseAdaptiveSizePolicy` flag (which is `true` by default). To see how the JVM is resizing the spaces in an application, set the `-XX:+PrintAdaptiveSizePolicy` flag.

Tuning the throughput collector is all about pause times and striking a balance between the overall heap size and the sizes of the old and young generations.

There are two trade-offs to consider here. First, we have the classic programming trade-off of time versus space. A larger heap consumes more memory on the machine, and the benefit of consuming that memory is (at least to a certain extent) that the application will have a higher throughput.

The second trade-off concerns the length of time it takes to perform GC. The number of full GC pauses can be reduced by increasing the heap size, but that may have the perverse effect of increasing average response times because of the longer GC times. Similarly, full GC pauses can be shortened by allocating more of the heap to the young generation than to the old generation, but that, in turn, increases the frequency of the old GC collections.

Adaptive sizing in the throughput collector will resize the heap (and the generations) in order to meet its pause-time goals. Those goals are set with these flags: `-XX:MaxGCPauseMillis=N` and `-XX:GCTimeRatio=N`.

The `GCTimeRatio` flag specifies the amount of time you are willing for the application to spend in GC, it's default value is 99.

$$
ThroughputGoal = 1 - 1 / (1 + GCTimeRatio)
$$

$$
GCTimeRatio = Throughput / (1 - Throughput)
$$


### Sizing Metaspace

When the JVM loads classes, it must keep track of certain metadata about those classes. This occupies a separate heap space called the **metaspace**.

Information in the metaspace is used only by the compiler and JVM runtime, and the data it holds is referred to as **class metadata**.

Because the default size of metaspace is unlimited, an application (particularly in a 32-bit JVM) could run out of memory by filling up metaspace. Resizing the metaspace requires a full GC, so it is an expensive operation. 

### Controlling Parallesim

All GC algorithms except the serial collector use multiple threads. The number of these threads is controlled by the `-XX:ParallelGCThreads=N` flag. The value of this flag affects the number of threads used for the following operations:
* Collection of the young generation when using `-XX:+UseParallelGC`
* Collection of the old generation when using `-XX:+UseParallelGC`
* Collection of the young generation when using `-XX:+UseG1GC`
* Stop-the-world phases of G1 GC (though not full GCs)

The total number of threads (where `N` is the number of CPUs) on a machine with more than eight CPUs is shown here: `ParallelGCThreads = 8 + ((N - 8) * 5 / 8)`.

## Advanced Tuning

### Tenuring and Survivor Spaces

Objects are moved into the old generation in two circumstances. First, the survivor spaces are fairly small. When the target survivor space fills up during a young collection, any remaining live objects in eden are moved directly into the old generation. Second, there is a limit to the number of GC cycles during which an object can remain in the survivor spaces. That limit is called the *tenuring threshold*.

The initial size of the survivor spaces is determined by the `-XX:InitialSurvivorRatio=N` flag, which is used in this equation: `survivor_space_size = new_size / (initial_survivor_ratio + 2)`.

The JVM may increase the survivor spaces size to a maximum determined by the setting of the `-XX:MinSurvivorRatio=N` flag. That flag is used in this equation: `maximum_survivor_space_size = new_size / (min_survivor_ratio + 2)`.

There is the question of how many GC cycles an object will remain ping-ponging between the survivor spaces before being moved into the old generation. That answer is determined by the tenuring threshold. The JVM continually calculates what it thinks the best tenuring threshold is. The threshold starts at the value specified by the `-XX:InitialTenuringThreshold=N` flag (the default is 7 for the throughput and G1 GC collectors, and 6 for CMS). The JVM will ultimately determine a threshold between 1 and the value specified by the `-XX:MaxTenuringThreshold=N` flag; for the throughput and G1 GC collectors, the default maximum threshold is 15, and for CMS it is 6.

### Allocating Large Objects

It is important to applications that frequently create a significant number of large objects. In this context, *large* is a relative term; it depends, as you’ll see, on the size of a particular kind of buffer within the JVM.This buffer is known as a **thread-local allocation buffer (TLAB)**. 

Each thread has a dedicated region where it allocates objects—a thread-local allocation buffer, or TLAB. When objects are allocated directly in a shared space such as eden, some synchronization is required to manage the free-space pointers within that space.

By default, TLABs are enabled; they can be disabled by specifying `-XX:-UseTLAB`. They have a small size, so large objects cannot be allocated within a TLAB. Large objects must be allocated directly from the heap, which requires extra time because of the synchronization.

In addition, TLAB is just a section within eden.

Outside JFR, the best way to monitor the TLAB allocation by adding the `-XX:+PrintTLAB` flag to the command line in JDK 8 or including `tlab*=trace` in the log configuration for JDK 11.

Applications that spend a lot of time allocating objects outside TLABs will benefit from changes that can move the allocation to a TLAB. The size of the TLABs can be set explicitly using the flag `-XX:TLABSize=N`.

Objects that are allocated outside a TLAB are still allocated within eden when possible. If the object cannot fit within eden, it must be allocated directly in the old generation. G1 GC defines a *humongous object* as one that is half of the region size. Since G1 GC divides the heap into regions, each of which has a fixed size. he size of the regions will be set according to this formula (using log base 2): `region_size = 1 << log(Initial Heap Size / 2048)`.

## GC Tools

### Enabling GC Logging in JDK 8

JDK 8 provides multiple ways to enable the GC log. Specifying either of the flags `-verbose:gc` or `-XX:+PrintGC` will create a simple GC log (the flags are aliases for each other, and by default the log is disabled). The `-XX:+PrintGCDetails` flag will create a log with much more information.

In conjunction with the detailed log, it is recommended to include `-XX:+PrintGCTimeStamps` or `-XX:+PrintGCDateStamps` so that the time between GC operations can be determined.

The GC log is written to standard output, though that location can (and usually should) be changed with the `-Xloggc:filename` flag. Using `-Xloggc` automatically enables the simple GC log unless `PrintGCDetails` has also been enabled.

The amount of data that is kept in the GC log can be limited using log rotation.

Putting that all together, a useful set of flags for logging is as follows: `-Xloggc:gc.log -XX:+PrintGCTimeStamps -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFile=8 -XX:GCLogFileSize=8m`.

### Enabling GC Logging in JDK 11

To enable GC logging in JDK 11, use following flags: `-Xlog:gc*:file=gc.log:time:filecount=7,filesize=8M`. The colons divide the command into four sections.

For a scriptable solution, `jstat` is the tool of choice. `jstat` provides nine options to print different information about the heap; `jstat -options` will provide the full list. One useful option is `-gcutil`, which displays the time spent in GC as well as the percentage of each GC area that is currently filled. If you’ve forgotten to enable GC logging, this is a good substitute to watch how GC operates over time.

## A quick approach to choosing and tuning a garbage collector

Here’s a quick set of questions to ask yourself to help put everything in context:

* **Can your application tolerate some full GC pauses?**
  * If not, G1 GC is the algorithm of choice. Even if you
  can tolerate some full pauses, G1 GC will often be better than parallel GC unless your application is CPU bound.

* **Are you getting the performance you need with the default settings?**
  * Try the default settings first. As GC technology matures, the ergonomic (automatic) tuning gets better all the time. If you’re not getting the performance you need, make sure that GC is your problem. Look at the GC logs and see how much time you’re spending in GC and how frequently the long pauses occur. For a busy application, if you’re spending 3% or less time in GC, you’re not going to get a lot out of tuning (though you can always try to reduce outliers if that is your goal).

* **Are the pause times that you have somewhat close to your goal?**
  * If they are, adjusting the maximum pause time may be all you need. If they aren’t, you need to do something else. If the pause times are too large but your throughput is OK, you can reduce the size of the young generation (and for full GC pauses, the old generation); you’ll get more, but shorter, pauses.

* **Is throughput lagging even though GC pause times are short?**
  * You need to increase the size of the heap (or at least the young generation). More isn’t always better: bigger heaps lead to longer pause times. Even with a concurrent collector, a bigger heap means a bigger young generation by default, so you’ll see longer pause times for young collections. But if you can, increase the heap size, or at least the relative sizes of the generations.

* **Are you using a concurrent collector and seeing full GCs due to concurrent-mode failures?**
  * If you have available CPU, try increasing the number of concurrent GC threads or starting the background sweep sooner by adjusting InitiatingHeapOccupancyPercent. For G1, the concurrent cycle won’t start if there are pending mixed GCs; try reducing the mixed GC count target.

* **Are you using a concurrent collector and seeing full GCs due to promotion failures?**
  * In G1 GC, an evacuation failure (to-space overflow) indicates that the heap is fragmented, but that can usually be solved if G1 GC performs its background sweeping sooner and mixed GCs faster. Try increasing the number of concurrent G1 threads, adjusting InitiatingHeapOccupancyPercent, or reducing the mixed GC count target.