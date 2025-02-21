本文档翻译自`sahlberg/libsmb2/README <https://github.com/sahlberg/libsmb2/blob/master/README>`_，翻译时文件的最新提交是``02783d6f32515375a2a9b13446917770550bdab4 Merge branch 'master' into Cleanups``，大部分借助于ChatGPT翻译，仅作为我个人的参考，如果你想查阅，建议看英文文档，因为我不确定我记录的中文翻译是否完整和正确。

Libsmb2 是一个用于访问或提供 SMB2/SMB3 共享的用户空间客户端/服务器库。
它具有高性能且完全异步。它支持 SMB 读/写命令的零拷贝以及复合命令。

Libsmb2 采用 LGPLv2.1 许可证发布。

API
===
Libsmb2 实现了三种不同的 API 用于访问远程 SMB 共享：

1、高级同步 POSIX 风格 API：
这是一个简单的 API，用于访问共享。
此 API 中的函数与相应的 POSIX 函数相似。
此 API 在 libsmb2.h 中描述。

2、高级异步 POSIX 风格 API：
这是一个高性能、完全非阻塞且异步的 API。
此 API 中的函数与相应的 POSIX 函数相似。
这是推荐的 API。
此 API 在 libsmb2.h 中描述。

3、低级异步 RAW API：
这是一个低级 API，提供对 SMB2 PDUs 和数据结构的直接访问。
此 API 在 libsmb2-raw.h 中描述。

Libsmb2 实现了一个同步 API 来运行 SMB 服务器。你可以实现自己的主循环来运行异步服务器。

SMB URL 格式
==============
目前 SMB URL 格式是 Samba 项目定义/使用的 URL 格式的一个小子集。
目标是最终支持完整的 URL 格式，从而使 URLs 在 Samba 工具和 Libsmb2 之间可互换，但我们还没有达到这个目标。

smb://[<domain>;][<user>@]<server>[:<port>]/<share>[/path][?arg=val[&arg=val]*]

<server> 可以是主机名、IPv4 或 IPv6 地址。

libsmb2 支持的参数有：
 sec=<mech>    : 用于认证到服务器的机制。默认是任何可用的机制，但可以通过以下方式覆盖：
		 krb5: 使用 Kerberos 通过 kinit 获取凭据。
		 krb5cc: 使用 Kerberos 通过凭据缓存获取凭据。
		 ntlmssp : 仅使用 NTLMSSP。
 vers=<version> : 要协商的 SMB 版本：
                  2: 协商任何版本的 SMB2
                  3: 协商任何版本的 SMB3
		  2.02, 2.10, 3.00, 3.02, 3.1.1 : 协商特定版本。
		  默认是协商任何 SMB2 或 SMB3 版本。
  seal          : 启用 SMB3 加密。
  sign          : 强制 SMB2/3 签名。
  timeout       : 取消命令的超时时间（秒）。
                  默认是 0：没有超时。
  ndr32         : DCERPC: 仅提供 NDR32 传输语法。（默认）
  ndr64         : DCERPC: 仅提供 NDR64 传输语法。
  ndr3264       : DCERPC: 提供 NDR32 和 NDR64 传输语法。
  le            : DCERPC: 以小端格式发送 PDU。
  be            : DCERPC: 以大端格式发送 PDU。
注意：
	使用 krb5cc 模式时，请使用 smb2_set_domain() 和 smb2_set_password() 在示例和应用程序中进行设置。

SMB 服务器
==========
在 examples/smb2-server-sync.c 中有一个示例服务器实现。库的服务器函数将一个函数指针数组传递给服务器，库将调用这些函数以处理每个客户端命令。你需要实现并返回每个命令的回复。示例模拟了一个包含少量文件的磁盘。每次客户端连接时，你的处理程序也将被调用，以便你在协商之前配置上下文。

身份验证
==============
Libsmb2 提供对 NTLMSSP 用户名/密码身份验证的内置支持。
它还可以选择性地与 (MIT) Kerberos 身份验证一起构建。

如果这些库存在，Libsmb2 将尝试与 Kerberos 一起构建。
你可以通过使用 --without-libkrb5 标志来强制构建不包含 Kerberos 支持的版本。在这种情况下，只会提供 NTLMSSP 身份验证。

MIT Kerberos
============
身份验证是通过 MIT Kerberos 实现的，它支持 KRB5 用于与 Active Directory 认证以及 NTLMSSP（可选）。

MIT Kerberos 也可以配置为提供 NTLMSSP 身份验证，
作为与内置 NTLMSSP 实现的替代方案，使用外部机制插件。
要使用这个 Kerberos/NTLMSSP 模块，你需要构建并安装 GSS-NTLMSSP，地址为 [https://github.com/simo5/gss-ntlmssp]。
如果你不确定，可以跳过此模块，只使用 Libsmb2 提供的 NTLMSSP 模块。

NTLM 身份验证
-------------------
NTLM 凭据存储在一个文本文件中，格式如下：
DOMAIN:USERNAME:PASSWORD
每个用户名一行。
你需要设置环境变量 NTLM_USER_FILE 来指向此文件。
对于每个本地用户账户，都需要在此文件中添加一条条目。

默认情况下，NTLM 身份验证将使用当前进程的用户名。
你可以通过在 SMB URL 中指定不同的用户名来覆盖此设置：
  smb://guest@server/share?sec=ntlmssp

你也可以通过调用以下函数在应用程序中提供用户名和密码：
  smb2_set_user(smb2, <username>);
  smb2_set_password(smb2, <password>);

（对于服务器，你不需要设置用户，因为客户端将提供。）

KRB5 身份验证
-------------------
当 Linux 工作站和文件服务器都属于 Active Directory 时，可以使用 Kerberos 身份验证。

你应该能够通过指定 sec=krb5 在 URL 中对文件服务器进行身份验证：
  smb://server/share?sec=krb5

应用程序需要使用 smb2_set_user()、smb2_set_password() 和 smb2_set_domain() 分别设置用户名、密码和域名 FQDN。

NTLM 凭据
================
这适用于内置的 NTLMSSP 实现以及使用 Kerberos 和 NTLMSSP 机制插件时。

NTLM 凭据存储在一个文本文件中，格式如下：
DOMAIN:USERNAME:PASSWORD
每个用户名一行。
你需要设置环境变量 NTLM_USER_FILE 来指向此文件。
对于每个本地用户账户，都需要在此文件中添加一条条目。

默认情况下，NTLM 身份验证将使用当前进程的用户名。
你可以通过在 SMB URL 中指定不同的用户名来覆盖此设置：
  smb://guest@server/share?sec=ntlmssp

你也可以通过调用以下函数在应用程序中提供用户名和密码：
  smb2_set_user(smb2, <username>);
  smb2_set_password(smb2, <password>);

（对于服务器，你不需要设置用户，因为客户端将提供。）

SMB2/3 签名
==============
签名在 KRB5、内置 NTLMSSP 支持以及 gss-ntlmssp 机制插件中得到支持。

SMB3 加密
===============
加密仅在 KRB5 或内置 NTLMSSP 支持下提供。
当使用 gss-ntlmssp 机制插件时，不支持加密。
可以通过 "seal" URL 参数或调用以下函数启用加密：
  smb3_set_seal(smb2, 1);

构建 LIBSMB2
===============

 Windows
---------------------------
你需要安装 CMake（https://cmake.org/）和 Visual Studio（https://www.visualstudio.com/）来为 Windows 构建 libsmb2（包括 Universal Windows Platform）。

请按照以下步骤构建共享库：

	mkdir build
	cd build
	cmake -G "Visual Studio 15 2017" ..
	cmake --build . --config RelWithDebInfo

静态库：

	mkdir build
	cd build
	cmake -G "Visual Studio 15 2017" -DBUILD_SHARED_LIBS=0 ..
	cmake --build . --config RelWithDebInfo

 macOS, iOS, tvOS, watchOS
---------------------------
你可以使用 AMSMB2（https://github.com/amosavian/AMSMB2）通用框架，
它包含了为 Apple 设备编译的 libsmb2。

它是用 Swift 编写的，但可以在 Swift 和 Objective-C 代码中使用。

如果你想重新构建 libsmb2，请按照以下步骤操作：

	git clone https://github.com/amosavian/AMSMB2
	cd AMSMB2/buildtools
	./build.sh

预编译的二进制文件默认不包括 Kerberos 支持。
如果你想构建带 Kerberos 支持的库，请执行此脚本：

	./build-with-krb5.sh


ESP32
-----
libsmb2 已经为 ESP32 微控制器预配置，使用 esp-idf 工具链（不支持 Arduino）。只需将此项目克隆到 ESP32 项目的 'components' 目录中，它将自动包含在构建过程中。

Raspberry Pi Pico W (RP2040)
----------------------------
libsmb2 将在 RP2040 上使用 gcc-arm-none-eabi、pico-sdk 和 FreeRTOS-Kernel 编译。
在 examples/picow 中有一个 CMakeLists.txt 文件，可以编辑以指向 pico-sdk 和 FreeRTOS-Kernel，然后将构建 libsmb2 和示例——这可以作为起点。
在 include/picow 中有一些用于 lwip、FreeRTOS 和任何使用 libsmb2 构建的应用程序的配置文件。这些文件也可以作为起点并根据需要进行调整。

在 RP2040 上，除了 RP2040 定义（如 PICO_BOARD=pico_w）外，libsmb2 所需的唯一定义是 PICO_PLATFORM。

Playstation 2
------------
EE，Emotion-Engine，是 PS2 的主 CPU。
要为 PS2 EE 编译 libsmb2，首先安装 PS2 工具链和 PS2 SDK 并进行设置。

要构建 libsmb2.a，作为 EE tcpip 堆栈的 libsmb2 版本：
  $ make -f Makefile.platform clean
  $ make -f Makefile.platform ps2_ee_install

EE 使用 IOP 堆栈，这是 EE 版本的不同，当 LWIP 堆栈运行在 IOP 上时（libsmb2_rpc 并链接 -lps2ips）

要构建 libsmb2_rpc.a，作为运行在 IOP tcpip 堆栈上的 EE 版本：
  $ make -f Makefile.platform clean
  $ make -f Makefile.platform ps2_rpc_install

IOP，IO-Processor 是 PS2 的辅助 CPU。
该库用于构建 smb2man.irx 模块，但在安装时未包含该库，要为 PS2 IOP 和 smb2man.irx 安装 libsmb2，首先安装 PS2 工具链和 PS2SDK 并进行设置。

然后要构建 libsmb2，运行：
  $ make -f Makefile.platform clean
  $ make -f Makefile.platform ps2_iop_install
  $ make -f Makefile.platform clean  
  $ make -f Makefile.platform ps2_irx_install

PlayStation 3
-------------
PPU，PowerPC，是 PS3 的主 CPU。
要为 PS3 PPU 编译 libsmb2，首先安装 PS3 工具链和 PSL1GHT SDK 并进行设置。

然后要构建 libsmb2，运行：
  $ cd lib
  $ make -f Makefile.PS3_PPU install

该过程将把生成的 libsmb2.a 和 include/smb2 头文件复制到你的 PSL1GHT SDK portlibs 文件夹中。

PlayStation Vita
-------------
ARM® Cortex™ - A9 核心（4 核），是 PSVITA 的主 CPU。
要为 PSVITA 编译 libsmb2，首先使用 vdpm 安装 VitaSDK。

然后要构建 libsmb2，运行：
  $ make vita_install -f Makefile.platform

该过程将把生成的 libsmb2.a 和 include/smb2 头文件复制到你的 VitaSDK libs 文件夹中。

PlayStation 4
-------------
x86_64 是 PS4 的主 CPU。
要为 PS4 PPU 编译 libsmb2，首先安装 PS4 工具链和 OpenOrbis SDK 并进行设置。

然后要构建 libsmb2，运行：
  $ make -f Makefile.platform ps4_install

该过程将把生成的 libsmb2.a 和 include/smb2 头文件复制到你的 OpenOrbis SDK include 文件夹中。

Nintendo 3DS
-------------
Nintendo 3DS 的 CPU 是 ARM11 MPCore 变种。
要为 Nintendo 3DS 编译 libsmb2，首先安装 devkitPro 和 libctru 进行设置。

然后要构建 libsmb2，运行：
  $ make -f Makefile.platform 3ds_install

该过程将把生成的 libsmb2.a 和 include/smb2 头文件复制到你的 devkitPro 3ds portlibs 文件夹中。

Nintendo Switch
-------------
Nintendo Switch 的 CPU 是自定义 Nvidia Tegra X1。
要为 Nintendo Switch 编译 libsmb2，首先安装 devkitPro 和 libnx 进行设置。

然后要构建 libsmb2，运行：
  $ cd lib
  $ make -f Makefile.platform switch_install

该过程将把生成的 libsmb2.a 和 include/smb2 头文件复制到你的 devkitPro switch portlibs 文件夹中。

Nintendo Wii
-------------
Nintendo Wii 的 CPU 是 Broadway PowerPC 处理器。
要为 Nintendo Wii 编译 libsmb2，首先使用 pacman 安装 devkitPro 和 libogc 进行设置。

然后要构建 libsmb2，运行：
  $ make -f Makefile.platform wii_install

该过程将把生成的 libsmb2.a 和 include/smb2 头文件复制到你的 devkitPro wii portlibs 文件夹中。

Nintendo Gamecube
-------------
Nintendo GameCube 的 CPU 是 IBM "Gekko" PowerPC CPU。
要为 Gamecube 编译 libsmb2，首先使用 pacman 安装 devkitPro 和 libogc 进行设置。

然后要构建 libsmb2，运行：
  $ make -f Makefile.platform gc_install

该过程将把生成的 libsmb2.a 和 include/smb2 头文件复制到你的 devkitPro gamecube portlibs 文件夹中。

Nintendo DS 
-------------
Nintendo DS 的 CPU 是 ARM7TDMI 和 ARM946E-S。
要为 Nintendo DS 编译 libsmb2，首先使用 pacman 安装 devkitPro 和 libnds 进行设置。

然后要构建 libsmb2，运行：
  $ cd lib
  $ make -f Makefile.platform ds_install

该过程将把生成的 libsmb29.a 和 include/smb2 头文件复制到你的 devkitPro ds portlibs 文件夹中的 lib/arm9。

Nintendo WII-U
-------------
Nintendo Wii-U 的 CPU 是 IBM "Espresso" PowerPC 基于 45 纳米工艺，具有 4 核，主频为 1.24 GHz。
要为 Nintendo WII-U 编译 libsmb2，首先使用 pacman 安装 devkitPro 和 libwut 进行设置。

然后要构建 libsmb2，运行：
  $ cd lib
  $ make -f Makefile.platform wiiu_install

该过程将把生成的 libsmb2.a 和 include/smb2 头文件复制到你的 devkitPro wiiu portlibs 文件夹中。

Amiga (AmigaOS)
----------------------
AmigaOS 是一种操作系统，主处理器是 PowerPC 微处理器。
有 3 个版本：
AmigaOS4(Makefile.AMIGA)
AmigaOS3(Makefile.AMIGA_OS3)
AmigaAROS(Makefile.AMIGA_AROS)
要为 AmigaOS 编译 libsmb2，你需要设置 newlib.library V53.40 或更高版本（或 V53.30，如 4.1 FE 中所包含）和 filesysbox.library 54.4 或更高版本进行设置。

然后根据你的 AmigaOS 系统选择相应的 makefile 并执行：
  $ cd lib
  $ make -f Makefile.YOUR_AMIGA_OS_USED clean install

该过程将把生成的 libsmb2.a 和 include/smb2 头文件复制到 lib 文件夹中的 bin 文件夹。

注意：Amiga AROS 是 AmigaOS 的开源版本，因此除非使用 AmigaAROS，否则不要构建此版本。

Dreamcast (KallistiOS)
----------------------
Hitachi SH4（小端模式）是 Dreamcast 的主 CPU。
要为 Dreamcast 编译 libsmb2，首先安装 KOS 工具链并进行设置。

然后要构建 libsmb2，运行：
  $ cd lib
  $ make -f Makefile.platform clean dc_install

该过程将把生成的 libsmb2.a 和 include/smb2 头文件复制到 KallistiOS 工具链的安装位置 addons 文件夹。
注意：目前还没有 libsmb2 的 kos-ports 条目，但一旦创建了包含 Dreamcast 支持的版本发布，从 kos-ports 安装将成为首选安装方法。

Xbox (Xbox XDK)
----------------------
Xbox 的 CPU 是定制的 Intel Pentium III Coppermine 处理器，仅支持小端值。
要为 Xbox 编译 libsmb2，首先安装 Xbox XDK（包括所有功能），Microsoft Visual C++ 2003 Professional 和 Windows XP。

然后要构建 libsmb2，进入 Xbox 文件夹
并打开提供的 .sln 文件，然后点击绿色按钮进行构建：

该过程将生成 libsmb2.lib。然后你可以将包含文件和 .lib 文件复制到你的 Xbox 项目中。

Xbox 360 (Xbox 360 SDK)
----------------------
Xbox 360 的 CPU 是 PPC（PowerPC）Xenon，仅支持大端值。
要为 Xbox 360 编译 libsmb2，首先安装 Xbox 360 SDK（包括所有功能），Microsoft Visual C++ 2010 Ultimate 和 Windows XP（推荐）或 Windows 7。

然后要构建 libsmb2，进入 Xbox 360 文件夹
并打开提供的 .sln 文件，然后点击绿色按钮进行构建：

该过程将生成 libsmb2.lib。然后你可以将包含文件和 .lib 文件复制到你的 Xbox 360 项目中。

注意：这两个端口基于 BDC（Brent De Cartet）的 XBMC-360 端口，现在正在更新为 libsmb2 标准，以提供最佳性能。
