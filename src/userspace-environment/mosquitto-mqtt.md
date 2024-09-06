从事LoRaWAN开发时，调试需要用到MQTT服务器，使用mosquitto软件搭建MQTT服务器。

本文以Fedora33为例，说明mosquitto软件的安装和使用。

# 安装

安装mosquitto: `sudo dnf install mosquitto -y`

开启mosquitto服务: `sudo systemctl start mosquitto`

关闭mosquitto服务: `sudo systemctl stop mosquitto`

查看mosquitto状态: `sudo systemctl status mosquitto`

开机启动服务: `sudo systemctl enable mosquitto`

> 注意: 有些系统上mosquitto-clients还需要另外安装（如ubuntu，`sudo apt install mosquitto-clients -y`）。

# 订阅消息

使用以下命令订阅消息:

`sudo mosquitto_sub -t "#" -h localhost`

其中`-t "#"`表示订阅所有的MQTT topic，`-h localhost`表示MQTT服务器的ip为localhost

# 发布消息

使用以下命令发布消息:

`sudo mosquitto_pub -t "topic" -m "message" -h localhost`

其中`-t "topic"`表示MQTT的topic，`-m "message"`表示发布的消息，`-h localhost`表示MQTT服务器的ip为localhost

# MQTT账号密码

编辑配置文件 `sudo vim /etc/mosquitto/mosquitto.conf`，在文件末尾添加以下内容:

```sh
allow_anonymous false # 不能匿名访问
password_file /etc/mosquitto/pwfile # 存放密码的文件
```

第一次新建MQTT账号（**带有选项-c**）:

`sudo mosquitto_passwd -c /etc/mosquitto/pwfile 账号名`

增加MQTT账号（**无选项-c**）:

`sudo mosquitto_passwd /etc/mosquitto/pwfile 账号名`

最后重启mosquitto服务:

`sudo systemctl restart mosquitto`

订阅消息的命令要修改成:

`sudo mosquitto_sub -t "#" -h localhost -u 账号名 -P 密码`

发布消息的命令要修改成:

`sudo mosquitto_pub -t "topic" -m "message" -h localhost -u 账号名 -P 密码`

