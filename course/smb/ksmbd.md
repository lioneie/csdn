# 参考资料

- [KSMBD kernel doc](https://chenxiaosong.com/src/translations/smb/ksmbd-kernel-doc.html)
- [ksmbd-tools](https://chenxiaosong.com/src/translations/smb/ksmbd-tools-readme.html)
- [cifsd-team/ksmbd](https://github.com/cifsd-team/ksmbd)

# 现状

- [开发进度](https://github.com/torvalds/linux/blob/master/Documentation/filesystems/smb/ksmbd.rst#ksmbd-feature-status)。以下是待实现或待完善的功能:
  - SMB3 Multi-channel: 部分支持。多通道，计划将来实现重播/重试机制。
  - ACLs: 部分支持。Access Control List (访问控制列表)，仅支持DACL，SACL（审计）计划在未来实现。对于所有权（SID），ksmbd生成随机的子身份验证值（然后存储到磁盘），并使用从inode获取的uid/gid作为本地域SID的RID。目前的ACL实现仅限于独立服务器，不支持作为域成员运行。正在与Samba工具进行集成，以便将来支持作为域成员运行。
  - Durable handle v1,v2: 未支持。耐久句柄是一种特殊的文件句柄，主要应对临时的客户端网络中断。
  - Persistent handle: 未支持。持久句柄，不仅应对客户端的网络中断，还能在服务器端的重大故障后保持有效。
  - SMB2 notify: 未支持。向客户端发送文件系统变化的通知消息。
  - DCE/RPC support: 部分支持。分散式运算环境/远端呼叫系统（英文全称: Distributed Computing Environment / Remote Procedure Calls），一些必要的调用（如NetShareEnumAll、NetServerGetInfo、SAMR、LSARPC）由ksmbd.mountd通过netlink接口处理。目前正在调查通过upcall与Samba工具和库进行额外集成的可能性，以支持额外的DCE/RPC管理调用（以及未来对Witness协议的支持等）。
  - ksmbd/nfsd interoperability: 未支持。和nfsd的互操作性，这个特性ksmbd要支持包括租约（Leases）、通知（Notify）、ACL（访问控制列表）和共享模式（Share modes）。
  - SMB3.1.1 Compression: 未支持。压缩，减少网络带宽的使用，提高数据传输效率。
  - SMB3.1.1 over QUIC: 未支持。QUIC（Quick UDP Internet Connections）。
  - Signing/Encryption over RDMA: 未支持。通过RDMA（Remote Direct Memory Access，远程直接内存访问）进行签名和加密。
  - SMB3.1.1 GMAC signing support: 未支持。Galois message authentication code mode, 伽罗瓦消息验证码，是一种基于 AES（Advanced Encryption Standard）的认证算法。
- 使用指导文档较全。
- cve漏洞暂时较多:
  - 9.8分[CVE-2022-47939](https://nvd.nist.gov/vuln/detail/cve-2022-47939)
  - 9.8分[CVE-2023-32254](https://nvd.nist.gov/vuln/detail/CVE-2023-32254)
  - 9.0分[CVE-2023-32250](https://nvd.nist.gov/vuln/detail/CVE-2023-32250)
  - 8.8分[CVE-2022-47942](https://nvd.nist.gov/vuln/detail/CVE-2022-47942)
  - 8.1分[CVE-2022-47940](https://nvd.nist.gov/vuln/detail/CVE-2022-47940)
  - 8.1分[CVE-2023-32258](https://nvd.nist.gov/vuln/detail/CVE-2023-32258)
  - 8.1分[CVE-2023-32257](https://nvd.nist.gov/vuln/detail/CVE-2023-32257)
  - 7.8分[CVE-2023-32356](https://nvd.nist.gov/vuln/detail/CVE-2023-32356)
  - 7.5分[CVE-2023-32252](https://nvd.nist.gov/vuln/detail/CVE-2023-32252)
  - 7.5分[CVE-2023-32248](https://nvd.nist.gov/vuln/detail/CVE-2023-32248)
  - 7.5分[CVE-2023-32247](https://nvd.nist.gov/vuln/detail/CVE-2023-32247)

# 环境

```sh
apt install -y git gcc pkgconf autoconf automake libtool make meson ninja-build gawk libnl-3-dev libnl-genl-3-dev libglib2.0-dev
dnf install -y git gcc pkgconf autoconf automake libtool make meson ninja-build gawk libnl3-devel glib2-devel
git clone https://github.com/cifsd-team/ksmbd-tools.git
cd ksmbd-tools
./autogen.sh
./configure --with-rundir=/run # --prefix=/usr/local/sbin --sysconfdir=/usr/local/etc
make
sudo make install 
```

安装的二进制文件为`/usr/local/sbin/ksmbd.*`，配置文件例子`/usr/local/etc/ksmbd/ksmbd.conf.example`。

以上是使用`autotools`编译，如果要使用`meson`编译，查看[ksmbd-tools README](https://chenxiaosong.com/src/translations/smb/ksmbd-tools-readme.html)。

用户操作:
<!--
```sh
# 以下3个命令是很早以前的命令
# ksmbd.adduser --add-user=MyUser
# ksmbd.adduser --update-user=MyUser --password=MyNewPassword
# ksmbd.adduser --del-user=MyUser
```
-->
```sh
mkdir -vp /tmp/s_test
# 生成 ksmbd.conf
sudo ksmbd.addshare --add \
                    --option "path = /tmp/s_test" \
                    --option 'read only = no' \
                    TEST
sudo ksmbd.addshare --update TEST # 填写其他信息
sudo ksmbd.adduser --add root
sudo ksmbd.adduser --delete root # 删除用户
```

配置文件`/usr/local/etc/ksmbd/ksmbd.conf`的一个例子如下:
```sh
[global]
        writeable = yes
        public = yes

[TEST]
        comment = xfstests test dir
        ; 注意路径后面不要有空格，我被路径后的空格坑过
        path = /tmp/s_test
```

执行脚本[ksmbd-svr-setup.sh](https://gitee.com/chenxiaosonggitee/blog/blob/master/course/smb/ksmbd-svr-setup.sh)启动内核的ksmbd server。

```sh
sudo ksmbd.control --shutdown # 关闭
sudo ksmbd.mountd # 启动
sudo mount -o user=root //127.0.0.1/TEST /mnt
```

# 代码流程

```c
kthread
  worker_thread
    process_scheduled_works
      process_one_work
        handle_ksmbd_work
          __handle_ksmbd_work
            __process_request
              smb2_open
                dentry_open
                  vfs_open
                    do_dentry_open
                      ext2_file_open
```