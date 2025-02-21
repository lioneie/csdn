本文档翻译自[linux-test-project/ltp 的 README 文件](https://github.com/linux-test-project/ltp/blob/master/README.md)，翻译时文件的最新提交是`2a50d18cc README: Mention -f param for strace`，大部分借助于ChatGPT。仅作为我个人的参考，如果你想查阅，建议看英文文档，因为我不确定我记录的中文翻译是否完整和正确。

# Linux Test Project

Linux测试项目（Linux Test Project，简称LTP）是由SGI、OSDL和Bull共同发起的联合项目，由IBM、思科、富士通、SUSE、红帽、Oracle等公司共同开发和维护。该项目旨在向开源社区提供测试套件，验证Linux系统的可靠性、健壮性和稳定性。

LTP测试套件包含一系列用于测试Linux内核和相关功能的工具集。我们的目标是通过引入测试自动化技术，改进Linux内核和系统库的质量测试工作。欢迎有兴趣的开源贡献者加入我们。

项目页面位于: http://linux-test-project.github.io/

最新的镜像始终可在以下位置获取: https://github.com/linux-test-project/ltp/releases

关于项目的讨论请访问LTP邮件列表: http://lists.linux.it/listinfo/ltp

LTP邮件列表的存档位于: https://lore.kernel.org/ltp/

IRC频道 #ltp: irc.libera.chat

Git仓库位于GitHub: https://github.com/linux-test-project/ltp

Patchwork实例位于: https://patchwork.ozlabs.org/project/ltp/list/

# Warning!

请谨慎使用这些测试！

不要在生产系统上运行它们。特别是Growfiles、doio和iogen这些测试会对系统的I/O能力造成压力，虽然它们不应该在正常运行的系统上造成问题，但它们旨在发现（或引起）问题。

# Quick guide to running the tests

如果你已经安装了git、autoconf、automake、m4、pkgconf/pkg-config、libc头文件、Linux内核头文件以及其他常见的开发包（请参阅INSTALL和ci/*.sh），那么以下步骤很可能会成功:
```sh
$ git clone https://github.com/linux-test-project/ltp.git
$ cd ltp
$ make autotools
$ ./configure
```

现在，你可以选择继续编译和运行单个测试，或者编译和安装整个测试套件。

对于可选的库依赖关系，请查看ci/目录中适用于主要发行版的脚本。你还可以使用`./build.sh`脚本来构建整个LTP。

## Shortcut to running a single test

如果你只需要执行单个测试，实际上无需编译整个LTP。如果你想运行一个系统调用的测试用例，以下步骤应该可以正常工作:
```sh
$ cd testcases/kernel/syscalls/foo
$ make
$ PATH=$PATH:$PWD ./foo01
```

Shell测试用例稍微复杂一些，因为它们需要一个shell库的路径以及已编译的二进制助手的路径，但一般来说以下步骤应该可以正常工作:
```sh
$ cd testcases/lib
$ make
$ cd ../commands/foo
$ PATH=$PATH:$PWD:$PWD/../../lib/ ./foo01.sh
```

Open Posix Testsuite有自己的构建系统，需要先生成Makefile，然后在子目录中进行编译也应该可以工作:
```sh
$ cd testcases/open_posix_testsuite/
$ make generate-makefiles
$ cd conformance/interfaces/foo
$ make
$ ./foo_1-1.run-test
```

请注意，在运行测试之前，确保已经安装了所需的依赖项，并且环境变量已经设置正确以便找到所需的文件和库。

## Compiling and installing all testcases

```sh
$ make
$ make install
```

这将把LTP安装到/opt/ltp目录下。

- 如果遇到问题，请参阅`INSTALL`文件和`./configure --help`的帮助信息。
- 如果以上方法都无法解决问题，请在邮件列表或Github上寻求帮助。

如果configure脚本无法找到构建依赖项，则可能会禁用一些测试。

- 如果一个测试由于缺少组件而返回TCONF，请检查`./configure`的输出。
- 如果一个测试由于缺少用户或组而失败，请参阅INSTALL的快速入门部分。

## Running tests

```sh
$ cd /opt/ltp
$ ./runltp
```

请注意，许多测试用例需要以root用户身份执行。

要运行特定的测试套件:
```sh
$ ./runltp -f syscalls
```

要运行所有名称中带有madvise的测试:
```sh
$ ./runltp -f syscalls -s madvise
```

另请参阅:
```sh
$ ./runltp --help
```

测试套件（例如syscalls）在runtest目录中定义。每个文件包含一个简单格式的测试用例列表，详见doc/ltp-run-files.txt。

每个测试用例都有自己的可执行文件或脚本，可以直接执行:
```sh
$ testcases/bin/abort01
```

有些测试用例需要参数:
```sh
$ testcases/bin/mesgq_nstest -m none
```

绝大多数测试用例都支持-h（帮助）选项:
```sh
$ testcases/bin/ioctl01 -h
```

许多测试需要设置特定的环境变量:
```sh
$ LTPROOT=/opt/ltp PATH="$PATH:$LTPROOT/testcases/bin" testcases/bin/wc01.sh
```

大多数情况下，需要设置路径变量（PATH）和LTPROOT变量，但还有一些其他变量，runltp通常会为您设置这些变量。

请注意，所有shell脚本都需要设置PATH变量。然而，并不限于shell脚本，许多基于C语言的测试也需要设置环境变量。

更多信息请参阅doc/User-Guidelines.asciidoc文件或在线查看 https://github.com/linux-test-project/ltp/wiki/User-Guidelines。

## Network tests

网络测试需要特定的设置，详见testcases/network/README.md（在线查看地址: https://github.com/linux-test-project/ltp/tree/master/testcases/network）。

## Containers

当前在容器内运行LTP并不是一个捷径。这将使事情变得更加困难。

有一个可以与Docker或Podman一起使用的Containerfile。目前它可以构建Alpine和OpenSUSE镜像。

可以使用类似以下命令构建容器:
```sh
$ podman build -t tumbleweed/ltp \
       --build-arg PREFIX=registry.opensuse.org/opensuse/ \
       --build-arg DISTRO_NAME=tumbleweed \
       --build-arg DISTRO_RELEASE=20230925 .
```

或者只需执行 `podman build .`，它将创建一个Alpine容器。

容器中包含了Kirk在 `/opt/kirk` 中。因此，以下命令将运行一些测试:
```sh
$ podman run -it --rm tumbleweed/ltp:latest
$ cd /opt/kirk && ./kirk -f ltp -r syscalls
```

SUSE还发布了一个较小的LTP容器，不基于Containerfile。

# Debugging with gdb and strace

新的测试库在一个分支进程中运行实际的测试，即test()函数。要在gdb中获取崩溃测试的堆栈跟踪，需要设置 follow-fork-mode child。要使用strace跟踪测试，使用带有 -f 选项的strace来启用对分叉进程的跟踪。

# Developers corner

在开始之前，你应该阅读以下文档:

- doc/Test-Writing-Guidelines.asciidoc
- doc/Build-System.asciidoc
- doc/LTP-Library-API-Writing-Guidelines.asciidoc

还有一个逐步教程:

- doc/C-Test-Case-Tutorial.asciidoc

如果有任何未涵盖的内容，请不要犹豫在LTP邮件列表上提问。还请注意这些文档可以在线访问:

- https://github.com/linux-test-project/ltp/wiki/Test-Writing-Guidelines
- https://github.com/linux-test-project/ltp/wiki/LTP-Library-API-Writing-Guidelines
- https://github.com/linux-test-project/ltp/wiki/Build-System
- https://github.com/linux-test-project/ltp/wiki/C-Test-Case-Tutorial

虽然我们接受GitHub的拉取请求，但首选方式是将补丁发送到我们的邮件列表。

在发布到邮件列表之前，在GitHub Actions上测试补丁是个好主意。我们的GitHub Actions设置涵盖了各种架构和发行版，以确保LTP在大多数常见配置上能够编译成功。为了测试，你只需将更改推送到你在GitHub上的LTP分支。