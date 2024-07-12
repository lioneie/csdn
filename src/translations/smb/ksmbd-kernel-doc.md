本文档翻译自[Documentation/filesystems/smb/ksmbd.rst](https://github.com/torvalds/linux/blob/fdfd6dde4328635861db029f6fdb649e17350526/Documentation/filesystems/smb/ksmbd.rst)，翻译时文件的最新提交是`fdfd6dde4328635861db029f6fdb649e17350526 ksmbd: update feature status in documentation`，大部分借助于ChatGPT翻译，仅作为我个人的参考，如果你想查阅，建议看英文文档，因为我不确定我记录的中文翻译是否完整和正确。

# KSMBD - SMB3 内核服务器

KSMBD 是一个 Linux 内核服务器，实现在内核空间中的 SMB3 协议，用于通过网络共享文件。

## KSMBD 架构

性能相关的操作子集属于内核空间，而与性能无关的操作子集则属于用户空间。因此，历史上导致许多缓冲区溢出问题和危险安全漏洞的 DCE/RPC 管理以及用户账户管理是在用户空间中实现的，作为 ksmbd.mountd。与性能相关的文件操作（打开/读取/写入/关闭等）在内核空间（ksmbd）中进行。这也使得与 VFS 接口的集成更容易。

### ksmbd（内核守护进程）

当服务器守护进程启动时，它会在初始化时启动一个分叉线程（ksmbd/接口名称）并打开一个专用端口 445 来监听 SMB 请求。每当有新的客户端发出请求时，分叉线程将接受客户端连接，并为客户端与服务器之间的专用通信通道分叉一个新线程。这允许并行处理来自客户端的 SMB 请求（命令），以及允许新的客户端建立新连接。每个实例被命名为 ksmbd/1~n（端口号），以指示已连接的客户端。根据 SMB 请求类型，每个新线程可以决定将命令传递给用户空间（ksmbd.mountd），目前 DCE/RPC 命令被确定通过用户空间处理。为了进一步利用 Linux 内核，选择将命令作为工作项处理，并在 ksmbd-io kworker 线程的处理程序中执行。这允许处理程序的多路复用，因为内核会在负载增加时启动额外的工作线程，反之，如果负载减少，则销毁额外的工作线程。因此，在与客户端建立连接后，专用的 ksmbd/1..n（端口号）完全负责接收/解析 SMB 命令。每个接收到的命令都并行工作，即可以有多个客户端命令并行处理。接收每个命令后，为每个命令准备一个单独的内核工作项，这些工作项进一步排队由 ksmbd-io kworker 处理。因此，每个 SMB 工作项都排队到 kworker。这允许默认内核来管理负载共享，并通过并行处理客户端命令优化客户端性能。

### ksmbd.mountd（用户空间守护进程）

ksmbd.mountd 是一个用户空间进程，用于传输通过 ksmbd.adduser（用户空间实用程序的一部分）注册的用户账户和密码。此外，它允许将从 smb.conf 解析的共享信息参数传递给内核中的 ksmbd。在执行部分，它有一个守护进程持续运行，并使用 netlink 套接字连接到内核接口，等待请求（dcerpc 和共享/用户信息）。它处理从 NetShareEnum 和 NetServerGetInfo 中最重要的文件服务器 RPC 调用（至少几十个）。完整的 DCE/RPC 响应从用户空间准备并传递给客户端的相关内核线程。

## KSMBD Feature Status

请查看原网页。

## How to run

请查看原网页。

## Shutdown KSMBD

请查看原网页。

## How to turn debug print on

请查看原网页。
