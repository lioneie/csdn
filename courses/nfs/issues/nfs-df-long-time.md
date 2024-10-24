# 问题描述

dorado和netapp当nfs server，使用nfsv3挂载，停止任何操作等待10min以上，再执行`df -h`命令偶现执行时间超3s。使用nfsv4挂载，在一定条件下必现`df -h`命令执行时间超过40s。

挂载参数如下:
```sh
xx.xx.xx.xx:/export on /mnt/nfsv3 type nfs (rw,relatime,vers=3,rsize=65536,wsize=65536,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=xx.xx.xx.xx,mountvers=3,mountport=635,mountproto=udp,local_lock=none,addr=xx.xx.xx.xx)

xx.xx.xx.xx:/export on /mnt/nfsv41 type nfs4 (rw,relatime,vers=4.1,rsize=262144,wsize=262144,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=xx.xx.xx.xx,local_lock=none,addr=xx.xx.xx.xx)
```

准备`debuginfo`:
```sh
rpm2cpio kernel-debuginfo-4.19.90-89.15.v2401.ky10.x86_64.rpm | cpio -div
```

# `tcpdump`抓包

## nfsv4

- 5.752516: GETATTR Call
- 5.754274: GETATTR Reply
  - Attr mask[0]: 0x0010011a (Type, Change, Size, FSID, FileId)
  - Attr mask[1]: 0x00b0a23a (Mode, NumLinks, Owner, Owner_Group, RawDev, Space_Used, Time_Access, Time_Metadata, Time_Modify, Mounted_on_FileId)
- 45.802934: GETATTR Call
- 45.805379: GETATTR Replay
  - Attr mask[0]: 0x00e00000 (Files_Avail, Files_Free, Files_Total)
  - Attr mask[1]: 0x00001c00 (Space_Avail, Space_Free, Space_Total)

## nfsv3

- 2351.124940: SYN
- 2351.125149: SYN-ACK
- 2351.125167: RST
- 2354.176234: SYN
- 2354.176450: SYN-ACK
- 2354.176487: SYN

- SYN: 客户端向服务器发送一个SYN（同步）包，表示请求建立连接。这个包中包含客户端的初始序列号。
- SYN-ACK: 服务器收到SYN包后，返回一个SYN-ACK（同步-确认）包，表示同意建立连接，并且确认客户端的序列号。这个包中包含服务器的初始序列号。
- ACK: 客户端收到SYN-ACK包后，发送一个ACK（确认）包给服务器，确认接收到服务器的SYN-ACK。至此，连接建立完成，客户端和服务器可以开始数据传输。
- RST: 是TCP协议中的一种控制包，用于强制关闭一个连接。RST代表“Reset”，RST包的发送意味着连接的状态被立即清除，不需要进行正常的连接终止过程。它通常在以下几种情况下使用：
  - 异常关闭：当一方收到一个不期望的包（例如，连接已经关闭或不存在的连接）时，会发送RST包来通知对方重置连接。
  - 拒绝连接：当服务器收到一个连接请求（SYN），但不愿意或不能接受该请求时，可以发送RST包给客户端，以表明连接被拒绝。
  - 错误处理：在一些错误情况下，例如应用程序崩溃或无法处理接收到的数据，TCP栈可以发送RST包来重置连接。

# 日志分析

## nfsv4

打开日志开关，复现后抓取日志:
```sh
echo 0xFFFF > /proc/sys/sunrpc/nfs_debug # NFSDBG_ALL
echo 0x7fff > /proc/sys/sunrpc/rpc_debug # RPCDBG_ALL
```

复现后抓到以下日志:
```sh
[509287.484234] RPC: 25155 call_start nfs4 proc GETATTR (sync)
[509287.486186] decode_attr_type: type=040000
[509287.486189] decode_attr_change: change attribute=7413717318535264640
[509287.486191] decode_attr_size: file size=4096
[509287.486193] decode_attr_fsid: fsid=(0x1e0/0x0)
[509287.486195] decode_attr_fileid: fileid=65
[509287.486197] decode_attr_fs_locations: fs_locations done, error = 0
[509287.486199] decode_attr_mode: file mode=0755
[509287.486201] decode_attr_nlink: nlink=3
[509307.511394] decode_attr_owner: uid=0
[509327.534150] decode_attr_group: gid=0
[509327.534154] decode_attr_rdev: rdev=(0x0:0x0)
[509327.534156] decode_attr_space_used: space used=4096
[509327.534159] decode_attr_time_access: atime=1726140575
[509327.534161] decode_attr_time_metadata: ctime=1726140575
[509327.534163] decode_attr_time_modify: mtime=1726140575
[509327.534165] decode_attr_mounted_on_fileid: fileid=65
[509327.534592] RPC: 25158 call_start nfs4 proc STATFS (sync)
[509327.537215] decode_attr_files_avail: files avail=2516582400
[509327.537217] decode_attr_files_free: files free=2516582400
[509327.537219] decode_attr_files_total: files total=2516582400
[509327.537221] decode_attr_space_avail: space avail=515395936256
[509327.537223] decode_attr_space_free: space free=515395936256
[509327.537225] decode_attr_space_total: space total=515396075520
```

`GETATTR`回复数据解码在`decode_getfattr_attrs()`函数中，`decode_attr_owner()`过了`20s`才解码，`decode_attr_group()`以后面的解码函数过了`40s`秒。

抓取内核栈:
```sh
cat /proc/36787/stack
[<0>] call_usermodehelper_exec+0x13d/0x170
[<0>] call_sbin_request_key+0x2bc/0x380
[<0>] request_key_and_link+0x4fd/0x660
[<0>] request_key+0x3c/0x90
[<0>] nfs_idmap_get_key+0xac/0x1c0 [nfsv4]
[<0>] nfs_idmap_lookup_id+0x30/0x80 [nfsv4]
[<0>] nfs_map_name_to_uid+0x6a/0x110 [nfsv4]
[<0>] decode_getfattr_attrs+0xfb2/0x1730 [nfsv4]
[<0>] decode_getfattr_generic.constprop.118+0xe2/0x130 [nfsv4]
[<0>] nfs4_xdr_dec_getattr+0x9a/0xb0 [nfsv4]
[<0>] rpcauth_unwrap_resp+0xd0/0xe0 [sunrpc]
[<0>] call_decode+0x153/0x850 [sunrpc]
[<0>] __rpc_execute+0x7f/0x3f0 [sunrpc]
[<0>] rpc_run_task+0x109/0x150 [sunrpc]
[<0>] nfs4_call_sync_sequence+0x64/0xa0 [nfsv4]
[<0>] _nfs4_proc_getattr+0x116/0x140 [nfsv4]
[<0>] nfs4_proc_getattr+0x7a/0x110 [nfsv4]
[<0>] __nfs_revalidate_inode+0xff/0x330 [nfs]
[<0>] nfs_getattr+0x141/0x2d0 [nfs]
[<0>] vfs_statx+0x89/0xe0
[<0>] __do_sys_newstat+0x39/0x70
[<0>] do_syscall_64+0x5f/0x240
[<0>] entry_SYSCALL_64_after_hwframe+0x5c/0xc1

cat /proc/36787/stack
[<0>] call_usermodehelper_exec+0x13d/0x170
[<0>] call_sbin_request_key+0x2bc/0x380
[<0>] request_key_and_link+0x4fd/0x660
[<0>] request_key+0x3c/0x90
[<0>] nfs_idmap_get_key+0xac/0x1c0 [nfsv4]
[<0>] nfs_idmap_lookup_id+0x30/0x80 [nfsv4]
[<0>] nfs_map_group_to_gid+0x6a/0x110 [nfsv4]
[<0>] decode_getfattr_attrs+0x105f/0x1730 [nfsv4]
[<0>] decode_getfattr_generic.constprop.118+0xe2/0x130 [nfsv4]
[<0>] nfs4_xdr_dec_getattr+0x9a/0xb0 [nfsv4]
[<0>] rpcauth_unwrap_resp+0xd0/0xe0 [sunrpc]
[<0>] call_decode+0x153/0x850 [sunrpc]
[<0>] __rpc_execute+0x7f/0x3f0 [sunrpc]
[<0>] rpc_run_task+0x109/0x150 [sunrpc]
[<0>] nfs4_call_sync_sequence+0x64/0xa0 [nfsv4]
[<0>] _nfs4_proc_getattr+0x116/0x140 [nfsv4]
[<0>] nfs4_proc_getattr+0x7a/0x110 [nfsv4]
[<0>] __nfs_revalidate_inode+0xff/0x330 [nfs]
[<0>] nfs_getattr+0x141/0x2d0 [nfs]
[<0>] vfs_statx+0x89/0xe0
[<0>] __do_sys_newstat+0x39/0x70
[<0>] do_syscall_64+0x5f/0x240
[<0>] entry_SYSCALL_64_after_hwframe+0x5c/0xc1
```

```sh
scripts/faddr2line usr/lib/debug/lib/modules/4.19.90-89.15.v2401.ky10.x86_64/vmlinux call_usermodehelper_exec+0x13d/0x170
call_usermodehelper_exec+0x13d/0x170:
call_usermodehelper_exec at kernel/umh.c:614
```

睡眠发生在`call_usermodehelper_exec()`中的`wait_for_completion(&done);`。

## nfsv3

```sh
[510403.908320] RPC:   275 xprt_connect_status: retrying
[510403.908323] RPC:   275 call_connect_status (status -104)
[510403.908326] RPC:   275 sleep_on(queue "delayq" time 4805072524)
[510403.908332] RPC:   275 added to queue 000000000db4bcdb "delayq"
[510403.908334] RPC:       wake_up_first(000000008c3c84d4 "xprt_sending")
[510403.908336] RPC:   275 setting alarm for 3000 ms
[510403.908338] RPC:   275 sync task going to sleep
[510406.968250] RPC:   275 timeout
[510406.968273] RPC:   275 __rpc_wake_up_task (now 4805075584)
```

`call_connect_status()`函数中`task->tk_status`错误码为`-ECONNRESET`。

# 调试

## kprobe trace

```sh
cd /sys/kernel/debug/tracing/
# 可以用 kprobe 跟踪的函数
cat available_filter_functions | grep nfs_map_name_to_uid
echo 1 > tracing_on
# x86_64函数参数用到的寄存器: RDI, RSI, RDX, RCX, R8, R9
echo 'p:p_nfs_map_name_to_uid nfs_map_name_to_uid name=+0(%si):string' >> kprobe_events
echo 1 > events/kprobes/p_nfs_map_name_to_uid/enable
echo stacktrace > events/kprobes/p_nfs_map_name_to_uid/trigger
echo '!stacktrace' > events/kprobes/p_nfs_map_name_to_uid/trigger
echo 0 > events/kprobes/p_nfs_map_name_to_uid/enable
echo '-:p_nfs_map_name_to_uid' >> kprobe_events
```

## tracepoint

```sh
# tracepoint
cd /sys/kernel/debug/tracing/
echo nop > current_tracer
echo 1 > tracing_on
cat available_events | grep nfs4_map_name_to_uid
cat available_events | grep nfs4_map_group_to_gid
echo nfs4:nfs4_map_name_to_uid >> set_event
echo nfs4:nfs4_map_group_to_gid >> set_event
# echo > set_event # 清空

echo 0 > trace # 清除trace信息
cat trace_pipe
```

## kprobe module

源码[`kprobe-df-long-time.c`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/nfs/kprobe-df-long-time.c)，修改[`Makefile`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/nfs/Makefile)中`KDIR`路径后编译运行。

## `request-key`调试

内核做以下修改:
```c
--- a/security/keys/request_key.c
+++ b/security/keys/request_key.c
@@ -16,6 +16,7 @@
 #include <net/net_namespace.h>
 #include "internal.h"
 #include <keys/request_key_auth-type.h>
+#include <linux/delay.h>
 
 #define key_negative_timeout   60      /* default timeout on a negative key's existence */
 
@@ -193,9 +194,13 @@ static int call_sbin_request_key(struct key *authkey, void *aux)
        argv[i] = NULL;
 
        /* do it */
+
+       printk(" %s %s %s %s %s %s %s %s\n",
+              argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7]);
+       // mdelay(20*1000);
        ret = call_usermodehelper_keys(request_key, argv, envp, keyring,
                                       UMH_WAIT_PROC);
-       kdebug("usermode -> 0x%x", ret);
+       printk("usermode -> 0x%x\n", ret);
        if (ret >= 0) {
                /* ret is the exit/wait code */
                if (test_bit(KEY_FLAG_USER_CONSTRUCT, &key->flags) ||
@@ -519,7 +524,7 @@ static struct key *construct_key_and_link(struct keyring_search_context *ctx,
                ret = construct_key(key, callout_info, callout_len, aux,
                                    dest_keyring);
                if (ret < 0) {
-                       kdebug("cons failed");
+                       printk("cons failed\n");
                        goto construction_failed;
                }
        } else if (ret == -EINPROGRESS) {
```

创建测试程序（不能是脚本，会报`ENOEXEC`错误）:
```sh
cat << EOF > main.c
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char *argv[]) {
    char command[256] = "strace -o /root/strace.out -f -v -s 4096 -tt /sbin/request-key-origin";

    // 拼接参数
    for (int i = 1; i < argc; i++) {
        sprintf(command + strlen(command), " %s", argv[i]);
    }
    printf("command: %s\n", command);

    // 执行命令
    int result = system(command);
    printf("result: %d\n", result);

    FILE *file = fopen("/root/command.txt", "w");  // 打开文件，写入模式
    fprintf(file, "%s\n", command);  // 使用 fprintf 写入字符串
    // 或者使用 fputs(file, command);
    fclose(file);  // 关闭文件

    return result;
}
EOF

# mv /sbin/request-key /sbin/request-key-origin # 程序重命名，只需要开始时执行一次
gcc main.c -o /sbin/request-key
# /sbin/request-key create 883219074 0 0 78314096 0 453981511 # 测试命令
```

执行`df`命令后，`request-key`程序的所有系统调用在文件`/root/strace.out`中。

读取内核栈:
```sh
pid=$(tail -n 1 strace.out | cut -d ' ' -f 1)
cat /proc/${pid}/stack
```

## 现场复现的client环境

```sh
domainname localdomain
```

`/etc/hosts` 新添加以下的后面两行，前面默认的配置不删除:
```sh
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
# 101.226.141.58 qyapi.weixin.qq.com
# 101.89.47.18 api.weixin.qq.com
101.227.143.58 qyapi.weixin.qq.com
101.100.77.18 api.weixin.qq.com
```

`/etc/resolv.conf`:
```sh
# nameserver 114.114.114.114
# nameserver 8.8.8.8
nameserver 115.119.114.114
nameserver 8.8.9.9
```

kprobe module打印如下:
```sh
[711334.420054] handler_pre: <call_usermodehelper_setup> /sbin/request-key op:create, key:626115642, uid:0, gid:0, keyring:515291944, keyring:0, keyring:620716518
[711334.424225] handler_pre: <call_usermodehelper_setup> /sbin/request-key op:create, key:44305564, uid:0, gid:0, keyring:515291944, keyring:0, keyring:620716518
```

strace日志如下:
```sh
4014  20:02:20.175808 socket(AF_INET, SOCK_DGRAM|SOCK_CLOEXEC|SOCK_NONBLOCK, IPPROTO_IP) = 3
4014  20:02:20.175944 connect(3, {sa_family=AF_INET, sin_port=htons(53), sin_addr=inet_addr("114.114.114.114")}, 16) = 0
4014  20:02:20.176123 poll([{fd=3, events=POLLOUT}], 1, 0) = 1 ([{fd=3, revents=POLLOUT}])
4014  20:02:20.176231 sendto(3, "\264#\1\0\0\1\0\0\0\0\0\0\vkylin2403-2\0\0\1\0\1", 29, MSG_NOSIGNAL, NULL, 0) = 29
4014  20:02:20.176388 poll([{fd=3, events=POLLIN}], 1, 5000) = 0 (Timeout)
4014  20:02:25.181729 socket(AF_INET, SOCK_DGRAM|SOCK_CLOEXEC|SOCK_NONBLOCK, IPPROTO_IP) = 4
4014  20:02:25.181933 connect(4, {sa_family=AF_INET, sin_port=htons(53), sin_addr=inet_addr("8.8.8.8")}, 16) = 0
4014  20:02:25.182130 poll([{fd=4, events=POLLOUT}], 1, 0) = 1 ([{fd=4, revents=POLLOUT}])
4014  20:02:25.182334 sendto(4, "\264#\1\0\0\1\0\0\0\0\0\0\vkylin2403-2\0\0\1\0\1", 29, MSG_NOSIGNAL, NULL, 0) = 29
4014  20:02:25.182558 poll([{fd=4, events=POLLIN}], 1, 5000) = 0 (Timeout)
4014  20:02:30.187737 poll([{fd=3, events=POLLOUT}], 1, 0) = 1 ([{fd=3, revents=POLLOUT}])
4014  20:02:30.187942 sendto(3, "\264#\1\0\0\1\0\0\0\0\0\0\vkylin2403-2\0\0\1\0\1", 29, MSG_NOSIGNAL, NULL, 0) = 29
4014  20:02:30.188136 poll([{fd=3, events=POLLIN}], 1, 5000) = 0 (Timeout)
4014  20:02:35.192739 poll([{fd=4, events=POLLOUT}], 1, 0) = 1 ([{fd=4, revents=POLLOUT}])
4014  20:02:35.192975 sendto(4, "\264#\1\0\0\1\0\0\0\0\0\0\vkylin2403-2\0\0\1\0\1", 29, MSG_NOSIGNAL, NULL, 0) = 29
4014  20:02:35.193137 poll([{fd=4, events=POLLIN}], 1, 5000) = 0 (Timeout)
4014  20:02:40.195745 close(3)          = 0
4014  20:02:40.195964 close(4)          = 0
```

可以看出在dns解析时连接dns服务器花了40s。

## 虚拟机环境

```sh
echo N > /sys/module/nfsd/parameters/nfs4_disable_idmapping # server，默认为Y
echo N > /sys/module/nfs/parameters/nfs4_disable_idmapping # client，默认为Y
mount -t nfs -o rw,relatime,vers=4.1,rsize=262144,wsize=262144,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,local_lock=none 192.168.53.40:/s_test /mnt
```

```sh
domainname localdomain
```

`/etc/hosts` 新添加以下的后面两行，前面默认的配置不删除:
```sh
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
101.227.143.58 qyapi.weixin.qq.com
101.100.77.18 api.weixin.qq.com
```

`/etc/resolv.conf`文件内容替换为：
```sh
nameserver 115.119.114.114
nameserver 8.8.9.9
```

但很有可能会被 NetworkManager 工具或`systemd-resolved.service`服务在下一次启动时覆盖掉`/etc/resolv.conf`，我们要做的就是禁止服务来更改本文件:
```sh
sudo cp /etc/resolv.conf ./
sudo rm -rf /etc/resolv.conf
sudo cp ./resolv.conf /etc/resolv.conf
sudo chattr +i /etc/resolv.conf
sudo rm ./resolv.conf
```

kprobe module打印如下:
```sh
[  998.700832] handler_pre: <call_usermodehelper_setup> /sbin/request-key op:create, key:216577440, uid:0, gid:0, keyring:744331010, keyring:0, keyring:493558208
[  998.850977] handler_pre: <call_usermodehelper_setup> /sbin/request-key op:create, key:243125691, uid:0, gid:0, keyring:744331010, keyring:0, keyring:493558208
```

```sh
touch /mnt/file
echo 3 > /proc/sys/vm/drop_caches
ls /mnt/file
# /sbin/request-key参数中的第一个keyring
keyctl list 744331010
keyctl clear 744331010
```

# 代码分析

## nfsv4

```c
newstat
  vfs_statx
    nfs_getattr
      __nfs_revalidate_inode
        nfs4_proc_getattr
          _nfs4_proc_getattr
            nfs4_call_sync_sequence
              rpc_run_task
                __rpc_execute
                  call_decode
                    rpcauth_unwrap_resp
                      nfs4_xdr_dec_getattr
                        decode_getfattr_generic.constprop.118
                          decode_getfattr_attrs
                            decode_attr_owner
                              nfs_map_name_to_uid // error=0 id=0 name=root@localdomain
                                nfs_idmap_lookup_id
                                  nfs_idmap_get_key
                                    nfs_idmap_request_key
                                      request_key(key_type_id_resolver)
                                        request_key_and_link(type=key_type_id_resolver)
                                          construct_key_and_link // 开始密钥构建
                                            construct_key // 调用用户空间进行密钥构造，程序失败被忽略，优先考虑密钥状态。
                                              call_sbin_request_key // 请求用户空间完成密钥的构造，执行 "/sbin/request-key <op> <key> <uid> <gid> <keyring> <keyring> <keyring>"
                                                call_usermodehelper_keys
                                                  call_usermodehelper_exec
                                                    // 等待用户态命令执行完成，卡在了连接dns服务器上，因为客户环境上与互联网不通
                                                    wait_for_completion(&done);
                            decode_attr_group
                              nfs_map_group_to_gid // error=0 id=0 name=root@localdomain
                                nfs_idmap_lookup_id
                                  nfs_idmap_get_key
                                    request_key
                                      request_key_and_link
                                        call_sbin_request_key
                                          call_usermodehelper_exec
                                            wait_for_completion(&done);
```

```c
/**                                                                            
 * request_key - 请求一个密钥并等待构建完成                       
 * @type: 密钥的类型。                                                         
 * @description: 密钥的可搜索描述。                        
 * @callout_info: 传递给实例化回调的数据（或NULL）。      
 *                                                                             
 * 与request_key_and_link()相似，但如果找到密钥，它不会将返回的密钥添加到keyring中，新的密钥总是在用户的配额中分配，
 * callout_info必须是一个以NUL结尾的字符串，且不能传递任何辅助数据。                                                                  
 *                                                                             
 * 此外，它将像wait_for_key_construction()一样工作，等待处于构建中的密钥完成，等待期间不能被中断。   
 */
struct key *request_key(struct key_type *type,   
                        const char *description, 
                        const char *callout_info)
/**                                                                                
 * request_key_and_link - 请求一个密钥并将其缓存到keyring中。                 
 * @type: 我们需要的密钥类型。                                                 
 * @description: 密钥的可搜索描述。                            
 * @callout_info: 传递给实例化回调的数据（或NULL）。          
 * @callout_len: callout_info的长度。                                       
 * @aux: 实例化回调的辅助数据。                                            
 * @dest_keyring: 用于缓存密钥的位置。                                          
 * @flags: 传递给key_alloc()的标志。                                                   
 *                                                                                 
 * 在进程的keyring中搜索符合指定条件的密钥，如果找到，将返回该密钥并增加其使用计数。否则，    
 * 如果callout_info不为NULL，则会分配一个密钥，并请求某些服务（可能在用户空间中）来实例化它。                        
 *                                                                                 
 * 如果成功找到或创建，密钥将被链接到提供的目标keyring中。                                                     
 *                                                                                 
 * 如果成功，返回一个指向密钥的指针；如果找到的密钥不可访问、为负、已撤销或已过期，则返回
 * -EACCES、-ENOKEY、-EKEYREVOKED或-EKEYEXPIRED；如果未找到密钥且未提供@callout_info，则返回-ENOKEY；  
 * 如果没有足够的密钥配额来创建新密钥，则返回-EDQUOT；如果没有足够的内存，则返回-ENOMEM。                                              
 *                                                                                 
 * 如果返回的密钥是新创建的，则它可能仍处于构建中，应使用wait_for_key_construction()来等待完成。    
 */                                                                                
struct key *request_key_and_link(struct key_type *type,                            
                                 const char *description,                          
                                 const void *callout_info,                         
                                 size_t callout_len,                               
                                 void *aux,                                        
                                 struct key *dest_keyring,                         
                                 unsigned long flags)

```

#　结论

## nfsv4

nfsv4在启用idmap的情况下，在解析`GETATTR`回复报文的`owner`和`group`时，会调用用户态程序`request-key`，`request-key`会再调用到`nfsidmap`程序，紧接着触发一个域名解析，由于现场环境与互联网不通，所以连接dns的两个ip时20秒超时，解析`owner`和`group`共花了40s，所以在现场现场环境中`df`命令的执行时间花了40s。

可通过以下几种方案解决或规避:

- 网络连接互联网（解决根因）
- 禁用nfs idmap
- 禁用dns服务