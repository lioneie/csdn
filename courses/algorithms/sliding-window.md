# leetcode 219. 存在重复元素 II

- [点击这里查看题目](https://leetcode.cn/problems/contains-duplicate-ii/description/)

c语言实现:
```c
struct hash_table {
    int key;
    int value; // value 用不到
    UT_hash_handle hh; /* makes this structure hashable */
};

// 必须要初始化为NULL，考虑到leetcode c语言实现执行多个用例时全局变量和静态变量只会初始化一次，
// 所以我们就不在这里初始化值，而是放到main()中，
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

bool containsNearbyDuplicate(int* nums, int numsSize, int k) {
    head_table = NULL;
    struct hash_table *tmp;
    struct hash_table *curr, *next;
    for (int i = 0; i < numsSize; i++) {
        if (i > k) {
            // 窗口大小为k，移除掉一个元素
            tmp = uthash_find(nums[i - k - 1]);
            if (tmp)
                uthash_delete(tmp);
        }
        tmp = uthash_find(nums[i]);
        if (tmp)
            return true;
        tmp = malloc(sizeof(struct hash_table));
        tmp->key = nums[i];
        // tmp->value 用不到
        uthash_add(tmp);
    }

    HASH_ITER(hh, head_table, curr, next) {
        uthash_delete(curr);
        free(curr);
    }
    return false;
}
```