本文档翻译自[LTP Network Tests 的 README 文件](https://github.com/linux-test-project/ltp/blob/master/testcases/network/README.md)，翻译时文件的最新提交是`bc904b3ed net: tst_netload_compare(): Ignore performance failures`，大部分借助于ChatGPT。仅作为我个人的参考，如果你想查阅，建议看英文文档，因为我不确定我记录的中文翻译是否完整和正确。

# LTP网络测试

## 单主机配置

这是默认配置（如果未定义 `RHOST` 环境变量）。LTP会添加 `ltp_ns` 网络命名空间，并根据LTP网络环境变量自动配置 `veth` 对。

## 两个主机配置

此设置需要正确设置 `RHOST` 环境变量并配置SSH访问远程主机。

`RHOST` 变量必须设置为服务器的主机名（测试管理链接），并且需要设置公钥或无密码登录。

SSH服务器需要配置为允许root登录和使用公钥认证（在 `/etc/ssh/sshd_config` 中设置 `PermitRootLogin yes` 和 `PubkeyAuthentication yes`）。

一些尚未移植到网络API的网络压力测试被设计为通过 `LTP_RSH` 环境变量通过 `rsh` 进行测试。现在默认使用 `ssh`，详情请参阅 [`testcases/network/stress/README`](https://github.com/linux-test-project/ltp/blob/master/testcases/network/stress/README)。

## 服务器服务配置

测试具有各种外部依赖项，如果未安装则以 `TCONF` 退出。某些测试需要额外的设置。

### FTP和telnet设置

FTP压力测试和telnet服务器测试需要设置环境变量 `RHOST`（远程机器）、`RUSER`（远程用户）和 `PASSWD`（远程密码）。注意: 对于其他测试，`RHOST` 将意味着两个主机配置。

如果 `RUSER` 设置为 `root`，则需要执行以下步骤之一:

- 在 `/etc/ftpusers`（或 `/etc/vsftpd.ftpusers`）中，注释包含 "root" 字符串的行。此文件列出了所有不能在当前系统上进行ftp访问的用户。
- 如果不想执行前一步骤，则在 `/root/.netrc` 中添加以下条目:

```
machine <remote_server_name>
login root
password <remote_root_password>
```

### HTTP设置

HTTP压力测试需要配置并运行Web服务器（Apache2、Nginx等）。

### NFS设置

NFS测试需要运行NFS服务器，请启用并启动 `nfs-server.service`（Debian/Ubuntu和openSUSE/SLES: `nfs-kernel-server` 包，其他发行版: `nfs-server` 包）。

没有检测服务是否正在运行，测试将在没有警告的情况下简单失败。

### TI-RPC / Sun RPC设置

TI-RPC（或glibc旧版Sun RPC）测试需要运行rpcbind（或旧版发行版上的portmap），请启用并启动 `rpcbind.service`。

## LTP设置

安装LTP测试套件（请参阅INSTALL）。在两个主机配置的情况下，LTP需要安装在完全相同的位置，并且在*两个*客户端和服务器机器上设置 `LTPROOT` 和 `PATH` 环境变量。这是必需的，因为某些测试期望在特定位置找到服务器文件。

例如，默认前缀 `/opt/ltp` 的示例:

```sh
export LTPROOT="/opt/ltp"; export PATH="$LTPROOT/testcases/bin:$PATH"
```

## 运行测试

网络测试通过运行 network.sh 脚本执行:

```sh
TEST_VARS ./network.sh OPTIONS
```

其中

- `TEST_VARS` - 非默认的网络参数
- `OPTIONS` - 测试组(s)，使用 -h 查看可用选项。

所有 LTP 网络参数的默认值都在 `testcases/lib/tst_net.sh` 中设置。网络压力参数在 `testcases/network/stress/README` 中有文档。

使用 `tst_netload_compare()` 测试的测试还会测试性能。它们可能在过载的系统上失败。为了忽略性能失败并仅测试网络功能，请设置 `LTP_NET_FEATURES_IGNORE_PERFORMANCE_FAILURE=1` 环境变量。

## 调试

单主机和双主机配置都支持通过 `TST_NET_RHOST_RUN_DEBUG=1` 环境变量进行调试。