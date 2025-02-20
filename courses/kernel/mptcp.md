mptcp的maintainer之一Geliang Tang <tanggeliang@kylinos.cn>是我们麒麟软件的，最近在调研mptcp和smb、nfs结合的可能性，顺便记录一下。

# 资料

- [mptcp.dev](https://www.mptcp.dev/), 对应的[github仓库](https://github.com/multipath-tcp/mptcp.dev)
- [mptcp_net-next/wiki](https://github.com/multipath-tcp/mptcp_net-next/wiki)
- [Multipath TCP Documentation](https://mptcp-apps.github.io/mptcp-doc/)
- [RFC 8684](https://www.rfc-editor.org/rfc/rfc8684.html), [pdf文档翻译请查看百度网盘](https://chenxiaosong.com/baidunetdisk)
- [邮件列表](https://lore.kernel.org/mptcp/)
- [patchwork](https://patchwork.kernel.org/project/mptcp/list/)
- [mptcpd](https://github.com/multipath-tcp/mptcpd)
- [tools/testing/selftests/net/mptcp](https://github.com/torvalds/linux/tree/master/tools/testing/selftests/net/mptcp), [github mptcp_net-next仓库](https://github.com/multipath-tcp/mptcp_net-next/tree/export/tools/testing/selftests/net/mptcp), [内核编译需要打开的配置选项](https://github.com/multipath-tcp/mptcp_net-next/blob/export/tools/testing/selftests/net/mptcp/config)
- [mptcp-upstream-virtme-docker](https://github.com/multipath-tcp/mptcp-upstream-virtme-docker), [github virtme-ng](https://github.com/arighi/virtme-ng), [gitcode virtme-ng](https://gitcode.com/gh_mirrors/vi/virtme-ng)
- [开发中的特性](https://github.com/multipath-tcp/mptcp_net-next/projects?query=is%3Aopen), [MPTCP Upstream: Future](https://github.com/orgs/multipath-tcp/projects/1/views/1)
- [mptcp-hello](https://github.com/mptcp-apps/mptcp-hello/)

# 使用

- [`mptcp-client.c`](https://gitee.com/chenxiaosonggitee/blog/blob/master/courses/kernel/src/mptcp/mptcp-client.c)
- [`mptcp-server.c`](https://gitee.com/chenxiaosonggitee/blog/blob/master/courses/kernel/src/mptcp/mptcp-server.c)
- [`Makefile`](https://gitee.com/chenxiaosonggitee/blog/blob/master/courses/kernel/src/mptcp/Makefile.c)

## qemu虚拟机

qemu命令行启动虚拟机时，多个网卡的启动参数如下:
```sh
-net tap \
-net nic,model=virtio,macaddr=00:11:22:33:44:06 \
-net nic,model=virtio,macaddr=00:11:22:33:44:56 \
```

启动后，在虚拟机中用`ifconfig -a`可以看到另一个网卡`ens3`，debian使用以下命令:
```sh
echo -e "auto ens3\niface ens3 inet dhcp" >> /etc/network/interfaces
systemctl restart networking
```

qemu命令行启动虚拟机可以参考[《内核开发环境》](https://chenxiaosong.com/courses/kernel/dev-environment.html)。

## mptcp相关命令

编译内核时打开配置`CONFIG_MPTCP`、`CONFIG_MPTCP_IPV6`和`CONFIG_INET_MPTCP_DIAG`。

检查系统配置:
```sh
# 也就是 /proc/sys/net/mptcp/enabled 文件的值
sysctl net.mptcp.enabled # 检查
sysctl -w net.mptcp.enabled=1 # 如果上面命令检查没开，就执行这条命令
```

安装相关软件:
```sh
dnf install mptcpd -y
```

路径管理器:
```sh
/proc/sys/net/mptcp/pm_type # 0: 内核, 1: 用户空间
```

数据包调度器:
```sh
/proc/sys/net/mptcp/available_schedulers
/proc/sys/net/mptcp/scheduler
```

已经编译完的二进程程序使用mptcp:
```sh
mptcpize run <command>
mptcpize enable <systemd unit>
```

## 路径管理

我的环境如下:
```sh
server:
    ens2: 192.168.53.209
    ens3: 192.168.53.37
client:
    ens2: 192.168.53.210
    ens3: 192.168.53.38
```

server端操作:
```sh
ss -iaM # 查看socket状态
    # State   Recv-Q  Send-Q  Local Address:Port  Peer Address:Port
    # ESTAB   0       0       192.168.53.37:9734  192.168.53.1:36632
    # LISTEN  0       5             0.0.0.0:9734       0.0.0.0:*
ip mptcp endpoint show # 列出主机上活动 IP 地址的标识符
    # 192.168.53.37 id 1 subflow dev ens3
    # 192.168.53.209 id 2 subflow dev ens2
```

client端操作:
```sh
ss -iaM # 查看socket状态
    # State  Recv-Q  Send-Q  Local Address:Port    Peer Address:Port
    # ESTAB  0       0       192.168.53.210:36632  192.168.53.37:9734
ip mptcp endpoint show # 列出主机上活动 IP 地址的标识符
    # 192.168.53.38 id 1 subflow dev ens3
    # 192.168.53.210 id 2 subflow dev ens2
ip mptcp limits # 查看限制
    # add_addr_accepted 0 subflows 2
ip mptcp limits set subflow 2
ip mptcp limits set add_addr_accepted 2
# 删除和添加路径
ip mptcp endpoint del id 1 # ens3
ip mptcp endpoint del id 2 # 全给删除了
ip mptcp endpoint add 192.168.53.38 dev ens3 subflow
ip mptcp endpoint add 192.168.53.210 dev ens2 subflow
```

# 内核态socket

- [`kernel-socket-client.c`](https://gitee.com/chenxiaosonggitee/blog/blob/master/courses/kernel/src/kernel-socket/kernel-socket-client.c)
- [`kernel-socket-server.c`](https://gitee.com/chenxiaosonggitee/blog/blob/master/courses/kernel/src/kernel-socket/kernel-socket-server.c)
- [`Makefile`](https://gitee.com/chenxiaosonggitee/blog/blob/master/courses/kernel/src/kernel-socket/Makefile)

测试步骤:
```sh
make
insmod ./kernel-socket-server.ko
insmod ./kernel-socket-client.ko
```

#  疑问

- 不修改应用，使用BPF来修改socket类型，用mptcpize？
- 路径管理器，内核内和用户空间，区别？是能相互替代还是各有分工？
- 子路径是自动识别的还是要手动操作？

