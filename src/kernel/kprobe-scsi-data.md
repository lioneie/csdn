这篇文章介绍一个block层相关的概率极低的问题的定位方法。

# 问题描述

存储盘数据读写过程中，发现个别存储盘发生了几个字节的数据错误，从应用层一直定位到block层，最终确定数据错误是发生在存储盘的驱动，存储盘的驱动已经不属于内核领域了，驱动问题怎么解决我们不讨论，这里只说block层是怎么确定没问题的。

测试过程是:

1. 往存储盘的特定位置写文件。
2. 清除缓存。
3. 把文件内容读回来比较。
4. 概率性的出现几个字节的数据错误。

# 问题定位

文件`file-expect`用于读取预期的数据内容，另一个文件`file`在第三个page的开始处有3个字节数据错误。
```sh
dd if=/dev/random of=file-expect bs=1048576 count=40 # 生成40M大小的数据随机的文件
cp file-expect file
debugfs /dev/sda
debugfs:  stat file        # (0-10239):45056-55295
dd if=file-expect of=3rd-right bs=1 skip=8192 count=4096 # 生成4K大小的文件 3rd-right，第三个正确的页数据
dd if=/dev/zero of=wrong-1page bs=1 count=4096 # 生成4K大小的文件wong-1page，全是0，错误的页数据

dd if=wrong-1page of=/dev/sda2 bs=1 seek=184557568 count=3 # 写第3个错误的页，45056 * 4096 + 8192，只写3个字节
echo 3 > /proc/sys/vm/drop_caches
```

使用[`kprobe-scsi.c`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/kernel/kprobe-scsi.c)来检测`scsi_dispatch_cmd`（写）和`scsi_finish_command`（读）函数中的数据，与预期的数据内容比较，查看内核日志看看是否能正确识别出错误数据。

[`Makefile`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/kernel/Makefile)。

再把`file`文件内容变成正确的，再查看内核日志:
```sh
dd if=3rd-right of=/dev/sda2 bs=1 seek=184557568 count=4096 # 写第3个正确的页，45056 * 4096 + 8192
dd if=file-expect of=/dev/sda2 bs=4096 seek=45056 count=10240 # 或把 file 重置, 全部正确
```
