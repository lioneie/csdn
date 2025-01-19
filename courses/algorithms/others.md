# leetcode 204. 计数质数

- [点击这里查看题目](https://leetcode.cn/problems/count-primes/description/)

质数的定义: 只有两个正因数（1和它本身）的自然数即为质数。如: 2, 3, 5, 7, 11, ...

## 枚举法

枚举法，无法通过所有测试用例:
```c
int is_prime(int num)
{
    for (int i = 2; i * i <= num; i++) {
        if (num % i == 0)
            return 0;
    }
    return 1;
}

int countPrimes(int n) {
    int ret = 0;
    for (int i = 2; i < n; i++)
        ret += is_prime(i);
    return ret;
}
```

## 埃氏筛

[点击这里查看官方讲解](https://leetcode.cn/problems/count-primes/solutions/507273/ji-shu-zhi-shu-by-leetcode-solution/)。

```c
static int *is_composites;

void get_composites(int n)
{
    for (int i = 2; i < n; ++i) {
        if (!is_composites[i]) {
            // n 不必被 2 ~ n-1 之间的每一个整数去除，只需被 2 ~ 根号 n 之间的每一个整数去除就可以了
            if ((long long)i * i < n) {
                // 应该直接从 i*i 开始标记，因为 2i,3i,… 这些数一定在 i 之前就被其他数的倍数标记过了
                for (int j = i * i; j < n; j += i) {
                    is_composites[j] = 1;
                }
            }
        }
    }
}

int is_prime(int n)
{
    return !is_composites[n];
}

int countPrimes(int n) {
    if (n < 2) {
        return 0;
    }
    is_composites = malloc(sizeof(int) * n);
    memset(is_composites, 0, sizeof(int) * n);
    get_composites(n);
    int ret = 0;
    for (int i = 2; i < n; i++)
        ret += is_prime(i);
    free(is_composites);
    return ret;
}
```

## 线性筛

[这个方法有时间再研究](https://leetcode.cn/problems/count-primes/solutions/507273/ji-shu-zhi-shu-by-leetcode-solution/)

# 2019华为面试题 - 计算孪生素数对的个数

题目: 计算不大于n(1 < n < 100000001)的范围内的[孪生素数](https://baike.baidu.com/item/%E5%AD%AA%E7%94%9F%E8%B4%A8%E6%95%B0/10399834)对的个数。100以内有: (3,5), (5,7), (11,13), (17,19), (29,31), (41,43), (59,61), (71,73)，共8组。

[点击这里查看源码](https://gitee.com/chenxiaosonggitee/blog/blob/master/courses/algorithms/src/others/twin-prime.c)。

# leetcode 32. 最长有效括号

23年刚开始的几天做了但没什么卵用的题目。

- [点击这里查看题目](https://leetcode.cn/problems/longest-valid-parentheses/description/)

# leetcode 236. 二叉树的最近公共祖先

23年刚开始的几天做了但没什么卵用的题目。

- [点击这里查看题目](https://leetcode.cn/problems/lowest-common-ancestor-of-a-binary-tree/description/)

# 时间区间类 leetcode 57. 插入区间

- [点击这里查看题目](https://leetcode.cn/problems/insert-interval/description/)

# 系统设计题 leetcode 1396. 设计地铁系统

- [点击这里查看题目](https://leetcode.cn/problems/design-underground-system/description/)

# 系统题 leetcode 146. LRU 缓存

- [点击这里查看题目](https://leetcode.cn/problems/lru-cache/description/)

# 系统题 leetcode 355. 设计推特

- [点击这里查看题目](https://leetcode.cn/problems/design-twitter/description/)

# 系统题 leetcode 901. 股票价格跨度

- [点击这里查看题目](https://leetcode.cn/problems/online-stock-span/description/)

# 系统题 leetcode 1603. 设计停车系统

- [点击这里查看题目](https://leetcode.cn/problems/design-parking-system/description/)

