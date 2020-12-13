---
title: "Linux添加用户并授予root权限的简单方法"
date: 2019-02-13T16:29:45+08:00
draft: false
authors: ["zhannicholas"]
tags:
  - Linux
---

# 快速方法

**使用`root`操作**

## Step 1: 添加一个用户

```bash
adduser username
```

## Step 2: 授予root权限

```bash
usermod -aG sudo username
```

# 但是......

**有些时候，这并不管用**

在`vultr`新租的Debian VPS上，我想添加`sarkar`这个用户，并授予它`root`权限。依然执行了上面的命令，但可怜的`sarkar`还是一个普通用户。解决方案如下：

## Step1: 安装sudo

```bash
# apt-get install sudo
```

## Step2: 修改/etc/sudoers

```bash
# cd /etc
# chmod +w sudoers
# vim sudoers
```

找到下面内容：

```txt
# User privilege specification
root	ALL=(ALL:ALL) ALL
```

在后面添加一行，声明`sarkar`的权限：

```txt
# User privilege specification
root	ALL=(ALL:ALL) ALL
sarkar    ALL=(ALL:ALL) ALL
```



保存并退出。然后：

```bash
# chmod -w sudoers
```

使`/etc/sudoers`再次成为不可写的状态。

现在，`sarkar`就具有`root`权限了。