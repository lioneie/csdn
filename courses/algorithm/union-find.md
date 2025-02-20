并查集如果直接做题，可能不好理解，最好是先[学一下并查集数据结构的知识点](https://www.runoob.com/data-structures/union-find-basic.html)。

# leetcode 547. 省份数量

- [点击这里查看题目](https://leetcode.cn/problems/number-of-provinces/description/)

比如城市连接情况如下:
```
0 <--> 1 <--> 2 <--> 5
3 <--> 4
```

`isConnected[]`数组是这样:
```
1 1 1 0 0 1
  1 1 0 0 1
    1 0 0 1
      1 1 0
        1 0
          1
```

代码执行过程:
```
(i=0,j=1) = 1, Union(1, 0), id[1] = id[0] = 0
(i=0,j=2) = 1, Union(2, 0), id[2] = id[0] = 0
(i=0,j=5) = 1, Union(5, 0), id[5] = id[0] = 0
---------------------------------------------
(i=1,j=2) = 1, Union(2, 1), id[2] = id[1] = 0
(i=1,j=5) = 1, Union(5, 1), id[5] = id[1] = 0
---------------------------------------------
(i=2,j=5) = 1, Union(5, 2), id[5] = id[2] = 0
---------------------------------------------
(i=3,j=4) = 1, Union(4, 3), id[4] = id[3] = 3
```

运行结束后:
```
id[0] = 0
id[1] = 0
id[2] = 0
id[3] = 3
id[4] = 3
id[5] = 0
```

所以只有2个id，也就是省份个数为2个。

[力扣官方题解](https://leetcode.cn/problems/number-of-provinces/solutions/549895/sheng-fen-shu-liang-by-leetcode-solution-eyk0/)c语言实现加些注释:
```c
int Find(int* id, int index) {
    // 以Union(id, j, i)调用，Find()递归不会超过2次
    if (id[index] != index) {
        id[index] = Find(id, id[index]);
    }
    return id[index];
}

void Union(int* id, int index1, int index2) {
    // index2的id和index1一样
    id[Find(id, index1)] = Find(id, index2);
}

int findCircleNum(int** isConnected, int isConnectedSize, int* isConnectedColSize) {
    int cities = isConnectedSize;
    int id[cities];
    for (int i = 0; i < cities; i++) {
        id[i] = i;
    }
    for (int i = 0; i < cities; i++) {
        // j大于i，所以不会重复检查
        for (int j = i + 1; j < cities; j++) {
            if (isConnected[i][j] == 1) {
                // 官方给出的代码中用的是Union(id, i, j)不好理解
                // 改成这样j放前面才更好理解
                Union(id, j, i);
            }
        }
    }
    int provinces = 0;
    for (int i = 0; i < cities; i++) {
        if (id[i] == i) {
            provinces++;
        }
    }
    return provinces;
}
```

