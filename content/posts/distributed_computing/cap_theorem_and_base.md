---
date: "2021-08-17T00:54:37+08:00"
title: "CAP 定理与 BASE 理论"
authors: ["zhannicholas"]
categories:
  - 分布式计算
tags:
  - 分布式计算
draft: false
toc: true
mathjax: true
---

## CAP 定理

计算机科学家 Eric Brewer 指出：一个分布式系统最多只能同时满足一致性（Consistency）、可用性（Availability）和分区容错性（Partition Tolerance）这三项中的两项。这就是 **CAP 定理**，也叫 Brewer 定理。CAP 定理是分布式系统发展的理论基石，对分布式系统的发展有着广泛而深远的影响。

![CAP 定理](/images/distributed_computing/cap-theorem.png)

**一致性** 是指所有节点在同一时刻的数据都是相同的，所有节点都拥有最新版本的数据。也就是说，在同一时刻，不管访问系统中的哪个节点，所得到的数据不仅是一样的，而且是最新的。

**可用性** 是指系统总能对客户端的请求给予响应。系统并不保证响应包含的数据一定是最新的，数据可能是老旧的甚至错误的，但响应是一定会有的。从客户端来看，它发出去的请求总是有响应的，不会出现整个系统无法连接、超时或无响应的情况。

**分区容错性** 是指当系统中的部分节点出现消息丢失或分区故障时，系统仍然能够继续对外提供服务。在分布式环境中，每个服务节点都是不可靠的。当某些节点发生故障，或节点与节点之间的通信出现异常时，系统就出现了分区问题。从系统本身来看，当分区问题出现时，它仍然要对外提供稳定服务。而对于客户端而言，系统的分区问题对它来说是透明的，客户端并不会感受到系统的分区问题。

### CAP 定理的证明

根据 CAP 定理，分布式系统中的一致性、可用性和分区容错性不可兼得，最多只能满足其中两点。下面用只有两个服务器的情况来简单证明一下。假定我们有一个分布式系统，它由 node1 和 node2 两个节点组成。在最开始的时候，两个节点之间的数据 X 的值相同，都是 $v_0$。此时，不管用户是访问 node1 还是 node2，所得 X 的值都是 $v_0$。

![CAP 定理证明——初始情况](/images/distributed_computing/cap-proof-at-the-begining.png)

在正常的情况下，node1 和 node2 此时都在正常工作，相互之间通信良好。某一时刻，用户向 node1 执行了更新操作，node1 中数据 X 的值被修改成了 $v_1$。此时，node1 会发送一个消息 M 给 node2，告知 node2 将 X 的值修改为 $v_1$。node2 在收到消息 M 之后， X 的值也会被修改成 $v_1$。此后，用户不管是请求 node1 还是 node2，所得 X 的值都是 $v_1$。

![CAP 定理证明——正常情况](/images/distributed_computing/cap-proof-normal-case.png)

如果网络出现了分区，node1 与 node2 之间无法正常进行通信，消息 M 无法抵达 node2，那么 node1 和 node2 的数据就会出现不一致。

![CAP 定理证明——异常情况](/images/distributed_computing/cap-proof-something-wrong.png)

此时，若用户请求 node2，由于 node1 与 node2 通信故障，node2 无法给用户返回正确的结果 $v_1$，此时有两种处理方案：

1. 牺牲一致性，node2 向用户返回老数据 $v_0$
2. 牺牲可用性，node2 阻塞用户请求，直到完成数据同步

到这里，CAP 定理的就证明完了。分析过程说明，当系统出现分区时，一致性与可用性只能二选一。

### CAP 定理的权衡

根据 CAP 定理，分布式系统无法同时满足一致性、可用性和分区容错性。那么在构建分布式系统时，我们应该如何取舍呢？

#### CA

这种方案不支持分区容错，也就是说节点和网络一直会处于理想状态，不会发生故障。但是，分布式系统中的故障是客观存在的，系统中的节点越多，出错的概率就越大。所以 CA 是不切实际的。

#### CP

这种方案放弃了可用性，在系统出现分区时，服务会一直阻塞，直到数据达成一致。在此期间，系统对外是不可用的。CP 适合对数据一致性比较敏感的业务场景。我们常用的 Zookeeper 就是优先保证 CP。

#### AP

牺牲一致性，换取可用性。当系统出现分区时，用户的请求依然可以得到响应，只是数据可能是老旧的数据。整个系统依然对外提供稳定服务，用户体验会好于 CP。

### CAP 的问题和误区

虽然 CAP 定理极大地促进了分布式系统的发展，但是人们在分布式系统演进的过程中发现，CAP 过于理想化，存在不少问题和误区。

由于网络分区问题肯定存在，很多人在设计分布式系统时就局限在了 CP 和 AP 的二选一当中。但实际上，分布式系统中的分区问题出现的概率并不高。在没有出现分区问题时，不应该只选择一致性或可用性，而应该同时提供。Brewer 本人也在 CAP 定理提出的 12 年（2012 年）[发文](https://www.infoq.com/articles/cap-twelve-years-later-how-the-rules-have-changed/) 指出人们在使用 CAP 时存在的误区。

此外，在同一个系统中，不同业务在分区出现时对一致性和可用性的选择取可能是不同的。所以，在设计分布式系统时，要根据实际的业务场景灵活变通。CAP 作为指导分布式系统设计的理论，告诉我们的是实际设计时要考虑的因素，而不是让我们进行绝对的选择。

## BASE 理论

在设计分布式系统时，我们往往需要在一致性和可用性之间权衡，并不一定是二选一。CAP 定理中的一致性强调的是强一致性，但在实际运用中，我们也可能选择弱一致性或最终一致性。这就引出了 BASE 理论，它是 CAP 的延伸。

BASE 是 Basically Available（基本可用）、Soft State（软状态）和 Eventually Consistent（最终一致）的简写。它的基本思想是：权衡分布式系统的各个功能，尽量保证系统的稳定可用，即便在出现局部故障和异常时，也确保系统的主体功能可用，确保系统的最终一致性。

**基本可用**：当分布式系统出现故障时，允许损失部分可用性，保证核心功能可用。

**软状态**：允许系统出现中间状态。当系统出现分区时，虽然各分区的数据处于不一致状态，但这并不影响系统对外提供服务。

**最终一致性**：分布式系统不需要实时保持强一致状态，当系统发生故障时，数据的不一致是可以容忍的。但在故障恢复后，要进行数据的同步，最终达到一致性状态。

## 参考资料

1. Wikipedia. [CAP theorem](https://en.wikipedia.org/wiki/CAP_theorem).
2. [Brewer's CAP Theorem](https://www.julianbrowne.com/article/brewers-cap-theorem).
3. Eric Brewer. [CAP Twelve Years Later: How the "Rules" Have Changed](https://www.infoq.com/articles/cap-twelve-years-later-how-the-rules-have-changed/).