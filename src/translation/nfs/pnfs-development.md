本文档翻译自[linux-nfs.org中PNFS Development相关的内容](https://linux-nfs.org/wiki/index.php/PNFS_Development)，大部分借助于ChatGPT。仅作为我个人的参考，如果你想查阅，建议看英文文档，因为我不确定我记录的中文翻译是否完整和正确。

# PNFS Development

[原网页](https://linux-nfs.org/wiki/index.php/PNFS_Development)。

Linux pNFS具有可插拔的客户端和服务器架构，通过为文件、对象和块布局启用动态支持，充分发挥了pNFS作为通用和可扩展的元数据协议的潜力。

pNFS是第一个NFSv4小版本的一部分。这个空间用于跟踪和分享Linux pNFS实现的想法和问题。

## 客户端信息

- Fedora pNFS 客户端设置 - 如何设置 Fedora pNFS 客户端。
- Archlinux pNFS 客户端设置 - 如何设置 Archlinux pNFS 客户端。

## 服务器端信息

从4.0版本开始，上游服务器包含pNFS块支持。请参阅PNFS块服务器设置以获取说明。

以下说明适用于过时的原型:

- pNFS设置说明 - 基本的pNFS设置说明。
- GFS2设置注意事项 - cluster3，2.6.27内核

## 开发资源

- pNFS开发Git树
- pNFS Git树配方
- pNFS服务器文件系统API设计
- Wireshark补丁

## 提交错误

- linux-nfs.org Bugzilla - "NFSv4.1相关错误"组成员可读/写访问
  - 使用关键词: "NFSv4.1"和"pNFS"。
  - "NFSv4.1相关错误"组用于跟踪我们的错误。您需要在bugzilla上拥有用户帐户，然后发送电子邮件给Trond将您添加到该组。

## 设计笔记

- pNFS开发路线图
- pNFS基于文件的状态标识分发

## 历史内容

pNFS原型设计

# Fedora pNFS Client Setup

[原网页](https://linux-nfs.org/wiki/index.php/Fedora_pNFS_Client_Setup)。

## Installing Fedora

请查看原网页。

## Installing pNFS Enabled Fedora kernel

从内核 3.1 开始，块布局客户端已包含在标准内核中，您可以跳过此部分。

有两种安装启用 pNFS 的内核的方法。可以使用 yum 仓库或者直接下载。

具体内容请查看原网页（陈孝松注: 我们测试是用最新的内核，肯定包含了pNFS功能，所以可以暂不用管这些内容）。

## Target and blkmapd setup for block layout client

如果您使用文件或对象布局，请跳过此部分。如果您使用块布局与 iSCSI 目标，请按照以下说明操作。

您需要 pnfs 版本的 nfs-utils。如果您已经添加了 pnfs yum 仓库，只需执行 "yum update" 即可获取此软件包。您还可以从 http://steved.fedorapeople.org/repos/pnfs 下载 rpm，或者从 git 源代码树 git://git.linux-nfs.org/projects/bhalevy/pnfs-nfs-utils.git 构建它。

从版本 1.2.5 开始，标准的 nfs-utils 软件包包含了对 pNFS 的支持，包括块布局客户端，但您应用这个补丁以防止日志被垃圾填满: 0001-remove-pretty_sig.patch

您需要在服务器上设置 iSCSI 目标，并根据本地政策设置任何登录或权限所需的操作。具体操作步骤取决于服务器。

为了便于调试，您应该降低挂起任务的超时时间:
```sh
sysctl -w kernel.hung_task_timeout_secs=10
```

现在连接到您的 iSCSI 目标，类似于:
```sh
iscsiadm -m discovery -t sendtargets -p <iscsi-server> -l
```

然后启动块布局服务，它会加载内核模块并启动 blkmapd:
```sh
service blkmapd restart
```

如果您收到错误消息 "blkmapd: unrecognized service"，可能是缺少初始化文件。您可以从 CITI pnfs 网站安装它:
```sh
wget -O /etc/rc.d/init.d/blkmapd http://www.citi.umich.edu/projects/nfsv4/pnfs/block/download/rh-init.txt
chmod +x /etc/rc.d/init.d/blkmapd
```

## Mount Filesystem

在挂载服务器时使用 `-o minorversion=1` 挂载选项，类似于:
```sh
mount -t nfs4 -o minorversion=1 <server>:/export  /mnt
```

## Generate Traffic

使用“dd”生成一些I/O或运行“Connectathon”。您可以从 http://www.connectathon.org 下载Connectathon。所有测试都应该顺利通过，没有错误。

要验证 pNFS 是否正常工作，请在 /proc/self/mountstat 中使用 grep 查找单词 'LAYOUT'。您应该看到一些非零值。

```sh
fedora# grep LAYOUT /proc/self/mountstats
        nfsv4:  bm0=0xfcff8fff,bm1=0x40f9bfff,acl=0x3,sessions,pnfs=LAYOUT_BLOCK_VOLUME
        PNFS_LAYOUTGET: 2561 2561 0 655616 256284 34 1698 2575
        PNFS_LAYOUTCOMMIT: 0 0 0 0 0 0 0 0
        PNFS_LAYOUTRETURN: 1 1 0 252 88 0 0 1
```

## Unmount and disconnect

```sh
umount /mnt
iscsiadm -m node -U all
```

## Troubleshooting

如果您正在使用文件或对象布局，请跳过此部分。如果您正在使用 iSCSI 目标的块布局，请按照以下说明操作。

如果这对您没有用，请按照以下步骤查找问题。首先确保您的 iSCSI 目标已经被挂载。对于每个目标设备，在 `/var/log/messages` 中应该看到类似以下内容:
```sh
Mar  7 09:46:34 rhcl1 kernel: scsi 7:0:0:15: Direct-Access     DGC      RAID 5           0326 PQ: 0 ANSI: 4
Mar  7 09:46:34 rhcl1 kernel: sd 7:0:0:15: Attached scsi generic sg32 type 0
Mar  7 09:46:34 rhcl1 kernel: sd 7:0:0:15: [sdq] 1125628928 512-byte logical blocks: (576 GB/536 GiB)
Mar  7 09:46:36 rhcl1 kernel: sd 7:0:0:15: [sdq] Write Protect is off
Mar  7 09:46:37 rhcl1 kernel: sd 7:0:0:15: [sdq] Write cache: disabled, read cache: enabled, doesn't support DPO or FUA
Mar  7 09:46:37 rhcl1 kernel: sdq: unknown partition table
Mar  7 09:46:38 rhcl1 kernel: sd 7:0:0:15: [sdq] Attached SCSI disk
```

您还应该在 `/sys/block` 目录中看到块设备:
```sh
pdsi7# ls /sys/block
loop0  loop6  ram11  ram3  ram9  sdae  sdak  sdaq  sdb  sdh  sdn  sdt  sdz
loop1  loop7  ram12  ram4  sda   sdaf  sdal  sdar  sdc  sdi  sdo  sdu
loop2  md127  ram13  ram5  sdaa  sdag  sdam  sdas  sdd  sdj  sdp  sdv
loop3  ram0   ram14  ram6  sdab  sdah  sdan  sdat  sde  sdk  sdq  sdw
loop4  ram1   ram15  ram7  sdac  sdai  sdao  sdau  sdf  sdl  sdr  sdx
loop5  ram10  ram2   ram8  sdad  sdaj  sdap  sdav  sdg  sdm  sds  sdy
```

接下来加载内核模块:
```sh
modprobe blocklayoutdriver
pdsi7# modprobe blocklayoutdriver
pdsi7#
```

现在以前台模式运行守护进程:
```sh
pdsi7# /usr/sbin/blkmapd -f
```

最后，运行您的挂载命令，并验证您是否有一个 pnfs 挂载（参见上面的“Mount Filesystem”和“Generate Traffic”）。守护进程在发现您的设备时应该打印一些消息:
```sh
pdsi7# /usr/sbin/blkmapd -f
blkmapd: process_deviceinfo: 12 vols
blkmapd: decode_blk_signature: si_comps[0]: bs_length 4, bs_string 0x14
blkmapd: decode_blk_signature: si_comps[1]: bs_length 32, bs_string APM000644032240000
blkmapd: read_cmp_blk_sig: /dev/sdn sig 0x14 at -65536
blkmapd: read_cmp_blk_sig: /dev/sdn sig APM000644032240000 at -65436
blkmapd: decode_blk_volume: simple 0
...
blkmapd: decode_blk_volume: stripe 10 nvols=10 unit=512
blkmapd: decode_blk_volume: concat 11 1
blkmapd: dm_device_create: 10 pnfs_vol_0 253:0
blkmapd: dm_device_create: 11 pnfs_vol_1 253:1
```

这些消息的内容取决于您的设备拓扑结构。如果您仍然没有 pnfs 挂载，守护进程可能会打印一些有用的信息，或者您可以在 `/var/log/messages` 中找到一些信息。

# PNFS block server setup

[原网页](https://linux-nfs.org/wiki/index.php/PNFS_block_server_setup)。

最近将基于块布局的 pNFS 服务器合并到了 Linux 内核中。使用时需要谨慎，参见下面的警告。

要使用它，您需要:

- 至少版本为 4.0 的内核，配置了 CONFIG_NFSD_PNFS，
- 在服务器上同样较新的 nfs-utils（截至本文撰写时尚未正式发布；至少需要 steved 的 git 树中的 c08f1382e5609bc686c3df95ff1e267804b37a61 版本），以及
- 一个共享的块设备，服务器和客户端都可以访问。

格式化块设备为 xfs 文件系统，使用 "pnfs" 导出选项导出它，并启动 nfs 服务器，并按照下面的第二个警告创建一个 `/sbin/nfsd-recall-failed`。

在客户端上: 启动 `blkmap` 守护进程。（在 Fedora 上: `systemctl enable nfs-blkmap` 和 `systemctl start nfs-blkmap`）。然后使用至少 4.1 版本的 nfs 进行挂载。

客户端将通过直接读取或写入块设备而不是将 NFS 读取和写入发送到服务器来执行对普通文件的读取和写入。如果您可以在 `/proc/self/mountstats` 中看到 LAYOUTGET 调用，则可能正在工作。

警告:

- 客户端通过查看块设备的内容来确定要写入的块设备。如果客户端还可以访问相同文件系统的快照，可能会选择错误。这可能会损坏您的数据。
- 服务器需要能够在需要时撤销客户端对数据的直接访问，例如，多个客户端需要同时访问的情况。如果客户端对正常的 NFS 回调请求无响应，服务器必须能够强制切断客户端的访问。为使此工作正常运行，您必须提供一个 `/sbin/nfsd-recall-failed` 脚本，它知道如何切断客户端的访问。详细信息请参阅 [`Documentation/filesystems/nfs/pnfs-block-server.txt`](https://git.linux-nfs.org/?p=bfields/linux.git;a=blob;f=Documentation/filesystems/nfs/pnfs-block-server.txt;h=2143673cf1544bfc18502b8e0e4ee469234e7aae;hb=c517d838eb7d07bbe9507871fab3931deccff539)。如果未能执行此操作，可能会再次损坏您的数据。

# PNFS Setup Instructions

[原网页](https://linux-nfs.org/wiki/index.php/PNFS_Setup_Instructions)。

这个PNFS代码的描述已经过时，不再继续开发。

## File Layout

### Accessing a storage system with pNFS

#### 步骤0: 从PNFS开发Git树中获取pNFS内核，并在所有涉及的服务器上进行安装。

#### 步骤1: 设置NFSv4服务器

1. 

在所有数据服务器（DS）和元数据服务器（MDS）上创建`/etc/exports`文件。
```sh
/export  *(rw,sync,fsid=0,insecure,no_subtree_check)
```

注意: 从2.6.32-rc1版本开始，需要使用“pnfs”导出选项。
```sh
/export  *(rw,sync,fsid=0,insecure,no_subtree_check,pnfs)
```

在`pnfs`导出选项公开发布之前，请从以下地址构建和安装`exportfs、rpc.mountd、rpc.nfsd`，以及可选的`nfsstat`:
```sh
git://linux-nfs.org/~bhalevy/pnfs-nfs-utils.git

To install just the required binaries:
cp utils/exportfs/exportfs /usr/sbin/exportfs
cp utils/mountd/mountd /usr/sbin/rpc.mountd
cp utils/mountd/nfsd /usr/sbin/rpc.nfsd
cp utils/nfsstat/nfsstat /usr/sbin/nfsstat
```

2. 

告诉元数据服务器数据服务器的IP地址:
```sh
echo "/dev/sdc:192.168.0.1,192.168.0.2" >/proc/fs/nfsd/pnfs_dlm_device
```
(用托管导出的GFS2文件系统的设备名称替换`/dev/sdc`，并用数据服务器的IP地址替换IP地址。)

3. 

如果需要启动NFS服务，则在元数据服务器上运行以下命令。
```sh
/etc/init.d/nfs restart

or

rpc.mountd
rpc.nfsd 8
exportfs -r
```

#### 第二步: 在客户端加载布局驱动

```sh
modprobe nfs_layout_nfsv41_files
```

#### 第三步: 挂载pNFS文件系统。

在pnfs客户端:
```sh
mount -t nfs4 -o minorversion=1 <mds_server>:/ /mnt/pnfs

注意: 每个文件系统都有自己选择MDS的方式。确保只挂载MDS而不是DS。
```

### 调试帮助

nfs 调试:
```sh
echo 32767 > /proc/sys/sunrpc/nfsd_debug
echo 32767 > /proc/sys/sunrpc/nfs_debug
```
# Configuring pNFS/spnfsd

[原网页](https://linux-nfs.org/wiki/index.php?title=Configuring_pNFS/spnfsd)。

注意: spnfs已经从git://linux-nfs.org/~bhalevy/linux-pnfs.git pnfs-all-3.2中删除。

## What is pNFS ?

pNFS是NFSv4.1提供的新功能，也称为Parallel NFS。Parallel NFS（pNFS）扩展了网络文件共享版本4（NFSv4），允许客户端直接访问由NFSv4服务器使用的存储上的文件数据。这种绕过服务器进行数据访问的能力可以提高性能和并行性，但需要额外的客户端功能来进行数据访问，其中一些取决于所使用的存储类别。

Parallel NFS具有多种直接访问数据的方式。目前，提供了三种“布局”:

- LAYOUT4_FILE: 跨多个NFS服务器进行条带化
- LAYOUT4_BLOCK_VOLUME: 允许客户端按块设备中存储的方式访问数据
- LAYOUT4_OSD2_OBJECTS: 基于OSD2协议。

NFSv4.1和pNFS由以下RFC描述:

- RFC5661: 网络文件系统（NFS）版本4.1协议
- RFC5662: 网络文件系统（NFS）版本4.1，外部数据表示标准（XDR）描述
- RFC5663: 并行NFS（pNFS）块/卷布局
- RFC5664: 基于对象的并行NFS（pNFS）操作

## What is spNFS ?

spNFS是一个简单的pNFS LAYOUT4_FILE服务器实现，它使用独立的NFS服务器作为数据服务器，并将大部分MDS逻辑放在用户空间守护进程中。截至2011年初，它基本上没有维护，并且我们不再推荐使用它；如果您仍想尝试spNFS，可以使用以下步骤，但是您可能会更喜欢使用不同的服务器实现（请参阅 http://wiki.linux-nfs.org/wiki/index.php/PNFS_server_projects ）。

## Content of this document

这份文档描述了如何使用3台机器设置一个基本的pNFS/LAYOUT4_FILE测试配置，使用服务器端的spNFS。

（警告: 截至2011年2月，spNFS代码大部分未维护；我们不再推荐使用。）

我使用的机器是:

- nfsmds，IP地址= XX.YY.ZZ.A，用作元数据服务器
- nfsds，IP地址= XX.YY.ZZ.B，用作数据服务器
- nfsclient，IP地址= XX.YY.ZZ.C，用作客户端

## Where is the source code?

首先要做的是重新编译一个兼容的内核和nfs-utils发行版。我使用了Benny Halevy的git仓库中的那些。
```sh
 # Get kernel repository
 git clone git://git.linux-nfs.org/projects/bhalevy/linux-pnfs.git
 
 # Get nfs-utils repository
 git://linux-nfs.org/~bhalevy/pnfs-nfs-utils.git
```

在这份文档中，我使用了具有以下状态的版本库。
- pnfs-nfs-utils: commit id = 2b5373db8615a52c47dbcf3ab968fad7cdcc6fed (pnfs-nfs-utils-1-2-2)
- kernel linux-pnfs: commit id = cbd09e0fb2b160a06a44aad1c21786b99401823f (pnfs-all-2.6.33-2010-03-09)

## Let's go configuring now...

### Building the pnfs Kernel

内核编译正常。只需确保在`.config`文件中配置了正确的选项。

```sh
       CONFIG_NETWORK_FILESYSTEMS=y
       CONFIG_NFS_FS=m
       CONFIG_NFS_V4=y
       CONFIG_NFS_V4_1=y
       CONFIG_PNFS=y
       CONFIG_NFSD=m
       CONFIG_PNFSD=y
       # CONFIG_PNFSD_LOCAL_EXPORT is not set
       CONFIG_SPNFS=y
       CONFIG_SPNFS_LAYOUTSEGMENTS=y
```

使用2.6.34或更高版本的内核，添加（应该与`CONFIG_NFS_FS`相同）。
```sh
CONFIG_PNFS_FILE_LAYOUT=m
```

### Building nfs-utils

编译pnfs-nfs-utils将按照以下步骤进行。

```sh
 # autoreconf --instal
 # ./configure --prefix=/usr && make && make install
```

但是您必须确保已安装以下产品（所有节点都使用Fedora 12安装）:

- libtirpc + libtirpc-dev
- tcp_wrappers + tcp_wrapper-libs + tcp_wrappers-devel
- libblkid + libblkid-devel
- libevent + libevent-devel
- libnfsidmap
- device-mapper-devel (starting Fedora 15)

你会发现它们都是rpm包，但是libnfsidmap不是。对于这个包，您需要获取最新版本，进行编译和安装（不要忘记指定“./configure --prefix=/usr”）。您可以从nfs-utils-lib-devel-1.1.4-8或更高版本获取它。

基本上，类似以下命令的命令应该可以完成所有必需的工作（以Fedora 15为例）:
```sh
 # yum install libtirpc{,-devel} tcp_wrappers{,-devel} libevent{,-devel} libnfsidmap{,-devel} openldap-devel \
               libgssglue{,-devel} krb5-devel libblkid{,-devel} device-mapper-devel libcap{,-devel}
```

### Configuring the test bed to used pNFS over LAYOUT4_FILES

在这种配置中，客户端（nfsclient）将挂载MDS（nfsmds）。客户端插入了一个特定的内核模块，称为布局驱动程序，用于连接到DS。所有的元数据流量将通过MDS传递，但数据流量将在DS和客户端之间进行。

MDS应该能够挂载DS并在其上具有root访问权限。它运行一个用户空间守护程序，spnfsd（它是nfs-utils的一部分），使用此挂载点从DS获取信息。

#### Configuring the spNFS Data Server

数据服务器只是一个普通的NFSv4.1服务器。重要的是，元数据服务器必须具有对其的root访问权限，以防止由于EPERM错误导致的奇怪行为。

数据服务器的`/etc/exports`在nfsds上将如下所示:
```sh
/export/spnfs  *(rw,sync,fsid=0,insecure,no_subtree_check,pnfs,no_root_squash)
```

#### Configuring the spNFS Metadata Server

MDS是DS的客户端，并运行spnfsd。它也是启用了pNFS的NFSv4.1服务器。

spnfsd配置分两步进行:

- 将MDS配置为DS的客户端
- 编写`/etc/spnfsd.conf`文件

在MDS上，/etc/fstab应包含以下行:
```sh
nfsds:/       /spnfs/XX.YY.ZZ.B   nfs4    minorversion=1        0 0
```

必须通过NFSv4进行挂载，并将`minorversion`设置为1。

它的`/etc/spnfsd`配置文件将如下所示（这是一个单个DS配置）:
```sh
 [General]
 Verbosity = 1
 Stripe-size = 8192
 Dense-striping = 0
 Pipefs-Directory = /var/lib/nfs/rpc_pipefs
 DS-Mount-Directory = /spnfs
 
 [DataServers]
 NumDS = 1
 DS1_IP = XX.YY.ZZ.B
 DS1_PORT = 2049
 DS1_ROOT = /
 DS1_ID = 1
```

最后，`/etc/exports`将如下所示:
```sh
 /export  *(rw,sync,pnfs,fsid=0,insecure,no_subtree_check,no_root_squash)
```

注意在`exports`选项中有`pnfs`。

#### Configuring the client

客户端将作为普通的NFSv4.1客户端使用。唯一要做的就是确保布局驱动程序内核模块已加载。
```sh
# modprobe nfs_layout_nfsv41_files
```

（在2.6.26之前的内核中被称为nfslayoutdriver）

然后，您可以在客户端上挂载MDS:
```sh
# mount -t nfs4 -o minorversion=1 nfsmds:/ /mnt
```

警告: 在进行任何读/写操作之前，请确保NFSv4的宽限期已经过去。通常，在nfs服务启动后需要90秒。

#### Basic test

第一个测试非常简单: 在客户端上，我向文件写入50个字节:
```sh
 # echo "jljlkjljjhkjhkhkjhkjhkjhkjhkjhkjhkjhkjhkjhkjhkjhk" > ./myfile
 # ls -i ./myfile
 330246 myfile
```

在数据服务器上，我应该看到一个新文件，其文件名包含了myfile的文件ID，并位于其导出给MDS的根目录中。
```sh
 # ls -l /export/spnfs/330246*
 -rwxrwxrwx 1 root root 50 Mar 24 10:49 /export/spnfs/330246.2343187478
 # cat /export/spnfs/330246.2343187478
 jljlkjljjhkjhkhkjhkjhkjhkjhkjhkjhkjhkjhkjhkjhkjhk
```

正如您所见，这个文件位于数据服务器上，包含了客户端写入的数据。

在MDS上，文件具有正确的大小，但如果在NFS之外查看，它没有分配任何块。它不包含任何数据。
```sh
 # cd /export
 # stat myfile
 File: `myfile'
 Size: 50              Blocks: 0            IO Block: 4096   regular file
 Device: fd00h/64768d    Inode: 330246      Links: 1
 Access: (0644/-rw-r--r--)  Uid: (    0/    root)   Gid: (    0/    root)
 Access: 2010-03-24 12:56:02.331151053 +0100
 Modify: 2010-03-24 10:49:08.997150735 +0100
 Change: 2010-03-24 10:49:08.997150735 +0100
 
 # cat myfile
 (no output, the file is empty)
 ```

 -- Philippe Deniel 2010-04-07

# PNFS server projects

[原网页](http://wiki.linux-nfs.org/wiki/index.php/PNFS_server_projects)。

这是我们知道的一些可能被包含在主要Linux发行版中的项目列表。这意味着它们需要在Linux上运行，以自由/开源软件许可发布，并具备足够的质量、性能和实用性，以说服上游项目（如Linux内核），证明它们值得额外代码的投入。

对于每个项目，我们想知道还有多少工作要做才能满足这些要求。

## files-based projects

### spNFS

将后端数据存储在普通的本地磁盘文件系统中（如ext3），采用混合用户/内核（类似fuse）设计，并通过IO与元数据服务器通信。 (2008 connectathon presentation.)

目前未维护。可能需要进行一两次重新设计。

### gfs2

基于文件的服务器，使用gfs2在元数据服务器和数据服务器之间共享数据。

初步原型已存在。已通过一些简单测试。已知在协议上有些作弊（基于早期的4.1代码，尚未在数据服务器上强制使用stateid）。已经有使用中的崩溃报告。关于性能还没有详细信息。

### ocfs2

现在没有这样的实现。但是，似乎可以使用集群软件的用户空间部分（对内核文件系统代码进行最少或没有修改）来实现简单的pNFS。因此，对gfs2的任何工作也应该可以轻松应用于ocfs2（因为它们共享用户空间基础设施）。

## block-based projects

Rick McNeal，LSI Logic，发布了: http://git.linux-nfs.org/?p=rmcneal/linux-pnfs.git;a=summary 和 http://git.linux-nfs.org/?p=rmcneal/ctl.git;a=summary

基于spnfs基础设施实现基于块的pNFS MDS。计划将其合并到pnfs树中，一旦我们有了一些最基本的文档，描述如何设置服务器。

Rick McNeal说: “我想我应该介入并谈谈关于块布局工作的事情。pNFS服务器可以运行在任何愿意提供inode到块映射函数的文件系统上。由于客户端被期望具有与服务器相同的对存储的块级访问，因此不会给存储设备增加额外的负载。

[1] 还有几个其他部分，但问题的核心是需要将inode映射到`devid/extent_list`。”

未维护。看起来仍然是一个非常原型阶段的项目。

## objects-based projects

### exofs

基于对象的文件系统，部分用作pNFS后端。Exofs目前已合并，并支持nfs导出。打算支持跨多个OSD的镜像和raid0。当前状态不确定。

Benny Halevy在2009年2月15日表示: “我们对对象后端的计划是将exofs（扩展对象文件系统）导出到pNFS上。Exofs是内核驻留的，使用OSD进行持久存储。目前它支持单个OSD，对多个OSD的支持已经在路线图上。关于集群化，pNFS over exofs的架构是集中的，因此有一个单独的MDS运行文件系统代码的单个实例，并且有多个OSD，文件系统管理器和客户端都在与之通信。”