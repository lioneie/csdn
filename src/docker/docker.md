这篇文章就是记录一些常用的docker操作命令，方便后续查阅。

# 安装docker

参考[Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)

ubuntu环境安装docker步骤如下:
```sh
sudo apt-get remove docker docker-engine docker.io containerd runc -y
sudo apt-get update -y
sudo apt-get install ca-certificates curl gnupg lsb-release -y
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.huaweicloud.com/docker-ce/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://repo.huaweicloud.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
```

# 配置docker权限

查看是否有`docker`组:
```sh
sudo cat /etc/group | grep docker
```

如果没有则创建，如果有就不需要创建:
```sh
sudo groupadd docker
```

查看当前用户是否在组中:
```sh
groups | grep docker
```

如果没有则添加到组中:
```sh
sudo usermod -aG docker $USER # 或者使用 sudo gpasswd -a sonvhi docker
su - $USER # 或退出shell重新登录, 但在tmux中不起作用
```

# 镜像和容器

## 镜像加速和代理

点击[阿里云镜像加速器](https://cr.console.aliyun.com/cn-hangzhou/instances/mirrors)，登录阿里云账号，按照网页提示操作。我试了，好像没什么卵用。

配置代理:
```sh
sudo mkdir /etc/systemd/system/docker.service.d/
sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf <<-'EOF'
[Service]
Environment="HTTP_PROXY=http://172.17.0.1:1081/"
Environment="HTTPS_PROXY=http://172.17.0.1:1081/"
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```

## 常用命令

以下是一些常用命令:
```sh
docker pull ubuntu:22.04 # 下载镜像
docker image rm ubuntu:22.04 # 删除镜像
docker image ls # 查看镜像
docker ps -a # 查看容器
docker save xxxxxxxxxx > ubuntu-xxxx:22.04.tar # 保存镜像
docker container prune # 删除全部容器
docker restart xxxxxxx # 重启容器
docker attach xxxxxxxx # 退出后会导致容器停止
docker exec -it xxxxxxxx bash # 启动bash，退出bash后不会导致容器停止
# -i: 交互式操作
# -t: 终端
# -d: 后台运行
# --privileged: 以特权模式运行容器, 容器将拥有对主机系统硬件的完全访问权限, 如kvm
docker run ... # 根据镜像启动容器
```

执行`gcc`命令后立刻删除容器:
```sh
# --rm 命令执行完后删除容器
docker run --rm -v "$PWD":/usr/src/myapp -w /usr/src/myapp workspace-ubuntu:22.04 /bin/gcc -v
```

后台运行，停止后会立即删除容器:
```sh
# --rm 停止容器后会删除容器
docker run --name rm-workspace --hostname rm-workspace --rm -itd -v /home/sonvhi/chenxiaosong:/home/sonvhi/chenxiaosong -w /home/sonvhi/chenxiaosong workspace-ubuntu:22.04 bash
docker exec -it rm-workspace bash # 启动bash，退出bash后不会导致容器停止
```

启动脚本[`start.sh`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/docker/start.sh)。

## 更新镜像

当要把一个容器保存成镜像时，执行以下命令:
```sh
docker run --name workspace --hostname workspace --privileged -it -v /home/sonvhi/chenxiaosong:/home/sonvhi/chenxiaosong -w /home/sonvhi/chenxiaosong workspace-ubuntu:22.04 bash # 前台运行，停止后不删除容器
docker ps -a # 查看容器
docker stop workspace # 停止容器
rm workspace-ubuntu\:22.04.tar # 确保当前目录下没有文件
docker export workspace > workspace-ubuntu:22.04.tar # 导出容器
docker rm workspace # 删除容器
docker ps -a # 查看容器是否删除成功
docker image rm workspace-ubuntu:22.04 # 删除镜像
docker image ls # 查看镜像是否删除成功
cat workspace-ubuntu\:22.04.tar | docker import - workspace-ubuntu\:22.04 # 导入镜像
```

脚本[`update-image.sh`](https://gitee.com/chenxiaosonggitee/blog/blob/master/src/docker/update-image.sh)。

## 中文支持

docker中的ubuntu2204默认不支持中文，需要安装某些软件:
```shell
apt install -y language-pack-zh-hans
apt install -y fonts-wqy-zenhei
apt install -y fonts-wqy-microhei
echo "export LANG=zh_CN.UTF-8" >> ~/.bashrc
echo "export LANGUAGE=zh_CN:zh" >> ~/.bashrc
echo "export LC_ALL=zh_CN.UTF-8" >> ~/.bashrc
source ~/.bashrc
```

## ssh登录

ubuntu中默认不能以root登录，作如下更改:
```shell
# 先安装一些网络工具包
apt update -y
apt install net-tools -y
apt install iputils-ping -y
apt install openssh-client -y
apt install openssh-server -y
vim /etc/ssh/sshd_config # PermitRootLogin prohibit-password 改为 PermitRootLogin yes
service ssh restart # docker 中不能使用 systemctl 启动 ssh
```

# macos环境

macos的docker要想与宿主机通信，要进行端口映射，启动时要加选项`-p 8888:8888`，macos下用docker我个人只是为了看代码（使用code-server）。

当要把一个容器保存成镜像时，执行以下命令:
```sh
# macos 中要进行端口映射，因为没有像 linux 中的 docker0 网络
docker run -p 8888:8888 --name workspace --hostname workspace -it -v /Users/sonvhi/chenxiaosong:/home/sonvhi/chenxiaosong -w /home/sonvhi/chenxiaosong workspace-ubuntu:22.04 bash # 前台运行
docker ps -a # 查看容器
docker stop workspace # 停止容器
rm workspace-ubuntu\:22.04.tar # 删除文件
docker export workspace > workspace-ubuntu:22.04.tar # 导出容器
docker rm workspace # 删除容器
docker ps -a # 查看容器是否删除成功
docker image rm workspace-ubuntu:22.04 # 删除镜像
docker image ls # 查看镜像是否删除成功
cat workspace-ubuntu\:22.04.tar | docker import - workspace-ubuntu\:22.04 # 导入镜像
```

后台运行，停止后删除容器:
```sh
docker run -p 8888:8888 --name rm-workspace --hostname rm-workspace --rm -itd -v /Users/sonvhi/chenxiaosong:/home/sonvhi/chenxiaosong -w /home/sonvhi/chenxiaosong workspace-ubuntu:22.04 bash # 后台运行
docker exec -it rm-workspace bash # 启动bash，退出bash后不会导致容器停止
```