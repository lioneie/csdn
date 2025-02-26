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

# virt-manager

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

