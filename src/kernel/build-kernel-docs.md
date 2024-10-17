参考[简介 — The Linux Kernel documentation](https://www.kernel.org/doc/html/latest/translations/zh_CN/doc-guide/sphinx.html)。

在我的环境中，运行`make O=build SPHINXOPTS=-v htmldocs`后报以下错误:
```sh
Documentation/Makefile:41: The 'sphinx-build' command was not found. Make sure you have Sphinx installed and in PATH, or set the SPHINXBUILD make variable to point to the full path of the 'sphinx-build' executable.

Detected OS: DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=22.04
DISTRIB_CODENAME=jammy
DISTRIB_DESCRIPTION="Ubuntu 22.04.2 LTS".
Warning: better to also install "convert".
Warning: better to also install "dot".
Warning: better to also install "dvipng".
ERROR: please install "ensurepip", otherwise, build won't work.
Warning: better to also install "fonts-noto-cjk".
Warning: better to also install "latexmk".
Warning: better to also install "rsvg-convert".
Warning: better to also install "texlive-lang-chinese".
Warning: better to also install "xelatex".
You should run:

        sudo apt-get install imagemagick graphviz dvipng python3-venv fonts-noto-cjk latexmk librsvg2-bin texlive-lang-chinese texlive-xetex

Sphinx needs to be installed either:
1) via pip/pypi with:

        /usr/bin/python3 -m venv sphinx_2.4.4
        . sphinx_2.4.4/bin/activate
        pip install -r ./Documentation/sphinx/requirements.txt

    If you want to exit the virtualenv, you can use:
        deactivate

2) As a package with:

        sudo apt-get install python3-sphinx

    Please note that Sphinx >= 3.0 will currently produce false-positive
   warning when the same name is used for more than one type (functions,
   structs, enums,...). This is known Sphinx bug. For more details, see:
        https://github.com/sphinx-doc/sphinx/pull/8313

Can't build as 2 mandatory dependencies are missing at ./scripts/sphinx-pre-install line 997.

make[2]: *** [Documentation/Makefile:43：htmldocs] 错误 2
make[1]: *** [/home/linux/code/linux/Makefile:1692：htmldocs] 错误 2
make: *** [Makefile:234：__sub-make] 错误 2
```