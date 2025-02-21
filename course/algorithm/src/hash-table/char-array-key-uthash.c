// SPDX-License-Identifier: GPL-2.0
/*
 * key为char数组时，uthash的使用
 *
 * Copyright (C) 2025.01.20 ChenXiaoSong <chenxiaosong@chenxiaosong.com>
 */
#include <stdio.h>
// 如果访问不了github，uthash.h头文件也可以在这里下载: https://gitee.com/chenxiaosonggitee/tmp/blob/master/algorithm/uthash.h
#include "../../../../../tmp/algorithm/uthash.h"

struct hash_table {
	char key[64];
	int id; // value
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
	HASH_ADD_STR(head_table, key, add); // 这里的key不是变量，而是结构体成员名
}

static struct hash_table *uthash_find(char *key)
{
	struct hash_table *out;

	HASH_FIND_STR(head_table, key, out); // 这里的key是变量，和int类型需要取地址不同，这里不用取地址
	return out;
}

static void uthash_delete(struct hash_table *del)
{
	HASH_DEL(head_table, del);
}

#define uthash_iter(el) \
	HASH_ITER(hh, head_table, el, tmp_table)

char *name_array[] = {
	"you",
	"me",
	"others",
	"what the fuck",
};

#define NAME_WIDTH	20

static void test_add(void)
{
	printf("\ntesting add\n");

	for (int i = 0; i < 3; i++) {
		int id = i + 5;
		struct hash_table *user = malloc(sizeof(struct hash_table));
		strcpy(user->key, name_array[i]); // add时要复制字符串
		user->id = id;
		uthash_add(user);
		printf("\tadd\t %*s -> %d\n", NAME_WIDTH, user->key, user->id);
	}
}

static void test_find(void)
{
	printf("\ntesting find\n");

	for (int i = 0; i < 4; i++) {
		char *key = name_array[i];
		struct hash_table *user = uthash_find(key);
		if (user) {
			printf("\t\t%*s -> %d\n", NAME_WIDTH, user->key, user->id);
		} else {
			printf("\t\t%*s -> NULL\n", NAME_WIDTH, key);
		}
	}
}

static void test_delete(void)
{
	printf("\ntesting delete\n");

	char *key_array[] = {name_array[1]};

	for (int i = 0; i < sizeof(key_array) / sizeof(key_array[0]); i++) {
		char *key = key_array[i];
		struct hash_table *user = uthash_find(key);
		if (user) {
			printf("\tdelete\t %*s -> %d\n", NAME_WIDTH, user->key, user->id);
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
		printf("\tfree\t %*s -> %d\n", NAME_WIDTH, user->key, user->id);
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
