---
date: "2021-07-24T21:57:59+08:00"
title: "Linux 目录结构"
authors: ["zhannicholas"]
categories:
  - Linux
tags:
  - Linux
draft: false
toc: true
---

在平常使用 Linux 的过程中，总感觉各个目录的作用存在某种约定，似乎大家都将程序放在 `/bin`、`/sbin`、`/usr/bin` 或 `usr/sbin` 下，将配置文件放到 `/etc` 下，将用户的主目录放到 `/home` 下……深入查阅相关资料后才发现，这背后还隐藏着一个标准——[Filesystem Hierarchy Standard](https://wiki.linuxfoundation.org/lsb/fhs)。本文的主要内容就来自 FHS 3.0。

仔细一想，这么做也很有道理。毕竟 Linux 是开源的，发行版众多，更有很多人在 Linux 的基础上进行定制开发。如果大家都按照自己的想法配置 Linux 系统的文件系统结构，对文件的管理将会是一个令人头疼的问题。为了避免五花八门的目录层级结构，Linux 基金会发布了 FHS（Filesystem Hierarchy Standard），标准主要规范了 Linux 系统中一级目录和部分二级目录的用途，以及各个目录应该存储什么样的数据，大多数 Linux 发行版都遵循这一标准。这样，在与 FHS 相兼容的 Linux 系统上，用户可以很方便地进行文件的管理。

## 区分文件

FHS 采用了两种不同的方式对文件进行区分：

* 可共享（sharable）vs 不可共享（unsharable）
* 可变（variable） vs 不可变（static）

可共享文件指那些可以共享给其它主机使用的文件，不可共享文件则相反。不可变文件包括二进制文件、库文件、文档等，文件的改变通常需要系统的管理员介入，可变文件则相反。

以下是 FHS 给出的一个例子：

|          | sharable                   | unsharable          |
| -------- | -------------------------- | ------------------- |
| static   | /usr, /opt                 | /etc, /boot         |
| variable | /var/mail, /var/spool/news | /var/run, /var/lock |

## 根目录

Linux 将整个文件系统看成一棵树，这棵树的根节点就是根目录，用 `/` 表示。根目录很重要，所有的目录都是由根目录衍生出来的，它还与开机、还原、系统修复等操作有关。

FHS 建议将根目录放在不太大的分区，因为分区越大，可放入的数据就越多，出错的可能性就会增大。FHS 要求根目录下应该有以下目录：

* **/bin**：存放供所有用户使用的完成基本维护任务的命令。这里的 `bin` 是 `binaries` 的缩写，代表二进制文件，通常是可执行的。一些常用的命令，比如 `cat`、`ls`、`cp`、`rm` 等都在这个目录下。FHS 还要求 `/bin` 目录不能有子目录。
* **/boot**：存放启动 Linux 时用到的一些核心文件，比如操作系统内核、引导程序 Grub 等。
* **/dev**：存放所有的设备文件。从此目录可以访问磁盘、内存、CD-ROM 等系统设备。`dev` 表示 `devices`。FHS 还要求 `/dev` 下有以下设备：
  * **/dev/null**：写到这个设备的所有内容都会被丢弃，我们可以通过 `>` 重定向符号将输出流重定向到 `/dev/null` 来忽略输出的结果。
  * **/dev/zero**：这是一个产生数字 0 的设备，写到这个设备的所有内容都会被丢弃。无论你对它进行多少次读取，都会读到 0。
  * **/dev/tty**：表示当前进程的控制终端（如果有的话）。所以，当我们执行 `echo "hello" > /dev/tty` 时，`hello` 就会出现在屏幕上。`tty` 是 `Teletype` 的缩写。
* **/etc**：存放配置文件。
* **/home**：用户的主目录，存放用户的个人文件。除 root 用户外，每个用户的主目录均在 `/home` 下以用户自己的名字命名。
* **/lib**：存放启用系统或运行 `/bin` 和 `/sbin` 目录中的命令所需的共享库。`/lib`目录可能会有一些变种，比如 `lib32` 存放 32 位程序所需的库文件，而 `lib64` 存放 64 位程序所需的库文件。
* **/media**：挂载可移动设备，一般用于自动挂载 U 盘等媒体。
* **/mnt**：临时用于挂载文件系统的地方，
* **/opt**：多数第三方软件默认会安装到此位置。这里的 `opt` 是 `optional` 的缩写。
* **/root**：root 用户主目录的默认位置。
* **/run**：存放系统启动后与系统的信息数据，包括 PID(process identifier) 文件，PID 文件通常命名为 `<program-name>.pid`。在 boot 进程开始之前，这个目录必须被清空。
* **/sbin**：存放与系统启动、修复、恢复等与系统维护有关的命令，例如 `shutdown`、`reboot`、`fsck`、`ifconfig` 等，需要 root 用户才能执行。`sbin` 表示 `system binaries`。
* **/srv**：存放系统所提供的服务的相关数据，例如 `/srv/www` 可包含 Web 服务器相关的数据。`srv` 表示 `service`。
* **/tmp**：存放临时文件。所有用户都可以在这个目录中创建、编辑文件，但只有文件拥有者才能删除文件。`tmp` 表示 `temporary`。
* **/sys**：存放与设备、驱动和一些与内核有关的信息。
* **/proc**：存放内核与进程的状态信息。例如 `/proc/cpuinfo` 含有与 CPU 相关的信息。

## /usr 目录

`/usr` 是一个庞大的文件夹，其下的目录结构与根目录相似。根目录中的文件多是系统级的文件，而 `/usr` 中是用户级的文件，一般与具体的系统无关。`/usr` 目录存放的是 **可共享**、**只读** 的数据。这意味着 `/usr` 中的文件可以在与 FHS 兼容的主机之间共享，且不可以被修改。

在早期的 Unix/Linux 系统中，`/usr` 被用作用户的主目录（类似于现在的 `/home` 目录），`usr` 表示 `user`。而在现在的 Unix/Linux 系统中，`/usr` 存放的是用户级的程序和数据，`usr` 表示 `User System Resources`。不过在网上，有人说 `usr` 是 `Unix Software Resources` 的缩写，还有人说是 `Unix System Resources` 的缩写……笔者在这里给出上面内容的参考来源——[Linux Filesystem Hierarchy：/usr](https://tldp.org/LDP/Linux-Filesystem-Hierarchy/html/usr.html)，大家可以自行判断。当然，名字的来源不知重点🤭

`/usr` 的子目录一般有：

* **/usr/bin**：绝大部分用户可使用的命令都放在这里，这些命令通常与系统的维护无关。
* **/usr/include**：主要放置 C/C++ 程序的头文件。
* **/usr/lib**：存放供应用程序使用的库文件。
* **/usr/local**：系统管理员在本机安装的软件一般都在这下面，其目录结构与 `/usr` 目录类似。
* **/usr/sbin**：存放不是 `/sbin` 中一定要有的系统管理命令。
* **/usr/share**：存放于系统硬件架构无关的数据。比如 `/usr/share/man` 存放有在线手册、`/usr/share/xml` 存放 XML 数据。
* **/usr/src**：存放源代码文件。

## /var 目录

`/var` 目录存放着可变的数据文件，比如运行日志、临时文件等。`var` 表示 `variable`。

`/var` 的子目录主要有：

* **/var/cache**：存放应用的缓存数据。
* **/var/crash**：存放系统崩溃后的转储文件（dump）。
* **/var/lib**：存放应用程序运行时需要的状态信息。
* **/var/lock**：存放锁文件。某些设备或资源一次只能被一个应用程序使用，如果资源同时被两个或多个程序使用，就可能产生一些错误，因此需要上锁。
* **/var/log**：存放日志数据。
* **/var/opt**：存放安装在 `/opt` 目录中的程序用到的可变数据。
* **/var/run**：存放正在执行的程序的信息，例如 PID 文件。
* **/var/tmp**：存放系统重启之间保存的临时文件。


## 参考资料

1. [FHS 3 Specification Series](https://refspecs.linuxfoundation.org/fhs.shtml).
2. [Linux Filesystem Hierarchy：/usr](https://tldp.org/LDP/Linux-Filesystem-Hierarchy/html/usr.html).
3. [Filesystem Hierarchy Standard](https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard).
4. [ Terminal Special Files such as /dev/tty](https://tldp.org/HOWTO/Text-Terminal-HOWTO-7.html).
