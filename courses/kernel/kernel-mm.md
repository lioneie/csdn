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

- 逻辑地址（logical address）：由段（segment）和偏移量（offset或displacement）

MMU，英文全称Memory Management Unit，中文翻译为内存管理单元，又叫分页内存管理单元（Paged Memory Management Unit），把虚拟地址转换成物理地址。MMU以page大小为单位管理内存，虚拟内存的最小单位就是page。


# 页

- KMSAN: todo
- KASAN: todo

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
        void *virtual;                  /* 内核虚拟地址（如果不是 kmapped，即 highmem，则为 NULL） */
#endif /* WANT_PAGE_VIRTUAL */

#ifdef CONFIG_KMSAN
        /*
        * 此页面的 KMSAN 元数据：
        *  - 影子页面：每个位表示原始页面对应位是否已初始化（0）或未初始化（1）；
        *  - 原始页面：每 4 个字节包含一个栈追踪的 ID，用于指示未初始化值的创建位置。
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
        struct {        /* 页面缓存和匿名页 */
                /**
                * @lru: 页面淘汰列表，例如 active_list，由 lruvec->lru_lock 保护。
                * 有时由页面所有者用作通用列表。
                */
                union {
                        struct list_head lru;

                        /* 或者，对于不可回收的 "LRU 列表" 槽位 */
                        struct {
                                /* 总是偶数，以抵消 PageTail */
                                void *__filler;
                                /* 统计页面或页片的 mlock 数量 */
                                unsigned int mlock_count;
                        };

                        /* 或者，空闲页面 */
                        struct list_head buddy_list;
                        struct list_head pcp_list;
                };
                /* 有关 PAGE_MAPPING_FLAGS，请参见 page-flags.h */
                struct address_space *mapping;
                union {
                        pgoff_t index;          /* 我们在映射中的偏移量。 */
                        unsigned long share;    /* fsdax 的共享计数 */
                };
                /**
                * @private: 映射专用的不透明数据。
                * 如果 PagePrivate，通常用于 buffer_heads。
                * 如果 PageSwapCache，则用于 swp_entry_t。
                * 如果 PageBuddy，则表示伙伴系统中的顺序。
                */
                unsigned long private;
        };
        struct {        /* 网络栈使用的 page_pool */
                /**
                * @pp_magic: 魔术值，用于避免回收非 page_pool 分配的页面。
                */
                unsigned long pp_magic;
                struct page_pool *pp;
                unsigned long _pp_mapping_pad;
                unsigned long dma_addr;
                union {
                        /**
                        * dma_addr_upper: 在 32 位架构上可能需要 64 位值。
                        */
                        unsigned long dma_addr_upper;
                        /**
                        * 支持 frag page，不支持 64 位 DMA 的 32 位架构。
                        */
                        atomic_long_t pp_frag_count;
                };
        };
        struct {        /* 复合页面的尾页 */
                unsigned long compound_head;    /* 位零已设置 */
        };
        struct {        /* ZONE_DEVICE 页面 */
                /** @pgmap: 指向宿主设备页面映射。 */
                struct dev_pagemap *pgmap;
                void *zone_device_data;
                /*
                * ZONE_DEVICE 私有页面被计为已映射，因此接下来的 3 个字保存了
                * 映射、索引和私有字段，当页面迁移到设备私有内存时，这些字段来自
                * 源匿名页面或页面缓存页面。
                * ZONE_DEVICE MEMORY_DEVICE_FS_DAX 页面在 pmem 支持的 DAX 文件
                * 被映射时也使用映射、索引和私有字段。
                */
        };

        /** @rcu_head: 您可以使用它通过 RCU 释放页面。 */
        struct rcu_head rcu_head;
}

/* 这个联合体的大小是4字节。 */
union page_union_2 {
        /*
        * 如果页面可以映射到用户空间，则编码该页面被页表引用的次数。
        */
        atomic_t _mapcount;

        /*
        * 如果页面既不是 PageSlab 也不能映射到用户空间，此处存储的值可能有助于
        * 确定该页面的用途。有关当前存储在此处的页面类型列表，请参见 page-flags.h。
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
        * 可寻址的常规内存在 ZONE_NORMAL 中。如果 DMA 设备支持对所有可寻址内存的传输，
        * 则可以对 ZONE_NORMAL 中的页面执行 DMA 操作。
        */
        ZONE_NORMAL,
#ifdef CONFIG_HIGHMEM
        /*
        * 一种只能通过将部分映射到其自身地址空间来由内核寻址的内存区域。
        * 例如，i386 使用此区域允许内核寻址超过 900MB 的内存。
        * 内核将为每个需要访问的页面设置特殊映射（在 i386 上为页表项）。
        */
        ZONE_HIGHMEM,
#endif
        /*
        * ZONE_MOVABLE 类似于 ZONE_NORMAL，不同之处在于它包含可移动页面，
        * 下面描述了几个例外情况。ZONE_MOVABLE 的主要用途是增加内存下线/卸载
        * 成功的可能性，并局部限制不可移动的分配 - 例如，增加 THP/大页的数量。
        * 值得注意的特殊情况包括：
        *
        * 1. 锁定页面：（长期）锁定可移动页面可能会实质上使这些页面变得不可移动。
        *    因此，我们不允许在 ZONE_MOVABLE 中长期锁定页面。当页面被锁定并出现错误时，
        *    它们会立即从正确的区域中获取。然而，当页面被锁定时，地址空间中可能已经有
        *    位于 ZONE_MOVABLE 中的页面（即用户在锁定前已访问该内存）。在这种情况下，
        *    我们将它们迁移到不同的区域。当迁移失败时 - 锁定失败。
        * 2. memblock 分配：kernelcore/movablecore 设置可能会在引导后导致
        *    ZONE_MOVABLE 中包含不可移动的分配。内存下线和分配会很早失败。
        * 3. 内存空洞：kernelcore/movablecore 设置可能会在引导后导致 ZONE_MOVABLE
        *    中包含内存空洞，例如，如果我们有仅部分填充的部分。内存下线和分配会很早失败。
        * 4. PG_hwpoison 页面：虽然在内存下线期间可以跳过中毒页面，但这些页面不能被分配。
        * 5. 不可移动的 PG_offline 页面：在半虚拟化环境中，热插拔的内存块可能仅部分
        *    由伙伴系统管理（例如，通过 XEN-balloon、Hyper-V balloon、virtio-mem）。
        *    由伙伴系统未管理的部分是不可移动的 PG_offline 页面。在某些情况下
        *    （virtio-mem），在内存下线期间可以跳过这些页面，但不能移动/分配。
        *    这些技术可能会使用 alloc_contig_range() 再次隐藏之前暴露的页面
        *    （例如，在 virtio-mem 中实现某种内存卸载）。
        * 6. ZERO_PAGE(0)：kernelcore/movablecore 设置可能会导致
        *    ZERO_PAGE(0)（在不同平台上分配方式不同）最终位于可移动区域。
        *    ZERO_PAGE(0) 不能迁移。
        * 7. 内存热插拔：当使用 memmap_on_memory 并将内存上线到 MOVABLE 区域时，
        *    vmemmap 页面也会放置在该区域。这些页面不能真正移动，因为它们自存储在范围内，
        *    但在描述的范围即将下线时，它们被视为可移动。
        *
        * 总体而言，不应在 ZONE_MOVABLE 中出现不可移动的分配，这会降低内存下线的效果。
        * 分配器（如 alloc_contig_range()）必须预料到在 ZONE_MOVABLE 中迁移页面可能会失败
        * （即使 has_unmovable_pages() 表示没有不可移动页面，也可能存在假阴性）。
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
        NR_WMARK  // 总数
};                    

struct zone {
        /* 主要为只读字段 */

        /* 区域水印，通过 *_wmark_pages(zone) 宏访问 */
        unsigned long _watermark[NR_WMARK]; // 查看 zone_watermarks
        unsigned long watermark_boost;

        unsigned long nr_reserved_highatomic;

        /*
        * 我们不知道将要分配的内存是否可释放或最终会被释放，所以为了避免完全浪费数GB的内存，
        * 我们必须保留一些较低区域的内存（否则我们有可能在较低区域内存不足的情况下，
        * 而较高区域却有大量可释放的内存）。如果 sysctl_lowmem_reserve_ratio 的 sysctl 发生变化，
        * 该数组会在运行时重新计算。
        */
        long lowmem_reserve[MAX_NR_ZONES];

#ifdef CONFIG_NUMA
        int node;
#endif
        struct pglist_data      *zone_pgdat;
        struct per_cpu_pages    __percpu *per_cpu_pageset;
        struct per_cpu_zonestat __percpu *per_cpu_zonestats;
        /*
        * high 和 batch 值被复制到各个页面集以便更快速地访问
        */
        int pageset_high;
        int pageset_batch;

#ifndef CONFIG_SPARSEMEM
        /*
        * pageblock_nr_pages 块的标志。请参阅 pageblock-flags.h。
        * 在 SPARSEMEM 中，此映射存储在 struct mem_section 中。
        */
        unsigned long           *pageblock_flags;
#endif /* CONFIG_SPARSEMEM */

        /* zone_start_pfn == zone_start_paddr >> PAGE_SHIFT */
        unsigned long           zone_start_pfn;
        /*
        * spanned_pages 是该区域所跨越的总页数，包括空洞，计算公式为：
        *      spanned_pages = zone_end_pfn - zone_start_pfn;
        *
        * present_pages 是该区域内存在的物理页，计算公式为：
        *      present_pages = spanned_pages - absent_pages(空洞中的页数);
        *
        * present_early_pages 是自启动早期以来该区域内存在的内存页，不包括热插拔内存。
        *
        * managed_pages 是由伙伴系统管理的存在页，计算公式为（reserved_pages 包括由 bootmem 分配器分配的页）：
        *      managed_pages = present_pages - reserved_pages;
        *
        * cma_pages 是分配给 CMA 使用的存在页（MIGRATE_CMA）。
        *
        * 因此， present_pages 可被内存热插拔或内存电源管理逻辑用来通过检查
        * (present_pages - managed_pages) 来找出未管理的页。而 managed_pages
        * 应该被页分配器和虚拟内存扫描器用来计算各种水印和阈值。
        *
        * 锁定规则：
        *
        * zone_start_pfn 和 spanned_pages 受 span_seqlock 保护。
        * 这是一个 seqlock，因为它必须在 zone->lock 外部读取，
        * 并且它是在主分配器路径中完成的。但是，它的写入频率非常低。
        *
        * span_seq 锁与 zone->lock 一起声明，因为它在 zone->lock 附近经常被读取。
        * 这样有机会使它们位于同一个缓存行中。
        *
        * 运行时对 present_pages 的写访问应由 mem_hotplug_begin/done() 保护。
        * 任何无法容忍 present_pages 漂移的读者应使用 get_online_mems() 以获得稳定的值。
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
        * 隔离页面块的数量。用于解决由于竞争性检索页面块的迁移类型导致的错误空闲页计数问题。
        * 受 zone->lock 保护。
        */
        unsigned long           nr_isolate_pageblock;
#endif

#ifdef CONFIG_MEMORY_HOTPLUG
        /* 有关详细描述，请参阅 spanned/present_pages */
        seqlock_t               span_seqlock;
#endif

        int initialized;

        /* 页分配器使用的写密集字段 */
        CACHELINE_PADDING(_pad1_);

        /* 不同大小的空闲区域 */
        struct free_area        free_area[MAX_ORDER + 1];

#ifdef CONFIG_UNACCEPTED_MEMORY
        /* 待接受的页面。列表中的所有页面都是 MAX_ORDER */
        struct list_head        unaccepted_pages;
#endif

        /* 区域标志，见下文 */
        unsigned long           flags;

        /* 主要保护 free_area */
        spinlock_t              lock; // 只保护结构，不保护在这个区的页

        /* 由压缩和 vmstats 使用的写密集字段。 */
        CACHELINE_PADDING(_pad2_);

        /*
        * 当空闲页数低于此点时，在读取空闲页数时会采取额外步骤，
        * 以避免每个 CPU 计数器漂移导致水印被突破
        */
        unsigned long percpu_drift_mark;

#if defined CONFIG_COMPACTION || defined CONFIG_CMA
        /* 压缩空闲扫描器应开始的 pfn（page frame number 页帧号） */
        unsigned long           compact_cached_free_pfn;
        /* 压缩迁移扫描器应开始的页帧号（pfn） */
        unsigned long           compact_cached_migrate_pfn[ASYNC_AND_SYNC];
        unsigned long           compact_init_migrate_pfn;
        unsigned long           compact_init_free_pfn;
#endif

#ifdef CONFIG_COMPACTION
        /*
        * 在压缩失败时，跳过 1<<compact_defer_shift 次压缩后再尝试。
        * 自上次失败以来尝试的次数由 compact_considered 跟踪。
        * compact_order_failed 是压缩失败的最小顺序。
        */
        unsigned int            compact_considered;
        unsigned int            compact_defer_shift;
        int                     compact_order_failed;
#endif

#if defined CONFIG_COMPACTION || defined CONFIG_CMA
        /* 当应清除 PG_migrate_skip 位时设为 true */
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

```c
/**
 * DOC: 操作修饰符
 * 
 * 操作修饰符
 * ----------------
 * 
 * %__GFP_NOWARN 抑制分配失败报告。
 * 
 * %__GFP_COMP 处理复合页元数据。
 * 
 * %__GFP_ZERO 成功时返回已清零的页。
 * 
 * %__GFP_ZEROTAGS 如果内存本身被清零（通过 __GFP_ZERO 或 init_on_alloc，
 * 前提是未设置 __GFP_SKIP_ZERO ），则在分配时清零内存标签。此标志用于优化：
 * 在清零内存的同时设置内存标签对性能的额外影响最小。
 * 
 * %__GFP_SKIP_KASAN 使 KASAN 在页分配时跳过取消标记。用于用户空间和 vmalloc 页；
 * 后者由 kasan_unpoison_vmalloc 代替取消标记。对于用户空间页，
 * 也会跳过标记，详细信息见 should_skip_kasan_poison。仅在 HW_TAGS 模式下有效。
 */                                                                            
#define __GFP_NOWARN    ((__force gfp_t)___GFP_NOWARN)                          
#define __GFP_COMP      ((__force gfp_t)___GFP_COMP)                            
#define __GFP_ZERO      ((__force gfp_t)___GFP_ZERO)                            
#define __GFP_ZEROTAGS  ((__force gfp_t)___GFP_ZEROTAGS)                        
#define __GFP_SKIP_ZERO ((__force gfp_t)___GFP_SKIP_ZERO)                       
#define __GFP_SKIP_KASAN ((__force gfp_t)___GFP_SKIP_KASAN)                     
                                                                                
/* 禁用 GFP 上下文跟踪的 lockdep */                               
#define __GFP_NOLOCKDEP ((__force gfp_t)___GFP_NOLOCKDEP)                       
                                                                                
/* 为 N 个 __GFP_FOO 位预留空间 */                                               
#define __GFP_BITS_SHIFT (26 + IS_ENABLED(CONFIG_LOCKDEP))                      
#define __GFP_BITS_MASK ((__force gfp_t)((1 << __GFP_BITS_SHIFT) - 1))          
```

## 区修饰符

表示从哪个区分配内存。注意返回逻辑地址的函数如`__get_free_pages()`和`kmalloc()`等不能指定`__GFP_HIGHMEM`，因为可能会出现还没映射虚拟地址空间，没有虚拟地址。

```c
/*
 * 物理地址区域修饰符（参见 linux/mmzone.h - 低四位）
 * 
 * 不要对这些修饰符做任何条件判断。如有必要，修改没有下划线的定义并一致地使用它们。
 * 这里的定义可能会用于位比较。
 */                                                                              
#define __GFP_DMA       ((__force gfp_t)___GFP_DMA)                                
#define __GFP_HIGHMEM   ((__force gfp_t)___GFP_HIGHMEM)                            
#define __GFP_DMA32     ((__force gfp_t)___GFP_DMA32)                              
#define __GFP_MOVABLE   ((__force gfp_t)___GFP_MOVABLE)  /* ZONE_MOVABLE allowed */
#define GFP_ZONEMASK    (__GFP_DMA|__GFP_HIGHMEM|__GFP_DMA32|__GFP_MOVABLE)        
```

## 页面的移动性和放置提示

```c
/**
 * DOC: 页面的移动性和放置提示
 *
 * 页面的移动性和放置提示
 * -----------------------
 *
 * 这些标志提供了有关页面移动性的信息。具有相似移动性的页面被放置在相同的页面块中，以最大限度地减少由外部碎片引起的问题。
 *
 * %__GFP_MOVABLE （也是一个区域修饰符）表示页面可以通过内存压缩期间的页面迁移来移动或可以被回收。
 *
 * %__GFP_RECLAIMABLE 用于指定 SLAB_RECLAIM_ACCOUNT 的 slab 分配，其页面可以通过收缩器（shrinkers）释放。
 *
 * %__GFP_WRITE 表示调用者打算对页面进行写操作。尽可能地，这些页面将分散在本地区域之间，以避免所有脏页面集中在一个区域（公平区域分配策略）。
 *
 * %__GFP_HARDWALL 强制执行 cpuset 内存分配策略。
 *
 * %__GFP_THISNODE 强制分配从请求的节点中满足，不进行回退或放置策略的强制执行。
 *
 * %__GFP_ACCOUNT 使分配计入 kmemcg。kmemcg 是 Kernel Memory Control Group（内核内存控制组）的缩写。它是 Linux 内核中的一种内存管理机制，用于对内核内存进行分组和控制。具体来说，kmemcg 允许用户限制和监视内核分配的内存，以防止某些进程消耗过多的内核内存资源，从而影响系统的整体性能和稳定性。
 */
#define __GFP_RECLAIMABLE ((__force gfp_t)___GFP_RECLAIMABLE)
#define __GFP_WRITE	((__force gfp_t)___GFP_WRITE)
#define __GFP_HARDWALL   ((__force gfp_t)___GFP_HARDWALL)
#define __GFP_THISNODE	((__force gfp_t)___GFP_THISNODE)
#define __GFP_ACCOUNT	((__force gfp_t)___GFP_ACCOUNT)
```

## 水位标志修饰符

```c
/**
 * DOC: 水位标志修饰符
 *
 * 水位标志修饰符 -- 控制对紧急预留内存的访问
 * --------------------------------------------
 *
 * %__GFP_HIGH 表示调用者是高优先级的，并且在系统能够继续前进之前，必须满足该请求。
 * 例如，从原子上下文创建 IO 上下文以清理页面和请求。
 *
 * %__GFP_MEMALLOC 允许访问所有内存。这只能在调用者保证分配将很快释放更多内存时使用，
 * 例如进程退出或交换。使用者应该是内存管理（MM）或与虚拟内存（VM）紧密协作（例如通过 NFS 进行交换）。
 * 使用此标志的用户必须非常小心，不要完全耗尽预留内存，并实施一种控制机制，
 * 根据释放的内存量来控制预留内存的消耗。在使用此标志之前，应始终考虑使用预先分配的池（例如 mempool）。
 *
 * %__GFP_NOMEMALLOC 用于明确禁止访问紧急预留内存。如果同时设置了 %__GFP_MEMALLOC 标志，此标志优先。
 */
#define __GFP_HIGH	((__force gfp_t)___GFP_HIGH)
#define __GFP_MEMALLOC	((__force gfp_t)___GFP_MEMALLOC)
#define __GFP_NOMEMALLOC ((__force gfp_t)___GFP_NOMEMALLOC)
```

## 回收修饰符

```c
/**
 * DOC: 回收修饰符
 *
 * 回收修饰符
 * ----------
 * 请注意，以下所有标志仅适用于可休眠的分配（例如 %GFP_NOWAIT 和 %GFP_ATOMIC 将忽略它们）。
 *
 * %__GFP_IO 可以启动物理 IO。
 *
 * %__GFP_FS 可以调用底层文件系统。清除此标志可以避免分配器递归到可能已经持有锁的文件系统中。
 *
 * %__GFP_DIRECT_RECLAIM 表示调用者可以进入直接回收。如果有备用选项可用，可以清除此标志以避免不必要的延迟。
 *
 * %__GFP_KSWAPD_RECLAIM 表示调用者希望在达到低水位时唤醒 kswapd 并让它回收页面直到达到高水位。当有备用选项可用且回收可能会中断系统时，调用者可能希望清除此标志。一个典型的例子是 THP 分配，其中备用选项成本低廉，但回收/压缩可能导致间接停滞。
 *
 * %__GFP_RECLAIM 是允许/禁止直接回收和 kswapd 回收的简写。
 *
 * 默认分配器行为取决于请求大小。我们有一个所谓昂贵分配（order > %PAGE_ALLOC_COSTLY_ORDER）的概念。
 * !昂贵分配是至关重要的，不能失败，所以它们默认情况下是隐含的不失败（某些例外情况如 OOM 受害者可能会失败，因此调用者仍需检查失败）而昂贵请求则试图不造成干扰，即使不调用 OOM 杀手也会后退。
 * 以下三个修饰符可以用来覆盖某些隐含规则
 *
 * %__GFP_NORETRY: 虚拟内存实现将只尝试非常轻量级的内存直接回收以在内存压力下获得一些内存（因此它可以休眠）。它将避免像 OOM 杀手这样具有破坏性的操作。在内存压力大的情况下，失败是很可能发生的，因此调用者必须处理失败。此标志适用于可以轻松处理失败且成本较低的情况，例如降低吞吐量
 *
 * %__GFP_RETRY_MAYFAIL: 虚拟内存实现将在某些地方有进展的情况下重试先前失败的内存回收过程。它可以等待其他任务尝试高层次的内存释放方法，例如压缩（消除碎片）和页面换出。
 * 重试次数有一定限制，但比 %__GFP_NORETRY 的限制大。
 * 带有此标志的分配可能会失败，但只有在确实没有未使用的内存时才会失败。尽管这些分配不会直接触发 OOM 杀手，但它们的失败表明系统可能很快需要使用 OOM 杀手。
 * 调用者必须处理失败，但可以通过失败更高级别的请求或以效率低得多的方式完成来合理地处理。
 * 如果分配确实失败，并且调用者能够释放一些非必要的内存，那么这样做可能会使整个系统受益。
 *
 * %__GFP_NOFAIL: 虚拟内存实现 _必须_ 无限重试：调用者无法处理分配失败。分配可能会无限期阻塞，但不会返回失败。测试失败是没有意义的。
 * 新用户应仔细评估（并且该标志应仅在没有合理的失败策略时使用），但绝对比在分配器周围编写无尽循环代码更可取。
 * 强烈不建议将此标志用于昂贵的分配。
 */
#define __GFP_IO	((__force gfp_t)___GFP_IO)
#define __GFP_FS	((__force gfp_t)___GFP_FS)
#define __GFP_DIRECT_RECLAIM	((__force gfp_t)___GFP_DIRECT_RECLAIM) /* Caller can reclaim */
#define __GFP_KSWAPD_RECLAIM	((__force gfp_t)___GFP_KSWAPD_RECLAIM) /* kswapd can wake */
#define __GFP_RECLAIM ((__force gfp_t)(___GFP_DIRECT_RECLAIM|___GFP_KSWAPD_RECLAIM))
#define __GFP_RETRY_MAYFAIL	((__force gfp_t)___GFP_RETRY_MAYFAIL)
#define __GFP_NOFAIL	((__force gfp_t)___GFP_NOFAIL)
#define __GFP_NORETRY	((__force gfp_t)___GFP_NORETRY)
```

## 类型标志

组合了行为修饰符和区修饰符。

```c
/**
 * DOC: 有用的 GFP 标志组合
 *
 * 有用的 GFP 标志组合
 * ----------------------------
 *
 * 常用的 GFP 标志组合。建议子系统从这些组合之一开始，然后根据需要设置/清除 %__GFP_FOO 标志。
 *
 * %GFP_ATOMIC 用户不能休眠，需要分配成功。应用了较低的水印以允许访问“原子保留”。
 * 当前实现不支持 NMI 和其他一些严格的非抢占上下文（例如 raw_spin_lock）。
 * %GFP_NOWAIT 也是如此。
 *
 * %GFP_KERNEL 适用于内核内部分配。调用者需要 %ZONE_NORMAL 或更低区域以直接访问，但可以直接回收。
 *
 * %GFP_KERNEL_ACCOUNT 与 GFP_KERNEL 相同，但分配会记入 kmemcg。
 *
 * %GFP_NOWAIT 适用于不应因直接回收、启动物理 IO 或使用任何文件系统回调而停滞的内核分配。
 *
 * %GFP_NOIO 将使用直接回收来丢弃不需要启动任何物理 IO 的干净页或 slab 页。
 * 请尽量避免直接使用此标志，而应使用 memalloc_noio_{save,restore}
 * 来标记整个范围，说明不能执行任何 IO 的原因。所有分配请求将隐式继承 GFP_NOIO。
 *
 * %GFP_NOFS 将使用直接回收，但不会使用任何文件系统接口。
 * 请尽量避免直接使用此标志，而应使用 memalloc_nofs_{save,restore}
 * 来标记整个范围，说明不能/不应递归到 FS 层的原因。所有分配请求将隐式继承 GFP_NOFS。
 *
 * %GFP_USER 适用于需要内核或硬件直接访问的用户空间分配。
 * 它通常用于映射到用户空间的硬件缓冲区（例如图形），硬件仍然必须进行 DMA。
 * 这些分配强制执行 cpuset 限制。
 *
 * %GFP_DMA 出于历史原因存在，应尽可能避免使用。
 * 标志表示调用者要求使用最低区域（%ZONE_DMA 或 x86-64 上的 16M）。
 * 理想情况下，应删除该标志，但这需要仔细审核，因为一些用户确实需要它，
 * 而其他用户使用该标志来避免 %ZONE_DMA 中的低内存保留，并将最低区域视为一种紧急保留。
 *
 * %GFP_DMA32 类似于 %GFP_DMA，除了调用者要求 32 位地址。
 * 请注意，kmalloc(..., GFP_DMA32) 不返回 DMA32 内存，因为未实现 DMA32 kmalloc 缓存数组。
 * （原因：内核中没有这样的用户）。
 *
 * %GFP_HIGHUSER 适用于可能映射到用户空间的用户空间分配，
 * 不需要内核直接访问但一旦使用便不能移动。例如硬件分配，直接将数据映射到用户空间，
 * 但没有地址限制。
 *
 * %GFP_HIGHUSER_MOVABLE 适用于内核不需要直接访问的用户空间分配，但需要访问时可以使用 kmap()。
 * 预计这些分配可通过页回收或页迁移移动。通常，LRU 上的页也会分配 %GFP_HIGHUSER_MOVABLE。
 *
 * %GFP_TRANSHUGE 和 %GFP_TRANSHUGE_LIGHT 用于 THP 分配。
 * 它们是复合分配，如果内存不可用，通常会快速失败，并且在失败时不会唤醒 kswapd/kcompactd。
 * _LIGHT 版本根本不尝试回收/压缩，默认用于页面错误路径，而非轻量版用于 khugepaged。
 */
#define GFP_ATOMIC	(__GFP_HIGH|__GFP_KSWAPD_RECLAIM)
#define GFP_KERNEL	(__GFP_RECLAIM | __GFP_IO | __GFP_FS)
#define GFP_KERNEL_ACCOUNT (GFP_KERNEL | __GFP_ACCOUNT)
#define GFP_NOWAIT	(__GFP_KSWAPD_RECLAIM)
#define GFP_NOIO	(__GFP_RECLAIM)
#define GFP_NOFS	(__GFP_RECLAIM | __GFP_IO)
#define GFP_USER	(__GFP_RECLAIM | __GFP_IO | __GFP_FS | __GFP_HARDWALL)
#define GFP_DMA		__GFP_DMA
#define GFP_DMA32	__GFP_DMA32
#define GFP_HIGHUSER	(GFP_USER | __GFP_HIGHMEM)
#define GFP_HIGHUSER_MOVABLE	(GFP_HIGHUSER | __GFP_MOVABLE | __GFP_SKIP_KASAN)
#define GFP_TRANSHUGE_LIGHT	((GFP_HIGHUSER_MOVABLE | __GFP_COMP | \
			 __GFP_NOMEMALLOC | __GFP_NOWARN) & ~__GFP_RECLAIM)
#define GFP_TRANSHUGE	(GFP_TRANSHUGE_LIGHT | __GFP_DIRECT_RECLAIM)
```

# 页高速缓存

访问磁盘的速度要远低于访问内存的速度。

缓存策略有三种：

- 不缓存，直接写到磁盘，同时让缓存中的数据失效。
- Write Through，写操作同时更新内存缓存和磁盘。
- Write Back，写操作先写到内存缓存中，磁盘不会立刻更新，先标记脏页，然后将脏页周期性的写到磁盘中。

Linux的缓存回收是选择没有标记为脏的页进行简单替换。最近最少使用算法，LRU，