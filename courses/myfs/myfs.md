<!--
https://github.com/namjaejeon/ksmbd/blob/master/README.md
https://github.com/namjaejeon/ksmbd/blob/master/Makefile
-->
由于工作需要，写了一个功能最简单的文件系统，想着再完善一下，当成公开课素材，一来觉得挺好玩，二来觉得可以自己的简历也需要这么一个项目。

这个"我的"（my）文件系统不是为了生产目的，目前只用于学习目的，欢迎更多的朋友来完善，可以参考其他文件系统的代码（当然不能整段copy），但请标明出处。

[点击这里访问代码仓库](https://gitee.com/chenxiaosonggitee/myfs)。

# 编译

## 独立模块编译

修改[`Makefile`](https://gitee.com/chenxiaosonggitee/myfs/blob/master/Makefile)文件中的`KDIR`变量对应内核仓库的路径，在[代码仓库](https://gitee.com/chenxiaosonggitee/myfs)执行以下命令:
```sh
make # 生成 myfs.ko
# make clean # 清理编译生成的文件
```

## 作为内核一部分编译

到内核仓库打上补丁[`0001-add-support-for-myfs.patch`](https://gitee.com/chenxiaosonggitee/myfs/blob/master/0001-add-support-for-myfs.patch)，再把[整个代码仓库目录`myfs`](https://gitee.com/chenxiaosonggitee/myfs)复制到内核仓库的`fs`目录下。

然后到内核仓库中执行以下命令:
```sh
make O=x86_64-build menuconfig
make O=x86_64-build bzImage -j`nproc`
make O=x86_64-build modules -j`nproc`
```
