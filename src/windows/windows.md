# 安装系统

- [win11镜像下载](https://www.microsoft.com/zh-cn/software-download/windows11)（国内网络会更快）
- [老毛桃U盘PE重装教程](https://www.laomaotao.net/help/2020/0806/8620.html)

MSR分区(微软保留分区)是GPT磁盘上用于保留空间以供备用的分区。例如在将磁盘转换为动态磁盘时会使用这些空间。

ESP分区(UEFI System partition)用于采用了UEFI BIOS的电脑系统，用来启动操作系统。分区内存放引导管理程序、驱动程序、系统维护工具等。

如果电脑采用了UEFI系统，或当前磁盘将来可能会用在UEFI系统上启动系统，则应建立ESP分区。

远程登录工具可以使用`MobaXterm`。

virt-manager中安装win11，默认分辨率太低，还要在windows中安装[Windows SPICE Guest Tools](https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe)，[参考这个网页](https://www.spice-space.org/download.html)。

# wsl

应用商店中安装wsl（不需要翻墙），打开`Turn Windows features on or off` 中的wsl

```sh
# 将WSL 2设置为默认版本
wsl --set-default-version 2
# 启用虚拟机平台功能
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```
重启电脑后，安装
```sh
# 要翻墙才能访问
wsl.exe --list --online
# 默认安装的位置: C:\Users\%username%\AppData\Local\Packages\CanonicalGroupLimited.Ubuntu22.04LTS_79rhkp1fndgsc
wsl.exe --install Ubuntu-22.04
# win11
wsl.exe --install -d Ubuntu-22.04

# 其中的VERSION是指wsl的版本
wsl --list --verbose
# 正在运行的
wsl --list --running
# 卸载
# 不会删除数据
wsl --unregister Ubuntu-22.04
# 删除数据
wsl --uninstall Ubuntu-22.04

wsl --export Ubuntu-22.04 D:\chenxiaosong\wsl-backup\Ubuntu-22.04.tar
# wsl --import <发行版名称> <安装路径> <tar文件路径>
wsl --import Ubuntu-22.04 D:\chenxiaosong\wsl-install D:\chenxiaosong\wsl-backup\Ubuntu-22.04.tar

# 开机
wsl --distribution Ubuntu-22.04
# 关机
wsl --shutdown Ubuntu-22.04
```

