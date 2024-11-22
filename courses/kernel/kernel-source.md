# 内核社区

<!-- public begin -->
说到Linux内核，很多人可能会认为只有Linus这样的神才懂。但事实是任何人都能参与，比如我这样能力差的也参与到Linux内核社区了。可能很多人早就想贡献Linux内核了，但就是不知道怎么开始。
<!-- public end -->

Linux内核有一个官方网站[The Linux Kernel Archives](https://kernel.org/)，在这个网站上可以获取Linux内核源码以及[其他相关源码](https://git.kernel.org/)。

Linux内核社区主要以邮件交流为主，以下是一些常用的网站:

- [邮件列表](https://lore.kernel.org/): 在这里获取社区的最新动态。
- [按模块划分的patchwork](https://patchwork.kernel.org/): 补丁的邮件都会在这里归档。
- [bugzilla](https://bugzilla.kernel.org/): 上面有很多未解决的bug，想在社区提补丁可以在这上面找问题。
- [syzbot](https://syzkaller.appspot.com/upstream): [谷歌的syzkaller](https://github.com/google/syzkaller)模糊测试跑出来的bug，想在社区提补丁也可以在这上面找问题。
- [kernelnewbies](https://kernelnewbies.org/): 适合内核初学者看的网站。
- [LWN.net](https://lwn.net/): Linux新闻周刊。

# openEuler社区

[openEuler托管在gitee上](https://gitee.com/openeuler/kernel)，贡献openEuler要通过提交Pull Requests。

CLA 协议是开源贡献协议，用于规范贡献者的权利及义务。贡献者在贡献openEuler社区前，需要[签署CLA](https://clasign.osinfra.cn/sign/gitee_openeuler-1611298811283968340)，[签署流程](https://www.openeuler.org/zh/blog/2022-11-25-cla/CLA%E7%AD%BE%E7%BD%B2%E6%B5%81%E7%A8%8B.html)。如果你是以公司邮箱贡献，且公司已经签了CLA，你应该选择“法人贡献者登记”；如果你是以个人邮箱贡献，选择“签署个人CLA”。注意仓库下`.git/config`或`~/.gitconfig`中的邮箱配置要求必须是签署了CLA的邮箱，用`git log --pretty=fuller`可以查看commit的邮箱。

[Kernel SIG | openEuler Kernel 补丁合入规范](https://my.oschina.net/openeuler/blog/5949607)，可以用<!-- public begin -->[脚本`create-openeuler-git-msg.sh`](https://gitee.com/chenxiaosonggitee/blog/blob/master/courses/kernel/src/scripts/create-openeuler-git-msg.sh)<!-- public end --><!-- private begin -->脚本`src/scripts/create-openeuler-git-msg.sh`<!-- private end -->生成openEuler补丁需要的格式。

# 内核源码树

我们以社区最近的一个LTS（longterm support，长期维护版本）v6.6的代码来讲接下来的课程。

内核源码树根目录每个文件夹的描述如下（按字母顺序）:

- `arch`: architecture的缩写，体系结构相关。我们着重介绍`arch/x86/`和`arch/arm64/`，在每个体系结构目录下，`boot/`是启动相关，`configs/`是配置相关，`include/`头文件相关，`mm/`内存管理相关，等等。
- `block`: 块设备IO层相关。
- `certs`: 认证相关。
- `crypto`: 加密API，加密、散列、压缩、校验等算法。
- `Documentation`: 文档，要多看，很有用。也可以看在线文档: https://www.kernel.org/doc/html/latest/
- `drivers`: 设备驱动程序相关。
- `fs`: 文件系统相关。我们主要介绍`fs/`目录下VFS（虚拟文件系统）相关的，还会介绍几个具体的文件系统，如`fs/ext2/`、`fs/xfs/`、`fs/proc/`、`fs/sysfs/`等，当然具体的文件系统不会介绍得很详细，只说一个大概，主要还是以VFS的讲解为主。
- `include`: 内核头文件相关。
- `init`: 内核引导和初始化相关。
- `io_uring`: 5.1版本引入的高性能异步IO框架，主要是为了加快IO密集型应用的性能。
- `ipc`: 进程间通信相关。
- `kernel`: 进程相关，包括进程管理和进程调度。
- `lib`: 可以看成是一个标准C库的子集，如`strlen`、`mmcpy`、`sprintf`等函数。
- `LICENSES`: 许可证。
- `mm`: 与体系结构无关的内存管理代码，注意与体系结构相关的代码在`arch/mm/`目录下。
- `net`: 网络子系统，如TCP/IP等网络协议的实现。
- `rust`: 内核除了C语言外采用的一门新开发语言，和C性能差不多，目前暂时主要用于驱动开发。
- `samples`: 示例代码，很好的学习资源，不要放过。
- `scripts`: 脚本文件，如`make menuconfig`、`make scripts_gdb`等都是调用这个目录下的脚本。
- `security`: 安全模块，比如复杂的`selinux`。
- `sound`: 语音子系统相关。
- `tools`: 开发工具相关。
- `usr`: 早期的用户空间代码（`initramfs`），比如有打包和压缩用的`cpio`等。注意，`usr`的全称是`Unix System Resources`，不是`user`，不是`user`，不是`user`。为什么要强调不是`user`呢，因为有太多太多的人读成了`user`，咱们专业点，读成`u, s, r`，一个单词一个单词的读。
- `virt`: 虚拟化相关，如`kvm`。

上面是文件夹，接下来介绍根目录下的文件:

- `COPYING`: 许可证。
- `CREDITS`: 贡献者。
- `Kbuild`: 内核顶层目录的`Kbuild`, 在进入子目录之前准备全局头文件并检查完整性。
- `Kconfig`: 内核配置。
- `MAINTAINERS`: 维护者名单。
- `Makefile`: 设置编译参数。
- `README`: 描述文档在哪里。

# 贡献Linux内核社区

## 准备补丁

你可以通过[bugzilla](https://bugzilla.kernel.org/)或[syzbot](https://syzkaller.appspot.com/upstream)发现内核bug，也可以通过阅读内核代码发现bug或进行重构。<!-- public begin -->或者可以用[`calc-func-lines.sh`脚本](https://gitee.com/chenxiaosonggitee/blog/tree/master/courses/kernel/src/scripts/calc-func-lines.sh)<!-- public end --><!-- private begin -->或者可以用`src/scripts/calc-func-lines.sh`脚本<!-- private end -->找到长函数（不容易阅读）进行重构。

可以参考内核仓库中的补丁<!-- public begin -->，比如[我提交的补丁](https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git/log/?qt=grep&q=chenxiaosong)<!-- public end -->。修改代码时要参考[Linux内核代码风格](https://www.kernel.org/doc/html/latest/translations/zh_CN/process/coding-style.html#cn-codingstyle)。

注意commit message每行长度不超过 72 个字符。

`git commit`命令之后，使用以下命令会生成补丁文件:
```shell
# -1 表示最后一次commit，
git format-patch -1

# 指定commit号
git format-patch --subject-prefix="PATCH next" -1 <commit号>

# 如果是第2个版本或第3个版本，需要指定v2或v3
git format-patch --subject-prefix="PATCH v2" -1

# 如果内容不变，重新发送（比如加一个抄送的人）
git format-patch --subject-prefix="PATCH resend,v2" -1

# 从指定的commit号数向前3个，共生成3个补丁
git format-patch --subject-prefix="PATCH resend,v2" -3 <commit号>

# 生成补丁集
git format-patch --subject-prefix="PATCH resend,v2" -3 commit号 --cover-letter
# 编辑0000-cover-letter.patch, 可参考patchwork上其他补丁的写法
vim 0000-cover-letter.patch
```

## 邮箱配置

- 163邮箱配置: 默认情况下，163邮箱只能在网页和网易邮箱大师登录。如果要用git通过163邮箱发送邮件则需要对163邮箱进行配置。在[pc端网页](mail.163.com)登录163邮箱，点击“设置 --> POP3/SMTP/IMAP”，开启SMTP服务，会弹出授权密码窗口，记下这个授权密码（也可以在下方新增授权密码或删除）。
- foxmail邮箱（qq邮箱）配置: 在[pc端网页](https://mail.qq.com/)登录foxmail邮箱，点击"Settings -> Third-party Services -> IMAP/SMTP", 点击"Generate Authorization Code"生成在`.gitconfig`和[thunderbird](https://www.thunderbird.net)中登录的密码。
- 腾讯企业邮箱配置: 登录[腾讯企业邮箱](https://exmail.qq.com/login)个人账号（不是管理员），左上角“设置”，然后“邮箱绑定 -> 客户端专用密码 -> 生成新密码“，注意要记住这个密码，只会显示一次，忘记了就要重新生成密码。thunderbird中登录时的配置:
  - 收件服务器: 协议IMAP，主机名: imap.exmail.qq.com，端口: 993（或不填），连接安全性: 自动检测。
  - 发件服务器: 主机名: smtp.exmail.qq.com，端口: 465（或不填），连接安全性: 自动检测。

## thunderbird邮件客户端

最新版本的[thunderbird](https://www.thunderbird.net/)默认使用html格式发送和显示，需要更改配置，参考[Plain text e-mail - Thunderbird](http://kb.mozillazine.org/Plain_text_e-mail_-_Thunderbird#Send_plain_text_messages)。

依次点击 `Account Settings（账户设置） -> 地址簿 -> Composition & Addressing -> Composition（编写） -> 取消勾选 Compose messages in HTML format（以html格式编写消息）`。

thunderbird有个快捷键`k`，会忽略话题，不小心按下后邮件就会不再显示，可以在`查看 -> 话题`里勾选`已忽略话题`，就能看到不小心按下`k`而不显示的邮件。

还有，不建议订阅内核任何模块的邮件列表，因为太多了，一旦订阅邮箱基本就爆了，可以在[邮件列表网站](https://lore.kernel.org/)上选择对应的模块在线浏览，如果需要回复，可以把邮件下载下来保存成文件，然后用thunderbird打开文件，然后就可以回复了。如果实在要订阅，可以访问[vger.kernel.org](https://subspace.kernel.org/vger.kernel.org.html)和[linux-kernel mailing list FAQ](http://vger.kernel.org/lkml/)。

## git发送邮件

安装软件:
```sh
sudo apt install git-email -y
```

163邮箱`~/.gitconfig`:
```sh
[sendemail]
	from = your_name@163.com
	smtpserver = smtp.163.com
	smtpuser = your_name@163.com
	smtpencryption = ssl 
	smtppass = 此处填写163邮箱的授权密码
	smtpserverport = 994 
```

foxmail(qq)邮箱`~/.gitconfig`:
```sh
[sendemail]
        from = your_name@foxmail.com
        smtpserver = smtp.qq.com
        smtpuser = your_name@foxmail.com
        smtpencryption = ssl 
        smtppass = 此处填写qq邮箱的授权密码
```

腾讯企业邮箱`~/.gitconfig`:
```sh
[sendemail]
        from = your_name@your_name.com
        smtpserver = smtp.exmail.qq.com
        smtpuser = your_name@your_name.com
        smtpencryption = ssl 
        smtppass = 此处填写腾讯企业邮箱的授权密码
        smtpserverport = 465
```

获取maintainer邮箱:
```shell
./scripts/get_maintainer.pl file1.patch
```
发送邮件:
```shell
# --to是主送，--cc是抄送
git send-email --to=to1@example.com,to2@example.com --cc=cc1@example.com,cc2@example.com file1.patch file2.patch
```

可以使用脚本[`get-maintainer-email.sh`](https://gitee.com/chenxiaosonggitee/blog/blob/master/courses/kernel/src/scripts/get-maintainer-email.sh)来获取邮箱:
```sh
git format-patch -1 1aee9158bc97
bash get-maintainer-email.sh fs/nfs/ fs/nfsd fs/nfs_common 0001-nfsd-lock_rename-needs-both-directories-to-live-on-t.patch
```