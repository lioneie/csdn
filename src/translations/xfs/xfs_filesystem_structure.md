本文翻译自[xfs_filesystem_structure.pdf](https://mirrors.edge.kernel.org/pub/linux/utils/fs/xfs/docs/xfs_filesystem_structure.pdf)，大部分借助于ChatGPT翻译，仅作为我个人的参考，如果你想查阅，建议看英文文档，因为我不确定我记录的中文翻译是否完整和正确。

<!-- 翻译时告诉chatgpt: 翻译成中文，标点符号结尾的换行后面是一个新段落，非标点符号结尾的换行忽略 -->

# Part I High Level Design

XFS是一种高性能文件系统，旨在最大化并行吞吐量，并可扩展到极大的64位存储系统。最初由SGI于1993年10月为IRIX开发，XFS能够处理大文件、大文件系统、许多索引节点、大目录、大文件属性和大分配。文件系统通过将存储设备分割成半自治分配组来优化并行访问。XFS采用分支树（B+树）来加速对大型列表的搜索；它还使用延迟的基于范围的分配来提高数据连续性和IO性能。

本文档描述了XFS文件系统的磁盘布局以及如何使用调试工具xfs_db和xfs_logprint来检查元数据结构。它还描述了磁盘上的元数据与更高级别的设计目标之间的关系。

本文档中的信息来自于Linux内核中XFS源代码，版本为v4.3。本书的源代码可在 [kernel/git/djwong/xfs-documentation.git](https://git.kernel.org/pub/scm/linux/kernel/git/djwong/xfs-documentation.git/tree/) 获得。

反馈应发送到XFS邮件列表，目前为linux-xfs@vger.kernel.org。

> 注意：XFS元数据结构中的所有字段都采用大端字节顺序，除了以主机顺序格式化的日志项。

# Chapter 1 Overview

XFS向用户呈现了一个标准的Unix文件系统接口：一个根目录树，包含目录、文件、符号链接和设备。这五种实体在文件系统内部都由索引节点或“inode”表示；每个节点都由一个唯一的inode编号引用。目录由（名称，inode编号）元组组成，多个元组可以包含相同的inode编号。数据块通过每个索引节点中的块映射与文件关联。还可以将（键，值）元组附加到任何索引节点上；这些被称为“扩展属性”，超出了标准的Unix文件属性。

在内部，XFS文件系统被划分为若干大小相等的块，称为分配组（AG）。每个AG几乎可以被认为是一个单独的文件系统，它维护着自己的空间使用情况、索引节点和其他次要元数据。拥有多个AG使得XFS能够在并发访问增加时并行处理大多数操作而不降低性能。每个分配组使用多个B+树来维护诸如空闲块的位置、已分配的inode的位置和空闲inode的位置等记账记录。

文件、符号链接和目录可以有最多两个块映射，或“分支”，将文件或目录与特定的文件系统块关联起来。“属性分支”跟踪用于存储和索引扩展属性的块，而“数据分支”跟踪文件数据块、符号链接目标或目录块，具体取决于inode记录的类型。两个分支都将逻辑偏移量与一组物理块相关联，从而实现了稀疏文件和目录。目录条目和扩展属性包含在由分支映射的块中的第二级数据结构内。此结构由可变长度的目录或属性记录组成，并且可能包含第二个B+树来索引这些记录。

XFS采用了一个日志记录日志，在其中收集元数据更改，以便在发生崩溃时可以原子方式执行文件系统操作。此外，还有一个实时设备的概念，其中分配更简单地跟踪，并且以更大的块来减少分配延迟的抖动。

# Chapter 2 Metadata Integrity

## Introduction

XFS面临的最大可扩展性问题不是算法可扩展性的问题，而是文件系统结构的验证问题。磁盘上的结构和索引的可扩展性以及用于迭代它们的算法足以支持具有数十亿索引节点的PB级文件系统，然而正是这种可扩展性导致了验证问题。

几乎所有 XFS 上的元数据都是动态分配的。唯一固定位置的元数据是分配组头（SB、AGF、AGFL 和 AGI），而所有其他元数据结构都需要通过不同的方式遍历文件系统结构才能发现。虽然用户空间工具已经可以验证和修复结构，但它们能够验证的范围是有限的，这反过来限制了 XFS 文件系统的支持大小。

例如，完全可以手动使用 xfs_db 和一些脚本来分析一个 100TB 文件系统的结构，以确定损坏问题的根本原因，但仍然主要是手动验证诸如单比特错误或错误写入是否是造成损坏事件的最终原因。进行这种法医分析可能需要几个小时到几天的时间，因此在这种规模上进行根本原因分析是完全可能的。

然而，如果我们将文件系统扩展到 1PB，现在我们有了10倍的元数据需要分析，因此分析工作时间将会增加到几周甚至几个月的法医工作。大部分的分析工作是缓慢而繁琐的，所以随着分析量的增加，导致原因被淹没在噪音中的可能性也越来越大。因此，支持PB级别的文件系统的主要关注点是尽量减少对文件系统结构进行基本法医分析所需的时间和精力。

因此，版本 5 磁盘格式为所有元数据类型引入了更大的头部，使文件系统能够更严格地检查从磁盘读取的信息。元数据完整性字段现在包括：

- 魔数，用于分类所有类型的元数据。这与 v4 版本相同。
- 文件系统 UUID 的副本，用于确认给定的磁盘块与超级块相连。
- 拥有者，以避免访问属于文件系统其他部分的元数据。
- 文件系统块编号，用于检测错误的写入位置。
- 上次写入该块的日志序列号，以避免重放过时的日志条目。
- 整个块的 CRC32c 校验和，用于检测轻微的损坏。

元数据完整性覆盖范围已扩展到文件系统中的所有元数据块，具体如下：

- 在目录树中，索引节点可以有多个“拥有者”；因此记录中包含索引节点号而不是拥有者或块号。
- 超级块没有拥有者。
- 磁盘配额文件没有拥有者或块号。
- 文件拥有的元数据将索引节点号列为拥有者。
- 每个分配组数据和B+树块将分配组号列为拥有者。
- 每个分配组头部扇区不列出拥有者或块号，因为它们具有固定位置。
- 远程属性块不会被记录，因此 LSN 必须为 -1。

这个功能使得 XFS 能够决定块内容是否如此意外，以至于它应该立即停止。不幸的是，校验和不允许自动修正。请像往常一样定期备份。

## Self Describing Metadata

当前元数据格式的一个问题是，除了元数据块中的魔数之外，我们没有其他方法来确定它应该是什么。我们甚至无法确定它是否在正确的位置。简而言之，你不能孤立地查看一个单独的元数据块并说“是的，它应该在那里，内容是有效的”。

因此，法医分析中大部分时间都花在对元数据值进行基本验证上，寻找在范围内但不正确的值（因此无法被自动验证检查检测到）。找到并理解诸如交叉链接的块列表（例如，在B树中的兄弟指针最终形成了循环）之类的事物是理解出了什么问题的关键，但是事后无法确定块的链接顺序或写入磁盘的顺序。

因此，我们需要在元数据中记录更多信息，以便我们能够快速确定元数据是否完好，并且可以在分析目的上忽略它。我们无法防范每种可能的错误，但我们可以确保常见类型的错误是容易可检测的。因此，自描述元数据的概念应运而生。

自描述元数据的第一个基本要求是元数据对象在一个众所周知的位置包含某种形式的唯一标识符。这使我们能够识别块的预期内容，从而解析和验证元数据对象。如果我们不能独立识别对象中的元数据类型，那么元数据就不能很好地描述它自己了！

幸运的是，几乎所有的XFS元数据都已经嵌入了魔数——只有AGFL、远程符号链接和远程属性块没有包含识别魔数。因此，我们可以通过改变这些对象的磁盘格式来添加更多的识别信息，并通过简单地改变元数据对象中的魔数来检测这一点。也就是说，如果它有当前的魔数，则元数据不是自我识别的。如果它包含新的魔数，则是自我识别的，我们可以在运行时、法医分析或修复期间对元数据对象进行更广泛的自动化验证。

作为主要关注点，自描述元数据需要某种形式的整体完整性检查。如果我们不能验证元数据没有因外部影响而发生改变，就不能信任元数据。因此，我们需要某种形式的完整性检查，这是通过向元数据块添加CRC32c验证来完成的。如果我们能够验证该块包含预期包含的元数据，则可以跳过大量手动验证工作。

由于XFS中的元数据长度不能超过64k，因此选择了CRC32c，32位CRC足以检测元数据块中的多位错误。现在常见的CPU都支持硬件加速CRC32c，所以它的速度很快。虽然CRC32c并不是最强的完整性检查，但它完全满足我们的需求，并且开销相对较小。增加对更大完整性字段和/或算法的支持并不会比CRC32c带来更多的价值，反而会增加很多复杂性，因此没有更改完整性检查机制的规定。

自描述元数据需要包含足够的信息，以便可以在不查看其他元数据的情况下验证元数据块是否在正确的位置。这意味着它需要包含位置信息。仅仅向元数据添加一个块号不足以防止错误定向写入——写入可能会被错误定向到错误的LUN，从而写入到错误文件系统的“正确块”。因此，位置信息必须包含文件系统标识符以及块号。

法医分析中的另一个关键信息点是知道元数据块属于谁。我们已经知道了类型、位置、有效性和/或损坏状态，以及最后修改时间。知道块的所有者很重要，因为它可以让我们找到其他相关的元数据，以确定损坏的范围。例如，如果我们有一个extent btree对象，我们不知道它属于哪个inode，因此必须遍历整个文件系统以找到块的所有者。更糟的是，损坏可能意味着找不到任何所有者（即它是一个孤儿块），因此如果元数据中没有所有者字段，我们无法了解损坏的范围。如果元数据对象中有所有者字段，我们可以立即进行自上而下的验证，以确定问题的范围。

不同类型的元数据有不同的所有者标识符。例如，目录、属性和extent树块都由一个inode拥有，而空闲空间btree块由一个分配组拥有。因此，所有者字段的大小和内容取决于我们所查看的元数据对象的类型。所有者信息还可以识别错误定向的写入（例如，空闲空间btree块写入错误的分配组）。

自描述元数据还需要包含一些指示其何时写入文件系统的信息。在进行法医分析时，一个关键信息点是该块最近的修改时间。基于修改时间相关性分析一组损坏的元数据块很重要，因为它可以指示这些损坏是否相关，是否存在导致最终失败的多个损坏事件，甚至是否存在运行时验证未检测到的损坏。

例如，通过查看包含块的空闲空间btree块的最后写入时间与元数据对象本身的最后写入时间，可以确定元数据对象是应该是空闲空间还是仍然被其所有者引用。如果空闲空间块比对象和对象的所有者更近期，那么很有可能该块应该已从所有者中移除。

为了提供这个“写入时间戳”，每个元数据块都会记录最后一次修改它的事务的日志序列号（LSN）。这个数字在文件系统的生命周期中会不断增加，唯一会重置它的是运行xfs_repair修复文件系统。此外，通过使用LSN，我们可以判断损坏的元数据是否属于同一日志检查点，从而大致了解在第一次和最后一次损坏元数据实例之间发生了多少修改，以及从写入损坏到检测到损坏之间发生了多少修改。

## Runtime Validation

自描述元数据的验证在运行时发生在两个地方：

- 在从磁盘成功读取之后立即进行
- 在写入 IO 提交之前立即进行

验证是完全无状态的——它独立于修改过程进行，只是检查元数据是否如其所述，元数据字段是否在界限内且内部一致。因此，我们无法捕捉到块内可能发生的所有类型的损坏，因为操作状态可能对元数据施加某些限制，或者块间关系可能出现损坏（例如，损坏的兄弟指针列表）。因此，我们仍需要在主代码中进行有状态检查，但一般来说，大多数逐字段验证由验证器处理。

对于读取验证，调用者需要指定应看到的预期元数据类型，IO 完成过程会验证元数据对象是否与预期相符。如果验证过程失败，则将读取的对象标记为 EFSCORRUPTED。调用者需要捕获此错误（与 IO 错误相同），并且如果由于验证错误需要采取特殊操作，可以通过捕获 EFSCORRUPTED 错误值来进行。

如果我们需要在更高层次上对错误类型进行更多区分，可以根据需要为不同的错误定义新的错误编号。

读取验证的第一步是检查魔数并确定是否需要进行 CRC 验证。如果需要，则计算 CRC32c 并将其与对象本身存储的值进行比较。一旦验证通过，进一步检查位置信息，然后进行广泛的对象特定元数据验证。如果这些检查中的任何一个失败，则缓冲区被认为是损坏的，并适当设置 EFSCORRUPTED 错误。

写入验证与读取验证相反——首先广泛验证对象，如果通过验证，我们更新对象最后一次修改的 LSN。在此之后，我们计算 CRC 并将其插入对象。一旦完成，写入 IO 被允许继续。如果在此过程中发生任何错误，缓冲区再次标记为 EFSCORRUPTED 错误，供更高层次捕获。

## Structures

一个典型的磁盘结构需要包含以下信息：
```c
struct xfs_ondisk_hdr {
        __be32 magic; /* magic number */
        __be32 crc; /* CRC, not logged */
        uuid_t uuid; /* filesystem identifier */
        __be64 owner; /* parent object */
        __be64 blkno; /* location on disk */
        __be64 lsn; /* last modification in log, not logged */
};
```

根据元数据，这些信息可能是与元数据内容分开的头部结构的一部分，或者可能分布在现有结构中。对于已经包含部分此类信息的元数据，例如超级块和 AG 头部，会出现后者的情况。

其他元数据可能具有不同的信息格式，但通常提供相同级别的信息。例如：

- 短 B 树块有一个 32 位的所有者（AG 号）和一个 32 位的块号用于定位。这两者结合提供的信息与上面结构中的 @owner 和 @blkno 相同，但使用了磁盘上少 8 个字节的空间。
- 目录/属性节点块有一个 16 位的魔数，并且包含魔数的头部也包含其他信息。因此，附加的元数据头部改变了元数据的整体格式。

典型的缓冲区读取验证器的结构如下：
```c
#define XFS_FOO_CRC_OFF offsetof(struct xfs_ondisk_hdr, crc)
static void
xfs_foo_read_verify(struct xfs_buf *bp)
{
        struct xfs_mount *mp = bp->b_target->bt_mount;
        if ((xfs_sb_version_hascrc(&mp->m_sb) &&
             !xfs_verify_cksum(bp->b_addr, BBTOB(bp->b_length),
                               XFS_FOO_CRC_OFF)) ||
            !xfs_foo_verify(bp)) {
                XFS_CORRUPTION_ERROR(__func__, XFS_ERRLEVEL_LOW, mp, bp->b_addr);
                xfs_buf_ioerror(bp, EFSCORRUPTED);
        }
}
```

代码通过检查超级块的特性位确保只有在文件系统启用CRC时才检查CRC，然后如果CRC验证通过（或者不需要CRC），则验证块的实际内容。验证函数将采取几种不同的形式，具体取决于是否可以使用魔术数来确定块的格式。

如果不能，代码结构如下：
```c
static bool
xfs_foo_verify(struct xfs_buf *bp)
{
        struct xfs_mount *mp = bp->b_target->bt_mount;
        struct xfs_ondisk_hdr *hdr = bp->b_addr;
        if (hdr->magic != cpu_to_be32(XFS_FOO_MAGIC))
                return false;
        if (!xfs_sb_version_hascrc(&mp->m_sb)) {
                if (!uuid_equal(&hdr->uuid, &mp->m_sb.sb_uuid))
                        return false;
                if (bp->b_bn != be64_to_cpu(hdr->blkno))
                        return false;
                if (hdr->owner == 0)
                        return false;
        }
        /* object specific verification checks here */
        return true;
}
```

如果不同格式有不同的魔术数，验证函数将如下所示：
```c
static bool
xfs_foo_verify(struct xfs_buf *bp)
{
        struct xfs_mount *mp = bp->b_target->bt_mount;
        struct xfs_ondisk_hdr *hdr = bp->b_addr;
        if (hdr->magic == cpu_to_be32(XFS_FOO_CRC_MAGIC)) {
                if (!uuid_equal(&hdr->uuid, &mp->m_sb.sb_uuid))
                        return false;
                if (bp->b_bn != be64_to_cpu(hdr->blkno))
                        return false;
                if (hdr->owner == 0)
                        return false;
        } else if (hdr->magic != cpu_to_be32(XFS_FOO_MAGIC))
                return false;
        /* object specific verification checks here */
        return true;
}
```

写验证器与读验证器非常相似，它们只是执行操作的顺序与读验证器相反。一个典型的写验证器如下：
```c
static void
xfs_foo_write_verify(struct xfs_buf *bp)
{
        struct xfs_mount *mp = bp->b_target->bt_mount;
        struct xfs_buf_log_item *bip = bp->b_fspriv;
        if (!xfs_foo_verify(bp)) {
                XFS_CORRUPTION_ERROR(__func__, XFS_ERRLEVEL_LOW, mp, bp->b_addr);
                xfs_buf_ioerror(bp, EFSCORRUPTED);
                return;
        }
        if (!xfs_sb_version_hascrc(&mp->m_sb))
                return;
        if (bip) {
                struct xfs_ondisk_hdr *hdr = bp->b_addr;
                hdr->lsn = cpu_to_be64(bip->bli_item.li_lsn);
        }
        xfs_update_cksum(bp->b_addr, BBTOB(bp->b_length), XFS_FOO_CRC_OFF);
}
```

这将验证元数据的内部结构，然后再进行其他操作，检测内存中修改元数据时发生的损坏。如果元数据验证通过，并且启用了CRC，我们将更新LSN字段（上次修改时间）并计算元数据的CRC。一旦完成这些操作，我们就可以发出IO。

## Inodes and Dquots

TODO

# Part II Global Structures

TODO

# Chapter 13 Journaling Log

> 注意：这里只涵盖 v2 日志格式

XFS 日志在磁盘上以文件系统内保留的块扩展区或作为一个单独的日志设备存在。日志本身可以看作是一系列的日志记录；每个日志记录包含部分或全部事务。事务由一系列日志操作头（“日志项”）、格式化结构和原始数据组成。事务中的第一个操作建立事务ID，最后一个操作是提交记录。记录在开始和提交操作之间的操作代表事务所做的元数据更改。如果缺少提交操作，则事务不完整且无法恢复。

## Log Records

XFS 日志分为一系列的日志记录。日志记录似乎对应一个内核日志缓冲区，最大可以达到 256KiB。每个记录都有一个日志序列号，这与 v5 元数据完整性字段中记录的 LSN 相同。

日志序列号是由两个 32 位数量组成的 64 位数量。高 32 位是“循环号”，每次 XFS 循环通过日志时递增一次。低 32 位是“块号”，在事务提交时分配，并且应该对应日志内的块偏移量。

一个日志记录以以下头开始，在磁盘上占用 512 字节：
```c
typedef struct xlog_rec_header {
        __be32 h_magicno;
        __be32 h_cycle;
        __be32 h_version;
        __be32 h_len;
        __be64 h_lsn;
        __be64 h_tail_lsn;
        __le32 h_crc;
        __be32 h_prev_block;
        __be32 h_num_logops;
        __be32 h_cycle_data[XLOG_HEADER_CYCLE_SIZE / BBSIZE];
        /* new fields */
        __be32 h_fmt;
        uuid_t h_fs_uuid;
        __be32 h_size;
} xlog_rec_header_t;
```

- `h_magicno`: 日志记录的魔数，0xfeedbabe。
- `h_cycle`: 该日志记录的循环号。
- `h_version`: 日志记录版本，目前为 2。
- `h_len`: 日志记录的长度（以字节为单位）。必须对齐到 64 位边界。
- `h_lsn`: 该记录的日志序列号。
- `h_tail_lsn`: 第一个具有未提交缓冲区的日志记录的日志序列号。
- `h_crc`: 日志记录头、循环数据和日志记录本身的校验和。
- `h_prev_block`: 前一个日志记录的块号。
- `h_num_logops`: 该记录中的日志操作数。
- `h_cycle_data`: 每个日志扇区的第一个 u32 必须包含循环号。由于日志项缓冲区的格式化不考虑此要求，日志中每个扇区的前四字节的原始内容被复制到该数组的相应元素中。之后，这些扇区的前四字节被标记上循环号。恢复时会逆转此过程。如果该日志记录中的扇区多于此数组中的槽数，则循环数据会继续扩展到所需的多个扇区；每个扇区格式化为类型 `xlog_rec_ext_header`。
- `h_fmt`: 日志记录的格式。这个值是以下值之一：

| Format value | Log format |
| -------------|----------- |
|XLOG_FMT_UNKNOWN | Unknown. Perhaps this log is corrupt.
|XLOG_FMT_LINUX_LE | Little-endian Linux. |
|XLOG_FMT_LINUX_BE | Big-endian Linux.|
|XLOG_FMT_IRIX_BE | Big-endian Irix.|

- `h_fs_uuid`: 文件系统UUID
- `h_size`: 内核日志记录大小。这个大小在16到256KiB之间，默认值为32KiB。

如前所述，如果该日志记录超过256个扇区，循环数据将溢出到日志中的下一个扇区。每个这样的扇区的格式如下：
```c
typedef struct xlog_rec_ext_header {
        __be32 xh_cycle;
        __be32 xh_cycle_data[XLOG_HEADER_CYCLE_SIZE / BBSIZE];
} xlog_rec_ext_header_t;
```

- `xh_cycle`：此日志记录的循环编号。应与 `h_cycle` 匹配。
- `xh_cycle_data`：溢出的循环数据。

## Log Operations

在一个日志记录中，日志操作记录为一个系列，其中包含一个操作头紧跟着一个数据区域。操作头的格式如下：
```c
typedef struct xlog_op_header {
        __be32 oh_tid;
        __be32 oh_len;
        __u8 oh_clientid;
        __u8 oh_flags;
        __u16 oh_res2;
} xlog_op_header_t;
```

- `oh_tid`：此操作的事务 ID。
- `oh_len`：数据区域的字节数。
- `oh_clientid`：此操作的发起者。可以是以下之一：

| Client ID | Originator |
| ----------|------------|
|XFS_TRANSACTION| 操作来自一个事务.|
|XFS_VOLUME| ⁇?|
|XFS_LOG| ⁇?|

- `oh_flags`：指定与此操作相关联的标志。这可以是以下值的组合（尽管大多数情况下只会设置一个）：

|Flag | Description|
|-----|------------|
|XLOG_START_TRANS |开始一个新的事务。下一个操作头应该描述一个事务头。.|
|XLOG_COMMIT_TRANS| Commit this transaction.|
|XLOG_CONTINUE_TRANS| Continue this trans into new log record.|
|XLOG_WAS_CONT_TRANS| This transaction started in a previous log record.|
|XLOG_END_TRANS| End of a continued transaction.|
|XLOG_UNMOUNT_TRANS| Transaction to unmount a filesystem.|

- `oh_res2`: Padding.

数据区域紧跟在操作头之后，长度正好为 oh_len 字节。这些有效载荷是以主机字节顺序排列的，这意味着不能在具有不同字节顺序的系统上重新播放未经清理的 XFS 文件系统的日志。

## Log Items

以下是可以跟随`xlog_op_header`的日志项负载类型。除了缓冲数据和inode核心外，所有日志项都有一个魔术数字来区分它们自己。缓冲数据项只会在xfs_buf_log_format项之后出现；而inode核心项只会在xfs_inode_log_format项之后出现。

|Magic| Hexadecimal| Operation Type|
|-----|------------|---------------|
|XFS_TRANS_HEADER_MAGIC|0x5452414e |Log Transaction Header |
|XFS_LI_EFI|0x1236 |Extent Freeing Intent                 |
|XFS_LI_EFD|0x1237 |Extent Freeing Done                   |
|XFS_LI_IUNLINK|0x1238| Unknown?                          |
|XFS_LI_INODE|0x123b| Inode Updates                       |
|XFS_LI_BUF|0x123c| Buffer Writes                         |
|XFS_LI_DQUOT|0x123d |Update Quota                        |
|XFS_LI_QUOTAOFF|0x123e |Quota Off                        |
|XFS_LI_ICREATE|0x123f |Inode Creation                    |
|XFS_LI_RUI|0x1240 |Reverse Mapping Update Intent         |
|XFS_LI_RUD|0x1241 |Reverse Mapping Update Done           |
|XFS_LI_CUI|0x1242 |Reference Count Update Intent         |
|XFS_LI_CUD|0x1243 |Reference Count Update Done           |
|XFS_LI_BUI|0x1244 |File Block Mapping Update Intent      |
|XFS_LI_BUD|0x1245 |File Block Mapping Update Done        | 

请注意，所有日志项（除了事务头）必须以以下头部结构开头。类型和大小字段嵌入到每个日志项头部中，但没有单独定义的头部。
```c
struct xfs_log_item {
        __uint16_t magic;
        __uint16_t size;
};
```

### Transaction Headers

TODO