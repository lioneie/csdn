# 用户空间接口

Nice值表示进程对其他进程的**友好程度**，nice值越高表示占用cpu越低

Nice值取值范围 0 ~ 39 （对应静态优先级）

```c
int nice(int incr);
```

示例文件[nice.c](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/process/nice.c)。两个进程并行运行，各自增加自己的计数器。父进程使用默认nice值，子进程nice值可选。

`gcc nice.c -o nice` 编译文件

单核cpu系统，运行 `./nice` ，nice值相等，父子进程计数值几乎相等。

单核cpu系统，运行 `./nice 20`,子进程nice值高，子进程的计数值极小。

双核或多核cpu系统，运行 `./nice 20`,子进程nice值高，但父子进程计数值几乎相等。因为父子进程不共享同一cpu，分别在不同cpu上同时运行。

获取和设置进程优先级：

```c
getpriority
setpriority
```

获取和设置进程的调度策略：

```c
sched_setscheduler 
sched_getscheduler
```

获取和设置POSIX线程的调度：

```c
pthread_attr_setschedpolicy
pthread_attr_getschedpolicy
pthread_attr_getschedparam
pthread_attr_setschedparam
pthread_attr_getinheritsched
pthread_attr_setinheritsched
```

# CFS调度

CFS**没有**时间片的概念，也**不是**根据优先级来决定下一个该运行的进程

CFS是通过计算**进程消耗的CPU时间（加权之后）**来确定下一个该运行的进程。从而到达所谓的公平性。

分配给进程的运行时间 = 调度周期 * 进程权重 / 所有进程权重之和

Linux通过引入virtual runtime(vruntime)来实现CFS

实际上vruntime就是根据权重将实际运行时间标准化

谁的vruntime值较小就说明它以前占用cpu的时间较短，受到了“不公平”对待，因此下一个运行进程就是它。这样高nice值的进程能得到迅速响应，低nice值的进程能获取更多的cpu时间。

Linux采用了一颗红黑树（对于多核调度，实际上每一个核有一个自己的红黑树），记录下每一个进程的vruntime

红黑树操作的算法复杂度最大为O(lgn)

请阅读2.6.34内核`kernel/sched_fair.c`中的下列结构体或函数：

调度器实体结构：`struct sched_entity`

虚拟时间记账：`update_curr、__update_curr`

进程选择：`pick_next_entity、enqueuer_entity、dequeuer_entity`

调度器入口：`pick_next_task`
