# leetcode 208. 实现 Trie (前缀树)

- [点击这里查看题目](https://leetcode.cn/problems/implement-trie-prefix-tree/description/)

前缀树，又称字典树。

c语言实现:
```c
typedef struct Trie { // 这里不能写成 typedef struct {
    struct Trie *children[26]; // 前面的 struct 不能少，否则编译不过
    bool is_end;
} Trie;

Trie* trieCreate() {
    Trie *ret = malloc(sizeof(Trie));
    memset(ret->children, 0, sizeof(ret->children));
    ret->is_end = false;
    return ret;
}

void trieFree(Trie* obj) {
    for (int i = 0; i < 26; i++) {
        if (obj->children[i])
            trieFree(obj->children[i]);
    }
    free(obj);
}

void trieInsert(Trie* obj, char* word) {
    int len = strlen(word);
    for (int i = 0; i < len; i++) {
        int ch = word[i] - 'a';
        if (!obj->children[ch])
            obj->children[ch] = trieCreate();
        obj = obj->children[ch];
    }
    obj->is_end = true;
}

static bool __trie_starts_with(Trie **obj, char *prefix)
{
    int len = strlen(prefix);
    for (int i = 0; i < len; i++) {
        int ch = prefix[i] - 'a';
        if (!(*obj)->children[ch])
            return false;
        *obj = (*obj)->children[ch];
    }
    return true;
}

bool trieStartsWith(Trie* obj, char* prefix) {
    return __trie_starts_with(&obj, prefix);
}

bool trieSearch(Trie* obj, char* word) {
    if (__trie_starts_with(&obj, word))
        return obj->is_end;
    return false;
}

/**
 * Your Trie struct will be instantiated and called as such:
 * Trie* obj = trieCreate();
 * trieInsert(obj, word);
 
 * bool param_2 = trieSearch(obj, word);
 
 * bool param_3 = trieStartsWith(obj, prefix);
 
 * trieFree(obj);
*/
```