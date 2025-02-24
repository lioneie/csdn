[点击这里查看配套的视频](https://chenxiaosong.com/video.html)。

本文章的目的不是教学五笔，而是谈谈为什么要用五笔，还有一些笔记。

# 用五笔的好处

以下几点是我个人选择用五笔的理由:

1. 打字快。当然，关于五笔打字快可能很多人不认同，认为现在的智能拼音输入法打字也很快。没错，那些用拼音打字快的大佬，如果用五笔打字的话，也许速度会更快。
2. 让打字变成玩游戏。人不是机器，如果让人一直重复一件事情，而这件事情又很简单（比如用拼音打字），会让人产生枯燥的感觉，然后就会讨厌这件事。很多程序员说他们不喜欢写文档，可能（当然不是绝对）有部分原因就是因为觉得打字无聊。而使用五笔输入法会让人觉得打字是在玩游戏，比使用拼音输入法打字更有挑战性。我个人觉得打字有意思，喜欢写文档，也喜欢写博客并分享出来，很大程度上是因为我用五笔输入法。
3. 错别字少。你问我使用五笔输入法有没打错过字？我会回答你: 有，但。。。很少打错。使用五笔输入法因为重码少，基本不需要选择，如果选错了也会是天差地别的另一个字，很容易发现。
4. 其他原因。暂时不知道怎么描述。。。

# 五笔字根助记词

用五笔很多年了，虽然大部分时候不需要字根助记词，但偶尔还是会回想一下，[点击这里查看86版五笔字根助记词](https://chenxiaosong.com/picture/wubi-86.png)。

# Linux五笔输入法安装与配置

安装五笔（如果你Linux安装语言是中文的已经默认安装了五笔）:

```shell
# fedora
sudo yum install ibus*wubi* -y

# ubuntu
sudo apt update -y
sudo apt install ibus*wubi* -y
```

会安装haifeng和jidian两个五笔输入法，注意，安装完后要**重启系统**（应该也有不重启系统就能用的办法，但我重启了）。

然后，在Fedora系统配置中，**Region & Language -> Input sources** 选择五笔输入法。

ubuntu系统配置中，**Keyboard -> Input sources**添加五笔输入法，**Keyboard shortcuts**更改切换输入法的快捷键。

Linux下的极点五笔输入法，四码唯一不自动上屏，打开五笔的设置，修改: Details -> Auto commit mode: **Normal**

Linux系统五笔输入法，如果按右shift键，会变成拼音输入法（当然，不是智能拼音）。

> Android和iOS系统，我用的是**搜狗五笔输入法**。

# ibus输入法更改快捷键

```shell
cp /usr/share/ibus-table/engine/table.py /usr/share/ibus-table/engine/table.py.bak # 备份
```
在`/usr/share/ibus-table/engine/table.py`文件中删除或注释以下内容，去除`ctrl+/`切换commit快捷键（与emacs快捷键冲突）:
```python
         # Match direct commit mode switch hotkey
         if (self._match_hotkey(
                 key, IBus.KEY_slash,
                 IBus.ModifierType.CONTROL_MASK)
                 and  self.db.user_can_define_phrase and self.db.rules):
             self.set_autocommit_mode(not self._auto_commit)
             return True
```

重启ibus:
```shell
sudo ibus-daemon -r # 好像没用，需要重启系统
```

当然，如果实在不想改配置，emacs撤消快捷键就不要用`ctrl+/`，可以用`ctrl+x u`。

# 最后

五笔是一个工具，就和Linux系统一样，不需要觉得很难，用的过程就是学习的过程，其实不需要花费很多时间学习。

就我个人而言，初学时大概3天基本就熟悉五笔了，7天左右就比我用拼音输入法快了（当然，这7天时间我没使用过拼音，一直在用五笔）。

练习的话，可以使用 [金山打字通](https://www.51dzt.com/rubik-ssr/51dzt) 这个软件，我读小学时在Windows上用这个软件练习过五笔，但可惜的是，这个软件没有Linux版本。
