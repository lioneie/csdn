src_path=/home/sonvhi/chenxiaosong/code # 替换为你的仓库路径
dst_path=/var/www
tmp_html_path=${dst_path}/html-tmp
html_path=${dst_path}/html
tmp_courses_path=/tmp/blog

. ${src_path}/blog/src/blog-web/common-lib.sh

# 每一行代表： 是否生成目录 是否添加签名 markdown或rst文件相对路径 html文件相对路径 网页标题
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
            # nfs
            1 1 courses/kernel/patches/xprtrdma-kmalloc-rpcrdma_ep-separate-from-rpcrdma_xp.md ~
                "e28ce90083f0 xprtrdma: kmalloc rpcrdma_ep separate from rpcrdma_xprt"
            1 1 courses/kernel/patches/nfsd-Fix-races-between-nfsd4_cb_release-and-nfsd4_sh.md ~
                "2bbfed98a4d8 nfsd: Fix races between nfsd4_cb_release() and nfsd4_shutdown_callback()"
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
    1 1 src/kernel-environment/kernel-qemu-kvm.md kernel/kernel-qemu-kvm.html "QEMU/KVM环境搭建与使用"
    1 1 src/strace-fault-inject/strace-fault-inject.md kernel/strace-fault-inject.html "strace内存分配失败故障注入"
    1 1 src/kernel/openeuler-sysmonitor.md kernel/openeuler-sysmonitor.html "openEuler的sysmonitor"
    1 1 src/kernel/kprobe-scsi-data.md kernel/kprobe-scsi-data.html "使用kprobe监控scsi的读写数据"
    1 1 src/process/process.md kernel/process.html "Linux进程调度"
    1 1 src/kernel/gio-to-mount.md kernel/gio-to-mount.html "gio执行慢的临时解决办法"
    1 1 src/kernel/syzkaller.md kernel/syzkaller.html "syzkaller - 内核模糊测试工具"
    # nfs
    1 1 src/nfs/nfs-debug.md nfs/nfs-debug.html "定位NFS问题的常用方法"
    1 1 src/nfs/CVE-2022-24448.md nfs/CVE-2022-24448.html "CVE-2022-24448"
    1 1 src/nfs/nfs-handle-writeback-errors-incorrectly.md nfs/nfs-handle-writeback-errors-incorrectly.html "NFS回写错误处理不正确的问题"
    1 1 src/nfs/4.19-null-ptr-deref-in-nfs_updatepage.md nfs/4.19-null-ptr-deref-in-nfs_updatepage.html '4.19 nfs_updatepage空指针解引用问题'
    1 1 src/nfs/4.19-null-ptr-deref-in-nfs_readpage_async.md nfs/4.19-null-ptr-deref-in-nfs_readpage_async.html '4.19 nfs_readpage_async空指针解引用问题'
    1 1 src/nfs/4.19-aarch64-null-ptr-deref-in-nfs_readpage_async.md nfs/4.19-aarch64-null-ptr-deref-in-nfs_readpage_async.html "aarch64架构 4.19 nfs_readpage_async空指针解引用问题"
    1 1 src/nfs/4.19-rdma-not-supported.md nfs/4.19-rdma-not-supported.html "4.19 rdma协议不支持的问题"
    1 1 src/nfs/4.19-nfs-mount-hung.md nfs/4.19-nfs-mount-hung.html "4.19 nfs lazy umount 后无法挂载的问题"
    1 1 src/nfs/4.19-warning-in-nfs4_put_stid-and-panic.md nfs/4.19-warning-in-nfs4_put_stid-and-panic.html "4.19 nfs4_put_stid报warning紧接着panic的问题"
    1 1 src/nfs/cthon-nfs-tests.md nfs/cthon-nfs-tests.html "Connectathon NFS tests"
    1 1 src/nfs/4.19-nfs-no-iterate_shared.md nfs/4.19-nfs-no-iterate_shared.html "nfs没实现iterate_shared导致的遍历目录无法并发问题"
    1 1 src/nfs/unable-to-initialize-client-recovery-tracking.md nfs/unable-to-initialize-client-recovery-tracking.html "重启nfs server后client打开文件卡顿很长时间的问题"
    1 1 src/nfs/4.19-ltp-nfs-fail.md nfs/4.19-ltp-nfs-fail.html "4.19 ltp nfs测试失败问题"
    1 1 src/nfs/nfs-no-net-oom.md nfs/nfs-no-net-oom.html "nfs断网导致oom的问题"
    # smb(cifs)
    1 1 src/smb/4.19-null-ptr-deref-in-cifs_reconnect.md smb/4.19-null-ptr-deref-in-cifs_reconnect.html "4.19 cifs_reconnect空指针解引用问题"
    1 1 src/smb/cifs-newfstatat-ENOTSUPP.md smb/cifs-newfstatat-ENOTSUPP.html "cifs newfstatat报错ENOTSUPP"
    # xfs
    1 1 src/xfs/xfs-null-ptr-deref-in-xfs_getbmap.md xfs/xfs-null-ptr-deref-in-xfs_getbmap.html "xfs_getbmap发生空指针解引用问题"
    1 1 src/xfs/xfs-shutdown-fs.md xfs/xfs-shutdown-fs.html "xfs agf没落盘的问题"
    # ext
    1 1 src/ext/null-ptr-deref-in-jbd2_journal_commit_transaction.md ext/null-ptr-deref-in-jbd2_journal_commit_transaction.html "jbd2_journal_commit_transaction空指针解引用问题"
    1 1 src/ext/bugon-in-ext4_writepages.md ext/bugon-in-ext4_writepages.html "ext4_writepages报BUG_ON的问题"
    1 1 src/ext/bugon-in-start_this_handle.md ext/bugon-in-start_this_handle.html "start_this_handle报BUG_ON的问题"
    1 1 src/ext/symlink-file-size-not-match.md ext/symlink-file-size-not-match.html "symlink file size 错误的问题"
    1 1 src/ext/uaf-in-ext4_search_dir.md ext/uaf-in-ext4_search_dir.html "ext4_search_dir空指针解引用问题"
    # 文件系统
    1 1 src/filesystem/configfs-race.md fs/configfs-race.html "configfs加载或卸载模块时的并发问题"
    1 1 src/filesystem/microsoft-fs.md fs/microsoft-fs.html "微软文件系统"
    1 1 src/btrfs/4.19-btrfs-forced-readonly.md fs/4.19-btrfs-forced-readonly.html "4.19 btrfs文件系统变成只读的问题"
    1 1 src/filesystem/minix-fs.md fs/minix-fs.html "minix文件系统"
    1 1 src/filesystem/tmpfs-oom.md fs/tmpfs-oom.html "tmpfs不断写导致oom的问题"
    # Linux环境
    1 1 src/userspace-environment/vnc.md linux/vnc.html "VNC远程桌面"
    1 1 src/blog-web/blog-web.md linux/blog-web.html "如何拥有个人域名的网站和邮箱"
    1 1 src/userspace-environment/install-linux.md linux/install-linux.html "Linux环境安装与配置"
    1 1 src/linux-config/linux-config.md linux/linux-config.html "Linux配置文件"
    1 1 src/ssh-reverse/ssh-reverse.md linux/ssh-reverse.html "反向ssh和内网穿透"
    1 1 src/userspace-environment/docker.md linux/docker.html "Docker安装与使用"
    1 1 src/macos/qemu-kvm-install-macos.md linux/qemu-kvm-install-macos.html "QEMU/KVM安装macOS系统"
    1 1 src/userspace-environment/ghostwriter-makdown.md linux/ghostwriter-makdown.html "ghostwriter: 一款makdown编辑器"
    1 1 src/userspace-environment/mosquitto-mqtt.md linux/mosquitto-mqtt.html "使用mosquitto搭建MQTT服务器"
    1 1 src/editor/editor.md linux/editor.html "编辑器"
    1 1 src/windows/wine.md linux/wine.html "Linux使用wine运行Windows软件"
    1 1 src/openharmony/openharmony.md linux/openharmony.html "OpenHarmony编译运行调试环境"
    # 其他
    1 1 src/windows/windows.md others/windows.html "Windows系统"
    1 1 src/wubi/wubi.md others/wubi.html "五笔输入法"
    1 1 src/keybord/keybord.md others/keyboard.html "键盘配置"
    1 1 src/free-software/free-software.md others/free-software.html "自由软件介绍"
    1 1 src/lorawan/stm32-linux.md others/stm32-linux.html "STM32 Linux开发环境"
    1 1 src/health/tooth-clean.md others/tooth-clean.html "牙齿护理"
    # 翻译
    1 1 src/translations/translations.md translations/translations.html "翻译"
        # nfs
        1 1 src/translations/nfs/rfc8881-nfsv4.1.md translations/rfc8881-nfsv4.1.html "Network File System (NFS) Version 4 Minor Version 1 Protocol"
        1 1 src/translations/nfs/rfc7862-nfsv4.2.md translations/rfc7862-nfsv4.2.html "Network File System (NFS) Version 4 Minor Version 2 Protocol"
        1 1 src/translations/nfs/kernel-doc-client-identifier.rst translations/kernel-doc-client-identifier.html "NFSv4 client identifier"
        1 1 src/translations/nfs/cthon-nfs-tests-readme.md translations/cthon-nfs-tests-readme.html "Connectathon NFS tests README"
        1 1 src/translations/nfs/bugzilla-redhat-bug-2176575.md translations/bugzilla-redhat-bug-2176575.html "Red Hat Bugzilla - Bug 2176575 - intermittent severe NFS client performance drop via nfs_server_reap_expired_delegations looping?"
        1 1 src/translations/nfs/pnfs.com.md translations/pnfs.com.html "pnfs.com"
        1 1 src/translations/nfs/kernel-doc-pnfs.md translations/kernel-doc-pnfs.html "kernel doc: Reference counting in pnfs"
        1 1 src/translations/nfs/pnfs-development.md translations/pnfs-development.html "linux-nfs.org PNFS Development"
        1 1 src/translations/nfs/kernel-doc-nfs41-server.md translations/kernel-doc-nfs41-server.html "kernel doc: NFSv4.1 Server Implementation"
        1 1 src/translations/nfs/kernel-doc-pnfs-block-server.md translations/kernel-doc-pnfs-block-server.html "kernel doc: pNFS block layout server user guide"
        1 1 src/translations/nfs/kernel-doc-pnfs-scsi-server.md translations/kernel-doc-pnfs-scsi-server.html "kernel doc: pNFS SCSI layout server user guide"
        # smb
        1 1 src/translations/smb/ms-smb.md translations/ms-smb.html "[MS-SMB]: Server Message Block (SMB) Protocol"
        1 1 src/translations/smb/ms-smb2.md translations/ms-smb2.html "[MS-SMB2]: Server Message Block (SMB) Protocol Versions 2 and 3"
        1 1 src/translations/smb/ksmbd-kernel-doc.md translations/ksmbd-kernel-doc.html "KSMBD kernel doc"
        1 1 src/translations/smb/ksmbd-tools-readme.md translations/ksmbd-tools-readme.html "ksmbd-tools README"
        # btrfs
        1 1 src/translations/btrfs/btrfs-doc.rst translations/btrfs-doc.html "BTRFS documentation"
        # xfs
        1 1 src/translations/xfs/xfs_filesystem_structure.md translations/xfs_filesystem_structure.html "xfs_filesystem_structure.pdf"
        # wine
        1 1 src/translations/wine/building-wine-winehq-wiki.md translations/building-wine-winehq-wiki.html "Building Wine - WineHQ Wiki"
        1 1 src/translations/wine/box64-docs-X64WINE.md translations/box64-docs-X64WINE.html "box64 Installing Wine64"
        1 1 src/translations/wine/box86-docs-X86WINE.md translations/box86-docs-X86WINE.html "box86 Installing Wine (and winetricks)"
        # tests
        1 1 src/translations/tests/ltp-readme.md translations/ltp-readme.html "Linux Test Project README"
        1 1 src/translations/tests/ltp-network-tests-readme.md translations/ltp-network-tests-readme.html "LTP Network Tests README"
        1 1 src/translations/tests/xfstests-readme.md translations/xfstests-readme.html "(x)fstests README"
        1 1 src/translations/tests/syzkaller.md translations/syzkaller.html "syzkaller - kernel fuzzer"
        # qemu
        1 1 src/translations/qemu/qemu-networking-nat.md translations/qemu-networking-nat.html "QEMU Documentation/Networking/NAT"
        # systemtap
        1 1 src/translations/systemtap/systemtap-readme.md translations/systemtap-readme.html "systemtap README"
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
