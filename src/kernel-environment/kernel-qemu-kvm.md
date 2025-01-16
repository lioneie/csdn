<!-- [QEMU中的网络](https://blog.csdn.net/chengbeng1745/article/details/81271024) -->

<!--
# qemu虚拟机启动时指定ip

```shell
[root@192 ~]# cat /lib/systemd/system/qemu-vm-setup.service
[Unit]
Description=QEMU VM Setup

[Service]
Type=oneshot
ExecStart=/root/qemu-vm-setup.sh

[Install]
WantedBy=default.target
```

```shell
[root@192 ~]# cat qemu-vm-setup.sh 
#!/bin/sh

dev=$(ip link show | awk '/^[0-9]+: en/ {sub(":", "", $2); print $2}')
ip=$(awk '/IP=/ { print gensub(".*IP=([0-9.]+).*", "\\1", 1) }' /proc/cmdline)

if test -n "$ip"
then
	gw=$(echo $ip | sed 's/[.][0-9]\+$/.1/g')
	ip addr add $ip/24 dev $dev
	ip link set dev $dev up
	ip route add default via $gw dev $dev
fi
```
-->

# 修改成不需要密码

`/etc/passwd`修改成:
```sh
root::0:0:Super User:/root:/bin/bash
```

`/etc/shadow`可以不修改。

# arm32架构

在 linux 仓库中执行 `make dtbs` 生成 dtb 文件

ubuntu2204宿主机中创建网络:
```sh
sudo apt install bridge-utils -y # brctl命令
sudo apt-get install uml-utilities -y # tunctl 命令， centos９没有
qemu-system-arm -net nic,model=? -M vexpress-a15 # 查看支持的虚拟网络
sudo tunctl -b # 按顺序创建 tap0 tap1，每输入一次命令创建一个
sudo tunctl -t tap0 -u sonvhi # 指定名称创建
sudo tunctl -t tap1 -u sonvhi
sudo ip link set tap0 up # 激活
sudo ip link set tap1 up # 激活
sudo tunctl -d tap1 # 删除 tap1
sudo brctl show # 查看网桥
sudo brctl addif virbr0 tap0 # tap0 加入网桥
sudo brctl addif virbr0 tap1 # tap1 加入网桥
sudo brctl delif virbr0 tap0 # tap0 移出网桥

sudo brctl addbr br0 # 新建网桥 br0
sudo brctl delbr br0 # 删除网桥 br0
sudo brctl addif br0 enx381428b8c32c # 注意:无线网卡不行, 必须是以太网卡
sudo brctl addif br0 tap0 # tap0 加入网桥
```

centos9宿主机中没有 `tunctl`的解决办法:
```sh
sudo ip tuntap add tap0 mode tap user sonvhi
sudo ip tuntap del tap0 mode tap
sudo ip tuntap list
```

bullseye aarch64 网络无法使用， `/etc/network/interfaces` 需要把 `eth0` 改成 `enp0s1`(通过`dmesg | grep -i eth`找到`enp0s1`)

# riscv ubuntu2204镜像

riscv64架构的镜像，可以直接下载[ubuntu2204](https://ubuntu.com/download/risc-v)（选择[QEMU emulator]）。

```sh
qemu-system-riscv64 -netdev ? # 宿主机中查看可用的netdev backend类型
```

虚拟机中修改配置:
```sh
systemctl status systemd-modules-load.service # 查看systemd-modules-load服务状态
# 删除systemd-modules-load服务，怕万一后续有用，只做重命名
mv /lib/systemd/system/systemd-modules-load.service /lib/systemd/system/systemd-modules-load.service.bak

cp /etc/fstab /etc/fstab.bak # 备份
vim /etc/fstab # 删除 LABEL=UEFI 一行
```

# openeuler

[openEuler 22.03 LTS SP2（或更新的版本）](https://www.openeuler.org/en/download/?version=openEuler%2022.03%20LTS%20SP2)，Scenario选择“cloud computing”，下载`qcow2.xz`，解压:
```sh
xz -d openEuler-22.03-LTS-SP2-x86_64.qcow2.xz
```

qemu启动参数需要做一些小修改 `-append "... root=/dev/vda2 ..."`。

默认的登录账号是`root`，密码是 `openEuler12#$`，具体参考[系统安装](https://docs.openeuler.org/zh/docs/22.03_LTS_SP3/docs/Releasenotes/%E7%B3%BB%E7%BB%9F%E5%AE%89%E8%A3%85.html)。

注意需要打开`vfat`文件系统相关配置，具体查看[《微软文件系统》](https://chenxiaosong.com/src/filesystem/microsoft-fs.html)中`vfat`相关的一节。否则会进入emergency mode，如果你实在不想打开`vfat`文件系统相关配置，可以编辑`/etc/fstab`文件删除`/boot`相关的一行，重启系统就可以正常启动了，但不建议哈。
