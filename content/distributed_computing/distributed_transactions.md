---
date: "2021-08-17T22:13:51+08:00"
title: "分布式事务"
authors: ["zhannicholas"]
categories:
  - 分布式计算
tags:
  - 分布式计算
draft: false
toc: true
---

我们常说事务是一组操作，这组操作要么全部成功，要么全部不成功。当事务失败时，事务内所作的所有变更都会被回滚。在单机环境中，若多个线程同时对数据进行操作，事务就是对数据的完整性的保障。类似地，在分布式环境中处理数据变更的时候，需要通过分布式事务来保证数据的正确完整，防止数据变更请求在部分节点上的执行失败而导致的数据不一致问题。

为了实现分布式事务，人们开发出了很多经典的分布式一致性算法，例如 2PC、3PC、TCC 等。

## 2PC

2PC 是两阶段提交（Two-phase Commit）的简称，它是一种实现分布式事务的算法。顾名思义，2PC 中事务的提交过程分两个阶段来完成：准备（Prepare）阶段和提交（Commit）阶段。

**准备阶段**：协调者向所有参与者发送事务内容，询问其是否可以提交事务，然后等待所有参与者的答复。参与者执行事务（但不提交），若执行成功，则给协调者反馈 YES，若执行失败，则给协调者反馈 NO。

**提交阶段**：当协调者收到所有参与者的反馈信息后，会对信息进行统计。只有当所有的参与者都反馈 YES 时，协调者才会给所有的参与者发送提交事务的命令。否则，协调者会给所有的参与者发送 abort 请求，回滚事务。

虽然 2PC 可以有效保证分布式环境中的事务，但算法本身也存在不少缺陷：

* 性能问题。在算法的执行过程中，所有的参与者都处于阻塞状态。只有在协调者通知参与者提交或回滚，参与者在本地执行完相应的操作之后，资源才会被释放。
* 协调者单点问题。若协调者发生故障，参与者收不到提交或回滚的通知，就会一直处于锁定状态。
* 消息丢失导致的数据不一致问题。在提交阶段，若系统出现分区，部分参与者没有收到提交消息，各节点的数据就会变得不一致。

## 3PC

由于 2PC 存在各种问题，人们对它进行了改进，衍生出了新的协议。三阶段提交（Three-Phase Commit, 3PC）就是 2PC 的改进版本，它将事务的提交过程分为了 CanCommit、PreCommit 和 DoCommit 三个阶段。


**CanCommit**：协调者向所有参与者发送包含事务内容的 CanCommit 请求，询问其是否可以提交事务，然后等待所有参与者的答复。参与者收到请求后，判断自己能够执行事务。若参与者认为自己可以提交，则反馈 YES ，否则反馈 NO。

**PreCommit**：协调者接收所有参与者的反馈消息，根据反馈消息决定是否中断事务。当所有参与者都反馈 YES 时，协调者向所有参与者发出 PreCommit 请求，参与者收到请求后执行事务（但不提交），执行成功后向协调者反馈 Ack 表示已经准备好提交事务，否则反馈 NO。若有参与者在 CanCommit 阶段返回 NO 或协调者在超时之前未收到任何反馈，协调者就会向所有的参与者发出 abort 请求，请求中断事务。

**DoCommit**：如果 PreCommit 阶段中的所有参与者都反馈 Ack，协调者就会给所有的参与者发送 DoCommit 请求，参与者收到之后会进行真正的事务提交。反之，如果 PreCommit 阶段有一个参与者反馈 NO 或者协调者在超时之前没有收到反馈，则会向所有的参与者发送 abort 请求，中断事务。

需要注意的是：只要进入到了 DoCommit 阶段，无论协调者出现故障，还是协调者与参与者之间的通信出现问题，都会导致参与者无法收到协调者发出的 DoCommit 请求或 abort 请求。这是，参与者会在等待超时之后，主动提交事务。

与 2PC 相比，3PC 通过超时机制降低了阻塞范围并解决了协调者单点问题，但还是没有完全解决数据不一致的问题。

## 参考资料

1. Wikipedia. [Two-phase commit protocol](https://en.wikipedia.org/wiki/Two-phase_commit_protocol).
2. Wikipedia. [Three-phase commit protocol](https://en.wikipedia.org/wiki/Three-phase_commit_protocol).