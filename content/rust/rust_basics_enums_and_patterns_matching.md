---
date: "2021-09-27T19:04:33+08:00"
title: "Rust 基础：枚举与模式匹配"
authors: ["zhannicholas"]
categories:
  - Rust
tags:
  - Rust
draft: false
toc: true
---

**枚举（enum or enumeration）** 是一种允许我们列举出所有可能的值的数据类型，每一个可能的值都是一个 `variant`。举个简单的例子，常见的 IP 地址有 IPv4 和 IPv6 两种，这时就可以定义一个表示 IP 地址类型的枚举类。

## 枚举的定义

我们先来定义一个表示 IP 地址类型的枚举类：
```rust
enum IpAddrKind {
  V4,
  V6,
}
```

现在我们可以使用刚定义的 `IpAddrKind` 了。在 Rust 中，枚举类型实例的通过 `::` 操作符创建的，`::` 的左边是命名空间（枚举类型），右边是枚举类型中的可能值（variant）。例如：
```rust
let four = IpAddrKind::V4;
let six = IpAddrKind::V6;
```
在 Rust 中，枚举类型中所有 variant 的类型都是相同的，这一点与其它编程语言有些不同。例如 `IpAddrKind::V4` 和 `IpAddrKind::V6` 的类型都是 `IpAddrKind`。现在的 `IpAddrKind` 只有类型的含义，并不能存储任何 IP 地址数据，我们把它稍微改造一下：
```rust
enum IpAddrKind {
  V4(String),
  V6(String),
}

let home = IpAddrKind::V4(String::from("127.0.0.1"));
let loopback = IpAddrKind::V6(String::from("::1"));
```

现在，`IpAddrKind` 都能存储地址数据了。不过它还可以变得更加高级，IPv4 的地址可以用四个 `0~255` 之间的整数表示：
```rust
enum IpAddrKind {
  V4(u8, u8, u8, u8),
  V6(String),
}

let home = IpAddrKind::V4(127, 0, 0, 1);
let loopback = IpAddrKind::V6(String::from("::1"));
```

这就是枚举比结构体更灵活的地址。枚举类型中的每一个值都可以是不同的类型，而结构体则做不到这一点。要同时表示两种类型的 IP 地址，需要定义两种不同类型的结构体，而只需要一种类型的枚举类即可！

枚举也是支持使用 `impl` 定义方法的。例如：
```rust
impl IpAddrKind {
    fn doSomething(&self) {
      println!("do something");
    }
  }

fn main() {
    let home = IpAddrKind::V4(String::from("127.0.0.1"));
    let loopback = IpAddrKind::V6(String::from("::1"));
    home.doSomething();
    loopback.doSomething();
}
```

以上代码为 `IpAddrKind` 定义了一个 `doSomething` 方法。枚举类型是不支持关联函数的。

## Option 与 Null

在支持 Null 的编程语言中，数据的值要么是 null，要么是 not-null。在这些编程语言中，我们必须非常小心，因为 `Null Pointer Exception` 经常出现。但在 Rust 中，是没有 Null 这个概念的，取而代之的是 `Option`。`Option` 是 Rust 标准库定义的一个枚举类型。它的作用非常大，可以表示有或者没有的概念。

我们可以换个角度来看待 null 与 not-null：not-null 表示值存在，而 null 表示值缺失。`Option` 恰好用`Some` 和 `None` 表达出了有与没有的概念：
```rust
enum Option<T> {
  None,
  Some<T>,
}
```

这里的 `<T>` 是 Rust 中的泛型语法，可以表示任何类型。我们不需要导入任何模块就可以直接使用 `Option`，因为它实在是太重要了。此外，`None` 和 `Some` 在使用时也可以不加 `Option::` 这个前缀。例如：
```rust
fn main() {
  let some_number = Some(5);
  let some_string = Some("a string");
  let absent_number: Option<i32> = None;
}
```
有一点需要注意：**在使用 `None` 的时候，我们必须显式地给出数据的类型**。因为 `None` 可以表示任何类型，Rust 的编译器是无法推断出它的实际类型的。

那么，为什么 `Option<T>` 比 null 要好呢？这时因为 `Option<T>` 和 `<T>` 表示的是不同的类型，编译器是不会允许我们将 `Option<T>` 当作绝对有效的值（编译器会确保 `<T>` 表示的值总是有效的）使用的，它会确保我们在使用 `Option<T>` 之前处理了空值的情况。

## 使用 match 进行模式匹配

Rust 提供了一个极其强大的控制流操作符——`match`。我们可以使用 `match` 进行模式匹配（pattern matching），然后在不同的模式下执行不同的代码。这种操作有点像 Java 和其它编程语言种的 `switch...case`。但是 Rust 种的模式匹配更加强大，模式可以是字面值、变量名、通配符等等。并且，Rust 的编译器会确保我们处理了所有可能的情况，这就是利用 `match` 进行模式匹配的强大之处。

现在来看一个例子：
```rust
enum IpAddrKind {
  V4(u8, u8, u8, u8),
  V6(String),
}

fn is_ipv4(ip: IpAddrKind) -> bool {
  match ip {
    IpAddrKind::V4(a, b, c, d) => true,
    IpAddrKind::V6(s) => false,
  }
}

fn main() {
  let home = IpAddrKind::V4(127, 0, 0, 1);
  let loopback = IpAddrKind::V6(String::from("::1"));
  println!("home is Ipv4 address: {}", is_ipv4(home));
  println!("loopback is Ipv4 address: {}", is_ipv4(loopback));
}
```
以上代码定义了一个判断 IP 地址是否为 IPv4 地址的函数 `is_ipv4`。程序的最终运行结果为：
```powershell
home is Ipv4 address: true
loopback is Ipv4 address: false
```

你可能会觉得 `match` 代码块种的 `(a, b, c, d)` 和 `(s)` 有些奇怪。这时因为我们定义的 `IPAddrKind::V4` 包含四个字段，`IpAddrKind::V6` 包含一个字段，在使用时必须给出所有字段的值，否则编译会报错。

我们来仔细看一下 `match` 表达式。整个表达式以 `match` 关键字开始，然后是被匹配的数据（`ip`），再往后则是由尖括号 `{}` 包裹的具体分支。每个分支之间用 `,` 隔开。Rust 管每个分支叫 arm，一个 arm 由三部分组成：
* 模式（例如 `IpAddrKind::V6(s)`）
* `=>` 操作符
* 匹配成功后执行的代码

再来看一个使用 `match` 匹配 `Option<T>` 的例子：
```rust
fn main() {
  fn plus_one(x: Option<i32>) -> Option<i32> {
    match x {
      None => None,
      Some(i) => Some(i + 1),
    }
  }

  let five = Some(5);
  let six = plus_one(five);
  let none = plus_one(None);
}
```

如果省略 `match` 代码块中的 `None => None,` 会怎么样呢？答案是编译失败，并且编译器会提示我们没有覆盖到 `None` 的情况。这再次说明了 Rust 要求我们在使用 `match` 进行模式匹配必须要覆盖所有的情况。

有时候，我们可能并不希望把模式所有可能的值都列举出来。这时可以使用 Rust 给我们提供的占位符 `_`。`_` 是一种特殊的模式，可以匹配所有的情况。一般将它放到最后，用于表示当前剩下的未列举出来的所有模式。例如：
```rust
fn plus_one(x: Option<i32>) -> Option<i32> {
  match x {
    Some(i) => Some(i + 1),
    _ => None,
  }
}
```

仔细看上面这个 `plus_one` 函数，实际有意义的操作只发生在 `x` 为 `Some(i)` 的时候，`_` 的情况略显多余。对于只需要匹配一模式并忽略剩余所有模式的情况，Rust 给我们提供了 `if let` 语法。例如：
```rust
fn main() {
  fn print_i32(x: Option<i32>) {
    if let Some(i) = x {
      println!("x = {}", i);
    };
  }

  print_i32(Some(1));
  print_i32(None);
}
```
程序的最终输出结果为：
```powershell
x = 1
```
`if let` 后面跟的分别是模式（`Some(i)`）、`=` 、被匹配的值（`x`）和匹配成功后进行的操作（`println!("x = {}", i);`）。

`if let` 也可以搭配 `else` 使用，例如：
```rust
fn plus_one(x: Option<i32>) -> Option<i32> {
  if let Some(i) = x {
    Some(i + 1)
  } else {
    None
  }
}
```


## 参考资料

1. Steve Klabnik, Carol Nichols. [The Rust Programming Language](https://doc.rust-lang.org/stable/book/).