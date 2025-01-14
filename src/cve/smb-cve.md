# `CVE-2024-50047 b0abcd65ec54 smb: client: fix UAF in async decryption`。

[openeuler的issue](https://gitee.com/src-openeuler/kernel/issues/IAYRE5)。

[CVE-2024-50047 的修复导致出现Oops 复位](https://gitee.com/openeuler/kernel/issues/IBC88Z?skip_mobile=true)

# `CVE-2024-50106 8dd91e8d31fe nfsd: fix race between laundromat and free_stateid`

[openeuler issue](https://gitee.com/src-openeuler/kernel/issues/IB2BX2)

# `CVE-2024-53095 ef7134c7fc48 smb: client: Fix use-after-free of network namespace.`

[openeuler issue](https://gitee.com/src-openeuler/kernel/issues/IB67YB)

[openeuler 4.19 补丁](https://gitee.com/openeuler/kernel/pulls/14249)

还有后续修复补丁`e9f2517a3e18 smb: client: fix TCP timers deadlock after rmmod`。

```
最近，我们收到客户报告称，在重新连接到服务器时，通用Internet文件系统（CIFS）触发了oops（内核错误）。[0]

该工作负载运行在Kubernetes上，部分Pods在非根网络命名空间中挂载CIFS服务器。虽然这个问题很少发生，但每次发生时都是在Pod即将终止的过程中。

根本原因是网络命名空间引用计数错误。

CIFS使用内核套接字，而这些套接字并不持有它们所属网络命名空间的引用计数。这意味着CIFS必须确保套接字始终在网络命名空间被释放之前被释放；否则，就会发生“使用已释放内存”的错误。

重现问题的步骤大致如下：

在非根网络命名空间中挂载CIFS。
丢弃该网络命名空间中的数据包。
销毁网络命名空间。
卸载CIFS。

使用下面的脚本[1]，我们可以快速重现该问题，如果启用了CONFIG_NET_NS_REFCNT_TRACKER配置选项，还可以看到错误提示[2]。

当套接字是TCP类型时，由于存在异步定时器，很难在不持有引用计数的情况下保证网络命名空间的生命周期。

让我们像在处理提交 9744d2bf1976（"smc: 修复tcp_write_timer_handler()中的使用已释放内存错误。"）中的SMC时那样，为每个套接字持有网络命名空间的引用计数。

注意，我们需要将put_net()从cifs_put_tcp_session()中移动到clean_demultiplex_info()；否则，在cifsd尝试从cifs_demultiplex_thread()重新连接时，__sock_create()仍可能访问已被释放的网络命名空间。

此外，不能在__sock_create()之前直接放置maybe_get_net()，因为该代码不在RCU保护之下，存在很小的可能性是，相同的地址可能被重新分配给另一个网络命名空间。
```

# `CVE-2024-49988 ee426bfb9d09 ksmbd: add refcnt to ksmbd_conn struct`

```
ksmbd：在 ksmbd_conn 结构体中添加引用计数

在发送 oplock 中断请求时，使用了 opinfo->conn，但是在多通道环境下，已经释放的 ->conn 可能会被使用。这个补丁在 ksmbd_conn 结构体中添加了引用计数，以确保只有在不再使用时，ksmbd_conn 结构体才能被释放。
```

[openeuler issue](https://gitee.com/src-openeuler/kernel/issues/IAYRCR)

# `CVE-2024-26952 c6cd2e8d2d9a ksmbd: fix potencial out-of-bounds when buffer offset is invalid`

引入问题的补丁: `0626e6641f6b cifsd: add server handler for central processing and tranport layers`。

[openeuler issue](https://gitee.com/src-openeuler/kernel/issues/I9L5L1)

# `CVE-2024-26954 a80a486d72e2 ksmbd: fix slab-out-of-bounds in smb_strndup_from_utf16()`

引入问题的补丁: `0626e6641f6b cifsd: add server handler for central processing and tranport layers`。

[openeuler issue](https://gitee.com/src-openeuler/kernel/issues/I9L5E3)

# `CVE-2024-26936 17cf0c2794bd ksmbd: validate request buffer size in smb2_allocate_rsp_buf()`

[openeuler issue](https://gitee.com/src-openeuler/kernel/issues/I9L4XI)

```
ksmbd：在 smb2_allocate_rsp_buf() 中验证请求缓冲区大小

响应缓冲区应该在 smb2_allocate_rsp_buf 中分配，随后再验证请求。然而，smb2_allocate_rsp_buf() 中使用了有效负载中的字段以及 smb2 头部的内容。这个补丁在 smb2_allocate_rsp_buf() 中添加了简单的缓冲区大小验证，以避免潜在的请求缓冲区越界问题。
```

# `CVE-2023-52442 3df0411e132e ksmbd: validate session id and tree id in compound request`

[openeuler issue](https://gitee.com/src-openeuler/kernel/issues/I92OR4)

# `CVE-2024-39468 02c418774f76 smb: client: fix deadlock in smb2_find_smb_tcon()`

因为主线代码文件夹经过了重命名`38c8a9a52082 smb: move client and server files to common directory fs/smb`，老版本要打上这个补丁，必须将`.patch`文件中的`smb/client`改成`cifs`:
```sh
sed -i 's/smb\/client/cifs/g' 0001-smb-client-fix-deadlock-in-smb2_find_smb_tcon.patch
```

[openeuler issue](https://gitee.com/src-openeuler/kernel/issues/IA8AFZ)。

在4.19和5.4代码中，`smb2_find_smb_tcon()`函数中未对`smb2_find_smb_sess_tcon_unlocked()`的结果进行错误处理，没有相关逻辑，不影响。

# [`CVE-2024-0565 eec04ea11969 smb: client: fix OOB in receive_encrypted_standard()`](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=eec04ea119691e65227a97ce53c0da6b9b74b0b7)

[openeuler issue](https://gitee.com/src-openeuler/kernel/issues/I8WEOK)

## 4.19合补丁

因为主线代码文件夹经过了重命名`38c8a9a52082 smb: move client and server files to common directory fs/smb`，4.19要打上这个补丁，必须将`.patch`文件中的`smb/client`改成`cifs`:
```sh
sed -i 's/smb\/client/cifs/g' 0001-smb-client-fix-OOB-in-receive_encrypted_standard.patch
```

使用`git am 0001-smb-client-fix-OOB-in-receive_encrypted_standard.patch --reject`命令打上补丁后，会有冲突，不同的地方是:
```sh
--- a/fs/cifs/smb2ops.c
+++ b/fs/cifs/smb2ops.c
@@ -3218,7 +3218,7 @@ receive_encrypted_standard(struct TCP_Server_Info *server,
 {
        int ret, length;
        char *buf = server->smallbuf;
-       struct smb2_sync_hdr *shdr;
+       struct smb2_hdr *shdr;
        unsigned int pdu_length = server->pdu_size;
        unsigned int buf_size;
        struct mid_q_entry *mid_entry;
@@ -3248,7 +3248,7 @@ receive_encrypted_standard(struct TCP_Server_Info *server,
 
        next_is_large = server->large_buf;
 one_more:
-       shdr = (struct smb2_sync_hdr *)buf;
+       shdr = (struct smb2_hdr *)buf;
        if (shdr->NextCommand) {
                if (next_is_large)
                        next_buffer = (char *)cifs_buf_get();
```

在主线代码上使用`git blame fs/smb/client/smb2ops.c | grep "struct smb2_hdr \*shdr"`找到前置补丁`0d35e382e4e9 cifs: Create a new shared file holding smb2 pdu definitions`才能解决冲突，但此前置补丁与我们修改的内容无关，所以只需要手动处理冲突即可。

# `CVE-2023-6606 b35858b3786d smb: client: fix OOB in smbCalcSize()`

[openeuler issue](https://gitee.com/src-openeuler/kernel/issues/I8MXXW)

因为主线代码文件夹经过了重命名`38c8a9a52082 smb: move client and server files to common directory fs/smb`，低版本要打上这个修复补丁，必须将`.patch`文件中的`smb/client`改成`cifs`:
```sh
sed -i 's/smb\/client/cifs/g' 0001-smb-client-fix-OOB-in-smbCalcSize.patch
```

此补丁修复`checkSMB()->smbCalcSize()`中访问越界的问题。

# `CVE-2023-52757 e6322fd177c6 smb: client: fix potential deadlock when releasing mids`

[openeuler issue](https://gitee.com/src-openeuler/kernel/issues/I9R4KS)。

[openeuler 5.10补丁](https://gitee.com/openeuler/kernel/pulls/9825)。

```
smb: 客户端: 修复释放 mids 时的潜在死锁

所有 release_mid() 的调用者似乎都持有 @mid 的引用，因此在 @server->mid_lock 自旋锁下调用 kref_put(&mid->refcount, __release_mid) 并不是必要的。如果它们没有持有引用，那么本来就会发生 use-after-free 错误。

通过去掉这个自旋锁，也修复了潜在的死锁问题，如下所示：

CPU 0                                CPU 1
------------------------------------------------------------------
cifs_demultiplex_thread()            cifs_debug_data_proc_show()
 release_mid()
  spin_lock(&server->mid_lock);
                                     spin_lock(&cifs_tcp_ses_lock)
                                      spin_lock(&server->mid_lock)
  __release_mid()
   smb2_find_smb_tcon()
    spin_lock(&cifs_tcp_ses_lock) *死锁*
```

因为主线代码文件夹经过了重命名`38c8a9a52082 smb: move client and server files to common directory fs/smb`，4.19要打上这个补丁，必须将`.patch`文件中的`smb/client`改成`cifs`:
```sh
sed -i 's/smb\/client/cifs/g' 0001-smb-client-fix-potential-deadlock-when-releasing-mid.patch
```

`git checkout 72bc63f5e23a38b65ff2a201bdc11401d4223fa9`回退到之前的记录，`git blame fs/smb/client/cifsproto.h | grep release_mid`找到`70f08f914a37a`，这个commit只是把`cifs_mid_q_entry_release()`重命名成`release_mid()`。

```sh
# fs/cifs/transport.c
-void cifs_mid_q_entry_release(struct mid_q_entry *midEntry)
+void release_mid(struct mid_q_entry *mid)
 {
-       struct TCP_Server_Info *server = midEntry->server;
+       struct TCP_Server_Info *server = mid->server;

        spin_lock(&server->mid_lock);
-       kref_put(&midEntry->refcount, _cifs_mid_q_entry_release);
+       kref_put(&mid->refcount, __release_mid);
        spin_unlock(&server->mid_lock);
 }
```

# [`CVE-2023-6610 567320c46a60a3c39b69aa1df802d753817a3f86 smb: client: fix potential OOB in smb2_dump_detail()`](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=567320c46a60a3c39b69aa1df802d753817a3f86)

[openeuler issue](https://gitee.com/src-openeuler/kernel/issues/I8MXXY)

因为主线代码文件夹经过了重命名`38c8a9a52082 smb: move client and server files to common directory fs/smb`，低版本要打上这个补丁，必须将`.patch`文件中的`smb/client`改成`cifs`:
```sh
sed -i 's/smb\/client/cifs/g' 0001-smb-client-fix-potential-OOB-in-smb2_dump_detail.patch
```

此修复补丁修复`smb2_dump_detail()->calc_smb_size()`的越界问题，调用`calc_smb_size()`之前要先用`check_message()`校验。

## 4.19合补丁

使用`git am 0001-smb-client-fix-potential-OOB-in-smb2_dump_detail.patch --reject`命令打上补丁后，会有冲突，不同的地方是:
```sh
diff --git a/fs/cifs/smb2misc.c b/fs/cifs/smb2misc.c
index 39ae3baa52a3..790e2e932e68 100644
--- a/fs/cifs/smb2misc.c
+++ b/fs/cifs/smb2misc.c
@@ -204,20 +204,20 @@ smb2_check_message(char *buf, unsigned int len, struct TCP_Server_Info *srvr)
                return 1;
 
        if (shdr->StructureSize != SMB2_HEADER_STRUCTURE_SIZE) {
-               cifs_dbg(VFS, "Illegal structure size %u\n",
+               cifs_dbg(VFS, "Invalid structure size %u\n",
                         le16_to_cpu(shdr->StructureSize));
                return 1;
        }
 
        command = le16_to_cpu(shdr->Command);
        if (command >= NUMBER_OF_SMB2_COMMANDS) {
-               cifs_dbg(VFS, "Illegal SMB2 command %d\n", command);
+               cifs_dbg(VFS, "Invalid SMB2 command %d\n", command);
                return 1;
        }
 
        if (smb2_rsp_struct_sizes[command] != pdu->StructureSize2) {
                if (command != SMB2_OPLOCK_BREAK_HE && (shdr->Status == 0 ||
-                   pdu->StructureSize2 != SMB2_ERROR_STRUCTURE_SIZE2)) {
+                   pdu->StructureSize2 != SMB2_ERROR_STRUCTURE_SIZE2_LE)) {
                        /* error packets have 9 byte structure size */
                        cifs_dbg(VFS, "Illegal response size %u for command %d\n",
                                 le16_to_cpu(pdu->StructureSize2), command);
diff --git a/fs/cifs/smb2ops.c b/fs/cifs/smb2ops.c
index 813d67b4a1a5..9f2c0733a4ae 100644
--- a/fs/cifs/smb2ops.c
+++ b/fs/cifs/smb2ops.c
@@ -245,9 +245,9 @@ smb2_dump_detail(void *buf, struct TCP_Server_Info *server)
 #ifdef CONFIG_CIFS_DEBUG2
        struct smb2_sync_hdr *shdr = (struct smb2_sync_hdr *)buf;
 
-       cifs_dbg(VFS, "Cmd: %d Err: 0x%x Flags: 0x%x Mid: %llu Pid: %d\n",
+       cifs_server_dbg(VFS, "Cmd: %d Err: 0x%x Flags: 0x%x Mid: %llu Pid: %d\n",
                 shdr->Command, shdr->Status, shdr->Flags, shdr->MessageId,
-                shdr->ProcessId);
+                shdr->Id.SyncId.ProcessId);
        cifs_dbg(VFS, "smb buf %p len %u\n", buf,
                 server->ops->calc_smb_size(buf, server));
 #endif
```

先看`fs/cifs/smb2ops.c`文件的冲突，在主线代码上使用`git blame fs/smb/client/smb2ops.c | grep "cifs_server_dbg"`找到前置补丁`3175eb9b577e cifs: add a debug macro that prints \\server\share for errors`，打上这个前置补丁有很多的冲突，而这里只是涉及到打印相关的，所以不合入此前置补丁，手动处理冲突。再使用`git blame fs/smb/client/smb2ops.c | grep "Id.SyncId.ProcessId"`找到前置补丁`0d35e382e4e9 cifs: Create a new shared file holding smb2 pdu definitions`，打上这个前置补丁也会有很多的冲突，也不涉及cve的修复内容，所以不合入这个前置补丁，也手动处理冲突。

再看`fs/cifs/smb2misc.c`文件的冲突，在主线代码上使用`git blame fs/smb/client/smb2misc.c | grep SMB2_ERROR_STRUCTURE_SIZE2_LE`找到前置补丁`113be37d8744 [smb3] move more common protocol header definitions to smbfs_common`，打上这个前置补丁会有很多冲突，也不涉及cve的修复内容，所以不合入此前置补丁，手动处理冲突。再切换到cve修复补丁的前一个commit，`git checkout aa3e193d66db56b3331142509acb4b5bad4e7f4f && git blame fs/smb/client/smb2misc.c | grep Invalid SMB2 command`找到前置补丁`a0a3036b81f1 cifs: Standardize logging output`，打上这个前置补丁有很多冲突，只涉及打印相关的，所以不合入这个前置补丁，手动处理冲突。

## 4.4合补丁

前置补丁有:

- `93012bf98416 cifs: add server->vals->header_preamble_size`: `9ec672bd1713`的前置补丁，用`header_preamble_size`变量取代常数4
- `c0953f2ed510 cifs: smb2pdu: Fix potential NULL pointer dereference`: 修复`93012bf98416`导致的空指针解引用
- `14547f7d74c4 cifs: add server argument to the dump_detail method`: 给函数`smb2_dump_detail()`增加一个参数
- `9ec672bd1713 cifs: update calc_size to take a server argument`: 给`calc_size()`相关的函数增加一个参数，另外用`heder_preamble_size`变量取代常数4
- `71992e62b864 cifs: fix build break when CONFIG_CIFS_DEBUG2 enabled`: 修复编译错误, `dump_detail()`和`calc_smb_size()`增加参数，要把`CONFIG_CIFS_DEBUG2`配置打开测试才会出现，麒麟的配置默认不打开

# `CVE-2023-52434 af1689a9b770 smb: client: fix potential OOBs in smb2_parse_contexts()`

[openeuler issue](https://gitee.com/src-openeuler/kernel/issues/I92HX8)

在`smb2_parse_contexts()`中解引用create contexts时如果没有判断offsets和lengths的有效性，会发生访问越界。

## 4.19合补丁

因为主线代码文件夹经过了重命名`38c8a9a52082 smb: move client and server files to common directory fs/smb`，4.19要打上这个补丁，必须将`.patch`文件中的`smb/client`改成`cifs`:
```sh
sed -i 's/smb\/client/cifs/g' 0001-smb-client-fix-potential-OOBs-in-smb2_parse_contexts.patch
```

打上前置补丁`89a5bfa350fa smb3: optimize open to not send query file internal info`后有冲突，还需要再合入前置补丁`b0f6df737a1c cifs: cache FILE_ALL_INFO for the shared root handle`。


# `CVE-2024-35866 58acd1f49716 smb: client: fix potential UAF in cifs_dump_full_key()`

[openeuler](https://www.openeuler.org/en/security/cve/detail/?cveId=CVE-2024-35866&packageName=kernel)

`git blame fs/smb/client/ioctl.c | grep "cifs_dump_full_key"`找引入`cifs_dump_full_key()`函数的补丁，找到`1bb56810677f2`（还不是最终的引入补丁），`checkout`到之前的`eb0688180549e3b72464e9f78df58cb7a5592c7f`，再执行`git blame fs/cifs/ioctl.c | grep "cifs_dump_full_key"`，找到`7ba3d1cdb7988ccfbc6e4995dee04510c85fefbc smb3.1.1: allow dumping keys for multiuser mounts`，就是最终的引入问题的补丁。

# `CVE-2024-35861 e0e50401cc39 smb: client: fix potential UAF in cifs_signal_cifsd_for_reconnect()`

[openeuler](https://www.openeuler.org/en/security/cve/detail/?cveId=CVE-2024-35861&packageName=kernel)

## 4.19合补丁

因为主线代码文件夹经过了重命名`38c8a9a52082 smb: move client and server files to common directory fs/smb`，4.19要打上这个补丁，必须将`.patch`文件中的`smb/client`改成`cifs`:
```sh
sed -i 's/smb\/client/cifs/g' 0001-smb-client-fix-potential-UAF-in-cifs_signal_cifsd_fo.patch
```

引入问题的补丁: `dca65818c80c cifs: use a different reconnect helper for non-cifsd threads`。

# `CVE-2024-35868 d3da25c5ac84 smb: client: fix potential UAF in cifs_stats_proc_write()`

[openeuler](https://www.openeuler.org/en/security/cve/detail/?cveId=CVE-2024-35868&packageName=kernel)

因为主线代码文件夹经过了重命名`38c8a9a52082 smb: move client and server files to common directory fs/smb`，4.19要打上这个补丁，必须将`.patch`文件中的`smb/client`改成`cifs`:
```sh
sed -i 's/smb\/client/cifs/g' 0001-smb-client-fix-potential-UAF-in-cifs_stats_proc_writ.patch
```

参考`d328c09ee9f1 smb: client: fix use-after-free bug in cifs_debug_data_proc_show()`

# `CVE-2024-35863 69ccf040acdd smb: client: fix potential UAF in is_valid_oplock_break()`

[openeuler](https://www.openeuler.org/en/security/cve/detail/?cveId=CVE-2024-35863&packageName=kernel)

因为主线代码文件夹经过了重命名`38c8a9a52082 smb: move client and server files to common directory fs/smb`，4.19要打上这个补丁，必须将`.patch`文件中的`smb/client`改成`cifs`:
```sh
sed -i 's/smb\/client/cifs/g' 0001-smb-client-fix-potential-UAF-in-is_valid_oplock_brea.patch
```

`cifs_ses_exiting()`函数引入的补丁是`ca545b7f0823 smb: client: fix potential UAF in cifs_debug_files_proc_show()`，此补丁还有前置补丁`d7d7a66aacd6 cifs: avoid use of global locks for high contention data`（引入`struct cifs_ses`中的`spinlock_t ses_lock`）。

找引入`is_valid_oplock_break()`函数的补丁，`git blame fs/smb/client/misc.c | grep is_valid_oplock_break`找到`d4e4854fd1c85`，还不是引入补丁，再`git checkout 792af7b05b8a78def080ec757a4d4420b9fd0cc2`到之前的记录，再使用`git blame fs/cifs/misc.c | grep is_valid_oplock_break`找到`d7c8c94d3e4c1`，还不是引入补丁，`git checkout 083d3a2cff514c5301f3a043642940d4d5371b22`到之前的记录，`git blame fs/cifs/misc.c | grep is_valid_oplock_break`找到最早的commit `1da177e4c3f41524e886b7f1b8a0c1fc7321cac2`，就是引入问题的补丁。

按如下修改，参考`d328c09ee9f1 smb: client: fix use-after-free bug in cifs_debug_data_proc_show()`:
```c
diff --git a/fs/cifs/misc.c b/fs/cifs/misc.c
index 00e99a4ea023..6d54c0117c73 100644
--- a/fs/cifs/misc.c
+++ b/fs/cifs/misc.c
@@ -468,6 +468,8 @@ is_valid_oplock_break(char *buffer, struct TCP_Server_Info *srv)
        spin_lock(&cifs_tcp_ses_lock);
        list_for_each(tmp, &srv->smb_ses_list) {
                ses = list_entry(tmp, struct cifs_ses, smb_ses_list);
+               if (ses->status == CifsExiting)
+                       continue;
                list_for_each(tmp1, &ses->tcon_list) {
                        tcon = list_entry(tmp1, struct cifs_tcon, tcon_list);
                        if (tcon->tid != buf->Tid)
```

# `CVE-2024-35865 22863485a462 smb: client: fix potential UAF in smb2_is_valid_oplock_break()`

[openeuler](https://www.openeuler.org/en/security/cve/detail/?cveId=CVE-2024-35865&packageName=kernel)

因为主线代码文件夹经过了重命名`38c8a9a52082 smb: move client and server files to common directory fs/smb`，4.19要打上这个补丁，必须将`.patch`文件中的`smb/client`改成`cifs`:
```sh
sed -i 's/smb\/client/cifs/g' 0001-smb-client-fix-potential-UAF-in-smb2_is_valid_oplock.patch
```

参考`d328c09ee9f1 smb: client: fix use-after-free bug in cifs_debug_data_proc_show()`

# `CVE-2024-35870 24a9799aa8ef smb: client: fix UAF in smb2_reconnect_server()`

```
UAF（Use After Free）漏洞是由于 smb2_reconnect_server() 访问了一个已经被另一个执行 __cifs_put_smb_ses() 线程正在销毁的会话（session）。这种情况可能发生在以下情况: (a) 客户端与服务器建立了连接但没有会话，或 (b) 另一个线程再次将 @ses->ses_status 设置为 SES_EXITING 以外的其他状态。

为了解决这个问题，我们需要确保无条件地将 @ses->ses_status 设置为 SES_EXITING，并防止在我们仍在销毁会话时，任何其他线程设置新的状态。

在 __cifs_put_smb_ses() 中释放 ipc 之后添加一些延迟可以重现这个问题——这将使 smb2_reconnect_server() 的工作线程有机会运行，然后访问 @ses->ipc。
```

因为主线代码文件夹经过了重命名`38c8a9a52082 smb: move client and server files to common directory fs/smb`，4.19要打上这个补丁，必须将`.patch`文件中的`smb/client`改成`cifs`:
```sh
sed -i 's/smb\/client/cifs/g' 0001-smb-client-fix-UAF-in-smb2_reconnect_server.patch
```

`git blame fs/smb/client/connect.c | grep cifs_mark_tcp_ses_conns_for_reconnect`找到补丁`183eea2ee5ba9`，再回退到之前的补丁`git checkout 2e0fa298d149e07005504350358066f380f72b52`，执行`git blame fs/cifs/connect.c | grep cifs_mark_tcp_ses_conns_for_reconnect`找到`43b459aa5e222`，回退到之前的补丁`git checkout efb21d7b0fa4b1a9a35dcf38b262a314fb3628ea`，找到引入`cifs_reconnect`的补丁`1da177e4c3f41524e886b7f1b8a0c1fc7321cac2`。

[openeuler issue](https://gitee.com/src-openeuler/kernel/issues/I9QG1A)。

# [`CVE-2023-52752 d328c09ee9f1 smb: client: fix use-after-free bug in cifs_debug_data_proc_show()`](https://lore.kernel.org/all/20231030201956.2660-2-pc@manguebit.com/)

[openeuler的4.19 pr](https://gitee.com/openeuler/kernel/pulls/8522/files)

[openeuler的5.10 pr](https://gitee.com/openeuler/kernel/pulls/8605/files)

[openeuler上的代码分析](https://gitee.com/openeuler/kernel/pulls/8605#note_30899023_conversation_122811113)

`struct cifs_ses`的`ses_lock`成员是在补丁`d7d7a66aacd6 cifs: avoid use of global locks for high contention data`中引入的。

# `CVE-2023-52751 5c86919455c1 smb: client: fix use-after-free in smb2_query_info_compound()`

[openeuler](https://www.openeuler.org/en/security/cve/detail/?cveId=CVE-2023-52751&packageName=kernel)

因为主线代码文件夹经过了重命名`38c8a9a52082 smb: move client and server files to common directory fs/smb`，4.19要打上这个补丁，必须将`.patch`文件中的`smb/client`改成`cifs`:
```sh
sed -i 's/smb\/client/cifs/g' 0001-smb-client-fix-use-after-free-in-smb2_query_info_com.patch
```

[`git log fs/smb/client/cached_dir.c`](https://github.com/torvalds/linux/commits/master/fs/smb/client/cached_dir.c)