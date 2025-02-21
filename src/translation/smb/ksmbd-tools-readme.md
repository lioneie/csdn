本文档翻译自[cifsd-team/ksmbd-tools/README.md](https://github.com/cifsd-team/ksmbd-tools/blob/1cbb9277cf48479036e5dee9f23e0ea6d47397c7/README.md)，翻译时文件的最新提交是`1cbb9277cf48479036e5dee9f23e0ea6d47397c7 ksmbd-tools: make share/user non-options and unify option naming`，大部分借助于ChatGPT翻译，仅作为我个人的参考，如果你想查阅，建议看英文文档，因为我不确定我记录的中文翻译是否完整和正确。

# ksmbd-tools

ksmbd-tools 是 ksmbd 内核服务器 的一组用户空间实用程序，ksmbd 已在 Linux 5.15 版本中合并到主线。

## Building and Installing

您应该首先检查您的发行版是否有 `ksmbd-tools` 的软件包，如果有的话，考虑通过包管理器安装它。否则，请按照以下说明自行构建它。可以使用 GNU Autotools 或 Meson 构建系统。

Debian 及其衍生版本的依赖项: `git` `gcc` `pkgconf` `autoconf`  
`automake` `libtool` `make` `meson` `ninja-build` `gawk` `libnl-3-dev`  
`libnl-genl-3-dev` `libglib2.0-dev`

RHEL 及其衍生版本的依赖项: `git` `gcc` `pkgconf` `autoconf`  
`automake` `libtool` `make` `meson` `ninja-build` `gawk` `libnl3-devel`  
`glib2-devel`

示例构建和安装:
```sh
git clone https://github.com/cifsd-team/ksmbd-tools.git
cd ksmbd-tools

# autotools build

./autogen.sh
./configure --with-rundir=/run

make
sudo make install

# meson build

mkdir build
cd build
meson -Drundir=/run ..

ninja
sudo ninja install
```

默认情况下，实用程序位于 `/usr/local/sbin`，它们默认使用的文件位于  
`/usr/local/etc` 下的 `ksmbd` 目录中。

如果您想将 ksmbd-tools 安装在 `/usr` 下，这可能会与使用包管理器安装的  
ksmbd-tools 冲突，请在 `configure` 或 `meson` 中添加 `--prefix=/usr` 和  
`--sysconfdir=/etc` 作为选项。在这种情况下，实用程序位于 `/usr/sbin`，它们  
默认使用的文件位于 `/etc` 下的 `ksmbd` 目录中。

很可能您应该将 `--with-rundir` 或 `-Drundir` 作为选项添加到 `configure` 或  
`meson` 中。这是因为您的系统可能没有在默认值给定的目录下挂载 tmpfs 文件系统。  
常见的选择是 `/run`、`/var/run` 或 `/tmp`。ksmbd-tools 使用该目录存放每个进程  
可修改的数据，即 `ksmbd.lock` 文件，该文件保存 `ksmbd.mountd` 管理进程的 PID。  
如果您的 autoconf 支持，您也可以选择将 `--runstatedir` 作为选项添加到 `configure` 中。

如果您有 systemd 并且它至少满足所需的最低版本，构建将安装 `ksmbd.service` 单元文件。  
该单元文件支持常见的单元命令，并处理加载内核模块。请注意，单元文件的位置可能与  
使用包管理器安装的 ksmbd-tools 冲突。您可以绕过版本检查并自己选择单元文件目录，  
通过将 `--with-systemdsystemunitdir=DIR` 或 `-Dsystemdsystemunitdir=DIR` 作为选项添加到  
`configure` 或 `meson` 中。

## Usage

帮助文档:
```sh
man 8 ksmbd.addshare
man 8 ksmbd.adduser
man 8 ksmbd.control
man 8 ksmbd.mountd
man 5 ksmbd.conf
man 5 ksmbdpwd.db
```

示例会话:
```sh
# 如果你使用 autoconf 默认设置自行构建并安装了 ksmbd-tools，工具位于 /usr/local/sbin'，默认用户数据库是 /usr/local/etc/ksmbd/ksmbdpwd.db'，默认配置文件是 `/usr/local/etc/ksmbd/ksmbd.conf'。

# 否则，工具可能位于 /usr/sbin'，默认用户数据库是 /etc/ksmbd/ksmbdpwd.db'，默认配置文件是 `/etc/ksmbd/ksmbd.conf'。

# 创建共享路径目录。共享使用其底层文件系统在此目录中存储文件。
mkdir -vp $HOME/MyShare

# 将共享添加到默认配置文件。请注意，ksmbd.addshare 不进行变量扩展。没有 --add 时，如果 MyShare 存在，ksmbd.addshare 将更新 MyShare。
sudo ksmbd.addshare --add \
                    --option "path = $HOME/MyShare" \
                    --option 'read only = no' \
                    MyShare

# 默认配置文件现在有一个新的部分用于 MyShare。
#
# [MyShare]
#         ; share parameters
#         path = /home/tester/MyShare
#         read only = no
#

# 每个共享都有自己的部分，其中包含适用于该共享的共享参数。在 [global] 中给出的共享参数会更改其默认值。[global] 还包含一些不特定于共享的全局参数。

# 你可以通过省略 --option 来交互式地更新共享。如果没有 --update，ksmbd.addshare 会添加 MyShare（如果它不存在的话）。
sudo ksmbd.addshare --update MyShare

# 将用户添加到默认用户数据库。系统将提示你输入密码。
sudo ksmbd.adduser --add MyUser

# 没有名为 MyUser 的系统用户，因此需要将其映射到一个系统用户。我们可以强制所有访问共享的用户映射到一个系统用户和组。

更# 新默认配置文件中共享的共享参数。
sudo ksmbd.addshare --update \
                    --option "force user = $USER" \
                    --option "force group = $USER" \
                    MyShare

# 默认配置文件现在包含更新后的共享参数。
#
# [MyShare]
#         ; share parameters
#         force group = tester
#         force user = tester
#         path = /home/tester/MyShare
#         read only = no
#

# 加载内核模块。
sudo modprobe ksmbd

# 启动用户模式和内核模式守护程序。所有接口默认都被监听。
sudo ksmbd.mountd

# 使用 cifs-utils 挂载新共享，并以新用户身份进行身份验证。你将被提示输入之前使用 ksmbd.adduser 设置的密码。
sudo mount -o user=MyUser //127.0.0.1/MyShare /mnt

# 你现在可以在 /mnt 访问该共享。
sudo touch /mnt/new_file_from_cifs_utils

# 卸载该共享。
sudo umount /mnt

# 更新默认用户数据库中用户的密码。
# 可以使用 --password 选项来指定密码，而不是提示输入密码。
sudo ksmbd.adduser --update --password MyNewPassword MyUser

# 从默认用户数据库中删除一个用户。
sudo ksmbd.adduser --delete MyUser

# 这些工具通过向 ksmbd.mountd 发送 SIGHUP 信号来通知其更改。在不使用这些工具的情况下进行更改时，可以手动执行此操作。
sudo ksmbd.control --reload

# 切换 ksmbd 对 "smb" 组件的调试打印。
sudo ksmbd.control --debug smb

# 有些更改需要重新启动用户模式和内核模式守护程序。修改任何全局参数就是这种更改的一个例子。重新启动意味着在关闭守护程序后启动 ksmbd.mountd。

# Shutdown the user and kernel mode daemons.
sudo ksmbd.control --shutdown

# 卸载内核模块。
sudo modprobe -r ksmbd
```

## Packages

以下打包状态跟踪器由[the Repology project](https://repology.org)提供。.

[![Packaging status](https://repology.org/badge/vertical-allrepos/ksmbd-tools.svg)](https://repology.org/project/ksmbd-tools/versions)