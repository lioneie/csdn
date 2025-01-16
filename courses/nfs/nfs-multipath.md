<!--
疑问:

- 在进行文件操作时 eNFS 将 IO 通过 RoundRobin 方式负载均衡到多条链路上以提升性能（当前版本负载均衡只支持 NFS V3）
-->

# openeuler nfs+的使用

- [eNFS 使用指南](https://docs.openeuler.org/zh/docs/20.03_LTS_SP4/docs/eNFS/enfs%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97.html)（[文档源码](https://gitee.com/openeuler/docs/blob/stable2-20.03_LTS_SP4/docs/zh/docs/eNFS/enfs%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97.md)）
- [openeuler23.03 NFS多路径用户指南](https://docs.openeuler.org/zh/docs/23.03/docs/NfsMultipath/NFS%E5%A4%9A%E8%B7%AF%E5%BE%84.html)（[文档源码](https://gitee.com/openeuler/docs/tree/stable2-23.03/docs/zh/docs/NfsMultipath)），瞎搞的，这个版本根本没有多路径功能
- [src-openeuler合入的pull request](https://gitee.com/src-openeuler/kernel/pulls?assignee_id=&author_id=&label_ids=&label_text=&milestone_id=&priority=&project_id=src-openeuler%2Fkernel&project_type=&scope=&search=enfs&single_label_id=&single_label_text=&sort=closed_at+desc&status=merged&target_project=&tester_id=)
- [openeuler没合入的pull request](https://gitee.com/openeuler/kernel/pulls?assignee_id=&author_id=&label_ids=&label_text=&milestone_id=&priority=&project_id=openeuler%2Fkernel&project_type=&scope=&search=enfs&single_label_id=&single_label_text=&sort=&status=all&target_project=&tester_id=)
- [补丁文件](https://gitee.com/src-openeuler/kernel/tree/openEuler-20.03-LTS-SP4)
- [support.huawei.com](https://support.huawei.com/supportindex/index)选择"企业技术支持"

可以使用脚本[`create-enfs-patchset.sh`](https://gitee.com/chenxiaosonggitee/blog/blob/master/courses/nfs/src/create-enfs-patchset.sh)生成完整的补丁文件，[再打上我修改的补丁](https://gitee.com/chenxiaosonggitee/tmp/tree/master/nfs/enfs)。切换到`openEuler-1.0-LTS`分支，编译前打开配置`CONFIG_ENFS`，可能还要关闭配置`CONFIG_NET_VENDOR_NETRONOME`。

最方便的就是在virt-manager虚拟机中测试，在图形界面上添加多个网卡。

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

qemu命令行启动虚拟机可以参考[《内核开发环境》](https://chenxiaosong.com/courses/kernel/kernel-dev-environment.html)。

挂载:
```sh
modprobe enfs # 经过我的修改已经能自动加载了
mount -t nfs -o localaddrs=192.168.53.40~192.168.53.53,remoteaddrs=192.168.53.215~192.168.53.216 192.168.53.216:/s_test /mnt/
```

如果没有创建`/etc/enfs/config.ini`，会报错`failed to open file:/etc/enfs/config.ini err:-2`，配置文件请参考[eNFS 使用指南](https://docs.openeuler.org/zh/docs/20.03_LTS_SP4/docs/eNFS/enfs%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97.html)。只需要在nfs client端支持enfs就可以，`/etc/enfs/config.ini`默认配置如下:
```sh
path_detect_interval=10 # 路径连通探测周期，单位 ： 秒
path_detect_timeout=10 # 路径连通探测消息越野时间，单位 ： 秒
multipath_timeout=0 # 选择其他路径达到的文件操作的超时阈值，0表示使用 mount 命令指定的 timeo 参数，不使用 eNFS 模块的配置，单位 ： 秒。
multipath_disable=0 # 启用 eNFS 特性
```

除了`mount`命令查看之外，还可以用以下方式:
```sh
cat /proc/enfs/192.168.53.216_0/path
cat /proc/enfs/192.168.53.216_0/stat
```

# 我修改的nfs+补丁

[我修改的补丁请查看这里](https://gitee.com/chenxiaosonggitee/tmp/tree/master/nfs/enfs)。

```c
// struct enfs_adapter_ops->owner 的引用计数参考
struct nfs_client
  struct nfs_subversion * cl_nfs_mod
    struct module *owner

// nfs_multipath_router_get 修改参考
get_nfs_version
  request_module
```

# nfs+代码分析

[pull request](https://gitee.com/src-openeuler/kernel/pulls?assignee_id=&author_id=&label_ids=&label_text=&milestone_id=&priority=&project_id=src-openeuler%2Fkernel&project_type=&scope=&search=enfs&single_label_id=&single_label_text=&sort=closed_at+desc&status=merged&target_project=&tester_id=)和[补丁文件](https://gitee.com/src-openeuler/kernel/tree/openEuler-20.03-LTS-SP4)。

## [`1/6 nfs: add api to support enfs registe and handle mount option`](https://gitee.com/src-openeuler/kernel/blob/openEuler-20.03-LTS-SP4/0001-nfs_add_api_to_support_enfs_registe_and_handle_mount_option.patch)

```
At the NFS layer, the eNFS registration function is called back when
the mount command parses parameters. The eNFS parses and saves the IP
address list entered by users.
```

这个补丁实现了nfs层的enfs的接口，下面的代码流程是我看代码时的笔记:
```c
struct nfs_client_initdata
  void *enfs_option; /* struct multipath_mount_options * */

struct nfs_parsed_mount_data
  void *enfs_option; /* struct multipath_mount_options * */ 

struct nfs_client
  /* multi path private structure (struct multipath_client_info *) */
  void *cl_multipath_data;

struct enfs_adapter_ops

nfs4_create_server
  nfs4_init_server
    enfs_option = data->enfs_option
    nfs4_set_client
      .enfs_option = enfs_option,
      nfs_get_client
        nfs_match_client
          nfs_multipath_client_match
        nfs4_alloc_client
          nfs_create_multi_path_client
            nfs_multipath_router_get
              request_module("enfs")
              try_module_get(ops->owner) // 引用计数直到umount时才能释放
            nfs_multipath_client_info_init
          nfs_create_rpc_client
            .multipath_option = cl_init->enfs_option,

nfs4_free_client
  nfs_free_client
    nfs_free_multi_path_client
      nfs_multipath_router_put // 释放nfs_create_multi_path_client中一直持有的引用计数

nfs_parse_mount_options
  enfs_check_mount_parse_info
    enfs_parse_mount_options
      nfs_multipath_parse_options // parse_mount_options
        nfs_multipath_parse_ip_list
          nfs_multipath_parse_ip_list_inter
```

## [`2/6 sunrpc: add api to support enfs registe and create multipath then dispatch IO`](https://gitee.com/src-openeuler/kernel/blob/openEuler-20.03-LTS-SP4/0002-sunrpc_add_api_to_support_enfs_registe_and_create_multipath_then_dispatch_IO.patch)

```
At the sunrpc layer, the eNFS registration function is called back When
the NFS uses sunrpc to create rpc_clnt, the eNFS combines the IP address
list entered for mount to generate multiple xprts. When the I/O times
out, the callback function of the eNFS is called back so that the eNFS
switches to an available link for retry.
```

```c
// The high-level client handle
struct rpc_clnt
  bool cl_enfs

struct rpc_create_args
  // 这里使用了nfs层的结构体，耦合了
  void *multipath_option // struct multipath_mount_options

struct rpc_task
  unsigned long           tk_major_timeo

// RPC task flags
#define RPC_TASK_FIXED  0x0004          /* detect xprt status task */

struct rpc_multipath_ops

struct rpc_xprt
  atomic_long_t   queuelen;
  void *multipath_context;

struct rpc_xprt_switch
  unsigned int            xps_nactive;
  atomic_long_t           xps_queuelen;
  unsigned long           xps_tmp_time;

// 挂载
nfs4_alloc_client
  nfs_create_rpc_client
    rpc_create
      rpc_create_xprt
        rpc_multipath_ops_create_clnt

// 卸载
rpc_shutdown_client
  rpc_multipath_ops_releas_clnt

rpc_task_release_client / nfs4_async_handle_exception
  rpc_task_release_transport // 这里改成和主线一样
    rpc_task_release_xprt // 从主线搬运过来的

rpc_task_set_transport
  rpc_task_get_next_xprt // 从主线搬运过来的
    rpc_task_get_xprt // 从主线搬运过来的

call_reserveresult
  rpc_multipath_ops_task_need_call_start_again

call_transmit
  rpc_multipath_ops_prepare_transmit

call_timeout
  rpc_multipath_ops_failover_handle

rpc_clnt_add_xprt
  rpc_xprt_switch_set_roundrobin

rpc_init_task
  rpc_task_get_xprt // 和主线一样
```

## [`3/6 nfs: add enfs module for nfs mount option`](https://gitee.com/src-openeuler/kernel/blob/openEuler-20.03-LTS-SP4/0003-add_enfs_module_for_nfs_mount_option.patch)

```
The eNFS module registers the interface for parsing the mount command.
During the mount process, the NFS invokes the eNFS interface to enable
the eNFS to parse the mounting parameters of UltraPath. The eNFS module
saves the mounting parameters to the context of nfs_client.
```

## [`4/6 nfs: add enfs module for sunrpc multipatch`](https://gitee.com/src-openeuler/kernel/blob/openEuler-20.03-LTS-SP4/0004-add_enfs_module_for_sunrpc_multipatch.patch)

```
When the NFS invokes the SunRPC to create rpc_clnt, the eNFS interface
is called back. The eNFS creates multiple xprts based on the output IP
address list. When NFS V3 I/Os are delivered, eNFS distributes I/Os to
available links based on the link status, improving performance through
load balancing.
```

## [`5/6 nfs: add enfs module for sunrpc failover and configure`](https://gitee.com/src-openeuler/kernel/blob/openEuler-20.03-LTS-SP4/0005-add_enfs_module_for_sunrpc_failover_and_configure.patch)

```
When sending I/Os from the SunRPC module to the NFS server times out,
the SunRPC module calls back the eNFS module to reselect a link. The
eNFS module distributes I/Os to other available links, preventing
service interruption caused by a single link failure.
```

## [`6/6 nfs, sunrpc: add enfs compile option`](https://gitee.com/src-openeuler/kernel/blob/openEuler-20.03-LTS-SP4/0006-add_enfs_compile_option.patch)

```
The eNFS compilation option and makefile are added. By default, the eNFS
compilation is performed.
```

# 主线`nconnect`挂载选项

[Multiple network connections for a single NFS mount.](https://patchwork.kernel.org/project/linux-nfs/cover/155917564898.3988.6096672032831115016.stgit@noble.brown/)

cover-letter翻译:
```
这组补丁基于 git://git.linux-nfs.org/projects/trondmy/nfs-2.6.git 中的 multipath_tcp 分支。

我想为这项工作表达支持，并希望它能够被合并。多年来，我们有客户/合作伙伴一直在希望得到这种功能。在 SLES 15 之前的版本中，我们提供了一个名为“nosharetransport”的挂载选项，以便从同一服务器挂载多个文件系统，每个文件系统都会得到一个独立的 TCP 连接。在 SLE15 中，我们使用了这个‘nconnect’功能，这要更好得多。

合作伙伴向我们保证，这在总体吞吐量上有所提高，特别是在绑定网络中，但我们直到 Olga Kornievskaia 提供了一些具体的测试数据之后才得到了可靠的数据，谢谢 Olga！

根据我的理解，正如我在某个补丁中解释的那样，通常通过分配流而不是分配数据包来利用并行硬件。这样可以避免流中数据包的乱序交付。因此，需要多个流来有效利用并行硬件。

这组补丁的早期版本在 2017 年 4 月发布，Chuck 提出了两个问题：

1. mountstats 只报告每个挂载的一个 xprt
2. 会话建立必须在单个 xprt 上进行，因为在会话建立之前，无法将其他 xprt 绑定到会话。 我已添加补丁来解决这些问题，并且还在 debugfs 信息中添加了额外的 xprt。

此外，我还重新安排了一些补丁，合并了两个，并删除了对 TCP 和 NFSV4.x,x>=1 的限制。讨论表明，这些限制没有必要，我也没有看到需要它们的理由。

Trond 树中的负载均衡代码存在一个 bug。在 xprt 附加到客户端时，队列长度会递增。有些请求（特别是 BIND_CONN_TO_SESSION）会传入一个 xprt，但这种情况下队列长度并未递增，而是被递减了。这会导致队列长度变为负值，从而引发问题。

我在想，最后三个补丁（允许多个连接）是否可以合并为一个补丁。

我没有深入考虑如何自动确定最佳连接数，但我怀疑这很难做到透明且可靠。当增加连接能够提高吞吐量时，这几乎肯定是个好选择。但当增加连接并未提高吞吐量时，影响就不那么明显了。我觉得，可能的最好的方法是，协议改进中服务器建议一个上限，当客户端注意到传输积压时，它会向该上限增加连接数。但我们需要更多的经验才能完善这项功能。

欢迎任何评论。我很希望看到这项工作，或类似的功能能够被合并。

谢谢， NeilBrown
```

## 1/9 [`tags/v5.3-rc1 21f0ffaff510 SUNRPC: Add basic load balancing to the transport switch`](https://patchwork.kernel.org/project/linux-nfs/patch/155917688854.3988.7703839883828652258.stgit@noble.brown/)

```
SUNRPC: 为传输切换添加基础负载均衡

目前，仅计算队列长度。这比计算队列中字节数的方式不够精确，但实现起来更容易。
```

## 2/9 612b41f808a9 SUNRPC: Allow creation of RPC clients with multiple connections

## 3/9 5a0c257f8e0f NFS: send state management on a single connection.

## 4/9 10db56917bcb SUNRPC: enhance rpc_clnt_show_stats() to report on all xprts.

```sh
cat /proc/self/mountstats | less
```

## 5/9 2f34b8bfae19 SUNRPC: add links for all client xprts to debugfs

## 6/9 28cc5cd8c68f NFS: Add a mount option to specify number of TCP connections to use

## 7/9 6619079d0540 NFSv4: Allow multiple connections to NFSv4.x (x>0) servers

## 8/9 bb71e4a5d7eb pNFS: Allow multiple connections to the DS

## 9/9 53c326307156 NFS: Allow multiple connections to a NFSv2 or NFSv3 server

# 主线`max_connect`挂载选项

[do not collapse trunkable transports](https://patchwork.kernel.org/project/linux-nfs/cover/20210827183719.41057-1-olga.kornievskaia@gmail.com/)

cover-letter翻译:
```
这组补丁系列尝试允许对同一服务器（即支持 NFSv4.1+ 会话可拆分的服务器）但不同网络地址的新挂载使用与这些挂载关联的连接，同时仍然使用相同的客户端结构。

新增了一个挂载选项 "max_connect"，用于控制可以向现有客户端添加多少额外的传输连接，最多可以添加 16 个这样的传输连接。

v5：修复编译警告

v4： 未对 5 个补丁做任何更改。 删除了补丁 6。 新增了手册页补丁。
```

1/5 tags/v5.15-rc1 3a3f976639f2 SUNRPC keep track of number of transports to unique addresses

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
