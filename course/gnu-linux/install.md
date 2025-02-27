在GNU/Linux发行版的选择上，我们这里是学习的目的，所以就选用能体验最新特性的[Ubuntu](https://ubuntu.com/download)和[Fedora](https://fedoraproject.org/)，都是每年发布两个版本。

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


