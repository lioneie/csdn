本文档翻译自`Documentation/admin-guide/cifs/todo.rst <https://github.com/torvalds/linux/blob/master/Documentation/admin-guide/cifs/todo.rst>`_，翻译时文件的最新提交是``cfb7a13399be2234052a5bc480d166cd33047b0c cifs: update known bugs mentioned in kernel docs for cifs``，大部分借助于ChatGPT翻译，仅作为我个人的参考，如果你想查阅，建议看英文文档，因为我不确定我记录的中文翻译是否完整和正确。

截至 6.7 内核。请参阅 https://wiki.samba.org/index.php/LinuxCIFSKernel
获取每个版本添加的功能列表

缺失功能的部分列表
==================

欢迎贡献。该模块有很多可见且重要的贡献机会。以下是已知问题和缺失功能的部分列表：

a) SMB3（和 SMB3.1.1）缺少的可选功能：
   多通道性能优化、算法通道选择、
   目录租约优化、
   支持更快的数据包签名（GMAC），
   支持网络上的压缩，
   T10 卸载复制即 "ODX"（目前唯一支持的两种服务器端复制机制是复制块和 "Duplicate Extents" ioctl）

b) 更优化的稀疏文件支持的合并和错误处理，
   也许添加新的可选 SMB3.1.1 fsctl 以使范围折叠和范围插入更具原子性

c) 支持 SMB3.1.1 通过 QUIC（也许还有其他基于套接字的协议如 SCTP）

d) 配额支持（需要微小的内核更改，因为否则配额调用将无法传递到网络文件系统或无设备文件系统）。

e) 可以优化更多用例以使用 "合并"（例如 open/query/close 和 open/setinfo/close）以减少到服务器的往返次数并提高性能。使用合并已经改进了各种情况（stat、statfs、create、unlink、mkdir、xattrs），但还有更多可以做的。此外，我们可以通过使用延迟关闭（使用句柄缓存租约）并更好地使用文件句柄上的引用计数器显著减少冗余打开操作。

f) 完成 inotify 支持，使 kde 和 gnome 文件列表窗口能够自动刷新（Asser 部分完成）。需要微小的内核 vfs 更改以支持从文件中移除 D_NOTIFY。

g) 添加 GUI 工具以配置 /proc/fs/cifs 设置并显示 CIFS 统计信息（已开始）

h) 实现安全和可信类别的 xattrs 支持（需要微小的协议扩展）以更好地支持 SELINUX

i) 添加对树连接上下文（见 MS-SMB2）的支持，这是 SMB3.1.1 协议的新功能（对虚拟化可能特别有用）。

j) 创建 UID 映射设施，以便服务器 UID 可以按挂载或按服务器映射到客户端 UID 或没有映射时映射到 nobody。还可以更好地与 winbind 集成以解析 SID 所有者

k) 添加工具以利用更多 smb3 特定的 ioctl 和功能
   （passthrough ioctl/fsctl 现在已在 cifs.ko 中实现，允许直接从用户空间发送各种 SMB3 fsctl 和查询信息以及设置信息调用）
   添加工具以使从工具设置各种非 POSIX 元数据属性更容易（例如扩展 smb-info 工具中已完成的内容）。

l) 加密文件支持（目前报告了服务器上文件加密的属性，但不支持更改属性）。

m) 改进统计信息收集工具（也许与 nfsometer 集成？）以扩展并使目前在 /proc/fs/cifs/Stats 中的工具更易于使用

n) 添加对基于声明的 ACL 支持 ("DAC")

o) 挂载助手 GUI（简化挂载时的各种配置选项）

p) 扩展对见证协议的支持，以允许通知共享移动和服务器网络适配器更改。目前，Linux 客户端仅支持见证协议通知服务器移动。

q) 允许 mount.cifs 在报告方言或不支持的功能错误时更加详细。由于新挂载 API 的实现，这现在变得更容易。

r) 更新 cifs 文档和用户指南。

s) 通过运行更广泛的 xfstests 集来发现的错误。

t) 将 cifs 和 smb3 支持分离为单独的模块，以便在不需要的环境中禁用传统的（且不太安全的）CIFS 方言，并简化代码。

v) 对 SMB3.1.1 POSIX 扩展的进一步测试

w) 支持 Mac SMB3.1.1 扩展，以改进与 Apple 服务器的互操作性

x) 支持其他身份验证选项（例如 IAKERB、点对点 Kerberos、SCRAM 以及现有服务器支持的其他选项）

y) 改进跟踪，添加更多 eBPF 跟踪点，改进性能分析脚本

已知错误
========

请参阅 https://bugzilla.samba.org - 搜索产品 "CifsVFS" 获取当前的错误列表。 也请检查 http://bugzilla.kernel.org（产品 = 文件系统，组件 = CIFS）以及 xfstest 结果，例如 https://wiki.samba.org/index.php/Xfstest-results-smb3

杂项测试待办
==================
1) 针对各种服务器类型检查最大路径名和最大路径名组件。尝试嵌套符号链接（8 层深）。在 stat -f 信息中返回最大路径名

2) 改进 xfstest 的 cifs/smb3 支持，并在需要时调整 xfstests 以更好地测试 cifs/smb3

3) 使用 iozone 和类似工具进行更多的性能测试和优化 - 可以通过并行化顺序写入以及在禁用签名时请求更大的读取大小（大于协商大小）并向现代服务器发送更大的写入大小来进行一些简单的更改。

4) 更全面地测试不常见的服务器

5) 继续扩展 smb3 "buildbot"，目前它对 Windows、Samba 和 Azure 进行自动化 xfstesting - 添加额外的测试，并允许 buildbot 更快地执行测试。buildbot 的 URL 是：http://smb3-test-rhel-75.southcentralus.cloudapp.azure.com

6) 解决各种 coverity 警告（大多数本质上不是错误，但解决的警告越多，将来静态分析器指出的真正问题就越容易被发现）。
