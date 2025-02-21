相关的问题: [4.19 __nfs3_proc_setacls()空指针解引用问题](https://chenxiaosong.com/course/nfs/issue/4.19-null-ptr-deref-in-__nfs3_proc_setacls.html)。

`[PATCH 0/3] nfs_instantiate() might succeed leaving dentry negative unhashed`:
```
在添加提交 b0c6108ecf64 ("nfs_instantiate(): prevent multiple aliases for directory inode") 后，我的 NFS 客户端在同时对本地文件系统和通过 knfsd 导出的相同文件系统执行 Lustre 竞争测试时崩溃：

    BUG: unable to handle kernel NULL pointer dereference at 0000000000000028
     Call Trace:
      ? iput+0x76/0x200
      ? d_splice_alias+0x307/0x3c0
      ? dput.part.31+0x96/0x110
      ? nfs_instantiate+0x45/0x160 [nfs]
      nfs3_proc_setacls+0xa/0x20 [nfsv3]
      nfs3_proc_create+0x1cc/0x230 [nfsv3]
      nfs_create+0x83/0x160 [nfs]
      path_openat+0x11aa/0x14d0
      do_filp_open+0x93/0x100
      ? __check_object_size+0xa3/0x181
      do_sys_open+0x184/0x220
      do_syscall_64+0x5b/0x1b0
      entry_SYSCALL_64_after_hwframe+0x65/0xca

   158 static int __nfs3_proc_setacls(struct inode *inode, struct posix_acl *acl,
   159         struct posix_acl *dfacl)
   160 {
161     struct nfs_server *server = NFS_SERVER(inode);

0x28 的偏移量是 struct inode 中的 i_sb，我们传递了一个空指针 (NULL inode) 给 nfs3_proc_setacls()。

在分析这个问题后，我发现 R12 中的 dentry 在 nfs_instantiate() 之后有一个空的 inode，这在我们在 nfs_fhget() 之后将其移动到别名中是合理的（见上述提交）。确实，在子节点列表中是 d_splice_alias() 之后留下的相同的正 dentry。通常来说，移动它对于调用者来说是可以的，除了 NFSv3，因为我们希望 inode 指针能够随着 dentry 回到调用栈，以便我们可以在其上设置 ACL 或在 EXCLUSIVE 的情况下设置属性。

第一个补丁将 nfs_instantiate() 拆分开来，以便我们可以有两个调用路径，原始路径——其调用者不关心哪个 dentry 最终被散列，另一个新路径返回 dentry 或别名。

第二个补丁修改了 NFSv3，使其使用后者路径，供需要引用 dentry 的调用者使用。

第三个补丁删除了对正 dentry 的测试，因为这似乎是不可能的——我找不到路径能够触发它，并且在我所有的测试中从未触发过。
```

# [`406cd91533dcc NFS: Refactor nfs_instantiate() for dentry referencing callers`](https://lore.kernel.org/linux-nfs/5f1de77be01d5729bf246dce8e2fd2d8d191c6bb.1568377101.git.bcodding@redhat.com/)



# [`17fd6e457b30e NFSv3: use nfs_add_or_obtain() to create and reference inodes`](https://lore.kernel.org/linux-nfs/157982bc982443f8c675d4269e70da55afa82821.1568377101.git.bcodding@redhat.com/)



# [`581057c8346b9 NFS: remove unused check for negative dentry`](https://lore.kernel.org/linux-nfs/34f99243d118543593cf82d5862065fd037c58e7.1568377101.git.bcodding@redhat.com/)