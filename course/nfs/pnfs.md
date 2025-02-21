# 文档

- [PNFS Development - Linux NFS](https://chenxiaosong.com/src/translation/nfs/pnfs-development.html)
- [pnfs.com](https://chenxiaosong.com/src/translation/nfs/pnfs.com.html)
- block layout: [January 2010 rfc5663 Parallel NFS (pNFS) Block/Volume Layout](https://www.rfc-editor.org/rfc/rfc5663), [July 2012 rfc6688 Parallel NFS (pNFS) Block Disk Protection](https://www.rfc-editor.org/rfc/rfc6688)
- flexible file layout: [August 2018 rfc8435 Parallel NFS (pNFS) Flexible File Layout](https://www.rfc-editor.org/rfc/rfc8435)
- object layout （已废弃）: [January 2010 rfc5664 Object-Based Parallel NFS (pNFS) Operations](https://www.rfc-editor.org/rfc/rfc5664)
- file layout （没有用户需求）: [August 2020 rfc8881 nfsv4.1](https://www.rfc-editor.org/rfc/rfc8881)

# 我和社区的邮件交流

[Question about pNFS documentation](https://lore.kernel.org/all/BA2DED4720A37AFC+88e58d9e-6117-476d-8e06-1d1a62037d6d@chenxiaosong.com/)

## 有没有详细的pNFS环境搭建指导文档?

[Chuck Lever 回复内容](https://lore.kernel.org/all/08BB98A6-FA14-4551-B977-8BC4029DB0E1@oracle.com/)翻译如下:
```
我不知道除了你这里列出的文档以外，还有没有其他最新的文档。

请注意，Linux NFS客户端实现了file、block和flexfile layout类型，但Linux NFS服务器仅实现了pNFS block layout类型。

我一直在构建测试，旨在每次发布NFSD时运行这些测试，以检验Linux NFS服务器和客户端对pNFS block layout的支持，因为pNFS block是我们的客户端和服务器之间的共同点。

请查看[1]顶部的9个提交。这些提交包含对kdevops的更改，增加了它设置iSCSI target并在其本地NFS服务器上启用pNFS的能力。如果你能阅读Ansible脚本，这些可能会帮助你形成使用Linux NFS实现及其iSCSI target和initiator来设置你自己环境的配方。

管理员文档（除了kdevops之外）还在待办事项列表中，但尚未开始。

[1] https://github.com/chucklever/kdevops/tree/pnfs-block-testing
```

注意邮件中说的[chucklever/kdevops/tree/pnfs-block-testing)](https://github.com/chucklever/kdevops/tree/pnfs-block-testing)顶部的9个提交也是[linux-kdevops/kdevops](https://github.com/linux-kdevops/kdevops)中的以下几个记录:
```sh
9f42f09 docs: Fill out docs/nfs.md
687ed7f fstests: Enable testing with pNFS block layouts
976a759 pynfs: Enable testing with pNFS block layouts
9024573 gitr: Enable testing with pNFS block layouts
f391aed nfsd_add_export: Enable pnfs on capable exports
1dcae17 nfsd: Provision an iSCSI initiator on the kdevops NFS server
af043aa iscsi: Provision a target node to host iSCSI LUNs
6cc895a Shorten the names of devices where exports reside
2172d8e nfsd_add_export: Move storage allocation to separate YML files
```

## 除了block layout外，nfs server有没计划实现其他的layout?

[Chuck Lever 回复内容](https://lore.kernel.org/all/1D4505F5-1923-4E7B-A12B-F1E05308914C@oracle.com/)翻译如下:
```
object layout类型已经被弃用。如果我没记错的话，Linux NFS 客户端几年前就移除了对该类型的支持。服务器端也不计划支持它。

file layout类型通常需要一个集群文件系统作为后端。你可以在 Ceph 或 gfs2 上构建一些东西，但这将是一个重大努力，并且需要用户需求。目前没有任何需求。

NFS 服务器有一个玩具级的 flexfile layout实现，仅仅是一个概念验证。我们确实有一个未规划的待办事项，即研究如何将其扩展以提供测试客户端 flexfile 支持的平台。但这个工作不是优先任务。
```

# 现状

客户端:

- 实现了file, block, flexfile layout的支持，object layout已经废弃（已移除支持）。
- 使用指导文档少，使用很麻烦。

服务端:

- block layout实现较完善，[linux-kdevops/kdevops](https://github.com/linux-kdevops/kdevops)仓库有测试用例。
- flexfile layout有初步的实现（概念验证阶段），待扩展。
- file layout（无用户需求）和object layout（已废弃）不打算实现。

# 简介

pNFS的网络结构图如下:
```sh
+---------+                                          
| +---------+
| | +---------+                             +---------+
| | |         |            pNFS             |  meta   |
+-| | clients |<--------------------------->|  data   |
  +-|         |                             | server  |
    +---------+                             +---------+
       ^ ^ ^                                     ^     
       | | |                                     | 
       | | |                                     | 
       | | |                                     | 
       | | |                                     | 
       | | | storage                             | 
       | | | protocol  +---------+               | 
       | | +---------->| +---------+             |     
       | +------------>| | +---------+  control  |
       +-------------->| | |  data   |  protocol |
                       | | |  server |<----------+
                       +-| |(storage |      
                         +-| devices)|
                           +---------+
```

- pNFS: client和meta data server的通信协议。meta data server 保存文件的布局结构（layout），layout是对文件在data server中存储方式的一种说明，也就是元数据。
- storage protocol: 我们只关心 block layout 和 flexfile layout。
- control protocol: 不属于pNFS的范围。对block layout来说是iSCSI。