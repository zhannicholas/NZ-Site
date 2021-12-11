---
date: "2021-10-27T21:10:27+08:00"
title: "Shell 脚本：正则表达式"
authors: ["zhannicholas"]
categories:
  - Shell
tags:
  - Shell
draft: false
toc: true
---

正则表达式（regular expression, RE）在 Shell 中的应用非常广泛，我们常用的 `find`、`grep`、`sed`、`awk` 等命令都涉及到正则表达式……

在 Shell 中，表达式就是一个字符串。字符串由字符组成，其中有些字符除了字面含义之外还有特殊含义，这些具有特殊含义的字符就是元字符（metacharacter）。

正则表达式主要用于搜索文本和操作字符串，它包含以下内容：
* 字符集（character set）。字符集内所有的字符都只具有字面含义，不包括元字符
* 锚点（anchor）。锚点标识着正则表达式要匹配的文本中的位置，比如 `^` 和 `$`
* 修饰符（modifier）。修饰符的作用是扩展或者缩小正则表达式要匹配的文本的范围，包括星号（*）、方括号（[）和反斜杠（/）

## 标准正则表达式中的特殊字符

* `*`：匹配前一个字符出现任意次数，包括 0 次
* `.`：匹配除换行符（\n）之外的任何单字符
* `^`：匹配字符串的开始位置
* `$`：匹配字符串的结束位置
* `[...]`：封装正则表达式中用到的一组字符
* `\`：对特殊字符进行转义，转移后的特殊字符只具备字面含义
* `\<...\>`：标记单词边界

## 扩展正则表达式中的特殊字符

扩展正则表达式给标准正则表达式中加入了新的元字符，主要用在 `egrep`、`awk` 和 `Perl` 中。

* `?`：匹配前一个字符出现零次或一次
* `+`：匹配前面的子表达式出现一次或多次
* `\{\}`：限定前面的子表达式出现的次数
* `()`：封装一组正则表达式
* `|`：从一组选择中选择一个，即或的含义

## Globbing

Bash 本身并不能识别正则表达式，解释正则表达式的是一些像 `sed` 和 `awk` 这样的命令和工具。Shell 展开中有一种类型叫文件名展开（filename expansion），但展开的事情并不是 Bash 自己完成的，而是由一个叫做 `globbing` 的进程完成的。但是 globbing 本身并不能使用标准的正则表达式，它只能识别一些特殊字符（比如 `*`、`?`、`[]`）。这些特殊字符一般称为通配符（wildcards），也叫 *globbing* 或 *pattern matching*。需要注意的是：`*` 并不会匹配以 `.` 开头的文件名。

## 参考资料

1. [Bash Guide for Beginners](https://tldp.org/LDP/Bash-Beginners-Guide/html/index.html).
2. [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/index.html).
3. [Bash Reference Manual](https://www.gnu.org/software/bash/manual/html_node/).