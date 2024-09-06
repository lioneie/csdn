本文档翻译自[kernel.org xfs/xfstests-dev.git 的 README 文件](https://git.kernel.org/pub/scm/fs/xfs/xfstests-dev.git/tree/README)（[或github](https://github.com/kdave/xfstests/blob/master/README)），翻译时文件的最新提交是`790a9e7c3c94f1a576e05478b832a423252c3edd common/rc: notrun if io_uring is disabled by sysctl`，大部分借助于ChatGPT。仅作为我个人的参考，如果你想查阅，建议看英文文档，因为我不确定我记录的中文翻译是否完整和正确。

# 构建FSQA套件

## Ubuntu或Debian

```
1. 确保软件包列表是最新的并安装所有必要的软件包:

   $ sudo apt-get update
   $ sudo apt-get install acl attr automake bc dbench dump e2fsprogs fio gawk \
        gcc git indent libacl1-dev libaio-dev libcap-dev libgdbm-dev libtool \
        libtool-bin liburing-dev libuuid1 lvm2 make psmisc python3 quota sed \
        uuid-dev uuid-runtime xfsprogs linux-headers-$(uname -r) sqlite3 \
        libgdbm-compat-dev

2. 安装用于正在测试的文件系统的软件包:

   $ sudo apt-get install exfatprogs f2fs-tools ocfs2-tools udftools xfsdump \
        xfslibs-dev
```

## Fedora

```
1. 从标准存储库安装所有必要的软件包:

   $ sudo yum install acl attr automake bc dbench dump e2fsprogs fio gawk gcc \
        gdbm-devel git indent kernel-devel libacl-devel libaio-devel \
        libcap-devel libtool liburing-devel libuuid-devel lvm2 make psmisc \
        python3 quota sed sqlite udftools  xfsprogs

2. 安装用于正在测试的文件系统的软件包:

    $ sudo yum install btrfs-progs exfatprogs f2fs-tools ocfs2-tools xfsdump \
        xfsprogs-devel
```

## RHEL或CentOS

```
1. 启用EPEL存储库:
    - 请参阅https://docs.fedoraproject.org/en-US/epel/#How_can_I_use_these_extra_packages.3F

2. 从标准存储库和EPEL安装所有必要的软件包:

   $ sudo yum install acl attr automake bc dbench dump e2fsprogs fio gawk gcc \
        gdbm-devel git indent kernel-devel libacl-devel libaio-devel \
        libcap-devel libtool libuuid-devel lvm2 make psmisc python3 quota sed \
        sqlite udftools xfsprogs

   或者，EPEL软件包可以从源代码编译，参见:
    - https://dbench.samba.org/web/download.html
    - https://www.gnu.org/software/indent/

3. 构建并安装 'liburing':
    - 请参阅https://github.com/axboe/liburing。

4. 安装用于正在测试的文件系统的软件包:

    对于XFS安装:
     $ sudo yum install xfsdump xfsprogs-devel

    对于exfat安装:
     $ sudo yum install exfatprogs

    对于f2fs构建和安装:
     - 请参阅https://git.kernel.org/pub/scm/linux/kernel/git/jaegeuk/f2fs-tools.git/about/

    对于ocfs2构建和安装:
     - 请参阅https://github.com/markfasheh/ocfs2-tools
```

## SUSE Linux企业版或openSUSE

```
1. 从标准存储库安装所有必要的软件包:

   $ sudo zypper install acct automake bc dbench duperemove dump fio gcc git \
        indent libacl-devel libaio-devel libattr-devel libcap libcap-devel \
        libtool liburing-devel libuuid-devel lvm2 make quota sqlite3 xfsprogs

2. 安装用于正在测试的文件系统的软件包:

    对于btrfs安装:
     $ sudo zypper install btrfsprogs libbtrfs-devel

    对于XFS安装:
     $ sudo zypper install xfsdump xfsprogs-devel
```

## 构建和安装测试、库和工具

```
$ git clone git://git.kernel.org/pub/scm/fs/xfs/xfstests-dev.git
$ cd xfstests-dev
$ make
$ sudo make install
```

## 环境设置

```
1. 编译 XFS/EXT4/BTRFS 等文件系统到您的内核中，或者加载为模块。例如，
   对于 XFS，可以在内核配置中启用 XFS_FS，或者将其编译为模块，并使用 'sudo modprobe xfs' 加载它。大多数发行版通常都会在内核中/作为模块提供这些文件系统。

2. 创建测试设备:
    - 格式化为您希望测试的文件系统类型。
    - 应至少为 10GB 大小。
    - 可以选择性地填充可销毁的数据。
    - 设备内容可能会被销毁。

3. (可选) 创建临时设备。
    - 许多测试依赖于临时设备的存在。
    - 不需要格式化。
    - 应至少为 10GB 大小。
    - 必须与测试设备不同。
    - 设备内容将被销毁。

4. (可选) 创建临时设备池。
    - BTRFS 测试需要此项
    - 通过 SCRATCH_DEV_POOL 变量指定 3 个或更多独立的临时设备，例如 SCRATCH_DEV_POOL="/dev/sda /dev/sdb /dev/sdc"
    - 设备内容将被销毁。
    - 临时设备应该保持未设置状态，它将被 SCRATCH_DEV_POOL 实现覆盖。

5. 将 local.config.example 复制为 local.config 并根据需要进行编辑。TEST_DEV
   和 TEST_DIR 是必需的。

6. (可选) 创建 fsgqa 测试用户和组:

   $ sudo useradd -m fsgqa
   $ sudo useradd 123456-fsgqa
   $ sudo useradd fsgqa2
   $ sudo groupadd fsgqa

   如果您的系统不支持以数字开头的名称，则可以安全地跳过 "123456-fsgqa" 用户创建步骤，只有少数测试需要它。

7. (可选) 如果您希望运行套件的 udf 组件，请安装 mkudffs。还需下载并构建 Philips UDF 验证软件，网址为
   https://www.lscdweb.com/registered/udf_verifier.html，然后将 udf_test
   二进制文件复制到 xfstests/src/。

8. (可选) 要进行 io_uring 相关的测试，请确保以下 3 件事情:
     1) 内核构建时启用了 CONFIG_IO_URING=y
     2) 执行 'sysctl -w kernel.io_uring_disabled=0'（如果内核支持，则设置为 2 以动态禁用 io_uring 测试）
     3) 在构建 fstests 之前安装包含 liburing.h 的 liburing 开发包

例如，使用回环分区运行测试:

    # xfs_io -f -c "falloc 0 10g" test.img
    # xfs_io -f -c "falloc 0 10g" scratch.img
    # mkfs.xfs test.img
    # losetup /dev/loop0 ./test.img
    # losetup /dev/loop1 ./scratch.img
    # mkdir -p /mnt/test && mount /dev/loop0 /mnt/test
    # mkdir -p /mnt/scratch

上述设置的配置是:

    $ cat local.config
    export TEST_DEV=/dev/loop0
    export TEST_DIR=/mnt/test
    export SCRATCH_DEV=/dev/loop1
    export SCRATCH_MNT=/mnt/scratch

从这一点开始，您可以运行一些基本测试，请参阅下面的 '使用 FSQA 套件'。
```

## 附加设置

```
某些测试需要在您的 local.config 中进行额外配置。将以下变量添加到 local.config 并将该文件保存在您的工作区中。或者根据测试机器的主机名在 common/config 中的 switch 中添加一个 case 来分配这些变量。或者使用 'setenv' 进行设置。

额外的 TEST 设备规范:
 - 将 TEST_LOGDEV 设置为 "用于测试文件系统外部日志的设备"
 - 将 TEST_RTDEV 设置为 "用于测试文件系统实时数据的设备"
 - 如果设置了 TEST_LOGDEV 和/或 TEST_RTDEV，则它们将始终被使用。
 - 将 FSTYP 设置为 "您想要测试的文件系统"。文件系统类型是根据 TEST_DEV 设备确定的，但您可能想要覆盖它；如果未设置，则默认为 'xfs'

额外的 SCRATCH 设备规范:
 - 将 SCRATCH_LOGDEV 设置为 "用于临时文件系统外部日志的设备"
 - 将 SCRATCH_RTDEV 设置为 "用于临时文件系统实时数据的设备"
 - 如果设置了 SCRATCH_LOGDEV 和/或 SCRATCH_RTDEV，则 USE_EXTERNAL 环境将始终使用

用于 xfsdump 测试的磁带设备规范:
 - 将 TAPE_DEV 设置为 "用于测试 xfsdump 的磁带设备"。
 - 将 RMT_TAPE_DEV 设置为 "用于测试 xfsdump 的远程磁带设备"
   如果将该变量设置为 "yes"，则启用它们的使用。
 - 请注意，如果测试 xfsdump，请确保磁带设备有一盘可以被覆盖的磁带。

额外的 XFS 规范:
 - 将 TEST_XFS_REPAIR_REBUILD 设置为 1，以便在_check_xfs_filesystem运行 xfs_repair -n 来检查文件系统；xfs_repair 用于重建元数据索引；以及 xfs_repair -n（第三次）来检查重建的结果。
 - 将 FORCE_XFS_CHECK_PROG 设置为 yes，以便在_check_xfs_filesystem中运行 xfs_check 来检查文件系统。截至2021年8月，xfs_repair 发现了 xfs_check 发现的所有文件系统损坏，而且还发现了更多，这意味着不再默认运行 xfs_check。
 - 将 TEST_XFS_SCRUB_REBUILD 设置为 1，以便在_check_xfs_filesystem运行 xfs_scrub 以“force_repair”模式重建文件系统；以及 xfs_repair -n 来检查重建的结果。
 - 如果存在 xfs_scrub，则该程序将始终检查测试和临时文件系统，如果它们在测试结束时仍处于在线状态。不再需要设置 TEST_XFS_SCRUB。

工具规范:
 - dump:
    - 将 DUMP_CORRUPT_FS 设置为 1，以记录 XFS、ext* 或 btrfs 文件系统的元数据转储（dump），如果文件系统检查失败。
    - 将 DUMP_COMPRESSOR 设置为一个压缩程序，以压缩文件系统的元数据转储。此程序必须接受 '-f' 和要压缩的文件名；它还必须接受 '-d -f -k' 和要解压缩的文件名。换句话说，它必须模拟 gzip。
 - dmesg:
    - 将 KEEP_DMESG 设置为 yes，以在测试后保留 dmesg 日志
 - kmemleak:
    - 将 USE_KMEMLEAK 设置为 yes，如果内核支持 kmemleak，则在每次测试后扫描内核中的内存泄漏。
 - fsstress:
    - 设置 FSSTRESS_AVOID 和/或 FSX_AVOID，其中包含要添加到 fsstress 和 fsx 调用末尾的选项，以防您希望从这些测试中排除某些操作模式。
 - core dumps:
    - 将 COREDUMP_COMPRESSOR 设置为一个压缩程序，以压缩崩溃转储。
      此程序必须接受 '-f' 和要压缩的文件名。换句话说，它必须模拟 gzip。

内核/模块相关的配置:
 - 将 TEST_FS_MODULE_RELOAD 设置为 1，在测试调用之间卸载模块并重新加载它。这假定模块的名称与 FSTYP 相同。
 - 将 MODPROBE_PATIENT_RM_TIMEOUT_SECONDS 设置为指定的时间量，以指定我们应该尝试患者模块移除的时间量。默认值为 50 秒。将其设置为 "forever"，我们将永远等待直到模块消失。
 - 将 KCONFIG_PATH 设置为您首选的内核配置文件的位置。测试使用此配置文件来检查内核功能是否已启用。
 - 将 REPORT_GCOV 设置为目录路径，以便 lcov 和 genhtml 从内核收集的任何 gcov 代码覆盖数据生成 html 报告。如果 REPORT_GCOV 设置为 1，则报告将写入 $REPORT_DIR/gcov/。

测试控制:
 - 将 LOAD_FACTOR 设置为非零正整数，以将系统上施加到测试的负载量增加指定倍数。
 - 将 TIME_FACTOR 设置为非零正整数，以将测试运行时间增加指定倍数。
 - 对于属于 "soak" 组的测试，设置 SOAK_DURATION 允许测试运行者精确指定测试应继续运行的时间。此设置将覆盖 TIME_FACTOR。浮点数允许使用，并且支持单位后缀 m(分钟)、h(小时)、d(天) 和 w(周)。

其他:
 - 如果希望禁用 UDF 验证测试，请将环境变量 DISABLE_UDF_TEST 设置为 1。
 - 将 LOGWRITES_DEV 设置为一个块设备，用于电源故障测试。
 - 将 PERF_CONFIGNAME 设置为任意字符串，用于标识运行性能测试的测试设置。对于每种要运行的性能测试，这应该是不同的，以便比较相关的结果。例如，对于使用旋转硬盘的配置，可以设置为 'spinningrust'，对于使用 nvme 驱动器的测试，可以设置为 'nvme'。
 - 将 MIN_FSSIZE 设置为指定的文件系统最小大小（字节）。设置此参数将跳过创建小于 MIN_FSSIZE 的文件系统的测试。
 - 将 DIFF_LENGTH 设置为“从失败的测试中打印的差异行数”，默认为 10，设置为 0 可以打印完整的差异。
 - 将 IDMAPPED_MOUNTS 设置为 true，以在 idmapped 挂载上运行所有测试。虽然此选项支持所有文件系统，但目前只有 -overlay 预计可以无问题运行。对于其他文件系统，可能需要对测试套件进行额外的补丁和修复。
 - 将 REPORT_VARS_FILE 设置为包含冒号分隔的名称-值对的文件，这些名称-值对将记录在测试部分报告中。名称必须是唯一的。冒号周围的空格将被移除。
 - 将 CANON_DEVS 设置为 yes，以规范化设备符号链接。这样，您就可以使用类似于 TEST_DEV/dev/disk/by-id/nvme-* 的东西，使得设备在重新启动之间保持持久。默认情况下此功能已禁用。
```

# 使用FSQA套件

```
运行测试:

    - cd xfstests
    - 默认情况下，测试套件将运行自动组中的所有测试。这些是预期作为回归测试正常工作的测试，并且排除了已知会导致机器故障的条件的测试（即“危险”测试）。
    - ./check '*/001' '*/002' '*/003'
    - ./check '*/06?'
    - 可以通过以下方式运行测试组: ./check -g [group(s)]
      构建xfstests后，查看tests/*/group.list文件以了解每个测试的组成员资格。
    - 如果要运行所有测试，而不管它们属于哪个组（包括危险测试），请使用“all”组: ./check -g all
    - 要随机化测试顺序: ./check -r [test(s)]
    - 您可以明确指定NFS/AFS/CIFS/OVERLAY，否则
      文件系统类型将从$TEST_DEV自动检测:
        - 用于运行nfs测试: ./check -nfs [test(s)]
        - 用于运行afs测试: ./check -afs [test(s)]
        - 用于运行cifs/smb3测试: ./check -cifs [test(s)]
        - 用于overlay测试: ./check -overlay [test(s)]
          TEST和SCRATCH分区应预先用另一个基本fs格式化，overlay目录将在其中创建


    check脚本测试每个脚本的返回值，并将输出与期望输出进行比较。如果输出不符合预期，则会输出差异，并生成一个.out.bad文件以表示测试失败。

    意外的控制台消息、崩溃和挂起可能被视为失败，但不一定会被QA系统检测到。
```

# 添加到FSQA套件

```
创建新的测试脚本:

    使用 "new" 脚本。

测试脚本环境:

    开发新的测试脚本时请牢记以下事项。一旦源自 "common/preamble" 文件并调用了 "_begin_fstest" 函数，所有环境变量和shell程序都可用于脚本。

     1. 测试从任意目录运行。如果要在XFS文件系统上执行操作（好主意，对吧？），则执行以下操作之一:

        (a) 随意在目录 $TEST_DIR 中创建目录和文件...这在XFS文件系统中，并且可由所有用户写入。在测试完成时应进行清理，例如，使用trap中的 _cleanup shell 程序...参见 001 的示例。如果需要知道，$TEST_DIR 目录位于块设备 $TEST_DEV 上的文件系统中。

        (b) 在 $SCRATCH_DEV 上创建新的XFS文件系统，并将其挂载到 $SCRATCH_MNT 上。在启动时调用 _require_scratch 函数如果需要使用临时分区。_require_scratch 对 $SCRATCH_DEV 和 $SCRATCH_MNT 进行了一些检查，并确保它们未被挂载。测试完成后应进行清理，并特别是卸载 $SCRATCH_MNT。测试可以使用 $SCRATCH_LOGDEV 和 $SCRATCH_RTDEV 进行测试外部日志和实时卷的使用-但是，这些测试需要在这些变量未设置的常见情况下简单地“通过”（例如，cat $seq.out; exit - 或默认为内部日志）。

     2. 您可以安全地创建不属于文件系统测试的临时文件（例如，捕获输出，准备要做的事情列表等）文件名为 $tmp.<anything>。由 "new" 脚本创建的标准测试脚本框架将初始化 $tmp 并在退出时进行清理。

     3. 默认情况下，测试以执行控制脚本 "check" 的用户身份运行。

     4. 其他一些有用的shell程序:

        _get_fqdn - 输出主机的完全限定域名

        _get_pids_by_name - 一个参数是进程名称，返回所有匹配的pid

        _within_tolerance - 用于确定性输出的高级数值“接近就足够好”的过滤器...请参阅common/filter中的注释以了解说明

        _filter_date - 将ctime（3）格式的日期转换为字符串DATE以获取确定性输出

        _cat_passwd、- 转储密码文件和组文件的内容（本地文件和NIS数据库的内容（如果可能存在））

        _cat_group

     5. 一般建议、使用约定等:
        - 当需要密码或组文件的内容时，请使用 _cat_passwd 和 _cat_group 函数，以确保包括NIS信息（如果NIS处于活动状态）。
        - 在测试中调用 getfacl 时，请传递 "-n" 参数，以便在输出中使用数字标识符而不是符号标识符。
        - 创建新测试时，可以输入自定义文件名。文件名的形式为NNN-custom-name，其中NNN是由./new脚本自动添加的唯一ID，并且"custom-name"是在./new脚本中输入的可选字符串。它只能包含字母数字字符和短划线。请注意，“NNN-”部分是自动添加的。

     6. 测试组成员资格: 每个测试可以与任意数量的组相关联，以便选择测试的子集。组名称必须使用集合[:alnum:_-]中的字符进行人类可读。

        测试作者通过将这些组的名称作为参数传递给 _begin_fstest 函数来将测试与组相关联。虽然 _begin_fstests 是必须在测试开始时调用的shell函数，以正确初始化测试环境，但构建基础结构还会扫描测试文件以查找 _begin_fstests 调用。它执行此操作以编译用于确定在运行 `check` 时要运行哪些测试的组列表。

        但是，由于构建基础结构还使用 _begin_fstests 作为已定义的关键字，因此对其格式化的方式施加了其他限制:

        (a) 它必须是单行，没有多行连续性。

        (b) 组名应由空格分隔，而不是其他空白字符

        (c) 将“#”放置在列表中的任何位置，即使在组名的中间，也将导致从“#”到行尾的所有内容被忽略。

        例如，代码:

        _begin_fstest auto quick subvol snapshot # metadata

        将当前测试与“auto”、“quick”、“subvol”和“snapshot”组关联起来。因为 "metadata" 在 "#" 注释分隔符之后，所以构建基础设施将忽略它，因此它不会与该组相关联。

        在列表中不需要指定 "all" 组，因为该组始终根据组列表在运行时计算。

验证输出:

    每个测试脚本都有一个名称，例如007，以及一个关联的验证输出，例如007.out。

    确保验证输出是确定性的非常重要，测试脚本的一部分工作是过滤输出以实现这一点。需要过滤的示例:

    - 日期
    - 进程ID
    - 主机名
    - 文件系统名称
    - 时区
    - 变量目录内容
    - 不精确的数字，特别是大小和时间

通过/失败:

    脚本 "check" 可用于运行一个或多个测试。

    当测试编号 $seq 被认为 "通过" 时:
    (a) 未创建 "core" 文件，
    (b) 未创建文件 $seq.notrun，
    (c) 退出状态为 0，且
    (d) 输出与已验证的输出匹配。

    在 "未运行" 情况下（b），$seq.notrun 文件应包含一个简短的一行摘要，说明为什么未运行该测试。不检查标准输出，因此可以用于更详细的说明，并在交互式运行QA测试时提供反馈。


    要强制使用非零退出状态，请使用:
    status=1
    exit

    请注意:
    exit 1
    由于退出陷阱的工作方式，不会产生预期的效果。

    最近的通过/失败历史记录维护在文件 "check.log" 中。
    每个测试的最近一次通过的经过时间保存在 "check.time" 中。

    工具目录中的 compare-failures 脚本可用于比较失败，给定包含那些运行的stdout的文件。
```

# 提交补丁

```
将补丁发送到 fstests 邮件列表，地址为 fstests@vger.kernel.org。
```
