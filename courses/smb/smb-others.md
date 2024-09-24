# client流程

正在更新的内容都放到这篇文章中，等到有些知识点达到一定量时，会把这些知识点整理成专门的一章。

请求处理过程:
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

回复处理过程:
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

打开文件处理过程:
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

读文件处理过程:
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

写文件处理过程:
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

# lock

`lock.c`文件如下:
```c
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>

int main() {
    int fd = open("/mnt/file", O_RDWR);
    if (fd == -1) {
        perror("Failed to open file");
        return 1;
    }

    struct flock fl;
    fl.l_type = F_WRLCK;  // 写锁
    fl.l_whence = SEEK_SET;
    fl.l_start = 0;
    fl.l_len = 0;  // 锁定整个文件

    if (fcntl(fd, F_SETLK, &fl) == -1) {
        perror("Failed to lock file");
        close(fd);
        return 1;
    }

    printf("File locked. Press Enter to unlock...");
    getchar();

    fl.l_type = F_UNLCK;  // 解锁
    if (fcntl(fd, F_SETLK, &fl) == -1) {
        perror("Failed to unlock file");
    }

    close(fd);
    return 0;
}
```

`lock.c`文件还可以用`flock()`函数:
```c
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/file.h>

int main(int argc, char *argv[]) {
    const char file_path = "/mnt/file";
    int fd = open(file_path, O_RDWR);
    if (fd == -1) {
        printf("Error: open %s\n", file_path);
        exit(EXIT_FAILURE);
    }
    printf("open succ %s\n", file_path);

    int res = flock(fd, LOCK_SH);
    if (res == -1) {
        printf("Error: flock %s\n", file_path);
        close(fd);
        exit(EXIT_FAILURE);
    }
    printf("lock succ %s\n", file_path);

    printf("File locked. Press Enter to unlock...");
    getchar();

    // Unlock and close the file
    flock(fd, LOCK_UN);
    close(fd);

    return 0;
}
```

```sh
gcc -o lock lock.c
./lock # client 1
./lock # client 2，这时会调用 SMB2_lock， server会调用 smb2_lock
```