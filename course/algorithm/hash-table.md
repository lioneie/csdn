# uthash

- [uthash主页](https://troydhanson.github.io/uthash/)
- [uthash github](https://github.com/troydhanson/uthash)
- 头文件`uthash.h`: [github](https://github.com/troydhanson/uthash/blob/master/src/uthash.h)，[也可以在github下载](https://gitee.com/chenxiaosonggitee/tmp/blob/master/algorithms/uthash.h)）
- [key为int类型时uthash的示例](https://gitee.com/chenxiaosonggitee/blog/blob/master/course/algorithm/src/hash-table/int-key-uthash.c)
- [key为char指针类型时uthash的示例](https://gitee.com/chenxiaosonggitee/blog/blob/master/course/algorithm/src/hash-table/char-ptr-key-uthash.c)
- [key为char数组类型时uthash的示例](https://gitee.com/chenxiaosonggitee/blog/blob/master/course/algorithm/src/hash-table/char-array-key-uthash.c)

注意在leetcode中使用uthash，`head_table`在每个用例执行时都要初始化为`NULL`，因为全局变量和静态变量的初始化只会执行一次。

# leetcode 1. 两数之和

- [点击这里查看题目](https://leetcode.cn/problems/two-sum/description/)

c语言实现:
```c
struct hash_table {
	int key;
	int value; // value
	UT_hash_handle hh; /* makes this structure hashable */
};

// 必须要初始化为NULL，考虑到leetcode c语言实现执行多个用例时全局变量和静态变量只会初始化一次，
// 所以我们这里就不在这里初始化值，而是放到main()中，
// 防止以后从这里copy代码到leetcode中时用例不通过
static struct hash_table *head_table;

static void uthash_add(struct hash_table *add)
{
	HASH_ADD_INT(head_table, key, add); // 这里的key不是变量，而是结构体成员名
}

static struct hash_table *uthash_find(int key)
{
	struct hash_table *out;

	HASH_FIND_INT(head_table, &key, out); // 这里的key是变量
	return out;
}

static void uthash_delete(struct hash_table *del)
{
	HASH_DEL(head_table, del);
}

/**
 * Note: The returned array must be malloced, assume caller calls free().
 */
int* twoSum(int* nums, int numsSize, int target, int* returnSize) {
    head_table = NULL;
    struct hash_table *tmp;
    for (int i = 0; i < numsSize; i++) {
        tmp = uthash_find(target - nums[i]);
        if (tmp) {
            int *ret = malloc(sizeof(int) * 2);
            ret[0] = tmp->value;
            ret[1] = i;
            *returnSize = 2;
            return ret;
        }
        tmp = malloc(sizeof(struct hash_table));
        tmp->key = nums[i];
        tmp->value = i;
        uthash_add(tmp);
    }
    *returnSize = 0;
    return NULL;
}
```

# leetcode 496. 下一个更大元素 I

[点击这里查看“单调栈 + 哈希表”的解法](https://chenxiaosong.com/course/algorithm/monotonic-stack.html)

# leetcode 217. 存在重复元素

- [点击这里查看题目](https://leetcode.cn/problems/contains-duplicate/description/)

c语言实现:
```c
struct hash_table {
	int key;
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