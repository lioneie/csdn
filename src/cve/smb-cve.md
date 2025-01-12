# `CVE-2024-50047 b0abcd65ec54 smb: client: fix UAF in async decryption`。

[openeuler的issue](https://gitee.com/src-openeuler/kernel/issues/IAYRE5)。

[CVE-2024-50047 的修复导致出现Oops 复位](https://gitee.com/openeuler/kernel/issues/IBC88Z?skip_mobile=true)

# `CVE-2024-50106 8dd91e8d31fe nfsd: fix race between laundromat and free_stateid`

[openeuler issue](https://gitee.com/src-openeuler/kernel/issues/IB2BX2)

# `CVE-2024-53095 ef7134c7fc48 smb: client: Fix use-after-free of network namespace.`

[openeuler issue](https://gitee.com/src-openeuler/kernel/issues/IB67YB)

[openeuler 4.19 补丁](https://gitee.com/openeuler/kernel/pulls/14249)

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

# `CVE-2024-0565 eec04ea11969 [smb: client: fix OOB in receive_encrypted_standard()](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=eec04ea119691e65227a97ce53c0da6b9b74b0b7)

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