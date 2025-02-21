我熟悉的内核模块，除了nfs就是smb了。nfs client是我相对比较熟悉的模块，但nfs client maintainer很不友好，nfs server maintainer友好但我对nfs server不是太熟悉。smb server近两年贡献的人数不是很多，又是近几年才进内核的模块，所以是相对比较适合我投入社区的。

- [邮件列表](https://lore.kernel.org/linux-cifs/)
- [patchwork](https://patchwork.kernel.org/project/cifs-client/list/)

# 社区

- nfs client maintainer: Steve French <sfrench@samba.org>，友好
- nfs server maintainer: Namjae Jeon <linkinjeon@kernel.org>，友好
- [nfs client maintainer的仓库](https://git.samba.org/sfrench/?p=sfrench/cifs-2.6.git;a=summary)
- [nfs server maintainer的仓库](https://github.com/namjaejeon/ksmbd)

获取supporter、reviewer、maintainer、open list、moderated list的邮箱:
```sh
./scripts/get_maintainer.pl fs/smb/server/
./scripts/get_maintainer.pl fs/smb/client/
./scripts/get_maintainer.pl fs/smb/common/
./scripts/get_maintainer.pl fs/smb/Makefile
./scripts/get_maintainer.pl fs/smb/Kconfig
./scripts/get_maintainer.pl fs/smb/
```

发送补丁:
```sh
git send-email --to=linkinjeon@kernel.org,sfrench@samba.org,stfrench@microsoft.com,pc@manguebit.com,sprasad@microsoft.com,dhowells@redhat.com,senozhatsky@chromium.org,tom@talpey.com,ronniesahlberg@gmail.com,bharathsm@microsoft.com --cc=chenxiaosong@kylinos.cn,chenxiaosong@chenxiaosong.com,linux-cifs@vger.kernel.org,linux-kernel@vger.kernel.org 00* # samba-technical@lists.samba.org要订阅才能发送成功
```

# smb server补丁统计

smb client很早进入内核，就不统计了。这里统计一下2021.03.16进入内核的smb server的补丁贡献者，列出贡献超过一个补丁的贡献者。

截止2024.12.28，smb server模块我总共贡献8个补丁，后续多投入社区，多贡献补丁，同时review一些代码。

现在（2024.12.28）的目录`fs/smb/server`统计:
```sh
# 还要显示邮件可以用 --format='%aN <%aE>'
# --follow 对目录其实没啥卵用，但还是习惯的写了
git log --follow --format='%aN <%aE>' fs/smb/server/ | sort | uniq -c | sort -nr
    125 Namjae Jeon <linkinjeon@kernel.org>
      7 Marios Makassikis <mmakassikis@freebox.fr>
      7 ChenXiaoSong <chenxiaosong@kylinos.cn> # 这是我
      6 Thorsten Blum <thorsten.blum@linux.dev>
      6 Jeff Layton <jlayton@kernel.org>
      3 Yang Li <yang.lee@linux.alibaba.com>
      3 Steve French <stfrench@microsoft.com>
      3 Hobin Woo <hobin.woo@samsung.com>
      3 Gustavo A. R. Silva <gustavoars@kernel.org>
      2 Randy Dunlap <rdunlap@infradead.org>
      2 Lu Hongfei <luhongfei@vivo.com>
      2 Kuan-Ting Chen <h3xrabbit@gmail.com>
      2 Jordy Zomer <jordyzomer@google.com>
      2 Fedor Pchelkin <pchelkin@ispras.ru>
      2 Dr. David Alan Gilbert <linux@treblig.org>
      2 Christophe JAILLET <christophe.jaillet@wanadoo.fr>
      2 Al Viro <viro@zeniv.linux.org.uk>
```

`checkout`到`38c8a9a52082 smb: move client and server files to common directory fs/smb`（2023.05.21）之前的记录:
```sh
git checkout cb8b02fd6343228966324528adf920bfb8b8e681
git log --follow --format='%aN <%aE>' fs/ksmbd/ | sort | uniq -c | sort -nr
    107 Namjae Jeon <linkinjeon@kernel.org>
     46 Hyunchul Lee <hyc.lee@gmail.com>
     42 Namjae Jeon <namjae.jeon@samsung.com>
     24 Christian Brauner <brauner@kernel.org>
     13 Marios Makassikis <mmakassikis@freebox.fr>
     10 Steve French <stfrench@microsoft.com>
      6 Dan Carpenter <error27@gmail.com>
      5 Yang Li <yang.lee@linux.alibaba.com>
      5 Ronnie Sahlberg <lsahlber@redhat.com>
      4 Ralph Boehme <slow@samba.org>
      4 Dawei Li <set_pte_at@outlook.com>
      4 David Disseldorp <ddiss@suse.de>
      4 Christophe JAILLET <christophe.jaillet@wanadoo.fr>
      4 Atte Heikkilä <atteh.mailbox@gmail.com>
      4 Al Viro <viro@zeniv.linux.org.uk>
      3 Jeff Layton <jlayton@kernel.org>
      3 Gustavo A. R. Silva <gustavoars@kernel.org>
      3 Colin Ian King <colin.i.king@gmail.com>
      3 Chih-Yen Chang <cc85nod@gmail.com>
      2 Tom Talpey <tom@talpey.com>
      2 Kees Cook <keescook@chromium.org>
      2 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
      2 Amir Goldstein <amir73il@gmail.com>
      1 ChenXiaoSong <chenxiaosong2@huawei.com> # 这是我
```

再`checkout`到`1a93084b9a89 ksmbd: move fs/cifsd to fs/ksmbd`（2021.06.24）之前的记录:
```sh
git checkout 131bac1ece2e16201674b2f29b64d2044c826b56
git log --follow --format='%aN <%aE>' fs/cifsd/ | sort | uniq -c | sort -nr
     91 Namjae Jeon <namjae.jeon@samsung.com>
     13 Hyunchul Lee <hyc.lee@gmail.com>
      9 Marios Makassikis <mmakassikis@freebox.fr>
      5 Dan Carpenter <dan.carpenter@oracle.com>
      3 Yang Yingliang <yangyingliang@huawei.com>
      3 Colin Ian King <colin.king@canonical.com>
      2 Muhammad Usama Anjum <musamaanjum@gmail.com>
      2 kernel test robot <lkp@intel.com>
```

# 社区其他人的补丁

请查看[社区补丁](https://chenxiaosong.com/course/smb/patch/other-patch.html)

