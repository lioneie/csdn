[`e6abc8caa6de nfsd: Don't release the callback slot unless it was actually held`](https://lore.kernel.org/all/20190405155437.5545-1-trond.myklebust@hammerspace.com/):
```
nfsd: 只有在实际持有回调槽时才释放它

如果在回调槽关闭时有多个回调排队等待回调槽，那么它们目前都会像持有该槽一样，调用 nfsd4_cb_sequence_done()，从而导致有趣的副作用。

此外，nfsd4_cb_sequence_done() 中的 'retry_nowait' 路径会在不先释放槽的情况下返回 nfsd4_cb_prepare()，这会在第二次调用 nfsd41_cb_get_slot() 时导致死锁。

因此，该补丁添加了一个布尔值来跟踪回调是否实际获取了槽，以便在这两种情况下做出正确的处理。
```
