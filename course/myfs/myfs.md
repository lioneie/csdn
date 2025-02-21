由于工作需要，写了一个功能最简单的文件系统，想着再完善一下，当成公开课素材，一来觉得挺好玩，二来觉得可以自己的简历也需要这么一个项目。

这个"我的"（my）文件系统不是为了生产目的，目前只用于学习目的，欢迎更多的朋友来完善，可以参考其他文件系统的代码（当然不能整段copy），但请标明出处。

[点击这里访问代码仓库](https://gitee.com/chenxiaosonggitee/myfs)。

# 参考

- [《Linux内核文件系统》](https://chenxiaosong.com/course/kernel/fs.html)
- [`ksmbd/README.md`](https://github.com/namjaejeon/ksmbd/blob/master/README.md)
- [`ksmbd/Makefile`](https://github.com/namjaejeon/ksmbd/blob/master/Makefile)

# 编译

## 独立模块编译

修改[`Makefile`](https://gitee.com/chenxiaosonggitee/myfs/blob/master/Makefile)文件中的`KDIR`变量对应Linux内核仓库的路径，然后在[`myfs`代码仓库](https://gitee.com/chenxiaosonggitee/myfs)执行以下命令:
```sh
make # 生成 myfs.ko
# make clean # 清理编译生成的文件
```

## 作为内核一部分编译

把[整个代码仓库目录`myfs`](https://gitee.com/chenxiaosonggitee/myfs)复制到Linux内核仓库的`fs`目录下。然后到内核仓库中执行以下命令:
```sh
git am fs/myfs/0001-add-support-for-myfs.patch
mv fs/myfs/Makefile.kernel fs/myfs/Makefile
make O=x86_64-build menuconfig
make O=x86_64-build bzImage -j`nproc`
make O=x86_64-build modules -j`nproc`
```

## todo

本来想和[`ksmbd/Makefile`](https://github.com/namjaejeon/ksmbd/blob/master/Makefile)中一样用`ifneq ($(KERNELRELEASE),)`隔离开独立模块和作为内核一部分，但好像没什么卵用，对makefile熟悉的朋友可以告诉我要怎么写。

# 使用

## 调试日志

参考[`fs/smb/server/server.c`](https://github.com/torvalds/linux/blob/master/fs/smb/server/server.c)写了一个日志开关功能，使用请参考[《smb调试方法》](https://chenxiaosong.com/course/smb/debug.html)。

控制命令如下:
```sh
cat /sys/class/myfs-ctrl/debug # 查看日志开关，打开的日志类型有中括号
echo all > /sys/class/myfs-ctrl/debug # 全部切换
echo main > /sys/class/myfs-ctrl/debug # 只切换main
```

## 挂载

用以下命令挂载:
```sh
mount -t myfs /dev/sda /mnt
mount
lsblk
df
umount /mnt
```

如果编译内核打开了`CONFIG_BLK_DEV_LOOP`配置，可以挂载文件:
```sh
mount -t myfs -o loop /dev/sda /mnt
```

## 文件操作

```c
#include <stdio.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <errno.h>
#include <fcntl.h>
#include <linux/limits.h>

int main()
{
        int res = syscall(__NR_openat, AT_FDCWD, "/mnt", O_RDONLY|O_NONBLOCK|O_CLOEXEC|O_DIRECTORY);
        printf("result: %d\n", res);

        return 0;
}
```

# 开发过程

文件系统的模块加载函数是`init_myfs()`，模块卸载函数是`exit_myfs()`。可作为独立模块编译，也可作为内核一部分编译，内核配置选项是`CONFIG_MYFS`。

引入`struct file_system_type myfs_fs_type`，实现`.mount`和`.kill_sb`方法，但测试发现mount时会panic，用`scripts/faddr2line`脚本解析栈信息，发现在`legacy_get_tree()`中得到的`struct dentry *root`为空，所以是还没能得到`root`的`dentry`和`inode`。

为了方便调试，引入调试日志函数接口`myfs_debug()`。接着在`myfs_fill_super()`函数中获取`root inode`，但mount时却报错: `mount: /mnt: mount(2) system call failed: Not a directory.`。查看代码发现是`root inode`不是目录类型，所以将`root inode`的`i_mode`设置成目录类型，这时就能挂载成功。

但这时`df -Th`命令还不能输出`myfs`相关的信息，引入`struct super_operations myfs_sops`且实现`.statfs`方法，`df -Th`命令就可输出相关信息。

引入`myfs_dir_operations`和`myfs_file_operations`，但是`ls /mnt`还是报错`ls: cannot open directory '/mnt': Not a directory`，具体原因待定位。
<!--
```c
openat
  do_sys_open
    do_sys_openat2
      do_filp_open
        path_openat
          do_open
            vfs_open
              do_dentry_open
                ext2_dir_open
```
-->

