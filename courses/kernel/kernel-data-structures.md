# radix tree

数据结构如下:
```c
struct radix_tree_root {                     
        spinlock_t              xa_lock;     
        gfp_t                   gfp_mask;    
        struct radix_tree_node  __rcu *rnode;
};                                           
```

函数接口:
```c
/**
 * radix_tree_delete_item - 从基数树中删除一个条目
 * @root: 基数树的根
 * @index: 索引键
 * @item: 预期的条目
 * 
 * 从以 @root 为根的基数树中删除位于 @index 的 @item。
 * 
 * 返回：已删除的条目，如果条目不存在或给定 @index 处的条目不是 @item，则返回 %NULL。
 */
void *radix_tree_delete_item(struct radix_tree_root *root,
                             unsigned long index, void *item)
```

# idr

IDR（ID Radix Tree）是一种数据结构，用于管理小范围的整数 ID 到指针的映射。IDR 提供了一种高效的方式来分配和管理整数 ID，特别适用于需要快速分配和查找 ID 的场景。

数据结构:
```c
struct idr {                             
        struct radix_tree_root  idr_rt;  
        unsigned int            idr_base;
        unsigned int            idr_next;
};                                       
```

函数接口:
```c
/**
 * idr_alloc_u32() - 分配一个 ID。
 * @idr: IDR 句柄。
 * @ptr: 要与新 ID 关联的指针。
 * @nextid: 指向一个 ID 的指针。
 * @max: 要分配的最大 ID（包括在内）。
 * @gfp: 内存分配标志。
 * 
 * 在 @nextid 和 @max 指定的范围内分配一个未使用的 ID。
 * 注意，@max 是包括在内的，而 idr_alloc() 的 @end 参数是排除的。
 * 新 ID 在指针插入 IDR 之前分配给 @nextid，因此如果 @nextid 指向
 * @ptr 所指向的对象，则并发查找不会找到未初始化的 ID。
 * 
 * 调用者应提供自己的锁定机制，以确保不会发生两个对 IDR 的并发修改。
 * 对 IDR 的只读访问可以在 RCU 读锁下进行，或者可以排除同时写入者。
 * 
 * 返回：如果分配了 ID，则返回 0；如果内存分配失败，则返回 -ENOMEM；
 * 如果找不到空闲 ID，则返回 -ENOSPC。如果发生错误，@nextid 不会改变。
 */                                                                       
int idr_alloc_u32(struct idr *idr, void *ptr, u32 *nextid,                
                        unsigned long max, gfp_t gfp)                     

/**
 * idr_alloc() - 分配一个 ID。
 * @idr: IDR 句柄。
 * @ptr: 要与新 ID 关联的指针。
 * @start: 最小 ID（包括在内）。
 * @end: 最大 ID（不包括在内）。
 * @gfp: 内存分配标志。
 * 
 * 在 @start 和 @end 指定的范围内分配一个未使用的 ID。如果 @end <= 0，
 * 则将其视为比 %INT_MAX 大一。这允许调用者使用 @start + N 作为 @end，
 * 只要 N 在整数范围内。
 * 
 * 调用者应提供自己的锁定机制，以确保不会发生两个对 IDR 的并发修改。
 * 对 IDR 的只读访问可以在 RCU 读锁下进行，或者可以排除同时写入者。
 * 
 * 返回：新分配的 ID，如果内存分配失败，则返回 -ENOMEM；
 * 如果找不到空闲 ID，则返回 -ENOSPC。
 */
int idr_alloc(struct idr *idr, void *ptr, int start, int end, gfp_t gfp)

/**
 * idr_alloc_cyclic() - 循环分配一个 ID。
 * @idr: IDR 句柄。
 * @ptr: 要与新 ID 关联的指针。
 * @start: 最小 ID（包括在内）。
 * @end: 最大 ID（不包括在内）。
 * @gfp: 内存分配标志。
 * 
 * 在 @start 和 @end 指定的范围内分配一个未使用的 ID。如果 @end <= 0，
 * 则将其视为比 %INT_MAX 大一。这允许调用者使用 @start + N 作为 @end，
 * 只要 N 在整数范围内。对未使用 ID 的搜索将从最后一个分配的 ID 开始，
 * 如果在到达 @end 之前找不到空闲的 ID，将循环到 @start。
 * 
 * 调用者应提供自己的锁定机制，以确保不会发生两个对 IDR 的并发修改。
 * 对 IDR 的只读访问可以在 RCU 读锁下进行，或者可以排除同时写入者。
 * 
 * 返回：新分配的 ID，如果内存分配失败，则返回 -ENOMEM；
 * 如果找不到空闲 ID，则返回 -ENOSPC。
 */
int idr_alloc_cyclic(struct idr *idr, void *ptr, int start, int end, gfp_t gfp)

/**
 * idr_remove() - 从 IDR 中移除一个 ID。
 * @idr: IDR 句柄。
 * @id: 指针 ID。
 * 
 * 从 IDR 中移除该 ID。如果该 ID 之前不在 IDR 中，则此函数返回 %NULL。
 * 
 * 由于此函数会修改 IDR，调用者应提供自己的锁定机制，以确保不会发生
 * 对同一 IDR 的并发修改。
 * 
 * 返回：以前与该 ID 关联的指针。
 */
void *idr_remove(struct idr *idr, unsigned long id)

/**
 * idr_find() - 返回给定 ID 的指针。
 * @idr: IDR 句柄。
 * @id: 指针 ID。
 * 
 * 查找与此 ID 关联的指针。%NULL 指针可能表示 @id 未分配或与此 ID 关联的
 * 是 %NULL 指针。
 * 
 * 如果叶指针的生命周期管理正确，则此函数可以在 rcu_read_lock() 下调用。
 * 
 * 返回：与此 ID 关联的指针。
 */
void *idr_find(const struct idr *idr, unsigned long id)

/**
 * idr_for_each() - 遍历所有存储的指针。
 * @idr: IDR 句柄。
 * @fn: 每个指针要调用的函数。
 * @data: 传递给回调函数的数据。
 * 
 * 对 @idr 中的每个条目调用回调函数，传递 ID、条目和 @data。
 * 
 * 如果 @fn 返回任何非零值，迭代将停止，并且该值将从此函数返回。
 * 
 * 如果受到 RCU 保护，idr_for_each() 可以与 idr_alloc() 和 idr_remove()
 * 并发调用。新添加的条目可能不会被看到，而已删除的条目可能会被看到，
 * 但添加和删除条目不会导致其他条目被跳过，也不会看到虚假的条目。
 */
int idr_for_each(const struct idr *idr,
                int (*fn)(int id, void *p, void *data), void *data)
```