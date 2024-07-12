# 问题描述

```sh
------------[ cut here ]------------
kernel BUG at fs/jbd2/transaction.c:389!
invalid opcode: 0000 [#1] PREEMPT SMP KASAN PTI
CPU: 9 PID: 131 Comm: kworker/9:1 Not tainted 5.17.0-862.14.0.6.x86_64-00001-g23f87daf7d74-dirty #197
Workqueue: events flush_stashed_error_work
RIP: 0010:start_this_handle+0x41c/0x1160
RSP: 0018:ffff888106b47c20 EFLAGS: 00010202
RAX: ffffed10251b8400 RBX: ffff888128dc204c RCX: ffffffffb52972ac
RDX: 0000000000000200 RSI: 0000000000000004 RDI: ffff888128dc2050
RBP: 0000000000000039 R08: 0000000000000001 R09: ffffed10251b840a
R10: ffff888128dc204f R11: ffffed10251b8409 R12: ffff888116d78000
R13: 0000000000000000 R14: dffffc0000000000 R15: ffff888128dc2000
FS:  0000000000000000(0000) GS:ffff88839d680000(0000) knlGS:0000000000000000
CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
CR2: 0000000001620068 CR3: 0000000376c0e000 CR4: 00000000000006e0
DR0: 0000000000000000 DR1: 0000000000000000 DR2: 0000000000000000
DR3: 0000000000000000 DR6: 00000000fffe0ff0 DR7: 0000000000000400
Call Trace:
 <TASK>
 jbd2__journal_start+0x38a/0x790
 jbd2_journal_start+0x19/0x20
 flush_stashed_error_work+0x110/0x2b3
 process_one_work+0x688/0x1080
 worker_thread+0x8b/0xc50
 kthread+0x26f/0x310
 ret_from_fork+0x22/0x30
 </TASK>
Modules linked in:
---[ end trace 0000000000000000 ]---
```

# 内核构造补丁

```c
From d1a8dd46cc15f1df4453c2ae08d1c4f4a83c36e5 Mon Sep 17 00:00:00 2001
From: ChenXiaoSong <chenxiaosongemail@foxmail.com>
Date: Sun, 1 May 2022 19:53:24 +0800
Subject: [PATCH] reproduce bug_on in start_this_handle() during umount
 filesystem

Signed-off-by: ChenXiaoSong <chenxiaosongemail@foxmail.com>
---
 fs/ext4/super.c   | 7 +++++++
 fs/jbd2/journal.c | 4 ++++
 2 files changed, 11 insertions(+)

diff --git a/fs/ext4/super.c b/fs/ext4/super.c
index 81749eaddf4c..7cf8613a7841 100644
--- a/fs/ext4/super.c
+++ b/fs/ext4/super.c
@@ -56,6 +56,7 @@
 #include "acl.h"
 #include "mballoc.h"
 #include "fsmap.h"
+#include <linux/delay.h>
 
 #define CREATE_TRACE_POINTS
 #include <trace/events/ext4.h>
@@ -712,6 +713,9 @@ static void flush_stashed_error_work(struct work_struct *work)
 	journal_t *journal = sbi->s_journal;
 	handle_t *handle;
 
+	printk("%s:%d,begin delay\n", __func__, __LINE__);
+	mdelay(5000);
+	printk("%s:%d,end delay\n", __func__, __LINE__);
 	/*
 	 * If the journal is still running, we have to write out superblock
 	 * through the journal to avoid collisions of other journalled sb
@@ -1211,6 +1215,9 @@ static void ext4_put_super(struct super_block *sb)
 	 * Since we could still access attr_journal_task attribute via sysfs
 	 * path which could have sbi->s_journal->j_task as NULL
 	 */
+	printk("%s:%d,begin delay\n", __func__, __LINE__);
+	mdelay(5000);
+	printk("%s:%d,end delay\n", __func__, __LINE__);
 	ext4_unregister_sysfs(sb);
 
 	if (sbi->s_journal) {
diff --git a/fs/jbd2/journal.c b/fs/jbd2/journal.c
index fcacafa4510d..29ffdd4f6686 100644
--- a/fs/jbd2/journal.c
+++ b/fs/jbd2/journal.c
@@ -47,6 +47,7 @@
 
 #include <linux/uaccess.h>
 #include <asm/page.h>
+#include <linux/delay.h>
 
 #ifdef CONFIG_JBD2_DEBUG
 ushort jbd2_journal_enable_debug __read_mostly;
@@ -290,6 +291,9 @@ static void journal_kill_thread(journal_t *journal)
 {
 	write_lock(&journal->j_state_lock);
 	journal->j_flags |= JBD2_UNMOUNT;
+	printk("%s:%d,begin delay\n", __func__, __LINE__);
+	mdelay(5000);
+	printk("%s:%d,end delay\n", __func__, __LINE__);
 
 	while (journal->j_task) {
 		write_unlock(&journal->j_state_lock);
-- 
2.25.1
```

# 构造脚本

```sh
umount /mnt
mkfs.ext4 -E lazy_itable_init=0,lazy_journal_init=0 -b 4096 -F /dev/sda
mount /dev/sda /mnt
umount /mnt &
sleep 2
echo 1 > /sys/fs/ext4/sda/trigger_fs_error
```

# 代码流程

修复补丁：[b98535d09179 ext4: fix bug_on in start_this_handle during umount filesystem](https://lore.kernel.org/all/20220322012419.725457-1-yebin10@huawei.com/)

```c
mount
  do_mount
    path_mount
      do_new_mount
        vfs_get_tree
          ext4_get_tree
            get_tree_bdev
              ext4_fill_super
                __ext4_fill_super
                  INIT_WORK(&sbi->s_error_work, flush_stashed_error_work)
                  ext4_register_sysfs

// umount /mnt &
task_work_run
  __cleanup_mnt
    cleanup_mnt
      deactivate_super
        deactivate_locked_super
          kill_block_super
            generic_shutdown_super
              ext4_put_super
                flush_work(&sbi->s_error_work) // 等最后一个 work 执行完成
                jbd2_journal_destroy
                  journal_kill_thread

// echo 1 > /sys/fs/ext4/sda/trigger_fs_error,建议使用这种方法构造
write
  ksys_write
    vfs_write
      new_sync_write
        call_write_iter
          kernfs_fop_write_iter
            sysfs_kf_write
              ext4_attr_store
                trigger_test_error
                  ext4_error
                    ext4_handle_error
                      schedule_work(&EXT4_SB(sb)->s_error_work)

// cat /proc/fs/ext4/sda/mb_groups, 不建议使用这个方法构造
read
  ksys_read
    vfs_read
      new_sync_read
        call_read_iter
          proc_reg_read_iter
            seq_read_iter
              ext4_mb_seq_groups_show
                ext4_mb_load_buddy
                  ext4_mb_load_buddy_gfp
                    ext4_mb_init_group
                      ext4_mb_init_cache
                        ext4_read_block_bitmap_nowait
                          ext4_validate_block_bitmap
                            blk = ext4_valid_block_bitmap
                            // 把 blk 强制赋值成 -1, 就能进入以下条件
                            if (unlikely(blk != 0))

process_one_work
  flush_stashed_error_work
    jbd2_journal_start
      jbd2__journal_start
        start_this_handle
          if (!journal->j_running_transaction)
          goto repeat

// 时序
        umount                   | write procfs      |      error_work
---------------------------------|-------------------|---------------------
ext4_put_super                   |                   |            
 flush_work(&sbi->s_error_work)  |                   |            
                                 |trigger_test_error |            
                                 | ext4_error        |            
                                 |  ext4_handle_error|            
                                 |   schedule_work   |            
 jbd2_journal_destroy            |                   |            
  journal_kill_thread            |                   |            
   journal->j_flag |= JBD2_UMOUNT|                   |            
                                 |                   |flush_stashed_error_work
                                 |                   | jbd2_journal_start
                                 |                   |  jbd2__journal_start
                                 |                   |   start_this_handle
                                 |                   |    BUG_ON(journal->j_flags & JBD2_UNMOUNT)
```
