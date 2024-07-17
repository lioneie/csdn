我的大部分工作都是和开源社区打交道，所以我的笔记也都可以公开。我的笔记没有什么高大上的内容，只是记录自己学到的一些知识点，当然如果能对其他热爱技术的朋友有所启发，我就更开心了。

博客内容还在完善和整理中，更多的内容可以查看我的博客的[GitHub仓库](https://github.com/chenxiaosonggithub/blog)或[gitee仓库](https://gitee.com/chenxiaosonggitee/blog)。

我的博客网页只是简单的内容展示，如果要进行关键字搜索，可以在[GitHub仓库上搜索](https://github.com/search?q=repo%3Achenxiaosonggithub%2Fblog+&type=code)。

# Linux内核课程

[点击查看Linux内核课程（持续更新中）](https://chenxiaosong.com/courses/kernel.html)

利用业余时间整理了一个Linux内核相关的教程，最大的目的是为了整理自己以前学习到的知识点，当然也为了学习还没学到的知识点，查缺补漏，温故知新。

在这里郑重承诺一下，课程里的每一个字，我都是用键盘一字一句的敲出来，绝对不会复制粘贴，引用其他朋友原话的内容我也会标明出处，欢迎各位朋友的监督。

# NFS文件系统课程

[点击查看nfs文件系统（持续更新中）](https://chenxiaosong.com/courses/nfs.html)

# SMB文件系统课程

[点击查看smb文件系统（持续更新中）](https://chenxiaosong.com/courses/smb.html)

# Linux内核

[QEMU/KVM环境搭建与使用](https://chenxiaosong.com/kernel/kernel-qemu-kvm.html)

[strace内存分配失败故障注入](https://chenxiaosong.com/kernel/strace-fault-inject.html)

[openEuler的sysmonitor](https://chenxiaosong.com/kernel/openeuler-sysmonitor.html)

[使用kprobe监控scsi的读写数据](https://chenxiaosong.com/kernel/kprobe-scsi-data.html)

[Linux进程调度](https://chenxiaosong.com/kernel/process.html)

[gio执行慢的临时解决办法](https://chenxiaosong.com/kernel/gio-to-mount.html)

[syzkaller - 内核模糊测试工具](https://chenxiaosong.com/kernel/syzkaller.html)

# NFS（网络文件系统）

[定位NFS问题的常用方法](https://chenxiaosong.com/nfs/nfs-debug.html)

[CVE-2022-24448](https://chenxiaosong.com/nfs/CVE-2022-24448.html)

[NFS回写错误处理不正确的问题](https://chenxiaosong.com/nfs/nfs-handle-writeback-errors-incorrectly.html)

[4.19 nfs_updatepage空指针解引用问题](https://chenxiaosong.com/nfs/4.19-null-ptr-deref-in-nfs_updatepage.html)

[4.19 nfs_readpage_async空指针解引用问题](https://chenxiaosong.com/nfs/4.19-null-ptr-deref-in-nfs_readpage_async.html)

[aarch64架构 4.19 nfs_readpage_async空指针解引用问题](https://chenxiaosong.com/nfs/4.19-aarch64-null-ptr-deref-in-nfs_readpage_async.html)

[4.19 rdma协议不支持的问题](https://chenxiaosong.com/nfs/4.19-rdma-not-supported.html)

[4.19 nfs lazy umount 后无法挂载的问题](https://chenxiaosong.com/nfs/4.19-nfs-mount-hung.html)

[4.19 nfs4_put_stid报warning紧接着panic的问题](https://chenxiaosong.com/nfs/4.19-warning-in-nfs4_put_stid-and-panic.html)

[Connectathon NFS tests](https://chenxiaosong.com/nfs/cthon-nfs-tests.html)

[4.19 nfs没实现iterate_shared导致的遍历目录无法并发问题](https://chenxiaosong.com/nfs/4.19-nfs-no-iterate_shared.html)

[重启nfs server后client打开文件卡顿很长时间的问题](https://chenxiaosong.com/nfs/unable-to-initialize-client-recovery-tracking.html)

[4.19 ltp nfs测试失败问题](https://chenxiaosong.com/nfs/4.19-ltp-nfs-fail.html)

[nfs断网导致oom的问题](https://chenxiaosong.com/nfs/nfs-no-net-oom.html)

# SMB(CIFS)文件系统

[4.19 cifs_reconnect空指针解引用问题](https://chenxiaosong.com/smb/4.19-null-ptr-deref-in-cifs_reconnect.html)

[cifs newfstatat报错ENOTSUPP](https://chenxiaosong.com/smb/cifs-newfstatat-ENOTSUPP.html)

# XFS文件系统

[xfs_getbmap发生空指针解引用问题](https://chenxiaosong.com/xfs/xfs-null-ptr-deref-in-xfs_getbmap.html)

[xfs agf没落盘的问题](https://chenxiaosong.com/xfs/xfs-shutdown-fs.html)

# EXT文件系统

[jbd2_journal_commit_transaction空指针解引用问题](https://chenxiaosong.com/ext/null-ptr-deref-in-jbd2_journal_commit_transaction.html)

[ext4_writepages报BUG_ON的问题](https://chenxiaosong.com/ext/bugon-in-ext4_writepages.html)

[start_this_handle报BUG_ON的问题](https://chenxiaosong.com/ext/bugon-in-start_this_handle.html)

[symlink file size 错误的问题](https://chenxiaosong.com/ext/symlink-file-size-not-match.html)

[ext4_search_dir空指针解引用问题](https://chenxiaosong.com/ext/uaf-in-ext4_search_dir.html)

# 文件系统

[configfs加载或卸载模块时的并发问题](https://chenxiaosong.com/fs/configfs-race.html)

[微软文件系统](https://chenxiaosong.com/fs/microsoft-fs.html)

[4.19 btrfs文件系统变成只读的问题](https://chenxiaosong.com/fs/4.19-btrfs-forced-readonly.html)

[minix文件系统](https://chenxiaosong.com/fs/minix-fs.html)

[tmpfs不断写导致oom的问题](https://chenxiaosong.com/fs/tmpfs-oom.html)

# Linux环境

[VNC远程桌面](https://chenxiaosong.com/linux/vnc.html)

[如何拥有个人域名的网站和邮箱](https://chenxiaosong.com/linux/blog-web.html)

[Linux环境安装与配置](https://chenxiaosong.com/linux/userspace-environment.html)

[Linux配置文件](https://chenxiaosong.com/linux/linux-config.html)

[反向ssh和内网穿透](https://chenxiaosong.com/linux/ssh-reverse.html)

[Docker安装与使用](https://chenxiaosong.com/linux/docker.html)

[QEMU/KVM安装macOS系统](https://chenxiaosong.com/linux/qemu-kvm-install-macos.html)

[ghostwriter: 一款makdown编辑器](https://chenxiaosong.com/linux/ghostwriter-makdown.html)

[使用mosquitto搭建MQTT服务器](https://chenxiaosong.com/linux/mosquitto-mqtt.html)

[编辑器](https://chenxiaosong.com/linux/editor.html)

[Linux使用wine运行Windows软件](https://chenxiaosong.com/linux/wine.html)

[OpenHarmony编译运行调试环境](https://chenxiaosong.com/linux/openharmony.html)

# 还没有分类

[Windows系统](https://chenxiaosong.com/others/windows.html)

[键盘配置](https://chenxiaosong.com/others/keyboard.html)

[五笔输入法](https://chenxiaosong.com/others/wubi.html)

[自由软件介绍](https://chenxiaosong.com/others/free-software.html)

[STM32 Linux开发环境](https://chenxiaosong.com/others/stm32-linux.html)

[牙齿护理](https://chenxiaosong.com/others/tooth-clean.html)

# 翻译

[点击查看翻译文章](https://chenxiaosong.com/translations/translations.html)
