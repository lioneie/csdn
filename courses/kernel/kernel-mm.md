我们知道，操作系统是横跨软件和硬件的桥梁，其中内存寻址是操作系统设计的硬件基础之一。

# 内存相关概念

先介绍几个概念。

```sh
logical                 linear              physical
address  +------------+ address  +--------+ address
-------->|segmentation|--------->| paging |--------->
         |   unit     |          |  unit  |
         +------------+          +--------+
```

MMU，英文全称Memory Management Unit，中文翻译为内存管理单元，又叫分页内存管理单元（Paged Memory Management Unit），把虚拟地址转换成物理地址。MMU以page大小为单位管理内存，虚拟内存的最小单位就是page。


# 页

```c
struct page {
        unsigned long flags;            /* 原子标志，其中一些可能被异步更新 */

        union page_union_1;
        union page_union_2;

        /* 使用计数。*不要直接使用*。请参见 page_ref.h 头文件 */
        // page_count()返回0代表空闲
        atomic_t _refcount;

#ifdef CONFIG_MEMCG
        unsigned long memcg_data;
#endif

        /*
         * 在所有 RAM 都映射到内核地址空间的机器上，
         * 我们可以简单地计算虚拟地址。在具有 highmem 的机器上，
         * 部分内存会动态映射到内核虚拟内存中，因此我们需要一个地方来存储该地址。
         * 请注意，在 x86 上这个字段可以是 16 位的 ... ;)
         *
         * 具有慢速乘法运算的架构可以在 asm/page.h 中定义
         * WANT_PAGE_VIRTUAL
         */
#if defined(WANT_PAGE_VIRTUAL)
        void *virtual;                  /* Kernel virtual address (NULL if
                                           not kmapped, ie. highmem) */
#endif /* WANT_PAGE_VIRTUAL */

#ifdef CONFIG_KMSAN
        /*
         * KMSAN metadata for this page:
         *  - shadow page: every bit indicates whether the corresponding
         *    bit of the original page is initialized (0) or not (1);
         *  - origin page: every 4 bytes contain an id of the stack trace
         *    where the uninitialized value was created.
         */
        struct page *kmsan_shadow;
        struct page *kmsan_origin;
#endif

#ifdef LAST_CPUPID_NOT_IN_PAGE_FLAGS
        int _last_cpupid;
#endif
} _struct_page_alignment;

/*
 * 这个联合体中有五个字（20/40字节）可用。
 * 警告：第一个字的第0位用于 PageTail()。这意味着
 * 这个联合体的其他使用者不能使用这个位，以避免
 * 冲突和误报的 PageTail()。
 */
union page_union_1 {
        struct {        /* Page cache and anonymous pages */
                /**
                    * @lru: Pageout list, eg. active_list protected by
                    * lruvec->lru_lock.  Sometimes used as a generic list
                    * by the page owner.
                    */
                union {
                        struct list_head lru;

                        /* Or, for the Unevictable "LRU list" slot */
                        struct {
                                /* Always even, to negate PageTail */
                                void *__filler;
                                /* Count page's or folio's mlocks */
                                unsigned int mlock_count;
                        };

                        /* Or, free page */
                        struct list_head buddy_list;
                        struct list_head pcp_list;
                };
                /* See page-flags.h for PAGE_MAPPING_FLAGS */
                struct address_space *mapping;
                union {
                        pgoff_t index;          /* Our offset within mapping. */
                        unsigned long share;    /* share count for fsdax */
                };
                /**
                    * @private: Mapping-private opaque data.
                    * Usually used for buffer_heads if PagePrivate.
                    * Used for swp_entry_t if PageSwapCache.
                    * Indicates order in the buddy system if PageBuddy.
                    */
                unsigned long private;
        };
        struct {        /* page_pool used by netstack */
                /**
                    * @pp_magic: magic value to avoid recycling non
                    * page_pool allocated pages.
                    */
                unsigned long pp_magic;
                struct page_pool *pp;
                unsigned long _pp_mapping_pad;
                unsigned long dma_addr;
                union {
                        /**
                            * dma_addr_upper: might require a 64-bit
                            * value on 32-bit architectures.
                            */
                        unsigned long dma_addr_upper;
                        /**
                            * For frag page support, not supported in
                            * 32-bit architectures with 64-bit DMA.
                            */
                        atomic_long_t pp_frag_count;
                };
        };
        struct {        /* Tail pages of compound page */
                unsigned long compound_head;    /* Bit zero is set */
        };
        struct {        /* ZONE_DEVICE pages */
                /** @pgmap: Points to the hosting device page map. */
                struct dev_pagemap *pgmap;
                void *zone_device_data;
                /*
                    * ZONE_DEVICE private pages are counted as being
                    * mapped so the next 3 words hold the mapping, index,
                    * and private fields from the source anonymous or
                    * page cache page while the page is migrated to device
                    * private memory.
                    * ZONE_DEVICE MEMORY_DEVICE_FS_DAX pages also
                    * use the mapping, index, and private fields when
                    * pmem backed DAX files are mapped.
                    */
        };

        /** @rcu_head: You can use this to free a page by RCU. */
        struct rcu_head rcu_head;
}

/* 这个联合体的大小是4字节。 */
union page_union_2 {
        /*
            * If the page can be mapped to userspace, encodes the number
            * of times this page is referenced by a page table.
            */
        atomic_t _mapcount;

        /*
            * If the page is neither PageSlab nor mappable to userspace,
            * the value stored here may help determine what this page
            * is used for.  See page-flags.h for a list of page types
            * which are currently stored here.
            */
        unsigned int page_type;
}
```

`flags`字段里的每一位定义在`enum pageflags`。在内核代码中，我们经常看到类似`SetPageError`、`PagePrivate`的函数，但总是找不到定义，这是因为这些函数是通过宏定义生成的。宏定义是对`enum pageflags`中的每个值进行宏展开，这里列出设置和检测的宏定义：
```c
// 检测
#define TESTPAGEFLAG(uname, lname, policy)                       
static __always_inline int Page##uname(struct page *page)        
        { return test_bit(PG_##lname, &policy(page, 0)->flags); }

// 设置                                          
#define SETPAGEFLAG(uname, lname, policy)                        
static __always_inline void SetPage##uname(struct page *page)    
        { set_bit(PG_##lname, &policy(page, 1)->flags); }        
```

页的拥有者可能是用户空间进程、动态分配的内核数据、静态内核代、页调整缓存等。

页的大小可以用`getconf -a | grep PAGESIZE`命令查看。`x86`默认打开配置`CONFIG_HAVE_PAGE_SIZE_4KB`和`CONFIG_PAGE_SIZE_4KB`。

