<!-- https://blog.csdn.net/ycnian/category_1320297.html -->

# NFS和SunRPC

先看一下维基百科对NFS的定义:

> 网络文件系统（英语: Network File System，缩写作 NFS）是一种分布式文件系统，力求客户端主机可以访问服务器端文件，并且其过程与访问本地存储时一样，它由昇阳电脑（已被甲骨文公司收购）开发，于1984年发布。
>
> 它基于开放网路运算远端程序呼叫（ONC RPC，又被称为Sun ONC 或 Sun RPC）系统: 一个开放、标准的RFC系统，任何人或组织都可以依据标准实现它。

再看一下SunRPC的定义:

> 开放网路运算远端程序呼叫（英语: Open Network Computing Remote Procedure Call，缩写为ONC RPC），一种被广泛应用的远端程序呼叫（RPC）系统，是一种属于应用层的协议堆叠，底层为TCP/IP协议。开放网路运算（ONC）最早源自于昇阳电脑（Sun），是网路文件系统计划的一部份，因此它经常也被称为Sun ONC 或 Sun RPC。现今在多数类UNIX系统上都实作了这套系统，微软公司也以Windows Services for UNIX在他们产品上提供ONC RPC的支援。2009年，昇阳电脑以标准三条款的BSD许可证释出这套系统。2010年，收购了昇阳电脑的甲骨文公司确认了这套软体BSD许可证的有效性与适用范围。

# NFS各版本比较

nfs各个版本的区别:

- NFSv2: 实现基本的功能，有很多的限制，如: 读写最大长度限制8192字节，文件句柄长度固定32字节，只支持同步写。
- NFSv3: 取消了一些限制，如: 文件句柄长度最大64字节，支持服务器异步写。增加ACCESS请求检查用户的访问权限。
- NFSv4: 有状态协议（NFSv2和NFSv3都是无状态协议），实现文件锁功能。只有两种请求`NULL`和`COMPOUND`，支持delegation。文件句柄长度最大128字节。
- NFSv4.1: 支持并行存储。
- NFSv4.2: 引入复合写操作（COMPOUNDV4 Write Operations），支持服务器端复制（不经过客户端）。

# 文件句柄

我们先来看一下client端如果只告诉server端一个inode号会发生什么。

nfs server端的`/etc/exports`文件如下:
```sh
/export/sda *(rw,no_root_squash,fsid=0)
/export/sda/sdb *(rw,no_root_squash,fsid=1)
```

nfs server端以下命令执行后，`/export/sda/file`和`/export/sda/sdb/file`的inode号相同都是12（通过命令`stat file`查看）:
```sh
mkfs.ext4 -b 4096 -F /dev/sda
mkfs.ext4 -b 4096 -F /dev/sdb

mkdir /export/sda
mount -t ext4 /dev/sda /export/sda
touch /export/sda/file

mkdir /export/sda/sdb
mount -t ext4 /dev/sdb /export/sda/sdb
touch /export/sda/sdb/file
```

nfs client挂载命令:
```sh
mount -t nfs -o vers=4.1 ${server_ip}:/ /mnt
```

以上命令执行后，`${server_ip}:/`挂载到`/mnt`，nfs client端执行`stat /mnt/file`查看到inode为12。

nfs client再执行`stat /mnt/sdb/file`查看到inode也为12，这时会自动将`${server_ip}:/sdb`挂载到`/mnt/sdb`。

所以，如果nfs client只告诉nfs server一个inode号，nfs server不能确定是哪个文件系统的inode，也就无法找到对应的文件。

文件句柄中不仅包含inode信息，还包含服务端具体文件系统的信息，总之就是肯定可以在服务端找到对应的文件。nfs server文件句柄的数据结构是:
```c
struct knfsd_fh {                                                             
        unsigned int    fh_size;        /*                                    
                                         * Points to the current size while   
                                         * building a new file handle.        
                                         */                                   
        union {                                                               
                char                    fh_raw[NFS4_FHSIZE];                  
                struct {                                                      
                        u8              fh_version;     /* == 1 */            
                        u8              fh_auth_type;   /* deprecated */      
                        u8              fh_fsid_type;                         
                        u8              fh_fileid_type;                       
                        u32             fh_fsid[]; /* flexible-array member */
                };                                                            
        };                                                                    
};                                                                            
```

server端生成文件句柄的流程是:
```c
// 将当前文件句柄设置为根文件系统
nfsd4_putrootfh
  exp_pseudoroot
    fh_compose
      mk_fsid

// 打开文件时，创新一个新的文件句柄
nfsd4_open
  do_open_lookup
    do_nfsd_create
      fh_compose
        mk_fsid
```

nfs client查看文件的`filehandle`，可以用`tcpdump`抓包，再使用`wireshark`查看 。

# clientid

前面说过NFSv4最大的变化是有状态的协议，每个客户端有一个独一无二的clientid，NFSv4.0相关的两种请求是`SETCLIENTID`和`SETCLIENTID_CONFIRM`。

另外，client有三种stateid: `nfs_delegation stateid`, `nfs4_lock_state ls_stateid`, `nfs4_state open_stateid`。

客户端相关的信息保存在`struct nfs_client`和`struct nfs4_client`中。client初始化clientid的函数为`nfs4_init_clientid()`和`nfs41_init_clientid()`。

`SETCLIENTID`请求: client端编码解码函数为`nfs4_xdr_enc_setclientid()`和`nfs4_xdr_dec_setclientid()`。server端处理函数是`nfsd4_setclientid()`，编码解码函数为`nfsd4_encode_setclientid()`和`nfsd4_decode_setclientid()`。

`SETCLIENTID_CONFIRM`请求: client端编码解码函数为`nfs4_xdr_enc_setclientid_confirm()`和`nfs4_xdr_dec_setclientid_confirm()`。server端处理函数是`nfsd4_setclientid_confirm(),`，编码解码函数为`nfsd4_encode_noop()`和`nfsd4_decode_setclientid_confirm()`。

在nfs client发起`SETCLIENTID`请求时，会创建一个RPC反向通道，nfs client是反向通道的服务器端。server端反向通道相关信息存储在`struct nfs4_cb_conn`,server端发起的callback请求(rpc请求)用`struct nfsd4_callback`表示。`nfsd4_setclientid() -> gen_callback()`填充`struct nfs4_cb_conn`，`nfsd4_setclientid_confirm() -> nfsd4_probe_callback()`创建反向通道，`nfsd4_run_cb_work() -> nfsd4_process_cb_update()`创建rpc客户端。

# session

<!-- https://www.likecs.com/show-305428643.html -->

NFSv4.1引入了一个很大很大的设计: session（会话）。`EXCHANGE_ID`取代了`SETCLIENTID`，`CREATE_SESSION`取代了`SETCLIENTID_CONFIRM`。

[rfc8881](https://www.rfc-editor.org/rfc/rfc8881)的“2.10.1. Motivation and Overview”（动机和概述）一节提到session是为了解决以下问题:

- 不支持“Exactly Once Semantics（精确一次语义）”（EOS）。这包括通过服务器故障和恢复对 EOS 的支持不足。
- 有限的回调支持，包括不支持通过防火墙发送回调以及正常请求和回调之间的竞争。
- 通过多个网络路径的有限trunking支持。
- 对于完全安全的操作需要机器凭据。

每个客户端有多个session，session可以连接不同的server。每个session有一个或两个通道: 正向通道（fore channel）和反向通道（backchannel）。每个通道有多个连接(connection)，每个连接类型可以不同。

session trunking: 是指将多个connection关联到同一个session，这些connection可以具有不同的目标和/或源网络地址。当两个连接的目标网络地址（server地址）相同时，server必须支持此类session trunking。当目标网络地址不同时，server可以在`EXCHANGE_ID`操作返回的数据中指示对session trunking的支持。client和server都可以有多个网络interface，connection的源地址和目标地址都可以不一样，如果connection属于同一组client和server就可以用于session trunking。

clientid trunking: 是指将多个session关联到同一个clientid。server必须在允许两个网络地址的session trunking的同时支持clientid trunking，server还允许cliented trunking的其他情况。多个server可能位于同一台机器，一组server可能有同样的数据（共享磁盘、集群），这种情况就可以使用clientid trunking。

todo: Exactly Once Semantics 和 Server Callback Races 的内容有待补充。

# delegation机制

delegation机制: 当nfs client1打开一个文件时，如果RPC反向通道可用，nfs server就会颁发一个凭证，nfs client1读写文件就不用发起`GETATTR`请求。当另一个client2也访问这个文件时，server就先回收client1的凭证，再响应client2的请求。之后，就和nfsv2和nfsv3一样读写之前要发起`GETATTR`请求。

回收delegation的过程如下:
```sh
                                +---------+
                                |         |
                                | client2 |<--------+
                                |         |         |
                                +---------+         |
                                  |     ^           |
                            1.OPEN|     |           |
                                  |     |           |
                                  | 2.NFS4ERR_DELAY |
                                  v     |           |
+---------+                     +---------+         |
|         |<---3.CB_RECALL------|         |         |
| client1 |----4.ok------------>| server  |--7.ok---+
|         |----5.DELEGRETURN--->|         |
|         |<---6.ok-------------|         |
+---------+                     +---------+
```

如果client1的反向通道抽风了，不能用了，回收delegation就会超时，server删除delegation，响应client2，然后在client1主动向server请求时，再通知client1。

客户端delegation的数据结构为`struct nfs_delegation`，服务端的数据结构为`struct nfs4_delegation`。delegation类型`enum open_delegation_type4`。

server创建delegation的流程:
```c
nfsd4_open
  nfsd4_process_open2
    nfs4_open_delegation
      nfsd4_cb_channel_good // 判断反向通道
      nfs4_set_delegation
        alloc_init_deleg
        vfs_setlease // 采用租借锁实现delegation
```

server回收delegation的操作是`NFSPROC4_CLNT_CB_RECALL`（操作处理函数定义在`nfs4_cb_procedures`），处理client发过来的请求的函数是`nfsd4_delegreturn`。

client端相关的流程:
```c
// 由_nfs4_open_and_get_state -> _nfs4_proc_open发起
rpc_async_schedule
  __rpc_execute
    rpc_prepare_task
      nfs4_open_prepare
        can_open_delegated // 判断是否要发起open请求

// 打开一个有delegation的文件
do_dentry_open
  nfs4_file_open
    nfs4_atomic_open
      nfs4_do_open
        _nfs4_do_open
          _nfs4_open_and_get_state
            _nfs4_proc_open
              nfs4_run_open_task
                .callback_ops = &nfs4_open_ops, // 会异步调用到nfs4_open_prepare
            _nfs4_opendata_to_nfs4_state
              nfs4_try_open_cached
                can_open_delegated

// 回收delegation
nfs_end_delegation_return
  nfs_end_delegation_return
    nfs_delegation_claim_opens
      nfs4_open_delegation_recall
        nfs4_open_recover_helper
          _nfs4_recover_proc_open // 发起open请求
          nfs4_opendata_to_nfs4_state // 更新struct nfs4_state
    nfs_do_return_delegation
      nfs4_proc_delegreturn // 最终调用到nfs4_xdr_enc_delegreturn, 更多的操作查看nfs4_procedures
```

# nfs文件锁

使用命令`man 5 nfs`查看`lock / nolock`挂载选项翻译如下:
```sh
选择是否使用NLM（Network Lock Manager）侧边协议在服务器上对文件进行加锁。如果未指定任何选项（或指定了lock选项），则在此挂载点上使用NLM锁定。当使用nolock选项时，应用程序可以锁定文件，但此类锁定仅对在同一客户端上运行的其他应用程序提供排除效果。远程应用程序不受这些锁的影响。

在使用NFS挂载/var时，必须使用nolock选项禁用NLM锁定，因为/var包含Linux上的NLM实现使用的文件。在挂载不支持NLM协议的NFS服务器上的导出时，也需要使用nolock选项。
```

<!-- 网上查到的，不确定是否正确
挂载选项`nolock`: 这是默认选项，在客户端加锁，不能保证多个客户端之间的数据不发生冲突。和其他文件系统的加锁过程一样。
挂载选项`lock`: 在服务端加锁，能够保证所有客户端访问同一文件不发生冲突。这里只介绍服务端锁。
-->

nfsv2和nfsv3使用NLM（Network Lock Manager）协议实现文件锁。`lock / nolock`挂载选项仅针对nfsv2和nfsv3，未指定时，默认`lock`选项。

nfsv4实现了文件锁，不需要NLM协议。`lock / nolock`挂载选项对nfsv4似乎不起作用。

锁定文件使用的命令是:
```sh
# -n, --nonblock: 如果无法获得锁，不会阻塞，而是立即返回非零退出状态。
# -e, --exclusive: 获取排他锁（写锁）。
# -s, --shared: 获取共享锁（读锁）。
flock -n /mnt/file -c 'echo "get file lock success"'
```

代码处理流程如下:
```c
// 加锁
SYSCALL_DEFINE2(flock, ...
  nfs_flock // f.file->f_op->flock
    do_setlk
      nfs4_proc_lock

// 关闭文件时释放锁
fput
  init_task_work(&file->f_rcuhead, ____fput);
    ____fput
      __fput
        locks_remove_file
          locks_remove_flock
            nfs_flock
              do_unlk
                nfs4_proc_lock
```

`nfs4_proc_lock`的第二个参数`int cmd`有3种选项:

- F_GETLK: 查询文件锁
- F_SETLK: 设置文件锁，如果冲突就退出
- F_SETLKW: 设置文件锁，如果冲突就等待，直到成功

文件锁相关的请求:

- NFSPROC4_CLNT_LOCK: 加锁
- NFSPROC4_CLNT_LOCKT: 查询
- NFSPROC4_CLNT_LOCKU: 解锁
- NFSPROC4_CLNT_RELEASE_LOCKOWNER: 释放文件锁所有者

判断锁类型的函数`nfs4_lock_type()`。

# todo

- `exportfs`: 解析结果`/var/lib/nfs/etab`
- `rpc.nfsd`:
- `rpc.mountd`: 
  - 开启MOUNT服务（NFS4不需要），请求server基本信息（主要是根节点的文件句柄）
  - 解析`/var/lib/nfs/etab`

v2 v3 sun, v4 netapp

nfsv3锁功能需要NLM

- `ac, noac`
- `actimeo`: `acregmin、acregmax、acdirmin、acdirmax`统一的值
- `sec`: 默认`sys`
- `sharecache  nosharecache`: 同一文件系统挂载到不到的目录是，是否共享文件缓存
- `lookupcache`
- `fsc`: fscache，数据保存到客户端磁盘，只读或修改不频繁

读:
```c
nfs_file_read
  nfs_file_direct_read // dio
  nfs_revalidate_mapping
    __nfs_revalidate_inode
      nfs_refresh_inode
  generic_file_read_iter
```

`struct nfs_pageio_ops nfs_pgio_rw_ops`。

`struct nfs_pgio_completion_ops`

radix树

`nfs_generic_pg_pgios`

`struct nfs_openargs nfs_openres nfs_open_confirmargs nfs_open_confirmres nfs4_opendata`

server和 client:

- `nfs4_openowner nfs4_state_owner`
- `nfs4_ol_stateid nfs4_state`

Linux没有实现OPEN_DELEGATE_WRITE open_delegation_type4, 好像不对，有实现

`encode_open()`

`CLOSE和OPEN_DOWNGRADE`

`struct rpc_call_ops`

`struct auth_ops svcauth_unix`

`rpc_procinfo rpc_message`

idr机制

NFSv2和NFSv3通过MOUNT协议获取根节点的⽂件句柄,[nfs-utils](https://git.kernel.org/pub/scm/linux/kernel/git/rw/nfs-utils.git/)的`mount_mnt_3_svc()`函数,写入`/proc/fs/nfsd/filehandle`，内核`write_filehandle()`解析（现在这个函数找不到）。

NFSv4通过PUTROOTFH请求获取根节点的⽂件句柄

`nfs4_open_delegation()`

`nfs_end_delegation_return()`

Clients和Storage Devices传输数据时需要使用专门的存储协议。目前RFC定义了三种存储协议: file
layout(RFC5661)、block layout(RFC5663)、object layout(RFC5664)
