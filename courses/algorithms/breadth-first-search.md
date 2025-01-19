# leetcode 100. 相同的树

- [点击这里查看题目](https://leetcode.cn/problems/same-tree/description/)

c语言实现:
```c
/**
 * Definition for a binary tree node.
 * struct TreeNode {
 *     int val;
 *     struct TreeNode *left;
 *     struct TreeNode *right;
 * };
 */

bool isSameTree(struct TreeNode* p, struct TreeNode* q){
    // head 左边，tail 右边
    int head1 = 0, tail1 = 0;
    int head2 = 0, tail2 = 0;
    // 两棵树上的节点数目都在范围 [0, 100] 内
    struct TreeNode *que1[101];
    struct TreeNode *que2[101];

    if (p == NULL && q == NULL)
        return true;
    else if (p == NULL || q == NULL)
        return false;
    que1[tail1++] = p;
    que2[tail2++] = q;

    while (head1 < tail1 && head2 < tail2) {
        struct TreeNode *node1 = que1[head1++];
        struct TreeNode *node2 = que2[head2++];
        if (node1->val != node2->val)
            return false;
        struct TreeNode *left1 = node1->left;
        struct TreeNode *right1 = node1->right;
        struct TreeNode *left2 = node2->left;
        struct TreeNode *right2 = node2->right;

        if ((left1 == NULL) ^ (left2 == NULL))
            return false;
        if ((right1 == NULL) ^ (right2 == NULL))
            return false;

        if (left1)
            que1[tail1++] = left1;
        if (right1)
            que1[tail1++] = right1;
        if (left2)
            que2[tail2++] = left2;
        if (right2)
            que2[tail2++] = right2;
    }
    return head1 == tail1 && head2 == tail2;
}
```

