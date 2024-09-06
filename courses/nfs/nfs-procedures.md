
# NFSv2 Procedures

NFSv2的Procedures定义在`include/uapi/linux/nfs2.h`中的`NFSPROC_NULL ~ NFSPROC_STATFS`，编码解码函数定义在`nfs_procedures`和`nfsd_procedures2`。

# NFSv3 Procedures

NFSv3的Procedures定义在`include/uapi/linux/nfs3.h`中的`NFS3PROC_NULL ~ NFS3PROC_COMMIT`，编码解码函数定义在`nfs3_procedures`和`nfsd_procedures3`。

# NFSv4 Procedures和Operations

NFSv4的Procedures定义在`include/linux/nfs4.h`中的`NFSPROC4_NULL`和`NFSPROC4_COMPOUND`，server编码解码函数定义在`nfsd_procedures4`。

NFSv4 server详细的Operations定义在`include/linux/nfs4.h`中的`enum nfs_opnum4`，处理函数定义在`nfsd4_ops`，编码解码函数定义在`nfsd4_enc_ops`和`nfsd4_dec_ops`。

NFSv4 client详细的Operations定义在`include/linux/nfs4.h`中的`NFSPROC4_CLNT_NULL ~ NFSPROC4_CLNT_READ_PLUS`，编码解码函数定义在`nfs4_procedures`。

# 反向通道Operations

NFSv4反向通道的Operations定义在`include/linux/nfs4.h`中的`enum nfs_cb_opnum4`(老版本内核还重复定义在`fs/nfs/callback.h`中的`enum nfs4_callback_opnum`，我已经提补丁移到公共头文件: [NFSv4, NFSD: move enum nfs_cb_opnum4 to include/linux/nfs4.h](https://lore.kernel.org/all/tencent_03EDD0CAFBF93A9667CFCA1B68EDB4C4A109@qq.com/))，server在`fs/nfsd/state.h`中还定义了`nfsd4_cb_op`，编码解码函数定义在`nfs4_cb_procedures`。client的编码解码函数定义在`callback_ops`。
