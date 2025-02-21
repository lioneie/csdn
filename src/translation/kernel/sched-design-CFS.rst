本文档翻译自`sched-design-CFS.rst <https://github.com/torvalds/linux/blob/master/Documentation/scheduler/sched-design-CFS.rst>`_，翻译时文件的最新提交是``0a0d5f32b01cbc184a0c3b07cbe291f03f7c8a35 docs/sp_SP: Add translation for scheduler/sched-design-CFS.rst``。大部分借助于ChatGPT翻译，仅作为我个人的参考，如果你想查阅，建议看英文文档，因为我不确定我记录的中文翻译是否完整和正确。

概述
======

CFS 代表“完全公平调度器”，是由 Ingo Molnar 实现的新“桌面”进程调度器，并在 Linux 2.6.23 中合并。它是以前的普通调度器的 SCHED_OTHER 交互代码的替代品。

CFS 设计的 80% 可以用一句话来概括: CFS 基本上在实际硬件上模拟了一个“理想的、精确的多任务 CPU”。

“理想的多任务 CPU”是一个（不存在的 :-)) CPU，它具有 100% 的物理计算能力，可以以精确相等的速度并行运行每个任务，每个任务的速度为 1/nr_running。例如: 如果有两个任务在运行，那么它会以 50% 的物理计算能力运行每个任务——即实际上是并行运行的。

在实际硬件上，我们一次只能运行一个任务，因此我们必须引入“虚拟运行时间”的概念。任务的虚拟运行时间指定了它的下一个时间片何时会在上述理想的多任务 CPU 上开始执行。实际上，任务的虚拟运行时间是其实际运行时间归一化到所有正在运行的任务的总数。

一些实现细节
==============

在 CFS 中，虚拟运行时间通过每个任务的 p->se.vruntime（纳秒单位）值来表示和跟踪。通过这种方式，可以准确地对任务应获得的“预期 CPU 时间”进行时间戳和测量。

   小细节: 在“理想”硬件上，任何时候所有任务都会具有相同的 p->se.vruntime 值——即，任务会同时执行，没有任何任务会从“理想” CPU 时间分配中“失衡”。

CFS 的任务选择逻辑基于此 p->se.vruntime 值，因此非常简单: 它总是尝试运行 p->se.vruntime 值最小的任务（即，到目前为止执行时间最少的任务）。CFS 总是试图将 CPU 时间尽可能接近“理想的多任务硬件”地在可运行的任务之间划分。

CFS 的大部分设计都源于这个非常简单的概念，附加了一些如 nice 级别、多处理以及各种算法变体来识别休眠者等附加修饰。

红黑树
========

CFS 的设计相当激进: 它不使用旧的运行队列数据结构，而是使用时间排序的红黑树来构建未来任务执行的“时间线”，因此没有“数组切换”伪影（以前的普通调度器和 RSDL/SD 都受到这些伪影的影响）。

CFS 还维护了 rq->cfs.min_vruntime 值，这是一个单调递增的值，跟踪运行队列中所有任务的最小 vruntime。系统完成的总工作量通过 min_vruntime 进行跟踪；该值用于将新激活的实体尽可能放置在树的左侧。

运行队列中正在运行的任务总数通过 rq->cfs.load 值进行计算，该值是队列中排队任务权重的总和。

CFS 维护一个时间排序的红黑树，所有可运行的任务按 p->se.vruntime 键排序。CFS 从这棵树中选择“最左边”的任务并坚持执行。随着系统的前进，执行的任务会越来越多地被放入树的右侧——慢慢但确实地为每个任务提供机会成为“最左边的任务”，从而在确定的时间内获得 CPU。

总结，CFS 工作原理如下: 它运行一个任务一段时间，当任务调度（或发生调度器时钟滴答时）时，任务的 CPU 使用情况被“记录下来”: 它刚刚使用物理 CPU 的（小）时间被添加到 p->se.vruntime。一旦 p->se.vruntime 变得足够高，另一个任务成为它维护的时间排序红黑树的“最左边的任务”（相对于最左边的任务加上一小段“粒度”距离，以避免过度调度任务和缓存抖动），那么新的最左边的任务将被选中，并且当前任务会被抢占。

CFS 的一些特性
==================

CFS 使用纳秒粒度计费，并且不依赖于任何 jiffies 或其他 HZ 细节。因此，CFS 调度器没有以前调度器那样的“时间片”概念，并且没有任何启发式方法。只有一个中央可调参数（你必须开启 CONFIG_SCHED_DEBUG）:

   /sys/kernel/debug/sched/base_slice_ns

可以用于将调度器调整为“桌面”（即低延迟）或“服务器”（即良好的批处理）工作负载。它默认为适合桌面工作负载的设置。SCHED_BATCH 也由 CFS 调度器模块处理。

如果 CONFIG_HZ 导致 base_slice_ns < TICK_NSEC，则 base_slice_ns 的值对工作负载几乎没有影响。

由于其设计，CFS 调度器不易受到当前对库存调度器的启发式攻击的影响: fiftyp.c、thud.c、chew.c、ring-test.c、massive_intr.c 均正常工作，不影响交互性并产生预期的行为。

CFS 调度器对 nice 级别和 SCHED_BATCH 的处理要比以前的普通调度器强得多: 这两种类型的工作负载都得到了更积极的隔离。

SMP 负载均衡已重新设计/规范化: 负载均衡代码中的运行队列遍历假设现已消失，并且使用了调度模块的迭代器。结果，负载均衡代码变得更简单了。


调度策略
===========

CFS 实现了三种调度策略:

  - SCHED_NORMAL（传统上称为 SCHED_OTHER）: 用于常规任务的调度策略。

  - SCHED_BATCH: 不会像常规任务那样频繁抢占，从而允许任务运行更长时间并更好地利用缓存，但代价是降低交互性。这非常适合批处理作业。

  - SCHED_IDLE: 这比 nice 19 更弱，但它不是一个真正的空闲定时器调度器，以避免出现会导致机器死锁的优先级反转问题。

SCHED_FIFO/_RR 在 sched/rt.c 中实现，并且按照 POSIX 规范实现。

util-linux-ng 2.13.1.1 中的 chrt 命令可以设置除 SCHED_IDLE 以外的所有这些策略。



调度类
=========

新的 CFS 调度器的设计方式引入了“调度类”，即一个可扩展的调度器模块层次结构。这些模块封装了调度策略的细节，并由调度器核心处理，而核心代码不假设太多关于它们的内容。

sched/fair.c 实现了上述的 CFS 调度器。

sched/rt.c 以比以前的普通调度器更简单的方式实现了 SCHED_FIFO 和 SCHED_RR 语义。它使用 100 个运行队列（用于所有 100 个 RT 优先级，而不是以前调度器中的 140 个），并且不需要过期数组。

调度类通过 sched_class 结构实现，该结构包含的钩子函数必须在发生有趣事件时调用。

以下是钩子函数的（部分）列表:

 - enqueue_task(...)

   当任务进入可运行状态时调用。
   它将调度实体（任务）放入红黑树并增加 nr_running 变量。

 - dequeue_task(...)

   当任务不再可运行时，调用此函数以将相应的调度实体排除在红黑树之外。它减少 nr_running 变量。

 - yield_task(...)

   此函数基本上只是一个先出队再入队的操作，除非 compat_yield sysctl 被打开；在这种情况下，它将调度实体放置在红黑树的最右端。

 - wakeup_preempt(...)

   此函数检查进入可运行状态的任务是否应该抢占当前正在运行的任务。

 - pick_next_task(...)

   此函数选择下一个最合适的任务进行运行。

 - set_next_task(...)

   当任务更改其调度类、更改其任务组或被调度时，调用此函数。

 - task_tick(...)

   此函数主要从时间滴答函数中调用；它可能导致进程切换。这驱动了运行中的抢占。



CFS 的组调度扩展
====================

通常，调度器对单个任务进行操作，并努力为每个任务提供公平的 CPU 时间。有时，可能需要对任务进行分组并为每个任务组提供公平的 CPU 时间。例如，可能需要首先为系统上的每个用户提供公平的 CPU 时间，然后为属于用户的每个任务提供公平的 CPU 时间。

CONFIG_CGROUP_SCHED 力求实现这一目标。它允许对任务进行分组，并在这些组之间公平地划分 CPU 时间。

CONFIG_RT_GROUP_SCHED 允许对实时（即 SCHED_FIFO 和 SCHED_RR）任务进行分组。

CONFIG_FAIR_GROUP_SCHED 允许对 CFS（即 SCHED_NORMAL 和 SCHED_BATCH）任务进行分组。

   这些选项需要定义 CONFIG_CGROUPS，并允许管理员使用“cgroup”伪文件系统创建任意任务组。有关此文件系统的更多信息，请参见 Documentation/admin-guide/cgroup-v1/cgroups.rst。

当定义了 CONFIG_FAIR_GROUP_SCHED 时，会为使用伪文件系统创建的每个组创建一个“cpu.shares”文件。请参见下面的示例步骤，以使用“cgroups”伪文件系统创建任务组并修改其 CPU 份额:

	# mount -t tmpfs cgroup_root /sys/fs/cgroup
	# mkdir /sys/fs/cgroup/cpu
	# mount -t cgroup -ocpu none /sys/fs/cgroup/cpu
	# cd /sys/fs/cgroup/cpu

	# mkdir multimedia	# 创建“multimedia”任务组
	# mkdir browser		# 创建“browser”任务组

	# #配置 multimedia 组以接收比 browser 组多两倍的 CPU 带宽
	# echo 2048 > multimedia/cpu.shares
	# echo 1024 > browser/cpu.shares

	# firefox &	# 启动 firefox 并将其移动到“browser”组
	# echo <firefox_pid> > browser/tasks

	# #启动 gmplayer（或你喜欢的电影播放器）
	# echo <movie_player_pid> > multimedia/tasks
