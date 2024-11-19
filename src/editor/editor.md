# vim

本节目的是为了查找命令方便，也希望可以给同样喜爱vim的朋友一些参考。

至于vim最基础的知识，可以在shell下输入`vimtutor`命令查看，网上也有很多翻译的文档，请自行搜索。

## vim配置

配置文件 `~/.vimrc` ，可以参考[我的配置文件](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/linux-config/config-files/vimrc)

加载其他的.vimrc，在~/.vimrc中加入以下内容:

`auto bufread      vim打开时所在的路径      so         .vimrc的路径/.vimrc` 

## vim快捷键

多文件查找:

```
:help vimgrep		（查看帮助文档）

:vimgrep /pattern/*		（当前目录下查找模式pattern）
:vimgrep /pattern/**	（当前目录和子目录下查找模式pattern）
:vimgrep /pattern/**/*	（子目录下查找模式pattern，不含当前目录）

:cn		（查找下一个）
:cp		（查找上一个）
:cw		（打开quickfix窗口）
```

多文件替换:

```
:args **/**				（打开当前目录和子目录下的所有文件）
:args **/*.c			（打开当前目录和子目录下的.c文件）
:args *					（打开当前目录下的所有文件）
:args *.c				（打开当前目录下的.c文件）
:args */*.c				（打开下一级目录下的.c文件，不含当前目录）

:argdo %s/old/new/gc | update	（old替换成new，需要确认，update表示自动保存）
```

查找:

```
*  	向后查找单词
#	向前查找单词
/\c		不区分大小写向后查找（向前查找用?）
/\<word\>	匹配头尾向后查找（向前查找用?）
```

替换:

```
:%s/old/new/gc
加g表示替换一行中的所有，不加g表示只替换一行中的第一个
加c表示需要确认，不加c表示不需要确认
加%表示替换所有行，不加%表示替换当前行

:n,ms/old/new/gc	（替换第n行到第m行）
省略n表示从当前行开始替换
m为$时表示最后一行
```

跳转（cscope提供的跳转快捷键查看cscope章节）:

```
ctrl加]	ctags提供的跳转定义
:ts		显示定义列表
ctrl加t	ctags提供的跳回
gd	局部变量跳转
gf	跳到头文件
ctrl加o	后退跳转
ctrl加i	前进跳转
```

文件回车符设置:

```
:set ff?	（查看文件的回车符类型）
:set ff=unix	（设置为unix回车符）
:set ff=dos		（设置为dos回车符）
```

折叠:

```
zc zC zm zM	折叠
zo zO zr zR	展开
```

可视:

```
v	小写v按字符选择可视范围
V	大写V按行选择可视范围
ctrl+v	块选择可视范围
多行插入	ctrl+v按块选择多行然后按下大写i
```

其他操作:

```
撤销行	大写U
撤销10次	10u
不断重做	.(点号)
删除到行首	d^
删除到行尾	d$
选中可视范围后，按<键向前缩进，按>键向后缩进
不选中可视范围时，按两次<键向前缩进，按两次>键向后缩进
取消查找高亮	:nohlsearch (简写成noh)
将当前行和下一行合并  大写J
将匹配到的所有行删除        :g/pattern/d
将没有匹配到的所有行删除        :g!/pattern/d
```
## ctags

安装ctags: `sudo dnf install ctags -y`。

使用`ctags -R`编译代码生成`tags`文件，在`tags`文件所在目录打开`vim`即可加载`tags`文件。

`ctrl加]`跳转定义，`:ts`显示定义列表，`ctrl加t`回退

加载tags文件	`:set tags+=文件路径/tags`

## 浏览器插件vimium

我是自由软件狂热者，平时工作环境基本都是字符界面，在图形界面下也是用键盘代替鼠标，键盘使用的是自定义的HHKB（可用键盘移动鼠标光标）。在浏览器中搜索资料时，移动鼠标光标效率太低，可以使用浏览器插件vimium。

以自由软件浏览器firefox为例，说明vimium的安装和使用。

firefox浏览器 **Add-ons -> Extensions -> Find more add-ons -> Vimium-FF** 。

至于使用帮助，按 ? （问号）会弹出**Vimium Help**弹窗，可以查看快捷键的提示，基本和vim的使用一致。

# emacs

这节记录一下emacs环境以及我常用的emacs快捷键，更多的内容请查看emacs的教学文档和帮助文档。

## 安装与配置

我使用的配置文件[.emacs](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/linux-config/config-files/emacs)。

```
M-x package-refresh-contents 刷新包存储库中可用的包内容
M-x package-list-packages 显示当前已安装的包和可用的包，安装需要的包，如evil（模拟vim）
```

如果你使用的是cscope插件来浏览代码，将[cscope-indexer](https://gitee.com/chenxiaosonggitee/cscope/blob/configure.chenxiaosong/contrib/xcscope/cscope-indexer)所在路径添加到PATH中。关于cscope的更多内容请查看[《vim编辑器》](https://chenxiaosong.com/linux/vim.html)。

如果你使用的是gtags插件（要先安装`apt install global -y`）来浏览代码，在配置文件中添加[xcscope.el](https://gitee.com/chenxiaosonggitee/cscope/blob/configure.chenxiaosong/contrib/xcscope/xcscope.el)所在的路径`(add-to-list 'load-path  "/your_path/cscope/contrib/xcscope")`。使用`gtags`命令生成索引文件，Linux内核代码使用`make gtags`生成索引文件。

## 常用快捷键

```
C-<chr>: ctrl和<chr>键同时按

M-<chr>: meta(alt)和<chr>键同时按，等效 ESC放开后再按<chr>

C-x     字符扩展。  C-x 之后输入另一个字符或者组合键。
M-x     命令名扩展。M-x 之后输入一个命令

字符界面启动: emacs -nw

退出: C-x C-c
取消: C-g
取消ESC: 再按两次ESC

下一屏: C-v
上一屏: M-v
滚动几行: C-u 8 C-v, C-u 8 M-v
光标所在行 中间-顶端-底端 切换: C-l

上下左右: C-p, C-n, C-b, C-f
移动单词: M-f, M-b
行头行尾: C-a, C-e
句头句尾: M-a, M-e
首行尾行: M-<, M->
重复: C-u 8, M-8
插入多个字符（插入8个*）: C-u 8 *

C-f 帮助文档: C-h k C-f

删除光标前后(注意<DEL>是Backspace): <DEL>, C-d
删除前面后面单词: M-<DEL>, M-d
删除到行尾句尾: C-k（再次按删除换行符）, M-k
删除到行首: C-u 0 C-k

移除选择文字: C-@（C-<SPC>）移动光标后 C-w
复制选择文字: C-@ 移动光标后 M-w
召回yanking: C-y
召回以前的: M-y
撤销undo: C-/ 或 C-x u 或 C-_

寻找文件: C-x C-f
保存: C-x C-s

列出缓冲区: C-x C-b
选择缓冲区: C-x b
保存当前缓冲区: C-x C-s
保存多个缓冲区: C-x s
在列表中删除缓冲区: 标记为删除 d, 标记为保留 m, 删除 x

替换: M-% 或 M-x replace-string

恢复: M-x recover-file

切换模式: M-x text-mode, M-x fundamental-mode
查看主模式文档: C-h m
自动折行 auto fill 辅模式: M-x auto-fill-mode
设置行边界: C-x f
手动折行: M-q

向上向下搜索: C-r, C-s

关闭当前窗口: C-x 0
关闭其他窗格（只保留当前窗格）: C-x 1 
上下两个窗格: C-x 2
左右两个窗格: C-x 3
在其他窗格打开文件: C-x 4 C-f
其他窗格滚动: C-M-v, C-M-S-v
移到其他窗格: C-x o
创建关闭窗口: M-x make-frame, M-x delete-frame

递归编辑: 替换时又进行搜索
离开递归编辑: 3次ESC

帮助: C-h C-h 或 C-h ? 或 F1 F1 或 M-x help
命令名称: C-h c C-p
命令帮助: C-h k C-p
函数: C-h f previous-line
变量: C-h v
相关命令搜索（Command Apropos）: C-h a
手册: C-h i emacs使用手册 m emacs
emacs使用手册: C-h r

剪切矩形块: C-@ 选择后 C-x r k
粘贴矩形块: C-x r y
插入空格矩形块(向右移): C-x r o
清除矩形块（变成空格）: C-x r c
插入文字（相当于vim的ctrl+v+大写i）: C-x r t

高亮: M-x highlight-regexp
取消高亮: M-x unhighlight-regexp

跳到指定行: M-g g

键盘宏: 
	开始录制: C-x (
	结束录制: C-x )
	重复:     C-u 8 C-x e

折叠: M-x 然后 hs-hide-all, hs-show-all, hs-hide-block, hs-show-block, hs-toggle-hidding

寻找括号的另一边（注意: 开始的括号要在光标里，结束的括号要在光标前）: C-M-n, C-M-p

查看buffer所在目录: C-x C-d

补全: M-/

redo: C-g 后 再 C-/

模式: M-x c-mode, M-x fundamental-mode

折叠缩进(配合outline-minor-mode): M-x c-mode, M-x evil-mode

复制到 clipboard: C-@ 选择后 M-x copy-rectange-to-register 选择寄存器值（如8），然后在一个新的空的窗格 M-x insert-register 选择寄存器值（如8），然后再全选复制到 clipboard （M-w）

evil 配置: M-x customize-group RET evil RET， 参考: https://evil.readthedocs.io/en/latest/settings.html
```

待确认的功能:
1. 临时切换成 tab键 插入空格，以及空格个数: 暂时通过复制上一行的方式来实现

# cscope

安装cscope: `sudo apt install cscope -y`，但有很多bug，建议使用[源码](https://sourceforge.net/p/cscope/cscope/ci/master/tree/)安装，可以使用[`configure`](https://sourceforge.net/p/cscope/cscope/ci/configure/tree/)分支，然后merge [`master(eaea31cb93ec)`](https://sourceforge.net/p/cscope/cscope/ci/master/tree/)和[`no_generated_files_in_repo(9c49a74d7ac1)](https://sourceforge.net/p/cscope/cscope/ci/no_generated_files_in_repo/tree/)分支，再合入[更改cscope快捷键的补丁](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/editor/0001-cscope-emacs-change-cscope-select-entry-other-window.patch)。

```sh
# ubuntu/raspberry-pi build environment
sudo apt-get install autoconf -y
sudo apt install libncurses5-dev -y
sudo apt-get install flex bison -y

# fedora build environment
sudo dnf install ncurses-devel ncurses -y

# build
autoreconf -f -i
mkdir build
cd build
../configure --prefix=/path/to/install
make
```

将脚本文件[cscope_maps.vim](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/editor/cscope_maps.vim)放到`~/.vim/plugin/`路径下，即可使用快捷键（快捷键种类查看 `:cs help`），如`:cs find s word`查找word引用可使用快捷键`ctrl加\加s`（按顺序依次按3个键）。

使用`cscope -Rqbk`（当需要包含`/usr/include`头文件时，不使用`-k`选项）编译代码生成`cscope.out`文件，在`cscope.out`文件所在目录打开`vim`即可加载`cscope.out`文件。Linux内核代码使用`make cscope`命令生成索引文件。
