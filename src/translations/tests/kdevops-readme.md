本文档翻译自[linux-kdevops/kdevops 的 README 文件](https://github.com/linux-kdevops/kdevops/blob/main/README.md)，翻译时文件的最新提交是`47f2275ba4da2795d460d8aee5def08702bb3838 linux: generate refs automatically`，大部分借助于ChatGPT。仅作为我个人的参考，如果你想查阅，建议看英文文档，因为我不确定我记录的中文翻译是否完整和正确。

# kdevops

kdevops 的主 git 仓库是:

  * https://github.com/linux-kdevops/kdevops

[kdevops logo](https://github.com/linux-kdevops/kdevops/tree/main/images/kdevops-trans-bg-edited-individual-with-logo-gausian-blur-1600x1600.png)

kdevops 提供了一个用于优化 Linux 内核开发和测试的自动化框架。它旨在帮助你快速适应任何复杂的 Linux 内核开发环境，并能够迅速为复杂的子系统设置一个完整的测试实验室。

它利用本地 ansible 角色，并可选地让你使用 [libguestfs](https://libguestfs.org/) 与 libvirt 或 terraform 来支持云提供商。kdevops 对 vagrant 的支持已被弃用，建议使用 [libguestfs](https://libguestfs.org/)，因为 vagrant 缺乏维护，新的开发应该使用并关注 [libguestfs](https://libguestfs.org/)。

kdevops 通过与 Linux 内核中使用的相同变体语言 kconfig 提供变体。它由 Linux 内核开发人员为 Linux 内核开发人员编写。该项目旨在支持所有 Linux 发行版。

kdevops 支持 [PCIe 直通](https://github.com/linux-kdevops/kdevops/tree/main/docs/libvirt-pcie-passthrough.md) 当使用虚拟化时，允许你选择将哪个 PCIe 设备传递到哪个客户机。你可以选择将所有设备传递给一个客户机，或者选择将某个设备传递给特定客户机。例如，你甚至可以得到多个客户机，每个客户机都有一个 PCIe 直通设备分配，这一切都通过 kconfig 完成。

kdevops [PCIe 直通](https://github.com/linux-kdevops/kdevops/tree/main/docs/libvirt-pcie-passthrough.md) 支持使用 [kdevops 动态 kconfig](https://github.com/linux-kdevops/kdevops/tree/main/docs/kdevops-dynamic-configuration.md)，提供了一个新目标 'make dynconfig'，它让 kdevops 根据你的系统环境动态生成 Kconfig 文件。这一机制将来会扩展，以使 kdevops 更加动态，以支持更多的功能。

## kdevops 快速演示

为了让你了解 kdevops 的强大功能和目标，我们提供了一些快速演示来展示你可以做什么。随着时间的推移，将添加更多的工作流。详细的文档说明了如何入门以及如何添加新的工作流。

### 只需 4 条命令即可开始内核黑客攻击

配置 kdevops 使用裸金属、云或本地 vm 解决方案，选择你喜欢的发行版，启用 Linux 内核工作流，选择目标 git 树，并在仅 4 条命令中运行新编译的 Linux git 树:

  * `make menuconfig`
  * `make`
  * `make bringup`
  * `make linux`
  * `make linux HOSTS="kdevops-xfs-crc kdevops-xfs-reflink"` 例如，如果你只想将上面的命令限制为列出的两个主机

要卸载所有节点上的 "6.6.0-rc2" 内核:

  * `make linux-uninstall KVER="6.6.0-rc2"`

### 只需 2 条命令即可开始运行 fstests

要测试内核与 fstests，例如，如果你启用了 fstests 工作流，你可以只运行:

  * `make fstests`
  * `make fstests-baseline`
  * `make fstests-results`

更多细节请参见 [kdevops fstests 文档](https://github.com/linux-kdevops/kdevops/tree/main/docs/fstests.md)

### 只需 2 条命令即可开始运行 blktests

要测试内核与 blktests，例如，如果你启用了 blktests 工作流，你可以只运行:

  * `make blktests`
  * `make blktests-baseline`
  * `make blktests-results`

更多细节请参见 [kdevops blktests 文档](https://github.com/linux-kdevops/kdevops/tree/main/docs/blktests.md)

### 只需 2 条命令即可开始测试 NFS

要测试内核的 nfs 服务器与 pynfs 测试套件，启用 pynfs 工作流，然后运行:

  * `make pynfs`
  * `make pynfs-baseline`

更多细节请参见 [kdevops nfs 文档](https://github.com/linux-kdevops/kdevops/tree/main/docs/nfs.md)

### 只需 2 条命令即可开始运行 git 回归套件

要使用 git 回归套件测试内核，启用 gitr 工作流，然后运行:

  * `make gitr`
  * `make gitr-baseline`

更多细节请参见 [kdevops gitr 文档](https://github.com/linux-kdevops/kdevops/tree/main/docs/gitr.md)

### 只需 2 条命令即可开始运行 ltp 套件

要使用 ltp 套件测试内核，启用 ltp 工作流，然后运行:

  * `make ltp`
  * `make ltp-baseline`

更多细节请参见 [kdevops ltp 文档](https://github.com/linux-kdevops/kdevops/tree/main/docs/ltp.md)

### 只需 2 条命令即可开始运行 nfstest 套件

要使用 nfstest 套件测试内核，启用 nfstest 工作流，然后运行:

  * `make nfstest`
  * `make nfstest-baseline`

更多细节请参见 [kdevops nfstest 文档](https://github.com/linux-kdevops/kdevops/tree/main/docs/nfstest.md)

### 以并行方式运行一些内核自测

kdevops 支持以并行方式运行 Linux 内核自测，这非常简单:

  * `make selftests`
  * `make selftests-baseline`

你也可以运行特定测试:

  * `make selftests-firmware`
  * `make selftests-kmod`
  * `make selftests-sysctl`

更多细节请参见 [kdevops selftests 文档](https://github.com/linux-kdevops/kdevops/tree/main/docs/selftests.md)

### CXL

有 CXL 支持。你可以使用虚拟化 CXL 设备，也可以使用 [PCIe 直通](https://github.com/linux-kdevops/kdevops/tree/main/docs/libvirt-pcie-passthrough.md) 将设备分配给客户机并创建自定义拓扑。kdevops 还可以为你构建和安装最新的 CXL 启用的 qemu 版本。更多细节请参见 [kdevops cxl 文档](https://github.com/linux-kdevops/kdevops/tree/main/docs/cxl.md)

## kdevops 聊天

我们使用 discord 和 IRC。目前我们在 discord 上的用户比在 IRC 上的多。

## kdevops 在 Discord 上

我们有一个公共聊天服务器，目前我们使用 discord:

  * https://bit.ly/linux-kdevops-chat

### kdevops IRC

我们也在 irc.oftc.net 上的 #kdevops

## kdevops 的组成部分

最好将 kdevops 视为你的目标工作流的阶段。首先你需要启动系统。你可以使用裸金属主机、云解决方案或生成本地虚拟化客户机。

kdevops 的使用阶段可以分为:

  * 启动
  * 使系统易于访问，并安装通用开发者首选项
  * 运行定义的工作流

[kdevops-diagram.png](https://github.com/linux-kdevops/kdevops/tree/main/images/kdevops-diagram.png)

---

# kdevops 工作流文档

kdevops 工作流是一种目标工作环境，你可以在其中运行不同的工作流。这些工作流对内核、云或 qemu 可能有不同的要求，还可能启用新的 make 目标以构建或测试目标。一些工作流是通用的，可能会被共享，例如用于配置和构建 Linux 的工作流。然而，如果你只想使用 Linux 发行版自带的内核，则构建和安装 Linux 是可选的。

## kdevops 共享工作流

* [kdevops 示例工作流: 运行 make linux](https://github.com/linux-kdevops/kdevops/tree/main/docs/kdevops-make-linux.md)

## kdevops 可能专用的工作流

  * [kdevops fstests 文档](https://github.com/linux-kdevops/kdevops/tree/main/docs/fstests.md)
  * [kdevops blktests 文档](https://github.com/linux-kdevops/kdevops/tree/main/docs/blktets.md)
  * [kdevops CXL 文档](https://github.com/linux-kdevops/kdevops/tree/main/docs/cxl.md)
  * [kdevops NFS 文档](https://github.com/linux-kdevops/kdevops/tree/main/docs/nfs.md)
  * [kdevops 自测文档](https://github.com/linux-kdevops/kdevops/tree/main/docs/selftests.md)

# kdevops 一般文档

以下是 kdevops 推荐的阅读文档。

  * [发送补丁和贡献给 kdevops](https://github.com/linux-kdevops/kdevops/tree/main/docs/contributing.md)
  * [kdevops 要求](https://github.com/linux-kdevops/kdevops/tree/main/docs/requirements.md)
  * [kdevops 不断演变的 make 帮助](https://github.com/linux-kdevops/kdevops/tree/main/docs/evolving-make-help.md)
  * [kdevops 配置](https://github.com/linux-kdevops/kdevops/tree/main/docs/kdevops-configuration.md)
  * [kdevops 镜像支持](https://github.com/linux-kdevops/kdevops/tree/main/docs/kdevops-mirror.md)
  * [kdevops 初次运行](https://github.com/linux-kdevops/kdevops/tree/main/docs/kdevops-first-run.md)
  * [kdevops 运行 make](https://github.com/linux-kdevops/kdevops/tree/main/docs/running-make.md)
  * [kdevops libvirt 存储池考虑](https://github.com/linux-kdevops/kdevops/tree/main/docs/libvirt-storage-pool.md)
  * [kdevops PCIe 直通支持](https://github.com/linux-kdevops/kdevops/tree/main/docs/libvirt-pcie-passthrough.md)
  * [kdevops 运行 make bringup](https://github.com/linux-kdevops/kdevops/tree/main/docs/running-make-bringup.md)
  * [kdevops 运行 make destroy](https://github.com/linux-kdevops/kdevops/tree/main/docs/kdevops-make-destroy.md)
  * [kdevops make mrproper](https://github.com/linux-kdevops/kdevops/tree/main/docs/kdevops-restarting-from-scratch.md)
  * [kdevops 大块尺寸 R&D](https://github.com/linux-kdevops/kdevops/tree/main/docs/lbs.md)

# kdevops kernel-ci 支持

kdevops 支持其自己的内核持续集成支持，以便让 Linux 开发人员和 Linux 发行版能够跟踪任何支持的 kdevops 工作流中的问题，并能够在检测到新回归时进行识别。但需要注意的是，kdevops 的 kernel-ci 仅在少数工作流中实现，例如 fstests 和 blktests。为了支持 kernel-ci，困难的一部分是确定基线是什么，并且能够以 kdevops 风格轻松地执行 `git diff` 并以每个回归一行的方式读取回归。这需要一些时间和工作。因此，其他一些工作流还不支持 kernel-ci。

相关文档如下:

  * [kdevops kernel-ci](https://github.com/linux-kdevops/kdevops/tree/main/docs/kernel-ci/README.md)

# kdevops 组织

kdevops 被放置在 linux-kdevops 组织下，以便其他开发人员能够无瓶颈地提交/推送更新。

# kdevops 测试结果

kdevops 已开始让用户/开发人员推送测试结果。这不仅仅是收集已知失败的基线结果，还旨在*内部*收集每个失败测试的所有 dmesg/坏日志文件。

提供了一个任意的命名空间，以便 linux-kdevops 组织的开发人员可以贡献发现。

请参阅 [查看 kdevops 存档结果](https://github.com/linux-kdevops/kdevops/tree/main/docs/viewing-fstests-results.md) 以查看更多有关如何查看结果的详细信息。我们将来应该为此添加简单的包装器。

# 关于 kdevops 或相关内容的视频演示

  * [2023 年 5 月 10 日 kdevops: fstests 和 blktests 测试自动化的进展](https://www.youtube.com/watch?v=aC4gb0r9Hho&ab_channel=TheLinuxFoundation)
    * [LWN 对此演讲的报道](https://lwn.net/Articles/937830/)
    * 对请求存储失败的跟进
    * [fstests 结果](https://github.com/linux-kdevops/kdevops/tree/main/workflows/fstests/results/)
    * [blktests 结果](https://github.com/linux-kdevops/kdevops/tree/main/workflows/blktests/results/)
    * 模块支持已确认
    * 人们如何使用 kdevops，一个例子是 Amir 和 Chandan 使用它来支持不同稳定内核的 XFS 稳定工作，使用不同的技术。Amir 使用三星提供的系统资源的本地虚拟化支持，而 Chandan 使用 Oracle Cloud Linux。有关详细信息，请参阅 [LSFMM 2023 Linux 稳定后端](https://www.youtube.com/watch?v=U-f7HlD2Ob4&list=PLbzoR-pLrL6rlmdpJ3-oMgU_zxc1wAhjS&ab_channel=TheLinuxFoundation) 视频
    * 审查 9p 支持
    * Chandan 添加了 OCI 云支持 [kdevops OCI 文档](https://github.com/linux-kdevops/kdevops/tree/main/docs/kdevops-terraform.md)
    * 由于已存在 terraform 提供程序，阿里巴巴云支持是可能的，欢迎补丁
    * arm64 问题 - 帮助我们 debian 的朋友们
    * [Oracle 支持我们提供免费试用云](https://www.oracle.com/cloud/free/)，注册吧！
    * 微软正在评估是否为我们提供信用支持
    * SUSE 可以帮助测试，但不能让人们登录
    * 与 patchwork 的令人兴奋的未来集成，我们可以从 eBPF 社区及其 patchwork 使用和测试中学习！
  * [2023 - 日常内核开发 kdevops 修复 bug 的演示](https://youtu.be/CfGX51a_Fq0) 涵盖以下主题:
    * 设置 kdevops 以使用 Linux git 树的镜像
    * 在主机 kdevops linux 目录上使用 git 远程
    * 研究并修复上游的一个真实世界内核问题的示例
    * 对 reproducers for bugs 的建议和价值，在这种情况下使用了 stress-ng， [更多关于修复此问题的提交的详细信息](https://git.kernel.org/pub/scm/linux/kernel/git/mcgrof/linux.git/commit/?h=20230328-module-alloc-opts&id=f66db2da670853b2386af23552fd941275a13644)
    * 使用特定的远程分支进行开发，在此示例中使用了 [20230328-module-alloc-opts](https://git.kernel.org/pub/scm/linux/kernel/git/mcgrof/linux.git/log/?h=20230328-module-alloc-opts) 作为示例 PATCH v1 系列
    * 使用 `localversion.*` 文件帮助识别 Grub 提示符上的内核名称
    * 在来宾上使用 9p 的 `make modules_install install -j100`
    * 使用 virsh 控制台访问来宾控制台
    * 访问控制台以选择启动时的内核
    * 对未来 v2 补丁系列的小改动的示例
  * [2023 - 实时 kdevops 演示](https://youtu.be/FSY3BMHUyJc) 涵盖以下主题:
    * 使用 AWS 和支持 [16k 原子写入](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/storage-twp.html) 的 ARM64 NVMe 驱动器的示例
    * 演示如何使用基于 linux-next 的自定义任意新 Linux 内核分支开始测试
    * 演示如何开始使用 linux-next 测试 btrfs
    * 演示如何使用 linux-next 测试 XFS
    * 演示 pynfs 测试初期的 NFS 测试工作
    * 演示当前的 CXL 工作流/测试
    * 演示一些稳定的 XFS 维护者如何使用 kdevops 使用本地虚拟化解决方案或云解决方案测试 XFS
    * 演示动态 Kconfig 生成以支持 PCIe 直通
  * [2022 - LSFMM - 运行 fstests 和 blktests 的挑战](https://youtu.be/9PYjRYbc-Ms)
  * [2020 - SUSE Labs 会议 - kdevops: 将 devops 引入内核开发](https://youtu.be/-1KnphkTgNg)

# kdevops 的内部机制

以下部分深入探讨了 kdevops 的技术细节。

  * [如何生成 extra_vars.yaml](https://github.com/linux-kdevops/kdevops/tree/main/docs/how-extra-vars-generated.md)
  * [如何生成 ansible hosts 文件](https://github.com/linux-kdevops/kdevops/tree/main/docs/the-gen-hosts-ansible-role.md)
  * [什么是 kdevops 节点文件及如何生成这些文件](https://github.com/linux-kdevops/kdevops/tree/main/docs/the-gen-nodes-ansible-role.md)
    * [如何生成动态 Vagrant 文件](https://github.com/linux-kdevops/kdevops/tree/main/docs/the-gen-nodes-ansible-role-vagrant.md)
    * [如何生成 terraform kdevops_nodes 变量](https://github.com/linux-kdevops/kdevops/tree/main/docs/the-gen-nodes-ansible-role-terraform.md)
  * [如何生成 terraform/terraform.tfvars 变量](https://github.com/linux-kdevops/kdevops/tree/main/docs/the-terraform-gen-tfvar-ansible-role.md)
  * [为何 Vagrant（已弃用）曾用于虚拟化](https://github.com/linux-kdevops/kdevops/tree/main/docs/why-vagrant.md)
  * [支持带有环回块设备的截断文件的案例](https://github.com/linux-kdevops/kdevops/tree/main/docs/testing-with-loopback.md)
  * [在使用环回/截断文件设置时遇到的更多问题](https://github.com/linux-kdevops/kdevops/tree/main/docs/seeing-more-issues.md)
  * [向 kdevops 添加新的工作流程](https://github.com/linux-kdevops/kdevops/tree/main/docs/adding-a-new-workflow.md)
  * [Kconfig 集成](https://github.com/linux-kdevops/kdevops/tree/main/docs/kconfig-integration.md)
  * [kdevops 动态 Kconfig 支持](https://github.com/linux-kdevops/kdevops/tree/main/docs/kdevops-dynamic-configuration.md)
  * [kdevops Git 参考生成支持](https://github.com/linux-kdevops/kdevops/tree/main/docs/kdevops-autorefs.md)
  * [kdevops 的动机](https://github.com/linux-kdevops/kdevops/tree/main/docs/motivations.md)
  * [Linux 发行版支持](https://github.com/linux-kdevops/kdevops/tree/main/docs/linux-distro-support.md)
  * [使用一个文件覆盖所有 Ansible 角色选项](https://github.com/linux-kdevops/kdevops/tree/main/docs/ansible-override.md)
  * [kdevops Vagrant 支持](https://github.com/linux-kdevops/kdevops/tree/main/docs/kdevops-vagrant.md)
  * [kdevops terraform 支持 - 使用 kdevops 的云设置](https://github.com/linux-kdevops/kdevops/tree/main/docs/kdevops-terraform.md)
  * [kdevops 本地 Ansible 角色](https://github.com/linux-kdevops/kdevops/tree/main/docs/ansible-roles.md)
  * [构建自定义 Vagrant box 的教程](https://github.com/linux-kdevops/kdevops/tree/main/docs/custom-vagrant-boxes.md)

# 许可证

此作品依据 copyleft-next-0.3.1 许可证授权，详情请参阅 [LICENSE](https://github.com/linux-kdevops/kdevops/tree/main/LICENSE) 文件。
请坚持在文件中使用 SPDX 注释进行许可证标注。
如果文件中没有 SPDX 注释，则默认使用 copyleft-next-0.3.1 许可证。我们保留带有宽松许可证的 SPDX 注释，以确保我们在宽松许可证下采用的上游项目可以从我们对其相应文件的更改中受益。
同样，GPLv2 文件也是允许的，因为 copyleft-next-0.3.1 与 GPLv2 兼容。
