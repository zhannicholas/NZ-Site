---
title: "寻找数组中的第K个最大的元素"
date: 2018-07-20T10:33:07+08:00
draft: false
authors: ["zhannicholas"]
toc: true
tags:
  - Leetcode
categories:
  - Leetcode
---

这是Leetcode上的第215题：数组中的第k个最大元素。

# 问题描述

在未排序的数组中找到第 k 个最大的元素。请注意，你需要找的是数组排序后的第 k 个最大的元素，而不是第 k 个不同的元素。

示例 1:

```test
输入: [3,2,1,5,6,4] 和 k = 2
输出: 5
```

示例 2:

```test
输入: [3,2,3,1,2,4,5,5,6] 和 k = 4
输出: 4
```

# 解决方案

提供两种解法，一种是使用快速排序的解法，一种是使用**划分**思想但不排序的解法。

## 使用排序

要找出数组中第K个最大的元素，最直观的方法就是先将原数组按照非递增顺序排序，然后返回第K个元素。我这里使用的是快速排序。

快速排序需要先对数组进行划分，划分的代码如下：

```Java
/**
 * 总是使用最右端的元素A[r]将数组A[p..r]划分为A[p..q - 1]、A[q]、A[q + 1..r]
* A[p..q - 1] >= A[q]
 * A[q + 1..r] < A[q]
 * @param A     待划分数组
 * @param p     下界
 * @param r     上界
 * @return      q
 */
private int partition(int[] A, int p, int r){
    int x = A[r];  // 保存最右端元素
    int i = p - 1;  // i最终指向A[p..q - 1]中的最后一个元素
    for(int j = p;j <= r - 1;j++){
        if(A[j] >= x){
            i ++;
            exchange(A, i, j);  // 将不小于A[q]的元素A[j]放到A[p..q - 1]中，同时一个小于A[q]的元素被放到A[q + 1..r]中
        }
    }
    exchange(A, i + 1, r);  // 将最右端的元素放到正确位置
    return i + 1;
}
```

接下来是寻找第K个最大的元素了：

```Java
private void quickSort(int[] nums, int p, int r){
    if(p < r){
        int q = partition(nums, p, r);
        quickSort(nums, p, q - 1);
        quickSort(nums, q + 1, r);
    }
}

public int findKthLargest(int[] nums, int k){
    int p = 0, r = nums.length - 1;
    quickSort(nums, p, r);
    return nums[k - 1];
}
```

## 使用划分

利用快速排序中划分的思想，假定始终选取数组A[0..n-1]中的最后一个元素（划分后它在数组中的位置为q）作为参照点，划分后的结果为：A[1..n-1]在划分后由三部分组成，从左到右依次为：

* A[0..q-1]: 均不小于A[q];
* A[q]
* A[q+1..n-1]:均小于A[q];

由此可确定第K大的元素的位置：

1. k = q + 1: 返回A[q];
2. k < q + 1: 在A[0..q-1]中继续寻找第K大的元素
3. k > q + 1： 在A[q+1..n-1]中继续寻找第(k - q + 1)大的元素

递归版本的代码如下：

```Java
private int findKthLargestHelper(int[] nums, int k, int p, int r){
int q = partition(nums, p, r);
    if(k == q + 1){
        return nums[q];
    }
    else if(k < q + 1){
        return findKthLargestHelper(nums, k, p, q - 1);
    }
    else{
        return findKthLargestHelper(nums, k - q + 1, q + 1, r);
    }
}
```

迭代版本做了一点改动，代码如下：

```Java
private int findKthLargestHelperIteratively(int[] nums, int k, int p, int r){
    int q = partition(nums, p, r);
    while(k != q + 1){
        if(k < q + 1){
            q = partition(nums, p, q - 1);
        }
        else{
            q = partition(nums, q + 1, r);
        }
    }
    return nums[q];
}
```
