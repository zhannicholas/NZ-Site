---
title: "约瑟夫问题"
date: 2018-05-27T11:35:18+08:00
draft: false
categories:
  - 读书笔记
tags:
  - C算法
---

# 问题由来

>这是一个很经典的问题了，大概就是说：
已知n个人（以编号1，2，3...n分别表示）围成一个圆圈。
从第一个人开始报数，数到m的那个人出列自杀；他的下一个人又从1开始报数，数到m的那个人又出列自杀；
依此规律重复下去，找出最后剩下来的那个人。更一般的，找出自杀顺序。

## 用C++链表实现

为了以一种圆圈的形式排列人群， 我们可以构建一个循环链表，每个人和他左边的那个人之间都有一个链接。用整数 **`i`** 代表循环中的第 **`i`** 个人。从 **`1`** 开始，每次生成一个结点插入链表尾部……直到最后一个人 **`n`** 进入链表， 然后让 **`n`** 的下一个指向 **`1`**，这样就构成了一个循环链表。设置一个变量 **`t`** 记录当前所报数字。从链表头部开始（ **`t = 1`**）用迭代器 **`it`** 遍历链表，当 **`t == m`** 时，**`it`** 刚好指向要该自杀的那个人，于是输出并从链表中删除。当 **`it`** 到达链表尾部时，让 **`it`** 指向链表头，这样就形成了一个环。重复操作，直到剩下最后一个人。

```C++
#include<cstdlib>
#include<cstdio>
#include<list>
using namespace std;

int main(){
    int n, m;
    scanf("%d%d", &n, &m);
    list<int> ring;
    for(int i = 1;i <= n;i++) ring.push_back(i);
    int t = 1;  //计数
    for(list<int>::iterator it = ring.begin();ring.size() != 1;){
        if(t++ == m){
            printf("%-3d", *it);
            it = ring.erase(it);  // 自杀
            t = 1;
        }
        else it++; // 指向下一个
        if(it == ring.end()) it = ring.begin();
    }
    printf("\nalive: %d\n", *ring.begin());
    system("pause");
    return 0;
}
```

### 用数组模拟链表实现

我们可以用数组的索引来实现链表，而不是用指针。方法就是：用数组元素 **`item[i]`** 存储编号为 **`i`** 的人，用数组元素 **`next[i]`** 存储 **`i`** 的下一个在数组中的位置。那么有 **`item[i] == i + 1`**。注意最开始的时候 **`next[n - 1] = 0`** 。用位置变量 **`pos`** 跟踪元素，首先让 **`pos = n - 1`** ,这样 **`pos`** 才是指向第一个人的，通过 **`m - 1`** 次 **`pos = next[pos]`** 得到自杀的那个人的前一个人位置，然后用 **`next[pos] = next[next[pos]]`** 删除第 **`m`** 个人。这种方式还是很浪费空间的。

```C++
#include<cstdio>
#include<cstdlib>
#include<vector>
using namespace std;

int main(){
    int n, m;
    scanf("%d%d", &n, &m);
    vector<int> item, next;
    for(int i = 1;i <= n;i++){
        item.push_back(i);
        next.push_back(i % n);  // 存放i的下一个的数组下标
    } 
    int t, pos = n - 1; // 使pos指向链表首元素

    for(int i = 0;i < n - 1;i++){
        for(t = 0;t < m - 1;t++) pos = next[pos];
        printf("%-3d", item[next[pos]]);
        next[pos] = next[next[pos]];  // 自杀
    }
    printf("\nalive: %d\n", item[pos]);
    system("pause");
    return 0;
}
```
