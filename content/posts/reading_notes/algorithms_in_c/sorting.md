---
title: "各种排序算法"
date: 2018-05-30T18:55:31+08:00
draft: false
toc: true
tags:
  - 算法
categories:
  - C算法
authors: ["zhannicholas"]
---

>学习《C算法》中排序这一部分时做的一些笔记。主要使用C++实现了书中的大部分排序算法。

# 开始之前

为了方便增加代码的灵活性，我采取了书中作者的部分方法。主要是用 **`type`** 代替了具体的数据类型，以及定义了两个用于比较的宏。通过改变下面内容， 可以很容易的进行其它数据类型的排序。

```C++
typedef int type;
#define less(A, B) (A < B)
#define equal(A, B) (A == B)
```

下面的 **`exchange()`** 函数用来交换两个元素：

```C++
void exchange(type &a, type &b){type t = a; a = b; b = t;}
```

还有用来测试算法正确性的驱动函数，它通过读取用户输入的数字 **`n`** , 产生 **`n`** 个10000以内的随机数作为测试数据。然后调用相应的排序算法并输出排序结果。

```C++
int main(){
    int n;
    scanf("%d", &n);
    type *a = new type[n];
    for(int i = 0;i < n;i++) a[i] = 10000 * (1.0 * rand() / RAND_MAX);
    //selectSort(a, 0, n - 1);
    //insertSort1(a, 0, n - 1);
    //insertSort2(a, 0, n - 1);
    //bubbleSort(a, 0, n - 1);
    //shakerSort(a, 0, n - 1);
    //shellSort(a, 0, n - 1);
    //countSort(a, 0, n - 1);
    //quickSort(a, 0, n - 1);
    //tri_quickSort(a, 0, n - 1);
    //mergeSort(a, 0, n - 1);
    //mergeTD(a, 0, n - 1);
    //oddEvenSort(a, 0, n - 1);
    //heapSort(a, 0, n - 1);
    //radixSort(a, 0, n - 1);
    for(int i = 0;i < n;i++) printf("%-6d", a[i]);
    printf("\n");
    delete []a;
    system("pause");
    return 0;
}
```

## 选择排序

### 步骤

 1. 首先，找出数组中最小的元素并用首位置的元素和它交换
 2. 然后， 找出数组中次小的元素并用第二个位置的元素和它交换
 3. 重复此步骤，直到整个数组排序完成。

### 具体实现

对于从 **`left`** 到 **`right - 1`** 的每个 **`i`** ,用 **`a[i]`**, **`a[i + 1]`**, ..., **`a[right]`** 中的最小元素进行交换。当索引 **`i`** 从左向右遍历时，其左边的元素所处的位置就是其在数组中的最终位置。
所以，当 **`i`** 到达最右端时，整个数组排序完成。

```C++
void selectSort(type a[], int left, int right){
    for(int i = left;i < right;i++){
        int minp = i;  // 假定未排序序列中的第一个为最小值
        for(int j = i + 1;j <= right;j++)
            if(less(a[j], a[minp])) minp = j;
        exchange(a[i], a[minp]);
    }
}
```

## 插入排序

### 步骤

对于未排序的序列，每次取其中的一个数。然后在已排序的序列中从后向前扫描， 找到合适的位置并插入。

### 说明

和选择排序一样，在排序过程中，当前索引左边的元素已经有序，但这并不是他们的最终位置，如果碰到了比它们更小的元素，它们还必须后移，为较小的元素腾出位置。

```C++
void insertSort1(type a[], int left, int right){
    for(int i = left + 1;i <= right;i++)
        for(int j = i;j > left;j--)
            if(less(a[j], a[j - 1])) exchange(a[j], a[j - 1]);
}
```

### 改进

> 与选择排序不同的时，插入排序的运行时间主要取决于输入中键的初始顺序。
当我们碰到的键不大于正被插入的键时，就可以停止 **`less()`** 和 **`exchange()`** 运算，因为左边的序列时已经排序好的了。特别地，当 **`less(a[j - 1], a[j])`** 为真时，我们可以直接跳出内层循环。
不难发现，**`j > left`** 的测试通常是多余的（只有在插入元素时当前看到的最小元素并且到达了数组的起始处，它才为真）。一种改进方法是：让键在 **`a[left]`** 到 **`a[N]`** 中保持有序，并在 **`a[0]`** 中放入一个标记键，它至少与数组中的最小键相同。然后通过测试是否碰到了最小键来同时测试 **`less(a[j - 1], a[j])`** 和 **`j > left`** 这两个条件，让内循环更小，程序更快。
对同一个元素的连续交换效率不高，如果进行两次或者更多的交换，中间变量 **`t`** 的值并没有改变。在第二次或以后的交换中，先保存再重新载入 **`t`** 的值就是浪费时间。

#### 具体做法

* 将数组中最小值放到第一个位置，作为标记。
* 在内循环中，进行单个赋值，而不是连续交换。
* 当正被插入的元素已经就位时，终止内循环。对于每个 **`i`** ，把大于 **`a[i]`** 的排序表 **`a[left], ..., a[i - 1]`** 的所有元素整体向右移动一个位置，再把 **`a[i]`** 放入适当的位置。这样就完成了整个排序的过程。

```C++
void insertSort2(type a[], int left, int right){
    for(int i = left + 1, minp = left;i <= right;i++){
        if(less(a[i], a[left])) minp = i;
        exchange(a[minp], a[left]);
    }
    for(int i = left + 2;i <= right;i++){
        int j = i;
        type v = a[i];  // 先保存a[i]，确保它不会被右移的元素覆盖
        //把大于a[i]的所有元素整体向右移动一个位置
        for(;less(v, a[j - 1]);j--) a[j] = a[j - 1];
        a[j] = v;  // 放入a[i]到适当的位置
    }
}
```

## 冒泡排序

### 步骤

1. 从左到右比较相邻的两个元素，如果第一个比第二个大，就交换它们
2. 对每一对元素重复第1步，结束时，最大的元素在排序序列的最右端。
3. 对除最后一个以外的所有元素重复以上步骤。
4. 重复直到没有任何一对数字需要比较。

代码如下：

```C++
void bubbleSort(type a[], int left, int right){
    for(int i = left;i <= right;i++){
        for(int j = left;j <= right - i - 1;j++)
            if(less(a[j + 1], a[j])) exchange(a[j + 1], a[j]);
    }
}
```

## 摇摆排序

冒泡排序改良版。将单向扫描数组改成从头到尾，再从尾到头的交替方式

```C++
void shakerSort(type a[], int left, int right){
    for(int i = left;i <= right;i++){
        for(int j = left;j <= right - i - 1;j++)
            if(less(a[j + 1], a[j])) exchange(a[j + 1], a[j]);
        for(int j = right - i - 1;j > i;j--)
            if(less(a[j], a[j - 1])) exchange(a[j], a[j - 1]);
    }
}
```

## 希尔排序

希尔排序又叫缩小增量排序，它是插入排序扩展。
> 插入排序慢， 因为它一次只交换相邻的两个元素（步长为1）。如果最小键位于数组尾部，则将它移动到正确位置需要N步。
为了让元素能够能快的到达正确的位置，改变步长。每隔h取一个元素，可以得到一些h-有序序列。然后改变步长继续操作，最终当步长为1的时候，希尔排序变成插入排序，这就保证了排序能够完成。

如果不使用标记，则在插入排序中，将步长由“1”换成“h”(也就是将每个“1”换成“h”)，得到的程序对序列进行h-排序。增加一个外循环来改变增量h，就可以得到最终程序。程序中选取的增量序列为：1，4，13，40，121，364，1093，3280，9841……

```C++
void shellSort(type a[], int left, int right){
    int h, i, j;
    for(h = 1;h < (right - left) / 3;h = h * 3 + 1);
    for(;h > 0;h /= 3){  // 调整增量
        for(i = left + h;i <= right;i += h){
            j = i;
            type v = a[i]; // 保存a[i]
            for(;j >= left + h && less(v, a[j - h]);j -= h) a[j] = a[j - h]; // 向后移动h个元素
        a[j] = v;  // 把a[i]放到正确位置
        }
    }
}
```

## 键索引计数排序

键索引排序把键当作索引进行排序，而不是把键当作被比较的抽象项。比如：排序一个包含N个项的文件，项的键为0~M-1之间的整数。我们可以用每个值来对键的个数进行计数，然后在第二遍扫描中使用计算出来的数将项移到正确的位置。通俗的讲：加入你们班有30个人，统计出来有5个人的绩点比你高，那么你的绩点就排在第6位。用这个方法可以得到其它人的排名，也就排好了序。对于重复值，需要特殊处理。
不过键索引基数排序局限于待排序数据的范围。

### 步骤

1. 首先，计数每个值的键的数量
2. 然后，小计小于或等于每个值的键数。
3. 接着，使用这些计数作为索引分拣键，比如 **`cnt[i]`** 表示小于 **`i`** 的个数，那个 **`a[i]`** 位于 **`aux[ant[i]]`**
4. 写回原数组

代码如下：

```C++
void countSort(type a[], int left, int right){
    int i, j, M = 10000; // 键必须是小于M的整数
    int N = right - left + 1, cnt[M];
    type *aux = new type[N];
    for(j = 0;j < M;j++) cnt[j] = 0; // 将计数初始化为0
    for(i = left;i <= right;i++) cnt[a[i] + 1]++;  //统计小于a[i]的值的出现频率
    for(j = left;j < M;j++) cnt[j + 1] += cnt[j]; // 得到小于等于计数器对应计数值键的数量,将频率转换为索引
    for(i = left;i <= right;i++) aux[cnt[a[i]]++] = a[i]; // 将键分布到辅助数组中
    for(i = left;i <= right;i++) a[i] = aux[i];  // 回写
    delete []aux;
}
```

## 快速排序

快速排序是一种分治方法。它的工作方式是：将待排序的序列划分为两组，然后独立排序各个部分划分的准确位置取决于输入中元素的初始顺序。
方法的关键在于划分过程，它将数组重排，使下面3个条件成立：

1. 对于某一个 **`i`** 值，元素 **`a[i]`** 处于数组中的最终位置;
2. **`a[i]`** 左边的元素都不大于 **`a[i]`** ;
3. **`a[i]`** 右边的元素都不小于 **`a[i]`** ;

### 划分方法

1. 首先，任意选定 **`a[right]`** 作为划分元素（它将处于在数组中的最终位置）。
2. 从左向右扫描，直到发现一个大于划分元素的元素；同时从右向左扫描，直到发现一个小于划分元素的元素，然后交换这两个元素。
3. 按这种方式继续划分。确保左指针左边的元素都小于划分元素，右指针右边的元素都大于划分元素。
4. 当左右指针相遇或者相互经过时，交换 **`a[right]`** 和右半部分最左边的元素（由左指针指向的元素），划分结束。 

```C++
int partition(type a[], int left, int right){
    int i = left - 1, j = right;
    type v = a[right];  // a[right]为划分元素
    for(;;){
        for(;less(a[++i], v););
        for(;less(v, a[--j]);) if(j == left) break;  // 避免划分元素为序列中的最小元素的情况发生
        if(j <= i) break;
        exchange(a[i], a[j]);
    }
    exchange(a[i], a[right]);  //交换a[right]和a[i]
    return i;  
}
```

如果数组中只有一个元素，不需要进行任何运算。否则，调用 **`partition()`** 函数处理这个数组，它将 **`a[i]`** 放到最终位置 **`(left < i <= right)`** 并且重排其它元素，让递归调用能够正确完成整个排序过程。

```C++
void quickSort(type a[], int left, int right){
    if(right <= left) return;
    int i = partition(a, left, right);
    quickSort(a, left, i - 1);
    quickSort(a, i + 1, right);
}
```

### 改进（三元素中值划分）

三元素中值划分使用一个更有可能在中间位置出现的元素作为划分元素。它从序列中选出三个元素的样本，然后用这三个元素的中值作为划分元素。分别从数组中的左、中、右选取一个元素。接着排序这三个元素，然后用 **`a[right - left]`** 交换中间那一个，再对 **`a[left + 1],...,a[right - 2]`** 运行划分算法。

### 应对大量重复键的情况---三路划分

>当排序序列中的重复键较多的时候，快速排序的低下性能让人难以接受。
可以把序列分为三部分，分别是：小于划分元素的部分、等于划分元素的部分、大于划分元素的部分。
修改标准划分方案如下：将在左边部分碰到的和划分元素相等的键放到序列的左端，将右边部分碰到的和划分元素相等的键放到序列右端。
然后，当指针交叉而且相等键的位置已知的时候，将所有与划分元素相等的键交换到位
![三路划分](/images/algorithms_in_c/三路划分.png)

#### 一点说明

程序将数组划分为三部分：小于划分元素的部分（ **`a[left],..., a[j]`** ）, 等于划分元素的部分（ **`a[j + 1],..., a[i - 1]`** ）,大于划分元素的部分( **`a[i],...,a[right]`** )。示意图如下：

```C++
void tri_quickSort(type a[], int left, int right){
    if(right <= left) return;
    type v = a[right];  // 划分元素
    int i = left, j = right - 1, p = left, q = right - 1;
    for(;;){
        for(;less(a[i], v);i++);
        for(;less(v, a[j]);j--) if(j == left) break;  // 避免划分元素为序列中的最小元素的情况发生
        if(j <= i) break;
        exchange(a[i], a[j]);
        if(equal(a[i], v)){p++;exchange(a[i], a[p]);}
        if(equal(a[j], v)){q--;exchange(a[j], a[q]);}
    }
    exchange(a[i], a[right]);
    i--;j++;
    int k;
    for(k = left;k < p;k++,i--) exchange(a[k], a[i]); 
    for(k = right - 1;k > q;k--, j++) exchange(a[k], a[j]);
    tri_quickSort(a, left, i);
    tri_quickSort(a, j, right);
}
```

## 奇偶排序

### 步骤

1. 选取所有为奇数列（下标为1,3,5...)的元素与其右侧元素比较，将小的放在前面
2. 选取所有为偶数列（下标为2,4,6...)的元素与其右侧元素比较，将小的放在前面
3. 重复1和2直到所有序列有序为止。

### 实现

```C++
void oddEvenSort(type a[], int left, int right){
    int i;
    bool oddSorted = false, evenSorted = false;
    while(!oddSorted || !evenSorted){
        oddSorted = true;
        evenSorted = true;
        for(i = left;i < right;i += 2){
            if(less(a[i + 1], a[i])){
                exchange(a[i + 1], a[i]);
                evenSorted = false;
            }
        }
        for(i = left + 1; i < right;i += 2){
            if(less(a[i + 1], a[i])){
                exchange(a[i + 1], a[i]);
                oddSorted = false;
            }
        }
    }
}
```

## 归并排序

### 归并

数组 **`a`** 的前半部分（ **`a[left],...,a[m]`** ）有序，后半部分（ **`a[m + 1],...,a[right]`** ）有序。归并这两部分，使整个数组有序。一般需要一个辅助数组 **`aux`** ,先把结果存到 **`aux`** 中，然后把排序结果从 **`aux`** 写回到 **`a`** 中。
一种常用的归并方法：

```C++
void merge0(type a[], int left, int m, int right){
    int len = right - left + 1;
    type *aux = new type[len];
    int i = left, j = m + 1, k = 0;
    while(i <= m && j <= right) aux[k++] = less(a[i], a[j]) ? a[i++] : a[j++];
    while(i <= m) aux[k++] = a[i++];
    while(j <= right) aux[k++] = a[j++];
    for(i = left, k = 0;i <= right;i++, k++) a[i] = aux[k];
    delete []aux;
}
```

另一种归并方法：
将前半部分复制到 **`aux`** 中，然后将后半部分（ **`a[m + 1],...,a[right]`** ）逆序复制到 **`aux`** 中,使两个部分最大元素背靠背位于 **`aux`** 中间，形成双调序列。这样，两个部分中的最大元素分别成为一个标记。

```C++
void merge1(type a[], int left, int m, int right){
    int len = right - left + 1;
    type *aux = new type[len];
    int i, j , k = 0;
    for(i = left;i <= m;i++) aux[k++] = a[i];  // 复制前半部分到aux
    for(j = right;j >= m + 1;j--) aux[k++] = a[j];  // 逆序复制后半部分到aux
    i = 0;j = len - 1;
    for(k = left;k <= right;k++){
        if(less(aux[i], aux[j])) a[k] = aux[i++];  // 归并，最大元素为各自的标记
        else a[k] = aux[j--];
    }
    delete []aux;
}
```

### 排序

 将数组分为两部分： **`a[left],..., a[m]`** 和 **`a[m + 1], ..., a[right]`** 。然后对这两个数组进行独立排序（通过递归调用），然后将这两个有序序列归并到最终的序列。

```C++
void mergeSort(type a[], int left, int right){
    int m = (left + right) / 2;
    if(right <= left) return;
    mergeSort(a, left, m);
    mergeSort(a, m + 1, right);
    merge1(a, left, m, right);  // 归并
}
```

### 巴切奇偶归并排序

首先要讲两个函数：
完全混洗(shuffle):将数组 **`a[left],...,a[right]`** 分为两半，前一半进入结果中的偶数编号位置，后一半进入结果中的奇数编号位置。
逆完全混洗(unshuffle):偶数编号位置的元素进入结果的前一半，奇数编号位置的元素进入结果的后一半。
这两个函数仅对带有偶数个元素的子数组使用。

```C++
void shuffle(type a[], int left, int right){
    int i, j, m = (left + right) / 2, len = right - left + 1;
    type *aux = new type[len];
    for(i = left, j = 0;i <= m;i++, j += 2){
        aux[j] = a[i];
        aux[j + 1] = a[m + 1 + i - left];
    }
    for(i = left, j = 0;i <= right;i++, j++) a[i] = aux[j];
    delete []aux;
}

void unshuffle(type a[], int left, int right){
    int i, j, m = (left + right) / 2, len = right - left + 1;
    int ma = len / 2;
    type *aux = new type[len];
    for(i = left, j = 0;i <= right;i += 2, j++){
        aux[j] = a[i];
        aux[ma + j] = a[i + 1];
    }
    for(i = left, j = 0;i <= right;i++, j++) a[i] = aux[j];
    delete []aux;
}
```

#### 巴切的奇偶归并网络

这个网络输入两个已排好序的序列，对这两个序列进行归并排序。首先对这两个序列进行逆混洗，然后分别归并前后部分，接着再混洗，最后进行一次(1,2)、(3,4)...这些相邻元素的比较交换得到排序结果。这里的代码只适合元素个数为 **`2^n`** 的序列。

```C++
void mergeTD(type a[], int left, int right){
    int i, m = (left + right) / 2;
    quickSort(a, left, m); quickSort(a, m + 1, right);
    if(left + 1 == right)
        if(less(a[right], a[left])) exchange(a[left], a[right]);
    if(left + 2 > right) return;  // 不多于两个元素
    unshuffle(a, left, right);  // 逆混洗
    mergeTD(a, left, m);
    mergeTD(a, m + 1, right);
    shuffle(a, left, right);  // 混洗
    for(i = left + 1;i < right;i += 2)  //比较交换
        if(less(a[i + 1], a[i])) exchange(a[i], a[i + 1]);
}
```

## 堆排序

### 堆

大顶堆——堆中不存在大于根键的结点。与之对应的由小顶堆。这里使用大顶堆。
如果用数组来保存堆，如果下标从 **`0`** 开始，很容易知道位置 **`i`** 处结点的父亲位于 **`(i - 1) / 2`** , 反之位置 **`i`** 处结点的孩子位于 **`(2i + 1)`** 和**`(2i + 2)`** 处。
堆中的第 **`i`** 个元素大于等于第 **`(2i + 1)`** 个元素和 **`(2i + 2)`** 个元素。
有关堆的很多算法都是首先对堆做一个简单的修改，这可能违反堆的条件，然后遍历堆，同时修正堆，确保整个堆满足堆的条件。
修正堆的情况有两种，一种是在堆底部添加新节点，然后需要向上遍历调整堆；另一种是用一个新节点替换掉根节点，然后需要向下遍历调整堆。
如果是由于节点的键变得大于它的父亲而违反了堆的性质，则可以通过交换该节点和它的父亲的位置。交换后，节点大于它的两个孩子（
一个是原来的父亲，一个是原来父亲的另一个孩子），但它仍有可能大于现在的父亲，因此需要继续调整，直到遇到一个真正比它大的父节点或者到达根的位置才结束。
如果是由于节点的键变得小于它的一个或者两个孩子而违反了堆的性质。则可以通过交换此节点和它的大孩子来进行修改。这可能导致孩子
的违规，然后就按照这种方式继续调整，直到到达不小于它的所有孩子的节点或者叶子节点才结束。

### 自底向上堆化

向上遍历堆，只要 **`a[k/2]`**  <  **`a[k]`** 就交换 **`k`** 处和 **`k/2`** 处的节点的位置。继续此过程，或者直到到达根节点为止

```C++
void fixUp(type a[], int left, int right){
    int s = right;
    int f = s / 2 - 1;
    while(f >= left){
        if(a[f] < a[s]) exchange(a[f], a[s]);
        s = f;
        f = s / 2 - 1;
    }
}
```

### 自顶向下堆化

向下遍历堆， 交换位置 **`k`** 处的节点和它孩子中较大的那个节点（如果有需要的话），当位置 **`k`** 处的节点不小于它的孩子或者到达了底端就停止。
需要注意的是：如果 **`N`** 为偶数，且 **`k = N/2`** 时， 它只有一个孩子节点。

```C++
void fixDown(type a[], int left, int right){
    int f = left;
    int s = 2 * f + 1; //左孩子
    while(s <= right){  // 没有到达底端
        if(s + 1 <= right && less(a[s], a[s + 1])) s++; // 找大孩子
        if(!less(a[f], a[s])) break;  // 已经满足堆的条件，跳出
        exchange(a[s], a[f]);   // 交换
        f = s;  // 继续
        s = 2 * f + 1;
    }
}
```

### 排序方法

移出堆顶元素，然后调整堆。重复直到堆中只有一个元素。

```C++
void heapSort(type a[], int left, int right){
    int N = right - left + 1;
    int i = N / 2 - 1; // 初始化i为最后一个父节点，从最后一个父节点开始调整，因为所有的叶子节点都是堆了
    for(;i >= 0;i--) fixDown(a, i, N); // 建大顶堆
    for(i = right;i >= left;){
        exchange(a[left], a[i]);  // 把根节点交换到最后
        fixDown(a, left, --i);  // 调整
    }
}
```

## 基数排序

 >引入：当我们在电话簿中查找某个人的电话时，我们通常只输入前几个字母，然后就能得到电话号码所在的页。为了在排序算法中取得相似效率，可以将比较键的抽象转化为另一种抽象。将这些键分解为一系列定长片段或字节。然后每次处理其中的一个片段，这种排序方法叫做基数排序。基数排序算法把键当作以R为基数的数值系统表示的数，R可取不同的值，分别处理这些数中的单个数字。
基数排序有两种：一种时从左到右按顺序检查键中的位，称为最高位基数排序。另一种采用从右到左的顺序，称为最低为基数排序。

以16进制为例，可以通过右移运算取得int(这里int为32 位)型数组 **`a[i]`** 的各个字节的数字:最低位(a[i] >> 0) & 0xff 、次低位(a[i] >> 8) & 0xff 以及(a[i] >> 16) & 0xff 和(a[i] >> 24) & 0xff。我们需要256(0xff - 0x00 + 1 = 256)个桶。稍微修改键索引计数的程序就得到了基数排序的程序。

```C++
void radix(int b, type a[], int left, int right){
    int i, j, M = 256;
    int N = right - left + 1, cnt[M];
    type *aux = new type[N];
    for(j = 0;j < M;j++) cnt[j] = 0; // 初始化计数为0
    for(i = left;i <= right;i++) cnt[((a[i] >> b * 8) & 0xff) + 1]++;  // 统计出现频率
    for(j = left;j < M;j++) cnt[j + 1] += cnt[j]; //得到小于等于计数器对应计数值键的数量,将频率转换为索引
    for(i = left;i <= right;i++) aux[cnt[(a[i] >> b * 8) & 0xff]++] = a[i]; //将键分不到辅助数组中
    for(i = left;i <= right;i++) a[i] = aux[i]; // 回写
    delete []aux;
}

void radixSort(type a[], int left, int right){
    radix(0, a, left, right);
    radix(1, a, left, right);
    radix(2, a, left, right);
    radix(3, a, left, right);
}
```
