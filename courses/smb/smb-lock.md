`lock.c`文件如下：
```c
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>

int main() {
    int fd = open("/mnt/file", O_RDWR);
    if (fd == -1) {
        perror("Failed to open file");
        return 1;
    }

    struct flock fl;
    fl.l_type = F_WRLCK;  // 写锁
    fl.l_whence = SEEK_SET;
    fl.l_start = 0;
    fl.l_len = 0;  // 锁定整个文件

    if (fcntl(fd, F_SETLK, &fl) == -1) {
        perror("Failed to lock file");
        close(fd);
        return 1;
    }

    printf("File locked. Press Enter to unlock...");
    getchar();

    fl.l_type = F_UNLCK;  // 解锁
    if (fcntl(fd, F_SETLK, &fl) == -1) {
        perror("Failed to unlock file");
    }

    close(fd);
    return 0;
}
```

`lock.c`文件还可以用`flock()`函数:
```c
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/file.h>

int main(int argc, char *argv[]) {
    const char file_path = "/mnt/file";
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

    printf("File locked. Press Enter to unlock...");
    getchar();

    // Unlock and close the file
    flock(fd, LOCK_UN);
    close(fd);

    return 0;
}
```

```sh
gcc -o lock lock.c
./lock # client 1
./lock # client 2，这时会调用 SMB2_lock，　server会调用 smb2_lock
```