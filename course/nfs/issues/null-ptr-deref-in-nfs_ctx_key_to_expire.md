# 问题现象

这个问题是以前华为同事在[openeuler的OLK-5.10分支](https://gitee.com/openeuler/kernel/tree/OLK-5.10/)上遇到的（现在我在麒麟软件），详情请看类似的[`[UBUNTU 20.04] Null Pointer issue in nfs code running Ubuntu on IBM Z`](https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1968096)，这个网页上提到修复补丁`ca05cbae2a04 NFS: Fix up nfs_ctx_key_to_expire()`。

[内存屏障相关的补丁可以参考`c0e48f9dea91 io_uring: add a memory barrier before atomic_read`](https://lore.kernel.org/all/1563453840-19778-1-git-send-email-liuzhengyuan@kylinos.cn/)

# 代码分析

华为的vmcore拿不出来，根据华为同事的解析结果，空指针解引用发生在`unx_match()`中的`if (!uid_eq(cred->cr_cred->fsuid, acred->cred->fsuid)`，`cred->cr_cred`的值为`NULL`。

合入`ca05cbae2a04 NFS: Fix up nfs_ctx_key_to_expire()`补丁前:
```c
// pwrite64系统调用
ksys_pwrite64
  vfs_write
    new_sync_write
      nfs_file_write
        nfs_key_timeout_notify
          nfs_ctx_key_to_expire
            unx_match // cred->cr_ops->crmatch
              // cred->cr_cred为NULL，发生空指针解引用
              if (!uid_eq(cred->cr_cred->fsuid
            unx_lookup_cred, // auth->au_ops->lookup_cred
            gss_key_timeout // cred->cr_ops->crkey_timeout

// 释放cr_cred不一定是从nfs_ctx_key_to_expire()调用到put_rpccred()，但这是比较好构造的情况吧
nfs_ctx_key_to_expire
  put_rpccred
    unx_destroy_cred
      call_rcu(&cred->cr_rcu, unx_free_cred_callback)
        put_cred(rpc_cred->cr_cred)
          __put_cred // 释放 cr_cred

// 注意write系统调用会加锁file->f_pos_lock
ksys_write / do_writev
  fdget_pos
    __fdget_pos
      mutex_lock(&file->f_pos_lock) // write在这里加锁，不会并发
```

当然空指针解引用问题涉及到乱序执行、内存屏障等，不好构造。这里我们先分析一下引用计数泄露的情况:
```c
ksys_pwrite64
  vfs_write
    new_sync_write
      nfs_file_write
        nfs_key_timeout_notify
          nfs_ctx_key_to_expire
            unx_lookup_cred, // auth->au_ops->lookup_cred
            // 两个进程同时lookup_cred成功，都对ll_cred进行了赋值，
            // 先赋值的cred没执行put_rpccred()，造成了引用计数泄露
            ctx->ll_cred = cred
```

# 构造复现

我们构造一下两个进程并发执行到`nfs_ctx_key_to_expire()`的情况，内核修改以下内容:
```sh
--- a/fs/nfs/write.c
+++ b/fs/nfs/write.c
@@ -37,6 +37,7 @@
 #include "pnfs.h"
 
 #include "nfstrace.h"
+#include <linux/delay.h>
 
 #define NFSDBG_FACILITY                NFSDBG_PAGECACHE
 
@@ -1237,6 +1238,9 @@ bool nfs_ctx_key_to_expire(struct nfs_open_context *ctx, struct inode *inode)
        struct auth_cred acred = {
                .cred = ctx->cred,
        };
+       printk("%s:%d, pid:%d, comm:%s, begin delay\n", __func__, __LINE__, current->pid, current->comm);
+       mdelay(10 * 1000);
+       printk("%s:%d, pid:%d, comm:%s, end delay\n", __func__, __LINE__, current->pid, current->comm);
 
        if (cred && !cred->cr_ops->crmatch(&acred, cred, 0)) {
                put_rpccred(cred);
```

用户态程序`test.c`:
```c
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>

int main() {
    const char *file_path = "/mnt/file";
    const char *message = "Hello, pwrite64!";
    off_t offset = 10;  // 从文件的第10个字节开始写

    // 打开文件，如果文件不存在则创建
    int fd = open(file_path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd == -1) {
        perror("open");
        return 1;
    }

    // 使用 pwrite 写数据
    ssize_t bytes_written = pwrite(fd, message, strlen(message), offset);
    if (bytes_written == -1) {
        perror("pwrite");
        close(fd);
        return 1;
    }

    printf("Wrote %zd bytes to %s at offset %ld\n", bytes_written, file_path, offset);

    // 关闭文件
    close(fd);
    return 0;
}
```

编译运行:
```sh
gcc -o test test.c
./test &
sleep 1
./test
```

现在构造出了两个进程同时执行到`nfs_ctx_key_to_expire()`的情况，引用计数泄露的情况只要同时`lookup_cred()`成功，然后都执行`ctx->ll_cred = cred`就会发生。后续再尝试。

至于空指针解引用的情况不好构造，因为涉及到乱序执行、内存屏障等，后面有时间再慢慢尝试构造。

# rcu相关函数注释翻译

趁此机会，顺便翻译一下rcu相关函数的注释，学习一下，请查看[《内核同步》](https://chenxiaosong.com/course/kernel/sync.html)。

