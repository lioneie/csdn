#define _GNU_SOURCE // 没有这一行找不到O_DIRECT
#include <stdio.h>
#include <fcntl.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

int main() {
	// 打开文件，返回文件描述符
	int fd = open("/mnt/file", O_RDWR);
	// 检查文件是否成功打开
	if (fd == -1) {
		printf("无法打开文件\n");
		return 1;
	}
	printf("打开文件成功\n");

	// 重新设置文件位置
	lseek(fd, 0, SEEK_SET);

	// 写入内容到文件
	const char *text = "这是一个示例文本文件。\nHello, World!\n";
	ssize_t bytes_written = write(fd, text, strlen(text));
	// 检查写入是否成功
	if (bytes_written == -1) {
		printf("写入文件时发生错误\n");
		close(fd);
		return 1;
	}
	printf("写入文件成功，%zd bytes\n", bytes_written);

	char buffer[100];     // 用于存储读取的内容
	// 打开文件，返回文件描述符
	int fd2 = open("/mnt/file", O_RDWR | O_DIRECT);
	// 检查文件是否成功打开
	if (fd2 == -1) {
		printf("无法打开文件\n");
		return 1;
	}
	ssize_t bytes_read;
	// direct读之前会先回写
	while ((bytes_read = read(fd2, buffer, sizeof(buffer))) > 0) {
		// 在此处你可以处理已读取的数据，例如打印到屏幕
		printf("读文件成功, %zd bytes\n", bytes_read);
	}

	// 关闭文件
	close(fd);
	close(fd2);

	return 0;
}

