# SMB和NetBIOS

NFS只能在Unix-Like系统间使用，CIFS（Common Internet File System）只能在Windows系统间使用，SMB（Server Message Block，中文翻译：服务器信息块）能够在Windows与Unix-Like之间使用。

- 1996年，微软提出将SMB改称为Common Internet File System。
- 2006年，Microsoft 随着 Windows Vista 的发布 引入了新的SMB版本 (SMB 2.0 or SMB2)。
- SMB 2.1, 随 Windows 7 和 Server 2008 R2 引入, 主要是通过引入新的机会锁机制来提升性能。
- SMB 3.0 (前称 SMB 2.2)在Windows 8 和 Windows Server 2012 中引入。

SMB基于NetBIOS（Network Basic Input/Output System），最初IBM提出的NetBIOS是无法跨路由的，使用NetBIOS over TCP/IP技术就可以跨路由使用SMB。

NetBIOS协议如下：

- [RFC1001, CONCEPTS AND METHODS](https://www.rfc-editor.org/rfc/rfc1001)
- [RFC1002, DETAILED SPECIFICATIONS](https://www.rfc-editor.org/rfc/rfc1002)

# SMB各版本比较

smb的协议文档有以下几个版本：

- [10/1/2020, [MS-CIFS]: Common Internet File System (CIFS) Protocol](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-cifs)
- [6/25/2021, [MS-SMB]: Server Message Block (SMB) Protocol](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-smb)
- [9/20/2023, [MS-SMB2]: Server Message Block (SMB) Protocol Versions 2 and 3](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-smb2)

# 社区

- nfs client maintainer: Steve French <sfrench@samba.org>，友好
- nfs server maintainer: Namjae Jeon <linkinjeon@kernel.org>，友好
- [nfs client maintainer的仓库](https://git.samba.org/sfrench/?p=sfrench/cifs-2.6.git;a=summary)
- [nfs server maintainer的仓库](https://github.com/namjaejeon/ksmbd)

获取supporter、reviewer、maintainer、open list、moderated list的邮箱:
```sh
./scripts/get_maintainer.pl fs/smb/server/
./scripts/get_maintainer.pl fs/smb/client/
./scripts/get_maintainer.pl fs/smb/common/
./scripts/get_maintainer.pl fs/smb/Makefile
./scripts/get_maintainer.pl fs/smb/Kconfig
./scripts/get_maintainer.pl fs/smb/
```

发送补丁:
```sh
git send-email --to=linkinjeon@kernel.org,sfrench@samba.org,stfrench@microsoft.com,pc@manguebit.com,sprasad@microsoft.com,dhowells@redhat.com,senozhatsky@chromium.org,tom@talpey.com,ronniesahlberg@gmail.com,bharathsm@microsoft.com --cc=chenxiaosong@kylinos.cn,chenxiaosong@chenxiaosong.com,linux-cifs@vger.kernel.org,linux-kernel@vger.kernel.org 00* # samba-technical@lists.samba.org要订阅才能发送成功
```