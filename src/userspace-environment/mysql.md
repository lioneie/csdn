# windows环境

[下载地址](https://dev.mysql.com/downloads/mysql/)（[老版本下载](https://downloads.mysql.com/archives/community/)）, 选择“Windows (x86, 64-bit), ZIP Archive”。可能还要安装[Latest Microsoft Visual C++ Redistributable Version](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-160#latest-microsoft-visual-c-redistributable-version)。

```sh
cd mysql-8.4.2-winx64/ # 不在这个目录下创建my.ini似乎也可以
cd bin/
# 如果忘记密码，只需要删除data目录，重新初始化数据
./mysqld --initialize --console # 初始化数据，会生成默认密码
./mysqld install # 会提示已经安装
net start mysql # 结束mysqld进程后，只需要执行此命令，不需要前面的命令
# net stop mysql # 停止服务
```

更改密码：
```sh
.\mysql -u root -p # 注意如果是在windows下，只能在cmd中执行，不能在shell中(如git shell)执行
mysql> ALTER USER 'root'@'localhost' IDENTIFIED BY '123456';
mysql> FLUSH PRIVILEGES; # 重新加载了权限表，以确保当前任何更改用户或权限的操作都会立即生效
```

以下是[YiShaAdmin](https://github.com/liukuo362573/YiShaAdmin/tree/YiShaAdmin-Net6)的一些操作。

常见操作：

```shell
mysql> show databases;
mysql> create DATABASE yishaadmin;
mysql> use yishaadmin;
mysql> SELECT DATABASE(); # 查看当前选择的数据库
mysql> source D:/chenxiaosong/code/YiShaAdmin/Document/DatabaseScript/mysql.sql;
mysql> source D:/chenxiaosong/code/YiShaAdmin/Document/DatabaseScript/mysql_data.sql;
mysql> show tables;
```
