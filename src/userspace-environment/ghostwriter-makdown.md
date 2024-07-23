写文档，最爽的格式就是markdown。

曾经尝试过几款自由开源的markdown编辑器，但都不够理想，不是功能不完善就是缺陷多。

现在我是直接在[自己的个人网站](https://chenxiaosong.com/)上查看最终的显示效果，具体可以看[《如何快速搭建一个简陋的个人网站》](https://chenxiaosong.com/src/blog-web/blog-web.html)。

尝试的其中一款编辑器就是[KDE的ghostwriter](https://ghostwriter.kde.org/)，这个markdown编辑器功能挺完善，但缺陷也不少。

2021年时我解决了一个**严重的预览界面显示缺陷**[Chinese preview in HTML is complete now. Update README.md.](https://github.com/KDE/ghostwriter/pull/618/commits)。

如果各位朋友想自己修改或增加功能，可以使用[github源码](https://github.com/KDE/ghostwriter)安装。

# Linux下源码安装

ghostwriter是跨平台的，在Linux、macOS、Windows下都能运行，这里我只介绍Fedora（Linux）下的编译运行，其他平台请参考[README.md](https://github.com/KDE/ghostwriter/blob/master/README.md)。

先安装Fedora下编译所需的软件：

```shell
sudo dnf install qt-devel qt5-qtbase-devel qt5-qtsvg-devel qt5-qtmultimedia-devel qt5-qtwebengine-devel hunspell-devel qt5-linguist -y
```

在[源码](https://github.com/KDE/ghostwriter)目录下编译：
```shell
qmake-qt5
make
# 安装命令可不执行
# make install
```

运行软件：
```shell
cd build/release/
./ghostwriter
```

这个软件曾经用着感觉还行。

# 预览界面显示缺陷

2021年6月刚用ghostwriter时，一个很明显的预览界面显示缺陷摆在我面前：预览界面中文显示不完整，刚开始想放弃这个软件，但又觉得其他功能挺完善的，最后还是决定自己解决缺陷。

现在把这个缺陷介绍一下，也希望各位朋友能和我一起完善ghostwriter。

导致这个缺陷的[commit](https://github.com/KDE/ghostwriter/commit/795de8ba2b3717e23543170c40f2dd2379530a33)：

```c
// src/cmarkgfmapi.cpp
-    cmark_parser_feed(parser, text.toLatin1().data(), text.length());
+    cmark_parser_feed(parser, text.toUtf8().data(), text.length());
```

定位到这个原因后，我修改成如下代码：

```c
// src/cmarkgfmapi.cpp
cmark_parser_feed(parser, text.toLatin1().data(), text.toLocal8Bit().length());
```

中文是Unicode编码，一个汉字占2个字节，而`QString.length()`一个汉字只当成一个字节，需要修改成`QString.toLocal8Bit().length()`。

我的修改方案是[Chinese preview in HTML is complete now. Update README.md.](https://github.com/KDE/ghostwriter/pull/618/commits)，[lioneie](https://github.com/lioneie)是我曾经的github用户名。

你没看错，就是这么容易解决，参与到自由软件就是这么简单，参与到开源软件就是这么简单。
