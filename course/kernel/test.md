下面介绍一些Linux内核的测试工具。

# syzkaller {#syzkaller}

<!--
https://i-m.dev/posts/20200313-143737.html

配置: https://github.com/google/syzkaller/blob/master/pkg/mgrconfig/config.go

复现:
```shell
./syz-execprog -executor=./syz-executor -repeat=0 -procs=16 -cover=0 ./log0
```

```sh
CONFIG_KCOV=y
CONFIG_KCOV_INSTRUMENT_ALL=y
CONFIG_KCOV_ENABLE_COMPARISONS=y
CONFIG_DEBUG_FS=y

CONFIG_CMDLINE_BOOL=y
CONFIG_CMDLINE="net.ifnames=0"

CONFIG_E1000=y
CONFIG_E1000E=y
CONFIG_E1000E_HWTS=y

CONFIG_BINFMT_MISC=y
```
-->
参考:

- [syzkaller源码](https://github.com/google/syzkaller)
- [syzkaller文档翻译](https://chenxiaosong.com/src/translation/tests/syzkaller.html)

## 软件环境

打开[All releases - The Go Programming Language](https://go.dev/dl/)，下载最新版本，如`go1.22.5.linux-amd64.tar.gz`:
```sh
wget https://go.dev/dl/go1.22.5.linux-amd64.tar.gz
tar xvf go1.22.5.linux-amd64.tar.gz
export GOROOT=`pwd`/go
export PATH=$GOROOT/bin:$PATH
```

编译`syzkaller`源码:
```sh
git clone https://github.com/google/syzkaller
cd syzkaller
make # 编译结果在 bin/
```

安装软件:
```sh
sudo apt update
sudo apt install make gcc flex bison libncurses-dev libelf-dev libssl-dev -y
```

内核[x86_64-config](https://gitee.com/chenxiaosonggitee/tmp/blob/master/config/x86_64-config)文件还要打开以下配置:
```sh
# Debug info for symbolization.
CONFIG_DEBUG_INFO_DWARF4=y

# Memory bug detector，这玩意儿会导致运行很慢，所以如果不是测试的不要打开
CONFIG_KASAN=y
CONFIG_KASAN_INLINE=y
```

## 生成`qcow2`镜像

```sh
sudo apt install debootstrap -y
```

```sh
mkdir syzkaller-image
cd syzkaller-image
wget https://raw.githubusercontent.com/google/syzkaller/master/tools/create-image.sh -O create-image.sh
chmod +x create-image.sh
```

为了加快下载速度，然后将`create-image.sh`中的`DEBOOTSTRAP_PARAMS="--keyring /usr/share/keyrings/debian-archive-removed-keys.gpg $DEBOOTSTRAP_PARAMS`后面的链接修改成`https://repo.huaweicloud.com/debian/`。但有些网络下也不会加快太多，可以想办法访问国外网络进行下载。

再运行脚本生成`bullseye.img`:
```sh
./create-image.sh
```

生成`bullseye.img`后，用以下脚本启动测试一下:
```sh
qemu-system-x86_64 \
    -m 2G \
    -smp 16 \
    -kernel /home/sonvhi/chenxiaosong/code/x86_64-linux/build/arch/x86/boot/bzImage \
    -append "console=ttyS0 root=/dev/sda earlyprintk=serial net.ifnames=0" \
    -drive file=bullseye.img,format=raw \
    -net user,host=10.0.2.10,hostfwd=tcp:127.0.0.1:10021-:22 \
    -net nic,model=e1000 \
    -enable-kvm \
    -nographic \
```

确保能远程登录:
```sh
ssh -i bullseye.id_rsa -p 10021 -o "StrictHostKeyChecking no" root@localhost
```

测试完后，要把虚拟机关机，因为syzkaller会自己启动虚拟机。如果你已经用上面的脚本启动了虚拟机，再启动syzkaller就会启动失败，而且`qcow2`镜像也会损坏。

## 运行

到syzkaller源码目录下，创建`my.cfg`文件如下:
```sh
{
    "target": "linux/amd64",
    "http": "0.0.0.0:56741",
    "workdir": "workdir",
    # 这个应该是vmlinux的路径
    "kernel_obj": "/home/sonvhi/chenxiaosong/code/x86_64-linux/build/",
    "image": "/home/sonvhi/chenxiaosong/syzkaller-image/bullseye.img",
    "sshkey": "/home/sonvhi/chenxiaosong/syzkaller-image/bullseye.id_rsa",
    "syzkaller": ".",
    # 只测 chmod 系统调用
	# "enable_syscalls": ["chmod"],
    "procs": 8,
    "type": "qemu",
    "vm": {
        "count": 4,
        "kernel": "/home/sonvhi/chenxiaosong/code/x86_64-linux/build/arch/x86/boot/bzImage",
        "cpu": 2,
        "mem": 2048
    }
}
```

运行:
```sh
mkdir workdir
./bin/syz-manager -config=my.cfg
```

这时就能通过网页查看测试结果。如果你是在docker中运行syzkaller，想在加一台电脑上访问网页，可以在宿主机中安装nginx，并在nginx配置文件`/etc/nginx/sites-enabled/default`中添加以下内容，`172.17.0.3`是docker的ip:
```sh
server {
        listen 56741;

        location / {
                proxy_pass http://172.17.0.3:56741/;
        }
}
```

这时就可以在其他电脑上访问`http://192.168.3.224:56741/`（`192.168.3.224`是宿主机的ip）。

## 构造一个简单的bug

连续两次`chmod`调用的mode入参为0时，产生空指针解引用的bug，这个函数的执行路径是`chmod() -> do_fchmodat() -> chmod_common()`。

```sh
diff --git a/fs/open.c b/fs/open.c
index 50e45bc7c4d8..ee7962ca777d 100644
--- a/fs/open.c
+++ b/fs/open.c
@@ -637,6 +637,12 @@ int chmod_common(const struct path *path, umode_t mode)
        struct iattr newattrs;
        int error;

+        static umode_t old_mode = 0xffff;
+        if (old_mode == 0 && mode == 0) {
+                path = NULL;
+        }
+        old_mode = mode;
+
        error = mnt_want_write(path->mnt);
        if (error)
                return error;
```

到syzkaller源码目录下，`my.cfg`文件修改成如下，增加`enable_syscalls`，只测试`chmod`:
```sh
{
    "target": "linux/amd64",
    "http": "0.0.0.0:56741",
    "workdir": "workdir",
    # 这个应该是vmlinux的路径
    "kernel_obj": "/home/sonvhi/chenxiaosong/code/x86_64-linux/build/",
    "image": "/home/sonvhi/chenxiaosong/syzkaller-image/bullseye.img",
    "sshkey": "/home/sonvhi/chenxiaosong/syzkaller-image/bullseye.id_rsa",
    "syzkaller": ".",
    # 只测 chmod 系统调用
	"enable_syscalls": ["chmod"],
    "procs": 8,
    "type": "qemu",
    "vm": {
        "count": 4,
        "kernel": "/home/sonvhi/chenxiaosong/code/x86_64-linux/build/arch/x86/boot/bzImage",
        "cpu": 2,
        "mem": 2048
    }
}
```

运行:
```sh
mkdir workdir
./bin/syz-manager -config=my.cfg
```

## 复现

可以在[syzbot](https://syzkaller.appspot.com/upstream)中找发现的bug，有crash的日志和复现程序（syz和C），把`bin/linux_amd64/`复制到要测试的虚拟机中，按以下步骤复现。

```sh
echo 1 > /proc/sys/kernel/panic_on_oops # 注意不能用 vim 编辑
cat /proc/sys/kernel/panic_on_oops # 确认是否生效
./linux_amd64/syz-execprog -executor=./linux_amd64/syz-executor -repeat=0 -procs=16 -cover=0 crash-log
./linux_amd64/syz-execprog -executor=./linux_amd64/syz-executor -repeat=0 -procs=16 -cover=0 file-with-a-single-program
```

<!--
./syz-prog2c -prog linux_amd64/test.txt -enable=all -threaded -repeat=2 -procs=8 -sandbox=namespace -segv -tmpdir

将程序转换为c代码，repeat默认为1，当转换不成功时，增加重复数量。

也可在转换为c代码前，排除掉单个程序中不会导致崩溃的系统调用，得到最终某几个系统调用触发的崩溃，在用syz-prog2c进行c代码的转换。
-->

# xfstests

- [xfstests README中文翻译](https://chenxiaosong.com/src/translation/tests/xfstests-readme.html)。
- [xfstests README.config-sections中文翻译](https://chenxiaosong.com/src/translation/tests/xfstests-readme.config-sections.html)

## 安装

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

## 测试前准备

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

## 测试

### `./check --help`

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

### ext4

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

### nfs

先执行[`bash nfs-svr-setup.sh`](https://gitee.com/chenxiaosonggitee/blog/blob/master/course/nfs/src/nfs-svr-setup.sh)启动nfs server。

创建`local.config`配置文件:
```sh
TEST_DEV=localhost:/s_test
TEST_DIR=/tmp/test
SCRATCH_DEV=localhost:/s_scratch
SCRATCH_MNT=/tmp/scratch
FSTYP=nfs
MOUNT_OPTIONS="-o vers=4.2"
```

测试命令:
```sh
./check generic/001
./check nfs/001
./check -g generic/dir # 组查看tests/generic/group.list
```

# ltp

## 环境

github源码: [linux-test-project/ltp](https://github.com/linux-test-project/ltp)，参考[INSTALL](https://github.com/linux-test-project/ltp/blob/master/INSTALL)安装需要的依赖软件。其中`linux-headers`相关的在debian上可以使用以下命令安装:
```sh
apt search linux-headers | less # 搜索对应的软件包名
apt install -y linux-headers-amd64 linux-headers-5.10.0-28-common
```

编译安装参考[README中文翻译](https://chenxiaosong.com/src/translation/tests/ltp-readme.html)，默认安装在`/opt/ltp`中。

## LTP Network Tests

[LTP Network Tests README中文翻译](https://chenxiaosong.com/src/translation/tests/ltp-network-tests-readme.html)。

打开配置`CONFIG_VETH=m`、`CONFIG_NFS_FS=m`。

在debian发行版下，启动nfs server服务后，执行命令`cd /opt/ltp/testscripts; ./network.sh -n`后报错，换成手动执行第一个用例`cd /opt/ltp/testcases/bin; PATH=$PATH:$PWD ./nfs01.sh -v 3 -t udp`，报错`nfs01 1 TCONF: rpc.statd not running`，修改`/opt/ltp/testcases/bin/nfs_lib.sh`:
```sh
diff --git a/testcases/network/nfs/nfs_stress/nfs_lib.sh b/testcases/network/nfs/nfs_stress/nfs_lib.sh
index d3de3b7f1..4be0bcc6f 100644
--- a/testcases/network/nfs/nfs_stress/nfs_lib.sh
+++ b/testcases/network/nfs/nfs_stress/nfs_lib.sh
@@ -174,7 +174,7 @@ nfs_setup()
        fi

        if tst_cmd_available pgrep; then
-               for i in rpc.mountd rpc.statd; do
+               for i in rpc.mountd; do
                        pgrep $i > /dev/null || tst_brk TCONF "$i not running"
                done
        fi
```

