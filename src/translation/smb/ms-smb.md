既然在深入nfs的知识，那就干脆把smb相关的知识一起对比着学习一下，本文翻译自[6/25/2021, [MS-SMB]: Server Message Block (SMB) Protocol](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-smb)，大部分借助于ChatGPT翻译，仅作为我个人的参考，如果你想查阅，建议看英文文档，因为我不确定我记录的中文翻译是否完整和正确。

持续更新中。。。

# 引言

服务器消息块（SMB）版本1.0协议定义了对通用互联网文件系统（CIFS）协议的扩展，该协议在[MS-CIFS]中进行了规定。除非在本文档中有明确扩展或覆盖，否则所有在[MS-CIFS]中为Windows NT操作系统客户端和服务器描述的规范和行为都适用于本文档中涉及的Windows客户端和服务器实现。本文档中涉及的Windows客户端和服务器实现的列表在第6节中提供。

除非另有说明，本文档仅提供相对于[MS-CIFS]规范的CIFS协议的扩展。扩展后的CIFS协议称为服务器消息块（SMB）版本1.0协议。要创建服务器消息块（SMB）版本1.0协议的完整实现，需要同时使用本文档和[MS-CIFS]。

本文档还定义了Windows相对于SMB扩展规范中描述的可选行为的行为。

本规范的第1.5、1.8、1.9、2和3节是规范性的。本规范中的所有其他部分和示例都是信息性的。

## 术语表

[查阅的时候再翻译](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-smb/c7d64f17-1ab6-4151-b9e8-f15813235c83)

## 参考资料

指向Microsoft开放规范库中文档的链接将指向所引用文档的最新发布版本中的正确部分。然而，由于库中的单个文档不会同时更新，文档中的章节编号可能不匹配。您可以通过查看勘误表来确认正确的章节编号。

### 规范性引用

我们经常对规范性引用进行调查，以确保它们持续可用。如果您在查找规范性引用时遇到任何问题，请联系dochelp@microsoft.com。我们将协助您查找相关信息。

[请查看网页](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-smb/2d91bdca-f941-428a-9f89-bcabebab4dce)

### 信息性引用

[请查看网页](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-smb/f8178eac-d7d6-476e-9d97-cf61125668a0)

## 概述

客户端系统使用通用互联网文件系统（CIFS）协议从服务器系统请求网络上的文件和打印服务。CIFS是一种有状态的协议，在其中客户端与服务器建立会话，并利用该会话发出各种请求，以访问文件、打印机和诸如命名管道之类的进程间通信（IPC）机制。CIFS引入状态以维护身份验证上下文、加密操作、文件语义（如锁定）和类似功能。有关CIFS协议功能的详细概述，请参阅[MS-CIFS]第2节。

Server Message Block（SMB）版本1.0协议通过提供额外的安全性、文件和磁盘管理支持，扩展了CIFS协议。这些扩展不改变CIFS协议的基本消息排序，但引入了新的标志、扩展请求和响应以及新的信息级别。所有这些扩展都遵循请求/响应模式，其中客户端启动所有请求。基础协议允许有一个例外情况，即oplock breaks，如[MS-CIFS]第3.2.5.42节所述。

本文档定义了对CIFS的SMB版本1.0协议扩展，提供对以下功能的支持:
```
新的身份验证方法，包括Kerberos。已增强Negotiate和Session Setup命令，以携带不透明的安全令牌，以支持与通用安全服务（GSS）兼容的机制。

枚举和访问文件的先前版本。使用文件系统控制（FSCTL）的新子命令允许客户端查询服务器是否存在文件的旧版本。如果服务器实现了带版本的文件系统，则可以将其暴露给客户端。

客户端请求在不要求客户端读取数据然后将数据写回服务器的情况下，在文件之间执行服务器端数据移动操作。如[MS-CIFS]所述，要在服务器上复制文件，需要客户端从服务器读取所有数据，然后将数据写回服务器。SMB版本1.0协议引入了一种在服务器上完全执行此类操作的方法，而不会消耗网络资源。

使用Direct TCP进行SMB传输的SMB连接。CIFS协议支持使用NBT进行连接，如[MS-CIFS]第2.1.1.2节所述。SMB版本1.0协议包括通过TCP直接连接的方法（请参阅[RFC793]），而不涉及NetBIOS（请参阅[RFC1001]和[RFC1002]）。关于NetBIOS的信息在[NETBEUI]中指定。

支持在共享连接和文件打开操作的响应中检索扩展信息。SMB版本1.0协议中的某些服务器功能和指标（例如需要客户端缓存共享内容）是通过对现有命令的这些扩展返回给客户端的。

用于设置和查询用户配额的额外SMB命令。只要服务器支持配额，客户端就可以约束用户文件占用的文件系统容量。
```

其中许多功能都通过对SMB_COM_NEGOTIATE（第2.2.4.5节）和SMB_COM_SESSION_SETUP_ANDX（第2.2.4.6节）命令请求和响应的增强来公开。

# todo: https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-smb/592d0cbe-41d0-4b8e-8bb9-a60edd85e5e8
