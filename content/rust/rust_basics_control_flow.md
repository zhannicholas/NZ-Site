---
date: "2021-09-05T08:28:14+08:00"
title: "Rust 基础：控制流"
authors: ["zhannicholas"]
categories:
  - Rust
tags:
  - Rust
draft: false
toc: true
---

几乎所有的编程语言中都有控制流（control flow）的概念，控制流即根据条件的成立与否决定代码的执行逻辑。在 Rust 中，控制流分为 `if` 表达式和循环。

## `if` 表达式

### 一个简单的 `if`

`if` 表达式告诉程序：如果条件成立，则执行某段代码，否则不执行那段代码。举个例子：
```rust
fn main() {
    let condition = true;
    if condition {
        println!("The condition was true.")
    }
}
```
使用 `cargo run` 运行这段代码，程序的输出结果是：
```powershell
The condition was true.
```
但如果你将 `let condition = true;` 替换成 `let condition = false;`，就不会看到任何输出。

在 Rust 中，所以的 `if` 表达式都以关键字 `if` 开头，随后是一个 `bool` 类型的条件，条件满足时执行的代码放在条件后面的尖括号里。Rust 要求条件的数据类型必须是布尔类型，因为 Rust 不会自动进行非布尔类型到布尔类型的值转换。所以，以下代码是不会通过编译的：
```rust
fn main() {
    let number = 1;
    if number {
        println!("The value of number is: {}", number);
    }
}
```

### 使用 `else`

我们也可以给 `if` 表达式加一个可选的 `else` 表达式，用来告知程序当条件不满足的时候应该执行何种操作。例如：
```rust
fn main() {
    let condition = false;
    if condition {
        println!("The condition was true.")
    } else {
      println!("The condition was false.");
    }
}
```
使用 `cargo run` 运行以上代码，你会看到屏幕上打印出了以下内容：
```powershell
The condition was false.
```

### 使用 `else if`

如果我们有多个条件，那么该如何写呢？答案是使用 `else if`。举个例子：
```rust
fn main() {
    let number = 6;

    if number % 4 == 0 {
        println!("number is divisible by 4");
    } else if number % 3 == 0 {
        println!("number is divisible by 3");
    } else if number % 2 == 0 {
        println!("number is divisible by 2");
    } else {
        println!("number is not divisible by 4, 3, or 2");
    }
}
```
以上程序中有四条执行路径，但是只会打印一条路径上的结果：
```powershell
number is divisible by 3
```
这是因为 Rust 会依次检查每一个条件，遇到第一个值为 `true` 的条件就执行与之关联的代码块，然后结束对所有后续条件的检查。

### 在 `let` 语句中使用 `if`

因为 `if` 是一个表达式，所以我们可以在 `let` 语句中使用它，例如：
```rust
fn main() {
    let condition = true;
    let number = if condition {5} else {6};
    println!("The value of number is: {}", number);
}
```
`if` 表达式的返回值会被绑定到变量 `number` 上。很明显，这里绑定给变量 `number` 的值是 `5`。我们可以使用 `cargo run` 检查一下运行结果：
```powershell
The value of number is: 5
```
Rust 要求所有可能从 `if` 表达式返回的值都必须是同一个类型。例如：
```rust
fn main() {
    let number = if true {5} else {"six"}
}
```
以上代码会由于 `if` 表达式可能返回的 `5` 和 `"six"` 两个值类型不同而无法通过编译。

## 循环

如果我们想让某一段代码执行多次，该怎么实现呢？一种简单且笨的方法是将那段代码复制多次，例如：
```rust
fn main() {
    println!("again!");
    println!("again!");
    println!("again!");
}
```
显然复制不是一个好主意。以上代码打印了三次 `again!`，但如果我们想让程序一直不停地打印 `again!` 呢？这时候复制就无能为力了（毕竟复制是个体力活😏）。正确的姿势是使用循环，循环可以不断地执行，我们也可以在某个时候中止循环。Rust 中有三类循环：`loop`、`while` 和 `for`。

### loop

`loop` 告诉 Rust 不停地重复执行某个代码块。例如：
```rust
fn main() {
    loop {
        println!("again!");
    }
}
```
如果运行这段代码，你的屏幕上会不断地打印出 `again!`。在你手动停止程序之前，这个打印过程不会停止。

你可能想问，如果我想在某个时候退出循环，应该怎么做？答案就是使用 `break` 关键字显式地告诉程序不要再执行循环了。例如：
```rust
fn main() {
    let mut counter = 0;
    loop {
        if counter == 2 {
            println!("The value of counter is: 2. Over!");
            break;
        }
        println!("The value of counter is not 2. Again!");
        counter += 1;
    }
}
```
这段代码的结果如下：
```powershell
The value of counter is not 2. Again!
The value of counter is not 2. Again!
The value of counter is: 2. Over!
```

在 Rust 中，`break` 不仅可以终止循环，还可以在终止循环的时候返回一个值供程序中的其它代码使用。这使得 `break` 有点像 Rust 函数中的 `return` 了。我们来看一个例子：
```rust
fn main() {
    let mut counter = 0;

    let result = loop {
        counter += 1;

        if counter == 2 {
            break counter;
        }
    };

    println!("The result is {}", result);
}
```
以上代码中声明了一个 `result` 变量，它将持有从 `loop` 循环返回的值。最终程序的输出结果为：
```powershell
The result is 2
```

### while

在 `loop` 的例子中，我们不断检查 `counter` 的值，当 `counter` 的值为 `2` 时就使用 `break` 结束循环，否则继续执行循环内的代码块。这也可以使用 Rust 中的 `while` 循环来实现，而且它看起来更加简洁。让我们使用 `while` 循环来改造第一个 `counter` 示例：
```rust
fn main() {
    let mut counter = 0;
    while counter != 2 {
        println!("The value of counter is not 2. Again!");
        counter += 1;
    }
    println!("The value of counter is: 2. Over!");
}
```
程序的运行结果依然是：
```powershell
The value of counter is not 2. Again!
The value of counter is not 2. Again!
The value of counter is: 2. Over!
```

在 `while` 循环中，条件位于 `while` 关键字后面。每次循环之前都会检查条件是否成立，若成立则执行循环体内的代码，否则结束循环。

### for

Rust 中的 `for` 循环与其它编程语言中的 `for` 有些不同。它主要用于对集合或某个范围进行迭代操作，需要搭配关键字 `in` 使用，在某些情况下可以替代 `loop` 和 `while`。例如：
```rust
fn main() {
    for element in [1, 2, 3] {
        println!("{}", element);
    }
}
```
以上代码的运行结果为：
```powershell
1
2
3
```
再来看一个范围迭代：
```rust
fn main() {
    for element in 1..4 {
        println!("{}", element);
    }
}
```
以上代码的运行结果依然是：
```powershell
1
2
3
```
在 Rust 中，[范围（range）](https://doc.rust-lang.org/reference/expressions/range-expr.html)默认是左闭右开的。当然，范围也有左闭右闭的写法。例如，`1..4` 与 `1.=3` 是等价的。

## 参考资料

1. Steve Klabnik, Carol Nichols. [The Rust Programming Language](https://doc.rust-lang.org/stable/book/).