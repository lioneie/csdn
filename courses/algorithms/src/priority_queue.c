// SPDX-License-Identifier: GPL-2.0
/*
 * 优先队列
 *
 * Copyright (C) 2024.10.11 ChenXiaoSong <chenxiaosong@chenxiaosong.com>
 */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <limits.h>

#define ARRAY_MAX_LENGTH	100

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
 * @i: 下标
 * Return: 左孩子的下标
*/
static int left(int i)
{
	return 2*i+1;
}

/**
 * right() - 右孩子
 * @i: 下标
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
	if (l < heap_size && array[l] > array[i])
		largest = l;
	if (r < heap_size && array[r] > array[largest])
		largest = r;
	if (i != largest) {
		swap(&array[i], &array[largest]);
		max_heapify(array, heap_size, largest);
	}
}

static int __attribute__((unused)) top(int *array)
{
	return array[0];
}

static void push(int *array, int *size, int x)
{
	int i;
	array[*size] = x;
	(*size)++;
	i = (*size) - 1;
	while (i > 0 && array[parent(i)] < array[i]) {
		swap(&array[parent(i)], &array[i]);
		i = parent(i);
	}
}

static void pop(int *array, int *size)
{
	array[0] = array[(*size)-1]; // 把最后一个数 放到第一个
	*size = (*size)-1;
	max_heapify(array, *size, 0);
}

static void print(int *array, int size)
{
	for (int i = 0; i < size; i++) {
		printf(" %d", array[i]);
	}
	printf("\n\r");
}

int main(int argc, char **argv)
{
	int array[ARRAY_MAX_LENGTH] = {4, 7, 8, 6};
	int size = 4;

	max_heapify(array, size, 0);
	print(array, size);

	push(array, &size, 9);
	print(array, size);

	push(array, &size, 3);
	print(array, size);

	pop(array, &size);
	print(array, size);

	pop(array, &size);
	print(array, size);

	return 0;
}
