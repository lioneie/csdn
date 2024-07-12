块设备是指硬盘、软盘驱动器、蓝光光驱、闪存等，能够随机访问固定大小的数据片（块）。

块设备（又叫硬扇区、设备块）最小可寻址单元是扇区，扇区大小最常见的是512字节。块（又叫文件块、I/O块）是文件系统的一种抽象，块大小不能超过一个page大小，通常是512B、1KB或4KB。

# 缓冲区

一个块与一个缓冲区对应，一个page可以包含一个或多个块，缓存区用缓冲区头结构体表示：
```c
/*
 * 在历史上，buffer_head 用于映射页面中的单个块，当然也是通过文件系统和块层进行 I/O 的单位。
 * 如今，基本的 I/O 单位是 bio，而 buffer_head 则用于提取块映射（通过 get_block_t 调用）、
 * 在页面内跟踪状态（通过 page_mapping）以及为了向后兼容性包装 bio 提交（例如 submit_bh）。
 */
struct buffer_head {
        unsigned long b_state;          /* buffer state bitmap (see above)，缓冲区状态标志，查看枚举bh_state_bits */
        struct buffer_head *b_this_page;/* circular list of page's buffers,页中的缓冲区 */
        union {
                struct page *b_page;    /* the page this bh is mapped to，存储b_data数据的page */
                struct folio *b_folio;  /* the folio this bh is mapped to */
        };

        sector_t b_blocknr;             /* start block number，b_bdev的起始块号 */
        size_t b_size;                  /* size of mapping，映像的大小 */
        char *b_data;                   /* pointer to data within the page，page中的数据指针，b_page中的某个位置，结束位置在b_data+b_size */

        struct block_device *b_bdev;    // 块设备
        bh_end_io_t *b_end_io;          /* I/O completion，io完成方法 */
        void *b_private;                /* reserved for b_end_io，也是io完成方法 */
        struct list_head b_assoc_buffers; /* associated with another mapping，映射链表 */
        struct address_space *b_assoc_map;      /* mapping this buffer is associated with，地址空间 */
        atomic_t b_count;               /* users using this buffer_head，使用计数，通过get_bh()和put_bh()操作 */
        spinlock_t b_uptodate_lock;     /* Used by the first bh in a page, to
                                         * serialise IO completion of other
                                         * buffers in the page */
};

enum bh_state_bits {
        BH_Uptodate,    /* Contains valid data，包含可用信息 */
        BH_Dirty,       /* Is dirty，比磁盘块内容新 */
        BH_Lock,        /* Is locked，被使用 */
        BH_Req,         /* Has been submitted for I/O，有I/O请求操作 */

        BH_Mapped,      /* Has a disk mapping，映射磁盘块的可用缓冲区 */
        BH_New,         /* Disk mapping was newly created by get_block，通过get_block()刚刚映射的，还不能访问 */
        BH_Async_Read,  /* Is under end_buffer_async_read I/O，正通过end_buffer_async_read()被异步io读 */
        BH_Async_Write, /* Is under end_buffer_async_write I/O，正通过end_buffer_async_write()被异步io写 */
        BH_Delay,       /* Buffer is not yet allocated on disk，还没和磁盘块关联 */
        BH_Boundary,    /* Block is followed by a discontiguity，下一个块不连续 */
        BH_Write_EIO,   /* I/O error on write，写的时候io错误 */
        BH_Unwritten,   /* Buffer is allocated on disk but not written，已和磁盘关联但还没写 */
        BH_Quiet,       /* Buffer Error Prinks to be quiet，错误不打印 */
        BH_Meta,        /* Buffer contains metadata */
        BH_Prio,        /* Buffer should be submitted with REQ_PRIO */
        BH_Defer_Completion, /* Defer AIO completion to workqueue */

        BH_PrivateStart,/* not a state bit, but the first bit available
                         * for private allocation by other entities，驱动程序可以使用的起始位
                         */
};
```