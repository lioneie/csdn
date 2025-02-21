# 快速排序

《算法导论》书中的第95页。时间复杂度O(nlgn)，空间复杂度O(lgn)。

[快速排序源码](https://gitee.com/chenxiaosonggitee/blog/blob/master/course/algorithm/src/sort/quick-sort.c)

[c语言快速排序的库函数用法](https://www.runoob.com/cprogramming/c-function-qsort.html)，[测试程序请点击这里](https://gitee.com/chenxiaosonggitee/blog/blob/master/course/algorithm/src/sort/clib-qsort.c)。函数原型:
```c
// compar(a, b):
//   return *a - *b: 升序
//   return *b - *a: 降序
void qsort(void *base, size_t nitems, size_t size, int (*compar)(const void *, const void *));
```

# 归并排序

《算法导论》书中的第17页。时间复杂度O(nlgn)，空间复杂度O(n)。

[归并排序源码](https://gitee.com/chenxiaosonggitee/blog/blob/master/course/algorithm/src/sort/merge-sort.c)

# 堆排序

[点击这里查看“堆（优先队列）”](https://chenxiaosong.com/course/algorithm/heap-priority-queue.html)

# leetcode 217. 存在重复元素

- [点击这里查看题目](https://leetcode.cn/problems/contains-duplicate/description/)

这个题目主要是熟悉一下c语言快速排序的库函数`qsort()`的用法，

c语言实现:
```c
int cmp(const void *a, const void *b)
{
    return *(int *)a - *(int *)b;
}

bool containsDuplicate(int* nums, int numsSize) {
    qsort(nums, numsSize, sizeof(int), cmp);
    for (int i = 1; i < numsSize; i++) {
        if (nums[i] == nums[i - 1])
            return true;
    }
    return false;
}
```

