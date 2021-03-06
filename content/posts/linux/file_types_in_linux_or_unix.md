---
date: "2021-07-22T09:20:30+08:00"
title: "Linux/Unix 中的文件类型"
authors: ["zhannicholas"]
categories:
  - Linux
tags:
  - Linux
draft: true
toc: true
---

在 Windows 中，文件类型是根据扩展名来确定的。例如：`a.pdf` 是一个 `pdf` 文件，而 `b.txt` 是一个 `txt` 文件。但在 Linux/Unix 中，文件类型与文件扩展名没有关系，它们是两个完全不同的概念。Linux/Unix 将一切都看作是文件，了解文件类型有助于我们对它们进行高效的管理。

[POSIX](https://en.wikipedia.org/wiki/POSIX) 中定义了七种标准的文件类型：

1. 普通文件（regular file）
2. 目录（directory）
3. 符号链接（symbolic link）
4. 管道（FIFO or named pipe）
5. 套接字（socket）
6. 字符设备（character special file）
7. 块设备（block special file）

此外，部分 Linux/Unix 操作系统发行版中可能还有 POSIX 规定以外的文件类型，比如 Solaris 中的 [door](https://en.wikipedia.org/wiki/Doors_(computing)) 类型。

在 Linux/Unix 文件系统中，文件的元数据存储在一个被称为 [inode](https://en.wikipedia.org/wiki/Inode) 的数据结构中，每个文件都有一个对应的 inode。我们可以使用 `stat` 命令来查看某个文件的 inode 信息。若只需要查看文件类型，`stat`输出内容未免太多了点，这个时候我们可以使用 `file` 命令或者 `ll`(或 `ls -l`) 命令。`file` 命令会直接展示文件类型，而 `ll` 命令的文件类型隐藏在输出的第一个字母中，以下面输出为例：

```txt
drwxr-xr-x 4 ubuntu ubuntu 4096 Feb 24 23:28 test
```

`ls -l` 命令中的参数 `l` 表示 “use a long listing format”，该输出的内容从左到右分别是：文件类型（d）、权限（rwxr-xr-x）、硬链接个数（4）、所有者（ubuntu）、所属组（ubuntu）、文件大小（4096）、上次修改时间（Feb 24 23:28）和文件名（test）。其中权限又分为三部分，从左到右分别是所有者权限（rwr）、所属组权限（r-x）和其他人权限（r-x）。我们这里主要关心的是文件类型，即输出中的第一个字母。[ls](https://www.gnu.org/software/coreutils/manual/html_node/What-information-is-listed.html#What-information-is-listed) 的文档给出了 13 个字母，用来标识不同的文件类型：

| character | file type                                 |
| --------- | ----------------------------------------- |
| -         | regular file                              |
| b         | block special file                        |
| c         | character special file                    |
| C         | high performance (“contiguous data”) file |
| d         | directory                                 |
| D         | door (Solaris 2.5 and up)                 |
| l         | symbolic link                             |
| M         | off-line (“migrated”) file (Cray DMF)     |
| n         | network special file (HP-UX)              |
| p         | FIFO (named pipe)                         |
| P         | port (Solaris 10 and up)                  |
| s         | socket                                    |
| ?         | some other file type                      |

`ls` 命令中还有一个有趣的参数是 `-F`，它的作用是“Append a character to each file name indicating the file type”。同样，[ls](https://www.gnu.org/software/coreutils/manual/html_node/General-output-formatting.html#General-output-formatting) 的文档也给出了不同字母的含义。可能是为了方便显示和区分，`-F` 输出的内容中用的是符号：

| 字母 | 文件类型   |
| ---- | ---------- |
| *    | 可执行文件 |
| /    | 目录       |
| @    | 符号链接   |
| \|   | 管道       |
| =    | 套接字     |
| >    | door      |

没有在文件名末尾追加符号的就是普通文件。

## 普通文件

普通文件也是 Linux/Unix 中最多的一类文件，包括文本文件、二进制文件、图片、视频、压缩文件等。

## 目录

目录内可以包含普通文件、目录和各种特殊文件。

## 符号链接

符号链接指向计算机上的另一个普通文件或目录。链接文件分为硬链接（hard link）和软链接（soft link）两种，有点类似于 Windows 中的快捷方式。

## 管道

管道具备 FIFO 的特性，在 Linux/Unix 中常用于进程间通信。

## 套接字

套接字文件可用于进程间信息的传递。在进程间通信方面，他和管道有一些相似之处，但管道是单向的，而套接字是双向全双工的。

## 字符设备

字符设备提供串行输入流或者接收串行输出流，不具备随机访问的能力。

## 块设备

块设备具备随机访问的能力，`/dev/` 目录下的大多数文件都是块设备。

## 参考资料

1. [Unix file types](https://en.wikipedia.org/wiki/Unix_file_types).