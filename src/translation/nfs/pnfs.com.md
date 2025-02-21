本文档翻译自[pnfs.com](http://www.pnfs.com/)，大部分借助于ChatGPT。仅作为我个人的参考，如果你想查阅，建议看英文文档，因为我不确定我记录的中文翻译是否完整和正确。

并行 NFS（pNFS）是 NFS v4.1 标准的一部分，它允许计算客户端直接并行访问存储设备。pNFS 架构消除了与当前部署的 NFS 服务器相关的可扩展性和性能问题。这是通过将数据和元数据分离，并将元数据服务器移出数据路径来实现的。

pNFS 消除了传统 NAS 解决方案的性能瓶颈: 在[pnfs.com](http://www.pnfs.com/)查看图片。

“基于 pNFS 的并行存储是超越集群 NFS 存储的下一个演进阶段，也是行业解决存储和 I/O 性能瓶颈的最佳方式。Panasas 是第一个识别到生产级、标准并行文件系统需求的公司，并在部署商业并行存储解决方案方面拥有前所未有的经验。” - Robin Harris，数据流动集团(Data Mobility Group)

# 简介

高性能数据中心已经积极向并行技术（如集群计算和多核处理器）迈进。虽然这种对并行性的增加克服了绝大多数计算瓶颈，但它将性能瓶颈转移到了存储 I/O 系统上。为了确保计算集群提供最大性能，存储系统必须针对并行性进行优化。基于 NFS v4.0 及更早版本的传统网络附加存储（NAS）架构在与大规模、高性能计算集群结合使用时存在严重的性能瓶颈和管理挑战。

一些存储行业技术领导者联合创建了并行 NFS（pNFS）协议，作为 NFS v4.1 标准的可选扩展。pNFS 采用了一种不同的方法，允许计算客户端直接读写存储，消除了存储控制器的性能瓶颈，并使单个文件系统的容量和性能线性扩展。

# NFS 面临的挑战

要理解 pNFS 如何工作，首先需要了解在典型的 NFS 架构中，当客户端尝试访问文件时会发生什么。传统的 NFS 架构包括一个放置在磁盘驱动器前面并通过 NFS 导出文件系统的文件头。当大量客户端要访问数据时，或者数据集变得过大时，NFS 服务器很快就会成为瓶颈，并且显著影响系统性能，因为 NFS 服务器位于客户端计算机和物理存储设备之间的数据路径上。

在[pnfs.com](http://www.pnfs.com/)查看图片。

# NFS 性能

pNFS 通过允许计算客户端直接并行读写数据，与物理存储设备之间的数据读写，消除了传统 NAS 系统中的性能瓶颈。NFS 服务器仅用于控制元数据和协调访问，允许大量客户端从非常大的数据集中获得非常快速的访问。

当客户端要访问文件时，首先向元数据服务器查询，获取数据位置地图以及关于其读取、修改和写入数据权限的凭证。一旦客户端拥有这两个组件，它在访问数据时就直接与存储设备通信。传统 NFS 中的每一位数据都经过 NFS 服务器 —— 而在 pNFS 中，NFS 服务器被移出了主要的数据路径，从而实现了对数据的自由快速访问。NFS 的所有优势都得以保留，但瓶颈被消除，并且数据可以并行访问，从而实现非常快速的吞吐率；系统容量可以轻松扩展，而不影响总体性能。

# 为什么 pNFS 重要？

pNFS 的重要性在于它将并行 I/O 的优势与网络文件系统 (NFS) 的普遍标准的优势结合在一起。这将允许用户在存储基础设施中体验到增加的性能和可扩展性，同时保证他们的投资安全，并确保他们选择最佳解决方案的能力仍然完整。

在网络文件系统方面，NFS 是通信协议标准。它在当前的高性能计算 (HPC) 和企业市场中被广泛使用。pNFS 标准对供应商和客户都具有吸引力。它使以 HPC 为中心的存储供应商（如 Panasas）能够将之前只通过专有协议提供的优势带入 NFS 市场。它还使以企业为重点的存储供应商能够更深入地进入 HPC 市场。因此，对于供应商来说，它拓宽了市场。对于客户来说，这意味着更多的选择和竞争来赢得他们的业务。它还使客户能够通过将 pNFS 作为标准 NAS 协议来标准化他们的 IT 环境。

并行 I/O 的优势包括:

- 提供非常高的应用程序性能
- 允许在没有性能降低的情况下进行大规模扩展
- 利用可用带宽
- 使用多个客户端将流增加到并行存储
- 能够进行更大规模的计算，以扩展集群

# pNFS 规范

## NFSv4 工作组的 pNFS RFC 文档

NFS4.1 标准文档很大，因为它包括了对 NFSv4 的完整描述以及新的 4.1 特性。还有两个伴随文档，描述了 pNFS 存储的对象布局和块布局。

- [RFC 5661](https://datatracker.ietf.org/doc/html/rfc5661) - 描述了 NFS 版本 4 的小版本 1，包括从基础协议保留的特性以及后续进行的协议扩展。
- [RFC 5662](https://datatracker.ietf.org/doc/html/rfc5662) - 包含了协议的机器可读的 XDR 定义。
- [RFC 5663](https://datatracker.ietf.org/doc/html/rfc5663) - 提供了一个基于块的布局类型定义的规范，用于与 NFSv4.1 协议一起使用。因此，这是 NFS 版本 4 的小版本 1 的伴随规范。
- [RFC 5664](https://datatracker.ietf.org/doc/html/rfc5664) - 提供了一个基于对象的布局类型定义的规范，用于与 NFSv4.1 协议一起使用。因此，这是 NFS 版本 4 的小版本 1 的伴随规范。

## 下载pNFS的源代码

从[linux-nfs.org](http://wiki.linux-nfs.org/wiki/index.php/PNFS_Development_Git_tree)（根据GNU通用公共许可证第2版提供）和opensolaris.org（根据OpenSolaris二进制许可证提供）下载pNFS启用的Linux内核的最新开发源代码。

- [NFSv4概述](http://www.snia.org/sites/default/files/SNIA_An_Overview_of_NFSv4-3_0.pdf)
- [NFS V4.1规范（NFS V4状态页面）](http://tools.ietf.org/wg/nfsv4/)
- [pNFS问题陈述](http://www.pdl.cmu.edu/pNFS/archive/gibson-pnfs-problem-statement.html)，Garth Gibson（Panasas），Peter Corbett（Netapp），互联网草案，2004年7月
- [Linux pNFS内核开发（CITI）](http://www.citi.umich.edu/projects/asci/pnfs/linux/)
- [开源NFS V4参考实现（CITI）](http://www.citi.umich.edu/projects/nfsv4/)