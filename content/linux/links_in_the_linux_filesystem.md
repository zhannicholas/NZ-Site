---
date: "2021-07-27T10:46:48+08:00"
title: "Linux 中的硬链接与软链接"
authors: ["zhannicholas"]
categories:
  - Linux
tags:
  - Linux
draft: false
toc: true
---

在 Linux 中，有一个东西叫链接文件，它有点像 Windows 中的快捷方式，可以很方便地实现文件的共享。链接主要分为两种：**硬链接（hard link）** 和 **软连接（soft link）**。链接在 Linux 非常有用，因为在 Linux 中，“every thing is a file”，链接可以带来极大的灵活性。

## Inode

在开始之前，让我们先简单了解一下磁盘分区与 [索引节点（inode）](https://en.wikipedia.org/wiki/Inode)。

为了方便管理和保证数据的安全，我们通常会对磁盘进行分区。每个分区都可以被单独挂载（mount）或取消挂载（umount）。每个分区都有自己的文件系统，不同分区的文件系统可以不同。在 Linux 文件系统中，文件就用 inode 表示，每个文件都有自己对应的 inode。每个分区都有一组自己的 inode ，不同分区的 inode 互不影响，因为它们位于不同的文件系统。在建立文件系统时，会建立一个 inode 表，表中包含一定数量的 inode 。每创建一个文件，系统就会分配一个 inode 号（inode number）给它，这个 inode 号就相当于文件的地址。

Linux 的文件实际上由两部分组成：数据部分和文件名部分。文件名部分保存在目录中，它包含文件的名字以及对应的 inode 号，通过 inode 号我们就可以找到数据部分的相关信息。通过分开存储文件名和文件数据，Linux 系统就能做到多个文件名关联同一个 inode 号。文件的数据部分不仅包括文件所有者、创建时间等元数据，还包括实际文件内容所在的磁盘位置。硬链接和软连接其实就是两种将多个文件名关联到同一份文件数据的方法。

## 硬链接

多个文件名可以指向同一个 inode 号，这些文件的关系就是硬链接的关系。简单来说，一个硬链接就是一个目录项，它关联的是文件名与 inode。由于文件本身就是一个目录项，因此一个文件至少有一个硬链接。删除硬链接时，对应 inode 的硬链接数量减一，只有当 inode 的硬链接数量为 0 时，文件才会被删除。硬链接是不能跨分区（或者跨文件系统）的，因为每个分区都有自己独立的 inode。

## 软连接

软链接也叫符号链接（symbolic link or symlink），它是一种特殊类型的文件。符号链接的文件内容实际上是另外一个文件（目标文件）的路径。操作系统会把对符号链接的读写操作重定向到目标文件上。由于符号链接指向的是文件路径而不是 inode，所以符号链接是可以跨分区的。删除符号链接并不会对目标文件造成任何影响。但是，如果目标文件被删除或者重命名了，符号链接就成为了死链接。

用一张图来说明硬链接与符号链接的区别：

![硬链接与软链接](/images/linux/links.png) 

## 实践

创建链接的命令是 `ln targetfile linkname`，命令默认创建的是硬链接，若要创建符号链接，需要加上 `-s` 参数，即 `ln -s targetfile linkname`。此外，我们可以通过 `ls -l` 查看文件硬链接的个数，通过 `ls -i` 查看文件所对应的 inode 号。

先用 `mkdir links` 创建一个测试目录，`cd links` 切换工作目录，再创建一个测试文件 `echo "hello" > hello.txt`。现在用 `ls -li` 检查一下：

```sh
ubuntu@XPS9380:~/links$ ls -li
total 4
3095 -rw-r--r-- 1 ubuntu ubuntu 6 Jul 27 14:25 hello.txt
```

可以看到，`hello.txt` 的硬链接个数为 1。现在创建一个硬链接：

```sh
ubuntu@XPS9380:~/links$ ln hello.txt hlink
ubuntu@XPS9380:~/links$ ls -li
total 8
3095 -rw-r--r-- 2 ubuntu ubuntu 6 Jul 27 14:25 hello.txt
3095 -rw-r--r-- 2 ubuntu ubuntu 6 Jul 27 14:25 hlink
```

可以看到，`hello.txt` 与 `hlink` 对应的 inode 号都是 `3095`。此外，`hlink` 的文件类型是 `-`，说明硬链接就是一个普通文件。

再来检查一下文件内容：

```sh
ubuntu@XPS9380:~/links$ cat hello.txt
hello
ubuntu@XPS9380:~/links$ cat hlink
hello
```

两个文件的内容是一样的。

现在来创建一个符号链接：

```sh
ubuntu@XPS9380:~/links$ ln -s hello.txt slink
ubuntu@XPS9380:~/links$ ls -li
total 8
3095 -rw-r--r-- 2 ubuntu ubuntu 6 Jul 27 14:25 hello.txt
3095 -rw-r--r-- 2 ubuntu ubuntu 6 Jul 27 14:25 hlink
3633 lrwxrwxrwx 1 ubuntu ubuntu 9 Jul 27 14:38 slink -> hello.txt
ubuntu@XPS9380:~/links$ cat slink
hello
```

从执行结果可以看出，`slink` 的文件类型是 `l`（符号链接）。虽然 `cat` 命令的输出内容与 `hello.txt` 相同，但 `slink` 有着不同的 inode 号，文件大小也不同。

现在来试一下删除操作，我们先删除 `hello.txt`，然后分别查看 `slink` 与 `hlink` 的内容：

```sh
ubuntu@XPS9380:~/links$ rm hello.txt ; ls -li
total 4
3095 -rw-r--r-- 1 ubuntu ubuntu 6 Jul 27 14:25 hlink
3633 lrwxrwxrwx 1 ubuntu ubuntu 9 Jul 27 14:38 slink -> hello.txt
ubuntu@XPS9380:~/links$ cat slink
cat: slink: No such file or directory
ubuntu@XPS9380:~/links$ cat hlink
hello
ubuntu@XPS9380:~/links$
```

可以发现，通过 `slink` 不能再访问到文件内容了，而通过 `hlink` 就可以。

## 参考资料

1. [Hard link](https://en.wikipedia.org/wiki/Hard_link).
2. [Symbolic link](https://en.wikipedia.org/wiki/Symbolic_link).
2. [Manipulating files](https://tldp.org/LDP/intro-linux/html/sect_03_03.html).
3. [The difference between hard and soft links](https://linuxgazette.net/105/pitcher.html).