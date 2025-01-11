# 代码分析

`sysctl`命令是读取`/proc/sys/`下的文件，如:
```sh
sysctl kernel.softlockup_panic # /proc/sys/kernel/softlockup_panic
sysctl kernel.hung_task_panic # /proc/sys/kernel/hung_task_panic
sysctl kernel.usermodehelper.bset # /proc/sys/kernel/usermodehelper/bset
sysctl net.mptcp.enabled # /proc/sys/net/mptcp/enabled
```

```c
watchdog_sysctls
hung_task_sysctls
usermodehelper_table
mptcp_sysctl_table
```

# man手册

为方便查阅，将`man sysctl`翻译一下:
```sh
名称
       sysctl - 运行时配置内核参数

语法
       sysctl [选项] [变量[=值]] [...]
       sysctl -p [文件或正则表达式] [...]

描述
       sysctl 用于在运行时修改内核参数。可以配置的参数列在 /proc/sys/ 下。Linux 需要启用 procfs 才能支持 sysctl。你可以使用 sysctl 读取和写入 sysctl 数据。

参数
       变量
              要读取的键的名称。示例：kernel.ostype。也可以使用 '/' 作为分隔符替代 '.'。

       变量=值
              设置一个键，使用变量=值的形式，其中变量是键名，值是要设置的值。如果值包含引号或其他 shell 解析的字符，可能需要用双引号将值括起来。

       -n, --values
              使用此选项禁用在打印值时显示键名。

       -e, --ignore
              使用此选项忽略未知键的错误。

       -N, --names
              仅显示键名。对于支持命令自动补全的 shell，可能非常有用。

       -q, --quiet
              使用此选项时，不会将设置的值输出到标准输出。

       -w, --write
              强制所有参数为写操作，并且在无法解析时打印错误。

       -p[文件], --load[=文件]
              从指定的文件加载 sysctl 设置，若未指定文件，则从 /etc/sysctl.conf 加载。指定 "-" 作为文件名表示从标准输入读取数据。使用此选项时，参数为文件，按照指定的顺序读取这些文件。文件参数可以是正则表达式。

       -a, --all
              显示当前所有可用的值。

       --deprecated
              在 --all 值列表中包含已弃用的参数。

       -b, --binary
              打印值时不换行。

       --system
              从所有系统配置文件加载设置。请参见下面的系统文件优先级部分。

       -r, --pattern pattern
              仅应用匹配指定模式的设置。模式使用扩展正则表达式语法。

       -A     是 -a 的别名。

       -d     是 -h 的别名。

       -f     是 -p 的别名。

       -X     是 -a 的别名。

       -o     不执行任何操作，存在是为了与 BSD 兼容。

       -x     不执行任何操作，存在是为了与 BSD 兼容。

       -h, --help
              显示帮助文本并退出。

       -V, --version
              显示版本信息并退出。

系统文件优先级
       使用 --system 选项时，sysctl 会按照以下顺序读取目录中的文件。加载指定文件名的文件后，后续目录中相同文件名的文件会被忽略。

       /etc/sysctl.d/*.conf
       /run/sysctl.d/*.conf
       /usr/local/lib/sysctl.d/*.conf
       /usr/lib/sysctl.d/*.conf
       /lib/sysctl.d/*.conf
       /etc/sysctl.conf

       所有配置文件按字典顺序排序，不论它们所在的目录。配置文件可以被完全替换（通过在优先级更高的目录中使用相同文件名的配置文件）或部分替换（通过按顺序在后面列出其他配置文件）。

示例
       /sbin/sysctl -a
       /sbin/sysctl -n kernel.hostname
       /sbin/sysctl -w kernel.domainname="example.com"
       /sbin/sysctl -p /etc/sysctl.conf
       /sbin/sysctl -a --pattern forward
       /sbin/sysctl -a --pattern forward$
       /sbin/sysctl -a --pattern 'net.ipv4.conf.(eth|wlan)0.arp'
       /sbin/sysctl --pattern '^net.ipv6' --system

已弃用的参数
       base_reachable_time 和 retrans_time 已被弃用。sysctl 命令不允许修改这些参数的值。坚持使用已弃用内核接口的用户应通过其他方式将值推送到 /proc 文件系统。例如：

       echo 256 > /proc/sys/net/ipv6/neigh/eth0/base_reachable_time

文件
       /proc/sys
       /etc/sysctl.d/*.conf
       /run/sysctl.d/*.conf
       /usr/local/lib/sysctl.d/*.conf
       /usr/lib/sysctl.d/*.conf
       /lib/sysctl.d/*.conf
       /etc/sysctl.conf

参见
       proc(5), sysctl.conf(5), regex(7)

作者
       George Staikos ⟨staikos@0wned.org⟩

报告错误
       请将错误报告发送到 ⟨procps@freelists.org⟩

procps-ng                                                                                                      2023-08-19                                                                                                      SYSCTL(8)
```

