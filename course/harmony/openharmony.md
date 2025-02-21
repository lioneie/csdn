[点击这里跳转到陈孝松OpenHarmony贡献](https://chenxiaosong.com/course/harmony/contribution.html)。

# 环境

开发板使用[大禹系列｜HH-SCDAYU200开发套件（Quad-core Cortex-A55 up to 2.0GHz）](http://www.hihope.org/pro/pro1.aspx?mtt=54)。

## docker环境搭建

在宿主机环境上可能会遇到各种各样的问题，可以使用 docker 编译, 以ubuntu22.04为例，说明环境的搭建。

[`hb`工具安装指导](https://gitee.com/openharmony/docs/blob/master/zh-cn/device-dev/quick-start/quickstart-pkg-install-tool.md)

```sh
# 获取代码环境
apt-get update -y && apt-get install python3 python3-pip -y
apt-get install git git-lfs -y
mkdir -p ~/.local/bin/
curl -s https://gitee.com/oschina/repo/raw/fork_flow/repo-py3 > /home/sonvhi/chenxiaosong/sw/repo
chmod a+x ~/.local/bin/repo
pip3 install -i https://repo.huaweicloud.com/repository/pypi/simple requests
ln -s /usr/bin/python3 /usr/bin/python

# 编译环境
apt-get update && apt-get install binutils git git-lfs gnupg flex bison gperf build-essential zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z1-dev ccache libgl1-mesa-dev libxml2-utils xsltproc unzip m4 bc gnutls-bin python3 python3-pip ruby libtinfo-dev libtinfo5 -y
apt install file -y
apt-get install default-jdk -y # 如果报错: javac: command not found
apt install libelf-dev -y # error: Cannot resolve BTF IDs for CONFIG_DEBUG_INFO_BTF
apt-get install libssl-dev -y # scripts/extract-cert.c:21:10: fatal error: 'openssl/bio.h' file not found
apt install liblz4-tool -y # /bin/sh: 1: lz4c: not found
apt-get install genext2fs -y # make-boot.sh: line 22: genext2fs: command not found
apt-get install cpio -y

# 头文件找不到解决方法
apt install apt-file -y
apt-file search X11/Xcursor/Xcursor.h # libxcursor-dev: /usr/include/X11/Xcursor/Xcursor.h
apt-file search X11/extensions/Xrandr.h # libxrandr-dev: /usr/include/X11/extensions/Xrandr.h
apt-file search X11/extensions/Xinerama.h # libxinerama-dev: /usr/include/X11/extensions/Xinerama.h
apt install libxcursor-dev libxrandr-dev libxinerama-dev -y
```

## 获取代码

[HiHope_DAYU200 搭建开发环境](https://gitee.com/hihope_iot/docs/blob/master/HiHope_DAYU200/%E5%BC%80%E5%8F%91%E7%8E%AF%E5%A2%83%E6%90%AD%E5%BB%BA%E7%BC%96%E8%AF%91%E6%8C%87%E5%8D%97.md)。

还可以参考openharmony[获取源码](https://gitee.com/openharmony/docs/blob/master/zh-cn/device-dev/quick-start/quickstart-pkg-sourcecode.md)

执行以下命令获取代码:
```sh
repo init -u https://gitee.com/openharmony/manifest.git -b master --no-repo-verify && repo sync -c && repo forall -c 'git lfs pull' && bash build/prebuilts_download.sh
```

## 编译

编译命令如下:
```sh
# 镜像输出在 out/rk3568/packages/phone/images 目录下
# 32位
./build.sh --product-name rk3568 --ccache
./build.sh --product-name rk3568 --ccache --fast-rebuild # --fast-rebuild 增量编译时跳过一些已经完成的步骤
./build.sh --product-name rk3568 --ccache --build-target dfs_service --fast-rebuild
# 64位
./build.sh --product-name rk3568 --ccache --target-cpu arm64
./build.sh --product-name rk3568 --ccache --target-cpu arm64 --fast-rebuild # 增量编译时跳过一些已经完成的步骤
./build.sh --product-name rk3568 --ccache --target-cpu arm64 --build-target dfs_service --fast-rebuild # --build-target dfs_service 只编译某个service
```

# 运行和调试

## 烧写

linux上压缩image文件:
```sh
zip -jr images.zip out/rk3568/packages/phone/images/
```

[烧写工具及指南](https://gitee.com/hihope_iot/docs/tree/master/HiHope_DAYU200/%E7%83%A7%E5%86%99%E5%B7%A5%E5%85%B7%E5%8F%8A%E6%8C%87%E5%8D%97)。

特别需要注意的是: 软件路径中不要含有中文，尤其是对英文版的windows系统。

windows安装`DriverAssitant_v5.1.1\DriverInstall.exe`后，打开`RKDevTool.exe`， 配置以下路径:
```sh
0x00000000 Loader MiniLoaderAll.bin
0x00000000 Parameter parameter.txt
0x00002000 Uboot uboot.img
0x00006000 resource resource.img
0x00004000 misc 可不选
0x00009000 Boot_linux boot_linux.img
0x00039000 ramdisk ramdisk.img
0x0003B000 System system.img
0x0043B000 Vendor vendor.img
0x0063B000 sys-prod 可不选
0x00654000 chip-prod 可不选
0x0066D000 updater updater.img
0x00677000 Userdata userdata.img
```

配置重新导出为文件`config.cfg`。

winodws usb线连接rk3568板子上的`usb3.0 OTG`，在rk3568板子上按`reset`键，再长按`vol+/recovery`键，进入loader模式，点击`RKDevTool`工具上的`执行`按钮。可以只烧录`System`和`Userdata`（包含数据库）。

复制so文件的脚本`scp_dfs_service_so.bat`:
```sh
scp -r -P 55555 sonvhi@chenxiaosong.com:/home/sonvhi/chenxiaosong/code/openharmony/openharmony/out/rk3568/filemanagement/dfs_service/ .
@pause
```

传输so文件到板子上的脚本`push_dfs_service_so.bat`:
```sh
hdc shell mount -o rw,remount /

hdc file send .\dfs_service\libcloud_adapter.z.so                           /system/lib/
hdc file send .\dfs_service\libcloud_daemon_kit_inner.z.so                  /system/lib/
hdc file send .\dfs_service\libcloudfiledaemon.z.so                         /system/lib/
hdc file send .\dfs_service\libcloudsync_asset_kit_inner.z.so               /system/lib/platformsdk/
hdc file send .\dfs_service\libcloudsync_kit_inner.z.so                     /system/lib/
hdc file send .\dfs_service\libcloudsyncmanager.z.so                        /system/lib/module/file/
hdc file send .\dfs_service\libcloudsync_sa.z.so                            /system/lib/
hdc file send .\dfs_service\libcloudsync.z.so                               /system/lib/module/file/
hdc file send .\dfs_service\libdistributed_file_daemon_kit_inner.z.so       /system/lib/
hdc file send .\dfs_service\libdistributedfiledaemon.z.so                   /system/lib/
hdc file send .\dfs_service\libdistributedfiledentry.z.so                   /system/lib/
hdc file send .\dfs_service\libdistributedfileutils.z.so                    /system/lib/

hdc shell sync
hdc shell reboot
@pause
```

## hdc工具

[hdc使用指导](https://docs.openharmony.cn/pages/v3.2/zh-cn/device-dev/subsystems/subsys-toolchain-hdc-guide.md/), [hdc_std使用指导](https://docs.openharmony.cn/pages/v3.1/zh-cn/device-dev/subsystems/subsys-toolchain-hdc-guide.md/)。

`hdc`工具从[每日构建](http://ci.openharmony.cn/workbench/cicd/dailybuild/dailylist)中搜索`ohos-sdk`。

`hdc shell` usb线连接rk3568板子上的`usb3.0 OTG`，**注意不是`DEBUG`串口**。

如果始终无法连接，`win+r`，输入`regedit`回车，找到注册表 `计算机\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{88bae032-5a81-49f0-bc3d-a4ff138216d6}`，确认是否有`Upperfilters`和`Lowerfilters`，删除后重新插拔。

```sh
# 从开发板上获取数据库文件
hdc file recv /data/app/el2/100/database/com.ohos.medialibrary.medialibrarydata/rdb/media_library.db .
hdc file recv /data/app/el2/100/database/com.ohos.medialibrary.medialibrarydata/rdb/media_library.db-wal .
hdc file recv /data/app/el2/100/database/com.ohos.medialibrary.medialibrarydata/rdb/media_library.db-shm .
# 整个文件夹
hdc file recv /data/app/el2/100/database/com.ohos.medialibrary.medialibrarydata/rdb/. .
# 向开发板发送数据库文件
hdc file send .\media_library.db /data/app/el2/100/database/com.ohos.medialibrary.medialibrarydata/rdb
hdc file send .\media_library.db-wal /data/app/el2/100/database/com.ohos.medialibrary.medialibrarydata/rdb
hdc file send .\media_library.db-shm /data/app/el2/100/database/com.ohos.medialibrary.medialibrarydata/rdb
```

## 关闭selinux

有些功能可能会被selinux阻止，可以关闭selinux测试:
```sh
mount -o rw,remount / # 重新可读可写挂载
echo "SELINUX=permissive" > /etc/selinux/config # 重启后生效，默认是 SELINUX=enforcing
setenforce 0
sync
```

## 日志

`hilog`日志设置:
```sh
# -w 开启日志落盘任务，start表示开始，stop表示停止
# -f 设置日志文件名
# -l 单个日志文件大小
hilog -w start -f cxsTest -l 1M -n 5 -m zlib -j 11

hilog -Q domainoff
hilog -p off # -p <on/off>, --privacy <on/off>
hilog -Q pidoff
hilog -Q domainoff
hilog -r
hilog -G 20M
hilog --baselevel=DEBUG
hilog | grep "CloudFileDaemon\|CLOUDSYNC_SA\|StorageDaemon" # 端云协同的日志
```

## crash调试

当程序crash时，可以把相关日志文件导出来分析:
```sh
hdc file recv /data/log/faultlog/faultlogger/. .
```

日志文件如下:
```
Generated by HiviewDFX@OpenHarmony
================================================================
Device info:OpenHarmony 3.2
Build info:OpenHarmony 4.0.7.1
Module name:cloudfiledaemon
Pid:516
Uid:1009
Reason:Signal:SIGSEGV(SEGV_MAPERR)@     (nil) 
Thread name:cloudfiledaemon
#00 pc 0000d2b8 /system/lib/libcloudfiledaemon.z.so(3d07c6d63b58da9d13918497b907cd8a)
#01 pc 000c7718 /system/lib/ld-musl-arm.so.1
#02 pc 00066078 /system/lib/ld-musl-arm.so.1
```

找到 `libcloudfiledaemon` 相关的库文件:
```sh
find out -name "libcloudfiledaemon*"
# 注意要选unstripped: out/rk3568/lib.unstripped/filemanagement/dfs_service/libcloudfiledaemon.z.so
```

找出 `0000d2b8` 对应的代码行:
```sh
# 找到foundation/filemanagement/dfs_service/services/cloudfiledaemon/src/fuse_manager/fuse_manager.cpp:353
prebuilts/gcc/linux-x86/aarch64/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-addr2line -e out/rk3568/lib.unstripped/filemanagement/dfs_service/libcloudfiledaemon.z.so -a 0000d2b8 # 32位用aarch64-linux-gnu-addr2line

prebuilts/clang/ohos/linux-x86_64/15.0.4/llvm/bin/llvm-addr2line -e out/rk3568/lib.unstripped/filemanagement/dfs_service/libcloudfiledaemon.z.so -a xxxxxxxx # 64位要用llvm-addr2line
```

## qemu运行调试环境

[device_qemu](https://gitee.com/openharmony/device_qemu#https://gitee.com/openharmony/device_qemu/blob/HEAD/arm_mps3_an547/README_zh.md)

[QEMU教程 for arm - linux](https://gitee.com/openharmony/device_qemu/blob/HEAD/arm_virt/linux/README_zh.md)

```sh
# 编译qemu-arm-linux-headless失败的issue，还未解决: https://gitee.com/openharmony/device_qemu/issues/I6AH7L?from=project-issue
docker run --rm -v "$PWD":/usr/src/myapp -w /usr/src/myapp ubuntu-openharmony:22.04 ./build.sh --product-name qemu-arm-linux-headless --ccache --jobs 64
docker run --rm -v "$PWD":/usr/src/myapp -w /usr/src/myapp ubuntu-openharmony:22.04 ./build.sh --product-name qemu-arm-linux-min --ccache --jobs 64
```

# tdd

合入补丁[0001-fuse-read-debug-dentry_meta_file_test-tdd.patch](https://gitee.com/chenxiaosonggitee/blog/blob/master/course/harmony/src/0001-fuse-read-debug-dentry_meta_file_test-tdd.patch)后，编译和运行tdd:
```sh
# 含调试信息的编译结果: out/rk3568/exe.unstripped/tests/unittest/filemanagement/dfs_service/dentry_meta_file_test
# 不含调试信息的编译结果: out/rk3568/tests/unittest/filemanagement/dfs_service/dentry_meta_file_test
./build.sh --product-name rk3568 --ccache --build-target dentry_meta_file_test --fast-rebuild # 32位
./build.sh --product-name rk3568 --ccache --target-cpu arm64 --build-target dentry_meta_file_test --fast-rebuild # 64位

# 从windows复制到 rk3568 板子上运行
hdc shell rm /data/dentry_meta_file_test -rf
hdc file send .\dentry_meta_file_test /data
hdc shell
chmod a+x /data/dentry_meta_file_test
cd /data/
/data/dentry_meta_file_test --gtest_list_tests
rm -rf /data/service/el2/100/hmdfs/cache/account_cache/dentry_cache/*
/data/dentry_meta_file_test --gtest_filter=DentryMetaFileTest.MetaFileCreate

# 改变dentryfile目录权限
chmod -R 777 /data/service/el2/100/hmdfs/cache/account_cache/dentry_cache/
ls -lh /data/service/el2/100/hmdfs/cache/account_cache/dentry_cache/cloud/ # 检查

# device_view目录
ls -lh /mnt/hmdfs/100/account/device_view/cloud/
cat /mnt/hmdfs/100/account/device_view/cloud/dir1/dir2/file4

# cloud_merge_view目录
ls -lh /mnt/hmdfs/100/account/cloud_merge_view/
cat /mnt/hmdfs/100/account/cloud_merge_view/dir1/dir2/file4
```

storage_daemon 单元测试:
```shell
./build.sh --product-name rk3568 --cacch --target-cpu arm64 --build-target storage_daemon_unit_test --build-target storage_manager_unit_test
```


# libfuse在qemu虚拟机中运行调试

```sh
# 安装依赖软件
apt install meson -y
apt install cmake -y
apt-get install pkg-config -y
apt install udev -y

# 编译安装
git clone https://github.com/libfuse/libfuse.git
cd libfuse
mkdir build; cd build
meson setup ..
meson configure -D buildtype=debug
ninja
ninja install # 运行 example 可以不安装

mkdir -p /mnt/cloud_dir
# gdb调试: ./example/passthrough_ll -o source=/tmp /mnt/cloud_dir -d
gdb ./example/passthrough_ll
(gdb) set args -o source=/tmp /mnt/cloud_dir -d # 设置运行选项
(gdb) b lo_lookup
(gdb) r
```

# hmdfs在qemu虚拟机中调试

[kernel_linux_5.10](https://gitee.com/openharmony/kernel_linux_5.10)在虚拟机中运行:
```sh
mkdir -p /mnt/dst
mkdir -p /mnt/cache_dir/dentry_cache/cloud
mkdir -p /mnt/cloud_dir
mkdir -p /mnt/src
echo 123456789 > /mnt/cloud_dir/file1
# 设置xattr，dentryfile文件由tdd生成，注意复制到其他系统，xattr要重新设置
setfattr -n user.hmdfs_cache -v "/" /mnt/cache_dir/dentry_cache/cloud/cloud_000000000000002f
setfattr -n user.hmdfs_cache -v "/dir1" /mnt/cache_dir/dentry_cache/cloud/cloud_0000000002c55df3
setfattr -n user.hmdfs_cache -v "/dir1/dir2" /mnt/cache_dir/dentry_cache/cloud/cloud_0004ba7c447bbfe1
# 挂载
mount -t hmdfs -o merge,local_dst=/mnt/dst,cache_dir=/mnt/cache_dir,cloud_dir=/mnt/cloud_dir /mnt/src /mnt/dst
# 输出云端文件内容
ls /mnt/dst/device_view/cloud/
cat /mnt/dst/device_view/cloud/file1
```