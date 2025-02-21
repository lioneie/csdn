本文档翻译自[Reference counting in pnfs](https://github.com/torvalds/linux/blob/34e75cf4beb1a88a61b7c76b5fdc99c43cff8594/Documentation/filesystems/nfs/pnfs.rst)，翻译时文件的最新提交是`34e75cf4beb1a88a61b7c76b5fdc99c43cff8594 Documentation: nfs: convert pnfs.txt to ReST`，大部分借助于ChatGPT。仅作为我个人的参考，如果你想查阅，建议看英文文档，因为我不确定我记录的中文翻译是否完整和正确。

# Reference counting in pnfs

```
这些缓存相互关联。我们有布局可以引用多个设备，每个设备可以引用多个数据服务器。每个数据服务器可以被多个设备引用。每个设备可以被多个布局引用。为了理清这一切，我们需要引用计数。
```

## `struct pnfs_layout_hdr`

```
网络命令 LAYOUTGET 对应 struct pnfs_layout_segment，通常用变量名 lseg 来表示。每个 nfs_inode 可能在 nfsi->layout 中持有指向这些布局段缓存的指针，其类型为 struct pnfs_layout_hdr。

我们会在每个引用它的未完成 RPC 调用（如 LAYOUTGET、LAYOUTRETURN 和 LAYOUTCOMMIT）中引用指向它的 inode 的头部，以及每个持有的 lseg。

每个头部在非空时也会被放入与 struct nfs_client（cl_layouts）关联的列表中。将其放入该列表不会增加引用计数，因为布局由将其保留在列表中的 lseg 维护。
```

## `deviceid_cache`

```
LSEG引用设备ID，这些设备ID根据NFS客户端和布局驱动类型进行解析。设备ID保存在RCU缓存（struct nfs4_deviceid_cache）中。缓存本身在每次挂载中被引用。条目（struct nfs4_deviceid）在引用它们的每个LSEG的生命周期内保持存在。

使用RCU是因为设备ID基本上是一种一次写入、多次读取的数据结构。32个桶的哈希表大小需要更好的论证，但考虑到每个文件系统可以有多个设备ID，每个NFS客户端可以有多个文件系统，这似乎是合理的。

哈希代码是从nfsd代码库中复制的。有关哈希和此算法变体的讨论可以在这里找到: http://groups.google.com/group/comp.lang.c/browse_thread/thread/9522965e2b8d3809。
```

## data server cache

```
文件驱动程序设备指的是数据服务器，它们保存在模块级别的缓存中。该引用在指向它的设备 ID 的生命周期内保持有效。
```

## lseg

```
lseg 维护一个额外的引用，该引用对应 NFS_LSEG_VALID 位，并将其保存在 pnfs_layout_hdr 的列表中。当最后一个 lseg 从 pnfs_layout_hdr 的列表中移除时，会设置 NFS_LAYOUT_DESTROYED 位，以防止添加任何新的 lseg。
```

## layout drivers

```
PNFS 使用被称为布局驱动程序的东西。STD 定义了四种基本的布局类型: "文件"、"对象"、"块" 和 "flexfiles"。对于每种类型都有一个布局驱动程序，并带有一个通用的函数向量表，由 nfs 客户端 pnfs 核心调用来实现不同的布局类型。

文件布局驱动程序代码位于: fs/nfs/filelayout/.. 目录
块布局驱动程序代码位于: fs/nfs/blocklayout/.. 目录
Flexfiles 布局驱动程序代码位于: fs/nfs/flexfilelayout/.. 目录
```

## blocks-layout setup

```
TODO: 记录块布局驱动程序的设置需求
```