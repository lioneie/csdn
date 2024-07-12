本文介绍一下我尝试过的nfs定位问题的常用方法，非权威，欢迎指正。

# 日志

发生问题时，报错日志肯定是很有用的信息，大部分发行版都会把日志放在`/var/log/messages*`文件中，默认情况下，nfs只会打印错误信息。但有些时候，我们需要一些调试日志信息，这时就要打开nfs和rpc的调试开关，以下是打开全部日志的命令，注意这将会打印大量日志，请先把`/var/log/messages*`复制保存到其他位置，避免错误日志被覆盖：
```sh
echo 0xFFFF > /proc/sys/sunrpc/nfs_debug # NFSDBG_ALL              0xFFFF
echo 0x7fff > /proc/sys/sunrpc/rpc_debug # RPCDBG_ALL              0x7fff
```

如果你缩小了nfs定位的范围，比如说只打开`pagecache`相关的nfs日志：
```sh
echo 0x0008 > /proc/sys/sunrpc/nfs_debug # NFSDBG_PAGECACHE
```

`include/uapi/linux/nfs_fs.h`中所有的nfs调试`flag`:
```sh
#define NFSDBG_VFS              0x0001
#define NFSDBG_DIRCACHE         0x0002
#define NFSDBG_LOOKUPCACHE      0x0004
#define NFSDBG_PAGECACHE        0x0008
#define NFSDBG_PROC             0x0010
#define NFSDBG_XDR              0x0020
#define NFSDBG_FILE             0x0040
#define NFSDBG_ROOT             0x0080
#define NFSDBG_CALLBACK         0x0100
#define NFSDBG_CLIENT           0x0200
#define NFSDBG_MOUNT            0x0400
#define NFSDBG_FSCACHE          0x0800
#define NFSDBG_PNFS             0x1000
#define NFSDBG_PNFS_LD          0x2000
#define NFSDBG_STATE            0x4000
#define NFSDBG_ALL              0xFFFF
```

同样的，如果你缩小了rpc定位的范围，比如说只打开`call`相关的rpc日志：
```sh
echo 0x0002 > /proc/sys/sunrpc/rpc_debug # RPCDBG_CALL
```

`include/uapi/linux/sunrpc/debug.h`中所有的rpc调试`flag`:
```sh
#define RPCDBG_XPRT             0x0001
#define RPCDBG_CALL             0x0002
#define RPCDBG_DEBUG            0x0004
#define RPCDBG_NFS              0x0008
#define RPCDBG_AUTH             0x0010
#define RPCDBG_BIND             0x0020
#define RPCDBG_SCHED            0x0040
#define RPCDBG_TRANS            0x0080
#define RPCDBG_SVCXPRT          0x0100
#define RPCDBG_SVCDSP           0x0200
#define RPCDBG_MISC             0x0400
#define RPCDBG_CACHE            0x0800
#define RPCDBG_ALL              0x7fff
```

# tcpdump抓包

既然nfs涉及到网络，定位问题肯定也少不了网络抓包，甚至在绝大多数情况下，网络抓包能够比日志提供更有用更直观的信息，使用`tcpdump`工具抓包：
```sh
# --interface: 指定要监听的网络接口，any表示所有的网络接口
# --buffer-size: 默认4KB, 单位 KB, 20480 代表 20MB。buffer大一点可以防止抓包数据丢失
tcpdump --interface=<网络接口> --buffer-size=20480 -w out.cap
```

当数据量比较大时，有时会发生抓包数据丢失。配置网络参数，把参数调大可以防止抓包数据丢失：
```sh
sysctl -a | grep net.core.rmem # 查看配置
sysctl net.core.rmem_default=xxx
sysctl net.core.rmem_max=xxx
```

`tcpdump`抓包的文件，可以使用`wireshark`分析。

# 重新挂载

在生产环境下，如果出现问题，很多时候可能没有很多时间可以保留现场，可能需要重新挂载快速恢复。

请注意，在`umount`之前，务必收集好需要的调试信息，因为很多问题可能一年半载也只会出现那么一次。

`umount <挂载点>`命令如果报错`device is busy`之类的信息，说明挂载点正在使用，可以使用以下命令查看使用挂载点的进程：
```sh
lsof | grep <挂载点>
fuser -m <挂载点>
```

如果找到的使用挂载点的进程非常重要，kill这些进程会导致重大问题，可以使用以下命令延迟卸载，会导致挂载点在后台被卸载，而不会强制终止进程：
```sh
umount --lazy <挂载点>
```

如果找到的使用挂载点的进程没有那么重要，建议还是kill掉这些进程再卸载，这样才能更彻底的恢复环境：
```sh
kill -SIGKILL <进程号>
umount <挂载点>
```

# 导出vmcore

在生产环境下，如果必须要快速恢复环境，且这个环境是可以接受重启系统，就可以尝试手动导出vmcore，vmcore中的信息有时对分析问题很有帮助：
```sh
echo 1 > /proc/sys/kernel/sysrq
echo c > /proc/sysrq-trigger
```

关于vmcore的更详细内容，请查看[《Linux内核课程》](https://chenxiaosong.com/courses/kernel.html)。

# 非特权源端口挂载

默认情况下，nfs挂载使用的源端口是小于1024的特权端口（Privileged Ports），需要root权限。

但在某些情况下，无法挂载时，可以尝试使用大于1024的非特权端口挂载，这对排查问题很有帮助。

首先，server端的`/etc/exports`文件中对导出路径增加`insecure`选项，如：
```sh
/tmp/ *(rw,no_root_squash,fsid=0,insecure)
```

重启server端服务：
```sh
systemctl restart nfs-server.service
```

client端挂载选项指定`noresvport`：
```sh
mount -t nfs -o vers=4.2,noresvport ${server_ip}:/ /mnt
```

请注意，使用非特权源端口挂载在一些场景下是不安全的（从server端的配置选项`insecure`就能看出），尽量只在调试场景下使用。

在我曾经定位过的nfs问题中，有碰到过路由器或交换机出于产品的某些原因，把小于1024的端口的数据包都给过滤了，当时就是使用非特权源端口挂载的方法排除其他可能性，最终定位出问题。
