# 要求

- 当nfs getattr整体执行时间超过1秒时，才输出结果。
- 统计网络等待时间或者rpc锁等待时间。

# 解决方案

先用shell脚本`stat`命令的内核栈，再使用bpftrace脚本探测。

## shell脚本

```sh
#!/bin/bash

INTERFACE_NAME=eth0

# 启动 `stat /mnt` 命令，并获取它的PID
stat /mnt &
STAT_PID=$!

tcpdump --interface=$INTERFACE_NAME --buffer-size=20480 -w out.cap &
TCPDUMP_PID=$!
# 使用 `sleep 1` 等待一秒钟
sleep 1

kill -9 $TCPDUMP_PID

# 检查 `stat /mnt` 是否仍在运行
if ps -p $STAT_PID > /dev/null; then
    echo "stat /mnt 卡住，输出内核栈: "
    # 如果仍在运行，输出该进程的内核栈
    cat /proc/$STAT_PID/stack
else
    rm out.cap
    echo "stat /mnt 正常完成。"
fi
```

抓取到如下栈:
```sh
[<0>] __rpc_execute+0xe0/0x3e0 [sunrpc]
[<0>] rpc_run_task+0x109/0x150 [sunrpc]
[<0>] rpc_call_sync+0x50/0x90 [sunrpc]
[<0>] nfs3_rpc_wrapper.constprop.14+0x2f/0x90 [nfsv3]
[<0>] nfs3_proc_getattr+0x58/0xb0 [nfsv3]
[<0>] __nfs_revalidate_inode+0xff/0x330 [nfs]
[<0>] nfs_getattr+0x141/0x2d0 [nfs]
[<0>] vfs_statx+0x89/0xe0
[<0>] __do_sys_newlstat+0x39/0x70
[<0>] do_syscall_64+0x5b/0x1d0
[<0>] entry_SYSCALL_64_after_hwframe+0x44/0xa9
```

## bpftrace脚本

没用上，但这里也记录一下。

```sh
kprobe:nfs3_proc_getattr
{
        @start[tid] = nsecs;
}

kretprobe:nfs3_proc_getattr
{
        $us = (nsecs - @start[tid]) / 100;
        printf("duration %d\n", $us);
        delete(@start[tid]);
}
```

# 结论

抓包数据显示，`FSSTAT`请求的回复超过1秒。