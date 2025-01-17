# leetcode 496. 下一个更大元素 I

- [点击这里查看题目](https://leetcode.cn/problems/next-greater-element-i/description/)

```c
struct hash_table {
	int key;            /* we'll use this field as the key */
	int value;
	UT_hash_handle hh; /* makes this structure hashable */
};

// TODO: 把head_table传入函数中，或把head_table声明成全局变量，都无法通过全部用例，为什么？
/*
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
*/

/**
 * Note: The returned array must be malloced, assume caller calls free().
 */
int* nextGreaterElement(int* nums1, int nums1Size, int* nums2, int nums2Size, int* returnSize){
    struct hash_table *head_table = NULL;
    int *res = malloc(sizeof(int) * nums1Size);
    int stack_array[nums2Size];
    int top_idx = -1;
    struct hash_table *tmp;
    for (int i = nums2Size-1; i >= 0; i--) {
        int num = nums2[i];
        tmp = malloc(sizeof(struct hash_table));
        while (top_idx >= 0 && num >= stack_array[top_idx]) {
            top_idx--;
        }
        tmp->key = num;
        tmp->value = (top_idx >= 0) ? stack_array[top_idx] : -1;
        // TODO: 使用uthash_add()无法通过全部用例
        HASH_ADD_INT(head_table, key, tmp);
        stack_array[++top_idx] = num;
    }
    for (int i = 0; i <= top_idx; i++) {
        printf(" %d", stack_array[i]);
    }
    for (int i = 0; i < nums1Size; i++) {
        // TODO: 使用uthash_find()无法通过全部用例
        HASH_FIND_INT(head_table, &nums1[i], tmp);
        res[i] = tmp->value;
    }
    *returnSize = nums1Size;
    return res;
}
```

