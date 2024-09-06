这里记录一下微软的几个文件系统的一些笔记，稍微用了一下，也顺便发过两个ntfs相关的补丁。

# ntfs

ntfs是只读文件系统，挂载步骤:
```sh
apt install ntfs-3g -y # mkfs.ntfs
fdisk /dev/sda # 新建分区 /dev/sda1
mkfs.ntfs /dev/sda1
apt remove ntfs-3g -y # 必须要卸载 ntfs-3g，否则会使用 fuse 挂载
mount -t ntfs /dev/sda1 /mnt
```

这里介绍两个syzkaller的问题和我提交的修复补丁。

- [`kernel BUG in ntfs_lookup_inode_by_name`](https://syzkaller.appspot.com/bug?id=c0e6183d33a904a5b7e3d5dedf877c5139b11a53)， 修复补丁: [`ntfs: fix BUG_ON in ntfs_lookup_inode_by_name()`](https://lore.kernel.org/all/20220809064730.2316892-1-chenxiaosong2@huawei.com/)。
- [`KASAN: out-of-bounds Read in ntfs_are_names_equal`](https://syzkaller.appspot.com/bug?id=80913ff3e4962a46fcce7ffd4125fdd1b8e11171)，修复补丁: [`ntfs: fix use-after-free in ntfs_ucsncmp()`](https://lore.kernel.org/all/20220709064511.3304299-1-chenxiaosong2@huawei.com/)。

# vfat

除了要打开`CONFIG_VFAT_FS`配置外，还要打开`CONFIG_NLS_ISO8859_1`等相关的配置。

```sh
apt install dosfstools -y
fdisk /dev/sda # 新建分区 /dev/sda1
mkfs.vfat /dev/sda1
useradd -s /bin/bash -d /home/test -m test # 添加用户test
# 文件的权限固定为 653(777-124)
mount -t vfat -o umask=124,uid=1000,gid=1000 /dev/sda1 /mnt # 1000是用户test的uid

chown root file # 报错Operation not permitted，vfat无法修改文件权限
```

# ntfs3

ntfs3是可读可写文件系统。挂载时指定`ntfs3`:
```sh
mount -t ntfs3 -o umask=124,uid=1000,gid=1000 /dev/sda1 /mnt
```
