<!-- https://desk.ctyun.cn/html/download/ -->

# 问题描述

5.4内核。

挂载参数：
```sh
# 'LAPTOP-OBA5M86D F' 是包含空格的目录名
//127.0.0.1/LAPTOP-OBA5M86D F on /media/LAPTOP-OBA5M86D F type cifs (rw,relatime,sync,vers=2.1,cache=strict,username=vagrant-3234,uid=0,noforceuid,gid=0,noforcegid,addr=127.0.0.1,file_mode=0777,dir_mode=0777,iocharset=utf8,soft,nounix,mapposix,noperm,rsize=1048576,wsize=1048576,bsize=1048576,echo_interval=2,actimeo=2)
# 第二次复现
//127.0.0.1/media-root-365C-B654 on /media/media-root-365C-B654 type cifs (rw,relatime,sync,vers=2.1,cache=strict,username=vagrant-3236,uid=0,noforceuid,gid=0,noforcegid,addr=127.0.0.1,file_mode=0777,dir_mode=0777,iocharset=utf8,soft,nounix,mapposix,noperm,rsize=1048576,wsize=1048576,bsize=1048576,echo_interval=2,actimeo=2)
```

`dmesg` 日志：
```sh
[16634.819041] CIFS VFS: \\127.0.0.1 cifs_put_smb_ses: Session Logoff failure rc=-78
...
[23080.736515] CIFS VFS: \\127.0.0.1 has not responded in 6 seconds. Reconnecting...
...
[23080.900680] CIFS VFS: \\127.0.0.1 disabling echoes and oplocks
```

# `strace`调试

使用`strace -o strace.out -f -v -s 4096 ls /media/media-root-365C-B654`得到以下日志：
```sh
# 偶尔会报错　(Host is down)
 79 241573 newfstatat(AT_FDCWD, "/media/media-root-365C-B654", 0x5587298b58, 0) = -1 ENOTSUPP (Unknown error 524)
 97 241573 write(2, "ls: ", 4)              = 4
 98 241573 write(2, "cannot access '/media/media-root-365C-B654'", 43) = 43
111 241573 write(2, ": Unknown error 524", 19) = 19
```

# `kprobe`调试

麒麟arm64系统下无法用`kprobe trace`，内核配置`CONFIG_TRACING`没打开。也没法用`systemtap`。

使用`kretprobe`模块代码，[`kretprobe_smb.c`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/smb/kretprobe_smb.c)和[`Makefile`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/smb/Makefile):
```sh
make -j`nproc`
insmod ./kretprobe_smb.ko func="wait_for_free_credits" # wait_for_free_credits可替换为其他函数名
```

尝试跟踪这几个返回`-ENOTSUPP`的函数：
```c
cifs_enable_signing
cifs_writev_requeue
cifs_fiemap
smb2_adjust_credits
handle_read_data
wait_for_free_credits
wait_for_compound_request
```

发现`-ENOTSUPP`都不是这几个函数返回的。

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

[可能的修复补丁](https://chenxiaosong.com/courses/patches/cifs-Fix-in-error-types-returned-for-out-of-credit-s.html)。

执行`ls /mnt`时，在`cifs`的代码中唯一可能返回`-ENOTSUPP`错误的只有`wait_for_free_credits()`
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

// 和 statx 系统调用一样，执行到vfs_statx
newfstatat
  vfs_fstatat
    vfs_statx

// 返回-EHOSTDOWN错误的路径
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