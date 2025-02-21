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
