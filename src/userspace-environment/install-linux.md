# virt-manager

`/etc/libvirt/qemu.conf`文件配置:
```sh
user = "root"
group = "libvirt"
```

## `x86_64` `virt-manager`安装`aarch64`系统

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

# ubuntu22.04

我平时工作用的是ubuntu桌面系统。

Linux内核开发相关的环境请查看[《Linux内核课程》](https://chenxiaosong.com/courses/kernel/kernel.html)。

常用的软件安装:
```sh
sudo apt install openssh-server -y # 默认桌面版本ubuntu不会安装ssh server
sudo apt install ibus*wubi* -y # 安装五笔，要重启才可用
sudo apt-get install fuse -y # v2ray的Linux桌面版本 V2Ray-Desktop-v2.4.0-linux-x86_64.AppImage 无法运行
sudo apt install tmux -y # Tmux（缩写自"Terminal Multiplexer"）是一个在命令行界面下运行的终端复用工具，我主要是用tmux的会话附加和分离功能
sudo apt install lxterminal -y # 这玩意儿比ubuntu默认的terminal更好用，是树莓派系统上默认的terminal

sudo apt install exfat-utils -y # exfat文件系统所需的工具

# 安装查看tcpdump工具收集的网络包的wireshark: https://launchpad.net/~wireshark-dev/+archive/ubuntu/stable
sudo add-apt-repository ppa:wireshark-dev/stable
sudo apt update
sudo apt install wireshark -y

sudo apt install samba -y # 在virt-manager中安装windows或macos时，与Linux宿主机共享文件用samba（就是cifs或smb）比较方便
sudo systemctl restart smbd.service # 重启cifs server

strings /lib/x86_64-linux-gnu/libc.so.6 |grep GLIBC_ # 查看glibc的版本，docker中无法编译有些低版本的内核代码

# 安装游戏软件stem时需要安装的依赖软件，但steam里的游戏在ubuntu下根本跑不动（我在戴尔笔记本xps13上试过cs非常卡）
sudo apt install libc6-i386 libgl1:i386 -y # for steam
```

默认`poweroff`和`reboot`等命令可以以非root权限运行，容易误操作，这些命令都软链接到`/bin/systemctl`, 可以用以下命令修改权限:
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

通过`sudo apt install ./xxxx.deb -y`安装的软件，卸载用以下命令:
```sh
sudo apt list --installed | grep wkhtmltox
sudo apt purge wkhtmltox -y
```

# centos 9

centos的开发软件生态比ubuntu还是稍微差一些，尤其是桌面系统。

常用软件安装:
```shell
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

设置hostname:
```sh
sudo hostnamectl set-hostname Threadripper-CentOS9
```

默认centos9是打开selinux的，但个人用户没有那么高的安全需求时，可以关闭selinux:
```sh
sudo vim /etc/selinux/config # centos9 改成 SELINUX=disabled
```

自动挂载磁盘，修改配置文件`/etc/fstab`，添加:
```sh
# 最后２个参数（0 0）的意义: dump, fsck
UUID=b7aa1308-f57e-4f28-834c-c463237a8383 /home/sonvhi/sonvhi/   ext4    errors=remount-ro    0       0
```

# fedora

fedora更新太频繁了，不稳定，不建议用作开发的系统。

安装软件:
```shell
sudo dnf groupinstall "Development Tools" -y
sudo yum install openssl dwarves zstd ncurses-devel -y # 内核编译所需
```

# 树莓派

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

# 麒麟系统

<!-- 公司内网，服务器版本: https://172.30.13.199/release/Release/build/os/ISO/, 桌面版本: https://builder.kylin.com/ -->

填写[产品试用申请](https://www.kylinos.cn/support/trial.html)，以下是各个版本的下载地址:

- [Kylin-Server-V10-SP3-General-Release-2303-X86_64.iso](https://distro-images.kylinos.cn:8802/web_pungi/download/share/vYTMm38Pkaq0KRGzg9pBsWf2c16FUwJL/)
- [Kylin-Server-V10-SP3-2403-Release-20240426-arm64.iso](https://iso.kylinos.cn/web_pungi/download/cdn/ni3tIfZoEKLDglszRXvh9WymuwOT5r6M/)，[Kylin-Server-V10-SP3-General-Release-2303-ARM64.iso](https://distro-images.kylinos.cn:8802/web_pungi/download/share/yYdlHoRzAre1mFPK9s3NviID4Lg5w6MW/)
- [Kylin-Desktop-V10-SP1-General-Release-2303-X86_64.iso](https://distro-images.kylinos.cn:8802/web_pungi/download/share/b4vmX7qEk90dyBrFfS5ANpGngaW2hZUK/)
- [Kylin-Desktop-V10-SP1-HWE-Release-2303-X86_64.iso](https://distro-images.kylinos.cn:8802/web_pungi/download/share/hXaJrnQWscuN2YtS7VAZizRP0EFbH4y3/)
- [Kylin-Desktop-V10-SP1-General-Release-2303-ARM64.iso](https://distro-images.kylinos.cn:8802/web_pungi/download/share/M8UbGlg2WyeHnANzv0srJOEjC9R7ZXDx/)
- [Kylin-Desktop-V10-SP1-General-Release-2303-MIPS64el.iso](https://distro-images.kylinos.cn:8802/web_pungi/download/share/jWbeB9k6FLvySThKilrgX5QUd0cwYtHo/)
- [Kylin-Desktop-V10-SP1-General-Release-2303-LoongArch64.iso](https://distro-images.kylinos.cn:8802/web_pungi/download/share/k1TnrIxSJ5dt47bzAeiOF0upRslgV9hE/)
- [Kylin-Desktop-V10-SP1-General-Release-2303-SW64.iso](https://distro-images.kylinos.cn:8802/web_pungi/download/share/XiGHY0EBQSC8ehIqzfPwaxsRu72vo5VT/)
- [Kylin-Desktop-V10-SP1-2303-update1-Wayland-Release-General-kirin9006c-20230703-ARM64.iso](https://distro-images.kylinos.cn:8802/web_pungi/download/share/d8ug4oiGAQFR7lKsLYOa2tmS9jrW3XT1/)

注意桌面麒麟系统在arm芯片的macos上无法用vmware fusion安装，可以用[UTM](https://github.com/utmapp/UTM)安装。

基于openeuler的服务器麒麟系统用`qemu`命令行启动时，编辑网络用命令`nmtui`，网络接口名改成和`ifconfig`中一样的名，再`启用连接 -> 激活`。arm64版本无法用[VMware以及UTM等虚拟机安装](https://gitee.com/src-openeuler/kernel/issues/I7LDS2)，可以尝试用[EulerLauncher](https://gitee.com/openeuler/eulerlauncher/tree/master/docs)安装（还可以参考[openeuler文档中的EulerLauncher](https://gitee.com/openeuler/docs/tree/master/docs/zh/docs/EulerLauncher)）。

<!-- 使用qcow2格式镜像就没有以下问题: 安装虚拟机时cpu、内存、硬盘不要分配太大，比如我用的是M2的Macbook Air（8G内存，8核，256G硬盘），只需分配2G内存（已验证分配4G无法安装），磁盘64G（默认分区方式要求硬盘必须大于50G）。安装完成后再次启动前可以把配置改大，但8G内存的电脑分配的内存不要超过2G，否则容易卡死（比如当启动其他虚拟机时）。安装时最好使用自定义分区，`efi`分区`512M`（注意要在下拉选项中选择），swap分区可以分配稍大一些，剩下全给`/`，备份分区在虚拟机中就不分配了。注意要修改成不休眠，默认10分钟锁屏幕，15分钟进入休眠，utm虚拟机就无法唤醒了。-->

一直提示“发现未认证应用执行”的解决办法，打开`/etc/default/grub`，修改为`GRUB_CMDLINE_LINUX_SECURITY="security="`，更新grub配置`sudo update-grub`，最后，重启系统。

# arcolinux

[ArcoLinux](https://arcolinux.com/)是[Arch Linux](https://archlinux.org/)的衍生发行版。
