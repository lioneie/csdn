# 简介

块设备是指硬盘、软盘驱动器、蓝光光驱、闪存等，能够随机访问固定大小的数据片（块）。字符设备是按字符流的方式有序访问，如串口和键盘。

对块设备和块设备的请求进行管理的子系统叫"块I/O层"。

块设备（又叫硬扇区、设备块）最小可寻址单元是扇区（sector），扇区大小最常见的是512字节。块（又叫文件块、I/O块）是文件系统的一种抽象，是文件系统的最小寻址单元，块大小不能超过一个page大小，只能是扇区的整数倍，通常是512B、1KB或4KB。

# 缓冲区和缓冲区头

一个块与一个缓冲区对应，一个page可以包含一个或多个块，缓存区用缓冲区头结构体表示:
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
```