本文介绍一下我尝试过的nfs定位问题的常用方法，非权威，欢迎指正。

# 日志

发生问题时，报错日志肯定是很有用的信息，大部分发行版都会把日志放在`/var/log/messages*`文件中，默认情况下，nfs只会打印错误信息。但有些时候，我们需要一些调试日志信息，这时就要打开nfs和rpc的调试开关。几个打印相关的宏定义是`dprintk()`、`dprintk_cont()`、`dprintk_rcu()`、`dprintk_rcu_cont`，下面以`dprintk()`为例讲一下这个宏定义的展开:
```c
// include/linux/sunrpc/debug.h
dprintk(fmt, ...)
  dfprintk(FACILITY, fmt, ##__VA_ARGS__)
    ifdebug(fac)
      // include/linux/sunrpc/debug.h
      if (unlikely(rpc_debug & RPCDBG_FACILITY))
      // include/linux/nfs_fs.h
      if (unlikely(nfs_debug & NFSDBG_FACILITY))
      // fs/nfsd/nfsd.h
      if (nfsd_debug & NFSDDBG_FACILITY)
      // include/linux/lockd/debug.h
      if (unlikely(nlm_debug & NLMDBG_FACILITY))
    printk(KERN_DEFAULT fmt, ##__VA_ARGS__);
```

以下是打开全部日志的命令，注意这将会打印大量日志，请先把`/var/log/messages*`复制保存到其他位置，避免错误日志被覆盖:
```sh
echo 0xFFFF > /proc/sys/sunrpc/nfs_debug # NFSDBG_ALL
echo 0x7fff > /proc/sys/sunrpc/rpc_debug # RPCDBG_ALL
echo 0x7FFF > /proc/sys/sunrpc/nfsd_debug # NFSDDBG_ALL
echo 0x7fff > /proc/sys/sunrpc/nlm_debug # NLMDBG_ALL
```

如果你缩小了定位的范围，可以只打开某些日志:
```sh
echo 0x0008 > /proc/sys/sunrpc/nfs_debug # NFSDBG_PAGECACHE
echo 0x0040 > /proc/sys/sunrpc/rpc_debug # RPCDBG_SCHED
echo 0x0400 > /proc/sys/sunrpc/nfsd_debug # NFSDDBG_PNFS
echo 0x0008 > /proc/sys/sunrpc/nlm_debug # NLMDBG_SVCLOCK
```

# tcpdump抓包

既然nfs涉及到网络，定位问题肯定也少不了网络抓包，甚至在绝大多数情况下，网络抓包能够比日志提供更有用更直观的信息，使用`tcpdump`工具抓包:
```sh
# --interface: 指定要监听的网络接口，any表示所有的网络接口
# --buffer-size: 默认4KB, 单位 KB, 20480 代表 20MB。buffer大一点可以防止抓包数据丢失
tcpdump --interface=<网络接口> --buffer-size=20480 -w out.cap
```

当数据量比较大时，有时会发生抓包数据丢失。配置网络参数，把参数调大可以防止抓包数据丢失:
```sh
sysctl -a | grep net.core.rmem # 查看配置
sysctl net.core.rmem_default=xxx
sysctl net.core.rmem_max=xxx
```

`tcpdump`抓包的文件，可以使用[`wireshark`](https://www.wireshark.org/)分析。如果要查看端口，需要在`preferences -> appearance -> columns`中添加`Src port (unresolved)`和`Dest port (unresolved)`。

# 重新挂载

在生产环境下，如果出现问题，很多时候可能没有很多时间可以保留现场，可能需要重新挂载快速恢复。

请注意，在`umount`之前，务必收集好需要的调试信息，因为很多问题可能一年半载也只会出现那么一次。

`umount <挂载点>`命令如果报错`device is busy`之类的信息，说明挂载点正在使用，可以使用以下命令查看使用挂载点的进程:
```sh
lsof | grep <挂载点>
fuser -m <挂载点>
```

如果找到的使用挂载点的进程非常重要，kill这些进程会导致重大问题，可以使用以下命令延迟卸载，会导致挂载点在后台被卸载，而不会强制终止进程:
```sh
umount --lazy <挂载点>
```

如果找到的使用挂载点的进程没有那么重要，建议还是kill掉这些进程再卸载，这样才能更彻底的恢复环境:
```sh
kill -SIGKILL <进程号>
umount <挂载点>
```

# 导出vmcore

在生产环境下，如果必须要快速恢复环境，且这个环境是可以接受重启系统，就可以尝试手动导出vmcore，vmcore中的信息有时对分析问题很有帮助:
```sh
echo 1 > /proc/sys/kernel/sysrq
echo c > /proc/sysrq-trigger
```

关于vmcore的更详细内容，请查看[内核调试方法](https://chenxiaosong.com/course/kernel/debug.html)。

如果要让内核在hungtask或softlockup等情况触发panic，可以执行以下操作:
```sh
sysctl -w kernel.softlockup_panic=1 # -w：表示“写”操作，用来修改内核参数
sysctl -w kernel.hung_task_panic=0
sysctl kernel.softlockup_panic # 查看
# 或者用以下命令
echo 1 > /proc/sys/kernel/softlockup_panic # 和sysctl命令效果一样
echo 0 > /proc/sys/kernel/hung_task_panic
cat /proc/sys/kernel/softlockup_panic # 查看
```

# 非特权源端口挂载

默认情况下，nfs client挂载使用的源端口是小于1024的特权端口（Privileged Ports），需要root权限。

但在某些情况下，无法挂载时，可以尝试使用大于1024的非特权端口挂载，这对排查问题很有帮助。

首先，server端的`/etc/exports`文件中对导出路径增加`insecure`选项，如:
```sh
/tmp/ *(rw,no_root_squash,fsid=0,insecure)
```

重启server端服务:
```sh
systemctl restart nfs-server.service
```

这时client端可以使用所有范围的端口挂载，默认情况下还是使用小于1024的端口，而大于1024的端口要指定挂载选项`noresvport`:
```sh
mount -t nfs -o noresvport ${server_ip}:/ /mnt
```

请注意，使用非特权源端口挂载在一些场景下是不安全的（从server端的配置选项的字面意思`insecure`就能看出），尽量只在调试场景下使用。

在我曾经定位过的nfs问题中，有碰到过路由器或交换机出于产品的某些原因，把小于1024的端口的数据包都给过滤了，当时就是使用非特权源端口挂载的方法排除其他可能性，最终定位出问题。
