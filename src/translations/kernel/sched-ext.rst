
本文档翻译自`sched-ext.rst <https://gitee.com/chenxiaosonggitee/tmp/blob/master/kernel/sched-ext-origin.rst>`_，翻译时sched-ext未合入主线，还在next仓库里，当时next仓库里的最新提交是``18b2bd03371b sched_ext: Documentation: Remove mentions of scx_bpf_switch_all``。大部分借助于ChatGPT翻译，仅作为我个人的参考，如果你想查阅，建议看英文文档，因为我不确定我记录的中文翻译是否完整和正确。

sched_ext 是一个调度器类，其行为可以通过一组 BPF 程序来定义——即 BPF 调度器。

* sched_ext 导出完整的调度接口，以便在其上实现任何调度算法。

* BPF 调度器可以根据需要将 CPU 分组并一起调度，因为任务在唤醒时不绑定到特定的 CPU。

* BPF 调度器可以随时动态开启和关闭。

* 无论 BPF 调度器做了什么，系统完整性始终得到维护。每当检测到错误、可运行任务停滞或调用 SysRq 键序列 :kbd:`SysRq-S` 时，默认的调度行为会恢复。

* 当 BPF 调度器触发错误时，会转储调试信息以辅助调试。调试转储被传递给调度器二进制文件并打印出来。调试转储也可以通过 `sched_ext_dump` 跟踪点访问。SysRq 键序列 :kbd:`SysRq-D` 会触发调试转储。这不会终止 BPF 调度器，只能通过跟踪点读取。

切换到和切换自 sched_ext
===============================

``CONFIG_SCHED_CLASS_EXT`` 是启用 sched_ext 的配置选项，而 ``tools/sched_ext`` 包含示例调度器。使用 sched_ext 应启用以下配置选项:

.. code-block:: none

    CONFIG_BPF=y
    CONFIG_SCHED_CLASS_EXT=y
    CONFIG_BPF_SYSCALL=y
    CONFIG_BPF_JIT=y
    CONFIG_DEBUG_INFO_BTF=y
    CONFIG_BPF_JIT_ALWAYS_ON=y
    CONFIG_BPF_JIT_DEFAULT_ON=y
    CONFIG_PAHOLE_HAS_SPLIT_BTF=y
    CONFIG_PAHOLE_HAS_BTF_TAG=y

只有在加载并运行 BPF 调度器时，sched_ext 才会被使用。

如果任务显式设置其调度策略为 ``SCHED_EXT``，则会被视为 ``SCHED_NORMAL`` 并由 CFS 调度，直到加载 BPF 调度器为止。

当 BPF 调度器加载且 ``SCX_OPS_SWITCH_PARTIAL`` 在 ``ops->flags`` 中未设置时，所有 ``SCHED_NORMAL``、``SCHED_BATCH``、``SCHED_IDLE`` 和 ``SCHED_EXT`` 任务都由 sched_ext 调度。

然而，当 BPF 调度器加载且 ``SCX_OPS_SWITCH_PARTIAL`` 在 ``ops->flags`` 中设置时，只有 ``SCHED_EXT`` 策略的任务由 sched_ext 调度，而 ``SCHED_NORMAL``、``SCHED_BATCH`` 和 ``SCHED_IDLE`` 策略的任务由 CFS 调度。

终止 sched_ext 调度器程序、触发 :kbd:`SysRq-S` 或检测到任何内部错误（包括停滞的可运行任务）都会中止 BPF 调度器并将所有任务恢复到 CFS。

.. code-block:: none

    # make -j16 -C tools/sched_ext
    # tools/sched_ext/scx_simple
    local=0 global=3
    local=5 global=24
    local=9 global=44
    local=13 global=56
    local=17 global=72
    ^CEXIT: BPF scheduler unregistered

可以通过以下方式确定 BPF 调度器的当前状态:

.. code-block:: none

    # cat /sys/kernel/sched_ext/state
    enabled
    # cat /sys/kernel/sched_ext/root/ops
    simple

``tools/sched_ext/scx_show_state.py`` 是一个 drgn 脚本，显示更详细的信息:

.. code-block:: none

    # tools/sched_ext/scx_show_state.py
    ops           : simple
    enabled       : 1
    switching_all : 1
    switched_all  : 1
    enable_state  : enabled (2)
    bypass_depth  : 0
    nr_rejected   : 0

如果设置了 ``CONFIG_SCHED_DEBUG``，可以通过以下方式确定给定任务是否在 sched_ext 上:

.. code-block:: none

    # grep ext /proc/self/sched
    ext.enabled                                  :                    1

基础
==========

用户空间可以通过加载一组实现了 ``struct sched_ext_ops`` 的 BPF 程序来实现任意的 BPF 调度器。唯一强制性的字段是 ``ops.name``，它必须是一个有效的 BPF 对象名称。所有操作都是可选的。以下修改的摘录来自 ``tools/sched_ext/scx_simple.bpf.c``，显示了一个最小的全局 FIFO 调度器。

.. code-block:: c

    /*
     * 决定一个任务在被入队前应该迁移到哪个 CPU（无论是在唤醒、fork 时还是 exec 时）。如果默认的 ops.select_cpu() 实现找到一个空闲核心，
     * 则直接将任务分发到 SCX_DSQ_LOCAL，并跳过 ops.enqueue() 回调。
     *
     * 注意，这个实现的行为与默认的 ops.select_cpu 实现完全相同。如果实现只是没有定义 simple_select_cpu() struct_ops 程序，
     * 调度器的行为将完全相同。
     */
    s32 BPF_STRUCT_OPS(simple_select_cpu, struct task_struct *p,
                       s32 prev_cpu, u64 wake_flags)
    {
            s32 cpu;
            /* 需要初始化，否则 BPF 验证器会拒绝程序 */
            bool direct = false;

            cpu = scx_bpf_select_cpu_dfl(p, prev_cpu, wake_flags, &direct);

            if (direct)
                    scx_bpf_dispatch(p, SCX_DSQ_LOCAL, SCX_SLICE_DFL, 0);

            return cpu;
    }

    /*
     * 将任务直接分发到全局 DSQ。只有在上面 ops.select_cpu() 中未找到核心进行分发时，才会调用此 ops.enqueue() 回调。
     *
     * 注意，这个实现的行为与默认的 ops.enqueue 实现完全相同，后者只是将任务分发到 SCX_DSQ_GLOBAL。如果实现只是没有定义 simple_enqueue struct_ops 程序，
     * 调度器的行为将完全相同。
     */
    void BPF_STRUCT_OPS(simple_enqueue, struct task_struct *p, u64 enq_flags)
    {
            scx_bpf_dispatch(p, SCX_DSQ_GLOBAL, SCX_SLICE_DFL, enq_flags);
    }

    s32 BPF_STRUCT_OPS_SLEEPABLE(simple_init)
    {
            /*
             * 默认情况下，所有 SCHED_EXT、SCHED_OTHER、SCHED_IDLE 和 SCHED_BATCH 任务应该使用 sched_ext。
             */
            return 0;
    }

    void BPF_STRUCT_OPS(simple_exit, struct scx_exit_info *ei)
    {
            exit_type = ei->type;
    }

    SEC(".struct_ops")
    struct sched_ext_ops simple_ops = {
            .select_cpu             = (void *)simple_select_cpu,
            .enqueue                = (void *)simple_enqueue,
            .init                   = (void *)simple_init,
            .exit                   = (void *)simple_exit,
            .name                   = "simple",
    };

调度队列
---------------

为了匹配调度器核心和 BPF 调度器之间的阻抗，sched_ext 使用 DSQ（调度队列），它可以同时作为 FIFO 和优先级队列运行。默认情况下，有一个全局 FIFO（``SCX_DSQ_GLOBAL``），以及每个 CPU 一个本地 DSQ（``SCX_DSQ_LOCAL``）。BPF 调度器可以使用 ``scx_bpf_create_dsq()`` 和 ``scx_bpf_destroy_dsq()`` 管理任意数量的 DSQ。

CPU 始终从其本地 DSQ 中执行任务。一个任务被“分发”到一个 DSQ。一个非本地 DSQ 被“消费”以将任务转移到消费 CPU 的本地 DSQ。

当 CPU 查找下一个要运行的任务时，如果本地 DSQ 不为空，则选择第一个任务。否则，CPU 尝试消费全局 DSQ。如果这也没有产生可运行的任务，则调用 ``ops.dispatch()``。

调度周期
----------------

以下简要展示了一个唤醒任务如何被调度和执行。

1. 当任务唤醒时，``ops.select_cpu()`` 是第一个被调用的操作。这有两个目的。首先，是 CPU 选择优化提示。其次，是唤醒选定的空闲 CPU。

   ``ops.select_cpu()`` 选择的 CPU 是一个优化提示，而不是绑定的。实际的决定在调度的最后一步做出。然而，如果 ``ops.select_cpu()`` 返回的 CPU 与任务最终运行的 CPU 匹配，可能会有小的性能提升。

   选择 CPU 的副作用是唤醒它从空闲状态。虽然 BPF 调度器可以使用 ``scx_bpf_kick_cpu()`` 帮助函数唤醒任何 CPU，但明智地使用 ``ops.select_cpu()`` 可以更简单和更高效。

   可以通过调用 ``scx_bpf_dispatch()`` 将任务立即分发到 DSQ。如果任务从 ``ops.select_cpu()`` 分发到 ``SCX_DSQ_LOCAL``，它将被分发到 ``ops.select_cpu()`` 返回的 CPU 的本地 DSQ。此外，从 ``ops.select_cpu()`` 直接分发将跳过 ``ops.enqueue()`` 回调。

   请注意，调度器核心会忽略无效的 CPU 选择，例如，如果它超出了任务的允许 cpumask。

2. 一旦目标 CPU 被选择，``ops.enqueue()`` 会被调用（除非任务是直接从 ``ops.select_cpu()`` 分发的）。``ops.enqueue()`` 可以做出以下决定:

   * 通过调用 ``scx_bpf_dispatch()`` 将任务立即分发到全局或本地 DSQ，分别为 ``SCX_DSQ_GLOBAL`` 或 ``SCX_DSQ_LOCAL``。

   * 通过调用 ``scx_bpf_dispatch()`` 将任务立即分发到自定义 DSQ，DSQ ID 小于 2^63。

   * 在 BPF 端排队任务。

3. 当 CPU 准备调度时，它首先查看其本地 DSQ。如果为空，则查看全局 DSQ。如果仍然没有任务运行，则调用 ``ops.dispatch()``，可以使用以下两个函数来填充本地 DSQ。

   * ``scx_bpf_dispatch()`` 将任务分发到 DSQ。可以使用任何目标 DSQ——``SCX_DSQ_LOCAL``、``SCX_DSQ_LOCAL_ON | cpu``、``SCX_DSQ_GLOBAL`` 或自定义 DSQ。虽然 ``scx_bpf_dispatch()`` 目前不能在持有 BPF 锁的情况下调用，但正在开发中并将支持。``scx_bpf_dispatch()`` 调度分发而不是立即执行。可以有多达 ``ops.dispatch_max_batch`` 的待处理任务。

   * ``scx_bpf_consume()`` 将任务从指定的非本地 DSQ 转移到调度 DSQ。此函数不能在持有任何 BPF 锁的情况下调用。``scx_bpf_consume()`` 在尝试消费指定 DSQ 之前，会刷新待处理的调度任务。

4. 在 ``ops.dispatch()`` 返回后，如果本地 DSQ 中有任务，CPU 运行第一个。如果为空，执行以下步骤:

   * 尝试消费全局 DSQ。如果成功，运行任务。

   * 如果 ``ops.dispatch()`` 已调度任何任务，重试第 3 步。

   * 如果上一个任务是 SCX 任务并且仍然可运行，继续执行它（见 ``SCX_OPS_ENQ_LAST``）。

   * 进入空闲状态。

请注意，BPF 调度器总是可以选择在 ``ops.enqueue()`` 中立即调度任务，如上述简单示例所示。如果只使用内置 DSQ，则不需要实现 ``ops.dispatch()``，因为任务从未排队到 BPF 调度器中，本地和全局 DSQ 会自动被消费。

``scx_bpf_dispatch()`` 将任务排队到目标 DSQ 的 FIFO 中。使用 ``scx_bpf_dispatch_vtime()`` 进行优先级队列。内部 DSQ，如 ``SCX_DSQ_LOCAL`` 和 ``SCX_DSQ_GLOBAL`` 不支持优先级队列调度，必须使用 ``scx_bpf_dispatch()`` 进行调度。有关更多信息，请参见 ``tools/sched_ext/scx_simple.bpf.c`` 中的函数文档和用法。

查看位置（Where to Look）
========================

* ``include/linux/sched/ext.h`` 定义了核心数据结构、操作表和常量。

* ``kernel/sched/ext.c`` 包含 sched_ext 核心实现和帮助函数。以 ``scx_bpf_`` 前缀的函数可以从 BPF 调度器调用。

* ``tools/sched_ext/`` 托管示例 BPF 调度器实现。

  * ``scx_simple[.bpf].c``: 使用自定义 DSQ 的最小全局 FIFO 调度器示例。

  * ``scx_qmap[.bpf].c``: 支持五级优先级的多级 FIFO 调度器，通过 ``BPF_MAP_TYPE_QUEUE`` 实现。

ABI 不稳定性
===============

sched_ext 提供给 BPF 调度器程序的 API 没有稳定性保证。这包括 ``include/linux/sched/ext.h`` 中定义的操作表回调和常量，以及 ``kernel/sched/ext.c`` 中定义的 ``scx_bpf_`` kfuncs。

虽然我们会尽力提供相对稳定的 API 接口，但它们在内核版本之间可能会发生变化，恕不另行通知。
