`b0c6108ecf64 nfs_instantiate(): prevent multiple aliases for directory inode`:
```
nfs_instantiate()：防止目录 inode 有多个别名

由于 NFS 支持基于文件句柄的打开（open-by-fhandle），我们必须处理 mkdir 与基于文件句柄猜测的打开（open-by-guessed-handle）之间的竞争条件。一个本地文件系统可能会决定新对象的 inode 编号，并在磁盘数据结构尚未完成之前，将该 inode 编号插入到 icache 中，并且仅在有了 dentry 别名之后才会解锁。这样，先执行 open-by-handle 的操作会悄然失败，而先执行 mkdir 的操作会让 open-by-handle 获取其 dentry。

对于 NFS 来说，这是不行的 —— icache 的键是服务器提供的 fhandle，我们在对象在服务器上完全创建之前无法获得它。我们必须应对这样一种可能性：open-by-handle 先获得内存中的 inode，并在其上附加一个 dentry，而 mkdir 后来才执行。

解决方案：让 nfs_mkdir() 使用 d_splice_alias() 来处理这些情况。
        * 我们可能会得到一个错误，只需将其返回给调用者。
        * 我们可能会得到 NULL —— 表示没有先前存在的 dentry 别名，我们刚刚完成了 d_add() 所做的事情。成功。
        * 我们可能会获得一个对已有别名的引用。在这种情况下，该别名已被移动到 nfs_mkdir() 参数的位置（并在此位置哈希），而 nfs_mkdir() 参数被保留为未哈希的负值。对于 ->mkdir() 调用者来说，这完全没问题，我们只需要释放从 d_splice_alias() 获取的引用并报告成功。
```

后续还有补丁集: [`nfs_instantiate() might succeed leaving dentry negative unhashed`](https://chenxiaosong.com/course/nfs/patch/patchset-nfs_instantiate-might-succeed-leaving-dentry-negative-unhashed.html)


