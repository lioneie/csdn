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

#define BACKTRACE_DEPTH 16

// int ext2_readdir(struct file *file, struct dir_context *ctx)
static char symbol[KSYM_NAME_LEN] = "ext2_readdir";
module_param_string(symbol, symbol, KSYM_NAME_LEN, 0644);

/* For each probe you need to allocate a kprobe structure */
static struct kprobe kp = {
	.symbol_name	= symbol,
};

static void show_backtrace(void)
{
	unsigned long stacks[BACKTRACE_DEPTH];
	unsigned int len;

	len = stack_trace_save(stacks, BACKTRACE_DEPTH, 2);
	stack_trace_print(stacks, len, 24);
}

/* kprobe pre_handler: called just before the probed instruction is executed */
static int __kprobes handler_pre(struct kprobe *p, struct pt_regs *regs)
{
	struct file *file;
	struct dir_context *ctx;
	struct dentry *tmp;
// x86_64函数参数用到的寄存器: RDI, RSI, RDX, RCX, R8, R9
#ifdef CONFIG_X86
	file = (struct file *)regs->di;
	ctx = (struct dir_context *)regs->si;
	pr_info("<%s> p->addr = 0x%p, ip = %lx, flags = 0x%lx\n",
		p->symbol_name, p->addr, regs->ip, regs->flags);
#endif
// aarch64函数参数用到的寄存器: X0 ~ X7
#ifdef CONFIG_ARM64
	file = (struct file *)regs->regs[0];;
	ctx = (struct dir_context *)regs->regs[1];;
	pr_info("<%s> p->addr = 0x%p, pc = 0x%lx, pstate = 0x%lx\n",
		p->symbol_name, p->addr, (long)regs->pc, (long)regs->pstate);
#endif
	struct inode *inode = file_inode(file);
	hlist_for_each_entry(tmp, &inode->i_dentry, d_u.d_alias)
		break;
	pr_info("<%s> dir name:%s, ctx:0x%p\n",
		p->symbol_name, tmp->d_name.name, ctx);

	/* A dump_stack() here will give a stack backtrace */
	// 也可以用 dump_stack()
	show_backtrace();
	return 0;
}

/* kprobe post_handler: called after the probed instruction is executed */
static void __kprobes handler_post(struct kprobe *p, struct pt_regs *regs,
				unsigned long flags)
{
#ifdef CONFIG_X86
	pr_info("<%s> p->addr = 0x%p, flags = 0x%lx\n",
		p->symbol_name, p->addr, regs->flags);
#endif
#ifdef CONFIG_ARM64
	pr_info("<%s> p->addr = 0x%p, pstate = 0x%lx\n",
		p->symbol_name, p->addr, (long)regs->pstate);
#endif
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
