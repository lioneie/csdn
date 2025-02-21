本文翻译自[box64 Installing Wine64](https://github.com/ptitSeb/box64/blob/main/docs/X64WINE.md)，翻译时文件的最新提交是`0cc04e5253aa31544ca9e234b37e20b1ab81232f Create X64WINE.md (#423)`。

# 安装 Wine64

在 64 位 ARM Linux 设备上运行 Wine64/Wine 可以使 x64/x86 Windows 程序在其上运行。

 - Box64 需要在 ARM64（aarch64）设备上**手动**安装 `wine-amd64`。这将运行 64 位 Windows 程序（也称为 x86_64）。
 - Box86 需要在 ARM32（armhf）设备上（或者在 ARM64 上使用 multiarch 或 chroot）**手动**安装 `wine-i386`。这将运行 32 位 Windows 程序（也称为 x86）。
 - _请注意，`wine:arm64` 和 `wine:armhf` 将无法与 Box64/Box86 一起工作。如果您要求设备的软件包管理器安装这些软件，它可能会尝试安装它们。_

请查看以下安装步骤（在 [示例](#examples) 部分）。

## 概述

安装 Wine64 和 Wine for Box64 & Box86 的一般步骤是:

 - 下载您希望安装的 Wine 版本的所有安装文件
 - 将安装文件解压缩或 dpkg 到一个文件夹中
 - 将该文件夹移动到您希望 Wine 运行的目录（通常默认为 `~/wine/`）
 - 进入 `/usr/local/bin` 并创建符号链接或脚本，将其指向您的主要 wine 二进制文件
 - 启动 wine 以创建一个新的 wineprefix
 - 下载 winetricks（这只是一个复杂的 bash 脚本），使其可执行，然后将其复制到 `/usr/local/bin`。

## 示例

### 从 WineHQ .deb 文件在 Raspberry Pi OS 上安装 Wine64 & Wine for Box64 & Box86

_链接来自 [WineHQ 仓库](https://dl.winehq.org/wine-builds/debian/dists/)_

这种安装方法允许您安装不同版本的 Wine64/Wine。您可以安装任何您希望的 Wine 版本/分支。

```sh
	# 注意: 只能在 aarch64 上运行（因为 box64 只能在 aarch64 上运行）。
	# box64 运行 wine-amd64，box86 运行 wine-i386。

	### 用户定义的 Wine 版本变量 ################
	# - 请使用以下信息替换变量。
	# - 请注意，尽管我们要在 ARM 处理器上安装，但我们需要为 Box64 使用 amd64 版本。
	# - Note that we need the i386 version for Box86 even though we're installing it on our ARM processor.
	# - Wine download links from WineHQ: https://dl.winehq.org/wine-builds/
  
	local branch="devel" #example: devel, staging, or stable (wine-staging 4.5+ requires libfaudio0:i386)
	local version="7.1" #example: "7.1"
	local id="debian" #example: debian, ubuntu
	local dist="bullseye" #example (for debian): bullseye, buster, jessie, wheezy, ${VERSION_CODENAME}, etc 
	local tag="-1" #example: -1 (some wine .deb files have -1 tag on the end and some don't)

  ########################################################

	# 清理所有旧的 Wine 实例
	wineserver -k # stop any old wine installations from running
	rm -rf ~/.cache/wine # remove any old wine-mono/wine-gecko install files
	rm -rf ~/.local/share/applications/wine # remove any old program shortcuts

	# 备份任何旧的 Wine 安装
	rm -rf ~/wine-old 2>/dev/null; mv ~/wine ~/wine-old 2>/dev/null
	rm -rf ~/.wine-old 2>/dev/null; mv ~/.wine ~/.wine-old 2>/dev/null
	sudo mv /usr/local/bin/wine /usr/local/bin/wine-old 2>/dev/null
	sudo mv /usr/local/bin/wine64 /usr/local/bin/wine-old 2>/dev/null
	sudo mv /usr/local/bin/wineboot /usr/local/bin/wineboot-old 2>/dev/null
	sudo mv /usr/local/bin/winecfg /usr/local/bin/winecfg-old 2>/dev/null
	sudo mv /usr/local/bin/wineserver /usr/local/bin/wineserver-old 2>/dev/null

	# Wine 的下载链接来自 WineHQ: https://dl.winehq.org/wine-builds/
	LNKA="https://dl.winehq.org/wine-builds/${id}/dists/${dist}/main/binary-amd64/" #amd64-wine links
	DEB_A1="wine-${branch}-amd64_${version}~${dist}${tag}_amd64.deb" #wine64 main bin
	DEB_A2="wine-${branch}_${version}~${dist}${tag}_amd64.deb" #wine64 support files (required for wine64 / can work alongside wine_i386 main bin)
		#DEB_A3="winehq-${branch}_${version}~${dist}${tag}_amd64.deb" #shortcuts & docs
	LNKB="https://dl.winehq.org/wine-builds/${id}/dists/${dist}/main/binary-i386/" #i386-wine links
	DEB_B1="wine-${branch}-i386_${version}~${dist}${tag}_i386.deb" #wine_i386 main bin
	DEB_B2="wine-${branch}_${version}~${dist}${tag}_i386.deb" #wine_i386 support files (required for wine_i386 if no wine64 / CONFLICTS WITH wine64 support files)
		#DEB_B3="winehq-${branch}_${version}~${dist}${tag}_i386.deb" #shortcuts & docs

	# 安装 amd64-wine（64 位）以及 i386-wine（32 位）。
	echo -e "Downloading wine . . ."
	wget -q ${LNKA}${DEB_A1} 
	wget -q ${LNKA}${DEB_A2} 
	wget -q ${LNKB}${DEB_B1} 
	echo -e "Extracting wine . . ."
	dpkg-deb -x ${DEB_A1} wine-installer
	dpkg-deb -x ${DEB_A2} wine-installer
	dpkg-deb -x ${DEB_B1} wine-installer
	echo -e "Installing wine . . ."
	mv wine-installer/opt/wine* ~/wine
	
	# 下载 Wine 的依赖项
	# - 这些软件包是在 64 位的 RPiOS 上通过 multiarch 运行 box86/wine-i386 所需的
	sudo dpkg --add-architecture armhf && sudo apt-get update # enable multi-arch
	sudo apt-get install -y libasound2:armhf libc6:armhf libglib2.0-0:armhf libgphoto2-6:armhf libgphoto2-port12:armhf \
		libgstreamer-plugins-base1.0-0:armhf libgstreamer1.0-0:armhf libldap-2.4-2:armhf libopenal1:armhf libpcap0.8:armhf \
		libpulse0:armhf libsane1:armhf libudev1:armhf libusb-1.0-0:armhf libvkd3d1:armhf libx11-6:armhf libxext6:armhf \
		libasound2-plugins:armhf ocl-icd-libopencl1:armhf libncurses6:armhf libncurses5:armhf libcap2-bin:armhf libcups2:armhf \
		libdbus-1-3:armhf libfontconfig1:armhf libfreetype6:armhf libglu1-mesa:armhf libglu1:armhf libgnutls30:armhf \
		libgssapi-krb5-2:armhf libkrb5-3:armhf libodbc1:armhf libosmesa6:armhf libsdl2-2.0-0:armhf libv4l-0:armhf \
		libxcomposite1:armhf libxcursor1:armhf libxfixes3:armhf libxi6:armhf libxinerama1:armhf libxrandr2:armhf \
		libxrender1:armhf libxxf86vm1 libc6:armhf libcap2-bin:armhf # to run wine-i386 through box86:armhf on aarch64
		# This list found by downloading...
		#	wget https://dl.winehq.org/wine-builds/debian/dists/bullseye/main/binary-i386/wine-devel-i386_7.1~bullseye-1_i386.deb
		#	wget https://dl.winehq.org/wine-builds/debian/dists/bullseye/main/binary-i386/winehq-devel_7.1~bullseye-1_i386.deb
		#	wget https://dl.winehq.org/wine-builds/debian/dists/bullseye/main/binary-i386/wine-devel_7.1~bullseye-1_i386.deb
		# then `dpkg-deb -I package.deb`. Read output, add `:armhf` to packages in dep list, then try installing them on Pi aarch64.
		
	# - 这些软件包是在 RPiOS 上运行 box64/wine-amd64 所需的（box64 只能在 64 位操作系统上运行）
	sudo apt-get install -y libasound2:arm64 libc6:arm64 libglib2.0-0:arm64 libgphoto2-6:arm64 libgphoto2-port12:arm64 \
		libgstreamer-plugins-base1.0-0:arm64 libgstreamer1.0-0:arm64 libldap-2.4-2:arm64 libopenal1:arm64 libpcap0.8:arm64 \
		libpulse0:arm64 libsane1:arm64 libudev1:arm64 libunwind8:arm64 libusb-1.0-0:arm64 libvkd3d1:arm64 libx11-6:arm64 libxext6:arm64 \
		ocl-icd-libopencl1:arm64 libasound2-plugins:arm64 libncurses6:arm64 libncurses5:arm64 libcups2:arm64 \
		libdbus-1-3:arm64 libfontconfig1:arm64 libfreetype6:arm64 libglu1-mesa:arm64 libgnutls30:arm64 \
		libgssapi-krb5-2:arm64 libjpeg62-turbo:arm64 libkrb5-3:arm64 libodbc1:arm64 libosmesa6:arm64 libsdl2-2.0-0:arm64 libv4l-0:arm64 \
		libxcomposite1:arm64 libxcursor1:arm64 libxfixes3:arm64 libxi6:arm64 libxinerama1:arm64 libxrandr2:arm64 \
		libxrender1:arm64 libxxf86vm1:arm64 libc6:arm64 libcap2-bin:arm64
		# This list found by downloading...
		#	wget https://dl.winehq.org/wine-builds/debian/dists/bullseye/main/binary-amd64/wine-devel_7.1~bullseye-1_amd64.deb
		#	wget https://dl.winehq.org/wine-builds/debian/dists/bullseye/main/binary-amd64/wine-devel-amd64_7.1~bullseye-1_amd64.deb
		# then `dpkg-deb -I package.deb`. Read output, add `:arm64` to packages in dep list, then try installing them on Pi aarch64.	

	# 这些软件包是在 RPiOS 上运行 wine-staging 所需的（致谢: chills340）
	sudo apt install libstb0 -y
	cd ~/Downloads
	wget -r -l1 -np -nd -A "libfaudio0_*~bpo10+1_i386.deb" http://ftp.us.debian.org/debian/pool/main/f/faudio/ # Download libfaudio i386 no matter its version number
	dpkg-deb -xv libfaudio0_*~bpo10+1_i386.deb libfaudio
	sudo cp -TRv libfaudio/usr/ /usr/
	rm libfaudio0_*~bpo10+1_i386.deb # clean up
	rm -rf libfaudio # clean up

	# 安装符号链接
	sudo ln -s ~/wine/bin/wine /usr/local/bin/wine
	sudo ln -s ~/wine/bin/wine64 /usr/local/bin/wine64
	sudo ln -s ~/wine/bin/wineboot /usr/local/bin/wineboot
	sudo ln -s ~/wine/bin/winecfg /usr/local/bin/winecfg
	sudo ln -s ~/wine/bin/wineserver /usr/local/bin/wineserver
	sudo chmod +x /usr/local/bin/wine /usr/local/bin/wine64 /usr/local/bin/wineboot /usr/local/bin/winecfg /usr/local/bin/wineserver
```

## 安装 winetricks

Winetricks 是一个 bash 脚本，它使安装和配置任何所需的 Windows 核心系统软件包更加容易，这些软件包可能是某些 Windows 程序的依赖项。您可以使用 `apt` 安装它，或者按照下面的步骤手动安装。

```sh
sudo apt-get install cabextract -y                                                                   # winetricks needs this installed
sudo mv /usr/local/bin/winetricks /usr/local/bin/winetricks-old                                      # Backup old winetricks
cd ~/Downloads && wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks # Download
sudo chmod +x winetricks && sudo mv winetricks /usr/local/bin/                                       # Install
```

每当我们运行 winetricks 时，我们必须告诉 Box86 抑制其信息横幅，否则 winetricks 将会崩溃。Box86 的信息横幅可以通过在调用 winetricks 之前设置 `BOX86_NOBANNER=1` 环境变量来抑制（例如: `BOX86_NOBANNER=1 winetricks`）。

如果 `apt` 安装了 winetricks 的桌面菜单快捷方式（或者如果您为 winetricks 创建了自己的桌面快捷方式），则可能需要编辑该快捷方式以包含 Box86 的 BOX86_NOBANNER=1 环境变量。使用您喜欢的文本编辑器，编辑 `/usr/share/applications/winetricks.desktop` 并将 `Exec=winetricks --gui` 更改为 `Exec=env BOX86_NOBANNER=1 winetricks --gui`。

## 示例命令

创建一个 64 位的 wineprefix:

`wine64 wineboot` 或 `wine wineboot`（wineprefix 被创建在 `~/.wine/`）

`WINEPREFIX="$HOME/prefix64" wine wineboot`（wineprefix 被创建在 `~/prefix64/`） _注意: 您需要在每个命令之前调用 `WINEPREFIX="$HOME/prefix64"` 来使用这个 wineprefix。_

创建一个 32 位的 wineprefix:

`WINEARCH=win32 wine wineboot`（wineprefix 被创建在 `~/.wine/`）

强制退出 wine:

`wineserver -k`

运行 Wine 配置:

`winecfg`

使用 winetricks:

`winetricks -q corefonts vcrun2010 dotnet20sp1`  

_此命令将以静默方式依次安装三个软件包: Windows 核心字体、VC++ 2010 运行库和 .NET 2.0 SP1。 `-q` 是“安装静默/安静”命令。_

调用 Box86 的日志功能（使用 `BOX86_LOG=1` 或类似命令）会导致 winetricks 崩溃。

要查看 winetricks 可帮助您安装的所有不同的 Windows 软件包和库的列表，请运行 `winetricks list-all`  

## 其他注意事项

### Wineprefixes（以及 Wine 初始化）

当您第一次运行或启动 Wine (`wine wineboot`) 时，Wine 将创建一个新的用户环境，用于安装 Windows 软件。这个用户环境称为 "wineprefix"（或 "wine 瓶子"），默认位于 `~/.wine`（请注意，Linux 文件夹名字前面有一个 `.` 是 "隐藏" 文件夹）。将 wineprefix 视为 Wine 的虚拟 '硬盘'，用于安装软件和保存设置。wineprefix 是可移植且可删除的。有关更多 Wine 文档，请参阅 [WineHQ](https://www.winehq.org/documentation)。

如果您在默认的 wineprefix 中损坏了某些东西，您可以通过删除您的 `~/.wine` 目录（使用 `rm -rf ~/.wine` 命令）然后再次启动 wine 来重新开始 "新"。

### 移植 wineprefixes

如果在 Box86 中无法安装 Wine 中的软件，但您在普通的 x86 Linux 计算机上安装了 Wine，则可以将 wineprefix 从 x86 Linux 计算机复制到运行 Box86 的设备上。这最容易通过在您的 x86 Linux 计算机上将 `~/.wine` 文件夹打包为一个 tar 文件（`tar -cvf winebottle.tar ~/.wine`），将 tar 文件传输到您的设备上，然后在运行 Box86 和 Wine 的设备上解压缩 tar 文件（`tar -xf winebottle.tar`）来完成。将 wineprefix 打包为 tar 文件可以保留其中的任何符号链接。

### 切换不同版本的 Wine

某些 Wine 版本与特定软件更配合。最好安装已知与您想要运行的软件配合的 Wine 版本。您可以从三个主要的 Wine 开发分支中选择，分别称为 wine-stable、wine-devel 和 wine-staging。_请注意，wine-staging 分支在树莓派上需要额外的安装步骤。_

您整个 Wine 安装可以存在于 Linux 计算机的一个单独文件夹中。TwisterOS 假定您的 Wine 安装位于 `~/wine/` 目录中。实际上，您将 `wine` 文件夹放在哪个目录下并不重要，只要您在 `/usr/local/bin/` 目录中有指向 `wine` 文件夹的符号链接，这样当您在终端中输入 `wine` 时，Linux 就能找到 Wine。

您可以通过将旧的 `wine` 和 `.wine` 文件夹重命名为其他名称，然后将新的 `wine` 文件夹（包含您新版本的 Wine）放在原来的位置来更改运行的 Wine 版本。再次运行 `wine wineboot` 将使旧版本的 Wine 中的 wineprefix 迁移到您刚刚安装的新版本的 Wine 中可用。您可以使用 `wine --version` 命令检查您正在运行的 Wine 版本。
