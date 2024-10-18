参考[简介 — The Linux Kernel documentation](https://www.kernel.org/doc/html/latest/translations/zh_CN/doc-guide/sphinx.html)。

# 环境

在我的环境中，运行`make O=build SPHINXOPTS=-v htmldocs`后报以下错误:
```sh
Documentation/Makefile:41: 找不到 'sphinx-build' 命令。请确保已安装 Sphinx 并在 PATH 中，或设置 SPHINXBUILD make 变量以指向 'sphinx-build' 可执行文件的完整路径。

检测到的操作系统：DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=22.04
DISTRIB_CODENAME=jammy
DISTRIB_DESCRIPTION="Ubuntu 22.04.2 LTS"。
警告：最好安装 "convert"。
警告：最好安装 "dot"。
警告：最好安装 "dvipng"。
错误：请安装 "ensurepip"，否则构建将无法工作。
警告：最好安装 "fonts-noto-cjk"。
警告：最好安装 "latexmk"。
警告：最好安装 "rsvg-convert"。
警告：最好安装 "texlive-lang-chinese"。
警告：最好安装 "xelatex"。
你应该运行：

        sudo apt-get install imagemagick graphviz dvipng python3-venv fonts-noto-cjk latexmk librsvg2-bin texlive-lang-chinese texlive-xetex

Sphinx 需要通过以下方式安装：
1) 通过 pip/pypi：

        /usr/bin/python3 -m venv sphinx_2.4.4
        . sphinx_2.4.4/bin/activate
        pip install -r ./Documentation/sphinx/requirements.txt

    如果你想退出虚拟环境，可以使用：
        deactivate

2) 作为包安装：

        sudo apt-get install python3-sphinx

    请注意，Sphinx >= 3.0 会在同名用于多个类型（函数、结构、枚举等）时产生误报警告。这是已知的 Sphinx 错误。更多详情，请查看：
        https://github.com/sphinx-doc/sphinx/pull/8313

由于缺少 2 个必需依赖项，无法构建，位于 ./scripts/sphinx-pre-install 第 997 行。

make[2]: *** [Documentation/Makefile:43：htmldocs] 错误 2
make[1]: *** [/home/linux/code/linux/Makefile:1692：htmldocs] 错误 2
make: *** [Makefile:234：__sub-make] 错误 2
```

再执行以下命令:
```sh
sudo apt-get install imagemagick graphviz dvipng python3-venv fonts-noto-cjk latexmk librsvg2-bin texlive-lang-chinese texlive-xetex -y
sudo apt-get install python3-sphinx -y
sudo apt-get install python3-sphinx
make O=build SPHINXOPTS=-v htmldocs
# make O=build cleandocs # 删除生成的文档
```

# 编译错误和警告

执行`make O=build htmldocs`命令后，有以下日志:
```sh
make[1]: 进入目录“/kernel/code/path/build”
  PARSE   include/uapi/linux/dvb/ca.h
  PARSE   include/uapi/linux/dvb/dmx.h
  PARSE   include/uapi/linux/dvb/frontend.h
  PARSE   include/uapi/linux/dvb/net.h
  PARSE   include/uapi/linux/videodev2.h
  PARSE   include/uapi/linux/media.h
  PARSE   include/uapi/linux/cec.h
  PARSE   include/uapi/linux/lirc.h
Using alabaster theme
Error: Cannot open file ../fs/netfs/io.c
/kernel/code/path/Documentation/admin-guide/media/ipu3.rst:592: WARNING: 脚注 [#] 没有被引用过。 [ref.footnote]
/kernel/code/path/Documentation/admin-guide/media/ipu3.rst:598: WARNING: 脚注 [#] 没有被引用过。 [ref.footnote]
/kernel/code/path/Documentation/block/ublk.rst:324: WARNING: 脚注 [#] 没有被引用过。 [ref.footnote]
WARNING: kernel-doc '../scripts/kernel-doc -rst -enable-lineno -sphinx-version 8.1.3 ../fs/netfs/io.c' failed with return code 1
/kernel/code/path/Documentation/driver-api/usb/usb:164: ../drivers/usb/core/message.c:968: WARNING: 重复的 C 声明，已经在 driver-api/usb/gadget:804 处声明。
声明为“.. c:function:: int usb_string (struct usb_device *dev, int index, char *buf, size_t size)”。
/kernel/code/path/Documentation/gpu/drm-kms:360: ../drivers/gpu/drm/drm_fourcc.c:344: WARNING: 重复的 C 声明，已经在 gpu/drm-kms:39 处声明。
声明为“.. c:function:: const struct drm_format_info * drm_format_info (u32 format)”。
/kernel/code/path/Documentation/gpu/drm-kms:476: ../drivers/gpu/drm/drm_modeset_lock.c:392: WARNING: 重复的 C 声明，已经在 gpu/drm-kms:49 处声明。
声明为“.. c:function:: int drm_modeset_lock (struct drm_modeset_lock *lock, struct drm_modeset_acquire_ctx *ctx)”。
/kernel/code/path/Documentation/gpu/drm-uapi:434: ../drivers/gpu/drm/drm_ioctl.c:875: WARNING: 重复的 C 声明，已经在 gpu/drm-uapi:70 处声明。
声明为“.. c:function:: bool drm_ioctl_flags (unsigned int nr, unsigned int *flags)”。
/kernel/code/path/Documentation/power/video.rst:213: WARNING: 脚注 [#] 没有被引用过。 [ref.footnote]
/kernel/code/path/Documentation/trace/debugging.rst: WARNING: 文档没有加入到任何目录树中
make[1]: 离开目录“/kernel/code/path/build”
