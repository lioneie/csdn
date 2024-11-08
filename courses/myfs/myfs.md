由于工作需要，写了一个功能最简单的文件系统，想着再完善一下，当成公开课素材，一来觉得挺好玩，二来觉得可以自己的简历也需要这么一个项目。

这个"我的"（my）文件系统不是为了生产目的，目前只用于学习目的，欢迎更多的朋友来完善，可以参考其他文件系统的代码（当然不能整段copy），但请标明出处。

[点击这里访问代码仓库](https://gitee.com/chenxiaosonggitee/myfs)。

# 参考

- [《Linux内核文件系统》](https://chenxiaosong.com/courses/kernel/kernel-fs.html)
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

# 调试

参考[`fs/smb/server/server.c`](https://github.com/torvalds/linux/blob/master/fs/smb/server/server.c)写了一个日志开关功能，使用请参考[《smb调试方法》](https://chenxiaosong.com/courses/smb/smb-debug.html)。

控制命令如下:
```sh
cat /sys/class/myfs-ctrl/debug # 查看日志开关
echo all > /sys/class/myfs-ctrl/debug # 全部切换
echo main > /sys/class/myfs-ctrl/debug # 只切换main
```