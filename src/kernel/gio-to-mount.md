# 方案总体思路

`gio mount -d /dev/sdx /media/${HOME}/xxx`命令执行时间长，`sudo mount /dev/sdx /media/${HOME}/xxx`命令执行时间短，临时的解决办法是把`gio`替换成`mount`，但`mount`需要`root`权限，可以让`sudo`组的用户不需要输入密码。

# `sudo`不需要密码

`/etc/sudoers`中将`%sudo	ALL=(ALL:ALL) ALL`修改成`%sudo	ALL=(ALL:ALL) NOPASSWD: ALL`，使`sudo`组的用户执行`sudo`命令时不需要密码。

# `gio`替换成`sudo mount`

重命名原始的`gio`文件:
```sh
sudo mv /usr/bin/gio /usr/bin/gio-origin
```

新建`/usr/bin/gio`脚本:
```sh
ORIGIN_OPTIONS=$@ # 全部的参数

if [ $1 = "mount" ]
then
        shift 2 # 跳过前2个参数
        OPTIONS="$@"
	    sudo mount $OPTIONS
        # echo "过滤后的参数 OPTIONS: $OPTIONS"
else
	    gio-origin $ORIGIN_OPTIONS
        # echo "不过滤的参数 ORIGIN_OPTIONS: $ORIGIN_OPTIONS"
fi
```

让`/usr/bin/gio`脚本可执行:
```sh
sudo chmod 777 /usr/bin/gio
```

# `umount`替换成`sudo umount`

重命名原始的`umount`文件:
```sh
sudo mv /usr/bin/umount /usr/bin/umount-origin
```

新建`/usr/bin/umount`脚本:
```sh
sudo umount-origin $@
```

让`/usr/bin/umount`脚本可执行:
```sh
sudo chmod 777 /usr/bin/umount
```