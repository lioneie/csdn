# 环境

下载[dkruchinin/cthon-nfs-tests](https://github.com/dkruchinin/cthon-nfs-tests)代码，编辑文件`tests.init`，只需以下几个变量，其他都可以删除:
```sh
CC=cc
CFLAGS=`echo -DLINUX`
LOCKTESTS=tlock
PATH=${PATH}:.
```

然后执行编译命令:
```sh
make -j16
```

更多的内容请查看[Connectathon NFS tests README中文翻译](https://chenxiaosong.com/src/translation/nfs/cthon-nfs-tests-readme.html)。

# 测试

挂载:
```sh
mount -t nfs -o vers=4.2 ${server_ip}:/s_test /mnt
```

basic, special, lock测试都测试成功:
```sh
./runtests -b -f /mnt/test
./runtests -s -f /mnt/test
./runtests -l -f /mnt/test
```

general测试失败:
```sh
./runtests -g -f /mnt/test
```

把`general/runtests.wrk`文件的`./stat nroff.time`一行用`#`注释掉，其他用例测试通过。

# general Nroff测试失败原因分析

接下来我们看看general Nroff测试为什么失败。

general测试包含几种: Small Compile， Tbl， Nroff，Large Compile，Four simultaneous large compiles，Makefile。

报错信息如下:
```sh
...
Small Compile
        0.0 (0.0) real  0.3 (0.0) user  0.0 (0.0) sys

Tbl
        0.0 (0.0) real  0.0 (0.0) user  0.0 (0.0) sys

Nroff
./stat: no data in nroff.time
general tests failed
```

查看`nroff.time`的内容:
```sh
warning: file 'nroff.in', around line 52:                                      
  table wider than line width                                                  
0.02user 0.12system 0:00.14elapsed 104%CPU (0avgtext+0avgdata 5860maxresident)k
0inputs+24outputs (0major+1249minor)pagefaults 0swaps
...                          
warning: file 'nroff.in', around line 52:                                      
  table wider than line width                                                  
0.02user 0.12system 0:00.14elapsed 104%CPU (0avgtext+0avgdata 5860maxresident)k
0inputs+24outputs (0major+1253minor)pagefaults 0swaps                          
```

再对比Small Compile测试的输出文件`smcomp.time`:
```sh
0.03user 0.30system 0:00.38elapsed 88%CPU (0avgtext+0avgdata 20608maxresident)k
0inputs+96outputs (0major+5662minor)pagefaults 0swaps
...
0.02user 0.32system 0:00.38elapsed 88%CPU (0avgtext+0avgdata 20352maxresident)k
0inputs+96outputs (0major+5660minor)pagefaults 0swaps
```

对比发现`nroff.time`文件多了一些警告，而其他内容都差不多:
```sh
warning: file 'nroff.in', around line 52:                                      
  table wider than line width    
```

看到这里，我们大概知道原因了，猜测是一些额外的输出没有过滤掉，我们做个实验，`general/runtests.wrk`文件修改以下内容，把77，78行注释掉:
```sh
74 set -e
75 # Filter excessive noise from GNU tbl.  Should be harmless for other
76 # versions of tbl.
77 # egrep -v '^tbl:.*$' <tbl.time >tbl.new
78 # mv -f tbl.new tbl.time
79 ./stat tbl.time
80 set +e
```

我们发现Tbl测试也失败了，查看`/mnt/test/tbl.time`文件，多了以下内容:
```sh
tbl:nroff.in:47: excess data entry '_' discarded
tbl:nroff.in:51: excess data entry '_' discarded
```

# 修改方案

因此，要想让Nroff测试通过，只需要把`nroff.time`文件的警告过滤掉就可以:
```sh
warning: file 'nroff.in', around line 52:                                      
  table wider than line width        
```

只需修改`general/runtests.wrk`文件:
```sh
diff --git a/general/runtests.wrk b/general/runtests.wrk
index 5efc091..04dae8e 100644
--- a/general/runtests.wrk
+++ b/general/runtests.wrk
@@ -89,6 +89,8 @@ $TIME nroff < nroff.tbl > nroff.out 2>> nroff.time || cat nroff.time
 $TIME nroff < nroff.tbl > nroff.out 2>> nroff.time || cat nroff.time
 rm nroff.out nroff.tbl
 set -e
+egrep -v '^warning:.*$|^  table wider.*$' <nroff.time >nroff.new
+mv -f nroff.new nroff.time
 ./stat nroff.time
 set +e
```

现在，执行`./runtests -g -f /mnt/test`命令你就能看到很漂亮的输出:
```sh
GENERAL TESTS: directory /mnt/test
cd /mnt/test; rm -f Makefile runtests runtests.wrk *.sh *.c mkdummy rmdummy nroff.in makefile.tst
cp Makefile runtests runtests.wrk *.sh *.c mkdummy rmdummy nroff.in makefile.tst /mnt/test

Small Compile
        0.0 (0.0) real  0.3 (0.0) user  0.0 (0.0) sys

Tbl
        0.0 (0.0) real  0.0 (0.0) user  0.0 (0.0) sys

Nroff
        0.0 (0.0) real  0.1 (0.0) user  0.0 (0.0) sys

Large Compile
        0.0 (0.0) real  0.3 (0.0) user  0.0 (0.0) sys

Four simultaneous large compiles
        0.1 (0.0) real  1.2 (0.0) user  0.0 (0.0) sys

Makefile
        0.0 (0.0) real  0.3 (0.0) user  0.0 (0.0) sys

General tests complete

All tests completed
```

