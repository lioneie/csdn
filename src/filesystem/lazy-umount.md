# 描述

执行以下命令:
```sh
fallocate -l 10M image
mkfs.ext4 -F image
mount -t ext4 image /mnt
vim /mnt/file & # 或者 cd /mnt
umount --lazy /mnt
```

这时，通用的一些命令如`df`、`mount`等看不到挂载实例。
