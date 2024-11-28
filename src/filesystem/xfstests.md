- [xfstests README中文翻译](https://chenxiaosong.com/src/translations/tests/xfstests-readme.html)。
- [xfstests README.config-sections中文翻译](https://chenxiaosong.com/src/translations/tests/xfstests-readme.config-sections.html)

# 安装

```sh
sudo yum install acl attr automake bc dbench dump e2fsprogs fio gawk gcc \
        gdbm-devel git indent kernel-devel libacl-devel libaio-devel \
        libcap-devel libtool liburing-devel libuuid-devel lvm2 make psmisc \
        python3 quota sed sqlite udftools  xfsprogs -y
# 安装用于正在测试的文件系统的软件包，或者其他软件包
sudo yum install btrfs-progs exfatprogs f2fs-tools ocfs2-tools xfsdump \
        xfsprogs-devel
```

源码编译安装:
```sh
git clone git://git.kernel.org/pub/scm/fs/xfs/xfstests-dev.git
cd xfstests-dev
make -j`nproc`
sudo make install
```

# 测试前准备

qemu的启动脚本添加两个设备:
```sh
-drive file=1,if=none,format=raw,cache=writeback,file.locking=off,id=dd_1 \
-device scsi-hd,drive=dd_1,id=disk_1,logical_block_size=512,physical_block_size=512 \
-drive file=2,if=none,format=raw,cache=writeback,file.locking=off,id=dd_2 \
-device scsi-hd,drive=dd_2,id=disk_2,logical_block_size=512,physical_block_size=512 \
```

创建两个10G的文件:
```sh
fallocate -l 10G 1
fallocate -l 10G 2
```

然后启动虚拟机，进入虚拟机。

(可选) 创建 fsgqa 测试用户和组:
```sh
sudo useradd -m fsgqa
sudo useradd 123456-fsgqa
sudo useradd fsgqa2
sudo groupadd fsgqa
```

# 测试

## `./check --help`

翻译如下:
```
用法: ./check [选项] [测试列表]

check 选项
    -nfs       测试 NFS
    -afs       测试 AFS
    -glusterfs 测试 GlusterFS
    -cifs      测试 CIFS
    -9p        测试 9p
    -fuse      测试 fuse
    -virtiofs  测试 virtiofs
    -overlay   测试 overlay
    -pvfs2     测试 PVFS2
    -tmpfs     测试 TMPFS
    -ubifs     测试 ubifs
    -l         行模式 diff
    -udiff     显示统一 diff（默认）
    -n         只显示，不运行测试
    -T         输出时间戳
    -r         随机化测试顺序
    --exact-order  按指定的准确顺序运行测试
    -i <n>     重复测试列表 <n> 次
    -I <n>     重复测试列表 <n> 次，但在任何测试失败时停止继续迭代
    -d         将测试输出转储到标准输出
    -b         简要测试总结
    -R fmt[,fmt]  以指定的格式生成报告。支持的格式：xunit, xunit-quiet
    --large-fs   优化大文件系统的临时设备
    -s section   仅运行配置文件中指定的部分
    -S section   排除配置文件中指定的部分
    -L <n>       测试失败后循环测试 <n> 次，测量通过/失败的总体指标

测试列表选项
    -g group[,group...]   包含这些组中的测试
    -x group[,group...]   排除这些组中的测试
    -X exclude_file       排除单个测试
    -e testlist           排除特定的测试列表
    -E external_file      排除单个测试
    [testlist]            包含匹配名称的测试

testlist 参数是以 <test dir>/<test name> 形式的测试列表。

<test dir> 是 tests 下的一个目录，包含一个组文件，该文件列出了该目录下测试的名称。

<test name> 可以是一个特定的测试文件名（例如 xfs/001）或一个测试文件名匹配模式（例如 xfs/*）。

group 参数是测试组的名称，可以从所有测试目录中收集（例如 quick）或从特定测试目录中的组收集，形式为 <test dir>/<group name>（例如 xfs/quick）。
如果要运行测试套件中的所有测试，可以使用 "-g all" 来指定所有组。

exclude_file 参数是每个测试目录下的一个文件名。在该文件所在的每个测试目录中，列出的测试名称将从该目录的测试列表中排除。

external_file 参数是一个路径，指向一个包含要排除的测试列表的单个文件，格式为 <test dir>/<test name>。

示例：
 check xfs/001
 check -g quick
 check -g xfs/quick
 check -x stress xfs/*
 check -X .exclude -g auto
 check -E ~/.xfstests.exclude
```

## ext4

创建`local.config`配置文件:
```sh
TEST_DEV=/dev/sda
TEST_DIR=/tmp/test
SCRATCH_DEV=/dev/sdb
SCRATCH_MNT=/tmp/scratch
FSTYP=ext4
MKFS_OPTIONS="-b 4096"
MOUNT_OPTIONS="-o acl,user_xattr"
```

测试命令:
```sh
./check generic/001
./check ext4/001
./check -g generic/dir # 组查看tests/generic/group.list
```

## nfs