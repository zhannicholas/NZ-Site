---
date: "2021-12-09T20:17:09+08:00"
title: "Java Performance: Java Servers and Database Performance Best Practices"
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


## Java Servers

Scaling servers is mostly about effective use of threads, and that use requires event-driven, nonblocking I/O.

Some newer frameworks offer programming models based on reactive programming. At their cores, **reactive programming** is based on handling asynchronous data streams using an event-based paradigm.

### Java NIO Overview

Blocking I/O requires that the server has a one-to-one correspondence between client connections and server threads; each thread can handle only a single connection. This is particularly an issue for clients that want to use HTTP keepalive to avoid the performance impact of creating a new socket with every request.

NIO is classic event-driven programming: when data on a socket connection is available to be read, a thread (usually from a pool) is notified of that event. That thread reads the data, processes it (or passes the data to yet another thread to be processed), and then returns to the pool.

### Server Containers

The threads notify the system call when I/O is available and are called **selector threads**. Then a separate thread pool of **worker threads** handles the actual request/response to a client after the selector notifies them that I/O is pending for the client.

The selector and worker threads can be set up in various ways:
* Selector and worker thread pools can be separate. The selectors wait for notification on all sockets and hand off requests to the worker thread pool.
* Alternately, when the selector is notified about I/O, it reads (perhaps only part of) the I/O to determine information about the request. Then the selector forwards the request to different server thread pools, depending on the type of request.
* A selector pool accepts new connections on a `ServerSocket`, but after the connections are made, all work is handled in the worker thread pool. A thread in the worker thread pool will sometimes use the `Selector` class to wait for pending I/O about an existing connection, and it will sometimes be handling the notification from a worker thread that I/O for a client is pending (e.g., it will perform the request/response for the client).
* There needn’t be a distinction at all between threads that act as selectors and threads that handle requests. A thread that is notified about I/O available on a socket can process the entire request. Meanwhile, the other threads in the pool are notified about I/O on other sockets and handle the requests on those other sockets.

### Async Rest Servers

An alternative to tuning the request thread pool of a server is to defer work to another thread pool. 

There are three reasons you would use an async response:
* To introduce more parallelism into the business logic.
* To limit the number of active threads.
* To properly throttle the server.

### JSON Processing

Given a series of JSON strings, a program must convert those strings into data suitable for processing by Java. This is called either **marshaling** or **parsing**, depending on the context and the resulting output. If the output is a Java object, the process is called **marshaling**; if the data is processed as it is read, the process is called **parsing**. The reverse—producing JSON strings from other data—is called **unmarshaling**.

## Database Performance Best Practices

There is no corresponding standard for NoSQL databases, and hence there is no standard platform support for accessing them.

### JDBC

The JDBC driver is the most important factor in the performance of database applications.

JDBC drivers come in four types (1–4). The driver types in wide use today are type 2 (which uses native code) and type 4 (which is pure Java).
* Type 1 drivers provide a bridge between Open Database Connectivity (ODBC) and JBDC. If an application must talk to a database using ODBC, it must use this driver. Type 1 drivers generally have quite bad performance.
* Type 2 drivers use a native library to access the database.
* Type 3 drivers are, like type 4 drivers, written purely in Java, but they are designed for a specific architecture in which a piece of middleware (sometimes, though usually not, an application server) provides an intermediary translation.
* Type 4 drivers are pure Java drivers that implement the wire protocol that the database vendor has defined for accessing their database.

Connections to a database are time-consuming to create, so JDBC connections are another prototypical object that you should reuse in Java.

In most circumstances, code should use a `PreparedStatement` rather than a `Statement` for its JDBC calls. This aids performance: prepared statements allow the database to reuse information about the SQL that is being executed. That saves work for the database on subsequent executions of the prepared statement. Prepared statements also have security and programming advantages, particularly in specifying parameters to the call.

Prepared statement pools operate on a per connection basis.

The size of the connection pool also matters because it is caching those prepared statements, which take up heap space (and often a lot of heap space).

Applications that process large amounts of data from a query should consider changing the fetch size of the data.

A trade-off exists between loading too much data in the application (putting pressure on the garbage collector) and making frequent database calls to retrieve a set of data.

### Transactions

Database transactions have two performance penalties. First, it takes time for the database to set up and then commit the transaction. Second, during a database transaction, it is common for the transaction to obtain a lock for a particular set of data.

Transactions are expensive to commit, so one goal is to perform as much work in a transaction as is possible. Unfortunately, that principle is completely at odds with another goal: because transactions can hold locks, they should be as short as possible.

Committing all the data at once offers the fastest performance.

Here are the basic transaction isolation modes (in order from most to least expensive):
* TRANSACTION_SERIALIZABLE: This is the most expensive transaction mode; it requires that all data accessed within the transaction be locked for the duration of the transaction.
* TRANSACTION_REPEATABLE_READ: This requires that all accessed data is locked for the duration of the transaction. However, other transactions can insert new rows into the table at any time. This mode can lead to phantom reads
* TRANSACTION_READ_COMMITTED: This mode locks only rows that are written during a transaction. This leads to nonrepeatable reads
* TRANSACTION_READ_UNCOMMITTED: This is the least expensive transaction mode. No locks are involved, so one transaction may read the written (but uncommitted) data in another transaction. This is known as a dirty read.

### JPA

The performance of JPA is directly affected by the performance of the underlying JDBC driver, and most of the performance considerations regarding the JDBC driver apply to JPA. JPA has additional performance considerations.

JPA achieves many of its performance enhancements by altering the bytecode of the entity classes.

In JDBC, we looked at two critical performance techniques: reusing prepared statements and performing updates in batches.

One common way to optimize writes to a database is to write only those fields that have changed.

The JPA Query Language (JPQL) doesn’t allow you to specify fields of an object to be retrieved.

#### JPA Caching

JPA is designed with that architecture in mind. Two kinds of caches exist in JPA. Each entity manager instance is its own cache: it will locally cache data that it has retrieved during a transaction. It will also locally cache data that is written during a transaction; the data is sent to the database only when the transaction commits.

When an entity manager commits a transaction, all data in the local cache can be merged into a global cache. The global cache is shared among all entity managers in the application. The global cache is also known as the Level 2 (L2) cache or the second-level cache; the cache in the entity manager is known as the Level 1, L1, or first-level cache.

### Summary

Properly tuning JDBC and JPA access to a database is one of the most significant ways to affect the performance of a middle-tier application. Keep in mind these best practices:
* Batch reads and writes as much as possible by configuring the JDBC or JPA configuration appropriately.
* Optimize the SQL the application issues. For JDBC applications, this is a question of basic, standard SQL commands. For JPA applications, be sure to consider the involvement of the L2 cache.
* Minimize locking where possible. Use optimistic locking when data is unlikely to be contended, and use pessimistic locking when data is contended.
* Make sure to use a prepared statement pool.
* Make sure to use an appropriately sized connection pool.
* Set an appropriate transaction scope: it should be as large as possible without negatively affecting the scalability of the application because of the locks held during the transaction.