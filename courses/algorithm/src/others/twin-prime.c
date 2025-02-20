// SPDX-License-Identifier: GPL-2.0
/*
 * 计算孪生素数对的个数
 *
 * Copyright (C) 2025.01.19 ChenXiaoSong <chenxiaosong@chenxiaosong.com>
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int is_prime(int num, int *results)
{
	if (results[num])
		return results[num];

	// num 不必被 2 ~ num-1 之间的每一个整数去除，只需被 2 ~ 根号num 之间的每一个整数去除就可以了
	for (int i = 2; i * i <= num; i++) {
		if (num % i == 0) {
			return results[num];
		}
	}
	results[num] = 1;
	return results[num];
}

int main(int argc, char **argv)
{
	int n = 100;
	int *results = malloc(sizeof(int) * (n + 1));
	memset(results, 0, sizeof(int) * (n + 1));

	for (int i = 2; i < n; i++) {
		if (is_prime(i, results) && i + 2 < n && is_prime(i + 2, results))
			printf("(%d,%d)\n", i, i + 2);
	}
	free(results);
	return 0;
}
