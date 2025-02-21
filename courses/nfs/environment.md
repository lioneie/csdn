# nfs server环境

## 步骤

nfs server安装所需软件:
```sh
apt-get install nfs-kernel-server -y # debian
dnf install nfs-utils -y # openeuler
```

nfs server编辑`exportfs`的配置文件`/etc/exports`，配置选项的含义可以通过命令`man 5 exports`查看:
```sh
/tmp/ *(rw,no_root_squash,fsid=0)
/tmp/s_test/ *(rw,no_root_squash,fsid=1)
/tmp/s_scratch *(rw,no_root_squash,fsid=2)
```

或者使用以下命令，具体用法查看`man 8 exportfs`:
```sh
exportfs -i -o fsid=148252,no_root_squash,rw *:/tmp/s_test # 添加
exportfs -u *:/tmp/s_test # 删除
```

执行脚本[nfs-svr-setup.sh](https://gitee.com/chenxiaosonggitee/blog/blob/master/courses/nfs/src/nfs-svr-setup.sh)启动nfs server，其中，`rpcbind`（在服务文件`/lib/systemd/system/rpcbind.service`中）负责端口的对应工作（以前叫`portmap`），其他程序请查看`/lib/systemd/system/nfs-server.service`服务文件。

## 软件和配置文件

`/etc/exports`的配置格式如下:
```sh
# 注意不能使用 192.168.122.* 而要使用 192.168.122.0/24
# [分享出去的目录]   [ip/(权限)]             [主机名]         [通配符]
tmp              192.168.122.0/24(ro)   localhost(rw)   *.chenxiaosong.com(ro,sync)
```
详细的配置查看`man 5 exports`，下面介绍几个常用的:

- `rw`可读可写，`ro`只读。
- `sync`写入磁盘，`async`先存放在内存中。
- client账号为root时，默认`root_squash`压缩成`nobody(nfsnobody) `，`no_root_squash`不压缩。
- `all_squash`把所有的用户都压缩成`nobody(nfsnobody)`。
- `anonuid,anongid`设置`nobody(nfsnobody)`对应的uid和gid。
- `nohide`和`crossmnt`: 仅针对v2和v3.
- `fsid=num|root|uuid`: 文件系统标识。

用以下命令查看开了哪些端口:
```sh
netstat -tulnp| grep -E '(rpc|nfs)'
```

以下命令查看rpc状态:
```sh
# -p: 针对ip
rpcinfo -p localhost
# -t: tcp, -u: udp
rpcinfo -t localhost nfs # nfs程序检查软件版本信息（tcp）
```

以下命令查看或操作分享的目录:
```sh
showmount -e localhost # 查看
exportfs # 查看
# -a: 全部，-r: 重新, -u: 取消，-v: 打印
exportfs -arv # 重新分享
exportfs -auv # 全部删除
```

还有两个文件:

- `/var/lib/nfs/etab`: 记录`/etc/exports`配置文件或`exportfs`命令分享出来的目录权限配置值。
- `/var/lib/nfs/xtab`和`/var/lib/nfs/rmtab`: 记录客户端数据。

# nfs client环境

nfs client安装所需软件:
```sh
apt-get install nfs-common -y # debian
dnf install nfs-utils -y # openeuler
```

nfs client挂载（更多挂载选项可以通过命令`man 5 nfs`查看）:
```sh
# nfsv4的根路径是/tmp/，源路径填写相对路径 /s_test 或 s_test
mount -t nfs -o vers=4.0 ${server_ip}:/s_test /mnt
mount -t nfs -o vers=4.1 ${server_ip}:/s_test /mnt
mount -t nfs -o vers=4.2 ${server_ip}:/s_test /mnt
# nfsv3和nfsv2 源路径要写完整的源路径，没有根路径的概念，源路径必须是绝对路径/tmp/s_test
mount -t nfs -o vers=3 ${server_ip}:/tmp/s_test /mnt
# nfsv2, nfs server 需要修改 /etc/nfs.conf 中的 `[nfsd] vers2=y`,但在Debian 11 (bullseye) 上安装的nfs-utils 1.3.3上找不到/etc/nfs.conf
mount -t nfs -o vers=2 ${server_ip}:/tmp/s_test /mnt
```

如果nfs server的exportfs的配置文件`/etc/exports`如下，没有`fsid`选项:
```sh
/tmp/s_test/ *(rw,no_root_squash)
```

这时nfsv4的根路径就是`/`，nfs client挂载nfsv4的命令如下:
```sh
mount -t nfs -o vers=4.0 ${server_ip}:/tmp/s_test /mnt # 或 tmp/s_test
```

要注意的是nfs不能在`/etc/fstab`文件中配置开机挂载，因为那时网络还没启动。