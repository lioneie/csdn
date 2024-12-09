
[点击这里在哔哩哔哩bilibili在线观看配套的教学视频《搭建个人主页-局域网》](https://www.bilibili.com/video/BV14z421z7Mb/)。

[点击这里在哔哩哔哩bilibili在线观看配套的教学视频《搭建个人主页-公网》](https://www.bilibili.com/video/BV1Tm421579v/)。

[点击这里在哔哩哔哩bilibili在线观看配套的教学视频《个人域名后缀的邮箱》](https://www.bilibili.com/video/BV1uE421N7iC/)。

这篇文章记录一下我是如何搭建[我那个简陋的个人网站](https://chenxiaosong.com/)，以及怎么拥有像chenxiaosong@chenxiaosong.com这种个人域名后缀的邮箱。各位朋友如果有更好的建议，请务必联系我。

# 域名和公网ip

首先，得先申请个域名，比如《你的名字拼音全拼.com》，可以在[阿里云](https://dc.console.aliyun.com/next/index?spm=5176.100251.console-base.ddomain.17894f15m8MjuR#/overview)、腾讯云等平台注册申请。然后还要有一台有公网ip的服务器，我用的是[阿里云的服务器](https://ecs.console.aliyun.com/home#/)。再把这个域名对应到这个公网ip上。

注意默认的80端口要放开。

# 简陋的个人网站

## nginx

Nginx（发音同「engine X」）是异步框架的网页服务器，也可以用作反向代理、负载平衡器和HTTP缓存。

ubuntu安装nginx:
```sh
apt install nginx -y
```

在[阿里云](https://yundun.console.aliyun.com/?p=cas#/certExtend/free/cn-hangzhou)购买免费SSL证书，再点击“创建证书”，点击“状态”栏中的感叹号，然后根据提示添加域名解析记录，注意证书签发后有效期为3个月。

将[`nginx-config`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/blog-web/nginx-config)复制到`/etc/nginx/sites-enabled/default`，具体的配置选项的解释请查看配置文件的具体内容。

重启nginx服务:
```sh
service nginx restart # 在docker中
sudo systemctl restart nginx
```

## nginx某个目录密码保护

安装软件:
```sh
apt-get install -y apache2-utils
yum install -y httpd-tools
```

创建密码文件:
```sh
htpasswd -c /etc/nginx/.htpasswd username # username 是你要设置的用户名
```

在`/etc/nginx/sites-enabled/default`加入以下配置:
```sh
       location /passwd {
               auth_basic "passwd access";   # 提示文本，可以随意设置
               auth_basic_user_file /etc/nginx/.htpasswd;  # 密码文件的路径
       }
```

## 检查.rst文件的格式

```sh
sudo apt install rstcheck -y
rstcheck file
```

## pandoc

pandoc用于将markdown或rst（ReStructuredText）格式文件转换成html。

安装:
```sh
apt-get install pandoc -y
```

具体的命令可以参考[`create-html.sh`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/blog-web/create-html.sh)，脚本里写了详细的说明。

## 脚本

先设置环境变量:
```sh
export MY_TOP_PATH=/your/top/path
export MY_CODE_TOP_PATH=${MY_TOP_PATH}/code/
```

[`restart.sh`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/blog-web/restart.sh)脚本用于更新git仓库，重新生成html文件，以及重启nginx服务:
```sh
bash src/blog-web/restart.sh
```

## 转pdf

### `chrome`

可以在图形界面系统中浏览器`右键 -> 打印(ctrl+p) -> 另存为pdf`。也可以参考[《无头 Chrome 使用入门》](https://developer.chrome.com/blog/headless-chrome?hl=zh-cn)使用命令行将链接存为pdf，`chrome`的路径可能在`/opt/google/chrome/chrome`。

### `wkhtmltopdf`

参考[linux.cn的《如何在 Linux 下将网页转换为 PDF 文件》](https://linux.cn/article-13928-1.html)。

注意不能用`apt`安装（目录不能跳转），要在[`wkhtmltopdf/packaging/releases`](https://github.com/wkhtmltopdf/packaging/releases/)里下载最新的版本，ubuntu22.04下载`jammy`相关的文件。

```sh
wkhtmltopdf --enable-internal-links --enable-external-links test.html test.pdf
wkhtmltopdf --enable-internal-links --enable-external-links https://chenxiaosong.com/courses/kernel/kernel-debug.html test.pdf
```

但代码框无法左右滑动，暂时不知道怎么搞TODO，知道的小伙伴一定要告诉我。

作为对比，用`apt`安装的`wkhtmltopdf`转换的pdf，代码框里的代码会自动换行，但目录不能跳转。后续准备看一下[`wkhtmltopdf`的源码](https://github.com/wkhtmltopdf/wkhtmltopdf)。

### `pandoc`

`man pandoc`中关于pdf的内容如下:
```
要生成PDF，请指定一个带有.pdf扩展名的输出文件:

       pandoc test.txt -o test.pdf

默认情况下，pandoc将使用LaTeX来创建PDF，这要求系统中安装了LaTeX引擎（请参见下面的--pdf-engine选项）。或者，pandoc也可以使用ConTeXt、roff ms或HTML作为中间格式。为此，请像之前一样指定一个带有.pdf扩展名的输出文件，但在命令行中添加--pdf-engine选项或使用-t context、-t html或-t ms。用于从中间格式生成PDF的工具可以使用--pdf-engine选项指定。

你可以使用变量来控制PDF的样式，具体取决于使用的中间格式: 请参阅LaTeX的变量、ConTeXt的变量、wkhtmltopdf的变量、ms的变量。当使用HTML作为中间格式时，可以使用--css选项来设置输出样式。

要调试PDF的创建，查看中间表示形式可能会有帮助: 不要使用-o test.pdf，而是使用例如-s -o test.tex来输出生成的LaTeX文件。然后你可以使用pdflatex test.tex来测试它。

使用LaTeX时，需要以下包（它们包含在所有最近版本的TeX Live中）: amsfonts、amsmath、lm、unicode-math、ifxetex、ifluatex、listings（如果使用--listings选项）、fancyvrb、longtable、booktabs、graphicx（如果文档包含图片）、hyperref、xcolor、ulem、geometry（设置geometry变量）、setspace（使用linestretch）、以及babel（使用lang）。使用xelatex或lualatex作为PDF引擎需要fontspec。xelatex使用polyglossia（使用lang）、xecjk和bidi（设置dir变量）。如果设置了mathspec变量，xelatex将使用mathspec而不是unicode-math。如果可用，upquote和microtype包将被使用，如果csquotes变量或元数据字段设置为true，csquotes包将用于排版。natbib、biblatex、bibtex和biber包可以选择性地用于引用渲染。以下包如果存在，将用于提高输出质量，但pandoc不要求它们必须存在: upquote（用于直引号在verbatim环境中）、microtype（用于更好的间距调整）、parskip（用于更好的段间距）、xurl（用于更好的URL换行）、bookmark（用于更好的PDF书签）、以及footnotehyper或footnote（允许表格中的脚注）。
```

默认用的是`--pdf-engine pdflatex`，也可以指定其他的`--pdf-engine`，如果未安装，会提示以下内容，根据文档安装所需的软件:
```
pdflatex not found. Please select a different --pdf-engine or install pdflatex -- see also /usr/share/doc/pandoc/README.Debian
```

安装`texlive-xetex`相关软件:
```sh
sudo apt install texlive-xetex texlive-lang-chinese -y
fc-list :lang=zh # 查看支持中文的字体
```

这时就可以转换了:
```sh
pandoc test.html --pdf-engine=xelatex -V CJKmainfont="AR PL UKai CN" -o test.pdf --metadata encoding=gbk --number-sections --css https://chenxiaosong.com/stylesheet.css
```

但`xelatex`字体好像有点小问题，感兴趣的朋友可以再研究一下。

还可以调用`wkhtmltopdf`:
```sh
pandoc test.html --pdf-engine=wkhtmltopdf -o test.pdf
```

这个和直接用`wkhtmltopdf`的效果好像是一毛一样。

## 被百度搜索到

你辛辛苦苦写的文章，肯定是希望被更多人看到，虽然百度上广告很多，但毕竟国内用的人还是多。

更具体的方法可以百度搜索，这里只说一下大致过程。进入[链接提交](https://ziyuan.baidu.com/linksubmit/url)，填写提交就可以了，听说要等个把月才能被搜索到。如果你的网站已经被收录了，在[百度搜索引擎](www.baidu.com)中搜索`site:chenxiaosong.com`能看到结果。

# 个人域名后缀的邮箱

是不是受够了在qq邮箱、foxmail邮箱、163邮箱注册邮箱时你的姓名全拼已经被抢注了，只能在后面加一些乱七八糟的后缀。你有了域名，加上腾讯企业邮箱（免费），就可以拥有一个类似 @chenxiaosong.com 结尾的邮箱了。

首先，在[腾讯企业微信网站](https://work.weixin.qq.com/wework_admin/register_wx?from=exmail&bizmail_code=&wwbiz_version=free&wwbiz_merge=true)上注册一个你个人的企业微信。然后以管理员身份登录到[企业微信](https://work.weixin.qq.com/wework_admin/loginpage_wx)，可通过【管理后台->协作->邮件->概况->配置】中绑定专属域名。详细的操作步骤可参考[如何添加/更换/注销域名？](https://open.work.weixin.qq.com/help2/pc/19809?person_id=1)，温馨提醒: 若域名历史没有绑定过邮箱使用且无需搬迁历史邮箱数据的，请选择左侧的【立即迁移】入口；反之，需要搬迁历史邮箱数据的，请选择【同步使用】入口迁移数据。

如果还是不知道怎么操作腾讯企业邮箱，请咨询企业微信客服。

# github.io

[GitHub Pages 文档](https://docs.github.com/zh/pages)。

首先在github上建立一个仓库，如[`chenxiaosonggithub.github.io`](https://github.com/chenxiaosonggithub/chenxiaosonggithub.github.io)，其中`chenxiaosonggithub`替换为你的github账号名，把html文件推送到这个仓库，注意要创建[`404.html`](https://github.com/chenxiaosonggithub/chenxiaosonggithub.github.io/blob/master/404.html)和[`CNAME`](https://github.com/chenxiaosonggithub/chenxiaosonggithub.github.io/blob/master/CNAME)。

在阿里云上配置DNS域名解析，添加记录类型`A`解析主域名`@`到记录值`185.199.108.153`、`185.199.109.153`、`185.199.110.153`、`185.199.111.153`之一（多个同时加好像不能生成ssl，但我不是很确定哈），再添加记录类型`CNAME`解析`www`到主域名。

直接把生成的html文件推送到仓库，然后设置 `Settings -> Pages -> Build and deployment -> Source: Deploy from a branch -> Branch: master`。

# gitee.io

[gitee静态页面托管](https://gitee.com/help/categories/56)。

Gitee Pages 已经暂停提供服务了，忽略。
