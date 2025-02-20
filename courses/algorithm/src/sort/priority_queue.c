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

// maximum()
static int top(int *array)
{
	return array[0];
}

// heap_increase_key(), 将数组中下标为i的元素的值增加到k
static void increase_to_k(int *array, int i, int k)
{
	int p = parent(i);
	array[i] = k;
	while (i > 0 && array[p] < array[i]) {
		swap(&array[p], &array[i]); // 把更大的上移
		i = p;
		p = parent(i);
	}
}

// insert()
static void push(int *array, int *size, int x)
{
	int i = *size;
	(*size)++;
	array[i] = INT_MIN; // 负无穷;
	increase_to_k(array, i, x);
}

// extract_max()
static int pop(int *array, int *size)
{
	int ret = top(array);
	array[0] = array[(*size)-1]; // 把最后一个数 放到第一个
	*size = (*size)-1;
	max_heapify(array, *size, 0);
	return ret;
}

static void print(char *str, int *array, int size)
{
	printf("%10s", str);
	for (int i = 0; i < size; i++) {
		printf(" %d", array[i]);
	}
	printf("\n");
}

int main(int argc, char **argv)
{
	int array[ARRAY_MAX_LENGTH] = {4, 7, 6, 8};
	int size = 4;

	build_max_heap(array, size);
	print("init: ", array, size);

	push(array, &size, 9);
	print("push 9: ", array, size);

	push(array, &size, 3);
	print("push 3: ", array, size);

	pop(array, &size);
	print("pop: ", array, size);

	pop(array, &size);
	print("pop: ", array, size);

	return 0;
}
