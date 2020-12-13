---
title: "完全平方数"
date: 2018-08-07T07:15:52+08:00
draft: false
mathjax: true
tags: 
    - Leetcode
categories:
    - Leetcode
author: ["zhannicholas"]
---

这是Leetcoce上的第[279](https://leetcode-cn.com/problems/perfect-squares/description/)个问题，解题的方法很有启发意义，以此备忘。

# 题目描述

给定正整数 n，找到若干个完全平方数（比如 1, 4, 9, 16, ...）使得它们的和等于 n。你需要让组成和的完全平方数的个数最少。

示例 1:

```example
输入: n = 12
输出: 3
解释: 12 = 4 + 4 + 4.
```

示例 2:

```example
输入: n = 13
输出: 2
解释: 13 = 4 + 9.
```

# 解决方案

## 一个错误的方法

最开始的想法是依次对每个数进行开方操作，这样能够找到比它小的最接近它的完全平方数。代码如下：

```java
private int numSquares1(int n){
        int step = 0;
        while(n > 0){
            n -= Math.pow((int)(Math.sqrt(n)), 2);
            step ++;
        }
        return step;
    }
```

这段代码使用的是贪心算法的思想，每次找比 **`n`** 小的最大的完全平方数。错误的原因是：这个贪心策略在这里 **并不适用** 。题目中就有一个反例：

```example
12 = 4 + 4 + 4
```

## 一个正确的方式

贪心策略不适用，又不想使用暴力解法。那么有没有好一点的解题方法呢？答案是有的：可以把原问题转化为一个 **图论** 中的问题。转化方法如下：

1. 对于从 **`n`** 到 **`0`** 的每一个数字，让其成为图中的一个顶点；
2. 如果图中的两个数字之间相差一个完全平方数，则连接它们；

![perfect-squares](/images/leetcode/perfect-squares.png)

这样一来，原来的问题就转化为求：**`n`** 到 **`0`** 之间的 **最短路径** 的问题。使用广度优先遍历的策略就可以找出答案。

java代码如下：

```java
/**
     * 最开始是想用贪心算法来求解，但是后来发现贪心算法在这里并不适用。比如:12 = 4 + 4 + 4;
     * 这里可以将问题转化为一个求图中的最短路径的问题：
     *      从n到0,每个数字表示一个节点。如果两个数字之间相差一个完全平方数，则连接它们。
     *      最终会得到一个无权图，此时原问题就转化为求这个无权图中n到0的最短路径。
     * 使用BFS的思想对图进行层序遍历，从n所在层到0所在层
     * @param n     给定的正整数n
     * @return      和为n需要的最少的完全平方数
     */
    private int numSquares(int n){
        if(n <= 0){
            return 0;
        }
        int step = 0;   // 存放最终结果
        Queue<Integer> queue = new LinkedList<>();
        queue.offer(n); // 初始节点n入队
        int size = queue.size();    // 保存当前层的节点数
        while(!queue.isEmpty()){
            if(size == 0){
                size = queue.size();
                step ++;
            }
            int number = queue.poll();  // 队首元素出队
            size --;
            if(number == 0){
                return step;    // 到达终点0，结束程序
            }
            for(int i = 1;number >= i * i;i ++){    // number内还存在完全平方数
                queue.offer(number - i * i);
            }
        }
    }
```

不幸的是：这段代码在Leetcode上 **超时** 了。

于是我改用了 **Pair<>** 对的形式，减少了对上面代码中`size`取值的判断次数，期望程序能快一点。代码如下：

```java
private int numSquares2(int n){
        if(n <= 0){
            return 0;
        }
        int step = 0;   // 存放最终结果
        Queue<Pair<Integer, Integer>> queue = new LinkedList<>();
        queue.offer(new Pair<>(n, 0)); // 初始节点n入队
        while(!queue.isEmpty()){
            Pair<Integer, Integer> pair = queue.poll();  // 队首元素出队
            int number = pair.getKey();
            step = pair.getValue();
            if(number == 0){
                return step;    // 到达终点0，结束程序
            }
            for(int i = 1;number - i * i >= 0;i ++){    // number内还存在完全平方数
                queue.offer(new Pair<>(number - i * i, step + 1));
            }
        }

        return step;
    }
```

然而：还是 **超时** 了。

于是我开始仔细看这一段代码，发现了引起性能问题的最大原因：**对于较大的数字，每次执行for循环的时候，都会往队列中推入很多重复的路径。比如要到达数字1所在的节点，可能从2、5、10、17、26...出发** 。只要减少了重复的路径，程序的性能应该就会有不少的提升。为了解决重复复访问的问题，我新开了一个数组，用来判断某个节点是否已被访问，现在只将没有被访问过的节点推入队列。

java代码如下：

```java
private int numSquares3(int n){
        if(n <= 0){
            return 0;
        }
        int step = 0;   // 存放最终结果
        Queue<Pair<Integer, Integer>> queue = new LinkedList<>();
        queue.offer(new Pair<>(n, 0)); // 初始节点n入队
        boolean[] visited = new boolean[n + 1];    // 用来保存已经访问过的节点
        visited[n] = true;
        while(!queue.isEmpty()){
            Pair<Integer, Integer> pair = queue.poll();  // 队首元素出队
            int number = pair.getKey();
            step = pair.getValue();
            if(number == 0){
                return step;    // 到达终点0，结束程序
            }
            for(int i = 1;number - i * i >= 0;i ++){    // number内还存在完全平方数
                if(!visited[number - i * i]) {
                    queue.offer(new Pair<>(number - i * i, step + 1));
                    visited[number - i * i] = true;     // 更新visited[]
                }
            }
        }

        return step;
    }
```

Accepted!耶~

终于能够看到用时极短的答案是怎么做的了。原来它们使用了 **数论** 的知识。我赶紧去补了一下 **四平方定理** 。

**四平方和定理** ：`任何一个正整数都可以表示成不超过四个整数的平方之和`。

**推论** ： `当n是形如:`\\(4^a(8b + 7)(a >= 0;b >= 0)\\)`n不能表示成3个整数的平方和`

借助这两条定理，我自己实现了一下。
java代码如下：

```java
// 使用四平方和定理及其推论
    private int numSquares4(int n){
        while(n % 4 == 0){
            n /= 4;
        }
        if(n % 8 == 7){
            return 4;
        }
        // 判断一个数是由一个还是两个平方数组成
        int r = (int)Math.sqrt(n);
        if(r * r == n){
            return 1;
        }
        for(int t = 1;t * t <= n;t ++){
            int k = (int)Math.sqrt(n - t * t);
            if(k * k + t * t == n){
                return 2;
            }
        }
        return 3;
    }
```
