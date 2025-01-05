我们学一个新东西，肯定第一件事就是模仿，godot官方的demo撸一遍应该就能对这个游戏引擎的使用有个初步的掌握了。

开始吧。。。

# 你的第一个 2D 游戏 - Dodge the Creeps

- [参考文档](https://docs.godotengine.org/zh-cn/4.x/getting_started/first_2d_game/index.html)
- [官方demo源码](https://github.com/godotengine/godot-demo-projects/tree/master/2d/dodge_the_creeps)
- [我撸一遍的源码](https://gitee.com/chenxiaosonggitee/tmp/tree/master/godot-src/2d-demo)

建议直接看[参考文档](https://docs.godotengine.org/zh-cn/4.x/getting_started/first_2d_game/index.html)，这里我只把一些需要特别注意的点记一下，不会把官方指导文档里已有的内容搬过来。

单击“其他节点”按钮并将 Area2D 节点添加到场景中时，默认折叠视图中并没有将Area2D展示出来，最好是在“搜索”框中搜索一下。

AnimatedSprite2D 需要一个 SpriteFrames 资源，在检查器的 Animation 选项卡下找到 Sprite Frames 属性，注意检查器在窗口的右边。

在“FileSystem”选项卡中找到玩家图像，“FileSystem（文件系统）”选项卡在窗口左下角。

