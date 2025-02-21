本文档翻译自[`google/syzkaller`](https://github.com/google/syzkaller)，大部分借助于ChatGPT。仅作为我个人的参考，如果你想查阅，建议看英文文档，因为我不确定我记录的中文翻译是否完整和正确。

# syzkaller - kernel fuzzer

翻译自[`README.md`](https://github.com/google/syzkaller/blob/master/README.md), 翻译时文件的最新提交是`c6f10907c38ce49ddc321539f75aabf0a9ad6c71 all: remove akaros support`。

[![CI Status](https://github.com/google/syzkaller/workflows/ci/badge.svg)](https://github.com/google/syzkaller/actions?query=workflow/ci)
[![OSS-Fuzz](https://oss-fuzz-build-logs.storage.googleapis.com/badges/syzkaller.svg)](https://bugs.chromium.org/p/oss-fuzz/issues/list?q=label:Proj-syzkaller)
[![Go Report Card](https://goreportcard.com/badge/github.com/google/syzkaller)](https://goreportcard.com/report/github.com/google/syzkaller)
[![Coverage Status](https://codecov.io/gh/google/syzkaller/graph/badge.svg)](https://codecov.io/gh/google/syzkaller)
[![GoDoc](https://godoc.org/github.com/google/syzkaller?status.svg)](https://godoc.org/github.com/google/syzkaller)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/google/syzkaller/blob/master/LICENSE)

`syzkaller` (`[siːzˈkɔːlə]`) 是一个无监督的覆盖率引导内核模糊测试工具。\
支持的操作系统: `FreeBSD`、`Fuchsia`、`gVisor`、`Linux`、`NetBSD`、`OpenBSD`、`Windows`。

邮件列表: [syzkaller@googlegroups.com](https://groups.google.com/forum/#!forum/syzkaller)（通过[网页](https://groups.google.com/forum/#!forum/syzkaller)或[电子邮件](mailto:syzkaller+subscribe@googlegroups.com)加入）。

发现的漏洞: [Darwin/XNU](https://github.com/google/syzkaller/blob/master/docs/darwin/README.md)，[FreeBSD](https://github.com/google/syzkaller/blob/master/docs/freebsd/found_bugs.md)，[Linux](https://github.com/google/syzkaller/blob/master/docs/linux/found_bugs.md)，[NetBSD](https://github.com/google/syzkaller/blob/master/docs/netbsd/found_bugs.md)，[OpenBSD](https://github.com/google/syzkaller/blob/master/docs/openbsd/found_bugs.md)，[Windows](https://github.com/google/syzkaller/blob/master/docs/windows/README.md)。

## 文档

最初，syzkaller 是为 Linux 内核模糊测试开发的，但现在它正在扩展以支持其他操作系统内核。
目前大部分文档与 [Linux](https://github.com/google/syzkaller/blob/master/docs/linux/setup.md) 内核相关。
对于其他操作系统内核，请参阅:
[Darwin/XNU](https://github.com/google/syzkaller/blob/master/docs/darwin/README.md)，
[FreeBSD](https://github.com/google/syzkaller/blob/master/docs/freebsd/README.md)，
[Fuchsia](https://github.com/google/syzkaller/blob/master/docs/fuchsia/README.md)，
[NetBSD](https://github.com/google/syzkaller/blob/master/docs/netbsd/README.md)，
[OpenBSD](https://github.com/google/syzkaller/blob/master/docs/openbsd/setup.md)，
[Starnix](https://github.com/google/syzkaller/blob/master/docs/starnix/README.md)，
[Windows](https://github.com/google/syzkaller/blob/master/docs/windows/README.md)，
[gVisor](https://github.com/google/syzkaller/blob/master/docs/gvisor/README.md)，
[Akaros](https://github.com/google/syzkaller/blob/master/docs/akaros/README.md)。

- [如何安装 syzkaller](https://github.com/google/syzkaller/blob/master/docs/setup.md)
- [如何使用 syzkaller](https://github.com/google/syzkaller/blob/master/docs/usage.md)
- [syzkaller 如何工作](https://github.com/google/syzkaller/blob/master/docs/internals.md)
- [如何安装 syzbot](https://github.com/google/syzkaller/blob/master/docs/setup_syzbot.md)
- [如何为 syzkaller 做贡献](https://github.com/google/syzkaller/blob/master/docs/contributing.md)
- [如何报告 Linux 内核漏洞](https://github.com/google/syzkaller/blob/master/docs/linux/reporting_kernel_bugs.md)
- [技术演讲和文章](https://github.com/google/syzkaller/blob/master/docs/talks.md)
- [基于 syzkaller 的研究工作](https://github.com/google/syzkaller/blob/master/docs/research.md)

## 免责声明

这不是谷歌的官方产品。

# How to set up syzkaller(docs/setup.md)

翻译自[`docs/setup.md`](https://github.com/google/syzkaller/blob/master/docs/setup.md), 翻译时文件的最新提交是`c6f10907c38ce49ddc321539f75aabf0a9ad6c71 all: remove akaros support`。

通用的 Linux 内核模糊测试设置说明请参见[这里](https://github.com/google/syzkaller/blob/master/docs/linux/setup.md)。

其他内核的设置请参见:
[FreeBSD](https://github.com/google/syzkaller/blob/master/docs/freebsd/README.md)，
[Darwin/XNU](https://github.com/google/syzkaller/blob/master/docs/darwin/README.md)，
[Fuchsia](https://github.com/google/syzkaller/blob/master/docs/fuchsia/README.md)，
[NetBSD](https://github.com/google/syzkaller/blob/master/docs/netbsd/README.md)，
[OpenBSD](https://github.com/google/syzkaller/blob/master/docs/openbsd/setup.md)，
[Windows](https://github.com/google/syzkaller/blob/master/docs/windows/README.md)。

按照这些说明操作后，你应该能够运行 `syz-manager`，看到它执行程序，并能够访问暴露在 `http://127.0.0.1:56741`（或你在 manager 配置中指定的其他地址）的统计信息。
如果一切正常，典型的执行日志应如下所示:
```sh
$ ./bin/syz-manager -config=my.cfg
2017/06/14 16:39:05 loading corpus...
2017/06/14 16:39:05 loaded 0 programs (0 total, 0 deleted)
2017/06/14 16:39:05 serving http on http://127.0.0.1:56741
2017/06/14 16:39:05 serving rpc on tcp://127.0.0.1:34918
2017/06/14 16:39:05 booting test machines...
2017/06/14 16:39:05 wait for the connection from test machine...
2017/06/14 16:39:59 received first connection from test machine vm-9
2017/06/14 16:40:05 executed 293, cover 43260, crashes 0, repro 0
2017/06/14 16:40:15 executed 5992, cover 88463, crashes 0, repro 0
2017/06/14 16:40:25 executed 10959, cover 116991, crashes 0, repro 0
2017/06/14 16:40:35 executed 15504, cover 132403, crashes 0, repro 0
```

此时，确保 syzkaller 能够收集已执行程序的代码覆盖率（除非你在配置中指定 `"cover": false` 或者你正在模糊测试的内核尚不支持覆盖率）。
网页上的 `cover` 计数器应为非零。

更多关于配置文件格式的信息，请参见[这里](https://github.com/google/syzkaller/blob/master/docs/configuration.md)。

故障排除提示请参见[此页面](https://github.com/google/syzkaller/blob/master/docs/troubleshooting.md)。

# How to set up syzkaller(docs/linux/setup.md)

翻译自[`docs/linux/setup.md`](https://github.com/google/syzkaller/blob/master/docs/linux/setup.md)，翻译时文件的最新提交是`dd26401e5ae3c1fe62beadcfb937ee5d06f304e2 docs: update required Go version`。

关于如何使用 syzkaller 进行 Linux 内核模糊测试的通用说明如下所示[below](#install)。

特定虚拟机类型或内核架构的说明可以在以下页面找到:

- [设置: Ubuntu 主机，QEMU 虚拟机，x86-64 内核](https://github.com/google/syzkaller/blob/master/docs/linux/setup_ubuntu-host_qemu-vm_x86-64-kernel.md)
- [设置: Linux 主机，QEMU 虚拟机，arm64 内核](https://github.com/google/syzkaller/blob/master/docs/linux/setup_linux-host_qemu-vm_arm64-kernel.md)
- [设置: Linux 主机，QEMU 虚拟机，arm 内核](https://github.com/google/syzkaller/blob/master/docs/linux/setup_linux-host_qemu-vm_arm-kernel.md)
- [设置: Linux 主机，QEMU 虚拟机，riscv64 内核](https://github.com/google/syzkaller/blob/master/docs/linux/setup_linux-host_qemu-vm_riscv64-kernel.md)
- [设置: Linux 主机，QEMU 虚拟机，s390x 内核](https://github.com/google/syzkaller/blob/master/docs/linux/setup_linux-host_qemu-vm_s390x-kernel.md)
- [设置: Linux 主机，安卓设备，arm32/64 内核](https://github.com/google/syzkaller/blob/master/docs/linux/setup_linux-host_android-device_arm-kernel.md)
- [设置: Linux 隔离主机](https://github.com/google/syzkaller/blob/master/docs/linux/setup_linux-host_isolated.md)
- [设置: Ubuntu 主机，VMware 虚拟机，x86-64 内核](https://github.com/google/syzkaller/blob/master/docs/linux/setup_ubuntu-host_vmware-vm_x86-64-kernel.md)

## install

使用 syzkaller 需要以下组件:

 - Go 编译器和 syzkaller 本身
 - 支持覆盖率的 C 编译器
 - 添加了覆盖率的 Linux 内核
 - 虚拟机或物理设备

如果遇到任何问题，请查看[故障排除](https://github.com/google/syzkaller/blob/master/docs/troubleshooting.md)页面。

### Go 和 syzkaller

`syzkaller` 是用 [Go](https://golang.org) 编写的，构建需要 `Go 1.21+` 工具链。
通常我们旨在支持 Go 的两个最新版本。
可以通过以下方式安装工具链:
```sh
wget https://dl.google.com/go/go1.21.4.linux-amd64.tar.gz
tar -xf go1.21.4.linux-amd64.tar.gz
export GOROOT=`pwd`/go
export PATH=$GOROOT/bin:$PATH
```

请参阅 [Go: 下载和安装](https://golang.org/doc/install) 以了解其他选项。

下载和构建 `syzkaller`:
```sh
git clone https://github.com/google/syzkaller
cd syzkaller
make
```

编译后的二进制文件应出现在 `bin/` 目录中。

注意: 如果您想进行跨操作系统/架构测试，您需要在 `make` 中指定 `TARGETOS`、`TARGETVMARCH` 和 `TARGETARCH` 参数。详情请参阅 [Makefile](https://github.com/google/syzkaller/blob/master/Makefile)。

### 环境

如果您在跨架构环境中进行模糊测试，可能需要正确设置 `binutils`，具体描述见[这里](https://github.com/google/syzkaller/blob/master/docs/linux/coverage.md#binutils)。

### C 编译器

Syzkaller 是一个覆盖率引导的模糊测试器，因此需要内核用覆盖率支持进行构建，这需要一个最新版本的 GCC。
覆盖率支持已提交到 GCC，并在 GCC 6.1.0 或更高版本中发布。
确保您的 GCC 满足此要求，或者获取一个 [syzbot](https://github.com/google/syzkaller/blob/master/docs/syzbot.md) 使用的 GCC，[点击这里](https://github.com/google/syzkaller/blob/master/docs/syzbot.md#crash-does-not-reproduce)。

### Linux 内核

除了 GCC 中的覆盖率支持，您还需要在内核端的支持。
KCOV 在 Linux 内核主线版本 4.6 中添加，并可以通过内核配置选项 `CONFIG_KCOV=y` 启用。
对于较旧的内核，您至少需要回移提交 [kernel: add kcov code coverage](https://github.com/torvalds/linux/commit/5c9a8750a6409c63a0f01d51a9024861022f6593)。
除此之外，建议回移所有涉及 `kernel/kcov.c` 的内核补丁。

为了启用更多 syzkaller 功能并提高错误检测能力，建议使用额外的配置选项。
详情请参阅[此页面](https://github.com/google/syzkaller/blob/master/docs/linux/kernel_configs.md)。

### 虚拟机设置

Syzkaller 在工作虚拟机或物理设备上执行内核模糊测试。
这些工作环境被称为虚拟机（VM）。
开箱即用的 syzkaller 支持 QEMU、kvmtool 和 GCE 虚拟机、安卓设备和 Odroid C2 板。

以下是 syzkaller 虚拟机的一般要求:

 - 模糊测试进程与外界通信，因此虚拟机镜像需要包含网络支持。
 - 模糊测试进程的程序文件通过 SSH 传输到虚拟机中，因此虚拟机镜像需要运行 SSH 服务器。
 - 虚拟机的 SSH 配置应设置为允许 `syz-manager` 配置中包含的身份进行 root 访问。换句话说，您应该能够执行 `ssh -i $SSHID -p $PORT root@localhost` 而无需输入密码（其中 `SSHID` 是 SSH 身份文件，`PORT` 是 `syz-manager` 配置文件中指定的端口）。
 - 内核通过 debugfs 条目导出覆盖率信息，因此虚拟机镜像需要在 `/sys/kernel/debug` 挂载 debugfs 文件系统。

要使用 QEMU syzkaller 虚拟机，您必须在主机系统上安装 QEMU，详情请参阅 [QEMU 文档](http://wiki.qemu.org/Manual)。
[create-image.sh](https://github.com/google/syzkaller/blob/master/tools/create-image.sh) 脚本可用于创建合适的 Linux 镜像。

有关为 QEMU、安卓和其他类型的虚拟机设置 syzkaller 的说明，请参阅文档顶部的链接。

### 故障排除

* QEMU 需要 root 权限才能使用 `-enable-kvm`。

    解决方案: 将您的用户添加到 `kvm` 组（`sudo usermod -a -G kvm` 并重新登录）。

* QEMU 崩溃，错误信息为:

    ```
    qemu-system-x86_64: error: failed to set MSR 0x48b to 0x159ff00000000
    qemu-system-x86_64: /build/qemu-EmNSP4/qemu-4.2/target/i386/kvm.c:2947: kvm_put_msrs: Assertion `ret == cpu->kvm_msr_buf->nmsrs' failed.
    ```
    解决方案: 从 QEMU 命令行中删除 `-cpu host,migratable=off`。最简单的方法是将 `syz-manager` 配置文件中的 `qemu_args` 设置为 `-enable-kvm`。

# Setup: Ubuntu host, QEMU vm, x86-64 kernel

翻译自[`docs/linux/setup_ubuntu-host_qemu-vm_x86-64-kernel.md`](https://github.com/google/syzkaller/blob/master/docs/linux/setup_ubuntu-host_qemu-vm_x86-64-kernel.md)，翻译时文件的最新提交是`d4d447cd780753901f9e00aa246cc835458a8f06 tools/create-image.sh: upgrade default release to bullseye`。

以下是如何在主机运行 Ubuntu，QEMU 实例运行 Debian Bullseye 的情况下，在 QEMU 中对 x86-64 内核进行模糊测试的说明。

在下面的说明中，`$VAR` 表示法（例如 `$GCC`、`$KERNEL` 等）用于表示在执行说明时创建的目录（例如解压 GCC 压缩包时将创建一个目录），或者你需要在运行说明之前自己创建的目录。手动替换这些变量的值。

## 安装先决条件

命令:
```sh
sudo apt update
sudo apt install make gcc flex bison libncurses-dev libelf-dev libssl-dev
```

## GCC

如果你的发行版中的 GCC 版本较旧，最好从[此列表](https://github.com/google/syzkaller/blob/master/docs/syzbot.md#crash-does-not-reproduce)获取最新的 GCC。下载并解压到 `$GCC`，你应该在 `$GCC/bin/` 目录下有 GCC 二进制文件。

>**Ubuntu 20.04 LTS**: 你可以忽略本节。GCC 已经是最新的版本。

命令:
```sh
ls $GCC/bin/
# Sample output:
# cpp     gcc-ranlib  x86_64-pc-linux-gnu-gcc        x86_64-pc-linux-gnu-gcc-ranlib
# gcc     gcov        x86_64-pc-linux-gnu-gcc-9.0.0
# gcc-ar  gcov-dump   x86_64-pc-linux-gnu-gcc-ar
# gcc-nm  gcov-tool   x86_64-pc-linux-gnu-gcc-nm
```

## 内核

### 检出 Linux 内核源码

命令:
```sh
git clone --branch v6.2 git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git $KERNEL
```

>我们建议从最新的稳定版本开始。v6.2 是一个示例。

### 生成默认配置

命令:
```sh
cd $KERNEL
make defconfig
make kvm_guest.config
```

或者如果你想指定一个编译器。

命令:
``` bash
cd $KERNEL
make CC="$GCC/bin/gcc" defconfig
make CC="$GCC/bin/gcc" kvm_guest.config
```

### 启用必需的配置选项

根据[kernel_configs.md](https://github.com/google/syzkaller/blob/master/docs/linux/kernel_configs.md)中的描述，启用内核配置选项以支持syzkaller。
不需要全部启用，但至少需要如下配置:
``` make
# Coverage collection.
CONFIG_KCOV=y

# Debug info for symbolization.
CONFIG_DEBUG_INFO_DWARF4=y

# Memory bug detector
CONFIG_KASAN=y
CONFIG_KASAN_INLINE=y

# Required for Debian Stretch and later
CONFIG_CONFIGFS_FS=y
CONFIG_SECURITYFS=y
```

编辑`.config`文件并手动启用这些选项（或者如果你更喜欢，可以通过`make menuconfig`完成）。

由于启用这些选项会导致更多的子选项可用，我们需要重新生成配置:

命令:
``` bash
make olddefconfig
```

或者如果你想指定一个编译器。

命令:
``` bash
make CC="$GCC/bin/gcc" olddefconfig
```

你可能还希望禁用可预测的网络接口命名机制。这可以在syzkaller配置中禁用（详细信息请参见[troubleshooting.md](https://github.com/google/syzkaller/blob/master/docs/linux/troubleshooting.md)），或者通过更新以下内核配置参数来实现:

``` make
CONFIG_CMDLINE_BOOL=y
CONFIG_CMDLINE="net.ifnames=0"
```

### Build the Kernel

命令:
``` bash
make -j`nproc`
```

或者如果你想指定一个编译器。

命令:
``` bash
make CC="$GCC/bin/gcc" -j`nproc`
```

现在你应该有`vmlinux`（内核二进制文件）和`bzImage`（压缩内核镜像）:

命令:
``` bash
ls $KERNEL/vmlinux
# sample output - $KERNEL/vmlinux
ls $KERNEL/arch/x86/boot/bzImage
# sample output - $KERNEL/arch/x86/boot/bzImage
```

## Image

### Install debootstrap

命令:
``` bash
sudo apt install debootstrap
```

### 创建 Debian Bullseye Linux 映像

创建一个包含最小必要软件包集的Debian Bullseye Linux镜像。

命令:
``` bash
mkdir $IMAGE
cd $IMAGE/
wget https://raw.githubusercontent.com/google/syzkaller/master/tools/create-image.sh -O create-image.sh
chmod +x create-image.sh
./create-image.sh
```

结果应该是 `$IMAGE/bullseye.img` 磁盘映像。

### 或者创建不同版本的 Debian Linux 映像

要创建不同版本的 Debian 映像（例如 buster、stretch、sid），请指定 `--distribution` 选项。

命令:
``` bash
./create-image.sh --distribution buster
```

### 映像额外工具

有时在虚拟机中拥有一些额外的软件包和工具是有用的，即使它们不是运行 syzkaller 所必需的。要安装我们认为有用的一组工具，请执行以下操作（请随意编辑脚本中的工具列表）:

命令:
``` bash
./create-image.sh --feature full
```

要安装 perf（不需要运行 syzkaller；需要 `$KERNEL` 指向内核源代码）:

命令:
``` bash
./create-image.sh --add-perf
```

有关 `create-image.sh` 的其他选项，请参考 `./create-image.sh -h`

## QEMU

### Install QEMU

命令:
``` bash
sudo apt install qemu-system-x86
```

### 验证

确保内核启动并且 `sshd` 启动。

命令:
``` bash
qemu-system-x86_64 \
	-m 2G \
	-smp 2 \
	-kernel $KERNEL/arch/x86/boot/bzImage \
	-append "console=ttyS0 root=/dev/sda earlyprintk=serial net.ifnames=0" \
	-drive file=$IMAGE/bullseye.img,format=raw \
	-net user,host=10.0.2.10,hostfwd=tcp:127.0.0.1:10021-:22 \
	-net nic,model=e1000 \
	-enable-kvm \
	-nographic \
	-pidfile vm.pid \
	2>&1 | tee vm.log
```

``` text
early console in setup code
early console in extract_kernel
input_data: 0x0000000005d9e276
input_len: 0x0000000001da5af3
output: 0x0000000001000000
output_len: 0x00000000058799f8
kernel_total_size: 0x0000000006b63000

Decompressing Linux... Parsing ELF... done.
Booting the kernel.
[    0.000000] Linux version 4.12.0-rc3+ ...
[    0.000000] Command line: console=ttyS0 root=/dev/sda debug earlyprintk=serial
...
[ ok ] Starting enhanced syslogd: rsyslogd.
[ ok ] Starting periodic command scheduler: cron.
[ ok ] Starting OpenBSD Secure Shell server: sshd.
```

之后，你应该能够在另一个终端中 ssh 到 QEMU 实例。

命令:
``` bash
ssh -i $IMAGE/bullseye.id_rsa -p 10021 -o "StrictHostKeyChecking no" root@localhost
```

### 疑难解答

如果出现 "too many tries" 错误，可能是 ssh 在传递显式传递的 `-i` 密钥之前传递了默认密钥。添加选项 `-o "IdentitiesOnly yes"`。

要终止正在运行的 QEMU 实例，按 `Ctrl+A` 然后 `X` 或运行:

命令:
``` bash
kill $(cat vm.pid)
```

如果 QEMU 正常工作，内核启动并且 ssh 成功，你可以关闭 QEMU 并尝试运行 syzkaller。

## syzkaller

按照[此处](https://github.com/google/syzkaller/blob/master/docs/linux/setup.md#go-and-syzkaller)所述构建 syzkaller。
然后创建如下所示的管理器配置，使用实际值替换环境变量 `$GOPATH`、`$KERNEL` 和 `$IMAGE`。

``` json
{
	"target": "linux/amd64",
	"http": "127.0.0.1:56741",
	"workdir": "$GOPATH/src/github.com/google/syzkaller/workdir",
	"kernel_obj": "$KERNEL",
	"image": "$IMAGE/bullseye.img",
	"sshkey": "$IMAGE/bullseye.id_rsa",
	"syzkaller": "$GOPATH/src/github.com/google/syzkaller",
	"procs": 8,
	"type": "qemu",
	"vm": {
		"count": 4,
		"kernel": "$KERNEL/arch/x86/boot/bzImage",
		"cpu": 2,
		"mem": 2048
	}
}
```

运行 syzkaller 管理器:

``` bash
mkdir workdir
./bin/syz-manager -config=my.cfg
```

现在 syzkaller 应该正在运行，你可以使用浏览器在 `127.0.0.1:56741` 查看管理器状态。

如果在 `syz-manager` 启动后遇到问题，请考虑使用 `-debug` 标志运行它。
还可以参考[此页面](https://github.com/google/syzkaller/blob/master/docs/troubleshooting.md)获取故障排除技巧。

# How to use syzkaller

翻译自[`README.md`](https://github.com/google/syzkaller/blob/master/docs/usage.md), 翻译时文件的最新提交是`7016057751ec811d92392186ea96c53a7253ea5e docs/usage.md: correct grammatical error`。

## 运行

启动 `syz-manager` 进程，命令如下:
```
./bin/syz-manager -config my.cfg
```

`syz-manager` 进程将启动虚拟机并在其中开始模糊测试。
`-config` 命令行选项指定配置文件的位置，配置文件描述见[这里](https://github.com/google/syzkaller/blob/master/docs/configuration.md)。
发现的崩溃、统计数据和其他信息会显示在管理器配置中指定的 HTTP 地址上。

## 崩溃

一旦 syzkaller 在某个虚拟机中检测到内核崩溃，它将自动开始重现该崩溃的过程（除非你在配置中指定了 `"reproduce": false`）。
默认情况下，它将使用 4 个虚拟机来重现崩溃，然后最小化导致崩溃的程序。
这可能会暂停模糊测试，因为所有虚拟机可能都忙于重现检测到的崩溃。

重现一次崩溃的过程可能需要几分钟到一个小时不等，这取决于崩溃是否容易重现或根本无法重现。
由于这个过程并不完美，因此可以按照[这里](https://github.com/google/syzkaller/blob/master/docs/reproducing_crashes.md)描述的方式尝试手动重现崩溃。

如果成功找到重现器，它可以生成两种形式之一: syzkaller 程序或 C 程序。
Syzkaller 总是尝试生成更用户友好的 C 重现器，但有时由于各种原因（例如略有不同的时间安排）会失败。
如果 syzkaller 仅生成了 syzkaller 程序，可以按照[这里](https://github.com/google/syzkaller/blob/master/docs/reproducing_crashes.md)的方式手动执行它们以重现和调试崩溃。

## 集线器

如果你运行多个 `syz-manager` 实例，可以将它们连接在一起并允许交换程序和重现器，详细信息见[这里](https://github.com/google/syzkaller/blob/master/docs/hub.md)。

## 报告漏洞

有关如何报告 Linux 内核漏洞的说明，请查看[这里](https://github.com/google/syzkaller/blob/master/docs/linux/reporting_kernel_bugs.md)。

# How to reproduce crashes

翻译自[`docs/reproducing_crashes.md`](https://github.com/google/syzkaller/blob/master/docs/reproducing_crashes.md), 翻译时文件的最新提交是``52c8379f77b5f292e2d527c66dfe17a899381d20 docs: update docs to reflect the new `async` flag``。

创建syzkaller错误的重现程序的过程是自动化的，但它并不完美，因此syzkaller提供了一些工具用于手动执行和重现程序。

在manager `workdir/crashes` 目录中创建的崩溃日志包含在崩溃前执行的程序。在并行执行模式下（当manager配置中的`procs`参数设置为大于1的值时），导致崩溃的程序不一定立即在崩溃前执行；有问题的程序可能在之前的某个地方。有两个工具可以帮助你识别和最小化导致崩溃的程序: `tools/syz-execprog` 和 `tools/syz-prog2c`。

`tools/syz-execprog` 在各种模式下执行单个syzkaller程序或一组程序（一次或无限循环；在线程/碰撞模式下（见下文），有或没有覆盖收集）。你可以通过循环运行崩溃日志中的所有程序来开始，以检查是否至少有一个程序确实使内核崩溃: `./syz-execprog -executor=./syz-executor -repeat=0 -procs=16 -cover=0 crash-log`。然后尝试识别导致崩溃的单个程序，可以用 `./syz-execprog -executor=./syz-executor -repeat=0 -procs=16 -cover=0 file-with-a-single-program` 测试程序。

注意: `syz-execprog` 在本地执行程序。所以你需要将 `syz-execprog` 和 `syz-executor` 复制到带有测试内核的虚拟机中并在那里运行。

一旦你有了导致崩溃的单个程序，尝试通过从程序中删除单个系统调用来最小化它（你可以在行首添加`#`来注释掉单行），以及删除不必要的数据（例如，将`&(0x7f0000001000)="73656c6600"`系统调用参数替换为 `&(0x7f0000001000)=nil`）。你还可以尝试将所有的mmap调用合并为一个映射整个所需区域的单个mmap调用。再次使用 `syz-execprog` 工具测试最小化。

现在你有了一个最小化的程序，检查如果使用 `./syz-execprog -threaded=0 -collide=0` 标志崩溃仍然重现。如果没有，那么你需要稍后做一些额外的工作。

现在，运行 `syz-prog2c` 工具处理程序。它会给你可执行的C源代码。如果崩溃在使用 `-threaded/collide=0` 标志时重现，那么这个C程序也应该导致崩溃。

如果崩溃在使用 `-threaded/collide=0` 标志时不可重现，那么你需要最后一步。你可以将线程模式视为每个系统调用在其自己的线程中执行。为了模拟这种执行模式，将单个系统调用移动到单独的线程中。你可以在这里看到一个例子: https://groups.google.com/d/msg/syzkaller/fHZ42YrQM-Y/Z4Xf-BbUDgAJ。

这个过程在 `syz-repro` 实用程序中有一定程度的自动化。你需要提供你的manager配置和崩溃报告文件。你可以参考[示例配置文件](https://github.com/google/syzkaller/blob/master//pkg/mgrconfig/testdata/qemu.cfg)。
```
./syz-repro -config my.cfg crash-qemu-1-1455745459265726910
```

它将尝试找到有问题的程序并最小化它。但由于有很多因素可以影响可重现性，它并不总是有效。
