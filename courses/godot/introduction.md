# 资料

- [godot主页](https://godotengine.org/)
- [中文文档](https://docs.godotengine.org/zh-cn/4.x/)
- [英文文档](https://docs.godotengine.org/en/stable/)
- [godot源码](https://github.com/godotengine/godot)
- [godot-demo-projects](https://github.com/godotengine/godot-demo-projects/)

# 安装运行

首先下载软件，[linux godot下载](https://godotengine.org/download/linux/)，[macos godot下载](https://godotengine.org/download/macos/)，[windows godot下载](https://godotengine.org/download/windows/)。.NET版本下载后的压缩包名中含有`mono`，GDScript版本下载后的压缩包名中不含有`mono`。

GDScript版本解压后直接双击运行即可，.NET版本运行前要安装.NET SDK。

为了测试软件是否可以正常运行，GDScript版本可以导入[`2d/dodge_the_creeps`](https://github.com/godotengine/godot-demo-projects/blob/master/2d/dodge_the_creeps/project.godot)（参考[你的第一个 2D 游戏](https://docs.godotengine.org/zh-cn/4.x/getting_started/first_2d_game/index.html)）和[`3d/squash_the_creeps`](https://github.com/godotengine/godot-demo-projects/blob/master/3d/squash_the_creeps/project.godot)（参考[你的第一个 3D 游戏](https://docs.godotengine.org/zh-cn/4.x/getting_started/first_3d_game/index.html)），然后点击右上角三角形的“运行项目”按钮即可运行游戏。

# 导出

最方便的就是导出为web，参考[为 Web 导出](https://docs.godotengine.org/zh-cn/4.x/tutorials/export/exporting_for_web.html)。

先在“项目 -> 安装Android构建模板”（当然不只安卓需要模板）安装模板，可能无法下载，可以在[github下载相应版本的`export_templates.tpz`](https://github.com/godotengine/godot/releases)。在“项目 -> 导出...“ 选择 “添加... -> Web -> 导出项目“。注意只有https才能正常访问网页，当然localhost可以用http，双击html文件运行也无法正常访问。

可以在电脑端网页试试我导出的官方教程的[2d demo](https://chenxiaosong.com/godot/2d-demo/2d-demo.html)和[3d demo](https://chenxiaosong.com/godot/3d-demo/3d-demo.html)，注意这两个demo需要用到方向键和空格，手机上无法玩，当然我后续也试试修改成手机上也能玩。

