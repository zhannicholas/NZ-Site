---
date: "2021-09-26T20:29:14+08:00"
title: "Rust 基础：结构体"
authors: ["zhannicholas"]
categories:
  - Rust
tags:
  - Rust
draft: false
toc: true
---

在 Rust 中，**结构体（struct or structure）** 是一种可自定义的数据类型，允许我们将一组相关数据组织在一起，形成一个有意义的整体。Rust 中的结构体和 C 语言中的结构体或 Java 中对象的数据属性类似。

## 结构体的定义

虽然 Rust 中的元组（tuple）也可以将一组相关数据组织在一起，但是元组中的各个数据项的含义却不那么直观，因为我们在访问元组中的元素时需要使用下标，而下标是没有任何特定的业务含义的。相比之下，结构体则更要灵活一些，它允许我们给结构体中的每个数据指定一个名字（这有点像键值对了）。

Rust 使用关键字 `struct` 定义结构体，下面是一个例子：
```rust
struct User {
  username: String,
  email: String,
  sign_in_count: u64,
  active: bool,
}
```
结构体 `User` 的定义主要由三部分组成：
* `struct` 关键字
* 结构体的名字，这里是 `User`
* 结构体的字段（field）定义，每个字段定义从左到右分别是字段的名字（比如 `username`）、冒号（`:`）和字段类型（比如 `String`），不同字段定义之间用逗号（`,`）隔开。最后一个逗号是可选的

需要注意的是：结构体的定义末尾不能加分号（`;`），否则编译器会抛出类似于下面这样的错误：
```txt
error: expected item, found `;`
 --> src\main.rs:6:2
6 | };
  |  ^ help: remove this semicolon
  |
  = help: braced struct declarations are not followed by a semicolon
```

## 结构体字段的访问与更新

结构体定义好了，接下来就是使用它。为了使用 `User` 结构体，我们需要创建一个 `User` 的实例（instance）：
```rust
fn main() {
    let user1 = User {
        email: String::from("someone@example.com"),
        username: String::from("someone"),
        active: true,
        sign_in_count: 1
    };

    println!("{}", user1.username);
}
```
创建结构体实例时，字段的顺序必须严格按照定义结构体时的顺序。但所有字段都必须给出，否则编译器会报错。以上示例还展示了读取结构体实例字段值的方法，那就是使用点符号（`.`）。

那么如何修改某个字段的值呢？答案还是使用点符号（`.`），并且还要将整个实例声明为可变的（Rust 并不允许我们将部分字段标记为可变的），例如：
```rust
fn main() {
    let mut user1 = User {
        email: String::from("someone@example.com"),
        username: String::from("someone"),
        active: true,
        sign_in_count: 1
    };

    user1.username = String::from("anotherone");

    println!("{}", user1.username);
}
```

这里我还发现了一个有趣的事情：**`String` 和 `&str` 是不同的类型**，虽然 `&str` 可以替代 `String`，但它们却是有着很大的不同！如果将 `user.username = String::from("anotherone");` 替换成 `user1.username = "anotherone";`，编译器就会抛出类型不匹配的错误：
```txt
error[E0308]: mismatched types
  --> src\main.rs:18:22
   |
18 |     user1.username = "anotherone";
   |                      |
   |                      expected struct `String`, found `&str`
   |                      help: try using a conversion method: `"anotherone".to_string()`
```

## 变量与字段同名时字段初始化的简写方法

除了在 `main` 函数中初始化结构体外，我们也可以单独定义一个函数来返回一个结构体的实例：
```rust
fn build_user(email: String, username: String) -> User {
    User {
        email: email,
        username: username,
        sign_in_count: 1,
        active: true
    }
}
```

有没有觉得这里的 `email` 和 `username` 的初始化略显重复？毕竟函数的参数名也是 `email` 和 `username`。这时，我们可以使用 **字段初始化简写语法（field init shorthand syntax）** 来简化代码：
```rust
fn build_user(email: String, username: String) -> User {
    User {
        email,
        username,
        sign_in_count: 1,
        active: true
    }
}
```
即：**当函数的参与名与结构体的字段名相同时，可以省略字段的值，但必须保留字段名**。

## 使用结构体更新语法从其它实例创建实例

有时候，我们会基于现有的实例去创建一个新的实例，然后仅改动新实例中的少部分字段的值，新实例中绝大部分字段值还是和旧实例一致。**结构体更新语法（struct update syntax）** 可以帮助我们更加优雅地实现这个目标。

首先看不使用结构体更新语法的写法：
```rust
let user2 = User {
    email: String::from("another@example.com"),
    username: String::from("another"),
    active: user1.active,
    sign_in_count: user1.sign_in_count,
};
```

再来看使用结构体更新语法的写法：
```rust
let user2 = User {
    email: String::from("another@example.com"),
    username: String::from("another"),
    ..user1
};
```
结构体更新语法 `..` 的作用是让剩下那些没有显式给出的字段的值与 `..` 后面给出的实例一致。需要注意的是 `..user1` 后面是不能跟 `,` 的，原因是 `error: cannot use a comma after the base struct`。

## 元组结构体

Rust 还支持没有字段名的结构体，这种结构体和元组类似，被称为 **元组结构体（tuple struc）**。元组结构体的定义由三部分组成：
* `struct` 关键字
* 结构体名字
* 字段类型组成的元组

例如：
```rust
fn main() {
    struct Color(i32, i32, i32);
    struct Point(i32, i32, i32);

    let black = Color(0, 0, 0);
    let origin = Point(0, 0, 0);
}
```
以上代码定义了两个结构体 `Color` 和 `Point`。虽然二者元组中的类型一样，但它们却是两个不同的结构体，不可混用！元组结构体的使用和元组类似，我们可以解构它，也可以是使用 `.` 加下标去访问特定的元素。

Rust 还支持没有任何字段的结构体，这种结构体被称为 **类单元结构体（Unit-Like Struct）**，它就像空元组 `()` 一样。

## 单元结构体

单元结构体（unit struct）不包含任何字段，例如：`struct Unit;`

## 结构体与所有权

**结构体拥有所有字段值的所有权，并且结构体内所有数据的有效期与结构体本身一致**。只要结构体有效，结构体内的数据就有效。还记得上文中提到的字段不匹配的错误吗？那个问题其实也和所有权有关系，因为 `&str` 是引用，它不具备数据的所有权。

## 方法

**方法（method）** 和函数（function）类似，二者除了定义的位置和参数列表不同外，其它完全相同。方法在结构体（或枚举（`enum`）和 `trait` 对象）的上下文中定义，并且第一个参数始终是 `self`（其它参数都在 `self` 后面）。`self` 表示的是当前的结构体实例，被调用的方法就在它身上。

### 方法的定义

前面提到过，方法的定义出现在一个某个上下文中。来看一个例子：
```rust
struct Rectangle {
    width: u32,
    height: u32,
}

impl Rectangle {
    fn area(&self) -> u32 {
        self.width * self.height
    }
}

fn main() {
    let rect1 = Rectangle {
        width: 30,
        height: 50,
    };

    println!(
        "The area of the rectangle is {} square pixels.",
        rect1.area()
    );
}
```

以上代码在 `Rectangle` 上下文中定义了一个求面积的方法 `area`。这里用到了 `impl` 关键字，其后是上下文 `Rectangle`，再往后则是方法的定义。

虽然 `area` 方法的定义中包含参数 `&self`，但是我们在调用它的时候，并没有显式地传入任何参数，而是简单地使用了 `rect1.area()`，这是因为 `&self` 在这里指代的是 `rect1`。仔细一看，似乎 `&self` 的类型与 `rect1` 的类型并不匹配，但为何没有出现错误呢？要回答这个问题，我们需要了解 Rust 中的 **自动引用和解引用（automatic referencing and deferencing）** 功能。

方法调用时发生自动引用与解引用的少数几个地方之一。这个功能的大致工作过程是这样的：当我们使用 `object.something()` 调用方法时，Rust 会自动添加 `&`、`&mut` 或 `*`，使得 `object` 与方法签名匹配。我们可以将上面代码中的 `self.width * self.height` 替换成 `&self.width * &self.height`，或将 `rect1.area()` 替换成 `&rect1.area()`，程序依然能正确运行。我们甚至可以将：
```rust
impl Rectangle {
    fn area(&self) -> u32 {
        self.width * self.height
    }
}
```
替换为：
```rust
impl Rectangle {
    fn area(self) -> u32 {
        &self.width * &self.height
    }
}
```

### 关联函数

除了定义方法外，`impl` 还允许我们定义不带 `self` 参数的函数。这种函数被称为 **关联函数（associated function）**，因为它们与结构体本身相关联。关联函数不是方法，因为它不涉及任何结构体实例。我们从字符串字面量创建 `String` 的 `from` 函数就是一个关联函数。在调用关联函数时，需要使用操作符 `::`，例如：`let s = String::from("hello");`。

## 参考资料

1. Steve Klabnik, Carol Nichols. [The Rust Programming Language](https://doc.rust-lang.org/stable/book/).
