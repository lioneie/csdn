# 进程

程序是存储在磁盘中，而进程是处于执行期的程序（当然还有相关资源），从内核视角看又叫任务（task）。执行线程，简称线程（thread），是在进程中活动的对象，内核调度的对象是线程，而不是进程。Linux内核不区分线程和进程，线程是特殊的进程。

进程提供两种虚拟机制: 虚拟处理器和虚拟内存。

在调试加打印时，我们经常会使用到`current->comm`和`current->pid`来获取进程名和进程id，其中的`current`宏定义在x86架构的实现如下：
```c
// arch/x86/include/asm/current.h
#define current get_current()

static __always_inline struct task_struct *get_current(void)
{                                                           
        return this_cpu_read_stable(pcpu_hot.current_task); 
}                                                           

struct pcpu_hot {                                                   
        union {                                                     
                struct {                                            
                        struct task_struct      *current_task;
                        ...
                };
                ...                          
        };                                                          
};                                                                  
```

用结构体`struct task_struct`来描述进程，这个结构体很大，请查看<!-- private begin -->`task_struct.c`<!-- private end --><!-- public begin -->[`task_struct.c`](https://gitee.com/chenxiaosonggitee/blog/tree/master/courses/kernel/task_struct.c)<!-- public end -->。

# 进程创建

```c
// kernel/fork.c
SYSCALL_DEFINE0(fork)

/*                                                                      
 * 好的，这是主要的 fork 例程。                                      
 *                                                                      
 * 它复制进程，如果成功则启动它，并在需要时使用虚拟内存等待它完成。
 *                                                                      
 * args->exit_signal 预计由调用者检查其合理性。                      
 */
pid_t kernel_clone(struct kernel_clone_args *args)

// kernel/exit.c
SYSCALL_DEFINE1(exit, int, error_code)

SYSCALL_DEFINE4(wait4, pid_t, upid, int __user *, stat_addr,
                int, options, struct rusage __user *, ru)

/*                                                                         
 * sys_waitpid() 保留用于兼容性。waitpid() 应该通过从 libc.a 调用 sys_wait4() 来实现。
 */                                                                        
SYSCALL_DEFINE3(waitpid, pid_t, pid, int __user *, stat_addr, int, options)
```