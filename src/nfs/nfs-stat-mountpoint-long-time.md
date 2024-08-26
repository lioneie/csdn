# 要求

- 当nfs getattr整体执行时间超过1秒时，才输出结果。
- 统计网络等待时间或者rpc锁等待时间。

# 解决方案

先用shell脚本`stat`命令的内核栈，再使用bpftrace脚本探测。

## shell脚本

```sh
#!/bin/bash

# 启动 `stat /mnt` 命令，并获取它的PID
stat /mnt &
STAT_PID=$!

# 使用 `sleep 1` 等待一秒钟
sleep 1

# 检查 `stat /mnt` 是否仍在运行
if ps -p $STAT_PID > /dev/null; then
    echo "stat /mnt 卡住，输出内核栈："
    # 如果仍在运行，输出该进程的内核栈
    cat /proc/$STAT_PID/stack
else
    echo "stat /mnt 正常完成。"
fi
```

## bpftrace脚本

```sh
kprobe:nfs4_proc_getattr
{
        @start[tid] = nsecs;
}

kretprobe:nfs4_proc_getattr
{
        $us = (nsecs - @start[tid]) / 100;
        printf("duration %d\n", $us);
        delete(@start[tid]);
}
```