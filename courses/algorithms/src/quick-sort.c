// SPDX-License-Identifier: GPL-2.0
/*
 * 快速排序
 *
 * Copyright (C) 2024.09.25 ChenXiaoSong <chenxiaosong@chenxiaosong.com>
 */
#include <stdio.h>
#include <stdlib.h>

/**
 * swap() - 交换两个数
 * @a: 第一个数指针
 * @b: 第二个数指针
 * Return: None
 */
static void swap(int *a, int *b)
{
	int tmp = *a;
	*a = *b;
	*b = tmp;
}

/**
 * rand_range() - 获取随机值
 * @min: 最小值
 * @max: 最大值
 * Return: 随机值
 */
static int rand_range(int min, int max)
{
	return rand() % (max - min + 1) + min;
}

/**
 * partition - 把数组划分为两个部分
 * @array: 数组
 * @begin: 开始的下标
 * @end: 结束的下标
 * Return: 中间的下标
 */
static int partition(int *array, int begin, int end)
{
	int rand_idx = rand_range(begin, end);
	swap(&array[rand_idx], &array[end]); // 随机选一个放在最后面
	int mid_val = array[end]; // 根据这个值把数组分成两半
	int left = begin;
	for (int right = begin; right < end; right++) {
		// [begin,left]: <= mid_val
		// (left,right): > mid_val
		if (array[right] <= mid_val) { // 这里也可以是 <
			swap(&array[left], &array[right]);
			left++;
		}
	}
	swap(&array[end], &array[left]); // 把mid_val放在中间
	return left; // mid_val对应的下标
}

/**
 * quiksort() - 快速排序
 * @array: 数组
 * @begin: 开始的下标
 * @end: 结束的下标
 * Return: None
 */
static void quiksort(int *array, int begin, int end)
{
	int mid;
	if (begin < end) {
		mid = partition(array, begin, end);
		quiksort(array, begin, mid);
		quiksort(array, mid+1, end);
	}
}

int main(int argc, char **argv)
{
	int array[] = {5, 8, 6, 7, 3, 4, 2, 1};
	int len = sizeof(array)/sizeof(array[0]);
	quiksort(array, 0, len - 1);
	for (int i = 0; i < len; i++) {
		printf(" %d", array[i]);
	}
	printf("\n\r");
	return 0;
}
