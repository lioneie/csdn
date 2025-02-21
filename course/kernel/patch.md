本文章列出一些内核补丁的分析，有些是我写的，有些是我定位问题时遇到的。

# NFS（网络文件系统）

[点击这里查看NFS相关补丁](https://chenxiaosong.com/course/nfs/patch.html)

# SMB(CIFS)文件系统

[点击这里查看SMB相关补丁](https://chenxiaosong.com/course/smb/patch.html)

# 我写的补丁

[点击查看kernel.org网站上我的Linux内核邮件列表](https://lore.kernel.org/all/?q=chenxiaosong)

[点击查看kernel.org网站上我的Linux内核仓库提交记录](https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git/log/?qt=grep&q=chenxiaosong)（加载需要一丢丢时间哈）

我写的补丁，除了上面的模块外，其他模块还有以下补丁。

[`001c179c4e26 xfs: fix NULL pointer dereference in xfs_getbmap()`](https://chenxiaosong.com/course/kernel/patch/xfs-fix-NULL-pointer-dereference-in-xfs_getbmap.html)

[`84ec758fb2daa configfs: fix a race in configfs_{,un}register_subsystem()`](https://chenxiaosong.com/course/kernel/patch/configfs-fix-a-race-in-configfs_-un-register_subsyst.html)

[`f7e942b5bb35d btrfs: qgroup: fix sleep from invalid context bug in btrfs_qgroup_inherit()`](https://lore.kernel.org/all/20221116142354.1228954-3-chenxiaosong2@huawei.com/)

[`a4c853af0c511 btrfs: add might_sleep() annotations`](https://lore.kernel.org/all/20221116142354.1228954-2-chenxiaosong2@huawei.com/)

[`1b513f613731e ntfs: fix BUG_ON in ntfs_lookup_inode_by_name()`](https://lore.kernel.org/all/20220809064730.2316892-1-chenxiaosong2@huawei.com/)

[CVE-2023-26607](https://nvd.nist.gov/vuln/detail/CVE-2023-26607): [`38c9c22a85aee ntfs: fix use-after-free in ntfs_ucsncmp()`](https://lore.kernel.org/all/20220709064511.3304299-1-chenxiaosong2@huawei.com/)（还有其他人的修复补丁）

# 调度

[`sched: EEVDF and latency-nice and/or slice-attr`](https://chenxiaosong.com/course/kernel/patch/sched-EEVDF-and-latency-nice-and-or-slice-attr.html)

<!--
# VFS（虚拟文件系统）

[`4595a298d556 iomap: Set all uptodate bits for an Uptodate page`](https://chenxiaosong.com/course/kernel/patch/iomap-Set-all-uptodate-bits-for-an-Uptodate-page.html)
-->

# EXT文件系统

[`23e3d7f7061f jbd2: fix a potential race while discarding reserved buffers after an abort`](https://chenxiaosong.com/course/kernel/patch/jbd2-fix-a-potential-race-while-discarding-reserved-.html)

[`ef09ed5d37b8 ext4: fix bug_on in ext4_writepages`](https://chenxiaosong.com/course/kernel/patch/ext4-fix-bug_on-in-ext4_writepages.html)

[`b98535d09179 ext4: fix bug_on in start_this_handle during umount filesystem`](https://chenxiaosong.com/course/kernel/patch/ext4-fix-bug_on-in-start_this_handle-during-umount-f.html)

[`a2b0b205d125 ext4: fix symlink file size not match to file content`](https://chenxiaosong.com/course/kernel/patch/ext4-fix-symlink-file-size-not-match-to-file-content.html)

[`c186f0887fe7 ext4: fix use-after-free in ext4_search_dir`](https://chenxiaosong.com/course/kernel/patch/ext4-fix-use-after-free-in-ext4_search_dir.html)

[`some refactor of __ext4_fill_super()`](https://chenxiaosong.com/course/kernel/patch/refactor-of-__ext4_fill_super.html)
