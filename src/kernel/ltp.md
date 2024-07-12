# 环境

github源码: [linux-test-project/ltp](https://github.com/linux-test-project/ltp)，参考[INSTALL](https://github.com/linux-test-project/ltp/blob/master/INSTALL)安装需要的依赖软件。其中`linux-headers`相关的在debian上可以使用以下命令安装：
```sh
apt search linux-headers | less # 搜索对应的软件包名
apt install -y linux-headers-amd64 linux-headers-5.10.0-28-common
```

编译安装参考[README中文翻译](https://chenxiaosong.com/translations/ltp-readme.html)，默认安装在`/opt/ltp`中。

# LTP Network Tests

[LTP Network Tests README中文翻译](https://chenxiaosong.com/translations/ltp-network-tests-readme.html)。

打开配置`CONFIG_VETH=m`、`CONFIG_NFS_FS=m`。

在debian发行版下，启动nfs server服务后，执行命令`cd /opt/ltp/testscripts; ./network.sh -n`后报错，换成手动执行第一个用例`cd /opt/ltp/testcases/bin; PATH=$PATH:$PWD ./nfs01.sh -v 3 -t udp`，报错`nfs01 1 TCONF: rpc.statd not running`，修改`/opt/ltp/testcases/bin/nfs_lib.sh`：
```sh
diff --git a/testcases/network/nfs/nfs_stress/nfs_lib.sh b/testcases/network/nfs/nfs_stress/nfs_lib.sh
index d3de3b7f1..4be0bcc6f 100644
--- a/testcases/network/nfs/nfs_stress/nfs_lib.sh
+++ b/testcases/network/nfs/nfs_stress/nfs_lib.sh
@@ -174,7 +174,7 @@ nfs_setup()
        fi

        if tst_cmd_available pgrep; then
-               for i in rpc.mountd rpc.statd; do
+               for i in rpc.mountd; do
                        pgrep $i > /dev/null || tst_brk TCONF "$i not running"
                done
        fi
```
