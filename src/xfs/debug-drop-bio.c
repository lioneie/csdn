// SPDX-License-Identifier: GPL-2.0-only
/*
 * Copyright (C) 2022 ChenXiaoSong
 */
#include <linux/kernel.h>
#include <linux/module.h>

extern int debug_drop_bio;

static int __init debug_drop_bio_init(void)
{
	debug_drop_bio = 1;
	return 0;
}

static void __exit debug_drop_bio_exit(void)
{
	debug_drop_bio = 0;
}

module_init(debug_drop_bio_init)
module_exit(debug_drop_bio_exit)
MODULE_LICENSE("GPL");

