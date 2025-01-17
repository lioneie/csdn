// SPDX-License-Identifier: GPL-2.0
/*
 * 带备忘的自顶向下法钢条切割
 *
 * Copyright (C) 2024.09.25 ChenXiaoSong <chenxiaosong@chenxiaosong.com>
 */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <limits.h>

/**
 * memoized_cut_rod_aux() - 递归切割钢条，aux指auxiliary（辅助函数）
 * @price_array: 价格数组
 * @len: 长度
 * @profits: 备忘数组，收益
 * Return: 最高能卖的钱
 */
static int memoized_cut_rod_aux(int *price_array, int len, int *profits)
{
	int ret;

	if (profits[len] >= 0)
		return profits[len]; // 已经计算过

	if (len == 0) {
		ret = 0; // 结束递归
	} else {
		ret = INT_MIN;
		// 遍历各种组合取最大值: 1 + len-1, 2 + len-2, 3 + len-3
		for (int i = 1; i <= len; i++) {
			int tmp = price_array[i] + memoized_cut_rod_aux(price_array, len-i, profits);
			if (tmp > ret)
				ret = tmp;
		}
	}
	profits[len] = ret; // 计算过的存起来
	return ret;
}

/**
 * memoized_cut_rod() - 带备忘的切割钢条
 * @price_array: 价格数组
 * @len: 长度
 * Return: 最高能卖的钱
 */
static int memoized_cut_rod(int *price_array, int len)
{
	int ret = 0;
	int *profits = (int *)malloc(sizeof(int) * (len+1)); // 用于备忘，把计算过的存起来
	for (int i = 0; i <= len; i++)
		profits[i] = INT_MIN; // 负无穷
	ret = memoized_cut_rod_aux(price_array, len, profits);
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
		int res = memoized_cut_rod(price_array, i);
		printf("长度为%d的钢条切割后能卖的最多钱: %d\n", i, res);
	}
	return 0;
}

