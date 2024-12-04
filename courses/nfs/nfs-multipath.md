# openeuler nfs+

- [NFS多路径用户指南](https://docs.openeuler.org/zh/docs/23.03/docs/NfsMultipath/NFS%E5%A4%9A%E8%B7%AF%E5%BE%84.html)（[文档源码](https://gitee.com/openeuler/docs/tree/stable2-23.03/docs/zh/docs/NfsMultipath)）
- [pull request](https://gitee.com/src-openeuler/kernel/pulls?assignee_id=&author_id=&label_ids=&label_text=&milestone_id=&priority=&project_id=src-openeuler%2Fkernel&project_type=&scope=&search=enfs&single_label_id=&single_label_text=&sort=closed_at+desc&status=merged&target_project=&tester_id=)
- [补丁文件](https://gitee.com/src-openeuler/kernel/tree/openEuler-20.03-LTS-SP4)
- [support.huawei.com](https://support.huawei.com/supportindex/index)选择"企业技术支持"

可以使用脚本[`create-enfs-patchset.sh`](https://gitee.com/chenxiaosonggitee/blog/blob/master/courses/nfs/src/create-enfs-patchset.sh)生成完整的补丁文件。

编译前打开配置`CONFIG_ENFS=y`。

挂载选项解析流程:
```c
nfs_parse_mount_options
  enfs_check_mount_parse_info
    nfs_multipath_parse_options
      nfs_multipath_parse_ip_list
        nfs_multipath_parse_ip_list_inter
```

# 主线代码对多路径的支持

## `nconnect`挂载选项

[Multiple network connections for a single NFS mount.](https://patchwork.kernel.org/project/linux-nfs/cover/155917564898.3988.6096672032831115016.stgit@noble.brown/)

cover-letter翻译:
```
这个补丁集基于git://git.linux-nfs.org/projects/trondmy/nfs-2.6.git 的multipath_tcp分支中的补丁。

我想要在支持这项工作并希望它能够成功的声音中加入我的声音。
多年来，我们的客户/合作伙伴一直希望有这样的功能。在SLE15之前的SLES版本中，我们提供了一个“nosharetransport”挂载选项，以便可以从同一服务器挂载多个文件系统，每个文件系统都将获得自己的TCP连接。在SLE15中，我们正在使用这个“nconnect”功能，这更加方便。

合作伙伴向我们保证它提高了总体吞吐量，特别是在使用绑定网络时，但在Olga Kornievskaia提供一些具体的测试数据之前，我们还没有任何具体的数据 - 谢谢Olga！

正如我在其中一个补丁中所解释的那样，我理解的是并行硬件通常通过分发流而不是数据包来利用，这避免了在流中传递数据包时的无序传递。因此，需要多个流来利用并行硬件。

此补丁集的早期版本于2017年4月发布，Chuck提出了两个问题:
1/ mountstats仅报告一个挂载的一个xprt
2/ 会话建立需要在单个xprt上进行，因为在建立会话之前不能将其他xprt绑定到会话。
我已经添加了解决这些问题的补丁，并且还在debugfs信息中添加了额外的xprt。

我还对补丁进行了一些重新排列，合并了两个补丁，并删除了对TCP和NFSV4.x，x>=1的限制。讨论似乎表明这些限制是不需要的，我看不到需要。

在Trond的树中有一个与负载平衡代码有关的错误。
当xprt附加到客户端时，queuelen会递增。
一些请求（特别是BIND_CONN_TO_SESSION）传递给一个xprt，但在这种情况下，queuelen没有递增，而是递减。这会导致其变为“负值”，从而产生混乱。

我想最后的三个补丁（Allow multiple connection）是否可以合并为一个单独的补丁。

我对自动确定最佳连接数没有进行深入思考，但我怀疑它可能无法在透明且可靠的情况下完成。当添加连接可以提高吞吐量时，几乎肯定是一件好事。当添加连接不会提高吞吐量时，其影响就不那么明显了。
我认为协议增强可以由服务器建议一个上限并在客户端注意到传输队列时逐渐增加到该上限的情况下，可能是我们能做的最好的事情。但在实施这个功能之前，我们需要更多的经验。

非常欢迎您的评论。我希望看到这个或类似的东西被合并。

谢谢，
NeilBrown
```

1/9 21f0ffaff510 SUNRPC: Add basic load balancing to the transport switch

2/9 612b41f808a9 SUNRPC: Allow creation of RPC clients with multiple connections

3/9 5a0c257f8e0f NFS: send state management on a single connection.

4/9 10db56917bcb SUNRPC: enhance rpc_clnt_show_stats() to report on all xprts.

```shell
cat /proc/self/mountstats | less
```

5/9 2f34b8bfae19 SUNRPC: add links for all client xprts to debugfs

6/9 28cc5cd8c68f NFS: Add a mount option to specify number of TCP connections to use

7/9 6619079d0540 NFSv4: Allow multiple connections to NFSv4.x (x>0) servers

8/9 bb71e4a5d7eb pNFS: Allow multiple connections to the DS

9/9 53c326307156 NFS: Allow multiple connections to a NFSv2 or NFSv3 server

## `max_connect`挂载选项

[do not collapse trunkable transports](https://patchwork.kernel.org/project/linux-nfs/cover/20210827183719.41057-1-olga.kornievskaia@gmail.com/)

cover-letter翻译:
```
这个补丁系列的目标是允许新的挂载（即nfsv4.1+支持会话干线的服务器）到相同的服务器，但到不同的网络地址使用与这些挂载相关联的连接，同时仍然使用相同的客户端结构。

一个新的挂载选项，"max_connect"，控制可以添加到现有客户端的额外传输的数量，最多可以有16个这样的传输。
```

1/5 3a3f976639f2 SUNRPC keep track of number of transports to unique addresses

2/5 df205d0a8ea1 SUNRPC add xps_nunique_destaddr_xprts to xprt_switch_info in sysfs

3/5 7e134205f629 NFSv4 introduce max_connect mount options

4/5 dc48e0abee24 SUNRPC enforce creation of no more than max_connect xprts

5/5 2a7a451a9084 NFSv4.1 add network transport when session trunking is detected

## 代码流程

```sh
mount -t nfs -o vers=4.1,nconnect=4,max_connect=4 192.168.122.76:s_test /mnt
mount -t nfs -o vers=4.1,nconnect=4,max_connect=4 localhost:s_test /mnt2
```

```c
mount
  do_mount
    path_mount
      do_new_mount
        parse_monolithic_mount_data
          nfs_fs_context_parse_monolithic
            nfs23_parse_monolithic
              generic_parse_monolithic
                vfs_parse_fs_string
                  vfs_parse_fs_param
                    nfs_fs_context_parse_param
                      ctx->nfs_server.nconnect = result.uint_32
                      ctx->nfs_server.max_connect = result.uint_32
        vfs_get_tree
          nfs_get_tree
            nfs4_try_get_tree
              nfs4_create_server
                nfs4_init_server
                  nfs4_set_client
                    nfs_get_client
                      nfs4_alloc_client
                        nfs_alloc_client
                          clp->cl_nconnect = cl_init->nconnect
                          clp->cl_max_connect // at least 1
                        nfs_create_rpc_client
                          .nconnect = clp->cl_nconnect
                          rpc_create
                            rpc_clnt_add_xprt // for(i = 0; i < args->nconnect - 1; i++)
                          clnt->cl_max_connect = clp->cl_max_connect
                      nfs4_init_client
                        nfs4_add_trunk // 挂载两个不同ip时
                          rpc_clnt_add_xprt
                            rpc_clnt_test_and_add_xprt
```
