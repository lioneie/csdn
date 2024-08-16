<!--
https://mp.weixin.qq.com/mp/homepage?__biz=MzI3NzA5MzUxNA==&hid=14&sn=a7deb8f4a4986e1d148671008bd1403c&scene=18&devicetype=android-31&version=28003255&lang=zh_CN&nettype=WIFI&ascene=0&pass_ticket=g0mPh534tJrl5gE9tLzM6LyENbehF%2BgNRmGTYAX3oL7VjrmEIkVz7S1FaWrX92H9&wx_header=3&scene=1
-->

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

进程退出执行后`__state`被设置为`EXIT_ZOMBIE`状态，直到父进程调用`wait4()`和`waitpid()`系统调用查询子进程是否终结（用户态程序调用`wait()`或`pthread_join()`），然后进程描述符被释放，`release_task()`被调用:
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

一个多线程的程序，所有线程形成一个线程组，线程组中的第一个线程为线程组的pid，　这个第一个线程叫主线程，也就是调用`pthread_create()`的线程，`struct task_struct`中的`tgid`表示线程组中主线程的pid，`getpid()`系统调用获得的就是这个值。

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

## 简介

process scheduler，简称为scheduler，翻译为进程调度器，有些中文书籍也翻译为进程调度程序，简称调度程序，注意这里的"程序"不是前面我们讲的能用`ps`命令查看的"进程"（所以"进程调度程序"这个翻译不好），而是内核的一个核心功能，直接集成在内核代码中。

抢占式多任务（preemptive multitasking）模式，是由调试器来决定什么时候挂起一个进程，以便其他进程能够有运行的机会，这个强制的挂起动作就叫"抢占"（preemption）。有些调度算法中，进程在被抢占之前能够运行的时间片（timeslice）是预先设置好的，但CFS调度算法没有采用时间片来达到公平调度。

非抢占式多任务（cooperative multitasking）模式，除非进程主动停止运行，否则会一直执行，进程主动挂起自己的操作叫yielding，翻译为让出（cpu）或让步，可能出现不让出cpu的进程，绝大部分操作系统都采用了抢占式多任务。

进程分为I/O消耗型和处理器消耗型。I/O消耗型进程大部分时间都在提交I/O请求或等待I/O请求（如键盘输入、网络I/O等），经常处于可运行状态，但运行时间很短。处理器消耗型进程刚好相反，大部分时间都在执行代码，没有被抢占就一直运行，不经常运行，但一旦运行时间比较长，如执行大量数学计算的程序。当然，也可能出现某个程序在不同时间段属于不同类型的情况。

Linux采用两种优先级范围：

- nice值: -20 ~ +19，默认为0，nice代表对其他进程的友好程度，nice值越高优先级越低，有些操作系统的nice值代表分配给进程的时间片的绝对值，Linux内核的nice值代表时间片的比例。使用命令`ps -el`输出的`NI`一列就是nice值。
- 实时优先级: 0 ~ 99，任何实时进程的优先级都高于普通进程，实时优先级与nice优先级处于互不相交的两个范畴。使用命令`ps -eo state,uid,pid,ppid,rtprio,time,comm`输出的`RTPRIO`一列就是实时优先级，如果是`-`就代表不是实时进程。

timeslice，翻译为"时间片"（在其他系统上又称为quantum或processor slice），是进程被抢占前能持续运行的时间。时间片的长短会影响系统性能，太长交互表现差，太短又会导致进程切换的开销大。后面要介绍Linux内核现在使用的CFS调度器没有直接给进程分配时间片，而是取决于进程消耗了多少处理器使用比。

## 用户空间接口

nice值表示进程对其他进程的**友好程度**，nice值越高表示占用cpu越低。

nice值取值范围 0 ~ 39 （对应静态优先级）。

```c
int nice(int incr)
```

这个接口是直接调用nice系统调用:
```c
SYSCALL_DEFINE1(nice, int, increment)
```

示例文件<!-- public begin -->[`nice.c`](https://gitee.com/chenxiaosonggitee/blog/blob/master/courses/kernel/nice.c)<!-- public end --><!-- private begin -->`nice.c`<!-- private end -->。两个进程并行运行，各自增加自己的计数器。父进程使用默认nice值，子进程nice值可选。

`gcc nice.c -o nice` 编译文件。

- 单核cpu系统，运行 `./nice` ，nice值相等，父子进程计数值几乎相等。
- 单核cpu系统，运行 `./nice 20`，子进程nice值高，子进程的计数值极小。
- 双核或多核cpu系统，运行 `./nice 20`，子进程nice值高，但父子进程计数值几乎相等。因为父子进程不共享同一cpu，分别在不同cpu上同时运行。


`/usr/include/pthread.h`或`/usr/aarch64-linux-gnu/include/pthread.h`头文件中POSIX线程调度相关的函数：

```c
pthread_attr_setschedpolicy
pthread_attr_getschedpolicy
pthread_attr_getschedparam
pthread_attr_setschedparam
pthread_attr_getinheritsched
pthread_attr_setinheritsched
```

再列出一些调度相关的库函数，也是直接调用同名的系统调用:

- `getpriority`: 获取进程优先级
- `setpriority`: 设置进程优先级
- `sched_getscheduler`: 获取进程的调度策略
- `sched_setscheduler`: 设置进程的调度策略
- `sched_getparam`: 获取实时优先级
- `sched_setparam`: 设置实时优先级
- `sched_get_priority_max`: 获取实时优先级的最大值
- `sched_get_priority_min`: 获取实时优先级的最小值
- `sched_rr_get_interval`: 获取进程的时间片值
- `sched_setaffinity`: 设置处理器亲和力
- `sched_getaffinity`: 获取处理器亲和力
- `sched_yield`: 暂时让出处理器

## 调度策略

`struct task_struct`中的`policy`表示调度策略。

```c
/*
 * 调度策略
 */
#define SCHED_NORMAL            0    // 普通调度策略，如CFS以及被淘汰的O(n)和O(1)
#define SCHED_FIFO              1    // 先入先出调度策略，运行时间比较短的进程
#define SCHED_RR                2    // 轮转调度策略，运行时间比较长的进程
#define SCHED_BATCH             3    // 批处理调度策略，cpu消耗型进程
/* SCHED_ISO: 保留但尚未实现 */
#define SCHED_IDLE              5    // 空闲调度策略，极低优先级的后台进程
#define SCHED_DEADLINE          6    // 截止期限调度策略
```

调试策略的具体实现用`struct sched_class`表示，可以查看宏定义`DEFINE_SCHED_CLASS`的引用。

比较重要的数据结构还有`struct rq`（管理可运行状态进程，表示一个可运行队列，也就是就绪队列）和`struct sched_entity`（调度器中调度实体）。
<!--
/*
 * 这是主要的、每个CPU对应的运行队列数据结构。
 *
 * 锁定规则：那些需要锁定多个运行队列的地方（例如负载均衡或线程迁移代码），
 * 锁的获取操作必须按 &runqueue 的地址升序进行。
 */
struct rq {
-->

CFS相关的函数流程如下：
```c
schedule
  __schedule
    pick_next_task
      __pick_next_task
        __pick_next_task_fair // class->pick_next_task
    context_switch
```

`set_tsk_need_resched()`、`clear_tsk_need_resched()`、`test_tsk_need_resched()`分别用于设置、清除、检查是否需要重新执行一次调度。

内核即将返回用户空间时（从系统调用返回或中断处理程序返回）会发生用户抢占。Linux内核支持内核抢占，只要没有持有锁，内核就可以抢占，也就是调度器可以挂起一个内核线程。

Linux内核有两种实时调度策略: `SCHED_FIFO`和`SCHED_RR`，这两种调度策略的进程比`SCHED_NORMAL`的进程优先级更高。`SCHED_RR`是带有时间片的`SCHED_FIFO`。这两种实时调度器使用静态优先级，高优先级的实时进程总能抢占低优先级进程。Linux内核是软实时，内核调度进程，尽力使进程在限定时间到来前运行，但不保证总能满足这些进程的要求，对于实时任务的调度不做任何保证，但性能还是不错的。实时优先级范围是`0 ~ MAX_RT_PRIO-1`，而`SCHED_NORMAL`进程的范围是`MAX_RT_PRIO ~ MAX_RT_PRIO+40`（对应`-20 ~ +19`的nice值）。

## O(n)和O(1)调度器

<!--
**静态优先级**（100 ~ 139）

静态优先级<120，基本时间片=max((140-静态优先级)*20, MIN_TIMESLICE)

静态优先级>=120，基本时间片=max((140-静态优先级)*5, MIN_TIMESLICE)

**动态优先级**=max(100 , min(静态优先级 - bonus + 5) , 139))，I/O消耗型进程bonus为正
-->

**内核2.4**版本的简陋的**O(n)**调度算法,进程数量多时，调度效率非常低：

```c
for (系统中的每个进程) {
	重新计算时间片;
	重新计算优先级;
}
```

**内核2.5**版本引入的O(1)调度现在已经被CFS调度取代，但作为一个经典的调度算法，非常值得介绍，其他改进的调度算法都是基于O(1)调度算法。

```c
struct {
  struct prio_array 活跃进程集合，时间片未用完
  struct prio_array 过期进程集合，已经用完时间片
} 可运行队列;

struct {
  进程个数;
  uint32_t 位图[5]; //160位，前140位有用，每一位代表对应的进程链表是否存在进程
  进程链表[140]; //对应动态优先级0~139
} prio_array; // 优先级数组
```

进程从活跃数组移动到过期数组前，已经重新计算好了时间片，本质就是采用**分散计算时间片**的方法。当活跃进程数组中没有进程时，只需要交换两个数组的指针，原来的过期数组变为活跃数组。因此只需要**依次遍历**位图的第一位，找到第一个置位，对应的进程链表上的所有进程都是优先级最高的，选取链表头的进程来执行即可。

<!--
请阅读2.6.11内核`linux/kernel/sched.c`中的下列函数：

时间片分配：`task_timeslice`

运行队列操作：`enqueque_task、dequeque_task`

更新时间片：`schedule_tick`
-->

# 完全公平调度器

Completely Fair Scheduler，翻译为"完全公平调度器"，缩写为CFS。参考了康恩·科里瓦斯所开发的楼梯调度算法（staircase scheduler）与RSDL（反转楼梯最后期限调度算法，The Rotating Staircase Deadline Schedule）的经验。

O(1)调度算法在进程数量不是很多在情况下（几十个）表现出近乎完美的性能。但程序数量更多时，或对响应时间敏感的程序（如需要用户交互的桌面应用），却有一些先天不足。在2.6.23版本中引入了CFS，取代了O(1)调试器。

前面我们说过，CFS下进程是否投入运行取决于处理器时间使用比。我们看一个例子，在只有一个cpu的电脑上，系统运行了2个进程，一个是vim（I/O消耗型），一个是gcc（处理器消耗型），如果nice值相同，CFS承诺给这两个进程各50%的cpu使用比，但vim更多的时间在等待用户输入，所以vim肯定用不到50%的cpu使用比，而gcc肯定用到超过50%的cpu使用比。所以，当我们输入字符唤醒vim时，CFS发现vim的cpu使用更少，所以想兑现完全公平的承诺，立刻抢占gcc，让vim投入运行，我们输入完字符后，vim却还是不贪心只使用了一丢丢cpu就继续睡了。

进程所获得的处理器时间由这个进程和所有可运行进程nice值的相对差值决定的，nice值对应的是处理器使用比。

具体代码实现请查看`DEFINE_SCHED_CLASS(fair)`。

## 时间记账

`struct task_struct`中有一个`struct sched_entity`类型的成员`se`。`struct sched_entity`的`vruntime`变量表示进程的虚拟运行时间（virtual runtime），这个值的计算是经过了所有可运行进程总数的标准化（被加权），可以帮助逼近CFS模型所追求的"理想多任务处理器"。

函数调用流程如下：
```c
update_process_times
  scheduler_tick
    task_tick_fair
      entity_tick
        update_curr
          curr->vruntime += calc_delta_fair
```

## 进程选择

CFS选择下一个运行进程时，会选择虚拟运行时间最小的进程。CFS使用红黑树来管理可运行进程队列，挑选下一个任务的流程如下：
```c
schedule
  __schedule
    pick_next_task
      __pick_next_task
        __pick_next_task_fair
          pick_next_task_fair
            pick_next_entity
              pick_eevdf
                __pick_eevdf
```

向红黑树中加入进程发生在进程变为可运行状态（被唤醒）或创建进程时，流程如下：
```c
activate_task
  enqueue_task
    enqueue_task_fair
      enqueue_entity
        __enqueue_entity
          rb_add_augmented_cached
            rb_insert_augmented_cached
              // 维护一个缓存，存放最左叶子节点
              root->rb_leftmost = node
```

从红黑树中删除进程发生在进程变为不可进行或进程终结时，流程如下：
```c
pick_next_task_fair
  set_next_entity
    __dequeue_entity
```

## 休眠和唤醒

内核用`wait_queue_entry`表示等待队列，静态创建可以用`DECLARE_WAITQUEUE()`，动态创建可以用`init_waitqueue_head()`。

休眠操作如下：
```c
// wq 是等待队列
DEFINE_WAIT(wait); // 或者用 init_wait()
add_wait_queue(&wq, &wait); // 在其他地方用 wake_up()唤醒
while (!condition) // condition是等待的事件
        prepare_to_wait(&wq, &wait, TASK_INTERRUPTIBLE);
        if (signal_pending(current)) {
                // 处理信号
        }
        schedule();
}
finish_wait(&wq, &wait);
```

`inotify_read()`函数中相关代码:
```c
DEFINE_WAIT_FUNC(wait, woken_wake_function);
add_wait_queue(&group->notification_waitq, &wait);
while (1) {
        if (signal_pending(current))
                break;
        wait_woken(&wait, TASK_INTERRUPTIBLE, MAX_SCHEDULE_TIMEOUT);
}
remove_wait_queue(&group->notification_waitq, &wait);
```

用`wake_up(struct wait_queue_head *wq_head)`唤醒。

## 多处理器系统中的运行队列平衡

多处理器机器有以下几种类型:

- 标准的多处理器体系结构: RAM芯片集被所有cpu共享。
- 超线程: intel发明的，当前线程在访问内存的间隙，处理器可以使用它的机器周期支执行另一个线程。一个超线程的物理cpu可以被Linux看作几个不同的逻辑cpu。
- NUMA: Non-Uniform Memory Access，非统一内存访问，把cpu和RAM以本地"节点"为单位分组。当cpu访问与它在同一个节点中的"本地"RAM，几乎没有竞争，访问非常快。

可以使用`lscpu`命令查看，`Thread(s) per core`代表每个核心的线程数，如果大于1，说明启用了超线程；`NUMA node(s)`表示NUMA节点的数量，如果只有一个节点，则表明不是NUMA架构，内存是所有CPU共享的。

`schedule()`函数从本地cpu运行队列中挑选进程运行，每个cpu有自己的运行队列，一个可运行进程只在一个队列中。

"调度域"（scheduling domain），是一个cpu集合，采取分层组织形式，最上层调度域（所有cpu）包括多个子调度域，子调度域包括一个cpu子集。底层某个调度域（基本调度域）的某个组的总工作量远远低于同一个调度域的另一个组时，开始迁移进程。调度域用`struct sched_domain`表示，调度域中的组用`struct sched_group`表示。相关函数请查看`run_rebalance_domains()`。