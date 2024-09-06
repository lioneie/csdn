4.19 syzkaller报如下错误:
```sh
[  414.798168][  3] blkdev_get: 3 callbacks suppressed
[  414.798185][  3] VFS: Open an write opened block device exclusively loop5 [20044 syz-executor.5].
[  414.810330][  3] Unable to handle kernel paging request at virtual address dfff200000000024
[  414.812720][  3] Mem abort info:
[  414.813715][  3]   ESR = 0x96000004
[  414.814910][  3]   Exception class = DABT (current EL), IL = 32 bits
[  414.816909][  3]   SET = 0, FnV = 0
[  414.818048][  3]   EA = 0, S1PTW = 0
[  414.819222][  3] Data abort info:
[  414.829755][  3]   ISV = 0, ISS = 0x00000004
[  414.832531][  3]   CM = 0, WnR = 0
[  414.833495][  3] [dfff200000000024] address between user and kernel address ranges
[  414.838499][  3] Internal error: Oops: 96000004 [#1] PREEMPT SMP
[  414.841694][  3] Modules linked in:
[  414.842754][  3] Process syz-executor.5 (pid: 20044, stack limit = 0x00000000c1f1725f)
[  414.845233][  3] CPU: 3 PID: 20044 Comm: syz-executor.5 Not tainted 4.19.90-89-00083-g8dde8c6ebf71 #82
[  414.848091][  3] Source Version: 8dde8c6ebf7152c08eb8da53affa99a5bf7777e6
[  414.850247][  3] Hardware name: linux,dummy-virt (DT)
[  414.851834][  3] pstate: 20000005 (nzCv daif -PAN -UAO)
[  414.853508][  3] pc : lbmStartIO+0x164/0x4ac fs/jfs/jfs_logmgr.c:2143
[  414.854859][  3] lr : lbmStartIO+0xfc/0x4ac fs/jfs/jfs_logmgr.c:2142
[  414.856173][  3] sp : ffff80012f2475a0
[  414.857366][  3] x29: ffff80012f2475a0 x28: 1fffe400031b2040 
[  414.859181][  3] x27: 0000000000000000 x26: ffff8000cdd26000 
[  414.860956][  3] x25: 0000000000000000 x24: ffff20001259bd80 
[  414.862701][  3] x23: 0000000000000000 x22: 0000000000000000 
[  414.864220][  3] x21: ffff8000cdd26000 x20: ffff800123a10c00 
[  414.865785][  3] x19: ffff8000c5332100 x18: 0000000000000000 
[  414.867297][  3] x17: 0000000000000000 x16: ffff2000083a4eb0 
[  414.868880][  3] x15: 1ffff00025e48dd4 x14: ffff20000888d8a4 
[  414.870454][  3] x13: ffff200008631078 x12: ffff100018a66430 
[  414.872105][  3] x11: 1ffff00018a6642f x10: ffff100018a6642f 
[  414.873876][  3] x9 : dfff200000000000 x8 : 0000efffe7599bd1 
[  414.875488][  3] x7 : ffff8000c533217f x6 : 0000000000000001 
[  414.877113][  3] x5 : ffff8000d2563a00 x4 : 0000000000000002 
[  414.879038][  3] x3 : ffff2000095f2004 x2 : 0000000000000024 
[  414.880773][  3] x1 : dfff200000000000 x0 : 0000000000000120 
[  414.882328][  3] Call trace:
[  414.883146][  3]  lbmStartIO+0x164/0x4ac fs/jfs/jfs_logmgr.c:2143
[  414.884281][  3]  lbmWrite+0x2c0/0x460 fs/jfs/jfs_logmgr.c:2092
[  414.885411][  3]  lmGCwrite+0x384/0x470 fs/jfs/jfs_logmgr.c:806
[  414.886510][  3]  lmGroupCommit+0x560/0x740 fs/jfs/jfs_logmgr.c:708
[  414.887659][  3]  txCommit+0xa50/0x3e60 fs/jfs/jfs_txnmgr.c:1313
[  414.888823][  3]  jfs_commit_inode+0x254/0x4b0 fs/jfs/inode.c:120
[  414.890226][  3]  jfs_fsync+0x11c/0x21c fs/jfs/file.c:50
[  414.891449][  3]  vfs_fsync_range+0x104/0x1bc fs/sync.c:201
[  414.892833][  3]  generic_write_sync include/linux/fs.h:2907 [inline]
[  414.892833][  3]  generic_file_write_iter+0x4e4/0x6dc mm/filemap.c:3375
[  414.894444][  3]  call_write_iter include/linux/fs.h:1918 [inline]
[  414.894444][  3]  new_sync_write+0x3b4/0x590 fs/read_write.c:475
[  414.895763][  3]  __vfs_write+0xd8/0x11c fs/read_write.c:488
[  414.896874][  3]  vfs_write+0x17c/0x474 fs/read_write.c:574
[  414.897916][  3]  ksys_write+0x100/0x2a0 fs/read_write.c:634
[  414.899033][  3]  __do_sys_write fs/read_write.c:646 [inline]
[  414.899033][  3]  sys_write+0x30/0x40 fs/read_write.c:643
[  414.900081][  3]  __sys_trace_return+0x0/0x4
[  414.901297][  3] Code: d2c40001 f2fbffe1 910482c0 d343fc02 (38e16841) 
[  414.903099][  3] ---[ end trace c60f5a2914e1708a ]---
```

修复补丁: `6306ff39a7fc jfs: fix log->bdev_handle null ptr deref in lbmStartIO`

