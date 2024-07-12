# 简介

根据[内核仓库文档Documentation/filesystems/btrfs.rst](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/Documentation/filesystems/btrfs.rst)中描述的：
```sh
Btrfs是一个针对Linux的写时复制文件系统，旨在实现先进功能的同时注重容错性、修复和易管理性。由多家公司联合开发，根据GPL许可证授权，并向任何人开放贡献。

Btrfs的主要特性包括：

基于范围的文件存储（最大文件大小为2^64）
对小文件进行高效的空间打包
空间高效的索引目录
动态索引分配
可写的快照
子卷（独立的内部文件系统根）
对象级镜像和条带化
数据和元数据的校验和（支持多种算法）
压缩（支持多种算法）
Reflink，去重
擦拭（在线校验和验证）
分层配额组（支持子卷和快照）
集成多设备支持，带有几种RAID算法
脱机文件系统检查
高效的增量备份和文件系统镜像（发送/接收）
Trim/discard
在线文件系统碎片整理
交换文件支持
分区模式
读/写元数据验证
在线调整大小（收缩、增长）
有关更多信息，请参阅文档网站或维基：

https://btrfs.readthedocs.io

该网站维护了有关管理任务、常见问题、用例、挂载选项、易懂的变更日志、功能、手册页、源代码存储库、联系人等的信息。
```

# 怎么用

```sh
apt install btrfs-progs -y # debian

mkfs.btrfs -f -L 'test1' /dev/sda /dev/sdb
mkfs.btrfs -f -L 'test2' /dev/nvme0n1
btrfs filesystem show # 显示文件系统的相关信息，包括挂载点、设备使用情况、RAID配置等
mount /dev/sda /mnt
btrfs filesystem df /mnt # 显示挂载在 /mnt 上的Btrfs文件系统的磁盘空间使用情况，包括总空间、已用空间、可用空间等

btrfs filesystem resize +10G /mnt # 调整文件系统大小
btrfs quota enable /mnt # 启用Btrfs文件系统的配额功能，这允许你设置对子卷（subvolume）和快照（snapshot）的磁盘配额
btrfs subvolume create /mnt/subvol1 # 子卷是Btrfs中用于组织和管理数据的一种方式
btrfs subvolume delete /mnt/subvol1
btrfs subvolume list /mnt # 查看Btrfs文件系统中的子卷
btrfs subvolume snapshot /mnt/subvol1 /mnt/snapshot1 # 创建一个名为 snapshot1 的快照（snapshot），基于现有的 subvol1 子卷。快照是文件系统的一个只读副本，它记录了在创建快照时文件系统的状态
```
