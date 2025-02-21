最近调研了ksmbd，打算贡献社区补丁，用[`calc-func-lines.sh`](https://gitee.com/chenxiaosonggitee/blog/blob/master/course/kernel/src/script/calc-func-lines.sh)脚本发现所有的文件系统的函数中排名第二长度（901行, 3714-2810）的是`smb2_open()`（排名第一的是ntfs3的1470行的`log_replay()`，但不熟悉就暂时不瞎参与了），就想着先把这个函数给尝试重构了，也先通过这个函数入手深入了解ksmbd。当然除了这个函数也会尝试做一些其他的重构。

# 重构参考

重构技巧可以参考Jason Yan <yanaijie@huawei.com>的ext4重构补丁集[`some refactor of __ext4_fill_super()`](https://chenxiaosong.com/course/kernel/patch/refactor-of-__ext4_fill_super.html)。

函数参数是结构体请参考`nfs4_run_open_task()`。

# 已经提交到社区的补丁

[`[PATCH] ksmbd: remove duplicate SMB2 Oplock levels definitions`](https://lore.kernel.org/all/20240619161753.385508-1-chenxiaosong@chenxiaosong.com/)

[`[PATCH v2 00/12] smb: fix some bugs, move duplicate definitions to common header file, and some small cleanups`](https://lore.kernel.org/all/20240822082101.391272-1-chenxiaosong@chenxiaosong.com/)

# `smb2_open()`重构

重构补丁还未完成，但发了一些这个函数的bugfix补丁，请查看[`[PATCH v2 00/12] smb: fix some bugs, move duplicate definitions to common header file, and some small cleanups`](https://lore.kernel.org/all/20240822082101.391272-1-chenxiaosong@chenxiaosong.com/)，以及2023年时发过的这个函数的一个bugfix补丁[`624b445544f ksmbd: fix possible refcount leak in smb2_open()`](https://patchwork.kernel.org/project/cifs-client/patch/20230302135804.2583061-1-chenxiaosong2@huawei.com/)。

先整理一下函数流程。`smb2_open()`框架流程:
```c
  ksmbd_override_fsids
  ksmbd_vfs_getattr
  goto reconnected_fp;
  ksmbd_override_fsids
  // 之前是 goto err_out2
  ksmbd_vfs_kern_path_locked
  goto err_out;
  smb2_creat
  ksmbd_vfs_kern_path_unlock
  goto err_out1;
reconnected_fp:
  // 已经重连
err_out:
  ksmbd_vfs_kern_path_unlock
err_out1:
  ksmbd_revert_fsids
err_out2:
  // 最后的错误处理
```

更具体的代码流程:
```c
kthread
  worker_thread
    process_scheduled_works
      process_one_work
        handle_ksmbd_work
          __handle_ksmbd_work
            __process_request
              smb2_open
smb2_open
  WORK_BUFFERS
    // 获取smb2_create_req和smb2_create_rsp
    __wbuf
  smb2_get_name // 获取要打开的文件名
  parse_stream_name // stream name是什么鬼，后面再看TODO
  ksmbd_share_veto_filename // 检查是否禁止访问的文件，veto翻译为禁止或否决
  server_conf.flags & KSMBD_GLOBAL_FLAG_DURABLE_HANDLE // 处理durable handle
  parse_durable_handle_context
    ksmbd_lookup_durable_fd
      __ksmbd_lookup_fd
        ksmbd_fp_get
          atomic_inc_not_zero(&fp->refcount) // 增加引用计数
  smb2_check_durable_oplock
  ksmbd_reopen_durable_fd
    __open_id(&work->sess->file_table, fp, OPEN_ID_TYPE_VOLATILE_ID);
  ksmbd_override_fsids
  ksmbd_put_durable_fd
    __ksmbd_close_fd
      atomic_dec_and_test(&fp->refcount) // 减少引用计数
  ksmbd_fd_put
    atomic_dec_and_test(&fp->refcount) // 减少引用计数
    __put_fd_final
      __ksmbd_close_fd
        ksmbd_remove_durable_fd
          __ksmbd_remove_durable_fd
            idr_remove(global_ft.idr, fp->persistent_id)
        __ksmbd_remove_fd
      atomic_dec(&work->conn->stats.open_files_count)
  req->ImpersonationLevel // 扮演，模仿
  req->CreateOptions // 判断选项是否有效
  req->CreateDisposition // Disposition 性情，气质，脾性
  req->DesiredAccess // 访问权限检查
  req->FileAttributes // 属性
  smb2_find_context_vals // 4次调用，non-durable handle
  ksmbd_override_fsids // 这个还没看懂TODO
  ksmbd_vfs_kern_path_locked // 获取当前文件和父目录的path
  if (stream_name) { // 处理stream name
  CreateOptions & FILE_NON_DIRECTORY_FILE_LE && S_ISDIR // 报错是个文件夹
  CreateOptions & FILE_DIRECTORY_FILE_LE && !S_ISDIR // 报错不是文件夹
  file_present && CreateDisposition == FILE_CREATE_LE // 报错已存在
  smb_map_generic_desired_access // 访问权限处理
  smb_check_perm_dacl // 检查访问权限
  ksmbd_vfs_query_maximal_access // 请求最大访问权限
  smb2_create_open_flags // 生成open flag
  // 文件不存在
  smb2_creat // 创建
  smb2_set_ea // Extended Attributes
  // 文件存在且未请求最大访问权限，处理访问权限
  inode_permission // 分别检查文件和父目录的访问权限
  // 此时文件肯定存在了
  ksmbd_query_inode_status // 获取inode状态
  dentry_open
    vfs_open
      do_dentry_open
        ext2_file_open // 执行到具体的后端文件系统
  file_info // 处理Create Action Flags
  ksmbd_vfs_set_fadvise // 将 SMB IO 缓存选项转换为 Linux 选项
  ksmbd_open_fd // ksmbd_file, Volatile-ID
    __open_id(&work->sess->file_table, fp, OPEN_ID_TYPE_VOLATILE_ID);
    atomic_inc(&work->conn->stats.open_files_count)
  ksmbd_open_durable_fd // Persistent-ID
  // 开始，如果创建新文件，则设置默认的 Windows 和 POSIX ACL
  ksmbd_vfs_inherit_posix_acl // 继承
  smb_inherit_dacl // TODO
  smb2_create_sd_buffer // security descriptor
  ksmbd_vfs_set_init_posix_acl
  ksmbd_acls_fattr // 获取cf_acls和cf_dacls
  build_sec_desc // 将权限位从模式转换为等效的 CIFS ACL
  ksmbd_vfs_set_sd_xattr // 设置security descriptor扩展属性
  // 结束，如果创建新文件，则设置默认的 Windows 和 POSIX ACL
  smb2_set_stream_name_xattr // stream name扩展属性
  // 在 daccess、saccess、attrib_only 和 stream 初始化后，能够通过 ksmbd_inode.m_fp_list 搜索到 fp
  list_add(&fp->node, &fp->f_ci->m_fp_list);
  ksmbd_inode_pending_delete // 在 oplock 断裂前，检查之前的 fp 中是否有删除待处理
  smb_break_all_oplock // 断开批处理/独占 oplock 和二级 oplock
  ksmbd_smb_check_shared_mode // 检查shared mode
  smb_send_parent_lease_break_noti // 使用parent key比较parent lease。如果没有具有相同parent lease，发送lease断裂通知
  smb_grant_oplock // 在文件打开时处理 Oplock/Lease 请求
  ksmbd_fd_set_delete_on_close // 关闭时自动删除
  smb2_create_truncate
  smb2_find_context_vals // 在打开请求中查找特定的上下文信息
  smb_break_all_levII_oplock // 发送 Level 2 Oplock 或 Read Lease 断裂命令
  vfs_fallocate
  ksmbd_vfs_getattr
  opinfo && opinfo->is_lease // 如果请求了租约，则发送租约上下文响应
```

# 公共头文件`fs/smb/common/smb2status.h`

具体的补丁请查看[`[PATCH v2 00/12] smb: fix some bugs, move duplicate definitions to common header file, and some small cleanups`](https://lore.kernel.org/all/20240822082101.391272-1-chenxiaosong@chenxiaosong.com/)。

## `fs/smb/client/smb2status.h`

- [`fs/smb/client/smb2status.h`的修改历史](https://github.com/torvalds/linux/commits/master/fs/smb/client/smb2status.h)
- [`fs/cifs/smb2status.h`的修改历史](https://github.com/torvalds/linux/commits/38c8a9a52082579090e34c033d439ed2cd1a462d/fs/cifs/smb2status.h?browsing_rename_history=true&new_path=fs/smb/client/smb2status.h&original_branch=master)

## `fs/smb/server/smbstatus.h`

- [`fs/smb/server/smbstatus.h`的修改历史](https://github.com/torvalds/linux/commits/master/fs/smb/server/smbstatus.h)
- [`fs/ksmbd/smbstatus.h`的修改历史](https://github.com/torvalds/linux/commits/38c8a9a52082579090e34c033d439ed2cd1a462d/fs/ksmbd/smbstatus.h?browsing_rename_history=true&new_path=fs/smb/server/smbstatus.h&original_branch=master)
- [`fs/cifsd/smbstatus.h`的修改历史](https://github.com/torvalds/linux/commits/1a93084b9a89818aec0ac7b59a5a51f2112bf203/fs/cifsd/smbstatus.h?browsing_rename_history=true&new_path=fs/smb/server/smbstatus.h&original_branch=master)

`e2f34481b24d cifsd: add server-side procedures for SMB3`的`fs/cifsd/smbstatus.h`和最新的`fs/smb/server/smbstatus.h`只有以下不同:
```sh
@@ -1,6 +1,6 @@
 /* SPDX-License-Identifier: LGPL-2.1+ */
 /*
- *   fs/server/smb2status.h
+ *   fs/cifs/smb2status.h
  *
  *   SMB2 Status code (network error) definitions
  *   Definitions are from MS-ERREF
```

## 最新代码对比

在vim下，`fs/smb/server/smbstatus.h`先做两组替换`:%s/\t\\\n\t/ /g`和`:%s/ \\\n\t/ /g`，然后再和`fs/smb/client/smb2status.h`对比，有以下不同:
```sh
# 这俩是client端的
+#define STATUS_SERVER_UNAVAILABLE cpu_to_le32(0xC0000466)
+#define STATUS_FILE_NOT_AVAILABLE cpu_to_le32(0xC0000467)
# 这俩是server端的
-#define STATUS_NO_PREAUTH_INTEGRITY_HASH_OVERLAP cpu_to_le32(0xC05D0000)
-#define STATUS_INVALID_LOCK_RANGE cpu_to_le32(0xC00001a1)
```

# 公共头文件`fs/smb/common/smbacl.h`

具体的补丁请查看[`[PATCH v2 00/12] smb: fix some bugs, move duplicate definitions to common header file, and some small cleanups`](https://lore.kernel.org/all/20240822082101.391272-1-chenxiaosong@chenxiaosong.com/)。

执行以下替换:
```sh
find fs/smb/client -type f -exec sed -i 's/struct cifs_ntsd/struct smb_ntsd/g' {} +
find fs/smb/client -type f -exec sed -i 's/struct cifs_sid/struct smb_sid/g' {} +
find fs/smb/client -type f -exec sed -i 's/struct cifs_acl/struct smb_acl/g' {} +
find fs/smb/client -type f -exec sed -i 's/struct cifs_ace/struct smb_ace/g' {} +
```

再把重复的宏定义移动到公共头文件。

# `smb2_compound_op()`重构

这个函数有12个参数，649行（827-177），必须重构了他。

```c
/*
 * 注意: 如果传递了 cfile，这里会释放对它的引用。所以请确保在从此函数返回后不要再次使用 cfile。
 * 如果传递了 @out_iov 和 @out_buftype，请确保它们都足够大（>= 3）以容纳所有复合响应。调用方也负责使用 free_rsp_buf() 来释放它们。
 */
smb2_compound_op
```

# `smb2_lock()`重构

这个函数也挺长挺复杂，有353行（7535-7181）。
