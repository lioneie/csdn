# leetcode 409. 最长回文串

- [点击这里查看题目](https://leetcode.cn/problems/longest-palindrome/description/)

c语言实现:
```c
int longestPalindrome(char * s){
    int str_len = strlen(s);
    int ret = 0;
    int char_count[255] = {0}; // 这种方式初始化为0不够保险

    memset(char_count, 0, sizeof(char_count)); // 这种方式初始化为0肯定没问题

    for (int i = 0; i < str_len; i++)
        char_count[s[i]]++;

    for (int i = 0; i < 255; i++) {
        ret += char_count[i] / 2 * 2;
        // 如果出现次数为奇数，且返回值是偶数，则返回值加1
        if (char_count[i] % 2 && ret % 2 == 0)
            ret++;
    }
    return ret;
}
```

