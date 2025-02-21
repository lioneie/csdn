<!-- https://lore.kernel.org/all/?q=Add+rb_add_augmented_cached%28%29+helper -->
<!-- https://lwn.net/ml/linux-kernel/20230531115839.089944915@infradead.org/ -->

# 前几版补丁集

## [`2023.03.06 [PATCH 00/10] sched: EEVDF using latency-nice`](https://lore.kernel.org/all/20230306132521.968182689@infradead.org/)

```
你好！

自从看到 latency-nice 补丁后，我一直在想，是否使用 EEVDF 会更有意义，我确实向 Vincent 提到过我之前的一些旧补丁（他的增强版 rbtree 也来自于此）。

此外，由于我真的不喜欢双树结构，我还认为我们可以在增强树和普通树之间动态切换（虽然我有这方面的代码，但由于目前的结果，我认为我们实际上不需要这个，所以这次没有包含它）。

无论如何，由于我最近身体不适，上周我拼命尝试连接一些神经元，以抵抗感冒，重新从被尘封了 13 年的黑暗地窖中找回 EEVDF 补丁。

到周五时，它们已经运行得相当不错了，而今天早上（显然我忘了周末是运行基准测试的理想时间）我运行了一堆 hackbench、netperf、tbench 和 sysbench 测试——有些项目表现更好，有些表现较差，但没有任何显示完全失败的迹象。

（事实上，一些 schbench 结果似乎表明 EEVDF 比 CFS 调度更加一致，并且有不少延迟优势）

（hackbench 也没有显示出增强树和一般更昂贵的选择有损失，事实上在这里显示了一些小幅度的提升）

hackbench 负载 + cyclictest --policy 其他结果:

                        EEVDF                    CFS

                # Min Latencies: 00053
  LNICE(19)     # Avg Latencies: 04350
                # Max Latencies: 76019

                # Min Latencies: 00052          00053
  LNICE(0)      # Avg Latencies: 00690          00687
                # Max Latencies: 14145          13913

                # Min Latencies: 00019
  LNICE(-19)    # Avg Latencies: 00261
                # Max Latencies: 05642

虽然 -19 的结果不如 Vincent 的漂亮，但最后我因为盯着树形打印看得眼花缭乱，实在弄不清楚问题出在哪里。

肯定还有更多的基准测试/调整要做（0-day 已经报告了 stress-ng 的失败），但如果我们能实现这一点，我们可以删除大量让人讨厌的启发式代码。EEVDF 比我们目前使用的策略要定义得更好。
```

## [`2023.03.28 [PATCH 00/17] sched: EEVDF using latency-nice`](https://lore.kernel.org/all/20230328092622.062917921@infradead.org/)

```
你好！

这是 EEVDF 补丁的最新版本 [1]。

自上次以来有很多变化；最显著的变化是它现在完全取代了 CFS，并使用基于滞后（lag）的迁移放置策略。较小的变化包括:

对 avg_vruntime 使用了 scale_load_down()；我测量的最大差值约为 44 位，基于系统/cgroup 的内核构建。
修复了一些重新加权/ cgroup 放置问题。
为较小的时间片引入了自适应放置策略。
将 se->lag 重命名为 se->vlag。
在补丁的末尾有一些 RFC 补丁和一个 DEBUG 补丁。关于这些补丁，PLACE_BONUS 补丁是一把混合的痛苦之剑。由于 EEVDF 实际上是公平的，给一个 100% 的父进程和一个 50% 的子进程分配了 67%/33% 的比例（例如 stress-futex、stress-nanosleep、starve 等等），而不是通过 sleeper bonus 实现的 50%/50% 的比例，因此一些基准测试出现了回退。我认为这些基准测试大多有点人为/愚蠢，但谁知道呢。

PLACE_BONUS 补丁严重搞乱了像 hackbench 和 latency-nice 之类的东西，因为它将任务放置在树的太左边。基本上它干扰了整个“时间点”，通过将任务放置回历史中，你正在为现在增加一个负担，以适应追赶的需求。还需要更多的调整。

但总体而言，该补丁似乎相当可用，可以进行更广泛的测试。

[1] https://citeseerx.ist.psu.edu/document?repid=rep1&type=pdf&doi=805acf7726282721504c8f00575d91ebfd750564
```

# 合入的补丁集[`2023.05.31 [PATCH 00/15] sched: EEVDF and latency-nice and/or slice-attr`](https://lore.kernel.org/all/20230531115839.089944915@infradead.org/)

邮件中的`11~15`补丁未合入。

```
你好！

这是最新版本的 EEVDF [1] 补丁。

自上次以来，唯一的实质性变化是修复了 tick-preemption [2]，并为混合时间片启发式添加了一个简单的安全防护措施。

除此之外，我重新排列了补丁顺序，使 EEVDF 优先，并将 latency-nice 或时间片属性的补丁放在后面。

测试结果应该与上次没有不同，许多人已经运行了这些补丁，并没有发现重大的性能问题；相反，发现了更好的延迟和更小的方差（可能是由于更稳定的延迟造成的）。

我希望我们可以开始排队合并这部分内容。

最大的问题是要暴露什么额外的接口；一些人对 latency-nice 接口提出了反对意见，“显而易见”的替代方案是直接暴露时间片长度作为请求/提示。

最后一个补丁实现了使用 sched_attr::sched_runtime 的替代方案，但尚未经过测试。

基础补丁 [1-11] 的 Diffstat:

 include/linux/rbtree_augmented.h |   26 +
 include/linux/sched.h            |    7 +-
 kernel/sched/core.c              |    2 +
 kernel/sched/debug.c             |   48 +-
 kernel/sched/fair.c              | 1105 ++++++++++++++++++--------------------
 kernel/sched/features.h          |   24 +-
 kernel/sched/sched.h             |   16 +-
 7 files changed, 587 insertions(+), 641 deletions(-)

[1] https://citeseerx.ist.psu.edu/document?repid=rep1&type=pdf&doi=805acf7726282721504c8f00575d91ebfd750564

[2] https://lkml.kernel.org/r/20230420150537.GC4253%40hirez.programming.kicks-ass.net
```

## [`[PATCH 01/15] af4cf40470c2 sched/fair: Add cfs_rq::avg_vruntime`](https://lore.kernel.org/all/20230531124603.654144274@infradead.org/)

```
sched/fair: 添加 cfs_rq::avg_vruntime

为了转向基于资格的调度策略，我们需要对理想调度器进行更好的近似。

具体来说，对于基于虚拟时间加权公平队列的调度器，理想的调度器将是各个虚拟运行时间的加权平均值（数学推导在注释中）。

因此，计算加权平均值来近似理想调度器——注意，这种近似体现在单个任务的行为上，这并不严格遵循理想调度器的规范。

特别是考虑添加一个虚拟运行时间在中心左侧的任务，在这种情况下，平均值将会向后移动——这是理想调度器当然永远不会做的事情。
```

## [`[PATCH 02/15] e0c2ff903c32 sched/fair: Remove sched_feat(START_DEBIT)`](https://lore.kernel.org/all/20230531124603.722361178@infradead.org/)

```
sched/fair: 移除 sched_feat(START_DEBIT)

随着 avg_vruntime() 的引入，不再需要使用较差的近似方法。将 0 延迟点作为插入新任务的起点。
```

## [`[PATCH 03/15] 86bfbb7ce4f6 sched/fair: Add lag based placement`](https://lore.kernel.org/all/20230531124603.794929315@infradead.org/)

```
sched/fair: 添加基于延迟的放置

随着 avg_vruntime 的引入，现在可以近似计算延迟（事实上，这就是引入它的全部目的）。利用这一点，在睡眠+唤醒时进行基于延迟的放置。

具体来说，FAIR_SLEEPERS 机制将任务放置得太靠左，破坏了 EEVDF 的截止时间特性。
```

## [`[PATCH 04/15] 99d4d26551b5 rbtree: Add rb_add_augmented_cached() helper`](https://lore.kernel.org/all/20230531124603.862983648@infradead.org/)

```
rbtree: 添加 rb_add_augmented_cached() 辅助函数

虽然略显次优，但在查找过程中向下遍历树时更新增强数据会更快——可惜当前的增强接口不支持这种操作，因此提供一个通用的辅助函数，用于将节点添加到增强缓存树中。
```

## [`[PATCH 05/15] 147f3efaa241 sched/fair: Implement an EEVDF-like scheduling policy`](https://lore.kernel.org/all/20230531124603.931005524@infradead.org/)

```
sched/fair: 实现类似 EEVDF 的调度策略

目前 CFS 是基于加权公平队列（WFQ）的调度器，只有一个调节参数——权重。通过添加第二个面向延迟的参数，可以更好地实现类似 WF2Q 或 EEVDF 的调度策略。

具体来说，EEVDF 在树的左半部分执行类似 EDF（最早截止时间优先）的调度——这些实体是需要被服务的。由于这是一个虚拟时间调度器，所以截止时间也是在虚拟时间内，这也是允许超额订阅的原因。

EEVDF 有两个参数:

权重，或时间斜率: 与以前一样，映射到 nice 值上。

请求大小，或时间片长度: 用于计算虚拟截止时间，如下所示: vd_i = ve_i + r_i/w_i

基本上，通过设置较小的时间片，截止时间会更早，任务将更优先并更早执行。

Tick 驱动的抢占由请求/时间片的完成驱动，而唤醒抢占则由截止时间驱动。

由于现在的树实际上是一个区间树，并且选择不再是“最左侧”，过度调度的问题也得到了缓解。
```

## [`[PATCH 06/15] 76cae9dbe185 sched/fair: Commit to lag based placement`](https://lore.kernel.org/all/20230531124604.000198861@infradead.org/)

```
sched/fair: 确认基于延迟的放置

移除了 FAIR_SLEEPERS 代码，取而代之的是新的基于延迟的放置。

具体来说，FAIR_SLEEPERS 机制是一个非常粗糙的近似方法，用于弥补缺乏基于延迟的放置，特别是“服务欠缺”部分。这对于像 starve 和 hackbench 这样的场景非常重要。

FAIR_SLEEPER 的一个副作用是导致了“小”的不公平，具体来说，通过总是忽略最长为 thresh 的睡眠时间，它对于一个 50% 的睡眠者和一个 100% 的运行者会有 50%/50% 的时间分配，而严格来说，这应该（当然）导致 33%/67% 的分配（如果睡眠期超过了 thresh，CFS 也会如此处理）。
```

## [`[PATCH 07/15] e8f331bcc270 sched/smp: Use lag to simplify cross-runqueue placement`](https://lore.kernel.org/all/20230531124604.068911180@infradead.org/)

```
sched/smp: 使用延迟简化跨运行队列的放置

在跨运行队列移动时，使用延迟既更准确又更简单。

值得注意的是，min_vruntime() 被发明为 avg_vruntime() 的一种廉价近似，用于此目的（SMP 迁移）。既然我们现在有了真实的 avg_vruntime()，就应当使用它。
```

## [`[PATCH 08/15] 5e963f2bd465 sched/fair: Commit to EEVDF`](https://lore.kernel.org/all/20230531124604.137187212@infradead.org/)

```
sched/fair: 确认使用 EEVDF

EEVDF 是一个定义更明确的调度策略，因此它具有更少的启发式方法和调节参数。没有强有力的理由继续保留 CFS。
```

## [`[PATCH 09/15] e4ec3318a17f sched/debug: Rename sysctl_sched_min_granularity to sysctl_sched_base_slice`](https://lore.kernel.org/all/20230531124604.205287511@infradead.org/)

```
sched/debug: 将 sysctl_sched_min_granularity 重命名为 sysctl_sched_base_slice

EEVDF 使用这个调节参数作为基本的请求/时间片——确保名称能够反映这一点。
```

## [`[PATCH 10/15] d07f09a1f99c sched/fair: Propagate enqueue flags into place_entity()`](https://lore.kernel.org/all/20230531124604.274010996@infradead.org/)

```
sched/fair: 将入队标志传播到 place_entity() 中

这允许 place_entity() 考虑 ENQUEUE_WAKEUP 和 ENQUEUE_MIGRATED 标志。
```