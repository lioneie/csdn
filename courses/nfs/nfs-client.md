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

除了列出结构体的代码和中文注释外，还会整理一些函数的执行流程，方便后续查询。

# 数据结构

## 超级块

### `struct nfs_server`

由于nfs client没有磁盘超级块，所以只有内存超级块结构体，在`nfs_get_tree_common()`函数中赋值`fc->s_fs_info = server`。

这个结构体太长了。

```c
/*
 * "存储在超级块中的 NFS 客户端参数". 挂载参数不同时每挂载一次创建一个nfs_server，请看 nfs_compare_super()
 */
struct nfs_server {
        struct nfs_client *     nfs_client;     /* 共享客户端和 NFS4 状态，多个 nfs_server 对应一个 nfs_client */
        struct list_head        client_link;    /* 共享同一个客户端的其他 nfs_server 结构的列表 */
        struct list_head        master_link;    /* 主服务器列表中的链接 */
        struct rpc_clnt *       client;         /* RPC 客户端句柄 */
        struct rpc_clnt *       client_acl;     /* ACL RPC 客户端句柄 */
        struct nlm_host         *nlm_host;      /* NLM 客户端句柄，v2 v3 文件锁 */
        struct nfs_iostats __percpu *io_stats;  /* I/O 统计信息 */
        atomic_long_t           writeback;      /* 正在向服务器写入的页的个数 */
        unsigned int            write_congested;/* 当写回过高时设置的标志 */
        unsigned int            flags;          /* 各种标志，挂载选项 */

/* 以下仅供内部使用。另见 uapi/linux/nfs_mount.h */
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

        unsigned int            fattr_valid;    /* 有效的属性 */
        unsigned int            caps;           /* 服务器功能，getattr 请求获取的 */
        unsigned int            rsize;          /* 读取大小，read 请求数据最大值 */
        unsigned int            rpages;         /* 读取大小（以页为单位） */
        unsigned int            wsize;          /* 写入大小，write 请求数据最大值 */
        unsigned int            wpages;         /* 写入大小（以页为单位） */
        unsigned int            wtmult;         /* 服务器磁盘块大小 */
        unsigned int            dtsize;         /* readdir 大小，readdir 请求 */
        unsigned short          port;           /* "port=" 设置，服务器端口 */
        unsigned int            bsize;          /* 服务器块大小 */
#ifdef CONFIG_NFS_V4_2
        unsigned int            gxasize;        /* getxattr 大小 */
        unsigned int            sxasize;        /* setxattr 大小 */
        unsigned int            lxasize;        /* listxattr 大小 */
#endif
        unsigned int            acregmin;       /* 属性缓存超时时间，普通文件缓存超时时间 */
        unsigned int            acregmax;
        unsigned int            acdirmin;       /* 目录缓存超时时间 */
        unsigned int            acdirmax;
        unsigned int            namelen;        /* 文件名最大长度 */
        unsigned int            options;        /* 挂载启用的额外选项 */
        unsigned int            clone_blksize;  /* CLONE 操作的粒度 */
#define NFS_OPTION_FSCACHE      0x00000001      /* - 本地缓存启用 */
#define NFS_OPTION_MIGRATION    0x00000002      /* - NFSv4 迁移启用 */

        enum nfs4_change_attr_type
                                change_attr_type;/* 变更属性描述 */

        struct nfs_fsid         fsid;
        int                     s_sysfs_id;     /* sysfs dentry 索引 */
        __u64                   maxfilesize;    /* 最大文件大小 */
        struct timespec64       time_delta;     /* 最小时间粒度 */
        unsigned long           mount_time;     /* 文件系统挂载时间 */
        struct super_block      *super;         /* VFS 超级块 */
        dev_t                   s_dev;          /* 超级块设备编号 */
        struct nfs_auth_info    auth_info;      /* 解析的认证方式 */

#ifdef CONFIG_NFS_FSCACHE
        struct fscache_volume   *fscache;       /* 超级块 cookie */
        char                    *fscache_uniq;  /* 唯一标识符（或 NULL） */
#endif

        u32                     pnfs_blksize;   /* layout_blksize 属性，仅 block layout 使用 */
#if IS_ENABLED(CONFIG_NFS_V4)
        u32                     attr_bitmask[3];/* V4 位掩码，表示此文件系统上支持的一组属性 */
        u32                     attr_bitmask_nl[3];
                                                /* V4 位掩码，表示此文件系统上支持的一组属性，
                                                   不包括标签支持位。 */
        u32                     exclcreat_bitmask[3];
                                                /* V4 位掩码，表示此文件系统上支持的排他创建属性 */
        u32                     cache_consistency_bitmask[3];
                                                /* V4 位掩码，表示服务器支持的变更属性、大小、
                                                   ctime 和 mtime 属性的子集 */
        u32                     acl_bitmask;    /* V4 位掩码，表示此文件系统上支持的 ACEs */
        u32                     fh_expire_type; /* V4 位掩码，表示此文件系统的文件句柄过期类型 */
        struct pnfs_layoutdriver_type  *pnfs_curr_ld; /* 活动布局驱动，有 3 种: block layout、file layout、object layout */
        struct rpc_wait_queue   roc_rpcwaitq;   // rpc 任务等待队列
        void                    *pnfs_ld_data;  /* 每个挂载点的数据 */

        /* 以下字段由 nfs_client->cl_lock 保护 */
        struct rb_root          state_owners;
#endif
        struct ida              openowner_id;
        struct ida              lockowner_id;
        struct list_head        state_owners_lru; // 空闲的 nfs4_state_owner (表示客户端的用户)
        struct list_head        layouts;        // pnfs_layout_hdr 链表
        struct list_head        delegations;    // nfs_delegation 链表
        struct list_head        ss_copies;

        unsigned long           mig_gen;
        unsigned long           mig_status;
#define NFS_MIG_IN_TRANSITION           (1)
#define NFS_MIG_FAILED                  (2)
#define NFS_MIG_TSM_POSSIBLE            (3)

        void (*destroy)(struct nfs_server *);   // nfs_destroy_server 和 nfs4_destroy_server

        atomic_t active; /* 保持对该服务器的任何活动的追踪，引用计数 */

        /* mountd 相关的挂载选项 */
        struct sockaddr_storage mountd_address; // mount 服务器地址
        size_t                  mountd_addrlen; // mount 服务器地址长度
        u32                     mountd_version; // mount 协议版本
        unsigned short          mountd_port;    // mount 协议端口
        unsigned short          mountd_protocol;// 传输层协议，默认 tcp
        struct rpc_wait_queue   uoc_rpcwaitq;

        /* XDR 相关信息 */
        unsigned int            read_hdrsize;

        /* 用户命名空间信息 */
        const struct cred       *cred;
        bool                    has_sec_mnt_opts;
        struct kobject          kobj;
};
```

### `struct nfs_client`

```c
/*                                                                                                 
 * nfs_client 标识我们的客户端状态到服务器。                                       
 */                                                                                                
struct nfs_client {                                                                                
        refcount_t              cl_count;       // 引用计数
        atomic_t                cl_mds_count;   //
        int                     cl_cons_state;  /* 当前构建状态 (-ve: 初始化错误)，下面的 3 种状态 */ 
#define NFS_CS_READY            0               /* 准备使用 */                             
#define NFS_CS_INITING          1               /* 正在初始化 */                            
#define NFS_CS_SESSION_INITING  2               /* 正在初始化会话 */                   
        unsigned long           cl_res_state;   /* NFS 资源状态 */                          
#define NFS_CS_CALLBACK         1               /* - 回调已启动 */                           
#define NFS_CS_IDMAP            2               /* - idmap 已启动 */                              
#define NFS_CS_RENEWD           3               /* - renewd 已启动 */                             
#define NFS_CS_STOP_RENEW       4               /* 不再需要续约状态 */                       
#define NFS_CS_CHECK_LEASE_TIME 5               /* 需要检查租约时间 */                     
        unsigned long           cl_flags;       /* 行为开关 */                            
#define NFS_CS_NORESVPORT       0               /* - 使用临时源端口 */                     
#define NFS_CS_DISCRTRY         1               /* - 在 RPC 重试时断开连接 */                    
#define NFS_CS_MIGRATION        2               /* - 透明状态迁移 */                     
#define NFS_CS_INFINITE_SLOTS   3               /* - 不限制 TCP 槽 */                      
#define NFS_CS_NO_RETRANS_TIMEOUT       4       /* - 禁用重传超时 */                
#define NFS_CS_TSM_POSSIBLE     5               /* - 可能状态迁移 */                      
#define NFS_CS_NOPING           6               /* - 连接时不进行 ping */                      
#define NFS_CS_DS               7               /* - 服务器是 DS */                             
#define NFS_CS_REUSEPORT        8               /* - 重新连接时重用源端口 */                
#define NFS_CS_PNFS             9               /* - 服务器用于 pnfs */                       
        struct sockaddr_storage cl_addr;        /* 服务器标识，服务器 ip 和端口 */
        size_t                  cl_addrlen;     // cl_addr 的长度
        char *                  cl_hostname;    /* 服务器的主机名 */                           
        char *                  cl_acceptor;    /* GSSAPI 接收者名称 */                         
        struct list_head        cl_share_link;  /* 全局客户端列表中的链接 */                   
        struct list_head        cl_superblocks; /* nfs_server 结构体列表，一个 nfs_client 包含多个 nfs_server */                   
                                                                                                   
        struct rpc_clnt *       cl_rpcclient;   // 与 nfs_server 无关的 RPC 请求时使用
        const struct nfs_rpc_ops *rpc_ops;      /* NFS 协议向量，有 nfs_v2_clientops、nfs_v3_clientops、nfs_v4_clientops */                          
        int                     cl_proto;       /* 网络传输协议，默认 tcp */
        struct nfs_subversion * cl_nfs_mod;     /* 指向 nfs 版本模块的指针 */                
                                                                                                   
        u32                     cl_minorversion;/* NFSv4 次要版本 */                           
        unsigned int            cl_nconnect;    /* 连接数 */                        
        unsigned int            cl_max_connect; /* 允许的最大传输数 */                  
        const char *            cl_principal;   /* 用于机器凭证 */                        
        struct xprtsec_parms    cl_xprtsec;     /* 传输安全策略 */                         
                                                                                                   
#if IS_ENABLED(CONFIG_NFS_V4)                                                                      
        struct list_head        cl_ds_clients; /* 认证方式的服务器数据 */                      
        u64                     cl_clientid;    /* 常量 */                                     
        nfs4_verifier           cl_confirm;     /* 客户端 ID 验证器 */                            
        unsigned long           cl_state;                                                          
                                                                                                   
        spinlock_t              cl_lock;                                                           
                                                                              
        unsigned long           cl_lease_time;  // 一般为 90s
        unsigned long           cl_last_renewal;
        struct delayed_work     cl_renewd;      // 超时调用 nfs4_renew_state()
                                                                              
        struct rpc_wait_queue   cl_rpcwaitq;                                  
                                                                              
        /* idmapper */                                                        
        struct idmap *          cl_idmap;                                     
                                                                              
        /* 客户端所有者标识符 */                                         
        const char *            cl_owner_id;                                  
                                                                              
        u32                     cl_cb_ident;    /* v4.0 回调标识符 */
        const struct nfs4_minor_version_ops *cl_mvops;                        
        unsigned long           cl_mig_gen;                                   
                                                                              
        /* NFSv4.0 传输阻塞 */                                      
        struct nfs4_slot_table  *cl_slot_tbl;                                 
                                                                              
        /* 用于下一个 CREATE_SESSION 的序列 ID */              
        u32                     cl_seqid;                                     
        /* 在 EXCHANGE_ID 期间用于获取客户端 ID 的标志 */    
        u32                     cl_exchange_flags;                            
        struct nfs4_session     *cl_session;    /* 共享会话 */          
        bool                    cl_preserve_clid;                             
        struct nfs41_server_owner *cl_serverowner;                            
        struct nfs41_server_scope *cl_serverscope;                            
        struct nfs41_impl_id    *cl_implid;                                   
        /* nfs 4.1+ 状态保护模式: */                                
        unsigned long           cl_sp4_flags;                                 
#define NFS_SP4_MACH_CRED_MINIMAL  1    /* 最小 sp4_mach_cred - 状态操作  
                                         * 必须使用机器凭证 */           
#define NFS_SP4_MACH_CRED_CLEANUP  2    /* CLOSE 和 LOCKU */                 
#define NFS_SP4_MACH_CRED_SECINFO  3    /* SECINFO 和 SECINFO_NO_NAME */     
#define NFS_SP4_MACH_CRED_STATEID  4    /* TEST_STATEID 和 FREE_STATEID */   
#define NFS_SP4_MACH_CRED_WRITE    5    /* WRITE */                           
#define NFS_SP4_MACH_CRED_COMMIT   6    /* COMMIT */                           
#define NFS_SP4_MACH_CRED_PNFS_CLEANUP  7 /* LAYOUTRETURN */                  
#if IS_ENABLED(CONFIG_NFS_V4_1)                                               
        wait_queue_head_t       cl_lock_waitq;                                
#endif /* CONFIG_NFS_V4_1 */                                                  
#endif /* CONFIG_NFS_V4 */                                                    
                                                                              
        /* 我们自己的 IP 地址，作为一个以 null 结尾的字符串。                   
         * 这用于生成 mv0 回调地址。                 
         */                                                                   
        char                    cl_ipaddr[48];                                
        struct net              *cl_net; // 网络命名空间
        struct list_head        pending_cb_stateids;                          
};                                                
```

## 超级块操作

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

## 索引节点

nfs没有磁盘索引节点，只有内存索引节点。

```c
/*
 * nfs fs inode 内存中的数据
 */
struct nfs_inode {
        /*
         * 64位 '索引节点编号'
         */
        __u64 fileid; // 索引节点编号
        /*
         * NFS 文件句柄
         */
        struct nfs_fh           fh; // 文件句柄
        /*
         * 各种标志
         */
        unsigned long           flags;                  /* 原子位操作 */
        unsigned long           cache_validity;         /* 位掩码 */
        /*
         * read_cache_jiffies 是我们开始读取缓存这个索引节点的时间。
         * attrtimeo 是缓存信息被认为有效的时间。成功的属性重新验证将使
         * attrtimeo 翻倍（最多到 acregmax/acdirmax），失败会将其重置为
         * acregmin/acdirmin。
         *
         * 如果以下条件成立，我们需要重新验证这个索引节点的缓存属性
         *
         *      jiffies - read_cache_jiffies >= attrtimeo
         *
         * 请注意比较是大于等于，这样可以指定零超时值。
         */
        unsigned long           read_cache_jiffies;     // 文件属性更新时间
        unsigned long           attrtimeo;              // 文件属性超时时间
        unsigned long           attrtimeo_timestamp;    // attrtimeo最后更新时间

        unsigned long           attr_gencount;          // 文件属性相关计数

        struct rb_root          access_cache;           // nfs_access_entry链表
        struct list_head        access_cache_entry_lru;
        struct list_head        access_cache_inode_lru;

        union {
                /* 目录 */
                struct {
                        /* 属性缓存的“生成计数器”。
                         * 每当我们更新服务器上的元数据时，都会增加这个计数器。
                         */
                        unsigned long   cache_change_attribute;
                        /*
                         * 这是用于 NFSv3 readdir 操作的 cookie 验证器
                         */
                        __be32          cookieverf[NFS_DIR_VERIFIER_SIZE];
                        /* 读操作: 正在进行的 sillydelete RPC 调用 */
                        /* 写操作: rmdir */
                        struct rw_semaphore     rmdir_sem;
                };
                /* 常规文件 */
                struct {
                        atomic_long_t   nrequests;
                        atomic_long_t   redirtied_pages;
                        struct nfs_mds_commit_info commit_info;
                        struct mutex    commit_mutex;
                };
        };

        /* 共享 mmap 写操作的打开上下文 */
        struct list_head        open_files;

        /* 跟踪乱序回复。
         * ooo 数组包含来自 changeid 序列的开始/结束对，当索引节点的
         * iversion 已更新时。它还包含从服务器回复中看到的 changeid 序列的
         * 结束/开始对（即反向顺序）。
         * 通常这些应该匹配，当 A:B 和 B:A 都在 ooo 中时，它们都会被移除。
         * 如果回复中的 A:B 导致 iversion 更新为 A:B，则不会添加。
         * 当回复的 pre_change 不匹配 iversion 时，则会添加 changeid 对和
         * 任何随之而来的 iversion 变化。稍后的回复可能会填补空白，或者
         * 可能由于另一个客户端的更改导致出现空白。
         * 当文件或目录被打开时，如果 ooo 表不为空，则我们假定这些空白是由
         * 另一个客户端造成的，并且我们会使缓存数据无效。
         *
         * 我们只能跟踪有限数量的并发空白。目前限制是 16。
         * 我们按需分配表。如果内存不足，那么我们可能无法缓存文件，所以也
         * 不会有损失。
         */
        struct {
                int cnt;
                struct {
                        u64 start, end;
                } gap[16];
        } *ooo;

#if IS_ENABLED(CONFIG_NFS_V4)
        struct nfs4_cached_acl  *nfs4_acl;
        /* NFSv4 状态 */
        struct list_head        open_states;
        struct nfs_delegation __rcu *delegation;
        struct rw_semaphore     rwsem;

        /* pNFS 布局信息 */
        struct pnfs_layout_hdr *layout;
#endif /* CONFIG_NFS_V4*/
        /* 已经读写的数据量 */
        __u64 write_io;
        __u64 read_io;
#ifdef CONFIG_NFS_V4_2
        struct nfs4_xattr_cache *xattr_cache;
#endif
        union {
                struct inode            vfs_inode;
#ifdef CONFIG_NFS_FSCACHE
                struct netfs_inode      netfs; /* netfs 上下文和 VFS 索引节点 */
#endif
        };
};
```

## 索引节点操作

### 常规文件

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

### 目录

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

### 符号链接

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

### 命名空间

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

## `dentry`操作

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

## `file`操作

### 常规文件

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

### 目录

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

## `address_space`操作

### 常规文件

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

### 目录

```c
const struct address_space_operations nfs_dir_aops = {
        .free_folio = nfs_readdir_clear_array,        
};                                                    
```

## 文件系统类型

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

## 模块加载卸载方法

`init_nfs_fs()`和`exit_nfs_fs()`。

# 函数流程

## rpc

```c
// 挂载时
nfs4_alloc_client
  nfs_create_rpc_client
    rpc_create
      rpc_create_xprt // 只会在挂载时执行到
        rpc_ping
          rpc_call_null_helper
            rpc_call_null_helper
              rpc_run_task

rpc_run_task / rpc_run_bc_task
  rpc_new_task
    rpc_init_task
      rpc_task_get_xprt
  rpc_execute
    rpc_make_runnable
      INIT_WORK(&task->u.tk_work, rpc_async_schedule) // 异步执行
    __rpc_execute // 同步执行，异步在内核线程执行到这个函数

rpc_task_release_client / nfs4_async_handle_exception
  rpc_task_release_transport

rpc_task_set_client / call_start
  rpc_task_set_transport
```

## mount

```c
vfs_parse_fs_param
  // 不指定版本号挂载时，默认用哪个版本由 `mount.nfs` 程序决定
  nfs_fs_context_parse_param

// v3
vfs_get_tree
  nfs_get_tree
    nfs_try_get_tree
      nfs_try_mount_request
        nfs3_create_server
          nfs_create_server
            nfs_init_server
              nfs_get_client
                nfs_match_client
                nfs_alloc_client
                nfs_init_client

// v4
vfs_get_tree
  nfs_get_tree
    nfs4_try_get_tree
      nfs4_create_server
        nfs4_init_server
          nfs4_set_client
            nfs_get_client
              nfs_match_client
              nfs4_alloc_client
                nfs_create_rpc_client
                  rpc_create
              nfs4_init_client
                nfs4_discover_server_trunking
                  nfs41_discover_server_trunking // 返回的 nfs_client 未就绪
                    nfs4_proc_exchange_id
              nfs4_add_trunk // 主线的多路径？
                rpc_clnt_add_xprt

kthread
  nfs4_run_state_manager
    nfs4_state_manager
      nfs4_reclaim_lease
        nfs4_establish_lease
          nfs41_init_clientid
            nfs4_proc_exchange_id
            nfs4_proc_create_session
            nfs_mark_client_ready(clp, NFS_CS_READY) // 设置成就绪状态
      nfs4_state_end_reclaim_reboot
        nfs4_reclaim_complete
          nfs41_proc_reclaim_complete
```

## umount

```c
// v4
task_work_run
  __cleanup_mnt
    cleanup_mnt
      deactivate_super
        deactivate_locked_super
          nfs_kill_super
            nfs_free_server
              rpc_shutdown_client
              nfs_put_client
                nfs4_free_client
                  nfs4_shutdown_client
                    nfs41_shutdown_client
                      nfs4_destroy_session
                        nfs4_proc_destroy_session
                      nfs4_destroy_clientid
                        nfs4_proc_destroy_clientid
                          _nfs4_proc_destroy_clientid
                  nfs_free_client
                    rpc_shutdown_client
```