---
title: "最大子数组问题"
date: 2018-06-29T10:44:26+08:00
draft: false
mathjax: true
tags:
  - 算法
categories:
  - 算法导论
authors: ["zhannicholas"]
---

# 问题

> 有一个数组A，寻找一个 **`A[]`** 的子数组 **`B[]`** ， 使得B的元素和大于A的任何一个子数组。比如A = [13, -3, 25, 20, -4, -20, -25, 18, 20, -5, 16, -5, -22, 18, -6, 8], 我们要求的 **`B[]`** 就是：[18, 20, -5, 16], 它的和大于 **`A[]`** 的任何一个子数组。

# 解决方案

## 暴力法求解

最简单也最直接的解题方式就是暴力法（Brute force）。用暴力法直接穷尽 **`A[]`** 的所有子数组， 然后选择其中最大的那个作为 **`B[]`** 就可以了。使用暴力法的时间复杂度为  \\( O(n^2) \\) 。 java代码如下:

```java
public int[] findMaxSubarray(int left, int right, int[] data){
        int i, j, maxLeft = left, maxRight = left, sum = Integer.MIN_VALUE, tempSum;
        for(i = left;i <= right;i++){
            tempSum = 0;  // data[i..j]的和
            for(j = i;j <= right;j++){
                tempSum += data[j];
                if(tempSum > sum){
                    sum = tempSum;
                    maxLeft = i;
                    maxRight = j;
                }
            }
        }
        return Arrays.copyOfRange(data, maxLeft, maxRight + 1);
    }
```

虽然暴力法能够得到我们想要的结果，但是因为暴力法的解空间巨大，因此只适用于数量不大的场合。下面采取的是一种较为高效的方法——分治法。

### 分治法求解

假如我们要求的是 **`A[left, right]`** 这个数组的最大子数组。分治法的思想是：**`divide -> conquer -> combine`** , 就是说：先把大问题分解成一系列的小问题，然后求解小问题，最后把小问题的解合并起来得到大问题的解。当然，有一个前提就是：大问题的解的确是有这些小问题构成的。
对于任何一个长度大于2的数组 **`A[left, right]`** ， 我们总能把它分解为两个子数组： **`A[left, mid]`** 和 **`A[mid + 1, right]`** 。假设我们要求的是 **`B[] = A[i, j]`** ,如此一来， **`A[i, j]`** 只有三种可能：

1. 完全位于 **`A[]`** 的左半部分，即： **`left <= i <= j <= mid`** ;
2. 完全位于 **`A[]`** 的右半部分，即： **`mid + 1 <= i <= j <= right`** ;
3. 同时位于左右两部分， 即： **`left <= i <= j <= right`** ;

对于前两种情况，可以直接递归求解。对于第三种情况，我们就要采用其它的方式了。对于越过中点的第三种情况， **`A[i, j]`** 可以拆分为 **`A[i, mid]`** 和 **`A[mid + 1, j]`** 。 由于中点包含在结果之内，所以可以这么做：

* 对于左半部分， 从 **`A[mid]`** 开始， 向 **`A[left]`** 靠近， 寻找 **`A[i, mid]`** ;
* 对于右半部分， 从 **`A[mid + 1]`** 开始， 向 **`A[right]`** 靠近， 寻找 **`A[mid + 1, j]`** ;

使用分治法的时间复杂度为：O(nlogn).

java实现的代码如下：

```java
public int[] findMaxCrossingArray(int left, int mid, int right, int[] data){
        int maxLeftSum = Integer.MIN_VALUE;
        int sum = 0;
        int i, j, maxLeft = mid, maxRight = mid + 1;
        for(i = mid;i >= left;i--){  // [left, mid]的maxSum
            sum += data[i];
            if(sum > maxLeftSum){
                maxLeftSum = sum;
                maxLeft = i;
            }
        }
        sum = 0;
        int maxRightSum = Integer.MIN_VALUE;
        for(j = mid + 1;j <= right;j++){  // [mid + 1, right] 的maxSum
            sum += data[j];
            if(sum > maxRightSum){
                maxRightSum = sum;
                maxRight = j;
            }
        }
        return Arrays.copyOfRange(data, maxLeft, maxRight + 1); // 得到A[i, j]
    }
```

然后下面是递归求解原问题的代码：

```java
public int[] findMaxSubarray(int left, int right, int[] data){  // 寻找最大子数组
        if(left == right) return data;
        else{
            int mid = (left + right) / 2;
            int[] maxLeftArray = findMaxSubarray(left, mid, data);
            int[] maxRightArray = findMaxSubarray(mid + 1, right, data);
            int[] maxCrossingArray = findMaxCrossingArray(left, mid, right, data);
            int sumLeft = sumArray(0, maxLeftArray.length - 1, maxLeftArray);
            int sumRight = sumArray(0, maxRightArray.length - 1, maxRightArray);
            int sumCrossing = sumArray(0, maxCrossingArray.length - 1, maxCrossingArray);
            if(sumLeft >= sumRight && sumLeft >= sumCrossing) return maxLeftArray;
            else if(sumRight >= sumLeft && sumRight >= sumCrossing) return maxRightArray;
            else return maxCrossingArray;
        }
    }
```

### 动态规划求解

《算法导论》在习题中讲到：

> Use the following ideas to develop a nonrecursive, linear-time algorithm for the
maximum-subarray problem. Start at the left end of the array, and progress toward
the right, keeping track of the maximum subarray seen so far. Knowing a maximum
subarray of A[1..j], extend the answer to find a maximum subarray ending at index
j + 1 by using the following observation: a maximum subarray of A[1..j + 1] 
is either a maximum subarray of A[1..j] or a subarray A[i..j + 1], for some
1 <= i <= j + 1. Determine a maximum subarray of the form A[i..j + 1] in
constant time based on knowing a maximum subarray ending at index j .

用中文来说就是：

> 若已知A[1...j]的最大子数组，基于如下性质可以得到 **`A[1..j + 1]`** 的最大子数组: **`A[1..j + 1]`** 的最大子数组要么是 **`A[1..j]`** 的最大子数组，要么是某个子数组 **`A[i..j + 1] (1 =< i <= j + 1)`** 。这个算法是线性时间O(n)。

因此，需要记录 **`A[1..j]`** 的最大子数组。于是我们可以这么想：如果前面的若干和小于0， 这对结果没有任何的帮助，应该丢弃，重新开始计算并更新位置标记；否则，向后延伸。
java代码如下：

```java
public int[] findMaxSubarray(int left, int right, int[] data){
        int maxLeft = left, maxRight = left, sum = Integer.MIN_VALUE, temp = left;
        int[] tempSum = new int[right - left + 1];
        tempSum[0] = data[left];
        for(int i = left + 1;i <= right;i++){
            if(tempSum[i - left - 1] < 0){  // 前面的最大和小于0，直接丢弃, 从下一个开始考虑
                tempSum[i] = data[i];
                temp = i;
            }
            else{  // 向后延伸
                tempSum[i - left] = tempSum[i - left - 1] + data[i];
            }
            if(tempSum[i - left] > sum){
                sum = tempSum[i - left];
                maxRight = i;
                maxLeft = temp;
            }
        }
        return Arrays.copyOfRange(data, maxLeft, maxRight + 1);

    }
```
