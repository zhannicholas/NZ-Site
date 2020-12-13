---
title: "用hugo和github pages搭建个人博客"
date: 2018-05-15T16:28:59+08:00
draft: false
toc: true
author: ["zhannicholas"]
tags: 
  - Hugo
categories:
  - 环境搭建
---

> 本文主要是想记录一下自己在win10下使用hugo和github pages搭建博客的过程，备忘。
为什么我要用hugo而不用hexo呢,最主要是因为hugo构建网站的速度非常快，直接秒好。  

# 环境要求

1. Go语言
2. Git
3. hugo

# 搭建环境

## Go语言

1. [下载](https://golang.org/dl/)
2. [如何安装](https://golang.org/doc/install/)
3. 添加环境变量
4. 验证安装

 win+R打开命令行窗口，输入：

 ```sh
 go version
 ```

 如果输出当前安装的go语言的版本号，即安装成功。

## Git

1. [how to install](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
2. [Git中文教程](https://git-scm.com/book/zh/v2)

## hugo

1. [如何安装](https://gohugo.io/getting-started/installing/)
2. 添加hugo环境变量
3. 验证安装

  ```sh
  hugo version
  ```

现在我们需要的环境都创建好了，接下来就可以在建立自己的网站了。

# 创建网站

首先在本地建立一个存放自己网站的文件夹，然后通过命令行进入刚才创建的文件夹，继续操作。

## 建立新网站mysite

```sh
# mysite是将要创建的网站名
hugo new site mysite
```

## 添加theme

```sh
# 进入mysite
cd mysite
```

> 默认情况下hugo生成的网站是没有任何theme的，所有我们需要自己去下载theme。
如果网速好的话，我们可以一次性下载所有的themes到themes文件夹下：

```sh
git clone --depth 1 --recursive https://github.com/gohugoio/hugoThemes.git themes
```

也可以只下载一个theme

```sh
cd themes # 没有的话就创建一个
```

使用```git clone```命令下载单个主题，用法如下：

    git clone URL_TO_THEME # URL_TO_THEME是theme的地址
比如我要下载hyde这个theme:

```sh
git clone https://github.com/spf13/hyde
```

## 添加内容并发布网站

在网站的根目录下执行：

```sh
hugo new posts/my-first-article.md
```

这样我们就成功的建立了my-first-article这篇文章，它位于网站根目录下的posts文件夹里。随便写你想写的内容，然后启动hugo服务器，下面```-D```表示当前内容为草稿，```-t hyde```表示采用hyde作为网站的theme：

```sh
hugo setver -D -t hyde
```

现在在浏览器输入：<http://localhost:1313/>。然后你就能看到你刚才写的网站了。现在你可以继续修改my-first-article的内容，浏览器会实时更新的的改动，不过这可能并不会被你发觉，因为hugo的速度实在是太快了，哈哈哈。

## 正式发布--托管到github

本地网站建好了，不过现在只有你自己能够看到。如果你想让别人也看到你的网站的话，我猜你肯定不想用自己的电脑做服务器吧。这个时候你可以利用github pages来都达到你的目的。

- 如果你没有github账号的话，那么首先注册[github](https://github.com)。千万别忘了你的用户名，后面会用上。假设我的用户名是sarkar。
- [登录github](https://github.com/login), 建立两个repository。一个是工程仓库（假定为mysite), 用来存放hugo内容和其他的资源文件。另一个就是```sarkar.github.io```, 这就是用来放你的网站内容的地方了(记得把这里的和以后的```sarkar```都换成你自己的github用户名)。
- 回到网站的根目录下，也就是mysite目录，在这之前打开你准备发布的```.md```文件，将```draft: true```改为```draft: false```。这样就可以正式的发布内容了，不再是草稿。然后执行命令：

```sh
hugo -t hyde --baseUrl="https://sarkar.github.io"
```

记得把username换成你自己的github用户名。
>命令会在网站网站的根目录下生成一个public文件夹，里面包含了hugo生成的所有静态页面。接下来要做的就是把这下静态页面给push到github上去。>

首先需要进到pulib目录, 然后执行以下命令：

```sh
cd public # 进入public目录
git init
git remote add origin https://github.com/sarkar/sarkar.github.io.git
git add -A
git commit -m "first commit"
git push -u origin master
```

不出意外的话，应该会弹出一个github的登陆窗口或者类似的东西。然后静待本地文件全部push完成。到浏览器输入sarkar.github.io应该就能访问到了刚才建立的网站了。

