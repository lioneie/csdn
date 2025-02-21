4.19内核打上[`22876f540bdf NFS: Don't call generic_error_remove_page() while holding locks`](https://lore.kernel.org/all/20190407175912.23528-21-trond.myklebust@hammerspace.com/)补丁之后，会引起软锁相关的问题，与此补丁相关的问题可以看一下[《4.19 nfs_updatepage()空指针解引用问题》](https://chenxiaosong.com/course/nfs/issue/4.19-null-ptr-deref-in-nfs_updatepage.html)。

