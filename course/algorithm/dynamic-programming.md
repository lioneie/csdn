在大厂的笔试中，动态规划属于是常考的一类题，也是很多人比较害怕的题目，就从这种题型开始吧。

# 钢条切割

题目在《算法导论》书中的第204页。下面简单的描述一下题目。

有一根钢条，给出一个价格数组`price[] = {0, 1, 5, 8, 9, 10, 17, 17, 20, 24, 30}`，其中`price[1]`表示长度为`1`的钢条价格为`1`，`price[2]`表示长度为`2`的钢条价格为`5`，求最多能卖多少钱？

- [带备忘的自顶向下法钢条切割](https://gitee.com/chenxiaosonggitee/blog/blob/master/course/algorithm/src/dynamic-programming/cut-rod-resultsized.c)
- [自底向上法钢条切割](https://gitee.com/chenxiaosonggitee/blog/blob/master/course/algorithm/src/dynamic-programming/cut-rod-bottom-up.c)

# leetcode 509. 斐波那契数

- [点击这里查看题目](https://leetcode.cn/problems/fibonacci-number/description/)

没错，除了使用递归来获得斐波那契数，也可以用动态规划来获得斐波那契数。

自底向上法:
```c
int fib(int n)
{
    if (n < 2)
        return n;
    int p = 0;
    int q = 0;
    int res = 1;
    for (int i = 2; i <= n; i++) {
        p = q;
        q = res;
        res = p + q;
    }
    return res;
}
```

带备忘的自顶向下法，其实就是递归，这里只是再熟悉一下动态规划的步骤:
```c
#define MAX_N 31

// 斐波那契函数，使用备忘录法（自顶向下）
int __fib(int n, int *results) {
    if (n == 0)
        return 0;
    if (n == 1)
        return 1;

    if (results[n] != -1) {
        return results[n]; // 已经计算过
    }

    results[n] = __fib(n - 1, results) + __fib(n - 2, results);

    return results[n];
}

int fib(int n)
{
    int results[MAX_N];

    // 初始化备忘录数组，所有元素设为 -1 表示尚未计算
    for (int i = 0; i < MAX_N; i++)
        results[i] = -1;

    return __fib(n, results);
}
```

