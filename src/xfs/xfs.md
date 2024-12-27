# `xfs_filesystem_structure.pdf`

- [英文 xfs_filesystem_structure.pdf](https://mirrors.edge.kernel.org/pub/linux/utils/fs/xfs/docs/xfs_filesystem_structure.pdf)
- [文档git仓库](https://git.kernel.org/pub/scm/fs/xfs/xfs-documentation.git)
- [pdf文档翻译请查看百度网盘](https://chenxiaosong.com/baidunetdisk)

<!-- https://zorrozou.github.io/docs/xfs/ -->
# xfs磁盘结构

```sh
+-------+-------+-------+-------+--------+
|  sb   |  agf  |  agi  |  agfl |  free  |
| (512) | (512) | (512) | (512) | (2048) |
+-------+-------+-------+-------+--------+
```

- sb: 超级块，`xfs_sb_5`
- agf: block索引的相关重要信息, `xfs_agf_t`
- agi: inode索引的相关重要信息, `xfs_agi_t`
- agfl: freelist（空闲块列表）结构信息，`xfs_agfl_t`

```sh
xfs_info image

xfs_db image
xfs_db> sb
xfs_db> p # 打印当前选择的结构的内容
xfs_db> sb
xfs_db> addr # 显示当前选择的结构的地址
# 块大小为4096时，后面的2048字节未被占用
xfs_db> fsblock 0 # 设置当前操作的文件系统块地址，这个命令允许你直接访问和操作文件系统中的特定块
xfs_db> p
xfs_db> type sb # 将当前选择的结构类型设置为超级块，这意味着接下来的操作将针对超级块进行
xfs_db> p
xfs_db> agf 0 # 选择第 0 个分配组（Allocation Group, AG）的分配组文件头（AGF）进行操作
xfs_db> addr
xfs_db> agi 0
xfs_db> addr
xfs_db> agfl 0
xfs_db> addr
xfs_db> agf   # 选择当前的分配组文件头
xfs_db> p     # 打印当前选择的 AGF 的内容
xfs_db> fsblock 1
xfs_db> type text
xfs_db> p
xfs_db> fsblock 2
xfs_db> type text
xfs_db> p
```

# 工具软件

<!-- https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/8/html/managing_file_systems/comparison-of-tools-used-with-ext4-and-xfs_getting-started-with-an-ext4-file-system -->

- `xfs_metadump -o image-file meta-file`: 将 XFS 文件系统元数据复制到文件中。选项`-o`表示禁用文件名和扩展属性的混淆。
- `xfs_mdrestore meta-file restore-file`: 将 XFS 元数据转储映像恢复到文件系统映像中。
- `xfs_db -r image-file`: 调试xfs文件系统，`-r`表示只读。
- `xfs_logprint -n image-file`: 打印xfs日志。选项`-n`表示不尝试解释日志数据，只解释日志头信息。
- `xfs_info`: 查看xfs的布局信息。
