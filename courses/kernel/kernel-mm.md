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

页的拥有者可能是用户空间进程、动态分配的内核数据、静态内核代、页高速缓存等。

页的大小可以用`getconf -a | grep PAGESIZE`命令查看。`x86`默认打开配置`CONFIG_HAVE_PAGE_SIZE_4KB`和`CONFIG_PAGE_SIZE_4KB`。

# 区

内核使用区（zone）对相似特性的页进行分组，描述的是物理内存。定义在`include/linux/mmzone.h`：
```c
enum zone_type {
        /*
         * ZONE_DMA 和 ZONE_DMA32 用于当外设无法对所有可寻址内存（ZONE_NORMAL）进行 DMA 时。
         * 在该区域覆盖整个 32 位地址空间的架构上使用 ZONE_DMA32。对于具有较小 DMA 地址限制的
         * 架构，保留 ZONE_DMA。当定义了 ZONE_DMA32 时，假定 32 位 DMA 掩码。
         * 一些 64 位平台可能需要同时使用这两个区域，因为它们支持具有不同 DMA 地址限制的外设。
         */
#ifdef CONFIG_ZONE_DMA
        ZONE_DMA,
#endif
#ifdef CONFIG_ZONE_DMA32
        ZONE_DMA32,
#endif
        /*
         * Normal addressable memory is in ZONE_NORMAL. DMA operations can be
         * performed on pages in ZONE_NORMAL if the DMA devices support
         * transfers to all addressable memory.
         */
        ZONE_NORMAL,
#ifdef CONFIG_HIGHMEM
        /*
         * A memory area that is only addressable by the kernel through
         * mapping portions into its own address space. This is for example
         * used by i386 to allow the kernel to address the memory beyond
         * 900MB. The kernel will set up special mappings (page
         * table entries on i386) for each page that the kernel needs to
         * access.
         */
        ZONE_HIGHMEM,
#endif
        /*
         * ZONE_MOVABLE is similar to ZONE_NORMAL, except that it contains
         * movable pages with few exceptional cases described below. Main use
         * cases for ZONE_MOVABLE are to make memory offlining/unplug more
         * likely to succeed, and to locally limit unmovable allocations - e.g.,
         * to increase the number of THP/huge pages. Notable special cases are:
         *
         * 1. Pinned pages: (long-term) pinning of movable pages might
         *    essentially turn such pages unmovable. Therefore, we do not allow
         *    pinning long-term pages in ZONE_MOVABLE. When pages are pinned and
         *    faulted, they come from the right zone right away. However, it is
         *    still possible that address space already has pages in
         *    ZONE_MOVABLE at the time when pages are pinned (i.e. user has
         *    touches that memory before pinning). In such case we migrate them
         *    to a different zone. When migration fails - pinning fails.
         * 2. memblock allocations: kernelcore/movablecore setups might create
         *    situations where ZONE_MOVABLE contains unmovable allocations
         *    after boot. Memory offlining and allocations fail early.
         * 3. Memory holes: kernelcore/movablecore setups might create very rare
         *    situations where ZONE_MOVABLE contains memory holes after boot,
         *    for example, if we have sections that are only partially
         *    populated. Memory offlining and allocations fail early.
         * 4. PG_hwpoison pages: while poisoned pages can be skipped during
         *    memory offlining, such pages cannot be allocated.
         * 5. Unmovable PG_offline pages: in paravirtualized environments,
         *    hotplugged memory blocks might only partially be managed by the
         *    buddy (e.g., via XEN-balloon, Hyper-V balloon, virtio-mem). The
         *    parts not manged by the buddy are unmovable PG_offline pages. In
         *    some cases (virtio-mem), such pages can be skipped during
         *    memory offlining, however, cannot be moved/allocated. These
         *    techniques might use alloc_contig_range() to hide previously
         *    exposed pages from the buddy again (e.g., to implement some sort
         *    of memory unplug in virtio-mem).
         * 6. ZERO_PAGE(0), kernelcore/movablecore setups might create
         *    situations where ZERO_PAGE(0) which is allocated differently
         *    on different platforms may end up in a movable zone. ZERO_PAGE(0)
         *    cannot be migrated.
         * 7. Memory-hotplug: when using memmap_on_memory and onlining the
         *    memory to the MOVABLE zone, the vmemmap pages are also placed in
         *    such zone. Such pages cannot be really moved around as they are
         *    self-stored in the range, but they are treated as movable when
         *    the range they describe is about to be offlined.
         *
         * In general, no unmovable allocations that degrade memory offlining
         * should end up in ZONE_MOVABLE. Allocators (like alloc_contig_range())
         * have to expect that migrating pages in ZONE_MOVABLE can fail (even
         * if has_unmovable_pages() states that there are no unmovable pages,
         * there can be false negatives).
         */
        ZONE_MOVABLE,
#ifdef CONFIG_ZONE_DEVICE
        ZONE_DEVICE,
#endif
        __MAX_NR_ZONES

};
```

内存区域的划分取决于体系结构，有些体系结构上所有的内存都是`ZONE_NORMAL`。

32位`x86`的：

- `ZONE_DMA`范围是`0~16M`。
- `ZONE_NORMAL`的范围是`16~896M`。
- `ZONE_HIGHMEM`的范围是大于`896M`的内存。

而64位`x86_64`则没有`ZONE_HIGHMEM`。

每个区用结构结构体`struct zone`表示:
```c
enum zone_watermarks {
        WMARK_MIN, // 最低水印。当可用内存低于此水印时，内核将强制执行紧急内存回收操作，以确保系统不会耗尽内存
        WMARK_LOW, // 低水印。当可用内存低于此水印但高于最低水印时，内核将开始执行内存回收操作，但不会像最低水印那么紧急
        WMARK_HIGH, // 高水印。当可用内存高于此水印时，内核认为系统内存充足，不需要进行内存回收操作
        WMARK_PROMO, // promotion提升，一种优化机制，用于更细粒度地控制内存分配和回收。它的作用是当内存压力较高时，将某些内存区域的水印提升到较高水平，以便更积极地进行内存回收，防止内存耗尽的风险。
        NR_WMARK      
};                    

struct zone {
        /* Read-mostly fields */

        /* zone watermarks, access with *_wmark_pages(zone) macros */
        unsigned long _watermark[NR_WMARK]; // 查看zone_watermarks
        unsigned long watermark_boost;

        unsigned long nr_reserved_highatomic;

        /*
         * We don't know if the memory that we're going to allocate will be
         * freeable or/and it will be released eventually, so to avoid totally
         * wasting several GB of ram we must reserve some of the lower zone
         * memory (otherwise we risk to run OOM on the lower zones despite
         * there being tons of freeable ram on the higher zones).  This array is
         * recalculated at runtime if the sysctl_lowmem_reserve_ratio sysctl
         * changes.
         */
        long lowmem_reserve[MAX_NR_ZONES];

#ifdef CONFIG_NUMA
        int node;
#endif
        struct pglist_data      *zone_pgdat;
        struct per_cpu_pages    __percpu *per_cpu_pageset;
        struct per_cpu_zonestat __percpu *per_cpu_zonestats;
        /*
         * the high and batch values are copied to individual pagesets for
         * faster access
         */
        int pageset_high;
        int pageset_batch;

#ifndef CONFIG_SPARSEMEM
        /*
         * Flags for a pageblock_nr_pages block. See pageblock-flags.h.
         * In SPARSEMEM, this map is stored in struct mem_section
         */
        unsigned long           *pageblock_flags;
#endif /* CONFIG_SPARSEMEM */

        /* zone_start_pfn == zone_start_paddr >> PAGE_SHIFT */
        unsigned long           zone_start_pfn;

        /*
         * spanned_pages is the total pages spanned by the zone, including
         * holes, which is calculated as:
         *      spanned_pages = zone_end_pfn - zone_start_pfn;
         *
         * present_pages is physical pages existing within the zone, which
         * is calculated as:
         *      present_pages = spanned_pages - absent_pages(pages in holes);
         *
         * present_early_pages is present pages existing within the zone
         * located on memory available since early boot, excluding hotplugged
         * memory.
         *
         * managed_pages is present pages managed by the buddy system, which
         * is calculated as (reserved_pages includes pages allocated by the
         * bootmem allocator):
         *      managed_pages = present_pages - reserved_pages;
         *
         * cma pages is present pages that are assigned for CMA use
         * (MIGRATE_CMA).
         *
         * So present_pages may be used by memory hotplug or memory power
         * management logic to figure out unmanaged pages by checking
         * (present_pages - managed_pages). And managed_pages should be used
         * by page allocator and vm scanner to calculate all kinds of watermarks
         * and thresholds.
         *
         * Locking rules:
         *
         * zone_start_pfn and spanned_pages are protected by span_seqlock.
         * It is a seqlock because it has to be read outside of zone->lock,
         * and it is done in the main allocator path.  But, it is written
         * quite infrequently.
         *
         * The span_seq lock is declared along with zone->lock because it is
         * frequently read in proximity to zone->lock.  It's good to
         * give them a chance of being in the same cacheline.
         *
         * Write access to present_pages at runtime should be protected by
         * mem_hotplug_begin/done(). Any reader who can't tolerant drift of
         * present_pages should use get_online_mems() to get a stable value.
         */
        atomic_long_t           managed_pages;
        unsigned long           spanned_pages;
        unsigned long           present_pages;
#if defined(CONFIG_MEMORY_HOTPLUG)
        unsigned long           present_early_pages;
#endif
#ifdef CONFIG_CMA
        unsigned long           cma_pages;
#endif

        const char              *name; // 查看 char * const zone_names[MAX_NR_ZONES]

#ifdef CONFIG_MEMORY_ISOLATION
        /*
         * Number of isolated pageblock. It is used to solve incorrect
         * freepage counting problem due to racy retrieving migratetype
         * of pageblock. Protected by zone->lock.
         */
        unsigned long           nr_isolate_pageblock;
#endif

#ifdef CONFIG_MEMORY_HOTPLUG
        /* see spanned/present_pages for more description */
        seqlock_t               span_seqlock;
#endif

        int initialized;

        /* Write-intensive fields used from the page allocator */
        CACHELINE_PADDING(_pad1_);

        /* free areas of different sizes */
        struct free_area        free_area[MAX_ORDER + 1];

#ifdef CONFIG_UNACCEPTED_MEMORY
        /* Pages to be accepted. All pages on the list are MAX_ORDER */
        struct list_head        unaccepted_pages;
#endif

        /* zone flags, see below */
        unsigned long           flags;

        /* Primarily protects free_area */
        spinlock_t              lock; // 只保护结构，不保护在这个区的页

        /* Write-intensive fields used by compaction and vmstats. */
        CACHELINE_PADDING(_pad2_);

        /*
         * When free pages are below this point, additional steps are taken
         * when reading the number of free pages to avoid per-cpu counter
         * drift allowing watermarks to be breached
         */
        unsigned long percpu_drift_mark;

#if defined CONFIG_COMPACTION || defined CONFIG_CMA
        /* pfn where compaction free scanner should start */
        unsigned long           compact_cached_free_pfn;
        /* pfn where compaction migration scanner should start */
        unsigned long           compact_cached_migrate_pfn[ASYNC_AND_SYNC];
        unsigned long           compact_init_migrate_pfn;
        unsigned long           compact_init_free_pfn;
#endif

#ifdef CONFIG_COMPACTION
        /*
         * On compaction failure, 1<<compact_defer_shift compactions
         * are skipped before trying again. The number attempted since
         * last failure is tracked with compact_considered.
         * compact_order_failed is the minimum compaction failed order.
         */
        unsigned int            compact_considered;
        unsigned int            compact_defer_shift;
        int                     compact_order_failed;
#endif

#if defined CONFIG_COMPACTION || defined CONFIG_CMA
        /* Set to true when the PG_migrate_skip bits should be cleared */
        bool                    compact_blockskip_flush;
#endif

        bool                    contiguous;

        CACHELINE_PADDING(_pad3_);
        /* Zone statistics */
        atomic_long_t           vm_stat[NR_VM_ZONE_STAT_ITEMS];
        atomic_long_t           vm_numa_event[NR_VM_NUMA_EVENT_ITEMS];
} ____cacheline_internodealigned_in_smp;
```

# 分配和释放内存的接口

分配页：
```c
// 分配 2^order 个连续物理page，返回值是第一个page的指针
struct page *alloc_pages(gfp_t gfp_mask, unsigned int order)
// 页转换成逻辑地址
void *page_address(const struct page *page)
void free_pages(unsigned long addr, unsigned int order)
// 返回值是逻辑地址
unsigned long __get_free_pages(gfp_t gfp_mask, unsigned int order)
// 只分配一个page，返回值是page的指针
alloc_page(gfp_mask)
// 只分配一个page，返回值是虚拟地址
__get_free_page(gfp_mask)
// 只分配一个page，返回值是虚拟地址，全部填充0
unsigned long get_zeroed_page(gfp_t gfp_mask)
```

释放页：
```c
// 传入page指针
void __free_pages(struct page *page, unsigned int order)
// 传入虚拟地址
void free_pages(unsigned long addr, unsigned int order)
// 释放一个page，传入虚拟地址
free_page(addr)
```

分配以字节为单位的内存：
```c
// 物理地址是连续的，一般是硬件设备要用到
void *kmalloc(size_t size, gfp_t gfp)
// 和kmalloc()配对使用，参数p可以为NULL
void kfree(void *p)
// 可能睡眠，物理地址可以不连续，虚拟地址连续，典型用途是获取大块内存，如模块装载
void *vmalloc(unsigned long size)
// 可能睡眠，和 vmalloc配对使用
void vfree(const void *addr)
```

# `gfp_t`

在`include/linux/gfp_types.h`中的解释：
```c
/* typedef 在 include/linux/types.h 中，但我们希望将文档放在这里 */     
#if 0                                                                  
/**
 * typedef gfp_t - 内存分配标志。
 * 
 * GFP 标志在 Linux 中广泛用于指示如何分配内存。GFP 的缩写来源于
 * get_free_pages()，这是底层的内存分配函数。并不是每个 GFP 标志都被
 * 每个可能分配内存的函数所支持。大多数用户会使用简单的 ``GFP_KERNEL``。
 */                                                               
typedef unsigned int __bitwise gfp_t;                                  
#endif                                                                 
```

## 行为修饰符

表示内核应该如何分配所需的内存。

## 区修饰符

表示从哪个区分配内存。

## 类型标志

组合了行为修饰符和区修饰符。

# 页高速缓存

访问磁盘的速度要远低于访问内存的速度。

缓存策略有三种：

- 不缓存，直接写到磁盘，同时让缓存中的数据失效。
- Write Through，写操作同时更新内存缓存和磁盘。
- Write Back，写操作先写到内存缓存中，磁盘不会立刻更新，先标记脏页，然后将脏页周期性的写到磁盘中。

Linux的缓存回收是选择没有标记为脏的页进行简单替换。最近最少使用算法，LRU，