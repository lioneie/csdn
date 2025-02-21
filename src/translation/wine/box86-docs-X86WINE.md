本文翻译自[box86 Installing Wine (and winetricks)](https://github.com/ptitSeb/box86/blob/master/docs/X86WINE.md)，翻译时文件的最新提交是`7748d10246be2b0269d76971c74d242bf659dbcb update X86WINE, libxxf86vm1:armhf (#955)`。

# 安装 Wine（和 winetricks）

_TwisterOS 用户: Wine、winetricks 和 Box86 已经安装在 TwisterOS 中。您不需要安装任何东西。_

_树莓派用户: Wine 需要一个 3G/1G 的分配内存内核。树莓派 4 的 Raspberry Pi OS 已经具有 3G/1G 的内核，并且可以与 Wine 一起使用，但是 **Pi 3B+ 和之前的型号具有 2G/2G 的内核，需要自定义编译的 3G/1G 内核才能使 Wine 工作。**_

请查看下面的安装步骤（在 [示例](#examples) 部分）。

使用 Wine 与 Box86 结合，允许 (x86) Windows 程序在 ARM Linux 计算机上运行（对于 x64，请使用 [box64](https://github.com/ptitSeb/box64) 和 wine-amd64 与 `aarch64` 处理器）。

Box86 需要在 ARM 设备上**手动**安装 `wine-i386`。即使在许多 ARM 设备的仓库中有 `wine-armhf`（即使用 _apt-get_ 将默认尝试安装 `wine-armhf`），但 `wine-armhf` 也无法与 Box86 一起使用。请注意，由于使用 `multiarch` 会导致您的 ARM 设备认为它需要安装许多 i386 依赖项才能使 `wine-i386` 工作，因此需要手动安装。 Box86 的“技巧”在于 Box86 “包装”了许多 Wine 的核心 Linux i386 库（.so 文件），以便它们的调用可以被您的 ARM 设备的其他 armhf Linux 系统库解释。还请注意，包装库是 Box86 开发的一个持续过程，并且在所有 i386 库依赖项都被包装之前，某些程序可能无法正常运行。

Wine 的安装文件可以在 [WineHQ 仓库](https://dl.winehq.org/wine-builds/debian/dists/buster/main/binary-i386/)、[TwisterOS FAQ](https://twisteros.com/faq.html) 页面或 [PlayOnLinux 网站仓库](https://www.playonlinux.com/wine/) 找到。尽管我们在 ARM 处理器上安装，Box86 需要 "i386"（x86）版本的 Wine。

## 概述

安装 Wine for Box86 的一般步骤是...

- 下载所需 Wine 版本的所有安装文件（.deb、.zip，甚至 .pol 文件）
- 将安装文件解压缩或使用 dpkg 安装到一个文件夹中
- 将该文件夹移动到您希望 Wine 运行的目录（在 TwisterOS 中，默认为 `~/wine/`）
- 如果您在 64 位 ARM 操作系统（aarch64）上运行 box86/i386-wine，则还必须安装一些额外的 armhf 库。
- 转到 `/usr/local/bin` 并创建符号链接或脚本，指向您的主要 wine 二进制文件（`wine`、`winecfg` 和 `wineserver`）。
- 启动 wine 以创建新的 wineprefix（`wine wineboot`）。
- 下载 winetricks（它只是一个非常复杂的 bash 脚本），使其可执行，然后将其复制到 `/usr/local/bin`。

## 示例

### 在 Raspberry Pi OS 上从 Twister OS FAQ 的 .tgz 文件中安装 Wine for Box86

_链接来自 [TwisterOS FAQ](https://twisteros.com/faq.html)_

这将安装 Wine v5.13（这是 TwisterOS 预安装的 Wine 版本）。提交错误报告时，其他 Box86 用户可能会假定您正在使用此版本的 Wine，除非另有说明。

```sh
# Backup any old wine installations
sudo mv ~/wine ~/wine-old
sudo mv ~/.wine ~/.wine-old
sudo mv /usr/local/bin/wine /usr/local/bin/wine-old
sudo mv /usr/local/bin/wineboot /usr/local/bin/wineboot-old
sudo mv /usr/local/bin/winecfg /usr/local/bin/winecfg-old
sudo mv /usr/local/bin/wineserver /usr/local/bin/wineserver-old

# Download, extract wine, and install wine (last I checked, the Twister OS FAQ page had Wine 5.13-devel)
wget https://twisteros.com/wine.tgz -O ~/wine.tgz
tar -xzvf ~/wine.tgz
rm ~/wine.tgz # clean up

# Install shortcuts (make launcher & symlinks. Credits: grayduck, Botspot)
echo -e '#!/bin/bash\nsetarch linux32 -L '"$HOME/wine/bin/wine "'"$@"' | sudo tee -a /usr/local/bin/wine >/dev/null # Create a script to launch wine programs as 32bit only
#sudo ln -s ~/wine/bin/wine /usr/local/bin/wine # You could also just make a symlink, but box86 only works for 32bit apps at the moment
sudo ln -s ~/wine/bin/wineboot /usr/local/bin/wineboot
sudo ln -s ~/wine/bin/winecfg /usr/local/bin/winecfg
sudo ln -s ~/wine/bin/wineserver /usr/local/bin/wineserver
sudo chmod +x /usr/local/bin/wine /usr/local/bin/wineboot /usr/local/bin/winecfg /usr/local/bin/wineserver

# Boot wine (make fresh wineprefix in ~/.wine )
wine wineboot
```

### 从 WineHQ 的 .deb 文件在 Raspberry Pi OS 上安装 Wine for Box86

_链接来自 [WineHQ 仓库](https://dl.winehq.org/wine-builds/debian/dists/buster/main/binary-i386/)_

此安装方法允许您安装不同版本的 Wine。您可以安装任何您想要的 Wine 版本/分支。

```sh
### User-defined Wine version variables ################
# - Replace the variables below with your system's info.
# - Note that we need the i386 version for Box86 even though we're installing it on our ARM processor.
# - Wine download links from WineHQ: https://dl.winehq.org/wine-builds/

wbranch="devel" #example: devel, staging, or stable (wine-staging 4.5+ requires libfaudio0:i386 - see below)
wversion="7.1" #example: 7.1
wid="debian" #example: debian, ubuntu
wdist="bullseye" #example (for debian): bullseye, buster, jessie, wheezy, etc
wtag="-1" #example: -1 (some wine .deb files have -1 tag on the end and some don't)

########################################################

# Clean up any old wine instances
wineserver -k # stop any old wine installations from running
rm -rf ~/.cache/wine # remove old wine-mono/wine-gecko install files
rm -rf ~/.local/share/applications/wine # remove old program shortcuts

# Backup any old wine installations
sudo mv ~/wine ~/wine-old
sudo mv ~/.wine ~/.wine-old
sudo mv /usr/local/bin/wine /usr/local/bin/wine-old
sudo mv /usr/local/bin/wineboot /usr/local/bin/wineboot-old
sudo mv /usr/local/bin/winecfg /usr/local/bin/winecfg-old
sudo mv /usr/local/bin/wineserver /usr/local/bin/wineserver-old

# Download, extract wine, and install wine
cd ~/Downloads
wget https://dl.winehq.org/wine-builds/${wid}/dists/${wdist}/main/binary-i386/wine-${wbranch}-i386_${wversion}~${wdist}${wtag}_i386.deb # download
wget https://dl.winehq.org/wine-builds/${wid}/dists/${wdist}/main/binary-i386/wine-${wbranch}_${wversion}~${wdist}${wtag}_i386.deb # (required for wine_i386 if no wine64 / CONFLICTS WITH wine64 support files)
dpkg-deb -x wine-${wbranch}-i386_${wversion}~${wdist}${wtag}_i386.deb wine-installer # extract
dpkg-deb -x wine-${wbranch}_${wversion}~${wdist}${wtag}_i386.deb wine-installer
mv wine-installer/opt/wine* ~/wine # install
rm wine*.deb # clean up
rm -rf wine-installer # clean up

# Install shortcuts (make 32bit launcher & symlinks. Credits: grayduck, Botspot)
echo -e '#!/bin/bash\nsetarch linux32 -L '"$HOME/wine/bin/wine "'"$@"' | sudo tee -a /usr/local/bin/wine >/dev/null # Create a script to launch wine programs as 32bit only
#sudo ln -s ~/wine/bin/wine /usr/local/bin/wine # You could aslo just make a symlink, but box86 only works for 32bit apps at the moment
sudo ln -s ~/wine/bin/wineboot /usr/local/bin/wineboot
sudo ln -s ~/wine/bin/winecfg /usr/local/bin/winecfg
sudo ln -s ~/wine/bin/wineserver /usr/local/bin/wineserver
sudo chmod +x /usr/local/bin/wine /usr/local/bin/wineboot /usr/local/bin/winecfg /usr/local/bin/wineserver

# These packages are needed for running wine on a 64-bit RPiOS via multiarch
karch=$(uname -m)
if [ "$karch" = "aarch64" ] || [ "$karch" = "aarch64-linux-gnu" ] || [ "$karch" = "arm64" ] || [ "$karch" = "aarch64_be" ]; then
    sudo dpkg --add-architecture armhf && sudo apt-get update # enable multi-arch
    sudo apt-get install -y libasound2:armhf libc6:armhf libglib2.0-0:armhf libgphoto2-6:armhf libgphoto2-port12:armhf \
        libgstreamer-plugins-base1.0-0:armhf libgstreamer1.0-0:armhf libldap-2.4-2:armhf libopenal1:armhf libpcap0.8:armhf \
        libpulse0:armhf libsane1:armhf libudev1:armhf libusb-1.0-0:armhf libvkd3d1:armhf libx11-6:armhf libxext6:armhf \
        libasound2-plugins:armhf ocl-icd-libopencl1:armhf libncurses6:armhf libncurses5:armhf libcap2-bin:armhf libcups2:armhf \
        libdbus-1-3:armhf libfontconfig1:armhf libfreetype6:armhf libglu1-mesa:armhf libglu1:armhf libgnutls30:armhf \
        libgssapi-krb5-2:armhf libkrb5-3:armhf libodbc1:armhf libosmesa6:armhf libsdl2-2.0-0:armhf libv4l-0:armhf \
        libxcomposite1:armhf libxcursor1:armhf libxfixes3:armhf libxi6:armhf libxinerama1:armhf libxrandr2:armhf \
        libxrender1:armhf libxxf86vm1:armhf libc6:armhf libcap2-bin:armhf # to run wine-i386 through box86:armhf on aarch64
        # This list found by downloading...
        #	wget https://dl.winehq.org/wine-builds/debian/dists/bullseye/main/binary-i386/wine-devel-i386_7.1~bullseye-1_i386.deb
        #	wget https://dl.winehq.org/wine-builds/debian/dists/bullseye/main/binary-i386/winehq-devel_7.1~bullseye-1_i386.deb
        #	wget https://dl.winehq.org/wine-builds/debian/dists/bullseye/main/binary-i386/wine-devel_7.1~bullseye-1_i386.deb
        # then `dpkg-deb -I package.deb`. Read output, add `:armhf` to packages in dep list, then try installing them on Pi aarch64.
fi

# These packages are needed for running wine-staging on RPiOS (Credits: chills340)
sudo apt install libstb0 -y
cd ~/Downloads
wget -r -l1 -np -nd -A "libfaudio0_*~bpo10+1_i386.deb" http://ftp.us.debian.org/debian/pool/main/f/faudio/ # Download libfaudio i386 no matter its version number
dpkg-deb -xv libfaudio0_*~bpo10+1_i386.deb libfaudio
sudo cp -TRv libfaudio/usr/ /usr/
rm libfaudio0_*~bpo10+1_i386.deb # clean up
rm -rf libfaudio # clean up

# Boot wine (make fresh wineprefix in ~/.wine )
wine wineboot
```

## 安装 winetricks

Winetricks 是一个 bash 脚本，它使安装和配置任何所需的 Windows 核心系统软件包更加容易，这些软件包可能是某些 Windows 程序的依赖项。您可以使用 `apt` 安装它，或者按照下面的步骤手动安装。

```
sudo apt-get install cabextract -y                                                                   # winetricks needs this installed
sudo mv /usr/local/bin/winetricks /usr/local/bin/winetricks-old                                      # Backup old winetricks
cd ~/Downloads && wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks # Download
sudo chmod +x winetricks && sudo mv winetricks /usr/local/bin/                                       # Install
```

每当我们运行winetricks时，我们必须告诉Box86抑制其信息横幅，否则winetricks会崩溃。可以使用BOX86_NOBANNER=1环境变量在调用winetricks之前抑制Box86的信息横幅（例如: `BOX86_NOBANNER=1 winetricks`）。

如果apt为winetricks安装了桌面菜单快捷方式（或者您自己创建了winetricks的桌面快捷方式），则可能需要编辑该快捷方式以包含Box86的BOX86_NOBANNER=1环境变量。使用您喜欢的文本编辑器，编辑`/usr/share/applications/winetricks.desktop`，并将`Exec=winetricks --gui`更改为`Exec=env BOX86_NOBANNER=1 winetricks --gui`。


## 示例命令

以下是一个使用box86运行winetricks命令的示例:

`BOX86_NOBANNER=1 winetricks -q corefonts vcrun2010 dotnet20sp1`

该命令将静默安装三个软件包: Windows核心字体、VC++ 2010运行库和.NET 2.0 SP1。 `-q` 是“安静/静默安装”的命令。

每当我们运行winetricks时，我们必须通过键入`BOX86_NOBANNER=1`来抑制Box86的横幅，以防止winetricks崩溃。调用Box86的日志功能（例如`BOX86_LOG=1`）也会导致winetricks崩溃。（如果需要Box86日志记录，我们可以修补winetricks以避免这些崩溃 - 请参阅*故障排除*部分）。

要获取winetricks可以帮助您安装的所有不同Windows软件包和库的列表，请运行`winetricks list-all`。

## 其他注意事项

### Wine前缀（以及Wine初始化）

当您首次运行或启动Wine（`wine wineboot`）时，Wine将在其中创建一个新的用户环境以安装Windows软件。此用户环境称为“wineprefix”（或“wine瓶”)，默认情况下位于`~/.wine`中（请注意，Linux文件夹以`.`开头的是“隐藏”文件夹）。将wineprefix视为Wine的虚拟“硬盘”，用于安装软件和保存设置。Wineprefix是可移植且可删除的。有关更多Wine文档，请参阅[WineHQ](https://www.winehq.org/documentation)。

如果您在默认的wineprefix中损坏了任何内容，可以通过删除`~/.wine`目录（使用`rm -rf ~/.wine`命令）并再次启动Wine来开始“新的”工作，从而创建一个新的默认wineprefix。

### 移植wineprefix（侧向加载）

如果在Box86上的设备上无法安装软件，但您在普通x86 Linux计算机上可以在Wine上安装软件，则可以将wineprefix从x86 Linux计算机复制到运行Box86的设备上。这最容易通过将x86 Linux计算机上的`~/.wine`文件夹打包成tar文件（`tar -cvf winebottle.tar ~/.wine`），将tar文件传输到您的设备上，然后在运行Box86和Wine的设备上解压缩tar文件（`tar -xf winebottle.tar`）。打包wineprefix会保留其中的任何符号链接。

### 更换不同版本的Wine

某些Wine版本与某些软件更配合。最好安装一个已知与要运行的软件配合良好的Wine版本。有三个主要的Wine开发分支可供选择，称为wine-stable、wine-devel和wine-staging。_请注意，wine-staging分支在树莓派上需要额外的安装步骤_。

您的整个Wine安装可以位于您Linux计算机上的一个单独文件夹中。TwisterOS假定您的Wine安装位于`~/wine/`目录中。将`wine`文件夹放在的实际目录不重要，只要您在`/usr/local/bin/`目录中有指向`wine`文件夹的符号链接，这样Linux就可以在您在终端中键入`wine`时找到Wine）。

您可以通过将旧的`wine`和`.wine`文件夹重命名为其他名称，然后将新的`wine`文件夹（其中包含新版本的Wine）放置到相同的位置来更改您正在运行的Wine版本。然后再次运行`wine wineboot`将会将一个wineprefix从旧版本的Wine迁移到您刚刚安装的新版本的Wine中，以便使用。您可以使用`wine --version`命令检查您正在运行的Wine版本。
