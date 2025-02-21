本文档翻译自[linux-kdevops/kdevops 的 `docs/nfs.md`](https://github.com/linux-kdevops/kdevops/blob/main/docs/nfs.md)，翻译时文件的最新提交是`9f42f09ae473e6ebb81c9094ac924ddc27c9e38e docs: Fill out docs/nfs.md`，大部分借助于ChatGPT。仅作为我个人的参考，如果你想查阅，建议看英文文档，因为我不确定我记录的中文翻译是否完整和正确。

# kdevops NFS 支持

kdevops 支持测试 NFS。它可以与 kdevops 配置的 NFS 服务器或与 kdevops 设置远程的 NFS 服务器一起工作。

# kdevops NFSD 设置
 
要启用本地 NFS 服务器，请转到“Bring up goals”菜单，并选择“Set up the kernel nfs server”（如果尚未启用）。
这将使“Configure the kernel NFS server”菜单可见。

在该菜单中，您可以选择用于 NFS 导出的文件系统类型（例如“xfs”或“ext4”）。默认情况下，这些导出的文件系统位于 NFS 服务器本身。

您还可以选择默认的导出选项以及服务器的一些其他管理选项。

本地 NFS 服务器与运行文件系统测试的其他目标节点基本相同。例如，“Target workflows”菜单下提供的 Linux 内核选项也会影响安装在 NFS 服务器上的内核。

## 通过 RDMA 使用 NFS

在“Bring up goals”菜单中，您可以在所有目标节点和本地 NFS 服务器（如果已配置）上启用使用软件模拟的 iWARP 或软件模拟的 RoCE。
请参阅“Configure an RDMA device”子菜单。

# 使用 pynfs 测试 kdevops NFS

首先，配置您的 NFS 服务器（可以是上述的本地 NFS 服务器；也可以是 kdevops 测试网络可访问的远程 NFS 服务器）。

要使用 pynfs 测试套件测试内核的 NFS 服务器，请在配置 kdevops 时启用“Target workflows”菜单下的 pynfs 工作流程。

完成所有选择后，使用常规的 make 目标启动您的 kdevops 环境。例如:

  * `make`
  * `make bringup`
  * `make linux`
  * `make pynfs`
  * `make pynfs-baseline`

# 使用 fstests 套件测试 kdevops NFS

首先，配置您的 NFS 服务器（可以是上述的本地 NFS 服务器；也可以是 kdevops 测试网络可访问的远程 NFS 服务器）。

要使用 NFS 运行 fstests 套件，请在“Target workflows”菜单下启用 fstests 工作流程。“Configure and run fstests”菜单将会出现。

在此菜单下，选择“nfs”作为“待测试的目标文件系统类型”。“Configure how to test nfs”子菜单可让您选择要测试的 NFS 版本。每个 NFS 版本都在其自己的目标节点中进行测试，以便测试可以并行运行。然后使用:

  * `make`
  * `make bringup`
  * `make linux`
  * `make fstests`
  * `make fstests-baseline`

# 使用 git 回归测试套件测试 kdevops NFS

首先，配置您的 NFS 服务器（可以是上述的本地 NFS 服务器；也可以是 kdevops 测试网络可访问的远程 NFS 服务器）。

要使用 NFS 运行 git 回归测试套件，请在“Target workflows”菜单下启用 gitr 工作流程。“Configure and run the git regression suite”菜单将会出现。

在此菜单下，选择“nfs”作为“待测试的目标文件系统类型”。“Configure how to test nfs”子菜单可让您选择要测试的 NFS 版本。每个 NFS 版本都在其自己的目标节点中进行测试，以便测试可以并行运行。然后使用:

  * `make`
  * `make bringup`
  * `make linux`
  * `make gitr`
  * `make gitr-baseline`

# 使用 nfstest 套件测试 kdevops NFS

nfstest 套件仅适用于 NFS 文件系统。

您必须首先配置 NFS 服务器，如上所述。

要运行 nfstest 套件，请在“Target workflows”菜单下启用 nfstest 工作流程。“Configure and run the nfstest suite”菜单将会出现。

在此菜单下，您可以选择要运行的测试组。每个测试组在其自己的目标节点中运行，以便测试可以并行运行。然后使用:

  * `make`
  * `make bringup`
  * `make linux`
  * `make nfstest`
  * `make nfstest-baseline`

# 使用 ltp 套件测试 kdevops NFS

运行 NFS 测试组时，ltp 套件使用回环 NFS。因此，它不需要单独的 NFS 服务器。

要运行 ltp 套件，请在“Target workflows”菜单下启用 ltp 工作流程。“Configure and run the ltp suite”菜单将会出现。

在此菜单下，您可以选择要运行的测试组。每个测试组在其自己的目标节点中运行，以便测试可以并行运行。然后使用:

  * `make`
  * `make bringup`
  * `make linux`
  * `make ltp`
  * `make ltp-baseline`

# NFS 的特殊测试模式

## 带 TLS 的 NFS

配置 kdevops 时，您可以选择配置一个证书颁发机构（CA），该机构可以为目标节点和 NFS 服务器创建 x.509 证书。CA 运行在控制节点上，证书在通过 libvirt 配置每个目标节点时分发给它们。

要启用 TLS，请在“Bring up goals”菜单中选择“Configure ktls on the hosts with self-signed CA”选项。

一些工作流程允许您调整挂载选项，以便在 NFS 客户端和服务器之间创建 TLS 会话。检查工作流程菜单，查看这些选项是如何设置的。

## 带 Kerberos 的 NFS

配置 kdevops 时，您可以选择配置一个 Kerberos 数据中心（KDC）。然后为每个目标节点自动创建并分发一个 keytab，在通过 libvirt 配置每个目标节点时分发给它们。

要启用带 Kerberos 的 NFS，请在“Bring up goals”菜单中选择“Set up KRB5”选项。

一些工作流程允许您调整挂载选项，以便在 NFS 客户端和服务器之间启用 Kerberos 的使用。检查工作流程菜单，查看这些选项是如何设置的。

## 带块布局的 pNFS

带块布局的 pNFS 需要对本地 NFS 服务器进行特殊设置，并在每个 NFS 客户端上安装 iSCSI 发起程序。

首先，本地 NFS 服务器仅在使用 XFS 文件系统时支持带块布局的 pNFS。通过“Configure the kernel NFS server”菜单下的“Type of filesystem to export”设置选择 xfs。

接下来，导出的 XFS 文件系统必须位于 iSCSI LUN 上，以便这些设备也能对 NFS 客户端可见。在“Bring up goals”菜单中选择“Set up an iSCSI target host”，然后返回到“Configure the kernel NFS server”菜单并为“Local or external physical storage”选择 iSCSI。

fstests、gitr 和 pynfs 工作流程支持带块布局的 pNFS，但其他工作流程不支持。在控制您希望运行的工作流程的菜单中，找到启用带块布局的 pNFS 的选项。这将在 NFS 客户端节点上配置 iSCSI 发起程序。

最后，对于 fstests 和 gitr 工作流程，选择 NFS 版本 4.1 或 NFS 版本 4.2 选项。较早的 NFS 版本不支持 pNFS。
