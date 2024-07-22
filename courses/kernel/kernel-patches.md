本文章列出一些内核补丁的分析，有些是我写的，有些是我定位问题时遇到的。

# NFS（网络文件系统）

[`e28ce90083f0 xprtrdma: kmalloc rpcrdma_ep separate from rpcrdma_xprt`](https://chenxiaosong.com/courses/kernel/patches/xprtrdma-kmalloc-rpcrdma_ep-separate-from-rpcrdma_xp.html)

[2bbfed98a4d8 nfsd: Fix races between nfsd4_cb_release() and nfsd4_shutdown_callback()`](https://chenxiaosong.com/courses/kernel/patches/nfsd-Fix-races-between-nfsd4_cb_release-and-nfsd4_sh.html)

# SMB(CIFS)文件系统

[`7de0394801da cifs: Fix in error types returned for out-of-credit situations.`](https://chenxiaosong.com/courses/kernel/patches/cifs-Fix-in-error-types-returned-for-out-of-credit-s.html)