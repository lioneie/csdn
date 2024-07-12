我们通过开发一个新操作系统需要的步骤，来切入学习nfs client。

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

## `struct nfs_server`

由于nfs client没有磁盘超级块，所以只有内存超级块结构体，在`nfs_get_tree_common()`函数中赋值`fc->s_fs_info = server`。

这个结构体太长了。

```c
/*
 * NFS client parameters stored in the superblock. 挂载参数不同时每挂载一次创建一个nfs_server，请看 nfs_compare_super()
 */
struct nfs_server {
        struct nfs_client *     nfs_client;     /* shared client and NFS4 state, 多个nfs_server对应一个nfs_client */
        struct list_head        client_link;    /* List of other nfs_server structs
                                                 * that share the same client
                                                 */
        struct list_head        master_link;    /* link in master servers list */
        struct rpc_clnt *       client;         /* RPC client handle， rpc客户端 */
        struct rpc_clnt *       client_acl;     /* ACL RPC client handle， acl想着的rpc客户端 */
        struct nlm_host         *nlm_host;      /* NLM client handle, v2 v3文件锁 */
        struct nfs_iostats __percpu *io_stats;  /* I/O statistics， io统计信息 */
        atomic_long_t           writeback;      /* number of writeback pages， 正在向server写入的页的个数 */
        unsigned int            write_congested;/* flag set when writeback gets too high */
        unsigned int            flags;          /* various flags， 挂载选项 */

/* The following are for internal use only. Also see uapi/linux/nfs_mount.h */
#define NFS_MOUNT_LOOKUP_CACHE_NONEG    0x10000
#define NFS_MOUNT_LOOKUP_CACHE_NONE     0x20000
#define NFS_MOUNT_NORESVPORT            0x40000
#define NFS_MOUNT_LEGACY_INTERFACE      0x80000
#define NFS_MOUNT_LOCAL_FLOCK           0x100000
#define NFS_MOUNT_LOCAL_FCNTL           0x200000
#define NFS_MOUNT_SOFTERR               0x400000
#define NFS_MOUNT_SOFTREVAL             0x800000
#define NFS_MOUNT_WRITE_EAGER           0x01000000
#define NFS_MOUNT_WRITE_WAIT            0x02000000
#define NFS_MOUNT_TRUNK_DISCOVERY       0x04000000
#define NFS_MOUNT_SHUTDOWN              0x08000000

        unsigned int            fattr_valid;    /* Valid attributes */
        unsigned int            caps;           /* server capabilities， server的功能，getattr请求获取的 */
        unsigned int            rsize;          /* read size， read请求数据最大值 */
        unsigned int            rpages;         /* read size (in pages) */
        unsigned int            wsize;          /* write size，write请求数据最大值 */
        unsigned int            wpages;         /* write size (in pages) */
        unsigned int            wtmult;         /* server disk block size， server磁盘块大小 */
        unsigned int            dtsize;         /* readdir size, readdir请求 */
        unsigned short          port;           /* "port=" setting， server端口 */
        unsigned int            bsize;          /* server block size， server块大小 */
#ifdef CONFIG_NFS_V4_2
        unsigned int            gxasize;        /* getxattr size */
        unsigned int            sxasize;        /* setxattr size */
        unsigned int            lxasize;        /* listxattr size */
#endif
        unsigned int            acregmin;       /* attr cache timeouts， 普通文件缓存超时时间 */
        unsigned int            acregmax;
        unsigned int            acdirmin;       // 目录缓存
        unsigned int            acdirmax;
        unsigned int            namelen;        // 文件名最大长度
        unsigned int            options;        /* extra options enabled by mount */
        unsigned int            clone_blksize;  /* granularity of a CLONE operation */
#define NFS_OPTION_FSCACHE      0x00000001      /* - local caching enabled */
#define NFS_OPTION_MIGRATION    0x00000002      /* - NFSv4 migration enabled */

        enum nfs4_change_attr_type
                                change_attr_type;/* Description of change attribute */

        struct nfs_fsid         fsid;
        int                     s_sysfs_id;     /* sysfs dentry index */
        __u64                   maxfilesize;    /* maximum file size */
        struct timespec64       time_delta;     /* smallest time granularity， 时间精度 */
        unsigned long           mount_time;     /* when this fs was mounted， 挂载时间 */
        struct super_block      *super;         /* VFS super block */
        dev_t                   s_dev;          /* superblock dev numbers */
        struct nfs_auth_info    auth_info;      /* parsed auth flavors */

#ifdef CONFIG_NFS_FSCACHE
        struct fscache_volume   *fscache;       /* superblock cookie */
        char                    *fscache_uniq;  /* Uniquifier (or NULL) */
#endif

        u32                     pnfs_blksize;   /* layout_blksize attr，block layout才会用到 */
#if IS_ENABLED(CONFIG_NFS_V4)
        u32                     attr_bitmask[3];/* V4 bitmask representing the set
                                                   of attributes supported on this
                                                   filesystem */
        u32                     attr_bitmask_nl[3];
                                                /* V4 bitmask representing the
                                                   set of attributes supported
                                                   on this filesystem excluding
                                                   the label support bit. */
        u32                     exclcreat_bitmask[3];
                                                /* V4 bitmask representing the
                                                   set of attributes supported
                                                   on this filesystem for the
                                                   exclusive create. */
        u32                     cache_consistency_bitmask[3];
                                                /* V4 bitmask representing the subset
                                                   of change attribute, size, ctime
                                                   and mtime attributes supported by
                                                   the server */
        u32                     acl_bitmask;    /* V4 bitmask representing the ACEs
                                                   that are supported on this
                                                   filesystem */
        u32                     fh_expire_type; /* V4 bitmask representing file
                                                   handle volatility type for
                                                   this filesystem， 文件句柄过期原因 */
        struct pnfs_layoutdriver_type  *pnfs_curr_ld; /* Active layout driver，有3种：block layout、file layout、object layout */
        struct rpc_wait_queue   roc_rpcwaitq;   // rpc任务等待队列
        void                    *pnfs_ld_data;  /* per mount point data */

        /* the following fields are protected by nfs_client->cl_lock */
        struct rb_root          state_owners;
#endif
        struct ida              openowner_id;
        struct ida              lockowner_id;
        struct list_head        state_owners_lru; // 空闲的nfs4_state_owner(表示客户端的用户)
        struct list_head        layouts;        // pnfs_layout_hdr链表
        struct list_head        delegations;    // nfs_delegation链表
        struct list_head        ss_copies;

        unsigned long           mig_gen;
        unsigned long           mig_status;
#define NFS_MIG_IN_TRANSITION           (1)
#define NFS_MIG_FAILED                  (2)
#define NFS_MIG_TSM_POSSIBLE            (3)

        void (*destroy)(struct nfs_server *);   // nfs_destroy_server和nfs4_destroy_server

        atomic_t active; /* Keep trace of any activity to this server， 引用计数 */

        /* mountd-related mount options */
        struct sockaddr_storage mountd_address; // mount服务器地址
        size_t                  mountd_addrlen; // mount服务器地址长度
        u32                     mountd_version; // mount协议版本
        unsigned short          mountd_port;    // mount协议端口
        unsigned short          mountd_protocol;// 传输层协议,默认tcp
        struct rpc_wait_queue   uoc_rpcwaitq;

        /* XDR related information */
        unsigned int            read_hdrsize;

        /* User namespace info */
        const struct cred       *cred;
        bool                    has_sec_mnt_opts;
        struct kobject          kobj;
};
```

## `struct nfs_client`

```c
/*                                                                                                 
 * The nfs_client identifies our client state to the server.                                       
 */                                                                                                
struct nfs_client {                                                                                
        refcount_t              cl_count;       // 引用计数
        atomic_t                cl_mds_count;   //
        int                     cl_cons_state;  /* current construction state (-ve: init error)，下面的3种状态 */ 
#define NFS_CS_READY            0               /* ready to be used */                             
#define NFS_CS_INITING          1               /* busy initialising */                            
#define NFS_CS_SESSION_INITING  2               /* busy initialising  session */                   
        unsigned long           cl_res_state;   /* NFS resources state */                          
#define NFS_CS_CALLBACK         1               /* - callback started */                           
#define NFS_CS_IDMAP            2               /* - idmap started */                              
#define NFS_CS_RENEWD           3               /* - renewd started */                             
#define NFS_CS_STOP_RENEW       4               /* no more state to renew */                       
#define NFS_CS_CHECK_LEASE_TIME 5               /* need to check lease time */                     
        unsigned long           cl_flags;       /* behavior switches */                            
#define NFS_CS_NORESVPORT       0               /* - use ephemeral src port */                     
#define NFS_CS_DISCRTRY         1               /* - disconnect on RPC retry */                    
#define NFS_CS_MIGRATION        2               /* - transparent state migr */                     
#define NFS_CS_INFINITE_SLOTS   3               /* - don't limit TCP slots */                      
#define NFS_CS_NO_RETRANS_TIMEOUT       4       /* - Disable retransmit timeouts */                
#define NFS_CS_TSM_POSSIBLE     5               /* - Maybe state migration */                      
#define NFS_CS_NOPING           6               /* - don't ping on connect */                      
#define NFS_CS_DS               7               /* - Server is a DS */                             
#define NFS_CS_REUSEPORT        8               /* - reuse src port on reconnect */                
#define NFS_CS_PNFS             9               /* - Server used for pnfs */                       
        struct sockaddr_storage cl_addr;        /* server identifier， 服务器ip和端口 */
        size_t                  cl_addrlen;     // cl_addr的长度
        char *                  cl_hostname;    /* hostname of server */                           
        char *                  cl_acceptor;    /* GSSAPI acceptor name */                         
        struct list_head        cl_share_link;  /* link in global client list */                   
        struct list_head        cl_superblocks; /* List of nfs_server structs,一个nfs_client包含多个nfs_server */                   
                                                                                                   
        struct rpc_clnt *       cl_rpcclient;   // 与nfs_server无关的RPC请求时使用
        const struct nfs_rpc_ops *rpc_ops;      /* NFS protocol vector, 有nfs_v2_clientops、nfs_v3_clientops、nfs_v4_clientops */                          
        int                     cl_proto;       /* Network transport protocol, 默认tcp */
        struct nfs_subversion * cl_nfs_mod;     /* pointer to nfs version module */                
                                                                                                   
        u32                     cl_minorversion;/* NFSv4 minorversion */                           
        unsigned int            cl_nconnect;    /* Number of connections */                        
        unsigned int            cl_max_connect; /* max number of xprts allowed */                  
        const char *            cl_principal;   /* used for machine cred */                        
        struct xprtsec_parms    cl_xprtsec;     /* xprt security policy */                         
                                                                                                   
#if IS_ENABLED(CONFIG_NFS_V4)                                                                      
        struct list_head        cl_ds_clients; /* auth flavor data servers */                      
        u64                     cl_clientid;    /* constant */                                     
        nfs4_verifier           cl_confirm;     /* Clientid verifier */                            
        unsigned long           cl_state;                                                          
                                                                                                   
        spinlock_t              cl_lock;                                                           
                                                                              
        unsigned long           cl_lease_time;  // 一般为90s
        unsigned long           cl_last_renewal;
        struct delayed_work     cl_renewd;      // 超时调用nfs4_renew_state()
                                                                              
        struct rpc_wait_queue   cl_rpcwaitq;                                  
                                                                              
        /* idmapper */                                                        
        struct idmap *          cl_idmap;                                     
                                                                              
        /* Client owner identifier */                                         
        const char *            cl_owner_id;                                  
                                                                              
        u32                     cl_cb_ident;    /* v4.0 callback identifier */
        const struct nfs4_minor_version_ops *cl_mvops;                        
        unsigned long           cl_mig_gen;                                   
                                                                              
        /* NFSv4.0 transport blocking */                                      
        struct nfs4_slot_table  *cl_slot_tbl;                                 
                                                                              
        /* The sequence id to use for the next CREATE_SESSION */              
        u32                     cl_seqid;                                     
        /* The flags used for obtaining the clientid during EXCHANGE_ID */    
        u32                     cl_exchange_flags;                            
        struct nfs4_session     *cl_session;    /* shared session */          
        bool                    cl_preserve_clid;                             
        struct nfs41_server_owner *cl_serverowner;                            
        struct nfs41_server_scope *cl_serverscope;                            
        struct nfs41_impl_id    *cl_implid;                                   
        /* nfs 4.1+ state protection modes: */                                
        unsigned long           cl_sp4_flags;                                 
#define NFS_SP4_MACH_CRED_MINIMAL  1    /* Minimal sp4_mach_cred - state ops  
                                         * must use machine cred */           
#define NFS_SP4_MACH_CRED_CLEANUP  2    /* CLOSE and LOCKU */                 
#define NFS_SP4_MACH_CRED_SECINFO  3    /* SECINFO and SECINFO_NO_NAME */     
#define NFS_SP4_MACH_CRED_STATEID  4    /* TEST_STATEID and FREE_STATEID */   
#define NFS_SP4_MACH_CRED_WRITE    5    /* WRITE */                           
#define NFS_SP4_MACH_CRED_COMMIT   6    /* COMMIT */                          
#define NFS_SP4_MACH_CRED_PNFS_CLEANUP  7 /* LAYOUTRETURN */                  
#if IS_ENABLED(CONFIG_NFS_V4_1)                                               
        wait_queue_head_t       cl_lock_waitq;                                
#endif /* CONFIG_NFS_V4_1 */                                                  
#endif /* CONFIG_NFS_V4 */                                                    
                                                                              
        /* Our own IP address, as a null-terminated string.                   
         * This is used to generate the mv0 callback address.                 
         */                                                                   
        char                    cl_ipaddr[48];                                
        struct net              *cl_net; // 网络命名空间
        struct list_head        pending_cb_stateids;                          
};                                                                            
```

## 相关代码流程

```c
// v3
mount
  do_mount
    path_mount
      do_new_mount
        vfs_get_tree
          nfs_get_tree
            nfs_try_get_tree
              nfs_try_mount_request
                nfs3_create_server
                  nfs_create_server
                    nfs_init_server
                      nfs_get_client
                        nfs_init_client

// v4
mount
  do_mount
    path_mount
      do_new_mount
        vfs_get_tree
          nfs_get_tree
            nfs4_try_get_tree
              nfs4_create_server
                nfs4_init_server
                  nfs4_set_client
                    nfs_get_client
                      nfs4_init_client
```

# 超级块操作

```c
// nfsv2, nfsv3
const struct super_operations nfs_sops = { 
        .alloc_inode    = nfs_alloc_inode, 
        .free_inode     = nfs_free_inode,  
        .write_inode    = nfs_write_inode, 
        .drop_inode     = nfs_drop_inode,  
        .statfs         = nfs_statfs,      
        .evict_inode    = nfs_evict_inode, 
        .umount_begin   = nfs_umount_begin,
        .show_options   = nfs_show_options,
        .show_devname   = nfs_show_devname,
        .show_path      = nfs_show_path,   
        .show_stats     = nfs_show_stats,  
};                                         

// nfsv4
static const struct super_operations nfs4_sops = { 
        .alloc_inode    = nfs_alloc_inode,         
        .free_inode     = nfs_free_inode,          
        .write_inode    = nfs4_write_inode,        
        .drop_inode     = nfs_drop_inode,          
        .statfs         = nfs_statfs,              
        .evict_inode    = nfs4_evict_inode,        
        .umount_begin   = nfs_umount_begin,        
        .show_options   = nfs_show_options,        
        .show_devname   = nfs_show_devname,        
        .show_path      = nfs_show_path,           
        .show_stats     = nfs_show_stats,          
};                                                 
```

# 索引节点

nfs没有磁盘索引节点，只有内存索引节点。

```c
/*
 * nfs fs inode data in memory
 */
struct nfs_inode {
        /*
         * The 64bit 'inode number'
         */
        __u64 fileid; // 索引节点编号
        /*
         * NFS file handle
         */
        struct nfs_fh           fh; // 文件句柄
        /*
         * Various flags
         */
        unsigned long           flags;                  /* atomic bit ops */
        unsigned long           cache_validity;         /* bit mask */
        /*
         * read_cache_jiffies is when we started read-caching this inode.
         * attrtimeo is for how long the cached information is assumed
         * to be valid. A successful attribute revalidation doubles
         * attrtimeo (up to acregmax/acdirmax), a failure resets it to
         * acregmin/acdirmin.
         *
         * We need to revalidate the cached attrs for this inode if
         *
         *      jiffies - read_cache_jiffies >= attrtimeo
         *
         * Please note the comparison is greater than or equal
         * so that zero timeout values can be specified.
         */
        unsigned long           read_cache_jiffies;     // 文件属性更新时间
        unsigned long           attrtimeo;              // 文件属性超时时间
        unsigned long           attrtimeo_timestamp;    // attrtimeo最后个性时间

        unsigned long           attr_gencount;          // 文件属性相关计数

        struct rb_root          access_cache;           // nfs_access_entry链表
        struct list_head        access_cache_entry_lru; // 
        struct list_head        access_cache_inode_lru;

        union {
                /* Directory */
                struct {
                        /* "Generation counter" for the attribute cache.
                         * This is bumped whenever we update the metadata
                         * on the server.
                         */
                        unsigned long   cache_change_attribute;
                        /*
                         * This is the cookie verifier used for NFSv3 readdir
                         * operations
                         */
                        __be32          cookieverf[NFS_DIR_VERIFIER_SIZE];
                        /* Readers: in-flight sillydelete RPC calls */
                        /* Writers: rmdir */
                        struct rw_semaphore     rmdir_sem;
                };
                /* Regular file */
                struct {
                        atomic_long_t   nrequests;
                        atomic_long_t   redirtied_pages;
                        struct nfs_mds_commit_info commit_info;
                        struct mutex    commit_mutex;
                };
        };

        /* Open contexts for shared mmap writes */
        struct list_head        open_files;

        /* Keep track of out-of-order replies.
         * The ooo array contains start/end pairs of
         * numbers from the changeid sequence when
         * the inode's iversion has been updated.
         * It also contains end/start pair (i.e. reverse order)
         * of sections of the changeid sequence that have
         * been seen in replies from the server.
         * Normally these should match and when both
         * A:B and B:A are found in ooo, they are both removed.
         * And if a reply with A:B causes an iversion update
         * of A:B, then neither are added.
         * When a reply has pre_change that doesn't match
         * iversion, then the changeid pair and any consequent
         * change in iversion ARE added.  Later replies
         * might fill in the gaps, or possibly a gap is caused
         * by a change from another client.
         * When a file or directory is opened, if the ooo table
         * is not empty, then we assume the gaps were due to
         * another client and we invalidate the cached data.
         *
         * We can only track a limited number of concurrent gaps.
         * Currently that limit is 16.
         * We allocate the table on demand.  If there is insufficient
         * memory, then we probably cannot cache the file anyway
         * so there is no loss.
         */
        struct {
                int cnt;
                struct {
                        u64 start, end;
                } gap[16];
        } *ooo;

#if IS_ENABLED(CONFIG_NFS_V4)
        struct nfs4_cached_acl  *nfs4_acl;
        /* NFSv4 state */
        struct list_head        open_states;
        struct nfs_delegation __rcu *delegation;
        struct rw_semaphore     rwsem;

        /* pNFS layout information */
        struct pnfs_layout_hdr *layout;
#endif /* CONFIG_NFS_V4*/
        /* how many bytes have been written/read and how many bytes queued up, 已经读写的数据量 */
        __u64 write_io;
        __u64 read_io;
#ifdef CONFIG_NFS_V4_2
        struct nfs4_xattr_cache *xattr_cache;
#endif
        union {
                struct inode            vfs_inode;
#ifdef CONFIG_NFS_FSCACHE
                struct netfs_inode      netfs; /* netfs context and VFS inode */
#endif
        };
};
```

# 索引节点操作

## 常规文件

```c
// nfsv2
static const struct inode_operations nfs_file_inode_operations = {
        .permission     = nfs_permission,                         
        .getattr        = nfs_getattr,                            
        .setattr        = nfs_setattr,                            
};                                                                

// nfsv3
static const struct inode_operations nfs3_file_inode_operations = {
        .permission     = nfs_permission,                          
        .getattr        = nfs_getattr,                             
        .setattr        = nfs_setattr,                             
#ifdef CONFIG_NFS_V3_ACL                                           
        .listxattr      = nfs3_listxattr,                          
        .get_inode_acl  = nfs3_get_acl,                            
        .set_acl        = nfs3_set_acl,                            
#endif                                                             
};                                                                 

// nfsv4
static const struct inode_operations nfs4_file_inode_operations = {
        .permission     = nfs_permission,                          
        .getattr        = nfs_getattr,                             
        .setattr        = nfs_setattr,                             
        .listxattr      = nfs4_listxattr,                          
};                                                                 
```

## 目录

```c
// nfsv2
static const struct inode_operations nfs_dir_inode_operations = {
        .create         = nfs_create,                            
        .lookup         = nfs_lookup,                            
        .link           = nfs_link,                              
        .unlink         = nfs_unlink,                            
        .symlink        = nfs_symlink,                           
        .mkdir          = nfs_mkdir,                             
        .rmdir          = nfs_rmdir,                             
        .mknod          = nfs_mknod,                             
        .rename         = nfs_rename,                            
        .permission     = nfs_permission,                        
        .getattr        = nfs_getattr,                           
        .setattr        = nfs_setattr,                           
};                                                               

// nfsv3
static const struct inode_operations nfs3_dir_inode_operations = {
        .create         = nfs_create,                             
        .lookup         = nfs_lookup,                             
        .link           = nfs_link,                               
        .unlink         = nfs_unlink,                             
        .symlink        = nfs_symlink,                            
        .mkdir          = nfs_mkdir,                              
        .rmdir          = nfs_rmdir,                              
        .mknod          = nfs_mknod,                              
        .rename         = nfs_rename,                             
        .permission     = nfs_permission,                         
        .getattr        = nfs_getattr,                            
        .setattr        = nfs_setattr,                            
#ifdef CONFIG_NFS_V3_ACL                                          
        .listxattr      = nfs3_listxattr,                         
        .get_inode_acl  = nfs3_get_acl,                           
        .set_acl        = nfs3_set_acl,                           
#endif                                                            
};                                                                

// nfsv4
static const struct inode_operations nfs4_dir_inode_operations = {
        .create         = nfs_create,                             
        .lookup         = nfs_lookup,                             
        .atomic_open    = nfs_atomic_open,                        
        .link           = nfs_link,                               
        .unlink         = nfs_unlink,                             
        .symlink        = nfs_symlink,                            
        .mkdir          = nfs_mkdir,                              
        .rmdir          = nfs_rmdir,                              
        .mknod          = nfs_mknod,                              
        .rename         = nfs_rename,                             
        .permission     = nfs_permission,                         
        .getattr        = nfs_getattr,                            
        .setattr        = nfs_setattr,                            
        .listxattr      = nfs4_listxattr,                         
};                                                                
```

## 符号链接

```c
/*                                                            
 * symlinks can't do much...                                  
 */                                                           
const struct inode_operations nfs_symlink_inode_operations = {
        .get_link       = nfs_get_link,                       
        .getattr        = nfs_getattr,                        
        .setattr        = nfs_setattr,                        
};                                                            
```

## 命名空间

```c
const struct inode_operations nfs_mountpoint_inode_operations = {
        .getattr        = nfs_getattr,                           
        .setattr        = nfs_setattr,                           
};                                                               
                                                                 
const struct inode_operations nfs_referral_inode_operations = {  
        .getattr        = nfs_namespace_getattr,                 
        .setattr        = nfs_namespace_setattr,                 
};                                                               
```

# `dentry`操作

```c
// nfsv2 nfsv3
const struct dentry_operations nfs_dentry_operations = {
        .d_revalidate   = nfs_lookup_revalidate,        
        .d_weak_revalidate      = nfs_weak_revalidate,  
        .d_delete       = nfs_dentry_delete,            
        .d_iput         = nfs_dentry_iput,              
        .d_automount    = nfs_d_automount,              
        .d_release      = nfs_d_release,                
}; 

// nfsv4
const struct dentry_operations nfs4_dentry_operations = {
        .d_revalidate   = nfs4_lookup_revalidate,        
        .d_weak_revalidate      = nfs_weak_revalidate,   
        .d_delete       = nfs_dentry_delete,             
        .d_iput         = nfs_dentry_iput,               
        .d_automount    = nfs_d_automount,               
        .d_release      = nfs_d_release,                 
};                                                       
```

# `file`操作

## 常规文件

```c
// nfsv2 nfsv3
const struct file_operations nfs_file_operations = {
        .llseek         = nfs_file_llseek,          
        .read_iter      = nfs_file_read,            
        .write_iter     = nfs_file_write,           
        .mmap           = nfs_file_mmap,            
        .open           = nfs_file_open,            
        .flush          = nfs_file_flush,           
        .release        = nfs_file_release,         
        .fsync          = nfs_file_fsync,           
        .lock           = nfs_lock,                 
        .flock          = nfs_flock,                
        .splice_read    = nfs_file_splice_read,     
        .splice_write   = iter_file_splice_write,   
        .check_flags    = nfs_check_flags,          
        .setlease       = simple_nosetlease,        
};                                                  

// nfsv4
const struct file_operations nfs4_file_operations = {
        .read_iter      = nfs_file_read,             
        .write_iter     = nfs_file_write,            
        .mmap           = nfs_file_mmap,             
        .open           = nfs4_file_open,            
        .flush          = nfs4_file_flush,           
        .release        = nfs_file_release,          
        .fsync          = nfs_file_fsync,            
        .lock           = nfs_lock,                  
        .flock          = nfs_flock,                 
        .splice_read    = nfs_file_splice_read,      
        .splice_write   = iter_file_splice_write,    
        .check_flags    = nfs_check_flags,           
        .setlease       = nfs4_setlease,             
#ifdef CONFIG_NFS_V4_2                               
        .copy_file_range = nfs4_copy_file_range,     
        .llseek         = nfs4_file_llseek,          
        .fallocate      = nfs42_fallocate,           
        .remap_file_range = nfs42_remap_file_range,  
#else                                                
        .llseek         = nfs_file_llseek,           
#endif                                               
};                                                   
```

## 目录

```c
const struct file_operations nfs_dir_operations = {
        .llseek         = nfs_llseek_dir,          
        .read           = generic_read_dir,        
        .iterate_shared = nfs_readdir,             
        .open           = nfs_opendir,             
        .release        = nfs_closedir,            
        .fsync          = nfs_fsync_dir,           
};                                                 
```

# `address_space`操作

## 常规文件

```c
const struct address_space_operations nfs_file_aops = { 
        .read_folio = nfs_read_folio,                   
        .readahead = nfs_readahead,                     
        .dirty_folio = filemap_dirty_folio,             
        .writepage = nfs_writepage,                     
        .writepages = nfs_writepages,                   
        .write_begin = nfs_write_begin,                 
        .write_end = nfs_write_end,                     
        .invalidate_folio = nfs_invalidate_folio,       
        .release_folio = nfs_release_folio,             
        .migrate_folio = nfs_migrate_folio,             
        .launder_folio = nfs_launder_folio,             
        .is_dirty_writeback = nfs_check_dirty_writeback,
        .error_remove_page = generic_error_remove_page, 
        .swap_activate = nfs_swap_activate,             
        .swap_deactivate = nfs_swap_deactivate,         
        .swap_rw = nfs_swap_rw,                         
};                                                      
```

## 目录

```c
const struct address_space_operations nfs_dir_aops = {
        .free_folio = nfs_readdir_clear_array,        
};                                                    
```

# 文件系统类型

```c
// nfsv2 nfsv3
struct file_system_type nfs_fs_type = {                                     
        .owner                  = THIS_MODULE,                              
        .name                   = "nfs",                                    
        .init_fs_context        = nfs_init_fs_context,                      
        .parameters             = nfs_fs_parameters,                        
        .kill_sb                = nfs_kill_super,                           
        .fs_flags               = FS_RENAME_DOES_D_MOVE|FS_BINARY_MOUNTDATA,
};                                                                          

// nfsv4                                       
struct file_system_type nfs4_fs_type = {                                    
        .owner                  = THIS_MODULE,                              
        .name                   = "nfs4",                                   
        .init_fs_context        = nfs_init_fs_context,                      
        .parameters             = nfs_fs_parameters,                        
        .kill_sb                = nfs_kill_super,                           
        .fs_flags               = FS_RENAME_DOES_D_MOVE|FS_BINARY_MOUNTDATA,
};                                                                          
```

# 模块加载卸载方法

`init_nfs_fs()`和`exit_nfs_fs()`。