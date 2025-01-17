// SPDX-License-Identifier: GPL-2.0
/*
 * 自底向上法钢条切割
 *
 * Copyright (C) 2024.09.25 ChenXiaoSong <chenxiaosong@chenxiaosong.com>
 */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <limits.h>

/**
 * bottom_up_cut_rod() - 自底向上切割钢条
 * @price_array: 价格数组
 * @len: 长度
 * Return: 最高能卖的钱
 */
static int bottom_up_cut_rod(int *price_array, int len)
{
	int ret = 0;
	int *profits = (int *)malloc(sizeof(int) * (len+1));
	profits[0] = 0;
	for (int i = 1; i <= len; i++) {
		int max = INT_MIN;
		for (int j = 1; j <= i; j++) {
			// 遍历各种组合取最大值: 1 + i-1, 2 + i-2, 3 + i-3
			int tmp = price_array[j] + profits[i-j];
			if (tmp > max)
				max = tmp;
		}
		profits[i] = max; // 是的，收益就这样算好了
	}
	ret = profits[len];
	free(profits);
	return ret;
}

/**
 * main() - 程序入口
 * @argc: 变量个数
 * @argv: 变量数组
 * Return: 程序执行结果
 */
int main(int argc, char **argv)
{
	// 长度为1价格1，长度为2价格5。。。
	int price_array[] = {0, 1, 5, 8, 9, 10, 17, 17, 20, 24, 30};
	int size = sizeof(price_array)/sizeof(price_array[0]);
	for (int i = 1; i < size; i++)
	{
		int res = bottom_up_cut_rod(price_array, i);
		printf("长度为%d的钢条切割后能卖的最多钱: %d\n", i, res);
	}
	return 0;
}

