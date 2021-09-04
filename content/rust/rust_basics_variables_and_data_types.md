---
date: "2021-09-03T21:32:35+08:00"
title: "Rust 基础：变量与数据类型"
authors: ["zhannicholas"]
categories:
  - Rust
tags:
  - Rust
draft: false
toc: true
mathjax: true
---

## 变量

### 变量与可变性

在 Rust 中，变量（variables）有两种：
* 不可变变量：一经赋值，就不再允许对变量的值进行修改
* 可变变量：可可对变量的值进行多次修改

在 Rust 中，我们使用 `let` 关键字声明一个变量，例如：`let x = 1`。默认情况下，`let` 声明的变量是 **不可变的**。如果代码里面出现不可变变量被多次赋值的情况，则代码是不会编译通过的。例如：
```rust
fn main() {
    let x = 5;
    println!("The value of x is: {}", x);
    x = 6;
    println!("The value of x is: {}", x);
}
```
如果使用 `cargo run` 运行这段代码，则会出现以下错误：
```powershell
> cargo run  
   Compiling variables v0.1.0 (F:\Code\Rust\rust-study\variables)
error[E0384]: cannot assign twice to immutable variable `x`
 --> src\main.rs:4:5
  |
2 |     let x = 5;
  |         -
  |         |
  |         first assignment to `x`
  |         help: consider making this binding mutable: `mut x`
3 |     println!("The value of x is: {}", x);
4 |     x = 6;
  |     ^^^^^ cannot assign twice to immutable variable

error: aborting due to previous error

For more information about this error, try `rustc --explain E0384`.
error: could not compile `variables`

To learn more, run the command again with --verbose.
```
Cargo 给了我们很多有用的错误信息，其中就一行被标成了红色，十分醒目：`cannot assign twice to immutable variable`。也就是说，不可以再次给不可变变量赋值。

解决错误的方法很简单，将第二行替换成 `let mut x = 5` 即可。我们在变量 `x` 之前加了一个关键字 `mut`，表明 `x` 是一个可变变量。再次运行 `cargo run`，我们就能看到正确的输出了。

### 常量

和其它编程语言一样，Rust 中也有常量（constants）这个概念。Rust 中的常量在赋值之后就不能修改。有人可能会问，这不就跟不可变变量一样吗？实际上，这只是常量与不可变变量的一个相同点，二者还是有差异的。

首先，声明常量的关键字是 `const`，而声明变量的关键字是 `let`。
```rust
const ONE: u32 = 1;
```
以上代码声明了一个名为 `ONE` 的常量，并赋值为 `1`。常量名约定使用大写字母，多个单词之间用下划线隔开。

其次，常量的赋值部分只能是一个常量表达式，不能是某个函数调用的结果或运行期间计算出来的值。而变量就没有这个限制。
```rust
let x = 1;
const SQUARE = x * x;
```
上面这段代码是无法正常编译的，因为 `x` 是变量，而 `SQUARE` 是常量，`x * x` 的值是在程序运行过程中计算出来的。

### 隐藏

我们可以多次定义一个同名的变量，后面定义的变量会隐藏（shadowing）它之前的同名变量，即程序只能看到最新一个同名变量的值。
```rust
fn main() {
    let x = 5;
    let x = x + 1;
    {
        let x = x * 2;
        println!("The value of x in the inner scope is: {}", x);
    }
    println!("The value of x is: {}", x);
}
```
以上这段代码很有意思，它首先将变量 `x` 的值绑定为 `5`，然后通过 `let x =` 隐藏 `5` 这个值，真正可见的值是 `6`。而在内部作用域中，第二个 `let` 再次隐藏 `x` 之前的值，真正可见的值是 `12`。内部作用域结束，作用域内的隐藏效果也结束了，`x` 的值又变成 `6`。所以，这个程序的输出结果应该是：
```powershell
The value of x in the inner scope is: 12
The value of x in the inner scope is: 6
```

如果我们去掉第二行开头的 `let`，程序就因不可变变量被再次赋值而编译失败。不可变变量的隐藏与不可变变量的赋值是完全不同的，我们可以认为隐藏就是重新声明了一个新的变量。

既然如此，为啥不直接使用可变变量呢？原因是隐藏更加灵活，因为不可变变量的变量类型在声明之后就不能再改了，而隐藏可以修改变量的数据类型。例如，下面的代码是可以编译成功的：
```rust
let a = 1;
let a = "1";
```
而下面这段代码将会编译失败：
```rust
let mut a = 1;
a = "1";
```

## 数据类型

Rust 是一门 **静态类型** 语言，在编译期间就必须确定所有变量的类型。Rust 中的每一个变量的值都属于某一数据类型，Rust 通过数据类型得知变量的值是何种数据，进而决定如何处理这个值。

我们并不需要一一声明变量所属的数据类型，Rust 的编译器是很智能的，它可以根据值及其使用方式推断出我们想要使用的数据类型。但是，当某个值可能属于多种数据类型时，我们就必须通过类型注解显式地给出变量的数据类型，否则编译就会出错。
```rust
let x = 1;  // 编译器可以推断出 x 的数据类型
let guess: u32 = "42".parse().expect("Not a number!");  // "42".parse() 的结果可能对应多种类型，所以需要使用类型注解
```

在 Rust 中，数据类型分为两类：标量类型（scalar types）和复合类型（compound types）

### 标量类型

一个标量类型表示的是单个值。Rust 中有四种基本的标量类型：整型、浮点型、布尔类型和字符类型。

#### 整型

整型（integer）是没有小数部分的数字。根据是否可以表示负数，整型又可以分为有符号整型和无符号整型。下面的表格列出了 Rust 中的所有整型：

| Length | Signed | Unsigned |
|--------|--------|----------|
|  8-bit |   i8   |    u8    |
| 16-bit |   i16  |   u16    |
| 32-bit |   i32  |   u32    |
| 64-bit |   i64  |   u64    |
| 128-bit|   i128 |   u128   |
|  arch  |  isize |   usize  |

其中，有符号整型以字母 `i` 开头，无符号整型以字母 `u` 开头。`i` 或 `u` 后面的数字即该类型所占的二进制位数。假设整型的长度为 `n` 位，则有符号整型能表示数值范围的区间是 $[-2^{n - 1}, 2^{n - 1} - 1]$，而无符号整型能表示数值范围区间是 $[0, 2^n - 1]$。例如，`i8` 可存储的数值范围是 [0, 255]，而 `u8` 可存储的数值范围是 [-128, 127]。表格中的 `isize` 和 `usize` 类型由运行程序的机器架构决定：对于 64 位架构的计算机来说，它们就是 64 位的，而对于 32 位架构的计算机来说，它们就是 32 位的。Rust 中默认的整型是 `i32`。

除了将整数写成最常见的十进制形式外，Rust 还允许我们将数字写成十六进制、八进制等形式。为了便于阅读，我们不仅可以在数值后面跟上它的具体类型（比如 `58u8` 表示 `u8` 类型的数字 `58`），还可以使用下划线（`_`）对数字进行分隔（比如 `10_000` 就是数字 `10000`）。下面表格列出了 Rust 中的各种整数表示法：

| Number Literals | Example |
|-----------------|---------|
|     Decimal     |  98_222 |
|     Hex         |  0xff   |
|     Octal       |  0o77   |
|     Binary      |  0b1111_0000 |
| Byte(`u8` only) |  b'A'   |

#### 浮点型

浮点型（floating-point）是带小数点的数字。Rust 有两种原生的浮点类型：单精度浮点型 `f32`（占 32 位）和双精度浮点型 `f64`（占 64 位）。`f64` 是 Rust 中默认的浮点类型。例如：
```Rust
let x = 2.0;  // f64
let y: f32 = 3.0; // f32
```

和大多数编程语言一眼，Rust 中的浮点型是使用 IEEE-754 标准表示的。

#### 布尔类型

Rust 中的布尔类型有两个可能的值：`true` 和 `false`。布尔类型占一个字节，类型注解为 `bool`。

#### 字符类型

字符类型（`char`）占 4 个字节，可以表示 `U+0000` 到 `U+D7FF` 之间和 `U+E000` 到 `U+10FFF` 之间的 Unicode 字符。

### 复合类型

复合类型可以将多个值组合到一个类型中。Rust 内置了元组（tuples）和数组（arrays）这两种复合类型。

#### 元组

元组可以包含不同类型得值，其长度在指定后就不能修改。创建一个元组的方式很简单，将各个值用逗号分隔，放在小括号当中即可：
```rust
let tup: (i32, f64, u8) = (500, 6.4, 1);
```
以上代码创建了一个包含三个不同类型数值的元组 `tup`。那么如何访问元组中的元素呢？Rust 给我们提供了两种方法，其中一种是使用模式匹配对元组进行解构（destructure）：
```rust
let tup = (500, 6.4, 1);
let (x, y, z) = tup;
println!("The value of y is: {}", y);
```
以上代码首先将元组 `(500, 6.4, 1)` 绑定到了变量 `tup` 上，然后使用模式 `(x, y, z)` 将 `tup` 分成了三个不同的部分，这个过程就是解构（destructring）。除了使用模式匹配解构外，我们还可以通过点号（`.`）加索引的方式访问元组中的值：
```rust
let tup = (500, 6.4, 1);
let x = tup.0;  // 500
let y = tup.1;  // 6.4
let z = tup.2;  // 1
println!("x = {}, y = {}, z = {}", x, y, z);
```
和大多数编程语言一样，Rust 中的下标也是从 0 开始的。

#### 数组

数组只能包含多个相同类型得值，其长度在指定后也不能修改。创建一个数组的方式也很简单，将各个值用逗号分隔，然后放到中括号当中即可：
```rust
let arr = [1, 2, 3];
```
我们可以通过下标访问数组中的元素：
```rust
let arr = [1, 2, 3];
let x = arr[0]; // 1
let y = arr[1]; // 2
let z = arr[2]; // 3
println!("x = {}, y = {}, z = {}", x, y, z);
```
我们也可以在声明数组的时候显式给出数组元素的类型和数组长度，例如：
```rust
let arr: [i32; 3] = [1, 2, 3];
```
以上代码声明了一个长度为 `3` 的数组 `[1, 2, 3]`，数组中的元素类型为 `i32`。

此外，Rust 还给我们提供了将数组初始化为相同值的简便写法：
```rust
let arr = [1; 3];
```
以上代码声明了一个长度为 `3` 的数组，数组中所有元素都是 `1`。该写法等价于：`let arr = [1, 1, 1]`。

## 参考资料

1. Steve Klabnik, Carol Nichols. [The Rust Programming Language](https://doc.rust-lang.org/stable/book/).