src_path=/home/sonvhi/chenxiaosong/code # 替换为你的仓库路径
dst_path=/var/www
tmp_html_path=${dst_path}/html-tmp
html_path=${dst_path}/html
tmp_courses_path=/tmp/blog

. ${src_path}/blog/src/blog-web/common-lib.sh

# 每一行代表：
#    是否生成目录
#    是否添加签名
#    源文件，markdown或rst文件相对路径
#    目的文件，html文件相对路径，如果是~，就代表只和源文件的后缀名不同
#    网页标题
array=(
    # 自我介绍
    0 0 src/blog-web/index.md index.html '陈孝松个人主页'
    1 1 src/blog-web/photos.md photos.html '陈孝松照片'
    1 1 src/blog-web/openharmony.md openharmony.html "陈孝松OpenHarmony贡献"
    1 1 src/blog-web/blog.md blog.html "陈孝松博客"
    1 1 src/blog-web/contributions.md contributions.html "陈孝松自由软件贡献"
    # 课程
    0 1 ${tmp_courses_path}/courses/kernel/kernel.md courses/kernel/kernel.html "Linux内核课程"
        1 1 ${tmp_courses_path}/courses/kernel/kernel-introduction.md courses/kernel/kernel-introduction.html "内核简介"
        1 1 ${tmp_courses_path}/courses/kernel/kernel-dev-environment.md courses/kernel/kernel-dev-environment.html "内核开发环境"
        1 1 ${tmp_courses_path}/courses/kernel/kernel-book.md courses/kernel/kernel-book.html "内核书籍推荐"
        1 1 ${tmp_courses_path}/courses/kernel/kernel-source.md courses/kernel/kernel-source.html "内核源码介绍"
        1 1 ${tmp_courses_path}/courses/kernel/kernel-fs.md courses/kernel/kernel-fs.html "文件系统"
        1 1 ${tmp_courses_path}/courses/kernel/kernel-debug.md courses/kernel/kernel-debug.html "内核调试方法"
        1 1 ${tmp_courses_path}/courses/kernel/kernel-patches.md courses/kernel/kernel-patches.html "内核补丁分析"
            # vfs
            1 1 courses/kernel/patches/iomap-Set-all-uptodate-bits-for-an-Uptodate-page.md ~
                "4595a298d556 iomap: Set all uptodate bits for an Uptodate page"
            # nfs
            1 1 courses/kernel/patches/xprtrdma-kmalloc-rpcrdma_ep-separate-from-rpcrdma_xp.md ~
                "e28ce90083f0 xprtrdma: kmalloc rpcrdma_ep separate from rpcrdma_xprt"
            1 1 courses/kernel/patches/nfsd-minor-4.1-callback-cleanup.md ~
                "12357f1b2c8e nfsd: minor 4.1 callback cleanup"
            1 1 courses/kernel/patches/nfsd-Fix-races-between-nfsd4_cb_release-and-nfsd4_sh.md ~
                "2bbfed98a4d8 nfsd: Fix races between nfsd4_cb_release() and nfsd4_shutdown_callback()"
            1 1 courses/kernel/patches/NFS-Don-t-call-generic_error_remove_page-while-holdi.md ~
                "22876f540bdf NFS: Don't call generic_error_remove_page() while holding locks"
            1 1 courses/kernel/patches/nfsd-Don-t-release-the-callback-slot-unless-it-was-a.md ~
                "e6abc8caa6de nfsd: Don't release the callback slot unless it was actually held"
            # smb
            1 1 courses/kernel/patches/cifs-Fix-in-error-types-returned-for-out-of-credit-s.md ~
                "7de0394801da cifs: Fix in error types returned for out-of-credit situations."
    0 1 courses/nfs/nfs.md ~ "nfs文件系统"
        1 1 courses/nfs/nfs-introduction.md ~ "nfs简介"
        1 1 courses/nfs/nfs-environment.md ~ "nfs环境"
        1 1 courses/nfs/nfs-client-struct.md ~ "nfs client数据结构"
        1 1 courses/nfs/pnfs.md ~ "Parallel NFS (pNFS)"
        1 1 courses/nfs/nfsd.md ~ "nfs server (nfsd)"
        1 1 courses/nfs/nfs-procedures.md ~ "nfs Procedures和Operations"
        1 1 courses/nfs/nfs-filehandle.md ~ "nfs文件句柄"
    0 1 courses/smb/smb.md ~ "smb文件系统"
        1 1 courses/smb/smb-introduction.md ~ "smb简介"
        1 1 courses/smb/smb-environment.md ~ "smb环境"
        1 1 courses/smb/ksmbd.md ~ "KSMBD - SMB3 Kernel Server"
        1 1 courses/smb/smb-client-struct.md ~ "smb client数据结构"
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
    1 1 src/nfs/nfs-debug.md ~ "定位NFS问题的常用方法"
    1 1 src/nfs/CVE-2022-24448.md ~ "CVE-2022-24448"
    1 1 src/nfs/nfs-handle-writeback-errors-incorrectly.md ~ "NFS回写错误处理不正确的问题"
    1 1 src/nfs/4.19-null-ptr-deref-in-nfs_updatepage.md ~ '4.19 nfs_updatepage空指针解引用问题'
    1 1 src/nfs/4.19-null-ptr-deref-in-nfs_readpage_async.md ~ '4.19 nfs_readpage_async空指针解引用问题'
    1 1 src/nfs/4.19-aarch64-null-ptr-deref-in-nfs_readpage_async.md ~ "aarch64架构 4.19 nfs_readpage_async空指针解引用问题"
    1 1 src/nfs/4.19-rdma-not-supported.md ~ "4.19 rdma协议不支持的问题"
    1 1 src/nfs/4.19-nfs-mount-hung.md ~ "4.19 nfs lazy umount 后无法挂载的问题"
    1 1 src/nfs/4.19-warning-in-nfs4_put_stid-and-panic.md ~ "4.19 nfs4_put_stid报warning紧接着panic的问题"
    1 1 src/nfs/cthon-nfs-tests.md ~ "Connectathon NFS tests"
    1 1 src/nfs/4.19-nfs-no-iterate_shared.md ~ "nfs没实现iterate_shared导致的遍历目录无法并发问题"
    1 1 src/nfs/unable-to-initialize-client-recovery-tracking.md ~ "重启nfs server后client打开文件卡顿很长时间的问题"
    1 1 src/nfs/4.19-ltp-nfs-fail.md ~ "4.19 ltp nfs测试失败问题"
    1 1 src/nfs/nfs-no-net-oom.md ~ "nfs断网导致oom的问题"
    # smb(cifs)
    1 1 src/smb/4.19-null-ptr-deref-in-cifs_reconnect.md ~ "4.19 cifs_reconnect空指针解引用问题"
    1 1 src/smb/cifs-newfstatat-ENOTSUPP.md ~ "cifs newfstatat报错ENOTSUPP"
    # xfs
    1 1 src/xfs/xfs-null-ptr-deref-in-xfs_getbmap.md ~ "xfs_getbmap发生空指针解引用问题"
    1 1 src/xfs/xfs-shutdown-fs.md ~ "xfs agf没落盘的问题"
    # ext
    1 1 src/ext/null-ptr-deref-in-jbd2_journal_commit_transaction.md ~ "jbd2_journal_commit_transaction空指针解引用问题"
    1 1 src/ext/bugon-in-ext4_writepages.md ~ "ext4_writepages报BUG_ON的问题"
    1 1 src/ext/bugon-in-start_this_handle.md ~ "start_this_handle报BUG_ON的问题"
    1 1 src/ext/symlink-file-size-not-match.md ~ "symlink file size 错误的问题"
    1 1 src/ext/uaf-in-ext4_search_dir.md ~ "ext4_search_dir空指针解引用问题"
    # 文件系统
    1 1 src/filesystem/configfs-race.md ~ "configfs加载或卸载模块时的并发问题"
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
    1 1 src/userspace-environment/docker.md ~ "Docker安装与使用"
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
    # 翻译
    1 1 src/translations/translations.md ~ "翻译"
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
        # smb
        1 1 src/translations/smb/ms-smb.md ~ "[MS-SMB]: Server Message Block (SMB) Protocol"
        1 1 src/translations/smb/ms-smb2.md ~ "[MS-SMB2]: Server Message Block (SMB) Protocol Versions 2 and 3"
        1 1 src/translations/smb/ksmbd-kernel-doc.md ~ "KSMBD kernel doc"
        1 1 src/translations/smb/ksmbd-tools-readme.md ~ "ksmbd-tools README"
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
        # qemu
        1 1 src/translations/qemu/qemu-networking-nat.md ~ "QEMU Documentation/Networking/NAT"
        # systemtap
        1 1 src/translations/systemtap/systemtap-readme.md ~ "systemtap README"
    # private
    1 1 src/private/v2ray/v2ray.md private/v2ray.html "v2ray代理服务器"
    1 1 src/private/chatgpt/chatgpt.md private/chatgpt.html "注册ChatGPT"
)

init_begin() {
    mkdir -p ${tmp_html_path}
    bash ${src_path}/blog/courses/courses.sh
}

init_end() {
    rm ${html_path}/ -rf
    mv ${tmp_html_path} ${html_path}
}

copy_secret_repository() {
    # pictures是我的私有仓库
    cp ${src_path}/pictures/public/ ${tmp_html_path}/pictures -rf
}

copy_public_files() {
    # css样式
    cp ${src_path}/blog/src/blog-web/stylesheet.css ${tmp_html_path}/
}

init_begin
create_sign ${src_path}/blog/src/blog-web/sign.md ${tmp_html_path}
create_html ${src_path}/blog ${tmp_html_path}
copy_secret_repository
copy_public_files
change_perm ${tmp_html_path}
init_end
