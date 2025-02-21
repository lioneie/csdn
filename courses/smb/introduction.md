[pdf文档翻译请查看百度网盘](https://chenxiaosong.com/baidunetdisk)。

# SMB和NetBIOS

NFS只能在Unix-Like系统间使用，CIFS（Common Internet File System）只能在Windows系统间使用，SMB（Server Message Block，中文翻译: 服务器信息块）能够在Windows与Unix-Like之间使用。

- 1996年，微软提出将SMB改称为Common Internet File System。
- 2006年，Microsoft 随着 Windows Vista 的发布 引入了新的SMB版本 (SMB 2.0 or SMB2)。
- SMB 2.1, 随 Windows 7 和 Server 2008 R2 引入, 主要是通过引入新的机会锁机制来提升性能。
- SMB 3.0 (前称 SMB 2.2)在Windows 8 和 Windows Server 2012 中引入。

SMB基于NetBIOS（Network Basic Input/Output System），最初IBM提出的NetBIOS是无法跨路由的，使用NetBIOS over TCP/IP技术就可以跨路由使用SMB。

NetBIOS协议如下:

- [RFC1001, CONCEPTS AND METHODS](https://www.rfc-editor.org/rfc/rfc1001)
- [RFC1002, DETAILED SPECIFICATIONS](https://www.rfc-editor.org/rfc/rfc1002)

# SMB各版本比较

smb的协议文档有以下几个版本:

- [10/1/2020, [MS-CIFS]: Common Internet File System (CIFS) Protocol](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-cifs)
- [6/25/2021, [MS-SMB]: Server Message Block (SMB) Protocol](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-smb)
- [9/20/2023, [MS-SMB2]: Server Message Block (SMB) Protocol Versions 2 and 3](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-smb2)
