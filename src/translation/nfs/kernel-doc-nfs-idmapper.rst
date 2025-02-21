本文档翻译自`Documentation/admin-guide/nfs/nfs-idmapper.rst <https://github.com/torvalds/linux/blob/master/Documentation/admin-guide/nfs/nfs-idmapper.rst>`_，翻译时文件的最新提交是`fbdcd0b8e56492dd85bd8d08f15a14334bb59259 Documentation: nfs: idmapper: convert to ReST <https://github.com/torvalds/linux/blob/fbdcd0b8e56492dd85bd8d08f15a14334bb59259/Documentation/admin-guide/nfs/nfs-idmapper.rst>`_，翻译时chatgpt不能用了，所以只能用文心一言，仅作为我个人的参考，如果你想查阅，建议看英文文档，因为我不确定我记录的中文翻译是否完整和正确。

  注: ``nfs.idmap``可能是以前系统的程序名中间有个点号，也可能是写错，已改正为``nfsidmap``。

=============
NFS ID Mapper
=============

ID映射器（Id mapper）被NFS（网络文件系统）用来将用户和组ID翻译成名称，以及将用户和组名称翻译成ID。这一转换过程的一部分涉及向用户空间发起上调用来请求相关信息。NFS有两种方式可以获得这些信息：调用/sbin/request-key或调用rpc.idmap守护进程。

NFS会首先尝试调用/sbin/request-key。如果调用成功，结果将被缓存到通用的request-key缓存中。这个调用仅在/etc/request-key.conf没有为id_resolver键类型进行配置时才会失败，如果你希望使用request-key方法，请参见下面的“配置”部分。

如果调用/sbin/request-key失败（即/etc/request-key.conf没有为id_resolver键类型进行配置），那么ID映射器将向遗留的rpc.idmap守护进程请求ID映射。这个结果将被存储在NFS自定义的ID映射缓存中。

Configuring
===========

  陈孝松注: 最新的用法请查看`《nfs idmap相关man手册》 <https://chenxiaosong.com/src/translation/nfs/man-nfsidmap.html>`_，这里的写的已经和最新的用法不一样了。

为了让/sbin/request-key能够指导上调用，需要修改/etc/request-key.conf文件。应该添加以下行：

``#OP	TYPE	DESCRIPTION	CALLOUT INFO	PROGRAM ARG1 ARG2 ARG3 ...``

``#======	=======	===============	===============	===============================``

``create	id_resolver	*	*		/usr/sbin/nfsidmap %k %d 600``

这将把所有id_resolver请求指向程序/usr/sbin/nfsidmap。最后一个参数600定义了密钥在未来多少秒后过期。这个参数对于/usr/sbin/nfsidmap是可选的。当没有指定超时时间时，nfsidmap将默认为600秒。

ID映射器使用的密钥描述为::

	  uid:  Find the UID for the given user
	  gid:  Find the GID for the given group
	 user:  Find the user  name for the given UID
	group:  Find the group name for the given GID

你可以单独处理这些请求中的任何一个，而不是使用通用的上调用程序。如果你想要使用自己的程序来查找用户ID（uid），那么你需要编辑你的request-key.conf文件，使其看起来像这样：

``#OP	TYPE	DESCRIPTION	CALLOUT INFO	PROGRAM ARG1 ARG2 ARG3 ...``

``#======	=======	===============	===============	===============================``

``create	id_resolver	uid:*	*		/some/other/program %k %d 600``

``create	id_resolver	*	*		/usr/sbin/nfsidmap %k %d 600``

请注意，新行被添加在通用程序对应行的上方。request-key会找到第一个匹配的行和对应的程序。在这种情况下，/some/other/program将处理所有用户ID（uid）的查找，而/usr/sbin/nfsidmap将处理组ID（gid）、用户名和组名的查找。

有关request-key功能的更多信息，请参阅Documentation/security/keys/request-key.rst文件。

nfsidmap
=========

nfsidmap 是被设计为被 request-key 调用的，而不应该“手动”运行。这个程序接受两个参数：一个序列化的密钥和一个密钥描述。序列化的密钥首先被转换成 key_serial_t 类型，然后作为参数传递给 keyctl_instantiate（这两个都是 keyutils.h 的一部分）。

实际的查找操作是由在 nfsidmap.h 中找到的函数执行的。nfsidmap 通过查看描述字符串的第一部分来确定要调用的正确函数。例如，一个用户ID（uid）查找的描述将显示为 "uid:user@domain"。

如果密钥被实例化，nfsidmap 将返回0；否则返回非0值。