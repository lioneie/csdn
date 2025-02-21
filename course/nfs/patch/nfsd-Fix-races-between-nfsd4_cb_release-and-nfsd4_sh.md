# 邮件内容

[`2bbfed98a4d8 nfsd: Fix races between nfsd4_cb_release() and nfsd4_shutdown_callback()`](https://lore.kernel.org/all/20191023214318.9350-1-trond.myklebust@hammerspace.com/) 邮件:

- Trond Myklebust: 当我们销毁客户端租约并调用 `nfsd4_shutdown_callback()` 时，我们必须确保在所有未完成的回调终止并释放它们的有效负载之前不返回。
- J. Bruce Fields: 这太好了，谢谢！我们从 Red Hat 用户那里看到了我相当确定是相同的 bug。我认为我的盲区是假设 rpc 任务不会在 `rpc_shutdown_client()` 之后继续存在。然而，它导致了 xfstests 的运行挂起，我还没有弄清楚原因。我会在今天下午花些时间进行研究，并告诉你我找到的东西。
- Trond Myklebust: 这是发生在版本2还是版本1？在版本1中，`__destroy_client()` 中肯定存在挂起问题，我认为在版本2中已经修复的引用计数泄漏。
- J. Bruce Fields: 我以为我正在运行版本2，让我仔细检查一下...
- J. Bruce Fields: 是的，在版本2上我在 `generic/013` 测试中遇到了挂起的情况。我快速检查了一下日志，没有看到有趣的信息，除此之外我还没有进行详细的调查。
- J. Bruce Fields: 通过运行 `./check -nfs generic/013` 可以重现。在Wireshark中看到的最后一条信息是一个异步的COPY调用和回复。这意味着可能正在尝试执行 CB_OFFLOAD。嗯。
- J. Bruce Fields: [哦，我认为它只需要以下的更改。](https://lore.kernel.org/all/20191107222712.GB10806@fieldses.org/)
- J. Bruce Fields: 应用如下更改，其中一部分更改拆分为单独的补丁（因为这是我注意到这个 bug 的方式）。
- J. Bruce Fields: [哎呀，这次记得附上补丁了。--b.](https://lore.kernel.org/all/20191108175228.GB758@fieldses.org/)
- J. Bruce Fields: [回调代码依赖于其中很多部分只能从有序工作队列 callback_wq 中调用，这值得记录。](https://lore.kernel.org/all/20191108175417.GC758@fieldses.org/)
- J. Bruce Fields: [意外的错误可能表明回调路径存在问题。](https://lore.kernel.org/all/20191108175559.GD758@fieldses.org/)

讨论此补丁的相关邮件: [nfsd: radix tree warning in nfs4_put_stid and kernel panic](https://lore.kernel.org/all/76C32636621C40EC87811F625761F2AF@alyakaslap/)

# 依赖补丁

4.19等低版本合入此补丁可能还要合入前置补丁[`12357f1b2c8e nfsd: minor 4.1 callback cleanup`](https://chenxiaosong.com/course/nfs/patch/nfsd-minor-4.1-callback-cleanup.html)。

已被回退的后续修复补丁[`c1ccfcf1a9bf NFSD: Reschedule CB operations when backchannel rpc_clnt is shut down`](https://chenxiaosong.com/course/nfs/patch/NFSD-Reschedule-CB-operations-when-backchannel-rpc_c.html)。


# 代码分析

`struct nfs4_client`中增加一个字段`cl_cb_inflight`表示未完成的回调的个数，注意这个补丁的标题是说竞争发生在两个函数之间。我们先来看一下补丁合入前的竞争，`nfsd4_cb_release()`和`__destroy_client()`同时调用到`radix_tree_node_free()`，导致`rcu_head`在被释放之后又被释放了一次。
```c
nfsd4_cb_release
  // nfsd4_run_cb // 这里补丁合入前后没有变化
  //   queue_work(callback_wq, &cb->cb_work)
  nfsd4_cb_recall_release // cb->cb_ops->release
    nfs4_put_stid
      idr_remove
        radix_tree_delete_item
          __radix_tree_delete
            delete_node
              radix_tree_node_free // __destroy_client中也调用到这里，并发

__destroy_client
  nfsd4_shutdown_callback
  free_client
    idr_destroy
      radix_tree_free_nodes
        radix_tree_node_free // nfsd4_cb_release也调用到这里，并发
```

合入补丁之后，`nfsd4_cb_release()`中的`radix_tree_node_free()`执行完后调用`nfsd41_cb_inflight_end()`唤醒`nfsd4_shutdown_callback()`，`free_client()`才开始执行，避免了并发的场景。
```c
nfsd4_cb_release
  // nfsd4_queue_cb // 这里补丁合入前后没有变化
  //   queue_work(callback_wq, &cb->cb_work)
  nfsd41_destroy_cb
    nfsd4_cb_recall_release // cb->cb_ops->release
      nfs4_put_stid
        idr_remove
          radix_tree_delete_item
            __radix_tree_delete
              delete_node
                radix_tree_node_free // 执行完后调用nfsd41_cb_inflight_end唤醒nfsd4_shutdown_callback
    nfsd41_cb_inflight_end
      atomic_dec_and_test
      wake_up_var // cl_cb_inflight变为0时，唤醒nfsd4_shutdown_callback

__destroy_client
  nfsd4_shutdown_callback
    nfsd41_cb_inflight_wait_complete // cl_cb_inflight变为0时，唤醒
  free_client
    idr_destroy
      radix_tree_free_nodes
        radix_tree_node_free // nfsd41_cb_inflight_wait_complete唤醒后才会执行到这里，没有并发的情况
```

<!--
调试:
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
-->
