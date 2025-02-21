本文档翻译自`BTRFS documentation <https://btrfs.readthedocs.io/en/latest/>`_，大部分借助于ChatGPT翻译，仅作为我个人的参考，如果你想查阅，建议看英文文档，因为我不确定我记录的中文翻译是否完整和正确。

持续更新中。。。

`index.rst <https://github.com/kdave/btrfs-progs/blob/devel/Documentation/index.rst>`_翻译时文件的最新提交是``216c9f0ffb6774afff97df71f248936232df3b16 btrfs-progs: docs: move doc conventions to developer docs``

BTRFS 是一个为 Linux 设计的现代写时复制（Copy on Write，COW）文件系统，旨在实现先进功能，同时重点关注容错性、修复以及简易管理。您可以在介绍中了解更多功能，或从下面的页面中选择。btrfs(8)、mkfs.btrfs(8) 等命令行工具的文档位于手册页面中。

这份文档仍在进行中，尚未完全迁移原始维基 https://btrfs.wiki.kernel.org 的所有内容至此。

介绍
============

`Introduction.rst <https://github.com/kdave/btrfs-progs/blob/devel/Documentation/Introduction.rst>`_翻译时文件的最新提交是``9aafb384cb324f78b0a6f676fb179cf7bbe0b744 btrfs-progs: docs: cross references, ioctl updates``。

BTRFS 是一个为 Linux 设计的现代写时复制（Copy on Write，COW）文件系统，旨在实现先进功能的同时，重点关注容错性、修复以及简易管理。其主要特点和优势包括:

*  不进行完整文件复制的快照功能
*  内置的卷管理，支持软件基础的 RAID 0、RAID 1、RAID 10 等
*  自我修复 - 数据和元数据的校验和，自动检测静默数据损坏

特性概览:

*  基于范围的文件存储
*  2的64次方字节 == 16 EiB: 由于 Linux VFS 的实际限制为 8 EiB，故实际文件大小有限制
*  空间高效的小文件打包
*  空间高效的索引目录
*  动态的 inode 分配
*  可写快照、只读快照、子卷（分离的内部文件系统根）支持
*  数据和元数据的校验和（crc32c、xxhash、sha256、blake2b）
*  压缩（ZLIB、LZO、ZSTD）及其启发式方法
*  集成的多设备支持:

    * 文件分片（类似 RAID0）
    * 文件镜像（类似 RAID1，最多 4 份拷贝）
    * 文件分片+镜像（类似 RAID10）
    * 单和双奇偶性实现（类似 RAID5/6，实验性质，不适用于生产环境）

*  SSD/NVMe（闪存存储）感知性，用于报告可重复使用的空闲块和优化（例如，避免不必要的寻道优化，以及以簇为单位发送写操作）
*  背景扫描过程，用于查找并修复具有冗余拷贝的文件中的错误
*  在线文件系统碎片整理
*  离线文件系统检查
*  现有 ext2/3/4 和 reiserfs 文件系统的原地转换
*  种子设备支持。创建一个（只读）文件系统，作为为其他 Btrfs 文件系统提供模板。原始文件系统和设备被包括为新文件系统的只读起点。使用写时复制，所有修改都存储在不同的设备上；原始文件保持不变。
*  子卷感知的配额支持
*  子卷更改的发送/接收，高效的增量文件系统镜像和备份
*  批处理或带外去重（写入后发生，而非期间）
*  交换文件支持
*  树检查器，读后和写前的元数据验证
*  区域模式支持（适用于 SMR/ZBC/ZNS 的友好分配，在非区域化设备上进行模拟）

状态
======

`Status.rst <https://github.com/kdave/btrfs-progs/blob/devel/Documentation/Status.rst>`_翻译时文件的最新提交是``ac8edc15130ff37d66d68cb9c2f30daa7f60a6b8 btrfs-progs: docs: restyle the landing page``。

概述
--------

要按其引入列出功能，请参见 `更改 (功能/版本) <Feature-by-version>`__。

下表旨在作为 BTRFS 支持的功能稳定性状态的概览。虽然某个功能在功能上可能是安全和可靠的，但这并不一定意味着它有用，例如满足您的特定工作负载的性能期望。功能的组合在性能上可能有所不同，表格不覆盖所有可能性。

**该表基于最新发布的 Linux 内核: 6.6**

每个功能的列反映了以下实现方式的状态:

| *稳定性* - 实现的完整性，用例覆盖
| *性能* - 在达到内在限制之前可以改进多少
| *注释* - 已知问题的简短描述，或与状态相关的其他信息

*图例:*

-  **OK**: 可以安全使用，没有已知的主要缺陷
-  **mostly OK**: 适用于常规使用，有一些已知问题，不影响大多数用户
-  **Unstable**: 除测试目的外，请勿使用，已知的严重问题，某些核心部分的实现缺失

内容太多，不全列出来，详细请查看 https://btrfs.readthedocs.io/en/latest/Status.html 。

手册页
======

`man-index.rst <https://github.com/kdave/btrfs-progs/blob/devel/Documentation/man-index.rst>`_翻译时文件的最新提交是``ee801c07d785760d2ec818d0cb9223211256fc28 btrfs-progs: docs: drop indices from pages``。

请查看: https://btrfs.readthedocs.io/en/latest/man-index.html 。

管理
==============

`Administration.rst <https://github.com/kdave/btrfs-progs/blob/devel/Documentation/Administration.rst>`_翻译时文件的最新提交是``9aafb384cb324f78b0a6f676fb179cf7bbe0b744 btrfs-progs: docs: cross references, ioctl updates``。

BTRFS 文件系统的主要管理工具是 :doc:`btrfs`。
请参考子命令的手册页以获取更多文档。

挂载选项
-------------

TODO: 翻译日期 Fri Dec 22 10:16:52 2023 +0000

挂载选项翻译出来没太大意义，请查看: https://btrfs.readthedocs.io/en/latest/Administration.html#mount-options 。

启动加载程序
-----------

TODO: 翻译日期 Fri Dec 22 10:16:52 2023 +0000

GRUB2 (https://www.gnu.org/software/grub) 对于从 BTRFS 启动具有最先进的支持，特别是在功能方面。

U-Boot (https://www.denx.de/wiki/U-Boot/) 对于启动有相当的支持，但并非所有的 BTRFS 功能都已实现，请查阅文档。

一般而言，每个设备的前 1MiB 未被使用，但主超级块位于偏移 64KiB，并跨越 4KiB。其余部分可以自由地被引导加载程序或其他系统信息使用。请注意，从 :doc:`zoned device<Zoned-mode>` 上的文件系统启动是不支持的。

.. _管理限制:

文件系统限制
-----------------

TODO: 翻译日期 Fri Dec 22 10:16:52 2023 +0000

.. 包括:: ch-fs-limits.rst

.. _管理灵活性:

灵活性
-----------

TODO: 翻译日期 Fri Dec 22 10:16:52 2023 +0000

.. 包括:: ch-flexibility.rst
