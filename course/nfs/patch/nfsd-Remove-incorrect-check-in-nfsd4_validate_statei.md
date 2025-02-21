[`600df3856f0b nfsd: Remove incorrect check in nfsd4_validate_stateid`](https://lore.kernel.org/all/20230718123837.124780-1-trondmy@kernel.org/)邮件及回复的邮件写了:

- Trond Myklebust: 如果客户端正在调用 TEST_STATEID，那是因为发生了某个事件，需要对所有状态标识进行有效性检查，并在已被撤销的状态标识上调用 FREE_STATEID。在这种情况下，要么该状态标识存在于与该 nfs4_client 关联的状态标识列表中（此时应该进行测试），要么不存在。没有其他需要考虑的条件。
- Jeff Layton: 我不太明白。这是在修复一个实际的 bug 吗？虽然承认这段代码似乎是不必要的，但移除它似乎不会导致用户可见的行为变化。我是否漏掉了什么？
- Trond Myklebust: 在 [https://bugzilla.redhat.com/show_bug.cgi?id=2176575](https://bugzilla.redhat.com/show_bug.cgi?id=2176575) 中明显触发了这个问题。此外，如果您查看提交 [663e36f07666](https://lore.kernel.org/all/20200319141849.GB1546@fieldses.org/)，您会发现它所做的一切就是移除日志消息，因为“这是预期的”。由于某种未知的原因，它没有意识到“然后检查是不正确的”。因此，是的，这是在修复一个真实的 bug。
- Jeff Layton: 是的，就我所知，那个提交只是移除了警告。我的假设是服务器分发的任何 stateid，si_opaque.so_clid 必须与 clid 匹配。但是...看起来 s2s 复制可能改变了这个规则？无论如何，这个补丁看起来没问题，所以我没有异议。我只是试图理解这可能发生的原因。
- Chuck Lever III: 我认为 [663e36f](https://lore.kernel.org/all/20200319141849.GB1546@fieldses.org/) 没有改变这个逻辑: 在发出警告时它“返回状态”，在移除警告后它也“返回状态”。如果存在 bug，它是否是在添加了“!same_clid()`”检查时引入的呢？修复: 7df302f75ee2 ("NFSD: TEST_STATEID should not return NFS4ERR_STALE_STATEID")
- Trond Myklebust: 正确。它无法修复比该补丁更旧的任何问题，因为它无法应用。
- Chuck Lever III: 正在进行测试。我计划将其应用于 nfsd-fixes 分支（用于 6.5-rc）

引入问题的补丁是[7df302f75ee2 NFSD: TEST_STATEID should not return NFS4ERR_STALE_STATEID](https://lore.kernel.org/all/20120529175556.4472.63375.stgit@lebasque.1015granger.net/)。

邮件中提到[Bug 2176575 点击查看中文翻译](https://chenxiaosong.com/src/translation/nfs/bugzilla-redhat-bug-2176575.html)中的以下描述似乎和[《4.19 nfs lazy umount 后无法挂载的问题》](https://chenxiaosong.com/src/nfs/4.19-nfs-mount-hung.html)遇到的问题相关:

> 在机器保持开启的状态下执行 umount -l / 和重新挂载同一文件系统似乎并没有改善情况。一旦发生这种情况，似乎无法停止它，即使通过重新启动服务器也不行。重新启动客户端可以很自然地修复问题。

TODO: 以下两句话，实在不知道怎么理解:

> 如果服务器设置了 SEQUENCEID 标志之一 SEQ4_STATUS_EXPIRED_SOME_STATE_REVOKED 或 SEQ4_STATUS_ADMIN_STATE_REVOKED，也会发生这种情况。
>
> 因此，这可能解释了循环的原因: 服务器期望通过FREE_STATEID释放不再有效的stateid，但这永远不会发生，因为TEST_STATEID的结果告诉客户端stateid是错误的。这再次意味着服务器无法清除SEQUENCEID标志，因此我们又会经历一轮TEST_STATEID。如此循环重复...

“这再次意味着服务器无法清除SEQUENCEID标志，因此我们又会经历一轮TEST_STATEID”，难道test stateid不应该是client端主动发起的？
