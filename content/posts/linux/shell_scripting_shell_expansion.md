---
date: "2021-10-23T17:15:13+08:00"
title: "Shell 脚本：shell 展开"
authors: ["zhannicholas"]
categories:
  - shell
tags:
  - shell
draft: false
toc: true
---

在 shell 将读取的命令分割成符号（token）之后，这些符号（或单词）会被展开或解析。Shell 会按照顺序执行八种类型的展开（expansion）：
1. Brace expansion
2. Tilde expansion
3. Shell parameter and variable expansion
4. Command substitution
5. Arithmetic expansion
6. Process substitution
7. Word splitting
8. File name expansion

## 大括号展开

大括号展开的形式为：一个可选的前导符（PREAMBLE）、一组位于一对大括号之间的由逗号分隔的字符串和一个可选的跋（POSTSCRIPT）。例如：
```shell
~$ echo sp{el,il,al}l
spell spill spall
```

## 波浪号展开

如果一个单词以没有被引起来的波浪号（~）开始，则在第一个没有被引起来的斜杠（若没有斜杠，则一直到最后一个字符）之前的字符将被视作波浪号前缀（tidle-prefix）。如果波浪号前缀中没有字符被引起来，那么波浪号前缀中的这些字符就会被当作一个可能的登录用户名。如果这个登录用户名是 null 字符串，则波浪号被替换为 shell 变量 HOME。如果 HOME 变量没有被设置，则替换为执行这个 shell 的用户的主目录。
如果波浪号前缀是”~+“，那么它会被替换为变量 PWD 的值。如果波浪号前缀是”~-“，那么它会被替换为变量 OLDPWD 的值。

## 参数或变量展开

美元符号（$）用于参数展开、命令替换或算术展开。被展开的参数名或符号可能被包裹在大括号中。
最基本的参数展开的形式是”${PARAMETER}“。如果我们想在某个变量不存在时创建这个变量，则可以使用”${VAR:=value}“

## 命令替换

命令替换（command substitution）允许我们用命令的输出来替换命令本身，它有两种形式：
* $(command)
* \`command\`

其中前者工作得更好，是用来取代后者的。

例如：
```shell
~$ whoami
ubuntu2004
~$ echo `whoami`
ubuntu2004
~$ echo $(whoami)
ubuntu2004
```

命令替换会调用一个 subshell。
> A subshell is a child process launched by a shell (or shell script).

## 算术展开

算术展开（arithmetic expansion）允许我们用一个算术表达式计算得到的值替换表达式本身。它也有两种形式：
* `$(( EXPRESSION ))`
* \`$[ EXPRESSION ]\`

例如：
```shell
~$ a=1
~$ echo $(( $a+1 ))
2
~$ echo $[ $a+1 ]
2
```

如果执行算术运算的操作数是一个字符串，那么它会被当作 0 处理。例如：
```shell
~$ a=1
~$ echo $(( $a+1 ))
1
~$ echo $[ $a+1 ]
1
```


## 进程替换

进程替换（Process substitution）在支持命名管道（FIFO）和命名打开文件的 /dev/fd 方法的系统上。形式也有两种：
* `<(LIST)`
* `>(LIST)`

## 单词拆分

Shell 会扫描不在双引号之内的参数展开、命令替换和算术展开的结果，用于单词拆分。分隔符为变量 IFS 中的每个字符，默认为 `<space><tab><newline>`。


## 文件名展开

单词拆分之后，如果 bash 的 -f 选项没有被设置，bash 就会扫描每个单词，寻找字符 `*`、`?`、`[`。如果这三个字符有所出现，单词会被视为一个模式（PATTERN），然后被替换为一个按照字段序排列与这个模式相匹配的文件名列表。


## 参考资料

1. [Bash Guide for Beginners](https://tldp.org/LDP/Bash-Beginners-Guide/html/index.html).
2. [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/index.html).