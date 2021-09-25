---
date: "2021-09-25T10:51:29+08:00"
title: "Rust 基础：所有权"
authors: ["zhannicholas"]
categories:
  - Rust
tags:
  - Rust
draft: false
toc: true
---

**所有权（ownership）** 是 Rust 独一无二的功能，也是 Rust 中的核心功能之一。Rust 不需要开发者手动回收内存，也没有垃圾收集器，但它还能保证内存安全，这就是所有权的强大之处。

在 Rust 中，内存的管理是通过所有权系统（ownership system）进行的，编译器会在编译时根据一系列的规则进行检查。更加令人赞叹的是，所有权系统中的任何功能都不会减慢程序的运行速度！

## 栈与堆

在开始学习所有权这个概念之前，我们有必要先回顾一下数据在内存中的存放形式。在 Rust 中，数据被存放在栈（stack）或堆（heap）中。

栈与堆组织数据的方式不同。在栈中，数据时先入后出（FILO）的，即最后存入的数据最先被使用。而在堆中，数据的使用就没有顺序要求，数据在堆中的组织情况比栈中要差很多。此外，存放在栈中的数据占用的空间必须是 **编译期间已知且固定的**，对于那些大小不固定或编译时无法知道大小的数据，应当被存放在堆上。在我们往堆中存数据时，内存分配器会从堆中找出一块大小合适的内存空间，标记其已使用，然后返回给我们一个指向分配地址的指针，后续我们就可以使用这个指针访问堆中的数据。这个指针会被存储在栈上，因为它的大小是固定且已知的。

将数据存储在栈上的速度要快于存储在堆上的速度。因为当数据被放在栈上时，内存分配器不需要为新数据找出一块空闲空间，数据总是被放在栈顶。如果数据要被放到堆上，内存分配器不仅需要从堆中找出一块合适的空闲空间，还需要防止这块空间被其它数据抢占。类似地，访问栈上数据的速度要快于访问堆上数据的速度。因为堆上的数据需要通过栈上的指针才能定位到，这比栈上的数据多了一次内存访问。

当我们调用一个函数时，传递给函数的值（或指向堆中数据的指针）和函数中的局部变量都是存放在栈上的。当函数调用结束后，这些值都会从栈中弹出。

讲了这么多，现在该所有权出场了。所有权负责 **跟踪哪部分代码正在使用堆中的哪部分数据，最大限度地减少堆中的重复数据，清理堆中未使用的数据，防止内存空间被耗尽**。简单来说，所有权管理着堆中的数据。

那么，Rust 中的哪些数据会被分配在堆上呢？答案是那些大小在编译期间不可知或者大小不固定的数据，比如字符串类型（`String`）。标量类型（整型、浮点型、布尔类型和字符类型）或复合类型（元组和数组）的数据都是存放在栈上的，作用域结束时就会被从栈上弹出。

需要注意的是：字符串类型（`String`）和字符串字面量（string literal）是不同的。字符串字面量（比如 `let s = "hello, world";`）是代码中硬编码的（编译时大小已知）、不可变的，而字符串类型的数据被存储在堆上，字符串类型的数据是可变的。我们可以使用 `String` 的 `from` 函数从字符串字面量创建一个 `String` 类型的变量，比如：
```rust
fn main() {
    let mut s = String::from("hello");
    s.push_str(", world!"); // push_str() appends a literal to a String
    println!("{}", s); // This will print `hello, world!`
}
```

## 所有权规则

所有权的规则如下，它们不可被违反：

* Rust 中的每个值都有一个变量，这个变量就是这个值的 **所有者（owner）**
* 每个值在同一时刻有且只有一个所有者
* 当所有者（变量）超出作用域（scope），值就会被丢弃（drop），值占据的内存被归还

变量在进入作用域后开始生效，此后，变量在超出作用域之前一直都是有效的。举个例子：
```rust
fn main() {
    { // s is not valid here, it’s not yet declared
        let s = "hello";   // s is valid from this point forward

        // do stuff with s
    }  // this scope is now over, and s is no longer valid
}
```

实际上，当变量超出作用域时，Rust 会自动为我们调用一个叫 `drop` 的特殊函数进行内存的归还。在上面这个例子中，`drop` 会在第一个 `}` 处被调用。

## 变量与数据的交互方式

在 Rust 中，多个变量可以以不同的方式与同一份数据进行交互，最常见的交互方式有移动（move）和克隆（clone）。

### 移动（Move）

先来看一段简单的代码：
```rust
fn main() {
    let x = 5;
    let y = x;
    println!("x = {}, y = {}.", x, y);
}
```
这段代码很简单，也能通过编译，最终运行会打印出结果 `x = 5, y = 5.`。如果将 `let x = 5;` 修改为 `let x = "5";`，仍然能得到一样的运行结果。但是，如果我将 `let x = 5;` 修改成 `let x = String::from("5");`，编译都过不去了😂。我并没有改动代码的结构，唯一改变的只有变量 `x` 的类型，这里面到底发生了什么？🤔

要回答这个问题，我们需要了解 Rust 中 `String` 在内存中的存储形式。为了能够使用官方的图，让我将代码修改为官方的代码😁：
```rust
fn main() {
    let s1 = String::from("hello");
    let s2 = s1;
    println!("s1 = {}, s2 = {}", s1, s2);
}
```
在 Rust 中，`String` 由三部分组成：指向字符串实际内容的指针、长度和容量。它们存放在栈上，对应下图中的左侧部分，字符串的实际内容则存放在堆上，对应下图中的右侧部分：

![](/images/rust/trpl04-01.svg)

当变量 `s1` 被赋值给 `s2` 后，字符串 `s1` 在栈上的数据被复制了一份给 `s2` 用，而堆上的内容没有被复制：

![](/images/rust/trpl04-02.svg)

这个过程似曾相识，它就像 Java 中的浅拷贝（shallow copy）一样。在，Rust 中，实际的过程不完全是这样，因为当 `s1` 和 `s2` 都超出作用域时，显然不应该归还两次内存。Rust 为了保证内存安全，并没有进行复制操作，而是在在执行 `let s2 = s1;` 之后使 `s1` 失效。这样，当 `s1` 超出作用域时，Rust 就不需要因为它释放任何内存了。让 `s1` 失效的操作在 Rust 中被称为 **移动（move）**，`let s2 = s1;` 的实际作用是让 `s1` 移动到 `s2`。所以，正确的图是下面这样的：

![](/images/rust/trpl04-04.svg)

这就是上面代码编译失败的原因，这下应该能看懂编译器给出的信息了：
```powershell
> cargo run
   Compiling ownership v0.1.0 (F:\Code\Rust\rust-study\ownership)
warning: unused variable: `s2`
 --> src\main.rs:3:9
  |
3 |     let s2 = s1;
  |         ^^ help: if this is intentional, prefix it with an underscore: `_s2`
  |
  = note: `#[warn(unused_variables)]` on by default

error[E0382]: borrow of moved value: `s1`
 --> src\main.rs:4:28
  |
2 |     let s1 = String::from("hello");
  |         -- move occurs because `s1` has type `String`, which does not implement the `Copy` trait
  |              -- value moved here
4 |     println!("{}, world!", s1);
  |                            ^^ value borrowed here after move

error: aborting due to previous error; 1 warning emitted

For more information about this error, try `rustc --explain E0382`.
error: could not compile `ownership`

To learn more, run the command again with --verbose.
F:\Code\Rust\rust-study\ownership [master +4 ~0 -0 !]> cargo run
   Compiling ownership v0.1.0 (F:\Code\Rust\rust-study\ownership)
error[E0382]: borrow of moved value: `s1`
 --> src\main.rs:4:34
  |
2 |     let s1 = String::from("hello");
  |         -- move occurs because `s1` has type `String`, which does not implement the `Copy` trait
3 |     let s2 = s1;
  |              -- value moved here
4 |     println!("s1 = {}, s2 = {}", s1, s2);
  |                                  ^^ value borrowed here after move

error: aborting due to previous error

For more information about this error, try `rustc --explain E0382`.
error: could not compile `ownership`

To learn more, run the command again with --verbose.
```

### 克隆（Clone）

Rust 不会自动进行数据的深拷贝（deep copy），因为深拷贝会对程序的性能造成很大的影响。如果我们希望 Rust 进行数据的深拷贝，需要使用 `clone` 方法。例如：

```rust
fn main() {
    let s1 = String::from("hello");
    let s2 = s1.clone();
    println!("s1 = {}, s2 = {}", s1, s2);
}
```

这样一来，`s1` 和 `s2` 涉及的数据就是下图中展示的这样了：

![](/images/rust/trpl04-03.svg)

### 栈上数据的复制（Copy）

现在来思考为啥 `let x = 5;` 或 `let x = "5";`时代码能够正常运行。这是因为 `5` 和 `"5"` 的大小都是固定的，程序编译时就可以知道它们的大小，所以数据被分配在了栈上。而 **Rust 对栈上数据的复制采取的是深拷贝**，深拷贝就不存在移动了。

还记得编译错误“move occurs because `s1` has type `String`, which does not implement the `Copy` trait”吗？Rust 中有一个特殊的注解叫做 **`Copy`**。如果某种数据类型实现了 `Copy`，旧变量在赋值之后仍然是可以使用的。此外，Rust 中还有一个特殊的注解叫做 **`Drop`**，它会在变量超出作用域后做些事情。Rust 不允许我们将 `Copy` 放在了实现了`Drop` 的类型上，如果我们这么做，编译会失败。

那么，哪些类型实现了 `Copy` 呢？说实话，有点多，具体的内容可以查看 [Trait Copy](https://doc.rust-lang.org/std/marker/trait.Copy.html#)。你会发现，所有的标量类型都实现了 `Copy`。

## 所有权与函数

传递变量给函数时所有权的变化与变量赋值一样。根据数据类型的不同，可能发生移动（丢失所有权）或复制，下面例子中的注释解释得非常清楚：
```rust
fn main() {
    let s = String::from("hello");  // s comes into scope

    takes_ownership(s);             // s's value moves into the function...
                                    // ... and so is no longer valid here

    let x = 5;                      // x comes into scope

    makes_copy(x);                  // x would move into the function,
                                    // but i32 is Copy, so it's okay to still
                                    // use x afterward

} // Here, x goes out of scope, then s. But because s's value was moved, nothing
  // special happens.

fn takes_ownership(some_string: String) { // some_string comes into scope
    println!("{}", some_string);
} // Here, some_string goes out of scope and `drop` is called. The backing
  // memory is freed.

fn makes_copy(some_integer: i32) { // some_integer comes into scope
    println!("{}", some_integer);
} // Here, some_integer goes out of scope. Nothing special happens.
```

如果函数带返回值呢？这个时候所有权也会发生转移：
```rust
fn main() {
    let s1 = gives_ownership();         // gives_ownership moves its return value into s1

    let s2 = String::from("hello");     // s2 comes into scope

    let s3 = takes_and_gives_back(s2);  // s2 is moved into takes_and_gives_back, which also
                                        // moves its return value into s3
} // Here, s3 goes out of scope and is dropped. s2 goes out of scope but was
  // moved, so nothing happens. s1 goes out of scope and is dropped.

fn gives_ownership() -> String {             // gives_ownership will move its
                                             // return value into the function that calls it

    let some_string = String::from("hello"); // some_string comes into scope

    some_string                              // some_string is returned and moves out to the calling function
}

// takes_and_gives_back will take a String and return one
fn takes_and_gives_back(a_string: String) -> String { // a_string comes into scope
    a_string  // a_string is returned and moves out to the calling function
}
```

## 引用

如果每次都进行 `takes_and_gives_back` 这种夺取所有权而后又归还所有权的操作，未免也太过繁琐。幸运的是，Rust 为我们提供了 **引用（reference）**，它可以消除 `takes_and_gives_bakc` 的尴尬之处。

下面是使用引用的一个例子：
```rust
fn main() {
    let s1 = String::from("hello");
    let len = calculate_length(&s1);
    println!("The length of '{}' is {}.", s1, len);
}

fn calculate_length(s: &String) -> usize {  // s is a reference to a String
    s.len()
} // Here, s goes out of scope. But because it does not have ownership of what it refers to, nothing happens.
```
引用允许我们引用某个变量，而不会夺取变量对数据的所有权。引用相关的操作符是 `&`，与之相反的操作叫解引用（dereferencing），操作符是 `*`。在以上代码中，`&s1` 创建了一个指向 `s1` 的引用，`s1` 依然持有字符串 `"hello"` 的所有权。

![](/images/rust/trpl04-05.svg)

由于 `&s1` 不具有数据的所有权，所以当 `&s1` 超出作用域时，数据不会被丢弃。Rust 将引用作为函数参数的操作称为 **借用（borrowing）**，这有点像现实生活中别人借了我们的东西又归还一样，所有权不会转移。

默认情况下，Rust 是不允许我们修改借用的数据的：
```rust
fn main() {
    let s = String::from("hello");
    change(&s);
}

fn change(some_string: &String) {
    some_string.push_str(", world");
}
```

以上代码会编译失败，并且编译器会告诉我们错误原因，并给出正确的修改建议：
```powershell
> cargo run
   Compiling ownership v0.1.0 (F:\Code\Rust\rust-study\ownership)
error[E0596]: cannot borrow `*some_string` as mutable, as it is behind a `&` reference
 --> src\main.rs:7:5
  |
6 | fn change(some_string: &String) {
  |                        ------- help: consider changing this to be a mutable reference: `&mut String`
7 |     some_string.push_str(", world");
  |     ^^^^^^^^^^^ `some_string` is a `&` reference, so the data it refers to cannot be borrowed as mutable

error: aborting due to previous error

For more information about this error, try `rustc --explain E0596`.
error: could not compile `ownership`

To learn more, run the command again with --verbose.
```

### 可变引用

在上面的错误中，编译器建议我们将 `change` 函数的参数由 `&String` 修改为 `&mut String`，即从不可变引用（immutable reference）修改为可变引用（mutable reference）。这操作和普通变量的可变与不可变类似。正确的代码应该是：
```rust
fn main() {
    let mut s = String::from("hello");
    change(&mut s);
}

fn change(some_string: &mut String) {
    some_string.push_str(", world");
}
```
这里进行了三处修改：首先将 `s` 改为可变的 `mut s`，然后是传递给 `change` 的参数修改为 `&mut s`，最后是 `change` 函数的定义修改为 `&mut String`，三者缺一不可。

但是，可变引用有一个非常大的限制：**同一时刻，同一数据的可变引用只能有一个，而不可变引用却可以有多个**。例如，下面的代码会编译失败：
```rust
fn main() {
    let mut s = String::from("hello");
    let r1 = &mut s;
    let r2 = &mut s;
    println!("{}, {}", r1, r2);
}
```
编译器简单明了地指出了我的错误：
```powershell
> cargo run
   Compiling ownership v0.1.0 (F:\Code\Rust\rust-study\ownership)
error[E0499]: cannot borrow `s` as mutable more than once at a time
 --> src\main.rs:4:14
  |
3 |     let r1 = &mut s;
  |              ------ first mutable borrow occurs here
4 |     let r2 = &mut s;
  |              ^^^^^^ second mutable borrow occurs here
5 |     println!("{}, {}", r1, r2);
  |                        -- first borrow later used here

error: aborting due to previous error

For more information about this error, try `rustc --explain E0499`.
error: could not compile `ownership`

To learn more, run the command again with --verbose.
```
Rust 这么做的原因是为了防止编译期间的数据竞争（和 Java 并发中的数据竞争类似）。数据竞争会导致程序的行为超出预期，加大运行时诊断问题的难度。

那么应该如何修改上面有问题的代码呢？拆分两个变量的作用域即可：
```rust
fn main() {
    let mut s = String::from("hello");
    {
      let r1 = &mut s;
    }
    let r2 = &mut s;
    println!("{}, {}", r1, r2);
}
```

**在 Rust 中，引用的作用域从声明开始，结束于引用最后一次被使用**。Rust 不允许同一份数据在一个作用域内同时出现可变引用和不可变引用的情况。例如：
```rust
fn main() {
    let mut s = String::from("hello");

    let r1 = &s; // no problem
    let r2 = &s; // no problem
    let r3 = &mut s; // BIG PROBLEM

    println!("{}, {}, and {}", r1, r2, r3);
}
```
会出现以下编译错误：
```powershell
> cargo run  
   Compiling ownership v0.1.0 (F:\Code\Rust\rust-study\ownership)
error[E0502]: cannot borrow `s` as mutable because it is also borrowed as immutable
 --> src\main.rs:5:14
  |
3 |     let r1 = &s; // no problem
  |              -- immutable borrow occurs here
4 |     let r2 = &s; // no problem
5 |     let r3 = &mut s; // BIG PROBLEM
  |              ^^^^^^ mutable borrow occurs here
6 |     println!("{}, {}, and {}", r1, r2, r3);
  |                                -- immutable borrow later used here

error: aborting due to previous error

For more information about this error, try `rustc --explain E0502`.
error: could not compile `ownership`

To learn more, run the command again with --verbose.
```

但如果我将代码修改为：
```rust
fn main() {
    let mut s = String::from("hello");
    let r1 = &s; // no problem
    let r2 = &s; // no problem
    println!("{} and {}", r1, r2);
    // variables r1 and r2 will not be used after this point
    let r3 = &mut s; // no problem
    println!("{}", r3);
}
```
程序就能通过编译并正常运行。这是因为，`r3` 被声明之前，`r1` 和 `r2` 的作用域已经结束了，不存在作用域的重叠。

## 切片（Slice）

切片（slice）允许我们引用集合中的一段连续元素，它是一种没有所有权的数据类型。

### 字符串切片

字符串切片（string slice）是一个指向 `String` 中的一部分内容的引用，这部分内容是原字符串的一个子串。例如：
```rust
fn main() {
    let s = String::from("hello world");
    let hello = &s[0..5];   // hello
    let world = &s[6..11];  // world
    println!("{}, {}", hello, world); // hello, world
}
```

在上面这段代码中，`hello` 和 `world` 都只引用了 `s` 中的一部分：

![](/images/rust/trpl04-06.svg)

字符串切片类型在 Rust 中用 `&str` 表示，它比 `String` 更加灵活。因为 `&str` 不仅可以引用 `String` 的一部分，还能引用 `String` 的所有内容。利用 `&str`，我们可以编写获取字符串中第一个单词的函数：
```rust
fn first_word(s: &String) -> &str {
    let bytes = s.as_bytes();

    for (i, &item) in bytes.iter().enumerate() {
        if item == b' ' {
            return &s[0..i];
        }
    }
    &s[..]
}
```

现在可以来回答为啥字符串字面量是不可变的这个问题了。因为字符串字面量的数据类型是 `&str`，而 `&str` 是不可变引用。

### 其它类型的切片

除了字符串切片（`&str`），Rust 中还有很多其它类型的切片，比如数组的切片：
```rust

#![allow(unused)]
fn main() {
let a = [1, 2, 3, 4, 5];
let slice = &a[1..3];
assert_eq!(slice, &[2, 3]);
}
```
在以上代码中，`slice` 是数组 `a` 的切片，它的数据类型是 `&[int32]`。



## 参考资料

1. Steve Klabnik, Carol Nichols. [The Rust Programming Language](https://doc.rust-lang.org/stable/book/).