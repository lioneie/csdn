# leetcode 21. 合并两个有序链表

- [点击这里查看题目](https://leetcode.cn/problems/merge-two-sorted-lists/description/)

合并过程如下:
```
1 --> 3 --> 5
2 --> 4 --> 6

1 --> ( 3 --> 5
        2 --> 4 --> 6 )
1 --> 2 --> ( 3 --> 5
              4 --> 6 )
1 --> 2 --> 3 --> ( 5
                    4 --> 6 )
1 --> 2 --> 3 --> 4 --> ( 5
                          6 )
1 --> 2 --> 3 --> 4 --> 5 --> ( 6 )
1 --> 2 --> 3 --> 4 --> 5 --> 6
```

c语言实现:
```c
/**
 * Definition for singly-linked list.
 * struct ListNode {
 *     int val;
 *     struct ListNode *next;
 * };
 */
struct ListNode* mergeTwoLists(struct ListNode* list1, struct ListNode* list2) {
    if (!list1)
        return list2;
    if (!list2)
        return list1;
    if (list1->val < list2->val) {
        list1->next = mergeTwoLists(list1->next, list2);
        return list1;
    } else {
        list2->next = mergeTwoLists(list1, list2->next);
        return list2;
    }
}
```

# leetcode 509. 斐波那契数

- [点击这里查看题目](https://leetcode.cn/problems/fibonacci-number/description/)

c语言实现:
```c
int fib(int n) {
    if (n == 0)
        return 0;
    if (n == 1)
        return 1;
    return fib(n - 1) + fib(n - 2);
}
```