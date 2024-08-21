<!-- public begin -->
BPF是最近几年比较火的内核子系统，我也与时俱进来学习一下。

- BPF（Berkeley Packet Filter）: 伯克利数据包过滤器，诞生于1992年，用于提升网络包过滤工具的性能。2014年重新实现BPF的补丁合入Linux内核主线。主要应用领域: 网络、可观测性、安全。
- eBPF（extended BPF）: 扩展后的BPF，官方的缩写仍然是BPF。BCC和bpftrace是可以提供高级语言编程支持的BPF前端。
- bpftrace: 提供了专门用于创建BPF工具的高级语言支持。相比BCC，bpftrace更适合编写功能强大的单行程序、短小的脚本。
- BCC（BPF Compiler Collection）: BPF编译器集合，最早用于开发BPF跟踪程序的高级框架，提供高级语言环境来实现用户端接口，如BPF程序、C语言、Python、Lua、C++。相比bpftrace，BCC更适合开发复杂的脚本和作为后台进程使用。[源码](https://github.com/iovisor/bcc)。
<!-- public end -->

# bpftrace

[bpftrace源码](https://github.com/bpftrace/bpftrace)。

## 安装

编译Linux内核时要打开以下配置:
```sh
CONFIG_BPF=y
CONFIG_BPF_SYSCALL=y
CONFIG_BPF_JIT=y
CONFIG_HAVE_EBPF_JIT=y
CONFIG_BPF_EVENTS=y
CONFIG_FTRACE_SYSCALLS=y
CONFIG_FUNCTION_TRACER=y
CONFIG_HAVE_DYNAMIC_FTRACE=y
CONFIG_DYNAMIC_FTRACE=y
CONFIG_HAVE_KPROBES=y
CONFIG_KPROBES=y
CONFIG_KPROBE_EVENTS=y
CONFIG_ARCH_SUPPORTS_UPROBES=y
CONFIG_UPROBES=y
CONFIG_UPROBE_EVENTS=y
CONFIG_DEBUG_FS=y
```

参考[`INSTALL.md`](https://github.com/bpftrace/bpftrace/blob/master/INSTALL.md)

可以使用包管理器安装:
```sh
sudo apt-get update -y && sudo apt install bpftrace -y
sudo dnf install bpftrace -y
```

或者使用源码安装。

fedora环境，参考[`Dockerfile.fedora`](https://github.com/bpftrace/bpftrace/blob/master/docker/Dockerfile.fedora):
```sh
sudo dnf install -y \
        asciidoctor \
        bison \
        binutils-devel \
        bcc-devel \
        cereal-devel \
        clang-devel \
        cmake \
        elfutils-devel \
        elfutils-libelf-devel \
        elfutils-libs \
        flex \
        gcc \
        gcc-c++ \
        libpcap-devel \
        libbpf-devel \
        llvm-devel \
        make \
        systemtap-sdt-devel \
        zlib-devel
```

编译:
```sh
git clone https://github.com/bpftrace/bpftrace
cd bpftrace
# mkdir build; cd build; cmake -DCMAKE_BUILD_TYPE=DEBUG .. # 《bpf之巅》书上的命令
mkdir build; cd build; cmake -DBUILD_TESTING=OFF -DCMAKE_INSTALL_PREFIX=/usr/local ..
make -j$(nproc) # 内存要大一点，否则会发生oom
```

测试和安装:
```sh
./src/bpftrace -e 'kprobe:do_nanosleep { printf("sleep by %s\n", comm); }' # 输出 "sleep by crond" 之类的
sudo make install -j`nproc` # 二进制安装到 /usr/local/bin/，工具安装/usr/local/share/bpftrace/tools/
```