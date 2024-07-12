# 问题描述

```sh
EXT4-fs (loop0): mounted filesystem without journal. Opts: ,errors=continue
==================================================================
BUG: KASAN: use-after-free in ext4_search_dir fs/ext4/namei.c:1394 [inline]
BUG: KASAN: use-after-free in search_dirblock fs/ext4/namei.c:1199 [inline]
BUG: KASAN: use-after-free in __ext4_find_entry+0xdca/0x1210 fs/ext4/namei.c:1553
Read of size 1 at addr ffff8881317c3005 by task syz-executor117/2331

CPU: 1 PID: 2331 Comm: syz-executor117 Not tainted 5.10.0+ #1
Hardware name: QEMU Standard PC (i440FX + PIIX, 1996), BIOS rel-1.14.0-0-g155821a1990b-prebuilt.qemu.org 04/01/2014
Call Trace:
 __dump_stack lib/dump_stack.c:83 [inline]
 dump_stack+0x144/0x187 lib/dump_stack.c:124
 print_address_description+0x7d/0x630 mm/kasan/report.c:387
 __kasan_report+0x132/0x190 mm/kasan/report.c:547
 kasan_report+0x47/0x60 mm/kasan/report.c:564
 ext4_search_dir fs/ext4/namei.c:1394 [inline]
 search_dirblock fs/ext4/namei.c:1199 [inline]
 __ext4_find_entry+0xdca/0x1210 fs/ext4/namei.c:1553
 ext4_lookup_entry fs/ext4/namei.c:1622 [inline]
 ext4_lookup+0xb8/0x3a0 fs/ext4/namei.c:1690
 __lookup_hash+0xc5/0x190 fs/namei.c:1451
 do_rmdir+0x19e/0x310 fs/namei.c:3760
 do_syscall_64+0x33/0x40 arch/x86/entry/common.c:46
 entry_SYSCALL_64_after_hwframe+0x44/0xa9
RIP: 0033:0x445e59
Code: 4d c7 fb ff c3 66 2e 0f 1f 84 00 00 00 00 00 66 90 48 89 f8 48 89 f7 48 89 d6 48 89 ca 4d 89 c2 4d 89 c8 4c 8b 4c 24 08 0f 05 <48> 3d 01 f0 ff ff 0f 83 1b c7 fb ff c3 66 2e 0f 1f 84 00 00 00 00
RSP: 002b:00007fff2277fac8 EFLAGS: 00000246 ORIG_RAX: 0000000000000054
RAX: ffffffffffffffda RBX: 0000000000400280 RCX: 0000000000445e59
RDX: 0000000000000000 RSI: 0000000000000000 RDI: 00000000200000c0
RBP: 0000000000000000 R08: 0000000000000000 R09: 0000000000000002
R10: 00007fff2277f990 R11: 0000000000000246 R12: 0000000000000000
R13: 431bde82d7b634db R14: 0000000000000000 R15: 0000000000000000

The buggy address belongs to the page:
page:0000000048cd3304 refcount:0 mapcount:0 mapping:0000000000000000 index:0x1 pfn:0x1317c3
flags: 0x200000000000000()
raw: 0200000000000000 ffffea0004526588 ffffea0004528088 0000000000000000
raw: 0000000000000001 0000000000000000 00000000ffffffff 0000000000000000
page dumped because: kasan: bad access detected

Memory state around the buggy address:
 ffff8881317c2f00: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
 ffff8881317c2f80: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
>ffff8881317c3000: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
                   ^
 ffff8881317c3080: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
 ffff8881317c3100: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
==================================================================
```

# 复现

内核构造补丁:
```sh
From 98cdf4ec2c2bb5fe2ab8654f52c48f906c1829b8 Mon Sep 17 00:00:00 2001
From: ChenXiaoSong <chenxiaosongemail@foxmail.com>
Date: Sun, 1 May 2022 02:35:04 +0800
Subject: [PATCH] reproduce uaf in ext4_search_dir()

Signed-off-by: ChenXiaoSong <chenxiaosongemail@foxmail.com>
---
 fs/ext4/namei.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/fs/ext4/namei.c b/fs/ext4/namei.c
index e37da8d5cd0c..94e022e4ab9c 100644
--- a/fs/ext4/namei.c
+++ b/fs/ext4/namei.c
@@ -1485,6 +1485,7 @@ int ext4_search_dir(struct buffer_head *bh, char *search_buf, int buf_size,
 		if (de_len <= 0)
 			return -1;
 		offset += de_len;
+		printk("%s:%d,search_buf:%px,dlimit:%px,de:%px,rec_len:%d,s_blocksize:%ld,de_len:%d,offset:%d\n", __func__, __LINE__, search_buf, dlimit, de, de->rec_len, dir->i_sb->s_blocksize, de_len, offset);
 		de = (struct ext4_dir_entry_2 *) ((char *) de + de_len);
 	}
 	return 0;
@@ -2076,6 +2077,8 @@ void ext4_insert_dentry(struct inode *dir,
 	ext4_set_de_type(inode->i_sb, de, inode->i_mode);
 	de->name_len = fname_len(fname);
 	memcpy(de->name, fname_name(fname), fname_len(fname));
+	if (strcmp(current->comm, "touch") == 0)
+		de->rec_len = 4071;
 	if (ext4_hash_in_dirent(dir)) {
 		struct dx_hash_info *hinfo = &fname->hinfo;
 
-- 
2.25.1
```

构造:
```sh
mkfs.ext4 -E lazy_itable_init=0,lazy_journal_init=0 -b 4096 -F /dev/sda
mount /dev/sda /mnt
mkdir /mnt/dir
dd if=/dev/zero of=/mnt/dd_file bs=1M count=10240 # 把空间全部填满
rm /mnt/dd_file -rf
touch /mnt/dir/file
rmdir /mnt/dir/dir
```

# 代码分析

修复补丁：[ext4: fix use-after-free in ext4_search_dir](https://lore.kernel.org/all/20220324064816.1209985-1-yebin10@huawei.com/)

```c
// mkdir dir
mkdir
  do_mkdirat
    filename_create
      __lookup_hash
        ext4_lookup
          ext4_lookup_entry
            __ext4_find_entry
              search_dirblock
                ext4_search_dir
    vfs_mkdir
      ext4_mkdir
        ext4_init_new_dir
          ext4_init_dot_dotdot

// rmdir dir
rmdir
  do_rmdir
    vfs_rmdir
      ext4_rmdir
        ext4_find_entry
          __ext4_find_entry
            search_dirblock
              ext4_search_dir
                de = (struct ext4_dir_entry_2 *)search_buf // 第一个目录项的开始地址
                dlimit = search_buf + buf_size // 最后一个目录项的结束地址
                // 注意 EXT4_BASE_DIR_LEN 的值为 9, 考虑到内存对齐
                while ((char *) de < dlimit + EXT4_BASE_DIR_LEN) {
                }

// rm dir -rf
unlinkat
  do_rmdir
    vfs_rmdir
      ext4_rmdir
        ext4_find_entry
          __ext4_find_entry
            search_dirblock
              ext4_search_dir

// 删除文件夹中的文件: rm dir/file
unlinkat
  do_unlinkat
    vfs_unlink
      ext4_unlink
        __ext4_unlink
          ext4_delete_entry
            ext4_generic_delete_entry

// touch dir/file
open
  do_sys_open
    do_sys_openat2
      do_filp_open
        path_openat
          open_last_lookups
            lookup_open
              ext4_create
                ext4_add_nondir
                  ext4_add_entry
                    for (block = 0; block < blocks; block++) {
                    add_dirent_to_buf
                      ext4_insert_dentry
```
