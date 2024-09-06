# 补丁

[`3e2910c7e23b NFS: Improve warning message when locks are lost.`](https://lore.kernel.org/all/164782079118.24302.10351255364802334775@noble.neil.brown.name/)

```
NFS: 改进锁丢失时的警告信息

NFSv4可能会在某些情况下丢失锁，例如，当网络分区时间超过租期时。如果发生这种情况，会生成以下警告信息:

  NFS: __nfs4_reclaim_open_state: Lock reclaim failed!

这个消息可能会误导人，因为它可能被理解为尝试了锁恢复。然而，默认情况下，除了服务器报告的情况外，不会尝试恢复锁。

此补丁修改了报告方式，使其在尝试从给定服务器恢复所有状态时最多生成一条消息。该消息报告服务器名称以及丢失的锁数量（如果数量非零）。它仅报告锁丢失的情况，并不暗示是否进行了恢复尝试。
```

# 复现

`test.c`文件如下:
```c
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/file.h>

int main(int argc, char *argv[]) {
    if (argc != 2) {
        printf("Usage: %s <file_path>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    const char *file_path = argv[1];
    int fd = open(file_path, O_RDWR);
    if (fd == -1) {
        printf("Error: open %s\n", file_path);
        exit(EXIT_FAILURE);
    }
    printf("open succ %s\n", file_path);
    printf("will flock\n");
    sleep(10);
    int res = flock(fd, LOCK_SH);
    if (res == -1) {
        printf("Error: flock %s\n", file_path);
        close(fd);
        exit(EXIT_FAILURE);
    }
    printf("lock succ %s\n", file_path);

    printf("File locked. Press Enter to unlock...");
    getchar();

    // Unlock and close the file
    flock(fd, LOCK_UN);
    close(fd);

    return 0;
}
```

编译运行:
```sh
bash nfs-svr-setup.sh
gcc -o test test.c
mount -t nfs localhost:/s_test /mnt
# mount -t nfs -o vers=4.0 localhost:/s_test /mnt
echo something > /mnt/file # 创建文件
echo 3 > /proc/sys/vm/drop_caches
tcpdump --interface=lo --buffer-size=20480 -w 4.2.cap &
# tcpdump --interface=lo --buffer-size=20480 -w 4.0.cap &
./test /mnt/file & # 后台运行
systemctl restart nfs-server
```

会打印`NFS: nfs4_reclaim_open_state: Lock reclaim failed!`。