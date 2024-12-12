# 描述

执行以下命令:
```sh
fallocate -l 10M image
mkfs.ext2 -F image
mount -t ext2 image /mnt
cd /mnt && vim file
umount --lazy /mnt
```

这时，通用的一些命令如`df`、`mount`等看不到挂载实例，也无法看到哪些进程正在使用挂载点。

# 调试

通过命令`strace -o strace.txt -f -v -s 4096 <df/mount>`可以知道，`df`、`mount`命令都是读取`/proc/self/mountinfo`文件。

以下命令查询进程:
```sh
# +D：递归地列出指定目录下所有打开的文件
lsof +D /mnt # List Open Files
# -m：表示查询挂载点（而不仅仅是某个文件）
fuser -mv /mnt # file user, 显示哪些进程正在访问特定文件、目录或文件系统
```

## 未执行`umount --lazy /mnt`

`lsof +D /mnt`输出如下:
```sh
COMMAND  PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
bash    2924 root  cwd    DIR    7,0     1024    2 /mnt
vim     3038 root  cwd    DIR    7,0     1024    2 /mnt
vim     3038 root    3u   REG    7,0    12288   15 /mnt/.file.swm
```

通过`strace`命令可知，是通过以下方式获取:
```sh
ls /proc/2924/cwd -lh # /proc/2924/cwd -> /mnt
ls /proc/3038/cwd -lh # /proc/3038/cwd -> /mnt
ls /proc/3038/fd/3 -lh # 3 -> /mnt/.file.swm
```

`fuser -mv /mnt`输出如下:
```sh
                     USER        PID ACCESS COMMAND
/mnt:                root     kernel mount /mnt
                     root       2924 ..c.. bash
                     root       3038 F.c.. vim
```

通过`strace`命令可知，是通过以下方式获取:
```sh
cat /proc/mounts
statx(0, "/mnt", ..., stx_mnt_id=0x46}) = 0
statx(0, "/proc/2924/cwd", ..., stx_mnt_id=0x46}) = 0
statx(0, "/proc/3038/cwd", ..., stx_mnt_id=0x46}) = 0
statx(0, "/proc/3038/fd/3", ..., stx_mnt_id=0x46}) = 0

ls /proc/3038/fd/3 -lh # 3 -> /mnt/.file.swm
```

## 执行`umount --lazy /mnt`后

```sh
ls /proc/2924/cwd -lh # /proc/2924/cwd -> /
ls /proc/3038/cwd -lh # /proc/3038/cwd -> /
ls /proc/3038/fd/3 -lh # /proc/3038/fd/3 -> /.file.swm
```

```sh
cat /proc/mounts
statx(0, "/", ..., stx_mnt_id=0x16}) = 0
statx(0, "/mnt", ..., stx_mnt_id=0x16}) = 0
statx(0, "/proc/2924/cwd", ..., stx_mnt_id=0x46}) = 0
statx(0, "/proc/3038/cwd", ..., stx_mnt_id=0x46}) = 0
statx(0, "/proc/3038/fd/3", ..., stx_mnt_id=0x46}) = 0
```

# 代码分析

