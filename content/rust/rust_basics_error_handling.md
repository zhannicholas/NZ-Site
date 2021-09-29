---
date: "2021-09-29T20:55:48+08:00"
title: "Rust 基础：错误处理"
authors: ["zhannicholas"]
categories:
  - Rust
tags:
  - Rust
draft: false
toc: true
---

任何软件都不可避免地出现各种或大或小的 Bug，软件设计的一大目标就是软件的健壮性，而错误处理就是提高软件健壮性的一大利器。作为一门对安全比较执着的编程语言，Rust 给我们开发者提供了很多处理错误的功能特性。

Rust 中的错误（error）分为两种：可恢复错误（recoverable error）和不可恢复错误（unrecoverable error）。在 Java 中，不仅有错误（error），还有异常（exception），但 Rust 中是没有异常的。对于可恢复错误，Rust 给我们提供了 `Result<T, E>` 这种数据类型，供我们作进一步决定。而对于不可恢复错误，Rust 给我们提供了一个叫做 `panic!` 的宏，`panic!` 会在程序遭遇不可恢复错误时立即停止程序的执行。

## 不可恢复错误与 `panic!`

有时候，你碰到的错误（比如数组下标越界）会让你束手无策。这时，你可以使用 Rust 提供的 `panic!` 宏直接终止程序，防止更坏的事情发生。当 `panic!` 执行时，Rust 程序默认会先打印出失败信息，[解退（unwinding）](https://doc.rust-lang.org/nomicon/unwinding.html)并清理栈，然后退出。解退是一种比较优雅退出方式，与之相对的是直接终止（abort）。二者的区别在于，解退会清理数据，归还内存，而直接终止就不会清理数据，回收内存的工作交给了操作系统。

先来看一个简单的 `panic!`：
```rust
fn main() {
    panic!("crash and burn");
}
```
这个程序一运行，就会出现错误信息：
```powershell
> cargo run
   Compiling error_handling v0.1.0 (F:\Code\Rust\rust-study\error_handling)
    Finished dev [unoptimized + debuginfo] target(s) in 3.19s
     Running `target\debug\error_handling.exe`
thread 'main' panicked at 'crash and burn', src\main.rs:2:5
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
error: process didn't exit successfully: `target\debug\error_handling.exe` (exit code: 101)
```
倒数第三行展示了 panic 出现的具体位置——src/main.rs 的第二行，倒数第二行则告诉了我们展示回溯（backtrace）的方法，最后一行则是给出了进程成功退出以及退出码的信息。

### Backtrace

如果 panic 出现在我们写的代码还好，这时可以直接看到错误发生在哪一行。但如果 panic 出现在 Rust 的核心库或者标准库内部会怎样呢？我们来看一个数组下标越界的例子：
```rust
fn main() {
    let v = vec![1, 2, 3];
    v[99];
}
```
这份代码能够正常通过编译，但是在运行的时候会出现以下错误：
```powershell
> cargo run
   Compiling error_handling v0.1.0 (F:\Code\Rust\rust-study\error_handling)
    Finished dev [unoptimized + debuginfo] target(s) in 2.67s
     Running `target\debug\error_handling.exe`
thread 'main' panicked at 'index out of bounds: the len is 3 but the index is 99', src\main.rs:3:5
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
error: process didn't exit successfully: `target\debug\error_handling.exe` (exit code: 101)
```
虽然错误信息告诉了我们错误发生在第三行，但没有给出具体是哪个地方导致了 panic 的出现。根据提示，我们可以使用环境变量 `RUST_BACKTRACE=1` 来展示 backtrace。

Backtrace 是一个由执行到 panic 发生位置过程中被调用的函数组成的列表。通过它，我们就能一步一步地走到 panic 出现的具体位置。我们修改环境变量，重新运行程序：
```powershell
> $env:RUST_BACKTRACE=1
> cargo run
    Finished dev [unoptimized + debuginfo] target(s) in 0.06s
     Running `target\debug\error_handling.exe`
thread 'main' panicked at 'index out of bounds: the len is 3 but the index is 99', src\main.rs:3:5
stack backtrace:
   0: std::panicking::begin_panic_handler
             at /rustc/a178d0322ce20e33eac124758e837cbd80a6f633\/library\std\src\panicking.rs:515
   1: core::panicking::panic_fmt
             at /rustc/a178d0322ce20e33eac124758e837cbd80a6f633\/library\core\src\panicking.rs:92
   2: core::panicking::panic_bounds_check
             at /rustc/a178d0322ce20e33eac124758e837cbd80a6f633\/library\core\src\panicking.rs:69
   3: core::slice::index::{{impl}}::index<i32>
             at /rustc/a178d0322ce20e33eac124758e837cbd80a6f633\library\core\src\slice\index.rs:184
   4: core::slice::index::{{impl}}::index<i32,usize>
             at /rustc/a178d0322ce20e33eac124758e837cbd80a6f633\library\core\src\slice\index.rs:15
   5: alloc::vec::{{impl}}::index<i32,usize,alloc::alloc::Global>
             at /rustc/a178d0322ce20e33eac124758e837cbd80a6f633\library\alloc\src\vec\mod.rs:2428
   6: error_handling::main
             at .\src\main.rs:3
   7: core::ops::function::FnOnce::call_once<fn(),tuple<>>
             at /rustc/a178d0322ce20e33eac124758e837cbd80a6f633\library\core\src\ops\function.rs:227
note: Some details are omitted, run with `RUST_BACKTRACE=full` for a verbose backtrace.
error: process didn't exit successfully: `target\debug\error_handling.exe` (exit code: 101)
```
这次输出的信息就多了不少。在 backtrace 中，最下面是我们写的代码，最上面则是库中发生 panic 的具体位置。若要避免 panic，我们就需要修改自己的代码，防止代码缺陷被库函数触发库函数内的 panic。


## 可恢复错误与 `Result<T, E>`

`panic!` 一般用于那些我们无法处理的错误，但在实际的编程过程中，大部分失败情况都是我们能够处理的。这时，我们一般会拿到错误信息，然后根据错误信息进行相关处理，确保程序能够继续执行下去。

`Result<T, E>` 这个枚举类型就是专门用来处理可能出现的失败的，它的定义如下：
```rust
enum Result<T, E> {
    OK(T),
    Err(E),
}
```
`Result` 包含 `OK` 和 `Err` 这两个 variant，分别表示成功和失败的情况。这里的 `T` 和 `E` 都是泛型参数，分别用来表示 `OK` 中成功的返回值的类型和 `Err` 中失败的错误类型。

我们来看一个打开文件的例子：
```rust
use std::fs::File;

fn main() {
    let f = File::open("hello.txt");
}
```
打开一个文件可能有多种结果：如果文件存在并且是可读的，我们就能从 `Result` 的 `OK` 中得到一个文件句柄（file handle），否则得到的将会是 `Err` 中携带的错误。错误可能是文件不存在，也可能是我们没有文件的读取权限……。如果是文件不存在，我们就可以主动创建文件，然后继续执行后续步骤。这就是一个可恢复错误的例子。先来看最简单的，文件不存在时直接退出：
```rust
use std::fs::File;

fn main() {
    let f = File::open("hello.txt");

    let f = match f {
        Ok(file) => file,
        Err(error) => panic!("Problem opening the file: {:?}", error),
    };
}
```
以上代码用 `match` 去匹配枚举类 `Result`，成功时得到文件句柄，失败时输出错误信息并退出程序。如果我们想在文件不存在时创建文件该怎么做呢？这种情况下，就需要去判断错误的类型：
```rust
use std::fs::File;
use std::io::ErrorKind;

fn main() {
    let f = File::open("hello.txt");

    let f = match f {
        Ok(file) => file,
        Err(error) => match error.kind() {
            ErrorKind::NotFound => match File::create("hello.txt") {
                Ok(fc) => fc,
                Err(e) => panic!("Problem creating the file: {:?}", e),
            },
            other_error => {
                panic!("Problem opening the file: {:?}", other_error)
            }
        },
    };
}
```
现在代码开起来开始有点复杂了。实际上，`Result` 有一个方法叫 `unwrap_or_else`，它可以代替上面的 `match` 表达式：
```rust
use std::fs::File;
use std::io::ErrorKind;

fn main() {
    let f = File::open("hello.txt").unwrap_or_else(|error| {
        if error.kind() == ErrorKind::NotFound {
            File::create("hello.txt").unwrap_or_else(|error| {
                panic!("Problem creating the file: {:?}", error);
            })
        } else {
            panic!("Problem opening the file: {:?}", error);
        }
    });
}
```

### 错误的传播

有时候，我们可能并不像自己处理错误，而是希望将错误的处理交给调用我们代码的人。当我们这么做时，就将错误传播（propagating）给了调用方，给了调用方更多的控制能力。例如，当文件不存在时，直接返回错误给调用方：
```rust
use std::fs::File;
use std::io;
use std::io::Read;

fn read_username_from_file() -> Result<String, io::Error> {
    let f = File::open("hello.txt");

    let mut f = match f {
        Ok(file) => file,
        Err(e) => return Err(e),
    };

    let mut s = String::new();

    match f.read_to_string(&mut s) {
        Ok(_) => Ok(s),
        Err(e) => Err(e),
    }
}
```
为了提高代码的可读性，Rust 还给我们提供了一个传播错误的简便写法——使用 `?` 操作符。例如，`?` 操作符改写上述代码的结果如下：
```rust
fn read_username_from_file() -> Result<String, io::Error> {
    let f = File::open("hello.txt")?;

    let mut s = String::new();

    f.read_to_string(&mut s)?;
    OK(s)
}
```
`?` 甚至还支持链式操作：
```rust
fn read_username_from_file() -> Result<String, io::Error> {
    let mut s = String::new();
    File::open("hello.txt")?.read_to_string(&mut s)?;
    OK(s)
}
```
但是，`?` 的使用是有限制的。它只能用在返回结果类型是 `Result`、`Option` 或实现了 `std::ops::Try` 的类型的函数上。

## 参考资料

1. Steve Klabnik, Carol Nichols. [The Rust Programming Language](https://doc.rust-lang.org/stable/book/).
