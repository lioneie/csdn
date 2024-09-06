本文档翻译自[pNFS block layout server user guide](https://github.com/torvalds/linux/blob/838f9bc02fee68185c1c6e667d6a7ab0eb5948a1/Documentation/admin-guide/nfs/pnfs-block-server.rst)，翻译时文件的最新提交是`838f9bc02fee68185c1c6e667d6a7ab0eb5948a1 Documentation/admin-guide: pnfs-block-server: drop doubled word`，大部分借助于ChatGPT。仅作为我个人的参考，如果你想查阅，建议看英文文档，因为我不确定我的中文翻译是否完整和正确。

# pNFS block layout server user guide

```
Linux NFS服务器现在支持pNFS块布局扩展。在这种情况下，NFS服务器充当pNFS的元数据服务器（MDS），除了处理对NFS导出的所有元数据访问外，还向客户端分发布局，使其能够直接访问与客户端共享的底层块设备。

要在Linux NFS服务器上使用pNFS块布局，导出的文件系统需要支持pNFS块布局（目前仅支持XFS），并且文件系统必须位于客户端和MDS都可以访问的共享存储（通常是iSCSI）上。目前，文件系统需要直接位于导出的卷上，MDS和客户端上的卷条带化或级联尚不支持。

在服务器上，如果文件系统支持它，则会自动启用pNFS块卷支持。在客户端，确保内核启用了CONFIG_PNFS_BLOCK选项，运行来自nfs-utils的blkmapd守护进程，并且文件系统使用NFSv4.1协议版本挂载（mount -o vers=4.1）。

如果nfsd服务器需要隔离一个无响应的客户端，它会调用/sbin/nfsd-recall-failed，第一个参数设置为客户端的IP地址，第二个参数设置为要隔离的文件系统的设备节点，去掉/dev前缀。下面是一个示例文件，显示如何将设备翻译成SCSI EVPD 0x80中的序列号:

cat > /sbin/nfsd-recall-failed << EOF

#!/bin/sh

CLIENT="$1"
DEV="/dev/$2"
EVPD=`sg_inq --page=0x80 ${DEV} | \
        grep "Unit serial number:" | \
        awk -F ': ' '{print $2}'`

echo "fencing client ${CLIENT} serial ${EVPD}" >> /var/log/pnfsd-fence.log
EOF
```