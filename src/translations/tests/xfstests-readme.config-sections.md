本文档翻译自[kernel.org xfs/xfstests-dev.git 的 README 文件](https://git.kernel.org/pub/scm/fs/xfs/xfstests-dev.git/tree/README)（[或github](https://github.com/kdave/xfstests/blob/master/README)），翻译时文件的最新提交是`5f6b9e575f1b6c68e7b1f5ce4b5b9149201ffc76 fstests: Doc changes for afs`，大部分借助于ChatGPT。仅作为我个人的参考，如果你想查阅，建议看英文文档，因为我不确定我记录的中文翻译是否完整和正确。

```
带有section的配置文件
====================

带有section的配置文件对于在单次运行中对多个文件系统或多个文件系统设置进行 xfstests 测试非常有用，而无需使用外部脚本。

语法
----

定义部分的语法如下：

    [section_name]

部分名称应由字母数字字符和下划线组成。其他任何字符都是禁止的，且该部分将无法识别。

配置文件中的每个部分应包含格式为

    OPTION=value

的选项。

'OPTION' 不能包含任何空格字符。'value' 可以包含任何字符，唯一的限制是 - 字符 ' 和 " 只能出现在 'value' 的开始和结束处，但这是可选的。

注意，选项会在各部分之间传递，因此相同的选项不必在每个部分中都指定。然而需要小心，避免从之前的部分中留下不必要的选项。

结果
----

对于每个部分，xfstests 将使用指定的选项运行并在 '$RESULT_BASE/$section_name' 目录中生成单独的结果。

不同的挂载选项
-----------------

在不同的配置部分中指定不同的挂载选项是允许的。当 TEST_FS_MOUNT_OPTS 在下一个部分中有所不同时，TEST_DEV 会自动重新挂载并使用新的 TEST_FS_MOUNT_OPTS 选项。

多个文件系统
-------------

在不同的配置部分中使用不同的文件系统是允许的。当 FSTYP 在下一个部分中有所不同时，FSTYP 文件系统将在运行测试之前自动创建。

注意，如果没有在该部分中直接指定 TEST_FS_MOUNT_OPTS、MOUNT_OPTIONS、MKFS_OPTIONS 或 FSCK_OPTIONS，它们将重置为给定文件系统的默认值。

您还可以通过指定 RECREATE_TEST_DEV 强制重新创建文件系统。

仅运行指定的部分
------------------

指定 '-s' 参数并附上部分名称将只运行指定的部分。'-s' 参数可以多次指定，以允许运行多个部分。

选项仍然会在部分之间传递，包括那些不打算运行的部分。因此，您可以执行如下操作：

[ext4]
TEST_DEV=/dev/sda1
TEST_DIR=/mnt/test
SCRATCH_DEV=/dev/sdb1
SCRATCH_MNT=/mnt/test1
FSTYP=ext4

[xfs]
FSTYP=xfs

[btrfs]
FSTYP=btrfs

并运行

./check -s xfs -s btrfs

以仅检查 xfs 和 btrfs。所有设备和挂载仍然会从部分 [ext4] 中解析。

示例
-----

以下是一个带有section的配置文件示例：

[ext4_4k_block_size]
TEST_DEV=/dev/sda
TEST_DIR=/mnt/test
SCRATCH_DEV=/dev/sdb
SCRATCH_MNT=/mnt/test1
MKFS_OPTIONS="-q -F -b4096"
FSTYP=ext4
RESULT_BASE="`pwd`/results/`date +%d%m%y_%H%M%S`"

[ext4_1k_block_size]
MKFS_OPTIONS="-q -F -b1024"

[ext4_nojournal]
MKFS_OPTIONS="-q -F -b4096 -O ^has_journal"

[xfs_filesystem]
MKFS_OPTIONS="-f"
FSTYP=xfs

[ext3_filesystem]
FSTYP=ext3
MOUNT_OPTIONS="-o noatime"

[cephfs]
TEST_DIR=/mnt/test
TEST_DEV=192.168.14.1:6789:/
TEST_FS_MOUNT_OPTS="-o name=admin,secret=AQDuEBtYKEYRINGSECRETriSC8YJGDZsQHcr7g=="
FSTYP="ceph"

[glusterfs]
FSTYP=glusterfs
TEST_DIR=/mnt/gluster/test
TEST_DEV=192.168.1.1:testvol
SCRATCH_MNT=/mnt/gluster/scratch
SCRATCH_DEV=192.168.1.1:scratchvol

[afs]
FSTYP=afs
TEST_DEV=%example.com:xfstest.test
TEST_DIR=/mnt/xfstest.test
SCRATCH_DEV=%example.com:xfstest.scratch
SCRATCH_MNT=/mnt/xfstest.scratch
```