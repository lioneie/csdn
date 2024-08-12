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
- `EXIT_DEAD`: 进程状态已经被父进程读取，系统正在进行最终清理，进程描述符尚未完全释放。
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
// fork()适合大多数创建子进程的场景，尤其是当子进程需要在执行exec()之前做更多操作时（如文件描述符重定向、环境变量设置等）
// 会为子进程分配一个新的地址空间，并将父进程的地址空间内容复制到子进程中
// 这个复制过程称为写时复制（Copy-On-Write, COW），即在父子进程之间共享相同的内存页，只有当父或子进程尝试修改某个页时，才会实际进行内存复制
fork
// vfork() 不会为子进程复制父进程的地址空间
// 效率高，适用于子进程立即调用exec()替换自身的场景（如执行一个新程序）
// 父进程会被挂起（即不能执行任何操作），直到调用 exec()，以防止父子进程之间发生竞争条件或冲突
vfork
clone3
clone
  kernel_clone
    copy_process
      dup_task_struct
```

进程终结时，调用`exit()`系统调用（在`kernel/exit.c`中）:
```c
exit
  do_exit
    exit_notify
      forget_original_parent
        exit_ptrace
        find_new_reaper
          if (reaper == &init_task) // 进程所在的线程组内如果没有其他进程，则返回init进程
```

进程退出执行后`__state`被设置为`EXIT_ZOMBIE`状态，直到父进程调用`wait4()`和`waitpid()`系统调用查询子进程是否终结，然后进程描述符被释放，`release_task()`被调用:
```c
wait4
waitpid
  kernel_wait4
    do_wait
      do_wait_thread
        wait_consider_task
          wait_task_zombie
            if (state == EXIT_DEAD)
            release_task
```

# 线程

## 创建线程

线程是和其他进程共享某些资源（如地址空间等）的进程，创建线程：
```c
// 共享: 地址空间、文件系统资源、文件描述符、信号处理程序
clone(CLONE_VM | CLONE_FS | CLONE_FILES | CLONE_SIGHAND, 0)
```

`clone`系统调用的参数`clone_flags`可以是如下值的组合:
```c
/*
 * cloning flags:
 */
#define CSIGNAL		0x000000ff	/* 在退出时要发送的信号掩码 */
#define CLONE_VM	0x00000100	/* 设置此标志时，进程之间共享虚拟内存（VM） */
#define CLONE_FS	0x00000200	/* 设置此标志时，进程之间共享文件系统信息 */
#define CLONE_FILES	0x00000400	/* 设置此标志时，进程之间共享已打开的文件 */
#define CLONE_SIGHAND	0x00000800	/* 设置此标志时，进程之间共享信号处理程序和被阻塞的信号 */
#define CLONE_PIDFD	0x00001000	/* 设置此标志时，在父进程中创建一个 pidfd */
#define CLONE_PTRACE	0x00002000	/* 设置此标志时，允许对子进程的跟踪继续 */
#define CLONE_VFORK	0x00004000	/* 设置此标志时，子进程在释放内存管理器（mm_release）时唤醒父进程 */
#define CLONE_PARENT	0x00008000	/* 设置此标志时，子进程与克隆进程拥有相同的父进程 */
#define CLONE_THREAD	0x00010000	/* 同一线程组？ */
#define CLONE_NEWNS	0x00020000	/* 新的挂载命名空间组 */
#define CLONE_SYSVSEM	0x00040000	/* 共享 System V 的 SEM_UNDO 语义 */
#define CLONE_SETTLS	0x00080000	/* 为子进程创建新的 TLS */
#define CLONE_PARENT_SETTID	0x00100000	/* 在父进程中设置 TID */
#define CLONE_CHILD_CLEARTID	0x00200000	/* 在子进程中清除 TID */
#define CLONE_DETACHED		0x00400000	/* 未使用，忽略 */
#define CLONE_UNTRACED		0x00800000	/* 设置此标志时，跟踪进程不能强制对子进程使用 CLONE_PTRACE */
#define CLONE_CHILD_SETTID	0x01000000	/* 在子进程中设置 TID */
#define CLONE_NEWCGROUP		0x02000000	/* 新的 cgroup 命名空间 */
#define CLONE_NEWUTS		0x04000000	/* 新的 UTS 命名空间 */
#define CLONE_NEWIPC		0x08000000	/* 新的 IPC 命名空间 */
#define CLONE_NEWUSER		0x10000000	/* 新的用户命名空间 */
#define CLONE_NEWPID		0x20000000	/* 新的 PID 命名空间 */
#define CLONE_NEWNET		0x40000000	/* 新的网络命名空间 */
#define CLONE_IO		0x80000000	/* 克隆 IO 上下文 */

/* clone3() 系统调用的标志。 */
#define CLONE_CLEAR_SIGHAND 0x100000000ULL /* 清除任何信号处理程序并重置为 SIG_DFL。 */
#define CLONE_INTO_CGROUP 0x200000000ULL /* 在具有相应权限的情况下克隆到特定的 cgroup 中。 */

/*
 * 克隆标志与 CSIGNAL 交叉，因此只能与 unshare 和 clone3 系统调用一起使用：
 */
#define CLONE_NEWTIME	0x00000080	/* 新的时间命名空间 */
```

## 内核线程

独立运行在内核空间的进程叫内核线程（kernel thread），和普通的用户进程的区别是没有独立的地址空间，也就是`task_struct`中的`mm`成员设置为`NULL`（可使用前一个用户空间进程的`mm`，用`active_mm`指向），所有内核线程都是`kthreadd`内核线程的后代。

创建新的内核线程：
```c
/**
 * kthread_create - 在当前节点上创建一个内核线程，处于不可运行状态，要通过wake_up_process()唤醒
 * @threadfn: 要在线程中运行的函数
 * @data: 传递给 @threadfn() 的数据指针
 * @namefmt: 用于线程名称的 printf 风格格式字符串
 * @arg: 用于 @namefmt 的参数
 *
 * 该宏将在当前节点上创建一个内核线程，并将其置于停止状态。
 * 这只是 kthread_create_on_node() 的一个辅助函数；
 * 详细信息请参见 kthread_create_on_node() 的文档。
 */
#define kthread_create(threadfn, data, namefmt, arg...) \                   
        kthread_create_on_node(threadfn, data, NUMA_NO_NODE, namefmt, ##arg)

/**
 * wake_up_process - 唤醒特定进程，唤醒kthread_create()创建的内核线程
 * @p: 要唤醒的进程
 *
 * 尝试唤醒指定的进程，并将其移到可运行进程集合中。
 *
 * 返回值: 如果进程被唤醒则返回 1，如果进程已经在运行则返回 0。
 *
 * 该函数在访问任务状态之前执行一个完整的内存屏障。
 */
int wake_up_process(struct task_struct *p)
```

也可以调用以下函数创建内核线程并立刻运行：
```c
/**
 * kthread_run - 创建并唤醒一个线程。简单的调用了kthread_create()和wake_up_process()
 * @threadfn: 要运行的函数，直到 signal_pending(current) 为止。
 * @data: 传递给 @threadfn 的数据指针。
 * @namefmt: 线程名称的 printf 风格格式。
 *
 * 描述: 这是 kthread_create() 后紧跟 wake_up_process() 的便捷包装。
 * 返回值: 返回创建的内核线程指针或 ERR_PTR(-ENOMEM)。
 */
#define kthread_run(threadfn, data, namefmt, ...)
```

`threadfn()`一直运行直到调用`do_exit()`退出，或内核其他部分调用以下函数退出：
```c
/**
 * kthread_stop - 停止由 kthread_create() 创建的线程。
 * @k: 由 kthread_create() 创建的线程。
 *
 * 设置 @k 线程的 kthread_should_stop() 返回 true，唤醒它，并等待其退出。
 * 这也可以在 kthread_create() 之后调用，而不是调用 wake_up_process()：
 * 线程将会退出而不调用 threadfn()。
 *
 * 如果 threadfn() 可能会自己调用 kthread_exit()，则调用者必须确保
 * task_struct 不会被释放。
 *
 * 返回值: 返回 threadfn() 的结果，如果从未调用过 wake_up_process()，
 * 则返回 %-EINTR。
 */
int kthread_stop(struct task_struct *k)
```

# 进程调度

## 多任务

process scheduler，简称为scheduler，翻译为进程调度器，有些中文书籍也翻译为进程调度程序，简称调度程序，注意这里的"程序"不是前面我们讲的能用`ps`命令查看的"进程"（所以"进程调度程序"这个翻译不好），而是内核的一个核心功能，直接集成在内核代码中。

抢占式多任务（preemptive multitasking）模式，是由调试器来决定什么时候挂起一个进程，以便其他进程能够有运行的机会，这个强制的挂起动作就叫"抢占"（preemption）。有些调度算法中，进程在被抢占之前能够运行的时间片（timeslice）是预先设置好的，但CFS调度算法没有采用时间片来达到公平调度。

非抢占式多任务（cooperative multitasking）模式，除非进程主动停止运行，否则会一直执行，进程主动挂起自己的操作叫yielding，翻译为让出（cpu）或让步，可能出现不让出cpu的进程，绝大部分操作系统都采用了抢占式多任务。

## O(n)和O(1)调度算法

**内核2.4**版本的简陋的**O(n)**调度算法,进程数量多时，调度效率非常低：

```c
for (系统中的每个进程) {
	重新计算时间片;
	重新计算优先级;
}
```

**内核2.5**版本引入的O(1)调度现在已经被CFS调度取代，但作为一个经典的调度算法，非常值得介绍，其他改进的调度算法都是基于O(1)调度算法。

```c
struct{
	struct prio_array 活跃进程集合;
	struct prio_array 过期进程集合;
}可运行队列;

struct{ //优先级数组
	进程个数;
	uint32_t 位图[5]; //160位，前140位有用
	进程链表[140]; //对应优先级0~139
}prio_array;
```

2个优先级数组prio_array分别表示**活跃进程集合**和**过期进程集合**

过期数组进程已经用完时间片，而活跃数组进程时间片未用完

进程从活跃数组移动到过期数组前，已经重新计算好了时间片

本质就是采用**分散计算时间片**的方法

当活跃进程数组中没有进程时，只需要交换两个数组的指针，原来的过期数组变为活跃数组

**位图**（第0位~139位）中的每一位代表对应的**进程链表**是否存在进程

因此只需要**依次遍历**位图的第一位，找到第一个置位，对应的进程链表上的所有进程都是优先级最高的，选取链表头的进程来执行即可。

O(1)调度算法在进程数量不是很多在情况下（几十个）表现出近乎完美的性能。但程序数量更多时，或对响应时间敏感的程序（如需要用户交互的桌面应用），却有一些先天不足

<!--
请阅读2.6.11内核`linux/kernel/sched.c`中的下列函数：

时间片分配：`task_timeslice`

运行队列操作：`enqueque_task、dequeque_task`

更新时间片：`schedule_tick`
-->