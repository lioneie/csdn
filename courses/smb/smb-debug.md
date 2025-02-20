# 打印

## server打印

smb server打印函数是`ksmbd_debug()`，相关代码如下:
```c
ksmbd_debug
  // 拼接成 KSMBD_DEBUG_ALL 等宏定义
  if (ksmbd_debug_types & KSMBD_DEBUG_##type)

// 使用宏拼接
CLASS_ATTR_RW(debug)
  struct class_attribute class_attr_debug = __ATTR_RW(debug)
    __ATTR(debug, 0644, debug_show, debug_store)
      .attr = {.name = __stringify(debug),
        __stringify_1(x)
          #debug ==> /sys/class/ksmbd-control/debug文件
      .show   = debug_show,
      .store  = debug_store,

// 还是宏拼接
ATTRIBUTE_GROUPS(ksmbd_control_class)
  ksmbd_control_class_group
  .attrs = ksmbd_control_class_attrs
  __ATTRIBUTE_GROUPS(ksmbd_control_class)
    ksmbd_control_class_groups[] // 引用这个变量的是ksmbd_control_class
    &ksmbd_control_class_group,

static struct class ksmbd_control_class = {
        .name           = "ksmbd-control", ==> /sys/class/ksmbd-control/目录
        .class_groups   = ksmbd_control_class_groups,
};
```

通过读写`/sys/class/ksmbd-control/debug`文件控制，但我们一般不直接操作这个文件，而是用以下命令控制打印的开关:
```sh
ksmbd.control --help # 查看帮助
# COMPONENT的值有: `all', `smb', `auth', `vfs', `oplock', `ipc', `conn', or `rdma'
ksmbd.control --debug=vfs
ksmbd.control --debug= # 不加COMPONENT可以查看当前的状态
```

## client打印

smb client打印函数有`cifs_dbg()`、`cifs_server_dbg()`、`cifs_tcon_dbg()`、`cifs_info()`，要打开配置`CONFIG_CIFS_DEBUG`才有效，打开`CONFIG_CIFS_DEBUG2`和`CONFIG_CIFS_DEBUG_DUMP_KEYS`能打印更多信息，以`cifs_dbg()`为例代码如下:
```c
cifs_dbg
  cifs_dbg_func(once, ...)
    pr_debug_once // 还有 pr_err_once
      printk_once // 只打印一次
  cifs_dbg_func(ratelimited, ...)
    pr_debug_ratelimited // 还有 pr_err_ratelimited
      __dynamic_pr_debug // 打开了配置 CONFIG_DYNAMIC_DEBUG
```

动态打印相关的内容请查看[《内核调试方法》](https://chenxiaosong.com/courses/kernel/debug.html)。

# tcpdump抓包

请查看[《nfs调试方法》](https://chenxiaosong.com/courses/nfs/nfs-debug.html)。

