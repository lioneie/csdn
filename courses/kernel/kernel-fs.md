一般的Linux书籍都是先讲解进程和内存相关的知识，但我想先讲解文件系统。<!-- public begin -->第一，因为我就是做文件系统的，更擅长这一块，其他模块的内容我还要再去好好看看书，毕竟不能误人子弟嘛；第二，是<!-- public end -->因为文件系统模块更接近于用户态，是相对比较好理解的内容（当然想深入还是要下大功夫的），由文件系统入手比较适合初学者。

# 什么是文件系统

我们先来看一下什么是文件系统？我们买电脑时，肯定会配一块硬盘（现在一般是固态硬盘），硬盘是用来存储数据资料的。比如要存储一句话:"我爱操作系统"，一个汉字占用2个字节，存储这一句话要占用12个字节（不包括结束符），我们可以用2种方法来存储。第一种方法是从硬盘第一个字节开始存储，前两个字节存储"我"，第三四个字节存储"爱"，以此类推。第二种方法是先创建一个文件，在这个文件里存储这句话，我们打开硬盘时，只需要找到这个文件的位置，就能找到这句话。第一种方法数据管理起来很不方便，所以一般都用第二种方法，第二种方法管理数据的规则就称为文件系统。

文件系统可以分为3类：

- 磁盘文件系统，如ext2、ext4、xfs、ntfs等。
- 网络文件系统，如nfs、cifs等。
- 特殊文件系统，如procfs、sysfs等。

我们来实际操作一下，虚拟机中的`${HOME}/qemu-kernel/start.sh`文件中增加以下内容（如果已有就不用增加）：
```sh
-drive file=1,if=none,format=raw,cache=writeback,file.locking=off,id=dd_1 \
-device scsi-hd,drive=dd_1,id=disk_1,logical_block_size=512,physical_block_size=512 \
```

然后在`${HOME}/qemu-kernel/`目录下创建一个文件：
```sh
fallocate -l 1G 1
```

进入虚拟机后，可以使用上面提到的第一种方法，直接从磁盘的第一个字节开始存：
```sh
echo "我爱操作系统" > /dev/sda
cat /dev/sda # 从磁盘的第一个字节开始输出
```

也可以用上面提到的第二种方法，也就是我们要学的文件系统：
```sh
mkfs.ext4 -F /dev/sda # 格式化文件系统
mount -t ext4 /dev/sda /mnt # 把磁盘挂载到某个目录
df /dev/sda # 查看是否已经挂载上
echo "我爱操作系统" > /mnt/file # 存到挂载点下的某个文件中
cat /mnt/file # 输出文件内容
debugfs /dev/sda
# debugfs:  stats # Block size: 1024
# debugfs:  stat file # BLOCKS: (0):7169
dd if=/dev/sda of=./data bs=1 skip=7341056 count=20
cat data
umount /mnt # 卸载文件系统
```

# 虚拟文件系统

虚拟文件系统英文全称Virtual file system，缩写为VFS，又称为虚拟文件切换系统（virtual filesystem switch）。所有的文件系统都要先经过虚拟文件系统层，虚拟文件系统相当于制定了一套规则，如果你想写一个新的文件系统，只需要遵守这套规则就可以了。

VFS虽然是用C语言写的，但使用了面向对象的设计思路。

## 超级块对象

超级块英文全称是super block，存储特定文件系统的信息。如果是基于磁盘的文件系统，通常对应磁盘上特定扇区中的数据。如果不是基于磁盘的文件系统（如procfs或sysfs），会在使用时创建超级块，只保留在内存中。

超级块对象结构体定义在文件`include/linux/fs.h`中，比较长，不用背，用到时查一下就好，我会在这里加一些中文注释。
```c
struct super_block {
        struct list_head        s_list;         /* 放在最开头，指向 super_blocks，使用list_add_tail加到super_blocks链表中 */
        dev_t                   s_dev;          /* 设备标识符 */
        unsigned char           s_blocksize_bits; // 块大小，单位：bit
        unsigned long           s_blocksize; // 块大小，单位：字节
        loff_t                  s_maxbytes;     /* 文件大小上限 */
        struct file_system_type *s_type; // 文件系统类型
        const struct super_operations   *s_op; // 超级块方法
        const struct dquot_operations   *dq_op; // 磁盘限额方法
        const struct quotactl_ops       *s_qcop; // 限额控制方法
        const struct export_operations *s_export_op; // 导出方法
        unsigned long           s_flags; // 挂载标志
        unsigned long           s_iflags;       /* 内部 SB_I_* 标志 */
        unsigned long           s_magic; // 文件系统幻数
        struct dentry           *s_root; // 目录挂载点
        struct rw_semaphore     s_umount; // 卸载信号量
        int                     s_count; // 超级块引用计数
        atomic_t                s_active; // 活动引用计数
#ifdef CONFIG_SECURITY
        void                    *s_security; // 安全模块
#endif
        const struct xattr_handler **s_xattr; // 扩展的属性操作
#ifdef CONFIG_FS_ENCRYPTION
        const struct fscrypt_operations *s_cop;
        struct fscrypt_keyring  *s_master_keys; /* 主加密密钥正在使用 */
#endif
#ifdef CONFIG_FS_VERITY
        const struct fsverity_operations *s_vop;
#endif
#if IS_ENABLED(CONFIG_UNICODE)
        struct unicode_map *s_encoding;
        __u16 s_encoding_flags;
#endif
        struct hlist_bl_head    s_roots;        /* NFS 的备用根目录项 */
        struct list_head        s_mounts;       /* 挂载点列表；_不_用于文件系统，struct mount的mnt_instance加到这个链表中 */
        struct block_device     *s_bdev; // 相关的块设备
        struct backing_dev_info *s_bdi;
        struct mtd_info         *s_mtd; // 存储磁盘信息
        struct hlist_node       s_instances; // 这种类型的所有文件系统
        unsigned int            s_quota_types;  /* 支持的配额类型的位掩码 */
        struct quota_info       s_dquot;        /* 限额相关选项 */

        struct sb_writers       s_writers;

        /*
         * 将 s_fs_info, s_time_gran, s_fsnotify_mask 和
         * s_fsnotify_marks 放在一起以提高缓存效率。
         * 它们经常被访问但很少被修改。
         */
        void                    *s_fs_info;     /* 文件系统私有信息 */

        /* c/m/atime 的精度（以纳秒为单位，不能超过一秒） */
        u32                     s_time_gran; // 时间戳粒度
        /* c/m/atime 的时间限制（以秒为单位） */
        time64_t                   s_time_min;
        time64_t                   s_time_max;
#ifdef CONFIG_FSNOTIFY
        __u32                   s_fsnotify_mask;
        struct fsnotify_mark_connector __rcu    *s_fsnotify_marks;
#endif

        char                    s_id[32];       /* 信息性名称，文本名字 */
        uuid_t                  s_uuid;         /* Universally Unique Identifier"（全局唯一标识符） */

        unsigned int            s_max_links;

        /*
         * 下一个字段仅供 VFS 使用。任何文件系统都没有权利查看它。
         * 你已经被警告过了。
         */
        struct mutex s_vfs_rename_mutex;        /* Kludge，重命名锁 */

        /*
         * 文件系统子类型。如果非空，/proc/mounts 中的文件系统类型字段
         * 将是 "type.subtype"
         */
        const char *s_subtype; // 子类型名称

        const struct dentry_operations *s_d_op; /* 目录项的默认 d_op */

        struct shrinker s_shrink;       /* 每个超级块的收缩器句柄 */

        /* nlink == 0 但仍被引用的 inode 数量 */
        atomic_long_t s_remove_count;

        /*
         * 被监视的 inode/mount/sb 对象的数量，注意 inode 对象目前被双重计算。
         */
        atomic_long_t s_fsnotify_connectors;

        /* 超级块的只读状态正在被更改 */
        int s_readonly_remount;

        /* 每个超级块的 errseq_t 用于通过 syncfs 报告回写错误 */
        errseq_t s_wb_err;

        /* 从中断上下文推迟的 AIO 完成 */
        struct workqueue_struct *s_dio_done_wq;
        struct hlist_head s_pins;

        /*
         * 拥有的用户命名空间和默认上下文，用于解释文件系统的 uid、gid、配额、
         * 设备节点、xattrs 和安全标签。
         */
        struct user_namespace *s_user_ns;

        /*
         * list_lru 结构本质上只是指向每个节点 lru 列表表格的指针，
         * 每个节点都有自己的自旋锁。没有必要将它们放入不同的缓存行。
         */
        struct list_lru         s_dentry_lru; // 未被使用目录项链表
        struct list_lru         s_inode_lru;
        struct rcu_head         rcu;
        struct work_struct      destroy_work;

        struct mutex            s_sync_lock;    /* 同步序列化锁 */

        /*
         * 指示该超级块在文件系统栈中的深度
         */
        int s_stack_depth;

        /* s_inode_list_lock 保护 s_inodes */
        spinlock_t              s_inode_list_lock ____cacheline_aligned_in_smp;
        struct list_head        s_inodes;       /* 索引节点链表 */

        spinlock_t              s_inode_wblist_lock;
        struct list_head        s_inodes_wb;    /* 回写的 inode */
} __randomize_layout;
```

超级块对象通过`alloc_super()`函数创建和初始化，具体的文件系统如ext2文件系统的流程如下：
```c
mount // 系统调用
  do_mount
    path_mount
      do_new_mount
        vfs_get_tree
          legacy_get_tree
            ext2_mount // ext2_fs_type的.mount方法
              mount_bdev
                sget
                  alloc_super
```

## 超级块操作

超级块对象中最重要的一个成员是`s_op`，也是面向对象思想的一个体现，超级块操作函数表结构体也是定义在文件`include/linux/fs.h`中。也不需要背，用到时查一下就可以。

```c
struct super_operations {
        struct inode *(*alloc_inode)(struct super_block *sb); // 创建和初始化一个新的索引节点对象
        void (*destroy_inode)(struct inode *); // 销毁索引节点
        void (*free_inode)(struct inode *); // 释放索引节点

  void (*dirty_inode) (struct inode *, int flags); // 索引节点脏（也就是数据被修改了）时调用，日志更新（如ext4的jbd2）
        int (*write_inode) (struct inode *, struct writeback_control *wbc); // 将索引节点写入磁盘
        int (*drop_inode) (struct inode *); // 最后一个索引节点的引用释放后调用，普通unix文件系统不会定义这个函数
        void (*evict_inode) (struct inode *); // 从磁盘删除索引节点
        void (*put_super) (struct super_block *); // 释放超级块，要持有超级块锁
        int (*sync_fs)(struct super_block *sb, int wait); // 文件系统的元数据与磁盘同步
        int (*freeze_super) (struct super_block *, enum freeze_holder who);
        int (*freeze_fs) (struct super_block *);
        int (*thaw_super) (struct super_block *, enum freeze_holder who);
        int (*unfreeze_fs) (struct super_block *);
        int (*statfs) (struct dentry *, struct kstatfs *); // 获取文件系统状态
        int (*remount_fs) (struct super_block *, int *, char *); // 指定新的选项重新安装文件系统
        void (*umount_begin) (struct super_block *); // 中断安装操作，目前只有网络相关的文件系统以及fuse实现了

        int (*show_options)(struct seq_file *, struct dentry *);
        int (*show_devname)(struct seq_file *, struct dentry *);
        int (*show_path)(struct seq_file *, struct dentry *);
        int (*show_stats)(struct seq_file *, struct dentry *);
#ifdef CONFIG_QUOTA
        ssize_t (*quota_read)(struct super_block *, int, char *, size_t, loff_t);
        ssize_t (*quota_write)(struct super_block *, int, const char *, size_t, loff_t);
        struct dquot **(*get_dquots)(struct inode *);
#endif
        long (*nr_cached_objects)(struct super_block *,
                                  struct shrink_control *);
        long (*free_cached_objects)(struct super_block *,
                                    struct shrink_control *);
        void (*shutdown)(struct super_block *sb);
};
```

注意在C语言的实现中，如果要获取`struct super_block *`父对象，必须要传入指针。

## 索引节点对象

索引节点包含了操作文件和目录时的全部信息，也定义在`include/linux/fs.h`。也不需要背，用到时查一下就可以。

```c
/*
 * 将“struct inode”中的大多数已读字段和经常访问的字段（特别是用于RCU路径查找和“stat”数据的字段）放在前面。
 */
struct inode {
        umode_t                 i_mode; // 访问权限
        unsigned short          i_opflags;
        kuid_t                  i_uid; // 使用者的id
        kgid_t                  i_gid; // 使用组的id
        unsigned int            i_flags; // 文件系统标志

#ifdef CONFIG_FS_POSIX_ACL
        struct posix_acl        *i_acl;
        struct posix_acl        *i_default_acl;
#endif

        const struct inode_operations   *i_op; // 索引节点操作表
        struct super_block      *i_sb; // 相关的超级块
        struct address_space    *i_mapping; // 相关的地址映射

#ifdef CONFIG_SECURITY
        void                    *i_security; // 安全模块
#endif

        /* 统计数据，不在路径遍历中访问 */
        unsigned long           i_ino; // 索引节点号
        /*
         * 文件系统只能直接读取 i_nlink。它们应该使用以下函数进行修改：
         *
         *    (set|clear|inc|drop)_nlink
         *    inode_(inc|dec)_link_count
         */
        union {
                const unsigned int i_nlink; // 硬链接数
                unsigned int __i_nlink;
        };
        dev_t                   i_rdev; // 实际设备标识符
        loff_t                  i_size; // 大小，单位：字节
        struct timespec64       i_atime; // 最后访问时间
        struct timespec64       i_mtime; // 最后修改时间
        struct timespec64       __i_ctime; /* 使用 inode_*_ctime accessors ! 最后改变时间 */
        spinlock_t              i_lock; /* 保护 i_blocks, i_bytes, 还有 i_size，自旋锁 */
        unsigned short          i_bytes; // 使用的字节数
        u8                      i_blkbits; // 以位为单位的块大小
        u8                      i_write_hint;
        blkcnt_t                i_blocks; // 文件的块数

#ifdef __NEED_I_SIZE_ORDERED
        seqcount_t              i_size_seqcount; // 对 i_size 进行串行计数
#endif

        /* Miscellaneous 杂项 */
        unsigned long           i_state; // 状态标志
        struct rw_semaphore     i_rwsem;

        unsigned long           dirtied_when;   /* 第一次弄脏时的 jiffies 值，第一次弄脏数据的时间 */
        unsigned long           dirtied_time_when;

        struct hlist_node       i_hash; // 散列表
        struct list_head        i_io_list;      /* 后备设备 IO 列表 */
#ifdef CONFIG_CGROUP_WRITEBACK
        struct bdi_writeback    *i_wb;          /* 关联的 cgroup wb */

        /* 外来 inode 检测，参见 wbc_detach_inode() */
        int                     i_wb_frn_winner;
        u16                     i_wb_frn_avg_time;
        u16                     i_wb_frn_history;
#endif
        struct list_head        i_lru;          /* inode LRU list，Least Recently Used 最近最少使用链表 */
        struct list_head        i_sb_list; // 超级块链表
        struct list_head        i_wb_list;      /* 后备设备回写列表 */
        union {
                struct hlist_head       i_dentry; // 目录项链表
                struct rcu_head         i_rcu;
        };
        atomic64_t              i_version; // 版本号
        atomic64_t              i_sequence; /* see futex */
        atomic_t                i_count; // 引用计数
        atomic_t                i_dio_count;
        atomic_t                i_writecount; // 写者计数
#if defined(CONFIG_IMA) || defined(CONFIG_FILE_LOCKING)
        atomic_t                i_readcount; /* struct files open RO */
#endif
        union {
                const struct file_operations    *i_fop; /* former ->i_op->default_file_ops，默认的索引节点操作 */
                void (*free_inode)(struct inode *);
        };
        struct file_lock_context        *i_flctx;
        struct address_space    i_data; // 设备地址映射
        struct list_head        i_devices; // 块设备链表
        union {
                struct pipe_inode_info  *i_pipe; // 管道信息
                struct cdev             *i_cdev; // 字符设备驱动
                char                    *i_link;
                unsigned                i_dir_seq;
        };

        __u32                   i_generation;

#ifdef CONFIG_FSNOTIFY
        __u32                   i_fsnotify_mask; /* 该 inode 关心的所有事件 */
        struct fsnotify_mark_connector __rcu    *i_fsnotify_marks;
#endif

#ifdef CONFIG_FS_ENCRYPTION
        struct fscrypt_info     *i_crypt_info;
#endif

#ifdef CONFIG_FS_VERITY
        struct fsverity_info    *i_verity_info;
#endif

        void                    *i_private; /* 文件系统或设备的私有指针 */
} __randomize_layout;
```

## 索引节点操作

索引节点对象中最重要的一个成员是`i_op`，也是面向对象思想的一个体现，索引节点操作函数表结构体也是定义在文件`include/linux/fs.h`中。还是不需要背，用到什么查什么就好。

```c
struct inode_operations {
        struct dentry * (*lookup) (struct inode *,struct dentry *, unsigned int); // 寻找索引节点，对应dentry中的文件名
        const char * (*get_link) (struct dentry *, struct inode *, struct delayed_call *);
        int (*permission) (struct mnt_idmap *, struct inode *, int); // 检查访问模式
        struct posix_acl * (*get_inode_acl)(struct inode *, int, bool);

        int (*readlink) (struct dentry *, char __user *,int); // 复制符号链接中的数据

        int (*create) (struct mnt_idmap *, struct inode *,struct dentry *, // 为dentry创建一个新的索引节点
                       umode_t, bool);
        int (*link) (struct dentry *,struct inode *,struct dentry *); // 创建硬链接
        int (*unlink) (struct inode *,struct dentry *); // 删除索引节点对象
        int (*symlink) (struct mnt_idmap *, struct inode *,struct dentry *, // 创建符号链接
                        const char *);
        int (*mkdir) (struct mnt_idmap *, struct inode *,struct dentry *, // 创建新目录
                      umode_t);
        int (*rmdir) (struct inode *,struct dentry *); // 删除目录
        int (*mknod) (struct mnt_idmap *, struct inode *,struct dentry *, // 创建特殊文件（设备文件、命名管道、套接字）
                      umode_t,dev_t);
        int (*rename) (struct mnt_idmap *, struct inode *, struct dentry *, // 移动文件
                        struct inode *, struct dentry *, unsigned int);
        int (*setattr) (struct mnt_idmap *, struct dentry *, struct iattr *); // 被notify_change()调用，修改索引节点后，通知
        int (*getattr) (struct mnt_idmap *, const struct path *, // 从磁盘更新时调用
                        struct kstat *, u32, unsigned int);
        ssize_t (*listxattr) (struct dentry *, char *, size_t); // 将所有属性列表复制到缓冲列表中
        int (*fiemap)(struct inode *, struct fiemap_extent_info *, u64 start,
                      u64 len);
        int (*update_time)(struct inode *, int);
        int (*atomic_open)(struct inode *, struct dentry *,
                           struct file *, unsigned open_flag,
                           umode_t create_mode);
        int (*tmpfile) (struct mnt_idmap *, struct inode *,
                        struct file *, umode_t);
        struct posix_acl *(*get_acl)(struct mnt_idmap *, struct dentry *,
                                     int);
        int (*set_acl)(struct mnt_idmap *, struct dentry *,
                       struct posix_acl *, int);
        int (*fileattr_set)(struct mnt_idmap *idmap,
                            struct dentry *dentry, struct fileattr *fa);
        int (*fileattr_get)(struct dentry *dentry, struct fileattr *fa);
        struct offset_ctx *(*get_offset_ctx)(struct inode *inode);
} ____cacheline_aligned;
```

## 目录项对象

需要注意目录项表示路径中的一个部分，如`/home/linux/file`路径中，`/`、`home`、`linux`是目录，属于目录项对象，`file`属于文件，也属于目录项对象。也就是说，目录项也能表示文件。目录项对象结构体定义在`include/linux/dcache.h`中，成员不多。

```c
struct dentry {
        /* RCU 查找涉及的字段 */
        unsigned int d_flags;           /* 受 d_lock 保护，目录项标识 */
        seqcount_spinlock_t d_seq;      /* 每个目录项的 seqlock */
        struct hlist_bl_node d_hash;    /* 查找哈希列表 */
        struct dentry *d_parent;        /* 父目录 */
        struct qstr d_name;             // 目录项名，d_name.name是字符串数组
        struct inode *d_inode;          /* 名称所属的位置 - NULL 表示negative， 关联的索引节点 */
        unsigned char d_iname[DNAME_INLINE_LEN];        /* 短文件名 */

        /* 引用查找也涉及以下内容 */
        struct lockref d_lockref;       /* 每个目录项的锁和引用计数，用d_count()函数获取 */
        const struct dentry_operations *d_op; // 目录项操作指针
        struct super_block *d_sb;       /* 目录项树的根，文件的超级块 */
        unsigned long d_time;           /* 由 d_revalidate 使用，重置时间 */
        void *d_fsdata;                 /* 文件系统特有数据 */

        union {
                struct list_head d_lru;         /* LRU list，Least Recently Used 最近最少使用链表 */
                wait_queue_head_t *d_wait;      /* 仅用于查找中的项目 */
        };
        struct list_head d_child;       /* 父列表的子项，目录项内部形成的链表 */
        struct list_head d_subdirs;     /* 子目录链表 */
        /*
         * d_alias 和 d_rcu 可以共享内存
         */
        union {
                struct hlist_node d_alias;      /* inode alias list，索引节点别名链表，当有多个硬链接时，就有多个dentry指向同一个inode，多个dentry都放到d_alias链表中 */
                struct hlist_bl_node d_in_lookup_hash;  /* 仅用于查找中的项目 */
                struct rcu_head d_rcu; // RCU加锁
        } d_u;
} __randomize_layout;
```

目录项有3种状态：

- 被使用：`d_inode`不为空，`d_count()`大于等于`1`
- 未被使用：`d_inode`不为空，`d_count()`为`0`，注意曾经可能使用过
- 无效状态：`d_inode`为空

目录项缓存有3种：

- "被使用的"目录项链表：`inode->i_dentry`链表，一个`inode`可能有多个链接，一个`inode`可能有多个`dentry`
- "Least Recently Used 最近最少使用"链表：`d_lru`链表，包含未被使用和无效状态的`dentry`
- 散列表：`dentry_hashtable`链表，散列值由`d_hash()`计算，`d_lookup()`查找散列表

目录项让相应的索引节点的`i_count`为正，目录项被缓存了，索引节点肯定也被缓存了。

## 目录项操作

目录项对象中最重要的一个成员是`d_op`，目录项操作结构体定义在`include/linux/dcache.h`中，方法不多。

```c
struct dentry_operations {
        int (*d_revalidate)(struct dentry *, unsigned int); // 判断目录项对象是否有效，从缓存中使用目录项时会调用，一般文件系统不实现这个方法
        int (*d_weak_revalidate)(struct dentry *, unsigned int);
        int (*d_hash)(const struct dentry *, struct qstr *); // 生成散列值
        int (*d_compare)(const struct dentry *, // 比较两个文件名，微软的文件系统需要实现，因为不区分大小写
                        unsigned int, const char *, const struct qstr *);
        int (*d_delete)(const struct dentry *); // d_count等于0时调用
        int (*d_init)(struct dentry *);
        void (*d_release)(struct dentry *); // 释放
        void (*d_prune)(struct dentry *);
        void (*d_iput)(struct dentry *, struct inode *); // dentry丢失相关的inode，也就是磁盘索引节点被删除了，调用此方法
        char *(*d_dname)(struct dentry *, char *, int);
        struct vfsmount *(*d_automount)(struct path *);
        int (*d_manage)(const struct path *, bool);
        struct dentry *(*d_real)(struct dentry *, const struct inode *);
} ____cacheline_aligned;
```

## 文件对象

站在用户角度，我们更关心的是文件对象。文件对象表示进程打开的文件，多个进程可能同时打开和操作同一个文件，同一个文件可能存在多个文件对象，最终指向同一个`dentry`。

```c
/*
 * f_{lock,count,pos_lock}成员可能存在高度争用，共享相同的缓存行。
 * 而f_{lock,mode}经常一起使用，因此也共享相同的缓存行。
 * 读取频率较高的f_{path,inode,op}被保存在单独的缓存行中。
 */
struct file {
        union {
                struct llist_node       f_llist; // 文件对象链表
                struct rcu_head         f_rcuhead; // 释放之后的rcu链表
                unsigned int            f_iocb_flags;
        };

        /*
         * 保护 f_ep 和 f_flags。
         * 禁止在 IRQ 上下文中获取。
         */
        spinlock_t              f_lock; // 单个文件结构锁
        fmode_t                 f_mode; // 访问模式
        atomic_long_t           f_count; // 引用计数
        struct mutex            f_pos_lock;
        loff_t                  f_pos; // 当前位移量（文件指针）
        unsigned int            f_flags; // 打开时指定的标志
        struct fown_struct      f_owner; // 拥有者通过信号进行异步IO数据的传送
        const struct cred       *f_cred; // 文件的信任状
        struct file_ra_state    f_ra; // 预读状态
        struct path             f_path; // 包含dentry和vfsmount
        struct inode            *f_inode;       /* cached value */
        const struct file_operations    *f_op; // 文件操作表

        u64                     f_version; // 版本号
#ifdef CONFIG_SECURITY
        void                    *f_security; // 安全模块
#endif
        /* tty 驱动程序以及其他驱动程序可能需要 */
        void                    *private_data; // tty设备驱动的钩子

#ifdef CONFIG_EPOLL
        /* 由 fs/eventpoll.c 用于链接所有的钩子到这个file对象 */
        struct hlist_head       *f_ep; // 事件池链表
#endif /* #ifdef CONFIG_EPOLL */
        struct address_space    *f_mapping; // 页缓存映射
        errseq_t                f_wb_err;
        errseq_t                f_sb_err; /* for syncfs */
} __randomize_layout
  __attribute__((aligned(4)));  /* 防止某些奇怪的情况认为 2 是可以的 */
```

## 文件操作

文件对象中最重要的一个成员是`f_op`，你会发现，文件操作方法名和很多系统调用很像。

```c
struct file_operations {
        struct module *owner;
        loff_t (*llseek) (struct file *, loff_t, int); // 更新偏移量指针
        ssize_t (*read) (struct file *, char __user *, size_t, loff_t *); // 读取数据，并更新文件指针
        ssize_t (*write) (struct file *, const char __user *, size_t, loff_t *); // 写入数据并更新指针
        ssize_t (*read_iter) (struct kiocb *, struct iov_iter *);
        ssize_t (*write_iter) (struct kiocb *, struct iov_iter *);
        int (*iopoll)(struct kiocb *kiocb, struct io_comp_batch *,
                        unsigned int flags);
        int (*iterate_shared) (struct file *, struct dir_context *); // v6.6在iterate_dir中加读锁，但在较早的版本（如v4.19）有些文件系统未实现此方法时加写锁
        __poll_t (*poll) (struct file *, struct poll_table_struct *); // 睡眠等待给定文件活动
        long (*unlocked_ioctl) (struct file *, unsigned int, unsigned long); // 不需要持有BKL，相比compat_ioctl，优先实现此方法
        long (*compat_ioctl) (struct file *, unsigned int, unsigned long); // 可移植变种，也不需要持有BKL
        int (*mmap) (struct file *, struct vm_area_struct *); // 将文件映射到地址空间上
        unsigned long mmap_supported_flags;
        int (*open) (struct inode *, struct file *); // 创建新的文件对象，与inode关联
        int (*flush) (struct file *, fl_owner_t id); // 已打开文件的引用计数减少时调用，作用取决于具体的文件系统
        int (*release) (struct inode *, struct file *); // 当引用计数为0时调用，作用取决于具体的文件系统
        int (*fsync) (struct file *, loff_t, loff_t, int datasync); // 所有文件的缓存数据写回磁盘
        int (*fasync) (int, struct file *, int); // 打开或关闭异步IO的通告信号
        int (*lock) (struct file *, int, struct file_lock *); // 给文件上锁
        unsigned long (*get_unmapped_area)(struct file *, unsigned long, unsigned long, unsigned long, unsigned long); // 获取未使用的地址空间来映射给定的文件
        int (*check_flags)(int); // 检查fcntl()系统调用的flags的有效性，只有nfs实现了
        int (*flock) (struct file *, int, struct file_lock *); // 提供忠告锁
        ssize_t (*splice_write)(struct pipe_inode_info *, struct file *, loff_t *, size_t, unsigned int);
        ssize_t (*splice_read)(struct file *, loff_t *, struct pipe_inode_info *, size_t, unsigned int);
        void (*splice_eof)(struct file *file);
        int (*setlease)(struct file *, int, struct file_lock **, void **);
        long (*fallocate)(struct file *file, int mode, loff_t offset,
                          loff_t len);
        void (*show_fdinfo)(struct seq_file *m, struct file *f);
#ifndef CONFIG_MMU
        unsigned (*mmap_capabilities)(struct file *);
#endif
        ssize_t (*copy_file_range)(struct file *, loff_t, struct file *,
                        loff_t, size_t, unsigned int);
        loff_t (*remap_file_range)(struct file *file_in, loff_t pos_in,
                                   struct file *file_out, loff_t pos_out,
                                   loff_t len, unsigned int remap_flags);
        int (*fadvise)(struct file *, loff_t, loff_t, int);
        int (*uring_cmd)(struct io_uring_cmd *ioucmd, unsigned int issue_flags);
        int (*uring_cmd_iopoll)(struct io_uring_cmd *, struct io_comp_batch *,
                                unsigned int poll_flags);
} __randomize_layout;
```

## 地址空间

磁盘块可能不连续和动态变化的，文件访问需要将文件看作一个连续的字节流，这个矛盾的解决核心在于地址空间的引入。

```c
// 可缓存、可映射对象的内容。
struct address_space {
        struct inode            *host;            // 拥有者，可以是 inode 或 block_device。
        struct xarray           i_pages;          // 缓存的页面。
        struct rw_semaphore     invalidate_lock;  // 在无效操作期间，保护页缓存内容与文件偏移->磁盘块映射之间的一致性。它还用于阻止通过内存映射修改页缓存内容。
        gfp_t                   gfp_mask;         // 用于分配页面的内存分配标志。
        atomic_t                i_mmap_writable;  // VM_SHARED 映射的数量。
#ifdef CONFIG_READ_ONLY_THP_FOR_FS
        /* thp 的数量，仅用于非 shmem 文件 */
        atomic_t                nr_thps;        // 页缓存中的 THP（非共享内存）数量。
#endif
        struct rb_root_cached   i_mmap;         // 私有和共享映射的树。
        unsigned long           nrpages;        // 页条目的数量，由 i_pages 锁保护。
        pgoff_t                 writeback_index;// 写回从这里开始。
        const struct address_space_operations *a_ops; // 方法。
        unsigned long           flags;          // 错误位和标志（AS_*）。
        struct rw_semaphore     i_mmap_rwsem;   // 保护 @i_mmap 和 @i_mmap_writable
        errseq_t                wb_err;         // 最近发生的错误。
        spinlock_t              private_lock;   // 供 address_space 的拥有者使用。
        struct list_head        private_list;   // 供 address_space 的拥有者使用。
        void                    *private_data;  // 供 address_space 的拥有者使用。
} __attribute__((aligned(sizeof(long)))) __randomize_layout;
```

地址空间操作:
```c
struct address_space_operations {
        int (*writepage)(struct page *page, struct writeback_control *wbc); // 将文件在内存page中的更新到磁盘上
        int (*read_folio)(struct file *, struct folio *); // 从磁盘上读取文件的数据到内存page中

        /* 从此映射中回写一些脏页。 */
        int (*writepages)(struct address_space *, struct writeback_control *); // 将多个page更新到磁盘上

        /* 标记一个 folio 为脏页。如果此操作使其变脏，则返回 true */
        bool (*dirty_folio)(struct address_space *, struct folio *);

        void (*readahead)(struct readahead_control *);

        int (*write_begin)(struct file *, struct address_space *mapping, // 要求具体文件系统准备将数据写到文件
                                loff_t pos, unsigned len,
                                struct page **pagep, void **fsdata);
        int (*write_end)(struct file *, struct address_space *mapping,   // 完成数据复制之后调用，具体文件系统 unlock page，释放引用计数，更新 i_size
                                loff_t pos, unsigned len, unsigned copied,
                                struct page *page, void *fsdata);

        /* 不幸的是，FIBMAP 需要这个权宜之计。不要使用它 */
        sector_t (*bmap)(struct address_space *, sector_t); // 将文件中的逻辑块扇区编号映射为对应设备上的物理块扇区编号
        void (*invalidate_folio) (struct folio *, size_t offset, size_t len); // 使某个page部分或全部失效
        bool (*release_folio)(struct folio *, gfp_t); // 日志文件系统使用，释放page
        void (*free_folio)(struct folio *folio);
        ssize_t (*direct_IO)(struct kiocb *, struct iov_iter *iter); // 绕过page cache
        /*
         * 将folio的内容移动到指定的目标，如果migrate_mode是MIGRATE_ASYNC，就不阻塞（异步）
         */
        int (*migrate_folio)(struct address_space *, struct folio *dst,
                        struct folio *src, enum migrate_mode);
        int (*launder_folio)(struct folio *); // 释放一个folio之前调用，回写dirty的folio
        bool (*is_partially_uptodate) (struct folio *, size_t from, // 判断是否最新
                        size_t count);
        void (*is_dirty_writeback) (struct folio *, bool *dirty, bool *wb);
        int (*error_remove_page)(struct address_space *, struct page *); // 被内存故障处理代码使用

        /* swapfile support */
        int (*swap_activate)(struct swap_info_struct *sis, struct file *file,
                                sector_t *span);
        void (*swap_deactivate)(struct file *file);
        int (*swap_rw)(struct kiocb *iocb, struct iov_iter *iter);
};
```

## 其他数据结构

`file_system_type`描述各种特定文件系统类型，每种文件系统只有一个`file_system_type`对象，具体文件系统如ext2模块加载时调用`init_ext2_fs() -> register_filesystem()`注册。根文件系统类型`rootfs_fs_type`。
```c
struct file_system_type {
        const char *name; // 名字
        int fs_flags; // 类型标志
#define FS_REQUIRES_DEV         1 
#define FS_BINARY_MOUNTDATA     2
#define FS_HAS_SUBTYPE          4
#define FS_USERNS_MOUNT         8       /* 可以由用户命名空间根目录挂载 */
#define FS_DISALLOW_NOTIFY_PERM 16      /* 禁用 fanotify 权限事件 */
#define FS_ALLOW_IDMAP         32       /* 文件系统已更新以处理 vfs id 映射。 */
#define FS_RENAME_DOES_D_MOVE   32768   /* 文件系统将在内部处理 rename() 时的 d_move()。 */
        int (*init_fs_context)(struct fs_context *);
        const struct fs_parameter_spec *parameters;
        struct dentry *(*mount) (struct file_system_type *, int, // 从磁盘中读取超级块
                       const char *, void *);
        void (*kill_sb) (struct super_block *);   // 终止访问超级块
        struct module *owner; // 文件系统模块
        struct file_system_type * next; // 链表中下一个文件系统类型
        struct hlist_head fs_supers;    // 超级块对象链表

        // 运行时使锁生效
        struct lock_class_key s_lock_key;
        struct lock_class_key s_umount_key;
        struct lock_class_key s_vfs_rename_key;
        struct lock_class_key s_writers_key[SB_FREEZE_LEVELS];

        struct lock_class_key i_lock_key;
        struct lock_class_key i_mutex_key;
        struct lock_class_key invalidate_lock_key;
        struct lock_class_key i_mutex_dir_key;
};
```

文件系统挂载时，有一个`mount`结构体在挂载点被创建，代表文件系统实例，也就是代表一个挂载点。

```c
struct mount {
        struct hlist_node mnt_hash;     // 散列表
        struct mount *mnt_parent;       // 父文件系统
        struct dentry *mnt_mountpoint;  // 挂载点的目录项
        struct vfsmount mnt;
        union {
                struct rcu_head mnt_rcu;
                struct llist_node mnt_llist;
        };
#ifdef CONFIG_SMP
        struct mnt_pcp __percpu *mnt_pcp;
#else
        int mnt_count;   // 引用计数
        int mnt_writers; // 写者引用计数
#endif
        struct list_head mnt_mounts;    /* 子文件系统链表, 固定在此 */
        struct list_head mnt_child;     /* 子文件系统链表 */
        struct list_head mnt_instance;  /* sb->s_mounts 上的挂载实例 */
        const char *mnt_devname;        /* 设备名称，例如 /dev/dsk/hda1 */
        struct list_head mnt_list;      // 描述符链表
        struct list_head mnt_expire;    /* 在到期链表的位置 */
        struct list_head mnt_share;     /* 在共享安装链表的位置 */
        struct list_head mnt_slave_list;/* 从安装链表 */
        struct list_head mnt_slave;     /* 在从安装链表的位置 */
        struct mount *mnt_master;       /* 从安装链表的主人 */
        struct mnt_namespace *mnt_ns;   /* 相关的命名空间 */
        struct mountpoint *mnt_mp;      /* 挂载的位置 */
        union {
                struct hlist_node mnt_mp_list;  /* 具有相同挂载点的挂载链表 */
                struct hlist_node mnt_umount;
        };
        struct list_head mnt_umounting; /* 用于卸载传播的列表条目 */
#ifdef CONFIG_FSNOTIFY
        struct fsnotify_mark_connector __rcu *mnt_fsnotify_marks;
        __u32 mnt_fsnotify_mask;
#endif
        int mnt_id;                     /* 安装标识符 */
        int mnt_group_id;               /* 组标识符 */
        int mnt_expiry_mark;            /* 到期时为1 */
        struct hlist_head mnt_pins;
        struct hlist_head mnt_stuck_children;
} __randomize_layout;

struct vfsmount {
        struct dentry *mnt_root;        /* 该文件系统的根目录项 */
        struct super_block *mnt_sb;     /* 超级块 */
        int mnt_flags;                  // 挂载标志, MNT_NOSUID 等
        struct mnt_idmap *mnt_idmap;
} __randomize_layout;
```

`files_struct`描述单个进程相关的信息，`struct task_struct`中的`files`成员指向它。
```c
/*
 * /* 打开的文件表结构 */
 */
struct files_struct {
  /*
   * 主要用于读取的部分
   */
        atomic_t count;             // 引用计数
        bool resize_in_progress;
        wait_queue_head_t resize_wait;

        struct fdtable __rcu *fdt;  // 如果打开的文件数大于NR_OPEN_DEFAULT，分配一个新数组
        struct fdtable fdtab;       // 基fd表
        /*
        * 在 SMP 中，写入部分位于单独的缓存行
        */
        spinlock_t file_lock ____cacheline_aligned_in_smp;  // 单个文件的锁
        unsigned int next_fd;                               // 缓存下一个可用的fd
        unsigned long close_on_exec_init[1];                // exec()时关闭的fd链表
        unsigned long open_fds_init[1];                     // 打开的fd链表
        unsigned long full_fds_bits_init[1];
        struct file __rcu * fd_array[NR_OPEN_DEFAULT];      // 默认的文件对象数组
};
```

`fs_struct`表示文件系统进程相关的信息，`struct task_struct`中的`fs`成员指向它。

```c
struct fs_struct {
        int users;              // 用户数目
        spinlock_t lock;        // 保护该结构体的锁
        seqcount_spinlock_t seq;
        int umask;              // 掩码
        int in_exec;            // 当前正在执行的文件
        struct path root;       // 根目录路径
        struct path pwd;        // 当前工作目录的路径
} __randomize_layout;
```

`mnt_namespace`表示单进程命名空间，`struct task_struct`中的`nsproxy->mnt_namespace`成员指向它。

```c
struct mnt_namespace {
        struct ns_common        ns;
        struct mount *  root; // 根目录的挂载点
        /*
         * 对 .list 的遍历和修改受以下任意一种方式保护：
         * - 获取 namespace_sem 的写锁，或
         * - 获取 namespace_sem 的读锁并获取 .ns_lock
         */
        struct list_head        list; // 挂载点链表
        spinlock_t              ns_lock;
        struct user_namespace   *user_ns;
        struct ucounts          *ucounts; // 用户计数
        u64                     seq;    /* 防止循环的序列号 */
        wait_queue_head_t poll; // 轮询的等待队列
        u64 event; // 事件计数
        unsigned int            mounts; /* 命名空间中的挂载数量 */
        unsigned int            pending_mounts;
} __randomize_layout;

struct ucounts {
        struct hlist_node node;
        struct user_namespace *ns;
        kuid_t uid;
        atomic_t count; // 引用计数
        atomic_long_t ucount[UCOUNT_COUNTS];
        atomic_long_t rlimit[UCOUNT_RLIMIT_COUNTS];
};
```

还有文件锁的数据结构为`struct file_lock`。

## 举几个例子

### `inode`的`i_nlink`

调试补丁为<!-- public begin -->[`0001-debug-vfs.patch`](https://gitee.com/chenxiaosonggitee/blog/blob/master/courses/kernel/src/0001-debug-vfs.patch)<!-- public end --><!-- private begin -->`src/0001-debug-vfs.patch`<!-- private end -->，看其中的`debug_inode_nlink()`函数。

在ext2文件系统下测试：
```sh
fallocate -l 100M image
mkfs.ext2 -F image
mount -t ext2 image /mnt
cd /mnt
echo "i love os" > file
cat file # 这时文件的i_nlink为1，只有一个dentry
ln file link # 创建硬链接i_nlink加1
cat file # 这时文件的i_nlink为2，有两个dentry
ln -s file slink # 创建软链接i_nlink不变
cat file # 这时文件的i_nlink不变还是为2
ls # 这时目录的i_nlink为3
mkdir dir # 只有创建文件夹i_nlink才会增加，创建文件不会
ls # 这时目录的i_nlink为4
```

对文件创建硬链接时`ln file link`，增加`inode->i_nlink`的流程如下：
```c
linkat // 系统调用
  do_linkat
    vfs_link
      ext2_link // ext2_dir_inode_operations的.link方法
        inode_inc_link_count
          inc_nlink
            inode->__i_nlink++
```

不能对目录创建硬链接。在目录`dir1`下创建`dir2`文件夹，父目录`dir1`的`inode->i_nlink`增加的流程如下：
```c
mkdir // 系统调用
  do_mkdirat
    vfs_mkdir
      ext2_mkdir // ext2_dir_inode_operations 的.mkdir方法
        inode_inc_link_count
          inc_nlink
            inode->__i_nlink++
```

### `super_block`的`s_mounts`

调试补丁为<!-- public begin -->[`0001-debug-vfs.patch`](https://gitee.com/chenxiaosonggitee/blog/blob/master/courses/kernel/src/0001-debug-vfs.patch)<!-- public end --><!-- private begin -->`src/0001-debug-vfs.patch`<!-- private end -->，看其中的`debug_sb_mounts()`函数。

每个挂载路径下有3个`struct mount`，分别是一次调用`vfs_create_mount()`和两次调用`clone_mnt()`创建的:
```c
mount
  do_mount
    path_mount
      do_new_mount
        do_new_mount_fc
          vfs_create_mount
            list_add_tail(&mnt->mnt_instance, &mnt->mnt.mnt_sb->s_mounts)
          do_add_mount
            graft_tree
              attach_recursive_mnt
                propagate_mnt
                  propagate_one
                    copy_tree
                      clone_mnt // 调用了两次
                        list_add_tail(&mnt->mnt_instance, &sb->s_mounts)
```

### 通过`inode`得到完整路径

调试补丁为<!-- public begin -->[`0001-debug-vfs.patch`](https://gitee.com/chenxiaosonggitee/blog/blob/master/courses/kernel/src/0001-debug-vfs.patch)<!-- public end --><!-- private begin -->`src/0001-debug-vfs.patch`<!-- private end -->，看其中的`debug_get_full_path()`函数。

# ext2文件系统

英文全称Extended file system，翻译为扩展文件系统。Linux内核最开始用的是minix文件系统，直到1992年4月，Rémy Card开发了ext文件系统，采用Unix文件系统（UFS）的元数据结构，在linux内核0.96c版中引入。设计上参考了BSD的快速文件系统（Fast File System，简称FFS）。1993年1月0.99版本中ext2合入内核，     2001年11月2.4.15版本中ext3合入内核，2006年10月10日2.6.19版本中ext4合入内核。

相关文档网站：

- [内核仓库ext2文档](https://www.kernel.org/doc/html/latest/filesystems/ext2.html)
- [ext4 wiki](https://ext4.wiki.kernel.org/index.php/Main_Page)

## 磁盘数据结构

### 块组

块组（block group）的内容如下:

|  超级块   | 组描<br>述符  | 数据块位图 | inode<br>位图 | inode表 | 数据块 |
|  ----    | ----         | ---     | ---         | ---      | --- |
| 1个块    | k个块         |  1个块 |     1个块       | n个块   | m个块 |

启动扇区和块组：

| 启动块 | 块组0 | 块组1 | ... | 块组n |
| ---   | ---  | ---   | --- | ---  |

对于超级块的存储，ext2的采用了稀疏超级块（sparse superblock）技术，超级块只存储到块组0、块组1和其他ID可以表示为3、5、7的幂的块组中，也就是0、1、3、5、7、9、25、49...

块组中内容的解释：

- 超级块：存储文件系统自身元数据
- 组描述符：包含所有块组的状态
- 数据块位图：每个bit表示对应的数据块是否空闲，1表示占用，0表示空闲
- inode位图：每个bit表示对应的inode是否空闲
- inode表：块组中的inode
- 数据块：文件的有用数据

举个例子，`32GB`的磁盘整个盘格式化为ext2文件系统，块大小为`4KB`，1个块大小的数据块位图描述`8*4K=32K`个数据块，也就是`32K*4KB=128MB`，大约有`32*1024MB/128MB=256`个块组。总块数为`total`，块大小为`bsize`字节，块组的总数约为`total/(8*bsize)`，套到上面的例子，就是`total=32*1024MB/4KB=8192K`，块组的总数约为`8192K/(8*4K)=256`个。`bsize`越小，块组数越大。

### 超级块

```c
struct ext2_super_block {
        __le32  s_inodes_count;         /* 索引节点总数 */
        __le32  s_blocks_count;         /* 块总数 */
        __le32  s_r_blocks_count;       /* 保留的块数 */
        __le32  s_free_blocks_count;    /* 空闲块计数器 */
        __le32  s_free_inodes_count;    /* 空闲索引节点计数器 */
        __le32  s_first_data_block;     /* 第一个数据块的块号，总是为1 */
        // 最小 EXT2_MIN_BLOCK_SIZE，最大 EXT2_MAX_BLOCK_SIZE
        __le32  s_log_block_size;       /* 块大小，对数表示，值为0时表示2^0*1024=1024，值为1时表示2^1*1024=2048,值为2时表示2^2*1024=4096 */
        __le32  s_log_frag_size;        /* 片大小 */
        __le32  s_blocks_per_group;     /* 每组中的块数 */
        __le32  s_frags_per_group;      /* 每组中的片数 */
        __le32  s_inodes_per_group;     /* 每组中的索引节点数 */
        __le32  s_mtime;                /* 最后一次挂载时间 */
        __le32  s_wtime;                /* 写时间 */
        __le16  s_mnt_count;            /* 挂载次数 */
        __le16  s_max_mnt_count;        /* 检查之前挂载操作的次数，挂载次数达到这个值后要进行检查 */
        __le16  s_magic;                /* 幻数，EXT2_SUPER_MAGIC */
        __le16  s_state;                /* 状态标志,挂载时为0，正常卸载为1(EXT2_VALID_FS)，错误为2(EXT2_ERROR_FS) */
        __le16  s_errors;               /* 检测到错误的行为 */
        __le16  s_minor_rev_level;      /* 次版本号 */
        __le32  s_lastcheck;            /* 最后检查的时间 */
        __le32  s_checkinterval;        /* 检查间隔 */
        __le32  s_creator_os;           /* 在什么操作系统上格式化的 */
        __le32  s_rev_level;            /* Revision level，主版本号 */
        __le16  s_def_resuid;           /* 保留块的默认uid */
        __le16  s_def_resgid;           /* 保留块默认gid */
        /*
         * 这些字段仅适用于 EXT2_DYNAMIC_REV 超级块。
         *
         * 注意：兼容功能集和不兼容功能集之间的区别在于，
         * 如果内核不知道不兼容功能集中设置的位，
         * 它应该拒绝挂载文件系统。
         *
         * e2fsck 的要求更加严格；如果它不知道
         * 兼容或不兼容功能集中的某个功能，
         * 它必须中止操作，而不是尝试处理
         * 它不理解的东西...
         */
        __le32  s_first_ino;            /* 第一个非保留的索引节点号 */
        __le16   s_inode_size;          /* 磁盘索引节点大小 */
        __le16  s_block_group_nr;       /* 超级块块组号 */
        __le32  s_feature_compat;       /* 兼容特性，查看 EXT2_FEATURE_COMPAT_DIR_PREALLOC 等宏定义 */
        __le32  s_feature_incompat;     /* 非兼容特性 */
        __le32  s_feature_ro_compat;    /* 只读兼容特性 */
        __u8    s_uuid[16];             /* 卷的 128 位 uuid，文件系统标识符 */
        char    s_volume_name[16];      /* 卷名 */
        char    s_last_mounted[64];     /* 最后挂载点文件夹 */
        __le32  s_algorithm_usage_bitmap; /* 压缩 */
        /*
         * 性能提示。只有在 EXT2_COMPAT_PREALLOC 标志开启时，
         * 才应进行目录预分配。
         */
        __u8    s_prealloc_blocks;      /* 预分配的块数 */
        __u8    s_prealloc_dir_blocks;  /* 为目录预分配的块数 */
        __u16   s_padding1; // 对齐用的
        /*
         * 如果设置了 EXT3_FEATURE_COMPAT_HAS_JOURNAL，则启用日志支持。
         */
        __u8    s_journal_uuid[16];     /* 日志超级块的 uuid */
        __u32   s_journal_inum;         /* 日志文件的 inode 编号 */
        __u32   s_journal_dev;          /* 日志文件的设备编号 */
        __u32   s_last_orphan;          /* 要删除的 inode 列表的起始位置 */
        __u32   s_hash_seed[4];         /* HTREE 哈希种子 */
        __u8    s_def_hash_version;     /* 使用的默认哈希版本 */
        __u8    s_reserved_char_pad;
        __u16   s_reserved_word_pad;
        __le32  s_default_mount_opts;
        __le32  s_first_meta_bg;        /* 第一个元块组 */
        __u32   s_reserved[190];        /* 填充到块的末尾 */
};
```

### 组描述符

```c
struct ext2_group_desc
{
        __le32  bg_block_bitmap;        /* 数据块位图所在的块号 */
        __le32  bg_inode_bitmap;        /* inode位图所在的块号 */
        __le32  bg_inode_table;         /* inode表所在的起始块号 */
        __le16  bg_free_blocks_count;   /* 组中空闲块个数 */
        __le16  bg_free_inodes_count;   /* 组中空闲索引节点数 */
        __le16  bg_used_dirs_count;     /* 组中目录数 */
        __le16  bg_pad;
        __le32  bg_reserved[3];
};
```

### inode表

`struct ext2_group_desc`的`bg_inode_table`表示inode表所在的起始块号，磁盘索引节点固定128字节（可以在gdb中打印`p sizeof(struct ext2_inode)`），1024字节块大小包含8个inode，4096字节块大小包含32个inode。

注意没有索引节点号，因为可以通过计算出来，比如块大小为4096字节，块组中inode位图占用一个块，一个块组的inode个数为4096，索引节点12345在磁盘上的位置可以这样计算`12345/4096=3余57`，所以在第3个块组（从块组0开始算）中索引节点表中的第57个表项。

```c
/*
 * 磁盘索引节点结构
 */
struct ext2_inode {
        __le16  i_mode;         /* 文件类型和访问权限，查看S_ISREG()等函数 */
        __le16  i_uid;          /* 所有者 Uid 的低 16 位，拥有者id */
        // 文件长度，最高位没使用，最大表示2GB文件，大于2GB文件再使用i_dir_acl字段
        __le32  i_size;         /* 大小（字节） */
        __le32  i_atime;        /* 访问时间 */
        __le32  i_ctime;        /* 索引节点创建时间 */
        __le32  i_mtime;        /* 文件数据最后改变时间 */
        __le32  i_dtime;        /* 删除时间 */
        __le16  i_gid;          /* 组 ID 的低 16 位，用户组id */
        __le16  i_links_count;  /* 硬链接计数 */
        __le32  i_blocks;       /* 数据块数，以512字节为单位 */
        __le32  i_flags;        /* 文件标志 */
        union {
                struct {
                        __le32  l_i_reserved1;
                } linux1;
                struct {
                        __le32  h_i_translator;
                } hurd1;
                struct {
                        __le32  m_i_reserved1;
                } masix1;
        } osd1;                         /* OS dependent 1，特定操作系统信息 */
        // i_block 数据块指针，指向15个块，前12个指向数据，第13个一次间接地址，第14个二次间接地址，第15个三次间接地址
        __le32  i_block[EXT2_N_BLOCKS];/* 指向块的指针 */
        __le32  i_generation;   /* 文件版本，给nfs用的 */
        // i_file_acl 访问控制列表，指向一个存放增强属性的块，其他inode如果增强属性一样，可以共享同一个块
        __le32  i_file_acl;     /* 文件访问控制列表（ACL） */
        __le32  i_dir_acl;      /* 目录访问控制列表 */
        __le32  i_faddr;        /* 片地址 */
        union {
                struct {
                        __u8    l_i_frag;       /* 片编号 */
                        __u8    l_i_fsize;      /* 片大小 */
                        __u16   i_pad1;
                        __le16  l_i_uid_high;   /* 以前是reserved2[0]    */
                        __le16  l_i_gid_high;   /* 以前是reserved2[0] */
                        __u32   l_i_reserved2;
                } linux2;
                struct {
                        __u8    h_i_frag;       /* 片编号 */
                        __u8    h_i_fsize;      /* 片大小 */
                        __le16  h_i_mode_high;
                        __le16  h_i_uid_high;
                        __le16  h_i_gid_high;
                        __le32  h_i_author;
                } hurd2;
                struct {
                        __u8    m_i_frag;       /* 片编号 */
                        __u8    m_i_fsize;      /* 片大小 */
                        __u16   m_pad1;
                        __u32   m_i_reserved2[2];
                } masix2;
        } osd2;                         /* 特定文件系统信息 */
};
```

`i_file_acl`指向一个存放增强属性的块，其他inode如果增强属性一样，可以共享同一个块，系统调用`setxattr()`、`lsetxattr()`、`fsetxattr()`设置文件增强属性，`getxattr()`、`lgetxattr()`、`fgetxattr()`返回文件增强属性，`listxattr()`、`llistxattr()`、`flistxattr()`列出文件所有增强属性。这些系统调用是通过       `chacl()`、`setfacl()`、`getfacl()`调用的。没有正式成为POSIX标准。
```c
struct ext2_xattr_entry {
        __u8    e_name_len;     /* 名称长度 */
        __u8    e_name_index;   /* 属性名称索引 */
        __le16  e_value_offs;   /* 值在磁盘块中的偏移量 */
        __le32  e_value_block;  /* 属性存储的磁盘块 (n/i) */
        __le32  e_value_size;   /* 属性值的大小 */
        __le32  e_hash;         /* 名称和值的哈希值 */
        char    e_name[];       /* 属性名称，可变数组/柔性数组/零长度数组 */
};
```

### 各种文件类型的存储

文件类型如下：
```c
#define FT_UNKNOWN      0 // 未知
#define FT_REG_FILE     1 // 常规文件
#define FT_DIR          2 // 目录
#define FT_CHRDEV       3 // 字符设备
#define FT_BLKDEV       4 // 块设备
#define FT_FIFO         5 // 命名管道
#define FT_SOCK         6 // 套接字
#define FT_SYMLINK      7 // 符号链接
                         
#define FT_MAX          8 // 类型总数
```

常规文件刚创建时是空的，不需要数据块，可以用`truncate()`或`open()`系统调用清空，如输入命令`> filename`。

设备文件、管道、套接字所有信息都存放在inode中。

符号链接名小于60个字符就放到`struct ext2_inode`的`i_block`数组中（15个4字节），如果大于60个字符就存到单独数据块中。

最后重点讲一下目录的存储，数据块包含`ext2_dir_entry_2`结构：
```c
/*
 * 目录项的新版本。由于EXT2结构以英特尔字节顺序存储，并且name_len字段永远不可能大于255个字符，因此可以安全地将额外的一个字节重新分配给file_type字段。
 */
struct ext2_dir_entry_2 {
        __le32  inode;                  /* 索引节点号 */
        __le16  rec_len;                /* 目录项长度，总是4的倍数 */
        __u8    name_len;               /* 文件名长度 */
        __u8    file_type;              // 文件类型，struct ext2_dir_entry中没有
        char    name[];                 /* 文件名，最大EXT2_NAME_LEN (255)字节 */
};
```

我们举个例子，刚格式化完ext2，然后创建目录`mkdir dir`，创建文件`touch file`、创建软链接`ln -s file link`。
```sh
                      file_type--+
                                 |
                    name_len--+  |
                              |  |
  address     inode   rec_len |  |   name
          +--+--+--+--|--+--|--|--|--+--+--+--+
        0 |      2    |  12 | 1| 2| . \0 \0 \0|
          +--+--+--+--|--+--|--|--|--+--+--+--+
       12 |      2    |  12 | 2| 2| .  . \0 \0|
          +--+--+--+--|--+--|--|--|--+--+--+--+--+--+--+--+--+--+--+--+
       24 |      11   |  20 |10| 2| l  o  s  t  +  f  o  u  n  d \0 \0|
          +--+--+--+--|--+--|--|--|--+--+--+--+--+--+--+--+--+--+--+--+
       44 |    15809  |  12 | 3| 2| d  i  r \0|
          +--+--+--+--|--+--|--|--|--+--+--+--+
       56 |      12   |  12 | 4| 1| f  i  l  e|
          +--+--+--+--|--+--|--|--|--+--+--+--+
       68 |      13   |  12 | 4| 7| l  i  n  k|
          +--+--+--+--|--+--|--|--|--+--+--+--+
```

如果删除`dir`，就会变成以下样子，删除的目录`inode`改为`0`，然后前一项的`rec_len`加上`12`。
```sh
                      file_type--+
                                 |
                    name_len--+  |
                              |  |
  address     inode   rec_len |  |   name
          +--+--+--+--|--+--|--|--|--+--+--+--+
        0 |      2    |  12 | 1| 2| . \0 \0 \0|
          +--+--+--+--|--+--|--|--|--+--+--+--+
       12 |      2    |  12 | 2| 2| .  . \0 \0|
          +--+--+--+--|--+--|--|--|--+--+--+--+--+--+--+--+--+--+--+--+
       24 |      11   |  32 |10| 2| l  o  s  t  +  f  o  u  n  d \0 \0|
          +--+--+--+--|--+--|--|--|--+--+--+--+--+--+--+--+--+--+--+--+
       44 |      0    |  12 | 3| 2| d  i  r \0|
          +--+--+--+--|--+--|--|--|--+--+--+--+
       56 |      12   |  12 | 4| 1| f  i  l  e|
          +--+--+--+--|--+--|--|--|--+--+--+--+
       68 |      13   |  12 | 4| 7| l  i  n  k|
          +--+--+--+--|--+--|--|--|--+--+--+--+
```

## 内存数据结构

磁盘和内存数据结构的关系如下，动态缓存指文件关闭或数据块被删除后页框回收算法从高速缓存中删除数据：

- 超级块：磁盘`ext2_super_block`，内存`ext2_sb_info`，总是缓存
- 组描述符：磁盘和内存都是`ext2_group_desc`，总是缓存
- 块位图和inode位图：磁盘是块中的位数组，内存是缓冲区中的位数组，动态缓存
- 索引节点：磁盘`ext2_inode`，内存`ext2_inode_info`，动态缓存，空闲索引节点从不缓存
- 数据块：磁盘是字节数组，内存是VFS缓冲区，动态缓存，空闲块从不缓存

### 超级块

VFS的`struct super_block`中的`s_fs_info`指向`struct ext2_sb_info`类型的结构：
```c
/*
 * 第二扩展文件系统的内存中超级块数据 */
 */
struct ext2_sb_info {
        unsigned long s_inodes_per_block;/* 每个块的 inode 数量 */
        unsigned long s_blocks_per_group;/* 每组中的块数 */
        unsigned long s_inodes_per_group;/* 每组中的 inode 数量 */
        unsigned long s_itb_per_group;  /* 每组的 inode 表块数 */
        unsigned long s_gdb_count;      /* 组描述符块的数量 */
        // 组描述符的个数，可以放在一个块中
        unsigned long s_desc_per_block; /* 每个块的组描述符数量 */
        unsigned long s_groups_count;   /* 文件系统中的组数 */
        unsigned long s_overhead_last;  /* 最近一次计算的开销 */
        unsigned long s_blocks_last;    /* 最近一次看到的块数 */
        // 包含磁盘超级块的缓冲区的缓冲区头
        struct buffer_head * s_sbh;     /* 包含超级块的缓冲区 */
        // 指向磁盘超级块所在的缓冲区
        struct ext2_super_block * s_es; /* 指向缓冲区中超级块的指针 */
        // 指向一个缓冲区（包含组描述符的缓冲区）首部数组
        struct buffer_head ** s_group_desc;
        unsigned long  s_mount_opt;
        unsigned long s_sb_block;
        kuid_t s_resuid;
        kgid_t s_resgid;
        unsigned short s_mount_state;
        unsigned short s_pad;
        int s_addr_per_block_bits;
        int s_desc_per_block_bits;
        int s_inode_size;
        int s_first_ino;
        spinlock_t s_next_gen_lock;
        u32 s_next_generation;
        unsigned long s_dir_count;
        u8 *s_debts;
        struct percpu_counter s_freeblocks_counter;
        struct percpu_counter s_freeinodes_counter;
        struct percpu_counter s_dirs_counter;
        struct blockgroup_lock *s_blockgroup_lock;
        /* 每个文件系统预留窗口树的根 */
        spinlock_t s_rsv_window_lock;
        struct rb_root s_rsv_window_root; // ext2_reserve_window_node的所有实例
        struct ext2_reserve_window_node s_rsv_window_head;
        /*
         * s_lock 保护 s_mount_state、s_blocks_last、s_overhead_last 和由 sbi->s_es 指向的
         * 超级块缓冲区内容的并发修改。
         *
         * 注意: 在 ext2_show_options() 中使用它来提供挂载选项的一致视图。
         */
        spinlock_t s_lock;
        struct mb_cache *s_ea_block_cache;
        struct dax_device *s_daxdev;
        u64 s_dax_part_off;
};
```

各个数据结构之间的关系如下图：
```sh
                                   ext2 partition
                                       +-------+----------+----------+----------+
                                       | super |group     |group     |group     |
                                       | block |descriptor|descriptor|descriptor|
                                       +-------+----------+----------+----------+
                                           ^         ^          ^            ^
                                           |         |          |            |
                                           |         +------+   +--------+   +----------+
                                           |                |            |              |
                                     +-----------+     +-----------+ +-----------+ +-----------+
 +---------------------+             |  buffer   |     |  buffer   | |  buffer   | |  buffer   |
 |   super_block       |        +--->+-----------+     +-----------+ +-----------+ +-----------+
 |                     |        |         ^                 ^             ^             ^
 |   .s_fs_info        |        |         |b_data           |b_data       |b_data       |b_data
 | +--------------+----|--s_es--+         |                 |             |             |  
 | | ext2_sb_info |----|----s_sbh--->+-----------+    +-----------------------------------------+
 | +--------------+    |             |buffer_head|    |+-----------+ +-----------+ +-----------+|
 |           |         |             +-----------+    ||buffer_head| |buffer_head| |buffer_head||
 +---------------------+                              |+-----------+ +-----------+ +-----------+|
             |                                        +-----------------------------------------+
          s_group_desc                                              ^
             |                                                      |
             +------------------------------------------------------+
```

挂载时`struct file_system_type ext2_fs_type`的`ext2_mount()`方法再执行到`ext2_fill_super()`从磁盘读取超级块。

ext2超级块的操作实现是`struct super_operations ext2_sops`。

### 索引节点

```c
/*
 * 第二扩展文件系统在内存中的 inode 数据
 */
struct ext2_inode_info {
        __le32  i_data[15];
        __u32   i_flags;
        __u32   i_faddr;
        __u8    i_frag_no;
        __u8    i_frag_size;
        __u16   i_state;
        __u32   i_file_acl;
        __u32   i_dir_acl;
        __u32   i_dtime;

        /*
         * i_block_group 是包含此文件 inode 的块组的编号。
         * 在 inode 的整个生命周期中保持不变，它用于进行块分配决策 - 
         * 我们试图将文件的数据块放置在其 inode 块附近，并将新的 inode 放置在其父目录的 inode 附近。
         */
        __u32   i_block_group;

        /* 块预读 */
        struct ext2_block_alloc_info *i_block_alloc_info;

        __u32   i_dir_start_lookup;
#ifdef CONFIG_EXT2_FS_XATTR
        /*
         * 扩展属性可以独立于主文件数据进行读取。即使在读取时也获取 i_mutex 会导致扩展属性的读取者和常规文件数据的写入者之间产生竞争，
         * 因此我们在读取或更改扩展属性时，会改为在 xattr_sem 上进行同步。
         */
        struct rw_semaphore xattr_sem;
#endif
        rwlock_t i_meta_lock;

        /*
         * truncate_mutex 用于将 ext2_truncate() 与 ext2_getblock() 串行化。
         * 它还保护 inode 的预留数据结构的内部: ext2_reserve_window 和
         * ext2_reserve_window_node。
         */
        struct mutex truncate_mutex;
        struct inode    vfs_inode;      // 虚拟文件系统的索引节点
        struct list_head i_orphan;      /* 已解除链接但仍打开的 inodes */
#ifdef CONFIG_QUOTA
        struct dquot *i_dquot[MAXQUOTAS];
#endif
};

struct ext2_block_alloc_info {                                                   
        /* 预留窗口信息 */                               
        struct ext2_reserve_window_node rsv_window_node;                         
        /*                                                                       
         * 是曾经 ext2_inode_info 结构中的 i_next_alloc_block 
         * 是文件中最近分配的块的逻辑（文件相对）编号。
         * 我们用这个来检测线性递增的分配请求。
         */                                                                      
        __u32                   last_alloc_logical_block;                        
        /*                                                                       
         * 曾是 ext2_inode_info 结构中的 i_next_alloc_goal                              
         * 是 i_next_alloc_block 的物理对应项。它是最近分配给该文件的块的物理块编号。
         * 当我们检测到线性递增的请求时，这为我们提供了下一次分配的目标。
         */                                                                      
        ext2_fsblk_t            last_alloc_physical_block;                       
};

struct ext2_reserve_window_node {                       
        struct rb_node          rsv_node;               
        __u32                   rsv_goal_size;      // 预留窗口的预期长度, 最大为 EXT2_MAX_RESERVE_BLOCKS
        __u32                   rsv_alloc_hit;      // 预分配的命中数
        struct ext2_reserve_window      rsv_window; // 预留窗口
};                                                      

```

由`struct super_operations ext2_sops`的`ext2_alloc_inode()`分配索引节点对象。

ext2索引节点操作实现:

- 常规文件: `struct inode_operations ext2_file_inode_operations`
- 目录: `struct inode_operations ext2_dir_inode_operations`
- 快速符号链接（路径名小于60字节）: `struct inode_operations ext2_fast_symlink_inode_operations`
- 普通符号链接（路径名大于60字节）: `struct inode_operations ext2_symlink_inode_operations`

`ext2_inode_info->vfs_inode->i_mapping->a_ops`的实现是`ext2_aops`和`ext2_dax_aops`（DAX，Direct Access，允许文件系统直接访问持久性内存（如非易失性内存，NVDIMM）上的数据，而无需经过缓存。这可以显著提高I/O性能，特别是在读取和写入小文件时）。

## 管理磁盘空间

创建索引节点 `ext2_new_inode()`，删除索引节点 `ext2_free_inode()`。

当块大小为`1024`字节时，命令`echo -n something | dd of=file bs=1 seek=4098`创建一个有“洞”的文件，索引节点的`i_size`值为`4099`，但`i_blocks`的值为2，因为只占用1个块，1个块`1024`字节，以`512`为单位的`i_blocks`的值为2。`i_block[]`数组前4个元素值为0，第五个元素存放块号。

分配数据块调用`ext2_get_block() -> ext2_alloc_blocks() -> ext2_new_blocks()`，释放数据块调用`ext2_free_blocks()`。

再讲一下数据块寻址，`inode`的`i_block[]`数组默认有15个元素，每个元素4字节，前12个直接指向存放数据的逻辑块（对应的文件块号是`0~11`）。第13个元素指向的是间接块，这个间接块上存了一个`bsize/4`个元素的数组（其中`bsize`表示块大小），对应的文件块号为`12~(11+bsize/4)`。第14个元素指向二级间接块，第15个元素指向三级间接块。

ext2不经过页缓存直接写调用`ext2_file_write_iter() -> ext2_dio_write_iter()`, 经过缓存写调用`ext2_file_write_iter() -> generic_file_write_iter()`。

## 调试ext2磁盘布局

<!-- 格式化 `superfortat` `fdformat` -->

`mkfs.ext2 /dev/sda`相当于`mke2fs -t 2 -b 1024 -m 5`，块大小默认`1024`字节，保留块百分比默认`5%`，每`8192`字节设置一个索引节点，`lost+found`目录放丢失和找到的缺陷块。

我们举个例子，一个比较小的磁盘（也可以打开内核配置`CONFIG_BLK_DEV_LOOP`然后对文件执行同样的操作），执行完以下命令：
<!--
```sh
# od选项：以十六进制格式，每行输出一个字节，并且每个字节都输出其地址，具体查看命令 man 1 od
# dd if=/dev/sda bs=1K count=2048 | od -tx1 -Ax > image # 也可以试试 debugfs
```
-->
```sh
mkfs.ext2 -F /dev/sda # 8412KB大小
dd if=/dev/sda of=image bs=1K count=8412
vim image # 然后输入 :%!xxd，当然也可以使用其他编辑器打开查看二进制数据
```

其中执行`mkfs.ext2`输出以下日志：
```sh
mke2fs 1.46.2 (28-Feb-2021)
Discarding device blocks: done                            
Creating filesystem with 8412 1k blocks and 2112 inodes
Filesystem UUID: 13b5577a-898c-40e5-a9e6-c0a0dd2b8ab6
Superblock backups stored on blocks: 
        8193

Allocating group tables: done                            
Writing inode tables: done                            
Writing superblocks and filesystem accounting information: done
```

通过`debugfs image`，然后输入`stats`查看到有2个块组（如果磁盘大小减小成`8411KB`，则只用1个块组）：
```sh
Filesystem volume name:   <none>
Last mounted on:          <not available>
Filesystem UUID:          13b5577a-898c-40e5-a9e6-c0a0dd2b8ab6
Filesystem magic number:  0xEF53
Filesystem revision #:    1 (dynamic)
Filesystem features:      ext_attr resize_inode dir_index filetype sparse_super large_file
Filesystem flags:         signed_directory_hash 
Default mount options:    user_xattr acl
Filesystem state:         clean
Errors behavior:          Continue
Filesystem OS type:       Linux
Inode count:              2112
Block count:              8412
Reserved block count:     420
Overhead clusters:        337
Free blocks:              8061
Free inodes:              2101
First block:              1
Block size:               1024
Fragment size:            1024
Reserved GDT blocks:      32
Blocks per group:         8192
Fragments per group:      8192
Inodes per group:         1056
Inode blocks per group:   132
Filesystem created:       Thu May 23 12:50:34 2024
Last mount time:          n/a
Last write time:          Thu May 23 12:50:34 2024
Mount count:              0
Maximum mount count:      -1
Last checked:             Thu May 23 12:50:34 2024
Check interval:           0 (<none>)
Reserved blocks uid:      0 (user root)
Reserved blocks gid:      0 (group root)
First inode:              11
Inode size:               128
Default directory hash:   half_md4
Directory Hash Seed:      2ac788a5-17e7-49f1-9b94-4ca6c9397d55
Directories:              2
 Group  0: block bitmap at 35, inode bitmap at 36, inode table at 37
           8010 free blocks, 1045 free inodes, 2 used directories
 Group  1: block bitmap at 8227, inode bitmap at 8228, inode table at 8229
           51 free blocks, 1056 free inodes, 0 used directories
```

默认1个块大小`1024(0x400)`字节，每个块的内容如下：

- 第0个块: `0~0x400`为引导块（启动块）
- 第1个块: `0x400~0x800`为超级块（`gdb`打印`p sizeof(struct ext2_super_block)`的值为`1024`），超级块固定1个块
  - `0x400`地址为`s_inodes_count`成员，值为`0x840(2112)`，注意是小端模式存储的
  - `0x438`地址的值为`EXT2_SUPER_MAGIC`，是`s_magic`成员的值，偏移量可以用`gdb`命令`p &((struct ext2_super_block *)0)->s_magic`查看
  - 其他字段的值请自行实践查看
- 第2个块: `0x800~0xc00`，两个块组描述符，一个块组描述符`32`字节，每个块组中含有全部块组的块组描述符，如果超过`32`个块组（`32*32=1024`），组描述符就不只一个块。和超级块一样，块组描述符也是只存储到块组0、1、3、5、7、9、25、49...
  - 第一个`ext2_group_desc`，`bg_block_bitmap`的值为`35(0x23)`
- 第35个块: `0x8c00~0x9000`为数据块位图
- 第36个块: `0x9000~0x9400`为索引节点位图
- 第37~164个块: `0x9400~0x29400`为inode表，inode表占`128`个块（`1024`个`inode`）
  - `0x9900`为`lost+found`文件的`ext2_inode`，`0x9928`为`i_block[]`（值为`0xaa`），数据块的地址为`0xaa*1024=0x2a800`，也就是`.`和`..`两个隐藏的文件夹

## 工具软件

<!-- `defrag.ext2` `dumpesfs` -->
<!-- https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/8/html/managing_file_systems/comparison-of-tools-used-with-ext4-and-xfs_getting-started-with-an-ext4-file-system -->

最后再介绍几个ext文件系统相关的用户态工具：

- `mke2fs`: 用于建立ext2文件系统，ext2文件系统直接使用`mkfs.ext2`（相当于`mke2fs -t 2`），ext4直接使用`mkfs.ext4`。具体用法查看`man 8 mke2fs`。
- `e2fsck`: 用于检查使用 ext2 文件系统的 partition 是否正常工作，对于ext2文件系统可以直接使用`fsck.ext2`命令，ext4直接使用`fsck.ext4`。具体用法查看`man 8 e2fsck`。
- `debugfs`: ext2/ext3/ext4文件系统调试器，具体用法查看`man 8 debugfs`。
- `dumpe2fs`: 显示ext2、ext3、ext4文件系统的超级快和块组信息，具体用法查看`man 8 dumpe2fs`。
- `tune2fs`: 用于管理文件系统参数，具体用法查看`man 8 tune2fs`。
- `e2image`: 将关键的 ext2/ext3/ext4 文件系统元数据保存到文件中，具体用法查看`man 8 e2image`。
  - `e2image device image-file`: 保存元数据，查看超级快和块组信息使用`debugfs -i image-file`和`dumpe2fs -i image-file`。
  - `e2image -I device image-file`: 恢复。
- `dump`: 备份ext2/3/4文件系统，安装`apt install dump -y`。

## 开发一个新文件系统的步骤

以ext2为例，说明开发一个新文件系统所需的步骤，也可以作为学习一个文件系统的方法步骤。

1. 定义超级块结构。
  - 磁盘超级块结构`struct ext2_super_block`，在`struct file_system_type ext2_fs_type`的`.mount`实现`ext2_mount()`里调用到的`ext2_fill_super()`中找。
  - 内存超级块结构`struct ext2_sb_info`，赋值给`struct super_block`的`s_fs_info`成员。
2. 实现超级块操作方法`ext2_sops`。
3. 定义索引节点结构。
  - 磁盘索引节点结构`struct ext2_inode`，在超级块操作方法`ext2_sops`的`.write_inode`实现函数中找。
  - 内存索引节点结构`struct ext2_inode_info`，内嵌`struct inode`，在超级块操作方法`ext2_sops`的很多函数都可以找到。
4. 实现各种类型文件的索引节点操作方法:
  - 常规文件`ext2_file_inode_operations`。
  - 目录`ext2_dir_inode_operations`。
  - 快速符号链接（路径名小于60字节）`ext2_fast_symlink_inode_operations`。
  - 普通符号链接（路径名大于60字节）`ext2_symlink_inode_operations`。
  - 其他`ext2_special_inode_operations`。
5. 实现`dentry`操作方法，ext和xfs等文件系统都没定义，nfs为`nfs_dentry_operations`和`nfs4_dentry_operations`，smb client为`cifs_dentry_ops`和`cifs_ci_dentry_ops`。
6. 实现各种类型文件的`file`操作方法:
  - 常规文件`ext2_file_operations`。
  - 目录`ext2_dir_operations`。
  - 其他类型查看`init_special_inode()`函数。
7. 实现各种类型文件的`address_space`操作方法：
  - 常规文件`ext2_aops`和`ext2_dax_aops`。
  - 目录，ext2没定义目录相关的操作，nfs为`nfs_dir_aops`。
  - 其他类型，如块设备`def_blk_aops`。
8. 定义文件系统类型`ext2_fs_type`。
9. 模块加载卸载方法，`init_ext2_fs`和`exit_ext2_fs`。

<!-- ing begin -->
# ext4文件系统

## jbd2

ext2不是日志（journal）文件系统，文件系统的状态存放在`struct ext2_super_block`结构体的`s_state`字段中，如果不等于`EXT2_VALID_FS`，说明没有正常卸载，`e2fsck`要检查所有磁盘数据结构，文件数和目录数很多、或者磁盘很大，一致性检查要花费非常久的时间。

ext4是日志文件系统，对文件系统的高级修改分两步：

- 把待写块的副本存放在journal中。
- 当发往journal的I/O数据传送完成时（数据提交到日志），块就被写入fs。

当发往fs的I/O数据传送终止时（把数据提交给fs），日志的块副本被丢弃。

`e2fsck`检查时，有两种情况：

- 提交到日志之前系统故障发生。高级修改的块副本要么从日志中丢失，要么是不完整的，忽略。
- 提交到日志之后系统故障发生。块的副本有效，`e2fsck`写入fs。

注意，日志功能只能保证系统调用级别的一致性。

ext文件系统有6种元数据：超级块，块组描述符，索引节点，间接块，数据块位图块，索引节点位图块。

有3种不同的日志模式：

- journal: 所有数据和元数据的改变都被记入日志，最安全最慢。
- ordered: 只有元数据的改变才被记入日志，数据在元数据之前写入磁盘，默认的日志模式。
- writeback: 只有元数据的改变才被记入日志，不保证数据在元数据之前写入磁盘，速度最快。

ext4本身不处理日志，而是利用日志块设备（journal block device, JBD2）。ext4和jbd2之间的交互基于3个基本单元：

- 日志记录: 描述一个磁盘块的一次更新。由低级操作所修改的整个`buffer`组成，直接操作`buffer`和`buffer_head`，在日志内部表现为普通的数据块或元数据。
- 原子操作处理: 一次高级修改对应的日志记录，修改文件系统的每个系统调用都引起一次单独的原子操作处理。
- 事务: 包括几个原子操作处理。
<!-- ing end -->
