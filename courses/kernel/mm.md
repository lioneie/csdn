<!--
https://mp.weixin.qq.com/mp/homepage?__biz=MzI3NzA5MzUxNA==&hid=14&sn=a7deb8f4a4986e1d148671008bd1403c&scene=1&devicetype=iMac+Mac14%2C2+OSX+OSX+14.5+build(23F79)&version=13080414&lang=zh_CN&nettype=WIFI&ascene=0&uin=&key=&fontScale=100
-->

# 内存地址

操作系统是横跨软件和硬件的桥梁，其中内存寻址是操作系统设计的硬件基础之一。

```sh
logical                 linear              physical
address  +------------+ address  +--------+ address
-------->|segmentation|--------->| paging |--------->
         |   unit     |          |  unit  |
         +------------+          +--------+
```

三种地址介绍:

- 逻辑地址（logical address）: 由段（segment）和偏移量（offset或displacement）组成。RISC（Reduced Instruction Set Computers）体系结构（如ARM）分段支持有限，在某些支持段的CISC（Complex Instruction Set Computers）体系结构如x86（x86无法绕过分段），Linux内核中，所有的段（如: 用户代码段、用户数据段、内核代码段、内核数据段）都从0地址开始，偏移量就是线性地址的大小，所以逻辑地址和线性地址是一毛一样的。
<!-- public begin -->
对x86汇编感兴趣的话可以参考小甲鱼老师的[【8086汇编入门】《零基础入门学习汇编语言》](https://www.bilibili.com/video/BV1Rs411c7HG/)。
<!-- public end -->
- 线性地址（linear address）: 又叫虚拟地址（virtual address），是连续的地址。在32位系统中，用户空间通常占用前3GB的线性地址空间，内核空间通常占用3GB~4GB的线性地址空间。在64位系统中，用户空间和内核空间占用更大的范围，具体的范围取决于内核的配置和架构。
- 物理地址（physical address）: 用于内存芯片级的内存寻址单元。

分段单元（segmentation unit）和分页单元（paging unit）都由MMU完成，英文全称Memory Management Unit，中文翻译为内存管理单元，又叫分页内存管理单元（Paged Memory Management Unit），最终转换成物理地址。MMU以page大小为单位管理内存，虚拟内存的最小单位就是page。

# 页

<!--
```c
/*
 * 系统中的每个物理页面都有一个 struct page 结构与之关联，
 * 以跟踪我们当前使用该页面的用途。注意，我们无法跟踪哪些任务在使用页面，
 * 但如果它是一个页缓存页面，rmap 结构可以告诉我们谁在映射它。
 *
 * 如果使用 alloc_pages() 分配页面，可以使用 struct page 中的一些空间
 * 供自己使用。主联合中的五个字是可用的，除了第一个字的位0必须保持清零。
 * 许多用户使用这个字来存储一个保证对齐的对象指针。
 * 如果使用与 page->mapping 相同的存储空间，必须在释放页面之前将其恢复为 NULL。
 *
 * 如果你的页面不会映射到用户空间，还可以使用 mapcount 联合中的四个字节，
 * 但在释放之前必须调用 page_mapcount_reset()。
 *
 * 如果想使用 refcount 字段，必须以不会导致其他 CPU 临时增加然后减少
 * 引用计数时出现问题的方式使用。在从 alloc_pages() 接收到页面时，
 * 引用计数将为正。
 *
 * 如果分配 order > 0 的页面，可以使用每个子页面中的某些字段，
 * 但之后可能需要恢复其中一些值。
 *
 * SLUB 使用 cmpxchg_double() 来原子性地更新其空闲列表和计数器。
 * 这要求在 struct slab 中空闲列表和计数器是相邻的并且是双字对齐的。
 * 由于 struct slab 目前只是重新解释 struct page 的位，
 * 我们将所有 struct page 对齐到双字边界，并确保 'freelist' 在 struct slab 中是对齐的。
 */
#ifdef CONFIG_HAVE_ALIGNED_STRUCT_PAGE                              
#define _struct_page_alignment  __aligned(2 * sizeof(unsigned long))
#else                                                               
#define _struct_page_alignment  __aligned(sizeof(unsigned long))    
#endif                                                              
```
-->

## `struct page`

系统中的每个物理页面都用`struct page`描述:
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
        * 此页面的 KMSAN 元数据:
        *  - 影子页面: 每个位表示原始页面对应位是否已初始化（0）或未初始化（1）；
        *  - 原始页面: 每 4 个字节包含一个栈追踪的 ID，用于指示未初始化值的创建位置。
        */
        struct page *kmsan_shadow;
        struct page *kmsan_origin;
#endif

#ifdef LAST_CPUPID_NOT_IN_PAGE_FLAGS
        int _last_cpupid;
#endif
} _struct_page_alignment;
```

`flags`字段里的每一位定义在`enum pageflags`。在内核代码中，我们经常看到类似`SetPageError`、`PagePrivate`的函数，但总是找不到定义，这是因为这些函数是通过宏定义生成的。宏定义是对`enum pageflags`中的每个值进行宏展开，这里列出设置和检测的宏定义:
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

页的拥有者可能是用户空间进程、动态分配的内核数据、静态内核代码、页高速缓存等。

页的大小可以用`getconf -a | grep PAGESIZE`命令查看。`x86`默认打开配置`CONFIG_HAVE_PAGE_SIZE_4KB`和`CONFIG_PAGE_SIZE_4KB`。

在看内存相关的代码时，还会看到KASAN（Kernel Address Sanitizer）和KMSAN（Kernel Memory Sanitizer）两个概念，他们是用于检测和调试内存错误的工具。

## 两个`union`

我们再把`struct page`结构体中的两个`union`单独拎出来讲:
```c
/*
 * 这个联合体中有五个字（20/40字节）可用。
 * 警告: 第一个字的第0位用于 PageTail()。这意味着
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

## `struct folio`

`struct folio` 是一种新引入的结构，旨在表示多个连续页面的集合（例如，多个 4KB 页面的组合）。它包含对多个页面的引用，允许内核在处理大页或多个相邻页面时更有效地管理内存。`struct folio` 是对 `struct page` 概念的扩展。

```c
/**
 * struct folio - 表示一组连续的字节。
 * @flags: 与页面标志相同。
 * @lru: 最近最少使用列表；跟踪此 folio 最近的使用情况。
 * @mlock_count: 此 folio 被 mlock() 固定的次数。
 * @mapping: 此页面所属的文件，或指向匿名内存的 anon_vma。
 * @index: 文件内的偏移量，以页面为单位。对于匿名内存，这是从 mmap 开始的索引。
 * @private: 文件系统每个 folio 的数据（参见 folio_attach_private()）。
 * @swap: 如果 folio_test_swapcache()，则用于 swp_entry_t。
 * @_mapcount: 不要直接访问此成员。使用 folio_mapcount() 来查找此 folio 被用户空间映射的次数。
 * @_refcount: 不要直接访问此成员。使用 folio_ref_count() 来查找对此 folio 的引用次数。
 * @memcg_data: 内存控制组数据。
 * @_entire_mapcount: 不要直接使用，请调用 folio_entire_mapcount()。
 * @_nr_pages_mapped: 不要直接使用，请调用 folio_mapcount()。
 * @_pincount: 不要直接使用，请调用 folio_maybe_dma_pinned()。
 * @_folio_nr_pages: 不要直接使用，请调用 folio_nr_pages()。
 * @_hugetlb_subpool: 不要直接使用，请在 hugetlb.h 中使用访问器。
 * @_hugetlb_cgroup: 不要直接使用，请在 hugetlb_cgroup.h 中使用访问器。
 * @_hugetlb_cgroup_rsvd: 不要直接使用，请在 hugetlb_cgroup.h 中使用访问器。
 * @_hugetlb_hwpoison: 不要直接使用，请调用 raw_hwp_list_head()。
 * @_deferred_list: 内存压力下要拆分的 folios。
 *
 * folio 是一组物理上、虚拟上和逻辑上连续的字节。它的大小是 2 的幂，并且与该幂对齐。它至少与 %PAGE_SIZE 一样大。如果它在页面缓存中，它位于文件偏移的倍数位置。它可以映射到用户空间的任意页面偏移地址，但其内核虚拟地址与其大小对齐。
 */
struct folio {
        /* private: 不要记录匿名联合体 */
        union {
                struct {
        /* public: */
                        unsigned long flags;
                        union {
                                struct list_head lru;
        /* private: 避免输出混乱 */
                                struct {
                                        void *__filler;
        /* public: */
                                        unsigned int mlock_count;
        /* private: */
                                };
        /* public: */
                        };
                        struct address_space *mapping;
                        pgoff_t index;
                        union {
                                void *private;
                                swp_entry_t swap;
                        };
                        atomic_t _mapcount;
                        atomic_t _refcount;
#ifdef CONFIG_MEMCG
                        unsigned long memcg_data;
#endif
        /* private: 带有 struct page 的联合体是过渡性的 */
                };
                struct page page;
        };
        union {
                struct {
                        unsigned long _flags_1;
                        unsigned long _head_1;
                        unsigned long _folio_avail;
        /* public: */
                        atomic_t _entire_mapcount;
                        atomic_t _nr_pages_mapped;
                        atomic_t _pincount;
#ifdef CONFIG_64BIT
                        unsigned int _folio_nr_pages;
#endif
        /* private: 带有 struct page 的联合体是过渡性的 */
                };
                struct page __page_1;
        };
        union {
                struct {
                        unsigned long _flags_2;
                        unsigned long _head_2;
        /* public: */
                        void *_hugetlb_subpool;
                        void *_hugetlb_cgroup;
                        void *_hugetlb_cgroup_rsvd;
                        void *_hugetlb_hwpoison;
        /* private: 带有 struct page 的联合体是过渡性的 */
                };
                struct {
                        unsigned long _flags_2a;
                        unsigned long _head_2a;
        /* public: */
                        struct list_head _deferred_list;
        /* private: 带有 struct page 的联合体是过渡性的 */
                };
                struct page __page_2;
        };
};
```

## 区

物理内存在逻辑上分为三级结构: 节点（在NUMA系统中，Non-Uniform Memory Access，非统一内存访问，可查看`pg_data_t`），区，页。

内核使用区（zone）对相似特性的页进行分组，描述的是物理内存。定义在`include/linux/mmzone.h`:
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
        * 成功的可能性，并局部限制不可移动的分配 - 例如，增加 THP(Transparent Huge Pages， 透明大页)/大页的数量。
        * 值得注意的特殊情况包括:
        *
        * 1. 锁定页面: （长期）锁定可移动页面可能会实质上使这些页面变得不可移动。
        *    因此，我们不允许在 ZONE_MOVABLE 中长期锁定页面。当页面被锁定并出现错误时，
        *    它们会立即从正确的区域中获取。然而，当页面被锁定时，地址空间中可能已经有
        *    位于 ZONE_MOVABLE 中的页面（即用户在锁定前已访问该内存）。在这种情况下，
        *    我们将它们迁移到不同的区域。当迁移失败时 - 锁定失败。
        * 2. memblock 分配: kernelcore/movablecore 设置可能会在引导后导致
        *    ZONE_MOVABLE 中包含不可移动的分配。内存下线和分配会很早失败。
        * 3. 内存空洞: kernelcore/movablecore 设置可能会在引导后导致 ZONE_MOVABLE
        *    中包含内存空洞，例如，如果我们有仅部分填充的部分。内存下线和分配会很早失败。
        * 4. PG_hwpoison 页面: 虽然在内存下线期间可以跳过中毒页面，但这些页面不能被分配。
        * 5. 不可移动的 PG_offline 页面: 在半虚拟化环境中，热插拔的内存块可能仅部分
        *    由伙伴系统管理（例如，通过 XEN-balloon、Hyper-V balloon、virtio-mem）。
        *    由伙伴系统未管理的部分是不可移动的 PG_offline 页面。在某些情况下
        *    （virtio-mem），在内存下线期间可以跳过这些页面，但不能移动/分配。
        *    这些技术可能会使用 alloc_contig_range() 再次隐藏之前暴露的页面
        *    （例如，在 virtio-mem 中实现某种内存卸载）。
        * 6. ZERO_PAGE(0): kernelcore/movablecore 设置可能会导致
        *    ZERO_PAGE(0)（在不同平台上分配方式不同）最终位于可移动区域。
        *    ZERO_PAGE(0) 不能迁移。
        * 7. 内存热插拔: 当使用 memmap_on_memory 并将内存上线到 MOVABLE 区域时，
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

32位`x86`:

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
        * spanned_pages 是该区域所跨越的总页数，包括空洞，计算公式为:
        *      spanned_pages = zone_end_pfn - zone_start_pfn;
        *
        * present_pages 是该区域内存在的物理页，计算公式为:
        *      present_pages = spanned_pages - absent_pages(空洞中的页数);
        *
        * present_early_pages 是自启动早期以来该区域内存在的内存页，不包括热插拔内存。
        *
        * managed_pages 是由伙伴系统管理的存在页，计算公式为（reserved_pages 包括由 bootmem 分配器分配的页）:
        *      managed_pages = present_pages - reserved_pages;
        *
        * cma_pages 是分配给 CMA 使用的存在页（MIGRATE_CMA）。
        *
        * 因此， present_pages 可被内存热插拔或内存电源管理逻辑用来通过检查
        * (present_pages - managed_pages) 来找出未管理的页。而 managed_pages
        * 应该被页分配器和虚拟内存扫描器用来计算各种水印和阈值。
        *
        * 锁定规则:
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

# 内存分配与释放

## 函数接口

分配页:
```c
// 分配 2^order 个连续物理page，返回值是第一个page的指针
struct page *alloc_pages(gfp_t gfp_mask, unsigned int order)
// 页转换成逻辑地址
void *page_address(const struct page *page)
// 返回值是逻辑地址
unsigned long __get_free_pages(gfp_t gfp_mask, unsigned int order)
// 只分配一个page，返回值是page的指针
alloc_page(gfp_mask)
// 只分配一个page，返回值是虚拟地址
__get_free_page(gfp_mask)
// 只分配一个page，返回值是虚拟地址，全部填充0
unsigned long get_zeroed_page(gfp_t gfp_mask)
```

释放页:
```c
// 传入page指针
void __free_pages(struct page *page, unsigned int order)
// 传入虚拟地址
void free_pages(unsigned long addr, unsigned int order)
// 释放一个page，传入虚拟地址
free_page(addr)
```

分配以字节为单位的内存:
```c
// 物理地址是连续的，一般是硬件设备要用到
void *kmalloc(size_t size, gfp_t gfp)
// 和kmalloc()配对使用，参数p可以为NULL
void kfree(void *p)
// 可能睡眠，物理地址可以不连续，虚拟地址连续，典型用途是获取大块内存，如模块装载
void *vmalloc(unsigned long size)
// 可能睡眠，和 vmalloc() 配对使用
void vfree(const void *addr)
```

## `gfp_t`

在`include/linux/gfp_types.h`中的解释:
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

### 行为修饰符

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
 * 前提是未设置 __GFP_SKIP_ZERO ），则在分配时清零内存标签。此标志用于优化:
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

### 区修饰符

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

### 页面的移动性和放置提示

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
#define __GFP_WRITE     ((__force gfp_t)___GFP_WRITE)
#define __GFP_HARDWALL   ((__force gfp_t)___GFP_HARDWALL)
#define __GFP_THISNODE  ((__force gfp_t)___GFP_THISNODE)
#define __GFP_ACCOUNT   ((__force gfp_t)___GFP_ACCOUNT)
```

### 水位标志修饰符

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
#define __GFP_HIGH      ((__force gfp_t)___GFP_HIGH)
#define __GFP_MEMALLOC  ((__force gfp_t)___GFP_MEMALLOC)
#define __GFP_NOMEMALLOC ((__force gfp_t)___GFP_NOMEMALLOC)
```

### 回收修饰符

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
 * %__GFP_KSWAPD_RECLAIM 表示调用者希望在达到低水位时唤醒 kswapd 并让它回收页面直到达到高水位。当有备用选项可用且回收可能会中断系统时，调用者可能希望清除此标志。一个典型的例子是 THP(Transparent Huge Pages， 透明大页) 分配，其中备用选项成本低廉，但回收/压缩可能导致间接停滞。
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
 * %__GFP_NOFAIL: 虚拟内存实现 _必须_ 无限重试: 调用者无法处理分配失败。分配可能会无限期阻塞，但不会返回失败。测试失败是没有意义的。
 * 新用户应仔细评估（并且该标志应仅在没有合理的失败策略时使用），但绝对比在分配器周围编写无尽循环代码更可取。
 * 强烈不建议将此标志用于昂贵的分配。
 */
#define __GFP_IO        ((__force gfp_t)___GFP_IO)
#define __GFP_FS        ((__force gfp_t)___GFP_FS)
#define __GFP_DIRECT_RECLAIM    ((__force gfp_t)___GFP_DIRECT_RECLAIM) /* 调用者可以回收 */
#define __GFP_KSWAPD_RECLAIM    ((__force gfp_t)___GFP_KSWAPD_RECLAIM) /* kswapd 可以唤醒 */
#define __GFP_RECLAIM ((__force gfp_t)(___GFP_DIRECT_RECLAIM|___GFP_KSWAPD_RECLAIM))
#define __GFP_RETRY_MAYFAIL     ((__force gfp_t)___GFP_RETRY_MAYFAIL)
#define __GFP_NOFAIL    ((__force gfp_t)___GFP_NOFAIL)
#define __GFP_NORETRY   ((__force gfp_t)___GFP_NORETRY)
```

### 类型标志

组合了以上修饰符。

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
 * （原因: 内核中没有这样的用户）。
 *
 * %GFP_HIGHUSER 适用于可能映射到用户空间的用户空间分配，
 * 不需要内核直接访问但一旦使用便不能移动。例如硬件分配，直接将数据映射到用户空间，
 * 但没有地址限制。
 *
 * %GFP_HIGHUSER_MOVABLE 适用于内核不需要直接访问的用户空间分配，但需要访问时可以使用 kmap()。
 * 预计这些分配可通过页回收或页迁移移动。通常，LRU 上的页也会分配 %GFP_HIGHUSER_MOVABLE。
 *
 * %GFP_TRANSHUGE 和 %GFP_TRANSHUGE_LIGHT 用于 THP(Transparent Huge Pages， 透明大页) 分配。
 * 它们是复合分配，如果内存不可用，通常会快速失败，并且在失败时不会唤醒 kswapd/kcompactd。
 * _LIGHT 版本根本不尝试回收/压缩，默认用于页面错误路径，而非轻量版用于 khugepaged。
 */
#define GFP_ATOMIC      (__GFP_HIGH|__GFP_KSWAPD_RECLAIM) // 在中断处理程序、软中断、tasklet
#define GFP_KERNEL      (__GFP_RECLAIM | __GFP_IO | __GFP_FS)
#define GFP_KERNEL_ACCOUNT (GFP_KERNEL | __GFP_ACCOUNT)
#define GFP_NOWAIT      (__GFP_KSWAPD_RECLAIM)
// GFP_NOIO 表示在内存分配期间不允许执行任何 I/O 操作
// 当你在一个上下文中进行内存分配，而这个上下文可能已经持有某些锁，
// 这些锁在进行 I/O 操作时可能会导致死锁。在这种情况下，
// 使用 GFP_NOIO 可以确保内存分配不会触发 I/O 操作，
// 从而避免潜在的死锁问题。
#define GFP_NOIO        (__GFP_RECLAIM)
// GFP_NOFS 表示在内存分配期间不允许执行任何与文件系统相关的操作。
// 当你在文件系统代码中进行内存分配，而这个上下文可能已经持有文件系统的锁，
// 这些锁在进行文件系统操作时可能会导致死锁。在这种情况下，
// 使用 GFP_NOFS 可以确保内存分配不会触发文件系统操作，
// 从而避免潜在的死锁问题。
// GFP_NOIO 比 GFP_NOFS 更严格，因为它不仅禁止文件系统相关的操作，还禁止所有的 I/O 操作。
// GFP_NOFS 仅禁止文件系统相关的操作，但允许非文件系统的 I/O 操作。
#define GFP_NOFS        (__GFP_RECLAIM | __GFP_IO)
#define GFP_USER        (__GFP_RECLAIM | __GFP_IO | __GFP_FS | __GFP_HARDWALL)
#define GFP_DMA         __GFP_DMA
#define GFP_DMA32       __GFP_DMA32
#define GFP_HIGHUSER    (GFP_USER | __GFP_HIGHMEM)
#define GFP_HIGHUSER_MOVABLE    (GFP_HIGHUSER | __GFP_MOVABLE | __GFP_SKIP_KASAN)
#define GFP_TRANSHUGE_LIGHT     ((GFP_HIGHUSER_MOVABLE | __GFP_COMP | \
                         __GFP_NOMEMALLOC | __GFP_NOWARN) & ~__GFP_RECLAIM)
#define GFP_TRANSHUGE   (GFP_TRANSHUGE_LIGHT | __GFP_DIRECT_RECLAIM)
```

# slab

slab的字面意思是指“板”或“平板”。一个高速缓存包含多个slab，slab由一个或多个物理上连续的页组成，每个slab包含被缓存的数据结构。

高速缓存使用结构体`struct kmem_cache`表示，其中包含多个`struct kmem_cache_node`对象，这个结构体中有3个重要的成员:
```c
struct kmem_cache_node {
        ...
        struct list_head slabs_partial; // 部分满
        struct list_head slabs_full;    // 满
        struct list_head slabs_free;    // 空
        ...
};
```

这3个链表包含高速缓存中的所有slab，`struct slab`用于描述每个slab:
```c
/* 重用 struct page 中的位 */
struct slab {
        unsigned long __page_flags;

#if defined(CONFIG_SLAB)

        struct kmem_cache *slab_cache;
        union {
                struct {
                        struct list_head slab_list; // 满、部分满或空链表
                        void *freelist; /* 空闲对象索引数组 */
                        void *s_mem;    /* 在slab中的第一个对象 */
                };
                struct rcu_head rcu_head;
        };
        unsigned int active;

#elif defined(CONFIG_SLUB)

        struct kmem_cache *slab_cache;
        union {
                struct {
                        union {
                                struct list_head slab_list;
#ifdef CONFIG_SLUB_CPU_PARTIAL
                                struct {
                                        struct slab *next;
                                        int slabs;      /* 剩余的slab数量 */
                                };
#endif
                        };
                        /* 双字边界 */
                        union {
                                struct {
                                        void *freelist;         /* 第一个空闲对象 */
                                        union {
                                                unsigned long counters;
                                                struct {
                                                        unsigned inuse:16; // slab中已分配的对象数
                                                        unsigned objects:15;
                                                        unsigned frozen:1;
                                                };
                                        };
                                };
#ifdef system_has_freelist_aba
                                freelist_aba_t freelist_counter;
#endif
                        };
                };
                struct rcu_head rcu_head;
        };
        unsigned int __unused;

#else
#error "Unexpected slab allocator configured"
#endif

        atomic_t __page_refcount;
#ifdef CONFIG_MEMCG
        unsigned long memcg_data;
#endif
};
```

slab分配器的接口:
```c
/**
 * kmem_cache_create - 创建一个缓存。可能休眠，不能在中断上下文中使用
 * @name: 用于在 /proc/slabinfo 中标识此缓存的字符串。
 * @size: 在此缓存中创建的对象的大小。
 * @align: 对象所需的对齐方式。
 * @flags: SLAB 标志
 * @ctor: 对象的构造函数。大部分都设置为NULL
 * 
 * 不能在中断内调用，但可以被中断。
 * 当缓存分配新的页面时，@ctor 会运行。
 * 
 * 标志包括
 * 
 * %SLAB_POISON - 用已知的测试模式（a5a5a5a5）填充 slab，以捕捉对未初始化内存的引用。
 * 
 * %SLAB_RED_ZONE - 在分配的内存周围插入“红色”区域，以检查缓冲区溢出。
 * 
 * %SLAB_HWCACHE_ALIGN - 将此缓存中的对象对齐到硬件缓存行。如果您像 davem 一样仔细计算周期，这可能会有好处。
 *
 * 还有其他的标志，请查看上述宏定义附近的代码
 * 
 * 返回: 成功时返回指向缓存的指针，失败时返回 NULL。
 */
struct kmem_cache *
kmem_cache_create(const char *name, unsigned int size, unsigned int align,
                slab_flags_t flags, void (*ctor)(void *))

/* 销毁高速缓存，也可能睡眠 */
void kmem_cache_destroy(struct kmem_cache *s)

/* 获取对象 */
void *kmem_cache_alloc(struct kmem_cache *cachep, gfp_t flags)

/**
 * kmem_cache_free - 释放一个对象
 * @cachep: 分配对象时使用的缓存。
 * @objp: 之前分配的对象。
 * 
 * 释放之前从该缓存中分配的对象。
 */
void kmem_cache_free(struct kmem_cache *cachep, void *objp)
```

目前内核中已经引入SLUB (Unqueued Allocator)，旧的SLAB将被弃用，请查看`SLAB_DEPRECATED`配置。SLUB 是一种改进版的 slab 分配器，它通过最小化缓存行使用来代替管理缓存对象队列（SLAB 方法）。每个 CPU 的缓存通过对象的 slabs 而不是对象的队列来实现。SLUB 可以有效地使用内存并具有增强的诊断功能。

Linux内核曾经有过slob分配器，已经移除了，具体请查看[`remove SLOB and allow kfree() with kmem_cache_alloc()`](https://lore.kernel.org/all/20230310103210.22372-1-vbabka@suse.cz/)。

# 高端内存

用`struct page *alloc_pages(gfp_t gfp_mask, unsigned int order)`分配的page，如果指定了`__GFP_HIGHMEM`，就没有逻辑地址，如果是映射到内核地址空间，可以使用:
```c
// 高端内存就建立永久映射，可能休眠
void *kmap(struct page *page)
// 解除映射
void kunmap(struct page *page)
```

当不能休眠时，使用临时映射（原子映射）:
```c
// 建立临时映射，禁止内核抢占
void *kmap_atomic(struct page *page)
/**
 * kunmap_atomic - 解除由 kmap_atomic() 映射的虚拟地址 - 已弃用！
 * @__addr:       要解除映射的虚拟地址
 * 
 * 解除先前由 kmap_atomic() 映射的地址并重新启用页面错误处理。
 * 根据 PREEMP_RT 配置，还可能重新启用迁移和抢占。用户不应该依赖这些副作用。
 * 
 * 映射应按照它们映射的相反顺序解除映射。
 * 有关嵌套的详细信息，请参见 kmap_local_page()。
 * 
 * @__addr 可以是映射页面内的任何地址，因此不需要减去添加的任何偏移量。
 * 与 kunmap() 相反，此函数接受从 kmap_atomic() 返回的地址，而不是传递给它的页面。
 * 如果传递页面，编译器会发出警告。
 */
kunmap_atomic(__addr)
```

# 每CPU变量

为每一个cpu分配一个变量可以减少数据锁定，也可以减少缓存失效（也叫缓存抖动，会影响系统性能）。

## 老的方法

```c
unsigned long data[NR_CPUS];
int cpu;
cpu = get_cpu(); // 禁止内核抢占
data[cpu]++;
put_cpu(); // 激活内核抢占
```

## 新的接口

编译时创建，注意不能在动态插入的模块中使用:
```c
// 定义
DEFINE_PER_CPU(type, name)
// 声明
DECLARE_PER_CPU(type, name)
// 获取并操作当前cpu变量，禁止抢占
get_cpu_var(name)++
// 完成，激活抢占
put_cpu_var(name)
// 获取并操作其他cpu上的变量，不会禁止抢占，也没有锁保护，不建议这样用
per_cpu(name, cpunum)++
```

动态创建:
```c
// 调用__alloc_percpu实现
alloc_percpu(type) // __alloc_percpu(sizeof(type), __alignof__(type))
/**                                                           
 * __alloc_percpu - 分配动态每CPU区域              
 * @size: 要分配的区域大小，以字节为单位                   
 * @align: 区域的对齐方式（最大为 PAGE_SIZE）                  
 *                                                            
 * 等效于 __alloc_percpu_gfp(size, align, %GFP_KERNEL)。
 */                                                           
void __percpu *__alloc_percpu(size_t size, size_t align)      
/**                                  
 * free_percpu - 释放每CPU区域    
 * @ptr: 指向要释放的区域的指针     
 *                                   
 * 释放每CPU区域 @ptr。            
 *                                   
 * 上下文:                          
 * 可以从原子上下文中调用。
 */                                  
void free_percpu(void __percpu *ptr) 
// 获取并操作当前cpu变量，禁止抢占，和编译时创建的用法一样
get_cpu_var(name)++
// 完成，激活抢占，和编译时创建的用法一样
put_cpu_var(name)
```

# 进程地址空间

## 内存描述符

内核使用内存描述符表示进程的地址空间。`struct task_struct`结构体中的`mm`成员指向进程使用的内存描述符，内核线程的没有内存描述符所以`mm`为空（可使用前一个用户空间进程的`mm`，用`active_mm`指向）。
```c
struct mm_struct {
        struct {
                /*
                 * 经常被写入的字段被放置在一个单独的缓存行中。
                 */
                struct {
                        /**
                         * @mm_count: 对 &struct mm_struct 的引用数量
                         * (@mm_users 计数为 1)。
                         *
                         * 使用 mmgrab()/mmdrop() 来修改。当该值降为 0 时，
                         * 释放 &struct mm_struct。
                         */
                        atomic_t mm_count;
                } ____cacheline_aligned_in_smp;

                struct maple_tree mm_mt;
#ifdef CONFIG_MMU
                unsigned long (*get_unmapped_area) (struct file *filp,
                                unsigned long addr, unsigned long len,
                                unsigned long pgoff, unsigned long flags);
#endif
                unsigned long mmap_base;        /* mmap 区域的基址 */
                unsigned long mmap_legacy_base; /* 自下而上分配的 mmap 区域的基址 */
#ifdef CONFIG_HAVE_ARCH_COMPAT_MMAP_BASES
                /* 兼容 mmap() 的基址 */
                unsigned long mmap_compat_base;
                unsigned long mmap_compat_legacy_base;
#endif
                unsigned long task_size;        /* 任务虚拟内存空间的大小 */
                pgd_t * pgd; // 页全局目录，由 page_table_lock 保护 

#ifdef CONFIG_MEMBARRIER
                /**
                 * @membarrier_state: 控制 membarrier 行为的标志。
                 *
                 * 该字段靠近 @pgd，希望能在相同的缓存行中，以便在 switch_mm()
                 * 中减少缓存失效。
                 */
                atomic_t membarrier_state;
#endif

                /**
                 * @mm_users: 包括用户空间在内的用户数量。
                 *
                 * 使用 mmget()/mmget_not_zero()/mmput() 来修改。当该值降为 0 时
                 * (即任务退出且没有其他临时引用持有者时)，我们也会释放对
                 * @mm_count 的引用(如果 @mm_count 也降为 0，则可能会释放 &struct mm_struct)。
                 */
                atomic_t mm_users; // 使用该地址的进程数目

#ifdef CONFIG_SCHED_MM_CID
                /**
                 * @pcpu_cid: 每个 CPU 当前的 cid。
                 *
                 * 跟踪每个 CPU 当前分配的 mm_cid。每个 CPU 的 mm_cid 值由其各自的
                 * 运行队列锁序列化。
                 */
                struct mm_cid __percpu *pcpu_cid;
                /*
                 * @mm_cid_next_scan: 下一次 mm_cid 扫描的时间（以 jiffies 为单位）。
                 */
                unsigned long mm_cid_next_scan;
#endif
#ifdef CONFIG_MMU
                atomic_long_t pgtables_bytes;   /* 所有页表的大小 */
#endif
                int map_count;                  /* VMAs 的数量 */

                spinlock_t page_table_lock; /* 保护页表和某些计数器 */
                /*
                 * 在某些内核配置下，当前 mmap_lock 在 'mm_struct' 内的偏移量
                 * 是 0x120，这是非常优化的，因为它的两个热字段 'count' 和 'owner'
                 * 位于两个不同的缓存行中，当 mmap_lock 竞争激烈时，这两个字段都
                 * 会被频繁访问，当前布局有助于减少缓存争用。
                 *
                 * 因此，在 mmap_lock 之前添加新字段时请小心，这很容易将这两个
                 * 字段推入一个缓存行中。
                 */
                struct rw_semaphore mmap_lock;

                // 所有的mm_struct对象通过mmlist域连接在双链表中
                struct list_head mmlist; /* 可能交换的 mm 的列表。这些
                                          * 全局串联在 init_mm.mmlist 上，
                                          * 由 mmlist_lock 保护。
                                          */
#ifdef CONFIG_PER_VMA_LOCK
                /*
                 * 该字段具有类似锁的语义，这意味着它有时会以 ACQUIRE/RELEASE 语义访问。
                 * 大致而言，递增序列号等同于释放 VMAs 上的锁；读取序列号可以是获取
                 * VMA 读锁的一部分。
                 *
                 * 在使用 RELEASE 语义的写 mmap_lock 下可以修改。
                 * 当持有写 mmap_lock 时，可以在没有其他保护的情况下读取。
                 * 如果不持有写 mmap_lock，则可以使用 ACQUIRE 语义读取。
                 */
                int mm_lock_seq;
#endif

                unsigned long hiwater_rss; /* RSS 使用的高水位标记 */
                unsigned long hiwater_vm;  /* 虚拟内存使用的高水位标记 */

                unsigned long total_vm;    /* 映射的总页数 */
                unsigned long locked_vm;   /* 设置了 PG_mlocked 的页数 */
                atomic64_t    pinned_vm;   /* 永久增加引用计数 */
                unsigned long data_vm;     /* VM_WRITE & ~VM_SHARED & ~VM_STACK */
                unsigned long exec_vm;     /* VM_EXEC & ~VM_WRITE & ~VM_STACK */
                unsigned long stack_vm;    /* VM_STACK */
                unsigned long def_flags;

                /**
                 * @write_protect_seq: 当任何线程写保护此 mm 映射的页以强制稍后 COW 时锁定，
                 * 例如在为 fork() 复制页表期间。
                 */
                seqcount_t write_protect_seq;

                spinlock_t arg_lock; /* 保护以下字段 */

                unsigned long start_code, end_code, start_data, end_data;
                unsigned long start_brk, brk, start_stack;
                unsigned long arg_start, arg_end, env_start, env_end;

                unsigned long saved_auxv[AT_VECTOR_SIZE]; /* 用于 /proc/PID/auxv */

                struct percpu_counter rss_stat[NR_MM_COUNTERS];

                struct linux_binfmt *binfmt;

                /* 特定架构的 MM 上下文 */
                mm_context_t context;

                unsigned long flags; /* 必须使用原子位操作访问 */

#ifdef CONFIG_AIO
                spinlock_t                      ioctx_lock;
                struct kioctx_table __rcu       *ioctx_table;
#endif
#ifdef CONFIG_MEMCG
                /*
                 * "owner" 指向被视为此 mm 的规范用户/所有者的任务。必须同时满足以下
                 * 条件才能更改它:
                 *
                 * current == mm->owner
                 * current->mm != mm
                 * new_owner->mm == mm
                 * 持有 new_owner->alloc_lock
                 */
                struct task_struct __rcu *owner;
#endif
                struct user_namespace *user_ns;

                /* 存储指向 /proc/<pid>/exe 符号链接的文件引用 */
                struct file __rcu *exe_file;
#ifdef CONFIG_MMU_NOTIFIER
                struct mmu_notifier_subscriptions *notifier_subscriptions;
#endif
#if defined(CONFIG_TRANSPARENT_HUGEPAGE) && !USE_SPLIT_PMD_PTLOCKS
                pgtable_t pmd_huge_pte; /* 由 page_table_lock 保护 */
#endif
#ifdef CONFIG_NUMA_BALANCING
                /*
                 * numa_next_scan 是下一次 PTE 重新映射为 PROT_NONE 以触发 NUMA 提示
                 * 故障的时间；此类故障收集统计数据并在必要时将页迁移到新节点。
                 */
                unsigned long numa_next_scan;

                /* 扫描和重新映射 PTEs 的重新启动点。 */
                unsigned long numa_scan_offset;

                /* numa_scan_seq 防止两个线程重新映射 PTEs。 */
                int numa_scan_seq;
#endif
                /*
                 * 正在进行带有批处理 TLB 刷新的操作。移动进程内存的任何操作都需要
                 * 在移动 PROT_NONE 映射页时刷新 TLB。
                 */
                atomic_t tlb_flush_pending;
#ifdef CONFIG_ARCH_WANT_BATCHED_UNMAP_TLB_FLUSH
                /* 参见 flush_tlb_batched_pending() */
                atomic_t tlb_flush_batched;
#endif
                struct uprobes_state uprobes_state;
#ifdef CONFIG_PREEMPT_RT
                struct rcu_head delayed_drop;
#endif
#ifdef CONFIG_HUGETLB_PAGE
                atomic_long_t hugetlb_usage;
#endif
                struct work_struct async_put_work;

#ifdef CONFIG_IOMMU_SVA
                u32 pasid;
#endif
#ifdef CONFIG_KSM
                /*
                 * 表示此进程中有多少页参与 KSM 合并（不包括 ksm_zero_pages）。
                 */
                unsigned long ksm_merging_pages;
                /*
                 * 表示检查是否进行 KSM 合并的页数，包括已合并和未合并的。
                 */
                unsigned long ksm_rmap_items;
                /*
                 * 表示启用 KSM use_zero_pages 时，有多少空页与内核零页合并。
                 */
                unsigned long ksm_zero_pages;
#endif /* CONFIG_KSM */
#ifdef CONFIG_LRU_GEN
                struct {
                        /* 此 mm_struct 位于 lru_gen_mm_list 上 */
                        struct list_head list;
                        /*
                         * 切换到此 mm_struct 时设置，作为自上次每节点页表遍历清除相应
                         * 位以来是否使用过的提示。
                         */
                        unsigned long bitmap;
#ifdef CONFIG_MEMCG
                        /* 指向上面 "owner" 的 memcg */
                        struct mem_cgroup *memcg;
#endif
                } lru_gen;
#endif /* CONFIG_LRU_GEN */
        } __randomize_layout;

        /*
         * mm_cpumask 需要位于 mm_struct 的末尾，因为它是基于 nr_cpu_ids 动态调整大小的。
         */
        unsigned long cpu_bitmap[];
};
```

## 相关函数

进程创建时:
```c
fork
  copy_mm
    mm = oldmm // if (clone_flags & CLONE_VM)
    dup_mm
      allocate_mm
        kmem_cache_alloc
```

进程退出时:
```c
exit_mm
  mmput // 减少 mm_users
    __mmput
      mmdrop // 减少mm_count
        mm_count
          free_mm
            kmem_cache_free
```

## 虚拟内存区域

可被进程合法访问的地址空间称为内存区域（memory area），内存区域也称为虚拟内存区域（Virtual Memory Areas, VMAs）。如果两个独立的进程将同一个文件映射到各自的地址空间，不会共享`vm_area_struct`；如果两个线程共享一个地址空间，则共享`vm_area_struct`。
```c
/*
 * 这个结构体描述了一个虚拟内存区域。每个 VM 区域/任务有一个这样的结构体。
 * 一个 VM 区域是指进程虚拟内存空间中具有特定页错误处理规则的部分
 * （例如共享库、可执行区域等）。
 */
struct vm_area_struct {
        /* 第一缓存行包含用于 VMA 树遍历的信息。 */

        union {
                struct {
                        /* VMA 覆盖 mm 内的 [vm_start; vm_end) 地址 */
                        unsigned long vm_start;
                        unsigned long vm_end;
                };
#ifdef CONFIG_PER_VMA_LOCK
                struct rcu_head vm_rcu; /* 用于延迟释放。 */
#endif
        };

        struct mm_struct *vm_mm;        /* 我们所属的地址空间。 */
        pgprot_t vm_page_prot;    /* 该 VMA 的访问权限。 */

        /*
         * 标志，参见 mm.h。
         * 查看 VM_READ 等宏定义。
         * 其中VM_SEQ_READ和VM_RAND_READ可通过系统调用madvise(behavior)设置，behavior可以是MADV_SEQUENTIAL或MADV_RANDOM
         * 要修改请使用 vm_flags_{init|reset|set|clear|mod} 函数。
         */
        union {
                const vm_flags_t vm_flags;
                vm_flags_t __private __vm_flags;
        };

#ifdef CONFIG_PER_VMA_LOCK
        /*
         * 只能在同时持有以下两者时写入（使用 WRITE_ONCE()）:
         *  - mmap_lock（写模式）
         *  - vm_lock->lock（写模式）
         * 在持有以下任一时可以可靠读取:
         *  - mmap_lock（读或写模式）
         *  - vm_lock->lock（读或写模式）
         * 可以在不持有任何锁时不可靠地读取（使用 READ_ONCE()），
         * 这种情况下只有 RCU 可以保持 VMA 结构体已分配。
         *
         * 该序列计数器明确允许溢出；序列计数器重用只会导致偶尔
         * 采用慢路径。
         */
        int vm_lock_seq;
        struct vma_lock *vm_lock;

        /* 指示从 mm->mm_mt 树分离的区域的标志 */
        bool detached;
#endif

        /*
         * 对于具有地址空间和后备存储的区域，
         * 链接到 address_space->i_mmap 区间树。
         *
         */
        struct {
                struct rb_node rb;
                unsigned long rb_subtree_last;
        } shared;

        /*
         * 一个文件的 MAP_PRIVATE vma 可以同时在 i_mmap 树和 anon_vma
         * 列表中，发生 COW 后。MAP_SHARED vma 只能在 i_mmap 树中。
         * 匿名 MAP_PRIVATE、栈或 brk vma（文件指针为 NULL）只能在
         * anon_vma 列表中。
         */
        struct list_head anon_vma_chain; /* 由 mmap_lock 和 page_table_lock
                                                                          * 序列化 */
        struct anon_vma *anon_vma;         /* 由 page_table_lock 序列化 */

        /* 处理该结构体的函数指针。 */
        const struct vm_operations_struct *vm_ops;

        /* 我们后备存储的信息: */
        unsigned long vm_pgoff;  /* 在 PAGE_SIZE 单位内的 vm_file 偏移 */
        struct file *vm_file;      /* 我们映射的文件（可以为 NULL）。 */
        void *vm_private_data;    /* 曾经是 vm_pte（共享内存） */

#ifdef CONFIG_ANON_VMA_NAME
        /*
         * 对于私有和共享匿名映射，一个指向包含 vma 名称的以空字符结尾的字符串的指针，
         * 如果未命名则为 NULL。由 mmap_lock 序列化。使用 anon_vma_name 访问。
         */
        struct anon_vma_name *anon_name;
#endif
#ifdef CONFIG_SWAP
        atomic_long_t swap_readahead_info;
#endif
#ifndef CONFIG_MMU
        struct vm_region *vm_region;    /* NOMMU 映射区域 */
#endif
#ifdef CONFIG_NUMA
        struct mempolicy *vm_policy;    /* 该 VMA 的 NUMA 策略 */
#endif
#ifdef CONFIG_NUMA_BALANCING
        struct vma_numab_state *numab_state;    /* NUMA 平衡状态 */
#endif
        struct vm_userfaultfd_ctx vm_userfaultfd_ctx;
} __randomize_layout;
```

常见的段（这里的"段"英文是"section"）:

- TEXT段: 程序代码段，`vm_flags`字段为`VM_EXEC`和`VM_READ`，`vm_file`字段不为`NULL`。
- DATA段: 静态初始化的数据，所以有初值的全局变量（不为0）和static变量在data区。`vm_flags`为`VM_READ`和`VM_WRITE`。
- BSS段: Block Started by Symbol，通常是指用来存放程序中**未初始化或初始化为0**的全局变量的一块内存区域，在程序载入时由内核清0。`vm_flags`为`VM_READ`和`VM_WRITE`。

## VMA操作

`vm_area_struct`中的`vm_ops`字段:
```c
/*
 * 这些是虚拟内存管理函数 - 打开一个区域、关闭和取消映射它
 * （需要保持磁盘上的文件最新等），当发生无页异常或写保护页异常时
 * 调用的函数指针。
 */
struct vm_operations_struct {
        // 指定的内存区域被加到地址空间时，open被调用
        void (*open)(struct vm_area_struct * area);
        /**
         * @close: 当 VMA 从内存管理中移除时调用。
         * 上下文: 用户上下文。可能会休眠。调用者持有 mmap_lock。
         */
        void (*close)(struct vm_area_struct * area);
        /* 在拆分前的任何时间调用以检查是否允许拆分 */
        int (*may_split)(struct vm_area_struct *area, unsigned long addr);
        int (*mremap)(struct vm_area_struct *area);
        /*
         * 由 mprotect() 调用以在 mprotect() 完成之前进行特定于驱动程序的权限检查。
         * VMA 不能被修改。如果 mprotect() 可以继续则返回 0。
         */
        int (*mprotect)(struct vm_area_struct *vma, unsigned long start,
                        unsigned long end, unsigned long newflags);
        vm_fault_t (*fault)(struct vm_fault *vmf);
        vm_fault_t (*huge_fault)(struct vm_fault *vmf, unsigned int order);
        vm_fault_t (*map_pages)(struct vm_fault *vmf,
                        pgoff_t start_pgoff, pgoff_t end_pgoff);
        unsigned long (*pagesize)(struct vm_area_struct * area);

        /* 通知一个以前只读的页面即将变为可写，如果返回错误将导致 SIGBUS */
        vm_fault_t (*page_mkwrite)(struct vm_fault *vmf);

        /* 当使用 VM_PFNMAP|VM_MIXEDMAP 时与 page_mkwrite 相同 */
        vm_fault_t (*pfn_mkwrite)(struct vm_fault *vmf);

        /* 当 get_user_pages() 失败时由 access_process_vm 调用，通常用于特殊的 VMA。
         * 另请参见 generic_access_phys()，它是一个适用于任何 iomem 映射的通用实现。
         */
        int (*access)(struct vm_area_struct *vma, unsigned long addr,
                      void *buf, int len, int write);

        /* 由 /proc/PID/maps 代码调用，以询问 VMA 是否有特殊名称。
         * 返回非 NULL 还会导致此 VMA 无条件地被转储。
         */
        const char *(*name)(struct vm_area_struct *vma);

#ifdef CONFIG_NUMA
        /*
         * set_policy() 操作必须在返回时为任何非 NULL 的 @new mempolicy 添加引用
         * 以保持策略。调用者应传递 NULL @new 以移除策略并回退到周围的上下文
         * ——即不要安装 MPOL_DEFAULT 策略，也不要安装任务或系统默认的 mempolicy。
         */
        int (*set_policy)(struct vm_area_struct *vma, struct mempolicy *new);

        /*
         * get_policy() 操作必须为标记为 MPOL_SHARED 的任何 (vma,addr) 处的策略添加引用 [mpol_get()]。
         * mm/mempolicy.c 中的共享策略基础设施将自动执行此操作。
         * 如果 (vma,addr) 处的策略未标记为 MPOL_SHARED，则 get_policy() 不得添加引用。
         * vma 策略受 mmap_lock 保护。如果在该地址处没有 [共享/vma] mempolicy，
         * 则 get_policy() 操作必须返回 NULL——即不要“回退”到任务或系统默认策略。
         */
        struct mempolicy *(*get_policy)(struct vm_area_struct *vma,
                                        unsigned long addr);
#endif
        /*
         * 由 vm_normal_page() 调用，用于特殊的 PTEs 以查找 @addr 的页面。
         * 如果默认行为（使用 pte_page()）找不到正确的页面，这很有用。
         */
        struct page *(*find_special_page)(struct vm_area_struct *vma,
                                          unsigned long addr);
};
```

## 查看内存区域

我们看一个最简单的程序`test.c`:
```c
#include <stdio.h>

int main(int argc, char *argv[]) {
        printf("Hello, World!\n");
        while (1) {
                // 在循环中可以执行其他操作，这里我们只让它一直循环
        }
        return 0;
}
```

然后编译运行:
```sh
gcc -o test test.c
./test & # 后台运行，会打印出进程号
```

查看内存区域:
```sh
cat /proc/2985/maps
00400000-00401000 r--p 00000000 fd:02 806031960                          /root/test
00401000-00402000 r-xp 00001000 fd:02 806031960                          /root/test
00402000-00403000 r--p 00002000 fd:02 806031960                          /root/test
00403000-00404000 r--p 00002000 fd:02 806031960                          /root/test
00404000-00405000 rw-p 00003000 fd:02 806031960                          /root/test
36732000-36753000 rw-p 00000000 00:00 0                                  [heap]
7f4ed4e61000-7f4ed4e64000 rw-p 00000000 00:00 0 
7f4ed4e64000-7f4ed4e8c000 r--p 00000000 fd:02 268556763                  /usr/lib64/libc.so.6
7f4ed4e8c000-7f4ed4ff5000 r-xp 00028000 fd:02 268556763                  /usr/lib64/libc.so.6
7f4ed4ff5000-7f4ed5043000 r--p 00191000 fd:02 268556763                  /usr/lib64/libc.so.6
7f4ed5043000-7f4ed5047000 r--p 001de000 fd:02 268556763                  /usr/lib64/libc.so.6
7f4ed5047000-7f4ed5049000 rw-p 001e2000 fd:02 268556763                  /usr/lib64/libc.so.6
7f4ed5049000-7f4ed5053000 rw-p 00000000 00:00 0 
7f4ed505b000-7f4ed505f000 r--p 00000000 00:00 0                          [vvar]
7f4ed505f000-7f4ed5061000 r-xp 00000000 00:00 0                          [vdso]
7f4ed5061000-7f4ed5062000 r--p 00000000 fd:02 268556760                  /usr/lib64/ld-linux-x86-64.so.2
7f4ed5062000-7f4ed5089000 r-xp 00001000 fd:02 268556760                  /usr/lib64/ld-linux-x86-64.so.2
7f4ed5089000-7f4ed5093000 r--p 00028000 fd:02 268556760                  /usr/lib64/ld-linux-x86-64.so.2
7f4ed5093000-7f4ed5095000 r--p 00032000 fd:02 268556760                  /usr/lib64/ld-linux-x86-64.so.2
7f4ed5095000-7f4ed5097000 rw-p 00034000 fd:02 268556760                  /usr/lib64/ld-linux-x86-64.so.2
7ffc36b1b000-7ffc36b3c000 rw-p 00000000 00:00 0                          [stack]
ffffffffff600000-ffffffffff601000 --xp 00000000 00:00 0                  [vsyscall]
```

还可以用更方便阅读的形式输出:
```sh
pmap 2985
3090:   ./test
0000000000400000      4K r---- test
0000000000401000      4K r-x-- test # 可读和可执行，代码段
0000000000402000      4K r---- test
0000000000403000      4K r---- test
0000000000404000      4K rw--- test # 可读和可写，数据段
0000000036732000    132K rw---   [ anon ] # 匿名映射，通常用于堆或其他动态分配的内存
00007f4ed4e61000     12K rw---   [ anon ]
00007f4ed4e64000    160K r---- libc.so.6
00007f4ed4e8c000   1444K r-x-- libc.so.6
00007f4ed4ff5000    312K r---- libc.so.6
00007f4ed5043000     16K r---- libc.so.6
00007f4ed5047000      8K rw--- libc.so.6 # 数据段
00007f4ed5049000     40K rw---   [ anon ]
00007f4ed505b000     16K r----   [ anon ]
00007f4ed505f000      8K r-x--   [ anon ]
00007f4ed5061000      4K r---- ld-linux-x86-64.so.2
00007f4ed5062000    156K r-x-- ld-linux-x86-64.so.2
00007f4ed5089000     40K r---- ld-linux-x86-64.so.2
00007f4ed5093000      8K r---- ld-linux-x86-64.so.2
00007f4ed5095000      8K rw--- ld-linux-x86-64.so.2
00007ffc36b1b000    132K rw---   [ stack ] # 栈内存区域
ffffffffff600000      4K --x--   [ anon ]
 total             2520K
```

## 内存区域操作函数

```c
/**
 * find_vma() - 查找给定地址的 VMA，或下一个 VMA。
 * @mm: 要检查的 mm_struct
 * @addr: 地址
 *
 * 返回值: 与 addr 关联的 VMA，或下一个 VMA。
 * 在 addr 及其以上没有 VMA 的情况下，可能返回 %NULL。
 */
struct vm_area_struct *find_vma(struct mm_struct *mm, unsigned long addr)

/**
 * find_vma_prev() - 查找给定地址的 VMA，或下一个 VMA，并将 %pprev 设置为前一个 VMA（如果有的话）。
 * 与 find_vma() 相同，但也在 *pprev 中返回指向前一个 VMA 的指针。
 * @mm: 要检查的 mm_struct
 * @addr: 地址
 * @pprev: 指向前一个 VMA 的指针
 *
 * 注意，这里缺少 RCU 锁，因为使用了外部的 mmap_lock()。
 *
 * 返回值: 与 @addr 关联的 VMA，或下一个 VMA。
 * 在 addr 及其以上没有 VMA 的情况下，可能返回 %NULL。
 */
struct vm_area_struct *
find_vma_prev(struct mm_struct *mm, unsigned long addr,
              struct vm_area_struct **pprev)

/**
 * find_vma_intersection() - 查找第一个与区间相交的 VMA
 * @mm: 进程地址空间
 * @start_addr: 包含的起始用户地址
 * @end_addr: 排除的结束用户地址
 *
 * 返回值: 区间内的第一个 VMA，否则为 %NULL。假设 start_addr < end_addr。
 */
struct vm_area_struct *find_vma_intersection(struct mm_struct *mm,
                                             unsigned long start_addr,
                                             unsigned long end_addr)

// 将一个地址区间加入到进程的地址空间，扩展已存在的内存区域域创建新的区域，调用者必须持有 current->mm->mmap_lock 的写锁
// file为NULL或offset为0称为匿名映射（anonymous mapping），否则称为文件映射（file-backed mapping）
// prot: 请查看 PROT_READ 等定义
// flag: 请查看 MAP_SHARED 和 MAP_GROWSDOWN 等定义
unsigned long do_mmap(struct file *file, unsigned long addr,
                      unsigned long len, unsigned long prot,
                      unsigned long flags, vm_flags_t vm_flags,
                      unsigned long pgoff, unsigned long *populate,
                      struct list_head *uf)

// 最终调用到 do_mmap()
SYSCALL_DEFINE6(mmap_pgoff, unsigned long, addr, unsigned long, len,
                unsigned long, prot, unsigned long, flags,          
                unsigned long, fd, unsigned long, pgoff)            

/* do_munmap() - 取消映射给定地址范围，非maple tree感知的do_munmap()调用的包装函数
 * @mm: mm_struct结构体                                                         
 * @start: 要munmap的起始地址                                        
 * @len: 要munmap的长度                                          
 * @uf: userfaultfd的list_head                                             
 *                                                                            
 * 返回: 成功返回0，否则返回错误                                     
 */
int do_munmap(struct mm_struct *mm, unsigned long start, size_t len,
              struct list_head *uf)

// 最终调用到 do_munmap()
SYSCALL_DEFINE2(munmap, unsigned long, addr, size_t, len)
```

## 页表

应用程序操作的是虚拟内存，但处理器操作的是物理内存。举个例子，32位x86 PAE模式下（Physical Address Extension，物理地址扩展，32位线性地址可以访问64G物理内存，处理器管脚36个），Linux内核使用三级页表完成地址转换:

- 顶级页表 - 页全局目录: PGD，Page Global Directory，`pgd_t`类型的数组。
- 二级页表 - 页中间目录: PMD，Page Middle Directory，`pmd_t`类型的数组。
- 三级页表 - 页表项: PTE，Page Table Entry，包含`pte_t`类型的页表项，指向物理页面。

其他体系结构下的使用的页表级数不一样，如`arm64`采用四级页表。`struct mm_struct`中的`pgd`成员指向进程的页全局目录，由`page_table_lock`保护。内核正确的设置了页表后，搜索页表的工作由硬件完成。

为了加快搜索物理地址的速度，多数体系结构实现了 Translation Lookaside Buffer，翻译为: 转译后备缓冲器（又叫页表缓存、转址旁路缓存）。90%命中TLB，10%需要访问页表。

# 伙伴算法

`struct zone`中有一个`free_area[MAX_ORDER + 1]`的数组:
```c
struct free_area {                                       
        struct list_head        free_list[MIGRATE_TYPES];
        unsigned long           nr_free;                 
};                                                       
```

其中`free_area[0]`中的链表中的内存块单位是`2^0=1`个page，`free_area[1]`的单位是`2^1`个page，以此类推。这种内存块称为"页块"或简称"块"，大小相同且物理地址连续的两个页块称为"伙伴"（Buddy）。

伙伴算法的工作原理: 先在大小满足要求的块链表中查找是否有空闲块，如果有就直接分配内存，否则在更大的块链表中查找，逆过程就是块的释放，把满足伙伴关系的块合并。

要分配`2^3=8`个page，`free_area[3]`（8个page的页块大小）、`free_area[4]`（16个page的页块大小）中的链表都找不到空闲块，只有`free_area[5]`（32个page的页块大小）中有空闲块，先把32 page的页块分成2个16 page的页块，其中一个16 page的页块插入`free_area[4]`的链表中，另一个16 page的页块再分成2个8 page的页块，一个8 page的页块插入`free_area[3]`的链表中，另一个8 page的页块用于最终分配。具体请查看`__rmqueue_smallest()`和`expand()`函数。访问虚拟内存时，如果物理内存还没分配，会发生缺页异常，内核将从磁盘或交换文件（SWAP）中将要访问的页装入物理内存，最终调用`alloc_pages()`为进程分配page，并将虚拟内存和物理内存的映射关系写入页表。内核总是**尽量延后**分配用户空间的内存。

<!-- ing begin -->
# 页高速缓存

访问磁盘的速度要远低于访问内存的速度。

缓存策略有三种:

- 不缓存，直接写到磁盘，同时让缓存中的数据失效。
- Write Through，写操作同时更新内存缓存和磁盘。
- Write Back，写操作先写到内存缓存中，磁盘不会立刻更新，先标记脏页，然后将脏页周期性的写到磁盘中。

Linux的缓存回收是选择没有标记为脏的页进行简单替换。最近最少使用算法，LRU，
<!-- ing end -->