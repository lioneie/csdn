tmp_courses_path=/tmp/blog

# 每一行代表:
#    是否生成目录
#    是否添加签名
#    源文件，markdown或rst文件相对路径
#    目的文件，html文件相对路径，如果是~，就代表只和源文件的后缀名不同
#    网页标题
array=(
    # 自我介绍
    1 1 src/blog-web/index.md index.html '陈孝松个人主页'
    1 1 src/blog-web/photos.md photos.html '陈孝松照片'
    1 1 src/blog-web/openharmony.md openharmony.html "陈孝松OpenHarmony贡献"
    1 1 src/blog-web/blog.md blog.html "陈孝松博客"
    1 1 src/blog-web/contributions.md contributions.html "陈孝松自由软件贡献"
    1 1 src/blog-web/translations.md ~ "翻译"
    1 1 src/blog-web/courses.md courses.html "课程和视频"
    1 1 src/blog-web/q.md q.html "QQ交流群"
    # 课程
    0 1 courses/kernel/kernel.md ${tmp_courses_path} "Linux内核课程"
        1 1 courses/kernel/kernel-introduction.md ${tmp_courses_path} "内核简介"
        1 1 courses/kernel/kernel-dev-environment.md ${tmp_courses_path} "内核开发环境"
        1 1 courses/kernel/kernel-book.md ${tmp_courses_path} "内核书籍推荐"
        1 1 courses/kernel/kernel-source.md ${tmp_courses_path} "内核源码介绍"
        1 1 courses/kernel/kernel-fs.md ${tmp_courses_path} "文件系统"
        1 1 courses/kernel/kernel-debug.md ${tmp_courses_path} "内核调试方法"
        1 1 courses/kernel/kernel-mm.md ${tmp_courses_path} "内存管理"
        1 1 courses/kernel/kernel-process.md ${tmp_courses_path} "进程管理和调度"
        1 1 courses/kernel/kernel-interrupt.md ${tmp_courses_path} "中断"
        1 1 courses/kernel/kernel-syscall.md ${tmp_courses_path} "系统调用"
        1 1 courses/kernel/kernel-timer.md ${tmp_courses_path} "定时器"
        1 1 courses/kernel/kernel-bpf.md ${tmp_courses_path} "BPF"
        1 1 courses/kernel/kernel-patches.md ${tmp_courses_path} "内核补丁分析"
            # 我写的补丁
            1 1 courses/kernel/patches/xfs-fix-NULL-pointer-dereference-in-xfs_getbmap.md ~
                "001c179c4e26d xfs: fix NULL pointer dereference in xfs_getbmap()"
            1 1 courses/kernel/patches/configfs-fix-a-race-in-configfs_-un-register_subsyst.md ~
                "84ec758fb2da configfs: fix a race in configfs_{,un}register_subsystem()"
            # 调度
            1 1 courses/kernel/patches/sched-EEVDF-and-latency-nice-and-or-slice-attr.md ~
                "sched: EEVDF and latency-nice and/or slice-attr"
            # vfs
            1 1 courses/kernel/patches/iomap-Set-all-uptodate-bits-for-an-Uptodate-page.md ~
                "4595a298d556 iomap: Set all uptodate bits for an Uptodate page"
            # ext
            1 1 courses/kernel/patches/jbd2-fix-a-potential-race-while-discarding-reserved-.md ~
                "23e3d7f7061f jbd2: fix a potential race while discarding reserved buffers after an abort"
            1 1 courses/kernel/patches/ext4-fix-bug_on-in-ext4_writepages.md ~
                "ef09ed5d37b8 ext4: fix bug_on in ext4_writepages"
            1 1 courses/kernel/patches/ext4-fix-bug_on-in-start_this_handle-during-umount-f.md ~
                "b98535d09179 ext4: fix bug_on in start_this_handle during umount filesystem"
            1 1 courses/kernel/patches/ext4-fix-symlink-file-size-not-match-to-file-content.md ~
                "a2b0b205d125 ext4: fix symlink file size not match to file content"
            1 1 courses/kernel/patches/ext4-fix-use-after-free-in-ext4_search_dir.md ~
                "c186f0887fe7 ext4: fix use-after-free in ext4_search_dir"
            1 1 courses/kernel/patches/refactor-of-__ext4_fill_super.md ~
                "some refactor of __ext4_fill_super()"
    0 1 courses/nfs/nfs.md ${tmp_courses_path} "nfs文件系统"
        1 1 courses/nfs/nfs-introduction.md ${tmp_courses_path} "nfs简介"
        1 1 courses/nfs/nfs-environment.md ${tmp_courses_path} "nfs环境"
        1 1 courses/nfs/nfs-client-struct.md ${tmp_courses_path} "nfs client数据结构"
        1 1 courses/nfs/pnfs.md ${tmp_courses_path} "Parallel NFS (pNFS)"
        1 1 courses/nfs/nfs-debug.md ${tmp_courses_path} "nfs调试方法"
        1 1 courses/nfs/nfs-multipath.md ${tmp_courses_path} "nfs多路径"
        1 1 courses/nfs/nfs-patches.md ${tmp_courses_path} "nfs补丁分析"
        1 1 courses/nfs/nfs-others.md ${tmp_courses_path} "nfs未分类的内容"
            # 我写的补丁
            1 1 courses/nfs/patches/CVE-2022-24448.md ~ "CVE-2022-24448"
            1 1 courses/nfs/patches/nfs-handle-writeback-errors-incorrectly.md ~ "NFS回写错误处理不正确的问题"
            # 其他人的补丁
            1 1 courses/nfs/patches/xprtrdma-kmalloc-rpcrdma_ep-separate-from-rpcrdma_xp.md ~
                "e28ce90083f0 xprtrdma: kmalloc rpcrdma_ep separate from rpcrdma_xprt"
            1 1 courses/nfs/patches/nfsd-minor-4.1-callback-cleanup.md ~
                "12357f1b2c8e nfsd: minor 4.1 callback cleanup"
            1 1 courses/nfs/patches/nfsd-Fix-races-between-nfsd4_cb_release-and-nfsd4_sh.md ~
                "2bbfed98a4d8 nfsd: Fix races between nfsd4_cb_release() and nfsd4_shutdown_callback()"
            1 1 courses/nfs/patches/NFS-Don-t-call-generic_error_remove_page-while-holdi.md ~
                "22876f540bdf NFS: Don't call generic_error_remove_page() while holding locks"
            1 1 courses/nfs/patches/nfsd-Don-t-release-the-callback-slot-unless-it-was-a.md ~
                "e6abc8caa6de nfsd: Don't release the callback slot unless it was actually held"
            1 1 courses/nfs/patches/nfsd4-use-reference-count-to-free-client.md ~
                "59f8e91b75ec nfsd4: use reference count to free client"
            1 1 courses/nfs/patches/NFSD-Reschedule-CB-operations-when-backchannel-rpc_c.md ~
                "c1ccfcf1a9bf NFSD: Reschedule CB operations when backchannel rpc_clnt is shut down"
            1 1 courses/nfs/patches/NFS-Improve-warning-message-when-locks-are-lost.md ~
                "3e2910c7e23b NFS: Improve warning message when locks are lost."
            1 1 courses/nfs/patches/nfsd-Remove-incorrect-check-in-nfsd4_validate_statei.md ~
                "600df3856f0b nfsd: Remove incorrect check in nfsd4_validate_stateid"
            1 1 courses/nfs/patches/patchset-nfs_instantiate-might-succeed-leaving-dentry-negative-unhashed.md ~
                "patchset: nfs_instantiate() might succeed leaving dentry negative unhashed"
        1 1 courses/nfs/nfs-issues.md ${tmp_courses_path} "nfs问题分析"
            1 1 courses/nfs/issues/nfs-clients-same-hostname-clientid-expire.md ~ "多个NFS客户端使用相同的hostname导致clientid过期"
            1 1 courses/nfs/issues/4.19-nfs-no-iterate_shared.md ~ "nfs没实现iterate_shared导致的遍历目录无法并发问题"
            1 1 courses/nfs/issues/4.19-null-ptr-deref-in-nfs_updatepage.md ~ '4.19 nfs_updatepage空指针解引用问题'
            1 1 courses/nfs/issues/4.19-aarch64-null-ptr-deref-in-nfs_readpage_async.md ~ "aarch64架构 4.19 nfs_readpage_async空指针解引用问题"
            1 1 courses/nfs/issues/4.19-null-ptr-deref-in-nfs_readpage_async.md ~ '4.19 nfs_readpage_async空指针解引用问题'
            1 1 courses/nfs/issues/4.19-warning-in-nfs4_put_stid-and-panic.md ~ "4.19 nfs4_put_stid报warning紧接着panic的问题"
            1 1 courses/nfs/issues/4.19-null-ptr-deref-in-__nfs3_proc_setacls.md ~ "4.19 __nfs3_proc_setacls空指针解引用问题"
            1 1 courses/nfs/issues/nfs-df-long-time.md ~ "nfs df命令执行时间长的问题"

    0 1 courses/smb/smb.md ${tmp_courses_path} "smb文件系统"
        1 1 courses/smb/smb-introduction.md ${tmp_courses_path} "smb简介"
        1 1 courses/smb/smb-environment.md ${tmp_courses_path} "smb环境"
        1 1 courses/smb/ksmbd.md ${tmp_courses_path} "smb server (ksmbd)"
        1 1 courses/smb/smb-client-struct.md ${tmp_courses_path} "smb client数据结构"
        1 1 courses/smb/smb-debug.md ${tmp_courses_path} "smb调试方法"
        1 1 courses/smb/smb-patches.md ${tmp_courses_path} "smb补丁分析"
        1 1 courses/smb/smb-refactor.md ${tmp_courses_path} "smb代码重构"
        1 1 courses/smb/smb-others.md ${tmp_courses_path} "smb未分类的内容"
            # 我写的补丁
            1 1 courses/smb/patches/cifs-fix-use-after-free-on-the-link-name.md ~
                "542228db2f28f cifs: fix use-after-free on the link name"
            # 其他人的补丁
            1 1 courses/smb/patches/cifs-Fix-in-error-types-returned-for-out-of-credit-s.md ~
                "7de0394801da cifs: Fix in error types returned for out-of-credit situations."
            1 1 courses/smb/patches/cve-smb-client-fix-use-after-free-bug-in-cifs_debug_data.md ~
                "d328c09ee9f1 smb: client: fix use-after-free bug in cifs_debug_data_proc_show()"
            1 1 courses/smb/patches/cve-smb-client-fix-potential-UAF-in-is_valid_oplock_brea.md ~
                "69ccf040acdd smb: client: fix potential UAF in is_valid_oplock_break()"
            1 1 courses/smb/patches/smb3-fix-problem-with-null-cifs-super-block-with-pre.md ~
                "87f93d82e0952 smb3: fix problem with null cifs super block with previous patch"
    0 1 courses/algorithms/algorithms.md ${tmp_courses_path} "算法"
        1 1 courses/algorithms/dynamic-programming.md ${tmp_courses_path} "动态规划"
        1 1 courses/algorithms/sort.md ${tmp_courses_path} "排序算法"
    1 1 courses/book-contents.md ~ "书籍目录"
    # Linux内核
    1 1 src/kernel-environment/kernel-qemu-kvm.md ~ "QEMU/KVM环境搭建与使用"
    1 1 src/strace-fault-inject/strace-fault-inject.md ~ "strace内存分配失败故障注入"
    1 1 src/kernel/openeuler-sysmonitor.md ~ "openEuler的sysmonitor"
    1 1 src/kernel/kprobe-scsi-data.md ~ "使用kprobe监控scsi的读写数据"
    1 1 src/process/process.md ~ "Linux进程调度"
    1 1 src/kernel/gio-to-mount.md ~ "gio执行慢的临时解决办法"
    1 1 src/kernel/syzkaller.md ~ "syzkaller - 内核模糊测试工具"
    # nfs
    1 1 src/nfs/4.19-rdma-not-supported.md ~ "4.19 rdma协议不支持的问题"
    1 1 src/nfs/4.19-nfs-mount-hung.md ~ "4.19 nfs lazy umount 后无法挂载的问题"
    1 1 src/nfs/cthon-nfs-tests.md ~ "Connectathon NFS tests"
    1 1 src/nfs/unable-to-initialize-client-recovery-tracking.md ~ "重启nfs server后client打开文件卡顿很长时间的问题"
    1 1 src/nfs/4.19-ltp-nfs-fail.md ~ "4.19 ltp nfs测试失败问题"
    1 1 src/nfs/nfs-no-net-oom.md ~ "nfs断网导致oom的问题"
    # smb(cifs)
    1 1 src/smb/4.19-null-ptr-deref-in-cifs_reconnect.md ~ "4.19 cifs_reconnect空指针解引用问题"
    1 1 src/smb/cifs-newfstatat-ENOTSUPP.md ~ "cifs newfstatat报错ENOTSUPP"
    # xfs
    1 1 src/xfs/xfs-shutdown-fs.md ~ "xfs agf没落盘的问题"
    # ext

    # 文件系统
    1 1 src/filesystem/microsoft-fs.md ~ "微软文件系统"
    1 1 src/btrfs/4.19-btrfs-forced-readonly.md ~ "4.19 btrfs文件系统变成只读的问题"
    1 1 src/filesystem/minix-fs.md ~ "minix文件系统"
    1 1 src/filesystem/tmpfs-oom.md ~ "tmpfs不断写导致oom的问题"
    # Linux环境
    1 1 src/userspace-environment/vnc.md ~ "VNC远程桌面"
    1 1 src/blog-web/blog-web.md ~ "如何拥有个人域名的网站和邮箱"
    1 1 src/userspace-environment/install-linux.md ~ "Linux环境安装与配置"
    1 1 src/linux-config/linux-config.md ~ "Linux配置文件"
    1 1 src/ssh-reverse/ssh-reverse.md ~ "反向ssh和内网穿透"
    1 1 src/docker/docker.md ~ "Docker安装与使用"
    1 1 src/macos/qemu-kvm-install-macos.md ~ "QEMU/KVM安装macOS系统"
    1 1 src/userspace-environment/ghostwriter-makdown.md ~ "ghostwriter: 一款makdown编辑器"
    1 1 src/userspace-environment/mosquitto-mqtt.md ~ "使用mosquitto搭建MQTT服务器"
    1 1 src/editor/editor.md ~ "编辑器"
    1 1 src/windows/wine.md ~ "Linux使用wine运行Windows软件"
    1 1 src/openharmony/openharmony.md ~ "OpenHarmony编译运行调试环境"
    1 1 src/userspace-environment/eulerlauncher.md ~ "macOS下用EulerLauncher运行openEuler"
    # 其他
    1 1 src/windows/windows.md ~ "Windows系统"
    1 1 src/wubi/wubi.md ~ "五笔输入法"
    1 1 src/keybord/keybord.md ~ "键盘配置"
    1 1 src/free-software/free-software.md ~ "自由软件介绍"
    1 1 src/lorawan/stm32-linux.md ~ "STM32 Linux开发环境"
    1 1 src/health/tooth-clean.md ~ "牙齿护理"
    1 1 src/game/black-myth-wukong.md ~ "黑神话：悟空"
    # 翻译
        # kernel
        1 1 src/translations/kernel/sched-design-CFS.rst ~ "CFS Scheduler"
        1 1 src/translations/kernel/sched-eevdf.rst ~ "EEVDF Scheduler"
        1 1 src/translations/kernel/sched-ext.rst ~ "Extensible Scheduler Class"
        1 1 src/translations/kernel/An-EEVDF-CPU-scheduler-for-Linux.md ~ "An EEVDF CPU scheduler for Linux"
        1 1 src/translations/kernel/Completing-the-EEVDF-scheduler.md ~ "Completing the EEVDF scheduler"
        # nfs
        1 1 src/translations/nfs/rfc8881-nfsv4.1.md ~ "Network File System (NFS) Version 4 Minor Version 1 Protocol"
        1 1 src/translations/nfs/rfc7862-nfsv4.2.md ~ "Network File System (NFS) Version 4 Minor Version 2 Protocol"
        1 1 src/translations/nfs/kernel-doc-client-identifier.rst ~ "NFSv4 client identifier"
        1 1 src/translations/nfs/cthon-nfs-tests-readme.md ~ "Connectathon NFS tests README"
        1 1 src/translations/nfs/bugzilla-redhat-bug-2176575.md ~
            "Red Hat Bugzilla - Bug 2176575 - intermittent severe NFS client performance drop via nfs_server_reap_expired_delegations looping?"
        1 1 src/translations/nfs/pnfs.com.md ~ "pnfs.com"
        1 1 src/translations/nfs/kernel-doc-pnfs.md ~ "kernel doc: Reference counting in pnfs"
        1 1 src/translations/nfs/pnfs-development.md ~ "linux-nfs.org PNFS Development"
        1 1 src/translations/nfs/kernel-doc-nfs41-server.md ~ "kernel doc: NFSv4.1 Server Implementation"
        1 1 src/translations/nfs/kernel-doc-pnfs-block-server.md ~ "kernel doc: pNFS block layout server user guide"
        1 1 src/translations/nfs/kernel-doc-pnfs-scsi-server.md ~ "kernel doc: pNFS SCSI layout server user guide"
        1 1 src/translations/nfs/kernel-doc-nfs-idmapper.rst ~ "kernel doc: NFS ID Mapper"
        1 1 src/translations/nfs/man-nfsidmap.md ~ "nfs idmap相关man手册"
        # smb
        1 1 src/translations/smb/ms-smb.md ~ "[MS-SMB]: Server Message Block (SMB) Protocol"
        1 1 src/translations/smb/ms-smb2.md ~ "[MS-SMB2]: Server Message Block (SMB) Protocol Versions 2 and 3"
        1 1 src/translations/smb/ksmbd-kernel-doc.md ~ "KSMBD kernel doc"
        1 1 src/translations/smb/ksmbd-tools-readme.md ~ "ksmbd-tools README"
        1 1 src/translations/smb/kernel-doc-cifs-introduction.rst ~ "kernel doc: admin-guide/cifs/introduction.rst"
        1 1 src/translations/smb/kernel-doc-cifs-todo.rst ~ "kernel doc: admin-guide/cifs/todo.rst"
        # btrfs
        1 1 src/translations/btrfs/btrfs-doc.rst ~ "BTRFS documentation"
        # xfs
        1 1 src/translations/xfs/xfs_filesystem_structure.md ~ "xfs_filesystem_structure.pdf"
        # wine
        1 1 src/translations/wine/building-wine-winehq-wiki.md ~ "Building Wine - WineHQ Wiki"
        1 1 src/translations/wine/box64-docs-X64WINE.md ~ "box64 Installing Wine64"
        1 1 src/translations/wine/box86-docs-X86WINE.md ~ "box86 Installing Wine (and winetricks)"
        # tests
        1 1 src/translations/tests/ltp-readme.md ~ "Linux Test Project README"
        1 1 src/translations/tests/ltp-network-tests-readme.md ~ "LTP Network Tests README"
        1 1 src/translations/tests/xfstests-readme.md ~ "(x)fstests README"
        1 1 src/translations/tests/syzkaller.md ~ "syzkaller - kernel fuzzer"
        1 1 src/translations/tests/kdevops-readme.md ~ "kdevops README"
        1 1 src/translations/tests/kdevops-nfs.md ~ "kdevops docs/nfs.md"
        # qemu
        1 1 src/translations/qemu/qemu-networking-nat.md ~ "QEMU Documentation/Networking/NAT"
        # systemtap
        1 1 src/translations/systemtap/systemtap-readme.md ~ "systemtap README"
        # doc-guide
        1 1 src/translations/doc-guide/kernel-doc.rst ~ "doc-guide/kernel-doc.rst"
    # private
    1 1 src/private/v2ray/v2ray.md private/v2ray.html "v2ray代理服务器"
    1 1 src/private/chatgpt/chatgpt.md private/chatgpt.html "注册ChatGPT"
)
