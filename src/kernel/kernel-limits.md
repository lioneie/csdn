# 文件系统限制

## ext

### 最大文件大小

### 最大文件系统大小

ext4文件系统大小支持1EB。

### 最大文件存储数量

### 最大子目录数

<!-- https://blog.51cto.com/u_11529070/10129653 -->
```sh
mkfs.ext4 -F /dev/sda
tune2fs -l /dev/sda # Filesystem features中有dir_nlink
dumpe2fs -h /dev/sda # 或者用dumpe2fs命令
```

以前ext4默认没开`dir_nlink`选项，子目录数量有限制，查看补丁`f8628a14a27e ext4: Remove 65000 subdirectory limit`。现在ext4默认打开`dir_nlink`选项，没有65000个的限制，具体查看`EXT4_FEATURE_RO_COMPAT_SUPP`宏定义。

### 最大符号链接深度

## nfs

## gfs2

## xfs

