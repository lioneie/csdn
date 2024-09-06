# 制作iso镜像

从 App Store 下载 macOS 安装程序(注意只能下载最新的)，或者从 Hackintosh 网站之类的网站下载。

使用以下命令:
```shell
# 从“应用程序”中复制到“macOS-Ventura.app”
# 具体大小可以查看 macOS-Ventura.app/Contents/SharedSupport/SharedSupport.dmg的大小，比这个文件稍微大一些
# 比如 SharedSupport.dmg 文件 11G, 大概需要 13.58G 的空间，如果空间不足，在使用 createinstallmedia 命令时会提示，重新生成更大的空间就可以
hdiutil create -o /tmp/Ventura -size 13.6G -volname Ventura -layout SPUD -fs JHFS+
hdiutil attach /tmp/Ventura.dmg -noverify -mountpoint /Volumes/Ventura
# 如果空间不够时，会提示
sudo macOS-Ventura.app/Contents/Resources/createinstallmedia --volume /Volumes/Ventura --nointeraction
# 执行完上面的命令后，挂载点文件夹名字变了
hdiutil detach /Volumes/Install macOS Ventura # 或者在Finder中卸载
# 不直接将 SharedSupport.dmg 转换为 iso，是为了确保镜像文件的兼容性和稳定性
hdiutil convert /tmp/Ventura.dmg -format UDTO -o ~/Desktop/Ventura # 自动添加 .cdr 后缀名
mv ~/Desktop/Ventura.cdr ~/Desktop/Ventura.iso
rm /tmp/Ventura.dmg
```

# 虚拟机安装macOS

安装[VMware Fusion](https://www.vmware.com/cn/products/fusion/fusion-evaluation.html)，购买注册码, 支持正版。

注意VMware-Fusion-13.5.1之后无法安装macOS，但具体哪一个版本开始无法安装不知道。

"Macintosh HD"默认不是“APFS“文件系统，而且已格式化的文件系统只有80+G大小，需要在“磁盘工具”中”抹掉“重新格式化为APFS, 才能全部利用磁盘空间。

# homebrew

安装`homebrew`:
```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

Warning: /opt/homebrew/bin is not in your PATH.
  Instructions on how to configure your shell for Homebrew
  can be found in the 'Next steps' section below.
==> Installation successful!

==> Homebrew has enabled anonymous aggregate formulae and cask analytics.
Read the analytics documentation (and how to opt-out) here:
  https://docs.brew.sh/Analytics
No analytics data has been sent yet (nor will any be during this install run).

==> Homebrew is run entirely by unpaid volunteers. Please consider donating:
  https://github.com/Homebrew/brew#donations

==> Next steps:
- Run these two commands in your terminal to add Homebrew to your PATH:
    (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> /Users/sonvhi/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
- Run brew help to get started
- Further documentation:
    https://docs.brew.sh
```

根据提示添加加到环境变量PATH中:
```sh
(echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> /Users/sonvhi/.zprofile
```

## 安装`qemu`

安装`qemu`:
```sh
brew install qemu
```

有以下提示信息:
```sh
==> Installing qemu
==> Pouring qemu--8.2.1.arm64_ventura.bottle.tar.gz
2024/02/05 23:57:32 [Warning] [2306516005] app/dispatcher: default route for tcp:eu-central-1-1.aws.cloud2.influxdata.com:443
2024/02/05 23:57:32 127.0.0.1:63471 accepted //eu-central-1-1.aws.cloud2.influxdata.com:443 [proxy]
🍺  /opt/homebrew/Cellar/qemu/8.2.1: 162 files, 562MB
==> Running `brew cleanup qemu`...
Disable this behaviour by setting HOMEBREW_NO_INSTALL_CLEANUP.
Hide these hints with HOMEBREW_NO_ENV_HINTS (see `man brew`).
```