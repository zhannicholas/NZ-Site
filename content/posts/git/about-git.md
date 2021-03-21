---
title: "Git初探"
date: 2018-05-30T15:56:02+08:00
draft: false
toc: true
categories:
  - Tools
tags:
  - Git
authors: ["zhannicholas"]
---

# 开始

## 文件的三种状态

* 已提交(committed)
 数据已经安全的保存在了本地的数据库中
* 已修改(modified)
 修改了文件，但还没保存到数据库中
* 已暂存(staged)
 对一个已修改的文件的当前版本做了标记，使之包含在下次的提交快照中。

## 项目的三个工作区域

* Git仓库目录
 保存项目的元数据和对象数据库
* 工作目录
 对项目的某个版本独立提取出来的内容
* 暂存区域
 保存下次将要提交的文件列表信息，是一个文件

## 基本的Git工作流程

1. 在工作目录中修改文件
2. 暂存文件，将文件的快照放入暂存区域
3. 提交更新，将暂存区域中的文件的快照永久保存到Git仓库目录

## 初次运行前

* 设置用户名与邮箱地址
 **`--global`** 表示使用 **`global config file`** , 用于所有配置。如果是对于需要使用不同用户名和邮箱的特定项目就不需要这个选项。

```git
$ git config --global user.name username
$ git config --global user.email example@xxx.com
```

* 设置文本编辑器

``` git
$ git config --global core.editor code
```

* 查看配置信息

```git
$ git config --list
```

* 获取帮助

有三种方式可以获取帮助，windows中默认支支持前两种

```git
$ git help <verb>
$ git <verb> --help
$ man git-<verb>
```

# 基础

## 获取Git仓库

* 在现有目录中初始化Git仓库

```git
$ git init
```

如果不是在一个空文件夹下执行这个命令，那么我们可以多做一点事情：开始跟踪指定文件并提交。使用 **`git add`** 命令来实现对指定文件的跟踪，然后执行 **`git commit`** 提交。 

* 克隆现有仓库

```git
$ git clone [url]
```
这个命令将会克隆Git仓库服务器上几乎所有的数据。

## 记录每次更新到仓库

* 检查文件当前状态

```git
$ git status
```

* 跟踪新文件

```git
$ git add (files)
```
跟踪后的文件会处于暂存状态。可以运行 **`git status`** 命令查看。
如果修改了已跟踪的文件，它的状态会变为已修改，要暂存这次更新，就需要运行 **`git add`** 命令 。注意： **`git add`** 是一个多功能命令，可以理解为“添加内容到下一次提交中”。

* 查看已暂存或未暂存的修改

```git
$ git diff
```

注意：**`git diff`** 只显示尚未暂存的改动，可以加上 **`--cache`** 选项来查看已经暂存的改动。可以使用这个命令来分析文件的差异。

* 提交更新

```git
$ git commit
```

这会启动默认的文本编辑器以便输入本次提交的说明。可以使用 **`-m`** 选项来把提交信息与命令放在同一行。如：

```git
$ git commit -m "add readme.md"
```

* 跳过使用暂存区域
  在提交的时候，给 **`git commit`** 命令加上 **`-a`** 选项，Git就会自动把所有已跟踪过的文件暂存起来一并提交，从而跳过 **`git add`** 步骤。

* 移除文件
  要从Git中移除某个文件，就必须要从已跟踪文件清单中移除（准确来说，是暂存区域），然后提交。使用的命令是 **`git rm`** ,它还会从工作目录中删除指定文件，这样就不会被跟踪了。
  如果想把文件从Git仓库中删除（亦从暂存区域删除），加上 **`--cache`** 选项即可。

* 移动文件
  使用命令 **`git mv`** 即可。它亦可以用来重命名文件：

```git
$ git mv old_file new_file
```

* 查看提交历史

```git
$ git log
```

这默认会按文件提交时间列出所有的更新，并且最新的跟新在最上面。一个常用的选项是 **`-p`** ,用来显示每次提交内容的差异。

* 撤销操作

  重新提交，下面的命令会用第二次提交取代第一次提交的结果：

```git
$ git commit --amend
```

取消暂存的文件：

```git
$ git reset <file>
```

撤销对文件的修改：

```git
$ git checkout --<file>
```

## 远程仓库的使用

* 查看远程仓库

```git
$ git remote
```

* 添加远程仓库

```git
$ git remote add <shortname> <url>
```

这会添加一个远程仓库并指定使用间写 **`shortname`** 来引用它。

* 从远程仓库抓取

```git
$ git fetch [remote-name]
```

* 推送到远程仓库

```git
$ git push [remote-name] [branch-name]
```

* 查看远程仓库

```git
$ git remote show [remote-name]
```

* 重命名远程仓库

```git
$ git remote rename [old-name] [new-name]
```

* 删除远程仓库

```git
$ git remote rm [remote-name]
```