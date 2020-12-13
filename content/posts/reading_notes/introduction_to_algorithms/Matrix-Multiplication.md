---
title: "矩阵乘法"
date: 2018-07-02T08:44:56+08:00
draft: false
mathjax: true
toc: true
categories:
  - 算法导论
tags:
  - 算法
authors: ["zhannicholas"]
---

# 矩阵乘法

矩阵相乘只有在第一个矩阵的列数（column）和第二个矩阵的行数（row）相同时才有定义。若 **`A`** 为 **`m x n`** 矩阵，B为 **`n x p`** 矩阵，则他们的乘积 **`C = AB`** 会是一个 **`m x p`** 矩阵。其乘积矩阵的元素如下面式子得出：
$$C\_{ij} = \sum\_{k = 1}^n A\_{ik} B\_{kj}$$

# 解决方案

## 常规方法求解

根据矩阵相乘的定义，可以直接求解两个矩阵的乘积。但这种方法的时间复杂度为：$ O(n^3) $。java代码如下：

```java
public int[][] matrixMultiply(int[][] A, int[][] B) {
        int rowc = A.length, colc = B[0].length, colab = A[0].length;
        int[][] C = new int[rowc][colc];
        for (int i = 0; i < rowc; i++) {
            for (int j = 0; j < colc; j++) {
                for (int k = 0; k < colab; k++) {
                    C[i][j] += A[i][k] * B[k][j];
                }
            }
        }
        return C;
    }
```

## 分治法求解

使用分治法求解矩阵乘法实际上是利用了分块矩阵的性质。为了方便使用分治法，假定相乘的矩阵都是 **`n x n`** 的，其中 **`n`** 是2的幂。分治法将 **`n x n`** 的矩阵划分为4个 **`n/2 x n/2`** 的子矩阵，然后进行运算。假设矩阵 **`A`** 、 **`B`** 、 **`C`** 均满足上面的要求，那么它们可以进行如下表示：
$$ A = \begin{bmatrix}A\_{11} & A\_{12} \\\ A\_{21} & A\_{22} \\\ \end{bmatrix},  B = \begin{bmatrix}B\_{11} & B\_{12} \\\ B\_{21} & B\_{22} \\\ \end{bmatrix},  C = \begin{bmatrix}C\_{11} & C\_{12} \\\ C\_{21} & C\_{22} \\\ \end{bmatrix} $$ 
于是有：
$$ A = \begin{bmatrix}C\_{11} & C\_{12} \\\ C\_{21} & C\_{22} \\\ \end{bmatrix} = \begin{bmatrix}A\_{11} & A\_{12} \\\ A\_{21} & A\_{22} \\\ \end{bmatrix} \begin{bmatrix}B\_{11} & B\_{12} \\\ B\_{21} & B\_{22} \\\ \end{bmatrix} $$
也就是说：
$$ C\_{11} = A\_{11}B\_{11} + A\_{12}B\_{21} $$
$$ C\_{12} = A\_{11}B\_{12} + A\_{12}B\_{22} $$
$$ C\_{21} = A\_{21}B\_{11} + A\_{22}B\_{21} $$
$$ C\_{22} = A\_{21}B\_{12} + A\_{22}B\_{22} $$
《算法导论》上的伪代码如下：
![Square-Matrix-Multiply-Recursive](/images/introduction_to_algorithms/Square-Matrix-Multiply-Recursive.jpg)
书上的伪代码掩盖了一个非常重要的细节，那就是如何分解矩阵。如果真的创建出12个子矩阵，那将会花费O($ n^2 $)的时间来复制矩阵的元素。不过书上给出了一个十分关键的提示——用下标来指明一个子矩阵。如此一来，就可以避免对矩阵的复制操作，只需花费O(1)的时间。既然矩阵符合上面的要求，只需要改变矩阵的表示方式即可。添加子矩阵在原矩阵中的开始位置及子矩阵的大小就好了。

java实现的代码如下：

```java
/**
     * @param ra A中行开始下标
     * @param ca A中列开始下标
     * @param n  子方阵宽度
     */
    private int[][] squareMatrixMultiply(int[][] A, int[][] B, int[][] C, int ra, int ca, int rb, int cb, int rc, int cc, int n) {
        if (n == 1) {
            C[rc][cc] = A[ra][ca] * B[rb][cb];  // 只有一个元素
        } else if (n == 2) {  // 都只有四个元素
            C[rc][cc] += A[ra][ca] * B[rb][cb] + A[ra][ca + 1] * B[rb + 1][cb];  // C11 = A11 * B11 + A12 * B21
            C[rc][cc + 1] += A[ra][ca] * B[rb][cb + 1] + A[ra][ca + 1] * B[rb + 1][cb + 1];  // C12 = A11 * B12 + A12 * B22
            C[rc + 1][cc] += A[ra + 1][ca] * B[rb][cb] + A[ra + 1][ca + 1] * B[rb + 1][cb];  // C21 = A21 * B11 + A22 * B21
            C[rc + 1][cc + 1] += A[ra + 1][ca] * B[rb][cb + 1] + A[ra + 1][ca + 1] * B[rb + 1][cb + 1];  // C22 = A21 * B12 + A22 * B22
        } else {
            n /= 2; // 分解矩阵
            squareMatrixMultiply(A, B, C, ra, ca, rb, cb, rc, cc, n);  // A11 * B11
            squareMatrixMultiply(A, B, C, ra, ca + n, rb + n, cb, rc, cc, n);  // A12 * B21
            squareMatrixMultiply(A, B, C, ra, ca, rb, cb + n, rc, cc + n, n);  // A11 * B12
            squareMatrixMultiply(A, B, C, ra, ca + n, rb + n, cb + n, rc, cc + n, n);  // A12 * B22
            squareMatrixMultiply(A, B, C, ra + n, ca, rb, cb, rc + n, cc, n);  // A21 * B11
            squareMatrixMultiply(A, B, C, ra + n, ca + n, rb + n, cb, rc + n, cc, n);  // A22 * B21
            squareMatrixMultiply(A, B, C, ra + n, ca, rb, cb + n, rc + n, cc + n, n);  // A21 * B12
            squareMatrixMultiply(A, B, C, ra + n, ca + n, rb + n, cb + n, rc + n, cc + n, n); // A22 * B22
        }
        return C;
    }
```

## Strassen方法

Strassen方法不是很直观，它的核心思想是减少乘法的次数。分治法用了8次乘法，而Strassen方法只用了7次乘法，时间复杂度为$ O(n^{lg\_7}) $。它的步骤如下：

1. 先将矩阵A、B、C分解为 **`n/2 x n/2`** 的子矩阵，可以采用上面的下标计算方式，但我重新创建了子矩阵。
2. 创建10个 **`n/2 x n/2`** 的矩阵$ S\_1, S\_2, ..., S\_{10} $:

$$ S\_1 = B\_{12} - B\_{22} $$
$$ S\_2 = A\_{11} + A\_{12} $$
$$ S\_3 = A\_{21} + A\_{22} $$
$$ S\_4 = B\_{21} - B\_{11} $$
$$ S\_5 = A\_{11} + A\_{22} $$
$$ S\_6 = B\_{11} + B\_{22} $$
$$ S\_7 = A\_{12} - A\_{22} $$
$$ S\_8 = B\_{21} + B\_{22} $$
$$ S\_9 = A\_{11} - A\_{21} $$
$$ S\_{10} = B\_{11} + B\_{12} $$
3. 递归的计算7次 **`n/2 x n/2`** 的矩阵乘法：
$$ P\_1 = A\_{11}S\_1 = A\_{11}B\_{12} - A\_{11}B\_{22} $$
$$ P\_2 = B\_{22}S\_2 = A\_{11}B\_{22} + A\_{12}B\_{22} $$
$$ P\_3 = B\_{11}S\_3 = A\_{21}B\_{11} + A\_{22}B\_{11} $$
$$ P\_4 = A\_{22}S\_4 = A\_{22}B\_{21} - A\_{22}B\_{11} $$
$$ P\_5 = S\_5S\_6 = A\_{11}B\_{11} + A\_{11}B\_{22} + A\_{22}B\_{11} + A\_{22}B\_{22} $$
$$ P\_5 = S\_5S\_6 = A\_{11}B\_{11} + A\_{11}B\_{22} + A\_{22}B\_{11} + A\_{22}B\_{22} $$
$$ P\_6 = S\_7S\_8 = A\_{12}B\_{21} + A\_{12}B\_{22} - A\_{22}B\_{21} - A\_{22}B\_{22} $$
$$ P\_7 = S\_9S\_{10} = A\_{11}B\_{11} + A\_{11}B\_{12} - A\_{21}B\_{11} + A\_{21}B\_{12} $$
4. 对$ P\_i $ 执行加减法运算得到 **`C`** 的四个子矩阵：
$$ C\_{11} = P\_5 + P\_4 - P\_2 + P\_6 $$
$$ C\_{12} = P\_1 + P\_2 $$
$$ C\_{21} = P\_3 + P\_4 $$
$$ C\_{22} = P\_5 + P\_1 - P\_3 - P\_7 $$
由于我直接拆分了矩阵，因此这一步还需要合并四个子矩阵到 **`C`** 。

java 代码如下：

```java
private int[][] squareMatrixMultiplyStrassen(int[][] A, int[][] B, int ra, int ca, int rb, int cb, int n) {
        int[][] C = new int[n][n];
        if (n == 1) {
            C[0][0] = A[ra][ca] * B[rb][cb];
            return C;
        } else {
            // step 1: 分解矩阵
            n /= 2;

            // step 2: 创建10个矩阵
            int[][] S1 = squareMatrixAddorSub(B, B, rb, cb + n, rb + n, cb + n, n, false);  // S1 = B12 - B22
            int[][] S2 = squareMatrixAddorSub(A, A, ra, ca, ra, ca + n, n, true);  // S2 = A11 + A12
            int[][] S3 = squareMatrixAddorSub(A, A, ra + n, ca, ra + n, ca + n, n, true);  // S3 = A21 + A22
            int[][] S4 = squareMatrixAddorSub(B, B, rb + n, cb, rb, cb, n, false);  // S4 = B21 - B11
            int[][] S5 = squareMatrixAddorSub(A, A, ra, ca, ra + n, ca + n, n, true);  // S5 = A11 + A22
            int[][] S6 = squareMatrixAddorSub(B, B, rb, cb, rb + n, cb + n, n, true);  // S6 = B11 + B22
            int[][] S7 = squareMatrixAddorSub(A, A, ra, ca + n, ra + n, ca + n, n, false);  // S7 = A12 - A22
            int[][] S8 = squareMatrixAddorSub(B, B, rb + n, cb, rb + n, cb + n, n, true);  // S8 = B21 + B22
            int[][] S9 = squareMatrixAddorSub(A, A, ra, ca, ra + n, ca, n, false);  // S9 = A11 - A21
            int[][] S10 = squareMatrixAddorSub(B, B, rb, cb, rb, cb + n, n, true);  // S10 = B11 + B12

            // Step 3: 计算7次乘法
            int[][] P1 = squareMatrixMultiplyStrassen(A, S1, ra, ca, 0, 0, n);  // P1 = A11 * S1
            int[][] P2 = squareMatrixMultiplyStrassen(S2, B, 0, 0, rb + n, cb + n, n);  // P2 = S2 * B22
            int[][] P3 = squareMatrixMultiplyStrassen(S3, B, 0, 0, rb, cb, n);  // P3 = S3 * B11
            int[][] P4 = squareMatrixMultiplyStrassen(A, S4, ra + n, ca + n, 0, 0, n);  // P4 = A22 * S4
            int[][] P5 = squareMatrixMultiplyStrassen(S5, S6, 0, 0, 0, 0, n);  // P5 = S5 * S6
            int[][] P6 = squareMatrixMultiplyStrassen(S7, S8, 0, 0, 0, 0, n);  // P6 = S7 * S8
            int[][] P7 = squareMatrixMultiplyStrassen(S9, S10, 0, 0, 0, 0, n);  // P7 = S9 * S10

            // Step4: 根据P1-P7计算出C
            int[][] T1 = squareMatrixAddorSub(P5, P4, 0, 0, 0, 0, n, true);  // P5 + P4
            int[][] T2 = squareMatrixAddorSub(P2, P6, 0, 0, 0, 0, n, false);  // P2 - P6
            int[][] C11 = squareMatrixAddorSub(T1, T2, 0, 0, 0, 0, n, false);  // C11 = P5 + P4 - P2 + P6
            int[][] C12 = squareMatrixAddorSub(P1, P2, 0, 0, 0, 0, n, true);  // C12 = P1 + P2
            int[][] C21 = squareMatrixAddorSub(P3, P4, 0, 0, 0, 0, n, true);  // C21 = P3 + P4
            int[][] T3 = squareMatrixAddorSub(P5, P1, 0, 0, 0, 0, n, true);  // P5 + P1
            int[][] T4 = squareMatrixAddorSub(P3, P7, 0, 0, 0, 0, n, true);  // P3 + P7
            int[][] C22 = squareMatrixAddorSub(T3, T4, 0, 0, 0, 0, n, false);  // C22 = P5 + P1 - P3 - P7

            // 合并C11、C12、C21、C22为C
            for (int i = 0; i < n; i++) {
                for (int j = 0; j < n; j++) {
                    C[i][j] = C11[i][j];
                }
            }
            for (int i = 0; i < n; i++) {
                for (int j = 0; j < n; j++) {
                    C[i][j + n] = C12[i][j];
                }
            }
            for (int i = 0; i < n; i++) {
                for (int j = 0; j < n; j++) {
                    C[i + n][j] = C21[i][j];
                }
            }
            for (int i = 0; i < n; i++) {
                for (int j = 0; j < n; j++) {
                    C[i + n][j + n] = C22[i][j];
                }
            }

        }
        return C;
    }
```

# 后记

当然，并不是所有的矩阵都是方阵， 也不是所有的方阵的元素个数的都是2的幂。为了让Strassen方法适用于一般的矩阵乘法，可以通过在原矩阵的行列补零得到上面要求的矩阵。在这之前，需要判断这个矩阵是不是上面的方阵，也就是判断方阵每行的元素个数是不是2的幂次方。

一种简单的方法如下：

```java
private boolean isSquareMatrix(int[][] A) {
        int rowa = A.length, cola = A[0].length;
        if ((rowa == cola) && ((rowa & (rowa - 1)) == 0)) return true;
        else return false;
    }
```

比如：8 & 7 = (1000 & 0111) = 0

如果矩阵不是我们需要的方阵，那么在将其转换成理想形式的方阵之前， 还需要找到比矩阵每行和每列的元素个数都要大并且最接近的2的幂次方数，下面是一种可行的方法：

```java
// 获取比a大，最接近a的2的幂次方数
    private int nextP2(int a){
        int t = 1;
        while(t < a) t <<= 1;
        return t;
    }

```

准备工作都做好了，接下来就是将矩阵转化为我们理想的方阵了，方法很简单，直接将原来的矩阵复制进新的矩阵就行了：

```java
private int[][] convertMatrixToStandardSquareMatrix(int[][] A, int n){
        int rowa = A.length, cola = A[0].length;
        int[][] C = new int[n][n];
        for(int i = 0;i < rowa;i++){
            for(int j = 0;j < cola;j++){
                C[i][j] = A[i][j];
            }
        }
        return C;
    }
```

如此以来，Strassen方法所需要的条件都有了，但这么计算出来的结果中会出现很多很多的0。这看起来是很不舒服的，于是，可以先保存原来矩阵的行数和列数，然后去掉多余的0，得到常规方法计算矩阵乘法的结果。

```java
// 处理不是2的指数次幂的矩阵变成方阵后运算多出来的那一大堆0
    private int[][] removeZerosInMatrix(int[][] A, int rowa, int cola){
        int[][] C = new int[rowa][cola];
        for(int i = 0;i < rowa;i++){
            for(int j = 0;j < cola;j++){
                C[i][j] = A[i][j];
            }
        }
        return C;
    }
```

<script type="text/javascript" src="http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=default"></script>
