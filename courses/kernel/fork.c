#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <dirent.h>

static void read_dir(void) {
    DIR *dir;
    struct dirent *entry;

    dir = opendir("/mnt/");
    if (dir == NULL) {
        perror("opendir");
        exit(EXIT_FAILURE);
    }
    // 只读取目录下的第一个文件
    entry = readdir(dir);
    printf("%s\n", entry->d_name);
    // 关闭目录
    closedir(dir);
}

int main() {
    int num_processes = 3; // 你可以修改这个值来创建不同数量的子进程
    pid_t pid;

    for (int i = 0; i < num_processes; i++) {
        pid = fork();
        if (pid < 0) {
            // fork失败
            perror("fork failed");
            exit(1);
        } else if (pid == 0) {
            // 子进程
            printf("child process %d, pid %d, ppid %d\n", i + 1, getpid(), getppid());
            while (1)
                ;
            exit(0); // 子进程结束
        } else {
            // 父进程
            printf("parent process pid %d, created child %d with pid %d\n", getpid(), i + 1, pid);
        }
    }

    read_dir();

    // 等待所有子进程完成
    for (int i = 0; i < num_processes; i++) {
        wait(NULL);
    }

    return 0;
}
