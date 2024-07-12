本文档翻译自[pNFS SCSI layout server user guide](https://github.com/torvalds/linux/blob/e70cc7122d8ebf919628de6c2d7bb69fff05d176/Documentation/admin-guide/nfs/pnfs-scsi-server.rst)，翻译时文件的最新提交是`e70cc7122d8ebf919628de6c2d7bb69fff05d176 Documentation/admin-guide: pnfs-scsi-server: drop doubled word`，大部分借助于ChatGPT。仅作为我个人的参考，如果你想查阅，建议看英文文档，因为我不确定我的中文翻译是否完整和正确。

# pNFS SCSI layout server user guide

```
本文档描述了Linux NFS服务器对pNFS SCSI布局的支持。使用pNFS SCSI布局时，NFS服务器充当pNFS的元数据服务器（MDS），除了处理对NFS导出的所有元数据访问外，还向客户端分发布局，使其能够直接访问与客户端共享的底层SCSI LUN。

要在Linux NFS服务器上使用pNFS SCSI布局，导出的文件系统需要支持pNFS SCSI布局（目前仅支持XFS），并且文件系统必须位于客户端和MDS都可以访问的SCSI LUN上。目前，文件系统需要直接位于导出的LUN上，MDS和客户端上的LUN条带化或级联尚不支持。

在使用CONFIG_NFSD_SCSI构建的服务器上，如果文件系统使用“pnfs”选项导出并且底层SCSI设备支持持久保留，则会自动启用pNFS SCSI卷支持。在客户端，确保内核启用了CONFIG_PNFS_BLOCK选项，并且文件系统使用NFSv4.1协议版本挂载（mount -o vers=4.1）。
```