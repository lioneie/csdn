此文档是介绍在QEMU/KVM中安装macOS VM的操作。

大多数内容翻译自foxlet所写的项目[README.md](https://github.com/foxlet/macOS-Simple-KVM/blob/master/README.md)，当然也修改和增加了一些内容。

项目[github链接](https://github.com/foxlet/macOS-Simple-KVM/tree/master/docs)。

此项目由[@FoxletFox](https://twitter.com/foxletfox)发起，获得其他许多人的帮助。

macOS和KVM的新手？ 请看[the FAQs](https://github.com/foxlet/macOS-Simple-KVM/tree/master/docs/FAQs.md)。

# 说明

需要说明的是苹果公司不允许macOS系统在非MAC电脑上安装，所以本文的方法请不要用于商业用途，仅供想折腾的极客参考。

我（陈孝松）有一台macbook pro，但还是更喜欢用Linux（Fedora），有极少数的商业软件没有提供Linux版本，又不想用windows系统，所以偶尔使用QEMU/KVM下安装的macOS系统。

# 准备

你将需要一个具有`qemu`（3.1或更高版本），`python3`，`pip`和KVM模块已启用的Linux系统。 **不需要** Mac电脑。 不同发行版的一些安装命令（本人用的是Fedora）：

```sh
sudo apt-get install qemu-system qemu-utils python3 python3-pip  # for Ubuntu, Debian, Mint, and PopOS.
sudo apt-get install qemu-kvm virt-manager bridge-utils -y # ubuntu 20.04

sudo pacman -S qemu python python-pip python-wheel  # for Arch.
sudo xbps-install -Su qemu python3 python3-pip   # for Void Linux.
sudo zypper in qemu-tools qemu-kvm qemu-x86 qemu-audio-pa python3-pip  # for openSUSE Tumbleweed
sudo dnf install @virtualization -y # for Fedora
sudo emerge -a qemu python:3.4 pip # for Gentoo
```

# 第1步

运行`jumpstart.sh`脚本下载macOS的安装介质（需要连接互联网）。 默认安装使用Catalina，但是你可以通过添加`--high-sierra`，`--mojave`或`--catalina`来选择要获取的版本。 例如：

```sh
./jumpstart.sh --catalina
```
> 注意：如果已经下载了`BaseSystem.img`，则可以跳过此步骤。 如果你具有`BaseSystem.dmg`，则需要使用dmg2img工具进行转换。

# 第2步

使用`qemu-img`创建一个空硬盘，根据你的需要修改名称和硬盘大小：

```sh
qemu-img create -f qcow2 MyDisk.qcow2 64G
```

将以下内容添加到`basic.sh`脚本的末尾：

```sh
    -drive id=SystemDisk,if=none,file=MyDisk.qcow2 \
    -device ide-hd,bus=sata.4,drive=SystemDisk \
```
> 注意：如果你运行在headless system (如 Cloud providers),，则需要加 `-nographic` ， 要支持VNC需要加`-vnc：0 -k en-us` 。

然后运行`basic.sh`来启动机器并安装macOS。 请记住首先在“磁盘工具”中进行分区！

# 第2a步 (Virtual Machine Manager)

1. 如果你想导入到Virt-Manager中进行进一步的配置（而不是只在QEMU上运行），只需运行`sudo ./make.sh --add`。
3. 运行上述命令后，在Virt-Manager的设置中添加 `MyDisk.qcow2` SATA Disk。
3. (Fedora需要这步操作，Ubuntu不需要)将 `OVMF_CODE.fd` 和 `OVMF_VARS-1024x768.fd` 放到 `/usr/share/OVMF/macOS/` 路径下（或其他路径，在home目录下会报`OVMF_CODE.fd权限错误`）。
4. 在Virt-Manager中`detail->overview->xml`中将`OVMF_*`路径修改成`/usr/share/OVMF/macOS/`下的文件（**要先允许xml编辑**）
5. Add Hardware -> Storage -> Details -> Select or create custom storage，添加catalina.qcow2
6. Boot Options -> Details -> Boot device order, 勾选 SATA Disk 2 和 3, 并把刚加的SATA Disk 3 放在最前面
7. 开机界面，选择最右边的盘

# 第2b步 (Headless Systems)

如果你使用的是cloud-based/headless system，则可以使用`headless.sh`来设置一个快速的VNC实例。 设置是通过变量定义的，如以下示例所示。 默认情况下，VNC将在端口 `5900` 上启动。

```sh
HEADLESS=1 MEM=1G CPUS=2 SYSTEM_DISK=MyDisk.qcow2 ./headless.sh
```

# 第3步

一切搞定！

要微调系统并提高性能，请查看[docs](https://github.com/foxlet/macOS-Simple-KVM/tree/master/docs)文件夹，以获取更多信息，如[adding memory](https://github.com/foxlet/macOS-Simple-KVM/blob/master/docs/guide-performance.md)，设置[bridged networking](https://github.com/foxlet/macOS-Simple-KVM/blob/master/docs/guide-networking.md)的更多信息，添加 [passthrough hardware (for GPUs)](https://github.com/foxlet/macOS-Simple-KVM/blob/master/docs/guide-passthrough.md)，调整[screen resolution](https://github.com/foxlet/macOS-Simple-KVM/blob/master/docs/guide-screen-resolution.md)并启用声音功能。
