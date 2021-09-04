---
date: "2021-09-02T19:45:08+08:00"
title: "Hello, Rust!"
authors: ["zhannicholas"]
categories:
  - Rust
tags:
  - Rust
draft: false
toc: true
---

> 年初学过几天 Rust，走马观花，很快就忘完了。现在有了些空闲时间，准备重新好好地把 Rust 学一遍，为后续操作系统的深入学习做好铺垫。在此之前，我主要写 Java，几乎所有的 Java 开发者都有过内存溢出（OOM）或内存泄露的噩梦。为了避免各种内存问题，Java 开发者通常需要熟悉垃圾回收，以及如何进行垃圾收集器的调优。当我第一次遇到 Rust 的时候，就被 Rust 惊人的运行速度和极高的内存利用率所吸引，这门语言居然没有运行时（runtime）和垃圾回收器（garbage collector），多么地神奇！

## 安装 Rust

学习一门编程语言的最佳方式就是实践。在实践之前，我们需要准备好相应的开发环境。Rust 推荐我们使用 [`rustup`](https://github.com/rust-lang/rustup.rs) 安装 Rust。`rustup` 是一个命令行工具，用于管理 Rust 版本和相关的其它工具。在 Windows 平台上，我只需要先下载 `rustup`，运行它，然后根据提示一步一步操作即可。除了 `rustup`，还有很多其它的安装方法，具体可以参考[官方文档](https://forge.rust-lang.org/infra/other-installation-methods.html)。

安装完成后，我们可以通过 `rustc --version` 检查是否安装成功。若控制台输出了 `rustc x.y.z (abcabcabc yyyy-mm-dd)` 形式的版本号，则表示安装成功。

## rustup

`rustup` 是一个很有用的工具，它给我们提供了很多实用的功能。

* 更新 Rust 到最新版本：`rustup update`
* 卸载 Rust 和 `rustup`：`rustup self uninstall`
* 查看 Rust 的本地文档：`rustup doc`

## Hello, world!

从大学的 C/C++，到后来的 Java、Python，我们学习一门新的编程语言几乎都是从“Hello, world!”开始。下面来写一个 Rust 版本的“Hello, world!”。

为了组织好代码，我们通常会将不同的代码放到不同的文件夹中。先给“Hello, world!”创建一个文件夹 `hello_world`：
```powershell
> mkdir hello_world
> cd hello_world
```
现在，创建 Rust 的源代码文件，这里我管它叫 `hello_world.rs`。Rust 的源代码文件总是以 `.rs` 结尾，如果文件名包含不止一个单词，建议使用下划线（`_`）分隔。
```rust
fn main() {
    println!("Hello, world!");
}
```
这就是 Rust 版本的“Hello, world!”源代码，和 Java 比起来，简单了太多。下一步要做的就是编译源文件得到可执行文件，然后运行：
```powershell
> rustc hello_world.rs
> ./hello_world.exe
Hello, world!
```
到此，我们“Hello, world!”就全部完成了。

## Hello, world! 详解

“Hello, world!” 虽然只有短短三行，但麻雀虽小，五脏俱全。它包含了一个简单 Rust 程序必要的组成部分。首先是
```rust
fn main() {

}
```
这里定义了一个 Rust 函数。和很多编程语言一样，`main` 函数有着特殊的地位，它是 Rust 程序的执行入口。我们的“Hello, world!” 中的 `main` 函数是没有参数的，如果你需要参数，把它们放到 `()` 中即可。函数体被包裹在 `{}` 中，Rust 中习惯将 `{` 放在函数定义的同一行，中间用一个空格隔开。

> 实际上，我们不需要过于在意代码的风格。因为 Rust 给我们提供了一个代码自动格式化工具——`rustfmt`，它是随着 Rust 的分发包一起发布的，也就是说，你的电脑上已经有它了。

在 `main` 函数内部有一行代码：
```rust
    println!("Hello, world!");
```
这行代码正是整个“Hello, world!”的核心部分，它将“Hello, world!”打印到了我们的屏幕上。它包含了四个值得我们注意的点：
* Rust style 的缩进是四个空格，而不是一个 TAB
* `println!` 调用了 Rust 宏（macro）。如果是调用普通函数的话，是没有后面那个 `!` 的，这就是调用宏与普通函数的区别
* `"Hello, world!"` 是一个字符串，我们将它作为参数传递给 `println!`，最终被输出到了屏幕上
* 代码上的末尾有一个 `;`，代表着当前表达式结束，它后面就是一个新的表达式了

除了宏与函数外，剩余三个部分都和 Java 等编程语言类似。

## 从编译到运行

Rust 是一种 **预编译（ahead-of-time compiled）** 语言，我们可以将编译出来的 Rust 程序直接交给别人，他们不需要安装 Rust 就可以直接运行。与 Python 和 JavaScript 等将编译和运行放在一起的动态语言不同，Rust 中编译和运行是分开的两个步骤。在“Hello, world!”中，我们先通过 Rust 的编译器 `rustc` 编译源代码：
```powershell
> rustc hello_world.rs
```
在 Windows 上，如果编译成功，我们就会得到两个文件： *hello_world.exe*和 *hello_world.pdb*。其中，*hello_world.exe* 是 Windows 平台上的二进制可执行文件，*hello_world.pdb* 则是针对 Windows 创建的文件，它包含符号（symbol）、类型（type）和模块（module）等调试信息。[pdb](https://docs.rs/pdb/0.7.0/pdb/) 即“Program Database”。

在 Linux 上，如果编译成功，则只会得到一个二进制可执行文件：*hello_world*。

不管是 Windows 上的 *hello_world.exe*，还是 Linux 上的 *hello_world*，我们都可以把它们直接放到另一台没有安装 Rust 的机器上运行。这就是 Rust 没有运行时（runtime）的具体体现。与之相对的 Java 语言就是一个很好的例子，我们先将 Java 的源代码文件 `.java` 编译成字节码文件 `.class`，再使用 `java` 命令运行编译字节码文件。这就要求目标机器上安装有 JRE（Java Runtime Environment）。

## Cargo

如果程序很简单，使用 `rustc` 就能轻易应付。但是，随着项目的增长，项目的方方面面都需要被管理，这时 `rustc` 就难以胜任了。所以，Rust 给我们提供了一个工具——Cargo。[Cargo](https://doc.rust-lang.org/cargo/) 是 Rust 的程序构建系统和包管理器，可以帮我们完成构建代码、下载依赖等任务。Cargo 之于 Rust 就像  Maven 或 Gradle 之于 Java。

默认情况下，安装 Rust 的时候也会一并安装 Cargo，我们可以通过以下命令检查 `cargo` 是否被正确安装：
```powershell
> cargo --version
```

### 使用 cargo 创建新项目

使用 cargo 创建新项目的操作尤为简单。
```powershell
> cargo new hello_cargo
> cd hello_cargo
```
在 `hello_cargo` 文件夹内，Cargo 默认为我们生成了 `.git` 目录和 `.gitignore`、源代码目录 `src` 以及 Cargo 的配置文件 `Cargo.toml`。源代码目录 `src` 里面有一个文件叫 `main.rs`，它的内容和前文的 `hello_world.rs` 一致。Cargo 期望所有的源代码文件都位于 `src` 目录内，项目的根目录中一般是配置文件、README、LICENSE 等与源代码无关的文件。

我们要重点关注的是 `Cargo.toml`，文件的内容如下：
```toml
[package]
name = "hello_cargo"
version = "0.1.0"
edition = "2018"

# See more keys and their definitions at https://doc.rust-lang.org/cargo/reference/manifest.html

[dependencies]
```
[`.toml`](https://toml.io/) 是一种文件格式，它通过片段（section）组织文件内容。我们的 `Cargo.toml` 就包含 `[package]` 和 `[dependencies]` 两个片段。其中，`[package]` 下面罗列的是当前包的配置信息，这里包括项目名称（name）、版本（version）和 Rust 版本（edition）；`[dependencies]` 下面罗列的则是项目的依赖。在 Rust 中，代码包被称为 crates。由于 `hello_cargo` 不需要任何依赖（crates），所以 `[dependencies]` 下面是空的。

### 构建并运行 Cargo 项目

构建 Cargo 项目的命令是：
```powershell
> cargo build
```
以 `hello_cargo` 为例，在 Windows 上执行 `cargo build` 之后，项目的根目录下会多出一个 `target` 文件夹和一个 `Cargo.lock` 文件。你会发现 `target` 下有一大堆文件，其中大部分文件都不是太重要，真正的可执行文件是 `target/debug/hello_cargo.exe`。
```powershell
> ./target/debug/hello_cargo.exe
Hello, world!
```

`Cargo.lock` 是第一次运行 `cargo build` 才会创建的文件，Cargo 用它来跟踪项目中依赖的具体版本。这个文件仅仅是给 Cargo 自己使用的，我们不应该去编辑它。

除了先手动构建项目再手动运行可执行文件外，Cargo 还给我们提供了一条可以自动构建并运行可执行文件的命令——`cargo run`。

### 使用 `cargo check` 检查错误

Cargo 还给我们提供了一个叫 `cargo check` 的命令，它会分析当前包内的代码并报告错误，但并不会产生可执行文件。通常情况下，`cargo check` 的执行速度比 `cargo build` 要快得多。如果你经常在编写代码的过程中通过编译来检查代码问题，那么 `cargo check` 绝对会成为你加速开发的好帮手。很多 Rustaceans 都在编写代码的过程中定期运行 `cargo check`，确保代码可以正常编译。当他们准备好运行可执行文件时，才会使用 `cargo build`。

### profiles

Cargo 给我们提供了两种 profile，用于不同场景下的程序构建：
* Default Profile：用于开发环境，`cargo build` 默认选项
* --release Profile：用于发布项目，需要通过 `cargo build --release` 显式指出

在开发过程中，我们通常希望编译尽可能快，这样我们能够更快地进行验证，所以 `cargo build` 默认会生成开发用过程使用的可执行文件。在我们使用 `cargo build --release` 构建发布项目时，Cargo 会在编译发布版本的过程中进行一系列优化。这些优化会使得你的 Rust 程序运行得更快，但是会消耗更多的编译时间。程序的最终用户通常希望程序运行尽可能地快，这正是是 `cargo build --realease` 花更多编译时间进行优化的原因。

不同 profile 构建出来的最终文件存放位置是不一样的。`cargo build` 编译出来的文件位于 `target/debug` 目录下，而`cargo build --release` 编译出来的文件位于 `target/release` 目录下。


## 参考资料

1. Steve Klabnik, Carol Nichols. [The Rust Programming Language](https://doc.rust-lang.org/stable/book/).