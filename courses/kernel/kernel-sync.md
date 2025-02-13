# 简介

内核线程、中断处理程序、陷入内核的用户进程，称为执行线程（threads of execution），多个执行线程并发访问共享资源，会造成数据不一致。

很多年前，只支持单核处理器的时代，避免并发访问数据很简单，只有中断发生时和重新调度执行另一个进程时，才会有并发访问数据的可能。

现在内核支持对称多处理器，数据可能同时被多个处理器同时访问。在支持抢占后，调度器还可能在任何时刻抢占正在运行的代码，重新调度执行其他进程。

避免并发和防止竞争条件称为同步（synchronization）。
这里介绍几个概念:

- 临界区: 访问和操作共享数据的代码段，叫临界区（critical regions），双叫临界段（critical sections）。
- 竞争条件: 临界区必须保证原子执行，如果多个执行线程在同一临界区同时执行，称为竞争条件（race condition）。

# rcu函数接口

```c
/**
 * rcu_assign_pointer() - 分配给RCU保护的指针
 * @p: 要赋值的指针
 * @v: 要赋值的内容 (publish)
 *
 * 将指定的值分配给指定的RCU保护指针，确保任何并发的RCU读操作能够看到
 * 任何先前的初始化。
 *
 * 在需要内存屏障的架构上插入内存屏障（大多数架构都需要），并且还防止编译器重新排序
 * 在指针赋值之后初始化结构的代码。更重要的是，这个调用文档化了哪些指针
 * 会被RCU读操作代码解引用。
 *
 * 在某些特殊情况下，你可以使用RCU_INIT_POINTER()来替代
 * rcu_assign_pointer()。RCU_INIT_POINTER()稍微快一些，因为
 * 它不会对CPU或编译器进行约束。尽管如此，当你应该使用
 * rcu_assign_pointer()时使用RCU_INIT_POINTER()是非常糟糕的事情，
 * 会导致无法诊断的内存损坏。所以请小心使用。
 * 请参见RCU_INIT_POINTER()的注释头部了解更多细节。
 *
 * 注意，rcu_assign_pointer()仅对每个参数进行一次求值，不论其出现次数。
 * 其中一个“额外”的求值在typeof()中，另一个只对sparse (__CHECKER__)可见，
 * 它们实际上并不会执行该参数。像大多数cpp宏一样，这种仅执行一次参数的属性
 * 很重要，因此在修改rcu_assign_pointer()和它调用的其他宏时，请小心。
 */
#define rcu_assign_pointer(p, v)

/**
 * rcu_dereference_protected() - 在"更新被防止时"获取RCU指针
 * @p: 要读取的指针，在解引用之前
 * @c: 解引用发生的条件
 *
 * 返回指定的RCU保护指针的值，但省略了READ_ONCE()。
 * 这在更新端锁防止指针值改变的情况下很有用。请注意，这个原语并不会防止编译器重复引用该指针
 * 或者将其与其他引用合并，因此在没有适当锁保护的情况下不应使用。
 *
 * 该函数仅供更新端使用。仅由rcu_read_lock()保护时使用此函数将导致不频繁但非常糟糕的失败。
 */
#define rcu_dereference_protected(p, c)

/**
 * kfree_rcu() - 在延迟期后释放对象
 * @ptr: 需要释放的指针，对于双参数调用的情况。
 * @rhf: 在@ptr类型中的struct rcu_head的名称。
 *
 * 许多RCU回调函数只是对基础结构调用kfree()。
 * 这些函数很简单，但它们的大小会逐渐增加，此外，当它们在内核模块中使用时，该模块必须在卸载时调用
 * 高延迟的rcu_barrier()函数。
 *
 * kfree_rcu()函数解决了这个问题。  kfree_rcu()并没有在嵌入的rcu_head结构中编码一个函数地址，而是
 * 编码了rcu_head结构在基础结构中的偏移量。
 * 由于函数不能位于内核虚拟内存的低位4096字节内，因此最大可以支持4095字节的偏移量。
 * 如果偏移量大于4095字节，则在kvfree_rcu_arg_2()中将产生编译时错误。如果此错误被触发，可以
 * 回退到使用call_rcu()，或重新安排结构，将rcu_head结构放置在前4096字节内。
 *
 * 要释放的对象可以通过kmalloc()或
 * kmem_cache_alloc()分配。
 *
 * 请注意，允许的偏移量在未来可能会减少。
 *
 * BUILD_BUG_ON检查不能涉及任何函数调用，因此检查是在宏中完成的。
 */
#define kfree_rcu(ptr, rhf) kvfree_rcu_arg_2(ptr, rhf)

/**
 * rcu_access_pointer() - 获取RCU指针但不进行解引用
 * @p: 要读取的指针
 *
 * 返回指定的RCU保护指针的值，但省略了在RCU读侧临界区内的lockdep检查。
 * 这在仅访问指针值但不解引用指针的情况下非常有用，例如，在测试RCU保护的指针
 * 是否为NULL时。虽然rcu_access_pointer()也可以用于更新端锁防止指针值改变的情况，但
 * 在这种情况下应使用rcu_dereference_protected()。
 * 在RCU读侧临界区内，几乎没有理由使用rcu_access_pointer()。
 *
 * 通常最好直接测试rcu_access_pointer()的返回值
 * 以避免后续不小心的更改引入意外的解引用。换句话说，将rcu_access_pointer()返回值赋值
 * 给一个局部变量会导致潜在的事故。
 *
 * 当读侧访问指针至少在一个延迟期之前被移除时，使用rcu_access_pointer()也是允许的，
 * 例如在RCU回调中释放数据时，或者在synchronize_rcu()返回后。这在延迟期过后拆解
 * 多链结构时非常有用。然而，rcu_dereference_protected()通常更适合这种情况。
 */
#define rcu_access_pointer(p) __rcu_access_pointer((p), __UNIQUE_ID(rcu), __rcu)

/**
 * rcu_read_lock() - 标记RCU读侧临界区的开始
 *
 * 当一个CPU调用synchronize_rcu()，而其他CPU正在RCU读侧临界区内时，
 * synchronize_rcu()会被阻塞，直到所有其他CPU退出其临界区。同样地，如果一个CPU调用
 * call_rcu()，而其他CPU正在RCU读侧临界区内，那么相应的RCU回调会延迟，直到所有其他
 * CPU退出其临界区。
 *
 * 在v5.0及更高版本的内核中，synchronize_rcu()和call_rcu()还会等待禁用抢占的代码区域，
 * 包括禁用中断或软中断的代码区域。在v5.0之前的内核（定义了synchronize_sched()）中，
 * 只有在rcu_read_lock()和rcu_read_unlock()之间的代码才会被保证等待。
 *
 * 需要注意的是，RCU回调允许与新的RCU读侧临界区并行运行。这可以通过以下事件序列发生：
 * (1) CPU 0进入RCU读侧临界区，(2) CPU 1调用call_rcu()注册RCU回调，(3) CPU 0退出RCU读侧临界区，
 * (4) CPU 2进入RCU读侧临界区，(5) RCU回调被调用。这是合法的，因为与call_rcu()并发运行的RCU读侧
 * 临界区（因此可能引用正在被相应RCU回调释放的内容）在相应的RCU回调被调用之前已完成。
 *
 * RCU读侧临界区可以嵌套。任何延迟的操作都会被推迟，直到最外层的RCU读侧临界区完成。
 *
 * 你可以通过遵循这个规则避免理解下一段内容：不要在!PREEMPTION内核中的rcu_read_lock() RCU
 * 读侧临界区中放入任何可能阻塞的代码。但是如果你想了解完整的情况，请继续阅读！
 *
 * 在非可抢占RCU实现（纯TREE_RCU和TINY_RCU）中，在RCU读侧临界区内阻塞是非法的。
 * 在可抢占RCU实现（PREEMPT_RCU）和CONFIG_PREEMPTION内核构建中，RCU读侧临界区
 * 可以被抢占，但显式阻塞是非法的。最后，在实时内核实现（带有-rt补丁集）中，RCU读侧临界区
 * 既可以被抢占，也可以阻塞，但只有在获取需要优先级继承的自旋锁时才允许阻塞。
 */
static __always_inline void rcu_read_lock(void)

/*
 * 那么，rcu_write_lock在哪里？ 它不存在，因为没有办法让写者锁住RCU读者。
 * 这是一个特性，而不是错误——这个属性正是RCU带来性能优势的原因。
 * 当然，写者必须彼此协调。正常的自旋锁原语可以很好地完成此工作，
 * 但也可以使用任何其他技术。RCU并不关心写者如何避免彼此冲突，
 * 只要它们能够做到这一点。
 */

/**
 * rcu_read_unlock() - 标记RCU读侧临界区的结束
 *
 * 在几乎所有情况下，rcu_read_unlock()都不会导致死锁。
 * 在最近的内核版本中，将synchronize_sched()和synchronize_rcu_bh()合并成
 * synchronize_rcu()后，这种免死锁性质也扩展到调度器的运行队列和优先级继承的
 * 自旋锁，这是通过在禁用中断时调用rcu_read_unlock()时进行的平稳状态延迟完成的。
 *
 * 请参见rcu_read_lock()了解更多信息。
 */
static inline void rcu_read_unlock(void)

/**
 * rcu_dereference() - 获取RCU保护的指针以便解引用
 * @p: 要读取的指针，在解引用之前
 *
 * 这是一个对rcu_dereference_check()的简单包装。
 */
#define rcu_dereference(p) rcu_dereference_check(p, 0)

/**
 * rcu_dereference_check() - 带有调试检查的rcu_dereference
 * @p: 要读取的指针，在解引用之前
 * @c: 解引用操作发生时的条件
 *
 * 执行rcu_dereference()，同时检查解引用发生时的条件是否正确。通常，条件
 * 用于表示此时应该保持的各种锁定条件。若条件满足，则检查应返回true。包括隐式检查
 * 是否处于RCU读取侧临界区（rcu_read_lock()）。
 *
 * 例如：
 *
 *      bar = rcu_dereference_check(foo->bar, lockdep_is_held(&foo->lock));
 *
 * 可以用来告诉lockdep，只有在rcu_read_lock()被持有，或者持有了替换foo->bar时所需的锁，
 * 才能解引用foo->bar。
 *
 * 注意，条件列表还可能包含某些情况下无需持有锁的指示，例如在目标结构的初始化或销毁期间：
 *
 *      bar = rcu_dereference_check(foo->bar, lockdep_is_held(&foo->lock) ||
 *                                            atomic_read(&foo->usage) == 0);
 *
 * 在需要内存屏障的架构上插入内存屏障（当前仅限Alpha架构），防止编译器重新获取指针值
 *（并避免合并获取），更重要的是，文档化哪些指针受RCU保护，并检查该指针是否已标注为__rcu。
 */
#define rcu_dereference_check(p, c) \
        __rcu_dereference_check((p), __UNIQUE_ID(rcu), \
                                (c) || rcu_read_lock_held(), __rcu)
```

