#include <stdio.h>
#include "../../../../../tmp/algorithms/uthash.h"

struct hash_table {
	int key;            /* we'll use this field as the key */
	char name[10]; // value
	UT_hash_handle hh; /* makes this structure hashable */
};

static struct hash_table *head_table = NULL;

void uthash_add(struct hash_table *add)
{
	HASH_ADD_INT(head_table, key, add);
}

static struct hash_table *uthash_find(int key)
{
	struct hash_table *out;

	HASH_FIND_INT(head_table, &key, out);
	return out;
}

static void uthash_delete(struct hash_table *del)
{
	HASH_DEL(head_table, del);
}

static void test_add(void)
{
	printf("testing add\n");

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
	}
}

static void test_find(void)
{
	printf("testing find\n");

	for (int i = 0; i < 4; i++) {
		int key = i + 5;
		struct hash_table *user = uthash_find(key);
		if (user) {
			printf("%d -> %s\n", key, user->name);
		} else {
			printf("%d -> NULL\n", key);
		}
	}
}

static void test_delete(void)
{
	printf("testing delete\n");

	int key_array[] = {6};

	for (int i = 0; i < sizeof(key_array) / sizeof(key_array[0]); i++) {
		int key = key_array[i];
		struct hash_table *user = uthash_find(key);
		if (user) {
			uthash_delete(user);
		}
	}
}

int main(int argc, char **argv)
{
	test_add();
	test_find();
	test_delete();
	test_find();
	return 0;
}
