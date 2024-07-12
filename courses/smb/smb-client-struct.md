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
        struct rb_root tlink_tree;                                   
        spinlock_t tlink_tree_lock;                                  
        struct tcon_link *master_tlink;                              
        struct nls_table *local_nls;                                 
        struct smb3_fs_context *ctx;                                 
        atomic_t active;                                             
        unsigned int mnt_cifs_flags;                                 
        struct delayed_work prune_tlinks;                            
        struct rcu_head rcu;                                         
                                                                     
        /* only used when CIFS_MOUNT_USE_PREFIX_PATH is set */       
        char *prepath;                                               
                                                                     
        /*                                                           
         * Indicate whether serverino option was turned off later    
         * (cifs_autodisable_serverino) in order to match new mounts.
         */                                                          
        bool mnt_cifs_serverino_autodisabled;                        
        /*                                                           
         * Available once the mount has completed.                   
         */                                                          
        struct dentry *root;                                         
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
/*      .show_path      = cifs_show_path, */ /* Would we ever need show path? */
        .show_devname   = cifs_show_devname,                                    
/*      .delete_inode   = cifs_delete_inode,  */  /* Do not need above          
        function unless later we add lazy close of inodes or unless the         
        kernel forgets to call us with the same number of releases (closes)     
        as opens */                                                             
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
 * One of these for each file inode
 */                                
struct cifsInodeInfo {                                                                          
        struct netfs_inode netfs; /* Netfslib context and vfs inode */                          
        bool can_cache_brlcks;                                                                  
        struct list_head llist; /* locks helb by this inode */                                  
        /*                                                                                      
         * NOTE: Some code paths call down_read(lock_sem) twice, so                             
         * we must always use cifs_down_write() instead of down_write()                         
         * for this semaphore to avoid deadlocks.                                               
         */                                                                                     
        struct rw_semaphore lock_sem;   /* protect the fields above */                          
        /* BB add in lists for dirty pages i.e. write caching info for oplock */                
        struct list_head openFileList;                                                          
        spinlock_t      open_file_lock; /* protects openFileList */                             
        __u32 cifsAttrs; /* e.g. DOS archive bit, sparse, compressed, system */                 
        unsigned int oplock;            /* oplock/lease level we have */                        
        unsigned int epoch;             /* used to track lease state changes */                 
#define CIFS_INODE_PENDING_OPLOCK_BREAK   (0) /* oplock break in progress */                    
#define CIFS_INODE_PENDING_WRITERS        (1) /* Writes in progress */                          
#define CIFS_INODE_FLAG_UNUSED            (2) /* Unused flag */                                 
#define CIFS_INO_DELETE_PENDING           (3) /* delete pending on server */                    
#define CIFS_INO_INVALID_MAPPING          (4) /* pagecache is invalid */                        
#define CIFS_INO_LOCK                     (5) /* lock bit for synchronization */                
#define CIFS_INO_MODIFIED_ATTR            (6) /* Indicate change in mtime/ctime */              
#define CIFS_INO_CLOSE_ON_LOCK            (7) /* Not to defer the close when lock is set */     
        unsigned long flags;                                                                    
        spinlock_t writers_lock;                                                                
        unsigned int writers;           /* Number of writers on this inode */                   
        unsigned long time;             /* jiffies of last update of inode */                   
        u64  server_eof;                /* current file size on server -- protected by i_lock */
        u64  uniqueid;                  /* server inode number */                               
        u64  createtime;                /* creation time on server */                           
        __u8 lease_key[SMB2_LEASE_KEY_SIZE];    /* lease key for this inode */                  
        struct list_head deferred_closes; /* list of deferred closes */                         
        spinlock_t deferred_lock; /* protection on deferred list */                             
        bool lease_granted; /* Flag to indicate whether lease or oplock is granted. */          
        char *symlink_target;                                                                   
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
/* d_delete:       cifs_d_delete,      */ /* not needed except for debugging */
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
         * TODO: investigate and if useful we could add an is_dirty_writeback
         * helper if needed                                                  
         */                                                                  
        .swap_activate = cifs_swap_activate,                                 
        .swap_deactivate = cifs_swap_deactivate,                             
};                                                                           

/*                                                                       
 * cifs_readahead requires the server to support a buffer large enough to
 * contain the header plus one complete page of data.  Otherwise, we need
 * to leave cifs_readahead out of the address space operations.          
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