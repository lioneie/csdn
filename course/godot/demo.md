我们学一个新东西，肯定第一件事就是模仿，godot官方的demo撸一遍应该就能对这个游戏引擎的使用有个初步的掌握了。

开始吧。。。

# 你的第一个 2D 游戏 - Dodge the Creeps

- [参考文档](https://docs.godotengine.org/zh-cn/4.x/getting_started/first_2d_game/index.html)
- [官方demo源码](https://github.com/godotengine/godot-demo-projects/tree/master/2d/dodge_the_creeps)
- [我修改后能在手机上玩的版本](https://chenxiaosong.com/godot/2d-demo/2d-demo.html)

我的修改: [添加4个方向键](https://gitee.com/chenxiaosonggitee/blog/blob/master/course/godot/src/0001-2d-dodge_the_creeps-add-dir-buttons.patch)后，可以在手机浏览器上玩，[感兴趣的朋友可以点击这里试试](https://chenxiaosong.com/godot/2d-demo/2d-demo.html)。

建议直接看[参考文档](https://docs.godotengine.org/zh-cn/4.x/getting_started/first_2d_game/index.html)，这里我只记一些自己在撸的过程中遇到的一些疑难点，不会把官方指导文档里已有的内容搬过来。

单击“其他节点”按钮并将 Area2D 节点添加到场景中时，默认折叠视图中并没有将Area2D展示出来，最好是在“搜索”框中搜索一下。

设置透明度: 在“检查器”中搜索“modulate”。

