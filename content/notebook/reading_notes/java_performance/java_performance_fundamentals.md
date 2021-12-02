---
date: "2021-11-24T20:52:36+08:00"
title: "Java Performance: foundamentals"
authors: ["zhannicholas"]
categories:
  - 读书笔记
tags:
  - Java
draft: false
toc: true
---

> Notes from *Java Performance, 2nd Edition by Scott Oaks.*


To be a good Java Performance engineer, we need some specific knowledge. This knowledge falls into two broad categories:
* The performance of the Java Virtual Machine (JVM) itself: the way that the JVM is configured affects many aspects of a program’s performance. 
* To understand how the features of the Java platform affect performance. 

## JVM tuning flags

With a few exceptions, the JVM accepts two kinds of flags: boolean flags, and flags that require a parameter.
* Boolean flags use this syntax: `-XX:+FlagName` enables the flag, and `-XX:-FlagName` disables the flag.
* Flags that require a parameter use this syntax: `-XX:FlagName=something`, meaning to set the value of `FlagName` to `something`.

The process of automatically tuning flags based on the environment is called **ergonomics**.

## Hardware Platform

Two popular platform in use today: Virtual Machines and Software Containers (such as Docker).

Virtual machine sets up a completely isolated copy of the **operating system** on a subset of the hardware on which the virtual machine is running. 

Docker container is just a process (potentially with resource constraints) within a running OS, it provides **isolation between processes**. By default, a Docker container is free to use all of the machine’s resources. But when the heap grows to it's maximum size and that size is larger than the memory assigned to the Docker container, the Docker container (and hence the JVM) will be **killed**.

## The Complete Performance Story

A **good algorithm** is the most important thing when it comes to fast performance.

A small well-written program will run faster than a large well-written program (write less code).

We should forget about small efficiencies, say about 97% of the time; **premature optimization is the root of all evil**. But premature optimization doesn't mean avoiding code constructs that are known to be bad for performance. For example:

```Java
log.log(Level.FINE, "I am here, and the value of X is "
        + calcX() + " and Y is " + calcY());
```

This code does a string concatenation that is likely unnecessary, since the message won’t be logged unless the logging level is set quite high. The suggested imporvement is:

```Java
if (log.isLoggable(Level.FINE)) {
    log.log(Level.FINE,
            "I am here, and the value of X is {} and Y is {}",
            new Object[]{calcX(), calcY()});
}
```

Remember, increasing load to a component in a system that is performing **badly** will make the entire system slower (For example, the database is always the bottleneck).

We should focus on the **common use case** scenarios. This principle manifests itself in several ways:
* Optimize code by profiling it and focusing on the operations in the profile taking the most time.
* Apply Occam’s razor to diagnosing performance problems. 
* Write simple algorithms for the most common operations in an application.

## Performance testing categories

Three categories of code can be used for performance testing: microbenchmarks, macrobenchmarks, and mesobenchmarks. 

### Microbenchmarks

A microbenchmark is a test designed to measure **a small unit** of performance in order to decide which of multiple alternate implementations is preferable.

But just-in-time compilation and garbage collection in Java make it difficult to write microbenchmarks correctly.

Some principles:
* Microbenchmarks must test a range of input
* Microbenchmarks must measure the correct input
* Microbenchmark code may behave differently in production

In microbenchmarks, a warm-up period is need, because one of the performance characteristics of Java is that **code performs better the more it is executed**.

### Macrobeanchmarks

The best thing to use to measure performance of an application is the **application itself**, in conjunction with any external resources it uses. This is a macrobenchmark.

### Mesobenchmarks

Mesobenchmarks are tests that occupy a middle ground between a microbenchmark and a full application.

## Throughput, Batching, and Response Time

Performance can be measured as **throughput (RPS)**, **elapsed time (batch time)**, or **response time**, and these three metrics are interrelated.

**Elapsed Time (Batch) Measurements**: how long it takes to accomplish a certain task. Performance is most often measured after the code in question has been executed long enough for it to have been compiled and optimized.

**Throughput Measurements**: A throughput measurement is based on the amount of work that can be accomplished in a certain period of time. This measurement is frequently referred to as transactions per second (TPS), requests per second (RPS), or operations per second (OPS).

**Response Time**: the amount of time that elapses between the sending of a request from a client and the receipt of the response. One difference between **average response time** and a **percentile response time** is in the way outliers affect the calculation of the average: since they are included as part of the average, large outliers will have a large effect on the average response time.

## Variability

**Test results vary over time**. Understanding when a difference is a real regression and when it is a random variation is difficult.

Testing code for changes like this is called regression testing. In a regression test, the original code is known as the *baseline*, and the new code is called the *specimen*. 

In general, the larger the variation in a set of results, the harder it is to guess the probability that the difference in the averages is real or due to random chance.

Statistical significance does not mean statistical importance.

Correctly determining whether results from two tests are different requires a level of statistical analysis to make sure that perceived differences are not the result of random chance. The rigorous way to accomplish that is to use Student’s t-test to compare the results. Data from the t-test tells us the probability that a regression exists, but it doesn’t tell us which regressions should be ignored and which must be pursued. Finding that balance is part of the art of performance engineering.



## Test early, Test Often

Early, frequent testing is most useful if the following guidelines are followed:
* Automate everything
* Measure everything
* Run on the target system

## Operating System Tools and Analysis

### CPU Usage

CPU usage is typically divided into two categories: **user time** and **system time** (Windows refers to this as **privileged time**). User time is the percentage of time the CPU is executing application code, while system time is the percentage of time the CPU is executing kernel code. 

The goal in performance is to **drive CPU usage as high as possible for as short a time as possible**. Driving the CPU usage higher is always the goal for **batch jobs**, because the job will be completed faster.

Both Windows and Unix systems allow you to monitor the number of threads that can be run (meaning that they are not blocked on I/O, or sleeping, and so on). Unix systems refer to this as the *run queue*: the first number in each line of `vmstat`'s output is the length of the run queue. Windows refers to this number as the *processor queue* and reports it (among other ways) via `typeperf`.

### Disk Usage

Monitoring disk usage has two important goals. The first pertains to the application itself: if the application is doing a lot of disk I/O, that I/O can easily become a bottleneck. The second is even if the application is not expected to perform a significant amount of I/O—is to help monitor if the system is swapping.

A system that is swapping—moving pages of data from main memory to disk, and vice versa—will have quite bad performance.

### Network Usage

Network usage is similar to disk traffic: the application might be inefficiently using the network so that bandwidth is too low, or the total amount of data written to a particular network interface might be more than the interface is able to handle.

Be sure to remember that the bandwidth is measured in bits per second (bps), although tools generally report bytes per second (Bps).

## Java Monitoring Tools

JDK provides many Java monitoring tools to help us gain insight in to the JVM:

* `jcmd`: Prints basic class, thread, and JVM information for a Java process. Usage: `jcmd process_id command optional_arguments`
* `jconsole`: Provides a graphical view of JVM activities, including thread usage, class usage, and GC activities.
  * Since `jconsole` requires a fair amount of system resources, running it on a production system can interfere with that system. But we can set up `jconsole` so that it can be **run locally and attach to a remote system**, which won't interfere with that remote system's performance.
* `jmap`: Provides heap dumps and other information about JVM memory usage.
* `jinfo`: Provides visibility into the system properties of the JVM, and allows some system properties to be set dynamically.
* `jstack`: Dumps the stacks of a Java process. Suitable for scripting.
* `jstat`: Provides information about GC and class-loading activities.
* `jvisualvm`: A GUI tool to monitor a JVM, profile a running application, and analyze JVM heap dumps.

Among these tools, nongraphical tools (expect `jconsole` and `jvisualvm`) are suitable for scripting.

These tools fits into broad areas:
* Basic VM information
* Thread information
* Class information
* Live GC analysis
* Heap dump postprocessing
* Profile a JVM

There's a lot of overlap with each tool's work. So it's better to focus on different areas.

### Basic VM information

#### Uptime

The length of time the JVM has been up can be found via this command:
```shell
$ jcmd <process_id> VM.uptime
```

#### System properties

The set of items in `System.getProperties()` can be displayed with either of these commands:
```shell
$ jcmd <process_id> VM.system_properties
```
or
```shell
$ jinfo -sysprops <process_id>
```

#### JVM version

The version of the JVM is obtained like this:
```shell
$ jcmd <process_id> VM.version
```

#### JVM command line

The command line can be displayed in the VM summary tab of `jconsole`, or via `jcmd`:
```shell
$ jcmd <process_id> VM.command_line
```

#### JVM tuning flags

The tuning flags in effect for an application can be obtained like this:
```shell
$ jcmd <process_id> VM.flags [-all]
```
Or, you can use `-XX:+PrintFlagsFinal` option on the command line to see platform-specific defaults.
```shell
$ java other_options -XX:+PrintFlagsFinal -version
```

Yet another way to see JVM options for a running application is with `jinfo`. Retrive the values of all flags in the proces:
```shell
$ jinfo -flags <process_id>
```
If `-flags` option is present, this command will provide information about all flags; ohterwise, it prints only those specified on the command line.

If you want to inspect the value of an individual flag, use `-flag` option:
```shell
$ jinfo -flag PrintGCDetails <process_id>
-XX:+PrintGCDetails
```
The advantage of `jinfo` is that is allows certain flag values to be changed during execution of the program. For example:
```shell
$ jinfo -flag -PrintGCDetails <process_id> # turns off PrintGCDetails
```
But this technique works only for those flags marked `manageable` in the output of `PrintFlagsFinal` command.

### Thread Information

If you have GUI, `jconsole` and `jvisualvm` are good tools to display real time information of threads running in an application.

The stacks can be obtained via `jstack`:
```shell
$ jstack <process_id>
```
Or `jcmd`:
```shell
$ jcmd <process_id> Thread.print
```

### Class Information

Information about the number of classes in use by an application can be obtained from `jconsole` or `jstat`. `jstat` can also provide information about class compilation.

### Live GC Analysis

Virtually every monitoring tool can report something about GC activity
* `jconsole` displays live graphs of the heap usage; 
* `jcmd` allows GC operations to be performed; 
* `jmap` can print heap summaries or information on the permanent generation or create a heap dump; 
* `jstat` produces a lot of views of what the garbage collector is doing

### Heap Dump Postprocessing

The *heap dump* is a **snapshot** of the heap that can be analyzed with various tools, including `jvisualvm` and the Eclipse Memory Analyzer Tool (MAT). GUI tool `jvisualvm` and command line tool `jcmd` or `jmap` can capture heap snapshots.

### Profile a JVM

**Profilers** are the most important tool in a performance analyst’s toolbox. Profiling happens in one of two modes: sampling mode or instrumented mode. 

#### Sampling Profilers

Sampling mode is the basic mode of profiling and carries the least amount of overhead.

In the common Java interface for profilers, the profiler can get the stack trace of a thread **only** when the thread is **at a safepoint**, so sampling becomes even less reliable.

Threads automatically go into a safepoint when they are:
* Blocked on a synchronized lock
* Blocked waiting for I/O
* Blocked waiting for a monitor
* Parked
* Executing Java Native Interface (JNI) code (unless they perform a GC locking function)

In addition, the JVM can set a flag asking for threads to go into a safepoint.

#### Instrumented Profilers

Instrumented profilers are much more intrusive than sampling profilers (they could have a greater effect on application than a sampling profiler), but they can also give more beneficial information about what’s happening inside a program.

Instrumented profilers work by altering the bytecode sequence of classes as they are loaded (inserting code to count the invocations, and so on).

Because of the changes introduced into the code via instrumentation, it is best to limit its use to a few classes. This means it is best used for second-level analysis: a sampling profiler can point to a package or section of code, and then the instrumented profiler can be used to drill into that code if needed.

### Java Flight Recorder

*Java Flight Recorder (JFR)* is a feature of the JVM that performs lightweight performance analysis of applications while they are running.

JFR collects a set of event data, the data stream is held in a circular buffer, so only the most recent events are available.

By default, JFR is set up so that it has very low overhead: an impact below 1% of the program’s performance.

JFR is initially disabled. To enable it, add the flag `-XX:+FlightRecorder` to the command line of the application (In Oracle's JDK 8, you must specify `XX:+UnlockCommercialFeatures` prior to it). 

If you forget to include these flags, you can use `jinfo` to change their values and enable JFR.

Flight recordings are made in one of two modes: either for a fixed duration (1 minute in this case) or continuously.

We can start JFR when the program initially begins by `-XX:StartFlightRecording=string` flag. Or, use `jcmd <process_id> JRF.start [options_list]` to start a recording during a run, use `jcmd <process_id> JRF.dump [options_list]` to dump current data in the circular buffer, and use `jcmd <process_id> JRF.stop [options_list]` to abort a recording in process.

JFR is useful in performance analysis, but it is also useful when enabled on a production system so that you can examine the events that led up to a failure.

### Java Mission Control

The usual tool to examine JFR recordings is *Java Mission Control (jmc)*.