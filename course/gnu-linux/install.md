在GNU/Linux发行版的选择上，我们这里是学习的目的，所以就选用能体验最新特性的[Ubuntu](https://ubuntu.com/download)和[Fedora](https://fedoraproject.org/)，都是每年发布两个版本。

与Linux内核开发相关的请查看[内核开发环境](https://chenxiaosong.com/course/kernel/dev-environment.html)。

# 启动配置

## BIOS设置

我用的主板是和Linus同款的“技嘉Aorus”，有时会抽风恢复默认的BIOS出厂设置，
在BIOS的“easy mode”中把“X.M.P. Disabled”改为“X.M.P.-DDR4-3600 18-22-22-42-64-1.35V”。
然后点击右下角的“Advanced Mode(F2)”进入“Advanced Mode”，“Tweaker -> Advanced CPU Settings -> SVM Mode”改为 “Enabled”开启硬件虚拟化配置。

另外再记录一下联想台式机进bios是按F1键。

## 双系统grub设置

grub的配置文件的示例[boot-efi-EFI](https://gitee.com/chenxiaosonggitee/blog/tree/master/course/gnu-linux/src/boot-efi-EFI)，在操作系统中的路径为`/boot/efi/EFI/{ubuntu,centos}/grub.cfg`。

centos9 grub设置:
```sh
blkid # 打印 uuid
vim /boot/efi/EFI/centos/grub.cfg # 更改 uuid, set prefix=($dev)/ 后接正确的路径
grub2-mkconfig -o /boot/grub2/grub.cfg # centos9使用的是grub2
```

ubuntu22.04 grub设置，修改配置`/boot/efi/EFI/ubuntu/grub.cfg`:
```sh
search.fs_uuid 22bac2d6-b556-4158-8244-fba87a8a34c3 root # 用 blkid 查看 uuid
set prefix=($root)'/boot/grub'
configfile $prefix/grub.cfg
```

更改启动界面选择系统的超时时间:
```sh
vim /etc/default/grub # GRUB_TIMEOUT=5
```

# virt-manager安装虚拟机

`/etc/libvirt/qemu.conf`文件配置:
```sh
user = "root"
group = "libvirt"
```

注意麒麟桌面系统v10的virt-manager图形显示协议要用vnc。

## `virt-manager`安装`aarch64`系统

- 首先`ssh-copy-id root@${ip}`确保可以免密码登录（非`root`用户就行）。
- 启动virt-manager后，`添加连接 -> 勾选 通过ssh连接到远程主机 -> 用户名: root -> 主机名: ${ip}:22｀。
- `创建虚拟机 -> 架构选项 -> 架构: aarch64 -> 机器类型: virt -> 在完成前打勾 在安装前自定义配置`。
- 弹出配置界面，`概况 固件: UEFI aarch64 -> cpu数 型号: cortex-a72 -> 添加硬件 图形 类型: spice服务器 地址: 所有接口 -> 添加硬件 输入 USB鼠标 USB键盘`。

`添加硬件 图形 类型:`如果选`vnc服务器`，要把virt-manager窗口关闭才能用vnc客户端登录，而且系统鼠标定位有一点小问题，所以不建议选择`vnc服务器`，建议选择`spice服务器`。

## 桥接

- 网络源: Macvtap设备
- 设备名称: 选择要桥接的接口，如enp2s0
- 设备型号: 我选择virtio

注意Macvtap方式不能访问宿主机和同一个交换机上的ip。

目前暂还没找到完美的virt-manager桥接方法。可以使用其他虚拟机软件如vmware或virtualbox。

# 配置

有些发行版默认`poweroff`和`reboot`等命令可以以非root权限运行，容易误操作，这些命令都软链接到`/bin/systemctl`, 可以用以下命令修改权限:
```sh
sudo chmod 700 /bin/systemctl
```

设置hostname:
```sh
sudo hostnamectl set-hostname Threadripper-Ubuntu2204
```

新建或删除用户:
```sh
sudo useradd -s /bin/bash -d /home/test -m test # 新建用户test
sudo userdel -r test # 删除用户test，-r选项代表同时删除用户的家目录和相关文件
```

ssh密码输入界面要很久才出现的解决办法,修改`/etc/ssh/ssh_config`文件:
```sh
GSSAPIAuthentication no # GSSAPI 通常用于支持 Kerberos 认证，提供一种安全且无缝的认证方式
```

如果没有挂载`/tmp`目录，可以修改`/etc/fstab`文件:
```sh
# defaults: 使用默认的挂载选项。
# noatime: 不更新文件的访问时间戳。
# nosuid: 不允许设置文件的 SUID 位。
# nodev: 不允许设备文件。
# noexec: 不允许执行二进制文件。安装vmware等软件时会安装不上
# mode=1777: 设置目录的权限为 1777，确保它是可写的临时目录。
tmpfs /tmp tmpfs defaults,noatime,nosuid,nodev,mode=1777,size=20G 0 0
```

自动挂载磁盘，修改配置文件`/etc/fstab`，添加:
```sh
# uuid用blkid /dev/sda查看
# 最后2个参数（0 0）的意义: dump, fsck
UUID=b7aa1308-f57e-4f28-834c-c463237a8383 /home/sonvhi/sonvhi/   ext4    errors=remount-ro    0       0
```

如果内存比较小，可以添加swap:
```sh
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
ls -lh /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo swapon -s
sudo vi /etc/fstab # 在/etc/fstab最后一行添加 /swapfile  none  swap  sw  0  0
```

shell界面路径名显示绝对路径，想换成只显示最后一个路径名分量, `~/.bashrc`文件修改以下变量:
```sh
PS1='${debian_chroot:+($debian_chroot)}\u@\h:\W\$ '
```

# VNC远程桌面 {#vnc}

<!--
https://blog.csdn.net/u011795345/article/details/78681213
https://cloud.tencent.com/developer/article/2148538

virt-install --virt-type kvm --name kylin-desktop --vcpus=4 --ram 4096 --cdrom=Kylin-Desktop-V10-SP1-General-Release-2303-ARM64.iso --disk image.qcow2,format=qcow2 --network network=default --graphics vnc,listen=0.0.0.0,port=5955 --os-type=linux

qemu-img create -f qcow2 kylin-sp1-210528.qcow2 100G
virt-install --virt-type kvm --name kylin-sp1-210528 --vcpus=4 --ram 4096 --cdrom=/root/virtual-machine/Kylin-Server-10-SP1-Release-Build20-20210518-x86_64.iso  --disk /root/virtual-machine/kylin-sp1-210528.qcow2,format=qcow2 --network network=default --graphics vnc,listen=0.0.0.0,port=5913 --os-type=linux 
-->

## vnc软件

### ubuntu

Ubuntu 服务端 `Settings -> Sharing -> Screen Sharing -> 启用旧式vnc协议 -> 打开远程控制`。

在客户端`Remmina`输入: `sonvhi-XPS-13-9305.local`(`hostname.local`)或 ip, 注意前面不能有`vnc://`，连接后点击`切换绽放模式`。

### macOS

服务端`System Settings` -> `General` -> `Sharing` -> `Screen Sharing` -> `开关右侧的i号`。

客户端可以使用系统自带的屏幕共享，`Spotlight Search`(command+space)搜索`Screen Sharing`（屏幕共享），然后直接输入ip。
还可以在Finder（访达）中按`cmd+k`跳出输入框（或在浏览器中直接输入），输入`vnc://${server_ip}:${port_number`。自带的屏幕共享鼠标功能支持更好。

客户端还可以使用[tightvnc](https://www.tightvnc.com/)，在[appstore安装Remote Ripple](https://remoteripple.com/download/)。鼠标功能支持不够（至少在连接ubuntu时）。

### tightvnc

Linux下的[tightvnc](https://www.tightvnc.com/)，客户端 xtightvncviewer, 服务端 tightvncserver。服务端 tightvncserver 启动后，客户端连接后画面一片灰，原因暂时不明，推荐使用上面系统自带的 vnc 软件。

## QEMU+VNC安装系统

通过iso文件安装Linux发行版时，要么在物理机上安装，要么在virt-manager上安装，如果我们想在没有图形界面的server环境上用命令行安装一个图形界面发行版，可以使用qemu+vnc来实现。下面我们以麒麟系统桌面发行版安装为例说明qemu+vnc的安装过程。

首先挂载iso文件，并把文件复制出来:
```sh
mkdir mnt
sudo mount Kylin-Desktop-V10-SP1-General-Release-2303-X86_64.iso mnt -o loop
mkdir tmp
cp mnt/. tmp/ -rf
sudo umount mnt
```

创建qcow2文件，并运行虚拟机:
```sh
qemu-img create -f qcow2 Kylin-Desktop-V10-SP1-General-Release-2303-X86_64.qcow2 512G
qemu-system-x86_64 \
-m 4096M \
-smp 16 \
-boot c \
-cpu host \
--enable-kvm \
-hda Kylin-Desktop-V10-SP1-General-Release-2303-X86_64.qcow2 \
-cdrom Kylin-Desktop-V10-SP1-General-Release-2303-X86_64.iso \
-kernel tmp/casper/vmlinuz \
-initrd tmp/casper/initrd.lz \
-vnc :1
```

vnc客户端可以使用ubuntu自带的Remmina（当然也可以使用其他vnc客户端），连接`${server_ip}:5901`，端口`5901`是由`-vnc :1`决定的（`5900 + 1`）。
macOS除了使用macOS自带的`Screen Sharing`（屏幕共享），还可以使用[appstore安装的Remote Ripple](https://remoteripple.com/download/)。

安装完成后，再运行:
```sh
qemu-system-x86_64 \
-enable-kvm \
-cpu host \
-smp 16 \
-m 4096 \
-device virtio-scsi-pci \
-drive file=Kylin-Desktop-V10-SP1-General-Release-2303-X86_64.qcow2,if=none,format=qcow2,cache=writeback,file.locking=off,id=root \
-device virtio-blk,drive=root,id=d_root \
-net nic,model=virtio,macaddr=00:11:22:33:44:55 \
-net bridge,br=virbr0 \
-vnc :1
```

但arm64的麒麟桌面系统没法这样安装（但可在virt-manager中安装），暂时还没找到原因。

可以在arm芯片的mac电脑中用vmware fusion安装arm64的ubuntu。

# 我的常用软件

这是我的开发环境上的一些配置，方便自己的查阅

## ubuntu

我平时工作用的是ubuntu桌面系统。

常用的软件安装:
```sh
strings /lib/x86_64-linux-gnu/libc.so.6 | grep GLIBC_ # 查看支持的glibc版本

sudo apt install openssh-server -y # 默认桌面版本ubuntu不会安装ssh server
sudo apt install ibus*wubi* -y # 安装五笔，要重启才可用
sudo apt-get install fuse -y # v2ray的Linux桌面版本 V2Ray-Desktop-v2.4.0-linux-x86_64.AppImage 无法运行
sudo apt install tmux -y # Tmux（缩写自"Terminal Multiplexer"）是一个在命令行界面下运行的终端复用工具，我主要是用tmux的会话附加和分离功能
sudo apt install lxterminal -y # 这玩意儿比ubuntu默认的terminal更好用，是树莓派系统上默认的terminal

sudo apt install exfat-utils -y # exfat文件系统所需的工具

# 只在ubuntu2204上验证过，安装查看tcpdump工具收集的网络包的wireshark: https://launchpad.net/~wireshark-dev/+archive/ubuntu/stable
sudo add-apt-repository ppa:wireshark-dev/stable
sudo apt update
sudo apt install wireshark -y

# 安装游戏软件stem时需要安装的依赖软件，但steam里的游戏在ubuntu下根本跑不动（我在戴尔笔记本xps13上试过cs非常卡）
sudo apt install libc6-i386 libgl1:i386 -y # for steam
```

通过`sudo apt install ./xxxx.deb -y`安装的软件，卸载用以下命令:
```sh
sudo apt list --installed | grep wkhtmltox
sudo apt purge wkhtmltox -y
```

## fedora

安装软件:
```sh
sudo dnf group install development-tools -y # fedora41不能用groupinstall，必须要两个单词group install
strings /lib64/libc.so.6 | grep ^GLIBC_ # 查看支持的glibc版本
```

# 其他系统的一些笔记

## centos

centos的开发软件生态比ubuntu还是稍微差一些，尤其是桌面系统。

常用软件安装:
```sh
sudo dnf groupinstall "development tools" -y # 编译常用软件
sudo dnf install qemu-kvm virt-manager libvirt -y # 虚拟机相关软件
sudo systemctl restart libvirtd # 需要重启libvirtd，否则虚拟机有些功能无法使用
sudo dnf install ncurses-devel -y # 内核编译所需

# centos9需要通过源码安装bridge-utils，https://wiki.linuxfoundation.org/networking/bridge
git clone -b main git://git.kernel.org/pub/scm/network/bridge/bridge-utils.git
cd bridge-utils
autoconf
./configure
```

默认centos9是打开selinux的，但个人用户没有那么高的安全需求时，可以关闭selinux:
```sh
sudo vim /etc/selinux/config # centos9 改成 SELINUX=disabled
```

## 树莓派

从[Operating system images](https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-os-64-bit)下载“Raspberry Pi OS with desktop and recommended software”。

向SD卡烧录系统:
```sh
sudo dd bs=4M if=解压之后的img of=/dev/sdb
```

图形界面的树莓派系统的常用软件安装:
```sh
# 解决git无法显示中文
git config --global core.quotepath false

# 安装五笔，需要重启
sudo apt-get update -y
sudo apt install ibus*wubi* -y

# 安装firefox
# sudo apt update -y
# sudo apt-get install iceweasel -y

sudo apt update -y
# 安装emacs
sudo apt install emacs -y
# 安装gvim
sudo apt install vim-gtk3 -y
```

含代理服务器选项，chrome浏览器启动命令:
```sh
chromium-browser --proxy-server="https=127.0.0.1:1080;http=127.0.0.1:1080;ftp=127.0.0.1:1080"
```

## 麒麟系统

填写[产品试用申请](https://www.kylinos.cn/support/trial.html)后就可以下载iso文件。

注意桌面麒麟系统在arm芯片的macos上无法用vmware fusion安装，可以用[UTM](https://github.com/utmapp/UTM)安装。

<!--
UTM安装时磁盘格式使用raw可能有以下问题（使用qcow2格式镜像就没有以下问题）:
安装虚拟机时cpu、内存、硬盘不要分配太大，比如我用的是M2的Macbook Air（8G内存，8核，256G硬盘），只需分配2G内存（已验证分配4G无法安装），磁盘64G（默认分区方式要求硬盘必须大于50G）。
安装完成后再次启动前可以把配置改大，但8G内存的电脑分配的内存不要超过2G，否则容易卡死（比如当启动其他虚拟机时）。安装时最好使用自定义分区，`efi`分区`512M`（注意要在下拉选项中选择），
swap分区可以分配稍大一些，剩下全给`/`，备份分区在虚拟机中就不分配了。注意要修改成不休眠，默认10分钟锁屏幕，15分钟进入休眠，utm虚拟机就无法唤醒了。
-->

基于openeuler的服务器麒麟系统用`qemu`命令行启动时，编辑网络用命令`nmtui`，网络接口名改成和`ifconfig`中一样的名，再`启用连接 -> 激活`。arm64版本无法用[VMware以及UTM等虚拟机安装](https://gitee.com/src-openeuler/kernel/issues/I7LDS2)，可以尝试用[EulerLauncher](https://gitee.com/openeuler/eulerlauncher/tree/master/docs)安装（还可以参考[openeuler文档中的EulerLauncher](https://gitee.com/openeuler/docs/tree/master/docs/zh/docs/EulerLauncher)）。

一直提示“发现未认证应用执行”的解决办法，打开`/etc/default/grub`，修改为`GRUB_CMDLINE_LINUX_SECURITY="security="`，更新grub配置`sudo update-grub`，最后，重启系统。

## arcolinux

[ArcoLinux](https://arcolinux.com/)是[Arch Linux](https://archlinux.org/)的衍生发行版。

