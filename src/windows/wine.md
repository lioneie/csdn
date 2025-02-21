[点击这里查看配套的教学视频](https://chenxiaosong.com/video.html)。

在Linux操作系统要运行Windows的`exe`程序，可以使用`wine`，还能跨cpu运行呢。

# 运行环境

源码安装之前，也建议先通过apt安装wine，安装完后运行环境就准备好了。

- [WineHQ - Run Windows applications on Linux, BSD, Solaris and macOS](https://www.winehq.org/)
- [Winetricks - WineHQ Wiki](https://wiki.winehq.org/Winetricks)

## x86_64

x86_64下使能32位架构:
```sh
sudo dpkg --add-architecture i386
sudo apt-get update -y
```

x86_64参考[Ubuntu WineHQ Repository - WineHQ Wiki](https://wiki.winehq.org/Ubuntu)，有些网络可能安装不了，可以尝试换个网络（也有可能是服务器出了问题，稍后再试试）:
```sh
sudo mkdir -pm755 /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources
sudo apt-get update -y
# Stable branch
sudo apt install --install-recommends winehq-stable -y
```

如果无法安装，可以下载报错信息中`xxxx.deb`文件的链接，复制到位置`/var/cache/apt/archives`，再重新安装。

## aarch64

aarch64下使能32位架构:
```sh
sudo dpkg --add-architecture armhf
sudo apt-get update -y
```

aarch64用如下命令安装:
```sh
sudo apt install -y wine
```

## 运行`exe`程序

可以尝试下载并直接运行免安装的[putty](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html)，x86_64架构下执行`wine putty-x86_64.exe`（下载x86_64版本），aarch64架构下执行`wine64 putty-arm64.exe`（下载arm64版本）。第一次运行时会提示: “Wine未找到到（两个到是什么鬼）用于支持.NET应用的wine-mono组件。Wine可以自动并下载安装该组件。注意: 推荐您安装为发行版定制的软件包。具体请参看 https://wiki.winehq.org/Mono 。“点击”安装“。

x86_64下安装并运行[微信](https://pc.weixin.qq.com/?lang=en_US)，注意c盘的位置在`${HOME}/.wine/drive_c/`，`wine WeChatSetup.exe`安装后，先进入`cd "${HOME}/.wine/drive_c/Program Files/Tencent/WeChat/[3.9.9.43]"`（有空格），再运行`wine WeChat.exe`。

中文字体显示有问题，先安装`sudo apt install winetricks -y`，如果报错不能用，可以下载[源码文件](https://github.com/Winetricks/winetricks/blob/master/src/winetricks)到`/usr/bin/winetricks`，并执行`sudo chown root:root /usr/bin/winetricks`和`sudo chmod 755 /usr/bin/winetricks`，但不知道搞什么东西，始终没法安装字体。

最好是安装ubuntu中文或麒麟系统，这样中文显示就默认没有问题。

# 编译环境

- [gitlab源码](https://gitlab.winehq.org/wine/wine)
- [Developers - WineHQ Wiki](https://wiki.winehq.org/Developers)

## 公共依赖软件

首先安装[Building Wine - WineHQ Wiki](https://wiki.winehq.org/Building_Wine)中`Satisfying Build Dependencies`一节提到的依赖，其中ubuntu安装debian一列的软件:
```sh
# Generally necessary
sudo apt install -y gcc-mingw-w64 libasound2-dev libpulse-dev libdbus-1-dev libfontconfig-dev libfreetype-dev libgnutls28-dev libgl-dev libunwind-dev libx11-dev libxcomposite-dev libxcursor-dev libxfixes-dev libxi-dev libxrandr-dev libxrender-dev libxext-dev
# Needed for many applications
sudo apt install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libosmesa6-dev libsdl2-dev libudev-dev libvulkan-dev
# Rare or domain-specific
sudo apt install -y libcapi20-dev libcups2-dev libgphoto2-dev libsane-dev libkrb5-dev samba-dev ocl-icd-opencl-dev libpcap-dev libusb-1.0-0-dev libv4l-dev
```
注意以上命令只是我自己整理方便后续部署时查阅，如果你安装的话最好查看网页，因为我不确定是否会新增一些依赖，毕竟wine软件在不断的发展。

上面的开发依赖软件安装后，运行`./configure`后还是会报错或警告，根据报错或警告信息继续安装以下软件:
```sh
# 报错
sudo apt-get install -y flex bison gettext
sudo apt install -y libpcsclite-dev # x86_64下没用，还是报 libpcsclite not found, smart cards won't be supported.
sudo apt install -y libwayland-dev # 安装了还是报 Wayland 32-bit development files not found, the Wayland driver won't be supported.

## opengl，用 glxinfo | grep "OpenGL" 能看到输出，但安装完后还是会有告警信息: No OpenGL library found on this system. OpenGL and Direct3D won't be supported.
### 所以opengl的告警应该和以下软件无关，而是和i386相关的软件中的某个相关（不确定是哪个）
### sudo apt-get install -y mesa-utils libglu1-mesa-dev freeglut3 freeglut3-dev
```

[Open Sound System Driver](http://www.opensound.com/download.cgi)驱动安装。

## x86架构编译环境

```sh
sudo apt install -y gcc-multilib # i386
sudo apt-get install -y libx11-dev:i386 libfreetype-dev:i386
sudo apt-get install -y libxrender-dev:i386 libgnutls28-dev:i386 libvulkan-dev:i386 libxcursor-dev:i386 libxi-dev:i386 libxext-dev:i386 libxrandr-dev:i386 libxfixes-dev:i386 libxcomposite-dev:i386 libosmesa6-dev:i386 ocl-icd-opencl-dev:i386 libpcap-dev:i386 libdbus-1-dev:i386 libsane-dev:i386 libusb-1.0-0-dev:i386 libv4l-dev:i386 libgphoto2-dev:i386 libpulse-dev:i386 libudev-dev:i386 libsdl2-dev:i386 libcapi20-dev:i386 libcups2-dev:i386 libfontconfig-dev:i386 
sudo apt-get install -y libgstreamer1.0-dev:i386 libgstreamer-plugins-base1.0-dev:i386
sudo apt install -y libwayland-dev:i386 # 安装了还是报 Wayland 32-bit development files not found, the Wayland driver won't be supported.

# 以下软件不能安装，不能安装，不能安装，安装了你的系统就完了，写出来只是记录一下曾经尝试的过程

# 本来是为了解决 libkrb5 32-bit development files not found (or too old), Kerberos won't be supported.
# sudo mv /usr/bin/krb5-config.mit /usr/bin/krb5-config.mit.bak # 不执行这一步会出错
# sudo apt-get install libkrb5-dev:i386 # 不加 -y

# 本来是为了解决 libnetapi not found, Samba NetAPI won't be supported.
# 但安装后图形界面没了，所以不能安装这个软件
# sudo apt-get install samba-dev:i386

# 安装后图形界面没了，所以不能安装这个软件，其实这个软件并不需要
# sudo apt-get install -y libpcsclite-dev:i386
```

## aarch64架构编译环境

```sh
sudo apt-get install -y libx11-dev:armhf libfreetype-dev:armhf
sudo apt-get install -y libxrender-dev:armhf libgnutls28-dev:armhf libvulkan-dev:armhf libxcursor-dev:armhf libxi-dev:armhf libxext-dev:armhf libxrandr-dev:armhf libxfixes-dev:armhf libxcomposite-dev:armhf libosmesa6-dev:armhf ocl-icd-opencl-dev:armhf libpcap-dev:armhf libdbus-1-dev:armhf libsane-dev:armhf libusb-1.0-0-dev:armhf libv4l-dev:armhf libgphoto2-dev:armhf libpulse-dev:armhf libudev-dev:armhf libsdl2-dev:armhf libcapi20-dev:armhf libcups2-dev:armhf libfontconfig-dev:armhf 
sudo apt-get install -y libgstreamer1.0-dev:armhf libgstreamer-plugins-base1.0-dev:armhf
sudo apt install -y libwayland-dev:armhf # 安装了还是报 Wayland 32-bit development files not found, the Wayland driver won't be supported.
sudo apt install -y clang lld
```

## 编译

再运行以下命令编译安装:
```sh
git clone https://gitlab.winehq.org/wine/wine.git wine-dirs/wine-source
mkdir wine-dirs/wine64-build/ -p
mkdir wine-dirs/wine32-build/ -p
# wine源码在 wine-dirs/wine-source
cd wine-dirs/wine64-build/ # 先到64位编译目录
../wine-source/configure --enable-win64 --prefix=/home/sonvhi/sw/wine
make -j12 # 12换成你的cpu核数
make install -j12 # 这时还无法运行微信

cd ../wine32-build/ # 再到32位编译目录
# x86_64，前面可以加 PKG_CONFIG_PATH=/usr/lib32，也可不加
../wine-source/configure --with-wine64=../wine64-build --prefix=/home/sonvhi/sw/wine
# aarch64
../wine-source/configure --with-wine64=../wine64-build --prefix=/home/sonvhi/sw/wine
make -j12
make install -j12 # 这时可以运行微信了
```

# aarch64 ubuntu22.04运行`x86_64`的wine

aarch64下还要安装box软件，32位box安装参考[ptitSeb/box86/blob/master/docs/COMPILE.md](https://github.com/ptitSeb/box86/blob/master/docs/COMPILE.md)，64位box安装参考[ptitSeb/box64/blob/main/docs/COMPILE.md](https://github.com/ptitSeb/box64/blob/main/docs/COMPILE.md)（要安装`box64`而不是`box64-arm64`）。

wine的环境请参考[box64 Installing Wine64翻译](https://chenxiaosong.com/src/translation/wine/box64-docs-X64WINE.html)和[box86 Installing Wine (and winetricks)翻译](https://chenxiaosong.com/src/translation/wine/box86-docs-X86WINE.html)。

```sh
rm -rf ~/.wine-old; mv ~/.wine ~/.wine-old
# 下载 Wine 的依赖项
# - 这些软件包是在 64 位的 RPiOS 上通过 multiarch 运行 box86/wine-i386 所需的
sudo dpkg --add-architecture armhf && sudo apt-get update # enable multi-arch
sudo apt-get install -y libasound2:armhf libc6:armhf libglib2.0-0:armhf libgphoto2-6:armhf libgphoto2-port12:armhf \
    libgstreamer-plugins-base1.0-0:armhf libgstreamer1.0-0:armhf libopenal1:armhf libpcap0.8:armhf \
    libpulse0:armhf libsane1:armhf libudev1:armhf libusb-1.0-0:armhf libvkd3d1:armhf libx11-6:armhf libxext6:armhf \
    libasound2-plugins:armhf ocl-icd-libopencl1:armhf libncurses6:armhf libncurses5:armhf libcap2-bin:armhf libcups2:armhf \
    libdbus-1-3:armhf libfontconfig1:armhf libfreetype6:armhf libglu1-mesa:armhf libglu1:armhf libgnutls30:armhf \
    libgssapi-krb5-2:armhf libkrb5-3:armhf libodbc1:armhf libosmesa6:armhf libsdl2-2.0-0:armhf libv4l-0:armhf \
    libxcomposite1:armhf libxcursor1:armhf libxfixes3:armhf libxi6:armhf libxinerama1:armhf libxrandr2:armhf \
    libxrender1:armhf libxxf86vm1 libc6:armhf libcap2-bin:armhf # to run wine-i386 through box86:armhf on aarch64
# sudo apt-get install -y libldap-2.4-2:armhf # ubuntu下找不到
# - 这些软件包是在 RPiOS 上运行 box64/wine-amd64 所需的（box64 只能在 64 位操作系统上运行）
sudo apt-get install -y libasound2:arm64 libc6:arm64 libglib2.0-0:arm64 libgphoto2-6:arm64 libgphoto2-port12:arm64 \
    libgstreamer-plugins-base1.0-0:arm64 libgstreamer1.0-0:arm64 libopenal1:arm64 libpcap0.8:arm64 \
    libpulse0:arm64 libsane1:arm64 libudev1:arm64 libunwind8:arm64 libusb-1.0-0:arm64 libvkd3d1:arm64 libx11-6:arm64 libxext6:arm64 \
    ocl-icd-libopencl1:arm64 libasound2-plugins:arm64 libncurses6:arm64 libncurses5:arm64 libcups2:arm64 \
    libdbus-1-3:arm64 libfontconfig1:arm64 libfreetype6:arm64 libglu1-mesa:arm64 libgnutls30:arm64 \
    libgssapi-krb5-2:arm64 libkrb5-3:arm64 libodbc1:arm64 libosmesa6:arm64 libsdl2-2.0-0:arm64 libv4l-0:arm64 \
    libxcomposite1:arm64 libxcursor1:arm64 libxfixes3:arm64 libxi6:arm64 libxinerama1:arm64 libxrandr2:arm64 \
    libxrender1:arm64 libxxf86vm1:arm64 libc6:arm64 libcap2-bin:arm64
# sudo apt-get install -y libldap-2.4-2:arm64 libjpeg62-turbo:arm64 # ubuntu下找不到
```

在`x86_64`的机器上编译好`wine`后，复制到`aarch64`的家目录下，然后执行以下命令:
```sh
# 安装符号链接
sudo rm /usr/local/bin/wine /usr/local/bin/wine64 /usr/local/bin/wineboot /usr/local/bin/winecfg /usr/local/bin/wineserver
sudo ln -s ${PWD}/wine/bin/wine /usr/local/bin/wine
sudo ln -s ${PWD}/wine/bin/wine64 /usr/local/bin/wine64
sudo ln -s ${PWD}/wine/bin/wineboot /usr/local/bin/wineboot
sudo ln -s ${PWD}/wine/bin/winecfg /usr/local/bin/winecfg
sudo ln -s ${PWD}/wine/bin/wineserver /usr/local/bin/wineserver
sudo chmod +x /usr/local/bin/wine /usr/local/bin/wine64 /usr/local/bin/wineboot /usr/local/bin/winecfg /usr/local/bin/wineserver
```

这时就可以运行`x86_64`架构下的`exe`程序:
```sh
which wine64 # 输出 /usr/local/bin/wine64
box64 wine64 --version # wine-9.6-73-g30a70548796
box64 wine64 putty-x86_64.exe
box64 wine64 WeChatSetup-x86_64.exe
```

# aarch64 ubuntu20.04运行`x86_64`的wine

因为在`x86_64` ubuntu20.04上无法编译最新wine，所以要在`x86_64` ubuntu22.04的机器上编译好`wine`。还有除了以下 Wine 的依赖项外，其他都和ubuntu22.04步骤一样。
```sh
sudo dpkg --add-architecture armhf && sudo apt-get update # enable multi-arch

# 下载 Wine 的依赖项
# - 这些软件包是在 64 位的 RPiOS 上通过 multiarch 运行 box86/wine-i386 所需的
sudo apt-get install -y libasound2:armhf libc6:armhf libglib2.0-0:armhf libgphoto2-6:armhf libgphoto2-port12:armhf \
    libgstreamer-plugins-base1.0-0:armhf libgstreamer1.0-0:armhf libopenal1:armhf libpcap0.8:armhf \
    libpulse0:armhf libsane1:armhf libudev1:armhf libusb-1.0-0:armhf libvkd3d1:armhf libx11-6:armhf libxext6:armhf \
    libasound2-plugins:armhf ocl-icd-libopencl1:armhf libncurses6:armhf libncurses5:armhf libcap2-bin:armhf libcups2:armhf \
    libdbus-1-3:armhf libfontconfig1:armhf libfreetype6:armhf libgnutls30:armhf \
    libgssapi-krb5-2:armhf libkrb5-3:armhf libodbc1:armhf libosmesa6:armhf libsdl2-2.0-0:armhf libv4l-0:armhf \
    libxcomposite1:armhf libxcursor1:armhf libxfixes3:armhf libxi6:armhf libxinerama1:armhf libxrandr2:armhf \
    libxrender1:armhf libxxf86vm1 libc6:armhf libcap2-bin:armhf libldap-2.4-2:armhf # to run wine-i386 through box86:armhf on aarch64
# sudo apt install -y libglu1-mesa:armhf libglu1:armhf # ubuntu20.04找不到
# - 这些软件包是在 RPiOS 上运行 box64/wine-amd64 所需的（box64 只能在 64 位操作系统上运行）
sudo apt-get install -y libasound2:arm64 libc6:arm64 libglib2.0-0:arm64 libgphoto2-6:arm64 libgphoto2-port12:arm64 \
    libgstreamer-plugins-base1.0-0:arm64 libgstreamer1.0-0:arm64 libopenal1:arm64 libpcap0.8:arm64 \
    libpulse0:arm64 libsane1:arm64 libudev1:arm64 libunwind8:arm64 libusb-1.0-0:arm64 libvkd3d1:arm64 libx11-6:arm64 libxext6:arm64 \
    ocl-icd-libopencl1:arm64 libasound2-plugins:arm64 libncurses6:arm64 libncurses5:arm64 libcups2:arm64 \
    libdbus-1-3:arm64 libfontconfig1:arm64 libfreetype6:arm64 libglu1-mesa:arm64 libgnutls30:arm64 \
    libgssapi-krb5-2:arm64 libkrb5-3:arm64 libodbc1:arm64 libosmesa6:arm64 libsdl2-2.0-0:arm64 libv4l-0:arm64 \
    libxcomposite1:arm64 libxcursor1:arm64 libxfixes3:arm64 libxi6:arm64 libxinerama1:arm64 libxrandr2:arm64 \
    libxrender1:arm64 libxxf86vm1:arm64 libc6:arm64 libcap2-bin:arm64 libldap-2.4-2:arm64
# sudo apt-get install -y libjpeg62-turbo:arm64 # ubuntu下找不到
```

<!-- 暂时有点问题，armhf安装出错
# 麒麟桌面版运行`x86_64`的wine

因为在`x86_64` 麒麟上无法编译最新wine，所以要在`x86_64` ubuntu22.04的机器上编译好`wine`。还有除了以下 Wine 的依赖项外，其他都和ubuntu22.04步骤一样。
```sh
sudo dpkg --add-architecture armhf && sudo apt-get update # enable multi-arch

# 下载 Wine 的依赖项
# - 这些软件包是在 64 位的 RPiOS 上通过 multiarch 运行 box86/wine-i386 所需的
sudo apt-get install -y libasound2:armhf libc6:armhf libgphoto2-port12:armhf \
    libopenal1:armhf libpcap0.8:armhf \
    libpulse0:armhf libudev1:armhf libusb-1.0-0:armhf libvkd3d1:armhf libx11-6:armhf libxext6:armhf \
    libasound2-plugins:armhf ocl-icd-libopencl1:armhf libncurses6:armhf libncurses5:armhf libcap2-bin:armhf libcups2:armhf \
    libdbus-1-3:armhf libfreetype6:armhf libgnutls30:armhf \
    libgssapi-krb5-2:armhf libkrb5-3:armhf libodbc1:armhf libosmesa6:armhf libsdl2-2.0-0:armhf libv4l-0:armhf \
    libxcomposite1:armhf libxcursor1:armhf libxfixes3:armhf libxi6:armhf libxinerama1:armhf libxrandr2:armhf \
    libxrender1:armhf libxxf86vm1 libc6:armhf libcap2-bin:armhf libldap-2.4-2:armhf # to run wine-i386 through box86:armhf on aarch64
# sudo apt-get install -y libfontconfig1:armhf libglib2.0-0:armhf libgphoto2-6:armhf libgstreamer-plugins-base1.0-0:armhf libgstreamer1.0-0:armhf libsane1:armhf # 依赖有问题
# sudo apt install -y libglu1-mesa:armhf libglu1:armhf # ubuntu20.04找不到
# - 这些软件包是在 RPiOS 上运行 box64/wine-amd64 所需的（box64 只能在 64 位操作系统上运行）
sudo apt-get install -y libasound2:arm64 libc6:arm64 libglib2.0-0:arm64 libgphoto2-6:arm64 libgphoto2-port12:arm64 \
    libgstreamer-plugins-base1.0-0:arm64 libgstreamer1.0-0:arm64 libopenal1:arm64 libpcap0.8:arm64 \
    libpulse0:arm64 libsane1:arm64 libudev1:arm64 libunwind8:arm64 libusb-1.0-0:arm64 libvkd3d1:arm64 libx11-6:arm64 libxext6:arm64 \
    ocl-icd-libopencl1:arm64 libasound2-plugins:arm64 libncurses6:arm64 libncurses5:arm64 libcups2:arm64 \
    libdbus-1-3:arm64 libfontconfig1:arm64 libfreetype6:arm64 libglu1-mesa:arm64 libgnutls30:arm64 \
    libgssapi-krb5-2:arm64 libkrb5-3:arm64 libodbc1:arm64 libosmesa6:arm64 libsdl2-2.0-0:arm64 libv4l-0:arm64 \
    libxcomposite1:arm64 libxcursor1:arm64 libxfixes3:arm64 libxi6:arm64 libxinerama1:arm64 libxrandr2:arm64 \
    libxrender1:arm64 libxxf86vm1:arm64 libc6:arm64 libcap2-bin:arm64 libldap-2.4-2:arm64
# sudo apt-get install -y libjpeg62-turbo:arm64 # ubuntu下找不到
```
-->

# wine-ce

- [gitee仓库](https://gitee.com/wine-ce)
- [b站视频](https://www.bilibili.com/video/BV1gv4y1578t/)
- [浅谈二进制翻译软件架构](https://www.bilibili.com/opus/781135473404805193)
- [b站: ARM转译x86项目Wine-CE测试(作者: 我梦见了电子羊)](https://www.bilibili.com/video/BV1ps4y1G7YZ/)