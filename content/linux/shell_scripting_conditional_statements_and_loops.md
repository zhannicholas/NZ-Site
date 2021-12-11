---
date: "2021-10-21T23:05:45+08:00"
title: "Shell 脚本：条件分支与循环"
authors: ["zhannicholas"]
categories:
  - Shell
tags:
  - Shell
draft: false
toc: true
---

和其它编程语言类似，bash 也给我们提供了条件语句（conditional statements）。

## 条件分支

### if

在 shell 中，`if/then` 的语法为：`if TEST-COMMANDS; then CONSEQUENT-CONMMANDS; fi`。

`TEST-COMMANDS` 列表执行后，如果它的返回状态是 0，就执行 `CONSEQUENT-COMMANDS` 列表，其中最后一条命令的退出状态就是整个 `if` 表达式的返回状态。

**在 UNIX/Linux 中，通常用 0 表示成功，非零表示失败**。

#### if/then/else

`If/then/else` 的语法为：`if TEST-COMMANDS; then CONSEQUENT-CONMMANDS; else ALTERNATE-CONSEQUENT-COMMANDS; fi`

#### if/then/elif/else

if 表达式的完整的语法为：`if TEST-COMMANDS; then CONSEQUENT-CONMMANDS; elif MORE-TEST-COMMANDS; then MORE-CONSEQUENT-COMMANDS; else ALTERNATE-CONSEQUENT-COMMANDS; fi`

#### test

`test` 是一个 bash 内置的命令，用于检查文件的类型和进行值的比较。特殊字符 `[` 是 `test` 的同义词。

`[]` 与 `[[]]` 的区别在于：`[[]]`（extended test command）比 `[]` 更强，它会阻止 shell 进行变量名的分词操作、阻止路径名展开。`[` 和 `[[` 的类型也不同：
```shell
~$ type [
[ is a shell builtin
~$ type [[
[[ is a shell keyword
```
还有更加有趣的：
```shell
~$ type ]
-bash: type: ]: not found
~$ type ]]
]] is a shell keyword
```

> A builtin is a command contained within the Bash tool set, literally built in.

> A keyword is a reserved word, token or operator. A keyword is not in itself a command, but a subunit of a command construct.

与文件相关的测试操作符很多，进一步查看：[File test operators](https://tldp.org/LDP/abs/html/fto.html)。
比较操作符也有很多，进一步查看：[Other Comparision Operators](https://tldp.org/LDP/abs/html/comparison-ops.html)。

### case

case 表达式的语法为：`case EXPRESSION in CASE1) COMMAND-LIST;; CASE2) COMMAND-LIST;; ... CASEN) COMMAND-LIST;; esac`

每个 `case` 都是一个匹配模式的表达式，若某个 `case` 的模式匹配成功，则执行 `)` 后的 `COMMAND-LIST`。`)` 的代表着模式的结束，它前面甚至可以写多个模式，每个模式之前用 `|` 分隔，例如：
```shell
case $1 in
  start | Start)
    start
    ;;
  *)
    echo "Default branch"
    ;;
esac
```

每个 `case` 加上对应的 `COMMAND-LIST` 就构成了一个子句（clause），每个子句都必须以 `;;` 结束

### select

select 语句的语法为：`select WORD [in LIST]; do RESPECTIVE-COMMANDS; done`。select 结构一般用于生成菜单。

## 循环

### for

for 循环的语法为：`for NAME [in LIST ]; do COMMANDS; done`。如果 `[in LIST]` 不存在，则它会被替换为 `in $@`，for 循环会为每一个位置参数执行一遍 `COMMANDS`。

### while

while 循环的语法为：`while CONTROL-COMMAND; do CONSEQUENT-COMMANDS; done`

### until
until 循环的语法为：`until TEST-COMMAND; do CONSEQUENT-COMMANDS; done`。until 循环与 while 循环稍有不同，它会在 `TEST-COMMAND` 为 false 时继续循环，在 `TEST-COMMAND` 为 true 时结束循环，二者循环进行的条件刚好相反。

### break & continue

`break` 和 `continue` 是两个能够影响循环执行的命令：前者终止整个循环，后者跳过当前循环进入下一次循环。


## 参考资料

1. [Bash Guide for Beginners](https://tldp.org/LDP/Bash-Beginners-Guide/html/index.html).
2. [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/index.html).
3. [Bash Reference Manual](https://www.gnu.org/software/bash/manual/html_node/).