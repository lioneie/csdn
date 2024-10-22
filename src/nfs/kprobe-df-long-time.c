// SPDX-License-Identifier: GPL-2.0-only
/*
 * Here's a sample kernel module showing the use of kprobes to dump a
 * stack trace and selected registers when kernel_clone() is called.
 *
 * For more information on theory of operation of kprobes, see
 * Documentation/trace/kprobes.rst
 *
 * You will see the trace data in /var/log/messages and on the console
 * whenever kernel_clone() is invoked to create a new process.
 */

#define pr_fmt(fmt) "%s: " fmt, __func__

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/kprobes.h>

// struct subprocess_info *call_usermodehelper_setup(const char *path, char **argv,
static char symbol[KSYM_NAME_LEN] = "call_usermodehelper_setup";
module_param_string(symbol, symbol, KSYM_NAME_LEN, 0644);

/* For each probe you need to allocate a kprobe structure */
static struct kprobe kp = {
	.symbol_name	= symbol,
};

/* kprobe pre_handler: called just before the probed instruction is executed */
static int __kprobes handler_pre(struct kprobe *p, struct pt_regs *regs)
{
	char **argv;
// x86_64函数参数用到的寄存器: RDI, RSI, RDX, RCX, R8, R9
#ifdef CONFIG_X86
	argv = (char **)regs->si;
#endif
// aarch64函数参数用到的寄存器: X0 ~ X7
#ifdef CONFIG_ARM64
	argv = (char **)regs->regs[1];;
#endif
	if (argv) {
		pr_info("<%s> %s op:%s, key:%s, uid:%s, gid:%s, keyring:%s, keyring:%s, keyring:%s\n",
			p->symbol_name, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7]);
	}

	return 0;
}

/* kprobe post_handler: called after the probed instruction is executed */
static void __kprobes handler_post(struct kprobe *p, struct pt_regs *regs,
				unsigned long flags)
{
}

static int __init kprobe_init(void)
{
	int ret;
	kp.pre_handler = handler_pre;
	kp.post_handler = handler_post;

	ret = register_kprobe(&kp);
	if (ret < 0) {
		pr_err("register_kprobe failed, returned %d\n", ret);
		return ret;
	}
	pr_info("Planted kprobe at %p\n", kp.addr);
	return 0;
}

static void __exit kprobe_exit(void)
{
	unregister_kprobe(&kp);
	pr_info("kprobe at %p unregistered\n", kp.addr);
}

module_init(kprobe_init)
module_exit(kprobe_exit)
MODULE_LICENSE("GPL");
