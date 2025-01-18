# leetcode 1863. 找出所有子集的异或总和再求和

- [点击这里查看题目](https://leetcode.cn/problems/sum-of-all-subset-xor-totals/description/)

c语言实现:
```c
static int *g_nums;
static int g_sum; // 不能在这里初始化为0，否则用例失败，只能在函数中赋值
static int g_nums_size;

static void backtrack(int value, int index)
{
    if (index == g_nums_size) {
        g_sum += value;
    } else {
        backtrack(value, index + 1);
        backtrack(value ^ g_nums[index], index + 1);
    }
}

int subsetXORSum(int* nums, int numsSize) {
    g_nums = nums;
    g_nums_size = numsSize;
    g_sum = 0; // 只能在函数中赋值，只在全局变量初始化的时候赋值用例失败
    backtrack(g_sum, 0);
    return g_sum;
}
```

