本文章列出一些内核补丁的分析，有些是我写的，有些是我定位问题时遇到的。

# NFS（网络文件系统）

[点击这里查看NFS相关补丁](https://chenxiaosong.com/courses/nfs/nfs-patches.html)

# SMB(CIFS)文件系统

[点击这里查看SMB相关补丁](https://chenxiaosong.com/courses/smb/smb-patches.html)

# 调度

[`sched: EEVDF and latency-nice and/or slice-attr`](https://chenxiaosong.com/courses/kernel/patches/sched-EEVDF-and-latency-nice-and-or-slice-attr.html)

# VFS（虚拟文件系统）

[`4595a298d556 iomap: Set all uptodate bits for an Uptodate page`](https://chenxiaosong.com/courses/kernel/patches/iomap-Set-all-uptodate-bits-for-an-Uptodate-page.html)

# EXT文件系统

[`23e3d7f7061f jbd2: fix a potential race while discarding reserved buffers after an abort`](https://chenxiaosong.com/courses/kernel/patches/jbd2-fix-a-potential-race-while-discarding-reserved-.html)

[`ef09ed5d37b8 ext4: fix bug_on in ext4_writepages`](https://chenxiaosong.com/courses/kernel/patches/ext4-fix-bug_on-in-ext4_writepages.html)

[`b98535d09179 ext4: fix bug_on in start_this_handle during umount filesystem`](https://chenxiaosong.com/courses/kernel/patches/ext4-fix-bug_on-in-start_this_handle-during-umount-f.html)

[`a2b0b205d125 ext4: fix symlink file size not match to file content`](https://chenxiaosong.com/courses/kernel/patches/ext4-fix-symlink-file-size-not-match-to-file-content.html)

[`c186f0887fe7 ext4: fix use-after-free in ext4_search_dir`](https://chenxiaosong.com/courses/kernel/patches/ext4-fix-use-after-free-in-ext4_search_dir.html)

[`some refactor of __ext4_fill_super()`](https://chenxiaosong.com/courses/kernel/patches/refactor-of-__ext4_fill_super.html)
