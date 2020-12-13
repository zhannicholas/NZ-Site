---
title: "Java中反转字符串的几种方法"
date: 2018-07-20T13:51:14+08:00
draft: false
authors: ["zhannicholas"]
tags:
  - Java
  - Leetcode
categories:
  - Leetcode
---

这是Leetcode上的第344题，虽然很简单，但是涉及到一些技巧，于是我决定把我试过的方法记录下来。

# 题目描述

请编写一个函数，其功能是将输入的字符串反转过来。

示例：

```test
输入：s = "hello" 
返回："olleh"
```

# 解决方案

反转字符串的方法由很多种，但是各自的效率会有些差别。

## 方法一

重新开辟一个字符串，然后将原来的字符串从后向前一个一个复制到新的字符串中。这可能是最容易想到也最经常使用的一个方法。

```Java
private String reverse(String s){
    String r = "";
    int n = s.length();
    for(int i = n - 1;i >= 0;i--){
        r += s.charAt(i);
    }
    return r;
}
```

不幸的是，这个方法未能通过所有的测试用例，最终超时了。。。

## 方法二

前一个方法失败了，于是决定采用**对撞指针**的方法来碰碰运气。初始化两个指针，一个指向字符串的开头，一个指向字符串的结尾，同时向中间移动直至两指针相遇，在移动的过程中交换各自指向的那个字符即可。但是问题来了，Java中没有直接提供在字符串上修改指定位置字符的方法。不过，Java提供了将字符串转为字符数组的方法，这也能达到我的目的。

```Java
private String reverse2(String s){
    char[] a = s.toCharArray();
    int l = 0, r = a.length - 1;
    while(l < r){
        char c = a[l];
        a[l] = a[r];
        a[r] = c;
        r --;
        l ++;
    }
    String s1 = "";
    for(int i = 0;i < a.length;i ++){
        s1 += a[i];
    }
    return s1;
}
```

本来以为这个方法能够通过测试，然而还是失败了。呜呜呜……，问题就在于最后5行。方法四就是对这几行的改进。

## 方法三

查阅API发现，Java中**StringBuilder**提供了反转字符串的方法，于是我决定试一试：

```Java
private String reverse3(String s){
    return new StringBuffer(s).reverse().toString();
}
```

短小精悍，这个方法通过了测试，并且只花了4ms。但还是不够好。

## 方法四

这是方法二的改进，能把测试时间缩短至2ms，是我目前知道的最快的方法了：

```Java
private String reverse2(String s){
    char[] a = s.toCharArray();
    int l = 0, r = a.length - 1;
    while(l < r){
        char c = a[l];
        a[l] = a[r];
        a[r] = c;
        r --;
        l ++;
    }
    return new String(a);
}
```
