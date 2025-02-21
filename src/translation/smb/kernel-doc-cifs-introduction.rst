本文档翻译自`Documentation/admin-guide/cifs/introduction.rst <https://github.com/torvalds/linux/blob/master/Documentation/admin-guide/cifs/introduction.rst>`_，翻译时文件的最新提交是``b4331b9884f12daf2a8dc595200b1fa5c57cf4a6 doc: Fix typo in admin-guide/cifs/introduction.rst``，大部分借助于ChatGPT翻译，仅作为我个人的参考，如果你想查阅，建议看英文文档，因为我不确定我记录的中文翻译是否完整和正确。

这是用于 SMB3 NAS 协议以及较旧方言（如 CIFS 协议）的客户端 VFS 模块，CIFS 是 Server Message Block（SMB）协议的继任者，SMB 是大多数早期 PC 操作系统的本地文件共享机制。改进后的 CIFS 版本现在称为 SMB2 和 SMB3。由于安全原因，强烈建议使用 SMB3（及更高版本，包括最新方言 SMB3.1.1）而不是使用较旧的方言如 CIFS。CIFS VFS 模块支持所有现代方言，包括最新的 SMB3.1.1。SMB3 协议由所有主要的文件服务器支持和实现，例如 Windows（包括 Windows 2019 Server），以及 Samba（它为 Linux 和许多其他操作系统提供了出色的 CIFS/SMB2/SMB3 服务器支持和工具）。Apple 系统也很好地支持 SMB3，大多数网络附加存储供应商也如此，因此这个网络文件系统客户端可以挂载到各种各样的系统上。它还支持挂载到云（例如 Microsoft Azure），包括必要的安全功能。

该模块的目的是为符合 SMB3 标准的服务器提供最先进的网络文件系统功能，包括先进的安全功能、优秀的并行化高性能 i/o、更好的 POSIX 兼容性、用户级的安全会话建立、加密、高性能的安全分布式缓存（租约/文件锁）、可选的数据包签名、大文件、Unicode 支持及其他国际化改进。由于 Samba 服务器和此文件系统客户端都支持 CIFS Unix 扩展，且 Linux 客户端还支持 SMB3 POSIX 扩展，因此在某些 Linux 到 Linux 环境中，这个组合可以作为其他网络和集群文件系统的合理替代方案，不仅限于 Linux 到 Windows（或 Linux 到 Mac）环境。

此文件系统有一个挂载工具（mount.cifs）和各种用户空间工具（包括 smbinfo 和 setcifsacl），可以从以下地址获取：

    https://git.samba.org/?p=cifs-utils.git

或

    git://git.samba.org/cifs-utils.git

mount.cifs 应安装在与其他挂载助手相同的目录中。

有关该模块的更多信息，请参见项目的 wiki 页面：

    https://wiki.samba.org/index.php/LinuxCIFS

和

    https://wiki.samba.org/index.php/LinuxCIFS_utils
