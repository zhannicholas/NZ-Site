---
title: "树"
date: 2018-06-02T10:07:28+08:00
draft: false
toc: true
categories:
  - 读书笔记
tags:
  - C算法
authors: ["zhannicholas"]
---

树是满足一定要求的顶点和边的非空集合。

# 二叉树

二叉树的每个节点至多有2个子节点。
一种表示方法：

```C++
struct Node{type key; Node *lchild, *richild;}
typedef Node *link;
```

这种表示方法只适合从根节点开始自顶向下的操作，而不适合自底向上的操作。不过可以在节点的定义中加入指向父节点的连接支持这种功能。
与二叉树类似的还有M叉树，它的每个节点最多只有M个节点。广义的树每个节点可以有任意多个子节点，可以用二叉树来表示它们，方法就是——“左孩子，右兄弟”。树的序列就形成了有序森林。
> 二叉树和有序森林之间存在一一的对应关系。

## 二叉树的一些数学性质

* 一棵二叉树有 **`N`** 个内部节点，有 **`N + 1`** 个外部节点（叶子节点）。
* 包含 **`N`** 个内部节点的二叉树有 **`2N`** 个链接： **`N - 1`** 个外部节点的链接和 **`N + 1`** 个内部节点的链接。
* 树中节点的所在的层是它的父节点的下一层（根节点位于第 **`0`** 层）。树的高度为树节点的最大层。树的路径长度为所有树节点的层总和：外部路径长度为所有外部节点的层总和，内部路径长度为所有内部节点的层总和。
  这里有一个计算树路径长度的简便方法：对于所有的 **`k`** , 求 **`k`** 与 **`k`** 层节点数之积的总和。
* 具有 **`N`** 个内部节点的二叉树的外部路径长度比内部路径长度大 **`2N`** 。
* 具有 **`N`** 个内部节点的二叉树的高度的最小值为 **`lgN`** ，最大值为 **`N - 1`** 。
  当树退化成只有一个叶子节点的时候，就是最坏的情况。
* 具有 **`N`** 个内部节点的二叉树内部路径长度最小值为 **`Nlg(N/4)`** ，最大值为 **`N(N - 1)/2`** 。

## 树的遍历

* 前序遍历
 根->左孩子->右孩子
* 中序遍历
 左孩子->根->右孩子
* 后序遍历
 左孩子->右孩子->根
* 层次遍历
  从上到下，从左到右

前序遍历（递归版）：

```C++
void preorderTraverse(link h, void visit(link)){
    if(h == root) return;
    visit(h);
    preorderTraverse(h -> lchild, visit);
    preorderTraverse(h -> rchild, visit);
}
```

前序遍历（非递归版）：

```C++
void preorderTraverse(link h, void visit(link)){
    stack<link> stk(maxn);
    s.push(h);
    while(!s.empty()){
        visit(s.top());
        s.pop();
        if(h -> lchild != null) s.push(h -> lchild);
        if(h -> rchild != null) s.push(h -> rchild);
    }
}
```

后序遍历和中序遍历只需要交换前序遍历中访问节点的顺序即可。
层次遍历：

```C++
void levelTraverse(link h, void visit(link)){
    queue<link> q(maxn);
    q.push(h);
    while(!q.empty()){
        visit(q.front());
        q.pop();
        if(h -> lchild != null) q.push(q -> lchild);
        if(h -> rchild != null) q.push(q -> rchild);
    }
}
```

计算树含有的节点数：

```C++
int count(link h){
    if(h == null) return 0;
    return count(h -> lchild) + count(h -> rchild) + 1;
}
```

计算树的高度：

```C++
int height(link h){
    if(h == null) return -1;
    return max(height(h -> lchild), height(h -> rchild)) + 1;
}
```

## 二叉搜索树

二叉树搜索树是一棵二叉树，它要么是一棵空树，要么具有以下性质：

1. 若任意节点的左子树不为空，则左子树上所有节点的值不大于它的根节点的值
2. 若任意节点的右子树不为空，则右子树上所有节点的值不小于它的根节点的值
3. 任意节点的左右子树都是二叉搜索树
4. 树中没有键值相等的节点

### 二叉搜索树中的查找

在二叉搜索树h中查找v的过程如下：

1. 若h是空树，则返回查找失败，否则：
2. 若x为根节点对应的数据值，则查找成功，否则：
3. 若x小于根节点对应的数据值，则查找左子树，否则：
4. 查找右子树

```C++
Item searchP(link h, type v){
    if(h == 0) return nullItem;
    type t = h -> item.getKey();
    if(t == v) return h -> item;
    if(v < t) searchP(h -> lchild, v);
    else searchP(h -> rchild, v);
}
```

### 在二叉搜索树中插入节点

在二叉搜索树h中插入节点v的过程如下，其中插入的节点总是叶子节点：

1. 若h是空树，则将v所指的节点作为根节点插入，否则：
2. 若v对应的数据值小于根节点对应的数据值，则在左子树中插入，否则：
3. 在右子树中插入

```C++
void insertP(link &h, Item x){
    if(h == 0) {h = new Node(x);return;}
    if(x.getKey() < h -> item.getKey()) insertP(h -> lchild, x);
    else insertP(h -> rchild, x);
}
```

上面的插入只适用于插入的节点最终是叶子节点的情况，可以通过这种方式来构造一棵树来对数据进行排序。对于插入的节点不一定到达叶子节点的情况，需要考虑其它的插入方法。旋转是树的一种基本变换，它允许交换树中根及其一个孩子的角色，同时保持节点中键的次序。
涉及到3个链接和两个节点。

> 右旋（**左孩子为轴，当前节点右旋**）。结果就是：原来的左孩子成为了新的根，原来左孩子的左孩子依旧是新根的左孩子，旧根的右孩子依旧是旧根的右孩子。旧根成为了新根的右孩子，原来左孩子的右孩子成为了旧根（新根的右孩子）的左孩子。

![rotateR](/images/algorithms_in_c/rotateR.jpg)

```C++
void rotateR(link &h){
    link t = h -> lchild;
    h -> lchild = t -> rchild;
    t -> rchild = h;
    h = t;
}
```

> 左旋和右旋相反。**右孩子为轴，当前节点左旋**。原来的右孩子成为了新的根，旧根成为了新根的左孩子。原来的右孩子的左孩子成为了旧根的右孩子。

![rotateL](/images/algorithms_in_c/rotateL.jpg)

```C++
void rotateL(link &h){
    link t = h -> rchild;
    h -> rchild = h -> lchild;
    t -> lchild = h;
    h = t;
}
```

有了左旋和右旋之后，就能迅速得到在BST的根插入新节点的递归函数，再适当子树的根插入新项，然后通过旋转将它带到主树的根。

```C++
void insertT(link &h, Item x){
    if(h == 0){h = new Node(x);return;}
    if(x.getKey() < h -> item.getkey()){insertT(h -> lchild, x); rotateR(h);}
    else{insertT(h -> rchild,x); rotateL(h);}
}
```

### 在二叉搜索树中选择节点

可以采用快速排序划分的思想来选择BST中第 **`k`** 小的节点。不过这需要给结点增加一个计数域，然后还需要修改其他所有的函数。

```C++
Item selectR(link h, int k){
    if(h == 0) return nullItem;
    int c = (h -> lchild == 0) ? 0 : h -> lchild -> cnt;
    if(c > k) return selectR(h -> lchild, k);
    if(c < k) return selectR(h -> rchild, k - c - 1);
    return h -> item;
}
```

### 对二叉搜索树进行划分

可以将选择运算修改为划分运算，它重排树，利用左旋和右旋将第 **`k`** 小的元素放到根。

```C++
link partition(link &h, int k){
    int c = (h -> lchild == 0) ? 0 : h -> lchild -> cnt;
    if(c > k) {partition(h -> lchild, k); rotateR(h);}
    if(c < k) {partition(h -> rchild, k - c - 1); rotateL(h);}
}
```

### 在二叉搜索树中删除节点

从BST删除一个节点，首先检查该节点是否在其中一棵子树中。如果是则用递归删除节点后的结果替换子树。如果删除的节点在根部，则需要用合并两棵子树的结果替换原来的树。

```C++
link joinLR(link l, link r){
    if(r == 0) return l;
    partition(r, 0);
    r -> lchild = l;
    return r;
}

void removeR(link &h, type v){
    if(h == 0) return;
    type w = h -> item.getKey();
    if(v < w) removeR(h -> lchild, v);
    if(v > w) removeR(h -> rchild, v);
    if(v == w){
        link t = h;
        h = joinLR(h -> lchild, h -> rchild);
        delete t;
    }
}
```

### 合并两棵二叉搜索树

书中的一个线性时间的递归实现：首先，利用根插入将第一课BST的根插入到第二棵BST中。这会得到两棵键小于根的子树和两棵键大于根的子树。然后递归的合并根左子树的前一对与根右子树的后一对来得到结果。

```C++
link joinAB(link a, link b){
    if(a == 0) return b;
    if(b == 0) return a;
    insertT(b, a -> item);
    b -> lchild = jionAB(a -> lchild, b -> lchild);
    b -> rchild = jionAB(a -> rchild, b -> rchild);
    delete a;
    return b;
}
```

## 2-3-4树

2-3-4树可以在O(logN)的时间内完成查找、插入、和删除操作。

2-3-4树是一棵空树或者是具有以下三类节点的树：

* 2-节点
    它具有一个键，以及具有较小键的左子树和具有较大键的右子树的两个链接。
* 3-节点
    它具有两个键，以及具有较小键的左子树，较大键的右子树和介于节点键之间的中间子树的三个链接。
* 4-节点
    它具有三个键，以及由节点键对应的区间定义的键值的树的四个链接。

### 节点的插入处理

* 如果搜索结束的节点是2-节点，将其变为3-节点。
* 如果搜索结束的节点是3-节点，将其变为4-节点。
* 如果搜索结束的节点是4-节点，将其分裂成两个2-节点，并将中间键上移到节点的父亲（父节点不是4-节点）。但如果父节点也是4-节点呢？更好的一个方法是：在沿树向下的过程中，分解任何4-节点，保证搜索路径不在4-节点终止。具体做法是：每当遇到一个2-节点（父亲）连接到4-节点（孩子），就把它转化为一个3-节点连接到连个2节点；每当遇到一个3-节点连接到4-节点，就把它转换为一个4-节点连接到两个2-节点。

## 红黑树

2-3-4树易于理解，但实现困难。
红黑树是2-3-4树的一种简单抽象表达方式。其基本思想是将2-3-4树表示为标准的BST(仅有2-节点)，但为每个节点添加一个额外的信息位，来为3-节点和4-节点编码。

链接有两种不同的类型：

* 红链接
    红链接将包含3-节点和4-节点的小二叉树捆绑在一起。
* 黑链接
    黑链接将2-3-4树捆绑在一起。

![2-3-4-and-red-black-tree](/images/algorithms_in_c/2-3-4.jpg)

红黑树有两个本质特性：

 1. 不用修改BST的标准搜索过程就能工作。
 2. 它们与2-3-4树直接对应。因此可以用上2-3-4树的简单插入平衡过程。

如果某个节点有2个红孩子，则它是4-节点的一部分。红黑树的插入开销很小：仅当看到4-节点的时候才采取平衡措施。分解不同4-节点的具体做法可以对照下图来说：
![balance-red-black-tree](/images/algorithms_in_c/balance-red-black-tree.jpg)

* 左一：4-节点的父亲是一个2-节点。
    将中间键上移转换为一个3-节点与两个2-节点的连接（变色）。
* 左二：4-节点的父亲是一个3-节点，并且是它的右孩子。
    变色。
* 左三：4-节点的父亲是一个3-节点，并且是它的左孩子。
    先变色得到两个方向相同的红链接，然后右旋。
* 左四：4-节点的父亲是一个3-节点，并且是它的中间孩子。
    先变色得到两个方向不同的红链接，然后右旋得到两个方向相同的红链接，然后再左旋。

用红黑树表示法实现2-3-4树的插入操作，首先要给修改节点定义，加入颜色位（用 **`1`** 表示红节点， **`0`** 表示黑节点）。在沿树向下的路径中（递归调用之前），检查4-节点，并通过切换所有3-节点的颜色位来分裂它们。当到达底部时，为被插入的项新建一个红节点并返回它的指针。在沿向上的路径中（递归调用之后），检查是否需要执行一次旋转操作：如果路径上有两个相同方向的红链接，则从上方节点进行一次旋转，然后切换颜色位，以形成一个正确的4-节点；如果路径上有两个方向不同的红链接，则从下方的节点执行一次旋转，以简化为另一种情况，留作向上的下一步处理。

```C++
int getColor(link x){if(x == 0) return 0; return x -> color;}
void insertRB(link &h, Item x, int sw){
    if(h == 0){h = new Node(x); return;}
    if(getColor(h -> lchild) && getColor(h -> rchild)){  // 变色, 分裂4-节点为3-节点
        h -> color = 1;
        h -> lchild -> color = 0;
        h -> rchild -> color = 0;
    }
    if(x.getKey() < h -> item.getKey()){  // 向左子树插入
        insertRB(h -> lchild, x, 0);
        if(getColor(h) && getColor(h -> lchild) && sw)  // 两个方向相同的红链接
            rotateR(h);
        if(getColor(h -> lchild) && getColor(h -> lchild -> lchild)){
            rotateR(h);
            h -> color = 0;
            h -> rchild -> colot = 1;
        }
    }
    else{  // 向右子树插入
        inserRB(h -> rchild, x, 1);
        if(getColor(h) && getColor(h -> rchild) && !sw)  // 左旋
            rotateL(h);
        if(getColor(h -> rchild) && getColor(h -> rchild -> rchild)){
            rotateL(h);
            h -> color = 0;
            h -> lchild -> color = 1;
        }
    }
}
```

红黑树的结构性定义：

红黑树是每个节点都带有颜色的BST，颜色为红色或黑色。除了BST的基本要求外，它还必须满足以下要求：

 1. 节点要么是红色，要么是黑色
 2. 根节点是黑色
 3. 所有叶子节点都是黑色
 4. 每个红节点必须有两个黑色的子节点（也就是说：不能有两个连续的红链接）。
 5. 从任一节点到其每个叶子节点的所有简单路径都包含相同数目的黑节点。
