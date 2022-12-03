---
date: "2022-12-02T20:45:02+08:00"
title: "百度地图 Geohash 可视化"
authors: ["zhannicholas"]
categories:
  - Geography
tags:
  - GeoGraphy
  - Geohash
  - 百度地图
draft: false
---

最近在百度地图上做基于位置的推荐服务，需要用到 geohash 和相关的可视化工具。由于不同地图厂商采用的坐标系不同，同一个位置在不同地图上的坐标会出现差异，算出来的 geohash 也会不同。我在网上并没有找到可直接用于百度地图的 geohash 可视化工具，所以就自己造了一个小玩具：[baidumap-geohash-explorer](https://zhannicholas.github.io/baidumap_geohash_explorer.html)。

## 百度地图 geohash 可视化工具

自己造的百度地图 geohash 可视化工具主要参考了 https://www.movable-type.co.uk/scripts/geohash.html 的设计和网页代码，主要功能有：
1. 根据输入的经度、纬度和 geohash 长度，自动计算出 geohash
2. 根据输入的 geohash，自动计算出对应的经度、纬度和 geohash 长度
3. 自动在百度地图上标注出 geohash 所表示的区域
4. 支持对相邻 8 个区域进行标注，方便观察 geohash 的变化规律
5. 单击拾取坐标

![](/images/geography/baidumap-geohash-explorer.png)


整个项目的代码也非常简单，一个网页就搞定了，源码详见 [Github](https://github.com/zhannicholas/baidumap-geohash-explorer)。克隆代码后，替换 AK，双击浏览器打开即可使用。

## 其它 Geohash 可视化工具

* https://geohash.softeng.co/: 仅支持 OpenStreetMap。它很好地展示了 geohash 每多一位，就会将原来的格子划分为 32 个更小的格子的特点。
* https://chrishewett.com/blog/geohash-explorer/：仅支持 OpenStreetMap，能够根据缩放情况自动选择合适级别的 geohash 进行展示。
* https://www.movable-type.co.uk/scripts/geohash.html：仅支持 Google Maps。不仅可以根据经度、纬度和期望的 geohash 长度自动算出对应的 geohash 值并展示，还能根据 geohash 解析出其对应的经度、纬度。
* https://ryan-miao.gitee.io/geohash_tool/：仅支持高德地图，鼠标点击时会自动绘制 geohash 格子。还支持显示相邻的 8 个区域。
* https://bhargavchippada.github.io/mapviz/：支持 Google Maps 和 MapBox，可以同时接收多个 geohash，并将它们显示在地图上。
