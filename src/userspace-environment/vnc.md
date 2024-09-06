<!--
https://blog.csdn.net/u011795345/article/details/78681213
https://cloud.tencent.com/developer/article/2148538

virt-install --virt-type kvm --name kylin-desktop --vcpus=4 --ram 4096 --cdrom=Kylin-Desktop-V10-SP1-General-Release-2303-ARM64.iso --disk image.qcow2,format=qcow2 --network network=default --graphics vnc,listen=0.0.0.0,port=5955 --os-type=linux

qemu-img create -f qcow2 kylin-sp1-210528.qcow2 100G
virt-install --virt-type kvm --name kylin-sp1-210528 --vcpus=4 --ram 4096 --cdrom=/root/virtual-machine/Kylin-Server-10-SP1-Release-Build20-20210518-x86_64.iso  --disk /root/virtual-machine/kylin-sp1-210528.qcow2,format=qcow2 --network network=default --graphics vnc,listen=0.0.0.0,port=5913 --os-type=linux 

-->

# vnc软件

## ubuntu

Ubuntu 服务端 `Settings -> Sharing -> Screen Sharing -> 启用旧式vnc协议 -> 打开远程控制`。

在客户端`Remmina`输入: `sonvhi-XPS-13-9305.local`(`hostname.local`)或 ip, 注意前面不能有`vnc://`，连接后点击`切换绽放模式`。

## macOS

服务端`System Settings` -> `General` -> `Sharing` -> `Screen Sharing` -> `开关右侧的i号`。

客户端可以使用系统自带的屏幕共享，`Spotlight Search`(command+space)搜索`Screen Sharing`，然后直接输入ip。还可以在Finder（访达）中按`cmd+k`跳出输入框，或在浏览器中，输入`vnc://${server_ip}`。自带的屏幕共享鼠标功能支持更好。

客户端还可以使用[tightvnc](https://www.tightvnc.com/)，在[appstore安装Remote Ripple](https://remoteripple.com/download/)。鼠标功能支持不够（至少在连接ubuntu时）。

## [tightvnc](https://www.tightvnc.com/)

Linux下，客户端 xtightvncviewer, 服务端 tightvncserver。服务端 tightvncserver 启动后，客户端连接后画面一片灰，原因暂时不明，推荐使用上面系统自带的 vnc 软件。

# QEMU+VNC安装系统

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

vnc客户端可以使用ubuntu自带的Remmina（当然也可以使用其他vnc客户端），连接`${server_ip}:5901`，端口`5901`是由`-vnc :1`决定的（`5900 + 1`）。macOS要使用[appstore安装的Remote Ripple](https://remoteripple.com/download/)，好像无法使用macOS自带的vnc客户端。

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

但arm64的麒麟桌面系统没法这样安装，暂时还没找到原因。

可以在arm芯片的mac电脑中用vmware fusion安装arm64的ubuntu。
