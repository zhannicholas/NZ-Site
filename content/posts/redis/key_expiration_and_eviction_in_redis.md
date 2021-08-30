---
date: "2021-08-19T09:52:38+08:00"
title: "Redis 中的 key 过期与淘汰机制"
authors: ["zhannicholas"]
categories:
  - Redis
tags:
  - Redis
draft: false
toc: true
---

作为一个内存数据库，Redis 的容量肯定是有限的。如果 Redis 允许我们不断写入数据而又不作任何清理工作的话，内存迟早要被耗尽。此外，若我们在 Redis 中创建了一个不带过期时间的 key，这个 key 即使不被使用，它也会在我们使用 `DEL` 命令删除它之前一直存在于 Redis 中，这可不是一件好事儿。所以，为 key 设置一个过期时间还是很有必要的。那么，Redis 是如何让 key 过期的呢，它又是如何淘汰过期的 key 的呢？这就是本文要将的主要内容。

## key 过期

我们可以在创建 key 时指定它的存活时间，也可以用 `EXPIRE key seconds [NX|XX|GT|LT]` 命令给 key 设置存活时间。当 key 过期时，它会被自动删除。

Redis 使用 `volatile` 这个术语来描述带有过期时间的 key，我们会在 key 的淘汰策略中再次与这个术语见面。对于不带过期时间的 key，Redis 也有一个专门的术语，那就是 `persistent`。

### 相关命令

Redis 支持不少与 key 过期有关的命令，包括为 key 设置过期时间、查看 key 还有多久过期和移除 key 的过期时间。

#### 为 key 设置过期时间

相关命令有：

* **EXPIRE**：设置 key 的存活时间，单位为秒
* **PEXPIRE**：设置 key 的存活时间，单位为毫秒
* **EXPIREAT**：设置 key 过期的 UNIX 时间戳，单位为秒
* **PEXPIREAT**：设置 key 过期的 UNIX 时间戳，单位为毫秒

`EXPIRE` 和 `PEXPIRE` 设置的是 key 的存活时间（time to live），key 的存活时间会随着时间的流逝而不断减少，当值为 0 时，Redis 就会移除这个 key。`EXPIREAT` 和 `PEXPIRE` 设置的是 key 的过期时间（expire time），当系统的当前 UNIX 时间超过设置的时间后，key 就会被删除。

#### 查看 key 还有多久过期

相关命令有：

* **TTL**：查看 key 的剩余存活时间，单位为秒
* **PTTL**：查看 key 的剩余存活时间，单位为毫秒

#### 移除 key 的过期时间

`PERSIST` 命令可以移除 key 的过期时间，将 key 从 `volatile` 变成 `persistent`。

### 具体做法

Redis 中的 key 有两种过期方式：被动过期和主动过期。

Redis 使用绝对的毫秒级 UNIX 时间戳来存储 key 的过期时间。任何时候，当某个 key 被访问时，如果系统的当前 UNIX 时间超过了它的过期时间，这个 key 就会被动过期。但是，有些 key 可能永远也不会被访问，而它们也需要被过期，这就需要用到主动过期。

Redis 会周期性地从带过期时间的 key 中随机选取一部分进行检测，然后删除其中已经过期的那些 key。实际上，Redis 每秒都会进行十次下面的操作：
1. 从所有带有过期时间的 key 中随机选取 20 个
2. 删除其中过期的那些 key
3. 如果过期的 key 超过 5 个（过期占比大于 25%），继续进入步骤 1

## key 的淘汰机制

当把 Redis 作为缓存使用时，我们通常会是希望 Redis 能够在我们添加新数据时自动淘汰旧的数据。当然，作为一个优秀的缓存组件，Redis 早已考虑到了这些，它还给我们提供了多种不同的淘汰策略。`redis.conf` 中有一个名为 `maxmemory` 的配置项，用来指定 Redis 可使用的内存阈值。当 key 过期，或者 Redis 在执行新命令时发现实际内存占用超过了 `maxmemory` 设置的阈值之后，Redis 就会根据`maxmemory-policy` 配置的淘汰策略淘汰过期或者不活跃的 key，回收内存，供新的 key 使用。`maxmemory=0` 表示不对内存做限制，可以不断存入数据，Redis 被用作内存数据库，适合数据量较小的业务。如果数据量很大，就需要给 `maxmemory` 设置一个合适的值，将 Redis 作为缓存使用。

![Redis key eviction](/images/databases/redis/redis-key-eviction.png "Redis 中的 key 淘汰机制")


### 淘汰策略

Redis 提供了八种淘汰策略：

| 策略（Policy）  | 描述（Description）                                        |
| --------------- | ---------------------------------------------------------- |
| noeviction      | 在插入新数据时，若内存超过限制，则返回错误，不淘汰任何 key |
| allkeys-lru     | 采用 LRU 算法对所有 key 进行淘汰                           |
| allkeys-lfu     | 采用 LRU 算法对所有 key 进行淘汰                           |
| allkeys-random  | 采用随机算法对所有 key 进行淘汰                            |
| volatile-lru    | 采用 LRU 算法对带过期时间的 key 进行淘汰                   |
| volatile-lfu    | 采用 LFU 算法对带过期时间的 key 进行淘汰                   |
| volatile-random | 采用随机算法对带过期时间的 key 进行淘汰                    |
| volatile-ttl    | 淘汰带过期时间的 key 中存活时间最短的 key                  |


八种淘汰策略各有不同的适用场景：`noeviction` 是 Redis 的默认 key 淘汰机制，适用于数据量不太大的场景，因为此时 Redis 被当成了内存数据库使用；随机策略适用于 key 没有明显热点的场景；LRU 淘汰策略适用于数据有冷热读写区分的场景；LFU 也适用于数据有冷热读写区分的场景，且越热的数据的访问频率越高。

需要注意的是：Redis 为了节省内存，并没有实现完整的 LRU 算法和 LFU 算法，而是采用了近似实现。

## 参考资料

1. [Redis Command Reference](https://redis.io/commands).
2. [Redis expires](https://redis.io/commands/expire#appendix-redis-expires).
3. [Using Redis as an LRU cache](https://redis.io/topics/lru-cache).

