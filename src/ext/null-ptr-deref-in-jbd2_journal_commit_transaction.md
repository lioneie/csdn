# 问题描述

```sh
[   72.796117] EXT4-fs error (device sda): ext4_journal_check_start:83: comm fallocate: Detected aborted journal
[   72.826847] EXT4-fs (sda): Remounting filesystem read-only
fallocate: fallocate failed: Read-only file system
[   74.791830] jbd2_journal_commit_transaction: jh=0xffff9cfefe725d90 bh=0x0000000000000000 end delay
[   74.793597] ------------[ cut here ]------------
[   74.794203] kernel BUG at fs/jbd2/transaction.c:2063!
[   74.794886] invalid opcode: 0000 [#1] PREEMPT SMP PTI
[   74.795533] CPU: 4 PID: 2260 Comm: jbd2/sda-8 Not tainted 5.17.0-rc8-next-20220315-dirty #150
[   74.798327] RIP: 0010:__jbd2_journal_unfile_buffer+0x3e/0x60
[   74.801971] RSP: 0018:ffffa828c24a3cb8 EFLAGS: 00010202
[   74.802694] RAX: 0000000000000000 RBX: 0000000000000000 RCX: 0000000000000000
[   74.803601] RDX: 0000000000000001 RSI: ffff9cfefe725d90 RDI: ffff9cfefe725d90
[   74.804554] RBP: ffff9cfefe725d90 R08: 0000000000000000 R09: ffffa828c24a3b20
[   74.805471] R10: 0000000000000001 R11: 0000000000000001 R12: ffff9cfefe725d90
[   74.806385] R13: ffff9cfefe725d98 R14: 0000000000000000 R15: ffff9cfe833a4d00
[   74.807301] FS:  0000000000000000(0000) GS:ffff9d01afb00000(0000) knlGS:0000000000000000
[   74.808338] CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
[   74.809084] CR2: 00007f2b81bf4000 CR3: 0000000100056000 CR4: 00000000000006e0
[   74.810047] DR0: 0000000000000000 DR1: 0000000000000000 DR2: 0000000000000000
[   74.810981] DR3: 0000000000000000 DR6: 00000000fffe0ff0 DR7: 0000000000000400
[   74.811897] Call Trace:
[   74.812241]  <TASK>
[   74.812566]  __jbd2_journal_refile_buffer+0x12f/0x180
[   74.813246]  jbd2_journal_refile_buffer+0x4c/0xa0
[   74.813869]  jbd2_journal_commit_transaction.cold+0xa1/0x148
[   74.817550]  kjournald2+0xf8/0x3e0
[   74.819056]  kthread+0x153/0x1c0
[   74.819963]  ret_from_fork+0x22/0x30
```

# 复现程序

## 内核构造补丁

```c
From 3465bf5459a86084db84408653ea83789f606eee Mon Sep 17 00:00:00 2001
From: ChenXiaoSong <chenxiaosongemail@foxmail.com>
Date: Wed, 20 Apr 2022 23:32:57 +0800
Subject: [PATCH] reproduce jbd2 deref null ptr

Signed-off-by: ChenXiaoSong <chenxiaosongemail@foxmail.com>
---
 fs/ext4/inode.c   | 7 +++++++
 fs/jbd2/commit.c  | 4 ++++
 fs/jbd2/journal.c | 6 ++++++
 3 files changed, 17 insertions(+)

diff --git a/fs/ext4/inode.c b/fs/ext4/inode.c
index 1ce13f69fbec..bb4b2fe8968d 100644
--- a/fs/ext4/inode.c
+++ b/fs/ext4/inode.c
@@ -49,6 +49,7 @@
 #include "truncate.h"
 
 #include <trace/events/ext4.h>
+#include <linux/delay.h>
 
 static __u32 ext4_inode_csum(struct inode *inode, struct ext4_inode *raw,
 			      struct ext4_inode_info *ei)
@@ -1261,6 +1262,9 @@ static int write_end_fn(handle_t *handle, struct inode *inode,
 	if (!buffer_mapped(bh) || buffer_freed(bh))
 		return 0;
 	set_buffer_uptodate(bh);
+	printk("%s:%d,jh:%px,bh:%px,begin sleep...\n", __func__, __LINE__, bh2jh(bh), bh);
+	mdelay(2000);
+	printk("%s:%d,jh:%px,bh:%px,end sleep...\n", __func__, __LINE__, bh2jh(bh), bh);
 	ret = ext4_handle_dirty_metadata(handle, NULL, bh);
 	clear_buffer_meta(bh);
 	clear_buffer_prio(bh);
@@ -4034,6 +4038,9 @@ int ext4_punch_hole(struct inode *inode, loff_t offset, loff_t length)
 		ret = ext4_update_disksize_before_punch(inode, offset, length);
 		if (ret)
 			goto out_dio;
+		printk("%s:%d,begin sleep...\n", __func__, __LINE__);
+		mdelay(3000);
+		printk("%s:%d,end sleep...\n", __func__, __LINE__);
 		truncate_pagecache_range(inode, first_block_offset,
 					 last_block_offset);
 	}
diff --git a/fs/jbd2/commit.c b/fs/jbd2/commit.c
index 5b9408e3b370..f7a4db3835ee 100644
--- a/fs/jbd2/commit.c
+++ b/fs/jbd2/commit.c
@@ -25,6 +25,7 @@
 #include <linux/blkdev.h>
 #include <linux/bitops.h>
 #include <trace/events/jbd2.h>
+#include <linux/delay.h>
 
 /*
  * IO end handler for temporary buffer_heads handling writes to the journal.
@@ -511,6 +512,9 @@ void jbd2_journal_commit_transaction(journal_t *journal)
 	 */
 	while (commit_transaction->t_reserved_list) {
 		jh = commit_transaction->t_reserved_list;
+		printk("%s:%d,jh:%px,bh:%px,begin sleep...\n", __func__, __LINE__, jh, jh2bh(jh));
+		mdelay(5000);
+		printk("%s:%d,jh:%px,bh:%px,end sleep...\n", __func__, __LINE__, jh, jh2bh(jh));
 		JBUFFER_TRACE(jh, "reserved, unused: refile");
 		/*
 		 * A jbd2_journal_get_undo_access()+jbd2_journal_release_buffer() may
diff --git a/fs/jbd2/journal.c b/fs/jbd2/journal.c
index fcacafa4510d..9bad5d4b2a84 100644
--- a/fs/jbd2/journal.c
+++ b/fs/jbd2/journal.c
@@ -47,6 +47,7 @@
 
 #include <linux/uaccess.h>
 #include <asm/page.h>
+#include <linux/delay.h>
 
 #ifdef CONFIG_JBD2_DEBUG
 ushort jbd2_journal_enable_debug __read_mostly;
@@ -2993,6 +2994,11 @@ static void __journal_remove_journal_head(struct buffer_head *bh)
 	/* Unlink before dropping the lock */
 	bh->b_private = NULL;
 	jh->b_bh = NULL;	/* debug, really */
+	if (strcmp(current->comm, "fallocate") == 0 || strcmp(current->comm, "ln") == 0) {
+		printk("%s:%d,jh:%px,bh:%px,begin sleep...\n", __func__, __LINE__, jh, bh);
+		mdelay(10000);
+		printk("%s:%d,jh:%px,bh:%px,end sleep...\n", __func__, __LINE__, jh, bh);
+	}
 	clear_buffer_jbd(bh);
 }
 
-- 
2.25.1
```

## fallocate 文件空洞

```sh
fallocate -l 1M file
ls -lh
# total 1.0M
# -rw-r--r--. 1 root root 1.0M Apr 21 01:14 file
du -c file -h
# 1.0M	file
# 1.0M	total

fallocate -o 0 -l 412K -n -p /mnt/file
ls -lh
# total 612K
# -rw-r--r--. 1 root root 1.0M Apr 21 01:15 file
du -c file -h
# 612K	file
# 612K	total

fallocate -l 312K file
ls -lh
# total 924K
# -rw-r--r--. 1 root root 1.0M Apr 21 01:15 file
du -c file -h
# 924K	file
# 924K	total

fallocate -o 312K -l 50K file # 4K对齐,实际分配52K
ls -lh
# total 976K
# -rw-r--r--. 1 root root 1.0M Apr 21 01:20 file
du -c file -h
# 976K	file
# 976K	total
```

## 常规文件, journal 模式

c程序：
```c
#include <stdio.h>
#include <errno.h>
#include <unistd.h>
#include <linux/fs.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#define LEN 4096

int main()
{
	int fd, res;
	char buf[LEN] = {0};
	fd = open("/mnt/file", O_RDWR);
	if (fd < 0) {
		printf("open fail, errno:%d\n", errno);
		return 1;
	}
	res = write(fd, buf, LEN);
	if (res != LEN) {
		printf("write fail, errno:%d\n", errno);
		return 1;
	}
	printf("success\n");
	return 0;
}
```

```sh
umount /mnt
mkfs.ext4 -F -b 4096 /dev/sda
mount -o data=journal /dev/sda /mnt
rm /mnt/file -rf
dd if=/dev/zero of=/mnt/file oflag=sync bs=4096 count=2
sync

./a.out & # c程序
sleep 0.5
fallocate -o 0 -l 4096 -n -p /mnt/file & # 可以只指定 -p
sleep 1
mount -o remount,abort /mnt
```

## 常规文件, order 模式

c程序：
```c
#include <stdio.h>
#include <errno.h>
#include <unistd.h>
#include <linux/fs.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#define LEN 4096
#define EXT4_JOURNAL_DATA_FL 0x00004000

int main()
{
        int fd, res;
        int flags = EXT4_JOURNAL_DATA_FL;
        char buf[LEN] = {0};
        fd = open("/mnt/file", O_RDWR);
        if (fd < 0) {
                printf("open fail, errno:%d\n", errno);
                return 1;
        }

        res = ioctl(fd, FS_IOC_SETFLAGS, &flags);
        if (res < 0) {
                printf("ioctl fail, errno:%d\n", errno);
                return 1;
        }

        res = fsync(fd);
        if (res < 0) {
                printf("fsync fail, errno:%d\n", errno);
                return 1;
        }

        res = write(fd, buf, LEN);
        if (res != LEN) {
                printf("write fail, errno:%d\n", errno);
                return 1;
        }

        printf("success\n");
        return 0;
}
```

```sh
umount /mnt
mkfs.ext4 -F -b 4096 /dev/sda
mount -o nodelalloc /dev/sda /mnt # 必须要指定　nodelalloc
rm /mnt/file -rf
dd if=/dev/zero of=/mnt/file bs=4096 count=2
sync

./a.out &
sleep 0.5
fallocate -o 0 -l 4096 -n -p /mnt/file & # 可以只指定 -p
sleep 1
mount -o remount,abort /mnt
```

## symbol link

```sh
umount /mnt
mkfs.ext4 -F -b 4096 /dev/sda
mount /dev/sda /mnt
mkdir /mnt/123456789012345678901234567890/1234567890123456789012345678901234567890 -p
touch /mnt/123456789012345678901234567890/1234567890123456789012345678901234567890/file
ln -s /mnt/123456789012345678901234567890/1234567890123456789012345678901234567890/file /mnt/link &
sleep 0.5
mount -o remount,abort /mnt
```


# 代码分析

修复补丁： [23e3d7f7061f jbd2: fix a potential race while discarding reserved buffers after an abort](https://patchwork.ozlabs.org/project/linux-ext4/patch/20220317142137.1821590-1-yebin10@huawei.com/)

```c
// mkfs.ext4 -F -b 4096 /dev/sda
// mount -o nodelalloc /dev/sda /mnt
mount
  do_mount
    path_mount
      do_new_mount
        parse_monolithic_mount_data
          generic_parse_monolithic
            vfs_parse_fs_string
              vfs_parse_fs_param
                ext4_parse_param
        vfs_get_tree
          ext4_get_tree
            get_tree_bdev
              ext4_fill_super
                __ext4_fill_super
                  // EXT4_SB(sb)->s_mount_opt |= EXT4_MOUNT_DELALLOC
                  set_opt(sb, DELALLOC)
                  ext4_apply_options
                    // -o nodelalloc 挂载，在这里清除 EXT4_MOUNT_DELALLOC
                    sbi->s_mount_opt &= ~ctx->mask_s_mount_opt
                  ext4_load_journal
                    ext4_get_journal
                      jbd2_journal_init_inode
                        journal_init_common
                          journal->j_flags |= JBD2_ABORT

// int flags = EXT4_JOURNAL_DATA_FL
// ioctl(fd, EXT4_IOC_SETFLAGS, &flags)
ioctl
  do_vfs_ioctl
    ioctl_setflags
      vfs_fileattr_set
        ext4_fileattr_set
          ext4_ioctl_setflags
            ext4_change_inode_journal_flag
              ext4_set_inode_flag(inode, EXT4_INODE_JOURNAL_DATA)
              ext4_set_aops
                ext4_inode_journal_mode
                  if (!test_opt(inode->i_sb, DELALLOC) // delay alloc 不支持 journal 模式

// mount -o remount,abort /mnt
mount
  do_mount
    path_mount
      do_remount
        reconfigure_super
          ext4_reconfigure
            __ext4_remount
              __ext4_error
                ext4_handle_error
                  jbd2_journal_abort
                    journal->j_flags |= JBD2_ABORT

write
  ksys_write
    vfs_write
      new_sync_write
        call_write_iter
          ext4_file_write_iter
            ext4_buffered_write_iter
              generic_perform_write
                ext4_write_begin
                  ext4_should_journal_data
                    ext4_inode_journal_mode
                      ext4_test_inode_flag(inode, EXT4_INODE_JOURNAL_DATA)
                  ext4_walk_page_buffers
                    do_journal_get_write_access
                      ext4_journal_get_write_access
                        __ext4_journal_get_write_access
                          jbd2_journal_get_write_access
                            do_get_write_access
                              __jbd2_journal_file_buffer(jh, transaction, BJ_Reserved)
                ext4_journalled_write_end
                  ext4_walk_page_buffers
                    write_end_fn
                      ext4_handle_dirty_metadata
                        __ext4_handle_dirty_metadata
                          jbd2_journal_dirty_metadata
                            is_handle_aborted
                              is_journal_aborted
                                return journal->j_flags & JBD2_ABORT
                            return -EROFS

fallocate
  ksys_fallocate
    vfs_fallocate
      ext4_fallocate
        ext4_punch_hole
          truncate_pagecache_range
            truncate_inode_pages_range
              truncate_cleanup_folio
                folio_invalidate
                  ext4_journalled_invalidate_folio
                    __ext4_journalled_invalidate_folio
                      jbd2_journal_invalidate_folio
                        journal_unmap_buffer
                          write_lock(&journal->j_state_lock)
                          zap_buffer:
                          write_unlock(&journal->j_state_lock)
                          jbd2_journal_put_journal_head
                            __journal_remove_journal_head
                              jh->b_bh = NULL
                              clear_buffer_jbd

symlinkat
  do_symlinkat
    vfs_symlink
      ext4_symlink
        __page_symlink
          pagecache_write_end
            ext4_journalled_write_end
              ext4_walk_page_buffers
                write_end_fn
                  ext4_handle_dirty_metadata
                    __ext4_handle_dirty_metadata
                      jbd2_journal_dirty_metadata
                        is_handle_aborted
                          is_journal_aborted
                            return journal->j_flags & JBD2_ABORT
                        return -EROFS
        goto err_drop_inode
        err_drop_inode:
        iput
          iput_final
            evict
              ext4_evict_inode
                truncate_inode_pages_final
                  truncate_inode_pages
                    truncate_inode_pages_range
                      truncate_cleanup_folio
                        folio_invalidate
                          ext4_journalled_invalidate_folio
                            __ext4_journalled_invalidate_folio
                              jbd2_jouranl_invalidate_folio
                                journal_unmap_buffer
                                  if (transaction == NULL) { // 条件不满足
                                  } else if (transaction == journal->j_committing_transaction) { // 条件也不满足
                                  } else {
                                  may_free = __dispose_buffer
                                    __jbd2_journal_unfile_buffer
                                      __jbd2_journal_temp_unlink_buffer
                                        case BJ_Reserved:
                                        list = &transaction->t_reserved_list
                                        __blist_del_buffer // 从 reserved 链表中删除
                                    jbd2_journal_put_journal_head
                                      if (!jh->b_jcount) // jh->b_jcount == 1
                                      jbd_unlock_bh_journal_head
                                zap_buffer:
                                write_unlock(&journal->j_state_lock)
                                jbd2_journal_put_journal_head
                                __journal_remove_journal_head
                                  jh->b_bh = NULL
                                  clear_buffer_jbd

kthread
  // kthread_run(kjournald2, ...)
  kjournald2
    jbd2_journal_commit_transaction
      while (commit_transaction->t_reserved_list)
      jh = commit_transaction->t_reserved_list
```