---
title: 分布式计算
linkTitle: 分布式计算
menu:
  - sidebar
weight: -250
slug: distributed_computing
---
[分布式计算（Distributed Computing）](https://en.wikipedia.org/wiki/Distributed_computing)是计算机科学的一个分支，专门研究分布式系统（Distributed Systems）。分布式系统是由一组彼此通过网络通信、为了完成共同的目标而一起协调工作的计算机节点组成的系统。例如，我们每天都在使用的[万维网](https://en.wikipedia.org/wiki/World_Wide_Web)就是一个巨大的分布式系统。

可伸缩性（Scalability）分布式系统的核心特点。当我们的系统达到瓶颈时，我们往往需要通过某种手段来提高系统的处理能力。在集中式系统中，系统能力的提升一般是通过升级服务器到中大型机、增加 CPU 核数等硬件升级手段来完成，这就是垂直扩展（Scale vertically）；而在分布式系统中，我们通过增加更多的计算机来提升系统的处理能力，这就是水平扩展（Scale horizontally）。当系统能力过剩时，分布式系统只需减少计算机数量即可，而集中式系统需要更换硬件，相当麻烦。

冗余（Redundancy）也是分布式系统的一大特点。在分布式系统中，多台计算机往往提供相同的服务。当某台机器发生故障时，整个系统并不会瘫痪，其它机器可以顶上来继续提供服务。而单机系统中的服务器故障可能导致整个系统的瘫痪。