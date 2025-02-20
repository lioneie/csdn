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
bool isSameTree(struct TreeNode* p, struct TreeNode* q) {
    if (p == NULL && q == NULL)
        return true;
    if (p == NULL || q == NULL)
        return false;

    if (p->val != q->val)
        return false;

    return isSameTree(p->left, q->left) && isSameTree(p->right, q->right);
}
```

