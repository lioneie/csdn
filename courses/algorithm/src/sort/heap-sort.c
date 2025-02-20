// SPDX-License-Identifier: GPL-2.0
/*
 * 堆排序
 *
 * Copyright (C) 2024.10.11 ChenXiaoSong <chenxiaosong@chenxiaosong.com>
 */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <limits.h>

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
 * parent() - 父结点
 * @i: 下标
 * Return: 父结点的下标
 */
static int parent(int i)
{
	return (int)((i-1)/2);
}

/**
 * left() - 左孩子
 * @i : 下标
 * Return: 左孩子的下标
 */
static int left(int i)
{
	return 2*i+1;
}

/**
 * right() - 右孩子
 * @i : 下标
 * Return: 右孩子的下标
 */
static int right(int i)
{
	return 2*i+2;
}

/**
 * max_heapify() - 维护最大堆
 * @array: 数组
 * @heap_size: 堆的大小
 * @i: 根节点的下标
 * Return: None
 */
static void max_heapify(int *array, int heap_size, int i)
{
	int l = left(i);
	int r = right(i);
	int largest = i;
	if (l < heap_size && array[l] > array[largest])
		largest = l;
	if (r < heap_size && array[r] > array[largest])
		largest = r;
	if (i != largest) {
		swap(&array[i], &array[largest]);
		max_heapify(array, heap_size, largest);
	}
}

/**
 * build_max_heap() - 建最大堆
 * @array: 数组
 * @size: 数组大小
 * Return: None
 */
static void build_max_heap(int *array, int size)
{
	int heap_size = size;
	for (int i = parent(size); i >= 0; i--)
		max_heapify(array, heap_size, i);
}

/**
 * heapsort() - 堆排序
 * @array: 数组
 * @size: 数组大小
 * Return: None
 */
static void heapsort(int *array, int size)
{
	int heap_size = size;
	build_max_heap(array, size);
	for (int i = size-1; i >= 1; i--) {
		swap(&array[0], &array[i]);
		heap_size--;
		max_heapify(array, heap_size, 0);
	}
}

int main(int argc, char **argv)
{
	int array[] = {5, 8, 6, 7, 3, 4, 2, 1};
	int len = sizeof(array)/sizeof(array[0]);
	heapsort(array, len);
	for (int i = 0; i < len; i++) {
		printf(" %d", array[i]);
	}
	printf("\n\r");
	return 0;
}
