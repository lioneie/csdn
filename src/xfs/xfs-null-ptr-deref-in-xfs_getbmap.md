# 问题描述

```sh
[   68.392204] BUG: kernel NULL pointer dereference, address: 000000000000002a
...
[   68.428987] Call Trace:
[   68.429726]  <TASK>
[   68.450295]  xfs_ioc_getbmap+0x192/0x310
[   68.451510]  xfs_file_ioctl+0x4a4/0xe70
[   68.473513]  vfs_ioctl+0x3b/0x70
[   68.474434]  __se_sys_ioctl+0xbd/0xe0
[   68.475341]  __x64_sys_ioctl+0x1f/0x30
[   68.476259]  do_syscall_64+0x43/0x120
[   68.477174]  entry_SYSCALL_64_after_hwframe+0x6e/0x76
```

# 内核构造补丁

```c
diff --git a/fs/xfs/xfs_bmap_util.c b/fs/xfs/xfs_bmap_util.c
index 1a1d1f881037..d886be3d301e 100644
--- a/fs/xfs/xfs_bmap_util.c
+++ b/fs/xfs/xfs_bmap_util.c
@@ -29,6 +29,7 @@
 #include "xfs_iomap.h"
 #include "xfs_reflink.h"
 #include "xfs_rtbitmap.h"
+#include <linux/delay.h>
 
 /* Kernel only BMAP related definitions and functions */
 
@@ -433,6 +434,10 @@ xfs_getbmap(
                whichfork = XFS_DATA_FORK;
        ifp = xfs_ifork_ptr(ip, whichfork);
 
+       printk("delay begin\n");
+       mdelay(5000);
+       printk("delay end\n");
+
        xfs_ilock(ip, XFS_IOLOCK_SHARED);
        switch (whichfork) {
        case XFS_ATTR_FORK:
```

# 用户态程序

`ioctl.c`文件：
```c
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <unistd.h>

int main() {
    const char *path = "/mnt";
    int fd;

    fd = open(path, O_RDONLY | O_DIRECTORY);
    if (fd == -1) {
        perror("无法打开目录");
        return EXIT_FAILURE;
    }

    char arg[32] = "\x01\xff\x00\x00\x00\x00\x03\x00\x00\x00\x00\x00\x00"
                   "\x00\x00\x00\x00\x00\x08\x00\x00\x00\xc6\x2a\xf7";

    if (ioctl(fd, _IOC(_IOC_READ | _IOC_WRITE, 0x58, 0x2c, 0x20), arg) == -1) {
        perror("ioctl 操作失败");
        close(fd);
        return EXIT_FAILURE;
    }

    printf("ioctl 操作成功\n");

    close(fd);
    return EXIT_SUCCESS;
}
```

`setxattr.c`文件：
```c
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/xattr.h>

int main() {
    const char *path = "/mnt";
    const char *attr_name = "trusted.overlay.upper";

    int result = setxattr(path, attr_name, NULL, 0, XATTR_CREATE);

    if (result == 0) {
        printf("扩展属性设置成功。\n");
    } else {
        perror("设置扩展属性时发生错误");
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
```

# 复现命令

```sh
apt-get install xfsprogs -y

fallocate -l 100M image
mkfs.xfs -f image
mount image /mnt

gcc setxattr.c -o setxattr
gcc ioctl.c -o ioctl
./ioctl & # 这里会deley 3秒
sleep 1
./setxattr
```

# 代码分析

```c
         ioctl               |       setxattr
 ----------------------------|---------------------------
 xfs_getbmap                 |
   xfs_ifork_ptr             |
     xfs_inode_has_attr_fork |
       ip->i_forkoff == 0    |
     return NULL             |
   ifp == NULL               |
 ----------------------------|---------------------------
                             | xfs_bmap_set_attrforkoff
                             |   ip->i_forkoff > 0
 ----------------------------|---------------------------
   xfs_inode_has_attr_fork   |
     ip->i_forkoff > 0       |
   ifp == NULL               |
   ifp->if_format // null-ptr-deref
```

修复补丁： [001c179c4e26 xfs: fix NULL pointer dereference in xfs_getbmap()](https://lore.kernel.org/all/20220727085230.4073478-1-chenxiaosong2@huawei.com/)

# vmcore解析

构造复现后，顺便导出vmcore解析一下玩玩。

`dmesg`日志：
```sh
[   87.104528] BUG: kernel NULL pointer dereference, address: 000000000000002a
[   87.107238] #PF: supervisor read access in kernel mode
[   87.108798] #PF: error_code(0x0000) - not-present page
[   87.110274] PGD 0 P4D 0 
[   87.111077] Oops: 0000 [#1] PREEMPT SMP NOPTI
[   87.112368] CPU: 1 PID: 502 Comm: ioctl Not tainted 6.7.0-rc2+ #14
[   87.114143] Hardware name: QEMU Standard PC (i440FX + PIIX, 1996), BIOS rel-1.16.2-0-gea1b7a073390-prebuilt.qemu.org 04/01/2014
[   87.117309] RIP: 0010:xfs_getbmap+0x17c/0x7d0
[   87.118657] Code: aa 2a 02 00 41 83 ff 01 0f 84 25 01 00 00 e8 6b c5 9a ff 45 85 ff 0f 84 4f 01 00 00 44 89 3c 24 e8 59 c5 9a ff 48 8b 44 24 18 <0f> b6 58 2a 80 fb 01 0f 84 c3 05 00 00 e8 42 c5 9a ff 84 db 0f 8e
[   87.123959] RSP: 0018:ffffc90003267bf0 EFLAGS: 00010246
[   87.125499] RAX: 0000000000000000 RBX: 0000000000000000 RCX: 0000000000000001
[   87.127580] RDX: 0000000000000001 RSI: ffff888105568000 RDI: 0000000000000002
[   87.129627] RBP: ffffffffffffffff R08: ffff88813ba72d70 R09: 0000000000000002
[   87.131635] R10: 0000000000000001 R11: 0000000000000001 R12: ffffc90003267cb8
[   87.133646] R13: ffff88810a8a9000 R14: 0000000000000001 R15: 0000000000000001
[   87.135657] FS:  00007f59e6862540(0000) GS:ffff88813ba40000(0000) knlGS:0000000000000000
[   87.137933] CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
[   87.139576] CR2: 000000000000002a CR3: 00000001048c2000 CR4: 0000000000350ef0
[   87.141589] Call Trace:
[   87.142325]  <TASK>
[   87.161495]  xfs_ioc_getbmap+0x192/0x310
[   87.162716]  xfs_file_ioctl+0x4a4/0xe70
[   87.184714]  vfs_ioctl+0x3b/0x70
[   87.185563]  __se_sys_ioctl+0xbd/0xe0
[   87.186472]  __x64_sys_ioctl+0x1f/0x30
[   87.187390]  do_syscall_64+0x43/0x120
[   87.188301]  entry_SYSCALL_64_after_hwframe+0x6e/0x76
```

解析崩在哪一行：
```sh
./scripts/faddr2line build/vmlinux xfs_getbmap+0x17c/0x7d0
xfs_getbmap+0x17c/0x7d0:
xfs_getbmap at fs/xfs/xfs_bmap_util.c:491
```

查看`if_format`在`struct xfs_ifork`中的偏移量：
```sh
crash> struct xfs_ifork -ox
struct xfs_ifork {
  ...
  [0x2a] int8_t if_format;
  ...
}
SIZE: 0x30
```
这就是为什么报错发生空指针解引用的地址是`000000000000002a`。
