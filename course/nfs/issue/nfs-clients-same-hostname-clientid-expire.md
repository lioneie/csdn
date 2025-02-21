# 问题描述

NFS客户端采用NFSv4.2(vers=4.2)挂载时，tcpdump抓包发现，NFS服务端经常SEQUENCE 返回 NFS4ERR_BADSESSION错误导致 客户端主动DESTROY_SESSION和CREATE_SESSION，客户端创建会话时，服务端返回NFS4ERR_STATLE_CLIENTID错误，客户端需要重新EXCHANGE_ID后CREATE_SESSION才成功，因为反复出现这种现象，导致客户端读写文件会出现偶尔错误，系统errno 会返回5。客户端改成 NFSv4.0和NFSv4.1没有出现这种现象。client日志中打印了`NFS: nfs4_reclaim_open_state: Lock reclaim failed!`，server日志中打印了`NFSD: client xx.xx.xx.xx testing state ID with incorrect client ID`。

挂载参数:
```sh
(ro,noexec,relatime,vers=4.1,rsize=1048576,wsize=1048576,namlen=255,soft,proto=tcp,timeo=10,retrans=2,sec=sys,clientaddr=xx.xx.xx.xx,local_lock=none,addr=xx.xx.xx.xx)
(ro,noexec,relatime,vers=4.2,rsize=1048576,wsize=1048576,namlen=255,soft,proto=tcp,timeo=10,retrans=2,sec=sys,clientaddr=xx.xx.xx.xx,local_lock=none,addr=xx.xx.xx.xx)
```

# 分析

关于打印日志`NFS: nfs4_reclaim_open_state: Lock reclaim failed!`，请查看[`3e2910c7e23b NFS: Improve warning message when locks are lost.`](https://chenxiaosong.com/course/nfs/patch/NFS-Improve-warning-message-when-locks-are-lost.html)，注意nfs4.0、4.1和4.2都会有这个打印。

关于打印`NFSD: client xx.xx.xx.xx testing state ID with incorrect client ID`已经被补丁`663e36f07666 nfsd4: kill warnings on testing stateids with mismatched clientids`移除。

# 调试

```sh
mount -t nfs -o ro,noexec,relatime,vers=4.2,rsize=1048576,wsize=1048576,namlen=255,soft,proto=tcp,timeo=10,retrans=2,sec=sys,local_lock=none 192.168.53.214:s_test /mnt
tcpdump --interface=ens2 --buffer-size=20480 -w good.cap &
echo 3 > /proc/sys/vm/drop_caches
cat /mnt/file
```

打开server端的打印开关:
```sh
echo 0x7FFF > /proc/sys/sunrpc/nfsd_debug # NFSDDBG_ALL
```

有以下打印:
```sh
__find_in_sessionid_hashtbl: session not found
```

kprobe跟踪函数:
```sh
cd /sys/kernel/debug/tracing/
cat available_filter_functions | grep __find_in_sessionid_hashtbl # 找不到
cat available_filter_functions | grep find_in_sessionid_hashtbl
cat available_filter_functions | grep init_session
cat available_filter_functions | grep unhash_session # 找不到
cat available_filter_functions | grep nfsd4_destroy_session
cat available_filter_functions | grep unhash_client_locked
echo 1 > tracing_on

echo 'p:p_find_in_sessionid_hashtbl find_in_sessionid_hashtbl' >> kprobe_events
echo 1 > events/kprobes/p_find_in_sessionid_hashtbl/enable
echo stacktrace > events/kprobes/p_find_in_sessionid_hashtbl/trigger
echo '!stacktrace' > events/kprobes/p_find_in_sessionid_hashtbl/trigger
echo 0 > events/kprobes/p_find_in_sessionid_hashtbl/enable
echo '-:p_find_in_sessionid_hashtbl' >> kprobe_events

echo 'p:p_init_session init_session' >> kprobe_events
echo 1 > events/kprobes/p_init_session/enable
echo stacktrace > events/kprobes/p_init_session/trigger
echo '!stacktrace' > events/kprobes/p_init_session/trigger
echo 0 > events/kprobes/p_init_session/enable
echo '-:p_init_session' >> kprobe_events

echo 'p:p_nfsd4_destroy_session nfsd4_destroy_session' >> kprobe_events
echo 1 > events/kprobes/p_nfsd4_destroy_session/enable
echo stacktrace > events/kprobes/p_nfsd4_destroy_session/trigger
echo '!stacktrace' > events/kprobes/p_nfsd4_destroy_session/trigger
echo 0 > events/kprobes/p_nfsd4_destroy_session/enable
echo '-:p_nfsd4_destroy_session' >> kprobe_events

echo 'p:p_unhash_client_locked unhash_client_locked' >> kprobe_events
echo 1 > events/kprobes/p_unhash_client_locked/enable
echo stacktrace > events/kprobes/p_unhash_client_locked/trigger
echo '!stacktrace' > events/kprobes/p_unhash_client_locked/trigger
echo 0 > events/kprobes/p_unhash_client_locked/enable
echo '-:p_unhash_client_locked' >> kprobe_events

echo 0 > trace # 清除trace信息
cat trace_pipe
```

```c
kthread
  nfsd
    svc_process
      svc_process_common
        nfsd_dispatch
          nfsd4_proc_compound

nfsd4_proc_compound
  nfsd4_sequence
    find_in_sessionid_hashtbl
      __find_in_sessionid_hashtbl
        idx = hash_sessionid


nfsd4_proc_compound
  nfsd4_create_session
    init_session
      idx = hash_sessionid
      list_add(&new->se_hash, &nn->sessionid_hashtbl[idx])

nfsd4_proc_compound
  // 执行umount命令时，先执行到这里，再执行到unhash_client_locked
  nfsd4_destroy_session
    unhash_session
      list_del(&ses->se_hash)

nfsd4_proc_compound
  nfsd4_destroy_clientid
    unhash_client
      unhash_client_locked
        list_del_init(&ses->se_hash)
```

# 结论

当多个 NFS 客户端使用相同的主机名时，默认的统一客户端字符串可能不够唯一，导致 NFS 服务器无法区分不同的客户端。NFS 服务器会将第二个客户端视为第一个客户端重启后的结果，从而使第一个客户端的 clientid 失效/过期，阻止第一个客户端进行通信。具体查看[NFSv4 clientid was expired suddenly due to use same hostname on several NFS clients](https://access.redhat.com/solutions/6395261)。