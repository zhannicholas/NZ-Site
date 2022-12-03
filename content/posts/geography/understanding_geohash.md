---
date: "2022-11-27T20:21:07+08:00"
title: "理解 Geohash"
authors: ["zhannicholas"]
categories:
  - 地理
tags:
  - Geography
  - Geohash
draft: false
toc: true
---

[Geohash](https://en.wikipedia.org/wiki/Geohash) 是 Gustavo Niemeyer 在 2008 年发明的一个地理编码系统（geocode system），它将经度和纬度这个二维的地理坐标编码成一个由数字和字母组成的字符串。虽然 geohash 是从经纬度计算出来的，但是 geohash 并不能像经纬度那样能够表示出某个点在地图上的确切位置。实际上，Geohash 表示的是一个**区域**，这个区域内所有的点都有着相同的 geohash 值。这意味着，geohash 可以帮助用户隐藏确切的位置信息，从而更好地保护用户的隐私。虽然我们可以通过 geohash 得知用户所在的区域，但是我们却无法知道用户到底在这个区域中的哪个点。

很多基于位置的个性化服务都是基于 geohash 实现的。比如查找附近的人，寻找附近的餐厅等等。以查找附近的人为例，如果两个人所处位置的 geohash 相同，那么我们可以认为这两个人在空间上是相近的。至于具体有多近，这取决于 geohash 所表示的位置精度。通过改变 geohash 的长度，我们可以表示任意精度的位置：geohash 越短，其表示的区域越大，位置精度越低；相反，geohash 越长，其表示的区域越小，位置精度越高。

以天府广场（latitude: 30.6599157, longitude: 104.0638546）为例，下图展示了通过不断增加 geohash 长度提高展示位置精度的过程：
![](/images/geography/geohash_precise.png)
* 当 geohash 长度为 1 时，选择 `w`
* 当 geohash 长度为 2 时，选择 `wm`
* 当 geohash 长度为 3 时，选择 `wm6`
* 当 geohash 长度为 4 时，选择 `wm6n`
* 当 geohash 长度为 5 时，选择 `wm6nj`
* 当 geohash 长度为 6 时，选择 `wm6nj2`

> 需要注意的是，同一个地点在不同地图下的经纬度可能是不一样的。本文采用的是 [OpenStreeMap](https://www.openstreetmap.org/)。

## 经度与纬度

经纬度是由地球表面经线和纬线相交组成的一个坐标系统。每根经线和纬线都有不同的度数，叫经度和纬度。

![https://commons.wikimedia.org/wiki/File:Latitude_and_Longitude_of_the_Earth.svg](/images/geography/1024px-Latitude_and_Longitude_of_the_Earth.svg.png)

地球是一个球体，经线连接南北两极，是半圆弧状。经过英国首都伦敦格林尼治天文台原址的那一条经线被定为 0° 经线，又叫本初子午线。本初子午线往东为东半球，往西为西半球。东西两个半球的经度范围均在 0° 至 180° 之间，合计360度。一般将西半球的经度范围记为  `[-180°, 0°)`，而将东半球的为 `(0°, 180°]`。

纬线与经线垂直的圆圈，任意两根纬线互相平行。赤道（实际上是地球表面的点随着地球自转产生的轨迹中最长的圆周线）是最大的纬线圈，纬度为 0°。赤道将地球分为南北两个半球，南北两个半球的纬度范围都是 90°，合计 180°。从赤道出发，向两极靠近，纬度越来越大，纬线圈越来越小。一般将南半球的纬度范围记为 `[-90°, 0°)`，而将北半球的纬度记为 `(0°, 90°]`。
南极点的纬度记为 90°S（或 -90°），北极点的纬度记为 90°N（或 +90°）。


## 算法原理

Geohash 是一种将二维的经纬度编码成一个字符串的地理编码方法，核心思想是区间二分：将地球编码看成一个二维平面，然后将这个平面递归均分为更小的子块。

当我们对一个地理坐标进行 geohash 编码时，先分别计算出经度和纬度各自的二进制编码，然后按照“从第 0 位开始，偶数位放经度，奇数位放纬度”的规则将经度和纬度的编码交叉组合，得到一个完整的二进制编码。接着，将二进制编码按照五个一组进行划分，算出每一组二进制编码的十进制值并将其作为索引查找 base32 编码表中对应的值。最后将这些值拼接在一起就得到了 geohash 值。

不难看出，geohash 越长，对地图的划分次数就越多。划分的次数多了，矩形区域就小了，位置精度也就上去了。那么是不是 geohash 越长越好呢？当然不是，我们应该根据实际的应用场景来选择合适的长度。如果使用内存存储 geohash，geohash 越长，其所占的空间就越大。为了保护用户的位置隐私，也需要将位置精度控制在合理的范围内。

接下来还是以成都市天府广场的位置为例，来看看 geohash 具体是如何计算的。

### 计算出经度和纬度各自对应的二进制编码

计算经度或纬度的二进制编码的方法如下：
1. 确定初始区间，经度为 `[-180°, +180°]`，纬度为 `[-90°, +90°]`。
2. 将初始区间对半拆分得到左半区间和右半区间，根据目标位置的经度或纬度是落在左区间还是右区间，决定当前位的二进制编码。左区间取 0，右区间取 1。
3. 对上一步中目标位置所在的子区间进行对半划分，按照同样的方式计算出下一位的二进制编码。
4. 重复划分上面的步骤，直到达到期望的编码长度。

首先对纬度进行二进制编码：
1. 将 `[-90°, 90°]` 对半拆分得到 `[-90°, 0°]` 和 `[0°, 90°]`，30.6599157 位于右区间，取 1 。
2. 将 `[0°, 90°]` 对半拆分得到 `[0°, 45°]` 和 `[45°, 90°]`，30.6599157 位于左区间，取 0 。
3. ……

按照这个流程，计算天府广场纬度 30.6599157 的 15 位二进制编码的过程：
```txt
迭代    左端点          区间中点         右端点           0/1
1       -90.000000      0.000000        90.000000        1
2       0.000000        45.000000       90.000000        0
3       0.000000        22.500000       45.000000        1
4       22.500000       33.750000       45.000000        0
5       22.500000       28.125000       33.750000        1
6       28.125000       30.937500       33.750000        0
7       28.125000       29.531250       30.937500        1
8       29.531250       30.234375       30.937500        1
9       30.234375       30.585938       30.937500        1
10      30.585938       30.761719       30.937500        0
11      30.585938       30.673828       30.761719        0
12      30.585938       30.629883       30.673828        1
13      30.629883       30.651855       30.673828        1
13      30.629883       30.651855       30.673828        1
14      30.651855       30.662842       30.673828        0
15      30.651855       30.657349       30.662842        1
```
通过以上计算，纬度 30.6599157 的二进制编码为：`10101 01110 01101`。

同理，我们也可以计算出经度 104.0638546 的 15 位二进制编码：
```txt
迭代    左端点           区间中点        右端点           0/1
1       -180.000000     0.000000        180.000000       1
2       0.000000        90.000000       180.000000       1
3       90.000000       135.000000      180.000000       0
4       90.000000       112.500000      135.000000       0
5       90.000000       101.250000      112.500000       1
6       101.250000      106.875000      112.500000       0
7       101.250000      104.062500      106.875000       1
8       104.062500      105.468750      106.875000       0
9       104.062500      104.765625      105.468750       0
10      104.062500      104.414062      104.765625       0
11      104.062500      104.238281      104.414062       0
12      104.062500      104.150391      104.238281       0
13      104.062500      104.106445      104.150391       0
14      104.062500      104.084473      104.106445       0
15      104.062500      104.073486      104.084473       0
```
经度 104.0638546 的二进制编码为 `11001 01000 00000`。

### 交叉合并经度和纬度的二进制编码

从第 0 位开始，**偶数位放经度，奇数位放纬度**，得到完整的二进制编码：

![](/images/geography/encode_longitude_and_latitude_to_binary.png)

### 将二进制编码分组并计算出对应的 Base32 编码

上面的二进制编码看起来很长，不方便记忆。为了压缩编码长度，geohash 采用了自己的 Base32 编码，将二进制编码转换成方便识别的文本。Geohash 所用的编码表由数字和字母组成，不过去掉了 a，i，l 和 o 四个字母：

![](/images/geography/geohash_base32.png)

有了编码表后，我们将之前组合得到的二进制编码，五个一组，计算出每一组的十进制值，然后查表得到最终的编码 `wm6n2j`：

![](/images/geography/binary_to_geohash.png)

## Geohash 解码

Geohash 的解码实际上编码的逆过程，先通过 Base32 编码表找出每个字符的十进制值，然后将十进制转为二进制，最后通过二进制计算出对应的区域范围。

前面我们计算出天府广场的 geohash 是 `wm6n2j`，现在将其还原为经纬度：

![](/images/geography/geohash_decode.png)

最后一步将二进制还原为十进制，从左往右遍历二进制编码，将当前区间对半划分，若为 0，取左区间为下一步划分用的区间，为 1 则将右区间作为下一步划分用的区间。经度的初始区间为 `[-180°, +180°]`，纬度的初始区间为 `[-90°, +90°]`。

将二进制编码的纬度 `10101 01110 01101` 还原，得到它表示的纬度范围是 `(30.657349, 30.662842)`：
```txt
0/1    最小值           最大值           
1      0.000000        90.000000       
0      0.000000        45.000000       
1      22.500000       45.000000       
0      22.500000       33.750000       
1      28.125000       33.750000       
0      28.125000       30.937500       
1      29.531250       30.937500       
1      30.234375       30.937500       
1      30.585938       30.937500       
0      30.585938       30.761719       
0      30.585938       30.673828       
1      30.629883       30.673828       
1      30.651855       30.673828       
0      30.651855       30.662842       
1      30.657349       30.662842 
```

将二进制编码的经度 `11001 01000 00000` 还原，得到它表示的经度范围是 `(104.062500, 104.073486)`：
```txt
0/1    最小值           最大值           
1      0.000000        180.000000      
1      90.000000       180.000000      
0      90.000000       135.000000      
0      90.000000       112.500000      
1      101.250000      112.500000      
0      101.250000      106.875000      
1      104.062500      106.875000      
0      104.062500      105.468750      
0      104.062500      104.765625      
0      104.062500      104.414062      
0      104.062500      104.238281      
0      104.062500      104.150391      
0      104.062500      104.106445      
0      104.062500      104.084473      
0      104.062500      104.073486
```

最终，我们得出 `wm6n2j` 表示的是经度在 `(104.062500, 104.073486)` 之间，纬度在 `(30.657349, 30.662842)` 之间的一个矩形区域。

对比天府广场（latitude: 30.6599157, longitude: 104.0638546），它恰好在计算出来的范围之内。这个例子很好地说明了 geohash 是如何表示一个区域范围的。

## Geohash 的长度与位置精度

Geohash 的长度对位置的精度有着非常直接的影响。从下面这个表格可以看出，当编码长度为 1 时，精度高达 2500km，而当编码长度为 8 时，精度降到了 19m。
| Geohash 长度 | 纬度位数 | 经度位数 | 纬度误差 | 精度误差 | 距离误差 |
|-------------|----------|---------|----------|---------|--------|
| 1 | 2 | 3 | ±23 | ±23 |±2,500 km |
| 2 | 5 | 5 |  ±2.8 |  ±5.6 |±630 km |
| 3 | 7 | 8 |  ±0.70 |  ±0.70 | ±78 km |
| 4 | 10 | 10 |  ±0.087 |  ±0.18 | ±20 km |
| 5 | 12 | 13 |  ±0.022 |  ±0.022 | ±2.4 km |
| 6 | 15 | 15 |  ±0.0027 |  ±0.0055 | ±0.61 km |
| 7 | 17 | 18 |  ±0.00068 |  ±0.00068 | ±0.076 km |
| 8 | 20 | 20 |  ±0.000085 |  ±0.00017 | ±0.019 km |


## Geohash 的局限性

Geohash 非常好用，但它还是存在两个问题：边界问题和非线性问题。

### 边界问题

Geohash 将邻近搜索（proximity search）转换为了字符串前缀匹配，和基于经纬度的算法相比，极大地提高了计算效率。由于 geohash 是将地图划分为矩形网格，并单独对每个矩形进行编码，这就会带来以下问题。比如下图中有 A、B、C 三个点，要查找离 B 最近的点。可以发现，距离较远的 A 和 B 有着相同的 geohash 编码，而较近的 C 的 geohash 编码却有所不同。

![](/images/geography/people_nearby.png)

这种问题一般出现在边界上。解决思路很简单，除了使用目标点的 geohash 进行匹配外，还需要检查相邻 8 个格子的 geohash 编码，这样才能选出最符合要求的答案。

### 非线性问题

Geohash 是基于经纬度的，它能反映出两个点在经纬度上面的距离，但是却不能反映出实际距离。在不同的纬度下，单位经度所表示的距离是不一样的。在赤道，单位经度对应的距离为 111.320km，而在 30°N 和 30°S，单位经度对应的距离为 110.852km。

这种非线性问题并不是 geohash 和经纬度系统的问题，而是在于将球体表面的坐标映射到二维平面的坐标的不均匀性。在不同的纬度下，指定长度的 geohash 所表示的矩形区域大小也是不一样的。矩形用南北方向的高度（height）和东西方向的宽度（width）来衡量。例如在赤道：
| Geohash 长度 | 宽（Width）| 高（Height）|
|--------------|-----------|-------------|
| 1 | 4604.5 km | 5003.8 km |
| 2 | 1249.4 km | 625.5 km |
| 3 | 156.4 km | 156.4 km |
| 4 | 39.1 km | 19.5 km |
| 5 | 4.9 km | 4.9 km |
| 6 | 1.2 km | 610.8 m |
| 7 | 152.7 m | 152.7 m |
| 8 | 38.2 m | 19.1 m |
| 9 | 4.8 m | 4.8 m |
| 10 | 1.2 m | 596.5 mm |
| 11 | 149.1 mm | 149.1 mm |
| 12 | 37.3 mm | 18.6 mm |

Blake Haugen 在他的博客 [Geohash Size Variation by Latitude](https://bhaugen.com/blog/geohash-sizes/) 中展示了不同纬度下不同长度的 geohash 所表示的矩形区域的大小。当 geohash 长度相同时，矩形的高度在不同纬度下是相同的，而矩形的宽度在不同纬度下并不相同。这一点从经纬度的划分上很好理解，假设地球是一个完美的球体，经线圈的周长是相同的，而纬线圈的周长在赤道最大，越靠近两极越小并不断趋近于零。


## 参考资料

1. [Wikipedia: Geohash](https://en.wikipedia.org/wiki/Geohash)
2. [Chris Hewett's GeoHash Explorer](https://chrishewett.com/blog/geohash-explorer/)
3. [Geohash Size Variation by Latitude](https://bhaugen.com/blog/geohash-sizes/)
4. [基于快速GeoHash，如何实现海量商品与商圈的高效匹配](https://zhuanlan.zhihu.com/p/39817945)
5. [Notes on Geohashing](https://eugene-eeo.github.io/blog/geohashing.html)
6. [The A-Z of Geohashing: What You Need to Know](https://www.iunera.com/kraken/fabric/geohashing/)
7. [百度地图 geohash 可视化工具](https://ryan-miao.gitee.io/geohash_tool/)