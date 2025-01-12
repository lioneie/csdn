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

