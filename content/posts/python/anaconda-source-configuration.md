---
title: "配置Anaconda源"
date: 2018-07-07T09:38:08+08:00
draft: false
authors: ["zhannicholas"]
toc: true
categories:
  - 新手上路
tags:
  - Python
---

> [**`Anaconda`**](https://www.anaconda.com/download/) 是一个 **`python`** 的发行版，可以用来管理 **`python`** 的包和环境，同时它包含1000+的开源package。正如那句话一样：\\
_The Most Trusted Distribution for Data Science_\\
还有一个没有包含那么多包的 **`python`** 发行版，叫做[**`Miniconda`**](https://conda.io/miniconda.html)。

# 是用Anaconda Navigator还是conda

**`Navigator`** 和 **`conda`** 都是可以用来管理包和环境。在安装完 **`Anaconda`** 之后，它们就都已经存在于系统之中了。区别是：

* **`Navigator`** 是图形界面
* **`conda`** 是命令行界面

可以同时使用它们来进行管理。

# 还是习惯使用conda

这里有一份[conda cheat sheet](http://conda.pydata.org/docs/_downloads/conda-cheatsheet.pdf)。花点时间看看，就能开始使用 **`conda`** 了。

**`.condarc`** 是 **`conda`** 的配置文件，它是可选的。当我们第一次运行 **`conda config`** 命令的时候, 这个文件就会被创建，通常位于：```C:\user\username\.condarc```。可以通过直接修改它来配置 **`conda`** ，因为 **`conda config`** 命令的结果最终会写到 **`.condarc`** 中。

## 配置源(channels)

**`Anaconda`** 默认的源位于国外，在国内访问的速度不够快。可以采用国内的镜像来加快访问速度。我一般使用的是清华的源，运行以下命令：

```powershell
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/
conda config --set show_channel_urls yes
```

通过命令：

```powershell
conda info
```

可以查看当前的配置信息。如果添加成功，你会看到刚才所添加的链接。不过也可以直接查看 **`.condarc`** 这个文件，文件的内容目前大致是这个样子：

```file
channels:
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/menpo/
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/bioconda/
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/msys2/
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge/
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/
  - defaults
ssl_verify: true
show_channel_urls: true
```

其中有一个字段是 **`defaults`**, 这使得所有默认的源都包含在当前的源里面，当然也可以删除它。\\
我们也可以改变默认的源，修改**`defalut_channels`** 即可。

## 让conda自动更新(auto_update_conda)

**`conda`** 默认是自动更新的，每当用户在root环境更新或安装包的时候，就会触发。可以采用命令：

```cmd
conda config --set auto_update_conda false
```

来关闭自动更新。这时候 **`conda`** 就只会在用户运行手动更新的命令 **`conda update`** 的时候及进行更新了。

## Alway yes(always_yes)

每当我们执行安装包的命令的时候， **`conda`** 都会问我们```Proceed ([y]/n)?```。如果不想每次都回答这个问题，可以这么设置 **`always_yes`** :

```cmd
conda config --set always_yes true
```


目前我用到的配置部分大致就是这些。[这里](https://conda.io/docs/user-guide/configuration/use-condarc.html)有一份关于使用 **`.condarc`** 的完整说明。
