---
date: "2021-12-10T22:33:48+08:00"
title: "Java Performance: Summary of Tuning Flags"
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

## Flags to tune the just-in-time compiler

| Flag | What it does | When to use it|
|------|--------------|---------------|
| `-server` | This flag no longer has any effect; it is silently ignored. | N/A | 
| `-client` | This flag no longer has any effect; it is silently ignored. | N/A | 
| `-XX:+TieredCompilation` | Uses tiered compilation. | Always, unless you are severely constrained for memory. | 
| `-XX:ReservedCodeCacheSize=<MB>` | Reserves space for code compiled by the JIT compiler. | When running a large program and you see a warning that you are out of code cache. | 
| `-XX:InitialCodeCacheSize=<MB>` | Allocates the initial space for code compiled by the JIT compiler. | If you need to preallocate the memory for the code cache (which is uncommon). | 
| `-XX:CompileThreshold=<N>` | Sets the number of times a method or loop is executed before compiling it. | This flag is no longer recommended. | 
| `-XX:+PrintCompilation` | Provides a log of operations by the JIT compiler. | When you suspect an important method isn’t being compiled or are generally curious as to what the compiler is doing. | 
| `-XX:CICompilerCount=<N>` | Sets the number of threads used by the JIT compiler. | When too many compiler threads are being started. This primarily affects large machines running many JVMs. | 
| `-XX:+DoEscapeAnalysis` | Enables aggressive optimizations by the compiler. | On rare occasions, this can trigger crashes, so it is sometimes recommended to be disabled. Don’t disable it unless you know it is causing an issue. | 
| `-XX:UseAVX=<N>` | Sets the instruction set for use on Intel processors. | You should set this to 2 in early versions of Java 11; in later versions, it defaults to 2. | 
| `-XX:AOTLibrary=<path>` | Uses the specified library for ahead-of-time compilation. | In limited cases, may speed up initial program execution. Experimental in Java 11 only. | 

## Flags to choose the GC algorithm

| Flag | What it does | When to use it|
|------|--------------|---------------|
| `-XX:+UseSerialGC` | Uses a simple, single-threaded GC algorithm. | For single-core virtual machines and containers, or for small (100 MB) heaps. | 
| `-XX:+UseParallelGC` | Uses multiple threads to collect both the young and old generations while application threads are stopped. | Use to tune for throughput rather than responsiveness; default in Java 8. | 
| `-XX:+UseG1GC` | Uses multiple threads to collect the young generation while application threads are stopped, and background thread(s) to remove garbage from the old generation with minimal pauses. | When you have available CPU for the background thread(s) and you do not want long GC pauses. Default in Java 11. | 
| `-XX:+UseConcMarkSweepGC` | Uses background thread(s) to remove garbage from the old generation with minimal pauses. | No longer recommended; use G1 GC instead. | 
| `-XX:+UseParNewGC` | With CMS, uses multiple threads to collect the young generation while application threads are stopped. | No longer recommended; use G1 GC instead. | 
| `-XX:+UseZGC` | Uses the experimental Z Garbage Collector (Java 12 only). | To have shorter pauses for young GC, which is collected concurrently. | 
| `-XX:+UseShenandoahGC` | Uses the experimental Shenandoah Garbage Collector (Java 12 OpenJDK only). | To have shorter pauses for young GC, which is collected concurrently. | 
| `-XX:+UseEpsilonGC` | Uses the experimental Epsilon Garbage Collector (Java 12 only). | If your app never needs to perform GC.

## Flags common to all GC algorithms

| Flag | What it does | When to use it|
|------|--------------|---------------|
| `-Xms` | Sets the initial size of the heap. | When the default initial size is too small for your application. | 
| `-Xmx` | Sets the maximum size of the heap. | When the default maximum size is too small (or possibly too large) for your application. | 
| `-XX:NewRatio` | Sets the ratio of the young generation to the old generation. | Increase this to reduce the proportion of the heap given to the young generation; lower it to increase the proportion of the heap given to the young generation. This is only an initial setting; the proportion will change unless adaptive sizing is turned off. As the young-generation size is reduced, you will see more frequent young GCs and less frequent full GCs (and vice versa). | 
| `-XX:NewSize` | Sets the initial size of the young generation. | When you have finely tuned your application requirements. | 
| `-XX:MaxNewSize` | Sets the maximum size of the young generation. | When you have finely tuned your application requirements. | 
| `-Xmn` | Sets the initial and maximum size of the young generation. | When you have finely tuned your application requirements. | 
| `-XX:MetaspaceSize=N` | Sets the initial size of the metaspace. | For applications that use a lot of classes, increase this from the default. | 
| `-XX:MaxMetaspaceSize=N` | Sets the maximum size of the metaspace. | Lower this number to limit the amount of native space used by class metadata. | 
| `-XX:ParallelGCThreads=N` | Sets the number of threads used by the garbage collectors for foreground activities (e.g., collecting the young generation, and for throughput GC, collecting the old generation). | Lower this value on systems running many JVMs, or in Docker containers on Java 8 before update 192. Consider increasing it for JVMs with very large heaps on very large systems. | 
| `-XX:+UseAdaptiveSizePolicy` | When set, the JVM will resize various heap sizes to attempt to meet GC goals. | Turn this off if the heap sizes have been finely tuned. | 
| `-XX:+PrintAdaptiveSizePolicy` | Adds information about how generations are resized to the GC log. | Use this flag to gain an understanding of how the JVM is operating. When using G1, check this output to see if full GCs are triggered by humongous object allocation. | 
| `-XX:+PrintTenuringDistribution` | Adds tenuring information to the GC logs. | Use the tenuring information to determine if and how the tenuring options should be adjusted. | 
| `-XX:InitialSurvivorRatio=N` | Sets the amount of the young generation set aside for survivor spaces. | Increase this if short-lived objects are being promoted into the old generation too frequently. | 
| `-XX:MinSurvivorRatio=N` | Sets the adaptive amount of the young generation set aside for survivor spaces. | Decreasing this value reduces the maximum size of the survivor spaces (and vice versa). | 
| `-XX:TargetSurvivorRatio=N` | The amount of free space the JVM attempts to keep in the survivor spaces. | Increasing this value reduces the size of the survivor spaces (and vice versa). | 
| `-XX:InitialTenuringThreshold=N` | The initial number of GC cycles the JVM attempts to keep an object in the survivor spaces. | Increase this number to keep objects in the survivor spaces longer, though be aware that the JVM will tune it. | 
| `-XX:MaxTenuringThreshold=N` | The maximum number of GC cycles the JVM attempts to keep an object in the survivor spaces. | Increase this number to keep objects in the survivor spaces longer; the JVM will tune the actual threshold between this value and the initial threshold. | 
| `-XX:+DisableExplicitGC>` | Prevents calls to `System.gc()` from having any effect. | Use to prevent bad applications from explicitly performing GC. | 
| `-XX:-AggressiveHeap` | Enables a set of tuning flags that are “optimized” for machines with a large amount of memory running a single JVM with a large heap. | It is better not to use this flag, and instead use specific flags as necessary . | 

## Flags controlling GC logging

| Flag | What it does | When to use it|
|------|--------------|---------------|
| `-Xlog:gc*` | Controls GC logging in Java 11. | GC logging should always be enabled, even in production. Unlike the following set of flags for Java 8, this flag controls all options to Java 11 GC logging; see the text for a mapping of options for this to Java 8 flags. | 
| `-verbose:gc` | Enables basic GC logging in Java 8. | GC logging should always be enabled, but other, more detailed logs are generally better. | 
| `-Xloggc:<path>` | In Java 8, directs the GC log to a special file rather than standard output. | Always, the better to preserve the information in the log. | 
| `-XX:+PrintGC` | Enables basic GC logging in Java 8. | GC logging should always be enabled, but other, more detailed logs are generally better. | 
| `-XX:+PrintGCDetails` | Enables detailed GC logging in Java 8. | Always, even in production (the logging overhead is minimal). | 
| `-XX:+PrintGCTimeStamps` | Prints a relative timestamp for each entry in the GC log in Java 8. | Always, unless datestamps are enabled. | 
| `-XX:+PrintGCDateStamps` | Prints a time-of-day stamp for each entry in the GC log in Java 8. | Has slightly more overhead than timestamps, but may be easier to process. | 
| `-XX:+PrintReferenceGC` | Prints information about soft and weak reference processing during GC in Java 8. | If the program uses a lot of those references, add this flag to determine their effect on the GC overhead. | 
| `-XX:+UseGCLogFileRotation` | Enables rotations of the GC log to conserve file space in Java 8. | In production systems that run for weeks at a time when the GC logs can be expected to consume a lot of space. | 
| `-XX:NumberOfGCLogFiles=N` | When logfile rotation is enabled in Java 8, indicates the number of logfiles to retain. | In production systems that run for weeks at a time when the GC logs can be expected to consume a lot of space. | 
| `-XX:GCLogFileSize=N` | When logfile rotation is enabled in Java 8, indicates the size of each logfile before rotating it. | In production systems that run for weeks at a time when the GC logs can be expected to consume a lot of space. |

## Flags for the throughput collector

| Flag | What it does | When to use it|
|------|--------------|---------------|
| `-XX:MaxGCPauseMillis=N` | Hints to the throughput collector how long pauses should be; the heap is dynamically sized to attempt to meet that goal. | As a first step in tuning the throughput collector if the default sizing it calculates doesn’t meet application goals. | 
| `-XX:GCTimeRatio=N` | Hints to the throughput collector how much time you are willing to spend in GC; the heap is dynamically sized to attempt to meet that goal. | As a first step in tuning the throughput collector if the default sizing it calculates doesn’t meet application goals. | 

## Flags for the G1 collector

| Flag | What it does | When to use it|
|------|--------------|---------------|
| `-XX:MaxGCPauseMillis=N` | Hints to the G1 collector how long pauses should be; the G1 algorithm is adjusted to attempt to meet that goal. | As a first step in tuning the G1 collector; increase this value to attempt to prevent full GCs. | 
| `-XX:ConcGCThreads=N` | Sets the number of threads to use for G1 background scanning. | When lots of CPU is available and G1 is experiencing concurrent mode failures. | 
| `-XX:InitiatingHeapOccupancyPercent=N` | Sets the point at which G1 background scanning begins. | Lower this value if G1 is experiencing concurrent mode failures. | 
| `-XX:G1MixedGCCountTarget=N` | Sets the number of mixed GCs over which G1 attempts to free regions previously identified as containing mostly garbage. | Lower this value if G1 is experiencing concurrent mode failures; increase it if mixed GC cycles take too long. | 
| `-XX:G1MixedGCCountTarget=N` | Sets the number of mixed GCs over which G1 attempts to free regions previously identified as containing mostly garbage. | Lower this value if G1 is experiencing concurrent mode failures; increase it if mixed GC cycles take too long. | 
| `-XX:G1HeapRegionSize=N` | Sets the size of a G1 region. | Increase this value for very large heaps, or when the application allocates very, very large objects. | 
| `-XX:+UseStringDeduplication` | Allows G1 to eliminate duplicate strings. | Use for programs that have a lot of duplicate strings and when interning is impractical. |

## Flags for the CMS collector

| Flag | What it does | When to use it|
|------|--------------|---------------|
| `-XX:CMSInitiating​OccupancyFraction=N` | Determines when CMS should begin background scanning of the old generation. | When CMS experiences concurrent mode failures, reduces this value. | 
| `-XX:+UseCMSInitiating​OccupancyOnly` | Causes CMS to use only `CMSInitiatingOccupancyFraction` to determine when to start CMS background scanning. | Whenever `CMSInitiatingOccupancyFraction` is specified. | 
| `-XX:ConcGCThreads=N` | Sets the number of threads to use for CMS background scanning. | When lots of CPU is available and CMS is experiencing concurrent mode failures. | 
| `-XX:+CMSIncrementalMode` | Runs CMS in incremental mode. No longer supported. | N/A | 

## Flags for memory management

| Flag | What it does | When to use it|
|------|--------------|---------------|
| `-XX:+HeapDumpOnOutOfMemoryError` | Generates a heap dump when the JVM throws an out-of-memory error. | Enable this flag if the application throws out-of-memory errors due to the heap space or permgen, so the heap can be analyzed for memory leaks. | 
| `-XX:HeapDumpPath=<path>` | Specifies the filename where automatic heap dumps should be written. | To specify a path other than _java\_pid<pid>.hprof_ for heap dumps generated on out-of-memory errors or GC events (when those options have been enabled). | 
| `-XX:GCTimeLimit=<N>` | Specifies the amount of time the JVM can spend performing GC without throwing an `OutOfMemoryException` . | Lower this value to have the JVM throw an OOME sooner when the program is executing too many GC cycles. | 
| `-XX:HeapFreeLimit=<N>` | Specifies the amount of memory the JVM must free to prevent throwing an `OutOfMemoryException` . | Lower this value to have the JVM throw an OOME sooner when the program is executing too many GC cycles. | 
| `-XX:SoftRefLRUPolicyMSPerMB=N` | Controls how long soft references survive after being used. | Decrease this value to clean up soft references more quickly, particularly in low-memory conditions. | 
| `-XX:MaxDirectMemorySize=N` | Controls how much native memory can be allocated via the `allocateDirect()` method of the `ByteBuffer` class. | Consider setting this if you want to limit the amount of direct memory a program can allocate. It is no longer necessary to set this flag to allocate more than 64 MB of direct memory. | 
| `-XX:+UseLargePages` | Directs the JVM to allocate pages from the operating system’s large page system, if applicable. | If supported by the OS, this option will generally improve performance. | 
| `-XX:+StringTableSize=N` | Sets the size of the hash table the JVM uses to hold interned strings. | Increase this value if the application performs a significant amount of string interning. | 
| `-XX:+UseCompressedOops` | Emulates 35-bit pointers for object references. | This is the default for heaps that are less than 32 GB in size; there is never an advantage to disabling it. | 
| `-XX:+PrintTLAB` | Prints summary information about TLABs in the GC log. | When using a JVM without support for JFR, use this to ensure that TLAB allocation is working efficiently. | 
| `-XX:TLABSize=N` | Sets the size of the TLABs. | When the application is performing a lot of allocation outside TLABs, use this value to increase the TLAB size. | 
| `-XX:-ResizeTLAB` | Disables resizing of TLABs. | Whenever `TLABSize` is specified, make sure to disable this flag. | 

## Flags for native memory tracking

| Flag | What it does | When to use it|
|------|--------------|---------------|
| `-XX:NativeMemoryTracking= X` | Enable Native Memory Tracking. | When you need to see what memory the JVM is using outside the heap. | 
| `-XX:+PrintNMTStatistics` | Prints Native Memory Tracking statistics when the program terminates. | When you need to see what memory the JVM is using outside the heap. | 

## Flags for thread handling

| Flag | What it does | When to use it|
|------|--------------|---------------| 
| `-Xss<N>` | Sets the size of the native stack for threads. | Decrease this size to make more memory available for other parts of the JVM. | 
| `-XX:-BiasedLocking` | Disables the biased locking algorithm of the JVM. | Can help performance of thread pool–based applications. | 

## Miscellaneous JVM flags 

| Flag | What it does | When to use it|
|------|--------------|---------------| 
| `-XX:+CompactStrings` | Uses 8-bit string representations when possible (Java 11 only). | Default; always use. | 
| `-XX:-StackTraceInThrowable` | Prevents the stack trace from being gathered whenever an exception is thrown. | On systems with very deep stacks where exceptions are frequently thrown (and where fixing the code to throw fewer exceptions is not a possibility). | 
| `-Xshare` | Controls class data sharing. | Use this flag to make new CDS archives for application code. | 

## Flags for Java Flight Recorder

| Flag | What it does | When to use it|
|------|--------------|---------------| 
| `-XX:+FlightRecorder` | Enables Java Flight Recorder. | Enabling Flight Recorder is always recommended, as it has little overhead unless an actual recording is happening (in which case, the overhead will vary depending on the features used, but still be relatively small). | 
| `-XX:+FlightRecorderOptions` | Sets options for a default recording via the command line (Java 8 only). | Control how a default recording can be made for the JVM. | 
| `-XX:+StartFlightRecorder` | Starts the JVM with the given Flight Recorder options. | Control how a default recording can be made for the JVM. | 
| `-XX:+UnlockCommercialFeatures` | Allows the JVM to use commercial (non-open-source) features. | If you have the appropriate license, setting this flag is required to enable Java Flight Recorder in Java 8. | 