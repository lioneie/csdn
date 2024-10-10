系统调用是用户进程和内核交互的接口，在用户空间进程和硬件设备之间添加一个中间层，系统调用为用户空间提供硬件的抽象接口，以及保证系统的稳定和安全，实现多任务和虚拟内在。

```c
#include <stdio.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <errno.h>

#ifndef __NR_openat_test
#define __NR_openat_test        463
#endif

int main()
{
        int res = syscall(__NR_openat_test, 55);
        printf("result: %d\n", res);

        return 0;
}
```
