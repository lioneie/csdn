# 问题描述

`nfsiostat`命令输出:
```sh
           ops/s       rpc bklog
           8.246           0.000

read:              ops/s            kB/s           kB/op         retrans    avg RTT (ms)    avg exe (ms)  avg queue (ms)
                   0.002           0.143          67.001        0 (0.0%)           1.618           1.658           0.015
write:             ops/s            kB/s           kB/op         retrans    avg RTT (ms)    avg exe (ms)  avg queue (ms)
                   6.549          24.308           3.711        0 (0.0%)           0.987        4621.857        4620.851
```

# `nfsiostat`

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

# 调试

```sh
time dd if=/dev/random of=/mnt/file bs=1 count=1 oflag=direct
time dd if=/mnt/file of=/dev/null bs=1 count=1 iflag=direct
```