本文档翻译自[dkruchinin/cthon-nfs-tests 的 README 文件](https://github.com/dkruchinin/cthon-nfs-tests/blob/master/README)，翻译时文件的最新提交是`0acf9a75ebc467e9b2563b09f057aae297769d21 As published in 2004 on http://www.connectathon.org/nfstests.html`，大部分借助于ChatGPT，当然有一丢丢是经过了我的修改。仅作为我个人的参考，如果你想查阅，建议看英文文档，因为我不确定我记录的中文翻译是否完整和正确。

# Connectathon NFS测试套件简介

```
这些目录包含可用于测试NFS协议实现的程序。测试在UNIX客户端和测试服务器和客户端功能上运行（有关在DOS和Windows上运行的信息，请参见READWIN.txt）。测试分为三组:

	basic   - 基本文件系统操作测试
	general - 一般文件系统测试
	special - 测试涉及某些常见问题领域
	lock    - 测试执行网络锁定

此README分为五个部分。第一部分是介绍，您正在阅读的部分。然后是有关在您的计算机上运行测试套件之前必须执行的操作的说明。接下来是有关通常如何运行测试套件的描述，然后是它们在Connectathon上的使用的描述。最后一部分详细描述了每个测试的操作。

此测试套件应该在BSD和基于System V的系统上运行。Connectathon测试套件的System V Release 3端口由Lachman Technology，Incorporated提供，地址为1901 N. Naper Blvd.,
Naperville, IL.  60563。
```

# 准备运行测试套件

```
为了准备在您的计算机上运行测试套件，请更改到最高级别的测试套件目录（它应该与包含此README文件的目录相同），根据您所在的平台编辑tests.init，并键入“make”以编译测试程序。如果您不确定是否在正确的目录中，请键入“ls -CF”，您应该看到以下文件和目录:

Makefile	basic/		lock/		tests.h
README		domount.c	runtests	tests.init
READWIN.txt	general/	server		tools/
Testitems	getopt.c	special/	unixdos.h

"server"脚本使用"getopt"。目录中包含了"getopt"的公共领域版本的源文件。Makefile将为您编译它。

根据脚本tests.init中找到的参数配置测试。它包含由各种Makefiles和shell脚本使用的命令和参数的各种定义。应检查此文件，然后可能对其进行修改以正确匹配您的系统。特别是，应检查并正确设置“MOUNTCMD”、“UMOUNTCMD”、“PATH”、“CFLAGS”和“LIBS”的值。有几组建议的值可作为可能的起点。

Makefiles中包含两个特殊目标: copy和dist。命令“make copy DESTDIR="path"”，其中"path"是目录的绝对名称，将导致已编译的测试被复制到“path”。命令“make dist DESTDIR="path"”，其中"path"是目录的绝对名称，将测试源代码复制到“path”。在制作这两个目标时，必须在make命令行上指定DESTDIR。

可能需要修改程序以便在您的计算机上进行编译。如果是这样，请告诉我们，以便我们可以将它们合并到我们的发布中。

使用默认值时，测试程序期望服务器上存在目录/server。测试驱动程序将在客户端上使用目录/mnt/'server_name'，如果需要的话将首先创建它（其中'server_name'是您正在测试的服务器的名称）。这些默认值可以在运行时被覆盖。如何执行此操作的说明包含在下一部分中。
```

# 如何运行测试套件

```
有两种运行测试的方式: 使用服务器shell脚本或挂载、自行运行测试，然后卸载。我们建议您使用服务器脚本来运行测试。
```

## 服务器脚本

```
服务器脚本根据给定的选项执行一个或多个测试集（请参阅下文）。它被设置为挂载、使用runtests程序运行测试，然后卸载。在尝试挂载服务器文件系统之前，它将尝试卸载挂载点上的任何内容。如果测试失败，运行将被中止，并保留文件系统已挂载，以协助故障排除。

服务器脚本使用domount程序挂载和卸载测试文件系统。由于只能由root执行挂载，domount必须具有root权限。Makefile将尝试将domount程序设置为root的setuid。服务器脚本可以作为非特权用户运行。或者，您可以在运行服务器之前以root身份登录。

server [-a|-b|-g|-s|-l] [-f|-t] [-n] [-o mnt_options] [-p server_path] [-m mntpoint] [-N numpasses] server_name

-a|-b|-g|-s|-l      - 将传递给runtests脚本。此参数是可选的。默认值从初始化文件tests.init中读取。变量TEST包含此参数。此参数选择要运行的测试:
    -a	运行基本、一般、特殊和锁定测试
    -b	仅运行基本测试
    -g	仅运行一般测试
    -s	仅运行特殊测试
    -l	仅运行锁定测试
-f|-t	    - 将传递给runtests脚本。此参数是可选的。默认值从初始化文件tests.init中读取。变量TESTARG包含此参数。此参数选择如何运行基本测试:
    -f	快速功能测试
    -t	带有计时的扩展测试模式
-n	    - 不执行mkdir和rmdir操作以创建和销毁测试目录。
-o mnt_options - 将传递给挂载命令。此参数是可选的。默认值从初始化文件tests.init中读取。变量MNTOPTIONS包含此参数。
-p server_path - 指定要挂载的服务器上的目录。此参数是可选的。默认值从初始化文件tests.init中读取。变量SERVPATH包含此参数。
-m mntpoint    - 指定客户端上的挂载点。此参数是可选的。默认值从初始化文件tests.init中读取。变量MNTPOINT包含此参数。
-N numpasses - 将传递给runtests脚本。此参数是可选的。它指定运行测试的次数。
server_name - 您要测试的服务器。这是唯一必需的参数。

测试程序在mntpoint目录中创建一个子目录，名称为'hostname'.test，（其中'hostname'是您运行测试的机器的名称）。如果使用服务器脚本，尽管可以在使用runtests直接运行时覆盖它，但此名称无法覆盖。

示例: （客户端机器为eddie）

eddie％server -o hard,intr,rw slartibartfarst
在路径/mnt.slartibartfast/eddie.test上启动测试 [y/n]？y
<测试输出>
         :
         :
所有测试完成
eddie％

有关更多详细信息，请参阅脚本。
```

## 自行运行测试

```
在最高级别目录（主runtests）中有一个runtest脚本，它使用tests.init设置测试环境，然后在基本、一般和/或特殊子目录中执行runtest脚本。

runtests [-a|-b|-g|-s|-l] [-f|-n|-t] [-N numpasses] [test-directory]

-a         - 运行基本、一般、特殊和锁定测试。这是默认值。
-b	       - 运行基本测试。
-g	       - 运行一般测试。
-s	       - 运行特殊测试。
-l	       - 运行锁定测试。
-f	       - 为快速功能测试设置参数。仅适用于基本测试。
-n             - 在test-directory上抑制目录操作（mkdir和rmdir）。有关更多详细信息，请参阅基本测试的描述。
-t             - 运行带有运行时间统计的全长测试。仅适用于基本测试。这是基本测试的默认模式。
-N numpasses   - 运行测试“numpasses”次。
test-directory - 测试程序在客户端上创建的测试目录的名称。runtests在原地执行基本测试，并在test目录中执行它们。将一般测试复制到测试目录并在那里执行。当使用-n标志时，假定测试目录已经存在。

默认test-directory为/mnt.'servername'/'hostname'.test（其中'servername'是要测试的服务器的名称，'hostname'是您正在运行测试的机器的名称）。有三种方法可以覆盖默认测试目录名称。一种是将test_directory放在命令行上。另一种方法是将环境变量NFSTESTDIR设置为目录名称。命令行方法会覆盖设置环境变量。第三种方法只能用于basic子目录中的测试。在那里，可以在tests.h中设置TESTDIR变量。命令行和环境变量都会覆盖此方法。

在将NFS服务器挂载到/mnt之前运行测试将在本地运行测试（如果/mnt是本地磁盘）。我们建议您在使用它们测试NFS之前执行此操作，以确保测试套件正常运行。

基本目录、一般目录和特殊目录中的runtests可以使用与主runtests相同的参数进行调用，如果您希望分别运行每个测试套件。
```

# 如何在Connectathon运行测试套件

```
应按以下顺序运行测试: basic、general和special。在尝试其他测试之前，应完全通过基本测试。

NFS测试套件应分为三个阶段运行:

第一阶段 - 在本地运行测试程序。

第二阶段 - 对Sun运行测试。在使用Sun作为服务器的情况下在您的机器上运行它们，然后在Sun上使用您的机器作为服务器运行它们。

第三阶段 - NxN测试。在使用每台其他机器作为服务器的情况下在您的机器上运行测试，一次一台。在成功完成使用特定服务器的测试之后，请在提供的电子板软件上记录下来。检查电子板以确保测试在使用您的机器作为服务器的每台其他机器上都成功运行。
```

# 测试描述

```
在括号中包含了测试套件使用的系统和库调用。如果您对如何记录时间统计感兴趣，可以查看源代码，因为这里没有包含。
```

##  基本测试

```
下面列出的许多程序都有可选的调用参数，可以用来覆盖现有参数。目前没有使用这些参数，因此不予描述。

test1: 文件和目录创建测试

此程序在客户端上创建测试目录（mkdir）并更改目录（chdir）到该目录，除非使用了-n标志，在这种情况下，它只是更改目录到测试目录。然后，它构建一个N级深的目录树，其中每个目录（包括测试目录）都有M个文件和P个目录（creat、close、chdir和mkdir）。对于-f选项，N = 2，M = 2，P = 2，因此总共创建了六个文件和六个目录。对于其他选项，N = 5，M = 5，P = 2。创建的文件以"file."开头，目录以"dir."开头。

test2: 文件和目录删除测试

此程序更改目录到测试目录（chdir和/或mkdir）并删除刚由test1创建的目录树（unlink、chdir和rmdir）。级别、文件和目录的数量以及名称前缀与test1相同。

此例程不会删除未由test1创建的文件或目录，并且如果发现一个，则会失败。它通过查看正在尝试删除的对象的名称前缀来确定这一点。

test3: 跨挂载点查找

此程序更改目录到测试目录（chdir和/或mkdir）并获取工作目录的文件状态（getwd或getcwd和stat）。对于-f选项，getwd或getcwd只执行一次。对于其他选项，执行250个getcwd或getcwd。

test4: setattr、getattr和lookup

此程序更改目录到测试目录（chdir和/或mkdir）并创建十个文件（creat）。然后更改权限（chmod）并为每个文件检索文件状态（stat）。对于-f选项，对每个文件只执行一次chmod和stat。对于其他选项，对每个文件执行50次getcwd或getcwd和stat。

test4a: getattr和lookup

此测试存在，但不作为测试套件的一部分调用。您可以编辑basic目录中的runtests，以便调用此测试。

此程序更改目录到测试目录（chdir和/或mkdir）并创建十个文件（creat）。然后检索每个文件的文件状态（stat）。对于-f选项，对每个文件只执行一次stat。对于其他选项，对每个文件执行50次stat。

test5: 读和写

此程序更改目录到测试目录（chdir和/或mkdir），然后:

1) 创建文件（creat）
2) 获取文件状态（fstat）
3) 检查文件大小
4) 将1048576字节写入文件（write）中，使用8192字节缓冲区。
5) 关闭文件（close）
6) 获取文件状态（stat）
7) 检查文件大小

对于-f选项，文件只创建和写入一次。对于其他选项，文件创建和写入10次。

然后，该文件以8192字节缓冲区打开（open）并读取（read）。其内容将与写入的内容进行比较。然后关闭文件（close）。

然后重新打开文件（open）并重新读取（read），然后删除文件（unlink）。对于-f选项，此序列仅执行一次。对于其他选项，此序列执行10次。

test5a: 写

此测试存在，但不作为测试套件的一部分调用。您可以编辑basic目录中的runtests，以便调用此测试。

此程序更改目录到测试目录（chdir和/或mkdir），然后:

1) 创建文件（creat）
2) 获取文件状态（fstat）
3) 检查文件大小
4) 将1048576字节写入文件（write）中，使用8192字节缓冲区。
5) 关闭文件（close）
6) 获取文件状态（stat）
7) 检查文件大小

对于-f选项，文件只创建和写入一次。对于其他选项，文件创建和写入10次。

test5b: 读

此测试存在，但不作为测试套件的一部分调用。您可以编辑basic目录中的runtests，以便调用此测试。

打开test5a中创建的文件（open）并读取（read），使用8192字节缓冲区。其内容将与写入的内容进行比较。然后关闭文件（close）并删除文件（unlink）。

对于-f选项，文件只打开和读取一次。对于其他选项，文件创建和写入10次。

test6: readdir

此程序更改目录到测试目录（chdir和/或mkdir），并创建200个文件（creat）。打开当前目录（opendir），找到开头（rewinddir），并循环读取目录（readdir），直到找到结尾。标记的错误有:

1) 没有"."
2) 没有".."
3) 重复的条目
4) 文件名不以"file."开头
5) 文件名的后缀超出范围
6) 返回未链接文件的条目。（此错误仅在使用-f以外的选项运行测试时才能找到。对于其他选项，rewinddir/readdir循环执行200次，并且每次都会取消链接一个文件）。

然后关闭目录（closedir）并删除创建的文件（unlink）。

test7: link和rename

此程序更改目录到测试目录（chdir和/或mkdir）并创建十个文件。对于这些文件的每一个，文件被重命名（rename），并为新旧名称都检索文件统计信息（stat）。标记的错误有:

1) 旧文件仍然存在
2) 新文件不存在（无法stat）
3) 新文件的链接数不等于一

然后尝试将新文件链接到其旧名称（link），并再次检索文件统计信息（stat）。如果出现错误，则标记:

1) 无法链接
2) 在链接后无法检索新文件的统计信息
3) 新文件的链接数不等于两
4) 在链接后无法检索旧文件的统计信息
5) 旧文件的链接数不等于两

然后删除新文件（unlink），并检索旧文件的文件统计信息（stat）。如果出现错误，则标记:

1) 在取消链接后无法检索旧文件的统计信息
2) 旧文件的链接数不等于一

对于-f选项，对每个文件，重命名/link/unlink循环执行一次。对于其他选项，对每个文件，重命名/link/unlink循环执行10次。

在测试结束时，删除任何剩余的文件（unlink）。

test7a: rename

此测试存在，但不作为测试套件的一部分调用。您可以编辑basic目录中的runtests，以便调用此测试。

此程序更改目录到测试目录（chdir和/或mkdir）并创建十个文件。对于这些文件的每一个，文件被重命名（rename），并为新旧名称都检索文件统计信息（stat）。标记的错误有:

1) 旧文件仍然存在
2) 新文件不存在（无法stat）
3) 新文件的链接数不等于一

然后将文件重命名回其原始名称，并应用相同的测试。

对于-f选项，对每个文件，重命名/重命名循环执行一次。对于其他选项，对每个文件，重命名/重命名循环执行10次。

在测试结束时，删除任何剩余的文件（unlink）。

test7b: link

此测试存在，但不作为测试套件的一部分调用。您可以编辑basic目录中的runtests，以便调用此测试。

此程序更改目录到测试目录（chdir和/或mkdir）并创建十个文件。为这些文件的每一个都执行链接（link），并检索新旧文件的文件统计信息（stat）。如果出现错误，则标记:

1) 无法链接
2) 在链接后无法检索任一文件的统计信息
3) 任一文件的链接数不等于两

接下来取消链接新文件（unlink）。如果出现错误，则标记:

1) 在取消链接后无法检索旧文件的统计信息
2) 旧文件的链接数不等于一

对于-f选项，对每个文件，链接/取消链接循环执行一次。对于其他选项，对每个文件，链接/取消链接循环执行10次。

在测试结束时，删除任何剩余的文件（unlink）。

test8: symlink和readlink

注意: 并非所有操作系统都支持symlink和readlink。如果在test8期间返回errno EOPNOTSUPP，则将此测试视为通过。对于不支持S_IFLNK的客户端，将不会尝试此测试。

此程序更改目录到测试目录（chdir和/或mkdir）并创建10个符号链接（symlink）。读取（readlink）并获取每个符号链接的统计信息（lstat），然后删除它们（unlink）。标记的错误有:

1) 不支持的功能
2) 无法获取统计信息（lstat失败）
3) 统计信息中的模式不是符号链接
4) 符号链接的值不正确（从readlink返回）
5) 链接名错误
6) 取消链接失败

对于-f选项，对每个符号链接，符号链接/readlink/unlink循环执行一次。对于其他选项，对每个符号链接，符号链接/readlink/unlink循环执行20次。

test9: statfs

此程序更改目录到测试目录（chdir和/或mkdir），并获取当前目录的文件系统状态（statfs）。对于-f选项，执行一次statfs。对于其他选项，执行1500次statfs。
```

## GENERAL:  用于测试服务器负载的一般测试

```
运行小型编译、tbl、nroff、大型编译、四个同时运行的大型编译和make。
```

## SPECIAL:  与特殊测试相关的信息

```
special目录设置为测试过去出现的特殊问题。这些测试旨在提供建议，注意事项。虽然不要求通过这些测试，但强烈建议这样做。

这些测试尝试:

    检查正确的打开/取消链接操作
    检查正确的打开/重命名操作
    检查正确的打开/chmod 0 操作
    检查非幂等请求的丢失回复
    测试独占创建
    测试负偏移查找
    测试重命名
```

## LOCK

```
lock目录包含一个测试程序，可用于测试内核文件和记录锁定功能。这是为了测试网络锁定管理器。

测试程序包含13组锁定测试。它们测试基本的锁定功能。

默认情况下，不测试强制锁定。通常不支持在NFS文件上进行强制锁定。
```

## MISC

```
'Testitems'是用于参考的NFS功能列表。

在'tools'中提供的程序可根据需要自行使用。请随时添加到此目录（或任何其他目录）！如果这样做，请确保将其副本发送给Mike Kupfer <mike.kupfer@sun.com>，以便将其添加到主测试分发中。

该树的代码于1998年8月进行了Y2000问题检查。
没有发现问题。

有关在DOS或Windows下运行测试的信息，请参见READWIN.txt。
```

2004年的更改包括以下内容:

1. 修复lock/tlock.c，以便在何时使用stdarg和何时使用varargs方面保持一致；由Samuel Sha <sam@austin.ibm.com>报告。

2. 更改"make all"，使各种"runtests"脚本具有执行位设置；由Erik Deumens <deumens@qtp.ufl.edu>报告。

3. 从James Peach <jpeach@sgi.com>删除了一些lint。

4. 来自James Peach <jpeach@sgi.com>的Irix 6.5.19支持。

5. "server"脚本现在导出MNTOPTIONS，以便可以检测到添加到"server"的选项。来自Chuck Lever <Charles.Lever@netapp.com>。

6. 测试现在正确地检查了从mmap()返回的错误。来自David Robinson <david.robinson@sun.com>。

7. 来自Mike Mackovitch <macko@apple.com>的MacOS X支持。

8. 对Linux的tests.init现在包括一个CC=行，以防您的发行版不包括"cc"。由Rodney Brown <rodney@lehman.com>报告。

9. 来自Erik Deumens <deumens@qtp.ufl.edu>的AIX更改。

10. 来自Eric Werme <werme@hp.com>的最新Tru64 Unix更改。

11. 一般测试在面对make(1)错误时应更加健壮。基于Chuck Lever <Charles.Lever@netapp.com>的评论和Mike Mackovitch <macko@apple.com>的补丁。

12. 用于基本测试的"make lint"目标现在包括subr.c。

13. 对special/bigfile2的改进:
    - 错误消息现在打印完整的低阶字（来自Mike Mackovitch <macko@apple.com>。
    - 使用O_SYNC打开了测试文件，以便立即检测到问题。

14. 修复special/op_chmod，使其使用CHMOD_NONE而不是0。来自Pascal Schmidt <der.eremit@email.de>。


2003年的更改包括以下内容:

1. 来自Brian Love <blove@rlmsoftware.com>和Brian McEntire <brianm@fsg1.nws.noaa.gov>的HPUX修复。

2. 基于<saul@exanet.com>的补丁的AIX支持。

3. 用于构建64位二进制文件的gcc命令行选项，来自Sergey Klyushin <sergey.klyushin@hummingbird.com>。

4. 现在服务器脚本的消息在测试失败后关于保留服务器挂载的清晰度稍有提高。感谢Vincent McIntyre <Vince.McIntyre@atnf.csiro.au>的建议。

5. 锁定测试现在应该适用于NFS版本4和实施强制锁定的服务器。感谢Bill Baker <bill.baker@sun.com>的test12修复。

6. 一般测试已经修复，使用了测试附带的"stat"程序，而不是任何系统的"stat"程序。


2002年的更改包括以下内容:

1. 特殊测试更好地识别了何时指定了NFS版本2（基于Jay Weber <jweber@mail.thatnet.net>的补丁）。

2. 根据Marty Johnson <martyj@traakan.com>的补丁，修复*BSD系统的编译和运行时问题。

3. 将默认本地挂载点从/mnt.'server_name'更改为/mnt/'server_name'。这样，如果服务器死机或挂起，它更不太可能在客户端上引起操作问题。

4. "server"脚本将尝试使用"mkdir -p"（如果可用）。

5. 一般测试和特殊测试在初始化期间更好地检查错误。

6. 由于运行时间可能很长，将bigfile测试移至special测试的末尾。

7. 修复了Tru64 UNIX的信号处理程序的定义。

8. 从Jay Weber <jweber@mail.thatnet.net>获取的Linux配置信息进行了更新。


2001年的更改包括以下内容:

1. 为顶级"server"和"runtests"脚本添加了"-N numpasses"选项。

2. 根据Anand Paladugu <paladugu_anand@emc.com>的建议，更新了HPUX的编译标志，以提高special/bigfile2测试的性能。

3. 对special/bigfile2.c进行了轻微的可移植性修复。

4. 基本测试不再假定"."在$PATH中。

5. 在Windows下更容易构建基本测试和special测试（来自Rick Hopkins <rhopkins@ssc-corp.com>）。
