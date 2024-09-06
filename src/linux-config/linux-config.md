Linux下一切皆文件，所有的配置选项也都是文件。

这篇文章列出了我所使用的配置，各位朋友如果有更好的配置建议，请务必联系我哦。

# 脚本

如果每次重装系统或到一个新的开发环境上都要重新配置一次，我们肯定会不开心的呢，特别是像我这种爱折腾系统的人。

所以，脚本一键搞定是多么的寂寞，哦不对，是多么的重要。

把我的[个人笔记仓库](https://gitee.com/chenxiaosonggitee/blog)clone到本地，进入到目录[`src/linux-config`](https://gitee.com/chenxiaosonggitee/blog/tree/master/src/linux-config)，执行脚本[`link-config.sh`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/linux-config/link-config.sh)创建软链接到代码仓库里的配置文件，执行脚本[`src/linux-config/copy.sh`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/linux-config/copy.sh)复制配置文件到家目录下。

# .bash_profile

.bash_profile 是一个用于配置用户的 Bash shell 环境的文件。它通常位于用户的主目录（$HOME）下。当用户登录到系统时，Bash shell 会尝试执行 .bash_profile 文件中包含的命令和设置。这使得用户能够自定义其 shell 环境和行为。

具体请查看[`.bash_profile`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/linux-config/config-files/bash_profile)。

# .emacs

配置我最喜欢的编辑器emacs，配合着gtags，然后用hhkb键盘看内核代码，真的没有比这更爽的事情了。

具体请查看[`.emacs`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/linux-config/config-files/emacs)。

# .gitconfig

当没有配置时，无法进行git的提交。

配置名字和邮箱:
```shell
git config --global user.name "ChenXiaoSong"
git config --global user.email "chenxiaosongemail@foxmail.com"
```

具体请查看[`.gitconfig`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/linux-config/config-files/gitconfig)。

# .origin_xmodmap.txt 和 .xmodmap.txt

xmodmap是Linux桌面系统用于更改键位分布的软件。

[`.origin_xmodmap.txt`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/linux-config/config-files/origin_xmodmap.txt)是用于还原我当年买的xps13笔记本的键位布局，[`.xmodmap.txt`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/linux-config/config-files/xmodmap.txt)是用于xps13的键位更改，符合我的个人习惯。

使用的方法是:
```shell
xmodmap .origin_xmodmap.txt # 还原，需要点时间
xmodmap .xmodmap.txt
```

帮助命令:
```shell
xmodmap -h
xmodmap -pm # 打印修饰键
xmodmap -pke # 除修饰键外的其他键
```

# .set_proxy.sh

用于设置代理或取消代理。

```shell
# 注意要用<点号>，而不能用 bash .set_proxy.sh
. .set_proxy.sh 1 # 设置代理
. .set_proxy.sh 0 # 取消代理
```

具体请查看[`.set_proxy.sh`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/linux-config/config-files/set_proxy.sh)。

# .tmux.conf

Tmux（缩写自"Terminal Multiplexer"）是一个在命令行界面下运行的终端复用工具，我主要是用tmux的会话附加和分离功能，在一个Tmux会话中分离，然后重新附加，这意味着可以从一个终端窗口断开，然后在另一个终端窗口中继续工作，或者甚至在断开后重新连接。

安装:
```sh
sudo apt update -y
sudo apt install tmux -y
```

`set -g prefix none`表示将prefix键设置为空，因此您无需按下任何键即可执行tmux命令。这通常是为了防止键冲突或简化tmux的使用。

`unbind C-b`将取消绑定 C-b 作为 prefix 键，从而使其不再触发 tmux 命令。

如果已经运行了tmux，要重新加载配置，在终端中输入`tmux source-file ~/.tmux.conf`，使新的prefix设置生效。

具体请查看[`.tmux.conf`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/linux-config/config-files/tmux.conf)。

# .vimrc

vim就是方便小巧，是Linux下最常用的编辑器了，以前我挺喜欢用的，现在我更多的是用emacs看代码。

具体请查看[`.vimrc`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/linux-config/config-files/vimrc)。
