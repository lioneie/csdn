我刚接触内核领域主要研究的方向是网络文件系统（nfs、cifs），对块文件系统的了解并不多，所以就从代码量比较小的minix文件系统学起。

# 使用

虚拟机启动时，不能使用4k盘，qemu启动命令`logical_block_size`和`physical_block_size`参数要使用512:
```sh
-drive file=1,if=none,format=raw,cache=writeback,file.locking=off,id=dd_1 \
-device scsi-hd,drive=dd_1,id=disk_1,logical_block_size=512,physical_block_size=512 \
```

格式化磁盘，具体的选项使用`man mkfs.minix`查看:
```sh
mkfs.minix -3 /dev/sda
```

挂载文件系统:
```sh
mount -t minix /dev/sda /mnt
```

或者格式化文件，通过loop设备挂载，注意这时需要打开`CONFIG_BLK_DEV_LOOP`配置。

# 支持长文件名

我们来看一个有趣的问题: 让minix文件系统（v3）支持最大长度4095字节的文件名。

当我们使用`touch`命令创建一个4095字节长度的文件时，会执行到`minix_lookup`函数。而当创建一个4096字节长度的文件时，不会执行到`minix_lookup`函数，说明在`vfs`已经拦截了。

调试的补丁为[`0001-debug-long-filename.patch`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/filesystem/0001-debug-long-filename.patch)，相关代码流程如下:
```c
openat
  do_sys_open
    do_sys_openat2
      getname
        getname_flags
          len = strncpy_from_user(kname, filename, EMBEDDED_NAME_MAX) = 4064 // EMBEDDED_NAME_MAX 为 4096-32
          // touch <4095字节文件名> 时 len = 4095, 会调用到 minix_lookup
          // touch <4096字节文件名> 时 len = 4096, 不会调用到 minix_lookup
          len = strncpy_from_user(kname, filename, PATH_MAX)
          if (unlikely(len == PATH_MAX))
          return ERR_PTR(-ENAMETOOLONG) // touch <4096字节文件名> 时
      do_filp_open
        path_openat
          open_last_lookups
            lookup_open
              minix_lookup
                // s_namelen 的值在 minix_fill_super 中设置，minix v3 为 60字节
                return ERR_PTR(-ENAMETOOLONG) // touch <4095字节文件名> 时
```

如果当路径中前面有其他路径时（如`/mnt/<4095字节文件名>`就有4100个字节），会被vfs拦截，所以当要支持4095字节长度时，要在`vfs`做修改。而大部分文件系统支持的最大文件名长度为255字节，所以我们可以这样设计: 当文件名（普通文件和文件夹）大于255字节时，在`vfs`对文件名做hash映射，当文件名（普通文件和文件夹）大于minix v3文件系统最大支持的60字节时，在minix文件系统对文件名做hash映射。

暂时只对最后一个路径名作hash映射，后续再补充支持对中间路径名进行hash映射，补丁为[`0001-minix-support-long-file-name.patch`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/filesystem/0001-minix-support-long-file-name.patch)。