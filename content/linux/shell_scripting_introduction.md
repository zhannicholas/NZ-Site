---
date: "2021-10-20T20:45:55+08:00"
title: "Shell 脚本：初见"
authors: ["zhannicholas"]
categories:
  - Shell
tags:
  - Shell
draft: false
toc: true
---

> 接下来将会有一系列与 Shell 脚本相关的笔记文章。在之前的工作中，作为一个 Java Boy，我几乎不需要自己编写 Shell 脚本，所以大学学过的 Shell 脚本编程基本忘完（实际上我并没有系统的学过它😂），工作中碰到相关东西时也是 Google 一下就搞定了。但是，现在的工作要求我能够编写 Shell 脚本实现一些自动化操作，所以我决定系统地学习一下 Shell 脚本编程的相关知识。主要参考的学习资料是 [The Linux Documentation Project](https://tldp.org/guides.html) 网站上推荐的两本在线书籍：[Bash Guide for Beginners](https://tldp.org/LDP/Bash-Beginners-Guide/html/index.html) 和 [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/index.html)。前者适合入门，后者适合精进，感谢作者的无私分享。

## Shell

Shell 既是一个命令解释器（command interpreter），又是一门编程语言。Shell 脚本（shell scripts）是用 shell 编程语言编写的程序，它可以将系统调用、各种工具和已编译的二进制文件粘合在一起，形成新的应用。

Shell 脚本是解释执行的，shell 从脚本中逐行读取命令，然后在系统中昂搜索这些命令并执行。

Shell 有很多种，比如 sh（Bourne Shell）、bash（Bourne Again shell）、csh（C shell）、tcsh（TENEX C shell）、ksh（Korn shell）、tmux 等

查看系统内已经有的 shell：`cat /etc/shells`。
查看当前用户默认的 shell：`cat /etc/passwd | grep $USER | awk 'BEGIN { FS=":" } { print $7 }`。

## Bash

绝大多数 Linux/Unix 系统默认的 shell 都是 bash，bash 不仅兼容 sh，而且能力更强。

### Bash 启动时加载的文件

当 bash 在不同的情况下被调用时（invoked），它会在启动时会读取并执行一些特定的文件，文件的读取顺序会在下面列出，如果某个文件不存在，bash 就会跳过它继续查找下一个文件。

#### Invoked as an interactive login shell，or with `--login`

交互式（interactive）bash 意味着我们可以输入命令，shell 通常会从它连接到的终端（terminal）读取命令，然后将执行结果输出到终端。而“login shell”则表示系统会在使用者使用 shell 之前对其进行身份的认证（通常要使用者提供用户名和密码）。这种情况下 bash 启动时读取的文件有：
* /etc/profile
* ~/.bash_profile or ~/.bash_login or ~/.profile：第一个存在的可读文件会被读取
* ~/.bash_logout：退出时读取

#### Invoked as an interactive non-login shell

non-login shell 表示系统在使用者使用 shell 之前不会对其进行身份的认证。这种情况下读取的文件有：
* ~/.bashrc

#### Invoked non-interactively

所有 bash 脚本使用的都是非交互式（non-interactively）shell。这时读取的文件有：
* 由变量 `BASH_ENV` 定义的文件，不过在搜索这个文件时并不会用上 `PATH`

#### Invoked with the sh command

这个时候读取的文件有：
* /etc/profile
* ~/.profile

## Shell 语法

如果输入不是注释（comment），shell 会读入并将其拆分成单词（word）和操作符（operator），使用“quoting rules”确定输入中每个字符的含义。然后，这些单词和操作符会被翻译成命令和其它结构（construct）。Shell 分析输入的过程如下：
1. Shell 从文件、字符串或用户的终端读取输入
2. 按照“quoting rules”将输入分解为单词和操作符。这些符号（token）被元字符（metacharacter）分隔。别名（alias）展开被执行
3. Shell 将这些符号解析（分析和替换）成简单命令或复合命令
4. Bash 执行各种 shell 展开（expansion），将展开的符号分解成文件名（filename）、命令（command）和参数（argument）列表
5. 如果有必要的话，重定向被执行。重定向操作符和它们的操作数被从参数列表中移除
6. 命令被执行
7. （可选）shell 等待命令执行完毕并收集命令的退出状态。

## She-Bang

Sha-Bang，又叫 Shebang、Hashbang，是一个由井号（sharp）和叹号（bang）构成的字符串 `#!`。若文件的第一行（空白行也是有效行）的前两个字符是 Sha-Bang，Linux 操作系统的进程加载器会分析 Sha-Bang 后面的内容，将这些内容作为解释器指令并调用该指令，载有 Sha-Bang 的文件路径会作为该解释器的参数（常见的 `$0`）。所以 Sha-Bang 的作用是告知系统这个文件包含着要交给命令解释器执行的命令（即整个脚本），而 Sha-Bang 后面的路径就是这个命令解释器的路径。很多 shell 脚本的第一行都是 `#!/bin/bash` 或 `#!/usr/bin/bash`。

**要执行某个脚本，用户不仅需要具备该脚本的读取权限，还需要具备该脚本的执行权限，光有执行权限是不够的。**

## 调试 Shell 脚本

若要调试（debug）shell 脚本，可以使用 bash 的 `-x` 选项 （在执行命令之前打印命令的 trace 信息）选项，例如：`bash -x your_script.sh`。

`bash -x` 是作用域整个脚本的，即脚本中所有命令的 trace 信息都会被打印出来。有时候，我们只想关注脚本中的某一部分，这个使用可以使用 shell 内置的 `set` 命令：使用 `set -x` 开启调试，使用 `set +x` 关闭调试。Shell 选项中的 `+/-` 与我们平常使用其它程序的习惯刚好相反，需要注意。`set -x` 和 `set +x` 可以在脚本中出现任意多次。

还有一种开启整个脚本调试信息的方法，那就是将 `-x` 选项直接加到 Sha-Bang 行解释器路径的后面，例如：`#!/bin/bash -x`。


## 参考资料

1. [Bash Guide for Beginners](https://tldp.org/LDP/Bash-Beginners-Guide/html/index.html).
2. [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/index.html).
3. [Bash Reference Manual](https://www.gnu.org/software/bash/manual/html_node/).