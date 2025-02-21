<!-- https://desk.ctyun.cn/html/download/ -->

# 问题描述

5.4内核。

挂载参数:
```sh
# 'LAPTOP-OBA5M86D F' 是包含空格的目录名
//127.0.0.1/LAPTOP-OBA5M86D F on /media/LAPTOP-OBA5M86D F type cifs (rw,relatime,sync,vers=2.1,cache=strict,username=vagrant-3234,uid=0,noforceuid,gid=0,noforcegid,addr=127.0.0.1,file_mode=0777,dir_mode=0777,iocharset=utf8,soft,nounix,mapposix,noperm,rsize=1048576,wsize=1048576,bsize=1048576,echo_interval=2,actimeo=2)
# 第二次复现
//127.0.0.1/media-root-365C-B654 on /media/media-root-365C-B654 type cifs (rw,relatime,sync,vers=2.1,cache=strict,username=vagrant-3236,uid=0,noforceuid,gid=0,noforcegid,addr=127.0.0.1,file_mode=0777,dir_mode=0777,iocharset=utf8,soft,nounix,mapposix,noperm,rsize=1048576,wsize=1048576,bsize=1048576,echo_interval=2,actimeo=2)
```

`dmesg` 日志:
```sh
[16634.819041] CIFS VFS: \\127.0.0.1 cifs_put_smb_ses: Session Logoff failure rc=-78
...
[23080.736515] CIFS VFS: \\127.0.0.1 has not responded in 6 seconds. Reconnecting...
...
[23080.900680] CIFS VFS: \\127.0.0.1 disabling echoes and oplocks
```

# `strace`调试

使用`strace -o strace.out -f -v -s 4096 ls /media/media-root-365C-B654`得到以下日志:
```sh
# 偶尔会报错 (Host is down)
 79 241573 newfstatat(AT_FDCWD, "/media/media-root-365C-B654", 0x5587298b58, 0) = -1 ENOTSUPP (Unknown error 524)
 97 241573 write(2, "ls: ", 4)              = 4
 98 241573 write(2, "cannot access '/media/media-root-365C-B654'", 43) = 43
111 241573 write(2, ": Unknown error 524", 19) = 19
```

`newfstatat`系统调用大部分时候返回`ENOTSUPP(524)`错误。

# `kprobe`调试

麒麟arm64系统下无法用`kprobe trace`，内核配置`CONFIG_TRACING`没打开。也没法用`systemtap`。

使用`kretprobe`模块代码，[`kretprobe_smb.c`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/smb/kretprobe_smb.c)和[`Makefile`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/smb/Makefile):
```sh
make -j`nproc`
insmod ./kretprobe_smb.ko func="compound_send_recv" # compound_send_recv可替换为其他函数名
```

尝试跟踪这几个返回`-ENOTSUPP`的函数:
```c
cifs_enable_signing
cifs_writev_requeue
cifs_fiemap
smb2_adjust_credits
handle_read_data
wait_for_free_credits
wait_for_compound_request // 无法直接跟踪，可以跟踪 compound_send_recv
```

发现返回`-ENOTSUPP`的是`wait_for_compound_request()`函数。

替换为主线内核，得到如下日志:
```sh
[ 7296.825123] CPU: 2 PID: 51185 Comm: ls Kdump: loaded Tainted: G           OE      6.10.0+ #1
[ 7296.825133] Hardware name: RDO OpenStack Compute, BIOS 0.0.0 02/06/2015
[ 7296.825135] Call trace:
...
[ 7296.825189]  compound_send_recv+0x0/0xbc8 [cifs]
[ 7296.825242]  smb2_query_path_info+0x128/0x3e4 [cifs]
[ 7296.825279]  cifs_get_fattr+0x354/0x920 [cifs]
[ 7296.825312]  cifs_get_inode_info+0x80/0x150 [cifs]
[ 7296.825344]  cifs_revalidate_dentry_attr+0x19c/0x2e4 [cifs]
[ 7296.825376]  cifs_getattr+0xa8/0x27c [cifs]
[ 7296.825408]  vfs_getattr_nosec+0xb4/0xd4
[ 7296.825411]  vfs_getattr+0x50/0x6c
[ 7296.825413]  vfs_statx_path+0x2c/0xf8
[ 7296.825415]  vfs_statx+0x9c/0x100
[ 7296.825416]  vfs_fstatat+0x5c/0xd8
[ 7296.825419]  __do_sys_newfstatat+0x28/0x64
...

[ 7296.825445] compound_send_recv returned 4294967261 and took 325120 ns to execute
```

# 复现

```sh
# -o iocharset=utf8 可能报错 CIFS VFS: CIFS mount error: iocharset utf8 not found
mount -t cifs -o rw,relatime,vers=2.1,cache=strict,uid=0,noforceuid,gid=0,noforcegid,addr=127.0.0.1,file_mode=0777,dir_mode=0777,soft,nounix,mapposix,noperm,rsize=1048576,wsize=1048576,bsize=1048576,echo_interval=2,actimeo=2 //localhost/TEST /mnt
```

## `Host is down`

报错`Host is down`的情况很好构造。

```sh
ifconfig lo down
strace -o strace.out -f -v -s 4096 ls /mnt
```

# 代码分析

[相关补丁](https://chenxiaosong.com/course/smb/patch/cifs-Fix-in-error-types-returned-for-out-of-credit-s.html)。

执行`ls /mnt`时，返回`-ENOTSUPP`错误的一个流程:
```c
statx
  vfs_statx
    vfs_getattr_nosec
      cifs_getattr
        cifs_revalidate_dentry_attr
          cifs_get_inode_info
            smb2_query_path_info
              open_shroot
                wait_for_free_credits
              SMB2_query_info
                query_info
                  cifs_send_recv
                    wait_for_free_credits
              close_shroot
                SMB2_close
                  SMB2_close_flags
                    cifs_send_recv
                      wait_for_free_credits
```

和 `statx` 系统调用一样，`newfstatat`最终执行到`vfs_statx`:
```c
newfstatat
  vfs_fstatat
    vfs_statx
```

返回-EHOSTDOWN错误的路径:
```c
statx
  do_statx
    vfs_statx
      vfs_getattr
        vfs_getattr_nosec
          cifs_getattr
            cifs_revalidate_dentry_attr
              cifs_get_inode_info
                cifs_get_fattr
                  smb2_query_path_info
                    smb2_compound_op
                      SMB2_open_init
                        smb2_plain_req_init
                          smb2_reconnect
                            cifs_wait_for_server_reconnect
                              return -EHOSTDOWN
```