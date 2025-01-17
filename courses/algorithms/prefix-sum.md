# leetcode 303. 区域和检索 - 数组不可变

- [点击这里查看题目](https://leetcode.cn/problems/range-sum-query-immutable/description/)

c语言实现:
```c
typedef struct {
    int *sums;
} NumArray;

NumArray* numArrayCreate(int* nums, int numsSize) {
    NumArray *ret = malloc(sizeof(NumArray));
    ret->sums = malloc(sizeof(int) * (numsSize+1));
    ret->sums[0] = 0;
    for (int i = 1; i < numsSize+1; i++) {
        ret->sums[i] = nums[i-1] + ret->sums[i-1];
    }
    return ret;
}

int numArraySumRange(NumArray* obj, int left, int right) {
    return obj->sums[right+1] - obj->sums[left];
}

void numArrayFree(NumArray* obj) {
    free(obj->sums);
    free(obj);
}

/**
 * Your NumArray struct will be instantiated and called as such:
 * NumArray* obj = numArrayCreate(nums, numsSize);
 * int param_1 = numArraySumRange(obj, left, right);
 
 * numArrayFree(obj);
*/
```

# leetcode 1893. 检查是否区域内所有整数都被覆盖

- [点击这里查看题目](https://leetcode.cn/problems/check-if-all-the-integers-in-a-range-are-covered/description/)

[leetcode官方答案](https://leetcode.cn/problems/check-if-all-the-integers-in-a-range-are-covered/solutions/825466/jian-cha-shi-fou-qu-yu-nei-suo-you-zheng-5hib/)加注释:
```c
// ranges = [[1,2],[4,7],[8,9]], rangesSize=3, rangesColSize=2, left = 2, right = 5
// ranges[i] = [start[i], end[i]]
bool isCovered(int** ranges, int rangesSize, int* rangesColSize, int left, int right) {
    // diff[i] 表示: (覆盖整数 i 的区间数量) - (覆盖 i−1 的区间数量)
    int diff[52];  // 差分数组
    memset(diff, 0, sizeof(diff));
    // diff[1] = 1, diff[2] = 0, diff[3] = -1
    // diff[4] = 1, diff[5] = 0, diff[6] = 0, diff[7] = 0, diff[8] = -1
    // diff[8] = 0, diff[9] = -1
    for (int i = 0; i < rangesSize; i++) {
        // 注意每个ranges[i]只有两个元素
        ++diff[ranges[i][0]]; // diff[start] + 1
        --diff[ranges[i][1] + 1]; // diff[end+1] - 1
    }
    // 前缀和
    int curr = 0;
    // i = 1: curr = 1
    // i = 2: curr = 1
    // i = 3: curr = 0 // 3就不在区间里，因为满足条件curr <= 0
    // i = 4: curr = 1
    for (int i = 1; i <= 50; ++i) {
        curr += diff[i];
        if (i >= left && i <= right && curr <= 0) {
            return false;
        }
    }
    return true;
}
```

