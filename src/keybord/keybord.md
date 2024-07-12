这里记录一下我在各个平台上使用的键盘配置，以及我使用的独立键盘。

# Linux

xmodmap是Linux桌面系统用于更改键位分布的软件，具体查看[《Linux配置文件》](https://chenxiaosong.com/linux/linux-config.html)中有关xmodmap配置相关的章节。

# macOS

[`Karabiner-Elements`](https://karabiner-elements.pqrs.org/), 要开启权限`Privacy & Security` -> `Input Monitoring`, 添加`karabiner_observer`、`karabiner_grabber`、`Karabiner-Elements`、`Karabiner-EventViewer`。有时权限还是有问题，需要通过先卸载软件再安装来解决。

`Complex Modifications`复杂的映射要修改文件`/Users/sonvhi/.config/karabiner/karabiner.json`。

查看按键名称可以使用`karabiner-EventViewer`查看。

默认按`caps_lock`键会切换输入法，设置 `Keybord` -> `Text input` -> `Input Sources` -> `Edit` -> `All Input Sources` -> 关闭`Use the Caps Lock key to switch to and from ABC`

默认按`caps_lock`键会切换输入法，设置 `Keybord` -> `Press fn(是一个地球图标) key to` 选 `Do Nothing`。

我使用的配置文件：[karabiner.json](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/keybord/karabiner.json)，放到macOS的`~/.config/karabiner/karabiner.json`路径下。

# windows autohotkey

windows上更改键位可以使用[autohotkey](https://www.autohotkey.com/)，有两个版本：

- [按键列表v1](https://wyagd001.github.io/zh-cn/docs/KeyList.htm)
- [按键列表v2](https://wyagd001.github.io/v2/docs/KeyList.htm)

v1版本的配置：[autohotkey-v1.1.ahk](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/keybord/autohotkey-v1.1.ahk)。

# hhkb

我用的键盘是HHKB，另外还买了一个[YDKB的控制模块](https://ydkb.io/)。

蓝牙出问题，可以尝试[清除配对信息按键 LShift+RShift+LCtrl+R](https://ydkb.io/help/#/ble-series/troubleshooting)。