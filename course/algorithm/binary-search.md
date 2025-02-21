# leetcode 69. x 的平方根

- [点击这里查看题目](https://leetcode.cn/problems/sqrtx/description/)

c语言实现:
```c
int mySqrt(int x)
{
    int small = 0;
    int big = x;
    int ret = -1;
    while (small <= big) {
        int mid = (small+big)/2;
        if ((long long)mid * mid <= x) {
            ret = mid;
            small = mid+1;
        } else {
            big = mid-1;
        }
    }
    return ret;
}
```

