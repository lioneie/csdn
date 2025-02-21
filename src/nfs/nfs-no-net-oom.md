# 构造

nfs环境搭建请参考[《nfs环境》](https://chenxiaosong.com/course/nfs/environment.html)。

构造nfs断网不断写文件导致oom的场景:
```sh
systemctl stop nfs-server # 客户端可用，服务端不可用

while true
do
    # 循环写
    echo something > /mnt/file &
done
```

# 内存消耗

`free -h`命令统计内存，只看到`used`不断增加。

`qemu`虚拟机中导出`vmcore`的方法请参考[《内核调试方法》](https://chenxiaosong.com/course/kernel/debug.html)，虚拟机导出`vmcore`对比，用`crash`解析，可以看出有大幅增加的只有`USED`:
```sh
# nfs刚挂载时
crash> kmem -i
                 PAGES        TOTAL      PERCENTAGE
    TOTAL MEM   998421       3.8 GB         ----
         FREE   902099       3.4 GB   90% of TOTAL MEM
         USED    96322     376.3 MB    9% of TOTAL MEM
       SHARED    10513      41.1 MB    1% of TOTAL MEM
      BUFFERS     1121       4.4 MB    0% of TOTAL MEM
       CACHED    34971     136.6 MB    3% of TOTAL MEM
         SLAB    19758      77.2 MB    1% of TOTAL MEM

   TOTAL HUGE        0            0         ----
    HUGE FREE        0            0    0% of TOTAL HUGE

   TOTAL SWAP        0            0         ----
    SWAP USED        0            0    0% of TOTAL SWAP
    SWAP FREE        0            0    0% of TOTAL SWAP

 COMMIT LIMIT   499210       1.9 GB         ----
    COMMITTED   128341     501.3 MB   25% of TOTAL LIMIT

# 快oom时
crash> kmem -i
                 PAGES        TOTAL      PERCENTAGE
    TOTAL MEM   998421       3.8 GB         ----
         FREE    21024      82.1 MB    2% of TOTAL MEM
         USED   977397       3.7 GB   97% of TOTAL MEM
       SHARED     3197      12.5 MB    0% of TOTAL MEM
      BUFFERS       78       312 KB    0% of TOTAL MEM
       CACHED     3496      13.7 MB    0% of TOTAL MEM
         SLAB    66520     259.8 MB    6% of TOTAL MEM

   TOTAL HUGE        0            0         ----
    HUGE FREE        0            0    0% of TOTAL HUGE

   TOTAL SWAP        0            0         ----
    SWAP USED        0            0    0% of TOTAL SWAP
    SWAP FREE        0            0    0% of TOTAL SWAP

 COMMIT LIMIT   499210       1.9 GB         ----
    COMMITTED  1391284       5.3 GB  278% of TOTAL LIMIT
```
