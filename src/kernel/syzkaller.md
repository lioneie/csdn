<!--
https://i-m.dev/posts/20200313-143737.html

配置： https://github.com/google/syzkaller/blob/master/pkg/mgrconfig/config.go

复现：
```shell
./syz-execprog -executor=./syz-executor -repeat=0 -procs=16 -cover=0 ./log0
```

```sh
CONFIG_KCOV=y
CONFIG_KCOV_INSTRUMENT_ALL=y
CONFIG_KCOV_ENABLE_COMPARISONS=y
CONFIG_DEBUG_FS=y

CONFIG_CMDLINE_BOOL=y
CONFIG_CMDLINE="net.ifnames=0"

CONFIG_E1000=y
CONFIG_E1000E=y
CONFIG_E1000E_HWTS=y

CONFIG_BINFMT_MISC=y
```
-->
参考：

- [syzkaller源码](https://github.com/google/syzkaller)
- [syzkaller文档翻译](https://chenxiaosong.com/translations/syzkaller.html)

# 软件环境

打开[All releases - The Go Programming Language](https://go.dev/dl/)，下载最新版本，如`go1.22.5.linux-amd64.tar.gz`:
```sh
wget https://go.dev/dl/go1.22.5.linux-amd64.tar.gz
tar xvf go1.22.5.linux-amd64.tar.gz
export GOROOT=`pwd`/go
export PATH=$GOROOT/bin:$PATH
```

编译`syzkaller`源码：
```sh
git clone https://github.com/google/syzkaller
cd syzkaller
make # 编译结果在 bin/
```

安装软件：
```sh
sudo apt update
sudo apt install make gcc flex bison libncurses-dev libelf-dev libssl-dev -y
```

内核[x86_64-config](https://gitee.com/chenxiaosonggitee/tmp/blob/master/configs/x86_64-config)文件还要打开以下配置：
```sh
# Debug info for symbolization.
CONFIG_DEBUG_INFO_DWARF4=y

# Memory bug detector，这玩意儿会导致运行很慢，所以如果不是测试的不要打开
CONFIG_KASAN=y
CONFIG_KASAN_INLINE=y
```

# 生成`qcow2`镜像

```sh
sudo apt install debootstrap -y
```

```sh
mkdir syzkaller-image
cd syzkaller-image
wget https://raw.githubusercontent.com/google/syzkaller/master/tools/create-image.sh -O create-image.sh
chmod +x create-image.sh
```

为了加快下载速度，然后将`create-image.sh`中的`DEBOOTSTRAP_PARAMS="--keyring /usr/share/keyrings/debian-archive-removed-keys.gpg $DEBOOTSTRAP_PARAMS`后面的链接修改成`https://repo.huaweicloud.com/debian/`。但有些网络下也不会加快太多，可以想办法访问国外网络进行下载。

再运行脚本生成`bullseye.img`：
```sh
./create-image.sh
```

生成`bullseye.img`后，用以下脚本启动测试一下：
```sh
qemu-system-x86_64 \
    -m 2G \
    -smp 16 \
    -kernel /home/sonvhi/chenxiaosong/code/x86_64-linux/build/arch/x86/boot/bzImage \
    -append "console=ttyS0 root=/dev/sda earlyprintk=serial net.ifnames=0" \
    -drive file=bullseye.img,format=raw \
    -net user,host=10.0.2.10,hostfwd=tcp:127.0.0.1:10021-:22 \
    -net nic,model=e1000 \
    -enable-kvm \
    -nographic \
```

确保能远程登录：
```sh
ssh -i bullseye.id_rsa -p 10021 -o "StrictHostKeyChecking no" root@localhost
```

测试完后，要把虚拟机关机，因为syzkaller会自己启动虚拟机。如果你已经用上面的脚本启动了虚拟机，再启动syzkaller就会启动失败，而且`qcow2`镜像也会损坏。

# 运行

到syzkaller源码目录下，创建`my.cfg`文件如下：
```sh
{
    "target": "linux/amd64",
    "http": "0.0.0.0:56741",
    "workdir": "workdir",
    # 这个应该是vmlinux的路径
    "kernel_obj": "/home/sonvhi/chenxiaosong/code/x86_64-linux/build/",
    "image": "/home/sonvhi/chenxiaosong/syzkaller-image/bullseye.img",
    "sshkey": "/home/sonvhi/chenxiaosong/syzkaller-image/bullseye.id_rsa",
    "syzkaller": ".",
    # 只测 chmod 系统调用
	# "enable_syscalls": ["chmod"],
    "procs": 8,
    "type": "qemu",
    "vm": {
        "count": 4,
        "kernel": "/home/sonvhi/chenxiaosong/code/x86_64-linux/build/arch/x86/boot/bzImage",
        "cpu": 2,
        "mem": 2048
    }
}
```

运行：
```sh
mkdir workdir
./bin/syz-manager -config=my.cfg
```

这时就能通过网页查看测试结果。如果你是在docker中运行syzkaller，想在加一台电脑上访问网页，可以在宿主机中安装nginx，并在nginx配置文件`/etc/nginx/sites-enabled/default`中添加以下内容，`172.17.0.3`是docker的ip：
```sh
server {
        listen 56741;

        location / {
                proxy_pass http://172.17.0.3:56741/;
        }
}
```

这时就可以在其他电脑上访问`http://192.168.3.224:56741/`（`192.168.3.224`是宿主机的ip）。

# 构造一个简单的bug

连续两次`chmod`调用的mode入参为0时，产生空指针解引用的bug，这个函数的执行路径是`chmod() -> do_fchmodat() -> chmod_common()`。

```sh
diff --git a/fs/open.c b/fs/open.c
index 50e45bc7c4d8..ee7962ca777d 100644
--- a/fs/open.c
+++ b/fs/open.c
@@ -637,6 +637,12 @@ int chmod_common(const struct path *path, umode_t mode)
        struct iattr newattrs;
        int error;

+        static umode_t old_mode = 0xffff;
+        if (old_mode == 0 && mode == 0) {
+                path = NULL;
+        }
+        old_mode = mode;
+
        error = mnt_want_write(path->mnt);
        if (error)
                return error;
```

到syzkaller源码目录下，`my.cfg`文件修改成如下，增加`enable_syscalls`，只测试`chmod`：
```sh
{
    "target": "linux/amd64",
    "http": "0.0.0.0:56741",
    "workdir": "workdir",
    # 这个应该是vmlinux的路径
    "kernel_obj": "/home/sonvhi/chenxiaosong/code/x86_64-linux/build/",
    "image": "/home/sonvhi/chenxiaosong/syzkaller-image/bullseye.img",
    "sshkey": "/home/sonvhi/chenxiaosong/syzkaller-image/bullseye.id_rsa",
    "syzkaller": ".",
    # 只测 chmod 系统调用
	"enable_syscalls": ["chmod"],
    "procs": 8,
    "type": "qemu",
    "vm": {
        "count": 4,
        "kernel": "/home/sonvhi/chenxiaosong/code/x86_64-linux/build/arch/x86/boot/bzImage",
        "cpu": 2,
        "mem": 2048
    }
}
```

运行：
```sh
mkdir workdir
./bin/syz-manager -config=my.cfg
```

# 复现

可以在[syzbot](https://syzkaller.appspot.com/upstream)中找发现的bug，有crash的日志和复现程序（syz和C），把`bin/linux_amd64/`复制到要测试的虚拟机中，按以下步骤复现。

```sh
echo 1 > /proc/sys/kernel/panic_on_oops # 注意不能用 vim 编辑
cat /proc/sys/kernel/panic_on_oops # 确认是否生效
./linux_amd64/syz-execprog -executor=./linux_amd64/syz-executor -repeat=0 -procs=16 -cover=0 crash-log
./linux_amd64/syz-execprog -executor=./linux_amd64/syz-executor -repeat=0 -procs=16 -cover=0 file-with-a-single-program
```

<!--
./syz-prog2c -prog linux_amd64/test.txt -enable=all -threaded -repeat=2 -procs=8 -sandbox=namespace -segv -tmpdir

将程序转换为c代码，repeat默认为1，当转换不成功时，增加重复数量。

也可在转换为c代码前，排除掉单个程序中不会导致崩溃的系统调用，得到最终某几个系统调用触发的崩溃，在用syz-prog2c进行c代码的转换。
-->
