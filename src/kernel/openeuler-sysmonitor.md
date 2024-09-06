sysmonitor工具通过内核的inotify特性实现文件的监控功能。inotify 是 Linux 内核提供的一种文件系统监视机制，用于监控文件系统事件，比如文件或目录的创建、删除、修改等。它允许应用程序在文件系统发生变化时立即获得通知，而不需要轮询文件系统状态。

相关文档: [docs/sysmonitor](https://gitee.com/openeuler/docs/tree/stable2-22.03_LTS_SP2/docs/zh/docs/sysmonitor)。

# 测试

当前（2023年12月13日）仅在[openEuler内核openEuler-22.03-LTS-SP2分支](https://gitee.com/openeuler/kernel/tree/openEuler-22.03-LTS-SP2/)发布。

下载openeuler的qcow2镜像（可参考[《QEMU/KVM环境搭建与使用》](https://chenxiaosong.com/src/kernel-environment/kernel-qemu-kvm.html)中openeuler相关的章节），安装并启动sysmonitor:
```sh
dnf install sysmonitor -y
systemctl restart sysmonitor
systemctl restart rsyslog
```

编辑`/etc/sysmonitor/file`配置文件，在最后一行添加`/root 0x300`。创建文件`touch /root/file`，删除文件`rm /root/file`，查看日志:
```sh
tail -f /var/log/sysmonitor.log
1 events queued
1th event handled
Subfile "file" under "/root" was added.
1 events queued
1th event handled
Subfile "file" under "/root" was deleted.
```

# 代码分析

[src-openeuler/sysmonitor](https://gitee.com/src-openeuler/sysmonitor)是开发中的代码。[openeuler/sysmonitor](https://gitee.com/openeuler/sysmonitor)是发布的代码。

我们期望`set_event_msg()`函数中的打印是类似`Subfile "file" under "/root" was added, comm: 进程名[进程pid], parent comm: 父进程名[父进程pid]`，但实际运行的日志中没有进程和父进程的信息，代码流程如下:
```c
#define INOTIFY_IOC_SET_SYSMONITOR_FM 0xABAB

main
  monitor_var_init
    file_monitor_init
      file_monitor_start
        open_inotify_fd
          ret = ioctl(fd, INOTIFY_IOC_SET_SYSMONITOR_FM) = -1
          // 没执行 g_save_process = true
        fm_add_watch
        if (event_check(inotify_fd) > 0)
        read_events
        handle_events
          handle_event
            set_event_msg
              if (!g_save_process) // 条件满足，不打印event信息
```

# 宿主机上编译

[openEuler内核openEuler-22.03-LTS-SP2分支](https://gitee.com/openeuler/kernel/tree/openEuler-22.03-LTS-SP2/)代码以`gcc -Og`编译。

[sysmonitor/sysmonitor-1.3.2/module](https://gitee.com/openeuler/sysmonitor/tree/master/sysmonitor-1.3.2/module)代码如果以`gcc -Og`编译，需要修改[sysmonitor/sysmonitor-1.3.2/module/Makefile](https://gitee.com/openeuler/sysmonitor/blob/master/sysmonitor-1.3.2/module/Makefile)以保证编译通过:
```sh
diff --git a/sysmonitor-1.3.2/module/Makefile b/sysmonitor-1.3.2/module/Makefile
index 8030152..cdd40ae 100644
--- a/sysmonitor-1.3.2/module/Makefile
+++ b/sysmonitor-1.3.2/module/Makefile
@@ -5,9 +5,9 @@
 
 obj-m += sysmonitor.o
 sysmonitor-objs := sysmonitor_main.o signo_catch.o fdstat.o monitor_netdev.o
-KERNELDIR ?= /lib/modules/$(shell uname -r)/build
+KERNELDIR ?= /home/sonvhi/chenxiaosong/code/openeuler-22.03/build
 PWD := $(shell pwd)
-EXTRA_CFLAGS += -Wall -Werror
+EXTRA_CFLAGS += -Wall
 
 modules:
        $(MAKE) -C $(KERNELDIR) M=$(PWD) modules
```

qemu启动时指定`-kernel`和`-append`选项，将编译出的`sysmonitor.ko`复制到虚拟机中的`/lib/modules/sysmonitor/sysmonitor.ko`

# 虚拟机中编译

进入openeuler镜像的虚拟机后。

```sh
yum-builddep sysmonitor-kmod.spec -y
dnf install rpm-build -y
mkdir ../rpmbuild/SOURCES/ -p
tar -cvjf sysmonitor-1.3.2.tar.bz2 sysmonitor-1.3.2
mv sysmonitor-1.3.2.tar.bz2 ../rpmbuild/SOURCES/
rpmbuild -ba sysmonitor-kmod.spec
yum localinstall sysmonitor-kmod-1.3.2-1.2.xxx.x86_64.rpm
```

qemu不管是指定内核还是使用镜像自带的内核，运行以上命令后，qemu镜像都损坏了，无法正常使用，重启后发生oom，不知道搞什么东西。

