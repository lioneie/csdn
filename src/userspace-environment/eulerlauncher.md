- [openEuler/docs/zh/docs/EulerLauncher](https://gitee.com/openeuler/docs/tree/master/docs/zh/docs/EulerLauncher)
- [eulerlauncher/docs](https://gitee.com/openeuler/eulerlauncher/tree/master/docs)
- [我提的一个issue](https://gitee.com/openeuler/docs/issues/IB5Z0N)

这个eulerlauncher的代码质量看着不高，因为随便在线浏览一下就看到像[`111`](https://gitee.com/openeuler/eulerlauncher/commit/981e58d3f229bd873e0b35d4fbd948119d82031d)和[`1`](https://gitee.com/openeuler/eulerlauncher/commit/2cca964649f002be03aa7d1bcfe1c3b3211ca7f2)这种提交记录。

```sh
/bin/zsh -c "$(curl -fsSL https://gitee.com/cunkai/HomebrewCN/raw/master/Homebrew.sh)"
brew install qemu
brew install wget

sudo visudo # 将%admin ALL=(ALL) ALL替换为 %admin ALL=(ALL) NOPASSWD: ALL
```

[前往EulerLauncher最新版下载MacOS版软件包并解压到期望的位置](https://gitee.com/openeuler/eulerlauncher/releases)，双击`EulerLauncher.dmg`安装（可能要在设置的隐私与安全中点击允许打开）。

```sh
sudo vim /Library/Application\ Support/org.openeuler.eulerlauncher/eulerlauncher.conf
```

配置文件内容如下:
```sh
[default]
log_dir = /Users/sonvhi/chenxiaosong/tmp/eulerlauncher.log # 日志文件位置(xxx.log)
work_dir = /Users/sonvhi/chenxiaosong/VM/eulerlauncher/ # EulerLauncher工作目录，用于存储虚拟机镜像、虚拟机文件等
wget_dir = /opt/homebrew/bin/wget # wget的可执行文件路径
qemu_dir = /opt/homebrew/bin/qemu-system-aarch64 # qemu的可执行文件路径
debug = True

[vm]
cpu_num = 4 # 配置虚拟机的CPU个数
memory = 2048 # 配置虚拟机的内存大小，单位为M，M1用户请勿配置超过2048
```

在应用程序中找到`EulerLauncher.app`，单击启动程序（可能要在设置的隐私与安全中点击允许打开）。然后用命令行:
```sh
eulerlauncher images # 获取可用镜像列表
eulerlauncher download-image 22.03-LTS # 异步下载镜像
eulerlauncher load-image --path {image_file_path} IMAGE_NAME # 加载本地镜像
eulerlauncher delete-image 22.03-LTS # 删除镜像
eulerlauncher images # 查看到Ready才可启动
eulerlauncher launch --image 22.03-LTS 22.03-LTS-instance1 # 创建虚拟机
eulerlauncher list # 获取虚拟机列表
ssh root@{instance_ip} # 默认用户为 root 默认密码为 openEuler12#$
eulerlauncher delete-instance 22.03-LTS-instance1 # 删除虚拟机
```