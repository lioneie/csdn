[`12357f1b2c8e nfsd: minor 4.1 callback cleanup`](https://lore.kernel.org/all/20191108175228.GB758@fieldses.org/)

作为4.19等低版本合入补丁[`2bbfed98a4d8 nfsd: Fix races between nfsd4_cb_release() and nfsd4_shutdown_callback()`](https://chenxiaosong.com/course/nfs/patch/nfsd-Fix-races-between-nfsd4_cb_release-and-nfsd4_sh.html)的前置补丁。

把所有`cb_holds_slot`变量的操作放到了新引入的辅助函数`nfsd41_cb_release_slot()`中。