# 问题描述

```sh
EXT4-fs error (device loop0): ext4_mb_generate_buddy:1141: group 0, block bitmap and bg descriptor inconsistent: 25 vs 31513 free cls
------------[ cut here ]------------
kernel BUG at fs/ext4/inode.c:2708!
invalid opcode: 0000 [#1] PREEMPT SMP KASAN PTI
CPU: 2 PID: 2147 Comm: rep Not tainted 5.18.0-rc2-next-20220413+ #155
RIP: 0010:ext4_writepages+0x1977/0x1c10
RSP: 0018:ffff88811d3e7880 EFLAGS: 00010246
RAX: 0000000000000000 RBX: 0000000000000001 RCX: ffff88811c098000
RDX: 0000000000000000 RSI: ffff88811c098000 RDI: 0000000000000002
RBP: ffff888128140f50 R08: ffffffffb1ff6387 R09: 0000000000000000
R10: 0000000000000007 R11: ffffed10250281ea R12: 0000000000000001
R13: 00000000000000a4 R14: ffff88811d3e7bb8 R15: ffff888128141028
FS:  00007f443aed9740(0000) GS:ffff8883aef00000(0000) knlGS:0000000000000000
CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
CR2: 0000000020007200 CR3: 000000011c2a4000 CR4: 00000000000006e0
DR0: 0000000000000000 DR1: 0000000000000000 DR2: 0000000000000000
DR3: 0000000000000000 DR6: 00000000fffe0ff0 DR7: 0000000000000400
Call Trace:
 <TASK>
 do_writepages+0x130/0x3a0
 filemap_fdatawrite_wbc+0x83/0xa0
 filemap_flush+0xab/0xe0
 ext4_alloc_da_blocks+0x51/0x120
 __ext4_ioctl+0x1534/0x3210
 __x64_sys_ioctl+0x12c/0x170
 do_syscall_64+0x3b/0x90
```

# 构造

```sh
mkfs.ext4 -O inline_data -b 4096 -F /dev/sda
mount /dev/sda /mnt
echo 1 > /mnt/file # 小文件
# 大文件，60个字符好像不够, 注意是追加 >>, 否则用 > 会删除文件重新创建
echo 123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890 >> /mnt/file
fallocate -l 10M /mnt/file
sync
```

# 代码分析

修复补丁：[ef09ed5d37b8 ext4: fix bug_on in ext4_writepages](https://patchwork.ozlabs.org/project/linux-ext4/patch/20220516122634.1690462-1-yebin10@huawei.com/)

```c
// 创建小文件，再追加大量数据
write
  ksys_write
    vfs_write
      new_sync_write
        call_write_iter
          ext4_file_write_iter
            ext4_buffered_write_iter
              generic_perform_write
                ext4_da_write_begin
                  ext4_da_write_inline_data_begin
                    ext4_da_convert_inline_data_to_extent // 先创建小文件，再追加大量数据, 执行到这里
                      SetPageDirty(page)
                      ext4_clear_inode_state(inode, EXT4_STATE_MAY_INLINE_DATA)

// fallocate命令注入故障
fallocate
  ksys_fallocate
    vfs_fallocate
      ext4_fallocate
        ext4_convert_inline_data
          ext4_convert_inline_data_nolock
            error = ext4_map_blocks
            // 注入故障
            if (strcmp(current->comm, "fallocate") == 0)
            error = -ENOSPC
            goto out_restore
            ext4_restore_inline_data
              ext4_set_inode_state(inode, EXT4_STATE_MAY_INLINE_DATA)

// 回写触发 bug on
kthread
  process_one_work
    wb_workfn
      wb_do_writeback
        wb_check_old_data_flush
          wb_writeback
            __writeback_inodes_wb
              writeback_sb_inodes
                __writeback_single_inode
                  do_writepages
                    ext4_writepages
                      if (ext4_has_inline_data(inode))
                      BUG_ON(ext4_test_inode_state(inode, EXT4_STATE_MAY_INLINE_DATA))
                      ext4_destroy_inline_data
```