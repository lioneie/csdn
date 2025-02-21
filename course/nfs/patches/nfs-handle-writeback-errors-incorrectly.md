这里介绍一组我发到社区的补丁集，这组补丁集被nfs maintainer剽窃了，但他修改后的版本却没有解决我提出的问题。

我的补丁集: [`nfs: handle writeback errors correctly`](https://patchwork.kernel.org/project/linux-nfs/list/?series=628066&state=%2A&archive=both)。

[openeuler5.10的后续方案](https://gitee.com/openeuler/kernel/pulls/10046/commits)

# 问题描述

```
1. 误报空间不足
2. 执行`dd`命令非常非常慢
```

复现程序:
```sh
        nfs server            |       nfs client
 -----------------------------|---------------------------------------------
 # No space left on server    |
 fallocate -l 100G /svr/nospc |
                              | mount -t nfs $nfs_server_ip:/ /mnt
                              |
                              | # 预期错误: 空间不足
                              | dd if=/dev/zero of=/mnt/file count=1 ibs=1M
                              |
                              | # 释放挂载点的空间
                              | rm /mnt/nospc
                              |
                              | # 问题1: 误报空间不足，问题2: 非常非常慢
                              | dd if=/dev/zero of=/mnt/file count=1 ibs=1M
```

# 原因分析

空间不足时执行 `dd`，返回错误 `-ENOSPC`，没有清除 `wb_err` 中的错误:
```c
filp_close
  nfs4_file_flush
    nfs_wb_all // 缓存落盘
      filemap_write_and_wait
        filemap_write_and_wait_range
          __filemap_fdatawrite_range
            filemap_fdatawrite_wbc
              do_writepages
                nfs_writepages // 向 nfs server 发送 write 请求
          filemap_fdatawait_range
            __filemap_fdatawait_range
              wait_on_page_writeback // 等待 write 请求回复
    filemap_check_wb_err // 返回错误 -ENOSPC，没有清除 wb_err 中的错误

rpc_async_release
  rpc_free_task
    rpc_release_calldata
      nfs_pgio_release
        nfs_write_completion
          nfs_mapping_set_error
            mapping_set_error
              __filemap_set_wb_err
                errset_set(&mapping->wb_err, err) // 在 wb_err 中记录错误
              set_bit(..., &mapping->flags); // 在 flags 中记录错误，现已经被 nfs maintainer 删除
```

空间释放后执行 `dd`, 上一次执行 `dd` 时的错误还没清除，导致变成了同步写，速度非常非常慢，即使空间足够还是报错空间不足:
```c
write
  ksys_write
    vfs_write
      new_sync_write
        call_write_iter
          nfs_file_write
            since = filemap_sample_wb_err = 0
              errseq_sample
                if (!(old & ERRSEQ_SEEM)) // 上一次执行 dd 时的错误还没清除
                return 0
            error = filemap_check_wb_err(..., since = 0) = -ENOSPC
            if (nfs_need_check_write) // 条件满足
              nfs_error_is_fatal_on_server
                nfs_error_is_fatal
                  return true // -ENOSPC
            nfs_wb_all // 变成了 sync write，每 4K 耗时约 10ms，导致 dd 命令非常非常慢


filp_close
  nfs4_file_flush
    nfs_wb_all // 缓存落盘
      filemap_write_and_wait
        filemap_write_and_wait_range
          if (mapping_needs_writeback) // 所有的数据已经落盘
    since = filemap_sample_wb_err = 0
      errseq_sample
        if (!(old & ERRSEQ_SEEM)) // 上一次执行 dd 时的错误还没清除
        return 0
    filemap_check_wb_err // 返回错误 -ENOSPC，还是没有清除 wb_err 中的错误
```

# 我的修改方案

## 第一个补丁: write返回更详细的错误

[NFS: return more nuanced writeback errors in nfs_file_write()](https://patchwork.kernel.org/project/linux-nfs/patch/20220401034409.256770-2-chenxiaosong2@huawei.com/)

回退 [6c984083ec24 ("NFS: Use of mapping_set_error() results in spurious errors")](https://lore.kernel.org/all/20220215230518.24923-1-trondmy@kernel.org/)，并且在 `write` 中返回更详细的错误:
```c
rpc_async_release
  rpc_free_task
    rpc_release_calldata
      nfs_pgio_release
        nfs_write_completion
          nfs_mapping_set_error
            mapping_set_error
              __filemap_set_wb_err
                errset_set(&mapping->wb_err, err) // 在 wb_err 中记录错误
              set_bit(..., &mapping->flags); // 回退 maintainer 的补丁，在 flags 中记录错误

nfs_file_write
  generic_perform_write // 同步写
    nfs_write_end
      nfs_wb_all
        filemap_write_and_wait
          filemap_write_and_wait_range
            filemap_check_errors
              test_and_clear_bit(..., &mapping->flags) // 返回 flags 中的错误，并清除
  filemap_fdatawrite_range // 异步写
  filemap_fdatawait_range // 同步写
    __filemap_check_errors
      test_and_clear_bit(..., &mapping->flags) // 返回 flags 中的错误，并清除
  generic_write_sync // 同步写
    vfs_fsync_range
      nfs_file_fsync
  filemap_check_wb_err // 返回更详细的错误
    return -(file->f_mapping->wb_err & MAX_ERRNO) // 返回wb_err 中的错误
```

## 第二个补丁: flush返回正确的错误

[NFS: nfs{,4}_file_flush() return correct writeback errors](https://patchwork.kernel.org/project/linux-nfs/patch/20220401034409.256770-3-chenxiaosong2@huawei.com/)

只有在 `nfs_wb_all` 有新错误产生的情况下，才尝试返回更详细的错误:
```c
nfs_file_flush
  // nfs_wb_all 执行期间如果有新的错误产生，才尝试返回更详细的错误，否则返回0
  if (nfs_wb_all)
  filemap_check_wb_err
    return -(file->f_mapping->wb_err & MAX_ERRNO) // 返回 wb_err 中的错误
```

## 第三个补丁: 解决 async write 变成 sync write 的问题

[Revert "nfs: nfs_file_write() should check for writeback errors"](https://patchwork.kernel.org/project/linux-nfs/patch/20220401034409.256770-4-chenxiaosong2@huawei.com/)

回退问题补丁 "nfs: nfs_file_write() should check for writeback errors"
问题补丁存在的问题:
```c
write
  ksys_write
    vfs_write
      new_sync_write
        call_write_iter
          nfs_file_write
            since = filemap_sample_wb_err = 0
              errseq_sample
                if (!(old & ERRSEQ_SEEM)) // 上一次执行 dd 时的错误还没清除
                return 0
            error = filemap_check_wb_err(..., since = 0) = -ENOSPC
            if (nfs_need_check_write) // 条件满足
              nfs_error_is_fatal_on_server
                nfs_error_is_fatal
                  return true // -ENOSPC
            nfs_wb_all // 变成了 sync write，每 4K 耗时约 10ms，导致 dd 命令非常非常慢
```

# maintainer 的修改方案（未解决此问题）

补丁集: [Ensure mapping errors are reported only once](https://patchwork.kernel.org/project/linux-nfs/list/?series=631225&state=%2A&archive=both)

## 想解决问题的补丁（实际没解决）

[NFS: Don't report ENOSPC write errors twice](https://patchwork.kernel.org/project/linux-nfs/patch/20220411213346.762302-4-trondmy@kernel.org/)

存在的问题:
```
1. 没解决空间释放后执行 dd 报错的问题
2. async write 清除 wb_err
```

```c
// dd 命令会多次调用 write, 由于第一次调用 write 就报错 -ENOSPC, 所以后续不再调用 write，dd 命令失败
nfs_file_write
  since = filemap_sample_wb_err = 0
    errseq_sample
      if (!(old & ERRSEQ_SEEM)) // 上一次执行 dd 时的错误还没清除
      return 0
  error = filemap_check_wb_err(..., since = 0) = -ENOSPC // 没有新的错误产生，却报错
  nfs_wb_all // 执行了一次落盘
  error = file_check_and_advance_wb_err // 返回 -ENOSPC，并清除 wb_err 错误
    errseq_check_and_advance
      // *eseq 和 old 比较，相等则 *eseq = new, return old，不相等则 return *eseq
      cmpxchg(eseq, old, new)
        *eseq = new
        return old
      return -(new & MAX_ERRNO)
  return error // -ENOSPC
```

## maintainer 的其他补丁

```c
[v2,1/5] NFS: Do not report EINTR/ERESTARTSYS as mapping errors
如果执行 flush 时被信号打断，page 请求重新排队传输

[v2,2/5] NFS: fsync() should report filesystem errors over EINTR/ERESTARTSYS
`nfs_file_fsync -> nfs_file_fsync_commit -> nfs_commit_inode` 被信号打断，优先报 wb err

[v2,4/5] NFS: Do not report flush errors in nfs_write_end()
在 `nfs_write_end` 中推迟报错

[v2,5/5] NFS: Don't report errors from nfs_pageio_complete() more than once
不尝试报 nfs_pageio_complete 的错误
```

# 其他文件系统对 wb err 的处理

## 调用 fsync 时清除 wb_err

`btrfs, ceph, ext4, fuse` 调用 `file_check_and_advance_wb_err` 清除 `address_space wb_err`

## 实现 flush 的文件系统

`cifs` 通过 `address_space` 中的 `flags` 返回错误（只有 -EIO 或 -ENOSPC）:
```c
cifs_flush
  filemap_write_and_wait
    filemap_write_and_wait_range
      filemap_check_errors
        test_and_clear_bit(..., &mapping->flags)
```

`fuse` 通过 `address_space` 中的 `flags` 返回错误（只有 -EIO 或 -ENOSPC）:
```c
fuse_flush
  filemap_check_errors
    test_and_clear_bit(..., &mapping->flags)
```

`orangefs` 通过 `address_space` 中的 `flags` 返回错误（只有 -EIO 或 -ENOSPC）:
```c
orangefs_flush
  filemap_write_and_wait
    filemap_write_and_wait_range
      filemap_check_errors
        test_and_clear_bit(..., &mapping->flags)
```

`f2fs` 的 `f2fs_file_flush` 总是返回0

`ecryptfs, overlayfs` 调用真实文件系统的 `flush` 函数

## async write

其他文件系统异步写都不会清除 `address_space` 中的 `wb_err`, 因为只会被 `file_check_and_advance_wb_err` 清除

# 与 maintainer 的交流

[[v2,3/5] NFS: Don't report ENOSPC write errors twice](https://patchwork.kernel.org/project/linux-nfs/patch/20220411213346.762302-4-trondmy@kernel.org/)

[[-next,1/2] nfs: nfs{,4}_file_flush should consume writeback error
](https://patchwork.kernel.org/project/linux-nfs/patch/20220305124636.2002383-2-chenxiaosong2@huawei.com/)

[[-next,v2] NFS: report and clear ENOSPC/EFBIG/EDQUOT writeback error on close() file](https://patchwork.kernel.org/project/linux-nfs/patch/20220614152817.271507-1-chenxiaosong2@huawei.com/)

## maintainer 两个版本的补丁都无法解决问题

和 maintainer 说了2次，他的回复没有正面回答这个问题。

第一次没有回答，马上发了第2版。

第二次没有正面回答:
```
I understand all that. The point you appear to be missing is that this
is in fact in agreement with the documented behaviour in the write(2)
and fsync(2) manpages. These errors are supposed to be reported once,
even if they were caused by a write to a different file descriptor.

In fact, even with your change, if you make the second 'dd' call fsync
(by adding a conv=fsync), I would expect it to report the exact same
ENOSPC error, and that would be correct behaviour!

So my patches are more concerned with the fact that we appear to be
reporting the same error more than once, rather than the fact that
we're reporting them in the second attempt at I/O. As far as I'm
concerned, that is the main change that is needed to meet the behaviour
that is documented in the manpages.
```

回复中提到我的补丁空间释放后加 `(conv=fsync)` 执行 `dd` 时应该要报错，我回复说我的补丁符合他的预期，maintainer 不再回复。

## maintainer 不断强调是文档规定

```
> And more importantly, we can not detect new error by using 
> filemap_sample_wb_err()/filemap_sample_wb_err() while
> nfs_wb_all(),just 
> as I described:
> 
> ```c
>    since = filemap_sample_wb_err() = 0
>      errseq_sample
>        if (!(old & ERRSEQ_SEEN)) // nobody see the error
>          return 0;
>    nfs_wb_all // no new error
>    error = filemap_check_wb_err(..., since) != 0 // unexpected error
> ```


As I keep repeating, that is _documented behaviour_!
```

我和他说的明明是 `filemap_sample_wb_err/filemap_check_wb_err` 的用法错误，他却强调是文档规定

## maintainer 最后直接说是vfs的问题

```
If you want the rules to change, then you need to talk to the entire
filesystem community and get them to accept that the VFS level
implementation of error handling is incorrect.

That's my final word on this subject.
```

vfs的处理机制明明是没有问题的，他到最后却直接说是vfs处理机制的问题，而且说不再讨论这个问题。
