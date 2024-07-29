本文章列出一些内核补丁的分析，有些是我写的，有些是我定位问题时遇到的。

# VFS（虚拟文件系统）

[`4595a298d556 iomap: Set all uptodate bits for an Uptodate page`](https://chenxiaosong.com/courses/kernel/patches/iomap-Set-all-uptodate-bits-for-an-Uptodate-page.html)

# NFS（网络文件系统）

[`e28ce90083f0 xprtrdma: kmalloc rpcrdma_ep separate from rpcrdma_xprt`](https://chenxiaosong.com/courses/kernel/patches/xprtrdma-kmalloc-rpcrdma_ep-separate-from-rpcrdma_xp.html)

[`12357f1b2c8e nfsd: minor 4.1 callback cleanup`](https://chenxiaosong.com/courses/kernel/patches/nfsd-minor-4.1-callback-cleanup.html)

[`2bbfed98a4d8 nfsd: Fix races between nfsd4_cb_release() and nfsd4_shutdown_callback()`](https://chenxiaosong.com/courses/kernel/patches/nfsd-Fix-races-between-nfsd4_cb_release-and-nfsd4_sh.html)

[`22876f540bdf NFS: Don't call generic_error_remove_page() while holding locks`]https://chenxiaosong.com/courses/kernel/patches/NFS-Don-t-call-generic_error_remove_page-while-holdi.html)

[`e6abc8caa6de nfsd: Don't release the callback slot unless it was actually held`](https://chenxiaosong.com/courses/kernel/patches/nfsd-Don-t-release-the-callback-slot-unless-it-was-a.html)

# SMB(CIFS)文件系统

[`7de0394801da cifs: Fix in error types returned for out-of-credit situations.`](https://chenxiaosong.com/courses/kernel/patches/cifs-Fix-in-error-types-returned-for-out-of-credit-s.html)

[`d328c09ee9f1 smb: client: fix use-after-free bug in cifs_debug_data_proc_show()`](https://chenxiaosong.com/courses/kernel/patches/smb-client-fix-use-after-free-bug-in-cifs_debug_data.html)