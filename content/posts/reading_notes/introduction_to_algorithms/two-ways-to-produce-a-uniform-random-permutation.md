---
title: "产生均匀随机排列的两种方法"
date: 2018-07-11T12:46:30+08:00
draft: false
toc: true
authors: ["zhannicholas"]
tags:
  - 算法
categories:
  - 算法导论
---

> 许多随机算法通过排列给定的输入数组来使输入随机化。这里的目标是构造数组 **`A`** 的一个随机排列。

# 方法一：排序

为数组的每一个元素 **`A[i]`** 分配一个随机的优先级 **`P[i]`** ，然后根据优先级来对数组 **`A`** 中的元素进行排序。比如：\\
A = {43, -1, 82, 61, -87, -86, -55, 28, 47, -97}\\
P = {70, 433, 302, 154, 805, 810, 740, 287, 213, 41}\\
排序后的 **`A`** 就是：\\
A = {-97, 43, 61, 47, 28, 82, -1, -55, -87, -86}

# 方法二：原地排列

假设数组 **`A`** 的长度为 **`n`** , 进行 **`n`** 次迭代，在第 **`i`** 次迭代的时候， 从 **`A[i..n]`** 中随机选取一个元素来作为 **`A[i]`** 。第 **`i`** 迭代之后， **`A[i]`** 就不再改变。

# 实现

主要java代码如下：

```java
import ch02.GenerateTestData;

import java.util.Random;

class PermutingArraysRandomly{

    public void printArray(int[] A){
        int n = A.length;
        for(int i = 0;i < n;i++){
            System.out.printf("%-6d", A[i]);
            if((i + 1) % 10 == 0) System.out.println();
        }
    }

    /**
     * @param a     下界
     * @param b     上界
     * @return      [a, b]之间的一个随机整数
     */
    public int rand(int a, int b){
        Random random = new Random();
        int c = b - a;
        return random.nextInt(c + 1) + a;
    }


    /**
     * 交换A[i]和A[j]的值
     * @param A
     * @param i
     * @param j
     */
    public void exchange(int[] A, int i, int j){
        int t = A[i];
        A[i] = A[j];
        A[j] = t;
    }

    /**
     * 根据优先级对数组A进行选择排序
     * @param A     待排序数组
     * @param P     优先级数组
     * @return      根据优先级排序后的数组
     */
    public int[] selectSort(int[] A, int[] P){
        int n = A.length;
        for(int i = 0;i < n;i++){
            int minp = i;
            for(int j = i + 1;j < n;j++){  // 值小的优先级高
                if(P[j] < P[minp]){
                    minp = j;
                }
            }
            exchange(A, i, minp);
            exchange(P, i, minp);
        }
        return A;
    }

    /**
     * 为数组的每个元素A[i]分配一个随机的优先级P[i]，然后根据优先级对数组A中的元素进行排序。
     * @param A
     * @return 按优先级排序后的数组，即随机排列后的数组
     */
    public int[] permuteBySorting(int[] A){
        int n = A.length;
        int[] P = new int[n];  // 优先级数组
        for(int i = 0;i < n;i++){
            P[i] = rand(0, n * n * n + 1);  // 使P[i]尽可能唯一
        }
        System.out.println("\nP:");
        printArray(P);
        selectSort(A, P);  // 根据优先级排序A
        System.out.println("\nsorted:");
        printArray(A);
        return A;
    }

    /**
     * 原地排列给定数列
     * @param A
     * @return
     */
    public int[] randomizeInPlace(int[] A){
        int n = A.length;
        for(int i = 0;i < n;i++){
            exchange(A, i, rand(i, n - 1));
        }
        return A;
    }
}

```
