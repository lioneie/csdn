# 问题描述

挂载信息:
```sh
mount | grep nfs
xx.xx.xx.xx:/server/export on /mnt type nfs (rw,relatime,vers=3,rsize=1048576,wsize=1048576,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=xx.xx.xx.xx,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=xx.xx.xx.xx,_netdev)
```

`nfsiostat`命令输出:
```sh
           ops/s       rpc bklog
           8.246           0.000

read:              ops/s            kB/s           kB/op         retrans    avg RTT (ms)    avg exe (ms)  avg queue (ms)
                   0.002           0.143          67.001        0 (0.0%)           1.618           1.658           0.015
write:             ops/s            kB/s           kB/op         retrans    avg RTT (ms)    avg exe (ms)  avg queue (ms)
                   6.549          24.308           3.711        0 (0.0%)           0.987        4621.857        4620.851
```

`mpstat`和`iostat -xm`命令输出中的`%iowait`过高，需要确认是否和nfs有关。

# `nfsiostat`

## man手册

```sh
NAME
       nfsiostat - 使用 /proc/self/mountstats 模拟 NFS 挂载点的 iostat

SYNOPSIS
       nfsiostat [[<interval>] [<count>]] [<options>] [<mount_point>]

DESCRIPTION
       nfsiostat 命令显示 NFS 客户端每个挂载点的统计信息。

       <interval>
              指定每个报告之间的时间间隔（单位：秒）。第一次报告包含自每个文件系统挂载以来的统计信息。之后的每个报告包含自上一个报告以来的统计信息。

       <count>
              如果指定了 <count> 参数，则 <count> 的值决定了在 <interval> 秒间隔下生成的报告数量。如果没有指定 <count> 参数，命令将连续生成报告。

       <options>
              见下文定义

       <mount_point>
              如果指定了一个或多个 <mount_point>，则仅显示这些挂载点的统计信息。否则，客户端上所有的 NFS 挂载点的统计信息将会列出。

       nfsiostat 输出的每一列的含义如下：
               - op/s
                      每秒操作次数。
               - rpc bklog
                      后台队列的长度。
               - kB/s
                      每秒读取/写入的千字节数。
               - kB/op
                      每次操作读取/写入的千字节数。
               - retrans
                      重传的次数。
               - avg RTT (ms)
                      从客户端内核发送 RPC 请求到接收到回复的时间延迟（毫秒）。
               - avg exe (ms)
                      从 NFS 客户端发出 RPC 请求到 RPC 请求完成的时间延迟（毫秒），包括上述 RTT 时间。
               - avg queue (ms)
                      从 NFS 客户端创建 RPC 请求任务到请求被传输的时间延迟（毫秒）。
               - errors
                      以错误状态（状态值小于 0）完成的操作次数。此计数仅在内核支持 RPC iostats 版本 1.1 或更高版本时可用。

       注意，如果使用时间间隔作为 nfsiostat 的参数，则显示的是与上一个时间间隔的差值，否则结果将显示自挂载共享以来的统计信息。

OPTIONS
       -a  或  --attr
              显示与属性缓存相关的统计信息。

       -d  或  --dir
              显示与目录操作相关的统计信息。

       -h  或  --help
              显示帮助信息并退出。

       -l LIST 或  --list=LIST
              仅打印前 LIST 个挂载点的统计信息。

       -p  或  --page
              显示与页面缓存相关的统计信息。

       -s  或  --sort
              按每秒操作次数（ops/second）排序 NFS 挂载点。

       --version
              显示程序的版本号并退出。

FILES
       /proc/self/mountstats

SEE ALSO
       iostat(8), mountstats(8), nfsstat(8)

AUTHOR
       Chuck Lever <chuck.lever@oracle.com>
```

## 代码分析

`/proc/self/mountstats`文件内容:
```sh
device localhost:/tmp/s_test mounted on /mnt with fstype nfs statvers=1.1
        opts:   rw,vers=3,rsize=1048576,wsize=1048576,namlen=255,acregmin=3,acregmax=60,acdirmin=30,acdirmax=60,hard,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=127.0.0.1,mountvers=3,mountport=20048,mountproto=udp,local_lock=none
        age:    159
        caps:   caps=0xf,wtmult=4096,dtsize=1048576,bsize=0,namlen=255
        sec:    flavor=1,pseudoflavor=1
        events: 0 0 0 0 2 1 7 1 0 1 0 1 0 0 3 0 0 2 0 0 1 0 0 0 0 0 0 
        bytes:  15 15 0 0 15 15 1 1 
        RPC iostats version: 1.1  p/v: 100003/3 (nfs)
        xprt:   tcp 795 1 2 0 2 15 15 0 15 0 2 0 0
        per-op statistics
                NULL: 1 1 0 44 24 0 0 0 0
             GETATTR: 2 2 0 208 224 0 0 0 0
             SETATTR: 0 0 0 0 0 0 0 0 0
              LOOKUP: 1 1 0 112 224 0 0 0 0
              ACCESS: 3 3 0 332 360 0 0 0 0
            READLINK: 0 0 0 0 0 0 0 0 0
                READ: 1 1 0 124 144 0 0 0 0
               WRITE: 1 1 0 148 136 0 14 14 0
              CREATE: 1 1 0 152 232 0 23 23 0
               MKDIR: 0 0 0 0 0 0 0 0 0
             SYMLINK: 0 0 0 0 0 0 0 0 0
               MKNOD: 0 0 0 0 0 0 0 0 0
              REMOVE: 0 0 0 0 0 0 0 0 0
               RMDIR: 0 0 0 0 0 0 0 0 0
              RENAME: 0 0 0 0 0 0 0 0 0
                LINK: 0 0 0 0 0 0 0 0 0
             READDIR: 0 0 0 0 0 0 0 0 0
         READDIRPLUS: 0 0 0 0 0 0 0 0 0
              FSSTAT: 1 1 0 104 84 0 0 0 0
              FSINFO: 2 2 0 208 160 0 0 0 0
            PATHCONF: 0 0 0 0 0 0 0 0 0
              COMMIT: 0 0 0 0 0 0 0 0 0
```

`rpc_init_task_statistics()`记录rpc任务开始的时刻，`xs_tcp_send_request()`记录tcp请求的时刻，`xprt_lookup_rqst()`计算tcp请求到收到回复的间隔时间，`rpc_count_iostats_metrics()`计算排队的时间和rpc任务总的时间:
```c
REG("mountstats", S_IRUSR, proc_mountstats_operations)

mountstats_open
  mounts_open_common
    p->show = show_vfsstat

show_vfsstat
  nfs_show_stats
    rpc_clnt_show_stats
      _add_rpc_iostats
      _print_rpc_iostats
        ktime_to_ms(stats->om_queue)

rpc_call_sync
  rpc_run_task
    rpc_new_task
      rpc_init_task
        rpc_init_task_statistics
          task->tk_start = ktime_get() // rpc任务开始的时刻

rpc_execute
  __rpc_execute
    call_transmit
      xprt_transmit
        xprt_request_transmit
          xs_tcp_send_request
            req->rq_xtime = ktime_get() // 发送tcp请求的时刻

xprt_lookup_rqst
  entry->rq_rtt = ktime_sub(ktime_get(), entry->rq_xtime) // tcp请求到收到回复的间隔时间

rpc_count_iostats_metrics
  backlog = ktime_sub(req->rq_xtime, task->tk_start) // rpc任务开始到tcp请求的间隔时间，也就是排队的时间
  execute = ktime_sub(now, task->tk_start) // 总的时间
```

# `/proc/stat`

由`strace -o strace.out -f -v -s 4096 xxxx`可以看出`iostat -xm` 和`mpstat`都是解析`/proc/stat`中的内容。

代码分析如下:
```c
struct proc_ops stat_proc_ops

stat_open
  single_open_size(file, show_stat,

show_stat
  get_iowait_time
    get_cpu_iowait_time_us
      get_cpu_sleep_time_us(ts, &ts->iowait_sleeptime,
```

# 调试

挂载:
```sh
mount -t nfs -o rw,relatime,vers=3,rsize=1048576,wsize=1048576,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,_netdev localhost:/tmp/s_test /mnt
```

测试读写一个字节所需时间:
```sh
time dd if=/dev/random of=/mnt/file bs=1 count=1 oflag=direct
time dd if=/mnt/file of=/dev/null bs=1 count=1 iflag=direct
```

从结果看，`dd`命令读写所用的时间正常。

再打开nfs和sunrpc的日志调试开关:
```sh
echo 0xFFFF > /proc/sys/sunrpc/nfs_debug # NFSDBG_ALL
echo 0x7fff > /proc/sys/sunrpc/rpc_debug # RPCDBG_ALL
nfsiostat 1 >  nfsiostat.txt &
nfsiostat_pid=$!
sleep 10
dmesg > dmesg.txt
# 关闭日志调试开关
echo 0 > /proc/sys/sunrpc/nfs_debug
echo 0 > /proc/sys/sunrpc/rpc_debug
kill -9 ${nfsiostat_pid}
```

# 代码分析

调用`io_schedule_prepare()`的地方:
```sh
io_schedule
io_schedule_timeout
mutex_lock_io
mutex_lock_io_nested
blkcg_maybe_throttle_blkg
```

