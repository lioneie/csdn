[`c1ccfcf1a9bf NFSD: Reschedule CB operations when backchannel rpc_clnt is shut down`](https://lore.kernel.org/all/170629112969.20612.8526400738389878628.stgit@manet.1015granger.net/):
```
在管理客户端断开连接时，NFSD会关闭并替换backchannel的rpc_clnt。

如果在关闭backchannel的rpc_clnt时有回调操作挂起，目前nfsd4_run_cb_work()会直接丢弃该回调。但这里有多种情况需要处理:
- 客户端的租约正在销毁。抛弃该回调。
- 客户端断开连接。它可能会强制重新传输CB操作，或者由于其他原因断开连接。当客户端重新连接时，重新安排CB进行重新传输。

由于现在可以重新安排回调操作，请确保cb_ops->prepare只能被调用一次，将cb_ops->prepare段落移动到rpc_call_async()调用之前。
```

主线又做了回退[`Revert "NFSD: Reschedule CB operations when backchannel rpc_clnt is shut down"`](https://lore.kernel.org/all/171391800174.101038.3614787261244381619.stgit@klimt.1015granger.net/):
```
还原的提交尝试使NFSD在NFS客户端断开连接时重新传输挂起的回调操作，但如果客户端在回调操作仍在挂起时永久不可达，这会无意中引入危险的行为回归。

断开连接可能是由于网络分区，或者是NFS服务器需要强制NFS客户端重新传输（例如，如果发生GSS窗口不足）。

还原提交后，NFSD的行为将恢复到v6.8及之前的版本。如果在客户端收到回调操作之前连接被终止，挂起的回调操作将永久丢失。

对于某些回调操作，这种丢失是无害的。

然而，对于CB_RECALL，这种丢失意味着可能不必要地撤销委托。对于CB_OFFLOAD，挂起的COPY操作将永远无法完成，除非NFS客户端随后发送OFFLOAD_STATUS操作，而Linux NFS客户端目前并未实现此操作。

这些问题仍需以某种方式解决。
```