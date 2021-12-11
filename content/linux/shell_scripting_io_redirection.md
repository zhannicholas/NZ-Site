---
date: "2021-10-27T22:26:55+08:00"
title: "Shell 脚本：I/O 重定向"
authors: ["zhannicholas"]
categories:
  - Shell
tags:
  - Shell
draft: false
toc: true
---

文件输入和输出是通过整数句柄（integer handle）实现的——每个打开的文件都会被赋予一个数字，这个数字就是文件描述符（file descriptor）。

最常见的文件描述符是标准输入（stdin）、标准输出（stdout）和标准错误（stderr），它们的文件描述符数字分别是 0、1、2。这些数字和相应的设备都是系统保留的，我们可以通过命令 `ls -l /dev/std*` 查看。

```shell
~$ ls -l /dev/std*
lrwxrwxrwx 1 root root 15 Oct 16 18:47 /dev/stderr -> /proc/self/fd/2
lrwxrwxrwx 1 root root 15 Oct 16 18:47 /dev/stdin -> /proc/self/fd/0
lrwxrwxrwx 1 root root 15 Oct 16 18:47 /dev/stdout -> /proc/self/fd/1
```

每个进程看到的 `/proc/self` 目录下的东西都不一样，因为 `/proc/self` 实际上是一个指向 `/proc/<process_ID>` 的符号链接。

## 输出重定向

* `COMMAND_OUTPUT >`：重定向输出到一个文件。如果文件不存在，则创建并写入，否则覆盖原文件
* `: > filename`：删除（truncate）文件的内容，如果文件不存在，则创建它。`:` 是一个占位符，代表无。
* `> filename`：和 `: > filename` 类似，但是在某些 shell 下工作不正常
* `COMMAND_OUTPUT >>`：重定向输出到一个文件，已追加的方式写入
* `1>filename`：重定向标准输出到文件，以覆盖的方式写入
* `1>>filename`：重定向标准输出到文件，以追加的方式写入
* `2>filename`：重定向标准错误到文件，以覆盖的方式写入
* `2>>filename`：重定向标准错误到文件，以追加的方式写入
* `&>filename`：重定向标准输出和标准错误到文件
* `M>N`：重定向文件描述符 `M`（如果未给出，则默认为 1）对应的文件到文件 `N` 。注意：`M` 是一个文件描述符，`N` 是一个文件。
* `M>&N`：定向文件描述符 `M`（如果未给出，则默认为 1）对应的文件到文件描述符 `N` 对应的文件。注意：这里 `M` 和 `N` 都是文件描述符
* `2>&1`：重定向标准错误到标准输出
* `i>&j`：重定向文件描述符 `i` 到 `j`
* `>&j`：重定向标准输出到文件描述符 `j`

## 输入重定向

* `0< filename`：从文件获取输入
* `[j]<>filename`：打开文件 `filename` 进行读写，若该文件不存在则创建它。如果文件描述符 `j` 未声明，则默认为 0

## 关闭文件描述符

* `n<&-`：关闭输入文件描述符 `n`
* `0<&-` 和 `<&-`：关闭标准输入
* `n>&-`：关闭输出文件描述符 `n`
* `1>&-` 和 `>&-`：关闭标准输出

## Here documents

`here document` 是一个有着特殊用途的代码块，它告诉 shell 从当前位置读取输入，直到遇到结束字符串。然后，读取到的内容会被用作命令的标准输入。语法如下：
```
COMMAND <<InputComesFromHERE
...
...
...
InputComesFromHERE
```
这里包含一个命令 `COMMAND`，一个限制字符串（limit string）`InputComesFromHERE`。限制字符串之间的内容就是 `COMMAND` 的标准输入，特殊字符 `<<` 出现在限制字符串的前面。由于 `here document` 使用限制字符串来判断输入是否结束，所以限制字符串的选取就非常重要，它不应该出现在给 `COMMAND` 的内容中。

## Here strings

`here string` 可以被看做 `here document` 的简单版本。它的形式为：`COMMAND <<< $WORD`。其中 `$WORD` 展开后的结果就会做为 `COMMAND` 的标准输入。

## 参考资料

1. [Bash Guide for Beginners](https://tldp.org/LDP/Bash-Beginners-Guide/html/index.html).
2. [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/index.html).
3. [Bash Reference Manual](https://www.gnu.org/software/bash/manual/html_node/).