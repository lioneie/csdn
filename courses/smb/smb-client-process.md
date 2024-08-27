请求处理过程：
```c
// 请求是struct smb_rqst *rqst->rq_iov, 回复是struct kvec *resp_iov
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
```

回复处理过程：
```c
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

打开文件处理过程：
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

// smb流程
atomic_open
  cifs_atomic_open
    cifs_lookup
      cifs_get_inode_info
        cifs_get_fattr
          smb2_query_path_info
            smb2_compound_op
    cifs_do_create
      smb2_open_file
        SMB2_open
          cifs_send_recv
```

读文件处理过程：
```c
read_pages
  netfs_readahead
    netfs_begin_read
      netfs_rreq_submit_slice
        netfs_read_from_server
          cifs_req_issue_read
            smb2_async_readv
              cifs_call_async
                mid->receive = receive
                mid->callback = callback

kthread
  cifs_demultiplex_thread
    cifs_readv_receive // mids[0]->receive
    smb2_readv_callback // mids[i]->callback
```

写文件处理过程：
```c
do_writepages
  netfs_writepages
    netfs_write_folio
      netfs_advance_write
        netfs_issue_write
          netfs_do_issue_write
            cifs_issue_write
              smb2_async_writev
                cifs_call_async

kthread
  cifs_demultiplex_thread
    smb2_writev_callback // mids[i]->callback
```

挂载:
```c
mount
  do_mount
    path_mount
      do_new_mount
        vfs_parse_fs_string
          vfs_parse_fs_param
            smb3_fs_context_parse_param
        parse_monolithic_mount_data
          smb3_fs_context_parse_monolithic
            while ((key = strsep(&options, ",")) != NULL) {
            vfs_parse_fs_string
              vfs_parse_fs_param
                smb3_fs_context_parse_param
```