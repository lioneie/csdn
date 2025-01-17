# uthash

- [uthash主页](https://troydhanson.github.io/uthash/)
- [uthash github](https://github.com/troydhanson/uthash)
- [uthash的示例](https://gitee.com/chenxiaosonggitee/blog/blob/master/courses/algorithms/src/hash-table/uthash.c)（[头文件`uthash.h`也可点击这里下载](https://gitee.com/chenxiaosonggitee/tmp/blob/master/algorithms/uthash.h)）

注意在leetcode中使用uthash，`struct hash_table *head_table`的定义不能在函数外，必须要函数内，不知道搞什么鬼，这有个屁不同呢。

# leetcode 1. 两数之和

- [点击这里查看题目](https://leetcode.cn/problems/two-sum/description/)

# leetcode 496. 下一个更大元素 I

[点击这里查看“单调栈 + 哈希表”的解法](https://chenxiaosong.com/courses/algorithms/monotonic-stack.html)

# leetcode 217. 存在重复元素

- [点击这里查看题目](https://leetcode.cn/problems/contains-duplicate/description/)

c语言实现:
```c
struct hash_table {
	int key;            /* we'll use this field as the key */
	int value;  // value用不到，可以去掉
	UT_hash_handle hh; /* makes this structure hashable */
};

// 只能放在函数里，放函数外用例失败
// struct hash_table *head_table = NULL;

bool containsDuplicate(int* nums, int numsSize) {
    struct hash_table *head_table = NULL; // 只能放在函数里，放函数外用例失败
    for (int i = 0; i < numsSize; i++) {
        struct hash_table *tmp;
        HASH_FIND_INT(head_table, &nums[i], tmp);
        if (!tmp) {
            tmp = malloc(sizeof(struct hash_table));
            tmp->key = nums[i];
            HASH_ADD_INT(head_table, key, tmp);
        } else {
            return true;
        }
    }
    return false;
}
```