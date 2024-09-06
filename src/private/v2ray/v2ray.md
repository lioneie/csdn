作为程序员，使用google搜索当然是必不可少的，如果使用百度搜索在绝大多数情况下只会得到一些广告。

本文档的编写目的是为了下次重新搭建代理服务器时的查询。

v2ray的github项目为[v2ray-core](https://github.com/v2fly/v2ray-core)。

安装说明请参考[install.md](https://github.com/v2fly/manual/blob/master/zh_cn/chapter_00/install.md)。

配置文件参考[VMess-Websocket](https://github.com/v2fly/v2ray-examples/tree/master/VMess-Websocket)。

# v2ray服务器安装与配置

可以使用以下命令安装:

```shell
bash <(curl https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
```

也可以在[项目的Releases](https://github.com/v2fly/v2ray-core/releases)界面选择一个版本下载Linux的安装包, 如[v2ray-linux-64.zip-v5.4.1](https://github.com/v2fly/v2ray-core/releases/download/v5.4.1/v2ray-linux-64.zip)。

将`/usr/local/etc/v2ray/config.json`的内容替换成[config_server.json](https://github.com/v2fly/v2ray-examples/blob/master/VMess-Websocket/config_server.json)中的内容，并修改以下内容

```json
...
 "port": 12345,	// 如果出现突然无法访问或不稳定，可以尝试修改端口
...
 "id": "12345678-1234-1234-1234-123456789012",		// 可自定义id
 "alterId": 64 // 客户端的值 <= 服务端的值, 两端都为64时无法使用(原因待分析)
...
```

修改完配置文件后，需要重启v2ray服务:

```shell
sudo systemctl restart v2ray
```

如果启动v2ray服务时报错，检查 `v2ray.service`文件:

```shell
[Service]
User=sonvhi # 修改成当前用户名
...
```

# linux系统客户端安装与配置

可以使用以下命令安装:

```shell
bash <(curl https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
```

也可以在[项目的Releases](https://github.com/v2fly/v2ray-core/releases)界面选择一个版本下载Linux的安装包, 如[v2ray-linux-64.zip-v5.4.1](https://github.com/v2fly/v2ray-core/releases/download/v5.4.1/v2ray-linux-64.zip)。

将`/usr/local/etc/config.json`的内容替换成[config_client.json](https://github.com/v2fly/v2ray-examples/blob/master/VMess-Websocket/config_client.json)中的内容，并修改以下内容:

```json
...
        "address": "请填写服务器ip", // 服务器地址，请修改为你自己的服务器 ip 或域名
        "port": 12345,  // 服务器端口
        "users": [{ 
			"id": "12345678-1234-1234-1234-123456789012",	// 与服务器id一样
...
```

修改完配置文件后，需要重启v2ray服务:

```sh
sudo systemctl restart v2ray
```

打开 设置 -> Network -> Manual -> HTTP proxy / HTTPS Proxy 127.0.0.1 1081

# macOS系统客户端安装与配置

在[项目的Releases](https://github.com/v2fly/v2ray-core/releases)界面选择一个版本下载macOS的安装包, 如[v2ray-macos-arm64-v8a.zip-v5.4.1](https://github.com/v2fly/v2ray-core/releases/download/v5.4.1/v2ray-macos-arm64-v8a.zip)。

解压后将`config.json`的内容替换成[config_client.json](https://github.com/v2fly/v2ray-examples/blob/master/VMess-Websocket/config_client.json)中的内容，并修改以下内容:
```json
...
 "port": 12345,	// 如果出现突然无法访问或不稳定，可以尝试修改端口
...
 "id": "12345678-1234-1234-1234-123456789012",		// 可自定义id
 "alterId": 64 // 客户端的值 <= 服务端的值, 两端都为64时无法使用(原因待分析)
...
```

修改完配置文件后，打开terminal，在解压的文件夹下执行以下命令:

```shell
./v2ray run
```

配置所连接网络的代理`Server: localhost, Port: 1081`。

# 安卓客户端安装与配置

下载v2ray的[安卓安装包](https://github.com/2dust/v2rayNG/releases)，并新建与服务器对应的配置。

![](https://chenxiaosong.com/pictures/v2ray-android.jpeg)

# Windows系统客户端安装与配置

在[项目的Releases](https://github.com/v2fly/v2ray-core/releases)界面选择一个版本下载Windows的安装包, 如[v2ray-windows-64-v8a.zip-v5.4.1](https://github.com/v2fly/v2ray-core/releases/download/v5.4.1/v2ray-windows-64.zip)

解压后将`config.json`的内容替换成[config_client.json](https://github.com/v2fly/v2ray-examples/blob/master/VMess-Websocket/config_client.json)中的内容，并修改以下内容:
```json
...
 "port": 12345,	// 如果出现突然无法访问或不稳定，可以尝试修改端口
...
 "id": "12345678-1234-1234-1234-123456789012",		// 可自定义id
 "alterId": 64 // 客户端的值 <= 服务端的值, 两端都为64时无法使用(原因待分析)
...
```

修改完配置文件后，打开windows的`cmd`程序，在解压的文件夹下执行以下命令:

```shell
.\v2ray run
```

然后配置网络的http代理 `localhost:1081`。
