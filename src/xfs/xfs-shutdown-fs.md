# 问题描述

`dmesg`中报warning，请查看[`dmesg-log.txt`](https://gitee.com/chenxiaosonggitee/tmp/blob/master/xfs/xfs-shutdown-fs/dmesg-log.txt)。其他报`Corruption of in-memory data detected.  Shutting down filesystem`的时刻分别为`8507581.813487, 9013282.995965, 142392.165592, 153722.596734`（复现一次，多次重新挂载触发）。

```sh
cat sos_commands/scsi/lsscsi 
[0:0:15:0]   enclosu SGA      E17202           0002  -          -
[0:2:0:0]    disk    AVAGO    MR9361-8i        4.68  /dev/sda   3600605b00eb200802cf6f6d2bc2a72b7
[0:2:1:0]    disk    AVAGO    MR9361-8i        4.68  /dev/sdb   3600605b00eb200802cf6f6debce27afe

cat sos_commands/block/lsblk
NAME                               MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sdb                                  8:16   0   7.1T  0 disk 
`-sdb1                               8:17   0   7.1T  0 part 
  |-VG_tidb-LV_t0ucccis_k07_data   253:2    0   500G  0 lvm  /paic/t0ucccis/td5520

cat sos_commands/block/lsblk_-f_-a_-l 
NAME                           FSTYPE      FSVER    LABEL UUID                                   FSAVAIL FSUSE% MOUNTPOINT
VG_tidb-LV_t0ucccis_k07_data   xfs                        94a6da2a-a2bb-41a1-bdd7-285c0b58c40a     79.2G    84% /paic/t0ucccis/td5520

xfs_metadump -o /dev/mapper/VG_tidb-LV_t0ucccis_k06_data  故障日志20240308.metadump.metadump
xfs_mdrestore 故障日志20240308.metadump  dm.img
xfs_repair -n dm.img 2>&1 | tee xfs_repair-log.txt
```

# 分析镜像

<!-- 镜像在百度网盘中 xfs-shutdown-fs-image.metadump.zip -->

日志[`xfs_repair-log.txt`](https://gitee.com/chenxiaosonggitee/tmp/blob/master/xfs/xfs-shutdown-fs/xfs_repair-log.txt)中:
```sh
agf_freeblks 3997090, counted 4111777 in ag 0
agf_longest 14556, counted 14846 in ag 0
```

代表AG0中空闲块数量不对。

再解析镜像:
```sh
xfs_db -r dm.img 
xfs_db> agf 0
xfs_db> p
freeblks = 3997090 # AG0中空闲块数量
longest = 14556 # AG0中可用的最长连续空闲块的数量
```

<!--
```sh
xfs_db> sb 0
xfs_db> p
fdblocks = 36891964 # 超级块中存放的所有AG的空闲块总和
```
-->

查看日志:
```sh
xfs_logprint -n dm.img > xfs_logprint-n-log.txt # 不尝试解释日志数据，只解释日志头信息。
xfs_logprint dm.img > xfs_logprint-log.txt # 解释日志数据和日志头信息
```

[xfs_logprint-log.txt](https://gitee.com/chenxiaosonggitee/tmp/blob/master/xfs/xfs-shutdown-fs/xfs_logprint-log.txt)中有如下日志:
```sh
cycle: 230651	version: 2		lsn: 230651,154624	tail_lsn: 230651,147968
length of Log Record: 258048	prev offset: 154112		num ops: 69
uuid: 561a8354-b4e6-4b60-a868-c7d633ec2d8b   format: little endian linux
h_size: 262144
----------------------------------------------------------------------------
Oper (20): tid: 60e70d0f  len: 128  clientid: TRANS  flags: none
AGF Buffer: XAGF  
ver: 1  seq#: 0  len: 8192000  
root BNO: 4065919  CNT: 6109247
level BNO: 2  CNT: 2
1st: 0  last: 5  cnt: 6  freeblks: 4111777  longest: 14846
```

[xfs_logprint-n-log.txt](https://gitee.com/chenxiaosonggitee/tmp/blob/master/xfs/xfs-shutdown-fs/xfs_logprint-n-log.txt)中有如下日志:
```sh
cycle: 230651	version: 2		lsn: 230651,154624	tail_lsn: 230651,147968
length of Log Record: 258048	prev offset: 154112		num ops: 69
uuid: 561a8354-b4e6-4b60-a868-c7d633ec2d8b   format: little endian linux
h_size: 262144
----------------------------------------------------------------------------
Oper (20): tid: 60e70d0f  len: 128  clientid: TRANS  flags: none
0x58 0x41 0x47 0x46 0x00 0x00 0x00 0x01 0x00 0x00 0x00 0x00 0x00 0x7d 0x00 0x00 
0x00 0x3e 0x0a 0x7f 0x00 0x5d 0x38 0x3f 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x02 
0x00 0x00 0x00 0x02 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x05 
0x00 0x00 0x00 0x06 0x00 0x3e 0xbd 0xa1 0x00 0x00 0x39 0xfe 0x00 0x00 0x00 0x04 
0x56 0x1a 0x83 0x54 0xb4 0xe6 0x4b 0x60 0xa8 0x68 0xc7 0xd6 0x33 0xec 0x2d 0x8b 
0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x01 0x00 0x0c 0xee 0xbf 0x00 0x00 0x00 0x01 
0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 
0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 
```

- `0x00~0x03`数据`0x58 0x41 0x47 0x46`是`XAGF`，代表agf数据结构。
- `0x08~0x0b`数据`0x00 0x00 0x00 0x00`代表第0号AG。
- `0x34~0x37`数据`0x00 0x3e 0xbd 0xa1`是十进制`4111777`，代表`agf_freeblks`。
- `0x38~0x3b`数据`0x00 0x00 0x39 0xfe`是十进制`14846`，代表`agf_longest`。

`tail_lsn: 230651,147968`代表包含未提交缓冲区的第一个日志记录的日志序列号，`lsn: 230651,154624`大于`tail_lsn`，暂时不能说明这条记录对应的io完成函数已经被调用。

再看之后的记录:
```sh
cycle: 230651	version: 2		lsn: 230651,253952	tail_lsn: 230651,239616
length of Log Record: 258048	prev offset: 253440		num ops: 71
uuid: 561a8354-b4e6-4b60-a868-c7d633ec2d8b   format: little endian linux
h_size: 262144
```

这条记录的`tail_lsn: 230651,239616`大于前面分析的`lsn: 230651,154624`，说明前面分析的记录对应的io已经完成返回。

再查看AG0最近一次写入的`lsn`:
```sh
xfs_db -r dm.img
xfs_db> agf 0
xfs_db> p
lsn = 0x383dc00078a00
```

`lsn = 0x383dc00078a00 = (0x383dc, 0x00078a00) = (230364, 494080)`


再看之后AGF相关的记录:
```sh
grep -r "0x58 0x41 0x47 0x46 0x00 0x00 0x00 0x01 0x00 0x00 0x00 0x00" xfs_logprint-n-log.txt --line-number
```

<!--
分别在以下各行号的位置，对应的`tail_lsn`分别为:
```sh
48263  lsn: 230650,371712	tail_lsn: 230650,293888
52116  lsn: 230650,386560	tail_lsn: 230650,293888
54569  lsn: 230650,389632	tail_lsn: 230650,293888
69739  lsn: 230650,390656	tail_lsn: 230650,293888
85321  lsn: 230650,414208	tail_lsn: 230650,293888
89628  lsn: 230650,426496	tail_lsn: 230650,425472
98543  lsn: 230650,447488	tail_lsn: 230650,426496
101617 lsn: 230650,460800	tail_lsn: 230650,426496
107632 lsn: 230650,475648	tail_lsn: 230650,426496
109327 lsn: 230650,476672	tail_lsn: 230650,426496
114815 lsn: 230650,480256	tail_lsn: 230650,426496
115618 lsn: 230650,481792	tail_lsn: 230650,426496
119204 lsn: 230650,482816	tail_lsn: 230650,426496
121800 lsn: 230650,488448	tail_lsn: 230650,487424
126108 lsn: 230650,489472	tail_lsn: 230650,487424
134746 lsn: 230650,498688	tail_lsn: 230650,488448
153605 lsn: 230650,509952	tail_lsn: 230650,488448
157287 lsn: 230650,511488	tail_lsn: 230650,488448
205193 lsn: 230651,140288	tail_lsn: 230651,133120
217883 lsn: 230651,147968	tail_lsn: 230651,146944
218254 lsn: 230651,148480	tail_lsn: 230651,146944
222805 lsn: 230651,148992	tail_lsn: 230651,146944
224547 lsn: 230651,149504	tail_lsn: 230651,146944
226171 lsn: 230651,150016	tail_lsn: 230651,147968
227624 lsn: 230651,153088	tail_lsn: 230651,147968
229392 lsn: 230651,154624	tail_lsn: 230651,147968
```
-->

查看AG1的信息:
```sh
xfs_db> agf 1
xfs_db> p 
lsn = 0x384fb00032800
```

`lsn = 0x384fb00032800 = (0x384fb, 0x00032800) = (230651, 206848)`也大于前面分析的`lsn: 230651,154624`。

<!--
# 代码分析

```c
// echo <9000个字节> > /mnt/file
kthread
  worker_thread
    process_scheduled_works
      process_one_work
        wb_workfn
          wb_do_writeback
            wb_check_start_all
              wb_writeback
                __writeback_inodes_wb
                  writeback_sb_inodes
                    __writeback_single_inode
                      do_writepages
                        xfs_vm_writepages
                          iomap_writepages
                            iomap_writepage_map
                              iomap_writepage_map_blocks
                                xfs_map_blocks
                                  xfs_bmapi_convert_delalloc
                                    xfs_bmapi_convert_one_delalloc
                                      xfs_bmapi_allocate
                                        xfs_bmap_alloc_userdata
                                          xfs_bmap_btalloc
```

```c
// echo <9000个字节> > /mnt/file
xfs_bmap_btalloc
  xfs_bmap_btalloc_best_length
    xfs_alloc_vextent_start_ag
      xfs_alloc_vextent_iterate_ags
        xfs_alloc_vextent_prepare_ag
          xfs_alloc_fix_freelist
            xfs_alloc_read_agf
      xfs_alloc_vextent_finish
        xfs_alloc_update_counters(tp=0xffff88810558c828, agbp=0xffff88810210a700, len=-3)

mount
  do_mount
    path_mount
      do_new_mount
        vfs_get_tree
          xfs_fs_get_tree
            get_tree_bdev
              xfs_fs_fill_super
                xfs_mountfs
                  xfs_log_mount
                    xlog_alloc_log
                      // 初始化 l_iclog_bufs 个 xlog_in_core_t
                      INIT_WORK(&iclog->ic_end_io_work, xlog_ioend_work);

// sync 命令
kthread
  worker_thread
    process_scheduled_works
      process_one_work
        xlog_cil_push_work
          xlog_cil_write_chain
            xlog_write
              xlog_write_full
                xlog_write_iovec
              xlog_state_release_iclog

// sync 命令
sync
  ksys_sync
    iterate_supers
      sync_fs_one_sb
        xfs_fs_sync_fs
          xfs_log_force

// 写操作后过一段时间触发
kthread
  worker_thread
    process_scheduled_works
      process_one_work
        xfs_log_worker
          xfs_log_force

xfs_log_force
  xlog_force_and_check_iclog
    xlog_force_iclog
      xlog_state_release_iclog
        xlog_sync
          xlog_write_iclog
            iclog->ic_bio.bi_end_io = xlog_bio_end_io
            submit_bio // 落盘成功后调用到 xlog_bio_end_io

kthread
  smpboot_thread_fn
    run_ksoftirqd
      handle_softirqs
        blk_done_softirq
          blk_complete_reqs
            lo_complete_rq
              blk_mq_end_request
                __blk_mq_end_request
                  flush_end_io
                    blk_flush_complete_seq
                      blk_mq_end_request
                        blk_update_request
                          bio_endio
                            xlog_bio_end_io
                              queue_work(..., &iclog->ic_end_io_work) // 触发 xlog_ioend_work

kthread
  worker_thread
    process_scheduled_works
      process_one_work
        xlog_ioend_work // 由 xlog_bio_end_io 触发
          xlog_state_done_syncing
```
-->

# 构造

打上补丁[`0001-debug-drop-bio.patch`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/xfs/0001-debug-drop-bio.patch)，执行`make`命令（[`Makefile`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/xfs/Makefile)）编译[`debug-drop-bio.c`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/xfs/debug-drop-bio.c)模块，在虚拟机中执行加载模块`insmod ./debug-drop-bio.ko`，再执行`echo somthting > /mnt/file`分配新的块，接着`umount`文件系统，就能得到AGF有问题的镜像。

```sh
echo 1234567890 > file
fallocate -o 15 -l 10M file
```
