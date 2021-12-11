---
date: "2021-12-10T21:59:04+08:00"
title: "Java Performance: Java SE API Tips"
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

## Strings

Strings are (unsurprisingly) the most common Java object.

### Compact Strings

In Java 8, all strings are encoded as arrays of 16-bit characters, regardless of the encoding of the string. This is wasteful, because most Western locales can encode strings into 8-bit byte arrays.

In Java 11, strings are encoded as arrays of 8-bit bytes unless they explicitly need 16-bit characters; these strings are known as **compact strings**. This feature is controlled by the `-XX:+CompactStrings` flag, which is true by default.

### Duplicate Strings and String Interning

Since strings are immutable, it is often better to reuse the existing strings. The duplicate strings can be removed in three ways:
* Performing automatic deduplication via G1 GC
* Using the `intern()` method of the `String` class to create the canonical version of the string
* Using a custom method to create a canonical version of the string

#### String Deduplication

The simplest mechanism is to let the JVM find the duplicate strings and deduplicate them: arrange for all references to point to a single copy and then free the remaining copies. This is possible only when using G1 GC and only when specifying the `-XX:+UseStringDeduplication` flag (which by default is false).

String deduplication is not enabled by default for three reasons. First, it requires extra processing during the young and mixed phases of G1 GC, making them slightly longer. Second, it requires an extra thread that runs concurrently with the application, potentially taking CPU cycles away from application threads. And third, if there are few deduplicated strings, the memory use of the application will be higher (instead of lower); this extra memory comes from the bookkeeping involved in tracking all the strings to look for duplications.

If you want to see how string deduplication is behaving in your application, run it with the `-XX:+PrintStringDeduplicationStatistics` flag in Java 8, or the `-Xlog:gc+stringdedup*=debug` flag in Java 11.

The point at which the tenured string is eligible for collection is controlled via the `-XX:StringDeduplicationAgeThreshold=N` flag, which has a default value of 3.

#### String Interning

The typical way to handle duplicate strings at a programmatic level is to use the `intern()` method of the `String` class.

Interned strings are held in a special hash table that is in native memory (though the strings themselves are in the heap). This native hash table has a fixed size (the default value is 60,013 in Java 8 and 65,536 in Java 11). and you can set it when the JVM starts by using the flag `-XX:StringTableSize=N`.

The performance of the `intern()` method is dominated by how well the string table size is tuned. In order to see how the string table is performing, run your application with the `-XX:+PrintStringTableStatistics` argument (which is false by default). 

#### String Concatenation

Don’t be afraid to use concatenation when it can be done on a single (logical) line, but never use string concatenation inside a loop unless the concatenated string is not used on the next loop iteration. Otherwise, always explicitly use a StringBuilder object for better performance.

## Buffered I/O

For file-based I/O using binary data, always use `BufferedInputStream` or `BufferedOutputStream` to wrap the underlying file stream. For file-based I/O using character (string) data, always wrap the underlying stream with BufferedReader or BufferedWriter.

When you convert between bytes and characters, operating on as large a piece of data as possible will provide the best performance.

## Classloading

The performance of classloading is the bane of anyone attempting to optimize either program startup or deployment of new code in a dynamic system.

**Class data sharing (CDS)** is a mechanism whereby the metadata for classes can be shared between JVMs. The first thing required to use CDS is a shared archive of classes. The second step is to use that class list to generate the shared archive like this:
```shell
$ java -Xshare:dump -XX:SharedClassListFile=filename \
    -XX:SharedArchiveFile=myclasses.jsa \
    ... classpath arguments ...
```
Finally, you use the shared archive to run the application like this:
```shell
$ java -Xshare:auto -XX:SharedArchiveFile=myclasses.jsa ... other args ...
```
The -Xshare command has three possible values:
* `off`: Don’t use class data sharing.
* `on`: Always use class data sharing.
* `auto`: Attempt to use class data sharing, but if for some reason the archive cannot be mapped, the application will proceed without it.

CDS will also save us some memory since the class data will be shared among processes.

## Random Numbers

Java comes with three standard random number generator classes: `java.util.Random`, `java.util.concurrent.ThreadLocalRandom`, and `java.security.SecureRandom`. These three classes have important performance differences.

The difference between the `Random` and `ThreadLocalRandom `classes is that the main operation (the `nextGaussian() `method) of the `Random` class is synchronized.

The difference between those classes and the `SecureRandom` class lies in the algorithm used. The `Random` class (and the `ThreadLocalRandom` class, via inheritance) implements a typical pseudorandom algorithm. While those algorithms are quite sophisticated, they are in the end deterministic. If the initial seed is known, it is possible to determine the exact series of numbers the engine will generate.

The `SecureRandom` class uses a system interface to obtain a seed for its random data. This is known as *entropy-based randomness* and is much more secure for operations that rely on random numbers.

On Linux systems, these two sources are */dev/random* (for seeds) and */dev/urandom* (for random numbers). The two systems handle that differently: */dev/random* will block until it has enough system events to generate the random data, and */dev/urandom* will fall back to a pseudorandom number generator (PRNG). The common consensus is use */dev/random* for seeds and */dev/urandom* for everything else.

## Java Native Interface

Performance tips about Java SE (particularly in the early days of Java) often say that if you want really fast code, you should use native code. In truth, if you are interested in writing the fastest possible code, avoid the Java Native Interface (JNI).

Well-written Java code will run at least as fast on current versions of the JVM as corresponding C or C++ code (it is not 1996 anymore). When an application is already written in Java, calling native code for performance reasons is almost always a bad idea.

## Logging

We should keep three basic principles in mind for application logs:
* First is to keep a balance between the data to be logged and level at which it is logged.
* The second principle is to use fine-grained loggers. it should be possible to enable small subsets of messages in a production environment without affecting the performance of the system.
* The third principle to keep in mind when introducing logging to code is to remember that it is easy to write logging code that has unintended side effects, even if the logging is not enabled.

## Lambdas and Anonymous Classes

The choice between using a lambda or an anonymous class should be dictated by ease of programming, since there is no difference between their performance.

Lambdas are not implemented as anonymous classes, so one exception to that rule is in environments where classloading behavior is important; lambdas will be slightly faster in that case.

## Stream and Filter Performance

One important performance feature of streams is that they can automatically parallelize code.

The first performance benefit from streams is that they are implemented as lazy data structures.

One reason, then, that filters can be so much faster than iterators is simply that they can take advantage of algorithmic opportunities for optimizations: the lazy filter implementation can end processing whenever it has done what it needs to do, processing less data.
