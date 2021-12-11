---
date: "2021-10-20T21:26:46+08:00"
title: "Shell 脚本：变量"
authors: ["zhannicholas"]
categories:
  - Shell
tags:
  - Shell
draft: false
toc: true
---

Shell 脚本用变量（variable）来表示数据，变量仅仅只是一个标签（label），它实际上是一个引用（reference）或指针（pointer），指向着与变量相关联的实际数据所存放的内存地址。
变量的名字就是变量的值的占位符（placehoder），变量的值（value）持有着数据。引用（reference）或检索（retrive）变量的值的操作被称为变量替换（variable substitution）。

变量的名字和值是完全不同的，如果 `variable1` 是一个变量的名字，那么 `$variable1`（`$variable1` 是 `${variable1`} 的简单形式）就是对该变量值的引用。`$` 符号在这里的作用就是进行变量替换。

按照作用域的不同，变量分为全局变量（global variables）和局部变量（local variables）
* 全局变量也就是我们通常说的环境变量（environment variables），对所有的 shell 都有效。查看环境变量的命令：`env` 或 `printenv`。
* 局部变量只对当前的 shell 有效。使用 shell 内置的 `set` 命令（不带任何选项参数）就可以输出所有变量（包括环境变量）和一系列的函数。

## 创建变量

变量名是大小写敏感的，一般用大写命名全局变量，用小写命名局部变量。变量名可以包含数字，但是不能以数字开头。定义变量的语法为：`VARNAME=value`。

```shell
~$ variable1=123
~$ echo variable1
variable1
~$ echo $variable1
123
~$ echo ${variable1}
123
```

与我们常用的编程语言不同，shell 中变量定义中的 **等号两侧是不能有空格的**，否则会出错。这与 shell 对命令的解释有关，例如：
* shell 会将 `VARIABLE =value` 当作命令 `VARIABLE` 运行，它有一个参数 `=value`
* shell 会将 `VARIABLE= value` 当作命令 `value` 运行，并且认为有一个值为 `""` 的环境变量 `VARIABLE`

```shell
~$ VARIABLE= value
value: command not found
~$ VARIABLE =value
VARIABLE: command not found
~$ VARIABLE = value
VARIABLE: command not found
```

从技术的角度来说，变量的名字因出现在赋值语句的左边而被称为 `lvalue`，变量的值因出现在赋值语句的右边而被称为 `rvalue`。

## 变量的类型

Bash 并不像其它编程语言那样看重变量的类型。Bash 变量本质上都是字符串，但是根据上下文的不同，如果bash 也是允许在变量上进行算术运算和比较操作的。

如果变量的值只包含数字，那么我们是可以在它上面进行正常的算术运算的。如果变量的值为 `null` 或包含数字以外的字符，在它上面进行算术运算时，变量的值会被当做整数 0。

### 设置变量的类型

如果我们硬是要指定变量的类型，也是可以的。Shell 内置的 `declare` 和 `typeset` 命令都可以设置变量的值和属性，这两个命令是同义词（synonym）。`declare` 语句的语法为：`declare OPTION(s) VARIABLE=value`，它支持的选项可以用 `man` 命令查看。


## 导出变量

在 shell 中创建的变量只对当前 shell 有效，它们都是局部变量。如果我们在当前 shell 中使用 bash 或类似的命令开启一个子 shell，父 shell 中定义的变量是不可用的。要将变量传递到子 shell 中，我们可以使用 `export` 命令导出变量，导出后的变量就会被当作环境变量对待。

## 特殊参数（Special parameters）

从命令行传递给脚本的参数用：`$0,$1,$2,$3...` 表示。其中，`$0` 时脚本本身的名字，`$1` 是第一个参数，`$2` 是第二个参数，依次类推。`$9` 之后的参数必须用大括号包裹起来，例如：`${10}`。这些参数由于和出现位置有关，所以被称为位置参数（positional parameters）。特殊变量 `$*` 和 `$@` 表示所有的参数。

## Quoting characters

在有些上下文中，很多字符或者单词都有特殊的含义，用特殊符号将它们引起来可以消除这些特殊含义。

```shell
~$ a=123
```

### 转义字符（\）

转义字符（Escape characters）用来移除其后 **单个字符** 的特殊含义。Bash 中的转义字符是反斜杠（\）。

```shell
~$ echo \$a
$a
~$ echo \${a}
${a}
```

转义符在行尾（对换行符进行转义）时，表示当前行的命令还未写完。这允许我们写出可读性更强的长命令，例如：
```shell
~$ echo foo\
> bar
foobar
```

### 单引号（''）

将变量的引用放在单引号中（'…'）就会让变量名被当作字面值处理，即不会发生变量替换，所以单引号被称为“full quoting”，有时又称“strong quoting”。

```shell
~$ echo '$a'
$a
~$ echo '${a}'
${a}
```

单引号（Single quotes）被用来移除两个单引号之间 **所有字符** 的特殊含义，即单引号中的所有字符都是字面值（literal value）。两个单引号之间是不能有单引号的，即便这个单引号被转义都不行。


### 双引号（""）

将变量的引用放在双引号中（"…"）并不会对变量替换造成影响，所以双引号被称为“partial quoting”，有时又称“weak quoting”。

双引号（Double quotes）会移除两个双引号之间除美元符号（$）、反引号（`）和反斜杠（\）之外的所有字符的特殊含义。美元符号和反引号的特殊含义在双引号之间会保留，而反斜杠只有在其后的字符是美元符号、反引号、双引号、反斜杠或换行符时才保留特殊含义，输入流会将这些字符前的反斜杠去掉。双引号之间是可以有由反斜杠转义的双引号的。

```shell
~$ echo "$a"
123
~$ echo "${a}"
123
```

双引号还可以保留变量值中的空白符，防止 shell 在解释命令时去掉多余的空白符。

```shell
~$ hello="A B  C   D"
echo $hello
A B C D
echo "$hello"
A B  C   D
```

## 参数替换

`${parameter}`：获取变量 `parameter` 的值，同 `$parameter`，但是前者的含义更加明确
```shell
~$ param=123
~$ echo ${param}
123
```

`${parameter-default}` 或 `${parameter:-default}`：如果参数 `parameter` 未设置，则使用 `default` 作为结果，但不会将 `default` 赋值给 `parameter`。`:` 的作用是：如果 `parameter` 已声明且值为 `null`，则使用 `default`。若没有 `:`，则只要 `parameter` 已声明，就不会使用 `default`
```shell
~$ echo ${param-1}
123
~$ echo ${param:-1}
123
~$ echo ${param1-1}
1
~$ echo ${param2:-2}
2
~$ param3=  # param3 is declared, but is null
~$ echo ${param3:-3}
3
~$ echo ${param3-3}

~$ echo ${param3}

```

`${parameter=default}` 和 `${parameter:=default}`：如果 `parameter` 未设置，则使用 `default` 并将其赋值给 `parameter`。这里 `:` 的含义与 `${parameter:-default}` 中的 `:` 类似。
```shell
~$ param4=  # param4 is declared, but is null
~$ echo ${param4:=4}
4
~$ echo ${param5=5}
5
~$ echo ${param5}
4
```

`${parameter+alt_value}` 和 `${parameter:+alt_value}`：如果 `parameter` 已设置，则使用 `alt_value` 但不进行赋值，否则使用 `null`。

`${parameter?err_msg}` 和 `${parameter:?err_msg}`：如果 `parameter` 已设置，则使用它，否则打印 `err_msg` 并终止脚本执行。

`${#var}`：计算字符串 `var` 的长度，或数组 `var` 中第一个元素的长度。

`${var#Pattern}` 和 `${var##Pattern}`：从 `$var` 首部开始移除 `$Pattern` 最短（`#`）或最长（`##`）匹配上的部分。

`${var%Pattern}` 和 `${var%%Pattern}`：从 `$var` 尾部开始移除 `$Pattern` 最短（`%`）或最长（`%%`）匹配上的部分。

`${var:pos}`：从偏移量 `pos` 处（即跳过 `pos` 个字符）展开 `$var`。

`${var:pos:len}`：从偏移量 `pos` 处展开最大长度为 `len` 个字符。

`${var/Pattern/Replacement}`：使用 `Replacement` 替换 `var` 中第一个匹配上 `Pattern` 的部分。

`${var//Pattern/Replacement}`：使用 `Replacement` 替换 `var` 中所有匹配上 `Pattern` 的部分。

`${var/#Pattern/Replacement}`：若 `var` 的前缀匹配上了 `Pattern`，则使用 `Replacement` 替换 `Pattern`。

`${var/%Pattern/Replacement}`：若 `var` 的后缀匹配上了 `Pattern`，则使用 `Replacement` 替换 `Pattern`。

`${!varprefix*}` 和 `${!varprefix@}`：筛选出所有名字以 `varprefix` 开头的已声明的变量。


## 参考资料

1. [Bash Guide for Beginners](https://tldp.org/LDP/Bash-Beginners-Guide/html/index.html).
2. [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/index.html).