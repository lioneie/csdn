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

