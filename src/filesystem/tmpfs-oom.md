# 构造

```sh
mount -t tmpfs -o size=64G test-oom /mnt

str='请替换为很长的字符串'
i=0
while true
do
    ((i++))
    # 循环写
    echo ${str} > /mnt/file${i}
    echo ${i}
done
```

# 内存消耗

`free -h`对比:
```sh
# tmpfs刚挂载时
               total        used        free      shared  buff/cache   available
Mem:           3.8Gi       417Mi       3.4Gi       948Ki       168Mi       3.4Gi

# oom时
               total        used        free      shared  buff/cache   available
Mem:           3.8Gi       3.6Gi        71Mi       2.9Gi       3.2Gi       169Mi
```

`qemu`虚拟机中导出`vmcore`的方法请参考[《内核调试方法》](https://chenxiaosong.com/course/kernel/debug.html)，虚拟机导出`vmcore`对比，用`crash`解析。

总内存`3.8G`，通过`crash`的命令`kmem -i`对比看出，发生oom时，大幅增加的内存有`USED`（增加约`3.33G`）和`CACHED`（增加约`2.76G`），小幅增加的有`SLAB`（增加约`660M`）。

mainline刚挂载tmpfs时:
```sh
free -h
               total        used        free      shared  buff/cache   available
Mem:           3.8Gi       691Mi       2.8Gi       956Ki       566Mi       3.1Gi
Swap:             0B          0B          0B

crash> kmem -i
                 PAGES        TOTAL      PERCENTAGE
    TOTAL MEM   998421       3.8 GB         ----
         FREE   730449       2.8 GB   73% of TOTAL MEM
         USED   267972         1 GB   26% of TOTAL MEM
       SHARED    69276     270.6 MB    6% of TOTAL MEM
      BUFFERS      783       3.1 MB    0% of TOTAL MEM
       CACHED   139008       543 MB   13% of TOTAL MEM
         SLAB    19389      75.7 MB    1% of TOTAL MEM

   TOTAL HUGE        0            0         ----
    HUGE FREE        0            0    0% of TOTAL HUGE

   TOTAL SWAP        0            0         ----
    SWAP USED        0            0    0% of TOTAL SWAP
    SWAP FREE        0            0    0% of TOTAL SWAP

 COMMIT LIMIT   499210       1.9 GB         ----
    COMMITTED   235188     918.7 MB   47% of TOTAL LIMIT
```

mainline快oom时:
```sh
free -h
               total        used        free      shared  buff/cache   available
Mem:           3.8Gi       3.4Gi       109Mi       2.3Gi       2.9Gi       440Mi
Swap:             0B          0B          0B

crash> kmem -i
                 PAGES        TOTAL      PERCENTAGE
    TOTAL MEM   998421       3.8 GB         ----
         FREE    27664     108.1 MB    2% of TOTAL MEM
         USED   970757       3.7 GB   97% of TOTAL MEM
       SHARED    52113     203.6 MB    5% of TOTAL MEM
      BUFFERS      285       1.1 MB    0% of TOTAL MEM
       CACHED   702798       2.7 GB   70% of TOTAL MEM
         SLAB   156596     611.7 MB   15% of TOTAL MEM

   TOTAL HUGE        0            0         ----
    HUGE FREE        0            0    0% of TOTAL HUGE

   TOTAL SWAP        0            0         ----
    SWAP USED        0            0    0% of TOTAL SWAP
    SWAP FREE        0            0    0% of TOTAL SWAP

 COMMIT LIMIT   499210       1.9 GB         ----
    COMMITTED   775490         3 GB  155% of TOTAL LIMIT
```

4.19刚挂载tmpfs时:
```sh
free -h
              total        used        free      shared  buff/cache   available
Mem:          3.8Gi       724Mi       2.2Gi       8.0Mi       933Mi       2.9Gi
Swap:            0B          0B          0B

crash> kmem -i
                 PAGES        TOTAL      PERCENTAGE
    TOTAL MEM  1006287       3.8 GB         ----
         FREE   582172       2.2 GB   57% of TOTAL MEM
         USED   424115       1.6 GB   42% of TOTAL MEM
       SHARED    27868     108.9 MB    2% of TOTAL MEM
      BUFFERS      407       1.6 MB    0% of TOTAL MEM
       CACHED   226288     883.9 MB   22% of TOTAL MEM
         SLAB    23597      92.2 MB    2% of TOTAL MEM

   TOTAL HUGE        0            0         ----
    HUGE FREE        0            0    0% of TOTAL HUGE

   TOTAL SWAP        0            0         ----
    SWAP USED        0            0    0% of TOTAL SWAP
    SWAP FREE        0            0    0% of TOTAL SWAP

 COMMIT LIMIT   503143       1.9 GB         ----
    COMMITTED   251344     981.8 MB   49% of TOTAL LIMIT
```

4.19快oom时:
```sh
free -h
              total        used        free      shared  buff/cache   available
Mem:          3.8Gi       1.1Gi       120Mi       1.9Gi       2.6Gi       561Mi
Swap:            0B          0B          0B

crash> kmem -i
                 PAGES        TOTAL      PERCENTAGE
    TOTAL MEM  1006287       3.8 GB         ----
         FREE    30608     119.6 MB    3% of TOTAL MEM
         USED   975679       3.7 GB   96% of TOTAL MEM
       SHARED    25198      98.4 MB    2% of TOTAL MEM
      BUFFERS      147       588 KB    0% of TOTAL MEM
       CACHED   649817       2.5 GB   64% of TOTAL MEM
         SLAB   150220     586.8 MB   14% of TOTAL MEM

   TOTAL HUGE        0            0         ----
    HUGE FREE        0            0    0% of TOTAL HUGE

   TOTAL SWAP        0            0         ----
    SWAP USED        0            0    0% of TOTAL SWAP
    SWAP FREE        0            0    0% of TOTAL SWAP

 COMMIT LIMIT   503143       1.9 GB         ----
    COMMITTED   755068       2.9 GB  150% of TOTAL LIMIT
```
