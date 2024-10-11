// SPDX-License-Identifier: GPL-2.0
/*
 * 归并排序
 *
 * Copyright (C) 2024.10.11 ChenXiaoSong <chenxiaosong@chenxiaosong.com>
 */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <limits.h>

/**
 * merge() - 合并数组
 * @array: 数组，分成两部分[start, mid]和(mid, end]，这两部分都已排好序
 * @start: 开始的下标
 * @mid: 中间的下标
 * @end: 结束的下标
 * Return: None
 */
static void merge(int *array, int start, int mid, int end)
{
	// 左边的数组包含下标mid
	int l_len = mid - start + 1;
	int r_len = end - mid;
	int *l_array = (int *)malloc(sizeof(int) * (l_len+1)); // 最后一个放哨兵
	int *r_array = (int *)malloc(sizeof(int) * (r_len+1));

	// 哨兵
	l_array[l_len] = INT_MAX; // 正无穷
	r_array[r_len] = INT_MAX;
	for (int i = 0; i < l_len; i++)
		l_array[i] = array[start+i];

	for (int i = 0; i < r_len; i++)
		r_array[i] = array[mid+i+1];

	int i = 0, j = 0;
	for (int k = start; k <= end; k++) {
		if (l_array[i] <= r_array[j]) {
			array[k] = l_array[i];
			i++;
		} else {
			array[k] = r_array[j];
			j++;
		}
	}
	
	free(l_array);
	free(r_array);
}

/**
 * mergesort() - 归并排序
 * @array: 数组
 * @start: 开始的下标
 * @end: 结束的下标
 * Return: None
 */
static void mergesort(int *array, int start, int end)
{
	int mid = 0;
	if (start < end) {
		mid = (int)((start + end) / 2);
		mergesort(array, start, mid);// 包含mid下标
		mergesort(array, mid+1, end);
		merge(array, start, mid, end);
	}
}

int main(int argc, char **argv)
{
	int array[] = {5, 8, 6, 7, 3, 4, 2, 1};
	int len = sizeof(array)/sizeof(array[0]);
	mergesort(array, 0, len - 1);
	for (int i = 0; i < len; i++) {
		printf(" %d", array[i]);
	}
	printf("\n\r");
	return 0;
}
