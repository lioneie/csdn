#include <linux/kernel.h>
#include <linux/module.h>

struct crash_test_data {
	int a;
	char b;
	int c;
};

static void create_oops(void) {
	struct crash_test_data *data = NULL;
	data->b = 2;
}

static int __init crash_test_init(void)
{
	create_oops();
	return 0;
}

static void __exit crash_test_exit(void)
{
}

module_init(crash_test_init)
module_exit(crash_test_exit)
MODULE_LICENSE("GPL");

