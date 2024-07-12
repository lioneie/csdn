本文档翻译自[Documentation/Networking/NAT](https://wiki.qemu.org/Documentation/Networking/NAT)，大部分借助于ChatGPT。仅作为我个人的参考，如果你想查阅，建议看英文文档，因为我不确定我记录的中文翻译是否完整和正确。

配置网络地址转换（NAT）是在桌面环境中网络虚拟机的一种有用方法（特别是在使用无线网络时）。 NAT网络将允许您的虚拟机完全访问网络，允许主机和虚拟机之间的网络通信，但防止虚拟机直接出现在物理网络上。

# 概述

要配置NAT网络，首先创建一个`/etc/qemu-ifup`脚本，该脚本创建一个没有任何物理端口的桥接。将该桥接配置为虚拟网络的网关，使用静态IP地址。使用`iptables`创建规则，将来自该桥接的流量伪装为主机网络。最后，在该桥接口上运行`dnsmasq`，充当虚拟网络的DHCP和DNS服务器。

请参阅下面的示例脚本。

# 使用

首先，安装桥接工具、`iptables`和`dnsmasq`：

在Fedora上：
```sh
yum install bridge-utils iptables dnsmasq
apt install bridge-utils iptables dnsmasq -y # 陈孝松注
```

将`qemu-ifup`脚本从此wiki复制到`/etc/qemu-ifup`，并确保该文件具有执行权限。
```sh
chmod 755 /etc/qemu-ifup
```

现在使用tap网络配置启动qemu，并将您的虚拟机配置为使用DHCP。它们应该获得有效的IP地址并能够访问网络。
```sh
qemu -net tap -net nic linux.img
```

# 故障处理

- 遇到了关于/dev/net/tun权限的错误。

目前，您需要以root权限运行qemu才能使用tun/tap网络。

# 脚本

[脚本](https://wiki.qemu.org/Documentation/Networking/NAT#Script)