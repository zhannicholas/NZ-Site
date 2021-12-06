---
date: "2021-12-06T20:15:55+08:00"
title: "Jit_compiler"
authors: ["zhannicholas"]
categories:
  - 读书笔记
tags:
  - Java
draft: false
toc: true
---

> Notes from *Java Performance, 2nd Edition by Scott Oaks.*

The **just-in-time (JIT) compiler** is the heart of the Java Virtual Machine; nothing controls the performance of your application more than the JIT compiler.

## Just-in-Time Compilers: An Overview

Computers can execute only a relatively few, specific instructions, which are called **machine code**. All programs that the CPU executes must therefore be translated into these instruction.

There are typically two kinds of programing language:
* *compiled language*, like C++. the program is written, and then a static compiler produces a binary. The assembly code in that binary is targeted to a particular CPU.
* *interpreted language*, like Python. The interpreter translates each line of the program into binary code as that line is executed.

Each system has advantages and disadvantages. Programs written in interpreted languages are portable, but might run slowly. 

Programs written in compiled language are opposite. A good compiler takes several factors into account when it produces a binary. In addition, a good compiler will produce a binary that executes the statement to load the data, executes other instructions, and then—when the data is available—executes the addition. An interpreter that is looking at only one line of code at a time doesn’t have enough information to produce that kind of code.

For these (and other) reasons, interpreted code will almost always be measurably slower than compiled code: compilers have enough information about the program to provide optimizations to the binary code that an interpreter simply cannot perform. However, interpreted code does have the advantage of portability.

Java attempts to find a middle ground among them. Java applications are compiled into an intermediate low-level language called *Java bytecode*, which will be runned by the `java` binary. This gives Java the platform independency of an interpreted language. Because it is executing an idealized binary code, the `java` program is able to compile the code into the platform binary as the code executes. This compilation occurs as the program is executed: it happens “just in time.”

Remember, the *Java bytecode* is the key of Java's platform independence, rather than the `java` binary. `java` binary is platform dependent.

## HotSpot Compilation

In a typical program, only a small subset of code is executed frequently, and the performance of an application depends primarily on how fast those sections of code are executed. These critical sections are known as the hot spots of the application; the more the section of code is executed, the hotter that section is said to be.

### Register and Main Memory

One of the most important optimizations a compiler can make involves when to use values from main memory and when to store values in a register.

Retrieving a value from main memory is an expensive operation that takes multiple cycles to complete.

Register usage is a general optimization of the compiler, and typically the JIT will aggressively use registers. 

## Tiered Compilation

Historically, JVM developers (and even some tools) sometimes referred to the compilers by the names `C1` (compiler 1, client compiler) and `C2` (compiler 2, server compiler).

The primary difference between the two compilers is their **aggressiveness** in compiling code. The C1 compiler begins compiling sooner than the C2 compiler does. This means that during the beginning of code execution, the C1 compiler will be faster, because it will have compiled correspondingly more code than the C2 compiler.

The engineering trade-off here is the knowledge the C2 compiler gains while it waits: that knowledge allows the C2 compiler to make better optimizations in the compiled code.

*tiered compilation* can be explicitly disabled with the `-XX:-TieredCompilation` flag (the default value of which is `true`);

## Common Compiler Flags

### Tuning the Code Cache

When the JVM compiles code, it holds the set of assembly-language instructions in the code cache. The code cache has a **fixed size**, and once it has filled up, the JVM is not able to compile any additional code.

The maximum size of the code cache is set via the `-XX:ReservedCodeCacheSize=N` flag. The code cache is managed like most memory in the JVM: there is an initial size (specified by `-XX:InitialCodeCacheSize=N`). Allocation of the code cache size starts at the initial size and increases as the cache fills up. 

If a 1 GB code cache size is specified, the JVM will reserve 1 GB of native memory. That memory isn’t allocated until needed, but it is still reserved, which means that sufficient virtual memory must be available on your machine to satisfy the reservation.

In Java 11, the code cache is segmented into three parts:
* Nonmethod code
* Profiled code
* Nonprofiled code

### Inspecting the Compilation Process

The `-XX:+PrintCompilation` flag (which by default is `false`) gives us visibility into the workings of the compiler. If `PrintCompilation` is enabled, every time a method (or loop) is compiled, the JVM prints out a line with information about what has just been compiled.

JIT compilation is an asynchronous process: when the JVM decides that a certain method should be compiled, that method is placed in a queue.

Code that needs to be compiled sits in a compilation queue. The more code in the queue, the longer the program will take to achieve optimal performance.

### Tiered Compilation Levels

There are five levels of compilation, because the C1 compiler has three levels. So the levels of compilation are as follows:
* 0: Interpreted code
* 1: Simple C1 compiled code
* 2: Limited C1 compiled code
* 3: Full C1 compiled code
* 4: C2 compiled code

### Deoptimization

**Deoptimization** means that the compiler has to “undo” a previous compilation. The effect is that the performance of the application will be reduced—at least until the compiler can recompile the code in question.

Deoptimization occurs in two cases: when code is `made not entrant` and when code is `made zombie`.

#### Not entrant code

Two things cause code to be made not entrant. One is due to the way classes and interfaces work, and one is an implementation detail of tiered compilation.

Aside from a momentary point where the trap is processed, deoptimization has not affected the performance in any significant way.

When code is compiled by the C2 compiler, the JVM must replace the code already compiled by the C1 compiler. It does this by marking the old code as not entrant and using the same deoptimization mechanism to substitute the newly compiled (and more efficient) code.

#### Deoptimizing zombie code

When the code for certain Java class was made not entrant, but the objects of that class remained. Eventually all those objects were reclaimed by GC. When that happened, the compiler noticed that the methods of that class were now eligible to be marked as zombie code.

## Advanced Compiler Flags

### Compilation Thresholds

Compilation is based on two counters in the JVM: the number of times the method has been called, and the number of times any loops in the method have branched back. *Branching back* can effectively be thought of as the number of times a loop has completed execution, either because it reached the end of the loop itself or because it executed a branching statement like `continue`.

When tiered compilation is disabled, standard compilation is triggered by the value of the `-XX:CompileThreshold=N` flag

### Compilation Threads

The number of compiler threads can be adjusted by setting the `-XX:CICompilerCount=N` flag. For tiered compilation, one-third (but at least one) threads will be used to process the C1 compiler queue, and the remaining threads (but also at least one) will be used to process the C2 compiler queue.

### Inlining

One of the most important optimizations the compiler makes is to inline methods. Inlining is enabled by default. It can be disabled using the `-XX:-Inline` flag.

### Escape Analysis

The C2 compiler performs aggressive optimizations if escape analysis is enabled (`-XX:+DoEscapeAnalysis`, which is true by default). In rare cases, it will get things wrong.

## Tiered Compilation Trade-offs

### The `javac` Compiler

Most important is that the `javac` compiler—with one exception—doesn’t really affect performance at all. In particular:
* The `-g` option to include additional debugging information doesn’t affect performance.
* Using the `final` keyword in your Java program doesn’t produce faster compiled code.
* Recompiling with newer `javac` versions doesn’t (usually) make programs any faster.

JDK 11 introduces a new way of doing string concatenation that can be faster than previous versions, but it requires that code be recompiled in order to take advantage of it. That is the exception to the rule here.

### The GraalVM

The **GraalVM** is a new virtual machine. It provides a means to run Java code, of course, but also code from many other languages.

## Precompilation

### Ahead-of-Time Compilation

**Ahead-of-time (AOT) compilation** was first available in JDK 9 for Linux only, but in JDK 11 it is available on all platforms. AOT compilation allows you to compile some (or all) of your application in advance of running it. This compiled code becomes a shared library that the JVM uses when starting the application.

To use AOT compilation, you use the `jaotc` tool to produce a shared library containing the compiled classes that you select. Then that shared library is loaded into the JVM via a runtime argument.



### GraalVM Native Compilation

AOT compilation was beneficial for relatively large programs but didn’t help (and could hinder) small, quick-running programs. The GraalVM, on the other hand, can produce full native executables that run without the JVM. These executables are ideal for short-lived programs.