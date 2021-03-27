---
title: "厄拉多筛法求素数"
date: 2018-05-26T10:43:44+08:00
draft: false
author: ["zhannicholas"]
categories:
  - 读书笔记
tags:
  - C算法
---

# 筛法原理

>给出要筛数值的范围maxn，找出maxn以内所有的素数。先用2去筛，即把2留下，把2的倍数剔除掉；再用下一个素数，也就是3筛，把3留下，把3的倍数剔除掉；接下去用下一个素数5筛，把5留下，把5的倍数剔除掉；不断重复下去......。

# 算法

可以通过维护一个标记数组 **`a[]`**来进行判断。

1. 若 **`i`** 为素数，则 **`a[i] = 1`** ，否则 **`a[i] = 0`**。
2. 首先，将所有的 **`a[i]`** 都设置为 **`1`**，表示已知的都是素数。然后将所有以已知素数的倍数为索引的数组元素设为 **`0`**。
3. 如果将所有较小素数的倍数都设置为 **`0`** 之后，**`a[i]`** 仍为 **`1`**，则 **`i`** 为素数。

```C++
#include<cstdio>
#include<cstdlib>
const int maxn = 10000;

int main(){
    int i, j, t, a[maxn];
    for(i = 2;i < maxn;i++) a[i] = 1;
    for(i = 2;i < maxn;i++){
        if(a[i] == 1){
            t = maxn / i;
            for(j = i;j < t;j++) a[i * j] = 0;
        }
    }
    for(i = 2;i < maxn;i++){
        if(a[i] == 1) printf("%4d ", i); 
    }
    system("pause");
    return 0;
}
```
