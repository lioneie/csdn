mptcp的maintainer之一Geliang Tang <tanggeliang@kylinos.cn>是我们麒麟软件的，最近在调研mptcp和smb结合的可能性，顺便记录一下。

- [mptcp.dev](https://www.mptcp.dev/)
- [mptcp_net-next/wiki](https://github.com/multipath-tcp/mptcp_net-next/wiki)
- [RFC 8684](https://www.rfc-editor.org/rfc/rfc8684.html), [pdf文档翻译请查看百度网盘](https://chenxiaosong.com/baidunetdisk)
- [邮件列表](https://lore.kernel.org/mptcp/)
- [patchwork](https://patchwork.kernel.org/project/mptcp/list/)
- [mptcpd](https://github.com/multipath-tcp/mptcpd)
- [tools/testing/selftests/net/mptcp](https://github.com/torvalds/linux/tree/master/tools/testing/selftests/net/mptcp)
- [mptcp-upstream-virtme-docker](https://github.com/multipath-tcp/mptcp-upstream-virtme-docker)

# 使用

[参考网页](https://www.mptcp.dev/setup.html)

打开内核配置`CONFIG_MPTCP`、`CONFIG_MPTCP_IPV6`和`CONFIG_INET_MPTCP_DIAG`。

检查系统配置:
```sh
sysctl net.mptcp.enabled # 检查
sysctl -w net.mptcp.enabled=1 # 如果上面命令检查没开，就执行这条命令
```

安装相关软件:
```sh
dnf install mptcpd -y
```

# 内核态socket

- [`kernel-socket-client.c`](https://gitee.com/chenxiaosonggitee/blog/blob/master/courses/kernel/src/kernel-socket/kernel-socket-client.c)
- [`kernel-socket-server.c`](https://gitee.com/chenxiaosonggitee/blog/blob/master/courses/kernel/src/kernel-socket/kernel-socket-server.c)
- [`Makefile`](https://gitee.com/chenxiaosonggitee/blog/blob/master/courses/kernel/src/kernel-socket/Makefile)

#  疑问

- 不修改应用，使用BPF来修改socket类型，用mptcpize？

