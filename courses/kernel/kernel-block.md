# 简介

块设备（block device）是指硬盘、软盘驱动器、蓝光光驱、闪存等，能够随机访问固定大小的数据片（块）。
字符设备（character device）是按字符流的方式有序访问，如串口和键盘。

对块设备和块设备的请求进行管理的子系统叫"块I/O层"（block I/O layer）。

块设备（又叫硬扇区、设备块）最小可寻址单元是扇区（sector），扇区大小最常见的是512字节。
块（block，又叫文件块、I/O块）是文件系统的一种抽象，是文件系统的最小寻址单元，块大小不能超过一个page大小，
只能是扇区的整数倍，通常是512B、1KB或4KB。

# 缓冲区和缓冲区头

一个块（block）与一个缓冲区（buffer）对应，一个page可以包含一个或多个块，缓存区用缓冲区头结构体表示:
```c
/*
 * 在历史上，buffer_head 用于映射页面中的单个块，当然也是通过文件系统和块层进行 I/O 的单位。
 * 如今，基本的 I/O 单位是 bio，而 buffer_head 则用于提取块映射（通过 get_block_t 调用）、
 * 在页面内跟踪状态（通过 page_mapping）以及为了向后兼容性包装 bio 提交（例如 submit_bh）。
 */
struct buffer_head {
        unsigned long b_state;          /* 缓冲区状态位图，查看枚举bh_state_bits */
        struct buffer_head *b_this_page;/* 页面缓冲区的循环链表 */
        union {
                struct page *b_page;    /* 此 bh 映射到的页面 */
                struct folio *b_folio;  /* 此 bh 映射到的 folio */
        };

        sector_t b_blocknr;             /* 起始块号 */
        size_t b_size;                  /* 映射的大小 */
        // 位于b_page的page上的某个位置，起始位置在b_data处，结束位置在b_data+b_size处
        char *b_data;                   /* 页面内数据的指针 */

        struct block_device *b_bdev;   /* 块设备 */
        bh_end_io_t *b_end_io;          /* I/O 完成回调 */
        void *b_private;                /* 保留给 b_end_io 使用 */
        struct list_head b_assoc_buffers; /* 与其他映射关联 */
        struct address_space *b_assoc_map;      /* 此缓冲区关联的映射 */
        atomic_t b_count;               /* 使用此 buffer_head 的用户计数，通过get_bh()和put_bh()操作 */
        spinlock_t b_uptodate_lock;     /* 页面中第一个 bh 使用的自旋锁，
                                         * 用于序列化页面中其他缓冲区的 IO 完成 */
};

enum bh_state_bits {
        BH_Uptodate,    /* 包含有效数据 */
        BH_Dirty,       /* 脏数据，比磁盘中的数据新 */
        BH_Lock,        /* 已加锁 */
        BH_Req,         /* 已提交 I/O 请求 */

        BH_Mapped,      /* 有磁盘映射 */
        BH_New,         /* 磁盘映射由 get_block 新创建，不能访问 */
        BH_Async_Read,  /* 正在执行 end_buffer_async_read 的异步 I/O */
        BH_Async_Write, /* 正在执行 end_buffer_async_write 的异步 I/O */
        BH_Delay,       /* 缓冲区尚未分配到磁盘 */
        BH_Boundary,    /* 块后面有不连续部分，处于边界，下一个块不再连续 */
        BH_Write_EIO,   /* 写入时发生 I/O 错误 */
        BH_Unwritten,   /* 缓冲区已分配到磁盘但未写入 */
        BH_Quiet,       /* 缓冲区错误消息静默 */
        BH_Meta,        /* 缓冲区包含元数据 */
        BH_Prio,        /* 缓冲区应以 REQ_PRIO 提交 */
        BH_Defer_Completion, /* 将异步 I/O 的完成延迟到工作队列 */

        BH_PrivateStart,/* 不是状态位，而是其他实体可私有分配的第一个可用位 */
};

typedef int (get_block_t)(struct inode *inode, sector_t iblock,    
                        struct buffer_head *bh_result, int create);
```

我们还会看到`buffer_uptodate()`、`set_buffer_uptodate()`、`buffer_uptodate()`之类的函数，但找不到函数定义，
这是因为函数定义是以宏定义的形式展开，具体可以看`BUFFER_FNS(bit, name)`。

# bio

块I/O操作的容器用`bio`结构体表示，以segment(一小块连续内存缓冲区)链表形式组织，一个缓冲区可以分散在内存的多个位置，叫向量I/O，又叫聚散I/O。

```c
/*
 * 块层和底层（例如驱动程序和堆叠驱动程序）的I/O主单元
 */
struct bio {
        struct bio              *bi_next;       /* 请求队列链接 */
        struct block_device     *bi_bdev;
        blk_opf_t               bi_opf;         /* 底部位 REQ_OP，顶部位
                                                 * req_flags。
                                                 */
        unsigned short          bi_flags;       /* BIO_* 标志 */
        unsigned short          bi_ioprio;
        blk_status_t            bi_status;
        atomic_t                __bi_remaining;

        // bi_iter.bi_idx表示bi_io_vec的当前索引，bi_iter.bi_idx在RAID中有多个
        struct bvec_iter        bi_iter;

        blk_qc_t                bi_cookie;
        bio_end_io_t            *bi_end_io;
        void                    *bi_private;
#ifdef CONFIG_BLK_CGROUP
        /*
         * 表示bio与css和请求队列的关联。
         * 如果bio直接传输到设备，它将没有blkg，因为它不会与请求队列关联。
         * 该引用会在bio释放时被释放。
         */
        struct blkcg_gq         *bi_blkg;
        struct bio_issue        bi_issue;
#ifdef CONFIG_BLK_CGROUP_IOCOST
        u64                     bi_iocost_cost;
#endif
#endif

#ifdef CONFIG_BLK_INLINE_ENCRYPTION
        struct bio_crypt_ctx    *bi_crypt_context;
#endif

        union {
#if defined(CONFIG_BLK_DEV_INTEGRITY)
                struct bio_integrity_payload *bi_integrity; /* 数据完整性 */
#endif
        };

        unsigned short          bi_vcnt;        /* bio_vec的数量 */

        /*
         * 从bi_max_vecs开始的所有成员将由bio_reset()保留
         */

        unsigned short          bi_max_vecs;    /* 我们可以容纳的最大bio_vecs数量 */

        atomic_t                __bi_cnt;       /* 引用计数 */ // 用bio_get()和bio_put()操作

        struct bio_vec          *bi_io_vec;     /* 实际的vec列表 */ // 整个数组表示完整的缓冲区

        struct bio_set          *bi_pool;

        /*
         * 我们可以在bio的末尾内联多个vec，以避免为少量bio_vecs进行双重分配。
         * 这个成员必须显然保持在bio的最后。
         */
        struct bio_vec          bi_inline_vecs[];
};
```

`bio`结构体的`bi_io_vec`成员指向一个向量（`<page, offset, len>`）数组:
```c
/**
 * struct bio_vec - 一个连续的物理内存地址范围
 * @bv_page:   与地址范围相关联的第一个页面。
 * @bv_len:    地址范围内的字节数。
 * @bv_offset: 相对于@bv_page起始位置的地址范围的起始位置。
 *
 * 如果n * PAGE_SIZE < bv_offset + bv_len，则以下条件成立：
 *
 *   nth_page(@bv_page, n) == @bv_page + n
 *
 * 这是因为page_is_mergeable()会检查上述属性。
 */
struct bio_vec {
        struct page     *bv_page;
        unsigned int    bv_len;
        unsigned int    bv_offset;
};
```

# I/O调度器介绍

用于保存挂起的块I/O请求的请求队列结构体是`struct request_queue`，队列中的每项请求用`struct request`（`include/linux/blk-mq.h`）表示，每个请求可以包含多个`bio`。

磁盘寻址是计算机中最慢的操作之一，为了优化，内核在将I/O请求提交给磁盘之前，会先执行合并与排序的预操作，我们将负责提交I/O请求的子系统称为I/O调度器（I/O Schedulers），注意有些书籍翻译成“I/O调度程序“。
I/O调度器将磁盘I/O资源分配给挂起的块I/O请求。

I/O调度器管理块设备的请求队列，减少磁盘寻址时间，提高全局吞吐量，注意提高“全局“意味着可能对某些请求不公平。

合并是将多个请求结合成一个请求，原本要执行的多次磁盘寻址就变成只需要一次磁盘寻址。排序是将请求按磁盘上扇区的排列顺序尽可能的有序排列，从而让磁盘头以直线方向移动，和电梯调度类似。

[参考内核文档](https://github.com/torvalds/linux/blob/master/Documentation/block/switching-sched.rst)，用以下命令查看和切换I/O调度器:
```sh
cat /sys/block/sda/queue/scheduler # 查看
  # [mq-deadline] kyber bfq none
echo none >/sys/block/sda/queue/scheduler # 切换
cat /sys/block/sda/queue/scheduler
  # [none] mq-deadline kyber bfq # 已经切换了
```

# 已淘汰的I/O调度器

我们先介绍几个现在最新的内核代码中已经淘汰了的I/O调度器，第一是因为资料多，第二是比较适合作为入门学习。

## Linus Elevator

Linus电梯在2.6版本中已经被取代了，但我们还是介绍一下，因为它足够简单。

当有新的I/O请求时，先检查挂起的请求是否可以和新请求合并:

- 向前合并: 新请求连在一个现存的挂起的请求前。
- 向后合并: 新请求连在一个现存的挂起的请求后。是概率比较大的合并类型，因为文件是以扇区号增长分布。

如果合并失败，就尝试按扇区方向为序插入。如果队列中存在一个驻留很久的请求，则新请求插入到队列尾部。

## Deadline

deadline I/O调度器被mq-deadline延续了，在最新的代码中已经没有了，是为了解决Linus Elevator的饥饿问题提出的。

Linus Elevator可能因为对某个磁盘区域的操作，让较远位置的其他请求永远得不到机会。
还可能造成writes starving reads的问题，写操作是异步的，读请求是同步的。

deadline I/O调度器的每个请求都有一个超时时间，写请求的超时时间比读请求长，写5s，读500ms。

涉及的几个队列:
```sh
Read FIFO queue
----------------> =========+
                           |
Write FIFO queue           v   dispatch queue    +----+
----------------> =========>   --------------->  |disk|
                           ^                     +----+
Sorted queue               |
----------------> =========+
```

请求除了插入排序队列，还会插入写请求队列或读请求队列，如果写请求队列或读请求队列的最前面的请求快超时了，就会立刻得到执行。
这样就避免了请求饥饿的发生。

## Anticipatory

最新的代码中已经没有这个I/O调度器了。
Anticipatory I/O调度器在deadline基础之上增加预测启发，调度器跟踪并统计每个应用程序块I/O操作的习惯行为，然后预测应用程序的未来行为。
读请求提交后等待6ms左右，如果有其他读请求到来，节省寻址次数。

## CFQ(Complete Fair Queuing)

CFQ I/O调度器已经被BFQ取代。CFQ是给每个进程维护一个请求队列，然后每个队列按扇区方向排序，以时间片轮转调度队列，从每个队列选取4个请求数。

## Noop

<!-- https://www.cnblogs.com/liulianzhen99/articles/18021188 -->

最新的代码中已经没有这个I/O调度器了，已经被多队列版本的none取代了。

Noop只做了合并的操作，适用于“寻址”代价小或没有代价的块设备。

<!-- ing begin -->
# mq-deadline

[参考文档](https://github.com/torvalds/linux/blob/master/Documentation/block/deadline-iosched.rst)

在`945ffb60c11d mq-deadline: add blk-mq adaptation of the deadline IO scheduler`引入。

# bfq

https://github.com/torvalds/linux/blob/master/Documentation/block/bfq-iosched.rst

# kyber

https://github.com/torvalds/linux/blob/master/Documentation/block/kyber-iosched.rst

<!-- ing end -->

