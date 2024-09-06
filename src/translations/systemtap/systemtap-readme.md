本文档翻译自[systemtap README](https://sourceware.org/git/?p=systemtap.git;a=blob;f=README;hb=92cb703ed8217db4cb693c29116f8d04d02d064b)，翻译时文件的最新提交是`92cb703ed remove dejazilla support`，大部分借助于ChatGPT翻译，仅作为我个人的参考，如果你想查阅，建议看英文文档，因为我不确定我记录的中文翻译是否完整和正确。

```
SystemTap是一个Linux跟踪/探测工具。

请访问项目网站 http://sourceware.org/systemtap，获取开发者和用户的文档和邮件列表信息。

这是自由软件。
有关再分发/修改条款，请参阅COPYING文件。
有关通用构建说明，请参阅INSTALL文件。
有关贡献建议，请参阅HACKING文件。

先决条件:

- Linux内核
- 内核模块构建环境（kernel-devel rpm）和/或dyninst
- 可选: 被检测的内核/用户空间的调试信息
- C编译器（与内核编译使用的相同），用于构建内核模块
- C++11编译器，如gcc 4.8+，用于构建SystemTap本身
- elfutils 0.151+及其带有libdwfl的版本，用于解析调试信息
- Python，用于脚本工具（例如dtrace(1)）
- root权限

安装步骤:

- 如果使用的是elfutils版本0.178或更高版本，请尝试使用debuginfod进行自动调试信息下载。这是一个实验性的公共服务器，可能足够使用:
  % export DEBUGINFOD_URLS=https://debuginfod.elfutils.org/
  % export DEBUGINFOD_PROGRESS=1
  更多详情请参阅 https://sourceware.org/elfutils/Debuginfod.html。

- 否则，请安装所需的调试信息包，适用于内核和/或用户空间。在现代Fedora上，可以使用以下命令:
  # debuginfo-install kernel [...]

  （注意内核、kernel-debug以及kernel-PAE等变体之间的混淆。每种变体通常都有对应的开发和调试信息包。）

- 安装SystemTap包。
  在现代Fedora上，执行以下命令:
  # yum install systemtap systemtap-runtime

构建步骤:

- 考虑安装kernel-debuginfo、kernel-devel、gcc和它们的依赖包（或者如果从源代码构建自己的内核，请参见下文）。如果仅使用纯用户空间的dyninst后端，请安装gcc和dyninst-devel。

- 如果可用，请安装您发行版的elfutils及其开发头文件/库。
  或者如果希望，可以单独构建elfutils一次，并安装到/usr/local。
  参见 https://elfutils.org/。
  elfutils版本0.178引入了自动调试信息下载功能，可以使systemtap的使用更加简便。

- 在现代Fedora上，安装一般的可选构建先决条件:
  # yum-builddep systemtap
  在现代Debian/Ubuntu上，类似地:
  # apt-get build-dep systemtap

- 下载systemtap源代码:
  https://sourceware.org/systemtap/ftp/releases/
  https://sourceware.org/systemtap/ftp/snapshots/
  （或者）使用git克隆:
  git clone git://sourceware.org/git/systemtap.git
      （或）https://sourceware.org/git/systemtap.git

- 正常构建systemtap:
  % .../configure [其他autoconf选项]
  在configure之前添加env LDFLAGS=-L/path/ CPPFLAGS=-I/path/，以在非系统目录中定位库文件。

  考虑使用"--prefix=DIRECTORY"配置选项，指定除了/usr/local之外的安装目录。它可以是普通的个人目录。

  % make all
  # make install
  若要卸载systemtap:
  # make uninstall

  或者，在类似Fedora的系统上:
  % make rpm
  # rpm -i /path/to/rpmbuild/.../systemtap*rpm

- 运行systemtap:

  安装完成后，要运行systemtap，请将$prefix/bin添加到您的$PATH中，或直接使用$prefix/bin/stap。如果保留了构建树，也可以在那里使用"stap"二进制文件。

  一些示例应该可以在$prefix/share/doc/systemtap/examples目录下找到。

  对于基于普通Linux内核模块的后端，请以root身份运行"stap"。如果需要，可以在/etc/groups中创建"stapdev"和"stapusr"条目。任何位于"stapdev"和"stapusr"组中的用户都可以像使用root权限一样运行systemtap。只有位于"stapusr"组中的用户可以启动（使用"staprun"）预编译的探测模块（由管理员复制到/lib/modules/`uname -r`/systemtap下）。"stapusr"用户也可以被允许创建自己的任意非特权systemtap脚本。有关更多设置信息，请参阅README.unprivileged。

  运行简单测试:
  # stap -v -e 'probe vfs.read {printf("read performed\n"); exit()}'

  从构建树运行完整的测试套件，请安装dejagnu，然后以root权限运行:
  # make installcheck

  对于原型dyninst纯用户空间后端，请任何用户运行"stap":
  % stap --runtime=dyninst -e 'probe process.function("*") { 
                               println(pn(), ":", $$parms) }' -c 'ls'

  对于原型bpf后端，请作为root运行"stap":
  # stap --runtime=bpf -e 'probe kernel.function("do_exit") {
                                 printf("bye %d\n", pid()) }'



提示:

- 默认情况下，systemtap会在以下位置查找调试信息:
  /boot/vmlinux-`uname -r`
  /usr/lib/debug/lib/modules/`uname -r`/vmlinux
  /lib/modules/`uname -r`/vmlinux
  /lib/modules/`uname -r`/build/vmlinux

构建kernel.org内核:

- 使用您通常的流程构建内核。启用以下配置选项: CONFIG_DEBUG_INFO、CONFIG_KPROBES、CONFIG_RELAY、CONFIG_DEBUG_FS、CONFIG_MODULES、CONFIG_MODULE_UNLOAD、CONFIG_UPROBES（如果可用）。
- % make modules_install install headers_install
- 启动到内核。

- 如果希望保留内核构建树，简单地运行:
  % stap -r /path/to/kernel/build/tree [...]
  完成。

- 或者，如果希望将内核构建/调试信息数据安装到systemtap可以找到而无需"-r"选项的位置:
  % ln -s /path/to/kernel/build/tree /lib/modules/RELEASE/build 

- 您也可以使用环境变量SYSTEMTAP_RELEASE来指定systemtap使用的内核数据，而不是使用"-r"选项。
```