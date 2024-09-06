# 问题描述

用主线内核(`7033999ecd7b`)测试nfs，发现当server端重启服务`systemctl restart nfs-server`，client端再读写文件会卡一会儿，5.10内核没有这个现象。

5.10内核server端重启服务，有如下打印:
```sh
[   97.616435] nfsd: last server has exited, flushing export cache
[   98.763518] NFSD: Using UMH upcall client tracking operations.
[   98.765527] NFSD: starting 90-second grace period (net f0000098)
```

主线内核server端重启服务，有如下打印:
```sh
[   64.637398] NFSD: Unable to initialize client recovery tracking! (-110)
[   64.639536] NFSD: starting 90-second grace period (net f0000000)
```

# 测试

复现命令如下:
```sh
# 以下命令如果没有特别强调，默认是client端的命令

systemctl restart nfs-server # server端命令
echo something > something
# 为什么不直接用 echo something > /mnt/file 呢，因为用ps命令无法查看到echo进程
# 但是这里好像用cat也没什么卵用，还是要用 ps aux | grep bash 才能找到进程号
# cat something > /mnt/file
# 还是用后台运行的方式，打印出进程号
echo something > /mnt/file & # 写文件，后台运行，会打印出进程号
[1] 493 # 进程号

systemctl restart nfs-server # server端命令
echo 3 > /proc/sys/vm/drop_caches
cat /mnt/file & # 读文件

cat /proc/493/stack
[<0>] nfs4_delay_interruptible+0x33/0xa0
[<0>] nfs4_delay+0x40/0x50
[<0>] nfs4_handle_exception+0xd2/0xf0
[<0>] nfs4_do_open+0x170/0x280
[<0>] nfs4_atomic_open+0xa9/0x110
[<0>] nfs_atomic_open+0x3cb/0x720
[<0>] atomic_open+0x8c/0x1b0
[<0>] lookup_open+0x330/0x470
[<0>] open_last_lookups+0x25b/0x4b0
[<0>] path_openat+0xa5/0x190
[<0>] do_filp_open+0x53/0xc0
[<0>] do_sys_openat2+0xab/0xe0
[<0>] do_sys_open+0xb5/0xd0
[<0>] __se_sys_openat+0x2f/0x40
[<0>] __x64_sys_openat+0x23/0x30
[<0>] do_syscall_64+0xe1/0x1d0
[<0>] entry_SYSCALL_64_after_hwframe+0x6c/0x74
```

server端用主线，client端用5.10，有问题；server端用5.10，client端用主线，没有问题。说明问题出在server端。

# client端代码分析

虽然问题出在server端，但我们还是先分析一下client端的代码，看看为什么读写文件会卡一会儿。

加调试打印信息:
```sh
--- a/fs/nfs/nfs4proc.c
+++ b/fs/nfs/nfs4proc.c
@@ -617,6 +617,7 @@ int nfs4_handle_exception(struct nfs_server *server, int errorcode, struct nfs4_
                        exception->retry = 0;
                        return ret2;
                }
+               printk("%s:%d, timeout:%ld\n", __func__, __LINE__, exception->timeout);
                ret = nfs4_delay(&exception->timeout,
                                exception->interruptible);
                goto out_retry;
```

测试打印结果如下:
```sh
root@syzkaller:~# time echo something > /mnt/file &
[1] 547
[  439.410573] nfs4_handle_exception:620, timeout:0
[  439.518513] nfs4_handle_exception:620, timeout:200
[  439.727291] nfs4_handle_exception:620, timeout:400 # 600
[  440.135717] nfs4_handle_exception:620, timeout:800 # 1400
[  440.992090] nfs4_handle_exception:620, timeout:1600 # 3000
[  442.655003] nfs4_handle_exception:620, timeout:3200 # 6200
[  445.919886] nfs4_handle_exception:620, timeout:6400 # 12600
[  452.383892] nfs4_handle_exception:620, timeout:12800 # 25400
[  465.695635] nfs4_handle_exception:620, timeout:25600 # 51000
[  481.055601] nfs4_handle_exception:620, timeout:30000 # 81000
[  496.415008] nfs4_handle_exception:620, timeout:30000 # 111000
[  511.775498] nfs4_handle_exception:620, timeout:30000 # 141000
real    1m27.820s # 87.82s
user    0m0.000s
sys     0m0.024s
```

server重启服务后，client打开文件时server端不断返回`NFS4ERR_GRACE`错误，代码流程如下:
```c
openat
  do_sys_open
    do_sys_openat2
      do_filp_open
        path_openat
          open_last_lookups
            lookup_open
              atomic_open
                nfs_atomic_open
                  nfs4_atomic_open
                    nfs4_do_open
                      status = _nfs4_do_open
                        _nfs4_open_and_get_state
                          _nfs4_proc_open
                            nfs4_run_open_task
                              rpc_run_task
                              // 从抓包数据可以看出，间隔时间依次是 0.105461, 0.20805, 0.407991, 0.807962, 1.665381, 3.264049, 6.463902, 13.311876, 15.35971
                              status = rpc_wait_for_completion_task
                      nfs4_handle_exception(status)
                        nfs4_do_handle_exception
                          case -NFS4ERR_GRACE:
                          exception->delay = 1
                        if (exception->delay) { // 条件满足
                        nfs4_delay
                          nfs4_delay_interruptible
```

# server端代码分析

下面我们再分析server端的问题。

首先看一下重启服务时的报错信息。前面说过，5.10内核server端重启服务，有如下打印:
```sh
[   97.616435] nfsd: last server has exited, flushing export cache
[   98.763518] NFSD: Using UMH upcall client tracking operations.
[   98.765527] NFSD: starting 90-second grace period (net f0000098)
```

主线内核server端重启服务，有如下错误打印:
```sh
[   64.637398] NFSD: Unable to initialize client recovery tracking! (-110)
[   64.639536] NFSD: starting 90-second grace period (net f0000000)
```

主线内核打开`CONFIG_NFSD_LEGACY_CLIENT_TRACKING`配置，没有问题，重启server端服务打印以下日志:
```sh
[  122.050050] NFSD: Using UMH upcall client tracking operations.
[  122.074438] NFSD: Using UMH upcall client tracking operations.
[  122.076097] NFSD: starting 90-second grace period (net f0000000)
```

所以现在要分析没打开`CONFIG_NFSD_LEGACY_CLIENT_TRACKING`配置时为什么会报错。`cld_running()`一直返回`false`。
```c
// rpc.nfsd进程
write
  ksys_write
    vfs_write
      nfsctl_transaction_write
        write_threads
          nfsd_svc
            nfsd_startup_net
              nfs4_state_start_net
                nfsd4_client_tracking_init
                  status = nfsd4_cld_tracking_init(net) = -110 // ETIMEDOUT
                    running = cld_running() = false // 判断10次，共1秒
                    if (!running) // 条件满足 running == false
                    status = -ETIMEDOUT
                  check_for_legacy_methods(status == -ETIMEDOUT)
                  if (status) { // status == -ETIMEDOUT
                  printk(KERN_WARNING "NFSD: Unable to initialize client"
                                      "recovery tracking! (%d)\n", status)
                printk(KERN_INFO "NFSD: starting %lld-second grace period (net %x)\n"
                queue_delayed_work(laundry_wq, &nn->laundromat_work, nn->nfsd4_grace * HZ)

// laundromat_work 延时执行的任务
laundromat_main
```

下面分析client端请求打开文件时，server为什么会返回错误`NFS4ERR_GRACE`:
```c
nfsd
  svc_recv
    svc_handle_xprt
      svc_process
        svc_process_common
          nfsd_dispatch
            nfsd4_proc_compound
              nfsd4_open
                status = nfserr_grace
                open->op_claim_type == NFS4_OPEN_CLAIM_NULL
                opens_in_grace(net) = true
                  __state_in_grace
                return nfserr_grace
```