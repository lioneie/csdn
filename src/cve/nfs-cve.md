# `CVE-2024-46690 40927f3d0972 nfsd: fix nfsd4_deleg_getattr_conflict in presence of third party lease`

引入问题的补丁: `c5967721e106 NFSD: handle GETATTR conflict with write delegation`。

[openeuler issue](https://gitee.com/src-openeuler/kernel/issues/IAR4A2)

# `CVE-2022-48829 a648fdeb7c0e NFSD: Fix NFSv3 SETATTR/CREATE's handling of large file sizes`

引入问题的补丁: `tags/v5.12-rc1 9cde9360d18d NFSD: Update the SETATTR3args decoder to use struct xdr_stream`。

[openeuler issue](https://gitee.com/src-openeuler/kernel/issues/IADGFA)

# `CVE-2022-48827 0cb4d23ae08c NFSD: Fix the behavior of READ near OFFSET_MAX`

```
NFSD：修复在 OFFSET_MAX 附近的 READ 行为

Dan Aloni 报告：

> 由于客户端提交的 8cfb9015280d（"NFS: Always provide aligned buffers to the RPC read layers"）补丁，0xfff 的读取会对齐到服务器的 rsize 为 0x1000。

> 结果，在一个服务器文件大小为 0x7fffffffffffffff 的测试中，客户端尝试从偏移量 0x7ffffffffffff000 开始读取，这会导致服务器中的 loff_t 溢出，并返回 NFS 错误代码 EINVAL 给客户端。于是客户端会无限期地重试该请求。

Linux NFS 客户端并没有正确处理 NFS_ERR_INVAL，尽管所有 NFS 规范都允许服务器返回该状态码用于 READ 操作。

为了替代返回 NFS_ERR_INVAL，应该让越界的 READ 请求成功并返回短小的结果。在结果中设置 EOF 标志，以防止客户端重试该 READ 请求。这种行为与 Solaris NFS 服务器一致。

请注意，NFSv3 和 NFSv4 在网络传输中使用的是 u64 偏移量值。这些偏移量值在内部使用前必须转换为 loff_t 类型——隐式类型转换不足以完成此任务。否则，VFS 对 sb->s_maxbytes 的检查将无法正确工作。
```

[openeuler issue](https://gitee.com/src-openeuler/kernel/issues/IADG80)。

[openeuler 5.10补丁](https://gitee.com/openeuler/kernel/pulls/10787)。

5.4代码没有`nfsd4_encode_read_plus()`。

# `CVE-2024-49974 aadc3bbea163 NFSD: Limit the number of concurrent async COPY operations`

```
NFS服务器：限制并发的异步COPY操作数量

目前似乎没有限制客户端可以启动的并发异步COPY操作的数量。此外，至少在我看来，每个异步COPY操作可以复制无限数量的4MB数据块，因此可能会持续很长时间。因此，我认为异步COPY操作可能成为一种拒绝服务（DoS）攻击的潜在载体。

我们需要添加一种限制机制，来限制并发的后台COPY操作数量。为了简单且公平起见，这个补丁实现了每个命名空间的限制。

当异步COPY请求发生时，如果并发操作数量已经超过限制，则返回 NFS4ERR_DELAY 错误。请求客户端可以选择在延迟后重新发送请求，或者退回使用传统的读写复制方式。

如果将来需要使该机制更为复杂，我们可以在后续的补丁中进一步讨论和改进。
```

[openeuler issue](https://gitee.com/src-openeuler/kernel/issues/IAYR9C)。

[openeuler 5.10补丁](https://gitee.com/openeuler/kernel/pulls/12460)，后续还有修复补丁:

- CVE-2024-50241: [`NFSD: Initialize struct nfsd4_copy earlier`](https://gitee.com/openeuler/kernel/pulls/13356)
- CVE-2024-53073: [`NFSD: Never decrement pending_async_copies on error`](https://gitee.com/openeuler/kernel/pulls/13905)

# `CVE-2024-41076 aad11473f8f4 NFSv4: Fix memory leak in nfs4_set_security_label`

引入问题的补丁: `1b00ad657997 NFS: Remove the nfs4_label from the nfs_setattrres`。

[openeuler issue](https://gitee.com/src-openeuler/kernel/issues/IAGELL)。

# `CVE-2024-26629 edcf9725150e nfsd: fix RELEASE_LOCKOWNER`

[openeuler issue](https://gitee.com/src-openeuler/kernel/issues/I98BN3)

## 补丁信息

```
nfsd: 修复RELEASE_LOCKOWNER

在nfsd4_release_lockowner()中对so_count的测试是毫无意义且有害的。恢复使用check_for_locks()，并将其修改为不睡眠。

首先: 有害。
正如nfsd4_release_lockowner()的kdoc注释中所记录的，对so_count的测试可能会出现假阳性，导致返回NFS4ERR_LOCKS_HELD，而实际上并未持有任何锁。这显然是协议违规，在Linux NFS客户端中可能会导致不正确的行为。

如果在某个线程仍在处理由于给定所有者持有冲突锁而失败的LOCK请求时发送了RELEASE_LOCKOWNER，则处理该LOCK请求的nfsd线程可能会持有对锁所有者的引用（conflock），导致nfsd4_release_lockowner()返回错误的错误。

Linux NFS客户端会忽略NFS4ERR_LOCKS_HELD错误，因为它从不发送NFS4_RELEASE_LOCKOWNER而不首先释放任何锁，因此它知道这种错误是不可能的。它假设锁所有者实际上已被释放，因此可以自由地在稍后的锁请求中重用相同的锁所有者标识符。

当它确实重新使用了先前RELEASE失败的锁所有者标识符时，它将自然使用零的lock_seqid。然而，服务器，即使没有释放锁所有者，也会期望更大的lock_seqid，因此会用NFS4ERR_BAD_SEQID回应。

因此，允许假阳性是有害的。

这个测试毫无意义，因为...嗯...它没有任何意义。

so_count是三个不同计数的总和。
1/列在so_stateids上的状态集合
2/由这些状态拥有的任何活动vfs锁集合
3/各种瞬态计数，例如冲突锁。

当对'2'进行测试时，很明显其中一个是通过find_lockowner_str_locked()获得的瞬态引用。另一个预期是什么并不清楚。

实际上，计数通常为2，因为so_stateids上恰好有一个状态。如果有更多的话，这将失败。

在我的测试中，我看到了两种调用RELEASE_LOCKOWNER的情况。在一种情况下，CLOSE在RELEASE_LOCKOWNER之前被调用。这将导致所有锁状态被移除，因此锁所有者被丢弃（当没有更多引用时，通常会发生这种情况，这通常发生在锁状态被丢弃时）。当nfsd4_release_lockowner()发现锁所有者不存在时，它会返回成功。

另一种情况显示了一个'2'的so_count，并且在so_stateid中列出了一个状态。看起来Linux客户端为每个文件使用单独的锁所有者，从而导致每个锁所有者一个锁状态，因此对'2'的这个测试是安全的。对于另一个客户端，可能不安全。

因此，此补丁将check_for_locks()更改为使用（较新的）find_any_file_locked()，以便不对nfs4_file引用进行引用，因此永远不会调用nfsd_file_put()，也永远不会睡眠。有了这个检查，可以安全地恢复对check_for_locks()的使用，而不是针对神秘的'2'进行测试。
```

## 4.19合补丁

前置补丁`eb82dd393744 nfsd: convert fi_deleg_file and ls_file fields to nfsd_file`合入时有冲突。前置补丁`e0aa651068bf nfsd: don't call nfsd_file_put from client states seqfile display`合入时也有冲突。冲突太大合入风险大。

# `CVE-2024-46696 1116e0e372eb nfsd: fix potential UAF in nfsd4_cb_getattr_release`

引入问题的补丁: `c5967721e106 NFSD: handle GETATTR conflict with write delegation`。

[openeuler issue](https://gitee.com/src-openeuler/kernel/issues/IAR4FS)

