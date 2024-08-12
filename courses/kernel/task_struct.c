struct task_struct {
#ifdef CONFIG_THREAD_INFO_IN_TASK
        /* 
        * 由于头文件混乱的原因（请参见 current_thread_info()），这个
        * 必须是 task_struct 的第一个元素。                   
        */
        struct thread_info              thread_info;
#endif
        unsigned int                    __state;

#ifdef CONFIG_PREEMPT_RT
        /* 为 "spinlock 睡眠者" 保存的状态 */
        unsigned int                    saved_state;
#endif

        /*
         * 这里开始是 task_struct 的可随机部分。只有与调度密切相关的项目应
         * 添加到此处以上。
         */
        randomized_struct_fields_start

        void                            *stack;
        refcount_t                      usage;
        /* 每个任务的标志 (PF_*), 在下面进一步定义: */
        unsigned int                    flags;
        unsigned int                    ptrace;

#ifdef CONFIG_SMP
        int                             on_cpu;
        struct __call_single_node       wake_entry;
        unsigned int                    wakee_flips;
        unsigned long                   wakee_flip_decay_ts;
        struct task_struct              *last_wakee;

        /*
         * recent_used_cpu 最初被设置为唤醒其他任务的任务所使用的最后一个
         * CPU。唤醒者/被唤醒者关系可以将任务推送到一个 CPU 上，其中每次
         * 唤醒都会移动到下一个。跟踪最近使用的 CPU 允许快速搜索最近可能
         * 空闲的 CPU。
         */
        int                             recent_used_cpu;
        int                             wake_cpu;
#endif
        int                             on_rq;

        int                             prio;
        int                             static_prio;
        int                             normal_prio;
        unsigned int                    rt_priority;

        struct sched_entity             se;
        struct sched_rt_entity          rt;
        struct sched_dl_entity          dl;
        const struct sched_class        *sched_class;

#ifdef CONFIG_SCHED_CORE
        struct rb_node                  core_node;
        unsigned long                   core_cookie;
        unsigned int                    core_occupation;
#endif

#ifdef CONFIG_CGROUP_SCHED
        struct task_group               *sched_task_group;
#endif

#ifdef CONFIG_UCLAMP_TASK
        /*
         * 为调度实体请求的限制值。
         * 必须在持有 task_rq_lock() 时更新。
         */
        struct uclamp_se                uclamp_req[UCLAMP_CNT];
        /*
         * 为调度实体使用的有效限制值。
         * 必须在持有 task_rq_lock() 时更新。
         */
        struct uclamp_se                uclamp[UCLAMP_CNT];
#endif

        struct sched_statistics         stats;

#ifdef CONFIG_PREEMPT_NOTIFIERS
        /* struct preempt_notifier 的列表: */
        struct hlist_head               preempt_notifiers;
#endif

#ifdef CONFIG_BLK_DEV_IO_TRACE
        unsigned int                    btrace_seq;
#endif

        unsigned int                    policy;
        int                             nr_cpus_allowed;
        const cpumask_t                 *cpus_ptr;
        cpumask_t                       *user_cpus_ptr;
        cpumask_t                       cpus_mask;
        void                            *migration_pending;
#ifdef CONFIG_SMP
        unsigned short                  migration_disabled;
#endif
        unsigned short                  migration_flags;

#ifdef CONFIG_PREEMPT_RCU
        int                             rcu_read_lock_nesting;
        union rcu_special               rcu_read_unlock_special;
        struct list_head                rcu_node_entry;
        struct rcu_node                 *rcu_blocked_node;
#endif /* #ifdef CONFIG_PREEMPT_RCU */

#ifdef CONFIG_TASKS_RCU
        unsigned long                   rcu_tasks_nvcsw;
        u8                              rcu_tasks_holdout;
        u8                              rcu_tasks_idx;
        int                             rcu_tasks_idle_cpu;
        struct list_head                rcu_tasks_holdout_list;
#endif /* #ifdef CONFIG_TASKS_RCU */

#ifdef CONFIG_TASKS_TRACE_RCU
        int                             trc_reader_nesting;
        int                             trc_ipi_to_cpu;
        union rcu_special               trc_reader_special;
        struct list_head                trc_holdout_list;
        struct list_head                trc_blkd_node;
        int                             trc_blkd_cpu;
#endif /* #ifdef CONFIG_TASKS_TRACE_RCU */

        struct sched_info               sched_info;

        struct list_head                tasks;
#ifdef CONFIG_SMP
        struct plist_node               pushable_tasks;
        struct rb_node                  pushable_dl_tasks;
#endif

        struct mm_struct                *mm;
        struct mm_struct                *active_mm;

        int                             exit_state;
        int                             exit_code;
        int                             exit_signal;
        /* 父进程死亡时发送的信号: */
        int                             pdeath_signal;
        /* JOBCTL_*，受siglock保护: */
        unsigned long                   jobctl;

        /* 用于模拟之前Linux版本的ABI行为: */
        unsigned int                    personality;

        /* 调度器位，由调度器锁序列化: */
        unsigned                        sched_reset_on_fork:1;
        unsigned                        sched_contributes_to_load:1;
        unsigned                        sched_migrated:1;

        /* 强制对齐到下一个边界: */
        unsigned                        :0;

        /* 未序列化，严格为'current' */

        /*
         * 这个字段不能在上面的调度器字中，因为wakelist队列
         * 不再由p->on_cpu序列化。然而:
         *
         * p->XXX = X;                  ttwu()
         * schedule()                     if (p->on_rq && ..) // false
         *   smp_mb__after_spinlock();    if (smp_load_acquire(&p->on_cpu) && //true
         *   deactivate_task()                ttwu_queue_wakelist())
         *     p->on_rq = 0;                    p->sched_remote_wakeup = Y;
         *
         * 保证所有'current'的存储在
         * ->sched_remote_wakeup被使用前可见，所以它可以在这个字中。
         */
        unsigned                        sched_remote_wakeup:1;

        /* 标志LSM我们在execve(): */
        unsigned                        in_execve:1;
        unsigned                        in_iowait:1;
#ifndef TIF_RESTORE_SIGMASK
        unsigned                        restore_sigmask:1;
#endif
#ifdef CONFIG_MEMCG
        unsigned                        in_user_fault:1;
#endif
#ifdef CONFIG_LRU_GEN
        /* 是否LRU算法可能适用于此访问 */
        unsigned                        in_lru_fault:1;
#endif
#ifdef CONFIG_COMPAT_BRK
        unsigned                        brk_randomized:1;
#endif
#ifdef CONFIG_CGROUPS
        /* 禁止用户态发起的cgroup迁移 */
        unsigned                        no_cgroup_migration:1;
        /* 任务被冻结/停止（由cgroup freezer使用） */
        unsigned                        frozen:1;
#endif
#ifdef CONFIG_BLK_CGROUP
        unsigned                        use_memdelay:1;
#endif
#ifdef CONFIG_PSI
        /* 由于内存不足而停滞 */
        unsigned                        in_memstall:1;
#endif
#ifdef CONFIG_PAGE_OWNER
        /* 用于page_owner=on检测页面跟踪中的递归。 */
        unsigned                        in_page_owner:1;
#endif
#ifdef CONFIG_EVENTFD
        /* eventfd_signal()的递归防止 */
        unsigned                        in_eventfd:1;
#endif
#ifdef CONFIG_IOMMU_SVA
        unsigned                        pasid_activated:1;
#endif
#ifdef  CONFIG_CPU_SUP_INTEL
        unsigned                        reported_split_lock:1;
#endif
#ifdef CONFIG_TASK_DELAY_ACCT
        /* 由于内存抖动而导致的延迟 */
        unsigned                        in_thrashing:1;
#endif

        unsigned long                   atomic_flags; /* 需要原子访问的标志。 */

        struct restart_block            restart_block;

        pid_t                           pid;
        pid_t                           tgid; // thread group identifier, 线程组中主线程的pid

#ifdef CONFIG_STACKPROTECTOR
        /* -fstack-protector GCC功能的Canary（金丝雀值）: */
        unsigned long                   stack_canary;
#endif
        /*
         * 指向（原始）父进程、最小的子进程、较年轻的兄弟姐妹、
         * 较年长的兄弟姐妹的指针。 （p->father可以被
         * p->real_parent->pid替代）
         */

        /* 真实的父进程: */
        struct task_struct __rcu        *real_parent;

        /* 接收SIGCHLD，wait4()报告: */
        struct task_struct __rcu        *parent;

        /*
         * 子/兄弟姐妹形成自然子女列表:
         */
        struct list_head                children;
        struct list_head                sibling;
        struct task_struct              *group_leader;

        /*
         * 'ptraced'是此任务使用ptrace()跟踪的任务列表。
         *
         * 这包括自然子女和PTRACE_ATTACH目标。
         * 'ptrace_entry'是此任务在p->parent->ptraced列表中的链接。
         */
        struct list_head                ptraced;
        struct list_head                ptrace_entry;

        /* PID/PID哈希表链接。 */
        struct pid                      *thread_pid;
        struct hlist_node               pid_links[PIDTYPE_MAX];
        struct list_head                thread_group;
        struct list_head                thread_node;

        struct completion               *vfork_done;

        /* CLONE_CHILD_SETTID: */
        int __user                      *set_child_tid;

        /* CLONE_CHILD_CLEARTID: */
        int __user                      *clear_child_tid;

        /* PF_KTHREAD | PF_IO_WORKER */
        void                            *worker_private;

        u64                             utime;
        u64                             stime;
#ifdef CONFIG_ARCH_HAS_SCALED_CPUTIME
        u64                             utimescaled;
        u64                             stimescaled;
#endif
        u64                             gtime;
        struct prev_cputime             prev_cputime;
#ifdef CONFIG_VIRT_CPU_ACCOUNTING_GEN
        struct vtime                    vtime;
#endif

#ifdef CONFIG_NO_HZ_FULL
        atomic_t                        tick_dep_mask;
#endif
        /* 上下文切换计数: */
        unsigned long                   nvcsw;
        unsigned long                   nivcsw;

        /* 单调时间，单位为纳秒: */
        u64                             start_time;

        /* 基于启动的时间，单位为纳秒: */
        u64                             start_boottime;

        /* MM故障和交换信息: 这可以说是mm特定或线程特定的: */
        unsigned long                   min_flt;
        unsigned long                   maj_flt;

        /* 如果CONFIG_POSIX_CPUTIMERS=n则为空 */
        struct posix_cputimers          posix_cputimers;

#ifdef CONFIG_POSIX_CPU_TIMERS_TASK_WORK
        struct posix_cputimers_work     posix_cputimers_work;
#endif

        /* 进程凭证: */

        /* 附加时的跟踪器凭证: */
        const struct cred __rcu         *ptracer_cred;

        /* 目标和实际的主观任务凭证 (COW): */
        const struct cred __rcu         *real_cred;

        /* 有效的（可重写的）主观任务凭证 (COW): */
        const struct cred __rcu         *cred;

#ifdef CONFIG_KEYS
        /* 缓存的请求密钥。 */
        struct key                      *cached_requested_key;
#endif

        /*
         * 可执行文件名，不包括路径。
         *
         * - 通常在setup_new_exec()中初始化
         * - 使用[gs]et_task_comm()访问它
         * - 使用task_lock()锁定它
         */
        char                            comm[TASK_COMM_LEN]; // command name

        struct nameidata                *nameidata;

#ifdef CONFIG_SYSVIPC
        struct sysv_sem                 sysvsem;
        struct sysv_shm                 sysvshm;
#endif
#ifdef CONFIG_DETECT_HUNG_TASK
        unsigned long                   last_switch_count;
        unsigned long                   last_switch_time;
#endif
        /* 文件系统信息: */
        struct fs_struct                *fs;

        /* 打开文件的信息: */
        struct files_struct             *files;

#ifdef CONFIG_IO_URING
        struct io_uring_task            *io_uring;
#endif

        /* 命名空间: */
        struct nsproxy                  *nsproxy;

        /* 信号处理程序: */
        struct signal_struct            *signal;
        struct sighand_struct __rcu     *sighand;
        sigset_t                        blocked;
        sigset_t                        real_blocked;
        /* 如果使用了set_restore_sigmask()则恢复: */
        sigset_t                        saved_sigmask;
        struct sigpending               pending;
        unsigned long                   sas_ss_sp;
        size_t                          sas_ss_size;
        unsigned int                    sas_ss_flags;

        struct callback_head            *task_works;

#ifdef CONFIG_AUDIT
#ifdef CONFIG_AUDITSYSCALL
        struct audit_context            *audit_context;
#endif
        kuid_t                          loginuid;
        unsigned int                    sessionid;
#endif
        struct seccomp                  seccomp;
        struct syscall_user_dispatch    syscall_dispatch;

        /* 线程组跟踪: */
        u64                             parent_exec_id;
        u64                             self_exec_id;

        /* 保护（取消）分配: mm, files, fs, tty, keyrings, mems_allowed, mempolicy: */
        spinlock_t                      alloc_lock;

        /* 保护PI数据结构: */
        raw_spinlock_t                  pi_lock;

        struct wake_q_node              wake_q;

#ifdef CONFIG_RT_MUTEXES
        /* 阻塞在由此任务持有的rt_mutex上的PI等待者: */
        struct rb_root_cached           pi_waiters;
        /* 在所有者的pi_lock和rq锁下更新 */
        struct task_struct              *pi_top_task;
        /* 死锁检测和优先级继承处理: */
        struct rt_mutex_waiter          *pi_blocked_on;
#endif

#ifdef CONFIG_DEBUG_MUTEXES
        /* 互斥死锁检测: */
        struct mutex_waiter             *blocked_on;
#endif

#ifdef CONFIG_DEBUG_ATOMIC_SLEEP
        int                             non_block_count;
#endif

#ifdef CONFIG_TRACE_IRQFLAGS
        struct irqtrace_events          irqtrace;
        unsigned int                    hardirq_threaded;
        u64                             hardirq_chain_key;
        int                             softirqs_enabled;
        int                             softirq_context;
        int                             irq_config;
#endif
#ifdef CONFIG_PREEMPT_RT
        int                             softirq_disable_cnt;
#endif

#ifdef CONFIG_LOCKDEP
# define MAX_LOCK_DEPTH                 48UL
        u64                             curr_chain_key;
        int                             lockdep_depth;
        unsigned int                    lockdep_recursion;
        struct held_lock                held_locks[MAX_LOCK_DEPTH];
#endif

#if defined(CONFIG_UBSAN) && !defined(CONFIG_UBSAN_TRAP)
        unsigned int                    in_ubsan;
#endif

        /* 日志文件系统信息: */
        void                            *journal_info;

        /* 叠加块设备信息: */
        struct bio_list                 *bio_list;

        /* 栈插入: */
        struct blk_plug                 *plug;

        /* VM状态: */
        struct reclaim_state            *reclaim_state;

        struct io_context               *io_context;

#ifdef CONFIG_COMPACTION
        struct capture_control          *capture_control;
#endif
        /* Ptrace状态: */
        unsigned long                   ptrace_message;
        kernel_siginfo_t                *last_siginfo;

        struct task_io_accounting       ioac;
#ifdef CONFIG_PSI
        /* 压力停滞状态 */
        unsigned int                    psi_flags;
#endif
#ifdef CONFIG_TASK_XACCT
        /* 累积的RSS使用量: */
        u64                             acct_rss_mem1;
        /* 累积的虚拟内存使用量: */
        u64                             acct_vm_mem1;
        /* 自上次更新以来的stime + utime: */
        u64                             acct_timexpd;
#endif
#ifdef CONFIG_CPUSETS
        /* 由 ->alloc_lock 保护: */
        nodemask_t                      mems_allowed;
        /* 捕捉更新的序列号: */
        seqcount_spinlock_t             mems_allowed_seq;
        int                             cpuset_mem_spread_rotor;
        int                             cpuset_slab_spread_rotor;
#endif
#ifdef CONFIG_CGROUPS
        /* 由 css_set_lock 保护的控制组信息: */
        struct css_set __rcu            *cgroups;
        /* cg_list 由 css_set_lock 和 tsk->alloc_lock 保护: */
        struct list_head                cg_list;
#endif
#ifdef CONFIG_X86_CPU_RESCTRL
        u32                             closid;
        u32                             rmid;
#endif
#ifdef CONFIG_FUTEX
        struct robust_list_head __user  *robust_list;
#ifdef CONFIG_COMPAT
        struct compat_robust_list_head __user *compat_robust_list;
#endif
        struct list_head                pi_state_list;
        struct futex_pi_state           *pi_state_cache;
        struct mutex                    futex_exit_mutex;
        unsigned int                    futex_state;
#endif
#ifdef CONFIG_PERF_EVENTS
        struct perf_event_context       *perf_event_ctxp;
        struct mutex                    perf_event_mutex;
        struct list_head                perf_event_list;
#endif
#ifdef CONFIG_DEBUG_PREEMPT
        unsigned long                   preempt_disable_ip;
#endif
#ifdef CONFIG_NUMA
        /* 由 alloc_lock 保护: */
        struct mempolicy                *mempolicy;
        short                           il_prev;
        short                           pref_node_fork;
#endif
#ifdef CONFIG_NUMA_BALANCING
        int                             numa_scan_seq;
        unsigned int                    numa_scan_period;
        unsigned int                    numa_scan_period_max;
        int                             numa_preferred_nid;
        unsigned long                   numa_migrate_retry;
        /* 迁移时间戳: */
        u64                             node_stamp;
        u64                             last_task_numa_placement;
        u64                             last_sum_exec_runtime;
        struct callback_head            numa_work;

        /*
         * 这个指针仅在系统调用和页面错误上下文（以及正在销毁的任务）中被修改，
         * 因此可以从以下任何上下文中读取:
         *  - RCU读侧关键部分
         *  - 从任何地方读取 current->numa_group
         *  - 任务的运行队列锁定，任务未运行
         */
        struct numa_group __rcu         *numa_group;

        /*
         * numa_faults 是一个分成四个区域的数组:
         * faults_memory, faults_cpu, faults_memory_buffer, faults_cpu_buffer
         * 按此精确顺序。
         *
         * faults_memory: 基于每个节点的故障的指数衰减平均值。
         * 调度位置决策基于这些计数。值在PTE扫描期间保持静态。
         * faults_cpu: 跟踪进程在遇到NUMA提示故障时运行的节点。
         * faults_memory_buffer 和 faults_cpu_buffer: 记录当前扫描窗口期间
         * 每个节点的故障。当扫描完成时，faults_memory 和 faults_cpu 的计数
         * 衰减，这些值被复制。
         */
        unsigned long                   *numa_faults;
        unsigned long                   total_numa_faults;

        /*
         * numa_faults_locality 跟踪在上一个扫描窗口期间记录的故障是否为远程/本地
         * 或迁移失败。任务扫描周期基于故障的局部性进行调整，
         * 具体权重取决于它们是否是共享或私有故障
         */
        unsigned long                   numa_faults_locality[3];

        unsigned long                   numa_pages_migrated;
#endif /* CONFIG_NUMA_BALANCING */

#ifdef CONFIG_RSEQ
        struct rseq __user *rseq;
        u32 rseq_len;
        u32 rseq_sig;
        /*
         * 对 rseq_event_mask 的读-修改-写操作必须在
         * 预取情况下以原子方式执行。
         */
        unsigned long rseq_event_mask;
#endif

#ifdef CONFIG_SCHED_MM_CID
        int                             mm_cid;         /* 当前 mm 中的 cid */
        int                             last_mm_cid;    /* 最近的 mm cid */
        int                             migrate_from_cpu;
        int                             mm_cid_active;  /* cid 位图是否处于活动状态 */
        struct callback_head            cid_work;
#endif

        struct tlbflush_unmap_batch     tlb_ubc;

        /* 缓存最近使用的 pipe 用于 splice(): */
        struct pipe_inode_info          *splice_pipe;

        struct page_frag                task_frag;

#ifdef CONFIG_TASK_DELAY_ACCT
        struct task_delay_info          *delays;
#endif

#ifdef CONFIG_FAULT_INJECTION
        int                             make_it_fail;
        unsigned int                    fail_nth;
#endif
        /*
         * 当 (nr_dirtied >= nr_dirtied_pause) 时，调用
         * balance_dirty_pages() 进行脏页节流暂停的时间:
         */
        int                             nr_dirtied;
        int                             nr_dirtied_pause;
        /* 写入和暂停周期的开始: */
        unsigned long                   dirty_paused_when;

#ifdef CONFIG_LATENCYTOP
        int                             latency_record_count;
        struct latency_record           latency_record[LT_SAVECOUNT];
#endif
        /*
         * 时间滑差值; 用于向上舍入 poll() 和
         * select() 等的超时值。单位为纳秒。
         */
        u64                             timer_slack_ns;
        u64                             default_timer_slack_ns;

#if defined(CONFIG_KASAN_GENERIC) || defined(CONFIG_KASAN_SW_TAGS)
        unsigned int                    kasan_depth;
#endif

#ifdef CONFIG_KCSAN
        struct kcsan_ctx                kcsan_ctx;
#ifdef CONFIG_TRACE_IRQFLAGS
        struct irqtrace_events          kcsan_save_irqtrace;
#endif
#ifdef CONFIG_KCSAN_WEAK_MEMORY
        int                             kcsan_stack_depth;
#endif
#endif

#ifdef CONFIG_KMSAN
        struct kmsan_ctx                kmsan_ctx;
#endif

#if IS_ENABLED(CONFIG_KUNIT)
        struct kunit                    *kunit_test;
#endif

#ifdef CONFIG_FUNCTION_GRAPH_TRACER
        /* 返回地址栈中当前存储地址的索引: */
        int                             curr_ret_stack;
        int                             curr_ret_depth;

        /* 返回函数追踪的返回地址栈: */
        struct ftrace_ret_stack         *ret_stack;

        /* 上次调度的时间戳: */
        unsigned long long              ftrace_timestamp;

        /*
         * 由于深度溢出而未被追踪的函数数量:
         */
        atomic_t                        trace_overrun;

        /* 暂停追踪: */
        atomic_t                        tracing_graph_pause;
#endif

#ifdef CONFIG_TRACING
        /* 追踪递归的位掩码和计数器: */
        unsigned long                   trace_recursion;
#endif /* CONFIG_TRACING */

#ifdef CONFIG_KCOV
        /* 详见 kernel/kcov.c */

        /* 为此任务启用的覆盖收集模式 (如果禁用则为 0): */
        unsigned int                    kcov_mode;

        /* kcov_area 的大小: */
        unsigned int                    kcov_size;

        /* 覆盖收集缓冲区: */
        void                            *kcov_area;

        /* 与此任务关联的 KCOV 描述符或 NULL: */
        struct kcov                     *kcov;

        /* 用于远程覆盖收集的 KCOV 公共句柄: */
        u64                             kcov_handle;

        /* KCOV 序列号: */
        int                             kcov_sequence;

        /* 从 softirq 上下文中收集覆盖率: */
        unsigned int                    kcov_softirq;
#endif

#ifdef CONFIG_MEMCG
        struct mem_cgroup               *memcg_in_oom;
        gfp_t                           memcg_oom_gfp_mask;
        int                             memcg_oom_order;

        /* 返回用户态时需要回收的页面数量: */
        unsigned int                    memcg_nr_pages_over_high;

        /* 由 memcontrol 用于有针对性的 memcg 收费: */
        struct mem_cgroup               *active_memcg;
#endif

#ifdef CONFIG_BLK_CGROUP
        struct gendisk                  *throttle_disk;
#endif

#ifdef CONFIG_UPROBES
        struct uprobe_task              *utask;
#endif
#if defined(CONFIG_BCACHE) || defined(CONFIG_BCACHE_MODULE)
        unsigned int                    sequential_io;
        unsigned int                    sequential_io_avg;
#endif
        struct kmap_ctrl                kmap_ctrl;
#ifdef CONFIG_DEBUG_ATOMIC_SLEEP
        unsigned long                   task_state_change;
# ifdef CONFIG_PREEMPT_RT
        unsigned long                   saved_state_change;
# endif
#endif
        struct rcu_head                 rcu;
        refcount_t                      rcu_users;
        int                             pagefault_disabled;
#ifdef CONFIG_MMU
        struct task_struct              *oom_reaper_list;
        struct timer_list               oom_reaper_timer;
#endif
#ifdef CONFIG_VMAP_STACK
        struct vm_struct                *stack_vm_area;
#endif
#ifdef CONFIG_THREAD_INFO_IN_TASK
        /* 活动任务持有一个引用: */
        refcount_t                      stack_refcount;
#endif
#ifdef CONFIG_LIVEPATCH
        int patch_state;
#endif
#ifdef CONFIG_SECURITY
        /* 由 LSM 模块用于访问限制: */
        void                            *security;
#endif
#ifdef CONFIG_BPF_SYSCALL
        /* 由 BPF 任务本地存储使用 */
        struct bpf_local_storage __rcu  *bpf_storage;
        /* 用于 BPF 运行上下文 */
        struct bpf_run_ctx              *bpf_ctx;
#endif

#ifdef CONFIG_GCC_PLUGIN_STACKLEAK
        unsigned long                   lowest_stack;
        unsigned long                   prev_lowest_stack;
#endif

#ifdef CONFIG_X86_MCE
        void __user                     *mce_vaddr;
        __u64                           mce_kflags;
        u64                             mce_addr;
        __u64                           mce_ripv : 1,
                                        mce_whole_page : 1,
                                        __mce_reserved : 62;
        struct callback_head            mce_kill_me;
        int                             mce_count;
#endif

#ifdef CONFIG_KRETPROBES
        struct llist_head               kretprobe_instances;
#endif
#ifdef CONFIG_RETHOOK
        struct llist_head               rethooks;
#endif

#ifdef CONFIG_ARCH_HAS_PARANOID_L1D_FLUSH
        /*
         * 如果支持在 mm 上下文切换时执行 L1D 清除，
         * 则我们使用此回调头来排队清除任务的工作，
         * 以终止未在 SMT 禁用的核心上运行的任务。
         */
        struct callback_head            l1d_flush_kill;
#endif

#ifdef CONFIG_RV
        /*
         * 每任务的 RV 监视器。如今固定在 RV_PER_TASK_MONITORS 中。
         * 如果我们找到更多监视器的理由，我们可以考虑
         * 添加更多或开发动态方法。到目前为止，
         * 这些都是没有理由的。
         */
        union rv_task_monitor           rv[RV_PER_TASK_MONITORS];
#endif

#ifdef CONFIG_USER_EVENTS
        struct user_event_mm            *user_event_mm;
#endif

        /*
         * 新的 task_struct 字段应添加在这里上方，以便
         * 它们包含在 task_struct 的随机部分中。
         */
        randomized_struct_fields_end

        /* 此任务的 CPU 特定状态: */
        struct thread_struct            thread;

        /*
         * 警告: 在 x86 上，'thread_struct' 包含一个变量大小的
         * 结构。它 *必须* 在 'task_struct' 的末尾。
         *
         * 不要在这里放置任何内容!
         */
};