本文章是从以前在海康威视做LoRaWAN研发时给同事分享的ppt内容整理而来，只是对linux进程调度的知识做一个概述，内容也有待补充和修改。

后续会再针对里面的某些知识点专门写一些文章。

# 简介

> 本文章的内容绝大多取材于以下几本书：
>
> Linux内核设计与实现-原书第3版 -- （美）Robert Love 著   陈莉君   康华   译
>
> 深入Linux内核-第3版 -- DANIEL P.BOVET & MARCO CESATI 著   陈莉君 张琼声  张宏伟 译
>
> Unix环境高级编程（第3版）-- [美] W.Richard Stevens & Stephen A.Rago 著  戚正伟 张亚英 尤晋元 译
>
> Linux程序设计 第4版 -- [英] Neil Matthew & Richard Stones 著   陈健  宋健建 译

操作系统 == 大型工厂

进程 == 生产线

线程 == 小的生产线

在内核中，进程、线程（线程是特殊的进程） **统一调度**

**I/O消耗型进程**：频繁使用I/O设备，如键盘活动。对CPU的占有很少，响应要快。

**CPU消耗型进程**：频繁使用CPU，如gcc。对I/O设备没有过多的需求，常常位于后台运行。

操作系统既要有迅速的响应能力，又要有最大的CPU利用率（高吞吐量）。内核调度程序更倾向于I/O消耗型进程

如果多个进程共用一个CPU，每个进程轮流得到一个时间片（slice）独享CPU。

如果一个进程时间片用完，内核会切换成其他进程独享CPU。

**静态优先级**（100 ~ 139）

静态优先级<120，基本时间片=max((140-静态优先级)*20, MIN_TIMESLICE)

静态优先级>=120，基本时间片=max((140-静态优先级)*5, MIN_TIMESLICE)

**动态优先级**=max(100 , min(静态优先级 – bonus + 5) , 139))，I/O消耗型进程bonus为正

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

# O(1)调度

**内核2.4**版本的简陋的**O(n)**调度算法,进程数量多时，调度效率非常低：

```c
for (系统中的每个进程) {
	重新计算时间片;
	重新计算优先级;
}
```

**内核2.6**版本的O(1)调度现在已经被CFS调度取代，但作为一个经典的调度算法，非常值得介绍，其他改进的调度算法都是基于O(1)调度算法。

```c
struct{
	struct prio_array 活跃进程集合;
	struct prio_array 过期进程集合;
}可运行队列;

struct{//优先级数组
	进程个数;
	uint32_t 位图[5];//160位，前140位有用
	进程链表[140];//对应优先级0~139
}prio_array;
```

2个优先级数组prio_array分别表示**活跃进程集合**和**过期进程集合**

过期数组进程已经用完时间片，而活跃数组进程时间片未用完

进程从活跃数组移动到过期数组前，已经重新计算好了时间片

本质就是采用**分散计算时间片**的方法

当活跃进程数组中没有进程时，只需要交换两个数组的指针，原来的过期数组变为活跃数组

**位图**（第0位~139位）中的每一位代表对应的**进程链表**是否存在进程

因此只需要**依次遍历**位图的第一位，找到第一个置位，对应的进程链表上的所有进程都是优先级最高的，选取链表头的进程来执行即可。

请阅读2.6.11内核`linux/kernel/sched.c`中的下列函数：

时间片分配：`task_timeslice`

运行队列操作：`enqueque_task、dequeque_task`

更新时间片：`schedule_tick`

# CFS调度

CFS(Complete Fair Scheduler)，完全公平调度

从内核2.6.23版本开始，CFS取代了O(1)调度

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
