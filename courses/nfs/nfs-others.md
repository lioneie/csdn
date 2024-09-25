正在更新的内容都放到这篇文章中，等到有些知识点达到一定量时，会把这些知识点整理成专门的一章。

# `df`命令

client会发送两个`GETATTR`请求，第一个`GETATTR`请求以下内容:

- `Attr mask[0]: 0x0010011a (Type, Change, Size, FSID, FileId)`
- `Attr mask[1]: 0x00b0a23a (Mode, NumLinks, Owner, Owner_Group, RawDev, Space_Used, Time_Access, Time_Metadata, Time_Modify, Mounted_on_FileId)`

第二个`GETATTR`请求以下内容:

- `Attr mask[0]: 0x00e00000 (Files_Avail, Files_Free, Files_Total)`
- `Attr mask[1]: 0x00001c00 (Space_Avail, Space_Free, Space_Total)`

# 网络超时

```sh
systemctl stop nfs-server
stat /mnt/file

[100196.619028] nfs: server localhost not responding, still trying
[100216.521372] nfs: server localhost not responding, timed out
```

# delegation

`echo something > /mnt/file; echo 3 > /proc/sys/vm/drop_caches; cat > /mnt/file`:
```c
nfsd4_open
  nfsd4_process_open2
    nfs4_open_delegation
      nfs4_set_delegation
        alloc_init_deleg
          nfs4_alloc_stid
      nfs4_put_stid(&dp->dl_stid)
```

`echo 3 > /proc/sys/vm/drop_caches`:
```c
nfsd4_delegreturn
  destroy_delegation
    destroy_unhashed_deleg
      nfs4_put_stid
  nfs4_put_stid
```

# Procedures和Operations

## NFSv2 Procedures

NFSv2的Procedures定义在`include/uapi/linux/nfs2.h`中的`NFSPROC_NULL ~ NFSPROC_STATFS`，编码解码函数定义在`nfs_procedures`和`nfsd_procedures2`。

## NFSv3 Procedures

NFSv3的Procedures定义在`include/uapi/linux/nfs3.h`中的`NFS3PROC_NULL ~ NFS3PROC_COMMIT`，编码解码函数定义在`nfs3_procedures`和`nfsd_procedures3`。

## NFSv4 Procedures和Operations

NFSv4的Procedures定义在`include/linux/nfs4.h`中的`NFSPROC4_NULL`和`NFSPROC4_COMPOUND`，server编码解码函数定义在`nfsd_procedures4`。

NFSv4 server详细的Operations定义在`include/linux/nfs4.h`中的`enum nfs_opnum4`，处理函数定义在`nfsd4_ops`，编码解码函数定义在`nfsd4_enc_ops`和`nfsd4_dec_ops`。

NFSv4 client详细的Operations定义在`include/linux/nfs4.h`中的`NFSPROC4_CLNT_NULL ~ NFSPROC4_CLNT_READ_PLUS`，编码解码函数定义在`nfs4_procedures`。

## 反向通道Operations

NFSv4反向通道的Operations定义在`include/linux/nfs4.h`中的`enum nfs_cb_opnum4`(老版本内核还重复定义在`fs/nfs/callback.h`中的`enum nfs4_callback_opnum`，我已经提补丁移到公共头文件: [NFSv4, NFSD: move enum nfs_cb_opnum4 to include/linux/nfs4.h](https://lore.kernel.org/all/tencent_03EDD0CAFBF93A9667CFCA1B68EDB4C4A109@qq.com/))，server在`fs/nfsd/state.h`中还定义了`nfsd4_cb_op`，编码解码函数定义在`nfs4_cb_procedures`。client的编码解码函数定义在`callback_ops`。

# exportfs

`struct export_operations`

#  文件句柄

```sh
                    1.  +------------+ 6.
                   +----|   client   |>>>>>>>>>>+
                   |    +------------+          | 
           hey man,|          ^               你好像在逗我
    can you tell me|          |额，你猜？
 whose inode is 12?|        5.|                 |         
                   |    +------------+          |   
                   +--->|   server   |<<<<<<<<<<+  
                        +------------+
                         |  ^    ^  |
                     2.1.|  |    |  |2.2.
               +---------+  |    |  +---------+
               |            |    |            |
       hey boy |       i know   i know too    |hey girl
   do you know?|            |    |            |do you know?
               v            |    |            v      
          +----------+ 4.1. |    |4.2.   +----------+ 
          | /dev/sda |------+    +-------| /dev/sdb |
          +----------+                   +----------+
               ^                              ^      
        i am 12|                              |i am 12
               |3.1.                      3.2.|
          +----------+                   +----------+
          |   file   |                   |   file   |
          +----------+                   +----------+
```

# idmap

启用idmap:
```sh
echo N > /sys/module/nfsd/parameters/nfs4_disable_idmapping # server，默认为Y
echo N > /sys/module/nfs/parameters/nfs4_disable_idmapping # client，默认为Y
```

server端`/etc/idmapd.conf`文件配置:
```sh
[General]

Verbosity = 0
Pipefs-Directory = /run/rpc_pipefs
# set your own domain here, if it differs from FQDN minus hostname
# 修改成其他值，客户端nfs_map_name_to_uid和nfs_map_group_to_gid函数中的id不为0
Domain = localdomain

[Mapping]

Nobody-User = nobody
Nobody-Group = nogroup
```