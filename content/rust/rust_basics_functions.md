---
date: "2021-09-04T15:34:41+08:00"
title: "Rust 基础：函数"
authors: ["zhannicholas"]
categories:
  - Rust
tags:
  - Rust
draft: false
toc: true
---

在 Rust 中，函数无处不在。我们学习“Hello, world!”时接触到的 `main` 函数就是 Rust 中最重要的函数。我们也知道，声明 `main` 函数的时候需要用到关键字 `fn`。实际上，Rust 中的所有函数都是通过 `fn` 声明的。

在正式学习函数之前，有必要先了解一下 Rust 中的函数与变量命名风格。不同于 Java 中的驼峰命名（camel case），Rust 中推崇使用蛇形命名（snake case）。在蛇形命名中，所有字母都是小写的，单词之间使用下划线（`_`）分隔，比如 `hello_world`。

## 一个简单的函数

下面代码展示了一个简单地无参函数的使用：
```rust
fn main() {
    println!("Hello, world!");

    another_function();
}

fn another_function() {
    println!("Another function.");
}
```
使用 `cargo run` 运行程序，结果如下：
```powershell
Hello, world!
Another function.
```
代码中定义的 `another_function` 的定义出现在 `main` 函数之后，它还可以出现在 `main` 函数之前。其实，Rust 并不关心我们在何处定义函数，只要它能找到就行。

再来看一下 `another_function` 的组成：首先是 `fn` 关键字，往后是函数名，函数名后跟了一对圆括号，最后则是有尖括号包裹的函数体。因为 `another_function` 不需要任何参数，所以圆括号内没有任何内容。

## 函数参数

Rust 中的函数是可以有参数的，我们只需要把参数信息放到函数名后面的圆括号中，就可以在函数体中使用它们了。例如，我们可以对 `another_function` 稍加改造，把它变成一个有参函数：
```rust
fn main() {
    another_function(5);
}

fn another_function(x: i32) {
    println!("The value of x is: {}", x);
}
```
使用 `cargo run` 运行程序，你就会看到控制台打印出了以下内容：
```powershell
The value of x is: 5
```
在这个例子中，`another_function` 有一个类型为 `i32` 的参数 `x`。需要注意的是，这里的 `i32` 是不可省略的。**我们必须在函数签名中显式给出每个参数的类型**，否则就会编译失败。如果我们的函数有多个参数，使用逗号进行分隔即可，多个参数的类型不必相同。比如：
```rust
fn another_fuction(x: i32, y: i8) {
    println!("x = {}, y = {}", x, y);
}
```
上面代码中的 `another_fuction` 就有 `x` 和 `y` 两个参数。其中，参数 `x` 的类型是 `i32`，而参数 `y` 的类型是 `i8`。

## 语句与表达式

Rust 是一门基于表达式的语言。**表达式（expressions）会计算并返回一个值。语句（statements）则是执行某些动作的指令，并不会返回一个值**。来看一个例子：
```rust
fn main() {
    let x = 1;
}
```
在上面的代码中，`1` 是一个表达式，它返回的值恰好是 `1`。而 `let x = 1` 则是一个语句，它没有任何返回值。因此，下面这种写法是无法通过编译的：
```rust
fn main() {
    let y = (let x = 1);
}
```
因为 `let x = 1` 是一个语句，它没有返回值，所以没有任何东西绑定到变量 `y` 上。Rust 在这一点上跟其它编程语言有很大不同，在很多编程语言中 `y = x = 1` 是合法的，而 Rust 中是不允许的。

函数调用是表达式，宏调用是表达式，我们用来创建新作用域的代码块（`{}`）也是一个表达式。例如：
```rust
fn main() {
    let x = 5;

    let y = {
        let x = 3;
        x + 1
    };

    println!("The value of y is: {}", y);
}
```
在以上代码中，表达式：
```rust
{
    let x = 3;
    x + 1
}
```
返回的值是 `4`，而这个 `4` 最终会被绑定到变量 `y` 上。我们可能会觉得这个表达式看上去很奇怪，尤其是最后一行 `x + 1` 居然没有用分号结尾。这是因为，**在 Rust 中，表达式是不包括末尾的分号的，如果我们将分号加到表达式后面，那就不是表达式而是一个语句了**。

## 带返回值的函数

迄今为止，我们写的函数都是不带返回值的。那么带返回值的函数该怎么写呢？先来看一个例子：
```rust
fn five() -> i32 {
    5
}

fn main() {
    let x = five();
    println!("The value of x is: {}", x);
}
```
和之前的函数不同的是，我们在圆括号后面加了 `->` 和返回值类型 `i32`，同时，函数体中的最后一行是一个表达式 `5`。这就是带返回值的函数的写法，即在函数签名上加上 `->` 和返回值类型，并在函数体的最后一行写上一个表达式，这个表达式就是我们的返回值，表达式的类型就是函数签名上 `->` 后面的函数类型。返回值并不一样要在函数体的最后一行，我们也可以在函数体的中间使用关键字 `return` 加上一个表达式提前返回。使用 `return` 是显式返回，而函数体中最后一行的表达式则是隐式返回。

## 参考资料

1. Steve Klabnik, Carol Nichols. [The Rust Programming Language](https://doc.rust-lang.org/stable/book/).