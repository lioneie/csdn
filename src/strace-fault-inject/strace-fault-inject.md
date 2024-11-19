# 源码安装 strace

下载[strace/strace](https://github.com/strace/strace)代码，然后打上补丁[`fault-inject: inject memory allocate failed error`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/strace-fault-inject/0001-fault-inject-inject-memory-allocate-failed-error.patch)。

编译命令如下:
```sh
./bootstrap
mkdir build && cd build
../configure --enable-mpers=no
make
```

# 内核修改

内核代码打上补丁[src/strace-fault-inject/0001-fault-inject-always-print-the-stack.patch](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/strace-fault-inject/0001-fault-inject-always-print-the-stack.patch)，内核配置选项增加文件[src/strace-fault-inject/fault-inject-config.txt](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/strace-fault-inject/fault-inject-config.txt)中的内容。

# 测试

这里说一个我个人通过strace内存分配失败故障注入发现的一个bug，使用的脚本是:
```sh
for i in `seq 1 100000`
do
    mount_options="vers=4.1"
    # fault=${i}表示第几次内存分配注入故障
    strace -f -o output.txt -e trace=mount -e inject=mount:when=1:fault=${i} mount -t nfs -o ${mount_options} localhost:s_test /mnt
    umount /mnt
    echo "strace fault inject i = ${i}"
    OUT=`grep -nr 'FAIL-NTH 0/' output.txt`
    if [ -z "${OUT}" ]; then
        echo "strace fault inject done"
        bread; # 提前结束
    fi
```

当nfsv4.1/4.2挂载时执行到`nfs4_schedule_state_manager`内存分配失败，就会出现`mount`系统调用卡住永远不返回。我的解决方案是[[PATCH v2] NFSv4.1: handle memory allocation failure in nfs4_schedule_state_manager()](https://lore.kernel.org/all/20221112073055.1024799-1-chenxiaosong2@huawei.com/)，只可惜被nfs maintainer一声不响的剽窃了，他的补丁是[NFSv4.x: Fail client initialisation if state manager thread can't run](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=b4e4f66901658fae0614dea5bf91062a5387eda7)，大家可以尝试在主线版本回退这个补丁进行测试。

示例脚本是对nfs的`mount`系统调用进入故障注入，可以换成任何其他的系统调用，也可以换成其他文件系统，当然了，并不局限于文件系统。

除了看循环有没卡住，还可以看`dmesg`命令中有没有空指针解引用以及有没内存之类的报错，还可以看`kmemleak`有没内存泄露。
