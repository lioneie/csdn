# 问题描述

dorado和netapp当nfs server，使用nfsv3挂载，停止任何操作等待10min以上，再执行`df -h`命令偶现执行时间超3s。使用nfsv4挂载，在一定条件下必现`df -h`命令执行时间超过40s。

# `tcpdump`抓包

## nfsv4

- 5.752516: GETATTR Call
- 5.754274: GETATTR Reply
  - Attr mask[0]: 0x0010011a (Type, Change, Size, FSID, FileId)
  - Attr mask[1]: 0x00b0a23a (Mode, NumLinks, Owner, Owner_Group, RawDev, Space_Used, Time_Access, Time_Metadata, Time_Modify, Mounted_on_FileId)
- 45.802934: GETATTR Call
- 45.805379: GETATTR Replay
  - Attr mask[0]: 0x00e00000 (Files_Avail, Files_Free, Files_Total)
  - Attr mask[1]: 0x00001c00 (Space_Avail, Space_Free, Space_Total)

## nfsv3

- 2351.124940: SYN
- 2351.125149: SYN-ACK
- 2351.125167: RST
- 2354.176234: SYN
- 2354.176450: SYN-ACK
- 2354.176487: SYN

- SYN: 客户端向服务器发送一个SYN（同步）包，表示请求建立连接。这个包中包含客户端的初始序列号。
- SYN-ACK: 服务器收到SYN包后，返回一个SYN-ACK（同步-确认）包，表示同意建立连接，并且确认客户端的序列号。这个包中包含服务器的初始序列号。
- ACK: 客户端收到SYN-ACK包后，发送一个ACK（确认）包给服务器，确认接收到服务器的SYN-ACK。至此，连接建立完成，客户端和服务器可以开始数据传输。
- RST: 是TCP协议中的一种控制包，用于强制关闭一个连接。RST代表“Reset”，RST包的发送意味着连接的状态被立即清除，不需要进行正常的连接终止过程。它通常在以下几种情况下使用：
  - 异常关闭：当一方收到一个不期望的包（例如，连接已经关闭或不存在的连接）时，会发送RST包来通知对方重置连接。
  - 拒绝连接：当服务器收到一个连接请求（SYN），但不愿意或不能接受该请求时，可以发送RST包给客户端，以表明连接被拒绝。
  - 错误处理：在一些错误情况下，例如应用程序崩溃或无法处理接收到的数据，TCP栈可以发送RST包来重置连接。

# 日志分析

## nfsv4

打开日志开关，复现后抓取日志:
```sh
echo 0xFFFF > /proc/sys/sunrpc/nfs_debug # NFSDBG_ALL
echo 0x7fff > /proc/sys/sunrpc/rpc_debug # RPCDBG_ALL
```

复现后抓到以下日志:
```sh
[509287.484234] RPC: 25155 call_start nfs4 proc GETATTR (sync)
[509287.486186] decode_attr_type: type=040000
[509287.486189] decode_attr_change: change attribute=7413717318535264640
[509287.486191] decode_attr_size: file size=4096
[509287.486193] decode_attr_fsid: fsid=(0x1e0/0x0)
[509287.486195] decode_attr_fileid: fileid=65
[509287.486197] decode_attr_fs_locations: fs_locations done, error = 0
[509287.486199] decode_attr_mode: file mode=0755
[509287.486201] decode_attr_nlink: nlink=3
[509307.511394] decode_attr_owner: uid=0
[509327.534150] decode_attr_group: gid=0
[509327.534154] decode_attr_rdev: rdev=(0x0:0x0)
[509327.534156] decode_attr_space_used: space used=4096
[509327.534159] decode_attr_time_access: atime=1726140575
[509327.534161] decode_attr_time_metadata: ctime=1726140575
[509327.534163] decode_attr_time_modify: mtime=1726140575
[509327.534165] decode_attr_mounted_on_fileid: fileid=65
[509327.534592] RPC: 25158 call_start nfs4 proc STATFS (sync)
[509327.537215] decode_attr_files_avail: files avail=2516582400
[509327.537217] decode_attr_files_free: files free=2516582400
[509327.537219] decode_attr_files_total: files total=2516582400
[509327.537221] decode_attr_space_avail: space avail=515395936256
[509327.537223] decode_attr_space_free: space free=515395936256
[509327.537225] decode_attr_space_total: space total=515396075520
```

`GETATTR`回复数据解码在`decode_getfattr_attrs()`函数中，`decode_attr_owner()`过了`20s`才解码，`decode_attr_group()`以后面的解码函数过了`40s`秒。

## nfsv3

```sh
[510403.908320] RPC:   275 xprt_connect_status: retrying
[510403.908323] RPC:   275 call_connect_status (status -104)
[510403.908326] RPC:   275 sleep_on(queue "delayq" time 4805072524)
[510403.908332] RPC:   275 added to queue 000000000db4bcdb "delayq"
[510403.908334] RPC:       wake_up_first(000000008c3c84d4 "xprt_sending")
[510403.908336] RPC:   275 setting alarm for 3000 ms
[510403.908338] RPC:   275 sync task going to sleep
[510406.968250] RPC:   275 timeout
[510406.968273] RPC:   275 __rpc_wake_up_task (now 4805075584)
```

`call_connect_status()`函数中`task->tk_status`错误码为`-ECONNRESET`。