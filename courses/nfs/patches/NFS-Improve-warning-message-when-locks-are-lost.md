[`3e2910c7e23b NFS: Improve warning message when locks are lost.`](https://lore.kernel.org/all/164782079118.24302.10351255364802334775@noble.neil.brown.name/)

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

    int res = flock(fd, LOCK_SH);
    if (res == -1) {
        printf("Error: flock %s\n", file_path);
        close(fd);
        exit(EXIT_FAILURE);
    }
    printf("lock succ %s\n", file_path);

    printf("begin sleep\n");
    sleep(60);
    printf("end sleep\n");

    // Unlock and close the file
    flock(fd, LOCK_UN);
    close(fd);

    return 0;
}
```

编译运行:
```sh
gcc -o test test.c
bash nfs-svr-setup.sh
mount -t nfs localhost:/s_test /mnt
echo something > /mnt/file # 创建文件
./test /mnt/file & 后台运行
systemctl restart nfs-server
```

会打印`NFS: nfs4_reclaim_open_state: Lock reclaim failed!`。