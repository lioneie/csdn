本文章介绍我所使用的自由软件，整理了官网和源码地址等信息。在以后使用的过程中，如果需要修改源码，也方便查找。

# 自由软件之父

我的精神偶像: **理查德·马修·斯托曼**（**Richard Matthew Stallman, RMS**）。

他曾经说过:

> 随着社区（软件分享社区）的终结，我面临着一个道德上的抉择。最简单的就是投身于专有软件世界之中，签署不公开协议，并承诺不帮助同行、同事。自己也很可能编写软件，并在不公开协议的前提下发布软件，去同流合污，迫使更多的人背叛自己的原则。显然，走这条路，可以挣大钱，而且使编写代码的工作增添一份金钱上的快乐。但是我知道，等到自己职业生涯终结时，我再回首这些年为分离人类而砌造的‘墙壁’。我会感受到，我将自己的一生都用在使这个世界变得更加糟糕。

Linux内核源码使用的GPL协议就是他提出的。

斯托曼过着简朴的生活。他没有自己的汽车，住在租来的房子里，也没有结婚没有孩子（哦不对，他有孩子，叫“自由软件运动”），因为他觉得那样会变成挣钱的奴隶。

> 斯托曼传记: 《Free as in Freedom: Richard Stallman's Crusade for Free Software》（中文翻译: [《若为自由故》](https://book.douban.com/subject/26314527/)）

自由软件基金会网站: [https://www.fsf.org/](https://www.fsf.org/)。

GNU网站: [http://www.gnu.org/](http://www.gnu.org/)。

# Linux系统

我的技术偶像: **林纳斯·本纳第克特·托瓦兹**（**Linus Benedict Torvalds**）。

> 林纳斯自传: [《只是为了好玩》](https://book.douban.com/subject/25930025/)。

Linux内核源码地址: [https://github.com/torvalds/linux](https://github.com/torvalds/linux)。

我用的Linux桌面发行版是[Ubuntu](https://ubuntu.com/), 基于[Debian](https://www.debian.org/), Ubuntu的源码: [https://code.launchpad.net/ubuntu](https://code.launchpad.net/ubuntu)。

曾经也用过[Fedora](https://fedoraproject.org/)，Fedora Commons源码: [https://github.com/fcrepo/fcrepo](https://github.com/fcrepo/fcrepo)。Fedora 2021年使用的图形桌面环境是[GNOME](https://www.gnome.org/)。

# 虚拟机: QEMU/KVM

Virtual Machine Manager: [https://virt-manager.org/](https://virt-manager.org/)。

KVM为Linux内核的模块。

QEMU: [https://www.qemu.org/](https://www.qemu.org/)。

[QEMU/KVM安装macOS系统](https://chenxiaosong.com/src/macos/qemu-kvm-install-macos.html)。

# 编辑器: emacs

[emacs](http://www.gnu.org/software/emacs/)是我用的最多的编辑器，尤其是浏览Linux内核源码时，配合[gtags](https://www.gnu.org/software/global/)（安装: `sudo apt install global -y`），简直完美。

源码: [http://savannah.gnu.org/projects/emacs/](http://savannah.gnu.org/projects/emacs/)。

# 编辑器: vim

世上两大编辑器（[vim](https://www.vim.org/)和[emacs](http://www.gnu.org/software/emacs/)）之一。

github源码: [https://github.com/vim/vim](https://github.com/vim/vim)。

我主要开发语言为C语言，使用的vim插件有[ctags](http://ctags.sourceforge.net/)和[cscope](http://cscope.sourceforge.net/)。当然，现在更多的是使用emacs和gtags浏览Linux内核代码。

# 浏览器: Firefox

[Firefox](https://www.mozilla.org/en-US/firefox/)是一个由[Mozilla](https://www.mozilla.org/en-US/)开发的自由及开放源代码的网页浏览器。

源码地址（github上没有）: [https://hg.mozilla.org/mozilla-central/](https://hg.mozilla.org/mozilla-central/)。

# 浏览器: Chromium

按理说Firefox更加的“自由”，但Firefox现在真的做得不怎么好用，越来越多人用户转为选择使用Google Chrome或基于 Chromium 的浏览器（如Microsoft Edge、Opera、Brave、Vivaldi等）。

Chromium源码: [https://chromium.googlesource.com/chromium/src.git](https://chromium.googlesource.com/chromium/src.git)。

# Office办公软件: LibreOffice

LibreOffice Writer（文本）、LibreOffice Calc（表格）、LibreOffice Impress（ppt）、LibreOffice Draw（画图）。

官网: [https://www.libreoffice.org/](https://www.libreoffice.org/)。

源码地址: [https://github.com/LibreOffice/core](https://github.com/LibreOffice/core)。

# vscode编辑器

[vscode](https://code.visualstudio.com/)的源码: [https://github.com/microsoft/vscode](https://github.com/microsoft/vscode)。

另外非vscode官方的能在浏览器中使用的[code-server](https://github.com/coder/code-server)也非常好用。
