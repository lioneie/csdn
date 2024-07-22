
邮件列表类似问题的讨论：[nfsd: radix tree warning in nfs4_put_stid and kernel panic](https://lore.kernel.org/all/76C32636621C40EC87811F625761F2AF@alyakaslap/)

[`2bbfed98a4d8 nfsd: Fix races between nfsd4_cb_release() and nfsd4_shutdown_callback()`](https://lore.kernel.org/all/20191023214318.9350-1-trond.myklebust@hammerspace.com/) 邮件：

- Trond Myklebust: 当我们销毁客户端租约并调用 `nfsd4_shutdown_callback()` 时，我们必须确保在所有未完成的回调终止并释放它们的有效负载之前不返回。
- J. Bruce Fields: 这太好了，谢谢！我们从 Red Hat 用户那里看到了我相当确定是相同的 bug。我认为我的盲区是假设 rpc 任务不会在 rpc_shutdown_client() 之后继续存在。然而，它导致了 xfstests 的运行挂起，我还没有弄清楚原因。我会在今天下午花些时间进行研究，并告诉你我找到的东西。
- Trond Myklebust: 这是发生在版本2还是版本1？在版本1中，由于我认为在版本2中已经修复的引用计数泄漏，__destroy_client() 中肯定存在挂起问题。
- J. Bruce Fields: 我以为我正在运行版本2，让我仔细检查一下...
- J. Bruce Fields: 是的，在版本2上我在 `generic/013` 测试中遇到了挂起的情况。我快速检查了一下日志，没有看到有趣的信息，除此之外我还没有进行详细的调查。
- J. Bruce Fields： 通过运行 `./check -nfs generic/013` 可以重现。在Wireshark中看到的最后一条信息是一个异步的COPY调用和回复。这意味着可能正在尝试执行 CB_OFFLOAD。嗯。
- J. Bruce Fields: [哦，我认为它只需要以下的更改。](https://lore.kernel.org/all/20191107222712.GB10806@fieldses.org/)
- J. Bruce Fields: 应用如下更改，其中一部分更改拆分为单独的补丁（因为这是我注意到这个 bug 的方式）。
- J. Bruce Fields: [哎呀，这次记得附上补丁了。--b.](https://lore.kernel.org/all/20191108175228.GB758@fieldses.org/)
- J. Bruce Fields: [回调代码依赖于其中很多部分只能从有序工作队列 callback_wq 中调用，这值得记录。](https://lore.kernel.org/all/20191108175417.GC758@fieldses.org/)
- J. Bruce Fields: [意外的错误可能表明回调路径存在问题。](https://lore.kernel.org/all/20191108175559.GD758@fieldses.org/)

```c
// 重启服务 systemctl restart nfs-server
nfsd_svc
  nfsd_destroy_serv
    nfsd_shutdown_net
      nfs4_state_shutdown_net
        nfs4_state_destroy_net
          destroy_client
            __destroy_client
              nfsd4_shutdown_callback



// 挂载 4.0
rpc_async_schedule
  __rpc_execute
    rpc_exit_task
      nfsd4_cb_probe_done
        nfsd4_mark_cb_state(clp, NFSD4_CB_UP)
```
