# 进程

## 简介

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

## 进程描述符

用结构体`struct task_struct`来描述进程，这个结构体很大，请查看<!-- private begin -->`task_struct.c`<!-- private end --><!-- public begin -->[`task_struct.c`](https://gitee.com/chenxiaosonggitee/blog/tree/master/courses/kernel/task_struct.c)<!-- public end -->。

其中`__state`可以是以下值，通过`set_current_state(state_value)`来设置：

- `TASK_RUNNING`: 进程可执行，要么正在执行，要么在等待队列中等待执行。
- `TASK_INTERRUPTIBLE`: 进程正在休眠，当某些条件满足时唤醒，接收到信号可被唤醒。
- `TASK_UNINTERRUPTIBLE`: 接收到信号不能唤醒，其他和`TASK_INTERRUPTIBLE`一样。
- `__TASK_STOPPED`: 进程停止执行，没有投入运行也不能投入运行，接收到`SIGSTOP`、`SIGTSTP`、`SIGTTIN`、`SIGTTOU`信号时进入这个状态，在调试期间接收到任何信号也进入这个状态。
- `__TASK_TRACED`: 被其他进程跟踪，如通过`ptrace`调试。

`exit_state`退出状态可以是以下值：

- `EXIT_ZOMBIE`: 进程已经终止，但其状态尚未被父进程读取，进程描述符仍然存在。
- `EXIT_DEAD`: 进程状态已经被读取，系统正在进行最终清理，进程描述符尚未完全释放。
- `EXIT_TRACE`: 进程正在被跟踪（traced）。这通常发生在调试会话中，进程在执行过程中被调试器（如gdb）所跟踪。

用`set_current_state(state_value)`设置进程状态。

在系统启动的最后阶段启动pid这`1`的`init`进程，其他进程都是这个进程的后代，通过`current->parent`获得当前进程的父进程，当前进程的子进程用如下代码遍历：
```c

struct list_head *list;
struct task_struct *child;

list_for_each(list, &current->children) {
        child = list_entry(list, struct task_struct, sibling);
        printk(KERN_INFO "child pid: %d, comm: %s\n", child->pid, child->comm);
}
```

遍历祖先，直到`init`进程：
```c
struct task_struct *task;
for (task = current; task != &init_task; task = task->parent) {
        printk(KERN_INFO "pid: %d, comm: %s\n", task->pid, task->comm);
}
```

从`tasks`成员获取前一个和后一个进程：
```c
list_entry(task->tasks.next, struct task_struct, tasks) // 后一个，next_task(p)宏定义
list_entry(task->tasks.prev, struct task_struct, tasks) // 前一个
```

遍历所有进程用`for_each_process(p)`宏定义，但除非必要，我们不建议这样全部遍历。

## 进程创建和终结

进程的创建包含`fork()`（或`vfork`）和`exec`（`execve()`和`execveat()`）。

其中`fork`相关流程如下：
```c
// kernel/fork.c
fork // 适合大多数创建子进程的场景，尤其是当子进程需要在执行exec()之前做更多操作时（如文件描述符重定向、环境变量设置等）
vfork // 效率高，适用于子进程立即调用exec()替换自身的场景（如执行一个新程序）
clone3
clone
  kernel_clone
    copy_process
      dup_task_struct
```

进程终结时，调用`exit()`系统调用（在`kernel/exit.c`中），进程退出执行后`__state`被设置为`EXIT_ZOMBIE`状态，直到父进程调用`wait4()`和`waitpid()`系统调用查询子进程是否终结，然后进程描述符被释放，`release_task()`被调用。

# 线程

线程是和其他进程共享某些资源（如地址空间等）的进程，