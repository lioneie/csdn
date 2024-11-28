[(x)fstests README中文翻译](https://chenxiaosong.com/src/translations/tests/xfstests-readme.html)。

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

```sh
./check generic/001
./check ext4/001
./check -g generic/dir # 组查看tests/generic/group.list
```