---
date: "2021-08-27T22:22:46+08:00"
title: "Java 中的 hashCode() 与 equals()"
authors: ["zhannicholas"]
categories:
  - Java
tags:
  - Java
draft: false
toc: true
---

有一道经典的 Java 面试题叫：重写了 `equals()`，为什么还要重写 `hashCode()`？

> 不幸的是，笔者最近也被问到这个问题的变种了。当时面试官的提问点有点奇葩，问我这两个方法在被调用时谁先谁后的问题。笔者当时想，这面试官是不是八股文看多了，连这两方法调用先后都问出来了吗？严格上来说，`equals()` 和 `hashCode()` 在绝大多数情况下都是单独调用的，只有在像 `HashMap` 这样的数据结构的内部实现中，才会存在方法调用的先后关系。笔者当时也没完全搞清楚面试官到底想问什么，所以就象征性的回答了 `hashCode()` 先调用。今天，笔者突然想到这个问题，感觉当时面试官想问的是 `HashMap` 内部实现时对这两个方法的依赖情况。

在 Java 中，一切皆对象。并且所有的对象都直接或间接地继承自 `java.lang.Object`。`Object` 类定义了一系列 Java 对象所共有的方法，`hashCode()` 和 `equals()` 就在其中。

## hashCode()

{`hashCode()`](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/lang/Object.html#hashCode()) 方法用于返回对象的哈希值。`Object` 类定义了 `hashCode()` 的契约，这里我直接列出：
> The general contract of hashCode is:
> * Whenever it is invoked on the same object more than once during an execution of a Java application, the hashCode method must consistently return the same integer, provided no information used in equals comparisons on the object is modified. This integer need not remain consistent from one execution of an application to another execution of the same application.
> * If two objects are equal according to the equals(Object) method, then calling the hashCode method on each of the two objects must produce the same integer result.
> * It is not required that if two objects are unequal according to the equals(Object) method, then calling the hashCode method on each of the two objects must produce distinct integer results. However, the programmer should be aware that producing distinct integer results for unequal objects may improve the performance of hash tables.

## equals()

[`equals()`](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/lang/Object.html#equals(java.lang.Object)) 方法用来判断两个对象在是否相等。它与 `==` 有着本质区别：`==` 比较的是两个对象的内存地址，即判断它们是否是同一个对象，而 `equals()` 是判断两个对象在逻辑上是否相等。`Object` 类也同样定义了 `equals()` 的契约，我还是直接列出：
> he equals method implements an equivalence relation on non-null object references:
> * It is reflexive: for any non-null reference value x, x.equals(x) should return true.
> * It is symmetric: for any non-null reference values x and y, x.equals(y) should return true if and only if y.equals(x) returns true.
> * It is transitive: for any non-null reference values x, y, and z, if x.equals(y) returns true and y.equals(z) returns true, then x.equals(z) should return true.
> * It is consistent: for any non-null reference values x and y, multiple invocations of x.equals(y) consistently return true or consistently return false, provided no information used in equals comparisons on the objects is modified.
> * For any non-null reference value x, x.equals(null) should return false.
> Note that it is generally necessary to override the hashCode method whenever this method is overridden, so as to maintain the general contract for the hashCode method, which states that equal objects must have equal hash codes.

注意：这里用了一个修饰词 `generally`（通常）。也就是说，我们在重写 `equals()` 之后是可以不重写 `hashCode()` 的。只是这样会引发一个问题，不重写就违反了 `hashCode()` 的契约，因为当两个对象 `equals` 时，它们的哈希值也应该是一样的。这在 `HashMap` 这一类数据结构中就会引起问题，典型的问题就是内存泄露。

## hashCode() 和 equals() 重写不当造成的内存泄露

我们先来看一段代码：

```java
class Key {
  String name;
  public Key(String name) {
    this.name = name;
  }
}

class HashMapMemoryLeakDemo {
  public static void main(String[] args) {
    Map<Key, Integer> map = new HashMap<>();
    map.put(new Key("1"), 1);
    map.put(new Key("2"), 2);
    map.put(new Key("3"), 3);
    System.out.println(map.get(new Key("1")));
  }
}
```
程序的输出结果是 `null`。为什么不是 `1` 呢？因为 `hashCode()` 是一个 native 方法，它的实现取决于具体的 JVM 实现。一些 JVM 会将 `hashCode()` 实现为对象在内存中的地址。上面代码在从 map 中取值的时候使用了一个新创建的对象作为 key，所以会返回 null。类似地，我们使用 `map.remove(new Key("1"))` 也无法将最初用 `new Key("1")` 创建的那个对象从 map 中移除。久而久之，就会出现内存泄露。

## hashCode 和 equals() 在 HashMap 中的使用

`HashMap` 底层的数据结构是一个 `table` ，定义如下：
```java
transient Node<K,V>[] table;
```
这个 `table` 就是我们传统意义上的哈希表。有哈希表就有可能出现哈希冲突，`HashMap` 采用链表（或红黑树）来解决哈希冲突。当链表长度大于 8 并且容量大于 64 时，链表结构会转换成红黑树结构。`Node` 表示链表中的节点，同时也被红黑树节点 `TreeNode` 间接继承。我们将`table` 数组中的元素称为哈希桶，整个 `HashMap` 的组成结构如下图所示：

![HashMap 内部结构](/images/java/java_lang/hashmap-internal-structure.png)

知道这些之后，就可以尝试回答文章开头那个问题了。`HashMap` 通过哈希函数将 `<K, V>` 分散到不同的哈希桶中。然而由于哈希冲突的存在，一个哈希桶中可能放有多个节点。在查找元素的时候，首先会通过哈希函数得到一个哈希值，通过哈希值定位到哈希桶。`HashMap` 中的哈希函数是这样的：
```java
static final int hash(Object key) {
    int h;
    return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
}
```
这里就用到了 `key` 的 `hashCode()`。找到哈希桶之后，会接着遍历桶中所有节点，通过 `key` 的 `equals()` 来判断当前节点是否就是我们要查找的节点。

这应该就是“If a.equals(b), then a.hashCode() == b.hashCode(), not vice versa.” 的原因了。到了这里，也不难回答为什么重写 `equals()` 就要重写 `hashCode()` 这个问题了。答案的核心就在于哈希表和哈希冲突。