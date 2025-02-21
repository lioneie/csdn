// SPDX-License-Identifier: GPL-2.0
/*
 * uthash的使用
 *
 * Copyright (C) 2025.01.17 ChenXiaoSong <chenxiaosong@chenxiaosong.com>
 */
#include <stdio.h>
// 如果访问不了github，uthash.h头文件也可以在这里下载: https://gitee.com/chenxiaosonggitee/tmp/blob/master/algorithm/uthash.h
#include "../../../../../tmp/algorithm/uthash.h"

struct hash_table {
	int key;
	char name[10]; // value
	UT_hash_handle hh; /* makes this structure hashable */
};

// 必须要初始化为NULL，考虑到leetcode c语言实现执行多个用例时全局变量和静态变量只会初始化一次，
// 所以我们就不在这里初始化值，而是放到main()中，
// 防止以后从这里copy代码到leetcode中时用例不通过
static struct hash_table *head_table;

// 临时变量，不保存值
static struct hash_table *tmp_table;

static void uthash_add(struct hash_table *add)
{
	HASH_ADD_INT(head_table, key, add); // 这里的key不是变量，而是结构体成员名
}

static struct hash_table *uthash_find(int key)
{
	struct hash_table *out;

	HASH_FIND_INT(head_table, &key, out); // 这里的key是变量
	return out;
}

static void uthash_delete(struct hash_table *del)
{
	HASH_DEL(head_table, del);
}

#define uthash_iter(el) \
	HASH_ITER(hh, head_table, el, tmp_table)

static void test_add(void)
{
	printf("\ntesting add\n");

	char *name_array[] = {
		"you",
		"me",
		"others",
	};

	for (int i = 0; i < 3; i++) {
		int key = i + 5;
		struct hash_table *user = malloc(sizeof(struct hash_table));
		user->key = key;
		strcpy(user->name, name_array[i]);
		uthash_add(user);
		printf("\tadd %d -> %s\n", user->key, user->name);
	}
}

static void test_find(void)
{
	printf("\ntesting find\n");

	for (int i = 0; i < 4; i++) {
		int key = i + 5;
		struct hash_table *user = uthash_find(key);
		if (user) {
			printf("\t%d -> %s\n", key, user->name);
		} else {
			printf("\t%d -> NULL\n", key);
		}
	}
}

static void test_delete(void)
{
	printf("\ntesting delete\n");

	int key_array[] = {6};

	for (int i = 0; i < sizeof(key_array) / sizeof(key_array[0]); i++) {
		int key = key_array[i];
		struct hash_table *user = uthash_find(key);
		if (user) {
			printf("\tdelete %d -> %s\n", user->key, user->name);
			uthash_delete(user);
			free(user);
		}
	}
}

static void test_free_all(void)
{
	printf("\ntesting free all\n");
	struct hash_table *user;
	uthash_iter(user) {
		printf("\tfree %d -> %s\n", user->key, user->name);
		uthash_delete(user); // 如果不从链表中删除，再次遍历时获取到的是已经free的指针
		free(user);
	}
}

int main(int argc, char **argv)
{
	head_table = NULL;
	test_add();
	test_find();
	test_delete();
	test_find();
	test_free_all();
	test_find();
	return 0;
}
