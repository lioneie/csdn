# 问题描述

```sh
[home]# fsck.ext4  -fn  ram0yb
e2fsck 1.45.6 (20-Mar-2020)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Symlink /p3/d14/d1a/l3d (inode #3494) is invalid.
Clear? no
Entry 'l3d' in /p3/d14/d1a (3383) has an incorrect filetype (was 7, should be 0).
Fix? no
```

# 内核构造补丁

```c
From edd845db91cb201343ce26bf4827a08dec213dac Mon Sep 17 00:00:00 2001
From: ChenXiaoSong <chenxiaosongemail@foxmail.com>
Date: Sun, 1 May 2022 18:54:12 +0800
Subject: [PATCH] reproduce symlink file size do not match to file content

Signed-off-by: ChenXiaoSong <chenxiaosongemail@foxmail.com>
---
 block/blk-core.c       | 34 +++++++++++++++++++++++++++++-----
 fs/ext4/ext4.h         |  1 +
 fs/ext4/inode.c        |  8 +++++++-
 fs/ext4/page-io.c      | 18 +++++++++++++++---
 include/linux/bio.h    |  1 +
 include/linux/blkdev.h |  1 +
 6 files changed, 54 insertions(+), 9 deletions(-)

diff --git a/block/blk-core.c b/block/blk-core.c
index 937bb6b86331..40979511c0cf 100644
--- a/block/blk-core.c
+++ b/block/blk-core.c
@@ -771,7 +771,7 @@ void submit_bio_noacct_nocheck(struct bio *bio)
  * systems and other upper level users of the block layer should use
  * submit_bio() instead.
  */
-void submit_bio_noacct(struct bio *bio)
+void origin_submit_bio_noacct(struct bio *bio, char fault)
 {
 	struct block_device *bdev = bio->bi_bdev;
 	struct request_queue *q = bdev_get_queue(bdev);
@@ -791,8 +791,10 @@ void submit_bio_noacct(struct bio *bio)
 	if ((bio->bi_opf & REQ_NOWAIT) && !blk_queue_nowait(q))
 		goto not_supported;
 
-	if (should_fail_bio(bio))
+	if (should_fail_bio(bio) || fault) {
+		printk("%s:%d,inject fault,fault:%d\n", __func__, __LINE__, fault);
 		goto end_io;
+	}
 	if (unlikely(bio_check_ro(bio)))
 		goto end_io;
 	if (!bio_flagged(bio, BIO_REMAPPED)) {
@@ -873,8 +875,19 @@ void submit_bio_noacct(struct bio *bio)
 	bio->bi_status = status;
 	bio_endio(bio);
 }
+
+void submit_bio_noacct(struct bio *bio)
+{
+	origin_submit_bio_noacct(bio, 0);
+}
 EXPORT_SYMBOL(submit_bio_noacct);
 
+void submit_bio_noacct2(struct bio *bio, char fault)
+{
+	origin_submit_bio_noacct(bio, fault);
+}
+EXPORT_SYMBOL(submit_bio_noacct2);
+
 /**
  * submit_bio - submit a bio to the block device layer for I/O
  * @bio: The &struct bio which describes the I/O
@@ -888,7 +901,7 @@ EXPORT_SYMBOL(submit_bio_noacct);
  * in @bio.  The bio must NOT be touched by thecaller until ->bi_end_io() has
  * been called.
  */
-void submit_bio(struct bio *bio)
+void origin_submit_bio(struct bio *bio, char fault)
 {
 	if (blkcg_punt_bio_submit(bio))
 		return;
@@ -919,15 +932,26 @@ void submit_bio(struct bio *bio)
 		unsigned long pflags;
 
 		psi_memstall_enter(&pflags);
-		submit_bio_noacct(bio);
+		submit_bio_noacct2(bio, fault);
 		psi_memstall_leave(&pflags);
 		return;
 	}
 
-	submit_bio_noacct(bio);
+	submit_bio_noacct2(bio, fault);
+}
+
+void submit_bio(struct bio *bio)
+{
+	origin_submit_bio(bio, 0);
 }
 EXPORT_SYMBOL(submit_bio);
 
+void submit_bio2(struct bio *bio, char fault)
+{
+	origin_submit_bio(bio, fault);
+}
+EXPORT_SYMBOL(submit_bio2);
+
 /**
  * bio_poll - poll for BIO completions
  * @bio: bio to poll for
diff --git a/fs/ext4/ext4.h b/fs/ext4/ext4.h
index 3f87cca49f0c..375bf9eefab8 100644
--- a/fs/ext4/ext4.h
+++ b/fs/ext4/ext4.h
@@ -3793,6 +3793,7 @@ extern void ext4_io_submit_init(struct ext4_io_submit *io,
 				struct writeback_control *wbc);
 extern void ext4_end_io_rsv_work(struct work_struct *work);
 extern void ext4_io_submit(struct ext4_io_submit *io);
+extern void ext4_io_submit2(struct ext4_io_submit *io, char fault);
 extern int ext4_bio_write_page(struct ext4_io_submit *io,
 			       struct page *page,
 			       int len,
diff --git a/fs/ext4/inode.c b/fs/ext4/inode.c
index 1ce13f69fbec..0c4c061fc59c 100644
--- a/fs/ext4/inode.c
+++ b/fs/ext4/inode.c
@@ -1979,6 +1979,7 @@ static int ext4_writepage(struct page *page,
 	struct inode *inode = page->mapping->host;
 	struct ext4_io_submit io_submit;
 	bool keep_towrite = false;
+	int fault = 0;
 
 	if (unlikely(ext4_forced_shutdown(EXT4_SB(inode->i_sb)))) {
 		folio_invalidate(folio, 0, folio_size(folio));
@@ -2054,7 +2055,12 @@ static int ext4_writepage(struct page *page,
 		return -ENOMEM;
 	}
 	ret = ext4_bio_write_page(&io_submit, page, len, keep_towrite);
-	ext4_io_submit(&io_submit);
+	if (io_submit.io_bio && page->mapping && page->mapping->host &&
+	    S_ISLNK(page->mapping->host->i_mode)) {
+		printk("%s:%d,inject fault,inode num:%ld\n", __func__, __LINE__, page->mapping->host->i_ino);
+		fault = 1;
+	}
+	ext4_io_submit2(&io_submit, fault);
 	/* Drop io_end reference we got from init */
 	ext4_put_io_end_defer(io_submit.io_end);
 	return ret;
diff --git a/fs/ext4/page-io.c b/fs/ext4/page-io.c
index 495ce59fb4ad..8e1b367ac002 100644
--- a/fs/ext4/page-io.c
+++ b/fs/ext4/page-io.c
@@ -134,8 +134,10 @@ static void ext4_finish_bio(struct bio *bio)
 				continue;
 			}
 			clear_buffer_async_write(bh);
-			if (bio->bi_status)
+			if (bio->bi_status) {
+				// set_buffer_write_io_error(bh);
 				buffer_io_error(bh);
+			}
 		} while ((bh = bh->b_this_page) != head);
 		spin_unlock_irqrestore(&head->b_uptodate_lock, flags);
 		if (!under_io) {
@@ -366,18 +368,28 @@ static void ext4_end_bio(struct bio *bio)
 	}
 }
 
-void ext4_io_submit(struct ext4_io_submit *io)
+void origin_ext4_io_submit(struct ext4_io_submit *io, char fault)
 {
 	struct bio *bio = io->io_bio;
 
 	if (bio) {
 		if (io->io_wbc->sync_mode == WB_SYNC_ALL)
 			io->io_bio->bi_opf |= REQ_SYNC;
-		submit_bio(io->io_bio);
+		submit_bio2(io->io_bio, fault);
 	}
 	io->io_bio = NULL;
 }
 
+void ext4_io_submit(struct ext4_io_submit *io)
+{
+	origin_ext4_io_submit(io, 0);
+}
+
+void ext4_io_submit2(struct ext4_io_submit *io, char fault)
+{
+	origin_ext4_io_submit(io, fault);
+}
+
 void ext4_io_submit_init(struct ext4_io_submit *io,
 			 struct writeback_control *wbc)
 {
diff --git a/include/linux/bio.h b/include/linux/bio.h
index 278cc81cc1e7..e102c4afbf70 100644
--- a/include/linux/bio.h
+++ b/include/linux/bio.h
@@ -424,6 +424,7 @@ static inline struct bio *bio_alloc(struct block_device *bdev,
 }
 
 void submit_bio(struct bio *bio);
+void submit_bio2(struct bio *bio, char fault);
 
 extern void bio_endio(struct bio *);
 
diff --git a/include/linux/blkdev.h b/include/linux/blkdev.h
index 60d016138997..e46f41c3e9a2 100644
--- a/include/linux/blkdev.h
+++ b/include/linux/blkdev.h
@@ -860,6 +860,7 @@ void blk_request_module(dev_t devt);
 extern int blk_register_queue(struct gendisk *disk);
 extern void blk_unregister_queue(struct gendisk *disk);
 void submit_bio_noacct(struct bio *bio);
+void submit_bio_noacct2(struct bio *bio, char fault);
 
 extern int blk_lld_busy(struct request_queue *q);
 extern void blk_queue_split(struct bio **);
-- 
2.25.1
```

# 修复补丁合入之前的现象

修复补丁：[a2b0b205d125 ext4: fix symlink file size not match to file content](https://lore.kernel.org/all/20220321144438.201685-1-yebin10@huawei.com/)

```sh
umount /mnt
mkfs.ext4 -E lazy_itable_init=0,lazy_journal_init=0 -b 4096 -F /dev/sda
mount /dev/sda /mnt
# 路径名大于60个字符
ln -s 1234567890123456789012345678901234567890123456789012345678901234567890 /mnt/link
# ln -s abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz /mnt/link
sync
umount /mnt
# [   30.532593] ext4_writepage:2059,inject fault,inode num:12,fault:0
# [   30.533290] submit_bio_noacct:795,inject fault,fault:88
# [   30.533874] EXT4-fs warning (device sda): ext4_end_bio:341: I/O error 10 writing to inode 12 starting block 1847)
# [   30.534963] Buffer I/O error on device sda, logical block 1847
mount /dev/sda /mnt
ls -lh /mnt # 重新挂载后, symlink 内容错误
# lrwxrwxrwx. 1 root root  78 May  1 19:18 link -> 1234567890123456789012345678901234567890123456789012345678901234567890

# 在物理机上执行
fsck.ext4 -fn 1 # 文件 1 是对应虚拟机中 /dev/sda 的物理机文件
# e2fsck 1.45.5 (07-Jan-2020)
# 1: recovering journal
# Pass 1: Checking inodes, blocks, and sizes
# Pass 2: Checking directory structure
# Pass 3: Checking directory connectivity
# Pass 4: Checking reference counts
# Pass 5: Checking group summary information
# 1: 12/25600 files (8.3% non-contiguous), 1848/25600 blocks
echo $? # 0
debugfs 1
debugfs:  stat <12> # Symlink /link (inode #12) is invalid.
# (0):1847
debugfs:  bd 1847
# 0000  3132 3334 3536 3738 3930 3132 3334 3536  1234567890123456
# 0020  3738 3930 3132 3334 3536 3738 3930 3132  7890123456789012
# 0040  3334 3536 3738 3930 3132 3334 3536 3738  3456789012345678
# 0060  3930 3132 3334 3536 3738 3930 3132 3334  9012345678901234
# 0100  3536 3738 3930 0000 0000 0000 0000 0000  567890..........
# 0120  0000 0000 0000 0000 0000 0000 0000 0000  ................
# *
debugfs:  logdump -S
# Journal features:         journal_64bit
# Journal size:             4096k
# Journal length:           1024
# Journal sequence:         0x00000004
# Journal start:            0
# 
# Journal starts at block 0, transaction 4

# 删除链接文件
fsck.ext4 -fy 1 # 文件 1 是对应虚拟机中 /dev/sda 的物理机文件
# e2fsck 1.45.5 (07-Jan-2020)
# Pass 1: Checking inodes, blocks, and sizes
# Pass 2: Checking directory structure
# Symlink /link (inode #12) is invalid.
# Clear? yes
#
# Pass 3: Checking directory connectivity
# Pass 4: Checking reference counts
# Pass 5: Checking group summary information
#
# 1: ***** FILE SYSTEM WAS MODIFIED *****
# 1: 11/25600 files (9.1% non-contiguous), 1846/25600 blocks
```

# 修复补丁合入之后的现象

修复补丁：[a2b0b205d125 ext4: fix symlink file size not match to file content](https://lore.kernel.org/all/20220321144438.201685-1-yebin10@huawei.com/)

```sh
umount /mnt
mkfs.ext4 -E lazy_itable_init=0,lazy_journal_init=0 -b 4096 -F /dev/sda 
mount /dev/sda /mnt 
ln -s 1234567890123456789012345678901234567890123456789012345678901234567890 /mnt/link
sync
umount /mnt
# [   47.614676] ext4_writepage:2060,inject fault,inode num:12
# [   47.615308] origin_submit_bio_noacct:795,inject fault,fault:1
# [   47.615936] EXT4-fs warning (device sda): ext4_end_bio:343: I/O error 10 writing to inode 12 starting block 1847)
# [   47.617037] Buffer I/O error on device sda, logical block 1847
# [   47.622963] Aborting journal on device sda-8.
# [   47.624524] EXT4-fs error (device sda): ext4_put_super:1221: comm umount: Couldn't clean up the journal
# [   47.627310] EXT4-fs (sda): Remounting filesystem read-only
debugfs:  logdump -S
# Journal features:         journal_64bit
# Journal size:             4096k
# Journal length:           1024
# Journal sequence:         0x00000002
# Journal start:            1
# Journal errno:            -5
#
# Journal starts at block 1, transaction 2
# Found expected sequence 2, type 1 (descriptor block) at block 1
# Found expected sequence 2, type 2 (commit block) at block 10
# No magic number at block 11: end of journal.
```

# 代码流程

修复补丁：[a2b0b205d125 ext4: fix symlink file size not match to file content](https://lore.kernel.org/all/20220321144438.201685-1-yebin10@huawei.com/)

```c
kthread
  worker_thread
    process_one_work
      wb_workfn
        wb_do_writeback
          wb_check_start_all
            wb_writeback
              __writeback_inodes_wb
                writeback_sb_inodes
                  __writeback_single_inode
                    do_writepages
                      ext4_writepages
                        generic_writepages
                          write_cache_pages
                            __writepage
                              ext4_writepage
                                ext4_io_submit
                                  submit_bio
                                    submit_bio_noacct
                                      bio_endio
                                        ext4_end_bio
                                          ext4_finish_bio
                                            if (bio->bi_status) { 
                                            // PAGEFLAG(Dirty, dirty, PF_HEAD)
                                            SetPageError(page)
                                            mapping_set_error(page->mapping, -EIO)
                                            if (bio->bi_status)
                                            // BUFFER_FNS(Write_EIO, write_io_error)
                                            set_buffer_write_io_error // 解决方案
                                            buffer_io_error // fs/ext4/page-io.c
                                              printk_ratelimited(KERN_ERR "Buffer I/O error on device %pg, logical block %llu\n",

task_work_run
  __cleanup_mnt
    cleanup_mnt
      deactivate_super
        deactivate_locked_super
          kill_block_super
            generic_shutdown_super
              evict_inodes
                dispose_list
                  evict
                    ext4_evict_inode
                      truncate_inode_pages_final
                        truncate_inode_pages
                          truncate_inode_pages_range
                            truncate_cleanup_folio
                              folio_invalidate
                                ext4_journalled_invalidate_folio
                                  __ext4_journalled_invalidate_folio
                                    jbd2_journal_invalidate_folio
                                      journal_unmap_buffer
                                        // 如果 jbd2_journal_commit_transaction 没有执行过 set_bit(JBD2_CHECKPOINT_IO_ERROR,就在卸载时执行到这里
                                        __jbd2_journal_remove_checkpoint
                                          if (buffer_write_io_error(bh))
                                          set_bit(JBD2_CHECKPOINT_IO_ERROR, &journal->j_atomic_flags)
              ext4_put_super
                jbd2_journal_destroy
                  jbd2_log_do_checkpoint
                    jbd2_cleanup_journal_tail
                      __jbd2_update_log_tail
                        jbd2_journal_update_sb_log_tail
                          if (test_bit(JBD2_CHECKPOINT_IO_ERROR, &journal->j_atomic_flags)) {
                          jbd2_journal_abort(journal, -EIO)
                ext4_abort(sb, -err, "Couldn't clean up the journal")

kthread
  kjournald2
    jbd2_journal_commit_transaction
      __jbd2_journal_clean_checkpoint_list
        journal_clean_one_cp_list
          __jbd2_journal_remove_checkpoint
            if (buffer_write_io_error(bh))
            set_bit(JBD2_CHECKPOINT_IO_ERROR, &journal->j_atomic_flags)
```
