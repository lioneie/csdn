#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>      // for getpid()
#include <pthread.h>     // for pthread functions
#include <sys/syscall.h> // for syscall() and SYS_gettid
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

// 线程执行的函数
void *thread_function(void *arg) {
    int thread_num = *((int *)arg);

    pid_t tid = syscall(SYS_gettid);
    printf("thread %d: pid %d, tid %d, ppid %d\n", thread_num, getpid(), tid, getppid());
    read_dir();
    while (1)
        ;
    return NULL;
}

int main() {
    pthread_t threads[3];
    int thread_nums[3];

    pid_t tid = syscall(SYS_gettid);
    printf("main thread pid: %d, tid: %d, ppid: %d\n", getpid(), tid, getppid());
    read_dir();

    for (int i = 0; i < 3; i++) {
        thread_nums[i] = i + 1;
        // 创建线程
        if (pthread_create(&threads[i], NULL, thread_function, &thread_nums[i]) != 0) {
            perror("pthread_create");
            exit(EXIT_FAILURE);
        }
    }
    // 等待所有线程完成
    for (int i = 0; i < 3; i++) {
        pthread_join(threads[i], NULL);
    }

    printf("all threads have completed.\n");
    return 0;
}
