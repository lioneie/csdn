# 简介

系统调用是用户进程和内核交互的接口，在用户空间进程和硬件设备之间添加一个中间层，系统调用为用户空间提供硬件的抽象接口，以及保证系统的稳定和安全，实现多任务和虚拟内存。

unix接口设计有一句格言“提供机制而不是策略”，系统调用就是提供机制，抽象出了用于完成某种确定目的的函数，至于怎么用这些函数（也就是策略）就不是内核该考虑的了。c库就是负责策略，提供了posix的绝大部分api。

一般情况下，系统调用返回`0`表示成功，负的返回值表示错误，c库会把错误码写入`errno`全局变量，`perror()`会打印出`error`错误的字符串，如以下程序会打印出`Error: No such file or directory`:
```c
#include <stdio.h>

int main ()
{
    FILE *fp;

    fp = fopen("file_not_exist.txt", "r");
    if (fp == NULL) {
        perror("Error"); // 会追加字符串 ": No such file or directory"
        return(-1);
    }
    fclose(fp);

    return(0);
}
```

系统调用声明为`asmlinkage long sys_close(unsigned int fd)`的形式，其中`asmlinkage`限定词是编译指令，通知编译器仅从栈中提取函数参数。
每个系统调用对应一个独一无二的系统调用号，定义在`include/uapi/asm-generic/unistd.h`文件中，存在`sys_call_table[]`数组中，
另外有些体系结构如x86还要在`arch/x86/entry/syscalls/syscall_32.tbl`和`arch/x86/entry/syscalls/syscall_64.tbl`文件中指定。
如果一个系统调用被删除，这个系统调用号也不会回收，而是用以下函数取代:
```c
SYSCALL_DEFINE0(ni_syscall)
{
        return -ENOSYS;
}
```

# 系统调用处理程序

出于系统安全性和稳定性的考虑，用户空间进程无法在内核地址空间上读写。应用程序需要以某种机制通知内核，让内核代表自己执行一个系统调用，这种机制是通过软件中断（又叫编程异常）来实现，
触发异常让系统切换到内核态执行异常处理程序，也就是系统调用处理程序。x86体系结构触发系统调用的软件中断的中断号是`0x80`（10进制`128`），指令是`int $0x80`（或`sysenter`指令）。
x86体系结构下，`arch/x86/kernel/idt.c`文件中的`def_idts[]`数组定义了 Interrupt Descriptor Table（中断描述符表），系统调用的中断号是`IA32_SYSCALL_VECTOR`（`0x80`）。

x86_64体系结构下，代码流程如下:
```c
entry_SYSCALL_64 // arch/x86/entry/entry_64.S
  call    do_syscall_64 // %eax作为第二个参数传入
    do_syscall_x64
      if (unr < NR_syscalls)
      regs->ax = x64_sys_call // 系统调用返回值放在%eax
```

通过`man syscall`命令查看到常用的体系结构系统调用传参使用的寄存器如下:
```sh
Arch/ABI      arg1  arg2  arg3  arg4  arg5  arg6  arg7  Notes
-------------------------------------------------------------
arm64         x0    x1    x2    x3    x4    x5    -
i386          ebx   ecx   edx   esi   edi   ebp   -
riscv         a0    a1    a2    a3    a4    a5    -
x86-64        rdi   rsi   rdx   r10   r8    r9    -
```

# 系统调用的实现

我们通过增加一个新的系统调用的方式来看一下系统调用的代码细节。

## 接口

内核打上补丁
<!-- public begin -->
[`src/0001-add-new-syscall-openat_test.patch`](https://gitee.com/chenxiaosonggitee/blog/blob/master/course/kernel/src/0001-add-new-syscall-openat_test.patch)
<!-- public end -->
<!-- private begin -->
`src/0001-add-new-syscall-openat_test.patch`
<!-- private end -->
，用户态程序如下:
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

## 实现

用户空间与内核空间数据copy用以下函数:
```c
// 从用户空间读取数据，成功返回0，失败返回未完成copy的数据的字节数
unsigned long copy_from_user(void *to, const void __user *from, unsigned long n)
// 向用户空间写入数据，成功返回0，失败返回未完成copy的数据的字节数
unsigned long copy_to_user(void __user *to, const void *from, unsigned long n)
```

检查权限用函数`capable()`，参数传入`CAP_CHOWN`等宏定义。

内核执行系统调用时，处于进程上下文，`current`指针指向触发系统调用的用户态进程。在进程上下文中，可以休眠，可以被其他进程抢占。

