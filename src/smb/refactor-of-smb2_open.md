最近调研了ksmbd，打算贡献社区补丁，发现所有的文件系统的函数中排名第二长度（901行, 2803~3705）的是`smb2_open()`（排名第一的是ntfs3的1470行的`log_replay()`，但不熟悉就暂时不瞎参与了），就想着先把这个函数给尝试重构了，也先通过这个函数入手深入了解ksmbd。

# 重构参考

重构技巧可以参考Jason Yan <yanaijie@huawei.com>的ext4重构补丁，`ext4_fill_super()`函数重构前有1093行。

- [[v3,00/16] some refactor of __ext4_fill_super()](https://patchwork.ozlabs.org/project/linux-ext4/cover/20220916141527.1012715-1-yanaijie@huawei.com/)
- [[0/8] some refactor of __ext4_fill_super(), part 2.](https://patchwork.ozlabs.org/project/linux-ext4/cover/20230323140517.1070239-1-yanaijie@huawei.com/)

# 客户端流程

先看一下客户端是怎么请求的，才能更好的知道服务端要处理哪些。

```c
// vfs的流程
openat
  do_sys_open
    do_sys_openat2
      do_filp_open
        path_openat
          open_last_lookups
            lookup_open
              atomic_open

// 请求流程
atomic_open
  cifs_atomic_open
    cifs_do_create
      smb2_open_file
        SMB2_open
          cifs_send_recv
            compound_send_recv
              smb2_setup_request // ses->server->ops->setup_request
                smb2_get_mid_entry
                  smb2_mid_entry_alloc
                  // 加到队列中
                  list_add_tail(&(*mid)->qhead, &server->pending_mid_q);
                // 状态设置成已提交
                midQ[i]->mid_state = MID_REQUEST_SUBMITTED
                smb_send_rqst
                  __smb_send_rqst
                    smb_send_kvec
                wait_for_response
                  // 状态要为已接收，在dequeue_mid()中设置
                  midQ->mid_state != MID_RESPONSE_RECEIVED
                // 回复的内容
                buf = (char *)midQ[i]->resp_buf

// 回复处理过程
kthread
  cifs_demultiplex_thread
    smb2_find_mid // server->ops->find_mid
      __smb2_find_mid
        // 从pending_mid_q链表中找
        list_for_each_entry
    standard_receive3
      cifs_handle_standard
        handle_mid
          dequeue_mid
            // 状态设置成已接收
            mid->mid_state = MID_RESPONSE_RECEIVED
            // 在锁的保护下从链表中删除（可能是pending_mid_q链表也可能是retry_list链表）
            list_del_init(&mid->qhead)
```

# ksmbd流程

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
  req->ImpersonationLevel // 扮演，模仿
  req->CreateOptions // 判断选项是否有效
  req->CreateDisposition // Disposition 性情，气质，脾性
  req->DesiredAccess // 访问权限检查
  req->FileAttributes // 属性
  smb2_find_context_vals // 4次调用，non-durable handle
  ksmbd_override_fsids // 这个还没看懂TODO
  ksmbd_vfs_kern_path_locked // 获取当前文件和父目录的path
  if (stream_name) { // 处理stream name

  dentry_open
    vfs_open
      do_dentry_open
        ext2_file_open // 执行到具体的后端文件系统
```

# 公共头文件`fs/smb/common/smb2status.h`

## `fs/smb/client/smb2status.h`

- [`fs/smb/client/smb2status.h`的修改历史](https://github.com/torvalds/linux/commits/master/fs/smb/client/smb2status.h)
- [`fs/cifs/smb2status.h`的修改历史](https://github.com/torvalds/linux/commits/38c8a9a52082579090e34c033d439ed2cd1a462d/fs/cifs/smb2status.h?browsing_rename_history=true&new_path=fs/smb/client/smb2status.h&original_branch=master)

## `fs/smb/server/smbstatus.h`

- [`fs/smb/server/smbstatus.h`的修改历史](https://github.com/torvalds/linux/commits/master/fs/smb/server/smbstatus.h)
- [`fs/ksmbd/smbstatus.h`的修改历史](https://github.com/torvalds/linux/commits/38c8a9a52082579090e34c033d439ed2cd1a462d/fs/ksmbd/smbstatus.h?browsing_rename_history=true&new_path=fs/smb/server/smbstatus.h&original_branch=master)
- [`fs/cifsd/smbstatus.h`的修改历史](https://github.com/torvalds/linux/commits/1a93084b9a89818aec0ac7b59a5a51f2112bf203/fs/cifsd/smbstatus.h?browsing_rename_history=true&new_path=fs/smb/server/smbstatus.h&original_branch=master)

`e2f34481b24d cifsd: add server-side procedures for SMB3`的`fs/cifsd/smbstatus.h`最新的`fs/smb/server/smbstatus.h`只有以下不同：
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

在vim下，`fs/smb/server/smbstatus.h`先做两组替换`:%s/\t\\\n\t/ /g`和`:%s/ \\\n\t/ /g`，然后再对比两个文件，有以下不同：
```sh
@@ -982,6 +982,8 @@ struct ntstatus {
 #define STATUS_INVALID_TASK_INDEX cpu_to_le32(0xC0000501)
 #define STATUS_THREAD_ALREADY_IN_TASK cpu_to_le32(0xC0000502)
 #define STATUS_CALLBACK_BYPASS cpu_to_le32(0xC0000503)
# 这俩是client端的
+#define STATUS_SERVER_UNAVAILABLE cpu_to_le32(0xC0000466)
+#define STATUS_FILE_NOT_AVAILABLE cpu_to_le32(0xC0000467)
 #define STATUS_PORT_CLOSED cpu_to_le32(0xC0000700)
 #define STATUS_MESSAGE_LOST cpu_to_le32(0xC0000701)
 #define STATUS_INVALID_MESSAGE cpu_to_le32(0xC0000702)
@@ -1767,6 +1769,3 @@ struct ntstatus {
 #define STATUS_IPSEC_INVALID_PACKET cpu_to_le32(0xC0360005)
 #define STATUS_IPSEC_INTEGRITY_CHECK_FAILED cpu_to_le32(0xC0360006)
 #define STATUS_IPSEC_CLEAR_TEXT_DROP cpu_to_le32(0xC0360007)
# 这俩是server端的
-#define STATUS_NO_PREAUTH_INTEGRITY_HASH_OVERLAP cpu_to_le32(0xC05D0000)
-#define STATUS_INVALID_LOCK_RANGE cpu_to_le32(0xC00001a1)
```