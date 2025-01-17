// SPDX-License-Identifier: GPL-2.0
/*
 * c语言库函数快速排序qsort
 *
 * Copyright (C) 2025.01.17 ChenXiaoSong <chenxiaosong@chenxiaosong.com>
 */
#include <stdio.h>
#include <stdlib.h>

int ascend_cmp(const void *_a, const void *_b)
{
    int a = *(int *)_a, b = *(int *)_b;
    return a - b;
}

int descend_cmp(const void *_a, const void *_b)
{
    int a = *(int *)_a, b = *(int *)_b;
    return b - a;
}

int main(int argc, char **argv)
{
	int array[] = {5, 8, 6, 7, 3, 4, 2, 1};
	int len = sizeof(array)/sizeof(array[0]);

	printf("ascend_cmp(a, b), return a - b\n");
	qsort(array, len, sizeof(array[0]), ascend_cmp);
	for (int i = 0; i < len; i++) {
		printf(" %d", array[i]);
	}
	printf("\n\r");

	qsort(array, len, sizeof(array[0]), descend_cmp);
	printf("descend_cmp(a, b), return b - a\n");
	for (int i = 0; i < len; i++) {
		printf(" %d", array[i]);
	}
	printf("\n\r");
	return 0;
}
