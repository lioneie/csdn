我们通过开发一个新操作系统需要的步骤，来切入学习smb client。

1. 定义磁盘和内存的超级块结构。
2. 实现超级块操作方法。
3. 定义磁盘和内存的索引节点结构。
4. 实现各种类型文件的索引节点操作方法，常规文件、目录、快速符号链接、普通符号链接、其他类型。
5. 实现`dentry`操作方法。
6. 实现各种类型文件的`file`操作方法，常规文件、目录、快速符号链接、普通符号链接、其他类型。
7. 实现各种类型文件的`address_space`操作方法，常规文件、其他类型。
8. 定义文件系统类型。
9. 模块加载卸载方法。

注意，我只会列出结构体的代码，会在结构的成员加些中文注释（也可能以后再加），不会贴整段的函数代码，因为函数的实现要自己去看，看具体问题时再看函数实现才有意义。

# 超级块

由于smb client没有磁盘超级块，所以只有内存超级块结构体，在`cifs_set_super()`函数中赋值`sb->s_fs_info = mnt_data->cifs_sb`。

```c
struct cifs_sb_info {                                                
        struct rb_root tlink_tree;               // tlink 树
        spinlock_t tlink_tree_lock;              // tlink 树锁
        struct tcon_link *master_tlink;          // 主 tlink
        struct nls_table *local_nls;             // 本地 nls 表
        struct smb3_fs_context *ctx;             // smb3 文件系统上下文
        atomic_t active;                         // 活跃计数
        unsigned int mnt_cifs_flags;             // 挂载标志
        struct delayed_work prune_tlinks;        // 延迟清理 tlinks
        struct rcu_head rcu;                     // RCU 头
                                                                     
        /* 只有当 CIFS_MOUNT_USE_PREFIX_PATH 被设置时使用 */       
        char *prepath;                           // 预路径
                                                                     
        /*                                                           
         * 指示是否在以后关闭了 serverino 选项
         * (cifs_autodisable_serverino) 以匹配新挂载点。
         */                                                          
        bool mnt_cifs_serverino_autodisabled;    // serverino 自动禁用标志
        /*                                                           
         * 挂载完成后可用。                   
         */                                                          
        struct dentry *root;                     // 根目录 dentry
}; 
```

# 超级块操作

```c
static const struct super_operations cifs_super_ops = {                         
        .statfs = cifs_statfs,                                                  
        .alloc_inode = cifs_alloc_inode,                                        
        .write_inode    = cifs_write_inode,                                     
        .free_inode = cifs_free_inode,                                          
        .drop_inode     = cifs_drop_inode,                                      
        .evict_inode    = cifs_evict_inode,  
/*      .show_path      = cifs_show_path, */ /* 我们是否需要显示路径？ */
        .show_devname   = cifs_show_devname,                                    
/*      .delete_inode   = cifs_delete_inode,  */  /* 除非以后我们添加惰性关闭
        索引节点的功能，或者内核忘记在关闭时调用我们与打开次数相同的
        释放次数，否则不需要上述函数 */
        .show_options = cifs_show_options,                                      
        .umount_begin   = cifs_umount_begin,                                    
        .freeze_fs      = cifs_freeze,                                          
#ifdef CONFIG_CIFS_STATS2                                                       
        .show_stats = cifs_show_stats,                                          
#endif                                                                          
};                                                                              
```

# 索引节点

smb没有磁盘索引节点，只有内存索引节点。

```c
/*                                 
 * 每个文件 inode 的结构体
 */                                
struct cifsInodeInfo {                                                                          
        struct netfs_inode netfs;       /* Netfslib 上下文和 vfs inode */                          
        bool can_cache_brlcks;          // 是否可以缓存字节范围锁
        struct list_head llist;         /* 该 inode 持有的锁列表 */                                  
        /*                                                                                      
         * 注意: 有些代码路径会两次调用 down_read(lock_sem)，所以                             
         * 我们必须始终使用 cifs_down_write() 而不是 down_write()                         
         * 来避免此信号量的死锁。                                               
         */                                                                                     
        struct rw_semaphore lock_sem;   /* 保护上面的字段 */                          
        /* BB 添加用于脏页列表，即 oplock 的写缓存信息 */                
        struct list_head openFileList;  // 打开文件列表
        spinlock_t      open_file_lock; /* 保护 openFileList */                             
        __u32 cifsAttrs;                /* 例如 DOS 归档位、稀疏、压缩、系统等属性 */                 
        unsigned int oplock;            /* 我们拥有的 oplock/lease 级别 */                        
        unsigned int epoch;             /* 用于跟踪租约状态变化 */                 
#define CIFS_INODE_PENDING_OPLOCK_BREAK   (0) /* 正在进行 oplock 断裂 */                    
#define CIFS_INODE_PENDING_WRITERS        (1) /* 正在进行写操作 */                          
#define CIFS_INODE_FLAG_UNUSED            (2) /* 未使用的标志 */                                 
#define CIFS_INO_DELETE_PENDING           (3) /* 服务器上待删除 */                    
#define CIFS_INO_INVALID_MAPPING          (4) /* pagecache 无效 */                        
#define CIFS_INO_LOCK                     (5) /* 同步锁位 */                
#define CIFS_INO_MODIFIED_ATTR            (6) /* 指示 mtime/ctime 的变化 */              
#define CIFS_INO_CLOSE_ON_LOCK            (7) /* 不要在设置锁时延迟关闭 */     
        unsigned long flags;             // 标志字段
        spinlock_t writers_lock;          // 写入锁
        unsigned int writers;             /* 此 inode 的写入者数量 */                   
        unsigned long time;               /* inode 最后更新的 jiffies */                   
        u64  server_eof;                  /* 服务器上的当前文件大小 - 由 i_lock 保护 */
        u64  uniqueid;                    /* 服务器 inode 编号 */                               
        u64  createtime;                  /* 服务器上的创建时间 */                           
        __u8 lease_key[SMB2_LEASE_KEY_SIZE];    /* 此 inode 的租约密钥 */                  
        struct list_head deferred_closes; /* 延迟关闭列表 */                         
        spinlock_t deferred_lock;         /* 保护延迟列表 */                             
        bool lease_granted;               /* 标志指示是否授予租约或 oplock。 */          
        char *symlink_target;             // 符号链接目标
}; 
```

# 索引节点操作

## 常规文件

```c
const struct inode_operations cifs_file_inode_ops = {
        .setattr = cifs_setattr,                     
        .getattr = cifs_getattr,                     
        .permission = cifs_permission,               
        .listxattr = cifs_listxattr,                 
        .fiemap = cifs_fiemap,                       
        .get_acl = cifs_get_acl,                     
        .set_acl = cifs_set_acl,                     
};                                                   
```

## 目录

```c
const struct inode_operations cifs_dir_inode_ops = {
        .create = cifs_create,                      
        .atomic_open = cifs_atomic_open,            
        .lookup = cifs_lookup,                      
        .getattr = cifs_getattr,                    
        .unlink = cifs_unlink,                      
        .link = cifs_hardlink,                      
        .mkdir = cifs_mkdir,                        
        .rmdir = cifs_rmdir,                        
        .rename = cifs_rename2,                     
        .permission = cifs_permission,              
        .setattr = cifs_setattr,                    
        .symlink = cifs_symlink,                    
        .mknod   = cifs_mknod,                      
        .listxattr = cifs_listxattr,                
        .get_acl = cifs_get_acl,                    
        .set_acl = cifs_set_acl,                    
};                                                  
```

## 符号链接

```c
const struct inode_operations cifs_symlink_inode_ops = {
        .get_link = cifs_get_link,                      
        .permission = cifs_permission,                  
        .listxattr = cifs_listxattr,                    
};                                                      
```

## 其他

```c
static const struct inode_operations cifs_ipc_inode_ops = {
        .lookup = cifs_lookup,                             
};                                                         

const struct inode_operations cifs_namespace_inode_operations = {
};                                                               
```

# `dentry`操作

```c
const struct dentry_operations cifs_dentry_ops = {                             
        .d_revalidate = cifs_d_revalidate,                                     
        .d_automount = cifs_d_automount,                                       
/* d_delete:       cifs_d_delete,      */ /* 除了调试之外不需要 */
};                                                                             

const struct dentry_operations cifs_ci_dentry_ops = {
        .d_revalidate = cifs_d_revalidate,           
        .d_hash = cifs_ci_hash,                      
        .d_compare = cifs_ci_compare,                
        .d_automount = cifs_d_automount,             
};                                                   
```

# `file`操作

## 常规文件

```c
const struct file_operations cifs_file_ops = {    
        .read_iter = cifs_loose_read_iter,        
        .write_iter = cifs_file_write_iter,       
        .open = cifs_open,                        
        .release = cifs_close,                    
        .lock = cifs_lock,                        
        .flock = cifs_flock,                      
        .fsync = cifs_fsync,                      
        .flush = cifs_flush,                      
        .mmap  = cifs_file_mmap,                  
        .splice_read = filemap_splice_read,       
        .splice_write = iter_file_splice_write,   
        .llseek = cifs_llseek,                    
        .unlocked_ioctl = cifs_ioctl,             
        .copy_file_range = cifs_copy_file_range,  
        .remap_file_range = cifs_remap_file_range,
        .setlease = cifs_setlease,                
        .fallocate = cifs_fallocate,              
};                                                

const struct file_operations cifs_file_strict_ops = {
        .read_iter = cifs_strict_readv,              
        .write_iter = cifs_strict_writev,            
        .open = cifs_open,                           
        .release = cifs_close,                       
        .lock = cifs_lock,                           
        .flock = cifs_flock,                         
        .fsync = cifs_strict_fsync,                  
        .flush = cifs_flush,                         
        .mmap = cifs_file_strict_mmap,               
        .splice_read = filemap_splice_read,          
        .splice_write = iter_file_splice_write,      
        .llseek = cifs_llseek,                       
        .unlocked_ioctl = cifs_ioctl,                
        .copy_file_range = cifs_copy_file_range,     
        .remap_file_range = cifs_remap_file_range,   
        .setlease = cifs_setlease,                   
        .fallocate = cifs_fallocate,                 
};                                                   

const struct file_operations cifs_file_direct_ops = {
        .read_iter = cifs_direct_readv,              
        .write_iter = cifs_direct_writev,            
        .open = cifs_open,                           
        .release = cifs_close,                       
        .lock = cifs_lock,                           
        .flock = cifs_flock,                         
        .fsync = cifs_fsync,                         
        .flush = cifs_flush,                         
        .mmap = cifs_file_mmap,                      
        .splice_read = copy_splice_read,             
        .splice_write = iter_file_splice_write,      
        .unlocked_ioctl  = cifs_ioctl,               
        .copy_file_range = cifs_copy_file_range,     
        .remap_file_range = cifs_remap_file_range,   
        .llseek = cifs_llseek,                       
        .setlease = cifs_setlease,                   
        .fallocate = cifs_fallocate,                 
};                                                   

const struct file_operations cifs_file_nobrl_ops = { 
        .read_iter = cifs_loose_read_iter,           
        .write_iter = cifs_file_write_iter,          
        .open = cifs_open,                           
        .release = cifs_close,                       
        .fsync = cifs_fsync,                         
        .flush = cifs_flush,                         
        .mmap  = cifs_file_mmap,                     
        .splice_read = filemap_splice_read,          
        .splice_write = iter_file_splice_write,      
        .llseek = cifs_llseek,                       
        .unlocked_ioctl = cifs_ioctl,                
        .copy_file_range = cifs_copy_file_range,     
        .remap_file_range = cifs_remap_file_range,   
        .setlease = cifs_setlease,                   
        .fallocate = cifs_fallocate,                 
};                                                   

const struct file_operations cifs_file_strict_nobrl_ops = {
        .read_iter = cifs_strict_readv,                    
        .write_iter = cifs_strict_writev,                  
        .open = cifs_open,                                 
        .release = cifs_close,                             
        .fsync = cifs_strict_fsync,                        
        .flush = cifs_flush,                               
        .mmap = cifs_file_strict_mmap,                     
        .splice_read = filemap_splice_read,                
        .splice_write = iter_file_splice_write,            
        .llseek = cifs_llseek,                             
        .unlocked_ioctl = cifs_ioctl,                      
        .copy_file_range = cifs_copy_file_range,           
        .remap_file_range = cifs_remap_file_range,         
        .setlease = cifs_setlease,                         
        .fallocate = cifs_fallocate,                       
};                                                         

const struct file_operations cifs_file_direct_nobrl_ops = { 
        .read_iter = cifs_direct_readv,                     
        .write_iter = cifs_direct_writev,                   
        .open = cifs_open,                                  
        .release = cifs_close,                              
        .fsync = cifs_fsync,                                
        .flush = cifs_flush,                                
        .mmap = cifs_file_mmap,                             
        .splice_read = copy_splice_read,                    
        .splice_write = iter_file_splice_write,             
        .unlocked_ioctl  = cifs_ioctl,                      
        .copy_file_range = cifs_copy_file_range,            
        .remap_file_range = cifs_remap_file_range,          
        .llseek = cifs_llseek,                              
        .setlease = cifs_setlease,                          
        .fallocate = cifs_fallocate,                        
};                                                          
```

## 目录

```c
const struct file_operations cifs_dir_ops = {     
        .iterate_shared = cifs_readdir,           
        .release = cifs_closedir,                 
        .read    = generic_read_dir,              
        .unlocked_ioctl  = cifs_ioctl,            
        .copy_file_range = cifs_copy_file_range,  
        .remap_file_range = cifs_remap_file_range,
        .llseek = generic_file_llseek,            
        .fsync = cifs_dir_fsync,                  
};                                                
```

# `address_space`操作

## 常规文件

```c
const struct address_space_operations cifs_addr_ops = {                      
        .read_folio = cifs_read_folio,                                       
        .readahead = cifs_readahead,                                         
        .writepages = cifs_writepages,                                       
        .write_begin = cifs_write_begin,                                     
        .write_end = cifs_write_end,                                         
        .dirty_folio = cifs_dirty_folio,                                     
        .release_folio = cifs_release_folio,                                 
        .direct_IO = cifs_direct_io,                                         
        .invalidate_folio = cifs_invalidate_folio,                           
        .launder_folio = cifs_launder_folio,                                 
        .migrate_folio = filemap_migrate_folio,       
        /*                                                                   
        * TODO: 调查一下，如果有用，我们可以添加一个 is_dirty_writeback
        * 辅助函数（如果需要的话）                                                  
        */                        
        .swap_activate = cifs_swap_activate,                                 
        .swap_deactivate = cifs_swap_deactivate,                             
};                                                                           

/*                                                                       
 * cifs_readahead 需要服务器支持一个足够大的缓冲区，以容纳
 * 头部加上一个完整的数据页。否则，我们需要在地址空间操作中
 * 省略 cifs_readahead 。          
 */                                                                       
const struct address_space_operations cifs_addr_ops_smallbuf = {         
        .read_folio = cifs_read_folio,                                   
        .writepages = cifs_writepages,                                   
        .write_begin = cifs_write_begin,                                 
        .write_end = cifs_write_end,                                     
        .dirty_folio = cifs_dirty_folio,                                 
        .release_folio = cifs_release_folio,                             
        .invalidate_folio = cifs_invalidate_folio,                       
        .launder_folio = cifs_launder_folio,                             
        .migrate_folio = filemap_migrate_folio,                          
};                                                                       
```

# 文件系统类型

```c
struct file_system_type cifs_fs_type = {        
        .owner = THIS_MODULE,                   
        .name = "cifs",                         
        .init_fs_context = smb3_init_fs_context,
        .parameters = smb3_fs_parameters,       
        .kill_sb = cifs_kill_sb,                
        .fs_flags = FS_RENAME_DOES_D_MOVE,      
}; 

struct file_system_type smb3_fs_type = {        
        .owner = THIS_MODULE,                   
        .name = "smb3",                         
        .init_fs_context = smb3_init_fs_context,
        .parameters = smb3_fs_parameters,       
        .kill_sb = cifs_kill_sb,                
        .fs_flags = FS_RENAME_DOES_D_MOVE,      
};                                              
```

# 模块加载卸载方法

`init_cifs()`和`exit_cifs()`。