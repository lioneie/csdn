# CFS调度

CFS**没有**时间片的概念，也**不是**根据优先级来决定下一个该运行的进程

CFS是通过计算**进程消耗的CPU时间（加权之后）**来确定下一个该运行的进程。从而到达所谓的公平性。

分配给进程的运行时间 = 调度周期 * 进程权重 / 所有进程权重之和

Linux通过引入virtual runtime(vruntime)来实现CFS

实际上vruntime就是根据权重将实际运行时间标准化

谁的vruntime值较小就说明它以前占用cpu的时间较短，受到了“不公平”对待，因此下一个运行进程就是它。这样高nice值的进程能得到迅速响应，低nice值的进程能获取更多的cpu时间。

Linux采用了一颗红黑树（对于多核调度，实际上每一个核有一个自己的红黑树），记录下每一个进程的vruntime

红黑树操作的算法复杂度最大为O(lgn)

请阅读2.6.34内核`kernel/sched_fair.c`中的下列结构体或函数:

调度器实体结构: `struct sched_entity`

虚拟时间记账: `update_curr、__update_curr`

进程选择: `pick_next_entity、enqueuer_entity、dequeuer_entity`

调度器入口: `pick_next_task`
